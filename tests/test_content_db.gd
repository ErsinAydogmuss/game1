extends BaseTest
## İçerik veritabanı (data/*.json) ve çeviriler.


func test_loads_without_errors() -> void:
	var db := content()
	assert_eq(db.errors.size(), 0, "içerik hataları: " + ", ".join(db.errors))
	assert_eq(db.rarities.size(), 6, "6 nadirlik (Masalsı eklendi)")
	assert_eq(db.fish.size(), 19, "19 balık (Dalga 2'de 7 tür, Dalga 3'te aynalı sazan, iki alabalık ve kerevit, Dalga 4'te Ay Turnası, Kocabaş ve Gölün Bekçisi)")
	assert_true(not db.spot("home_lake").is_empty(), "testlerin gölü")
	assert_eq(db.main_spot, "big_lake", "oyun Köy Gölü'nde açılır")
	assert_true(db.gear.size() >= 30, "dükkân takımı okundu")
	assert_eq(db.max_rank(), 20, "20 rütbe")
	assert_true(db.rules != null, "kurallar okundu")


## docs/gdd.md §6: türler, nadirlikleri ve bölgeleri.
func test_fish_follow_the_design() -> void:
	var db := content()
	var expected := { "rudd": "common", "carp": "fine", "perch": "fine", "pike": "rare", "wels": "epic",
		"silverside": "common", "bream": "common", "chub": "common", "tench": "fine", "zander": "rare",
		"golden_carp": "epic", "sturgeon": "legendary", "mirror_carp": "rare" }
	for id: String in expected:
		var f := db.fish_by_id(id)
		assert_true(not f.is_empty(), "balık var: " + id)
		if not f.is_empty():
			assert_eq(db.rarity_id(int(f["rarity"])), expected[id], id + " nadirliği")
	assert_eq(db.fish_by_id("rudd")["size_cm"], Vector2i(15, 30), "Kızılkanat 15–30 cm")
	assert_eq(db.fish_by_id("wels")["size_cm"], Vector2i(100, 250), "Yayın 100–250 cm")
	# Mersin koruma altında; Ay Turnası (gece) ve Kocabaş (yağmurlu gece) efsane, Gölün Bekçisi hikâyenin
	# balığı: satılmaz, yalnızca bırakılır (Dalga 4, Ersin'in seçimi); ötekiler satılır.
	var released := ["sturgeon", "moon_pike", "kocabas", "keeper"]
	for f in db.fish:
		assert_eq(bool(f["release_only"]), str(f["id"]) in released,
				"%s: yalnızca mersin, Ay Turnası, Kocabaş ve Gölün Bekçisi bırakılır" % f["id"])
	assert_eq(int(db.fish_by_id("sturgeon")["value"]), 0, "mersin satılmaz")
	assert_eq(db.rarity_id(int(db.fish_by_id("moon_pike")["rarity"])), "legendary", "Ay Turnası Efsanevi")
	assert_eq(db.rarity_id(int(db.fish_by_id("kocabas")["rarity"])), "legendary", "Kocabaş Efsanevi")
	# Bölgeler: yeni türler kendi yerlerinde; yıldızlar (sudak, altın sazan, mersin) başlangıç
	# koylarında çıkmaz; iskele koyunda turna ve yayın az (Ersin'in seçimi).
	var homes := { "silverside": ["dock_cove", "reeds"], "bream": ["dock_cove", "deep_water"],
		"chub": ["rocky_point", "stream_mouth"], "tench": ["reeds"], "zander": ["rocky_point", "deep_water"],
		"golden_carp": ["lily_cove"], "sturgeon": ["deep_water"], "moon_pike": ["lily_cove"], "kocabas": ["deep_water"] }
	for id: String in homes:
		var found := []
		for z in db.zones_of("big_lake"):
			if id in (z["fish_ids"] as PackedStringArray):
				found.append(str(z["id"]))
		assert_eq(found, homes[id], "%s yaşadığı bölgeler" % id)
	var dock := CatchOdds.species_ppm(db, db.zone("big_lake", "dock_cove"))
	assert_true(int(dock["pike"]) <= 100_000 and int(dock["wels"]) <= 50_000, "iskele koyunda turna ve yayın az: %s" % str(dock))
	var spot := db.spot("home_lake")
	assert_eq(int(spot["max_shadows"]), 4, "gölde 4 gölge")
	assert_eq(str(spot["first_fish"]), "rudd", "ilk av Kızılkanat")



