extends BaseTest
## Fark etme, korkutma, dürtme ve erken dokunuş kuralları.


func _shadow(pos: Vector2, heading: Vector2, length: float = 0.6) -> FishShadow:
	var s := FishShadow.new()
	s.pos = pos
	s.heading = heading.normalized()
	s.length = length
	return s


func test_notice_cone_and_radius() -> void:
	var rules := content().rules
	var s := _shadow(Vector2.ZERO, Vector2(0, -1))
	assert_true(BiteRules.notices(s, Vector2(0, -2.9), rules), "önde 2,9 m: fark eder")
	assert_true(not BiteRules.notices(s, Vector2(0, -3.1), rules), "önde 3,1 m: fark etmez")
	assert_true(BiteRules.notices(s, Vector2(0, 1.7), rules), "arkada 1,7 m: fark eder")
	assert_true(not BiteRules.notices(s, Vector2(0, 1.9), rules), "arkada 1,9 m: fark etmez")
	var at_60 := Vector2(sin(deg_to_rad(60.0)), -cos(deg_to_rad(60.0))) * 2.5
	var at_80 := Vector2(sin(deg_to_rad(80.0)), -cos(deg_to_rad(80.0))) * 2.5
	assert_true(BiteRules.notices(s, at_60, rules), "60° yanda 2,5 m: konide")
	assert_true(not BiteRules.notices(s, at_80, rules), "80° yanda 2,5 m: konin dışında")


func test_scare_radius() -> void:
	var rules := content().rules
	var s := _shadow(Vector2.ZERO, Vector2(0, -1), 1.0)
	# Yarıçap: 1,0 / 2 + 0,3 = 0,8 m.
	assert_true(BiteRules.scares(s, Vector2(0.79, 0), rules), "0,79 m: korkar")
	assert_true(not BiteRules.scares(s, Vector2(0.81, 0), rules), "0,81 m: korkmaz")


func test_nibble_distribution() -> void:
	var rules := content().rules
	var rng := RandomNumberGenerator.new()
	rng.seed = 31
	var counts := [0, 0, 0, 0]
	var n := 20000
	for i in n:
		counts[BiteRules.roll_nibbles(rng, rules)] += 1
	var expected := [15.0, 30.0, 35.0, 20.0]
	for k in 4:
		assert_between(100.0 * counts[k] / n, expected[k] - 1.5, expected[k] + 1.5, "%d dürtme oranı" % k)
	var low := 1_000_000
	var high := 0
	for i in 2000:
		var gap := BiteRules.roll_gap(rng, rules)
		low = mini(low, gap)
		high = maxi(high, gap)
	assert_eq(low, FishingRules.to_steps(0.8), "en kısa ara 0,8 sn")
	assert_eq(high, FishingRules.to_steps(1.4), "en uzun ara 1,4 sn")


func test_early_tap_outcome() -> void:
	assert_eq(BiteRules.early_outcome(false, false, 0), "flee", "Normal: erken dokunuş balığı kaçırır")
	assert_eq(BiteRules.early_outcome(true, false, 0), "startle", "Kolay: ilk erken dokunuş irkiltir")
	assert_eq(BiteRules.early_outcome(true, false, 1), "flee", "Kolay: ikincisi kaçırır")
	assert_eq(BiteRules.early_outcome(false, true, 5), "startle", "ilk av hiç kaçmaz")


func test_window_lengths() -> void:
	var rules := content().rules
	assert_eq(BiteRules.window_steps(rules, false), 60, "Normal pencere 1,0 sn")
	assert_eq(BiteRules.window_steps(rules, true), 96, "Kolay pencere 1,6 sn")
