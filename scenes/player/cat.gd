class_name Cat
extends Node3D
## Tekir (Dalga 5, 2. adım; docs/gdd.md §7): iskelenin kedisi. main her kare nereye gideceğini söyler
## (go_to): iskele koyunda balıkçının biraz arkası, balıkçı başka bölgede ya da sandaldayken evi (iskelenin
## başı). Kıyı yolundan (ShorePath) yürür, uzaktaysa koşar; varınca balıkçıya döner ve bekler. Dokununca
## mırlar (kalpli balon, sıçrayış); acıkınca arada bir balıklı balon çıkar (CatRules; ceza yok). Gövde CatBody
## (Quaternius kedisi) ya da yedek ToyCat; tek çizim, gölgesiz. Kare başı hareket _process'te.

## Yürüme ve koşma hızı (m/sn); hedefe RUN_FROM'dan uzaksa koşar.
const SPEED := 1.25
const RUN_SPEED := 2.7
const RUN_FROM := 2.5
## Hedefe bu kadar yaklaşınca durur; hedef bu kadar kayınca yol yeniden çizilir.
const ARRIVE := 0.2
const REPATH := 0.5
## Dönme hızı (radyan/sn).
const TURN_RATE := 9.0
## Açken balıklı balon her HUNGRY_EVERY sn'de HUNGRY_HOLD sn görünür (geçici: çizim bütçesi).
const HUNGRY_EVERY := 9.0
const HUNGRY_HOLD := 3.0
## Mırlamada ve yemekte kalpli balonun süresi (sn).
const HEART_HOLD := 1.6
## Ekranda dokunma payı (viewport yüksekliği 1080'e göre piksel; gövdenin ortasından).
const TOUCH_PX := 58.0
## Balon başın bu kadar üstünü (m) gösterir; ekranın alt payına düşerse gösterilmez (ipucu çubuğu).
const BUBBLE_RISE := 0.12
const BUBBLE_FLOOR := 0.72

## Kıyı yolu, göl ve zemin yüksekliği (main verir).
var path: ShorePath
var height_at: Callable
var camera: Camera3D
var bubble: SpeechBubble
## Acıktı mı (main her kare verir: CatRules.is_hungry).
var hungry: bool = false

var _body: Node3D
var _target := Dice.NO_POINT
var _route := PackedVector2Array()
var _route_goal := Dice.NO_POINT
## Son aranan yol hedefe varmıyor (yarıda bitiyor): hedef REPATH'ten çok kaymadıkça yeniden aranmaz.
var _partial: bool = false
## Yüzün yönü (dünya xz) ve varınca bakılacak nokta.
var _facing := Vector2(1.0, 0.0)
var _look := Dice.NO_POINT
var _speed: float = 0.0
var _hungry_clock: float = 0.0


func _ready() -> void:
	_body = CatBody.new() if CatBody.available() else ToyCat.new()
	_body.name = "Body"
	add_child(_body)
	bubble = SpeechBubble.new()
	bubble.name = "Bubble"
	add_child(bubble)


## Hemen bir yere koyar (oturum başı, geçiş): yol unutulur.
func place(p: Vector2, facing: Vector2 = Vector2.ZERO) -> void:
	_route = PackedVector2Array()
	_route_goal = Dice.NO_POINT
	_target = p
	_speed = 0.0
	if facing.length() > 0.01:
		_facing = facing.normalized()
	position = Vector3(p.x, _height(p), p.y)
	_apply_facing()


## Gideceği yer (dünya xz) ve varınca bakacağı nokta (main her kare).
func go_to(target: Vector2, look: Vector2 = Dice.NO_POINT) -> void:
	_target = target
	_look = look


func pos2() -> Vector2:
	return Vector2(position.x, position.z)


func facing() -> Vector2:
	return _facing


func is_walking() -> bool:
	return _speed > 0.05


## Başın üstü (dünya).
func head_point() -> Vector3:
	return _body.call("head_point")


## Mırlar: kalpli balon ve sıçrayış (sesi ve titreşimi main verir).
func purr() -> void:
	bubble.pop(SpeechBubble.Kind.HEART, HEART_HOLD)
	_body.call("hop")


## Yer: kalpli balon biraz uzun, sıçrayış.
func eat() -> void:
	bubble.pop(SpeechBubble.Kind.HEART, HEART_HOLD * 1.5)
	_body.call("hop")
	_hungry_clock = 0.0


