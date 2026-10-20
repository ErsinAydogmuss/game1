extends BaseTest
## "Nasıl oynanır?" rehberi (GuidePages). Denetlenenler:
## - kapsam: her teknik ve tuzak, ana gölün her bölgesi, göldeki her nadirlik, dükkânın her takım
##   kategorisi ve her sekmesi rehberde;
## - çeviri: her anahtar iki dilde var, sayılar yerinde, sayıdan sonra ek yok;
## - sığma: yazılar gerçek fontlarla, iki dilde karosuna sığar;
## - kilit: o rütbenin puanında açılır, derin orta sandal ister.


func _rows() -> Dictionary:
	var rows := {}
	var f := FileAccess.open("res://localization/strings.csv", FileAccess.READ)
	while f != null and not f.eof_reached():
		var row := f.get_csv_line()
		if row.size() >= 3:
			rows[row[0]] = row
	return rows


## CSV'nin bir sütunundaki yazı (1 İngilizce, 2 Türkçe; yoksa anahtarın kendisi).
static func _text(rows: Dictionary, key: String, column: int) -> String:
	return (rows[key] as PackedStringArray)[column] if rows.has(key) else key


## Büyük harf: Türkçe sütunda i → İ (UiKit.upper o anki dile bakar; testte dil yok).
static func _upper(text: String, column: int) -> String:
	return (text.replace("i", "İ") if column == 2 else text).to_upper()


func test_pages_are_well_formed() -> void:
	var db := content()
	var ids := {}
	for p in GuidePages.PAGES:
		var id := str(p["id"])
		assert_true(not ids.has(id), "sayfa iki kez: " + id)
		ids[id] = true
		assert_true(GuidePages.LAYOUTS.has(str(p["layout"])), "%s: bilinmeyen düzen %s" % [id, p["layout"]])
		var layout: Array = GuidePages.LAYOUTS[str(p["layout"])]
		var tiles := GuidePages.tiles_of(db, id)
		assert_true(tiles.size() >= 1 and tiles.size() <= int(layout[0]) * int(layout[1]),
				"%s: %d karo (en çok %d)" % [id, tiles.size(), int(layout[0]) * int(layout[1])])
		var tile_ids := {}
		for tile in tiles:
			assert_true(not tile_ids.has(str(tile["id"])), "%s: karo iki kez: %s" % [id, tile["id"]])
			tile_ids[str(tile["id"])] = true
			assert_true(not (tile["text"] as Array).is_empty(), "%s/%s: metin yok" % [id, tile["id"]])
	assert_eq(GuidePages.page_index("basics"), 0, "ilk sayfa balık tutmak")
	assert_eq(GuidePages.page_index("yok"), -1, "bilinmeyen sayfa")


## Rehber oyunun her parçasını anlatır: teknikler ve tuzak, bölgeler, nadirlikler, takım kategorileri.
func test_guide_covers_the_game() -> void:
	var db := content()
	var techniques := {}
	for tile in GuidePages.tiles_of(db, "techniques"):
		techniques[str(tile["technique"])] = tile
	for t: String in ContentDB.TECHNIQUES:
		if db.has_technique(t):
			assert_true(techniques.has(t), "teknik rehberde yok: " + t)
			if techniques.has(t):
				assert_eq(int(techniques[t]["rank"]), db.technique_rank(t), "tekniğin kilidi: " + t)
	assert_true(techniques.has("trap"), "kerevit tuzağı rehberde")
	if techniques.has("trap"):
		assert_eq(int(techniques["trap"]["rank"]), TrapSim.rank(db), "tuzağın kilidi")
	var zones := {}
	for tile in GuidePages.tiles_of(db, "zones"):
		zones[str(tile["zone"])] = tile
	for z in db.zones_of(db.main_spot):
		var id := str(z["id"])
		assert_true(zones.has(id), "bölge rehberde yok: " + id)
		assert_true(GuidePages.ZONE_KEYS.has(id), "bölgenin tarifi yok: " + id)
		if zones.has(id):
			assert_eq(int(zones[id]["rank"]), int(z["rank"]), "bölgenin kilidi: " + id)
			assert_eq(bool(zones[id]["boat"]), bool(z["boat"]), "bölgenin sandalı: " + id)
			var suggest := str(z["suggest"])
			if not suggest.is_empty():
				assert_true("tech_" + suggest in (zones[id]["icons"] as PackedStringArray), "Dede'nin önerisi: " + id)
	var rarities := {}
	for tile in GuidePages.tiles_of(db, "rarity"):
		rarities[int(tile["rarity"])] = true
	for f in BookPanel.species(db, db.main_spot):
		assert_true(rarities.has(int(f["rarity"])), "nadirlik rehberde yok: " + db.rarity_id(int(f["rarity"])))
	var categories := {}
	for p in GuidePages.PAGES:
		for tile in GuidePages.tiles_of(db, str(p["id"])):
			if not str(tile["category"]).is_empty():
				categories[str(tile["category"])] = str(p["id"])
	for category: String in ContentDB.GEAR_CATEGORIES:
		assert_true(categories.has(category), "takım kategorisi rehberde yok: " + category)
	# Her bölgede avlanılmayan teknik (sinek) yerini söyler.
	for t: String in ContentDB.TECHNIQUES:
		if not db.has_technique(t):
			continue
		var everywhere := true
		for z in db.zones_of(db.main_spot):
			everywhere = everywhere and t in (z["techniques"] as PackedStringArray)
		if not everywhere:
			assert_true(GuidePages.WHERE_KEYS.has(t), "tekniğin yeri yazılmamış: " + t)
	for fx: String in ContentDB.SHADOW_FX:
		assert_true(GuidePages.SHADOW_KEYS.has(fx), "gölge ipucunun yazısı yok: " + fx)


