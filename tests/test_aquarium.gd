extends BaseTest
## Akvaryum (Dalga 5): tankta her tutulmuş türün en irisi (defterden; satılmayan türler girmez), kutu
## gerçek saatle dolar ve üst sınırda durur, saatin geri alınması bir şey kaybettirmez ya da kazandırmaz,
## kesir kaybolmaz (her saniye güncelleyen oyun ile tek seferde güncelleyen bot aynı parayı bulur),
## toplama paraya ve sayaca girer, kesir kutuda kalır.

const T0 := 1_700_000_000


func _save() -> SaveData:
	var save := SaveData.create_new(T0)
	save.records = {
		"rudd": { "count": 4, "best_cm": 24, "best_stars": 2, "first_unix": T0, "released": 0 },
		"pike": { "count": 1, "best_cm": 95, "best_stars": 4, "first_unix": T0, "released": 0 },
		"sturgeon": { "count": 1, "best_cm": 160, "best_stars": 3, "first_unix": T0, "released": 1 },
		"keeper": { "count": 1, "best_cm": 500, "best_stars": 5, "first_unix": T0, "released": 1 },
	}
	return save


func test_tank_holds_the_best_of_each_sellable_species() -> void:
	var db := content()
	var save := _save()
	var tank := Aquarium.fish(db, save)
	var ids: Array[String] = []
	for f in tank:
		ids.append(str(f["fish"]))
	assert_eq(ids, ["rudd", "pike"] as Array[String], "satılan türler fish.json sırasıyla")
	assert_eq(int(tank[0]["size_cm"]), 24, "defterin en irisi")
	assert_eq(int(tank[1]["stars"]), 4, "en irinin yıldızı")
	assert_eq(int(tank[1]["value"]), Economy.fish_value(db, "pike", 95), "değeri o boyda")
	for id in ["sturgeon", "keeper", "moon_pike", "kocabas"]:
		assert_true(not id in Aquarium.species(db), "%s tanka girmez (satılmaz, göle döner)" % id)
	assert_eq(Aquarium.capacity(db), 15, "tank 15 türü alır")
	assert_true("crayfish" in Aquarium.species(db), "tuzaktaki kerevit de girer")
	assert_eq(Aquarium.fish(db, SaveData.create_new(T0)), [] as Array[Dictionary], "boş defterde tank boş")


func test_rate_follows_the_tank() -> void:
	var db := content()
	var save := _save()
	var rules := db.rules
	var value := Economy.fish_value(db, "rudd", 24) + Economy.fish_value(db, "pike", 95)
	assert_eq(Aquarium.rate_ph(db, save), 2 * rules.aquarium_species_ph + (value * rules.aquarium_value_pm + 500) / 1000,
			"tür başına ve değerin payı")
	var before := Aquarium.rate_ph(db, save)
	save.records["pike"]["best_cm"] = 118
	assert_true(Aquarium.rate_ph(db, save) > before, "daha iri balık daha çok ziyaretçi")
	save.records["tench"] = { "count": 1, "best_cm": 30, "best_stars": 1, "first_unix": T0, "released": 0 }
	assert_true(Aquarium.rate_ph(db, save) > before + rules.aquarium_species_ph, "yeni tür daha çok ziyaretçi")
	assert_eq(Aquarium.rate_ph(db, SaveData.create_new(T0)), 0, "boş tank bağış toplamaz")


