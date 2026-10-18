extends BaseTest
## Denge botu (SessionSim) korkulukları: ekonomi ve ilerleme temposu (docs/gdd.md §10.4).
## Sayılar tools/economy_report.gd ölçümüne pay bırakarak seçildi; fiyat, rütbe puanı, balık
## değeri, oran ya da kural değişince rapor yeniden çalıştırılır, tablo ve bu sınırlar gözden
## geçirilir. Dalga 2: bölgeler rütbeyle açılır, sandal. Dalga 3: teknikler (spin rütbe 2'de; ilk
## kamışı öncelikli alınır, Dede haber verir); sonraki teknikler kendi satırlarını ekler.

const SEEDS := [1000, 1077, 1154]
## Korkulukların ölçüldüğü oyun süresi (dk).
const MINUTES := 310.0
## [olay, en erken dk, en geç dk]: her seed'de olay bu aralıkta ilk kez olmalı.
const PACING := [
	["sell", 0.0, 5.0],            # ilk satış (kova dolar, Nine'ye gidilir)
	["buy", 0.0, 10.0],            # ilk alışveriş
	["rank_2", 0.0, 5.0],
	["rank_3", 5.0, 15.0],         # nilüferli koy açılır (hedef 8–12)
	["rank_5", 15.0, 35.0],        # kayalık burun (20–30)
	["rank_7", 38.0, 65.0],        # dere ağzı (45–60)
	["rank_9", 60.0, 120.0],       # sandal Nine'de (hedef 80–110; dere ağzında balık çabuk geldiğinden ~70–80)
	["zone:lily_cove", 5.0, 15.0], # bölge açılınca bot hemen gider
	["zone:rocky_point", 15.0, 35.0],
	["species_5", 0.0, 30.0],
	["buy:rod_float_glass", 10.0, 45.0],
	["buy:bucket_big", 15.0, 60.0],
	["buy:net", 40.0, 100.0],
	["buy:boat", 90.0, 180.0],     # rütbe 9 + biriktirme (90–180)
	["buy:rod_spin_light", 4.0, 10.0], # spin rütbe 2'de: ilk kamışı (150) öncelikli
	["tech:spin", 4.0, 12.0],      # spinle ilk atış
	# Mersin: sandalla derin ortada, Efsanevi; ilk tutuluşu şansa çok bağlı (v0.3.1, 20 seed: 125–276
	# dk; eski kodda da bir seed 288). Zarların sırası değişince bir seed kolayca kayar: pay geniş.
	["species_12", 100.0, 300.0],
]


func test_same_seed_same_session() -> void:
	var db := content()
	var a := SessionSim.new(db, db.main_spot, 42)
	var b := SessionSim.new(db, db.main_spot, 42)
	a.run(30.0)
	b.run(30.0)
	assert_eq(a.casts, b.casts, "atış sayısı")
	assert_eq(a.catches, b.catches, "av sayısı")
	assert_eq(a.earned, b.earned, "kazanç")
	assert_eq(a.save.coins, b.save.coins, "para")
	assert_eq(a.save.owned, b.save.owned, "alınan takım")
	assert_eq(a.milestones, b.milestones, "olayların dakikaları")
	var c := SessionSim.new(db, db.main_spot, 43)
	c.run(30.0)
	assert_true(c.earned != a.earned or c.casts != a.casts, "başka seed başka oturum")


func test_pacing_guard_rails() -> void:
	var db := content()
	for seed_value: int in SEEDS:
		var sim := SessionSim.new(db, db.main_spot, seed_value)
		sim.run(MINUTES)
		for row: Array in PACING:
			var key: String = row[0]
			assert_true(sim.milestones.has(key), "seed %d: %s %d dk içinde hiç olmadı" % [seed_value, key, int(MINUTES)])
			if sim.milestones.has(key):
				assert_between(float(sim.milestones[key]), row[1], row[2], "seed %d: %s (dk)" % [seed_value, key])
		var hours := sim.elapsed / 3600.0
		assert_between(sim.earned / hours, 2500.0, 6500.0, "seed %d: saatte para" % seed_value)
		assert_between(sim.catches / hours, 120.0, 280.0, "seed %d: saatte av" % seed_value)


