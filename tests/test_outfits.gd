extends BaseTest
## Kıyafetler (Dalga 5): veri temiz, her yuvada bir varsayılan, açılma kayıttan türer (rütbe, defter, istek,
## sevgi, Bekçi, Tekir'in hediyeleri; geriye dönük), kilitli kıyafet giyilemez, bilinmeyen ya da kilitli kayıt
## varsayılana döner, yeni açılanlar bir kez duyurulur, dolapta görülünce rozet söner.


func _save() -> SaveData:
	return SaveData.create_new(1000)


func test_data_is_clean_and_every_slot_has_a_default() -> void:
	var db := content()
	assert_true(db.errors.is_empty(), "veri temiz: " + " | ".join(db.errors))
	for slot: String in SaveData.OUTFIT_SLOTS:
		var id := db.outfits.default_of(slot)
		assert_true(not id.is_empty(), "%s yuvasının varsayılanı var" % slot)
		assert_true(db.outfits.of_slot(slot).size() >= 5, "%s yuvasında en az 5 kıyafet" % slot)
		assert_eq(Outfits.equipped(db, _save(), slot), id, "yeni oyunda %s varsayılan" % slot)
	assert_eq(db.outfits.cat_gift_count(), 5, "Tekir'in beş hediyesi")
	for n in range(1, db.outfits.cat_gift_count() + 1):
		assert_true(not db.outfits.cat_gift(n).is_empty(), "Tekir'in %d. hediyesi" % n)
	assert_eq(db.outfits.cat_gift(db.outfits.cat_gift_count() + 1), "", "hediyeler bitince boş")


func test_bad_data_is_caught() -> void:
	var db := content()
	var bad := OutfitRules.from_dict({ "items": [
		{ "id": "hat_a", "slot": "hat", "unlock": "start", "shape": "bucket", "color": "#ffffff", "band": "#000000" },
		{ "id": "hat_a", "slot": "hat", "unlock": "start", "shape": "tophat", "color": "#ffffff", "band": "nope" },
		{ "id": "vest_a", "slot": "vest", "unlock": "rank", "value": 99, "color": "#ff0000" },
		{ "id": "rod_a", "slot": "rod", "unlock": "cat", "value": 2, "color": "#ff0000", "band": "#00ff00" },
		{ "id": "shoe_a", "slot": "shoes", "unlock": "magic" },
	] }, PackedStringArray())
	var errors := PackedStringArray()
	bad.validate(db, errors)
	var all := " | ".join(errors)
	assert_true("tekrar: hat_a" in all, "tekrarlanan kimlik")
	assert_true("biçimi bilinmiyor: tophat" in all, "bilinmeyen şapka biçimi")
	assert_true("band geçerli bir renk" in all, "bozuk renk")
	assert_true("vest_a: rütbe" in all, "aralık dışı rütbe")
	assert_true("yuva bilinmiyor: shoes" in all, "bilinmeyen yuva")
	assert_true("şart bilinmiyor: magic" in all, "bilinmeyen şart")
	assert_true("hat yuvasında tam bir başlangıç" in all, "iki başlangıç şapkası")
	assert_true("vest yuvasında tam bir başlangıç" in all, "başlangıç yeleği yok")
	assert_true("Tekir'in hediyeleri 1'den sırayla" in all, "hediye sırası boşluklu")


## Açılma kayıttan türer: her şart kendi sayacıyla; geriye dönük (yeni veri eski kayıtta da açılır).
func test_unlocks_follow_the_save() -> void:
	var db := content()
	var save := _save()
	for e in db.outfits.items:
		var start := str(e["unlock"]) == "start"
		assert_eq(Outfits.unlocked(db, save, str(e["id"])), start, "yeni oyunda yalnızca başlangıç: " + str(e["id"]))
		assert_eq(Outfits.reason(db, str(e["id"])).is_empty(), start, "kilitlinin nedeni var: " + str(e["id"]))
	# Rütbe: hat_red rütbe 3.
	save.xp = db.rank_xp[2]
	assert_eq(Rank.rank(db, save), 3, "rütbe 3")
	assert_true(Outfits.unlocked(db, save, "hat_red"), "rütbe 3'te kırmızı şapka")
	assert_true(not Outfits.unlocked(db, save, "hat_fly"), "rütbe 7'nin şapkası kilitli")
	assert_eq(Outfits.progress(db, save, "hat_fly"), Vector2i(3, 7), "ilerleme")
	# Defter: bere 8 tür.
	for f in db.fish.slice(0, 7):
		save.records[str(f["id"])] = { "count": 1 }
	assert_true(not Outfits.unlocked(db, save, "hat_beanie"), "7 tür yetmez")
	save.records[str(db.fish[7]["id"])] = { "count": 1 }
	assert_true(Outfits.unlocked(db, save, "hat_beanie"), "8 türde bere")
	# İstekler: kasket 10 istek.
	save.stats["requests"] = 10
	assert_true(Outfits.unlocked(db, save, "hat_cap"), "10 istekte kasket")
	# Göl sevgisi: mor yelek seviye 4.
	save.love = db.rules.love_levels[3]
	assert_eq(LakeLove.level(db.rules, save.love), 4, "sevgi seviyesi 4")
	assert_true(Outfits.unlocked(db, save, "vest_purple"), "sevgi 4'te mor yelek")
	assert_true(not Outfits.unlocked(db, save, "rod_night"), "sevgi 8'in kaplaması kilitli")
	# Bekçi.
	assert_true(not Outfits.unlocked(db, save, "hat_keeper"), "Bekçi bırakılmadan kilitli")
	save.keeper = 1
	assert_true(Outfits.unlocked(db, save, "hat_keeper") and Outfits.unlocked(db, save, "rod_keeper"),
			"Bekçi bırakılınca onun şapkası ve kaplaması")
	# Tekir: hediyeler beslemeden türer.
	save.cat_fed = db.rules.cat_gift_every * 2
	assert_true(Outfits.unlocked(db, save, db.outfits.cat_gift(1)), "1. hediye")
	assert_true(Outfits.unlocked(db, save, db.outfits.cat_gift(2)), "2. hediye")
	assert_true(not Outfits.unlocked(db, save, db.outfits.cat_gift(3)), "3. hediye henüz yok")


