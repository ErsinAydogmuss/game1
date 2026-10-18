extends BaseTest
## Para, kova ve rütbe (Economy, Bucket, Rank): balığın değeri, satış, satın alma, kuşanma, yem.


func _save() -> SaveData:
	return SaveData.create_new(100)


func test_fish_value_grows_with_size() -> void:
	var db := content()
	# Kızılkanat değeri 5, boyu 15–30 cm: en küçük 0,6, en büyük 1,6 kat.
	assert_eq(Economy.fish_value(db, "rudd", 15), 3, "en küçük kızılkanat")
	assert_eq(Economy.fish_value(db, "rudd", 30), 8, "en büyük kızılkanat")
	assert_true(Economy.fish_value(db, "rudd", 22) > 3 and Economy.fish_value(db, "rudd", 22) < 8, "orta boy arada")
	assert_true(Economy.fish_value(db, "wels", 100) > Economy.fish_value(db, "pike", 120), "Destansı yayın, Nadir turnadan değerli")
	assert_eq(Economy.fish_value(db, "yok", 20), 0, "bilinmeyen balık değersiz")


func test_selling_the_bucket() -> void:
	var db := content()
	var s := _save()
	assert_true(Bucket.add(db, s, "rudd", 30, 5), "kovaya girer")
	assert_true(Bucket.add(db, s, "carp", 80, 5), "kovaya girer")
	var expected := Economy.fish_value(db, "rudd", 30) + Economy.fish_value(db, "carp", 80)
	assert_eq(Economy.bucket_value(db, s), expected, "kovanın değeri")
	assert_eq(Economy.sell_all(db, s), expected, "satış kazancı")
	assert_eq(s.coins, expected, "para eklenir")
	assert_true(s.bucket.is_empty(), "kova boşalır")
	assert_eq(int(s.stats["sold"]), 2, "satılan sayısı")
	assert_eq(int(s.stats["earned"]), expected, "kazanç sayacı")


func test_bucket_capacity_and_overflow() -> void:
	var db := content()
	var s := _save()
	assert_eq(Bucket.capacity(db, s), 6, "başlangıç kovası 6 balık")
	for i in 6:
		assert_true(Bucket.add(db, s, "rudd", 20, 2), "%d. balık girer" % (i + 1))
	assert_true(Bucket.is_full(db, s), "kova dolu")
	assert_true(not Bucket.add(db, s, "rudd", 20, 2), "dolu kovaya girmez (çağıran bırakır)")
	s.owned.append("bucket_big")
	assert_eq(Bucket.capacity(db, s), 10, "büyük kovayla 10")
	assert_eq(Bucket.counts(s), { "rudd": 6 }, "tür başına sayım")


## Kapasite en büyük kovadan gelir: daha büyüğü alınmışsa küçüğü "sende" sayılır, satılmaz.
func test_smaller_bucket_adds_nothing() -> void:
	var db := content()
	var s := _save()
	s.coins = 100000
	s.xp = 100000
	s.owned.append("keepnet")
	assert_eq(Bucket.capacity(db, s), 16, "file 16 balık")
	assert_eq(Economy.buy_block(db, s, "bucket_big"), "owned", "daha küçük kova sende sayılır")
	assert_true(not Economy.buy(db, s, "bucket_big"), "alınmaz")
	assert_eq(s.coins, 100000, "para düşmez")
	assert_eq(Economy.buy_block(db, s, "keepnet_big"), "", "daha büyüğü alınabilir")


## Değeri 0 olan balık (Masalsı) satılmaz, kovada kalır; satılacak bir şey yoksa kayıt değişmez.
func test_unsellable_fish_stay_in_the_bucket() -> void:
	var db := ContentDB.load_default()
	db.fish_by_id("wels")["value"] = 0
	var s := _save()
	Bucket.add(db, s, "wels", 200, 5)
	Bucket.add(db, s, "rudd", 30, 5)
	var rudd := Economy.fish_value(db, "rudd", 30)
	assert_eq(Economy.sell_all(db, s), rudd, "yalnızca kızılkanat satılır")
	assert_eq(s.bucket.size(), 1, "değersiz balık kovada kalır")
	assert_eq(str(s.bucket[0]["fish"]), "wels", "kalan yayın")
	assert_eq(int(s.stats["sold"]), 1, "satılan sayısı")
	assert_eq(Economy.sell_all(db, s), 0, "satılacak yoksa 0")
	assert_eq(s.bucket.size(), 1, "kova değişmez")
	assert_eq(int(s.stats["sold"]), 1, "sayaç değişmez")


