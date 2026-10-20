extends BaseTest
## Konuşanların ifadeleri (Moods): sözün yüzü.


func test_tips_tell_and_excitement_wows() -> void:
	for i in range(1, Elder.TIP_COUNT + 1):
		assert_eq(Moods.of("UI_DEDE_TIP_%d" % i), Moods.STORY, "öğüt %d anlatır" % i)
	assert_eq(Moods.of("UI_HINT_CAST"), Moods.STORY, "talimat anlatır")
	assert_eq(Moods.of("UI_HINT_BITE"), Moods.WOW, "VUR anı heyecanlı")
	assert_eq(Moods.of("UI_DEDE_LEGEND_NEAR"), Moods.WOW, "efsanevi uyarısı şaşkın")
	assert_eq(Moods.of("UI_HINT_WAIT"), Moods.SMILE, "bekleme gülümser")
	assert_eq(Moods.of(""), Moods.SMILE, "boş söz gülümser")
	assert_eq(Moods.of("UI_BILINMEYEN"), Moods.SMILE, "listede olmayan gülümser")


## Kartta Dede: yeni tür gülümser, rekor ve Nadir ve üstü şaşırır.
func test_card_lines() -> void:
	var db := content()
	assert_eq(Moods.of(FishCard.dede_line(db, 0, {"new_species": true})), Moods.SMILE, "yeni tür")
	assert_eq(Moods.of(FishCard.dede_line(db, 0, {"new_record": true})), Moods.WOW, "rekor")
	for r in range(db.rarity_index("rare"), db.rarities.size()):
		assert_eq(Moods.of(FishCard.dede_line(db, r, {})), Moods.WOW, "kart: " + db.rarity_id(r))


func test_nine_lines() -> void:
	assert_eq(Moods.of("UI_NINE_SHOP_HELLO"), Moods.SMILE, "selam")
	assert_eq(Moods.of("UI_NINE_BOUGHT"), Moods.STORY, "satın alma: paketi uzatır")
	assert_eq(Moods.of("UI_NINE_SOLD"), Moods.WOW, "satış: sevinir")
	assert_eq(Moods.of("UI_NINE_NO_COINS"), Moods.SMILE, "para yetmeyince de güler yüz")


## Eşlemedeki sözler çeviri tablosunda var (adı değişen söz sessizce gülümsemeye düşmesin), ifadeler
## bilinen üç ifade ve her konuşanın her ifadesinin portresi var.
func test_keys_and_portraits_exist() -> void:
	var keys := {}
	var f := FileAccess.open("res://localization/strings.csv", FileAccess.READ)
	while f != null and not f.eof_reached():
		var row := f.get_csv_line()
		if row.size() >= 1:
			keys[row[0]] = true
	for key: String in Moods.BY_KEY:
		assert_true(keys.has(key), "çeviride var: " + key)
		assert_true(str(Moods.BY_KEY[key]) in Moods.ALL, "bilinen ifade: " + key)
	for prefix: String in Moods.BY_PREFIX:
		var used := false
		for key: String in keys:
			used = used or key.begins_with(prefix)
		assert_true(used, "ön ek kullanılıyor: " + prefix)
	for speaker: String in ["dede", "nine"]:
		for mood in Moods.ALL:
			assert_true(ItemArt.portrait("%s_%s" % [speaker, mood]) != null, "portre: %s_%s" % [speaker, mood])
