class_name OutfitIcon
extends Control
## Dolabın ikonları (Dalga 5, kıyafetler): kodla çizilir, kıyafetin renkleriyle. Şapka biçimleri (HatModel'deki
## gibi: kova, hasır, bere, kasket, sinekçi, taç, Bekçi), yelek (yağmurluk biçimi), olta (çapraz kamış: kaplamanın
## rengi ve sargıları; varsayılan kaplama bambu) ve sekmenin balıkçısı (yüz ve kova şapka). Çizim 100×100'lük
## tasarım kutusunda; boyuta ölçeklenir. Panelde: iskele bütçesine girmez.

const OUTLINE := Color("#3a2414")
const BAMBOO := Color("#d9963a")
const BAMBOO_WRAP := Color("#a86424")
const CORK := Color("#c98a4b")
const STEEL := Color("#c9d2dc")
const SKIN := Color("#f2c7a0")

## Ne çizilir: "hat", "vest", "rod" (item: OutfitRules satırı) ya da "angler" (sekme).
var kind: String = "hat":
	set(value):
		kind = value
		queue_redraw()
var item: Dictionary = {}:
	set(value):
		item = value
		queue_redraw()


static func make(what: String, row: Dictionary, side: float) -> OutfitIcon:
	var icon := OutfitIcon.new()
	icon.kind = what
	icon.item = row
	icon.custom_minimum_size = Vector2(side, side)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return icon


func _draw() -> void:
	var s := minf(size.x, size.y) / 100.0
	draw_set_transform(Vector2((size.x - 100.0 * s) * 0.5, (size.y - 100.0 * s) * 0.5), 0.0, Vector2(s, s))
	var color := _color("color", Color("#2c7d96"))
	var band := _color("band", Color("#f0b637"))
	match kind:
		"hat":
			_hat(str(item.get("shape", "bucket")), color, band)
		"vest":
			_vest(_color("color", Color("#f0b637")))
		"rod":
			_rod(item)
		"angler":
			_angler()
	draw_set_transform(Vector2.ZERO)


## Kıyafetin rengi (boş ya da bozuksa yedek: varsayılan kaplamada renk yok).
func _color(key: String, fallback: Color) -> Color:
	var text := str(item.get(key, ""))
	return Color(text) if Color.html_is_valid(text) else fallback


func _poly(points: PackedVector2Array, color: Color) -> void:
	draw_colored_polygon(points, color)
	var loop := points.duplicate()
	loop.append(points[0])
	draw_polyline(loop, OUTLINE, 2.5, true)


func _ellipse(center: Vector2, radius: Vector2, from: float = 0.0, to: float = TAU, steps: int = 24) -> PackedVector2Array:
	var out := PackedVector2Array()
	for i in steps + 1:
		var a := lerpf(from, to, float(i) / steps)
		out.append(center + Vector2(cos(a) * radius.x, sin(a) * radius.y))
	return out


# --- Şapkalar ---------------------------------------------------------------------

func _hat(shape: String, color: Color, band: Color) -> void:
	match shape:
		"straw":
			_poly(_ellipse(Vector2(50, 68), Vector2(46, 10)), color.darkened(0.08))
			_poly(PackedVector2Array([Vector2(31, 30), Vector2(69, 30), Vector2(72, 66), Vector2(28, 66)]), color)
			_poly(PackedVector2Array([Vector2(29, 55), Vector2(71, 55), Vector2(72, 64), Vector2(28, 64)]), band)
		"beanie":
			var dome := _ellipse(Vector2(50, 64), Vector2(34, 38), PI, TAU, 18)
			_poly(dome, color)
			_poly(PackedVector2Array([Vector2(14, 58), Vector2(86, 58), Vector2(86, 76), Vector2(14, 76)]), band)
			_poly(_ellipse(Vector2(50, 24), Vector2(10, 10)), band)
		"cap":
			_poly(_ellipse(Vector2(44, 60), Vector2(34, 22), PI, TAU, 18), color)
			_poly(PackedVector2Array([Vector2(10, 58), Vector2(78, 58), Vector2(78, 68), Vector2(10, 68)]), band)
			_poly(PackedVector2Array([Vector2(74, 60), Vector2(96, 64), Vector2(93, 71), Vector2(72, 68)]), band.darkened(0.15))
		"crown":
			var petals: Array[Color] = [band, Color.WHITE, Color("#c9a6e8"), Color("#ffd84a")]
			for i in 8:
				var a := PI + PI * (i + 0.5) / 8.0
				var leaf := Vector2(50, 62) + Vector2(cos(a + 0.2) * 40, sin(a + 0.2) * 14 + 4)
				draw_circle(leaf, 5.0, color)
			for i in 8:
				var a := PI * (i + 0.5) / 8.0
				var p := Vector2(50, 60) + Vector2(cos(a) * 38, sin(a) * 12)
				draw_circle(p, 9.0, petals[i % petals.size()])
				draw_circle(p, 3.5, Color("#f4c430"))
		_:
			_bucket(color, band)
			if shape == "fly":
				var flies: Array[Color] = [Color("#d9452f"), Color("#2fb5a8"), Color("#f07d24")]
				for i in 3:
					var p := Vector2(36 + 14 * i, 56)
					draw_circle(p, 5.0, flies[i])
					draw_line(p, p + Vector2(4, 7), Color("#ffd23f"), 2.5, true)
			elif shape == "keeper":
				_poly(PackedVector2Array([Vector2(40, 30), Vector2(64, 30), Vector2(54, 10)]), color.darkened(0.3))
				for p: Vector2 in [Vector2(38, 42), Vector2(50, 38), Vector2(62, 42)]:
					draw_circle(p, 3.5, band)


