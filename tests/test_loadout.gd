extends BaseTest
## Takım paneli (LoadoutPanel; testçi: "takım çantasında envanterimizdekileri görelim"): yuvaların sırası,
## sahip olunan takımlar (kamış tekniğin, yem elde kalan), yuva adlarının çevirisi, kuşanmanın oturuma geçmesi.


func test_slots_in_order() -> void:
	var db := content()
	assert_eq(LoadoutPanel.slots_of(db, "float"), ["rod", "hook", "bobber", "bait", "reel", "line"] as Array[String],
			"şamandıra: kamış, küçük takım, yem, sonra ortak makara ve misina")
	assert_eq(LoadoutPanel.slots_of(db, "spin"), ["rod", "lure", "reel", "line"] as Array[String], "spin")
	assert_eq(LoadoutPanel.slots_of(db, "bottom"), ["rod", "bait", "rig", "reel", "line"] as Array[String], "dip")
	assert_eq(LoadoutPanel.slots_of(db, "fly"), ["rod", "fly", "reel", "line"] as Array[String], "sinek")
	# Panel iki sütun, en çok üç sıra: telefonda küçülmeden sığsın (bot da ölçer).
	for t: String in ContentDB.TECHNIQUES:
		assert_true(LoadoutPanel.slots_of(db, t).size() <= LoadoutPanel.COLUMNS * 3, "en çok üç sıra: " + t)


func test_owned_items_only() -> void:
	var db := content()
	var s := SaveData.create_new(1)
	assert_eq(LoadoutPanel.owned_for(db, s, "float", "rod"), ["rod_bamboo"] as Array[String], "yeni oyunda bambu olta")
	assert_true(LoadoutPanel.owned_for(db, s, "spin", "rod").is_empty(), "spin kamışı yok")
	s.owned.append("rod_spin_light")
	assert_eq(LoadoutPanel.owned_for(db, s, "spin", "rod"), ["rod_spin_light"] as Array[String], "alınan spin kamışı")
	assert_true(not "rod_spin_light" in LoadoutPanel.owned_for(db, s, "float", "rod"), "kamış yalnızca kendi tekniğinde")
	assert_eq(LoadoutPanel.owned_for(db, s, "float", "bait"), ["bait_worm"] as Array[String], "bedava solucan hep")
	s.baits["bait_maggot"] = 3
	assert_true("bait_maggot" in LoadoutPanel.owned_for(db, s, "float", "bait"), "elde kalan yem")
	s.baits["bait_maggot"] = 0
	assert_true(not "bait_maggot" in LoadoutPanel.owned_for(db, s, "float", "bait"), "biten yem yok")
	# Her listelenen takım kuşanılabilir (panelde dokununca takılır) ve kuşanılan hep listede.
	s.owned.append("reel_smooth")
	for t: String in ContentDB.TECHNIQUES:
		if not Economy.technique_ready(db, s, t):
			continue
		for slot in LoadoutPanel.slots_of(db, t):
			var owned := LoadoutPanel.owned_for(db, s, t, slot)
			assert_true(Economy.equipped(db, s, slot, t) in owned, "kuşanılan listede: %s %s" % [t, slot])
			for id in owned:
				assert_true(Economy.equip(db, s, id, t), "kuşanılır: " + id)
				assert_eq(Economy.equipped(db, s, slot, t), id, "kuşanıldı: " + id)


func test_slot_names_exist() -> void:
	var table := TestDayPanelRows.read()
	for slot: String in ContentDB.GEAR_SLOTS:
		var row: PackedStringArray = table.get("UI_SLOT_" + slot, PackedStringArray())
		assert_true(row.size() >= 3 and not row[1].is_empty() and not row[2].is_empty(), "çevirisi yok: UI_SLOT_" + slot)


## Çeviri tablosu (test_day_panel'inkiyle aynı okuma).
class TestDayPanelRows:
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
