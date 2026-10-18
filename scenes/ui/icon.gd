class_name GameIcon
extends Control
## Oyun ikonu. Görseli varsa (assets/icons/ui, kullanıcının ChatGPT çizimleri) onu çizer;
## yoksa 100×100'lük bir tasarım alanında kodla çizer ve boyuta ölçekler. (Kazı'dan uyarlandı.)
## kind: coin, star, star_empty, close, book, settings, lock, question, hand, burst, trophy,
## sound, music, vibration, easy, globe, up, down, rod, reel, line, bait, net, bucket, aquarium,
## bobber, hook, fish, shop, gem, map, sell (para kesesi), release (göle dönen balık), pin (haritada
## "buradasın"). Yalnızca görselle çizilenler (görseli yoksa çağıran başka ikon seçer): anchor
## ("Kıyıya dön"), compass, buoy, signpost (harita). "fish:<id>" balık portresini, "rarity:<şekil>" nadirlik simgesini (circle, triangle,
## diamond, star, sparkle, medallion; görseli yoksa şekil tint renginde), "zone:<bölge>" bölge
## rozetini (görseli yoksa kodla: iskele, kamış, nilüfer, kaya, dere, şamandıra) çizer.

## Kodla çizilebilen ikonlar (görseli yoksa). Bilinmeyen ad soru işareti çizer (boş kalmasın);
## takımın "kind"ı bunlardan biri olmalı (test_content_db denetler).
const DRAWN: Array[String] = ["coin", "star", "star_empty", "close", "down", "up", "sound", "music",
		"vibration", "easy", "globe", "book", "settings", "question", "hand", "rod", "reel", "line", "bait",
		"net", "bobber", "hook", "fish", "bucket", "shop", "gem", "burst", "trophy", "lock", "map", "sell",
		"release", "pin", "boat"]

## Kod adı -> görsel adı (assets/icons/ui/<ad>.png).
const ART_NAMES := {
	"coin": "coin", "close": "close", "star": "star", "star_empty": "star_empty", "book": "book",
	"settings": "settings", "lock": "lock", "question": "question", "hand": "hand", "burst": "burst",
	"trophy": "trophy", "rod": "rod", "reel": "reel", "bait": "bait", "bucket": "bucket",
	"aquarium": "aquarium", "hook": "hook", "shop": "shop", "map": "map", "sell": "sell",
	"release": "release", "pin": "pin", "anchor": "anchor", "compass": "compass", "buoy": "buoy",
	"signpost": "signpost", "tech_float": "tech_float", "tech_spin": "tech_spin", "tech_bottom": "tech_bottom",
	"tech_fly": "tech_fly", "tech_trap": "tech_trap", "tackle_bag": "tackle_bag",
}
## Arayüz görseli olmayan kod adları -> takım resmi (assets/icons/gear/<ad>.png): dükkânın
## Misina, Yem, Ekstra ve tekniğe özel sekmeleri (yapay yem, kurşun, sinek).
const GEAR_ART := {"line": "line_braid", "bait": "bait_worm", "net": "net", "boat": "boat", "lure": "lure_spoon",
		"rig": "sinker", "fly": "fly_dry"}
## Yalnızca görselle çizilen adların görseli yokken kodla çizilen yedeği (teknik düğmeleri,
## takım çantası, tekniğe özel sekmeler).
const FALLBACK := {"lure": "bait", "rig": "bait", "fly": "bait", "tech_float": "bobber", "tech_spin": "rod",
		"tech_bottom": "rod", "tech_fly": "rod", "tech_trap": "net", "tackle_bag": "bucket"}

## Nadirlik şekli (rarities.json "shape") → arayüz kitindeki rozet görseli (assets/icons/ui).
## Görsel varsa renk tint'ten değil görselden gelir; test_art_sheet her nadirliği denetler.
const RARITY_ART := {
	"circle": "rarity_common", "triangle": "rarity_fine", "diamond": "rarity_rare",
	"star": "rarity_epic", "sparkle": "rarity_legendary", "medallion": "rarity_mythic",
}

