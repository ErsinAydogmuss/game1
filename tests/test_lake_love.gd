extends BaseTest
## Göl sevgisi (LakeLove, docs/gdd.md §10.5): 10 seviye; her seviye Nadir ve üstü türlerin
## ağırlığını %4 artırır (en çok %36); seviye 6'da altın hamur; sevgi hiç azalmaz.


func test_levels_and_thresholds() -> void:
	var rules := content().rules
	assert_eq(LakeLove.max_level(rules), 10, "10 seviye")
	assert_eq(LakeLove.level(rules, 0), 1, "sevgisiz göl seviye 1")
	assert_eq(LakeLove.level(rules, 11), 1, "eşiğin altı")
	assert_eq(LakeLove.level(rules, 12), 2, "ilk eşik")
	assert_eq(LakeLove.level(rules, 180), 6, "altın hamurun seviyesi")
	assert_eq(LakeLove.level(rules, 100000), 10, "en çok 10")
	assert_eq(LakeLove.next_at(rules, 40), 60, "sıradaki eşik")
	assert_eq(LakeLove.next_at(rules, 700), -1, "en üst seviyede eşik yok")
	assert_between(LakeLove.progress(rules, 21), 0.49, 0.51, "seviyenin yarısı (12 → 30)")
	assert_eq(LakeLove.progress(rules, 800), 1.0, "en üstte dolu")


func test_rare_bonus_is_four_percent_per_level() -> void:
	var rules := content().rules
	assert_eq(LakeLove.rare_bonus_pm(rules, 1), 1000, "seviye 1'de pay yok")
	assert_eq(LakeLove.rare_bonus_pm(rules, 2), 1040, "seviye başına %4")
	assert_eq(LakeLove.rare_bonus_pm(rules, 10), 1360, "en çok %36")
	assert_eq(LakeLove.rare_bonus_pm(rules, 25), 1360, "seviye sınırda")


func test_love_only_grows() -> void:
	var rules := content().rules
	var save := SaveData.create_new(1_700_000_000)
	var up := LakeLove.add(rules, save, 12)
	assert_eq(save.love, 12, "sevgi eklenir")
	assert_eq(int(up["old_level"]), 1, "eski seviye")
	assert_eq(int(up["new_level"]), 2, "seviye atladı")
	LakeLove.add(rules, save, -50)
	assert_eq(save.love, 12, "sevgi hiç azalmaz")


## Sevgi Nadir+ türlerin oranını artırır; Sıradan ve İnce türlerin göreli oranı değişmez.
func test_love_raises_rare_odds() -> void:
	var db := content()
	var zone := db.zone("big_lake", "lily_cove")
	var base := CatchOdds.species_ppm(db, zone, { "phase": "morning", "weather": "clear", "love": 1 })
	var loved := CatchOdds.species_ppm(db, zone, { "phase": "morning", "weather": "clear", "love": 10 })
	assert_true(int(loved["pike"]) > int(base["pike"]), "turna (Nadir) artar")
	assert_true(int(loved["golden_carp"]) > int(base["golden_carp"]), "altın sazan (Destansı) artar")
	assert_true(int(loved["rudd"]) < int(base["rudd"]), "kızılkanat (Sıradan) azalır")
	var ratio_base := float(base["pike"]) / float(base["rudd"])
	var ratio_loved := float(loved["pike"]) / float(loved["rudd"])
	assert_between(ratio_loved / ratio_base, 1.355, 1.365, "Nadir / Sıradan %36 artar")
	var commons := float(loved["perch"]) / float(loved["rudd"])
	assert_between(commons / (float(base["perch"]) / float(base["rudd"])), 0.995, 1.005, "Sıradan ve İnce arası aynı")
