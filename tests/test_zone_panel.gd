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
