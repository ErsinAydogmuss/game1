extends BaseTest
## Hava (Weather, docs/gdd.md §10.5): her oyun günü için tohumlu zar; açık %55, bulutlu %20,
## yağmur %15, sis %10; ilk gün açık; sis yalnızca sabah ve gece; yağmurlu gece fırtına; bugün ve
## yarın önceden belli.


func test_same_seed_same_weather() -> void:
	var rules := content().rules
	for day in [1, 2, 7, 40, 999]:
		assert_eq(Weather.of_day(rules, 4242, day), Weather.of_day(rules, 4242, day), "gün %d aynı" % day)
	var differs := false
	for day in range(1, 40):
		differs = differs or Weather.of_day(rules, 4242, day) != Weather.of_day(rules, 77, day)
	assert_true(differs, "başka seed başka hava")


func test_weather_odds_follow_the_design() -> void:
	var rules := content().rules
	var counts := {}
	var n := 20000
	for day in range(1, n + 1):
		var kind := Weather.of_day(rules, 1234, day)
		counts[kind] = int(counts.get(kind, 0)) + 1
	var expected := { "clear": 0.55, "cloudy": 0.2, "rain": 0.15, "fog": 0.1 }
	for kind: String in expected:
		var share := float(counts.get(kind, 0)) / n
		assert_between(share, float(expected[kind]) - 0.015, float(expected[kind]) + 0.015, "%s günü (%.3f)" % [kind, share])


func test_first_day_is_clear() -> void:
	var rules := content().rules
	for seed_value in [1, 4242, 99991, 123456789]:
		assert_eq(Weather.of_day(rules, seed_value, 0), "clear", "ilk gün açık (seed %d)" % seed_value)


func test_fog_only_in_the_morning_and_at_night() -> void:
	var db := content()
	var rules := db.rules
	var save := SaveData.create_new(1_700_000_000)
	save.seed = 4242
	var fog_day := -1
	for day in range(1, 200):
		if Weather.of_day(rules, save.seed, day) == "fog":
			fog_day = day
			break
	assert_true(fog_day > 0, "200 günde sisli gün var")
	if fog_day < 0:
		return
	var start := fog_day * DayClock.day_s(rules)
	var phases := { "morning": "fog", "noon": "cloudy", "evening": "cloudy", "night": "fog" }
	for i in 4:
		var clock := start + i * rules.phase_s + 10
		var phase := DayClock.phase(rules, clock)
		assert_eq(Weather.at(rules, save, clock), phases[phase], "sisli günde %s" % phase)
	save.clock_s = start + 3 * rules.phase_s
	assert_eq(WorldState.conditions(db, save)["weather"], "fog", "koşullarda gecenin sisi")


func test_forecast_and_storm() -> void:
	var rules := content().rules
	var save := SaveData.create_new(1_700_000_000)
	save.seed = 4242
	save.clock_s = 5 * DayClock.day_s(rules) + 100
	var days := Weather.forecast(rules, save)
	assert_eq(days.size(), 2, "bugün ve yarın")
	assert_eq(days[0], Weather.of_day(rules, save.seed, 5), "bugünün havası")
	assert_eq(days[1], Weather.of_day(rules, save.seed, 6), "yarının havası önceden belli")
	assert_true(Weather.stormy("rain", "night"), "yağmurlu gece fırtına")
	assert_true(not Weather.stormy("rain", "evening") and not Weather.stormy("fog", "night"), "öteki vakit ve hava fırtına değil")


## Geliştirme sürümünün HAVA düğmesi bugünün havasını sırayla çevirir; ertesi gün zar yine geçerli.
func test_debug_cycle_changes_only_today() -> void:
	var rules := content().rules
	var save := SaveData.create_new(1_700_000_000)
	save.seed = 4242
	save.clock_s = 3 * DayClock.day_s(rules) + 30
	var before := Weather.day_kind(rules, save, 3)
	var after := Weather.cycle_debug(rules, save)
	assert_true(after != before, "bugünün havası değişti")
	assert_eq(Weather.at(rules, save), after, "sabahın havası seçilen")
	assert_eq(Weather.day_kind(rules, save, 4), Weather.of_day(rules, save.seed, 4), "yarın zarınki")
	var kinds := {}
	for i in 4:
		kinds[Weather.cycle_debug(rules, save)] = true
	assert_eq(kinds.size(), 4, "dört hava sırayla")