## Vakit balığın ne zaman geldiğini değiştirir, kazancı değil: her türde dört vaktin çarpanlarının ortalaması 1
## (docs/gdd.md §6; belli vakitte gelen türün çarpanı yok).
func test_time_multipliers_average_one() -> void:
	var db := content()
	for f in db.fish:
		var sum := 0.0
		for phase: String in DayClock.PHASES:
			sum += db.when_mult(str(f["id"]), phase)
		assert_between(sum / float(DayClock.PHASES.size()), 0.995, 1.005, "%s: vakit çarpanlarının ortalaması 1" % f["id"])

## Bozuk veri yakalanır: kurallarla çelişen çekişme, bilinmeyen balık, suyun içindeki başlangıç.
func test_validation_catches_bad_data() -> void:
	var dir := "user://test_bad_data"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	for file: String in ["rarities.json", "rules.json", "progression.json"]:
		var text := FileAccess.get_file_as_string("res://data/" + file)
		_write(dir.path_join(file), text)
	var fish := JSON.parse_string(FileAccess.get_file_as_string("res://data/fish.json")) as Dictionary
	(fish["fish"][0]["fight"] as Dictionary)["pull"] = 0.95
	# Satılan bir balığın değeri 0 olamaz (yalnızca Masalsı ve koruma altındaki tür).
	(fish["fish"][1] as Dictionary)["value"] = 0
	# İri türde boyla artan çekiş de sınırın altında kalmalı (mersin: 0,75 + size_pull).
	for f: Variant in fish["fish"]:
		if str((f as Dictionary)["id"]) == "sturgeon":
			((f as Dictionary)["fight"] as Dictionary)["pull"] = 0.75
		# Hiçbir teknikle gelmeyen tür olmaz; bilinmeyen teknik yakalanır.
		if str((f as Dictionary)["id"]) == "tench":
			(f as Dictionary)["affinity"] = { "float": 0, "harpoon": 1 }
		# Binde birin altındaki yatkınlık sıfıra yuvarlanırdı (tür sessizce gelmezdi).
		if str((f as Dictionary)["id"]) == "perch":
			((f as Dictionary)["affinity"] as Dictionary)["spin"] = 0.0004
		# Vakit ve hava (Dalga 4): bilinmeyen vakit, sıfır çarpan; yalnızca gece gelen tür satılamaz.
		if str((f as Dictionary)["id"]) == "chub":
			(f as Dictionary)["when"] = { "dusk": 1.2, "noon": 0.0 }
			(f as Dictionary)["weather"] = { "snow": 2.0 }
		if str((f as Dictionary)["id"]) == "bream":
			(f as Dictionary)["only"] = { "phase": ["night", "teatime"], "season": ["winter"] }
	_write(dir.path_join("fish.json"), JSON.stringify(fish))
	var spots := JSON.parse_string(FileAccess.get_file_as_string("res://data/spots.json")) as Dictionary
	var spot: Dictionary = spots["spots"][0]
	spot["start"] = [0.0, 0.0]
	(spot["fish"] as Dictionary)["shark"] = 5
	_write(dir.path_join("spots.json"), JSON.stringify(spots))
	var gear := JSON.parse_string(FileAccess.get_file_as_string("res://data/gear.json")) as Dictionary
	for item: Variant in gear["gear"]:
		var g: Dictionary = item
		if str(g["id"]) == "bait_corn":
			(g["attract"] as Dictionary)["shark"] = 2.0
		if str(g["id"]) == "reel_master":
			g["drag"] = 0.6
		if str(g["id"]) == "line_braid":
			g["carry"] = 7
		if str(g["id"]) == "lure_spinner":
			(g["attract"] as Dictionary)["chub"] = 0.0002
	# Kamış ortak yuva olamaz.
	((gear["slots"] as Dictionary)["shared"] as Array).append("rod")
	_write(dir.path_join("gear.json"), JSON.stringify(gear))
	var db := ContentDB.load_from(dir)
	var all := " | ".join(db.errors)
	assert_true("bait_corn" in all, "yemin bilinmeyen balığı yakalanır")
	assert_true("reel_master" in all, "aşırı fren yakalanır")
	assert_true("sturgeon: pull" in all, "iri türün en irisinde sakin çekiş sınırı aşarsa yakalanır")
	assert_true("line_braid: carry" in all, "taşıma 1–5 yıldız dışında yakalanır")
	assert_true("rudd: pull" in all, "sakin çekişi sınırı aşan balık yakalanır: " + all)
	assert_true("carp: value" in all, "satılan balığın değeri 0 olamaz")
	assert_true("shark" in all, "bilinmeyen balık yakalanır")
	assert_true("başlangıç" in all, "suyun içindeki başlangıç yakalanır")
	assert_true("slots.shared" in all, "ortak yuvada kamış yakalanır")
	assert_true("tench: bilinmeyen teknik" in all, "yatkınlıkta bilinmeyen teknik yakalanır")
	assert_true("perch: bilinmeyen teknik ya da geçersiz yatkınlık: spin" in all, "binde birin altındaki yatkınlık")
	assert_true("lure_spinner: bilinmeyen balık ya da geçersiz çarpan: chub" in all, "binde birin altındaki çekim")
	assert_true("chub: when: bilinmeyen ad ya da geçersiz çarpan (0,001–5): dusk" in all, "bilinmeyen vakit")
	assert_true("chub: when: bilinmeyen ad ya da geçersiz çarpan (0,001–5): noon" in all, "sıfır vakit çarpanı")
	assert_true("chub: weather: bilinmeyen ad ya da geçersiz çarpan (0,001–5): snow" in all, "bilinmeyen hava")
	assert_true("bream: only.phase: bilinmeyen vakit: teatime" in all, "only'de bilinmeyen vakit")
	assert_true("bream: only: bilinmeyen koşul: season" in all, "only'de bilinmeyen koşul")
	assert_true("bream: only (belli vakitte gelen) tür release_only olmalı" in all, "belli vakitte gelen tür satılamaz")
	for file in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(dir.path_join(file)))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(dir))


