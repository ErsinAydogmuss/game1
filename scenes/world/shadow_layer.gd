class_name ShadowLayer
extends Node3D
## Göldeki balık gölgelerini çizer: her karede sim.shadows ile eşlenir. Doğan gölge yavaşça
## belirir, kaçan solar; yüzerken hafifçe kıvrılır. Oltadaki balık çekişme noktasında çırpınır.
## Gölge dörtgeni suyun 2 cm üstünde; -Z yönü balığın başı (shadow.gdshader).

const Y := 0.02
## Gölgenin eni / boyu.
const WIDTH_RATIO := 0.4
## Gölge, telefonda okunsun diye balığın boyundan biraz büyük çizilir (oyun kuralları gerçek boyu kullanır).
const DRAW_SCALE := 1.25
const FADE_IN := 1.2
const FADE_OUT := 4.0

var _nodes: Dictionary = {}
var _fade: Dictionary = {}
var _shader: Shader
var _mesh: PlaneMesh
var _clock: float = 0.0


func _ready() -> void:
	_shader = load("res://scenes/world/shadow.gdshader")
	_mesh = PlaneMesh.new()
	_mesh.size = Vector2.ONE


## Gölgeleri oturumla eşler. angler: balıkçının yeri (oltadaki balık ona ters bakar);
## thrash: oltadaki balık çırpınıyor mu.
func sync(sim: ShadowSim, angler: Vector2, thrash: bool, delta: float) -> void:
	_clock += delta
	var alive := {}
	for s in sim.shadows:
		alive[s.id] = true
		var node: MeshInstance3D = _nodes.get(s.id)
		if node == null:
			node = _make()
			_nodes[s.id] = node
			_fade[s.id] = 0.0
		var target := 0.0 if s.mode == FishShadow.Mode.FLEE else 1.0
		var rate := FADE_OUT if target < float(_fade[s.id]) else FADE_IN
		_fade[s.id] = move_toward(float(_fade[s.id]), target, delta * rate)
		var heading := s.heading
		var wiggle := sin(_clock * 7.0 + s.id * 1.7) * 0.07
		if s.mode == FishShadow.Mode.HOOKED:
			var away := s.pos - angler
			heading = away.normalized() if away.length_squared() > 0.01 else heading
			wiggle = sin(_clock * (18.0 if thrash else 9.0)) * (0.35 if thrash else 0.15)
		elif s.mode == FishShadow.Mode.PAUSE or s.mode == FishShadow.Mode.NIBBLE:
			wiggle *= 0.4
		node.position = Vector3(s.pos.x, Y, s.pos.y)
		node.rotation = Vector3(0.0, atan2(-heading.x, -heading.y) + wiggle, 0.0)
		node.scale = Vector3(s.length * WIDTH_RATIO, 1.0, s.length) * Vector3(DRAW_SCALE, 1.0, DRAW_SCALE)
		(node.material_override as ShaderMaterial).set_shader_parameter("fade", float(_fade[s.id]))
	for id: int in _nodes.keys():
		if not alive.has(id):
			(_nodes[id] as Node).queue_free()
			_nodes.erase(id)
			_fade.erase(id)


## Gölgenin dünyadaki yeri (yoksa Vector3.INF): sunum efektleri için.
func shadow_point(id: int) -> Vector3:
	var node: MeshInstance3D = _nodes.get(id)
	return node.global_position if node != null else Vector3.INF


func _make() -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = _mesh
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := ShaderMaterial.new()
	material.shader = _shader
	material.render_priority = 1
	node.material_override = material
	add_child(node)
	return node
