class_name SpeechBubble
extends Control
## Konuşma balonu (2B): ekranda Dede'nin başının üstünde; içinde üç nokta (konuşuyor) ya da ünlem; Tekir'in
## balonunda balık (acıktı) ya da kalp (mırlıyor, yedi).
## 3B sahnenin sisi ve ton eşlemesi onu grileştirmesin diye arayüz gibi çizilir; yakınlaşmada da
## aynı boyda kalır. pop() ile hafifçe taşarak büyür, HOLD_TIME sn durur, küçülerek kaybolur.
## Kuyruğun ucu anchor'a (viewport noktası) gelir. Kare başı hareket _process'te.

enum Kind { DOTS, EXCLAIM, FISH, HEART }

const BODY := Vector2(104, 68)
const RADIUS := 32
const TAIL := 24.0
const OUTLINE := 5.0
const GROW_TIME := 0.25
const HOLD_TIME := 2.0
const SHRINK_TIME := 0.2
const FILL := Color("#fffaf0")
const INK := Color("#2b1a10")
const FISH_COLOR := Color("#f2994a")
const HEART_COLOR := Color("#e5484d")
## Arayüz kitinin balon görseliyle çizilirken boyu (kuyruk altta, ortada).
const ART_SIZE := Vector2(126, 95)
## Görselde kuyruğun ucu (genişliğe oranla) ve gövdenin ortası (yüksekliğe oranla).
const ART_TIP_X := 0.49
const ART_BODY_Y := 0.37
## Görselli balonda işaretin boy çarpanı.
const ART_MARK := 0.82

## Kuyruğun ucunun ekrandaki yeri (viewport birimi); Elder her kare verir.
var anchor := Vector2.ZERO
var kind: Kind = Kind.DOTS

var _time: float = -1.0
## Bu açılıştaki duruş süresi (pop verir; varsayılan HOLD_TIME).
var _hold: float = HOLD_TIME
var _fill := StyleBoxFlat.new()
var _edge := StyleBoxFlat.new()
## Arayüz kitinin balonu (yoksa kodla çizilir).
var _art: Texture2D


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_art = ItemArt.frame("bubble")
	size = ART_SIZE if _art != null else BODY + Vector2(0.0, TAIL)
	pivot_offset = _tip()
	visible = false
	_fill.bg_color = FILL
	_edge.bg_color = INK
	for box: StyleBoxFlat in [_fill, _edge]:
		box.set_corner_radius_all(RADIUS)
		box.anti_aliasing = true
	_edge.set_expand_margin_all(OUTLINE)


func pop(new_kind: Kind, hold: float = HOLD_TIME) -> void:
	kind = new_kind
	_hold = hold
	_time = 0.0
	scale = Vector2.ZERO
	visible = true


func is_showing() -> bool:
	return _time >= 0.0


func _process(delta: float) -> void:
	if _time < 0.0:
		return
	_time += delta
	var grow := 1.0
	if _time < GROW_TIME:
		grow = back_out(_time / GROW_TIME)
	elif _time > GROW_TIME + _hold:
		var t := (_time - GROW_TIME - _hold) / SHRINK_TIME
		if t >= 1.0:
			_time = -1.0
			visible = false
			return
		grow = 1.0 - t * t
	scale = Vector2.ONE * grow
	position = anchor - pivot_offset
	queue_redraw()


func _draw() -> void:
	if _art != null:
		draw_texture_rect(_art, Rect2(Vector2.ZERO, ART_SIZE), false)
		# Görselin ahşap kenarı kalın: işaret biraz küçük ve aşağıda (ünlem üst kenara değmesin).
		_draw_mark(Vector2(ART_SIZE.x * 0.5, ART_SIZE.y * ART_BODY_Y + 3.0), ART_MARK)
		return
	var body := Rect2(Vector2.ZERO, BODY)
	var tail := PackedVector2Array([Vector2(BODY.x * 0.2, BODY.y - 10.0), Vector2(BODY.x * 0.48, BODY.y - 10.0), _tip()])
	# Önce koyu kenar (gövde ve kuyruk biraz büyük), sonra açık dolgu.
	draw_style_box(_edge, body)
	for outer in Geometry2D.offset_polygon(tail, OUTLINE, Geometry2D.JOIN_ROUND):
		draw_colored_polygon(outer, INK)
	draw_style_box(_fill, body)
	draw_colored_polygon(tail, FILL)
	_draw_mark(body.get_center())


## Balonun içi: üç zıplayan nokta ya da ünlem (c: gövdenin ortası).
## Balonun işareti: üç nokta ya da ünlem; k: boy çarpanı.
func _draw_mark(c: Vector2, k: float = 1.0) -> void:
	if kind == Kind.FISH:
		_draw_fish(c, k)
		return
	if kind == Kind.HEART:
		var beat := 1.0 + 0.08 * sin(_time * 9.0)
		draw_colored_polygon(heart(c, 26.0 * k * beat), HEART_COLOR)
		return
	if kind == Kind.DOTS:
		for i in 3:
			var hop := 6.0 * maxf(0.0, sin(_time * 7.0 - float(i) * 1.1))
			draw_circle(c + Vector2((float(i) - 1.0) * 25.0, -hop) * k, 7.5 * k, INK)
	else:
		var bar := Rect2(c + Vector2(-5.5, -24.0) * k, Vector2(11.0, 30.0) * k)
		draw_rect(bar, INK)
		draw_circle(bar.position + Vector2(5.5, 0.0) * k, 5.5 * k, INK)
		draw_circle(bar.end - Vector2(5.5, 0.0) * k, 5.5 * k, INK)
		draw_circle(c + Vector2(0.0, 19.0) * k, 6.5 * k, INK)


## Balık işareti (Tekir acıktı): turuncu gövde ve kuyruk tek çokgen, koyu göz; hafifçe yüzer.
func _draw_fish(c: Vector2, k: float) -> void:
	var swim := Vector2(sin(_time * 4.0) * 3.0, 0.0) * k
	var body := PackedVector2Array()
	for i in 14:
		var a := TAU * i / 14.0
		body.append(c + swim + Vector2(cos(a) * 24.0 - 4.0, sin(a) * 13.0) * k)
	var tail := PackedVector2Array([c + swim + Vector2(16.0, 0.0) * k, c + swim + Vector2(32.0, -13.0) * k,
			c + swim + Vector2(32.0, 13.0) * k])
	var merged := Geometry2D.merge_polygons(body, tail)
	draw_colored_polygon(merged[0] if not merged.is_empty() else body, FISH_COLOR)
	draw_circle(c + swim + Vector2(-16.0, -3.0) * k, 3.5 * k, INK)


## Kalp çokgeni (merkez, yarı genişlik).
static func heart(c: Vector2, r: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in 24:
		var t := TAU * i / 24.0
		var x := 16.0 * pow(sin(t), 3.0)
		var y := 13.0 * cos(t) - 5.0 * cos(2.0 * t) - 2.0 * cos(3.0 * t) - cos(4.0 * t)
		out.append(c + Vector2(x, -y) * (r / 17.0))
	return out


## Kuyruğun ucu (balonun kendi uzayında).
func _tip() -> Vector2:
	if _art != null:
		return Vector2(ART_SIZE.x * ART_TIP_X, ART_SIZE.y)
	return Vector2(BODY.x * 0.22, BODY.y + TAIL)


## Hafifçe taşan büyüme: 0 → ~1,1 → 1.
static func back_out(t: float) -> float:
	var c := 1.7
	var u := t - 1.0
	return 1.0 + (c + 1.0) * u * u * u + c * u * u