## Koruma altındaki tür (mersin) kovaya girmez ve satılmaz: tutulur, göle bırakılır (denge botu
## da bırakır: göl sevgisi ve bırakılan sayısı).
func test_protected_fish_is_always_released() -> void:
	var db := content()
	var s := _save()
	assert_true(Bucket.release_only(db, "sturgeon"), "mersin koruma altında")
	assert_true(not Bucket.release_only(db, "wels"), "yayın değil")
	assert_true(not Bucket.add(db, s, "sturgeon", 160, 4), "mersin kovaya girmez")
	assert_eq(s.bucket.size(), 0, "kova boş kalır")
	assert_eq(Economy.fish_value(db, "sturgeon", 160), 0, "mersin satılmaz")
	assert_true(Bucket.add(db, s, "bream", 40, 2), "çapak kovaya girer")
	var sim := SessionSim.new(db, "big_lake", 1)
	var def := db.fish_by_id("sturgeon")
	sim.call("_on_catch", def, 500000)
	assert_eq(sim.save.bucket.size(), 0, "bot da mersini kovaya koymaz")
	assert_eq(int((sim.save.records["sturgeon"] as Dictionary)["released"]), 1, "bırakılan sayısı")
	assert_eq(sim.save.love, int(db.rarity_def(int(def["rarity"]))["love"]), "göl sevgisi")


func test_buying_needs_rank_and_coins() -> void:
	var db := content()
	var s := _save()
	assert_eq(Economy.buy_block(db, s, "reel_basic"), "owned", "başlangıç takımı hep sahipli")
	assert_eq(Economy.buy_block(db, s, "reel_smooth"), "coins", "para yoksa alınmaz")
	s.coins = 100000
	assert_eq(Economy.buy_block(db, s, "rod_float_carbon"), "rank", "rütbe yetmezse alınmaz")
	assert_eq(Economy.buy_block(db, s, "yok"), "unknown", "bilinmeyen eşya")
	assert_true(Economy.buy(db, s, "reel_smooth"), "rütbe ve para yetince alınır")
	assert_eq(s.coins, 100000 - 150, "para düşer")
	assert_true(Economy.owns(db, s, "reel_smooth"), "sahiplenir")
	assert_eq(Economy.equipped(db, s, "reel"), "reel_smooth", "alınan takım kuşanılır")
	assert_eq(Economy.buy_block(db, s, "reel_smooth"), "owned", "ikinci kez alınmaz")
	assert_true(Economy.equip(db, s, "reel_basic"), "eskisine dönülebilir")
	assert_eq(Economy.gear_for(db, s).reel_speed, 1.6, "kuşanılan takım oturuma geçer")
	s.xp = db.rank_xp[4]
	assert_true(Economy.buy(db, s, "rod_float_carbon"), "5. rütbede karbon kamış")
	assert_eq(Economy.gear_for(db, s).range_m, 13.0, "menzil 13 m")
	assert_eq(int(s.stats["spent"]), 150 + 2000, "harcanan sayacı")


