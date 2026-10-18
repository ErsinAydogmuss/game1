extends BaseTest
## Çekişme modeli: sakin balıkta kırmızı yok, uyarı zamanı, kopma, kaçma, Kolay mod ve bot
## tarzlarının geçme oranları (tools/reel_report.gd'deki tablonun korkulukları).

const RUNS := 40
const DISTANCES := [4.0, 5.0, 6.0, 7.0, 8.0, 9.0]
## Dipte balık uzakta takılır (ölçüm: ortalama 12,5 m; tools/session_timing.gd --technique=bottom).
const BOTTOM_DISTANCES := [8.0, 9.5, 11.0, 12.5, 14.0, 15.0]
## Sinekte yakında (ölçüm: ortalama 4,4 m; tools/session_timing.gd --technique=fly).
const FLY_DISTANCES := [3.0, 3.5, 4.0, 4.5, 5.0, 5.5]
## Spinde yem balıkçıya gelirken takılır (ölçüm: 3,3–8,0 m; tools/session_timing.gd --technique=spin).
const SPIN_DISTANCES := [3.5, 4.5, 5.5, 6.0, 7.0, 8.0]


## gear: kuşanılmış takım (yoksa başlangıç takımı, yani bambu olta); percentile: boy yüzdeliği (ppm).
func _model(fish_id: String, start: float, easy: bool, seed: int, gear: GearStats = null,
		percentile: int = 0) -> ReelModel:
	var db := content()
	var g := gear if gear != null else GearStats.starter(db)
	return ReelModel.new(db.rules, db.fish_by_id(fish_id)["fight"], g.reel_speed, start,
			g.range_m + db.rules.escape_extra + g.escape_extra, easy, seed, g, percentile)


## Başlangıç takımı + cam elyafı kamış ve naylon misina (4★ taşır; tools/reel_report.gd --gear=mid).
func _mid_gear() -> GearStats:
	var db := content()
	var items := db.gear_start.duplicate()
	items["rod"] = "rod_float_glass"
	items["line"] = "line_mono"
	var none: Array[String] = []
	return GearStats.from_items(db, items, none)


## i. denemenin boy yüzdeliği: stars > 0 ise o yıldızın aralığında eşit aralıklı, yoksa en küçük boy.
static func _percentile(stars: int, i: int) -> int:
	if stars <= 0:
		return 0
	var low: int = 0 if stars == 1 else FishTable.STAR_LIMITS[stars - 2]
	var high: int = Dice.PPM if stars == 5 else FishTable.STAR_LIMITS[stars - 1]
	return low + int(float(high - low) * (float(i) + 0.5) / RUNS)


## RUNS deneme: { caught, snapped, escaped (oran 0..1), mean (tutulanların ortalama sn), max }.
## stars: balıkların yıldızı (0: en küçük boy).
func _rates(fish_id: String, bot_style: ReelBot.Style, reaction: float, easy: bool,
		gear: GearStats = null, stars: int = 0, distances: Array = DISTANCES) -> Dictionary:
	var caught := 0
	var snapped := 0
	var escaped := 0
	var total := 0.0
	var longest := 0.0
	for i in RUNS:
		var model := _model(fish_id, distances[i % distances.size()], easy, Dice.derive(4242, i), gear,
				_percentile(stars, i))
		var result := ReelBot.play(model, ReelBot.make(bot_style, reaction))
		match int(result["outcome"]):
			ReelModel.Outcome.CAUGHT:
				caught += 1
				total += float(result["seconds"])
				longest = maxf(longest, float(result["seconds"]))
			ReelModel.Outcome.SNAPPED:
				snapped += 1
			ReelModel.Outcome.ESCAPED:
				escaped += 1
	return {
		"caught": float(caught) / RUNS, "snapped": float(snapped) / RUNS, "escaped": float(escaped) / RUNS,
		"mean": total / maxi(1, caught), "max": longest,
	}


## Takımın taşıdığı balıkta (bambu olta: 3★'ın en irisi) sakinken basılı tutmak kırmızıya çıkmaz.
func test_calm_fish_never_goes_red() -> void:
	var limit := content().rules.limit
	for f in content().fish:
		var model := _model(f["id"], 9.0, false, 7, null, FishTable.STAR_LIMITS[2] - 1)
		model.holding = true
		var peak := 0.0
		while model.outcome == ReelModel.Outcome.NONE and model.phase != ReelModel.Phase.BURST:
			model.step()
			peak = maxf(peak, model.tension)
		assert_true(peak < limit, "%s: sakinken basılı tutmak kırmızıya çıkmaz (%.2f)" % [f["id"], peak])


