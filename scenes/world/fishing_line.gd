class_name FishingLine
extends MeshInstance3D
## Misina: oltanın ucundan şamandıraya (ya da çekişmede balığa) kameraya dönük ince şerit.
## Ekranda hep WIDTH_UNITS kalınlıkta görünür (uzaklığa göre genişler). Beklerken sarkar,
## çekişmede gerilir ve gerilimle titrer. Kare çizilmeden hemen önce (frame_pre_draw) yeniden
## kurulur ve uçlar o anda okunur (from_point / to_point): kamera, olta ve şamandıra o karenin
## son yerindedir (main'in _process'i çocuklardan önce çalışır; orada kopyalamak bir kare geç kalır).

const SEGMENTS := 20
## Ekranda kalınlık (viewport birimi; 1080 yükseklik ≈ 1,3 pt telefonda).
const WIDTH_UNITS := 3.6

var camera: Camera3D
## Uçları veren fonksiyonlar (Vector3 döner); verilmezse from / to kullanılır.
var from_point: Callable
var to_point: Callable
var from := Vector3.ZERO
var to := Vector3.ZERO
## Sarkma: 0 = gergin, 1 = boşta (ortası uzunluğun ~%12'si kadar düşer).
var sag: float = 0.35
## Titreme (0..1): gerilim ve patlama.
var shake: float = 0.0

var _mesh := ImmediateMesh.new()
var _clock: float = 0.0


func _ready() -> void:
	mesh = _mesh
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color("#f4f2ea")
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material_override = material
	RenderingServer.frame_pre_draw.connect(_rebuild)


func _exit_tree() -> void:
	if RenderingServer.frame_pre_draw.is_connected(_rebuild):
		RenderingServer.frame_pre_draw.disconnect(_rebuild)


func _process(delta: float) -> void:
	_clock += delta


func _rebuild() -> void:
	_mesh.clear_surfaces()
	if not is_visible_in_tree() or camera == null:
		return
	if from_point.is_valid():
		from = from_point.call()
	if to_point.is_valid():
		to = to_point.call()
	var length := from.distance_to(to)
	if length < 0.05:
		return
	var points := PackedVector3Array()
	var side_dir := (to - from).cross(Vector3.UP).normalized()
	for i in SEGMENTS + 1:
		var t := float(i) / SEGMENTS
		var p := from.lerp(to, t)
		var bell := 4.0 * t * (1.0 - t)
		p.y -= sag * length * 0.12 * bell
		if shake > 0.0:
			p += side_dir * sin(_clock * 43.0 + t * 11.0) * shake * 0.035 * bell
			p.y += cos(_clock * 37.0 + t * 9.0) * shake * 0.02 * bell
		points.append(p)
	var viewport_h := camera.get_viewport().get_visible_rect().size.y
	var px_world := 2.0 * tan(deg_to_rad(camera.fov) * 0.5) / maxf(viewport_h, 1.0)
	var eye := camera.global_position
	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for i in points.size():
		var p := points[i]
		var a := points[maxi(i - 1, 0)]
		var b := points[mini(i + 1, points.size() - 1)]
		var tangent := (b - a).normalized()
		var view := (eye - p).normalized()
		var side := tangent.cross(view).normalized() * (WIDTH_UNITS * 0.5 * px_world * eye.distance_to(p))
		_mesh.surface_add_vertex(p - side)
		_mesh.surface_add_vertex(p + side)
	_mesh.surface_end()
