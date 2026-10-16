class_name MeshBatch
extends RefCounted
## Kodla kurulan durağan parçaları (dükkân, şapka, yazma, çay bardağı) tek ağda birleştirir: her
## parçanın rengi köşe rengi olur, hepsi tek malzemeyle tek çizimde çizilir (çizim bütçesi:
## dükkânın ~120 parçası tek çizim). Parçalar dönebilir ve ölçeklenebilir.
## Kullanım: parçaları ekle (box, cylinder, sphere, add) ve build(); ya da Props ile bir pivotun
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


func is_empty() -> bool:
	return _verts.is_empty()


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