const WOOD := Color("#b07a3b")
const WOOD_DARK := Color("#7a4f22")
const STEEL := Color("#c9d2dc")
const STEEL_DARK := Color("#6d7580")
const GOLD := Color("#ffd23f")
const GOLD_DARK := Color("#e0a015")
const INK := Color("#3a3f47")
const WATER := Color("#3fb6c8")
const RED := Color("#e63946")

var kind: String = "coin":
	set(value):
		kind = value
		queue_redraw()
## gem / ok gibi kodla çizilen ikonların rengi.
var tint: Color = Color.WHITE:
	set(value):
		tint = value
		queue_redraw()
## Görselli ikonların rengi (ör. bulunmamış balık için siyah gölge).
var modulate_art: Color = Color.WHITE:
	set(value):
		modulate_art = value
		queue_redraw()


static func make(icon_kind: String, side: float, color: Color = Color.WHITE) -> GameIcon:
	var icon := GameIcon.new()
	icon.kind = icon_kind
	icon.tint = color
	icon.custom_minimum_size = Vector2(side, side)
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return icon


## Bu ikonun görseli (yoksa null).
static func texture_for(icon_kind: String) -> Texture2D:
	if icon_kind.begins_with("fish:"):
		return ItemArt.fish(icon_kind.substr(5))
	if icon_kind.begins_with("rarity:"):
		var art: String = RARITY_ART.get(icon_kind.substr(7), "")
		return ItemArt.ui(art) if not art.is_empty() else null
	if icon_kind.begins_with("zone:"):
		return ItemArt.zone(icon_kind.substr(5))
	var art: Texture2D = ItemArt.ui(str(ART_NAMES[icon_kind])) if ART_NAMES.has(icon_kind) else null
	if art == null and GEAR_ART.has(icon_kind):
		art = ItemArt.gear(str(GEAR_ART[icon_kind]))
	return art


func _draw() -> void:
	var texture := texture_for(kind)
	if texture != null:
		var side := minf(size.x, size.y)
		draw_texture_rect(texture, Rect2((size - Vector2(side, side)) * 0.5, Vector2(side, side)), false, modulate_art)
		return
	var s := minf(size.x, size.y) / 100.0
	draw_set_transform((size - Vector2(100, 100) * s) * 0.5, 0.0, Vector2(s, s))
	if kind.begins_with("rarity:"):
		_rarity(kind.substr(7))
		draw_set_transform(Vector2.ZERO)
		return
	if kind.begins_with("zone:"):
		_zone(kind.substr(5))
		draw_set_transform(Vector2.ZERO)
		return
	match str(FALLBACK.get(kind, kind)):
		"coin", "sell":
			_coin()
		"star":
			_star(tint)
		"star_empty":
			_star(Color(tint, 0.25))
		"close":
			draw_line(Vector2(24, 24), Vector2(76, 76), tint, 14.0)
			draw_line(Vector2(76, 24), Vector2(24, 76), tint, 14.0)
		"down":
			_arrow(true)
		"up":
			_arrow(false)
		"sound":
			_sound()
		"music":
			_music()
		"vibration":
			_vibration()
		"easy":
			_easy()
		"globe", "book", "map":
			_globe()
		"settings":
			_gear()
		"question":
			_question()
		"hand":
			_hand()
		"rod":
			_rod()
		"reel":
			_reel()
		"line":
			_line_spool()
		"bait":
			_bait_jar()
		"net":
			_net()
		"bobber":
			_bobber()
		"hook":
			_hook()
		"fish", "release":
			_fish(tint if tint != Color.WHITE else Color("#f2a541"))
		"bucket":
			_bucket()
		"shop":
			_shop()
		"gem":
			_gem()
		"burst", "trophy":
			_star(GOLD)
		"lock":
			_round_rect(Rect2(24, 44, 52, 42), STEEL_DARK, 8)
			draw_arc(Vector2(50, 44), 16, PI, TAU, 18, STEEL_DARK, 8.0, true)
		"pin":
			_pin()
		"boat":
			_boat()
		_:
			_question()
	draw_set_transform(Vector2.ZERO)


