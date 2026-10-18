class_name RodStand
extends Node3D
## Dipte balıkçının yanındaki sehpa (docs/gdd.md §10.3): iki ayaklı ahşap sehpa (kodla, tek ağ),
## üstünde yatan dip kamışı (RodModel "bottom") ve ucunda pirinç zil; hepsi gölgesiz. Koklamada
## zil sallanır ve uç seğirir (sniff); koşuda zil durmadan çalar, uç eğilip titrer ve kamışın
## üstünde 2B zil işareti (BellMark) sallanır (set_running). Misina kamışın ucundan çıkar
## (tip_point). Yerel -Z ileri (atış yönü). Kare başı hareket _process'te.

## Kamışın yerden açısı ve sehpanın yerleşimi (balıkçının yanında, atış yönüne doğru).
const RISE := deg_to_rad(26.0)
const SIDE := 0.65
const AHEAD := 0.2
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
	var frame := Node3D.new()
	frame.name = "Frame"
	add_child(frame)
	# Arka ayak (kamışın dibi yaslanır) ve ön çatal (kamış üstünde yatar): ince ahşap çubuklar.
	for x: float in [-0.08, 0.08]:
		Props.cylinder(frame, 0.012, 0.016, 0.26, Vector3(x, 0.13, 0.32), WOOD, 5, Vector3(0, 0, x * 2.0))
		Props.cylinder(frame, 0.012, 0.016, 0.62, Vector3(x, 0.31, -0.55), WOOD, 5, Vector3(0, 0, x * 2.0))
	Props.cylinder(frame, 0.012, 0.012, 0.22, Vector3(0, 0.26, 0.32), WOOD, 5, Vector3(0, 0, deg_to_rad(90.0)))
	Props.cylinder(frame, 0.012, 0.012, 0.22, Vector3(0, 0.61, -0.55), WOOD, 5, Vector3(0, 0, deg_to_rad(90.0)))
	# Ön çatalın iki ucu.
	for x: float in [-0.06, 0.06]:
		Props.cylinder(frame, 0.008, 0.01, 0.07, Vector3(x, 0.65, -0.55), WOOD, 5)
	MeshBatch.merge(frame)
	rod = RodModel.new()
	rod.name = "Rod"
	rod.style = "bottom"
	add_child(rod)
	rod.position = Vector3(0, 0.3, 0.42)
	rod.rotation = Vector3(RISE, 0, 0)
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


## Sehpa görünür ya da kalkar (kalkınca zil de susar).
func show_stand(on: bool) -> void:
	visible = on
	if not on:
		set_running(false)


## Balıkçının yanına koyar: atış yönüne (facing, xz) bakar; yanında yer yoksa (kıyı, iskele kenarı)
## öteki yanına, o da yoksa arkasına. walkable: o noktada sehpa durabilir mi (main verir).
func place(at: Vector3, facing: Vector2, walkable: Callable) -> void:
	var f := facing.normalized() if facing.length_squared() > 0.0001 else Vector2(0, -1)
	var right := Vector2(-f.y, f.x)
	var spot := Vector2(at.x, at.z) + f * AHEAD
	var chosen := spot + right * SIDE
	for candidate: Vector2 in [spot + right * SIDE, spot - right * SIDE, Vector2(at.x, at.z) - f * SIDE]:
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
