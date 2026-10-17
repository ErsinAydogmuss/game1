class_name ModelLibrary
extends RefCounted
## Hazır 3D modeller (KayKit ve Kenney paketleri, CC0; bkz. assets/CREDITS.md) için tek giriş
## noktası. Her modelin adı, dosyası ve oyundaki ölçeği burada durur. Paketlerin kendi ölçekleri
## farklı (ortaçağ paketinde bir fıçı 0,2 birim); ölçek, modeli gerçek boyutuna (metre) getirir.
##
## Model dosyası yoksa has() false döner; çağıran eski, kodla kurulan parçalara (Props) düşer.
## Aynı modelin kopyaları scatter() ile tek MultiMesh; aynı dokuyu paylaşan bir paketin modelleri
## merge() ile tek ağ (bölge parçaları) olarak çizilir.

const DIR := "res://assets/models/"
## ad → [dosya, ölçek]
const MODELS := {
	# Orman (KayKit orman paketi; boyları zaten metre). Hepsi tek dokuyu paylaşır: merge.
	"tree_1a": ["kaykit_forest/Tree_1_A_Color1.gltf", 0.9],
	"tree_1b": ["kaykit_forest/Tree_1_B_Color1.gltf", 0.85],
	"tree_1c": ["kaykit_forest/Tree_1_C_Color1.gltf", 0.75],
	"tree_3a": ["kaykit_forest/Tree_3_A_Color1.gltf", 0.95],
	"tree_3b": ["kaykit_forest/Tree_3_B_Color1.gltf", 0.9],
	"tree_4a": ["kaykit_forest/Tree_4_A_Color1.gltf", 0.9],
	"tree_4b": ["kaykit_forest/Tree_4_B_Color1.gltf", 0.85],
	"bush_1c": ["kaykit_forest/Bush_1_C_Color1.gltf", 0.75],
	"bush_1e": ["kaykit_forest/Bush_1_E_Color1.gltf", 0.75],
	"bush_1f": ["kaykit_forest/Bush_1_F_Color1.gltf", 0.7],
	"bush_3b": ["kaykit_forest/Bush_3_B_Color1.gltf", 0.75],
	"grass_1c": ["kaykit_forest/Grass_1_C_Color1.gltf", 0.75],
	"grass_2c": ["kaykit_forest/Grass_2_C_Color1.gltf", 0.7],
	"rock_3a": ["kaykit_forest/Rock_3_A_Color1.gltf", 1.0],
	"rock_3c": ["kaykit_forest/Rock_3_C_Color1.gltf", 1.0],
	"rock_3e": ["kaykit_forest/Rock_3_E_Color1.gltf", 0.95],
	"rock_3g": ["kaykit_forest/Rock_3_G_Color1.gltf", 0.85],
	"rock_3j": ["kaykit_forest/Rock_3_J_Color1.gltf", 0.85],
	"rock_3l": ["kaykit_forest/Rock_3_L_Color1.gltf", 0.75],
	# Uzaktaki tepeler ve dağlar (ortaçağ altıgen paketi)
	"mountain_a": ["medieval/mountain_A_grass_trees.gltf", 9.0],
	"mountain_b": ["medieval/mountain_B_grass_trees.gltf", 9.0],
	"hills": ["medieval/hills_A_trees.gltf", 8.0],
	# Kamp eşyaları (ortaçağ altıgen paketi)
	"barrel": ["medieval/barrel.gltf", 4.2],
	"crate": ["medieval/crate_A_big.gltf", 3.6],
	"sack": ["medieval/sack.gltf", 4.2],
	"bucket": ["medieval/bucket_water.gltf", 3.4],
	# Kamp (Kenney hayatta kalma paketi; çok küçük ölçekli)
	"campfire": ["kenney_survival/campfire-pit.glb", 3.4],
	"log_seat": ["kenney_survival/tree-log-small.glb", 1.8],
	"signpost": ["kenney_survival/signpost.glb", 2.8],
	# Kilitli bölgenin çiti ve tabelası (Kenney hayatta kalma paketi)
	"fence": ["kenney_survival/fence.glb", 2.2],
	"gate_sign": ["kenney_survival/signpost-single.glb", 3.0],
	# İskeleye bağlı sandal ve derin ortanın şamandıraları (Kenney deniz taşıtları)
	"boat": ["kenney_watercraft/boat-row-large.glb", 0.8],
	"buoy": ["kenney_watercraft/buoy-flag.glb", 0.5],
	# Cadılar Bayramı paketi (fenerli direk)
	"lantern_post": ["halloween/post_lantern.gltf", 0.62],
}

## yol → PackedScene (malzemeleri ayarlanmış).
static var _scenes: Dictionary = {}
## ad → [[Mesh, modelin kökünden göreli Transform3D]...] (merge ve bounds için).
static var _parts: Dictionary = {}


static func has(id: String) -> bool:
	return MODELS.has(id) and ResourceLoader.exists(_path(id))


## Modeli parent altına koyar. yaw: y ekseninde dönüş (radyan); size: ölçek çarpanı.
## Model yoksa null döner.
static func spawn(parent: Node3D, id: String, pos: Vector3, yaw: float = 0.0, size: float = 1.0) -> Node3D:
	var scene := _scene(id)
	if scene == null:
		return null
	var node := scene.instantiate() as Node3D
	node.name = id.to_pascal_case()
	node.position = pos
	node.rotation.y = yaw
	node.scale = Vector3.ONE * _scale(id) * size
	parent.add_child(node)
	return node


