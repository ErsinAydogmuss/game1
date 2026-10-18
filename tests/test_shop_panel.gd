extends BaseTest
## Dükkân paneli: her teknikte her sekmede en çok 6 kart (kaydırma yok, parmakla aranmaz) ve
## satılan her takım bir teknikte bir sekmede (Kamış ve tekniğe özel sekme bakılan tekniğin;
## ötekiler her teknikte aynı). Kovalar tek kartta: sırası gelen (sahip olunanın bir üstü).


## Dükkânda bakılabilen teknikler (kamışı olanlar).
func _techniques() -> Array[String]:
	var out: Array[String] = []
	for id in ContentDB.TECHNIQUES:
		if content().has_technique(id):
			out.append(id)
	return out


func test_every_tab_fits_one_page() -> void:
	for look in _techniques():
		for t: Array in ShopPanel.TABS:
			var items := ShopPanel.items_for(content(), str(t[0]), null, look)
			assert_true(items.size() <= ShopPanel.CARDS, "%s: %s sekmesinde %d kart (en çok %d)" % [look, t[0],
					items.size(), ShopPanel.CARDS])


func test_every_gear_item_has_a_tab() -> void:
	var shown := {}
	for look in _techniques():
		var here := {}
		for t: Array in ShopPanel.TABS:
			for g in ShopPanel.items_for(content(), str(t[0]), null, look):
				assert_true(not here.has(str(g["id"])), "%s: iki sekmede birden: %s" % [look, g["id"]])
				here[str(g["id"])] = true
				shown[str(g["id"])] = true
	for g in content().gear:
		# Kovalar sırası gelince (aşağıda).
		if str(g["category"]) == "bucket":
			continue
		assert_true(shown.has(str(g["id"])), "dükkânda yok: " + str(g["id"]))


## Ekstra sekmesinde kovalardan yalnızca sıradaki: alındıkça bir üstü gelir; hepsi alınınca en büyüğü.
func test_buckets_show_one_at_a_time() -> void:
	var db := content()
	var save := SaveData.create_new(0)
	var seen: Array[String] = []
	for i in 10:
		var buckets: Array[String] = []
		for g in ShopPanel.items_for(db, "extra", save):
			if str(g["category"]) == "bucket":
				buckets.append(str(g["id"]))
		assert_eq(buckets.size(), 1, "tek kova kartı")
		if buckets.is_empty() or buckets[0] in seen:
			break
		seen.append(buckets[0])
		save.owned.append(buckets[0])
	var paid := 0
	for g in db.gear_in("bucket"):
		if int(g["price"]) > 0:
			paid += 1
	assert_eq(seen.size(), paid, "satılık her kova sırayla gelir: %s" % str(seen))
	var last := Bucket.next_bucket(db, save)
	assert_eq(int(last["capacity"]), Bucket.capacity(db, save), "hepsi alınınca en büyüğü (sende)")
	var extra := ShopPanel.items_for(db, "extra", SaveData.create_new(0))
	var ids: Array[String] = []
	for g in extra:
		ids.append(str(g["id"]))
	assert_true("net" in ids and "boat" in ids, "Ekstra: kepçe ve sandal (%s)" % str(ids))


func test_stats_exist_on_items() -> void:
	for category: String in ShopPanel.STATS:
		for g in content().gear_in(category):
			for stat: Array in ShopPanel.STATS[category]:
				assert_true(g.has(str(stat[0])), "%s: değer yok: %s" % [g["id"], stat[0]])


## Sekme adları (her teknikte, iki dilde) sekmeye sığar: uzun ad (Yapay yem) küçülür, en küçük boyda
## da sekme görselinin payları içinde kalır.
func test_tab_titles_fit() -> void:
	var rows := {}
	var f := FileAccess.open("res://localization/strings.csv", FileAccess.READ)
	while f != null and not f.eof_reached():
		var row := f.get_csv_line()
		if row.size() >= 3:
			rows[row[0]] = row
	var keys: Array[String] = []
	for t: Array in ShopPanel.TABS:
		keys.append(str(t[2]))
	for look: String in ShopPanel.TECHNIQUE_TACKLE:
		keys.append(str((ShopPanel.TECHNIQUE_TACKLE[look] as Array)[1]))
	var font := UiKit.display_font()
	var room := ShopPanel.tab_text_room()
	assert_true(room > 100.0, "sekmede yazıya yer var (%.0f)" % room)
	for key in keys:
		for column: int in [1, 2]:
			var text := UiKit.upper((rows[key] as PackedStringArray)[column])
			var size := UiKit.fit_size(text, font, 26, room, ShopPanel.TAB_MIN_FONT)
			var width := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
			assert_true(width <= room, "%s (%s) sekmeye sığmıyor: %.0f > %.0f" % [key, "en" if column == 1 else "tr",
					width, room])
