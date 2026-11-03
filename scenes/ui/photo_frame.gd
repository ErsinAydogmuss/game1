class_name PhotoFrame
extends Control
## Fotoğraf modunun çerçevesi (Dalga 5): ekranın kenarlarına kodla çizilir ve fotoğrafa girer (deklanşörde
## görüntüyle birlikte alınır). Çeşitler (KINDS): yok, ahşap (kalın kahverengi kenar, iç çizgi, köşe çivileri),
## polaroid (krem kenar, altta geniş şerit; şeritte oyunun adı), çiçek (pastel pembe kenar, renkli çiçekler),
## eski kâğıt (Gölün Sırrı'nın haritası gibi: sarımsı kâğıt, yırtık iç kenar, sol üst köşede pusula).
## Parti 5b'nin çerçeve görselleri gelince onlarla çizilebilir (photo_wood, photo_polaroid, photo_lotus,
## photo_paper). Seçim düğmelerinde küçük önizleme de aynı işlevle çizilir (draw_frame).

const KINDS: Array[String] = ["none", "wood", "polaroid", "flower", "paper"]
const WOOD := Color("#8a5a36")
const WOOD_DARK := Color("#5a3a24")
const WOOD_LIGHT := Color("#b07a4a")
const PAPER := Color("#fbf6ea")
const PAPER_SHADE := Color("#e6dccb")
const PINK := Color("#f6c9d6")
const PETALS: Array[Color] = [Color("#ffffff"), Color("#ffd84a"), Color("#c9a6e8"), Color("#f28cb4"), Color("#8fd3f4")]
const INK := Color("#4a2a12")
const PARCHMENT := Color("#ead9ac")
const PARCHMENT_EDGE := Color("#a8814a")
const COMPASS := Color("#c0392b")

var kind: String = "none":
	set(value):
		kind = value
		queue_redraw()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)


func _draw() -> void:
	draw_frame(self, Rect2(Vector2.ZERO, size), kind, true)


## Polaroid'in alttaki şeridi (yazı ve logo buraya): kutunun yüksekliğinin payı.
static func strip_height(rect: Rect2) -> float:
	return rect.size.y * 0.13


## Kenarın kalınlığı (kutunun kısa kenarının payı).
static func border(rect: Rect2, frame: String) -> float:
	var short := minf(rect.size.x, rect.size.y)
	match frame:
		"wood":
			return short * 0.045
		"polaroid":
			return short * 0.035
		"flower":
			return short * 0.05
		"paper":
			return short * 0.045
	return 0.0


## Çerçeveyi rect'e çizer (overlay ya da düğmedeki önizleme). title: polaroid şeridinde oyunun adı. Bütün şekiller
## (şeritler, çizgiler, çiviler, çiçekler, dişler, pusula) tek üçgen dizisinde: tek çizim (her draw_circle ve
## draw_colored_polygon ayrı bir çizim olurdu: çiçekli çerçeve yüzlerce). Polaroid'in yazısı ayrı bir çizim.
static func draw_frame(canvas: CanvasItem, rect: Rect2, frame: String, title: bool = false) -> void:
	var b := border(rect, frame)
	var t := Tris.new()
	match frame:
		"wood":
			_band(t, rect, b, b, WOOD)
			var inner := rect.grow(-b)
			t.outline(inner.grow(b * 0.18), maxf(1.0, b * 0.22), WOOD_DARK)
			t.outline(rect, maxf(1.0, b * 0.12), WOOD_LIGHT)
			for corner: Vector2 in [rect.position, Vector2(rect.end.x, rect.position.y), rect.end,
					Vector2(rect.position.x, rect.end.y)]:
				var at := corner + (rect.get_center() - corner).normalized() * b * 0.75
				t.circle(at, b * 0.17, WOOD_DARK)
		"polaroid":
			var strip := strip_height(rect)
			_band(t, rect, b, strip, PAPER)
			t.outline(Rect2(rect.position + Vector2(b, b), rect.size - Vector2(2.0 * b, b + strip)),
					maxf(1.0, b * 0.12), PAPER_SHADE)
		"flower":
			_band(t, rect, b, b, PINK)
			var step := maxf(b * 1.6, 8.0)
			var i := 0
			var x := rect.position.x + b * 0.5
			while x < rect.end.x:
				_flower(t, Vector2(x, rect.position.y + b * 0.5), b * 0.34, i)
				_flower(t, Vector2(x, rect.end.y - b * 0.5), b * 0.34, i + 2)
				x += step
				i += 1
			var y := rect.position.y + b * 0.5 + step
			while y < rect.end.y - step * 0.5:
				_flower(t, Vector2(rect.position.x + b * 0.5, y), b * 0.34, i)
				_flower(t, Vector2(rect.end.x - b * 0.5, y), b * 0.34, i + 3)
				y += step
				i += 1
		"paper":
			_torn_band(t, rect, b)
			t.outline(rect, maxf(1.0, b * 0.16), PARCHMENT_EDGE)
			_compass(t, rect.position + Vector2(b * 1.15, b * 1.15), b * 0.85)
	t.flush(canvas)
	if frame == "polaroid" and title:
		var strip := strip_height(rect)
		var font := UiKit.display_font()
		var size := int(strip * 0.42)
		var text := str(TranslationServer.translate("UI_PHOTO_TITLE"))
		var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		canvas.draw_string(font, Vector2(rect.position.x + b * 1.6, rect.end.y - strip * 0.36),
				text, HORIZONTAL_ALIGNMENT_LEFT, width + 4.0, size, INK)


