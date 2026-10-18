extends BaseTest
## Dede'nin öğütleri (Elder.tips): rütbe 1'de yalnızca genel öğütler; teknik ve tuzak açıldıkça
## öğütleri genel öğütlerin arasına, açıldıkları rütbe sırasıyla girer. Bölgelerin önerdiği teknik
## (spots.json suggest) bölgede avlanılır ve sözü var.


func test_rank_one_has_only_general_tips() -> void:
	var db := content()
	var save := SaveData.create_new(0)
	var tips := Elder.tips(db, save)
	assert_eq(tips.size(), Elder.TIP_COUNT, "yalnızca genel öğütler")
	for i in Elder.TIP_COUNT:
		assert_eq(tips[i], Elder.TIP_KEY % (i + 1), "sıra aynı (%d)" % i)


func test_opened_techniques_join_between_general_tips() -> void:
	var db := content()
	var save := SaveData.create_new(0)
	save.xp = db.rank_xp[db.technique_rank("spin") - 1]
	var tips := Elder.tips(db, save)
	assert_eq(tips.size(), Elder.TIP_COUNT + 1, "spinin öğüdü katıldı")
	assert_eq(tips[1], str(Elder.TECH_TIPS["spin"]), "ilk genel öğütten sonra")
	save.xp = db.rank_xp[db.max_rank() - 1]
	tips = Elder.tips(db, save)
	assert_eq(tips.size(), Elder.TIP_COUNT + Elder.TECH_TIPS.size(), "hepsi açık")
	# Açıldıkları rütbe sırasıyla: spin (2), tuzak (3), dip (4), sinek (7).
	var order := PackedStringArray()
	for key in tips:
		if not key.begins_with(Elder.TIP_KEY.split("%")[0]) or key.right(1).is_valid_int():
			continue
		order.append(key)
	assert_eq(order, PackedStringArray([Elder.TECH_TIPS["spin"], Elder.TECH_TIPS["trap"], Elder.TECH_TIPS["bottom"],
			Elder.TECH_TIPS["fly"]]), "rütbe sırası")
	assert_true(TrapSim.rank(db) < db.technique_rank("bottom"), "tuzak dipten önce açılır (sıra sınaması)")


func test_zone_suggestions_are_huntable() -> void:
	var db := content()
	var suggested := 0
	for z in db.zones_of(db.main_spot):
		var suggest := str(z["suggest"])
		if suggest.is_empty():
			continue
		suggested += 1
		assert_true(suggest in (z["techniques"] as PackedStringArray), "%s: %s avlanılır" % [z["id"], suggest])
		assert_true(not CatchOdds.species_ppm(db, z, { "technique": suggest }).is_empty(),
				"%s: %s ile balık gelir" % [z["id"], suggest])
	assert_true(suggested >= 4, "bölgelerin çoğu bir teknik önerir (%d)" % suggested)
	assert_eq(str(db.zone(db.main_spot, "stream_mouth")["suggest"]), "fly", "dere ağzında sinek")


## Bölgenin önerisi: rütbesi gelmiş, başka teknikle tutana, bir kez; önerisi olmayan bölgede yok.
func test_zone_suggestion_rules() -> void:
	var db := content()
	var spot := db.main_spot
	var save := SaveData.create_new(0)
	assert_eq(Elder.suggestion(db, save, spot, "reeds", "float"), "", "rütbe 1: dip açılmadı")
	save.xp = db.rank_xp[db.technique_rank("bottom") - 1]
	assert_eq(Elder.suggestion(db, save, spot, "reeds", "float"), Elder.SUGGEST_KEY % "reeds", "dip açıldı, şamandırayla")
	assert_eq(Elder.suggestion(db, save, spot, "reeds", "spin"), Elder.SUGGEST_KEY % "reeds", "spinle de")
	assert_eq(Elder.suggestion(db, save, spot, "reeds", "bottom"), "", "zaten dipte")
	assert_eq(Elder.suggestion(db, save, spot, "lily_cove", "float"), Elder.SUGGEST_KEY % "lily_cove", "nilüferli koyda spin")
	assert_eq(Elder.suggestion(db, save, spot, "dock_cove", "float"), "", "iskele koyunun önerisi yok")
	assert_eq(Elder.suggestion(db, save, spot, "stream_mouth", "float"), "", "sinek rütbe 7")
	save.flags[Elder.SUGGEST_FLAG % "reeds"] = true
	assert_eq(Elder.suggestion(db, save, spot, "reeds", "float"), "", "bir kez söylenir")
	save.xp = db.rank_xp[db.technique_rank("fly") - 1]
	assert_eq(Elder.suggestion(db, save, spot, "stream_mouth", "float"), Elder.SUGGEST_KEY % "stream_mouth",
			"dere ağzında sinek")
