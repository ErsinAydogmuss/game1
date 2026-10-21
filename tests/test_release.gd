extends BaseTest
## Tut-bırak (Dalga 4, 3. adım; docs/gdd.md §10.4, §10.5): kovadan göle bırakmak para vermez, göl sevgisi
## verir (nadirliğe göre); defterde bırakılan sayısı ve sayaç; kovadan tür başına en küçüğü (BIRAK) ya da
## en son gireni (kartta "Göle bırak") çıkar; kova paneli türleri bir satırda toplar.


func _save_with(entries: Array) -> SaveData:
	var save := SaveData.create_new(1_700_000_000)
	for e: Array in entries:
		Records.add(save.records, str(e[0]), int(e[1]), 1, 0)
		save.bucket.append({ "fish": str(e[0]), "size_cm": int(e[1]), "stars": 1 })
	return save


func test_take_picks_the_smallest_and_take_last_the_newest() -> void:
	var save := _save_with([["rudd", 20], ["carp", 50], ["rudd", 12], ["rudd", 30]])
	var small := Bucket.take(save, "rudd")
	assert_eq(int(small.get("size_cm", 0)), 12, "BIRAK: türün en küçüğü")
	assert_eq(save.bucket.size(), 3, "kovadan çıktı")
	var last := Bucket.take_last(save, "rudd")
	assert_eq(int(last.get("size_cm", 0)), 30, "kart: en son giren")
	assert_true(Bucket.take(save, "perch").is_empty(), "kovada olmayan tür: boş")
	assert_eq(save.bucket.size(), 2, "olmayan tür kovayı değiştirmez")


func test_release_gives_love_not_coins() -> void:
	var db := content()
	var save := _save_with([["rudd", 20]])
	save.coins = 100
	var rarity := int(db.fish_by_id("rudd")["rarity"])
	var want := int(db.rarity_def(rarity)["love"])
	Bucket.take(save, "rudd")
	var result := WorldState.release(db, save, "rudd")
	assert_eq(int(result["love"]), want, "göl sevgisi nadirliğe göre (rarities.json love)")
	assert_eq(save.love, want, "kayıtta")
	assert_eq(save.coins, 100, "para vermez")
	assert_eq(int((save.records["rudd"] as Dictionary)["released"]), 1, "defterde bırakılan")
	assert_eq(int(save.stats.get("released", 0)), 1, "sayaç")


func test_release_reports_level_up() -> void:
	var db := content()
	var save := SaveData.create_new(1_700_000_000)
	Records.add(save.records, "golden_carp", 40, 1, 0)
	var levels := db.rules.love_levels
	save.love = levels[1] - 1
	var result := WorldState.release(db, save, "golden_carp")
	assert_true(int(result["new_level"]) > int(result["old_level"]), "eşik aşılınca seviye atlar")
	assert_eq(int(result["new_level"]), LakeLove.level(db.rules, save.love), "yeni seviye kayıttakiyle aynı")


func test_bucket_rows_group_species() -> void:
	var db := content()
	var save := _save_with([["rudd", 20], ["carp", 50], ["rudd", 12], ["golden_carp", 40]])
	var rows := BucketPanel.rows_of(db, save)
	assert_eq(rows.size(), 3, "tür başına bir satır")
	assert_eq(str(rows[0]["fish"]), "golden_carp", "nadir olan önce")
	for row in rows:
		var rarity := int(db.fish_by_id(str(row["fish"]))["rarity"])
		assert_eq(int(row["love"]), int(db.rarity_def(rarity)["love"]), "satırın sevgisi bir balığınki: " + str(row["fish"]))
		if str(row["fish"]) == "rudd":
			assert_eq(int(row["count"]), 2, "aynı türün sayısı")
			assert_eq(int(row["value"]), Economy.fish_value(db, "rudd", 20) + Economy.fish_value(db, "rudd", 12),
					"değer toplamı")
