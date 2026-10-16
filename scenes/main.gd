extends Node3D
## Ana sahne: her şeyi bağlar. 2. adımda yer tutucu bir göl, iskele ve arayüz iskeleti kurar
## (telefona ilk yüklemede imza ve ekran ayarları denensin diye).
## Sonraki adımlar: balık tutma (FishingSession, 3–4. adım), göl görselleri (5. adım),
## balıkçı, olta ve balık modelleri (6. adım).

## Gölün yarıçapları (metre): x ve z yönünde. Göl (0, 0, 0) merkezli bir elips.
const LAKE_RADIUS := Vector2(9.0, 6.5)
## İskele: kıyıdan (+z) göle doğru (-z) uzanır.
const DOCK_WIDTH := 1.6
const DOCK_FROM := 8.4
const DOCK_TO := 4.0
const DOCK_HEIGHT := 0.35

const SKY := Color("#a9d2ef")
const GRASS := Color("#5a9a3a")
const SAND := Color("#c9a865")
const WATER := Color("#1f7f98")
const WATER_DEEP := Color("#155a76")
const WOOD := Color("#9b6a3c")
const WOOD_DARK := Color("#6e4526")

var camera: FollowCamera
var hud: Hud
var settings_panel: SettingsPanel


func _ready() -> void:
	_build_environment()
	_build_placeholder_lake()
	_build_placeholder_dock()
	_build_placeholder_angler()
	camera = FollowCamera.new()
	add_child(camera)
	camera.snap(Vector3(0.0, 0.5, DOCK_TO - 0.6))
	_build_ui()
	GameState.changed.connect(_on_state_changed)
	Sounds.set_ambience("lake")


func _on_state_changed() -> void:
	hud.refresh()


# --- Dünya (yer tutucu) ----------------------------------------------------------

## Işık ve ortam: Kazı'nın telefonda denenmiş ayarları (5. adımda LakeScenery'ye taşınır).
func _build_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = SKY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#d4e4f7")
	env.ambient_light_energy = 0.5
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_white = 6.0
	env.glow_enabled = true
	env.glow_intensity = 0.7
	env.glow_bloom = 0.03
	env.glow_hdr_threshold = 0.95
	env.fog_enabled = true
	env.fog_mode = Environment.FOG_MODE_EXPONENTIAL
	env.fog_light_color = SKY
	env.fog_density = 0.006
	env.fog_sky_affect = 0.0
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.08
	env.adjustment_saturation = 1.16
	var world := WorldEnvironment.new()
	world.environment = env
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


func _build_placeholder_lake() -> void:
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(90.0, 90.0)
	ground.mesh = plane
	ground.material_override = Props.material(GRASS, 0.95)
	add_child(ground)
	# Kumsal, su ve derin su: üst üste ince diskler (z-kavgası olmasın diye 2 cm arayla).
	_disc(LAKE_RADIUS + Vector2(1.3, 1.3), 0.02, SAND, 0.95)
	_disc(LAKE_RADIUS, 0.04, WATER, 0.45)
	_disc(LAKE_RADIUS * 0.55, 0.06, WATER_DEEP, 0.45)
	# Kıyıda birkaç saz ve taş; uzakta basit ağaçlar (görsel; rastgelelik sabit tohumlu).
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 26:
		var a := rng.randf() * TAU
		var edge := Vector3(cos(a) * LAKE_RADIUS.x, 0.0, sin(a) * LAKE_RADIUS.y) * rng.randf_range(0.97, 1.05)
		if absf(edge.x) < DOCK_WIDTH * 1.5 and edge.z > 0.0:
			continue
		var h := rng.randf_range(0.6, 1.1)
		Props.cylinder(self, 0.03, 0.04, h, edge + Vector3(0.0, h * 0.5, 0.0), Color("#5f9a3c"), 5)
	for i in 6:
		var a := rng.randf() * TAU
		var rock := Vector3(cos(a) * (LAKE_RADIUS.x + 1.0), 0.1, sin(a) * (LAKE_RADIUS.y + 1.0))
		Props.sphere(self, rng.randf_range(0.25, 0.45), rock, Color("#9aa3ad"), 8, 4, Vector3(1.3, 0.6, 1.0))
	for i in 22:
		var a := rng.randf() * TAU
		var r := rng.randf_range(1.45, 2.1)
		var spot := Vector3(cos(a) * LAKE_RADIUS.x * r, 0.0, sin(a) * LAKE_RADIUS.y * r)
		# İskelenin önünü (kameraya yakın taraf) kapatmasın.
		if spot.z > 0.0 and absf(spot.x) < 5.0:
			continue
		var size := rng.randf_range(0.8, 1.3)
		Props.cylinder(self, 0.12 * size, 0.16 * size, 0.9 * size, spot + Vector3(0.0, 0.45 * size, 0.0), WOOD_DARK, 6)
		Props.cylinder(self, 0.0, 0.9 * size, 2.2 * size, spot + Vector3(0.0, 1.9 * size, 0.0), Color("#3f8f4a"), 7)