## Fazla iri balıktan sonra Dede'nin öğüdü: hangi kamış ve misina gerek; Nine'den mi alınacak, sende
## mi (tak), hangi rütbede.
func test_gear_for_stars() -> void:
	var db := content()
	var s := _save()
	var none := Economy.gear_for_stars(db, s, 3)
	assert_true((none["buy"] as Array).is_empty() and (none["equip"] as Array).is_empty(), "3★'ı bambu olta taşır")
	var four := Economy.gear_for_stars(db, s, 4)
	assert_eq(str(four["buy"]), str(["rod_float_glass", "line_mono"]), "4★: cam elyafı kamış ve naylon misina")
	assert_eq(int(four["rank"]), 2, "rütbe 1'de cam elyafı kamış kilitli (rütbe 2)")
	s.xp = db.rank_xp[1]
	assert_eq(int(Economy.gear_for_stars(db, s, 4)["rank"]), 0, "rütbe 2'de ikisi de Nine'de")
	s.coins = 1000
	assert_true(Economy.buy(db, s, "line_mono"), "naylon misina alınır")
	assert_true(Economy.equip(db, s, "line_mono_thin"), "ince misinaya dönülür")
	var both := Economy.gear_for_stars(db, s, 4)
	assert_eq(str(both["buy"]), str(["rod_float_glass"]), "kamış Nine'den alınır")
	assert_eq(str(both["equip"]), str(["line_mono"]), "naylon misina sende: takılır (yeniden alınmaz)")
	assert_true(Economy.buy(db, s, "rod_float_glass") and Economy.equip(db, s, "line_mono"), "alınır ve kuşanılır")
	var fitted := Economy.gear_for_stars(db, s, 4)
	assert_true((fitted["buy"] as Array).is_empty() and (fitted["equip"] as Array).is_empty(), "kuşanılan takım 4★ taşır")
	assert_true(Economy.equip(db, s, "rod_bamboo") and Economy.equip(db, s, "line_mono_thin"), "eskilere dönülür")
	var equip := Economy.gear_for_stars(db, s, 4)
	assert_eq(str(equip["equip"]), str(["rod_float_glass", "line_mono"]), "sendekiler önerilir")
	assert_true((equip["buy"] as Array).is_empty() and int(equip["rank"]) == 0, "alınacak yok")
	assert_true(Economy.equip(db, s, "rod_float_glass") and Economy.equip(db, s, "line_mono"), "kuşanılır")
	s.xp = db.rank_xp[4]
	var five := Economy.gear_for_stars(db, s, 5)
	assert_eq(str(five["buy"]), str(["rod_float_carbon", "line_braid"]), "5★: karbon kamış ve örgü misina")
	assert_eq(int(five["rank"]), 6, "rütbe 5'te örgü misina kilitli (rütbe 6; usta florokarbon 7'de açılır)")


func test_baits_are_packs_used_on_hook() -> void:
	var db := content()
	var s := _save()
	s.coins = 1000
	s.xp = db.rank_xp[1]
	assert_eq(Economy.equipped(db, s, "bait"), "bait_worm", "başta solucan")
	assert_true(Economy.buy(db, s, "bait_corn"), "mısır alınır")
	assert_eq(int(s.baits["bait_corn"]), 20, "bir paket 20 tane")
	assert_eq(Economy.equipped(db, s, "bait"), "bait_corn", "alınan yem takılır")
	assert_eq(Economy.gear_for(db, s).attraction("carp"), 3.0, "mısır sazanı çeker")
	assert_true(Economy.buy(db, s, "bait_corn"), "yem tekrar alınabilir")
	assert_eq(int(s.baits["bait_corn"]), 40, "paketler toplanır")
	for i in 40:
		Economy.use_bait(db, s)
	assert_eq(int(s.baits["bait_corn"]), 0, "balık takıldıkça harcanır")
	assert_eq(Economy.equipped(db, s, "bait"), "bait_worm", "biten yem solucana döner")
	Economy.use_bait(db, s)
	assert_eq(int(s.baits["bait_corn"]), 0, "solucan harcanmaz, sayı eksiye inmez")


func test_net_is_passive_once_owned() -> void:
	var db := content()
	var s := _save()
	assert_eq(Economy.gear_for(db, s).catch_m, db.rules.catch_m, "kepçesiz")
	s.owned.append("net")
	assert_eq(Economy.gear_for(db, s).catch_m, 0.85, "kepçe alınınca hep işler")


