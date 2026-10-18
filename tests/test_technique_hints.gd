extends BaseTest
## Yeni bir teknikte ilk atışların ipuçları (TechniqueHints): şamandıra sayılmaz, ilk 3 atış
## boyunca (atış sırasında da) görünür, her durumun sözü çeviride var.


func test_casts_are_counted_per_technique() -> void:
	var save := SaveData.create_new(0)
	assert_eq(TechniqueHints.casts(save, "spin"), 0, "başta atış yok")
	assert_true(not TechniqueHints.active(save, "float"), "şamandıranın ipuçları main'de (ilk 3 balık)")
	TechniqueHints.note_cast(save, "float")
	assert_eq(TechniqueHints.casts(save, "float"), 0, "şamandıra sayılmaz")
	for i in TechniqueHints.CASTS:
		TechniqueHints.note_cast(save, "spin")
		assert_true(TechniqueHints.active(save, "spin"), "%d. atışta ipucu var" % (i + 1))
	TechniqueHints.note_cast(save, "spin")
	assert_true(not TechniqueHints.active(save, "spin"), "%d. atıştan sonra ipucu yok" % TechniqueHints.CASTS)
	# Kayıttan geri gelen sayı (JSON'da float) da sayılır.
	var parsed: Dictionary = JSON.parse_string(JSON.stringify(save.to_dict()))
	var back := SaveData.from_dict(parsed)
	assert_eq(TechniqueHints.casts(back, "spin"), TechniqueHints.CASTS + 1, "sayı kayıtla korunur")


func test_spin_hints_follow_the_state() -> void:
	assert_eq(TechniqueHints.key("spin", FishingSession.State.WAITING), "UI_HINT_SPIN_REEL")
	assert_eq(TechniqueHints.key("spin", FishingSession.State.FOLLOWING), "UI_HINT_SPIN_FOLLOW")
	assert_eq(TechniqueHints.key("spin", FishingSession.State.BITING), "UI_HINT_SPIN_STRIKE")
	assert_eq(TechniqueHints.key("spin", FishingSession.State.FIGHTING), "UI_HINT_REEL")
	assert_eq(TechniqueHints.key("spin", FishingSession.State.IDLE), "UI_DEDE_TECH_FIRST_spin", "boşta: nereye atılır")
	assert_eq(TechniqueHints.key("spin", FishingSession.State.RETRIEVING), "", "geri sararken önceki söz kalır")


func test_every_hint_is_translated() -> void:
	var rows := {}
	var f := FileAccess.open("res://localization/strings.csv", FileAccess.READ)
	while f != null and not f.eof_reached():
		var row := f.get_csv_line()
		if row.size() >= 3:
			rows[row[0]] = row
	for technique: String in ContentDB.TECHNIQUES:
		if technique == "float" or not content().has_technique(technique):
			continue
		for state: int in FishingSession.State.values():
			var key := TechniqueHints.key(technique, state as FishingSession.State)
			if key.is_empty():
				continue
			assert_true(rows.has(key), "%s çeviride yok" % key)
		for key: String in ["UI_TECH_" + technique, "UI_TECH_%s_HOW" % technique, "UI_DEDE_TECH_OPEN_" + technique,
				"UI_DEDE_TECH_FIRST_" + technique]:
			assert_true(rows.has(key), "%s çeviride yok" % key)
	assert_true(rows.has("UI_TECH_float") and rows.has("UI_TECH_float_HOW"), "şamandıranın adı ve anlatımı")
