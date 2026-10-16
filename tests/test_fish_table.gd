extends BaseTest
## Balık zarı: tür dağılımı, boy yüzdeliği, yıldızlar, boy ve gölge; seed'li zarın tekrar
## edilebilirliği.

const SAMPLES := 20000


func test_percentile_curve() -> void:
	assert_eq(FishTable.percentile_for(0), 0, "en küçük")
	assert_eq(FishTable.percentile_for(Dice.PPM), Dice.PPM, "en büyük")
	var previous := -1
	var monotonic := true
	for u in range(0, Dice.PPM + 1, 997):
		var p := FishTable.percentile_for(u)
		if p < previous:
			monotonic = false
		previous = p
	assert_true(monotonic, "eğri hiç geri dönmez")
	assert_between(FishTable.percentile_for(500000), 320000, 340000, "u = 0,5 → 0,5^1,6 ≈ 0,33")


func test_stars() -> void:
	assert_eq(FishTable.stars(0), 1, "0 → 1 yıldız")
	assert_eq(FishTable.stars(199999), 1, "eşiğin altı")
	assert_eq(FishTable.stars(200000), 2, "0,2 → 2 yıldız")
	assert_eq(FishTable.stars(450000), 3, "0,45 → 3 yıldız")
	assert_eq(FishTable.stars(700000), 4, "0,7 → 4 yıldız")
	assert_eq(FishTable.stars(900000), 5, "0,9 → 5 yıldız")
	assert_eq(FishTable.stars(Dice.PPM), 5, "en büyük 5 yıldız")


func test_star_distribution() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 2024
	var counts := [0, 0, 0, 0, 0, 0]
	for i in SAMPLES:
		counts[FishTable.stars(FishTable.roll_percentile(rng))] += 1
	assert_between(100.0 * counts[5] / SAMPLES, 5.0, 7.8, "5 yıldız ~%6")
	assert_between(100.0 * counts[1] / SAMPLES, 33.0, 40.0, "1 yıldız en çok")


func test_species_distribution_follows_weights() -> void:
	var spot := content().spot("home_lake")
	var weights: PackedInt32Array = spot["fish_weights"]
	var total := 0
	for w in weights:
		total += w
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	var counts := PackedInt32Array()
	counts.resize(weights.size())
	for i in SAMPLES:
		counts[FishTable.roll_species(rng, weights)] += 1
	var ids: PackedStringArray = spot["fish_ids"]
	for i in weights.size():
		var expected := 100.0 * weights[i] / total
		assert_between(100.0 * counts[i] / SAMPLES, expected - 1.5, expected + 1.5, "%s oranı" % ids[i])


func test_size_and_shadow() -> void:
	var rudd := content().fish_by_id("rudd")
	assert_eq(FishTable.size_cm(rudd, 0), 15, "en küçük Kızılkanat 15 cm")
	assert_eq(FishTable.size_cm(rudd, Dice.PPM), 30, "en büyük Kızılkanat 30 cm")
	assert_between(FishTable.shadow_length(rudd, 0), 0.424, 0.426, "küçük gölge 0,85 × taban")
	assert_between(FishTable.shadow_length(rudd, Dice.PPM), 0.574, 0.576, "büyük gölge 1,15 × taban")
	var wels := content().fish_by_id("wels")
	assert_true(FishTable.shadow_length(wels, 0) > FishTable.shadow_length(rudd, Dice.PPM) * 2.0,
			"en küçük yayının gölgesi en büyük kızılkanatınkinin iki katından büyük")


func test_dice_is_repeatable() -> void:
	assert_eq(Dice.derive(5, 1, 2), Dice.derive(5, 1, 2), "aynı tohum aynı sonuç")
	assert_true(Dice.derive(5, 1, 2) != Dice.derive(5, 2, 1), "tuz sırası önemli")
	assert_true(Dice.derive(5, 1) != Dice.derive(6, 1), "taban tohum önemli")
	var a := RandomNumberGenerator.new()
	var b := RandomNumberGenerator.new()
	a.seed = 123
	b.seed = 123
	var same := true
	for i in 50:
		if FishTable.roll_percentile(a) != FishTable.roll_percentile(b):
			same = false
	assert_true(same, "aynı seed'le aynı boylar")
	var rng := RandomNumberGenerator.new()
	rng.seed = 9
	var picked := {}
	for i in 200:
		picked[Dice.pick_weighted(rng, PackedInt32Array([1, 0, 3]))] = true
	assert_true(not picked.has(1), "ağırlığı 0 olan hiç seçilmez")
	assert_eq(Dice.pick_weighted(rng, PackedInt32Array([0, 0])), -1, "toplam 0 → -1")
