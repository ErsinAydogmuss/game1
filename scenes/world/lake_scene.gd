class_name LakeScene
extends Node3D
## Gölün sahnesi (gri kutu): ışık ve ortam, zemin, su, iskele ve basit çevre süsleri.
## Su ve zemin, göl şeklinden (LakeShape) üretilen tek bir veri dokusunu paylaşır.
## 5. adımda arazi eğimi, dalga, köpük ve KayKit çevresi gelir.

## İskele güvertesinin su üstündeki yüksekliği (m).
const DOCK_HEIGHT := 0.35
## Zemin, su yüzeyinin (y = 0) biraz altında: su karada çizilmez, zemin görünür.
const GROUND_Y := -0.03
const SKY := Color("#a9d2ef")
const WOOD := Color("#9b6a3c")
const WOOD_DARK := Color("#6e4526")

var lake: LakeShape
var data_texture: ImageTexture
var environment: Environment


func setup(shape: LakeShape) -> void:
	lake = shape
	data_texture = LakeTexture.build(lake)
	_build_environment()
	_build_ground()
	_build_water()
	_build_dock()
	_build_scenery()


## Balıkçının duracağı yükseklik: iskelede güverte, karada zemin.
func stand_height(p: Vector2) -> float:
	return DOCK_HEIGHT + 0.04 if lake.on_dock(p) else 0.0


# --- Kurulum ------------------------------------------------------------------------

func _build_environment() -> void:
	environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = SKY
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#d4e4f7")
	environment.ambient_light_energy = 0.5
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_white = 6.0
	environment.glow_enabled = true
	environment.glow_intensity = 0.7
	environment.glow_bloom = 0.03
	environment.glow_hdr_threshold = 0.95
	environment.fog_enabled = true
	environment.fog_mode = Environment.FOG_MODE_EXPONENTIAL
	environment.fog_light_color = SKY
	environment.fog_density = 0.006
	environment.fog_sky_affect = 0.0
	environment.adjustment_enabled = true
	environment.adjustment_contrast = 1.08
	environment.adjustment_saturation = 1.16
	var world := WorldEnvironment.new()
	world.environment = environment
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.light_color = Color("#fff1db")
	sun.light_energy = 1.15
	sun.shadow_enabled = true
	sun.shadow_blur = 1.5
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_max_distance = 30.0
	add_child(sun)
	# Işık kameranın arkasından, biraz soldan gelsin: görünen yüzler aydınlık olsun.
	sun.look_at_from_position(Vector3.ZERO, Vector3(-0.35, -1.0, -0.55), Vector3.UP)
	var fill := DirectionalLight3D.new()
	fill.light_color = Color("#b9d4ff")
	fill.light_energy = 0.35
	add_child(fill)
	fill.look_at_from_position(Vector3.ZERO, Vector3(0.6, -0.5, 0.4), Vector3.UP)


func _build_ground() -> void:
	var plane := PlaneMesh.new()
	plane.size = Vector2(120.0, 120.0)
	var ground := MeshInstance3D.new()
	ground.name = "Ground"
	ground.mesh = plane
	ground.position = Vector3(lake.water_bounds.get_center().x, GROUND_Y, lake.water_bounds.get_center().y)
	ground.material_override = _shader_material("res://scenes/world/ground.gdshader")
	add_child(ground)


func _build_water() -> void:
	var bounds := lake.water_bounds.grow(0.5)
	var plane := PlaneMesh.new()
	plane.size = bounds.size
	var water := MeshInstance3D.new()
	water.name = "Water"
	water.mesh = plane
	water.position = Vector3(bounds.get_center().x, 0.0, bounds.get_center().y)
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	water.material_override = _shader_material("res://scenes/world/water.gdshader")
	add_child(water)


func _shader_material(path: String) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = load(path)
	LakeTexture.apply(material, lake, data_texture)
	return material


## İskele: enine tahtalar ve ayaklar (Props). Uzun kenarı z boyunca.
func _build_dock() -> void:
	var dock := Props.pivot(self, Vector3.ZERO, "Dock")
	var rect := lake.dock
	var plank := 0.3
	var count := maxi(1, int(rect.size.y / (plank + 0.04)))
	for i in count:
		var z := rect.position.y + (float(i) + 0.5) * rect.size.y / count
		var shade := WOOD if i % 2 == 0 else WOOD.darkened(0.08)
		Props.box(dock, Vector3(rect.size.x, 0.08, plank), Vector3(rect.get_center().x, DOCK_HEIGHT, z), shade)
	var post_z := rect.position.y + 0.2
	while post_z < rect.end.y:
		for side: float in [-1.0, 1.0]:
			var x := rect.get_center().x + side * (rect.size.x * 0.5 - 0.08)
			Props.cylinder(dock, 0.09, 0.09, 1.0, Vector3(x, -0.1, post_z), WOOD_DARK, 6)
		post_z += 1.4


## Kıyıda saz ve taş, uzakta basit ağaçlar (görsel; sabit tohumlu rastgelelik).
func _build_scenery() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var bounds := lake.water_bounds.grow(3.0)
	var placed := 0
	var tries := 0
	while placed < 34 and tries < 2000:
		tries += 1
		var p := Vector2(rng.randf_range(bounds.position.x, bounds.end.x), rng.randf_range(bounds.position.y, bounds.end.y))
		var shore := lake.shore_distance(p)
		if shore < -0.6 or shore > 0.35 or lake.on_dock(p, 1.2):
			continue
		var h := rng.randf_range(0.6, 1.1)
		Props.cylinder(self, 0.03, 0.04, h, Vector3(p.x, h * 0.5 - 0.05, p.y), Color("#5f9a3c"), 5)
		placed += 1
	placed = 0
	tries = 0
	var far := lake.water_bounds.grow(9.0)
	while placed < 26 and tries < 2000:
		tries += 1
		var p := Vector2(rng.randf_range(far.position.x, far.end.x), rng.randf_range(far.position.y, far.end.y))
		if lake.shore_distance(p) > -3.0 or (p.y > lake.dock.position.y and absf(p.x - lake.dock.get_center().x) < 6.0):
			continue
		var size := rng.randf_range(0.8, 1.3)
		Props.cylinder(self, 0.12 * size, 0.16 * size, 0.9 * size, Vector3(p.x, 0.45 * size, p.y), WOOD_DARK, 6)
		Props.cylinder(self, 0.0, 0.9 * size, 2.2 * size, Vector3(p.x, 1.9 * size, p.y), Color("#3f8f4a"), 7)
		placed += 1
	for i in 7:
		var a := rng.randf() * TAU
		var p := lake.water_bounds.get_center() + Vector2(cos(a), sin(a)) * rng.randf_range(10.5, 13.0)
		if lake.shore_distance(p) > -0.8 or lake.on_dock(p, 2.0):
			continue
		Props.sphere(self, rng.randf_range(0.25, 0.45), Vector3(p.x, 0.05, p.y), Color("#9aa3ad"), 8, 4, Vector3(1.3, 0.6, 1.0))
