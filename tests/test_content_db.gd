extends BaseTest
## İçerik veritabanı (data/*.json) ve çeviriler.


func test_loads_without_errors() -> void:
	var db := content()
	assert_eq(db.errors.size(), 0, "içerik hataları: " + ", ".join(db.errors))
	assert_eq(db.rarities.size(), 5, "5 nadirlik")
	assert_eq(db.fish.size(), 5, "prototipte 5 balık")
	assert_true(not db.rod("bamboo").is_empty(), "ilk olta bambu")
	assert_true(not db.spot("home_lake").is_empty(), "ilk göl")
	assert_true(db.rules != null, "kurallar okundu")


func test_fish_follow_the_design() -> void:
	var db := content()
	var expected := { "rudd": "common", "carp": "common", "perch": "fine", "pike": "rare", "wels": "epic" }
	for id: String in expected:
		var f := db.fish_by_id(id)
		assert_true(not f.is_empty(), "balık var: " + id)
		if not f.is_empty():
			assert_eq(db.rarity_id(int(f["rarity"])), expected[id], id + " nadirliği")
	assert_eq(db.fish_by_id("rudd")["size_cm"], Vector2i(15, 30), "Kızılkanat 15–30 cm")
	assert_eq(db.fish_by_id("wels")["size_cm"], Vector2i(100, 250), "Yayın 100–250 cm")
	assert_eq(db.rod("bamboo")["range_m"], 9.0, "bambu olta 9 m")
	var spot := db.spot("home_lake")
	assert_eq(int(spot["max_shadows"]), 4, "gölde 4 gölge")
	assert_eq(str(spot["first_fish"]), "rudd", "ilk av Kızılkanat")


## Bozuk veri yakalanır: kurallarla çelişen çekişme, bilinmeyen balık, suyun içindeki başlangıç.
func test_validation_catches_bad_data() -> void:
	var dir := "user://test_bad_data"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	for file: String in ["rarities.json", "rules.json", "rods.json"]:
		var text := FileAccess.get_file_as_string("res://data/" + file)
		FileAccess.open(dir.path_join(file), FileAccess.WRITE).store_string(text)
	var fish := JSON.parse_string(FileAccess.get_file_as_string("res://data/fish.json")) as Dictionary
	(fish["fish"][0]["fight"] as Dictionary)["pull"] = 0.95
	FileAccess.open(dir.path_join("fish.json"), FileAccess.WRITE).store_string(JSON.stringify(fish))
	var spots := JSON.parse_string(FileAccess.get_file_as_string("res://data/spots.json")) as Dictionary
	var spot: Dictionary = spots["spots"][0]
	spot["start"] = [0.0, 0.0]
	(spot["fish"] as Dictionary)["shark"] = 5
	FileAccess.open(dir.path_join("spots.json"), FileAccess.WRITE).store_string(JSON.stringify(spots))
	var db := ContentDB.load_from(dir)
	var all := " | ".join(db.errors)
	assert_true("pull" in all, "sakin çekişi sınırı aşan balık yakalanır: " + all)
	assert_true("shark" in all, "bilinmeyen balık yakalanır")
	assert_true("başlangıç" in all, "suyun içindeki başlangıç yakalanır")
	for file in DirAccess.get_files_at(dir):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(dir.path_join(file)))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(dir))


func test_rarity_lookups() -> void:
	var db := content()
	assert_eq(db.rarity_index("common"), 0, "sıradan ilk nadirlik")
	assert_eq(db.rarity_index("legendary"), db.rarities.size() - 1, "efsanevi son nadirlik")
	assert_eq(db.rarity_index("yok"), -1, "bilinmeyen nadirlik")
	assert_eq(db.rarity_id(2), "rare", "2: nadir")
	assert_true(db.rarity_def(99).is_empty(), "olmayan sıra boş döner")


func test_every_content_id_has_translations() -> void:
	var db := content()
	var table := _read_translations()
	var keys: Array[String] = []
	for r in db.rarities:
		keys.append("RARITY_" + str(r["id"]))
	for f in db.fish:
		keys.append("FISH_" + str(f["id"]))
		keys.append("FISH_" + str(f["id"]) + "_DESC")
	for r in db.rods:
		keys.append("ROD_" + str(r["id"]))
	for s in db.spots:
		keys.append("SPOT_" + str(s["id"]))
	for i in range(1, Elder.TIP_COUNT + 1):
		keys.append(Elder.TIP_KEY % i)
	for key in keys:
		assert_true(table.has(key), "çeviri anahtarı eksik: " + key)
		if table.has(key):
			var row: PackedStringArray = table[key]
			assert_true(row.size() >= 3 and not row[1].is_empty() and not row[2].is_empty(), "EN/TR metni boş: " + key)


## Kodda geçen "UI_..." anahtarlarının hepsi CSV'de olmalı (yazım hatalarını yakalar).
func test_ui_keys_used_in_code_exist() -> void:
	var table := _read_translations()
	var regex := RegEx.create_from_string("\"(UI_[A-Z0-9_]+)\"")
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