## Fazla iri (iri türün yıldızı taşımayı aşıyor): sakinken de basılı tutmak kırmızıya çıkar. İri
## olmayan türde boy çekişmeyi hiç değiştirmez (en küçüğüyle en irisi adım adım aynı).
func test_too_big_goes_red_even_when_calm() -> void:
	var db := content()
	for f in db.fish:
		var id := str(f["id"])
		if not bool((f["fight"] as Dictionary)["heavy"]):
			var small := ReelBot.play(_model(id, 7.0, false, 9, null, 0), ReelBot.make(ReelBot.Style.REACT, 0.4))
			var big := ReelBot.play(_model(id, 7.0, false, 9, null, Dice.PPM - 1), ReelBot.make(ReelBot.Style.REACT, 0.4))
			assert_true(int(big["outcome"]) == int(small["outcome"]) and float(big["seconds"]) == float(small["seconds"]),
					"%s: iri tür değil, boy çekişmeyi değiştirmez" % id)
			continue
		var model := _model(id, 9.0, false, 7, null, 800000)
		assert_eq(model.excess, 1, "%s: 4★, bambu olta 3★ taşır" % id)
		model.holding = true
		var red := false
		while model.outcome == ReelModel.Outcome.NONE and model.phase == ReelModel.Phase.CALM:
			model.step()
			red = red or model.in_red
		assert_true(red, "%s: fazla iri, sakinken de kırmızı" % id)
		assert_eq(_model(id, 9.0, false, 7, _mid_gear(), 800000).excess, 0, "%s: cam elyafı + naylon 4★ taşır" % id)


## İri balık takım ister (docs/gdd.md §5): bambu olta 1–3★ iri balığı rahat tutar; takımın
## taşımasını aşan 4–5★'ı iyi oyuncu da kusursuz pompalayan da (neredeyse) hiç tutamaz; o yıldızı
## taşıyan takımla iyi oyuncu tutar.
func test_big_fish_need_gear() -> void:
	var db := content()
	var mid := _mid_gear()
	var top := GearStats.best(db)
	assert_eq(top.carry, 5, "en iyi takım 5★ taşır")
	for f in db.fish:
		var id := str(f["id"])
		if not bool((f["fight"] as Dictionary)["heavy"]):
			continue
		assert_true(_rates(id, ReelBot.Style.REACT, 0.4, false, null, 3)["caught"] >= 0.95,
				"%s: bambu olta 3★'ı rahat tutar" % id)
		for stars: int in [4, 5]:
			var good := _rates(id, ReelBot.Style.REACT, 0.4, false, null, stars)
			assert_true(good["caught"] <= 0.05, "%s %d★: bambu oltayla iyi oyuncu tutamaz (%.2f)" % [id, stars, good["caught"]])
			var pump := _rates(id, ReelBot.Style.PUMP, 0.0, false, null, stars)
			assert_true(pump["caught"] <= 0.25, "%s %d★: kusursuz pompalayan da çoğunlukla kaçırır (%.2f)" % [id, stars,
					pump["caught"]])
			var fitted := _rates(id, ReelBot.Style.REACT, 0.4, false, top, stars)
			assert_true(fitted["caught"] >= 0.9, "%s %d★: en iyi takımla iyi oyuncu tutar (%.2f)" % [id, stars, fitted["caught"]])
		var four := _rates(id, ReelBot.Style.REACT, 0.4, false, mid, 4)
		assert_true(four["caught"] >= 0.9, "%s 4★: cam elyafı + naylonla iyi oyuncu tutar (%.2f)" % [id, four["caught"]])
		var five := _rates(id, ReelBot.Style.REACT, 0.4, false, mid, 5)
		assert_true(five["caught"] <= 0.05, "%s 5★: cam elyafı + naylon taşımaz (%.2f)" % [id, five["caught"]])


