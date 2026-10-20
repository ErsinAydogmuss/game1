class_name RodStand
extends Node3D
## Dipte balıkçının yanındaki sehpa (docs/gdd.md §10.3): iki ayaklı ahşap sehpa (kodla, tek ağ),
## üstünde yatan dip kamışı (kuşanılan dip kamışı ve makara: set_rod; zil yeni ucuna taşınır) ve
## ucunda pirinç zil; hepsi gölgesiz. Koklamada
## zil sallanır ve uç seğirir (sniff); koşuda zil durmadan çalar, uç eğilip titrer ve kamışın
## üstünde 2B zil işareti (BellMark) sallanır (set_running). Misina kamışın ucundan çıkar
## (tip_point). Yerel -Z ileri (atış yönü). Kare başı hareket _process'te.

## Kamışın yerden açısı ve sehpanın yerleşimi (balıkçının yanında, atış yönüne doğru). Sandalda
## küpeştede: daha yakın (teknenin yarı genişliği ~0,5 m). Arkaya konan sehpa biraz yana kayar:
## atış yönüne uzanan kamış balıkçının gövdesinden geçmesin.
const RISE := deg_to_rad(26.0)
const SIDE := 0.65
const BOAT_SIDE := 0.3
const BEHIND_SIDE := 0.3
const AHEAD := 0.2
## Kamışın sehpadaki yeri (yerel; dibi arkada) ve kamışın yaslandığı arka destek ile ön çatal (z).
const ROD_AT := Vector3(0, 0.3, 0.42)
const REAR_Z := 0.32
const FRONT_Z := -0.55
const WOOD := Color("#8a5a32")
const BRASS := Color("#d9a441")
## 2B zil işareti kamışın ucunun bu kadar üstünde (m).
const MARK_RISE := 0.35

var rod: RodModel

var _bell: Node3D
var _mark: BellMark
var _twitch: float = 0.0
var _running: bool = false
var _clock: float = 0.0


func _ready() -> void:
	if rod == null:
		build()


