extends BaseTest
## Bölge kartı (ZonePanel; testçi: "hangi bölgede hangi balık hangi oranda çıkıyor?"): oranlar oyunun oranı
## (elindeki teknik, şimdiki koşul), en sık gelen önce; şimdi gelmeyen tür ne zaman ya da hangi teknikle gelir;
## bölgenin tekniği oyunun oraya varınca seçeceği teknik.

const SPOT := "big_lake"


func _save() -> SaveData:
	var s := SaveData.create_new(1)
	s.seed = 77
	return s


## Gece (ilk gün açık hava: fırtına yok).
func _night(s: SaveData) -> void:
	s.clock_s = content().rules.phase_s * 3


func _row(rows: Array[Dictionary], id: String) -> Dictionary:
	for r in rows:
		if str(r["id"]) == id:
			return r
	return {}


## Şimdi gelenlerin oranı oyunun oranı (defterinkiyle aynı) ve toplamı tam %100; en sık gelen önce.
func test_rows_are_the_game_odds() -> void:
	var db := content()
	var s := _save()
	for z in db.zones_of(SPOT):
		var id := str(z["id"])
		var rows := ZonePanel.rows(db, s, SPOT, id)
		var odds := BookPanel.odds(db, s, SPOT, id)
		var total := 0
		var last := Dice.PPM + 1
		for r in rows:
			var ppm := int(r["ppm"])
			if str(r["when"]).is_empty():
				assert_eq(ppm, int(odds.get(str(r["id"]), 0)), "%s: %s defterle aynı" % [id, r["id"]])
				assert_true(ppm > 0 and ppm <= last, "%s: en sık gelen önce" % id)
				last = ppm
				total += ppm
			else:
				assert_eq(ppm, 0, "%s: şimdi gelmeyenin oranı yok" % id)
			assert_true(str(r["id"]) in (z["fish_ids"] as PackedStringArray), "%s: bölgenin türü" % id)
		assert_eq(total, Dice.PPM, "%s: oranların toplamı %%100" % id)
		# Kart iki sırada sığar: bölgenin bütün türleri.
		assert_true((z["fish_ids"] as PackedStringArray).size() <= ZonePanel.COLUMNS * 2, "%s: iki sıraya sığar" % id)


## Ay Turnası gündüz nilüferli koyda "Gece gelir" (oran yok, sonda); gece oranıyla gelir.
func test_night_legend_says_when() -> void:
	var db := content()
	var s := _save()
	var day := ZonePanel.rows(db, s, SPOT, "lily_cove")
	var moon := _row(day, "moon_pike")
	assert_eq(str(moon.get("when", "")), "UI_ZONE_NIGHT", "gündüz: gece gelir")
	assert_eq(str(day[-1]["id"]), "moon_pike", "şimdi gelmeyen sonda")
	_night(s)
	var night := _row(ZonePanel.rows(db, s, SPOT, "lily_cove"), "moon_pike")
	assert_true(str(night.get("when", "x")).is_empty() and int(night.get("ppm", 0)) > 0, "gece oranıyla")
	# Kocabaş yalnızca fırtınada (yağmurlu gece): açık gecede de "Fırtınada".
	var deep := _row(ZonePanel.rows(db, s, SPOT, "deep_water"), "kocabas")
	assert_eq(str(deep.get("when", "")), "UI_ZONE_STORM", "Kocabaş fırtınada")


## Şamandırayla gelmeyen tür, onu en sık getiren teknikle: dere ağzında alabalık sinekle, sazlıkta kerevit dipte.
func test_other_technique_is_named() -> void:
	var db := content()
	var s := _save()
	var trout := _row(ZonePanel.rows(db, s, SPOT, "stream_mouth"), "trout")
	assert_eq(str(trout.get("when", "")), "UI_ZONE_WITH", "alabalık başka teknikle")
	assert_eq(str(trout.get("technique", "")), "fly", "en sık sinekle")
	var crayfish := _row(ZonePanel.rows(db, s, SPOT, "reeds"), "crayfish")
	assert_eq(str(crayfish.get("technique", "")), "bottom", "kerevit dipte")


