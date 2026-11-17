class_name SpeechBubble
extends Control
## Konuşma balonu (2B): ekranda Dede'nin başının üstünde; içinde üç nokta (konuşuyor) ya da ünlem; Tekir'in
## balonunda mama kabı (acıktı; görseli yoksa kodla balık) ya da kalp (mırlıyor, yedi).
## 3B sahnenin sisi ve ton eşlemesi onu grileştirmesin diye arayüz gibi çizilir; yakınlaşmada da
## aynı boyda kalır. pop() ile hafifçe taşarak büyür, HOLD_TIME sn durur, küçülerek kaybolur.
## Kuyruğun ucu anchor'a (viewport noktası) gelir. Kare başı hareket _process'te.
## Balon ve işaretin parçaları bir kez çizilir; büyüme, noktaların zıplaması, kalbin atması ve balığın yüzmesi
## yalnızca konum ve ölçekle. Balon her kare yeniden çizilseydi her daire ve çokgen ekran kartında yeni tampon ve
## VAO kurardı (Compatibility; docs/performans-notlari.md §3.3: Kazı'da Android'de çökmenin şüphelisi).

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
## Acıkan Tekir'in işareti: Ersin'in mama kabı (Parti 5b home_icons "cat_bowl"; yoksa kodla turuncu balık).
var _bowl: Texture2D
## İşaretin parçaları (Mark; kind değişince yeniden kurulur) ve kurulduğu tür (-1: yok).
var _marks: Array[Mark] = []
var _marks_kind: int = -1


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Dünyadaki 2B yazı: fotoğraf modunda görüntüye girmez (PhotoMode.WORLD_LABELS).
	visibility_layer = PhotoMode.WORLD_LABELS
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_art = ItemArt.frame("bubble")
	_bowl = ItemArt.ui("cat_bowl")
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
	if _marks_kind != int(kind):
		_build_marks()
	_place_marks()


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
	_place_marks()


func _draw() -> void:
	if _art != null:
		draw_texture_rect(_art, Rect2(Vector2.ZERO, ART_SIZE), false)
		return
	var body := Rect2(Vector2.ZERO, BODY)
	var tail := PackedVector2Array([Vector2(BODY.x * 0.2, BODY.y - 10.0), Vector2(BODY.x * 0.48, BODY.y - 10.0), _tip()])
	# Önce koyu kenar (gövde ve kuyruk biraz büyük), sonra açık dolgu.
	draw_style_box(_edge, body)
	for outer in Geometry2D.offset_polygon(tail, OUTLINE, Geometry2D.JOIN_ROUND):
		draw_colored_polygon(outer, INK)
	draw_style_box(_fill, body)
	draw_colored_polygon(tail, FILL)


## İşaretin yeri (balonun kendi uzayında) ve boy çarpanı: görselin ahşap kenarı kalın, işaret biraz küçük ve aşağıda
## (ünlem üst kenara değmesin).
func _mark_center() -> Vector2:
	if _art != null:
		return Vector2(ART_SIZE.x * 0.5, ART_SIZE.y * ART_BODY_Y + 3.0)
	return Rect2(Vector2.ZERO, BODY).get_center()


func _mark_scale() -> float:
	return ART_MARK if _art != null else 1.0


## Balonun işareti: üç nokta, ünlem, kalp ya da mama kabı (balık); parçalar bir kez çizilir.
func _build_marks() -> void:
	for m in _marks:
		m.queue_free()
	_marks.clear()
	_marks_kind = int(kind)
	var k := _mark_scale()
	match kind:
		Kind.DOTS:
			for i in 3:
				_marks.append(Mark.new("dot", k, INK, null))
		Kind.EXCLAIM:
			_marks.append(Mark.new("exclaim", k, INK, null))
		Kind.HEART:
			_marks.append(Mark.new("heart", k, HEART_COLOR, null))
		Kind.FISH:
			_marks.append(Mark.new("bowl" if _bowl != null else "fish", k, FISH_COLOR, _bowl))
	for m in _marks:
		add_child(m)


## İşaretin kare başı hareketi: noktalar zıplar, kalp atar, balık (mama kabı) yüzer.
func _place_marks() -> void:
	var c := _mark_center()
	var k := _mark_scale()
	match kind:
		Kind.DOTS:
			for i in mini(3, _marks.size()):
				var hop := 6.0 * maxf(0.0, sin(_time * 7.0 - float(i) * 1.1))
				_marks[i].position = c + Vector2((float(i) - 1.0) * 25.0, -hop) * k
		Kind.HEART:
			if not _marks.is_empty():
				_marks[0].position = c
				_marks[0].scale = Vector2.ONE * (1.0 + 0.08 * sin(_time * 9.0))
		Kind.FISH:
			if not _marks.is_empty():
				_marks[0].position = c + Vector2(sin(_time * 4.0) * 3.0, 0.0) * k
		_:
			if not _marks.is_empty():
				_marks[0].position = c


## İşaretin bir parçası: kendi başlangıcının çevresinde bir kez çizilir (nokta, ünlem, kalp, mama kabı ya da balık).
class Mark extends Control:
	var shape: String
	var k: float
	var color: Color
	var art: Texture2D

	func _init(mark_shape: String, scale_k: float, mark_color: Color, texture: Texture2D) -> void:
		shape = mark_shape
		k = scale_k
		color = mark_color
		art = texture
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		visibility_layer = PhotoMode.WORLD_LABELS

	func _draw() -> void:
		match shape:
			"dot":
				draw_circle(Vector2.ZERO, 7.5 * k, color)
			"exclaim":
				var bar := Rect2(Vector2(-5.5, -24.0) * k, Vector2(11.0, 30.0) * k)
				draw_rect(bar, color)
				draw_circle(bar.position + Vector2(5.5, 0.0) * k, 5.5 * k, color)
				draw_circle(bar.end - Vector2(5.5, 0.0) * k, 5.5 * k, color)
				draw_circle(Vector2(0.0, 19.0) * k, 6.5 * k, color)
			"heart":
				draw_colored_polygon(SpeechBubble.heart(Vector2.ZERO, 26.0 * k), color)
			"bowl":
				var side := 66.0 * k
				draw_texture_rect(art, Rect2(-Vector2(side, side) * 0.5, Vector2(side, side)), false)
			"fish":
				# Kodla turuncu gövde ve kuyruk tek çokgen, koyu göz.
				var body := PackedVector2Array()
				for i in 14:
					var a := TAU * i / 14.0
					body.append(Vector2(cos(a) * 24.0 - 4.0, sin(a) * 13.0) * k)
				var tail := PackedVector2Array([Vector2(16.0, 0.0) * k, Vector2(32.0, -13.0) * k, Vector2(32.0, 13.0) * k])
				var merged := Geometry2D.merge_polygons(body, tail)
				draw_colored_polygon(merged[0] if not merged.is_empty() else body, color)
				draw_circle(Vector2(-16.0, -3.0) * k, 3.5 * k, SpeechBubble.INK)


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