## Saat, hava ve sevgi kuralları denetlenir (rules.json clock, weather, love).
func test_world_rules_are_validated() -> void:
	var errors := PackedStringArray()
	var rules := JSON.parse_string(FileAccess.get_file_as_string("res://data/rules.json")) as Dictionary
	rules["clock"] = { "phase_s": 10, "start_hour": 30 }
	rules["weather"] = { "chance": { "clear": 50, "hail": 5 }, "first_day": "storm", "fog_phases": ["dusk"],
		"fog_else": "fog", "rain_notice": 0.5 }
	rules["love"] = { "levels": [0, 20, 10], "rare_bonus": 0.5, "rare_from": "shiny" }
	FishingRules.from_dict(rules, errors)
	var all := " | ".join(errors)
	assert_true("weather.chance: bilinmeyen hava: hail" in all, "bilinmeyen hava")
	assert_true("geçersiz: saat" in all, "vakit 1 dk'dan kısa, saat 24'ten büyük")
	assert_true("geçersiz: hava" in all, "ilk gün ya da sisin yerine bilinmeyen hava, bilinmeyen vakit")
	assert_true("geçersiz: yağmur" in all, "yağmur fark etmeyi azaltamaz")
	assert_true("geçersiz: göl sevgisi" in all, "eşikler artmalı, pay en çok 0,1")
	var clean := PackedStringArray()
	FishingRules.from_dict(JSON.parse_string(FileAccess.get_file_as_string("res://data/rules.json")) as Dictionary, clean)
	assert_eq(clean.size(), 0, "oyunun kuralları temiz: " + " | ".join(clean))


