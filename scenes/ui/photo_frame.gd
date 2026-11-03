class_name PhotoFrame
extends Control
## Fotoğraf modunun çerçevesi (Dalga 5): ekranın kenarlarına kodla çizilir ve fotoğrafa girer (deklanşörde
## görüntüyle birlikte alınır). Çeşitler (KINDS): yok, ahşap (kalın kahverengi kenar, iç çizgi, köşe çivileri),
## polaroid (krem kenar, altta geniş şerit; şeritte oyunun adı), çiçek (pastel pembe kenar, renkli çiçekler).
## Parti 5b'nin çerçeve görselleri gelince onlarla çizilebilir. Seçim düğmelerinde küçük önizleme de aynı
## işlevle çizilir (draw_frame).

const KINDS: Array[String] = ["none", "wood", "polaroid", "flower"]
const WOOD := Color("#8a5a36")
const WOOD_DARK := Color("#5a3a24")
const WOOD_LIGHT := Color("#b07a4a")
const PAPER := Color("#fbf6ea")
const PAPER_SHADE := Color("#e6dccb")
const PINK := Color("#f6c9d6")
const PETALS: Array[Color] = [Color("#ffffff"), Color("#ffd84a"), Color("#c9a6e8"), Color("#f28cb4"), Color("#8fd3f4")]
const INK := Color("#4a2a12")

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
	return 0.0


## Çerçeveyi rect'e çizer (overlay ya da düğmedeki önizleme). title: polaroid şeridinde oyunun adı.
static func draw_frame(canvas: CanvasItem, rect: Rect2, frame: String, title: bool = false) -> void:
	var b := border(rect, frame)
	match frame:
		"wood":
			_band(canvas, rect, b, b, WOOD)
			var inner := rect.grow(-b)
			canvas.draw_rect(inner.grow(b * 0.18), WOOD_DARK, false, maxf(1.0, b * 0.22))
			canvas.draw_rect(rect, WOOD_LIGHT, false, maxf(1.0, b * 0.12))
			for corner: Vector2 in [rect.position, Vector2(rect.end.x, rect.position.y), rect.end,
					Vector2(rect.position.x, rect.end.y)]:
				var at := corner + (rect.get_center() - corner).normalized() * b * 0.75
				canvas.draw_circle(at, b * 0.17, WOOD_DARK)
		"polaroid":
			var strip := strip_height(rect)
			_band(canvas, rect, b, strip, PAPER)
			canvas.draw_rect(Rect2(rect.position + Vector2(b, b), rect.size - Vector2(2.0 * b, b + strip)),
					PAPER_SHADE, false, maxf(1.0, b * 0.12))
			if title:
				var font := UiKit.display_font()
				var size := int(strip * 0.42)
				var text := str(TranslationServer.translate("UI_PHOTO_TITLE"))
				var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
				canvas.draw_string(font, Vector2(rect.position.x + b * 1.6, rect.end.y - strip * 0.36),
						text, HORIZONTAL_ALIGNMENT_LEFT, width + 4.0, size, INK)
		"flower":
			_band(canvas, rect, b, b, PINK)
			var step := maxf(b * 1.6, 8.0)
			var i := 0
			var x := rect.position.x + b * 0.5
			while x < rect.end.x:
				_flower(canvas, Vector2(x, rect.position.y + b * 0.5), b * 0.34, i)
				_flower(canvas, Vector2(x, rect.end.y - b * 0.5), b * 0.34, i + 2)
				x += step
				i += 1
			var y := rect.position.y + b * 0.5 + step
			while y < rect.end.y - step * 0.5:
				_flower(canvas, Vector2(rect.position.x + b * 0.5, y), b * 0.34, i)
				_flower(canvas, Vector2(rect.end.x - b * 0.5, y), b * 0.34, i + 3)
				y += step
				i += 1


## Dört kenar şeridi (üst, sol, sağ: side; alt: bottom).
static func _band(canvas: CanvasItem, rect: Rect2, side: float, bottom: float, color: Color) -> void:
	canvas.draw_rect(Rect2(rect.position, Vector2(rect.size.x, side)), color)
	canvas.draw_rect(Rect2(Vector2(rect.position.x, rect.end.y - bottom), Vector2(rect.size.x, bottom)), color)
	canvas.draw_rect(Rect2(rect.position, Vector2(side, rect.size.y)), color)
	canvas.draw_rect(Rect2(Vector2(rect.end.x - side, rect.position.y), Vector2(side, rect.size.y)), color)


static func _flower(canvas: CanvasItem, at: Vector2, radius: float, index: int) -> void:
	var petal := PETALS[index % PETALS.size()]
	for k in 5:
		var a := TAU * k / 5.0 + index * 0.7
		canvas.draw_circle(at + Vector2(cos(a), sin(a)) * radius * 0.7, radius * 0.55, petal)
	canvas.draw_circle(at, radius * 0.45, Color("#f4c430"))