func _disc(radius: Vector2, y: float, color: Color, roughness: float) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 1.0
	mesh.bottom_radius = 1.0
	mesh.height = 0.02
	mesh.radial_segments = 64
	mesh.rings = 1
	var node := MeshInstance3D.new()
	node.mesh = mesh
	node.material_override = Props.material(color, roughness)
	node.position = Vector3(0.0, y - 0.01, 0.0)
	node.scale = Vector3(radius.x, 1.0, radius.y)
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(node)


func _build_placeholder_dock() -> void:
	var dock := Props.pivot(self, Vector3.ZERO, "Dock")
	var length := DOCK_FROM - DOCK_TO
	var plank := 0.3
	var count := int(length / (plank + 0.04))
	for i in count:
		var z := DOCK_TO + (float(i) + 0.5) * length / float(count)
		var shade := WOOD if i % 2 == 0 else WOOD.darkened(0.08)
		Props.box(dock, Vector3(DOCK_WIDTH, 0.08, plank), Vector3(0.0, DOCK_HEIGHT, z), shade)
	# Ayaklar.
	var post_z := DOCK_TO + 0.2
	while post_z < DOCK_FROM:
		for side: float in [-1.0, 1.0]:
			Props.cylinder(dock, 0.09, 0.09, 0.9, Vector3(side * (DOCK_WIDTH * 0.5 - 0.08), -0.05, post_z), WOOD_DARK, 6)
		post_z += 1.4


## Şimdilik basit bir balıkçı yer tutucusu (6. adımda KayKit karakteri gelir).
func _build_placeholder_angler() -> void:
	var angler := Props.pivot(self, Vector3(0.0, DOCK_HEIGHT + 0.04, DOCK_TO + 0.5), "Angler")
	Props.capsule(angler, 0.24, 0.95, Vector3(0.0, 0.48, 0.0), Color("#3d8bff"))
	Props.sphere(angler, 0.21, Vector3(0.0, 1.16, 0.0), Color("#f2c7a5"))
	Props.cylinder(angler, 0.16, 0.3, 0.16, Vector3(0.0, 1.36, 0.0), Color("#f4d35e"), 10)
	# Olta: ileri ve yukarı eğik ince çubuk, ucunda kırmızı-beyaz şamandıra suda.
	Props.cylinder(angler, 0.012, 0.025, 2.2, Vector3(0.25, 1.15, -0.85), WOOD_DARK, 5,
			Vector3(deg_to_rad(-62.0), 0.0, 0.0))
	var bobber := Vector3(0.25, 0.08, DOCK_TO - 3.2)
	Props.sphere(self, 0.11, bobber, Color("#e63946"))
	Props.sphere(self, 0.08, bobber + Vector3(0.0, 0.08, 0.0), Color.WHITE)


# --- Arayüz ----------------------------------------------------------------------

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	hud = Hud.new()
	layer.add_child(hud)
	settings_panel = SettingsPanel.new()
	layer.add_child(settings_panel)
	hud.settings_pressed.connect(settings_panel.open)
	hud.show_hint("UI_PLACEHOLDER_HINT")