## Kolay modda fazla iri balık kopmaz, kaçmaz; yalnızca yavaş gelir (hep basılı tutan da tutar).
func test_easy_mode_big_fish_are_only_slower() -> void:
	var db := content()
	var limit := db.rules.limit
	for f in db.fish:
		var id := str(f["id"])
		if not bool((f["fight"] as Dictionary)["heavy"]):
			continue
		for style: ReelBot.Style in [ReelBot.Style.ALWAYS, ReelBot.Style.PERFECT]:
			var model := _model(id, 9.0, true, 21, null, 950000)
			var bot := ReelBot.make(style)
			var events := PackedStringArray()
			var peak := 0.0
			model.holding = true
			while model.outcome == ReelModel.Outcome.NONE and model.steps < ReelBot.LIMIT_STEPS:
				model.holding = bot.decide(model, events)
				events = model.step()
				peak = maxf(peak, model.tension)
			assert_eq(int(model.outcome), ReelModel.Outcome.CAUGHT, "%s 5★: Kolay'da tutulur" % id)
			assert_true(peak <= limit + 0.0001, "%s 5★: Kolay'da gerilim sınırı geçmez" % id)
			assert_true(model.seconds() < 75.0, "%s 5★: Kolay'da 75 sn'den kısa (%.1f sn)" % [id, model.seconds()])
		# Hep basılı tutan ve yavaş oyuncu (0,7 sn): fazla iri yalnızca biraz yavaş gelir.
		for bot: Array in [[ReelBot.Style.ALWAYS, 0.0], [ReelBot.Style.REACT, 0.7]]:
			var fits: float = _rates(id, bot[0], bot[1], true, null, 3)["mean"]
			var big := _rates(id, bot[0], bot[1], true, null, 5)
			assert_eq(big["caught"], 1.0, "%s 5★: Kolay'da hep tutulur (%s)" % [id, str(bot[1])])
			assert_true(big["mean"] > fits and big["mean"] < 1.75 * fits,
					"%s: Kolay'da fazla iri biraz yavaş gelir (%s: %.1f → %.1f sn)" % [id, str(bot[1]), fits, big["mean"]])


## Kolay mod çekişme sürerken açılırsa (ayarlar) fazla iri balık o andan Kolay kurallarıyla gelir:
## kopmaz, bırakan yavaş oyuncudan da hızla uzaklaşmaz.
func test_easy_mode_switched_mid_fight() -> void:
	var db := content()
	for f in db.fish:
		var id := str(f["id"])
		if not bool((f["fight"] as Dictionary)["heavy"]):
			continue
		var model := _model(id, 6.0, false, 5, null, 950000)
		var bot := ReelBot.make(ReelBot.Style.REACT, 0.7)
		var events := PackedStringArray()
		model.holding = true
		for i in FishingRules.HZ >> 1:
			model.holding = bot.decide(model, events)
			events = model.step()
		assert_eq(int(model.outcome), ReelModel.Outcome.NONE, "%s: ilk yarım saniyede bitmez" % id)
		model.easy = true
		while model.outcome == ReelModel.Outcome.NONE and model.steps < ReelBot.LIMIT_STEPS:
			model.holding = bot.decide(model, events)
			events = model.step()
		assert_eq(int(model.outcome), ReelModel.Outcome.CAUGHT, "%s: Kolay açılınca tutulur" % id)
		assert_true(model.seconds() < 75.0, "%s: Kolay açılınca 75 sn'den kısa (%.1f sn)" % [id, model.seconds()])


func test_warning_comes_before_every_burst() -> void:
	var rules := content().rules
	for f in content().fish:
		var model := _model(f["id"], 30.0, true, 11)
		model.max_distance = 1000.0
		model.holding = true
		var warn_at := -1
		var bursts := 0
		var ok := true
		while model.steps < 60 * FishingRules.HZ and model.outcome == ReelModel.Outcome.NONE:
			for e in model.step():
				if e == "warn":
					warn_at = model.steps
				elif e == "burst":
					bursts += 1
					if model.steps - warn_at != rules.warn_steps:
						ok = false
		assert_true(bursts >= 5, "%s: uzun çekişmede birçok patlama" % f["id"])
		assert_true(ok, "%s: her patlamadan tam 0,5 sn önce uyarı" % f["id"])


