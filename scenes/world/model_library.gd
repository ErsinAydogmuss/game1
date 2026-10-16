class_name ModelLibrary
extends RefCounted
## Hazır 3D modeller (KayKit paketleri, CC0; bkz. assets/CREDITS.md) için tek giriş noktası.
## Her modelin adı, dosyası ve oyundaki ölçeği burada durur. Paketlerin kendi ölçekleri farklı
## (ortaçağ paketinde bir fıçı 0,2 birim); ölçek, modeli gerçek boyutuna (metre) getirir.
##
## Model dosyası yoksa has() false döner; çağıran eski, kodla kurulan parçalara (Props) düşer.
## Çok tekrar eden modeller (ağaç, kaya) scatter() ile tek MultiMesh olarak çizilir.

const DIR := "res://assets/models/"
## ad → [dosya, ölçek]
const MODELS := {
	# Doğa (ortaçağ altıgen paketi)
	"trees_a_large": ["medieval/trees_A_large.gltf", 3.4],
	"trees_a_medium": ["medieval/trees_A_medium.gltf", 3.2],
	"trees_a_small": ["medieval/trees_A_small.gltf", 3.0],
	"trees_b_large": ["medieval/trees_B_large.gltf", 3.4],
	"trees_b_medium": ["medieval/trees_B_medium.gltf", 3.2],
	"trees_b_small": ["medieval/trees_B_small.gltf", 3.0],
	"tree_a": ["medieval/tree_single_A.gltf", 3.6],
	"tree_b": ["medieval/tree_single_B.gltf", 3.4],
	"rock_a": ["medieval/rock_single_A.gltf", 4.0],
	"rock_b": ["medieval/rock_single_B.gltf", 4.0],
	"rock_c": ["medieval/rock_single_C.gltf", 4.0],
	"rock_d": ["medieval/rock_single_D.gltf", 4.0],
	"rock_e": ["medieval/rock_single_E.gltf", 4.0],
	"mountain_a": ["medieval/mountain_A_grass_trees.gltf", 9.0],
	"mountain_b": ["medieval/mountain_B_grass_trees.gltf", 9.0],
	"hills": ["medieval/hills_A_trees.gltf", 8.0],
	# Yapılar ve eşyalar (ortaçağ altıgen paketi)
	"market": ["medieval/building_market_blue.gltf", 2.6],
	"mine": ["medieval/building_mine_blue.gltf", 4.5],
	"barrel": ["medieval/barrel.gltf", 4.2],
	"bucket": ["medieval/bucket_water.gltf", 3.4],
	"crate_a": ["medieval/crate_A_big.gltf", 3.6],
	"crate_b": ["medieval/crate_B_big.gltf", 3.6],
	"crate_open": ["medieval/crate_open.gltf", 3.6],
	"crate_long": ["medieval/crate_long_A.gltf", 3.6],
	"pallet": ["medieval/pallet.gltf", 4.0],
	"lumber": ["medieval/resource_lumber.gltf", 3.2],
	"stones": ["medieval/resource_stone.gltf", 3.4],
	"sack": ["medieval/sack.gltf", 4.2],
	"tent": ["medieval/tent.gltf", 5.2],
	"wheelbarrow": ["medieval/wheelbarrow.gltf", 3.6],
	"flag": ["medieval/flag_red.gltf", 4.0],
	# Cadılar Bayramı paketi (ahşap bank, fenerler, taş yol)
	"bench": ["halloween/bench.gltf", 0.8],
	"lantern_post": ["halloween/post_lantern.gltf", 0.62],
	"lantern": ["halloween/lantern_standing.gltf", 0.6],
	"path_a": ["halloween/path_A.gltf", 0.62],
	"path_b": ["halloween/path_B.gltf", 0.62],
	# Mobilya paketi (temizleme tezgâhı)
	"table": ["furniture/table_medium.gltf", 0.75],
	"stool": ["furniture/chair_stool_wood.gltf", 0.85],
}

## yol → PackedScene (malzemeleri ayarlanmış).
static var _scenes: Dictionary = {}


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
static func scatter(parent: Node3D, id: String, transforms: Array[Transform3D]) -> bool:
	var scene := _scene(id)
	if scene == null or transforms.is_empty():
		return false
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
	root.free()
	return true


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