## Bölge verisi denetlenir: bilinmeyen havza bölgesi, suyun içindeki atış noktası, karadaki
## şamandıra, geçersiz rütbe.
func test_zone_validation_catches_bad_data() -> void:
	var dir := "user://test_bad_zones"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	for file: String in ["rarities.json", "rules.json", "progression.json", "fish.json", "gear.json"]:
		var text := FileAccess.get_file_as_string("res://data/" + file)
		_write(dir.path_join(file), text)
	var spots := JSON.parse_string(FileAccess.get_file_as_string("res://data/spots.json")) as Dictionary
	for raw: Variant in spots["spots"]:
		var spot: Dictionary = raw
		if str(spot["id"]) != "big_lake":
			continue
		var zones: Array = spot["zones"]
		(zones[1] as Dictionary)["stands"] = [[-17.5, -3.5]]
		(zones[5] as Dictionary)["buoys"] = [[0.0, 10.0]]
		(zones[2] as Dictionary)["rank"] = 99
		# Her bölgede şamandıra olmalı; sinek yalnızca akıntılı bölgede.
		(zones[0] as Dictionary)["techniques"] = ["spin", "fly"]
		# Dede bölgede avlanılmayan tekniği önermez (sazlıkta sinek yok).
		(zones[1] as Dictionary)["suggest"] = "fly"
		# Koruma altındaki tür tuzağa girmez (kovaya giremez, tuzak hiç boşalmazdı).
		((zones[1] as Dictionary)["trap"] as Dictionary)["sturgeon"] = 1
		((spot["basins"] as Array)[2] as Dictionary)["zone"] = "swamp"
	_write(dir.path_join("spots.json"), JSON.stringify(spots))
	var db := ContentDB.load_from(dir)
	var all := " | ".join(db.errors)
	assert_true("swamp" in all, "bilinmeyen havza bölgesi yakalanır: " + all)
	assert_true("reeds atış noktası" in all, "suyun içindeki atış noktası yakalanır")
	assert_true("deep_water şamandırası" in all, "karadaki şamandıra yakalanır")
	assert_true("lily_cove bölgesinin rütbesi" in all, "geçersiz rütbe yakalanır")
	assert_true("dock_cove bölgesinde şamandıra" in all, "şamandırasız bölge yakalanır")
	assert_true("dock_cove: sinek yalnızca akıntılı" in all, "akıntısız bölgede sinek yakalanır")
	assert_true("reeds: önerilen teknik bölgede avlanılmıyor: fly" in all, "avlanılmayan öneri yakalanır")
	assert_true("reeds: koruma altındaki tür tuzağa girmez: sturgeon" in all, "tuzakta koruma altındaki tür yakalanır")
	for file in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(dir.path_join(file)))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(dir))


## Takım ve rütbe: başlangıç takımı bedava, kategoriler sıralı, rütbe eşikleri ve unvanlar.
func test_gear_and_ranks() -> void:
	var db := content()
	for slot: String in db.slots_for("float"):
		var item := db.gear_item(str(db.gear_start[slot]))
		assert_eq(str(item.get("category", "")), slot, "başlangıç takımı: " + slot)
		assert_eq(int(item.get("price", -1)), 0, "başlangıç takımı bedava: " + slot)
	assert_eq(str(db.gear_in("rod")[0]["id"]), "rod_bamboo", "ilk kamış bambu")
	assert_eq(float(db.gear_item("rod_bamboo")["range_m"]), 9.0, "bambu kamış bugünkü bambu olta gibi 9 m")
	assert_eq(float(db.gear_item("reel_basic")["reel_speed"]), 1.6, "basit makara bugünkü sarma hızı")
	assert_eq(FishingRules.to_steps(float(db.gear_item("line_mono_thin")["snap_after"])), db.rules.snap_steps, "ince misina bugünkü kopma süresi")
	assert_eq(int(db.gear_item("bait_worm")["pack"]), 0, "solucan sınırsız")
	assert_eq(int(db.gear_item("rod_bamboo")["carry"]), db.rules.carry, "bambu kamış kurallardaki kadar taşır")
	assert_eq(int(db.gear_item("line_mono_thin")["carry"]), db.rules.carry, "ince misina kurallardaki kadar taşır")
	assert_eq(db.rank_for_xp(0), 1, "0 puan: 1. rütbe")
	assert_eq(db.rank_for_xp(db.rank_xp[1] - 1), 1, "eşiğin altı")
	assert_eq(db.rank_for_xp(db.rank_xp[1]), 2, "eşikte bir üst rütbe")
	assert_eq(db.rank_for_xp(999999), db.max_rank(), "en yüksek rütbede durur")
	assert_eq(db.rank_title(1), "novice", "ilk unvan")
	assert_eq(db.rank_title(3), "apprentice", "3. rütbeden çırak")
	assert_eq(db.rank_title(20), "lake_legend", "son unvan")


func test_rarity_lookups() -> void:
	var db := content()
	assert_eq(db.rarity_index("common"), 0, "sıradan ilk nadirlik")
	assert_eq(db.rarity_index("legendary"), 4, "efsanevi 5. nadirlik")
	assert_eq(db.rarity_index("mythic"), db.rarities.size() - 1, "masalsı son nadirlik (sona eklendi)")
	assert_eq(db.rarity_index("yok"), -1, "bilinmeyen nadirlik")
	assert_eq(db.rarity_id(2), "rare", "2: nadir")
	assert_true(db.rarity_def(99).is_empty(), "olmayan sıra boş döner")


