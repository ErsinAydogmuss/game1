extends BaseTest
## Defterin ipuçları (BookPanel.hints) oyundaki bütün tekniklere bakar: şamandırayla gelmeyen tür
## (aynalı sazan, yalnızca dip) de nerede yaşadığını, ne sıklıkla görüldüğünü ve hangi teknikle
## tutulduğunu söyler.


func test_bottom_only_fish_names_its_technique_and_zones() -> void:
	var db := content()
	var save := SaveData.create_new(0)
	var text := "\n".join(BookPanel.hints(db, save, db.main_spot, "mirror_carp"))
	assert_true(text.contains(UiKit.translate("UI_BOOK_HINT_TECH") % UiKit.translate("UI_TECH_bottom")),
			"dipte tutulur: %s" % text)
	assert_true(text.contains(UiKit.translate("ZONE_reeds")) and text.contains(UiKit.translate("ZONE_deep_water")),
			"sazlıkta ve derin ortada yaşar: %s" % text)
	assert_true(not text.contains(UiKit.translate("UI_BOOK_HINT_RARELY")), "nadiren değil (dipte ara sıra): %s" % text)


func test_float_fish_has_no_technique_line() -> void:
	var db := content()
	var save := SaveData.create_new(0)
	var tech := UiKit.translate("UI_BOOK_HINT_TECH").split("%")[0]
	var text := "\n".join(BookPanel.hints(db, save, db.main_spot, "carp"))
	assert_true(not text.contains(tech), "şamandırayla gelen türde teknik satırı yok: %s" % text)


## Kerevit tuzağa girer: ipucu tuzağın kurulduğu bölgeleri söyler, dip "da" olur; tuzak hep kerevit
## verdiği için sıklık yazılmaz, yaşadığı yerler tuzağınkilerle aynı olduğu için yinelenmez.
func test_trap_fish_names_the_trap_zones() -> void:
	var db := content()
	var save := SaveData.create_new(0)
	var lines := BookPanel.hints(db, save, db.main_spot, "crayfish")
	var text := "\n".join(lines)
	var zones := "%s, %s" % [UiKit.translate("ZONE_reeds"), UiKit.translate("ZONE_rocky_point")]
	assert_true(text.contains(UiKit.translate("UI_BOOK_HINT_TRAP") % zones), "tuzağa girer: %s" % text)
	assert_true(text.contains(UiKit.translate("UI_BOOK_HINT_TECH_ALSO") % UiKit.translate("UI_TECH_bottom")),
			"dipte de: %s" % text)
	for key: String in ["UI_BOOK_HINT_OFTEN", "UI_BOOK_HINT_SOMETIMES", "UI_BOOK_HINT_RARELY"]:
		assert_true(not text.contains(UiKit.translate(key)), "tuzak türünde sıklık yok: %s" % text)
	assert_true(not text.contains(UiKit.translate("UI_BOOK_HINT_ZONE").split("%")[0]),
			"yaşadığı yer tuzağınkiyle aynı, yinelenmez: %s" % text)


## Sevdiği yem türün tekniklerinin yuvalarından ve türü en sık getireni: alabalık için sinek, sudak için
## yapay yem (spinle, sudağı karidesli şamandıradan sık getirir), sazan için yem; kereviti çeken yok.
## Başka türleri de çeken yem türün payını düşürebilir: seçilen, o yuvadaki her yemden en az onun kadar
## getirir.
func test_favourite_brings_the_fish_most() -> void:
	var db := content()
	var spot := db.main_spot
	var categories := { "trout": "fly", "zander": "lure", "carp": "bait" }
	for id: String in categories:
		var favourite := BookPanel._favourite(db, spot, id, _techniques(db, id))
		assert_eq(str(db.gear_item(favourite).get("category", "")), str(categories[id]), "%s: %s" % [id, favourite])
	assert_eq(BookPanel._favourite(db, spot, "crayfish", _techniques(db, "crayfish")), "", "kereviti çeken yem yok")
	var trout := BookPanel._favourite(db, spot, "trout", _techniques(db, "trout"))
	for g in db.gear_in("fly"):
		assert_true(_best_ppm(db, spot, "trout", g) <= _best_ppm(db, spot, "trout", db.gear_item(trout)),
				"%s alabalığı %s'dan sık getirmez" % [g["id"], trout])
	var text := "\n".join(BookPanel.hints(db, SaveData.create_new(0), spot, "trout"))
	assert_true(text.contains(UiKit.translate("UI_BOOK_FLY_HINT") % UiKit.translate("GEAR_" + trout)), text)


static func _techniques(db: ContentDB, fish_id: String) -> PackedStringArray:
	var out := PackedStringArray()
	for t: String in ContentDB.TECHNIQUES:
		if db.affinity(fish_id, t) > 0.0:
			out.append(t)
	return out


## Yemle türün gölün bölgelerindeki en yüksek oranı (yemin tekniğiyle).
static func _best_ppm(db: ContentDB, spot: String, fish_id: String, item: Dictionary) -> int:
	var best := 0
	var technique := db.slot_technique(str(item["category"]))
	for z in db.zones_of(spot):
		best = maxi(best, int(CatchOdds.species_ppm(db, z, { "attract": item["attract"], "technique": technique }).get(fish_id, 0)))
	return best