## Nadirlik simgesi: renk tek başına yetmesin (renk körü oyuncu da ayırsın). Sıradan daire,
## Güzel üçgen, Nadir karo, Destansı yıldız, Efsanevi dört köşeli parıltı, Masalsı madalyon.
## Dolgusu tint, dış çizgisi koyu.
func _rarity(shape: String) -> void:
	var ink := Color("#2a160a")
	var c := Vector2(50, 50)
	match shape:
		"triangle":
			_outlined(PackedVector2Array([Vector2(50, 10), Vector2(91, 84), Vector2(9, 84)]), ink)
		"diamond":
			_outlined(PackedVector2Array([Vector2(50, 6), Vector2(88, 50), Vector2(50, 94), Vector2(12, 50)]), ink)
		"star":
			_outlined(_star_points(c + Vector2(0, 3), 46.0, 20.0, 5), ink)
		"sparkle":
			_outlined(_star_points(c, 48.0, 13.0, 4), ink)
		"medallion":
			draw_circle(c, 46, ink)
			draw_circle(c, 39, tint)
			draw_arc(c, 30, 0.0, TAU, 32, ink, 4.0, true)
			_outlined(_star_points(c + Vector2(0, 2), 22.0, 9.0, 5), ink)
		_:
			draw_circle(c, 40, ink)
			draw_circle(c, 33, tint)


func _outlined(points: PackedVector2Array, ink: Color) -> void:
	draw_colored_polygon(points, tint)
	var loop := points.duplicate()
	loop.append(points[0])
	draw_polyline(loop, ink, 7.0, true)


static func _star_points(center: Vector2, outer: float, inner: float, tips: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in tips * 2:
		var r := outer if i % 2 == 0 else inner
		var a := -PI * 0.5 + i * PI / tips
		points.append(center + Vector2(cos(a), sin(a)) * r)
	return points


func _question() -> void:
	_round_rect(Rect2(14, 14, 72, 72), Color("#5b6bd6"), 36)
	draw_arc(Vector2(50, 40), 14, PI, TAU + 0.6, 20, Color.WHITE, 9.0, true)
	draw_line(Vector2(56, 52), Vector2(50, 60), Color.WHITE, 9.0, true)
	draw_circle(Vector2(50, 72), 5.5, Color.WHITE)


func _coin() -> void:
	draw_circle(Vector2(50, 55), 40, Color("#a8700c"))
	draw_circle(Vector2(50, 50), 40, GOLD_DARK)
	draw_circle(Vector2(50, 50), 32, GOLD)
	draw_arc(Vector2(50, 50), 25, 0.0, TAU, 40, GOLD_DARK, 5.0, true)
	draw_colored_polygon(PackedVector2Array([Vector2(50, 36), Vector2(60, 50), Vector2(50, 64), Vector2(40, 50)]), GOLD_DARK)
	draw_circle(Vector2(37, 35), 6, Color(1, 1, 1, 0.6))


func _arrow(down: bool) -> void:
	var pts := [Vector2(37, 12), Vector2(63, 12), Vector2(63, 50), Vector2(82, 50), Vector2(50, 88),
			Vector2(18, 50), Vector2(37, 50)]
	var poly := PackedVector2Array()
	for p: Vector2 in pts:
		poly.append(p if down else Vector2(p.x, 100.0 - p.y))
	draw_colored_polygon(poly, tint)


## Hoparlör ve ses dalgaları (ayarlarda ses efektleri).
func _sound() -> void:
	_round_rect(Rect2(14, 38, 18, 26), INK, 4)
	draw_colored_polygon(PackedVector2Array([Vector2(30, 38), Vector2(52, 20), Vector2(52, 82), Vector2(30, 64)]), INK)
	for i in 3:
		var r := 14.0 + i * 11.0
		draw_arc(Vector2(52, 51), r, -0.8, 0.8, 18, GOLD.darkened(0.15 * i), 6.0, true)


## Nota (ayarlarda müzik).
func _music() -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(38, 22), Vector2(80, 12), Vector2(80, 24), Vector2(38, 34)]), INK)
	_round_rect(Rect2(34, 22, 7, 52), INK, 3)
	_round_rect(Rect2(76, 12, 7, 52), INK, 3)
	draw_circle(Vector2(30, 76), 12, GOLD_DARK)
	draw_circle(Vector2(30, 74), 11, GOLD)
	draw_circle(Vector2(72, 66), 12, GOLD_DARK)
	draw_circle(Vector2(72, 64), 11, GOLD)