## Sehpayı, kamışı ve zili kurar (bir kez; _ready kurar, testler doğrudan çağırabilir).
func build() -> void:
	if rod != null:
		return
	var frame := Node3D.new()
	frame.name = "Frame"
	add_child(frame)
	# Arka destek (kamışın tutamağı yaslanır) ve ön çatal (kamış iki ucun arasında yatar): ince
	# ahşap çubuklar; yükseklikleri kamışın çizgisinden (kamış ikisine de oturur).
	var rear := rest_height(REAR_Z, 0.03) - 0.012
	var front := rest_height(FRONT_Z, 0.026) - 0.012
	for x: float in [-0.08, 0.08]:
		Props.cylinder(frame, 0.012, 0.016, rear, Vector3(x, rear * 0.5, REAR_Z), WOOD, 5, Vector3(0, 0, x * 2.0))
		Props.cylinder(frame, 0.012, 0.016, front, Vector3(x, front * 0.5, FRONT_Z), WOOD, 5, Vector3(0, 0, x * 2.0))
	Props.cylinder(frame, 0.012, 0.012, 0.22, Vector3(0, rear, REAR_Z), WOOD, 5, Vector3(0, 0, deg_to_rad(90.0)))
	Props.cylinder(frame, 0.012, 0.012, 0.22, Vector3(0, front, FRONT_Z), WOOD, 5, Vector3(0, 0, deg_to_rad(90.0)))
	# Ön çatalın iki ucu (kamışın iki yanında).
	for x: float in [-0.06, 0.06]:
		Props.cylinder(frame, 0.008, 0.01, 0.07, Vector3(x, front + 0.047, FRONT_Z), WOOD, 5)
	MeshBatch.merge(frame)
	rod = _make_rod("", "")
	add_child(rod)
	_bell = Node3D.new()
	_bell.name = "Bell"
	rod.tip.add_child(_bell)
	Props.cylinder(_bell, 0.004, 0.004, 0.04, Vector3(0, -0.02, 0), Color("#5b4a3a"), 4)
	Props.sphere(_bell, 0.032, Vector3(0, -0.055, 0), BRASS, 10, 5)
	Props.sphere(_bell, 0.012, Vector3(0, -0.085, 0), BRASS.darkened(0.3), 6, 3)
	# Zilin üç parçası tek ağ (tek çizim; sehpa iskelede de 150 çizimin altında kalsın).
	MeshBatch.merge(_bell)
	for mesh in find_children("*", "GeometryInstance3D", true, false):
		(mesh as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# 3B düğümün görünürlüğü 2B çocuğa geçmez: işaret ayrıca gizlenir (show_stand, set_running).
	_mark = BellMark.new()
	add_child(_mark)
	visible = false


## Sehpadaki kamış kuşanılan dip kamışı ve makarası (RodModel.LOOKS): değiştiyse kamış yeniden
## kurulur, zil yeni ucuna taşınır.
func set_rod(rod_id: String, reel_id: String) -> void:
	if rod == null:
		build()
	if rod.gear_id == rod_id and rod.reel_id == reel_id:
		return
	var old := rod
	rod = _make_rod(rod_id, reel_id)
	_bell.get_parent().remove_child(_bell)
	rod.tip.add_child(_bell)
	remove_child(old)
	old.queue_free()
	add_child(rod)


## Sehpada yatan dip kamışı (kurulmuş; çağıran ekler).
func _make_rod(rod_id: String, reel_id: String) -> RodModel:
	var r := RodModel.new()
	r.name = "Rod"
	r.style = "bottom"
	r.gear_id = rod_id
	r.reel_id = reel_id
	r.build()
	r.position = ROD_AT
	r.rotation = Vector3(RISE, 0, 0)
	return r


## Sehpa görünür ya da kalkar (kalkınca zil de susar).
func show_stand(on: bool) -> void:
	visible = on
	if not on:
		set_running(false)


## Kamışın altının sehpanın z'sindeki yüksekliği (radius: kamışın o noktadaki kalınlığı).
static func rest_height(z: float, radius: float) -> float:
	return ROD_AT.y + (ROD_AT.z - z) * tan(RISE) - radius


## Balıkçının yanına (side m) koyar: atış yönüne (facing, xz) bakar; yanında yer yoksa (kıyı, iskele
## kenarı) öteki yanına, o da yoksa arkasına (önce biraz yana kayık). walkable: o noktada sehpa
## durabilir mi (main verir).
func place(at: Vector3, facing: Vector2, walkable: Callable, side: float = SIDE) -> void:
	var f := facing.normalized() if facing.length_squared() > 0.0001 else Vector2(0, -1)
	var right := Vector2(-f.y, f.x)
	var spot := Vector2(at.x, at.z) + f * AHEAD
	var behind := Vector2(at.x, at.z) - f * SIDE
	var chosen := spot + right * side
	for candidate: Vector2 in [spot + right * side, spot - right * side, behind + right * BEHIND_SIDE,
			behind - right * BEHIND_SIDE, behind]:
		if bool(walkable.call(candidate)):
			chosen = candidate
			break
	position = Vector3(chosen.x, at.y, chosen.y)
	rotation = Vector3(0, atan2(-f.x, -f.y), 0)


## Misinanın çıktığı yer: kamışın ucu.
func tip_point() -> Vector3:
	return rod.tip.global_position


## Koklama: zil bir kez sallanır, uç seğirir.
func sniff() -> void:
	_twitch = 1.0


## Koşu: zil durmadan çalar, uç eğilip titrer, 2B zil işareti çıkar.
func set_running(on: bool) -> void:
	_running = on
	if _mark != null:
		_mark.show_mark(on and visible)


func _process(delta: float) -> void:
	if not visible:
		return
	_clock += delta
	var view := get_viewport().get_camera_3d() if is_inside_tree() else null
	if _mark != null and _mark.visible and view != null:
		var point := tip_point() + Vector3(0, MARK_RISE, 0)
		_mark.anchor = view.unproject_position(point)
		_mark.modulate.a = 0.0 if view.is_position_behind(point) else 1.0
	_twitch = move_toward(_twitch, 0.0, delta * 2.2)
	var swing := 0.0
	if _running:
		rod.bend = 0.42 + 0.08 * sin(_clock * 17.0)
		swing = sin(_clock * 34.0) * 0.7
	else:
		rod.bend = 0.16 * _twitch * absf(sin(_clock * 22.0))
		swing = sin(_clock * 26.0) * 0.6 * _twitch
	_bell.rotation = Vector3(0, 0, swing)