## Teknikler (Dalga 3): makara ve misina ortak, her tekniğin kendi yuvaları; türlerin teknik
## yatkınlığı (şamandırada Dalga 3 öncesi bütün türler 1: oranları değişmez).
func test_technique_slots_and_affinity() -> void:
	var db := content()
	assert_eq(db.slots_for("float"), ["rod", "reel", "line", "hook", "bobber", "bait"] as Array[String],
			"şamandıranın yuvaları v0.3'teki sırayla")
	assert_eq(db.slots_for("spin"), ["rod", "reel", "line", "lure"] as Array[String], "spin: kamış ve yapay yem")
	assert_eq(db.slots_for("bottom"), ["rod", "reel", "line", "bait", "rig"] as Array[String], "dip: kamış, yem, kurşun")
	assert_eq(db.slots_for("fly"), ["rod", "reel", "line", "fly"] as Array[String], "sinek: kamış ve sinek")
	assert_true(db.is_shared("reel") and db.is_shared("line") and not db.is_shared("rod"), "makara ve misina ortak")
	for pair: Array in [["hook", "float"], ["bobber", "float"], ["lure", "spin"], ["rig", "bottom"], ["fly", "fly"],
			["rod", ""], ["bait", ""], ["reel", ""]]:
		assert_eq(db.slot_technique(str(pair[0])), str(pair[1]), "yuvanın tekniği: %s" % pair[0])
	for id: String in ["rudd", "silverside", "bream", "chub", "carp", "perch", "tench", "pike", "zander", "wels",
			"golden_carp", "sturgeon"]:
		assert_eq(db.affinity(id, "float"), 1.0, "%s şamandırayla eskisi gibi gelir" % id)
	assert_eq(db.affinity("perch", "spin"), 1.0, "levrek oynayan yeme gelir")
	assert_eq(db.affinity("carp", "spin"), 0.0, "sazan yapay yeme gelmez")
	assert_true(db.affinity("sturgeon", "bottom") > 1.0, "mersin dipte daha çok gelir")
	var zones := {}
	for z in db.zones_of(db.main_spot):
		zones[str(z["id"])] = z["techniques"]
	assert_true("fly" in (zones["stream_mouth"] as PackedStringArray), "dere ağzında sinek")
	for id: String in zones:
		assert_true("float" in (zones[id] as PackedStringArray), "%s: şamandıra" % id)
		if id != "stream_mouth":
			assert_true(not "fly" in (zones[id] as PackedStringArray), "%s: akıntı yok, sinek yok" % id)


## Takımın görseli yokken kodla çizilen ikonu var (dükkânda boş kart kalmasın).
func test_gear_kinds_are_drawable() -> void:
	for g in content().gear:
		# Kodla çizilen ikon: türün kendisi ya da yedeği (yapay yem, kurşun, sinek → yem).
		var drawn := str(GameIcon.FALLBACK.get(str(g["kind"]), str(g["kind"])))
		assert_true(drawn in GameIcon.DRAWN, "%s: kodla çizilen ikon yok (kind %s)" % [g["id"], g["kind"]])


func test_every_content_id_has_translations() -> void:
	var db := content()
	var table := _read_translations()
	var keys: Array[String] = []
	for r in db.rarities:
		keys.append("RARITY_" + str(r["id"]))
	for f in db.fish:
		keys.append("FISH_" + str(f["id"]))
		keys.append("FISH_" + str(f["id"]) + "_DESC")
	for g in db.gear:
		keys.append("GEAR_" + str(g["id"]))
		keys.append("GEAR_" + str(g["id"]) + "_DESC")
	for t in db.rank_titles:
		keys.append("RANK_" + str(t["id"]))
	for s in db.spots:
		keys.append("SPOT_" + str(s["id"]))
		# Bölge adları (haritada, defterde); eski şemadaki tek bölge ("main") adsız.
		for z: Dictionary in s["zones"]:
			if str(z["id"]) != "main":
				keys.append("ZONE_" + str(z["id"]))
			# Dede'nin bölgede önerdiği teknik.
			if not str(z["suggest"]).is_empty():
				keys.append("UI_DEDE_SUGGEST_" + str(z["id"]))
	for i in range(1, Elder.TIP_COUNT + 1):
		keys.append(Elder.TIP_KEY % i)
	# Vakitler ve havalar (saat çipi, defter; Dalga 4); fırtına yağmurlu gece.
	for phase in DayClock.PHASES:
		keys.append("PHASE_" + phase)
	for kind in Weather.KINDS:
		keys.append("WEATHER_" + kind)
	keys.append("WEATHER_storm")
	for phase in DayClock.PHASES:
		keys.append("UI_PHASE_NOW_" + phase)
	# Defterin vakit ve hava ipuçları (BookPanel._time_hints; birleştirilen anahtarlar).
	for f in db.fish:
		for key in BookPanel._time_hints(db, str(f["id"])):
			keys.append(key)
	# Göle bırakılan her türün kartta Dede'nin kendi sözü (FishCard.dede_line).
	for f in db.fish:
		if bool(f["release_only"]) and db.rarity_id(int(f["rarity"])) != "mythic":
			keys.append("UI_DEDE_CARD_RELEASE_" + str(f["id"]))
	for id: String in Elder.TECH_TIPS:
		keys.append(str(Elder.TECH_TIPS[id]))
	for i in range(1, Nine.LINE_COUNT + 1):
		keys.append(Nine.LINE_KEY % i)
	# Dede'nin karttaki sözleri: Nadir ve üstü her nadirlik için; koruma altındaki türde koruma sözü.
	for r in db.rarities:
		var line := FishCard.dede_line(db, db.rarity_index(str(r["id"])), {})
		if not line.is_empty():
			keys.append(line)
	for f in db.fish:
		var line := FishCard.dede_line(db, int(f["rarity"]), {}, str(f["id"]))
		if not line.is_empty() and not line in keys:
			keys.append(line)
	for key in keys:
		assert_true(table.has(key), "çeviri anahtarı eksik: " + key)
		if table.has(key):
			var row: PackedStringArray = table[key]
			assert_true(row.size() >= 3 and not row[1].is_empty() and not row[2].is_empty(), "EN/TR metni boş: " + key)