## Titreşen telefon.
func _vibration() -> void:
	_round_rect(Rect2(34, 14, 32, 72), INK, 8)
	_round_rect(Rect2(38, 20, 24, 56), Color("#8fd3ff"), 4)
	for side: float in [-1.0, 1.0]:
		var x := 50.0 + side * 26.0
		draw_line(Vector2(x, 34), Vector2(x + side * 6.0, 42), GOLD_DARK, 5.0, true)
		draw_line(Vector2(x + side * 6.0, 42), Vector2(x, 50), GOLD_DARK, 5.0, true)
		draw_line(Vector2(x, 50), Vector2(x + side * 6.0, 58), GOLD_DARK, 5.0, true)


## Kolay çekme: tüy.
func _easy() -> void:
	var feather := Color("#7fd18b")
	draw_colored_polygon(PackedVector2Array([Vector2(72, 12), Vector2(86, 30), Vector2(56, 70), Vector2(38, 76),
			Vector2(44, 58)]), feather)
	draw_colored_polygon(PackedVector2Array([Vector2(72, 12), Vector2(44, 58), Vector2(38, 76), Vector2(30, 52)]),
			feather.darkened(0.2))
	draw_line(Vector2(76, 20), Vector2(20, 88), WOOD_DARK, 5.0, true)


## Dünya (dil seçimi).
func _globe() -> void:
	draw_circle(Vector2(50, 50), 38, Color("#2f80c9"))
	draw_circle(Vector2(50, 50), 32, Color("#4aa3e8"))
	var land := Color("#6cc070")
	draw_colored_polygon(PackedVector2Array([Vector2(30, 30), Vector2(48, 24), Vector2(52, 40), Vector2(40, 52),
			Vector2(28, 46)]), land)
	draw_colored_polygon(PackedVector2Array([Vector2(56, 54), Vector2(74, 50), Vector2(76, 66), Vector2(60, 76)]), land)
	draw_circle(Vector2(38, 32), 5, Color(1, 1, 1, 0.5))


## Çark (ayarlar; görseli yoksa).
func _gear() -> void:
	for i in 8:
		var a := i * TAU / 8.0
		var c := Vector2(50, 50) + Vector2(cos(a), sin(a)) * 32.0
		draw_circle(c, 9, STEEL_DARK)
	draw_circle(Vector2(50, 50), 32, STEEL_DARK)
	draw_circle(Vector2(50, 50), 26, STEEL)
	draw_circle(Vector2(50, 50), 11, STEEL_DARK)


## İşaret eden el (görseli yoksa basit bir ok).
func _hand() -> void:
	var skin := Color("#f2c49b")
	_round_rect(Rect2(40, 10, 18, 50), skin, 9)
	_round_rect(Rect2(26, 44, 50, 42), skin, 16)
	draw_arc(Vector2(49, 18), 9, PI, TAU, 10, skin.darkened(0.3), 3.0, true)


## Olta: kamış, makara ve misina.
func _rod() -> void:
	draw_line(Vector2(18, 88), Vector2(84, 12), WOOD_DARK, 9.0, true)
	draw_line(Vector2(18, 88), Vector2(84, 12), WOOD, 5.0, true)
	_round_rect(Rect2(12, 74, 22, 14), Color("#c69a6b"), 6)
	draw_circle(Vector2(34, 66), 10, STEEL_DARK)
	draw_circle(Vector2(34, 66), 6, STEEL)
	draw_line(Vector2(84, 12), Vector2(86, 62), Color(1, 1, 1, 0.85), 2.0, true)
	_bobber_at(Vector2(86, 70), 9.0)


func _reel() -> void:
	draw_circle(Vector2(50, 54), 36, STEEL_DARK)
	draw_circle(Vector2(50, 54), 30, STEEL)
	draw_circle(Vector2(50, 54), 12, STEEL_DARK)
	draw_line(Vector2(50, 54), Vector2(80, 30), INK, 8.0, true)
	draw_circle(Vector2(82, 28), 8, WOOD)


