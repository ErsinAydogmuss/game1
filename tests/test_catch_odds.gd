extends BaseTest
## Hangi balığın geleceği (CatchOdds): oranlar toplamı tam 1e6, yem türleri çeker, zarın
## sonucu gösterilen orana uyar, şans garantisi doğru kademede ve tek bir gölgeyle işler.


func _spot() -> Dictionary:
	return content().spot("big_lake")


func test_odds_sum_to_one_million() -> void:
	var db := content()
	for ctx: Dictionary in [{}, { "attract": { "carp": 2.2 } }, { "attract": { "rudd": 1.8, "perch": 1.4 } }]:
		var species := CatchOdds.species_ppm(db, _spot(), ctx)
		var total := 0
		for id: String in species:
			total += int(species[id])
		assert_eq(total, Dice.PPM, "türler toplamı 1e6 (%s)" % str(ctx))
		var by_rarity := CatchOdds.rarity_ppm(db, species)
		var sum := 0
		for v in by_rarity:
			sum += v
		assert_eq(sum, Dice.PPM, "nadirlikler toplamı 1e6")


func test_bait_attracts_its_fish() -> void:
	var db := content()
	var plain := CatchOdds.species_ppm(db, _spot())
	# Köy Gölü ağırlıkları 40/25/22/9/4 = 100.
	assert_eq(int(plain["rudd"]), 400000, "kızılkanat %40")
	var corn := CatchOdds.species_ppm(db, _spot(), { "attract": db.gear_item("bait_corn")["attract"] })
	# Sazan 25 × 2,2 = 55; toplam 75 + 55 = 130.
	assert_between(float(corn["carp"]), 423076.0, 423078.0, "mısırla sazan %42,3")
	assert_true(int(corn["rudd"]) < int(plain["rudd"]), "öteki türlerin payı azalır")


func test_rolls_follow_the_shown_odds() -> void:
	var db := content()
	var species := CatchOdds.species_ppm(db, _spot())
	var rng := RandomNumberGenerator.new()
	rng.seed = 1234
	var counts := {}
	var n := 20000
	for i in n:
		var id := CatchOdds.roll(db, rng, species)
		counts[id] = int(counts.get(id, 0)) + 1
	for id: String in species:
		var expected := float(species[id]) / Dice.PPM
		assert_between(float(counts.get(id, 0)) / n, expected - 0.015, expected + 0.015, "%s oranı tutar" % id)


func test_floor_limits_the_roll() -> void:
	var db := content()
	var species := CatchOdds.species_ppm(db, _spot())
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	var rare := db.rarity_index("rare")
	for i in 200:
		var id := CatchOdds.roll(db, rng, species, rare)
		assert_true(int(db.fish_by_id(id)["rarity"]) >= rare, "garantide yalnızca Nadir ve üstü: " + id)
	# Gölde Efsanevi yok: garanti boşa düşmez, normal seçim yapılır.
	assert_true(not CatchOdds.roll(db, rng, species, db.rarity_index("legendary")).is_empty(), "uygun tür yoksa normal seçim")


func test_pity_counters() -> void:
	var db := content()
	var s := SaveData.create_new(1)
	var rare := db.rarity_index("rare")
	var common := db.rarity_index("common")
	assert_eq(CatchOdds.pity_floor(db, s), -1, "başta garanti yok")
	assert_eq(CatchOdds.pity_left(db, s, rare), 40, "Nadir için 40 av")
	assert_eq(CatchOdds.pity_left(db, s, common), -1, "Sıradan'ın garantisi yok")
	for i in 39:
		CatchOdds.note_catch(db, s, common)
	assert_eq(CatchOdds.pity_floor(db, s), -1, "39 avda henüz yok")
	CatchOdds.note_catch(db, s, db.rarity_index("fine"))
	assert_eq(CatchOdds.pity_floor(db, s), rare, "40. avda Nadir garantisi (Güzel sayacı sıfırlamaz)")
	assert_eq(int(s.pity["epic"]), 40, "Destansı sayacı da sayar")
	CatchOdds.note_catch(db, s, rare)
	assert_eq(int(s.pity["rare"]), 0, "Nadir tutulunca Nadir sayacı sıfırlanır")
	assert_eq(int(s.pity["epic"]), 41, "Destansı sayacı sürer")
	assert_eq(CatchOdds.pity_floor(db, s), -1, "garanti kullanıldı")


## Gölde tutulamayan kademenin dolu sayacı garantiyi kilitlemez: Köy Gölü'nde Efsanevi yok.
func test_pity_ignores_tiers_missing_from_the_lake() -> void:
	var db := content()
	var s := SaveData.create_new(1)
	var spot := db.spot("big_lake")
	s.pity["legendary"] = 999
	s.pity["epic"] = 3
	s.pity["rare"] = 40
	assert_eq(CatchOdds.top_rarity(db, spot), db.rarity_index("epic"), "gölün en yükseği Destansı")
	assert_eq(CatchOdds.pity_floor(db, s, spot), db.rarity_index("rare"), "Nadir garantisi işler")
	assert_eq(CatchOdds.pity_floor(db, s), db.rarity_index("legendary"), "göl verilmezse bütün kademeler")
	s.pity["rare"] = 2
	assert_eq(CatchOdds.pity_floor(db, s, spot), -1, "gölde olmayan Efsanevi garanti vermez")


## Garanti yakında doğan sıradaki gölgeyi belirler; aynı anda tek garanti gölgesi olur; tür
## değişse de boy aynı tuzlu zardan gelir.
func test_pity_shapes_the_next_shadow_only() -> void:
	var db := content()
	var spot := _spot()
	var lake := db.lake("big_lake")
	var rare := db.rarity_index("rare")
	var plain := ShadowSim.new(db, spot, lake, 777, false, Vector2(0, 4))
	var forced := ShadowSim.new(db, spot, lake, 777, false, Vector2(0, 4), { "pity_floor": rare })
	var pity_count := 0
	for s in forced.shadows:
		if s.pity:
			pity_count += 1
			assert_true(s.rarity >= rare, "garanti gölgesi Nadir ve üstü")
	assert_eq(pity_count, 1, "aynı anda tek garanti gölgesi")
	assert_eq(plain.shadows.size(), forced.shadows.size(), "aynı sayıda gölge")
	for i in mini(plain.shadows.size(), forced.shadows.size()):
		assert_eq(forced.shadows[i].percentile, plain.shadows[i].percentile, "boy türden bağımsız (%d)" % i)
		assert_eq(forced.shadows[i].pos, plain.shadows[i].pos, "yer türden bağımsız (%d)" % i)
