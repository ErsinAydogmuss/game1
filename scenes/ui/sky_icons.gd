class_name SkyIcons
extends RefCounted
## Vakit, hava, çay, göl sevgisi ve isteklerin kodla çizilen ikonları (Dalga 4; Ersin'in görselleri
## gelene kadar: docs/gorsel-istekleri.md Parti 5a, time_icons ve weather_icons). Üst ortadaki saat
## çipinde her karede görünürler: her ikon tek üçgen dizisi (bir çizim; draw_circle her daire için
## ayrı çizim tutardı, iskelede 150 çizim sınırı). Şekiller 100×100'lük tasarım alanında. Çipte havanın
## ikonu vaktin ikonunun yanında durur: bulut ve sis güneşsiz (gece de doğru görünsün).

const KINDS: Array[String] = ["phase_morning", "phase_noon", "phase_evening", "phase_night", "weather_clear",
		"weather_cloudy", "weather_rain", "weather_fog", "weather_storm", "tea", "love", "requests"]

const SUN := Color("#ffd23f")
const SUN_RAY := Color("#ffb000")
const DAWN := Color("#ffb347")
const DUSK := Color("#ff8a3d")
const WATER := Color("#3fb6c8")
const WATER_LIGHT := Color("#7fd3df")
const NIGHT := Color("#2a3a6b")
const MOON := Color("#ffe680")
const STAR := Color("#fff7d0")
const CLOUD := Color("#f4f7fb")
const RAIN_CLOUD := Color("#c3ccd6")
const STORM_CLOUD := Color("#5c6673")
const DROP := Color("#3fa9f5")
const REED := Color("#3d5a2a")

var points := PackedVector2Array()
var colors := PackedColorArray()
var indices := PackedInt32Array()


## İkonu item'ın üstüne tek üçgen dizisiyle çizer (origin: tasarım alanının sol üstü, scale: birim/px).
## _draw içinde, draw_set_transform'dan önce çağrılmalı.
static func draw(item: CanvasItem, kind: String, origin: Vector2, scale: float) -> void:
	var shape := SkyIcons.new()
	shape.build(kind)
	if shape.points.is_empty():
		return
	var out := PackedVector2Array()
	out.resize(shape.points.size())
	for i in shape.points.size():
		out[i] = origin + shape.points[i] * scale
	RenderingServer.canvas_item_add_triangle_array(item.get_canvas_item(), shape.indices, out, shape.colors)