## Misina makarası: iki kenar, sarılı misina ve dışarı sarkan ucu.
func _line_spool() -> void:
	var line := Color("#8fd3ff")
	_round_rect(Rect2(30, 26, 40, 48), line, 6)
	for i in 5:
		draw_line(Vector2(30, 32 + i * 9), Vector2(70, 36 + i * 9), Color(1, 1, 1, 0.75), 2.5, true)
	_round_rect(Rect2(20, 16, 60, 13), WOOD_DARK, 6)
	_round_rect(Rect2(20, 71, 60, 13), WOOD_DARK, 6)
	draw_circle(Vector2(50, 22), 4, WOOD)
	draw_polyline(PackedVector2Array([Vector2(70, 46), Vector2(82, 40), Vector2(88, 50), Vector2(84, 62)]), line, 3.0, true)


## Yem kavanozu: cam, içinde toprak, kapaktan kıvrılan pembe bir solucan.
func _bait_jar() -> void:
	_round_rect(Rect2(24, 30, 52, 60), Color("#dceff5"), 12)
	_round_rect(Rect2(29, 50, 42, 35), Color("#7a4f22"), 8)
	draw_circle(Vector2(40, 60), 3, Color("#5a3a18"))
	draw_circle(Vector2(58, 70), 3, Color("#5a3a18"))
	_round_rect(Rect2(21, 22, 58, 13), RED, 6)
	var worm := PackedVector2Array([Vector2(44, 24), Vector2(38, 13), Vector2(47, 6), Vector2(58, 10), Vector2(60, 20)])
	draw_polyline(worm, Color("#c85a74"), 9.0, true)
	draw_polyline(worm, Color("#f08aa0"), 6.0, true)
	draw_line(Vector2(34, 36), Vector2(34, 80), Color(1, 1, 1, 0.55), 4.0, true)


## Kepçe: tahta sap, çember ve ağ.
func _net() -> void:
	draw_line(Vector2(14, 90), Vector2(46, 54), WOOD_DARK, 9.0, true)
	draw_line(Vector2(14, 90), Vector2(46, 54), WOOD, 5.0, true)
	var center := Vector2(62, 38)
	var r := 26.0
	draw_circle(center, r, Color(1, 1, 1, 0.18))
	for k: float in [-16.0, -8.0, 0.0, 8.0, 16.0]:
		var half := sqrt(r * r - k * k)
		draw_line(center + Vector2(-half, k), center + Vector2(half, k), Color(1, 1, 1, 0.65), 2.0, true)
		draw_line(center + Vector2(k, -half), center + Vector2(k, half), Color(1, 1, 1, 0.65), 2.0, true)
	draw_arc(center, r, 0.0, TAU, 32, STEEL_DARK, 6.0, true)


func _bobber() -> void:
	_bobber_at(Vector2(50, 54), 32.0)


func _bobber_at(center: Vector2, r: float) -> void:
	draw_circle(center, r, Color.WHITE)
	draw_colored_polygon(_arc_points(center, r, r, PI, TAU, 18), RED)
	draw_line(center - Vector2(0, r * 1.6), center - Vector2(0, r), INK, maxf(2.0, r * 0.18), true)
	draw_circle(center + Vector2(-r * 0.35, -r * 0.45), r * 0.18, Color(1, 1, 1, 0.8))


func _hook() -> void:
	draw_line(Vector2(56, 10), Vector2(56, 62), STEEL_DARK, 8.0, true)
	draw_arc(Vector2(42, 62), 14, 0.0, PI, 16, STEEL_DARK, 8.0, true)
	draw_line(Vector2(28, 62), Vector2(32, 50), STEEL_DARK, 8.0, true)
	draw_circle(Vector2(56, 12), 6, STEEL)


