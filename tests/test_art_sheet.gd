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


## Parlak mor (R ile B yakın; Destansı rozet ve çerçeve) "all" temizlikte solar; "edge" yalnızca
## arka plana değen kenarı temizler, içi korunur. Kenardaki macenta sızıntısı "edge"de de gider.
func test_edge_despill_keeps_purple() -> void:
	var purple := Color8(241, 119, 250)
	var img := Image.create_empty(160, 120, false, Image.FORMAT_RGBA8)
	img.fill(MAGENTA)
	_disc(img, Vector2(50, 60), 30, purple)
	_disc(img, Vector2(115, 60), 30, Color8(240, 140, 40))
	var all := ArtSheet.new().remove_background(img, "all")
	var edge := ArtSheet.new().remove_background(img, "edge")
	var none := ArtSheet.new().remove_background(img, "none")
	assert_true(all.get_pixel(50, 60).r < 0.75, "all: morun içi solar (bu yüzden edge var)")
	assert_true(edge.get_pixel(50, 60).is_equal_approx(purple), "edge: morun içi korunur")
	assert_true(none.get_pixel(50, 60).is_equal_approx(purple), "none: dokunulmaz")
	var soft := 0
	for y in range(25, 96):
		for x in range(80, 150):
			var c := edge.get_pixel(x, y)
			if c.a > 0.1 and c.a < 0.95:
				soft += 1
				assert_true(c.b < 0.4, "edge: turuncunun kenarında macenta sızıntısı var: %s" % c)
	assert_true(soft > 10, "kenar yumuşak (yarı saydam piksel: %d)" % soft)


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
	for needed: String in ["style_sheet", "ui_1", "ui_2", "ui_frames", "ui_buttons", "rarity_frames",
			"rarity_badges", "portraits", "portraits_nine", "logo", "app_icon", "gear_rods_1", "gear_extras"]:
		assert_true(files.has(needed), "sayfa var: " + needed)


## Kesilen her 9 dilimli çerçevenin ve düğmenin (fit "trim") UiKit'te kenar payları var.
func test_frame_sheets_have_slices() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://data/art_sheets.json"))
	var frames := 0
	for raw: Variant in (parsed as Dictionary)["sheets"]:
		var def: Dictionary = raw
		if str(def.get("fit", "")) != "trim":
			continue
		assert_eq(str(def["out"]), ItemArt.FRAMES.get_base_dir(), "%s: çerçeve klasörü" % def["file"])
		for n: Variant in def["names"]:
			frames += 1
			assert_eq(UiKit.frame_slices(str(n)).size(), 4, "kenar payı var: " + str(n))
	assert_true(frames >= 18, "çerçeve, düğme ve nadirlik çerçeveleri tanımlı")


## Görsel yokken kodla çizilen stil döner; görsel gelince 9 dilimli doku köşe boyuna göre
## ölçeklenir ve içerik payları korunur.
func test_framed_scales_art_and_keeps_layout() -> void:
	var fallback := UiKit.pill_style()
	ItemArt.register_frame("pill", null)
	assert_true(UiKit.framed("pill", fallback, 30.0) == fallback, "görsel yoksa kodla çizilen stil")
	var img := Image.create_empty(200, 100, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	ItemArt.register_frame("pill", ImageTexture.create_from_image(img))
	var sb := UiKit.framed("pill", fallback, 30.0) as StyleBoxTexture
	assert_true(sb != null, "görsel varsa 9 dilimli doku")
	if sb != null:
		# Kısa kenar 100, en kalın pay 0,5 → 50 piksel; 30'a inmesi için 0,6 ölçek.
		assert_eq(sb.texture.get_size(), Vector2(120, 60), "doku ölçeklenir")
		assert_between(sb.texture_margin_left, 29.9, 30.1, "sol pay köşe boyu")
		assert_between(sb.texture_margin_top, 17.9, 18.1, "üst pay orantılı")
		assert_eq(sb.get_content_margin(SIDE_LEFT), fallback.get_content_margin(SIDE_LEFT), "içerik payı korunur")
		assert_eq(sb.get_content_margin(SIDE_TOP), fallback.get_content_margin(SIDE_TOP), "içerik payı korunur")
	ItemArt.register_frame("pill", null)


## Paletin düğme renkleri arayüz kitindeki düğmeyi kullanır; basılı hâli biraz koyu.
func test_button_art_matches_palette() -> void:
	var img := Image.create_empty(300, 120, false, Image.FORMAT_RGBA8)
	img.fill(Color.WHITE)
	ItemArt.register_frame("button_green", ImageTexture.create_from_image(img))
	var normal := UiKit._button_art(UiKit.SUCCESS, false, 30)
	var pressed := UiKit._button_art(UiKit.SUCCESS, true, 30)
	assert_true(normal != null and pressed != null, "yeşil düğme görseli kullanılır")
	if normal != null and pressed != null:
		assert_true(pressed.modulate_color.v < normal.modulate_color.v, "basılıyken koyu")
		assert_true(pressed.content_margin_top > normal.content_margin_top, "basılıyken yazı aşağıda")
	assert_true(UiKit._button_art(Color("#123456"), false, 30) == null, "palet dışı renk kodla çizilir")
	ItemArt.register_frame("button_green", null)
	assert_true(UiKit._button_art(UiKit.SUCCESS, false, 30) == null, "görsel yoksa kodla çizilir")
