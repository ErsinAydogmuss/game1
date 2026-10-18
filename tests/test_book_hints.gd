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
