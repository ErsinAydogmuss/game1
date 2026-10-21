extends BaseTest
## Çöp (Dalga 4): dipte tutulan balığın yanında ve tuzağın içeriğiyle çıkar; ne çıkacağı önceden belli
## (aynı seed aynı çöp); oranlar kurallardaki gibi; toplanınca göl sevgisi verir, kovaya girmez, para
## vermez; Dede'nin her eşyaya sözü ve eşyanın adı, görseli var.

const ROLLS := 20_000


func test_same_seed_same_trash() -> void:
	var rules := content().rules
	for seed_value: int in [1, 77, 4242, 99999]:
		assert_eq(Trash.with_catch(rules, seed_value, "bottom"), Trash.with_catch(rules, seed_value, "bottom"),
				"seed %d: balığın yanındaki çöp aynı" % seed_value)
		assert_eq(Trash.in_trap(rules, seed_value, 3), Trash.in_trap(rules, seed_value, 3),
				"seed %d: tuzağın çöpü aynı" % seed_value)


func test_only_the_bottom_brings_trash_with_a_fish() -> void:
	var rules := content().rules
	var surface := 0
	var bottom := 0
	for k in 4000:
		for technique: String in ["float", "spin", "fly"]:
			if not Trash.with_catch(rules, k, technique).is_empty():
				surface += 1
		if not Trash.with_catch(rules, k, "bottom").is_empty():
			bottom += 1
	assert_eq(surface, 0, "şamandıra, spin ve sinekte çöp yok")
	assert_true(bottom > 0, "dipte çöp çıkar (%d / 4000)" % bottom)


func test_odds_follow_the_rules() -> void:
	var rules := content().rules
	var with_fish := 0
	var in_traps := 0
	var counts := {}
	for k in ROLLS:
		if not Trash.with_catch(rules, k, "bottom").is_empty():
			with_fish += 1
		var item := Trash.in_trap(rules, 4242, k)
		if not item.is_empty():
			in_traps += 1
			counts[item] = int(counts.get(item, 0)) + 1
	var bottom_share := float(with_fish) / ROLLS
	var trap_share := float(in_traps) / ROLLS
	var bottom_want := rules.trash_bottom_ppm / float(Dice.PPM)
	var trap_want := rules.trash_trap_ppm / float(Dice.PPM)
	assert_between(bottom_share, bottom_want - 0.01, bottom_want + 0.01,
			"dipte balığın yanında %%%.1f (kural %%%.0f)" % [bottom_share * 100.0, bottom_want * 100.0])
	assert_between(trap_share, trap_want - 0.01, trap_want + 0.01,
			"tuzakta %%%.1f (kural %%%.0f)" % [trap_share * 100.0, trap_want * 100.0])
	var total := 0
	for w in rules.trash_weights:
		total += w
	for i in rules.trash_ids.size():
		var id := rules.trash_ids[i]
		var share := float(counts.get(id, 0)) / maxf(1.0, in_traps)
		var want := float(rules.trash_weights[i]) / total
		assert_between(share, want - 0.03, want + 0.03, "%s %%%.1f (ağırlık %%%.0f)" % [id, share * 100.0, want * 100.0])


func test_collecting_gives_love_not_coins() -> void:
	var db := content()
	var rules := db.rules
	var save := SaveData.create_new(0)
	save.coins = 120
	var before_bucket := save.bucket.size()
	var result := Trash.collect(rules, save, "boot")
	assert_eq(int(result["love"]), 3, "çizme 3 sevgi")
	assert_eq(save.love, 3, "sevgi kayda")
	assert_eq(save.coins, 120, "para vermez")
	assert_eq(save.bucket.size(), before_bucket, "kovaya girmez")
	assert_eq(int(save.stats.get("trash", 0)), 1, "sayaç")
	assert_eq(Trash.found(save, "boot"), 1, "eşyanın sayacı")
	var key := Trash.collect(rules, save, "rusty_key")
	assert_eq(int(key["love"]), 5, "paslı anahtar 5 sevgi")
	assert_eq(save.love, 8, "sevgi birikir")
	assert_eq(int(save.stats.get("trash", 0)), 2, "iki çöp")
	assert_eq(Trash.found(save, "tin_can"), 0, "teneke henüz yok")
	# Seviye atlama LakeLove'un sonucuyla gelir (bildirim, Dede).
	save.love = rules.love_levels[1] - 1
	var up := Trash.collect(rules, save, "tin_can")
	assert_eq(int(up["new_level"]), 2, "sevgi seviyesi atlar")
	assert_eq(Trash.love_of(rules, "bilinmeyen"), 0, "bilinmeyen eşya sevgi vermez")


func test_every_item_has_a_name_line_and_picture() -> void:
	var rules := content().rules
	var tr_names := {}
	for row in _csv_keys():
		tr_names[row] = true
	for id in rules.trash_ids:
		assert_true(tr_names.has("ITEM_" + id), "%s: ITEM_ çevirisi" % id)
		assert_true(tr_names.has("UI_DEDE_TRASH_" + id), "%s: Dede'nin sözü" % id)
		assert_true(ResourceLoader.exists(ItemArt.ITEMS % id), "%s: görseli" % id)


static func _csv_keys() -> PackedStringArray:
	var keys := PackedStringArray()
	var file := FileAccess.open("res://localization/strings.csv", FileAccess.READ)
	if file == null:
		return keys
	while not file.eof_reached():
		var row := file.get_csv_line()
		if row.size() > 0 and not row[0].is_empty():
			keys.append(row[0])
	return keys