func build(kind: String) -> void:
	match kind:
		"phase_morning":
			_rays(Vector2(50, 64), 31.0, 42.0, [200.0, 235.0, 270.0, 305.0, 340.0], 7.0, Color(DAWN, 0.9))
			_poly(_arc_poly(Vector2(50, 64), 26.0, PI, TAU, 16), DAWN)
			_rect(Rect2(12, 64, 76, 8), WATER)
			_rect(Rect2(24, 76, 52, 5), WATER_LIGHT)
		"phase_noon", "weather_clear":
			_rays(Vector2(50, 50), 28.0, 44.0, [0.0, 45.0, 90.0, 135.0, 180.0, 225.0, 270.0, 315.0], 8.0, SUN_RAY)
			_disc(Vector2(50, 50), 22.0, SUN)
			_disc(Vector2(43, 43), 7.0, Color("#ffe680"))
			if kind == "weather_clear":
				_poly(_star(Vector2(80, 22), 9.0, 3.0, 4), Color.WHITE)
				_poly(_star(Vector2(20, 80), 7.0, 2.5, 4), Color.WHITE)
		"phase_evening":
			_disc(Vector2(50, 56), 28.0, DUSK)
			_rect(Rect2(10, 60, 80, 11), Color("#6a4c93"))
			_rect(Rect2(10, 71, 80, 9), Color("#4a3570"))
			for x: float in [20.0, 26.0, 80.0]:
				_poly(PackedVector2Array([Vector2(x - 2.5, 80), Vector2(x + 2.5, 80), Vector2(x, 34 + absf(x - 50) * 0.2)]), REED)
		"phase_night":
			_disc(Vector2(50, 50), 42.0, NIGHT)
			var moon := Geometry2D.clip_polygons(_circle(Vector2(46, 52), 25.0, 28), _circle(Vector2(59, 44), 21.0, 28))
			if not moon.is_empty():
				_poly(moon[0], MOON)
			_poly(_star(Vector2(72, 30), 8.0, 3.0, 4), STAR)
			_poly(_star(Vector2(70, 70), 5.5, 2.0, 4), STAR)
		"weather_cloudy":
			_cloud(Vector2(38, 40), RAIN_CLOUD, Color("#9fabb8"))
			_cloud(Vector2(58, 62), CLOUD, Color("#d9e2ea"))
		"weather_rain":
			_cloud(Vector2(52, 42), RAIN_CLOUD, Color("#9fabb8"))
			for p: Vector2 in [Vector2(36, 72), Vector2(52, 82), Vector2(68, 70)]:
				_drop(p, DROP)
		"weather_fog":
			# Gri-mavi bantlar: saat çipinin açık hapında da seçilsin.
			for i in 4:
				_band(22.0 + i * 16.0, Color("#93a5b5").lerp(Color("#d6dee5"), i / 3.0))
		"weather_storm":
			_cloud(Vector2(52, 38), STORM_CLOUD, Color("#3f4752"))
			_poly(PackedVector2Array([Vector2(56, 50), Vector2(42, 72), Vector2(52, 72), Vector2(45, 94), Vector2(68, 64),
					Vector2(57, 64), Vector2(64, 50)]), SUN)
			_drop(Vector2(30, 70), DROP)
			_drop(Vector2(78, 72), DROP)
		"tea":
			_ellipse(Vector2(50, 82), 28.0, 7.0, Color("#f2f2f2"))
			var glass := PackedVector2Array([Vector2(35, 22), Vector2(65, 22), Vector2(57, 48), Vector2(63, 64), Vector2(57, 80),
					Vector2(43, 80), Vector2(37, 64), Vector2(43, 48)])
			_poly(glass, Color(0.93, 0.97, 1.0, 0.85))
			var tea := Geometry2D.intersect_polygons(_scaled(glass, Vector2(50, 52), 0.82), _box(Rect2(0, 38, 100, 62)))
			for part in tea:
				_poly(part, Color("#b8352a"))
			_rect(Rect2(33, 20, 34, 4), Color("#f6d27a"))
		"love":
			_disc(Vector2(37, 40), 17.0, Color("#2fc6c0"))
			_disc(Vector2(63, 40), 17.0, Color("#2fc6c0"))
			_poly(PackedVector2Array([Vector2(21, 46), Vector2(79, 46), Vector2(50, 84)]), Color("#2fc6c0"))
			_disc(Vector2(50, 50), 8.0, Color("#ff9ec4"))
			_disc(Vector2(34, 34), 5.0, Color(1, 1, 1, 0.75))
		"requests":
			_rect(Rect2(28, 26, 44, 50), Color("#f3e2b3"))
			_ellipse(Vector2(50, 26), 24.0, 6.0, Color("#e2c98c"))
			_ellipse(Vector2(50, 76), 24.0, 6.0, Color("#e2c98c"))
			_rect(Rect2(46, 22, 8, 58), Color("#e63946"))
			_poly(PackedVector2Array([Vector2(50, 50), Vector2(36, 42), Vector2(36, 58)]), Color("#c62f3b"))
			_poly(PackedVector2Array([Vector2(50, 50), Vector2(64, 42), Vector2(64, 58)]), Color("#c62f3b"))


# --- Şekiller --------------------------------------------------------------------------

