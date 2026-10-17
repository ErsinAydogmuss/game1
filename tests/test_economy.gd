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
	var up := Rank.add_xp(db, s, 45)
	assert_eq(int(up["old_rank"]), 1, "1. rütbeden")
	assert_eq(int(up["new_rank"]), 2, "2. rütbeye")
	assert_between(Rank.progress(db, s), 0.06, 0.08, "2. rütbede biraz ilerlemiş (45 / 40–110)")
	s.xp = 999999
	assert_eq(Rank.rank(db, s), db.max_rank(), "en yüksek rütbe")
	assert_eq(Rank.progress(db, s), 1.0, "en yüksek rütbede dolu")
