extends BaseTest
## Çekişme modeli: sakin balıkta kırmızı yok, uyarı zamanı, kopma, kaçma, Kolay mod ve bot
## tarzlarının geçme oranları (tools/reel_report.gd'deki tablonun korkulukları).

const RUNS := 40
const DISTANCES := [4.0, 5.0, 6.0, 7.0, 8.0, 9.0]


func _model(fish_id: String, start: float, easy: bool, seed: int) -> ReelModel:
	var db := content()
	var rod := db.rod("bamboo")
	return ReelModel.new(db.rules, db.fish_by_id(fish_id)["fight"], float(rod["reel_speed"]), start,
			float(rod["range_m"]) + db.rules.escape_extra, easy, seed)


## RUNS deneme: { caught, snapped, escaped (oran 0..1), mean (tutulanların ortalama sn), max }.
func _rates(fish_id: String, bot_style: ReelBot.Style, reaction: float, easy: bool) -> Dictionary:
	var caught := 0
	var snapped := 0
	var escaped := 0
	var total := 0.0
	var longest := 0.0
	for i in RUNS:
		var model := _model(fish_id, DISTANCES[i % DISTANCES.size()], easy, Dice.derive(4242, i))
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


func test_calm_fish_never_goes_red() -> void:
	var limit := content().rules.limit
	for f in content().fish:
		var model := _model(f["id"], 9.0, false, 7)
		model.holding = true
		var peak := 0.0
		while model.outcome == ReelModel.Outcome.NONE and model.phase != ReelModel.Phase.BURST:
			model.step()
			peak = maxf(peak, model.tension)
		assert_true(peak < limit, "%s: sakinken basılı tutmak kırmızıya çıkmaz (%.2f)" % [f["id"], peak])


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
