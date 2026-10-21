extends BaseTest
## Oyun saati (DayClock, docs/gdd.md §10.5): 24 dakikalık gün, 6'şar dakikalık 4 vakit; saat
## yalnızca oynarken akar (kayıttaki clock_s), çay sonraki vaktin tam başına geçirir.


func test_day_has_four_phases_of_six_minutes() -> void:
	var rules := content().rules
	assert_eq(rules.phase_s, 360, "bir vakit 6 dk")
	assert_eq(DayClock.day_s(rules), 1440, "bir gün 24 dk")
	var expected := ["morning", "noon", "evening", "night"]
	for i in 4:
		assert_eq(DayClock.phase(rules, i * 360), expected[i], "%d. vakit" % (i + 1))
		assert_eq(DayClock.phase(rules, i * 360 + 359), expected[i], "vaktin son saniyesi")
	assert_eq(DayClock.phase(rules, 1440), "morning", "ertesi gün sabah")
	assert_eq(DayClock.day(rules, 1439), 0, "ilk gün")
	assert_eq(DayClock.day(rules, 1440), 1, "ikinci gün")
	assert_eq(DayClock.phase(rules, -50), "morning", "eksi saat sabah sayılır")


func test_clock_text_runs_one_minute_per_second() -> void:
	var rules := content().rules
	assert_eq(DayClock.clock_text(rules, 0), "06:00", "sabah 06:00'da başlar")
	assert_eq(DayClock.clock_text(rules, 90), "07:30", "1 gerçek sn = 1 oyun dakikası")
	assert_eq(DayClock.clock_text(rules, 360), "12:00", "öğle")
	assert_eq(DayClock.clock_text(rules, 720), "18:00", "akşam")
	assert_eq(DayClock.clock_text(rules, 1080), "00:00", "gece yarısı")
	assert_eq(DayClock.clock_text(rules, 1439), "05:59", "şafaktan hemen önce")
	assert_eq(DayClock.clock_text(rules, 1440), "06:00", "yeni gün")


func test_advance_reports_phase_and_day_changes() -> void:
	var rules := content().rules
	var save := SaveData.create_new(1_700_000_000)
	var same := DayClock.advance(rules, save, 100)
	assert_eq(save.clock_s, 100, "saat ilerler")
	assert_true(not bool(same["phase_changed"]) and not bool(same["day_changed"]), "vakit aynı")
	var noon := DayClock.advance(rules, save, 300)
	assert_true(bool(noon["phase_changed"]) and not bool(noon["day_changed"]), "öğle oldu")
	assert_eq(str(noon["old_phase"]), "morning", "eski vakit")
	assert_eq(str(noon["new_phase"]), "noon", "yeni vakit")
	save.clock_s = 1430
	var dawn := DayClock.advance(rules, save, 20)
	assert_true(bool(dawn["day_changed"]), "gün değişti")
	assert_eq(int(dawn["new_day"]), 1, "ikinci gün")
	assert_eq(DayClock.advance(rules, save, -30)["phase_changed"], false, "saat geri gitmez")
	assert_eq(save.clock_s, 1450, "eksi süre eklenmez")


func test_tea_skips_to_the_next_phase_start() -> void:
	var rules := content().rules
	var save := SaveData.create_new(1_700_000_000)
	save.clock_s = 200
	assert_eq(DayClock.phase_left_s(rules, save.clock_s), 160, "vaktin kalanı")
	assert_eq(DayClock.next_phase(rules, save.clock_s), "noon", "sıradaki vakit")
	var change := DayClock.skip_phase(rules, save)
	assert_eq(save.clock_s, 360, "öğlenin tam başı")
	assert_eq(str(change["new_phase"]), "noon", "çayla öğle")
	assert_eq(DayClock.phase_left_s(rules, save.clock_s), 360, "yeni vakit baştan")
	save.clock_s = 1080
	DayClock.skip_phase(rules, save)
	assert_eq(save.clock_s, 1440, "geceden sonra ertesi sabah")
	assert_eq(DayClock.day(rules, save.clock_s), 1, "yeni gün")
	var restored := SaveData.from_dict(save.to_dict())
	assert_eq(restored.clock_s, 1440, "saat kayıtla saklanır")


## Dede'yle çay (WorldState): son çaydan beri en az bir balık (ilk çaydan önce de); içilince saat
## sonraki vaktin başına, son çay o anki balık sayısı. İçilemezse saat değişmez.
func test_tea_needs_a_fish_since_the_last_tea() -> void:
	var rules := content().rules
	var save := SaveData.create_new(1_700_000_000)
	save.clock_s = 100
	assert_true(not WorldState.can_tea(save), "hiç balık yokken çay yok")
	assert_true(WorldState.drink_tea(rules, save).is_empty() and save.clock_s == 100, "içilemezse saat aynı")
	save.catches = 1
	assert_true(WorldState.can_tea(save), "ilk balıktan sonra çay")
	var change := WorldState.drink_tea(rules, save)
	assert_eq(str(change.get("new_phase", "")), "noon", "çayla öğle")
	assert_eq(save.clock_s, 360, "öğlenin tam başı")
	assert_eq(save.tea_at, 1, "son çay kayıtta")
	assert_true(not WorldState.can_tea(save), "art arda ikinci çay yok")
	save.catches = 2
	assert_true(WorldState.can_tea(save), "bir balık daha: yine çay")
	WorldState.drink_tea(rules, save)
	assert_eq(DayClock.phase(rules, save.clock_s), "evening", "akşam")
	var restored := SaveData.from_dict(save.to_dict())
	assert_true(restored.tea_at == 2 and not WorldState.can_tea(restored), "son çay kayıtla saklanır")