## Dükkânın her sekmesinin "?"si o sekmedeki takımı anlatan sayfayı açar (her teknikte).
func test_shop_tabs_open_their_page() -> void:
	var db := content()
	for t: Array in ShopPanel.TABS:
		var tab := str(t[0])
		var page_id := GuidePages.page_for_shop_tab(tab)
		assert_true(GuidePages.page_index(page_id) >= 0, "%s sekmesinin sayfası yok: %s" % [tab, page_id])
		var on_page := {}
		for tile in GuidePages.tiles_of(db, page_id):
			on_page[str(tile["category"])] = true
		var categories: Array = (t[3] as Array).duplicate()
		if tab == "tackle":
			for look: String in ShopPanel.TECHNIQUE_TACKLE:
				categories.append_array((ShopPanel.TECHNIQUE_TACKLE[look] as Array)[0])
		for category: Variant in categories:
			assert_true(on_page.has(str(category)), "%s sekmesinin %s takımı %s sayfasında yok" % [tab, category, page_id])
	assert_eq(GuidePages.page_for_shop_tab("sell"), "loop", "kova sekmesi: oyunun döngüsü")
	assert_eq(GuidePages.page_for_shop_tab("bilinmeyen"), "basics", "bilinmeyen sekme: ilk sayfa")


## Rehberin her anahtarı iki dilde var, verilen sayılar yer tutucularla aynı sayıda, Türkçede sayıdan
## sonra ek yok ("%d'de" sayıya göre değişir) ve satır sonu yok (CSV'de "\n" iki harf kalır).
func test_keys_exist_with_matching_numbers() -> void:
	var db := content()
	var rows := _rows()
	var marks := RegEx.create_from_string("%[sd]")
	var checked := 0
	for p in GuidePages.PAGES:
		var id := str(p["id"])
		for key in GuidePages.keys_of(db, id):
			assert_true(rows.has(key), "%s: çeviri yok: %s" % [id, key])
			checked += 1
		for tile in GuidePages.tiles_of(db, id):
			for line: Array in tile["text"]:
				var key := str(line[0])
				if not rows.has(key):
					continue
				for column: int in [1, 2]:
					var text := _text(rows, key, column)
					assert_eq(marks.search_all(text).size(), (line[1] as Array).size(), "%s: sayılar (%d. sütun)" % [key, column])
	assert_true(checked > 60, "anahtarlar denetlendi (%d)" % checked)
	for key: String in rows:
		if not key.begins_with("UI_GUIDE_"):
			continue
		var tr_text := _text(rows, key, 2)
		assert_true(not RegEx.create_from_string("%[sd]'").search(tr_text), "sayıdan sonra ek: " + key)
		for column: int in [1, 2]:
			assert_true(not "\\n" in _text(rows, key, column), "satır sonu yerine iki harf: " + key)