## Dört kenar şeridi (üst, sol, sağ: side; alt: bottom).
static func _band(t: Tris, rect: Rect2, side: float, bottom: float, color: Color) -> void:
	t.rect(Rect2(rect.position, Vector2(rect.size.x, side)), color)
	t.rect(Rect2(Vector2(rect.position.x, rect.end.y - bottom), Vector2(rect.size.x, bottom)), color)
	t.rect(Rect2(rect.position, Vector2(side, rect.size.y)), color)
	t.rect(Rect2(Vector2(rect.end.x - side, rect.position.y), Vector2(side, rect.size.y)), color)


## Eski kâğıdın kenarı: dört şerit, iç kenarı yırtık (dişler kâğıt rengi, üstünde koyu kenar çizgisi).
static func _torn_band(t: Tris, rect: Rect2, b: float) -> void:
	_band(t, rect, b, b, PARCHMENT)
	var tooth := b * 0.32
	var step := maxf(b * 0.7, 4.0)
	var inner := rect.grow(-b)
	var edge := maxf(1.0, b * 0.08)
	for side in 4:
		var from: Vector2
		var along: Vector2
		var inward: Vector2
		var length: float
		match side:
			0:
				from = inner.position
				along = Vector2.RIGHT
				inward = Vector2.DOWN
				length = inner.size.x
			1:
				from = Vector2(inner.end.x, inner.position.y)
				along = Vector2.DOWN
				inward = Vector2.LEFT
				length = inner.size.y
			2:
				from = inner.end
				along = Vector2.LEFT
				inward = Vector2.UP
				length = inner.size.x
			_:
				from = Vector2(inner.position.x, inner.end.y)
				along = Vector2.UP
				inward = Vector2.RIGHT
				length = inner.size.y
		var points := PackedVector2Array()
		var d := 0.0
		var k := 0
		while d < length:
			var depth := tooth * (0.45 + 0.55 * float((k * 7) % 5) / 4.0)
			points.append(from + along * d)
			points.append(from + along * minf(d + step * 0.5, length) + inward * depth)
			d += step
			k += 1
		points.append(from + along * length)
		for j in range(0, points.size() - 2, 2):
			t.tri(points[j], points[j + 1], points[j + 2], PARCHMENT)
		for j in points.size() - 1:
			t.line(points[j], points[j + 1], edge, PARCHMENT_EDGE)


