extends BaseTest
## Kerevit tuzağı (Dalga 3): gerçek saatle dolar ve üst sınırda durur, saatin geri alınması bir şey
## kaybettirmez ya da kazandırmaz, içerik kurulunca belli olur, toplanan kovaya ve deftere girer
## (şans garantisi ilerlemez), kova doluysa kerevit tuzakta bekler; kurulacak yerin kuralları.

const SPOT := "big_lake"
const T0 := 1_700_000_000


func _save(traps: int = 1) -> SaveData:
	var db := content()
	var save := SaveData.create_new(T0)
	save.seed = 4242
	save.xp = db.rank_xp[4]
	for i in traps:
		save.owned.append("trap_%d" % (i + 1))
	return save


static func _stand(zone: String) -> Vector2:
	return (content().zone(SPOT, zone)["stands"] as Array)[0]


## Sazlığın atış noktasının yanında kurulmuş bir tuzak.
func _placed(save: SaveData, now: int = T0) -> Dictionary:
	var db := content()
	var angler := _stand("reeds")
	var p := TrapSim.spot_near(db, save, SPOT, "reeds", angler, Vector2(0, -1))
	assert_true(Dice.is_point(p), "sazlıkta tuzak yeri bulunur")
	return TrapSim.place(db, save, SPOT, "reeds", p, now)


func test_trap_fills_with_real_time_and_stops_at_the_cap() -> void:
	var db := content()
	var rules := db.rules
	var save := _save()
	var trap := _placed(save)
	assert_eq((trap["items"] as Array).size(), rules.trap_max, "içerik kurulunca belli (%d kerevit)" % rules.trap_max)
	TrapSim.update(rules, trap, T0 + rules.trap_fill_s - 1)
	assert_eq(TrapSim.ready(rules, trap), 0, "ilk kerevit dolma süresinden önce girmez")
	TrapSim.update(rules, trap, T0 + rules.trap_fill_s)
	assert_eq(TrapSim.ready(rules, trap), 1, "her dolma süresinde bir kerevit")
	TrapSim.update(rules, trap, T0 + 3 * rules.trap_fill_s)
	assert_eq(TrapSim.ready(rules, trap), 3, "oyun kapalıyken de dolar")
	TrapSim.update(rules, trap, T0 + 400 * rules.trap_fill_s)
	assert_eq(TrapSim.ready(rules, trap), rules.trap_max, "en çok %d (üst sınırda durur)" % rules.trap_max)
	assert_eq(int(trap["progress_s"]), rules.trap_max * rules.trap_fill_s, "süre de üst sınırda durur")
	assert_eq(TrapSim.seconds_to_next(rules, trap), 0, "dolu tuzakta sıradaki yok")


func test_turning_the_clock_back_loses_and_gains_nothing() -> void:
	var db := content()
	var rules := db.rules
	var save := _save()
	var trap := _placed(save)
	TrapSim.update(rules, trap, T0 + 1500)
	assert_eq(TrapSim.ready(rules, trap), 1, "1 kerevit girdi")
	var back := T0 - 86_400
	TrapSim.update(rules, trap, back)
	assert_eq(TrapSim.ready(rules, trap), 1, "saat geri alınınca kerevit kaybolmaz")
	assert_eq(int(trap["progress_s"]), 1500, "ilerleme de kaybolmaz")
	TrapSim.update(rules, trap, back + rules.trap_fill_s)
	assert_eq(int(trap["progress_s"]), 1500 + rules.trap_fill_s, "yeni dayanaktan sürer (kazanç yok)")
	assert_eq(TrapSim.ready(rules, trap), 2, "2 kerevit")


func test_contents_are_known_when_placed() -> void:
	var db := content()
	var rules := db.rules
	var a := _save()
	var b := _save()
	var trap_a := _placed(a)
	var trap_b := _placed(b)
	assert_eq(trap_a["items"], trap_b["items"], "aynı kayıtta aynı tuzak aynı içerikle kurulur")
	var planned: Array = (trap_a["items"] as Array).duplicate(true)
	for item: Dictionary in planned:
		assert_eq(str(item["fish"]), "crayfish", "sazlığın tuzağına kerevit girer")
	TrapSim.update(rules, trap_a, T0 + 2 * rules.trap_fill_s)
	var got: Array = TrapSim.collect(db, a, SPOT, 0, T0 + 2 * rules.trap_fill_s)["items"]
	assert_eq(got, planned.slice(0, 2), "toplananlar kurulurken belli olan ilk ikisi")


func test_collecting_fills_the_bucket_and_book_without_pity() -> void:
	var db := content()
	var rules := db.rules
	var save := _save()
	_placed(save)
	save.pity = { "rare": 7, "epic": 30 }
	var xp := save.xp
	var serial := save.trap_serial
	var now := T0 + 3 * rules.trap_fill_s + 600
	var result := TrapSim.collect(db, save, SPOT, 0, now)
	var got: Array = result["items"]
	assert_eq(got.size(), 3, "3 kerevit toplanır")
	assert_eq(save.bucket.size(), 3, "kovaya girer")
	assert_true(save.records.has("crayfish") and bool(result["new_species"]), "deftere yeni tür olarak girer")
	assert_true(save.xp > xp, "rütbe puanı verir")
	assert_eq(save.pity, { "rare": 7, "epic": 30 }, "şans garantisi sayaçları ilerlemez")
	var trap := save.traps[0]
	assert_eq((trap["items"] as Array).size(), rules.trap_max, "tuzak yeniden kurulur (içerik tamamlanır)")
	assert_eq(save.trap_serial, serial + 1, "yeni içerik yeni bir zarla")
	assert_eq(int(trap["progress_s"]), 600, "artan süre sonraki kereviti bekler")
	assert_eq(TrapSim.ready(rules, trap), 0, "toplanınca tuzak boş")
	assert_eq(int(save.stats.get("trapped", 0)), 3, "sayaç")