## Balık (renk: tint).
func _fish(color: Color) -> void:
	_ellipse(Vector2(46, 52), 32, 20, color.darkened(0.2))
	_ellipse(Vector2(46, 50), 32, 19, color)
	draw_colored_polygon(PackedVector2Array([Vector2(74, 50), Vector2(94, 32), Vector2(90, 50), Vector2(94, 68)]),
			color.darkened(0.15))
	draw_colored_polygon(PackedVector2Array([Vector2(40, 32), Vector2(56, 22), Vector2(60, 34)]), color.darkened(0.25))
	draw_circle(Vector2(28, 46), 6.5, Color.WHITE)
	draw_circle(Vector2(27, 46), 3.5, INK)
	draw_circle(Vector2(26, 44.5), 1.3, Color.WHITE)


func _bucket() -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(20, 36), Vector2(80, 36), Vector2(72, 88), Vector2(28, 88)]), WOOD)
	for y: float in [50.0, 72.0]:
		draw_line(Vector2(22, y), Vector2(78, y), STEEL_DARK, 5.0)
	draw_arc(Vector2(50, 36), 30, PI, TAU, 18, STEEL_DARK, 4.0, true)
	_ellipse(Vector2(50, 36), 30, 7, WATER)


func _shop() -> void:
	for i in 6:
		var x0 := 14.0 + i * 12.0
		var poly := PackedVector2Array([Vector2(x0, 16), Vector2(x0 + 12, 16), Vector2(x0 + 12 + (i - 2.5) * 1.6, 42),
				Vector2(x0 + (i - 2.5) * 1.6, 42)])
		draw_colored_polygon(poly, RED if i % 2 == 0 else Color("#fbf3e4"))
	_round_rect(Rect2(18, 50, 64, 38), Color("#9b6a3c"), 6)
	_round_rect(Rect2(12, 46, 76, 10), Color("#c48c55"), 4)
	draw_circle(Vector2(50, 70), 10, GOLD_DARK)
	draw_circle(Vector2(50, 70), 6, GOLD)


func _gem() -> void:
	var outline := PackedVector2Array([Vector2(50, 8), Vector2(86, 40), Vector2(50, 92), Vector2(14, 40)])
	draw_colored_polygon(outline, tint.darkened(0.25))
	draw_colored_polygon(PackedVector2Array([Vector2(50, 8), Vector2(86, 40), Vector2(50, 50), Vector2(14, 40)]), tint)
	draw_colored_polygon(PackedVector2Array([Vector2(50, 8), Vector2(66, 22), Vector2(50, 40), Vector2(34, 22)]),
			tint.lightened(0.35))
	outline.append(outline[0])
	draw_polyline(outline, tint.darkened(0.55), 4.0, true)


func _star(color: Color) -> void:
	var poly := PackedVector2Array()
	for i in 10:
		var r := 44.0 if i % 2 == 0 else 19.0
		var a := -PI * 0.5 + i * PI / 5.0
		poly.append(Vector2(50, 54) + Vector2(cos(a), sin(a)) * r)
	draw_colored_polygon(poly, color)


## Harita iğnesi: ucu aşağıda (noktayı gösterir), kırmızı baş, beyaz göz.
func _pin() -> void:
	var dark := RED.darkened(0.35)
	draw_colored_polygon(PackedVector2Array([Vector2(30, 46), Vector2(70, 46), Vector2(50, 96)]), dark)
	draw_circle(Vector2(50, 38), 28, dark)
	draw_colored_polygon(PackedVector2Array([Vector2(33, 46), Vector2(67, 46), Vector2(50, 90)]), RED)
	draw_circle(Vector2(50, 37), 25, RED)
	draw_circle(Vector2(50, 37), 10, Color.WHITE)
	draw_circle(Vector2(41, 27), 5, Color(1, 1, 1, 0.55))


## Kürekli sandal (yandan): ahşap gövde, oturak ve kürek.
func _boat() -> void:
	draw_line(Vector2(22, 30), Vector2(64, 72), WOOD_DARK, 6.0, true)
	draw_colored_polygon(PackedVector2Array([Vector2(8, 50), Vector2(92, 50), Vector2(80, 74), Vector2(22, 74)]), WOOD_DARK)
	draw_colored_polygon(PackedVector2Array([Vector2(12, 52), Vector2(88, 52), Vector2(78, 70), Vector2(24, 70)]), WOOD)
	draw_line(Vector2(16, 58), Vector2(84, 58), WOOD.lightened(0.25), 4.0, true)
	draw_line(Vector2(12, 80), Vector2(88, 80), WATER, 5.0, true)


