extends BaseTest
## Görsel boru hattı: sahte bir macenta sayfası üretilir, arka planı silinir ve nesnelere bölünür.

const W := 600
const H := 400
const MAGENTA := Color8(254, 2, 252)


## 3x2 sayfa: daire, yüzük (ortası arka plan), üç bilye, kare, dikdörtgen, üçgen.
static func _sheet() -> Image:
	var img := Image.create_empty(W, H, false, Image.FORMAT_RGBA8)
	img.fill(MAGENTA)
	# Hafif gürültü: yapay zekâ arka planı hiç tam düz değildir.
	for i in 400:
		img.set_pixel((i * 37) % W, (i * 91) % H, Color8(240, 12, 238))
	_disc(img, Vector2(100, 100), 55, Color8(240, 140, 40))
	_disc(img, Vector2(300, 100), 60, Color8(245, 200, 30))
	_disc(img, Vector2(300, 100), 25, MAGENTA)
	for p: Vector2 in [Vector2(470, 80), Vector2(530, 90), Vector2(500, 140)]:
		_disc(img, p, 18, Color8(60, 170, 230))
	img.fill_rect(Rect2i(50, 250, 100, 100), Color8(80, 200, 90))
	img.fill_rect(Rect2i(230, 270, 140, 60), Color8(150, 90, 50))
	for y in range(240, 360):
		var half := (y - 240) >> 1
		for x in range(500 - half, 500 + half + 1):
			img.set_pixel(x, y, Color8(40, 40, 50))
	return img


static func _disc(img: Image, center: Vector2, radius: float, color: Color) -> void:
	for y in range(int(center.y - radius) - 1, int(center.y + radius) + 2):
		for x in range(int(center.x - radius) - 1, int(center.x + radius) + 2):
			var d := Vector2(x + 0.5, y + 0.5).distance_to(center)
			if d <= radius - 0.5:
				img.set_pixel(x, y, color)
			elif d <= radius + 0.5:
				# Kenar yumuşatma: arka planla karışık piksel.
				img.set_pixel(x, y, img.get_pixel(x, y).lerp(color, radius + 0.5 - d))


func test_background_is_removed() -> void:
	var sheet := ArtSheet.new()
	var keyed := sheet.remove_background(_sheet())
	assert_eq(sheet.errors.size(), 0, "hata yok: " + ", ".join(sheet.errors))
	assert_true(sheet.background.is_equal_approx(MAGENTA), "arka plan rengi kenarlardan bulunur")
	assert_eq(keyed.get_pixel(5, 5).a, 0.0, "köşe saydam")
	assert_eq(keyed.get_pixel(200, 200).a, 0.0, "nesneler arası saydam")
	assert_eq(keyed.get_pixel(300, 100).a, 0.0, "yüzüğün ortası saydam")
	var center := keyed.get_pixel(100, 100)
	assert_eq(center.a, 1.0, "nesne opak")
	assert_true(center.is_equal_approx(Color8(240, 140, 40)), "nesne rengi korunur")
	# Turuncu dairenin yarı saydam kenar pikselleri: macenta karışımı geri çıkarılmış olmalı.
	var soft := 0
	for y in range(40, 160):
		for x in range(40, 160):
			var c := keyed.get_pixel(x, y)
			if c.a > 0.1 and c.a < 0.95:
				soft += 1
				assert_true(c.b < 0.4, "kenarda macenta sızıntısı var: %s" % c)
	assert_true(soft > 20, "kenar yumuşak (yarı saydam piksel: %d)" % soft)


func test_sheet_splits_into_objects() -> void:
	var sheet := ArtSheet.new()
	var pieces := sheet.split(sheet.remove_background(_sheet()), 3, 2)
	assert_eq(sheet.errors.size(), 0, "hata yok: " + ", ".join(sheet.errors))
	assert_eq(pieces.size(), 6, "6 nesne")
	if pieces.size() != 6:
		return
	assert_between(pieces[0].get_used_rect().size.x, 108, 118, "daire genişliği")
	assert_between(pieces[2].get_used_rect().size.x, 90, 110, "üç bilye tek nesne olarak kalır")
	assert_between(pieces[3].get_used_rect().size.x, 99, 103, "kare")
	for piece in pieces:
		var icon := ArtSheet.fit_square(piece, 64, 0.08)
		assert_eq(icon.get_size(), Vector2i(64, 64), "64x64 ikon")
		assert_eq(icon.get_pixel(1, 1).a, 0.0, "kenar payı saydam")


func test_rejects_fake_checkerboard() -> void:
	var img := Image.create_empty(120, 80, false, Image.FORMAT_RGBA8)
	for y in 80:
		for x in 120:
			img.set_pixel(x, y, Color(0.8, 0.8, 0.8) if ((x >> 3) + (y >> 3)) % 2 == 0 else Color.WHITE)
	var sheet := ArtSheet.new()
	sheet.remove_background(img)
	assert_true(not sheet.errors.is_empty(), "dama desenli arka plan reddedilir")


func test_transparent_input_is_kept() -> void:
	var img := Image.create_empty(40, 40, false, Image.FORMAT_RGBA8)
	img.fill_rect(Rect2i(10, 10, 20, 20), Color.RED)
	var keyed := ArtSheet.new().remove_background(img)
	assert_eq(keyed.get_pixel(15, 15), Color.RED, "zaten saydam görsel değişmez")
	var box := ArtSheet.fit_box(keyed, 30, true, 0.0)
	assert_eq(box.get_size(), Vector2i(20, 20), "kırpılır, küçültülmez")


## art_sheets.json: her ızgaralı sayfada ad sayısı ızgarayla aynı ve adlar tekrarsız.
func test_art_sheets_are_consistent() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/art_sheets.json"))
	assert_eq(typeof(parsed), TYPE_DICTIONARY, "art_sheets.json okunur")
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var seen := {}
	var files := {}
	for raw: Variant in (parsed as Dictionary)["sheets"]:
		var def: Dictionary = raw
		var file := str(def["file"])
		assert_true(not files.has(file), "sayfa adı tekrar: " + file)
		files[file] = true
		if bool(def.get("reference", false)):
			continue
		var names: Array = def["names"]
		if def.has("grid"):
			var grid: Array = def["grid"]
			assert_eq(names.size(), int(grid[0]) * int(grid[1]), "%s: ad sayısı ızgarayla aynı" % file)
		for n: Variant in names:
			var key := str(def["out"]) + "/" + str(n)
			assert_true(not seen.has(key), "çıktı adı tekrar: " + key)
			seen[key] = true
	for needed: String in ["style_sheet", "ui_1", "portraits", "logo", "app_icon"]:
		assert_true(files.has(needed), "sayfa var: " + needed)
