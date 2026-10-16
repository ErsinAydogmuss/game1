extends BaseTest
## Dükkân paneli: her sekmede en çok 6 kart (kaydırma yok, parmakla aranmaz) ve satılan her takım
## bir sekmede (şimdilik yalnızca şamandıra kamışları; öteki teknikler Dalga 3'te).


func test_every_tab_fits_one_page() -> void:
	for t: Array in ShopPanel.TABS:
		var items := ShopPanel.items_for(content(), str(t[0]))
		assert_true(items.size() <= ShopPanel.CARDS, "%s sekmesinde %d kart (en çok %d)" % [t[0], items.size(), ShopPanel.CARDS])


func test_every_gear_item_has_a_tab() -> void:
	var shown := {}
	for t: Array in ShopPanel.TABS:
		for g in ShopPanel.items_for(content(), str(t[0])):
			assert_true(not shown.has(str(g["id"])), "iki sekmede birden: " + str(g["id"]))
			shown[str(g["id"])] = true
	for g in content().gear:
		if str(g["category"]) == "rod" and str(g["technique"]) != "float":
			continue
		assert_true(shown.has(str(g["id"])), "dükkânda yok: " + str(g["id"]))


func test_stats_exist_on_items() -> void:
	for category: String in ShopPanel.STATS:
		for g in content().gear_in(category):
			for stat: Array in ShopPanel.STATS[category]:
				assert_true(g.has(str(stat[0])), "%s: değer yok: %s" % [g["id"], stat[0]])