## Bölge rozeti (Ersin'in görseli yoksa): yuvarlak su zemininde bölgenin simgesi.
func _zone(id: String) -> void:
	var water := Color("#5cc4dc") if id != "deep_water" else Color("#2f6fa8")
	draw_circle(Vector2(50, 50), 46, Color("#2b4a5c"))
	draw_circle(Vector2(50, 50), 41, water)
	match id:
		"dock_cove":
			for i in 4:
				_round_rect(Rect2(34, 18 + i * 16, 32, 12), WOOD if i % 2 == 0 else WOOD.lightened(0.12), 3)
			_round_rect(Rect2(30, 14, 6, 66), WOOD_DARK, 2)
			_round_rect(Rect2(64, 14, 6, 66), WOOD_DARK, 2)
		"reeds":
			for k in 3:
				var x := 34.0 + k * 15.0
				draw_line(Vector2(x, 82), Vector2(x + 2, 34 + k * 5), Color("#3f7a35"), 4.0, true)
				_round_rect(Rect2(x - 3, 30 + k * 5, 9, 20), Color("#7a4f22"), 4)
			draw_colored_polygon(PackedVector2Array([Vector2(26, 82), Vector2(36, 52), Vector2(40, 82)]), Color("#5aa548"))
			draw_colored_polygon(PackedVector2Array([Vector2(60, 82), Vector2(72, 56), Vector2(74, 82)]), Color("#5aa548"))
		"lily_cove":
			_ellipse(Vector2(48, 58), 28, 18, Color("#3f9a45"))
			draw_colored_polygon(PackedVector2Array([Vector2(48, 58), Vector2(76, 50), Vector2(76, 64)]), water)
			for k in 6:
				var a := TAU * k / 6.0
				_ellipse(Vector2(44, 42) + Vector2(cos(a), sin(a)) * 8.0, 7, 7, Color("#f6a6c8"))
			draw_circle(Vector2(44, 42), 6, Color("#ffd23f"))
		"rocky_point":
			_ellipse(Vector2(40, 60), 22, 16, Color("#7d838a"))
			_ellipse(Vector2(62, 54), 16, 13, Color("#9aa1a8"))
			_ellipse(Vector2(36, 54), 9, 6, Color("#b4bac0"))
			_ellipse(Vector2(60, 48), 6, 4, Color("#c4cad0"))
		"stream_mouth":
			for k in 3:
				var y := 36.0 + k * 14.0
				var pts := PackedVector2Array()
				for i in 9:
					pts.append(Vector2(22 + i * 7.0, y + sin(i * 1.2 + k) * 4.0))
				draw_polyline(pts, Color.WHITE, 5.0, true)
			_ellipse(Vector2(30, 76), 8, 5, Color("#9aa1a8"))
			_ellipse(Vector2(70, 74), 7, 4, Color("#9aa1a8"))
		"deep_water":
			_bobber_at(Vector2(50, 56), 20.0)
			draw_arc(Vector2(50, 76), 20, 0.2, PI - 0.2, 12, Color(1, 1, 1, 0.7), 4.0, true)
		_:
			_fish(Color("#f2a541"))


func _ellipse(center: Vector2, rx: float, ry: float, color: Color) -> void:
	var points := _arc_points(center, rx, ry, 0.0, TAU, 28)
	points.remove_at(points.size() - 1)
	draw_colored_polygon(points, color)


static func _arc_points(center: Vector2, rx: float, ry: float, from: float, to: float, steps: int) -> PackedVector2Array:
	var points := PackedVector2Array()
	for i in steps + 1:
		var a := lerpf(from, to, float(i) / steps)
		points.append(center + Vector2(cos(a) * rx, sin(a) * ry))
	return points


func _round_rect(rect: Rect2, color: Color, radius: int) -> void:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(radius)
	sb.anti_aliasing = true
	draw_style_box(sb, rect)