func test_holding_through_bursts_snaps() -> void:
	var rules := content().rules
	for fish_id: String in ["carp", "pike", "wels"]:
		var model := _model(fish_id, 9.0, false, 3)
		var result := ReelBot.play(model, ReelBot.make(ReelBot.Style.ALWAYS))
		assert_eq(int(result["outcome"]), ReelModel.Outcome.SNAPPED, "%s: hep basılı tutunca misina kopar" % fish_id)
		assert_true(float(result["red"]) >= float(rules.snap_steps) / FishingRules.HZ - 0.001,
				"%s: kopmadan önce en az 0,8 sn kırmızıda" % fish_id)


func test_never_reeling_lets_fish_escape() -> void:
	for f in content().fish:
		var result := ReelBot.play(_model(f["id"], 6.0, false, 5), ReelBot.make(ReelBot.Style.NEVER))
		assert_eq(int(result["outcome"]), ReelModel.Outcome.ESCAPED, "%s: hiç sarmayınca kaçar" % f["id"])


func test_easy_mode_never_snaps_or_escapes() -> void:
	var limit := content().rules.limit
	for f in content().fish:
		for style: ReelBot.Style in [ReelBot.Style.ALWAYS, ReelBot.Style.PERFECT]:
			var model := _model(f["id"], 9.0, true, 21)
			model.holding = true
			var bot := ReelBot.make(style)
			var events := PackedStringArray()
			var peak := 0.0
			while model.outcome == ReelModel.Outcome.NONE and model.steps < ReelBot.LIMIT_STEPS:
				model.holding = bot.decide(model, events)
				events = model.step()
				peak = maxf(peak, model.tension)
			assert_eq(int(model.outcome), ReelModel.Outcome.CAUGHT, "%s: Kolay'da tutulur" % f["id"])
			assert_true(peak <= limit + 0.0001, "%s: Kolay'da gerilim sınırı geçmez" % f["id"])
			assert_true(model.seconds() < 60.0, "%s: Kolay'da bir dakikadan kısa (%.1f sn)" % [f["id"], model.seconds()])


func test_good_players_catch_everything() -> void:
	for f in content().fish:
		for bot: Array in [[ReelBot.Style.PERFECT, 0.0], [ReelBot.Style.REACT, 0.4]]:
			for easy: bool in [false, true]:
				var r := _rates(f["id"], bot[0], bot[1], easy)
				assert_eq(r["caught"], 1.0, "%s: iyi oyuncu (%s, %s) her zaman tutar" % [f["id"], str(bot[1]),
						"Kolay" if easy else "Normal"])


func test_slow_players_mostly_catch() -> void:
	for f in content().fish:
		var normal := _rates(f["id"], ReelBot.Style.REACT, 0.7, false)
		assert_true(normal["caught"] >= 0.9, "%s: 0,7 sn tepkiyle de çoğunlukla tutulur (%.2f)" % [f["id"], normal["caught"]])
		var easy := _rates(f["id"], ReelBot.Style.REACT, 0.7, true)
		assert_true(easy["caught"] >= 0.95, "%s: Kolay'da 0,7 sn tepkiyle tutulur (%.2f)" % [f["id"], easy["caught"]])


func test_holding_only_works_on_small_fish() -> void:
	assert_true(_rates("rudd", ReelBot.Style.ALWAYS, 0.0, false)["caught"] >= 0.9, "Kızılkanat hep basılı tutularak da çıkar")
	for fish_id: String in ["carp", "pike", "wels"]:
		var r := _rates(fish_id, ReelBot.Style.ALWAYS, 0.0, false)
		assert_true(r["caught"] <= 0.1, "%s: hep basılı tutunca Normal'de kopar (%.2f)" % [fish_id, r["caught"]])
		assert_eq(_rates(fish_id, ReelBot.Style.ALWAYS, 0.0, true)["caught"], 1.0, "%s: Kolay'da hep basılı da olur" % fish_id)