## Tekir'in beslenmesi sıradaki hediyenin kıyafetini verir (beşinci beslemede).
func test_feeding_brings_the_gift_outfit() -> void:
	var db := content()
	var save := _save()
	var gift := ""
	for meal in db.rules.cat_gift_every:
		save.catches += db.rules.cat_meal_every
		save.bucket.append({ "fish": "rudd", "size_cm": 20, "stars": 1 })
		var fed := CatRules.feed(db, save)
		if int(fed.get("gift", 0)) > 0:
			gift = str(fed["gift_id"])
	assert_eq(gift, db.outfits.cat_gift(1), "beşinci beslemede ilk hediye")
	assert_true(Outfits.unlocked(db, save, gift), "hediye açıldı")
	assert_eq(Outfits.fresh(db, save), [gift] as Array[String], "yeni açılan yalnızca hediye")


func test_equip_only_unlocked_and_fall_back_to_default() -> void:
	var db := content()
	var save := _save()
	assert_true(not Outfits.equip(db, save, "hat_red"), "kilitli şapka giyilmez")
	assert_eq(Outfits.equipped(db, save, "hat"), "hat_bucket", "varsayılan kalır")
	assert_true(not Outfits.equip(db, save, "no_such_hat"), "bilinmeyen kıyafet giyilmez")
	save.xp = db.rank_xp[2]
	assert_true(Outfits.equip(db, save, "hat_red"), "açılınca giyilir")
	assert_eq(str(save.outfit["hat"]), "hat_red", "kayda yazıldı")
	assert_eq(Outfits.equipped(db, save, "hat"), "hat_red", "giyilen")
	var look := Outfits.look(db, save)
	assert_eq(str((look["hat"] as Dictionary)["shape"]), "bucket", "görünüşün şapkası")
	assert_eq(str((look["vest"] as Dictionary)["id"]), "vest_yellow", "yelek varsayılan")
	# Bozuk kayıt: bilinmeyen kimlik, başka yuvanın kimliği, kilitli kimlik varsayılana döner.
	save.outfit["vest"] = "hat_red"
	assert_eq(Outfits.equipped(db, save, "vest"), "vest_yellow", "başka yuvanın kimliği varsayılana")
	save.outfit["rod"] = "rod_keeper"
	assert_eq(Outfits.equipped(db, save, "rod"), "rod_plain", "kilitli kimlik varsayılana")
	save.outfit["hat"] = "crown_of_gold"
	assert_eq(Outfits.equipped(db, save, "hat"), "hat_bucket", "bilinmeyen kimlik varsayılana")
	# Kayıt gidiş-dönüş.
	assert_true(Outfits.equip(db, save, "hat_red"), "yine giyilir")
	var back := SaveData.from_dict(save.to_dict())
	assert_eq(Outfits.equipped(db, back, "hat"), "hat_red", "kayıtla döner")


## Yeni açılan bir kez duyurulur; dolapta görülünce rozet söner; görülen bir daha duyurulmaz.
func test_fresh_outfits_are_announced_once() -> void:
	var db := content()
	var save := _save()
	assert_eq(Outfits.fresh(db, save), [] as Array[String], "yeni oyunda duyurulacak yok")
	save.xp = db.rank_xp[2]
	var fresh := Outfits.fresh(db, save)
	assert_eq(fresh, ["hat_red", "vest_red"] as Array[String], "rütbe 3'e gelen: rütbe 2 ve 3'ün kıyafetleri")
	Outfits.announce(save, fresh)
	assert_eq(Outfits.fresh(db, save), [] as Array[String], "duyurulan yine duyurulmaz")
	assert_true(Outfits.is_new(save, "hat_red"), "dolapta yeni")
	assert_eq(Outfits.new_count(db, save), 2, "iki yeni")
	assert_eq(Outfits.new_count(db, save, "hat"), 1, "şapkalarda bir yeni")
	Outfits.mark_seen(db, save, "hat_red")
	assert_true(not Outfits.is_new(save, "hat_red"), "görülünce rozet söner")
	assert_eq(Outfits.new_count(db, save, "hat"), 0, "şapkalarda yeni yok")
	# Duyurulmadan dolapta görülen sonradan duyurulmaz.
	save.xp = db.rank_xp[4]
	Outfits.mark_seen(db, save, "rod_red")
	assert_true(not "rod_red" in Outfits.fresh(db, save), "görülen kaplama duyurulmaz")
	# Kilitli kıyafet görülmüş sayılmaz.
	Outfits.mark_seen(db, save, "hat_keeper")
	assert_true(not save.flags.has(Outfits.FLAG % "hat_keeper"), "kilitli görülmez")