## Ekrandaki bir nokta kedinin üstünde mi (gövdenin ortası ile başı arasındaki çizgiye yakın)?
func hit(view: Camera3D, screen: Vector2) -> bool:
	if not is_visible_in_tree() or view == null:
		return false
	var low := global_position + Vector3(0.0, 0.12, 0.0)
	var high := head_point()
	if view.is_position_behind(low) or view.is_position_behind(high):
		return false
	var a := view.unproject_position(low)
	var b := view.unproject_position(high)
	var pad := TOUCH_PX * view.get_viewport().get_visible_rect().size.y / 1080.0
	return Geometry2D.get_closest_point_to_segment(screen, a, b).distance_to(screen) <= pad


func _process(delta: float) -> void:
	_walk(delta)
	_body.call("set_motion", _speed)
	_update_bubble(delta)


func _walk(delta: float) -> void:
	_speed = 0.0
	if not Dice.is_point(_target) or path == null:
		return
	var here := pos2()
	if here.distance_to(_target) <= ARRIVE:
		_route = PackedVector2Array()
		_turn_to(_look, delta)
		return
	if _route.is_empty() or not Dice.is_point(_route_goal) or _route_goal.distance_to(_target) > REPATH:
		if _route.is_empty() and _partial and Dice.is_point(_route_goal) and _route_goal.distance_to(_target) <= REPATH:
			# Hedefe yol yok (kapalı çitin ardı): yolun ucunda bekler; hedef kaymadıkça yeniden aramaz (her karede
			# arama bütün yürünebilen alanı tarardı).
			_turn_to(_look, delta)
			return
		_route = path.route(here, _target)
		_route_goal = _target
		_partial = _route.is_empty() or _route[_route.size() - 1].distance_to(_target) > ARRIVE
		if _route.is_empty():
			return
	var left := ShorePath.length_of(here, _route)
	var speed := RUN_SPEED if left > RUN_FROM else SPEED
	var step := speed * delta
	var p := here
	while step > 0.0 and not _route.is_empty():
		var next := _route[0]
		var d := p.distance_to(next)
		if d <= step:
			p = next
			step -= d
			_route.remove_at(0)
		else:
			p = p + (next - p) / d * step
			step = 0.0
	var moved := p - here
	if moved.length() > 0.0001:
		_speed = speed
		_turn_toward(moved.normalized(), delta)
	position = Vector3(p.x, _height(p), p.y)


## Varınca bakılacak noktaya döner (yoksa olduğu gibi).
func _turn_to(look: Vector2, delta: float) -> void:
	if not Dice.is_point(look):
		return
	var dir := look - pos2()
	if dir.length() > 0.05:
		_turn_toward(dir.normalized(), delta)


func _turn_toward(dir: Vector2, delta: float) -> void:
	var from := atan2(_facing.y, _facing.x)
	var to := atan2(dir.y, dir.x)
	var angle := from + clampf(wrapf(to - from, -PI, PI), -TURN_RATE * delta, TURN_RATE * delta)
	_facing = Vector2(cos(angle), sin(angle))
	_apply_facing()


## Model +X'e bakar: dünyadaki yön (x, z) için y ekseninde dönüş.
func _apply_facing() -> void:
	rotation = Vector3(0.0, atan2(-_facing.y, _facing.x), 0.0)


func _height(p: Vector2) -> float:
	return float(height_at.call(p)) if height_at.is_valid() else 0.0


## Açken arada bir balıklı balon; balonun yeri her kare başın üstü (ekranın alt payında gizli).
func _update_bubble(delta: float) -> void:
	if hungry and not bubble.is_showing():
		_hungry_clock += delta
		if _hungry_clock >= HUNGRY_EVERY:
			_hungry_clock = 0.0
			bubble.pop(SpeechBubble.Kind.FISH, HUNGRY_HOLD)
	elif not hungry:
		_hungry_clock = HUNGRY_EVERY - 1.0
	if camera == null or not bubble.is_showing():
		return
	var top := head_point() + Vector3(0.0, BUBBLE_RISE, 0.0)
	var screen := camera.unproject_position(top)
	var view := camera.get_viewport().get_visible_rect().size
	bubble.anchor = screen
	bubble.modulate.a = 0.0 if camera.is_position_behind(top) or screen.y > view.y * BUBBLE_FLOOR else 1.0
