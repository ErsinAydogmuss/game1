class_name MeshBatch
extends RefCounted
## Kodla kurulan durağan parçaları (dükkân, şapka, yazma, çay bardağı) tek ağda birleştirir: her
## parçanın rengi köşe rengi olur, hepsi tek malzemeyle tek çizimde çizilir (çizim bütçesi:
## dükkânın ~120 parçası tek çizim). Parçalar dönebilir ve ölçeklenebilir.
## Kullanım: parçaları ekle (box, cylinder, sphere, add, triangles) ve build(); ya da Props ile bir pivotun
## altına kurulmuş parçaları merge() ile birleştir.

## Paylaşılan köşe rengi malzemesi (Props.material ile aynı mat görünüm).
static var _vertex_material: StandardMaterial3D

var _verts := PackedVector3Array()
var _normals := PackedVector3Array()
var _uvs := PackedVector2Array()
var _colors := PackedColorArray()
var _indices := PackedInt32Array()


func box(size: Vector3, pos: Vector3, color: Color, rot: Vector3 = Vector3.ZERO) -> void:
	var mesh := BoxMesh.new()
	mesh.size = size
	add(mesh, Transform3D(Basis.from_euler(rot), pos), color)


func cylinder(top_radius: float, bottom_radius: float, height: float, pos: Vector3, color: Color,
		segments: int = 8, rot: Vector3 = Vector3.ZERO) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_radius
	mesh.bottom_radius = bottom_radius
	mesh.height = height
	mesh.radial_segments = segments
	mesh.rings = 1
	add(mesh, Transform3D(Basis.from_euler(rot), pos), color)


func sphere(radius: float, pos: Vector3, color: Color, scale: Vector3 = Vector3.ONE, segments: int = 10,
		rings: int = 5) -> void:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = segments
	mesh.rings = rings
	add(mesh, Transform3D(Basis.from_scale(scale), pos), color)


## Bir parça ekler: ağın köşeleri xform ile taşınır, hepsine color verilir.
func add(mesh: PrimitiveMesh, xform: Transform3D, color: Color) -> void:
	var arrays := mesh.get_mesh_arrays()
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
	var uvs: Variant = arrays[Mesh.ARRAY_TEX_UV]
	var base := _verts.size()
	# Ölçek eşit değilse normaller ters-devrik matrisle döner.
	var normal_basis := xform.basis.inverse().transposed()
	for i in verts.size():
		_verts.append(xform * verts[i])
		_normals.append((normal_basis * normals[i]).normalized())
		_uvs.append((uvs as PackedVector2Array)[i] if uvs != null else Vector2.ZERO)
		_colors.append(color)
	var indices: Variant = arrays[Mesh.ARRAY_INDEX]
	if indices == null or (indices as PackedInt32Array).is_empty():
		for i in verts.size():
			_indices.append(base + i)
	else:
		for index in (indices as PackedInt32Array):
			_indices.append(base + index)


## Hazır bir ağı (ilk yüzeyi) kendi köşe renkleriyle ekler (akvaryumun balıkları: FishMesh). linear: ağın renkleri
## doğrusal (balığın gölgelendiricisi COLOR'ı olduğu gibi kullanır), birleşik ağın malzemesi sRGB okur: çevrilir.
## tint: renk bu renge bu kadar karışır (suyun ardındaki balık). two_sided: her üçgenin ters yüzü de eklenir
## (yüzgeçler tek yüzlü; malzeme arka yüzü çizmez). Ağın üçgen çorbası (renkleri ve ters yüzüyle) bir kez hazırlanır
## (_soup, önbellek); her eklemede köşeler ve normaller toplu dönüşür (Transform3D * dizi: yerel kod): akvaryumun
## altı balığı birkaç ms. Dönüşüm eşit ölçekli olmalı (dönme × ölçek; normaller dönmeyle döner).
func add_mesh(source: Mesh, xform: Transform3D, linear: bool = false, tint: Color = Color.WHITE, tint_amount: float = 0.0,
		two_sided: bool = false) -> void:
	if source == null or source.get_surface_count() == 0:
		return
	var soup := _soup(source, linear, tint, tint_amount, two_sided)
	var verts: PackedVector3Array = soup[0]
	var base := _verts.size()
	_verts.append_array(xform * verts)
	_normals.append_array(Transform3D(xform.basis.orthonormalized(), Vector3.ZERO) * (soup[1] as PackedVector3Array))
	_uvs.resize(_uvs.size() + verts.size())
	_colors.append_array(soup[2])
	_indices.append_array(PackedInt32Array(range(base, base + verts.size())))


static var _soups: Dictionary = {}


