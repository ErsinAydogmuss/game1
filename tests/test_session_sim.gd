extends BaseTest
## Denge botu (SessionSim) korkulukları: ekonomi ve ilerleme temposu (docs/gdd.md §10.4).
## Sayılar tools/economy_report.gd ölçümüne pay bırakarak seçildi; fiyat, rütbe puanı, balık
## değeri, oran ya da kural değişince rapor yeniden çalıştırılır, tablo ve bu sınırlar gözden
## geçirilir. Sonraki dalgalar kendi satırlarını ekler (spin takımı 4–10 dk, sandal 90–180 dk...).

const SEEDS := [1000, 1077, 1154]
## Korkulukların ölçüldüğü oyun süresi (dk).
const MINUTES := 100.0
## [olay, en erken dk, en geç dk]: her seed'de olay bu aralıkta ilk kez olmalı.
const PACING := [
	["sell", 0.0, 5.0],            # ilk satış (kova dolar, Nine'ye gidilir)
	["buy", 0.0, 10.0],            # ilk alışveriş
	["rank_2", 0.0, 5.0],
	["rank_5", 6.0, 20.0],
	["rank_10", 35.0, 90.0],
	["species_5", 0.0, 30.0],      # gölün beş türü
	["buy:rod_float_glass", 10.0, 45.0],
	["buy:bucket_big", 15.0, 60.0],
	["buy:net", 40.0, 100.0],
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
		assert_between(sim.earned / hours, 2000.0, 4500.0, "seed %d: saatte para" % seed_value)
		assert_between(sim.catches / hours, 120.0, 280.0, "seed %d: saatte av" % seed_value)


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