## Aynı modelin birçok kopyası: modeldeki her mesh için bir MultiMeshInstance3D (tek çizim).
## transforms: her kopyanın yeri, dönüşü ve ek ölçeği (modelin kendi ölçeği eklenir).
## Kurulan düğümleri döndürür (model yoksa boş).
static func scatter(parent: Node3D, id: String, transforms: Array[Transform3D]) -> Array[MultiMeshInstance3D]:
	var out: Array[MultiMeshInstance3D] = []
	var scene := _scene(id)
	if scene == null or transforms.is_empty():
		return out
	var root := scene.instantiate() as Node3D
	var base := Transform3D(Basis.from_scale(Vector3.ONE * _scale(id)), Vector3.ZERO)
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var mesh_node := node as MeshInstance3D
		var local := _relative_transform(root, mesh_node)
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = mesh_node.mesh
		mm.instance_count = transforms.size()
		for i in transforms.size():
			mm.set_instance_transform(i, transforms[i] * base * local)
		var instance := MultiMeshInstance3D.new()
		instance.name = "%s_%s" % [id.to_pascal_case(), mesh_node.name]
		instance.multimesh = mm
		parent.add_child(instance)
		out.append(instance)
	root.free()
	return out


## Aynı dokuyu paylaşan modellerin (bir paketin) kopyalarını tek ağda birleştirir: tek çizim
## (gölgesiyle iki), MultiMesh'ten farklı olarak farklı modeller de aynı ağa girer.
## placements: [ad, Transform3D] (yer, dönüş, ek ölçek; modelin kendi ölçeği eklenir).
## chunk > 0 ise yerleşimler chunk metrelik bölgelere ayrılır, her bölge ayrı bir ağ: ekranın
## dışında kalan bölge çizilmez. center: bölge ızgarasının ortası (ör. gölün ortası: kıyıdaki
## süsler tek bölgeye düşsün). Malzeme verilmezse ilk modelin malzemesi kullanılır (paketin
## modelleri aynı dokuyu aynı UV düzeniyle kullanır). Kurulan düğümleri döndürür (model yoksa boş).
static func merge(parent: Node3D, node_name: String, placements: Array[Array], chunk: float = 0.0,
		material: Material = null, center: Vector2 = Vector2.ZERO) -> Array[MeshInstance3D]:
	var tools := {}
	var used := material
	for placement in placements:
		var id := str(placement[0])
		var parts := _parts_of(id)
		if parts.is_empty():
			continue
		var xform: Transform3D = placement[1]
		var key := Vector2i.ZERO
		if chunk > 0.0:
			var at := (Vector2(xform.origin.x, xform.origin.z) - center) / chunk
			key = Vector2i(floori(at.x + 0.5), floori(at.y + 0.5))
		if not tools.has(key):
			var st := SurfaceTool.new()
			st.begin(Mesh.PRIMITIVE_TRIANGLES)
			tools[key] = st
		var base := xform * Transform3D(Basis.from_scale(Vector3.ONE * _scale(id)), Vector3.ZERO)
		for part: Array in parts:
			var mesh: Mesh = part[0]
			for s in mesh.get_surface_count():
				(tools[key] as SurfaceTool).append_from(mesh, s, base * (part[1] as Transform3D))
				if used == null:
					used = mesh.surface_get_material(s)
	var out: Array[MeshInstance3D] = []
	for key: Vector2i in tools:
		var node := MeshInstance3D.new()
		node.name = "%s_%d_%d" % [node_name, key.x, key.y]
		node.mesh = (tools[key] as SurfaceTool).commit()
		node.material_override = used
		parent.add_child(node)
		out.append(node)
	return out


## Modelin oyundaki ölçekle kutusu (yerel; ör. yarı gömülecek bir kayanın boyu). Model yoksa boş.
static func bounds(id: String) -> AABB:
	var box := AABB()
	var first := true
	for part: Array in _parts_of(id):
		var b := (part[1] as Transform3D) * (part[0] as Mesh).get_aabb()
		box = b if first else box.merge(b)
		first = false
	return Transform3D(Basis.from_scale(Vector3.ONE * _scale(id)), Vector3.ZERO) * box if not first else box


static func _parts_of(id: String) -> Array:
	if _parts.has(id):
		return _parts[id]
	var parts: Array = []
	var scene := _scene(id)
	if scene != null:
		var root := scene.instantiate() as Node3D
		for node in root.find_children("*", "MeshInstance3D", true, false):
			var mesh_node := node as MeshInstance3D
			parts.append([mesh_node.mesh, _relative_transform(root, mesh_node)])
		root.free()
	_parts[id] = parts
	return parts


static func _path(id: String) -> String:
	return DIR + str((MODELS[id] as Array)[0])


static func _scale(id: String) -> float:
	return float((MODELS[id] as Array)[1])


static func _scene(id: String) -> PackedScene:
	if not has(id):
		return null
	var path := _path(id)
	if not _scenes.has(path):
		var scene: PackedScene = load(path)
		_tune_materials(scene)
		_scenes[path] = scene
	return _scenes[path]


## KayKit dokuları renk geçişli düz renklerdir: mat, parlamasız malzeme daha iyi durur.
## Malzemeler paylaşılan kaynaklar olduğundan bir kez ayarlamak yeter.
static func _tune_materials(scene: PackedScene) -> void:
	var root := scene.instantiate()
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var mesh := (node as MeshInstance3D).mesh
		if mesh == null:
			continue
		for s in mesh.get_surface_count():
			var material := mesh.surface_get_material(s) as StandardMaterial3D
			if material == null:
				continue
			material.roughness = 0.9
			material.metallic = 0.0
			material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	root.free()


static func _relative_transform(root: Node3D, node: Node3D) -> Transform3D:
	var t := Transform3D.IDENTITY
	var current: Node = node
	while current != null and current != root:
		if current is Node3D:
			t = (current as Node3D).transform * t
		current = current.get_parent()
	return t
