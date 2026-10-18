extends BaseTest
## HUD: ipucu çubuğuna giren her söz iki dilde de tek satıra sığar (çubuk iki yandaki eylem
## düğmesi payının arasında; taşan yazı eylem düğmesinin altında kalırdı).

## İpucu çubuğunda görünen sözler: oyunun ipuçları, Dede'nin öğütleri ve uyarıları, Nine'nin sözleri
## (main._hint_key ve _say). Kartta ve dükkânda görünenler (UI_DEDE_CARD_, UI_NINE_SHOP_) değil.
const HINT_PREFIXES: Array[String] = ["UI_HINT_", "UI_DEDE_TIP_", "UI_NINE_LINE_", "UI_DEDE_TECH_"]
const HINT_KEYS: Array[String] = ["UI_DEDE_BUCKET", "UI_DEDE_BAIT_OUT", "UI_DEDE_BOAT", "UI_DEDE_BOAT_SHOP",
		"UI_DEDE_BOAT_DEEP", "UI_DEDE_GATE", "UI_DEDE_LEGEND_NEAR", "UI_DEDE_ZONE_OPEN", "UI_DEDE_SNAG", "UI_DEDE_FLY_HERE",
		"UI_DEDE_FLY_STILL"]


func test_hint_lines_fit_one_line() -> void:
	var room := Hud.hint_text_room()
	assert_true(room > 800.0, "ipucu çubuğunda yer var (%.0f)" % room)
	var font := UiKit.body_font()
	var checked := 0
	var f := FileAccess.open("res://localization/strings.csv", FileAccess.READ)
	while f != null and not f.eof_reached():
		var row := f.get_csv_line()
		if row.size() < 3 or not _is_hint(row[0]):
			continue
		for column in [1, 2]:
			var width := font.get_string_size(row[column], HORIZONTAL_ALIGNMENT_LEFT, -1, UiKit.SIZE_BODY).x
			assert_true(width <= room, "%s (%s) ipucu çubuğuna sığmıyor: %.0f > %.0f" % [row[0],
					"en" if column == 1 else "tr", width, room])
			checked += 1
	assert_true(checked >= 30, "ipucu sözleri denetlendi (%d)" % checked)


## Dede'nin fazla iri balıktan sonraki takım öğüdü biçimli söz: en geniş kamış ve misina adıyla
## (cümlenin ortasında küçük harfle) ve en büyük rütbeyle iki dilde tek satıra sığar; gerekirse
## ipucu çubuğu yazıyı Hud.HINT_MIN_SIZE'a kadar küçültür.
func test_gear_advice_fits_one_line() -> void:
	var room := Hud.hint_text_room()
	var font := UiKit.body_font()
	var rows := {}
	var f := FileAccess.open("res://localization/strings.csv", FileAccess.READ)
	while f != null and not f.eof_reached():
		var row := f.get_csv_line()
		if row.size() >= 3:
			rows[row[0]] = row
	for column: int in [1, 2]:
		var widest := { "rod": "", "line": "" }
		for g in content().gear:
			var category := str(g["category"])
			if not category in widest:
				continue
			var gear_name: String = (rows["GEAR_" + str(g["id"])] as PackedStringArray)[column]
			gear_name = gear_name.left(1).to_lower() + gear_name.substr(1)
			if _width(font, gear_name) > _width(font, str(widest[category])):
				widest[category] = gear_name
		var listed: String = (rows["UI_LIST_AND"] as PackedStringArray)[column] % [widest["rod"], widest["line"]]
		var lines := PackedStringArray()
		for key: String in ["UI_DEDE_TOO_BIG_BUY", "UI_DEDE_TOO_BIG_EQUIP"]:
			lines.append((rows[key] as PackedStringArray)[column] % listed)
		lines.append((rows["UI_DEDE_TOO_BIG_BOTH"] as PackedStringArray)[column] % [widest["rod"], widest["line"]])
		lines.append((rows["UI_DEDE_TOO_BIG_RANK"] as PackedStringArray)[column] % content().rank_xp.size())
		for text in lines:
			var size := UiKit.fit_size(text, font, UiKit.SIZE_BODY, room, Hud.HINT_MIN_SIZE)
			assert_true(_width(font, text, size) <= room, "takım öğüdü %d boyda da sığmıyor (%s): %s (%.0f > %.0f)" % [
					size, "en" if column == 1 else "tr", text, _width(font, text, size), room])


static func _width(font: Font, text: String, size: int = UiKit.SIZE_BODY) -> float:
	return font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x


static func _is_hint(key: String) -> bool:
	if key in HINT_KEYS:
		return true
	for prefix in HINT_PREFIXES:
		if key.begins_with(prefix):
			return true
	return false


## Ölçüm (ayarlarda sürüm yazısına 5 dokunuş): sol üstteki yazı her sürümde görünür; kapanınca
## yalnızca geliştirme sürümünde (FPS).
func test_perf_label() -> void:
	var hud := Hud.new()
	hud.call("_build_bottom")
	var fps: Label = hud.get("_fps")
	hud.perf = true
	assert_true(fps != null and fps.visible, "ölçüm açıkken görünür")
	assert_eq(fps.get_theme_constant("outline_size"), 8, "ölçümde dış çizgili (açık zeminde okunsun)")
	hud.perf = false
	assert_eq(fps.visible, OS.is_debug_build() and not OS.has_feature("movie"), "kapalıyken yalnızca geliştirme sürümünde")
	assert_eq(fps.get_theme_constant("outline_size"), 0, "kapalıyken dış çizgisiz")
	hud.free()