## Yazılar gerçek fontlarla iki dilde yerine sığar: karonun metni metin kutusuna, başlığı (büyük harf,
## gerekirse küçülerek) karonun genişliğine, giriş cümlesi tek satıra, alttaki satır karoya.
func test_texts_fit_in_both_languages() -> void:
	var db := content()
	var rows := _rows()
	var body := UiKit.body_font()
	var display := UiKit.display_font()
	for p in GuidePages.PAGES:
		var id := str(p["id"])
		var layout := str(p["layout"])
		for column: int in [1, 2]:
			var lang := "en" if column == 1 else "tr"
			var lead := _text(rows, str(p["lead"]), column)
			var lead_w := body.get_string_size(lead, HORIZONTAL_ALIGNMENT_LEFT, -1, GuidePages.LEAD_SIZE).x
			assert_true(lead_w <= GuidePages.LEAD_W, "%s (%s): giriş tek satıra sığmıyor (%.0f)" % [id, lang, lead_w])
			for tile in GuidePages.tiles_of(db, id):
				var titled := not str(tile["title"]).is_empty()
				var box := GuidePages.text_box(layout, titled)
				var text := GuidePages.text_of(tile, func(key: String) -> String: return _text(rows, key, column))
				var size := GuidePages.text_size(body, text, box.x)
				assert_true(size.x <= box.x + 0.5 and size.y <= box.y, "%s/%s (%s): metin sığmıyor %s > %s: %s" % [id,
						tile["id"], lang, size, box, text])
				if titled:
					var title := _upper(_text(rows, str(tile["title"]), column), column)
					var width := GuidePages.column_width(layout)
					var fitted := UiKit.fit_size(title, display, GuidePages.TITLE_SIZE, width, GuidePages.TITLE_MIN)
					assert_true(display.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, fitted).x <= width,
							"%s/%s (%s): başlık sığmıyor: %s" % [id, tile["id"], lang, title])
				assert_true(_footer_width(db, tile, rows, column) <= GuidePages.column_width(layout),
						"%s/%s (%s): alttaki satır sığmıyor (%.0f > %.0f)" % [id, tile["id"], lang,
						_footer_width(db, tile, rows, column), GuidePages.column_width(layout)])


## Alttaki satırın en geniş hâli: küçük ikonlar, yıldızlar ve sağda kilit hapı ya da yer hapı
## (hangisi genişse).
func _footer_width(db: ContentDB, tile: Dictionary, rows: Dictionary, column: int) -> float:
	var display := UiKit.display_font()
	var body := UiKit.body_font()
	var icons := (tile["icons"] as PackedStringArray).size()
	var width := icons * GuidePages.FOOT_ICON + maxi(0, icons - 1) * GuidePages.FOOT_SEP
	if int(tile["step"]) > 0:
		width += GuidePages.FOOT_H + GuidePages.FOOT_SEP
	var stars: Array = tile["stars"]
	if not stars.is_empty():
		width += body.get_string_size(_text(rows, "UI_STAT_CARRY", column), HORIZONTAL_ALIGNMENT_LEFT, -1,
				GuidePages.PILL_SIZE).x + GuidePages.FOOT_SEP + int(stars[1]) * GuidePages.STAR
	var pill := 0.0
	if int(tile["rank"]) > 1:
		var text := _upper(_text(rows, "UI_SHOP_RANK", column) % int(tile["rank"]), column)
		pill = GuidePages.PILL_ICON + GuidePages.FOOT_SEP + display.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1,
				GuidePages.PILL_SIZE).x
	if bool(tile["boat"]):
		var text := _upper(_text(rows, "GEAR_boat", column), column)
		pill = maxf(pill, GuidePages.PILL_ICON + GuidePages.FOOT_SEP + display.get_string_size(text,
				HORIZONTAL_ALIGNMENT_LEFT, -1, GuidePages.PILL_SIZE).x)
	if not str(tile["where"]).is_empty():
		var text := _upper(_text(rows, str(tile["where"]), column), column)
		pill = maxf(pill, display.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, GuidePages.PILL_SIZE).x)
	if pill > 0.0:
		width += GuidePages.FOOT_SEP * 2.0 + pill + GuidePages.PILL_MARGIN.x + GuidePages.PILL_MARGIN.y
	return width