## docs/gdd.md §5: iyi bir oyuncuyla Kızılkanat 4–7 sn, Yayın 14–20 sn.
func test_fight_durations() -> void:
	var rudd := _rates("rudd", ReelBot.Style.REACT, 0.4, false)
	assert_between(rudd["mean"], 4.0, 7.0, "Kızılkanat çekişmesi")
	var wels := _rates("wels", ReelBot.Style.REACT, 0.4, false)
	assert_between(wels["mean"], 14.0, 20.0, "Yayın çekişmesi")
	assert_true(wels["max"] < 40.0, "Yayın en fazla 40 sn sürer (%.1f)" % wels["max"])
	var previous := 0.0
	for fish_id: String in ["rudd", "carp", "pike", "wels"]:
		var mean: float = _rates(fish_id, ReelBot.Style.PERFECT, 0.0, false)["mean"]
		assert_true(mean > previous, "%s: büyük balık daha uzun sürer (%.1f sn)" % [fish_id, mean])
		previous = mean


## En iyi takım işi kolaylaştırır ama beceriyi silmez (docs/gdd.md §10.4): yavaş oyuncu da
## tutar; hep basılı tutan Nadir balığı en çok yarı yarıya, Destansı ve üstünü en çok %30 tutar
## (Güzel sazanı tutabilir: takımın ödülü); çekişme kısalır ama en çok %40.
func test_top_gear_keeps_skill_relevant() -> void:
	var top := GearStats.best(content())
	for f in content().fish:
		var slow := _rates(f["id"], ReelBot.Style.REACT, 0.7, false, top)
		assert_true(slow["caught"] >= 0.98, "%s: en iyi takımla 0,7 sn tepkiyle tutulur (%.2f)" % [f["id"], slow["caught"]])
	var db := content()
	for f in db.fish:
		var rarity := int(f["rarity"])
		if rarity < db.rarity_index("rare"):
			continue
		var limit := 0.5 if rarity == db.rarity_index("rare") else 0.3
		var hold := _rates(f["id"], ReelBot.Style.ALWAYS, 0.0, false, top)
		assert_true(hold["caught"] <= limit, "%s: en iyi takımla hep basılı tutan en çok %%%d tutar (%.2f)" % [f["id"],
				roundi(limit * 100), hold["caught"]])
	for fish_id: String in ["carp", "pike", "wels"]:
		var before: float = _rates(fish_id, ReelBot.Style.PERFECT, 0.0, false)["mean"]
		var after: float = _rates(fish_id, ReelBot.Style.PERFECT, 0.0, false, top)["mean"]
		assert_true(after < before, "%s: en iyi takımla çekişme kısalır (%.1f → %.1f sn)" % [fish_id, before, after])
		assert_true(after >= 0.6 * before, "%s: ama yarıdan fazla sürer (%.1f → %.1f sn)" % [fish_id, before, after])


## Dipin en iyi takımı da (kamışların gücü 0,25–0,3) beceriyi silmez: dipte gelen her tür dip
## uzaklığında aynı korkuluklarla; çekişme ilk dip kamışına göre kısalır ama en çok %40.
func test_top_bottom_gear_keeps_skill_relevant() -> void:
	var db := content()
	var top := GearStats.best(db, "bottom")
	var items := db.gear_start.duplicate()
	items["rod"] = "rod_carp_1"
	items["rig"] = "sinker"
	var none: Array[String] = []
	var first := GearStats.from_items(db, items, none)
	for f in db.fish:
		var id := str(f["id"])
		if db.affinity(id, "bottom") <= 0.0:
			continue
		var slow := _rates(id, ReelBot.Style.REACT, 0.7, false, top, 0, BOTTOM_DISTANCES)
		assert_true(slow["caught"] >= 0.98, "%s: en iyi dip takımıyla 0,7 sn tepkiyle tutulur (%.2f)" % [id, slow["caught"]])
		var rarity := int(f["rarity"])
		if rarity >= db.rarity_index("rare"):
			var limit := 0.5 if rarity == db.rarity_index("rare") else 0.3
			var hold := _rates(id, ReelBot.Style.ALWAYS, 0.0, false, top, 0, BOTTOM_DISTANCES)
			assert_true(hold["caught"] <= limit, "%s: en iyi dip takımıyla hep basılı tutan en çok %%%d tutar (%.2f)" % [id,
					roundi(limit * 100), hold["caught"]])
	for fish_id: String in ["carp", "wels", "mirror_carp"]:
		var before: float = _rates(fish_id, ReelBot.Style.PERFECT, 0.0, false, first, 0, BOTTOM_DISTANCES)["mean"]
		var after: float = _rates(fish_id, ReelBot.Style.PERFECT, 0.0, false, top, 0, BOTTOM_DISTANCES)["mean"]
		assert_true(after < before and after >= 0.6 * before, "%s: dipte en iyi takımla çekişme kısalır, yarıdan fazla sürer (%.1f → %.1f sn)" % [
				fish_id, before, after])


