class_name Elder
extends Node3D
## Dede: iskelenin kenarında oturur, bacakları suya sarkar; yanında çay bardağı. Kameraya dönük
## oturur ki yüzü görünsün. Konuşurken (ipucu değişince, ona dokununca) kameraya, yani oyuncuya
## bakar, başını sallar ve başının üstünde konuşma balonu çıkar. Balık tutulunca oturduğu yerde
## sevinir. Olta sudayken şamandırayı izler (focus); boşta gölde arada bir sağa sola bakınır.
## Görünüm ElderBody (KayKit Barbarian) ya da yedek ToyElder; ikisi aynı arayüzü taşır.
## Kare başı hareket _process'te.

## Dede'ye dokununca sırayla söylediği öğütler: çeviri anahtarı ve sayısı (strings.csv).
const TIP_KEY := "UI_DEDE_TIP_%d"
const TIP_COUNT := 6
## Balonun kuyruğu başın bu kadar üstünü (m) ve ekranda bu kadar sağını (viewport birimi)
## gösterir: üstteki balıkçıyı örtmesin.
const BUBBLE_RISE := 0.42
const BUBBLE_SIDE := 34.0
## Balon ekranın alt bu kadarına (oran) düşerse gösterilmez: orada ipucu çubuğu (Dede'nin yüzü ve
## sözü) ve eylem düğmesi var.
const BUBBLE_FLOOR := 0.72
## Konuşurken ve sevinirken kameraya bakma süresi (sn).
const TALK_LOOK_TIME := 2.6
## Boşta bakınma: aralık (sn) ve en çok açı (radyan).
const GLANCE_EVERY := Vector2(2.5, 5.5)
const GLANCE_ANGLE := 0.9
## Ekranda dokunma payı (viewport yüksekliği 1080'e göre piksel).
const TOUCH_PX := 70.0
## Yürüme engeli: oturma noktasından içeri doğru gövdenin ortası ve yarıçapı (m).
const BODY_INSET := 0.15
const BODY_RADIUS := 0.25
const TEA := Color("#b5481c")
const GLASS := Color("#f3e7d0")
const SAUCER := Color("#f6f3ec")

## true ise KayKit modeli olsa bile kodla kurulan model kullanılır (testler).
static var force_toy: bool = false

## Bu Dede için yedek model (karakter sayfası karşılaştırması); _ready'den önce verilir.
var use_toy: bool = false

## Konuşurken bakılan kamera (main verir).
var camera: Camera3D
## İzlenen nokta (dünya; ör. şamandıra). has_focus false ise boşta bakınır.
var focus := Vector3.ZERO
var has_focus: bool = false
var bubble: SpeechBubble

var _body: Node3D
var _seat := Vector3.ZERO
var _facing := Vector2(1.0, 0.0)
var _talk_time: float = -1.0
var _glance := Vector3.ZERO
var _glance_on: bool = false
var _glance_wait: float = 2.0


func _ready() -> void:
	if ElderBody.available() and not force_toy and not use_toy:
		_body = ElderBody.new()
	else:
		_body = ToyElder.new()
	_body.name = "Body"
	add_child(_body)
	bubble = SpeechBubble.new()
	bubble.name = "Bubble"
	add_child(bubble)


## KayKit modeli mi kullanılıyor?
func is_rigged() -> bool:
	return _body is ElderBody


## Oturtur: edge iskelenin kenarındaki nokta (dünya xz), facing dışa doğru (suya), deck_y güverte.
## Oturma noktası (diz arkası) kenara gelir; bacaklar dışarı sarkar. Yanına çay bardağı konur.
func seat(edge: Vector2, facing: Vector2, deck_y: float) -> void:
	_facing = facing.normalized()
	rotation = Vector3(0.0, atan2(_facing.x, _facing.y), 0.0)
	var offset: Vector3 = _body.call("seat_offset")
	_seat = Vector3(edge.x, deck_y, edge.y)
	position = _seat - basis * offset
	_add_tea()


## Balıkçının giremeyeceği daire: Vector3(x, z, yarıçap) (Angler.blockers).
func blocker() -> Vector3:
	var c := Vector2(_seat.x, _seat.z) - _facing * BODY_INSET
	return Vector3(c.x, c.y, BODY_RADIUS)


func head_point() -> Vector3:
	return _body.call("head_point")