## Rehberin her harfi fontunda var (Luckiest Guy başlıklar, Baloo 2 metinler; ★ ikonla çizilir).
func test_glyphs_exist() -> void:
	var db := content()
	var rows := _rows()
	var body := UiKit.body_font()
	var display := UiKit.display_font()
	for p in GuidePages.PAGES:
		var id := str(p["id"])
		for column: int in [1, 2]:
			var titles := PackedStringArray([_upper(_text(rows, str(p["title"]), column), column)])
			var texts := PackedStringArray([_text(rows, str(p["lead"]), column)])
			for tile in GuidePages.tiles_of(db, id):
				if not str(tile["title"]).is_empty():
					titles.append(_upper(_text(rows, str(tile["title"]), column), column))
				var label := GuidePages.action_label(tile)
				if not label.is_empty():
					titles.append(_upper(_text(rows, label, column), column))
				texts.append(GuidePages.text_of(tile, func(key: String) -> String: return _text(rows, key, column)))
			for text in titles:
				for i in text.length():
					var c := text.unicode_at(i)
					assert_true(c == 32 or display.has_char(c), "%s: başlık fontunda yok: %s (%s)" % [id, char(c), text])
			for text in texts:
				for i in text.length():
					var c := text.unicode_at(i)
					assert_true(c == 10 or c == 32 or body.has_char(c), "%s: metin fontunda yok: %s (%s)" % [id, char(c), text])


## Kilit o rütbenin puanında açılır; derin orta rütbe gelince sandal ister, sandalla açılır.
func test_locks_open_at_their_rank() -> void:
	var db := content()
	var locked := 0
	for p in GuidePages.PAGES:
		for tile in GuidePages.tiles_of(db, str(p["id"])):
			var rank := int(tile["rank"])
			if rank <= 1:
				assert_eq(GuidePages.lock_state(db, SaveData.create_new(0), tile), "boat" if bool(tile["boat"]) else "",
						"%s/%s başta açık" % [p["id"], tile["id"]])
				continue
			locked += 1
			var save := SaveData.create_new(0)
			save.xp = db.rank_xp[rank - 1] - 1
			assert_eq(GuidePages.lock_state(db, save, tile), "rank", "%s/%s rütbe %d'den önce kilitli" % [p["id"],
					tile["id"], rank])
			save.xp = db.rank_xp[rank - 1]
			var expected := "boat" if bool(tile["boat"]) else ""
			assert_eq(GuidePages.lock_state(db, save, tile), expected, "%s/%s rütbe %d'de" % [p["id"], tile["id"], rank])
			if bool(tile["boat"]):
				save.owned.append(Zones.BOAT)
				assert_eq(GuidePages.lock_state(db, save, tile), "", "%s/%s sandalla açık" % [p["id"], tile["id"]])
	assert_true(locked >= 8, "kilitli karolar var (%d)" % locked)
	assert_eq(GuidePages.bag_rank(db), db.technique_rank("spin"), "Takım Çantası ilk teknikle açılır")
	assert_eq(GuidePages.category_rank(db, "fly"), db.technique_rank("fly"), "sinek: tekniğin rütbesi")
	assert_eq(GuidePages.category_rank(db, "extra"), int(db.gear_item("net")["rank"]), "kepçe: kendi rütbesi")
	assert_eq(GuidePages.category_rank(db, "bait"), 1, "yem başta var")


## Sayılar veriden: tuzağın süresi ve üst sınırı, kovalar, tür sayısı, yıldızlar.
func test_numbers_come_from_data() -> void:
	var db := content()
	var techniques := {}
	for tile in GuidePages.tiles_of(db, "techniques"):
		techniques[str(tile["id"])] = tile
	var trap_line: Array = (techniques["trap"]["text"] as Array)[0]
	assert_eq(trap_line[1], [roundi(db.rules.trap_fill_s / 60.0), db.rules.trap_max], "tuzağın süresi ve üst sınırı")
	for tile in GuidePages.tiles_of(db, "extras"):
		if str(tile["id"]) == "bucket":
			var line: Array = (tile["text"] as Array)[0]
			assert_eq(line[1], [6, 36], "kovaların en küçüğü ve en büyüğü")
	for tile in GuidePages.tiles_of(db, "people"):
		if str(tile["id"]) == "book":
			assert_eq(((tile["text"] as Array)[0] as Array)[1], [BookPanel.species(db, db.main_spot).size()], "tür sayısı")
	for tile in GuidePages.tiles_of(db, "rods"):
		if str(tile["id"]) == "rod":
			assert_eq(tile["stars"], [3, 5], "bambu olta 3 yıldız, en iyisi 5")
