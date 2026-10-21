extends BaseTest
## "Bugün" paneli (DayPanel) ve çip: her vaktin ve havanın yazısı iki dilde var (anahtarlar kodda
## birleştirilir: test_content_db düz "UI_..." dizgilerini tarar), Dede'nin vakte ve havaya ilk sözleri,
## havanın ne zaman olduğu, saat çipinin dokunma kutusu.


func test_every_phase_and_weather_has_texts() -> void:
	var table := _read_translations()
	for phase: String in DayClock.PHASES:
		for key: String in ["PHASE_", "UI_PHASE_NOW_", "UI_DAY_UNTIL_", "UI_TEA_TO_"]:
			_assert_row(table, key + phase)
		# İlk gecenin sözü Nine'nin feneri (UI_DEDE_LANTERN).
		if phase != "night":
			_assert_row(table, "UI_DEDE_TIME_" + phase)
	for kind: String in Weather.KINDS + ["storm"]:
		_assert_row(table, "WEATHER_" + kind)
		if kind != "clear":
			_assert_row(table, "UI_DEDE_WEATHER_" + kind)
		var detail := DayPanel.weather_detail(kind)
		if not detail.is_empty():
			_assert_row(table, detail)
	assert_eq(DayPanel.weather_detail("rain"), "UI_DAY_DETAIL_rain", "yağmurlu günün gecesi fırtına")
	assert_eq(DayPanel.weather_detail("fog"), "UI_DAY_DETAIL_fog", "sis sabah ve gece")
	assert_eq(DayPanel.weather_detail("clear"), "", "açık havada açıklama yok")


## Saat çipi ve kova: dokunma kutuları en az 122 (hap ince), ekrandaki düğmelerde; olta boşta değilken dokunuş
## almazlar ama görünürler (main set_idle_touch'ı her kare verir); çip çekişmede gizli.
func test_world_chip_is_a_button() -> void:
	var hud := Hud.new()
	hud.call("_build_top")
	hud.call("_build_bottom")
	var chip := hud.world_button
	for b: TouchButton in [chip, hud.bucket_button]:
		assert_true(b != null and b.custom_minimum_size.y >= 122.0, "dokunma kutusu en az 122: " + str(b.name))
		assert_true(b in hud.buttons(), "ekrandaki düğmelerde (bot boyutu ve güvenli alanı denetler): " + str(b.name))
	hud.set_line_out(true)
	hud.set_idle_touch(false)
	assert_true(chip.visible and not chip.takes_touch and not hud.bucket_button.takes_touch,
			"olta sudayken görünür, dokunuş almaz")
	hud.set_line_out(false)
	hud.set_idle_touch(true)
	assert_true(chip.takes_touch and hud.bucket_button.takes_touch, "olta boşken dokunulur")
	hud.set_fighting(true)
	assert_true(not chip.visible, "çekişmede gizli")
	hud.set_fighting(false)
	assert_true(chip.visible, "çekişmeden sonra görünür")
	hud.free()


func _assert_row(table: Dictionary, key: String) -> void:
	var row: PackedStringArray = table.get(key, PackedStringArray())
	assert_true(row.size() >= 3 and not row[1].is_empty() and not row[2].is_empty(), "çevirisi yok: " + key)


static func _read_translations() -> Dictionary:
	var table := {}
	var f := FileAccess.open("res://localization/strings.csv", FileAccess.READ)
	if f == null:
		return table
	while not f.eof_reached():
		var row := f.get_csv_line()
		if row.size() >= 1 and not row[0].is_empty():
			table[row[0]] = row
	return table
