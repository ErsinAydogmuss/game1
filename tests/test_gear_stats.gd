extends BaseTest
## Takımın oyuna etkisi (GearStats): başlangıç takımı prototipin bambu oltasıyla aynı;
## pahalı takım menzili, sarmayı, freni, misinayı, iğneyi, şamandırayı ve kepçeyi değiştirir.


func test_starter_matches_the_prototype_rod() -> void:
	var db := content()
	var g := GearStats.starter(db)
	assert_eq(g.technique, "float", "şamandıra tekniği")
	assert_eq(g.range_m, 9.0, "menzil 9 m")
	assert_eq(g.reel_speed, 1.6, "sarma 1,6 m/sn")
	assert_eq(g.power, 0.0, "güç yok")
	assert_eq(g.drag, 0.0, "fren yok")
	assert_eq(g.snap_steps, db.rules.snap_steps, "kopma süresi kurallardaki gibi")
	assert_eq(g.stealth, 0.0, "görünmezlik yok")
	assert_eq(g.escape_extra, 0.0, "iğne kaçma payını değiştirmez")
	assert_eq(g.window_add_steps, 0, "VUR süresi aynı")
	assert_eq(g.catch_m, db.rules.catch_m, "kepçe yok")
	assert_true(g.attract.is_empty(), "solucan tür çekmez")
	assert_eq(str(g.items["rod"]), "rod_bamboo", "bambu kamış kuşanılı")
	assert_eq(g.carry, db.rules.carry, "iri balıkta 3★ taşır (kurallardaki gibi)")


## Taşıma kamışın ve misinanın küçüğüdür: iri balık için ikisi de sağlam olmalı.
func test_carry_is_the_weaker_of_rod_and_line() -> void:
	var db := content()
	var none: Array[String] = []
	var cases := [
		["rod_float_glass", "line_mono_thin", 3], ["rod_bamboo", "line_mono", 3], ["rod_float_glass", "line_mono", 4],
		["rod_float_carbon", "line_mono", 4], ["rod_float_carbon", "line_braid", 5], ["rod_float_glass", "line_braid_pro", 4],
	]
	for c: Array in cases:
		var g := GearStats.from_items(db, { "rod": c[0], "line": c[1] }, none)
		assert_eq(g.carry, int(c[2]), "%s + %s: %d★ taşır" % [c[0], c[1], c[2]])
	assert_eq(GearStats.best(db).carry, 5, "en iyi takım 5★ taşır")


func test_items_set_the_stats() -> void:
	var db := content()
	var extras: Array[String] = ["net"]
	var g := GearStats.from_items(db, {
		"rod": "rod_float_carbon", "reel": "reel_master", "line": "line_braid", "hook": "hook_large",
		"bobber": "bobber_bright", "bait": "bait_corn",
	}, extras)
	assert_eq(g.range_m, 13.0, "karbon kamış 13 m")
	assert_eq(g.power, 0.08, "karbon kamışın gücü")
	assert_eq(g.reel_speed, 1.95, "altın makara hızı")
	assert_eq(g.drag, 0.1, "altın makaranın freni")
	assert_eq(g.snap_steps, FishingRules.to_steps(0.9), "örgü misina 0,9 sn dayanır")
	assert_eq(g.escape_extra, 1.0, "büyük iğne +1 m")
	assert_eq(g.window_add_steps, FishingRules.to_steps(0.3), "parlak şamandıra +0,3 sn")
	assert_eq(g.catch_m, 0.85, "kepçe 0,85 m'den tutar")
	assert_eq(g.attraction("carp"), 3.0, "mısır sazanı çeker")
	assert_eq(g.attraction("rudd"), 1.0, "mısır kızılkanadı çekmez")


