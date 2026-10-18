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


## Sevdiği yem türün tekniklerinin yuvalarından: alabalık için sinek (nimf), tatlısu kefali için yapay
## yem (su üstü yemi, karidesten çok çeker), sazan için yem.
func test_favourite_comes_from_the_fish_techniques() -> void:
	var db := content()
	var save := SaveData.create_new(0)
	var cases := {
		"trout": UiKit.translate("UI_BOOK_FLY_HINT") % UiKit.translate("GEAR_fly_nymph"),
		"chub": UiKit.translate("UI_BOOK_LURE_HINT") % UiKit.translate("GEAR_lure_popper"),
		"carp": UiKit.translate("UI_BOOK_BAIT_HINT") % UiKit.translate("GEAR_bait_corn"),
	}
	for id: String in cases:
		var text := "\n".join(BookPanel.hints(db, save, db.main_spot, id))
		assert_true(text.contains(str(cases[id])), "%s: %s" % [id, text])