## Köşedeki küçük pusula: kâğıt rengi daire, halka ve dört uçlu yıldız (kuzey kırmızı).
static func _compass(t: Tris, at: Vector2, radius: float) -> void:
	t.circle(at, radius, PARCHMENT, 20)
	t.ring(at, radius, maxf(1.0, radius * 0.1), PARCHMENT_EDGE)
	for k in 4:
		var a := -PI * 0.5 + PI * 0.5 * k
		var tip := at + Vector2(cos(a), sin(a)) * radius * 0.85
		var left := at + Vector2(cos(a - PI * 0.5), sin(a - PI * 0.5)) * radius * 0.2
		var right := at + Vector2(cos(a + PI * 0.5), sin(a + PI * 0.5)) * radius * 0.2
		t.tri(tip, left, right, COMPASS if k == 0 else INK)


## Beş taç yapraklı çiçek; çok küçükken (düğmedeki önizleme) yalnızca renkli bir nokta.
static func _flower(t: Tris, at: Vector2, radius: float, index: int) -> void:
	var petal := PETALS[index % PETALS.size()]
	if radius < 2.0:
		t.circle(at, maxf(radius, 0.8), petal, 6)
		return
	for k in 5:
		var a := TAU * k / 5.0 + index * 0.7
		t.circle(at + Vector2(cos(a), sin(a)) * radius * 0.7, radius * 0.55, petal, 8)
	t.circle(at, radius * 0.45, Color("#f4c430"), 8)


## Üçgen toplayıcı: bir çerçevenin bütün şekilleri tek canvas_item_add_triangle_array ile çizilir (köşe renkli).
class Tris:
	var points := PackedVector2Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()

	func tri(a: Vector2, b: Vector2, c: Vector2, color: Color) -> void:
		var i := points.size()
		points.append_array(PackedVector2Array([a, b, c]))
		colors.append_array(PackedColorArray([color, color, color]))
		indices.append_array(PackedInt32Array([i, i + 1, i + 2]))

	func quad(a: Vector2, b: Vector2, c: Vector2, d: Vector2, color: Color) -> void:
		var i := points.size()
		points.append_array(PackedVector2Array([a, b, c, d]))
		colors.append_array(PackedColorArray([color, color, color, color]))
		indices.append_array(PackedInt32Array([i, i + 1, i + 2, i, i + 2, i + 3]))

	func rect(r: Rect2, color: Color) -> void:
		quad(r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y), color)

	## Dikdörtgenin çevresi: kalınlık kenarın ortasında (draw_rect'in boş hâli gibi).
	func outline(r: Rect2, width: float, color: Color) -> void:
		var w := width * 0.5
		rect(Rect2(r.position - Vector2(w, w), Vector2(r.size.x + width, width)), color)
		rect(Rect2(Vector2(r.position.x - w, r.end.y - w), Vector2(r.size.x + width, width)), color)
		rect(Rect2(Vector2(r.position.x - w, r.position.y + w), Vector2(width, maxf(0.0, r.size.y - width))), color)
		rect(Rect2(Vector2(r.end.x - w, r.position.y + w), Vector2(width, maxf(0.0, r.size.y - width))), color)

	func line(a: Vector2, b: Vector2, width: float, color: Color) -> void:
		if a.distance_squared_to(b) < 0.0001:
			return
		var n := (b - a).normalized().orthogonal() * width * 0.5
		quad(a + n, b + n, b - n, a - n, color)

	func circle(center: Vector2, radius: float, color: Color, segments: int = 12) -> void:
		var i0 := points.size()
		points.append(center)
		colors.append(color)
		for k in segments:
			var a := TAU * k / segments
			points.append(center + Vector2(cos(a), sin(a)) * radius)
			colors.append(color)
		for k in segments:
			indices.append_array(PackedInt32Array([i0, i0 + 1 + k, i0 + 1 + (k + 1) % segments]))

	func ring(center: Vector2, radius: float, width: float, color: Color, segments: int = 24) -> void:
		var inner := radius - width * 0.5
		var outer := radius + width * 0.5
		for k in segments:
			var d0 := Vector2(cos(TAU * k / segments), sin(TAU * k / segments))
			var d1 := Vector2(cos(TAU * (k + 1) / segments), sin(TAU * (k + 1) / segments))
			quad(center + d0 * inner, center + d0 * outer, center + d1 * outer, center + d1 * inner, color)

	func flush(canvas: CanvasItem) -> void:
		if not indices.is_empty():
			RenderingServer.canvas_item_add_triangle_array(canvas.get_canvas_item(), indices, points, colors)