func test_bad_items_fall_back_to_the_starter() -> void:
	var db := content()
	var none: Array[String] = ["shark_net"]
	var g := GearStats.from_items(db, { "rod": "reel_basic", "reel": "yok" }, none)
	assert_eq(str(g.items["rod"]), "rod_bamboo", "yanlış kategoriden kamış yerine bambu")
	assert_eq(str(g.items["reel"]), "reel_basic", "bilinmeyen makara yerine basit makara")
	assert_eq(g.catch_m, db.rules.catch_m, "bilinmeyen ekstra bir şey değiştirmez")


## Güç sarmayı hızlandırır, fren patlamadaki gerilimi kırpar, kepçe balığı uzaktan alır.
func test_gear_changes_the_fight() -> void:
	var db := content()
	var fight: Dictionary = db.fish_by_id("wels")["fight"]
	var starter := GearStats.starter(db)
	var top := GearStats.best(db)
	var peaks: Array[float] = []
	var finish: Array[float] = []
	for g: GearStats in [starter, top]:
		var model := ReelModel.new(db.rules, fight, g.reel_speed, 6.0, 30.0, true, 99, g)
		model.holding = true
		var peak := 0.0
		while model.outcome == ReelModel.Outcome.NONE and model.steps < ReelBot.LIMIT_STEPS:
			model.step()
			if model.phase == ReelModel.Phase.BURST:
				peak = maxf(peak, model.tension)
		peaks.append(peak)
		finish.append(model.distance)
	# Kolay modda gerilim sınırda durur; frenin etkisini Normal'de, patlamanın tepesinde ölç.
	var raw: Array[float] = []
	for g: GearStats in [starter, top]:
		var model := ReelModel.new(db.rules, fight, g.reel_speed, 30.0, 1000.0, false, 7, g)
		model.holding = true
		var peak := 0.0
		while model.outcome == ReelModel.Outcome.NONE and model.steps < 20 * FishingRules.HZ:
			model.step()
			peak = maxf(peak, model.tension)
		raw.append(peak)
	assert_true(raw[1] < raw[0], "fren patlamadaki gerilimi düşürür (%.2f → %.2f)" % [raw[0], raw[1]])
	assert_true(raw[1] > db.rules.limit, "en iyi frende bile patlama kırmızıya çıkar")
	assert_eq(finish[0], db.rules.catch_m, "kepçesiz 0,6 m'de tutulur")
	assert_eq(finish[1], 0.85, "kepçeyle 0,85 m'de tutulur")


func test_stealth_shrinks_the_scare_radius() -> void:
	var rules := content().rules
	var s := FishShadow.new()
	s.pos = Vector2.ZERO
	s.length = 1.0
	# Yarıçap 0,5 + 0,3 = 0,8 m; görünmezlik 0,3 ile 0,56 m.
	assert_true(BiteRules.scares(s, Vector2(0.6, 0), rules), "0,6 m: naylonda korkar")
	assert_true(not BiteRules.scares(s, Vector2(0.6, 0), rules, 0.3), "0,6 m: florokarbonda korkmaz")
	assert_true(BiteRules.scares(s, Vector2(0.5, 0), rules, 0.3), "0,5 m: florokarbonda da korkar")


## Daha uzun kamış daha uzağa atar (kıyının izin verdiği kadar).
func test_longer_rod_casts_farther() -> void:
	var db := content()
	var none: Array[String] = []
	var reaches: Array[float] = []
	for rod: String in ["rod_bamboo", "rod_float_carbon"]:
		var gear := GearStats.from_items(db, { "rod": rod }, none)
		var session := FishingSession.new(db, "home_lake", gear, 5, false, false)
		session.angler = Vector2(0.0, 4.0)
		assert_true(session.cast(Vector2(0.0, -30.0)), rod + ": atış yapılır")
		reaches.append(session.angler.distance_to(session.bobber))
	assert_true(reaches[0] <= 9.0 + 0.001, "bambu 9 m'yi geçmez (%.1f)" % reaches[0])
	assert_true(reaches[1] > reaches[0] + 0.5, "karbon daha uzağa (%.1f m)" % reaches[1])
