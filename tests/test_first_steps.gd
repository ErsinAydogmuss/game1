extends BaseTest
## İlk adımlar (FirstSteps; Görevler paneli): adımlar kayıttan türer, haberi bir kez verilir, eski kayıtta önceden
## bitenler sessizce görülmüş sayılır; yazıları iki dilde var; Görevler düğmesi büyük, rozetli.


func test_steps_follow_the_save() -> void:
	var db := content()
	var spot := db.main_spot
	var s := SaveData.create_new(1)
	assert_eq(FirstSteps.done_count(db, s, spot), 0, "yeni oyunda hiçbir adım bitmemiş")
	assert_true(not FirstSteps.all_done(db, s, spot), "liste açık")
	s.catches = 1
	assert_true(FirstSteps.done(db, s, spot, "catch"), "ilk balık")
	s.stats["sold"] = 2
	assert_true(FirstSteps.done(db, s, spot, "sell"), "ilk satış")
	s.stats["spent"] = 30
	assert_true(FirstSteps.done(db, s, spot, "buy"), "Nine'den ilk takım")
	var zones := db.zones_of(spot)
	s.flags["visited_" + str(zones[0]["id"])] = true
	assert_true(not FirstSteps.done(db, s, spot, "zone"), "başladığı bölge sayılmaz")
	s.flags["visited_" + str(zones[1]["id"])] = true
	assert_true(FirstSteps.done(db, s, spot, "zone"), "yeni bir bölge")
	assert_true(not FirstSteps.done(db, s, spot, "rank"), "rütbe 1")
	s.xp = db.rank_xp[FirstSteps.RANK - 1]
	assert_true(FirstSteps.done(db, s, spot, "rank"), "rütbe 2")
	assert_true(FirstSteps.all_done(db, s, spot), "hepsi bitince liste kalkar")
	assert_eq(FirstSteps.RANK, db.requests.unlock_rank, "rütbe adımı Dede'nin istekleri başlayınca biter")


func test_news_once() -> void:
	var db := content()
	var spot := db.main_spot
	var s := SaveData.create_new(1)
	s.catches = 3
	s.stats["sold"] = 1
	assert_eq(FirstSteps.fresh(db, s, spot), ["catch", "sell"] as Array[String], "biten iki adımın haberi sırayla")
	FirstSteps.mark_seen(s, "catch")
	assert_eq(FirstSteps.fresh(db, s, spot), ["sell"] as Array[String], "haberi verilen bir daha çıkmaz")
	FirstSteps.mark_all_seen(db, s, spot)
	assert_true(FirstSteps.fresh(db, s, spot).is_empty(), "eski kayıt: önceden bitenler sessizce görülmüş")
	s.stats["spent"] = 10
	assert_eq(FirstSteps.fresh(db, s, spot), ["buy"] as Array[String], "sonradan biten yine haber verir")


func test_texts_exist() -> void:
	var table := TestLoadoutRows.read()
	for id in FirstSteps.STEPS:
		var key := str(FirstSteps.STEP_KEYS.get(id, ""))
		var row: PackedStringArray = table.get(key, PackedStringArray())
		assert_true(row.size() >= 3 and not row[1].is_empty() and not row[2].is_empty(), "çevirisi yok: " + key)
		assert_true(TasksPanel.STEP_ICONS.has(id), "ikonu var: " + id)


## Görevler düğmesi: en az 122, ekrandaki düğmelerde (bot boyutu ve güvenli alanı denetler), olta sudayken gizli,
## rozeti tasks_badge ile.
func test_tasks_button() -> void:
	var hud := Hud.new()
	hud.call("_build_top")
	hud.call("_build_bottom")
	var b := hud.tasks_button
	assert_true(b != null and b.custom_minimum_size.x >= 122.0 and b.custom_minimum_size.y >= 122.0, "en az 122")
	assert_true(b in hud.buttons(), "ekrandaki düğmelerde")
	hud.tasks_badge = true
	assert_true((hud.get("_tasks_badge") as Control).visible, "rozet")
	hud.tasks_badge = false
	assert_true(not (hud.get("_tasks_badge") as Control).visible, "rozet söner")
	hud.set_line_out(true)
	assert_true(not b.visible, "olta sudayken gizli (ekranın her yeri eylem)")
	hud.set_line_out(false)
	assert_true(b.visible, "olta boşken görünür")
	hud.free()


class TestLoadoutRows:
	static func read() -> Dictionary:
		var table := {}
		var f := FileAccess.open("res://localization/strings.csv", FileAccess.READ)
		if f == null:
			return table
		while not f.eof_reached():
			var row := f.get_csv_line()
			if row.size() >= 1 and not row[0].is_empty():
				table[row[0]] = row
		return table
