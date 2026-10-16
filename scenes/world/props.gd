class_name Props
extends RefCounted
## Kodla kurulan basit 3D parçalar (gri-kutu modeller) için yardımcılar.
## Aynı renk ve ayardaki malzemeler önbellekten paylaşılır. Gerçek modeller (GLB) gelince
## bu parçaların yerini alacak; sahne kodu yalnızca kurulum fonksiyonlarını değiştirir.

static var _materials: Dictionary = {}


static func material(color: Color, roughness: float = 0.85, emission: float = 0.0) -> StandardMaterial3D:
	var key := "%s|%.2f|%.2f" % [color.to_html(), roughness, emission]
	if _materials.has(key):
		return _materials[key]
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = roughness
	if emission > 0.0:
		m.emission_enabled = true
		m.emission = color
		m.emission_energy_multiplier = emission
	_materials[key] = m
	return m


static func box(parent: Node3D, size: Vector3, pos: Vector3, color: Color,
		rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	return _add(parent, mesh, pos, color, rot)


static func cylinder(parent: Node3D, top_radius: float, bottom_radius: float, height: float,
		pos: Vector3, color: Color, segments: int = 8, rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_radius
	mesh.bottom_radius = bottom_radius
	mesh.height = height
	mesh.radial_segments = segments
	mesh.rings = 1
	return _add(parent, mesh, pos, color, rot)


static func sphere(parent: Node3D, radius: float, pos: Vector3, color: Color, segments: int = 12,
		rings: int = 6, scale: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var mesh := SphereMesh.new()
	mesh.radius = radius
	mesh.height = radius * 2.0
	mesh.radial_segments = segments
	mesh.rings = rings
	var node := _add(parent, mesh, pos, color, Vector3.ZERO)
	node.scale = scale
	return node


static func capsule(parent: Node3D, radius: float, height: float, pos: Vector3, color: Color,
		rot: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = height
	mesh.radial_segments = 12
	mesh.rings = 4
	return _add(parent, mesh, pos, color, rot)


## Boş bir eklem (pivot) düğümü.
static func pivot(parent: Node3D, pos: Vector3, node_name: String = "") -> Node3D:
	var node := Node3D.new()
	if not node_name.is_empty():
		node.name = node_name
	node.position = pos
	parent.add_child(node)
	return node


static func _add(parent: Node3D, mesh: Mesh, pos: Vector3, color: Color, rot: Vector3) -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = material(color)
	node.position = pos
	node.rotation = rot
	parent.add_child(node)
	return node