## Kodda geçen "UI_..." anahtarlarının hepsi CSV'de olmalı (yazım hatalarını yakalar).
func test_ui_keys_used_in_code_exist() -> void:
	var table := _read_translations()
	# "_" ile biten dizgi anahtar değil ön ektir (Moods.BY_PREFIX; test_moods denetler).
	var regex := RegEx.create_from_string("\"(UI_[A-Z0-9_]*[A-Z0-9])\"")
	var paths := _gd_files("res://scenes")
	paths.append_array(_gd_files("res://scripts"))
	assert_true(paths.size() > 0, "taranacak script bulunamadı")
	for path in paths:
		for m in regex.search_all(FileAccess.get_file_as_string(path)):
			assert_true(table.has(m.get_string(1)), "%s: çeviri anahtarı eksik: %s" % [path, m.get_string(1)])


## CSV'de her satırın İngilizce ve Türkçe metni dolu.
func test_translation_rows_are_complete() -> void:
	var table := _read_translations()
	assert_true(table.size() > 10, "çeviri tablosu okundu")
	for key: String in table:
		if key == "keys":
			continue
		var row: PackedStringArray = table[key]
		assert_true(row.size() >= 3 and not row[1].is_empty() and not row[2].is_empty(), "EN/TR metni boş: " + key)


## Biçimli metinlerde İngilizcesi ve Türkçesi aynı yer tutucuları aynı sırayla taşır (%s, %d): GDScript'in
## % işlecinde sıra numarası yok, yer değiştiren yer tutucu çalışırken hata verir.
func test_translation_placeholders_match() -> void:
	var table := _read_translations()
	var regex := RegEx.create_from_string("%[sd%]")
	for key: String in table:
		var row: PackedStringArray = table[key]
		if key == "keys" or row.size() < 3:
			continue
		var en := PackedStringArray()
		for m in regex.search_all(row[1]):
			en.append(m.get_string())
		var tr_marks := PackedStringArray()
		for m in regex.search_all(row[2]):
			tr_marks.append(m.get_string())
		assert_eq(tr_marks, en, "yer tutucular aynı değil: " + key)


static func _read_translations() -> Dictionary:
	var table := {}
	var f := FileAccess.open("res://localization/strings.csv", FileAccess.READ)
	if f == null:
		return table
	while not f.eof_reached():
		var row := f.get_csv_line()
		if row.size() >= 1 and not row[0].is_empty():
			table[row[0]] = row
	return table


static func _gd_files(dir: String) -> Array[String]:
	var out: Array[String] = []
	for file in DirAccess.get_files_at(dir):
		if file.ends_with(".gd"):
			out.append(dir.path_join(file))
	for sub in DirAccess.get_directories_at(dir):
		out.append_array(_gd_files(dir.path_join(sub)))
	return out


## Dosyayı yazar ve kapatır (kapatılmayan dosya okunurken yarım kalabilir).
static func _write(path: String, text: String) -> void:
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(text)
	f.close()