## Spin takımıyla da (ilk spin kamışı ve en iyisi) beceri gerekir: yırtıcı yakında takılır. Spinle
## gelen her tür 0,7 sn tepkiyle tutulur; hep basılı tutan Nadir türü en çok yarı yarıya, Destansı ve
## üstünü en çok %30 tutar; en iyi takımla çekişme kısalır ama en çok %40.
func test_spin_gear_keeps_skill_relevant() -> void:
	var db := content()
	var items := db.gear_start.duplicate()
	items["rod"] = "rod_spin_light"
	items["lure"] = "lure_spoon"
	var none: Array[String] = []
	var first := GearStats.from_items(db, items, none)
	var top := GearStats.best(db, "spin")
	for f in db.fish:
		var id := str(f["id"])
		if db.affinity(id, "spin") <= 0.0:
			continue
		for gear: GearStats in [first, top]:
			var name := "en iyi spin takımı" if gear == top else "spin kamışı"
			var slow := _rates(id, ReelBot.Style.REACT, 0.7, false, gear, 0, SPIN_DISTANCES)
			assert_true(slow["caught"] >= 0.98, "%s: %s, 0,7 sn tepkiyle tutulur (%.2f)" % [id, name, slow["caught"]])
			var rarity := int(f["rarity"])
			if rarity < db.rarity_index("rare"):
				continue
			var limit := 0.5 if rarity == db.rarity_index("rare") else 0.3
			var hold := _rates(id, ReelBot.Style.ALWAYS, 0.0, false, gear, 0, SPIN_DISTANCES)
			assert_true(hold["caught"] <= limit, "%s: %s, hep basılı tutan en çok %%%d tutar (%.2f)" % [id, name,
					roundi(limit * 100), hold["caught"]])
	for fish_id: String in ["perch", "pike", "zander"]:
		var before: float = _rates(fish_id, ReelBot.Style.PERFECT, 0.0, false, first, 0, SPIN_DISTANCES)["mean"]
		var after: float = _rates(fish_id, ReelBot.Style.PERFECT, 0.0, false, top, 0, SPIN_DISTANCES)["mean"]
		assert_true(after < before and after >= 0.6 * before, "%s: spinde en iyi takımla çekişme kısalır, yarıdan fazla sürer (%.1f → %.1f sn)" % [
				fish_id, before, after])


## Sinek takımıyla da (ilk sinek kamışı ve en iyisi) beceri gerekir: balık yakında takılır ama
## alabalık takılır takılmaz çırpınır (fight.first_burst). Sinekle gelen her tür 0,7 sn tepkiyle
## tutulur; hep basılı tutan Nadir türü en çok yarı yarıya, Destansı ve üstünü en çok %30 tutar.
func test_fly_gear_keeps_skill_relevant() -> void:
	var db := content()
	var items := db.gear_start.duplicate()
	items["rod"] = "rod_fly_1"
	items["fly"] = "fly_dry"
	var none: Array[String] = []
	var first := GearStats.from_items(db, items, none)
	var top := GearStats.best(db, "fly")
	for f in db.fish:
		var id := str(f["id"])
		if db.affinity(id, "fly") <= 0.0:
			continue
		for gear: GearStats in [first, top]:
			var name := "en iyi sinek takımı" if gear == top else "sinek kamışı"
			var slow := _rates(id, ReelBot.Style.REACT, 0.7, false, gear, 0, FLY_DISTANCES)
			assert_true(slow["caught"] >= 0.98, "%s: %s, 0,7 sn tepkiyle tutulur (%.2f)" % [id, name, slow["caught"]])
			var rarity := int(f["rarity"])
			if rarity < db.rarity_index("rare"):
				continue
			var limit := 0.5 if rarity == db.rarity_index("rare") else 0.3
			var hold := _rates(id, ReelBot.Style.ALWAYS, 0.0, false, gear, 0, FLY_DISTANCES)
			assert_true(hold["caught"] <= limit, "%s: %s, hep basılı tutan en çok %%%d tutar (%.2f)" % [id, name,
					roundi(limit * 100), hold["caught"]])