func test_rank_points() -> void:
	var db := content()
	var s := _save()
	assert_eq(Rank.catch_xp(db, db.rarity_index("common"), 1), 5, "1 yıldızlı sıradan: 5 puan")
	assert_eq(Rank.catch_xp(db, db.rarity_index("common"), 5), 10, "5 yıldız: 2 katı")
	assert_eq(Rank.catch_xp(db, db.rarity_index("epic"), 1), 60, "destansı: 60")
	var up := Rank.add_xp(db, s, db.rank_xp[1] + 6)
	assert_eq(int(up["old_rank"]), 1, "1. rütbeden")
	assert_eq(int(up["new_rank"]), 2, "2. rütbeye")
	var part := 6.0 / float(db.rank_xp[2] - db.rank_xp[1])
	assert_between(Rank.progress(db, s), part - 0.001, part + 0.001, "2. rütbede biraz ilerlemiş (eşiğin 6 puan üstü)")
	s.xp = 999999
	assert_eq(Rank.rank(db, s), db.max_rank(), "en yüksek rütbe")
	assert_eq(Rank.progress(db, s), 1.0, "en yüksek rütbede dolu")


## Bölgeli gölde yeni açılan bölge öncekilerden az kazandırmaz: her bölgede solucanla balık başına
## ortalama değer, rütbesi daha düşük bölgelerin hepsinden en az onlar kadardır (docs/gdd.md §10.1).
func test_newer_zones_pay_at_least_as_much() -> void:
	var db := content()
	var zones := db.zones_of(db.main_spot)
	for z in zones:
		var value := _mean_value(db, z)
		for older in zones:
			if int(older["rank"]) < int(z["rank"]):
				var before := _mean_value(db, older)
				assert_true(value >= before, "%s (rütbe %d, %.1f para) %s'dan (rütbe %d, %.1f) az kazandırmaz" % [
						z["id"], int(z["rank"]), value, older["id"], int(older["rank"]), before])


## Dede'nin bölgede önerdiği teknik (spots.json suggest) orada şamandıradan az kazandırmaz: dakikada
## ortalama kazanç (SessionSim.rate; süreler sim.json'dan, takımın taşıyamadığı iri balık kaçar), iki
## teknikte aynı kademe takımla (spinde kaşık, sinekte kuru sinek, yem solucan):
## - öneri ilk söylendiğinde: tekniğin ilk kamışı, şamandırada bambu; naylon misina (line_mono: rütbe 1,
##   120 para; test_session_sim: tekniklerden önce alınır);
## - iki teknikte de 4 yıldız taşıyan en ucuz kamış, naylon misina; 5 yıldız, örgü misina (line_braid).
## Sinek dere ağzında, spin nilüferli koyda ve kayalıkta, dip sazlıkta ve derin ortada (docs/gdd.md §10.3).
func test_suggested_technique_pays_at_least_float() -> void:
	var db := content()
	var timing := SessionSim.load_timing()
	var checked := 0
	for tier: Array in [[0, "line_mono"], [4, "line_mono"], [5, "line_braid"]]:
		for z in db.zones_of(db.main_spot):
			var suggest := str(z["suggest"])
			if suggest.is_empty():
				continue
			checked += 1
			var gear := _loadout(db, suggest, tier[0], tier[1])
			var float_gear := _loadout(db, "float", tier[0], tier[1])
			var own := SessionSim.rate(db, timing, z, suggest, gear)
			var float_rate := SessionSim.rate(db, timing, z, "float", float_gear)
			assert_true(own >= float_rate, "%s (%d yıldız): %s dakikada %.1f para, şamandıra %.1f" % [z["id"],
					float_gear.carry, suggest, own, float_rate])
	assert_true(checked >= 12, "öneriler denetlendi (%d)" % checked)


## Tekniğin taşıması en az min_carry olan en ucuz kamışı ve verilen misina; geri kalanı başlangıç takımı.
static func _loadout(db: ContentDB, technique: String, min_carry: int, line: String) -> GearStats:
	var items := db.gear_start.duplicate()
	var best: Dictionary = {}
	for rod in db.rods_of(technique):
		if int(rod["carry"]) >= min_carry and (best.is_empty() or int(rod["price"]) < int(best["price"])):
			best = rod
	items["rod"] = str(best["id"])
	items["line"] = line
	var none: Array[String] = []
	return GearStats.from_items(db, items, none)