func test_full_bucket_keeps_crayfish_in_the_trap() -> void:
	var db := content()
	var rules := db.rules
	var save := _save()
	_placed(save)
	while not Bucket.is_full(db, save):
		save.bucket.append({ "fish": "rudd", "size_cm": 20, "stars": 2 })
	var now := T0 + 2 * rules.trap_fill_s
	var result := TrapSim.collect(db, save, SPOT, 0, now)
	assert_true((result["items"] as Array).is_empty(), "kova dolu: toplanmaz")
	assert_eq(int(result["left"]), 2, "kerevitler tuzakta bekler (kayıp yok)")
	save.bucket.resize(save.bucket.size() - 1)
	result = TrapSim.collect(db, save, SPOT, 0, now)
	assert_eq((result["items"] as Array).size(), 1, "kovada yer açılınca sığan kadarı")
	assert_eq(int(result["left"]), 1, "kalanı yine tuzakta")


func test_where_a_trap_can_be_placed() -> void:
	var db := content()
	var save := _save(2)
	var reeds := _stand("reeds")
	assert_eq(TrapSim.place_block(db, _save(0), SPOT, "reeds", reeds + Vector2(0, -2), reeds), "UI_TRAP_NONE",
			"tuzağı olmayan kuramaz")
	var dock := _stand("dock_cove")
	assert_eq(TrapSim.place_block(db, save, SPOT, "dock_cove", dock + Vector2(0, -2.5), dock), "UI_TRAP_ZONE",
			"iskele koyuna tuzak kurulmaz")
	var first := TrapSim.spot_near(db, save, SPOT, "reeds", reeds, Vector2(0, -1))
	assert_true(Dice.is_point(first), "sazlıkta yer var")
	var lake := db.lake(SPOT)
	assert_true(lake.depth_at(first) <= db.rules.trap_depth, "sığ su (%.2f m)" % lake.depth_at(first))
	var d := first.distance_to(reeds)
	assert_true(d >= db.rules.trap_near.x and d <= db.rules.trap_near.y, "balıkçının yakınında (%.1f m)" % d)
	TrapSim.place(db, save, SPOT, "reeds", first, T0)
	assert_eq(TrapSim.place_block(db, save, SPOT, "reeds", first + Vector2(0.5, 0), reeds), "UI_TRAP_CLOSE",
			"öteki tuzağın dibine kurulmaz")
	var second := TrapSim.spot_near(db, save, SPOT, "reeds", reeds, Vector2(0, -1))
	assert_true(Dice.is_point(second) and second.distance_to(first) >= db.rules.trap_spacing, "ikincisine yer var")
	TrapSim.place(db, save, SPOT, "reeds", second, T0)
	assert_eq(TrapSim.place_block(db, save, SPOT, "reeds", second + Vector2(0, -1), reeds), "UI_TRAP_ALL_SET",
			"bütün tuzaklar kurulu")
	var deep := Dice.NO_POINT
	for k in 64:
		var p := reeds + Vector2.from_angle(TAU * k / 64.0) * 3.0
		if lake.is_water(p) and lake.depth_at(p) > db.rules.trap_depth:
			deep = p
	if Dice.is_point(deep):
		assert_eq(TrapSim.place_block(db, _save(1), SPOT, "reeds", deep, reeds), "UI_TRAP_DEEP", "derin suya kurulmaz")


func test_rocky_point_has_traps_too() -> void:
	var db := content()
	assert_true(TrapSim.zone_allows(db, SPOT, "reeds") and TrapSim.zone_allows(db, SPOT, "rocky_point"),
			"sazlıkta ve kayalık burunda tuzak")
	for zone: String in ["dock_cove", "lily_cove", "stream_mouth", "deep_water", ""]:
		assert_true(not TrapSim.zone_allows(db, SPOT, zone), "%s: tuzak yok" % zone)
	var save := _save()
	var rocky := _stand("rocky_point")
	var p := TrapSim.spot_near(db, save, SPOT, "rocky_point", rocky, Vector2(0, -1))
	assert_true(Dice.is_point(p), "kayalık burunda tuzak yeri bulunur")


func test_shop_shows_the_next_trap() -> void:
	var db := content()
	var save := _save(0)
	assert_eq(str(TrapSim.next_trap(db, save)["id"]), "trap_1", "önce ilk tuzak")
	save.owned.append("trap_1")
	assert_eq(str(TrapSim.next_trap(db, save)["id"]), "trap_2", "sonra ikincisi")
	save.owned.append("trap_2")
	save.owned.append("trap_3")
	assert_eq(str(TrapSim.next_trap(db, save)["id"]), "trap_3", "hepsi alınınca sonuncusu (sende)")
	assert_eq(TrapSim.owned(db, save), 3, "en çok 3 tuzak")


func test_crayfish_comes_with_bottom_and_traps_only() -> void:
	var db := content()
	for zone: String in ["reeds", "rocky_point"]:
		var place := Zones.place(db, SPOT, zone)
		var bottom := CatchOdds.species_ppm(db, place, { "technique": "bottom" })
		var share := float(bottom.get("crayfish", 0)) / Dice.PPM
		assert_true(share > 0.03 and share < 0.15, "%s: dipte arada kerevit (%%%.1f)" % [zone, share * 100.0])
		var float_odds := CatchOdds.species_ppm(db, place, { "technique": "float" })
		assert_true(not float_odds.has("crayfish"), "%s: şamandırayla kerevit gelmez" % zone)