func _bucket(color: Color, band: Color) -> void:
	_poly(PackedVector2Array([Vector2(8, 72), Vector2(92, 72), Vector2(80, 60), Vector2(20, 60)]), color.darkened(0.12))
	_poly(PackedVector2Array([Vector2(30, 28), Vector2(70, 28), Vector2(77, 62), Vector2(23, 62)]), color)
	_poly(PackedVector2Array([Vector2(25, 52), Vector2(75, 52), Vector2(77, 62), Vector2(23, 62)]), band)


# --- Yelek ve olta ------------------------------------------------------------------

func _vest(color: Color) -> void:
	var body := PackedVector2Array([Vector2(32, 14), Vector2(42, 20), Vector2(58, 20), Vector2(68, 14),
			Vector2(86, 30), Vector2(80, 44), Vector2(74, 40), Vector2(74, 88), Vector2(26, 88), Vector2(26, 40),
			Vector2(20, 44), Vector2(14, 30)])
	_poly(body, color)
	draw_line(Vector2(50, 22), Vector2(50, 88), color.darkened(0.3), 2.5, true)
	_poly(PackedVector2Array([Vector2(42, 20), Vector2(50, 32), Vector2(58, 20)]), color.lightened(0.25))
	for y: float in [44.0, 58.0, 72.0]:
		draw_circle(Vector2(56, y), 3.0, Color("#f4ecdc"))
	_poly(PackedVector2Array([Vector2(30, 60), Vector2(44, 60), Vector2(44, 72), Vector2(30, 72)]), color.darkened(0.12))


func _rod(row: Dictionary) -> void:
	var plain := str(row.get("unlock", "start")) == "start" or not Color.html_is_valid(str(row.get("color", "")))
	var blank := BAMBOO if plain else Color(str(row["color"]))
	var wrap := blank if plain or not Color.html_is_valid(str(row.get("band", ""))) else Color(str(row["band"]))
	if plain:
		wrap = BAMBOO_WRAP
	var a := Vector2(22, 80)
	var b := Vector2(92, 10)
	draw_line(a, b, OUTLINE, 9.0, true)
	draw_line(a, b, blank, 5.5, true)
	for f: float in [0.3, 0.55, 0.78]:
		var p := a.lerp(b, f)
		var n := (b - a).normalized().orthogonal() * 5.0
		draw_line(p - n, p + n, wrap, 5.0, true)
	draw_line(Vector2(8, 94), a, OUTLINE, 13.0, true)
	draw_line(Vector2(8, 94), a, CORK, 9.0, true)
	draw_circle(Vector2(24, 86), 9.0, OUTLINE)
	draw_circle(Vector2(24, 86), 7.0, STEEL)


## Sekmenin balıkçısı: yüz ve turkuaz kova şapka.
func _angler() -> void:
	draw_circle(Vector2(50, 70), 25.0, OUTLINE)
	draw_circle(Vector2(50, 70), 22.5, SKIN)
	draw_circle(Vector2(41, 72), 3.2, OUTLINE)
	draw_circle(Vector2(59, 72), 3.2, OUTLINE)
	draw_arc(Vector2(50, 78), 7.0, 0.3, PI - 0.3, 8, OUTLINE, 2.5, true)
	var teal := Color("#2c7d96")
	_poly(PackedVector2Array([Vector2(12, 56), Vector2(88, 56), Vector2(77, 47), Vector2(23, 47)]), teal.darkened(0.12))
	_poly(PackedVector2Array([Vector2(31, 18), Vector2(69, 18), Vector2(75, 49), Vector2(25, 49)]), teal)
	_poly(PackedVector2Array([Vector2(27, 40), Vector2(73, 40), Vector2(75, 49), Vector2(25, 49)]), Color("#f0b637"))