## Bölgede solucanla balık başına ortalama değer (boy zarının eşit aralıklı örnekleriyle).
static func _mean_value(db: ContentDB, place: Dictionary) -> float:
	const SAMPLES := 200
	var odds := CatchOdds.species_ppm(db, place)
	var value := 0.0
	for id: String in odds:
		var def := db.fish_by_id(id)
		var total := 0
		for i in SAMPLES:
			var u := int((float(i) + 0.5) / SAMPLES * Dice.PPM)
			total += Economy.fish_value(db, id, FishTable.size_cm(def, FishTable.percentile_for(u)))
		value += float(odds[id]) / Dice.PPM * float(total) / SAMPLES
	return value


## Takım çantası (Dalga 3): makara ve misina her teknikte ortak; iğne ve şamandıra şamandıranın,
## yem bakılan tekniğin (yem kullanmıyorsa şamandıranın) setine girer; kamışı olmayan teknik hazır
## değil, oturum şamandırayla sürer.
func test_technique_sets() -> void:
	var db := content()
	var save := _save()
	save.coins = 5000
	save.xp = db.rank_xp[4]
	assert_true(Economy.buy(db, save, "reel_smooth"), "makara alınır")
	assert_eq(save.loadouts["shared"], { "reel": "reel_smooth" }, "makara ortak sette")
	assert_eq(Economy.equipped(db, save, "reel", "spin"), "reel_smooth", "spinde de aynı makara")
	assert_eq(Economy.equipped(db, save, "reel", "bottom"), "reel_smooth", "dipte de aynı makara")
	assert_true(Economy.buy(db, save, "hook_medium", "spin"), "iğne alınır (spine bakarken de)")
	assert_eq(Economy.equipped(db, save, "hook"), "hook_medium", "iğne şamandıranın setinde")
	assert_eq(Economy.equipped(db, save, "hook", "spin"), "", "spinde iğne yuvası yok")
	assert_true(Economy.buy(db, save, "bait_corn", "bottom"), "mısır dipte bakarken alınır")
	assert_eq(Economy.equipped(db, save, "bait", "bottom"), "bait_corn", "mısır dipte takılı")
	assert_eq(Economy.equipped(db, save, "bait"), "bait_worm", "şamandırada solucan kalır")
	assert_true(Economy.equip(db, save, "bait_corn", "spin"), "spinde yem yuvası yok: şamandıraya takılır")
	assert_eq(Economy.equipped(db, save, "bait"), "bait_corn", "şamandırada mısır")
	assert_true(not Economy.technique_ready(db, save, "spin"), "spin kamışı yok: spin hazır değil")
	assert_true(Economy.technique_ready(db, save, "float"), "şamandıra hep hazır")
	assert_eq(Economy.equipped(db, save, "rod", "spin"), "", "spinde kamış yok")
	assert_eq(Economy.gear_for(db, save, "spin").technique, "float", "hazır olmayan teknikte şamandıranın takımı")
	assert_eq(Economy.gear_for(db, save, "spin").reel_speed, float(db.gear_item("reel_smooth")["reel_speed"]),
			"ortak makara işler")
	assert_true(Economy.technique_allowed(db, "big_lake", "stream_mouth", "fly"), "dere ağzında sinek")
	assert_true(not Economy.technique_allowed(db, "big_lake", "dock_cove", "fly"), "iskelede sinek yok")
	assert_true(Economy.technique_allowed(db, "big_lake", "dock_cove", "spin"), "iskelede spin")
	assert_true(not Economy.technique_allowed(db, "big_lake", "", "fly"), "bölgesiz suda (derin ortanın kıyısı) sinek yok")
	assert_true(Economy.technique_allowed(db, "big_lake", "", "float"), "bölgesiz suda şamandıra olur")