## Herhangi bir basit (kendini kesmeyen) çokgen: üçgenlere bölünür.
func _poly(poly: PackedVector2Array, color: Color) -> void:
	var tris := Geometry2D.triangulate_polygon(poly)
	if tris.is_empty():
		return
	var base := points.size()
	points.append_array(poly)
	for i in poly.size():
		colors.append(color)
	for t in tris:
		indices.append(base + t)


func _disc(c: Vector2, r: float, color: Color) -> void:
	_poly(_circle(c, r, 24), color)


func _ellipse(c: Vector2, rx: float, ry: float, color: Color) -> void:
	var poly := PackedVector2Array()
	for i in 24:
		var a := TAU * i / 24.0
		poly.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	_poly(poly, color)


func _rect(r: Rect2, color: Color) -> void:
	_poly(_box(r), color)


## Güneşin ışınları: verilen açılarda (derece; 0 sağ, 90 aşağı) r_in'den r_out'a ince üçgenler.
func _rays(c: Vector2, r_in: float, r_out: float, angles: Array, half_deg: float, color: Color) -> void:
	for a: float in angles:
		var mid := deg_to_rad(a)
		var half := deg_to_rad(half_deg)
		_poly(PackedVector2Array([c + Vector2.from_angle(mid - half) * r_in, c + Vector2.from_angle(mid) * r_out,
				c + Vector2.from_angle(mid + half) * r_in]), color)


## Bulut: üç yuvarlak ve altında düz bir gövde (gölgesiyle).
func _cloud(c: Vector2, color: Color, shade: Color) -> void:
	_rect(Rect2(c.x - 18, c.y + 4, 36, 12), shade)
	_disc(c + Vector2(-16, 4), 14.0, color)
	_disc(c + Vector2(0, -5), 18.0, color)
	_disc(c + Vector2(16, 5), 12.0, color)
	_rect(Rect2(c.x - 16, c.y + 2, 32, 12), color)


## Yağmur damlası: üstte sivri, altta yuvarlak.
func _drop(c: Vector2, color: Color) -> void:
	var poly := PackedVector2Array([c + Vector2(0, -11)])
	for i in 13:
		var a := deg_to_rad(-30.0 + 240.0 * i / 12.0)
		poly.append(c + Vector2(cos(a), sin(a)) * 5.5 + Vector2(0, 2))
	_poly(poly, color)


## Sisin dalgalı bandı (y: üst kenarın ortası).
func _band(y: float, color: Color) -> void:
	var poly := PackedVector2Array()
	for i in 13:
		var x := 16.0 + 68.0 * i / 12.0
		poly.append(Vector2(x, y + sin(x * 0.16) * 2.5))
	for i in range(12, -1, -1):
		var x := 16.0 + 68.0 * i / 12.0
		poly.append(Vector2(x, y + 7.0 + sin(x * 0.16 + 0.8) * 2.5))
	_poly(poly, color)


static func _circle(c: Vector2, r: float, segments: int) -> PackedVector2Array:
	return _arc_poly(c, r, 0.0, TAU, segments, false)


## Yay boyunca çokgen (kapalıysa merkez yok; açık yayda uçlar birleşir: yarım daire).
static func _arc_poly(c: Vector2, r: float, from: float, to: float, segments: int, open: bool = true) -> PackedVector2Array:
	var poly := PackedVector2Array()
	var count := segments + 1 if open else segments
	for i in count:
		var a := from + (to - from) * float(i) / float(segments)
		poly.append(c + Vector2(cos(a), sin(a)) * r)
	return poly


static func _star(c: Vector2, outer: float, inner: float, tips: int) -> PackedVector2Array:
	var poly := PackedVector2Array()
	for i in tips * 2:
		var r := outer if i % 2 == 0 else inner
		var a := -PI * 0.5 + i * PI / tips
		poly.append(c + Vector2(cos(a), sin(a)) * r)
	return poly


static func _box(r: Rect2) -> PackedVector2Array:
	return PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])


static func _scaled(poly: PackedVector2Array, center: Vector2, k: float) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in poly:
		out.append(center + (p - center) * k)
	return out