## Bölgenin tekniği: orada avlanılmayan teknik (sinek) yerine şamandıra; şamandıraya dönülüp bırakılan sinek dere
## ağzında yine sinek; kamışı alınmamış teknik sayılmaz.
func test_technique_for_the_zone() -> void:
	var db := content()
	var s := _save()
	assert_eq(ZonePanel.technique_for(db, s, SPOT, "stream_mouth"), "float", "yeni oyunda şamandıra")
	var rod := str(db.rods_of("fly")[0]["id"]) if not db.rods_of("fly").is_empty() else ""
	assert_true(not rod.is_empty(), "sinek kamışı var")
	s.owned.append(rod)
	s.technique = "fly"
	assert_eq(ZonePanel.technique_for(db, s, SPOT, "stream_mouth"), "fly", "dere ağzında sinek")
	assert_eq(ZonePanel.technique_for(db, s, SPOT, "dock_cove"), "float", "iskelede sinek yok: şamandıra")
	s.technique = "float"
	s.flags[Economy.HELD_FLAG] = "fly"
	assert_eq(ZonePanel.technique_for(db, s, SPOT, "stream_mouth"), "fly", "bırakılan sinek dere ağzında geri gelir")
	assert_eq(ZonePanel.technique_for(db, s, SPOT, "reeds"), "float", "sazlıkta şamandıra")
	# Sinek tekniğiyle dere ağzının oranları: alabalık şimdi gelir.
	var trout := _row(ZonePanel.rows(db, s, SPOT, "stream_mouth"), "trout")
	assert_true(int(trout.get("ppm", 0)) > 0, "sinekle alabalık oranıyla")


## İleri bölgenin hapı (yapı 4): çarpanın yazısı tam sayıda yalın, kesirde dilin ondalık ayracıyla.
func test_multiplier_text() -> void:
	assert_eq(ZonePanel.multiplier_text(2000), "2", "tam sayı")
	assert_eq(ZonePanel.multiplier_text(1000), "1", "bir")
	var text := ZonePanel.multiplier_text(1700)
	assert_true(text.begins_with("1") and text.ends_with("7") and text.length() == 3, "1,7 ya da 1.7: " + text)
	assert_eq(ZonePanel.multiplier_text(1996), "2", "yuvarlanır")
	var lily := ZonePanel.multiplier_text(1150)
	assert_true(lily.begins_with("1") and lily.ends_with("15") and lily.length() == 4, "1,15 yazılır: " + lily)
	assert_eq(ZonePanel.multiplier_text(1700).length(), 3, "sondaki sıfır yazılmaz")


## Bölgenin canavarı satırı (yapı 5): eksik takım adıyla (ikiden fazlası sayıyla), takım hazır (tekniğin adıyla),
## yenildi.
func test_boss_text() -> void:
	var db := content()
	var s := SaveData.create_new(5)
	s.xp = db.rank_xp[6]
	var name := TranslationServer.translate("FISH_pier_king")
	var start := ZonePanel.boss_text(db, s, SPOT, "dock_cove")
	assert_eq(start, TranslationServer.translate("UI_ZONE_BOSS_NEED_N") % [name, 5], "başta beş takım eksik: " + start)
	for id: String in ["rod_float_carbon", "bobber_bright", "hook_large", "reel_strong"]:
		s.owned.append(id)
		Economy.equip(db, s, id, "float")
	assert_eq(ZonePanel.boss_text(db, s, SPOT, "dock_cove"), TranslationServer.translate("UI_ZONE_BOSS_NEED") % [name,
			TranslationServer.translate("GEAR_line_braid")], "biri eksik: adıyla")
	s.owned.append("line_braid_pro")
	Economy.equip(db, s, "line_braid_pro", "float")
	assert_eq(ZonePanel.boss_text(db, s, SPOT, "dock_cove"), TranslationServer.translate("UI_ZONE_BOSS_READY") % [name,
			TranslationServer.translate("UI_TECH_float")], "daha iyi misinayla takım hazır")
	Records.add(s.records, "pier_king", 112, 5, 0)
	assert_eq(ZonePanel.boss_text(db, s, SPOT, "dock_cove"), TranslationServer.translate("UI_ZONE_BOSS_DONE") % name,
			"yenildi")