## Bölgeli göl: bot yalnızca açık bölgede avlanır (rütbe, sandal); kıyı bölgelerini dolaşır,
## sandalı alınca zamanının bir kısmını derin ortada geçirir.
func test_bot_fishes_only_in_open_zones() -> void:
	var db := content()
	var sim := SessionSim.new(db, db.main_spot, SEEDS[0])
	while sim.minutes() < 180.0:
		sim.cast_once()
		if not Zones.unlocked(db, sim.save, db.zone(sim.spot_id, sim.zone_id)):
			assert_true(false, "%.1f dk: kapalı bölgede (%s)" % [sim.minutes(), sim.zone_id])
			return
	assert_true(sim.zone_time.size() >= 5, "bölgeleri dolaştı (%s)" % [sim.zone_time.keys()])
	assert_true(float(sim.zone_time.get("deep_water", 0.0)) > 0.0, "sandalla derin ortada avlandı")


## Sandal öncelikli: rütbesi yetince parası yetene kadar başka takım alınmaz (biriktirir), yetince
## önce sandal.
func test_shop_saves_for_the_boat() -> void:
	var db := content()
	var sim := SessionSim.new(db, db.main_spot, 7)
	sim.save.xp = db.rank_xp[8]
	var price := int(db.gear_item(Zones.BOAT)["price"])
	sim.save.coins = price - 1
	assert_eq(sim.shop(), [] as Array[String], "sandala biriktirir")
	assert_eq(sim.save.coins, price - 1, "para harcanmaz")
	sim.save.coins = price + 100
	var bought := sim.shop()
	assert_true(not bought.is_empty() and bought[0] == Zones.BOAT, "önce sandal (%s)" % [bought])
	assert_true(Economy.owns(db, sim.save, Zones.BOAT), "sandal alındı")


## Alışveriş: rütbesi yeten en ucuz takım önce; para yetmezse biriktirir; kilitli olanı almaz.
func test_shop_buys_cheapest_unlocked_first() -> void:
	var db := content()
	var sim := SessionSim.new(db, db.main_spot, 7)
	sim.save.coins = 280
	# Rütbe 1: misina (120) ve makara (150) alınır; iğne (150) için 10 para eksik kalır.
	assert_eq(sim.shop(), ["line_mono", "reel_smooth"] as Array[String], "ucuzdan pahalıya")
	assert_eq(sim.save.coins, 10, "kalan para")
	assert_true(Economy.owns(db, sim.save, "line_mono") and Economy.owns(db, sim.save, "reel_smooth"), "sahip")
	assert_eq(Economy.equipped(db, sim.save, "line"), "line_mono", "alınan kuşanılır")
	# Cam kamış rütbe 2 ister: para olsa da rütbe 1'de alınmaz.
	sim.save.coins = 5000
	var bought := sim.shop()
	assert_true(not ("rod_float_glass" in bought), "rütbesi yetmeyen alınmaz")
	assert_true("hook_medium" in bought, "rütbe 1 takımı alınır")
	assert_true(sim.next_upgrade("rod").get("id", "") == "rod_float_glass", "sıradaki kamış cam")


## Yeni tekniğin ilk kamışı öncelikli: rütbesi yetince parası yetene kadar biriktirir, yetince önce
## o; yapay yemler ancak spin kamışı alınınca alışverişe girer. Kamış alınınca bot spini dener.
func test_shop_buys_the_new_technique_first() -> void:
	var db := content()
	var sim := SessionSim.new(db, db.main_spot, 7)
	sim.save.xp = db.rank_xp[1]
	var price := int(db.gear_item("rod_spin_light")["price"])
	sim.save.coins = price - 1
	assert_eq(sim.shop(), [] as Array[String], "spin kamışına biriktirir")
	assert_true(not ("lure" in sim.call("_buy_categories")), "kamış yokken yapay yem alınmaz")
	sim.save.coins = price + 120
	var bought := sim.shop()
	assert_true(not bought.is_empty() and bought[0] == "rod_spin_light", "önce spin kamışı (%s)" % [bought])
	assert_true(Economy.technique_ready(db, sim.save, "spin"), "spin hazır")
	assert_true("lure" in sim.call("_buy_categories"), "kamış alınınca yapay yem de alışverişte")
	sim.call("_choose_technique")
	assert_eq(sim.technique, "spin", "yeni tekniği dener (merak)")
	sim.cast_once()
	assert_true(sim.milestones.has("tech:spin"), "spinle ilk atış sayılır")
