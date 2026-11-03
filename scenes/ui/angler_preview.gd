class_name AnglerPreview
extends SubViewportContainer
## Balıkçının canlı önizlemesi (Dalga 5: karakter seçimi ve dolap): kendi dünyası olan saydam bir SubViewport'ta
## AnglerBody (görünüş `look`), elinde bambu olta; bekleme animasyonuyla durur, yavaşça sağa sola döner. Yalnızca
## görünürken çizilir. Arka planı çağıranın kartı verir (saydam).

## Kamera: dikey görüş açısı, balıkçıya uzaklık ve baktığı yükseklik (m; balıkçı ~1,45 m).
const FOV := 26.0
const DISTANCE := 4.4
const LOOK_Y := 0.78
## Yavaş dönüş: genlik (radyan) ve hız.
const SWAY := 0.45
const SWAY_SPEED := 0.6
## Kameraya hafif üçte bir dönük duruş (radyan).
const FACING := 0.5
## Olta dik taşınır ama oyundakinden (Angler.CARRY_DIR: öne yatık) farklı olarak yana yatık: önden bakan kamerada
## yüzün önünden geçmesin. Gövdenin uzayında (gövde -z'ye bakar, sağı +x). Boyu kısaltılır: bambu 2,3 m, çerçeveye
## sığmaz (boyun payı).
const CARRY_DIR := Vector3(0.45, 0.9, 0.12)
const ROD_LENGTH := 0.4

var look: String = "girl"

var _viewport: SubViewport
var _world: Node3D
var _pivot: Node3D
var _body: Node3D
var _rod: Node3D
## Oltanın yönü iskelet güncellenince verilir (bir kare geride kalmasın); iskeletsiz yedekte _process'te.
var _synced: bool = false
var _time: float = 0.0


func _init() -> void:
	stretch = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_viewport = SubViewport.new()
	_viewport.transparent_bg = true
	_viewport.own_world_3d = true
	_viewport.msaa_3d = Viewport.MSAA_2X
	_viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	add_child(_viewport)
	_world = Node3D.new()
	_viewport.add_child(_world)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_CLEAR_COLOR
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("#fff4e0")
	env.environment.ambient_light_energy = 0.65
	_world.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.light_energy = 1.05
	_world.add_child(sun)
	sun.rotation = Vector3(deg_to_rad(-40.0), deg_to_rad(35.0), 0.0)
	var camera := Camera3D.new()
	camera.fov = FOV
	_world.add_child(camera)
	camera.look_at_from_position(Vector3(0.0, LOOK_Y + 0.35, DISTANCE), Vector3(0.0, LOOK_Y, 0.0), Vector3.UP)
	camera.current = true
	_pivot = Node3D.new()
	_world.add_child(_pivot)


## Görünüşü kurar ya da değiştirir (girl, boy).
func show_look(kind: String) -> void:
	if kind == look and _body != null:
		return
	look = kind
	if _body != null:
		_pivot.remove_child(_body)
		_body.queue_free()
	_rod = null
	_synced = false
	if AnglerBody.available(kind):
		var body := AnglerBody.new()
		body.look = kind
		_body = body
	else:
		_body = ToyAngler.new()
	# Olta el yuvasına gövde hazır olunca (yuva gövdenin _ready'sinde kurulur; panel kurulurken önizleme henüz
	# ağaçta değil).
	_body.ready.connect(_add_rod.bind(_body), CONNECT_ONE_SHOT)
	_pivot.add_child(_body)


func _add_rod(body: Node3D) -> void:
	var mount := body.get("rod_mount") as Node3D
	if mount == null or body != _body:
		return
	var rod := RodModel.new()
	rod.style = "float"
	mount.add_child(rod)
	_rod = rod
	var skeleton := body.find_child("Skeleton3D", true, false) as Skeleton3D
	if skeleton != null:
		skeleton.skeleton_updated.connect(_carry_rod)
		_synced = true


## Olta gövdeye göre dik ve kısaltılmış (boyu oltanın -Z ekseninde): el yuvası kemikten güncellendikten sonra.
func _carry_rod() -> void:
	if _rod == null or not _rod.is_inside_tree():
		return
	var carry := (_pivot.global_basis * Basis.looking_at(CARRY_DIR.normalized(), Vector3.UP)).orthonormalized()
	_rod.global_basis = carry * Basis.from_scale(Vector3(1.0, 1.0, ROD_LENGTH))


func _process(delta: float) -> void:
	if not is_visible_in_tree() or _body == null:
		return
	_time += delta
	# Gövde -z'ye bakar (AnglerBody): kameraya (+z) çevrilir, üçte bir dönük.
	_pivot.rotation.y = PI + FACING + sin(_time * SWAY_SPEED) * SWAY
	_body.call("animate", delta, 0.0, "free", 0.0)
	if not _synced:
		_carry_rod()
