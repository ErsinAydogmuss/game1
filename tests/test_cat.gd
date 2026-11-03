extends BaseTest
## Tekir (Dalga 5): acıkma balık sayısından türer (gerçek saat yok, oyuncu yokken aç kalmaz), acıkmışken kovadaki
## en ucuz balığı yer, kova boşsa bekler (ceza yok), sayaçlar ve her beşinci beslemede sıradaki hediye.


func _save(catches: int) -> SaveData:
	var save := SaveData.create_new(1000)
	save.catches = catches
	return save


func test_hunger_follows_catches() -> void:
	var rules := content().rules
	var save := _save(0)
	assert_true(not CatRules.is_hungry(rules, save), "yeni oyunda tok")
	assert_eq(CatRules.meals_left(rules, save), rules.cat_meal_every, "acıkmasına kalan balık")
	save.catches = rules.cat_meal_every - 1
	assert_true(not CatRules.is_hungry(rules, save), "bir balık eksik")
	save.catches = rules.cat_meal_every
	assert_true(CatRules.is_hungry(rules, save), "yeterince balık tutulunca acıkır")
	assert_eq(CatRules.meals_left(rules, save), 0, "acıkınca kalan 0")
	save.catches += 500
	assert_true(CatRules.is_hungry(rules, save), "uzun süre beslenmese de yalnızca aç (ceza yok)")


func test_feeding_takes_the_cheapest_fish() -> void:
	var db := content()
	var save := _save(db.rules.cat_meal_every)
	save.bucket = [{ "fish": "pike", "size_cm": 80, "stars": 2 }, { "fish": "rudd", "size_cm": 25, "stars": 2 },
			{ "fish": "silverside", "size_cm": 16, "stars": 3 }, { "fish": "silverside", "size_cm": 9, "stars": 1 }]
	var cheapest := Economy.fish_value(db, "silverside", 9)
	var fed := CatRules.feed(db, save)
	assert_eq(str(fed.get("fish", "")), "silverside", "en ucuz tür")
	assert_eq(int(fed.get("size_cm", 0)), 9, "en ucuz balık (aynı türün küçüğü)")
	assert_eq(int(fed.get("value", -1)), cheapest, "değeri")
	assert_eq(save.bucket.size(), 3, "kovadan bir balık gitti")
	assert_eq(save.cat_fed, 1, "besleme sayısı")
	assert_eq(save.cat_meal_at, save.catches, "son besleme şimdiki balık sayısında")
	assert_eq(int(save.stats["cat_fed"]), 1, "sayaç")
	assert_true(not CatRules.is_hungry(db.rules, save), "beslenince tok")
	# En ucuz: ne en küçük ne son giren (çapak 25 cm 4 para; kızılkanat 30 cm 8, gümüş 18 cm 6).
	var other := _save(db.rules.cat_meal_every)
	other.bucket = [{ "fish": "rudd", "size_cm": 30, "stars": 2 }, { "fish": "bream", "size_cm": 25, "stars": 1 },
			{ "fish": "silverside", "size_cm": 18, "stars": 3 }]
	assert_eq(str(CatRules.feed(db, other).get("fish", "")), "bream", "en ucuz balık: ne en küçük ne son giren")
	# Değer eşitse küçüğü (çapak 25 cm ve gümüş 12 cm: ikisi de 4 para; ilk giren çapak).
	var tie := _save(db.rules.cat_meal_every)
	tie.bucket = [{ "fish": "bream", "size_cm": 25, "stars": 1 }, { "fish": "rudd", "size_cm": 30, "stars": 2 },
			{ "fish": "silverside", "size_cm": 12, "stars": 1 }]
	assert_eq(Economy.fish_value(db, "bream", 25), Economy.fish_value(db, "silverside", 12), "örnekte değerler eşit")
	var eaten := CatRules.feed(db, tie)
	assert_eq([str(eaten.get("fish", "")), int(eaten.get("size_cm", 0))], ["silverside", 12], "değer eşitse küçüğü")
	assert_eq(CatRules.feed(db, save), {}, "tokken yemez, kova aynı")
	assert_eq(save.bucket.size(), 3, "tok kedi balık almaz")


func test_empty_bucket_keeps_the_cat_waiting() -> void:
	var db := content()
	var save := _save(db.rules.cat_meal_every + 3)
	assert_eq(CatRules.feed(db, save), {}, "kova boşken beslenmez")
	assert_eq(save.cat_fed, 0, "sayaç değişmez")
	assert_true(CatRules.is_hungry(db.rules, save), "aç bekler")
	assert_eq(CatRules.pick(db, save), -1, "kovada balık yok")


func test_every_fifth_meal_brings_a_gift() -> void:
	var db := content()
	var rules := db.rules
	var save := _save(0)
	var gifts: Array[int] = []
	for meal in rules.cat_gift_every * 2:
		save.catches += rules.cat_meal_every
		save.bucket.append({ "fish": "rudd", "size_cm": 20, "stars": 1 })
		var fed := CatRules.feed(db, save)
		assert_eq(int(fed.get("fed", 0)), meal + 1, "besleme sırası")
		gifts.append(int(fed.get("gift", -1)))
	var expected: Array[int] = []
	for meal in rules.cat_gift_every * 2:
		var n := meal + 1
		expected.append(floori(float(n) / rules.cat_gift_every) if n % rules.cat_gift_every == 0 else 0)
	assert_eq(gifts, expected, "her %d beslemede sıradaki hediye (zar yok)" % rules.cat_gift_every)
	assert_eq(CatRules.gifts(rules, save), 2, "iki hediye kazanıldı")
