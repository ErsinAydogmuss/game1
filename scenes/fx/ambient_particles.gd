class_name AmbientParticles
extends CPUParticles3D
## Gölün havası ve gecesi (Dalga 4): yağmur damlaları, ateşböcekleri ya da gündüz kelebekler (göl sevgisi).
## Tek CPUParticles3D: tek çizim (iskelede 150 çizim sınırı); aynı anda tek tür. Kameranın baktığı yerin
## çevresinde: main her kare follow ile taşır. Parçacıklar dünyada kalır (local_coords kapalı): taşınınca
## düşen damla kaymaz. Görsel; oynanışı etkilemez.

## Türler: "" (yok), "rain", "fireflies", "butterflies".
const KINDS: Array[String] = ["", "rain", "fireflies", "butterflies"]
## Yağmur: damla sayısı, kutunun yarı boyu (m) ve yüksekliği, düşüş hızı (m/sn).
const RAIN_AMOUNT := 260
const RAIN_BOX := Vector3(11.0, 0.1, 9.0)
const RAIN_HEIGHT := 7.0
const RAIN_SPEED := 10.0
## Ateşböceği: sayı, kutunun yarı boyu ve yerden yüksekliği (m).
const FIREFLY_AMOUNT := 28
const FIREFLY_BOX := Vector3(9.0, 0.5, 7.0)
const FIREFLY_HEIGHT := 0.9
## Kelebek: sayı, kutunun yarı boyu ve yerden yüksekliği (m), ömrü boyunca kanat çırpışı, kanadın yarı
## eni ve boyu (m), renkleri (her kelebek birini alır).
const BUTTERFLY_AMOUNT := 12
const BUTTERFLY_BOX := Vector3(8.0, 0.35, 6.0)
const BUTTERFLY_HEIGHT := 0.8
const BUTTERFLY_FLAPS := 16
const BUTTERFLY_WING := Vector2(0.16, 0.13)
const BUTTERFLY_COLORS: Array[Color] = [Color("#ffd54a"), Color("#fbf7ee"), Color("#ff9f43"), Color("#7ec8f2"),
		Color("#f7a8c8")]

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
		"butterflies":
			_butterflies()
	visible = not kind.is_empty()
	if visible:
		restart()
		emitting = true


## Kameranın baktığı yer (yerin hizasında): parçacıklar onun çevresinde doğar.
func follow(point: Vector3) -> void:
	global_position = Vector3(point.x, point.y + _height, point.z)


func _rain() -> void:
	split_scale = false
	color_initial_ramp = null
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
	split_scale = false
	color_initial_ramp = null
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


## Kelebekler (gündüz, göl sevgisi 3'ten sonra): yavaşça dolaşan, kanat çırpan renkli kelebekler. Kanatlar yatay
## (kamera yukarıdan bakar); çırpış kanadın eninin ömür boyunca daralıp açılması (split_scale).
func _butterflies() -> void:
	_height = BUTTERFLY_HEIGHT
	amount = BUTTERFLY_AMOUNT
	lifetime = 7.0
	preprocess = lifetime
	explosiveness = 0.0
	randomness = 0.6
	emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	emission_box_extents = BUTTERFLY_BOX
	direction = Vector3(1.0, 0.1, 0.0)
	spread = 180.0
	gravity = Vector3.ZERO
	initial_velocity_min = 0.25
	initial_velocity_max = 0.55
	scale_amount_min = 0.8
	scale_amount_max = 1.2
	split_scale = true
	var flap := Curve.new()
	for i in BUTTERFLY_FLAPS * 2 + 1:
		flap.add_point(Vector2(float(i) / (BUTTERFLY_FLAPS * 2), 1.0 if i % 2 == 0 else 0.2))
	scale_curve_x = flap
	scale_curve_y = _flat_curve()
	scale_curve_z = _flat_curve()
	# Her kelebek bir renk (sabit geçişli ramp: karışık renk çıkmaz); doğarken ve ölürken saydam.
	var colors := Gradient.new()
	colors.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	var offsets := PackedFloat32Array()
	var palette := PackedColorArray()
	for i in BUTTERFLY_COLORS.size():
		offsets.append(float(i) / BUTTERFLY_COLORS.size())
		palette.append(BUTTERFLY_COLORS[i])
	colors.offsets = offsets
	colors.colors = palette
	color_initial_ramp = colors
	var fade := Gradient.new()
	fade.offsets = PackedFloat32Array([0.0, 0.1, 0.9, 1.0])
	fade.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 1), Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	color_ramp = fade
	mesh = _butterfly_mesh()


static func _flat_curve() -> Curve:
	var curve := Curve.new()
	curve.add_point(Vector2(0.0, 1.0))
	curve.add_point(Vector2(1.0, 1.0))
	return curve


## Kelebeğin ağı: yatay iki kanat (önde büyük, arkada küçük; beyaz: rengi parçacıktan) ve ince koyu gövde.
static func _butterfly_mesh() -> ArrayMesh:
	var w := BUTTERFLY_WING
	var verts := PackedVector3Array()
	var colors := PackedColorArray()
	for side: float in [-1.0, 1.0]:
		var root := Vector3(0.0, 0.0, 0.0)
		var tip := Vector3(side * w.x, 0.0, -w.y)
		var edge := Vector3(side * w.x * 0.95, 0.0, w.y * 0.15)
		var tail := Vector3(side * w.x * 0.6, 0.0, w.y * 0.85)
		for p: Vector3 in [root, tip, edge, root, edge, tail]:
			verts.append(p)
			colors.append(Color.WHITE)
	var body := Color(0.22, 0.15, 0.1)
	var half := w.x * 0.08
	for p: Vector3 in [Vector3(-half, 0.002, -w.y * 0.5), Vector3(half, 0.002, -w.y * 0.5), Vector3(half, 0.002, w.y * 0.6),
			Vector3(-half, 0.002, -w.y * 0.5), Vector3(half, 0.002, w.y * 0.6), Vector3(-half, 0.002, w.y * 0.6)]:
		verts.append(p)
		colors.append(body)
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_COLOR] = colors
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.disable_receive_shadows = true
	mesh.surface_set_material(0, material)
	return mesh