## Ağın üçgen çorbası: [köşeler, normaller, renkler] (sıralı, üçer üçer; ters yüz istenirse ardından sarımı çevrilmiş
## ve normali ters kopya). Ağ ve ayarlar başına bir kez.
static func _soup(source: Mesh, linear: bool, tint: Color, tint_amount: float, two_sided: bool) -> Array:
	var key := "%d:%s:%s:%.3f:%s" % [source.get_instance_id(), linear, tint.to_html(), tint_amount, two_sided]
	if _soups.has(key):
		return _soups[key]
	var arrays := source.surface_get_arrays(0)
	var verts: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
	var normals: Variant = arrays[Mesh.ARRAY_NORMAL]
	var colors: Variant = arrays[Mesh.ARRAY_COLOR]
	var indices: Variant = arrays[Mesh.ARRAY_INDEX]
	var order := PackedInt32Array()
	if indices == null or (indices as PackedInt32Array).is_empty():
		order = PackedInt32Array(range(verts.size()))
	else:
		order = indices
	var out_v := PackedVector3Array()
	var out_n := PackedVector3Array()
	var out_c := PackedColorArray()
	for face in (2 if two_sided else 1):
		for t in range(0, order.size() - 2, 3):
			var second := order[t + 1] if face == 0 else order[t + 2]
			var third := order[t + 2] if face == 0 else order[t + 1]
			for i: int in [order[t], second, third]:
				out_v.append(verts[i])
				var n: Vector3 = (normals as PackedVector3Array)[i] if normals != null else Vector3.UP
				out_n.append(n if face == 0 else -n)
				var c: Color = (colors as PackedColorArray)[i] if colors != null else Color.WHITE
				if linear:
					c = c.linear_to_srgb()
				out_c.append(c.lerp(tint, tint_amount) if tint_amount > 0.0 else c)
	var soup := [out_v, out_n, out_c]
	_soups[key] = soup
	return soup


## Kodla hesaplanan üçgenler (art arda üçer köşe; dışarıdan bakınca saat yönünde: Godot'nun ön
## yüzü). Normaller düz (üçgen başına); hepsine color verilir (nilüfer yaprağı, çiçek).
func triangles(points: PackedVector3Array, color: Color) -> void:
	for i in range(0, points.size() - 2, 3):
		var a := points[i]
		var b := points[i + 1]
		var c := points[i + 2]
		var n := (c - a).cross(b - a).normalized()
		for p: Vector3 in [a, b, c]:
			_indices.append(_verts.size())
			_verts.append(p)
			_normals.append(n)
			_uvs.append(Vector2.ZERO)
			_colors.append(color)


func is_empty() -> bool:
	return _verts.is_empty()


## Başka bir topluluğun parçalarını ekler (göl sevgisinin çiçekleri temel bitkilerle tek ağda).
func append(other: MeshBatch) -> void:
	if _verts.is_empty():
		# Boş topluluğa kopya (yerel kod; dükkânın sabit kısmı her yeniden kurulmada).
		_verts = other._verts.duplicate()
		_normals = other._normals.duplicate()
		_uvs = other._uvs.duplicate()
		_colors = other._colors.duplicate()
		_indices = other._indices.duplicate()
		return
	var base := _verts.size()
	_verts.append_array(other._verts)
	_normals.append_array(other._normals)
	_uvs.append_array(other._uvs)
	_colors.append_array(other._colors)
	for index in other._indices:
		_indices.append(base + index)


## Üçgen sayısı (ölçüm ve bot).
func triangle_count() -> int:
	return int(_indices.size() / 3.0)


## Birleşik ağ (tek yüzey; köşe renkli).
func mesh() -> ArrayMesh:
	var out := ArrayMesh.new()
	if _verts.is_empty():
		return out
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = _verts
	arrays[Mesh.ARRAY_NORMAL] = _normals
	arrays[Mesh.ARRAY_TEX_UV] = _uvs
	arrays[Mesh.ARRAY_COLOR] = _colors
	arrays[Mesh.ARRAY_INDEX] = _indices
	out.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return out


## Tek bir düğüm kurar. material verilmezse paylaşılan köşe rengi malzemesi; verilirse köşe rengini
## kullanmalı (vertex_color_use_as_albedo; ör. desenli kumaş: doku × köşe rengi).
func build(parent: Node3D, node_name: String, material: Material = null) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.name = node_name
	node.mesh = mesh()
	node.material_override = material if material != null else vertex_material()
	parent.add_child(node)
	return node


## Bir pivotun doğrudan çocukları olan Props parçalarını (MeshInstance3D + PrimitiveMesh) tek ağda
## birleştirir: parçanın düz rengi köşe rengi olur; dokulu parçalar beyaz (dokuyu material verir).
## Parçalar silinir; birleşik düğüm döner (pivotun çocuğu).
static func merge(pivot: Node3D, material: Material = null) -> MeshInstance3D:
	var batch := MeshBatch.new()
	for child in pivot.get_children():
		var part := child as MeshInstance3D
		if part == null or not (part.mesh is PrimitiveMesh):
			continue
		var color := Color.WHITE
		var flat := part.material_override as StandardMaterial3D
		if flat != null and flat.albedo_texture == null:
			color = flat.albedo_color
		batch.add(part.mesh as PrimitiveMesh, part.transform, color)
		pivot.remove_child(part)
		part.free()
	return batch.build(pivot, str(pivot.name) + "Mesh", material)


static func vertex_material() -> StandardMaterial3D:
	if _vertex_material == null:
		_vertex_material = StandardMaterial3D.new()
		_vertex_material.vertex_color_use_as_albedo = true
		_vertex_material.vertex_color_is_srgb = true
		_vertex_material.roughness = 0.85
	return _vertex_material
