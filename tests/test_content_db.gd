extends BaseTest
## İçerik veritabanı (data/*.json) ve çeviriler.


func test_loads_without_errors() -> void:
	var db := content()
	assert_eq(db.errors.size(), 0, "içerik hataları: " + ", ".join(db.errors))
	assert_eq(db.rarities.size(), 5, "5 nadirlik")


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
