class_name Villager
extends Node3D
## Köylülerin (Dede, Nine) ortak davranışı. Konuşurken (ipucu değişince, ona dokununca) kameraya,
## yani oyuncuya bakar, başını sallar ve başının üstünde konuşma balonu çıkar; sevinir; bir şeyi
## izler (focus: şamandıra, yaklaşan balıkçı); boşta arada bir sağa sola bakınır.
## Görünüm _make_body()'nin kurduğu gövdedir (KayKit modeli ya da kodla kurulan yedek); gövdeler
## aynı arayüzü taşır: head_point, look_at_point, nod, cheer. Kare başı hareket _process'te.

## Balonun kuyruğu başın bu kadar üstünü (m) ve ekranda bu kadar sağını (viewport birimi)
## gösterir: üstteki balıkçıyı örtmesin.
const BUBBLE_RISE := 0.42
const BUBBLE_SIDE := 34.0
## Balon ekranın alt bu kadarına (oran) düşerse gösterilmez: orada ipucu çubuğu (yüz ve söz) ve
## eylem düğmesi var.
const BUBBLE_FLOOR := 0.72
## Konuşurken ve sevinirken kameraya bakma süresi (sn).
const TALK_LOOK_TIME := 2.6
## Boşta bakınma: aralık (sn) ve en çok açı (radyan).
const GLANCE_EVERY := Vector2(2.5, 5.5)
const GLANCE_ANGLE := 0.9
## Ekranda dokunma payı (viewport yüksekliği 1080'e göre piksel).
const TOUCH_PX := 70.0

## Konuşurken bakılan kamera (main verir).
var camera: Camera3D
## İzlenen nokta (dünya). has_focus false ise boşta bakınır.
var focus := Vector3.ZERO
var has_focus: bool = false
var bubble: SpeechBubble

var _body: Node3D
## Önü (dünya xz; yüzün baktığı yön).
var _facing := Vector2(1.0, 0.0)
var _talk_time: float = -1.0
var _glance := Vector3.ZERO
var _glance_on: bool = false
var _glance_wait: float = 2.0


func _ready() -> void:
	_body = _make_body()
	_body.name = "Body"
	add_child(_body)
	bubble = SpeechBubble.new()
	bubble.name = "Bubble"
	add_child(bubble)


## Görünümü kurar (alt sınıflar: KayKit gövdesi ya da yedek).
func _make_body() -> Node3D:
	return Node3D.new()


## Dokunma çizgisinin alt ucu (dünya): oturak ya da ayak hizası.
func _low_point() -> Vector3:
	return global_position


func head_point() -> Vector3:
	return _body.call("head_point")


## Konuşur: balon (üç nokta), baş sallama, kameraya bakış.
func say() -> void:
	bubble.pop(SpeechBubble.Kind.DOTS)
	_body.call("nod")
	_talk_time = 0.0


## Onaylar: ünlemli balon ve baş sallama.
func approve() -> void:
	bubble.pop(SpeechBubble.Kind.EXCLAIM)
	_body.call("nod")
	_talk_time = 0.0


## Sevinir: kollar havada, ünlemli balon.
func cheer() -> void:
	bubble.pop(SpeechBubble.Kind.EXCLAIM)
	_body.call("cheer")
	_talk_time = 0.0


## Ekrandaki bir nokta köylünün üstünde mi (baş ile alt uç arasındaki çizgiye yakın)? Balon
## sayılmaz: sık çıkar; yürümek ya da atmak için gelen dokunuşu yutmasın.
func hit(view: Camera3D, screen: Vector2) -> bool:
	if not is_visible_in_tree() or view == null:
		return false
	var head := head_point()
	var low := _low_point()
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


## Boşta: arada bir önündekinin bir yanına bakar, sonra yine öne.
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
