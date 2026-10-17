extends BaseTest
## HUD: ipucu çubuğuna giren her söz iki dilde de tek satıra sığar (çubuk iki yandaki eylem
## düğmesi payının arasında; taşan yazı eylem düğmesinin altında kalırdı).

## İpucu çubuğunda görünen sözler: oyunun ipuçları, Dede'nin öğütleri ve uyarıları, Nine'nin sözleri
## (main._hint_key ve _say). Kartta ve dükkânda görünenler (UI_DEDE_CARD_, UI_NINE_SHOP_) değil.
const HINT_PREFIXES: Array[String] = ["UI_HINT_", "UI_DEDE_TIP_", "UI_NINE_LINE_"]
const HINT_KEYS: Array[String] = ["UI_DEDE_BUCKET", "UI_DEDE_BAIT_OUT", "UI_DEDE_BOAT", "UI_DEDE_BOAT_SHOP",
		"UI_DEDE_BOAT_DEEP", "UI_DEDE_GATE", "UI_DEDE_LEGEND_NEAR", "UI_DEDE_ZONE_OPEN"]


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
