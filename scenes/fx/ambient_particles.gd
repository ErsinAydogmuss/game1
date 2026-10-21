class_name AmbientParticles
extends CPUParticles3D
## Gölün havası ve gecesi (Dalga 4): yağmur damlaları ya da ateşböcekleri (ileride gündüz kelebekler).
## Tek CPUParticles3D: tek çizim (iskelede 150 çizim sınırı); aynı anda tek tür. Kameranın baktığı yerin
## çevresinde: main her kare follow ile taşır. Parçacıklar dünyada kalır (local_coords kapalı): taşınınca
## düşen damla kaymaz. Görsel; oynanışı etkilemez.

## Türler: "" (yok), "rain", "fireflies".
const KINDS: Array[String] = ["", "rain", "fireflies"]
## Yağmur: damla sayısı, kutunun yarı boyu (m) ve yüksekliği, düşüş hızı (m/sn).
const RAIN_AMOUNT := 260
const RAIN_BOX := Vector3(11.0, 0.1, 9.0)
const RAIN_HEIGHT := 7.0
const RAIN_SPEED := 10.0
## Ateşböceği: sayı, kutunun yarı boyu ve yerden yüksekliği (m).
const FIREFLY_AMOUNT := 28
const FIREFLY_BOX := Vector3(9.0, 0.5, 7.0)
const FIREFLY_HEIGHT := 0.9

var kind: String = ""
var _height: float = 0.0


func _init() -> void:
	local_coords = false
	emitting = false
	visible = false
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## Türü değiştirir ("" kapatır). Aynı türde bir şey yapmaz (yağan yağmur baştan başlamasın).
func set_kind(value: String) -> void:
	if value == kind:
		return
	kind = value
	emitting = false
	match kind:
		"rain":
			_rain()
		"fireflies":
			_fireflies()
	visible = not kind.is_empty()
	if visible:
		restart()
		emitting = true


## Kameranın baktığı yer (yerin hizasında): parçacıklar onun çevresinde doğar.
func follow(point: Vector3) -> void:
	global_position = Vector3(point.x, point.y + _height, point.z)


func _rain() -> void:
	_height = RAIN_HEIGHT
	amount = RAIN_AMOUNT
	lifetime = (RAIN_HEIGHT + 1.0) / RAIN_SPEED
	preprocess = lifetime
	explosiveness = 0.0
	randomness = 0.5
	emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	emission_box_extents = RAIN_BOX
	direction = Vector3(0.1, -1.0, 0.05)
	spread = 3.0
	gravity = Vector3.ZERO
	initial_velocity_min = RAIN_SPEED * 0.9
	initial_velocity_max = RAIN_SPEED * 1.1
	scale_amount_min = 0.8
	scale_amount_max = 1.2
	color_ramp = null
	var quad := QuadMesh.new()
	quad.size = Vector2(0.025, 0.5)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
	material.albedo_color = Color(0.82, 0.88, 0.96, 0.45)
	material.disable_receive_shadows = true
	quad.material = material
	mesh = quad


func _fireflies() -> void:
	_height = FIREFLY_HEIGHT
	amount = FIREFLY_AMOUNT
	lifetime = 5.0
	preprocess = lifetime
	explosiveness = 0.0
	randomness = 0.8
	emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	emission_box_extents = FIREFLY_BOX
	direction = Vector3(1.0, 0.2, 0.0)
	spread = 180.0
	gravity = Vector3.ZERO
	initial_velocity_min = 0.08
	initial_velocity_max = 0.3
	scale_amount_min = 0.7
	scale_amount_max = 1.3
	# Yanıp söner: iki kez parlar.
	var ramp := Gradient.new()
	ramp.offsets = PackedFloat32Array([0.0, 0.15, 0.35, 0.5, 0.7, 1.0])
	ramp.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 1), Color(1, 1, 1, 0.15), Color(1, 1, 1, 0.9),
			Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	color_ramp = ramp
	var sphere := SphereMesh.new()
	sphere.radius = 0.04
	sphere.height = 0.08
	sphere.radial_segments = 8
	sphere.rings = 4
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = true
	# Parlak (HDR): ortamın parlaması (glow) ateşböceğinin çevresini aydınlatır.
	material.albedo_color = Color(2.2, 2.4, 1.0, 1.0)
	material.disable_receive_shadows = true
	sphere.material = material
	mesh = sphere