## Konuşur: balon (üç nokta), baş sallama, kameraya bakış.
func say() -> void:
	bubble.pop(SpeechBubble.Kind.DOTS)
	_body.call("nod")
	_talk_time = 0.0


## Onaylar (sıradan bir balık): ünlemli balon ve baş sallama.
func approve() -> void:
	bubble.pop(SpeechBubble.Kind.EXCLAIM)
	_body.call("nod")
	_talk_time = 0.0


## Oturduğu yerde sevinir: kollar havada, ünlemli balon.
func cheer() -> void:
	bubble.pop(SpeechBubble.Kind.EXCLAIM)
	_body.call("cheer")
	_talk_time = 0.0


## Ekrandaki bir nokta Dede'nin üstünde mi (baş ile oturak arasındaki çizgiye yakın)?
func hit(view: Camera3D, screen: Vector2) -> bool:
	if not is_visible_in_tree() or view == null:
		return false
	var head := head_point()
	var low := _seat + Vector3(0.0, 0.1, 0.0)
	if view.is_position_behind(head) or view.is_position_behind(low):
		return false
	var a := view.unproject_position(head)
	var b := view.unproject_position(low)
	var scale := view.get_viewport().get_visible_rect().size.y / 1080.0
	var radius := maxf(TOUCH_PX * scale, a.distance_to(b) * 0.55)
	return Geometry2D.get_closest_point_to_segment(screen, a, b).distance_to(screen) <= radius


func _process(delta: float) -> void:
	var target := Vector3.ZERO
	var has := false
	if _talk_time >= 0.0:
		_talk_time += delta
		if _talk_time > TALK_LOOK_TIME:
			_talk_time = -1.0
	if _talk_time >= 0.0 and camera != null:
		target = camera.global_position
		has = true
	elif has_focus:
		target = focus
		has = true
	else:
		_update_glance(delta)
		target = _glance
		has = _glance_on
	_body.call("look_at_point", target, has)
	_place_bubble()


## Balon 2B bir arayüz parçası: başın ekrandaki yerine taşınır; kamera arkasındaysa gizlenir.
func _place_bubble() -> void:
	if not bubble.is_showing():
		return
	var view := get_viewport().get_camera_3d()
	var point := head_point() + Vector3(0.0, BUBBLE_RISE, 0.0)
	if view == null or view.is_position_behind(point):
		bubble.modulate.a = 0.0
		return
	var anchor := view.unproject_position(point) + Vector2(BUBBLE_SIDE, 0.0)
	var rect := get_viewport().get_visible_rect()
	var shown := anchor.y < rect.size.y * BUBBLE_FLOOR and anchor.x > 0.0 and anchor.x < rect.size.x
	bubble.modulate.a = 1.0 if shown else 0.0
	bubble.anchor = anchor


## Boşta: arada bir gölün bir yanına bakar, sonra yine öne.
func _update_glance(delta: float) -> void:
	_glance_wait -= delta
	if _glance_wait > 0.0:
		return
	_glance_wait = randf_range(GLANCE_EVERY.x, GLANCE_EVERY.y)
	_glance_on = not _glance_on and randf() < 0.7
	if _glance_on:
		var angle := randf_range(-GLANCE_ANGLE, GLANCE_ANGLE)
		var dir := Vector3(_facing.x, 0.0, _facing.y).rotated(Vector3.UP, angle)
		_glance = head_point() + dir * 4.0 + Vector3(0.0, -0.6, 0.0)


## Yanında, güvertede ince belli çay bardağı ve tabağı (sağ yanında, kenardan içeride). Oyun
## ölçeğinde okunsun diye gerçeğinden iri.
func _add_tea() -> void:
	var tea := Props.pivot(self, Vector3.ZERO, "Tea")
	tea.global_position = _seat + global_basis * Vector3(-0.3, 0.0, -0.25)
	tea.scale = Vector3.ONE * 1.5
	Props.cylinder(tea, 0.075, 0.07, 0.014, Vector3(0, 0.007, 0), SAUCER, 14)
	Props.cylinder(tea, 0.03, 0.038, 0.05, Vector3(0, 0.039, 0), TEA, 10)
	Props.cylinder(tea, 0.044, 0.03, 0.06, Vector3(0, 0.094, 0), TEA, 10)
	Props.cylinder(tea, 0.046, 0.046, 0.012, Vector3(0, 0.127, 0), GLASS, 10)