func test_box_fills_with_real_time_and_stops_at_the_cap() -> void:
	var db := content()
	var save := _save()
	var rate := Aquarium.rate_ph(db, save)
	assert_true(rate > 0, "tankta balık var")
	Aquarium.update(db, save, T0)
	assert_eq(save.aquarium_unix, T0, "kutunun saati ilk güncellemede başlar")
	assert_eq(save.aquarium_box, 0, "başlarken boş")
	assert_eq(Aquarium.pending(db, save, T0 + 3600), rate, "bir saatte saatlik kazanç")
	assert_eq(save.aquarium_box, 0, "bakmak kutuyu değiştirmez")
	assert_true(not Aquarium.is_full(db, save, T0 + 3600), "bir saatte dolmaz")
	var cap := Aquarium.cap_coins(db, save)
	assert_eq(cap, rate * db.rules.aquarium_cap_s / Aquarium.UNIT, "üst sınır cap_s'lik kazanç")
	assert_eq(Aquarium.pending(db, save, T0 + 86_400), cap, "bir günde üst sınırda durur")
	assert_true(Aquarium.is_full(db, save, T0 + 86_400), "üst sınırda dolu")
	Aquarium.update(db, save, T0 + 86_400)
	assert_eq(save.aquarium_box / Aquarium.UNIT, cap, "uzakta kalan oyuncu üst sınırı bulur")


func test_turning_the_clock_back_loses_and_gains_nothing() -> void:
	var db := content()
	var save := _save()
	Aquarium.update(db, save, T0)
	Aquarium.update(db, save, T0 + 1800)
	var half := save.aquarium_box
	assert_true(half > 0, "yarım saatte birikir")
	Aquarium.update(db, save, T0 - 50_000)
	assert_eq(save.aquarium_box, half, "saat geri alınınca kutu aynı")
	assert_eq(save.aquarium_unix, T0 - 50_000, "dayanak yenilenir")
	Aquarium.update(db, save, T0 - 50_000 + 1800)
	assert_eq(save.aquarium_box, half * 2, "geri alınan saat yeniden akınca yalnızca geçen süre kadar")


func test_no_fraction_is_lost() -> void:
	var db := content()
	var every_second := _save()
	var at_once := _save()
	Aquarium.update(db, every_second, T0)
	Aquarium.update(db, at_once, T0)
	for t in range(1, 5001):
		Aquarium.update(db, every_second, T0 + t)
	Aquarium.update(db, at_once, T0 + 5000)
	assert_eq(every_second.aquarium_box, at_once.aquarium_box, "her saniye güncellenen kutu tek seferdekiyle aynı")
	assert_eq(at_once.aquarium_box, Aquarium.rate_ph(db, at_once) * 5000, "birim: saatlik kazanç × saniye")


func test_collecting_pays_and_keeps_the_fraction() -> void:
	var db := content()
	var save := _save()
	save.coins = 10
	Aquarium.update(db, save, T0)
	var rate := Aquarium.rate_ph(db, save)
	var got := Aquarium.collect(db, save, T0 + 5401)
	var units := rate * 5401
	assert_eq(got, units / Aquarium.UNIT, "kutudaki tam para")
	assert_eq(save.coins, 10 + got, "paraya girer")
	assert_eq(int(save.stats["aquarium_coins"]), got, "sayaca girer")
	assert_eq(save.aquarium_box, units % Aquarium.UNIT, "kesir kutuda kalır")
	assert_eq(Aquarium.collect(db, save, T0 + 5401), 0, "boş kutudan para çıkmaz")
	assert_eq(int(save.stats["aquarium_coins"]), got, "boş toplama sayacı değiştirmez")
	var fresh := _save()
	assert_eq(Aquarium.collect(db, fresh, T0 + 99_999), 0, "saati başlamamış kutu boş")
	assert_eq(fresh.aquarium_unix, T0 + 99_999, "toplama saati başlatır")


func test_new_species_fill_from_now_on() -> void:
	var db := content()
	var save := SaveData.create_new(T0)
	Aquarium.update(db, save, T0)
	Aquarium.update(db, save, T0 + 7200)
	assert_eq(save.aquarium_box, 0, "boş tank iki saatte de bağış toplamaz")
	save.records["rudd"] = { "count": 1, "best_cm": 20, "best_stars": 1, "first_unix": T0, "released": 0 }
	assert_eq(Aquarium.pending(db, save, T0 + 7200 + 3600), Aquarium.rate_ph(db, save), "ilk balıktan sonra dolar")
