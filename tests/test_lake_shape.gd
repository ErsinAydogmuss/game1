extends BaseTest
## Göl şekli: su / kara / iskele, kıyı uzaklığı, derinlik ve şamandıranın düşeceği yer.
## Ölçüler data/spots.json'daki home_lake'ten: ana elips (0, 0) merkezli 9 × 6,5 m; iskele
## x −0,8..0,8, z 3,5..8,5; balıkçı (0, 4)'te.


func _lake() -> LakeShape:
	return content().lake("home_lake")


func test_water_land_and_dock() -> void:
	var lake := _lake()
	assert_true(lake.is_water(Vector2(0, 0)), "gölün ortası su")
	assert_true(not lake.is_water(Vector2(0, 12)), "kıyının ötesi kara")
	assert_true(not lake.is_water(Vector2(20, 0)), "uzak kara")
	assert_true(lake.on_dock(Vector2(0, 6)) and lake.is_water(Vector2(0, 6)), "iskelenin altı su")
	assert_true(lake.is_walkable(Vector2(0, 6)), "iskelede yürünür")
	assert_true(lake.is_walkable(Vector2(0, 12)), "karada yürünür")
	assert_true(not lake.is_walkable(Vector2(0, 0)), "suda yürünmez")
	assert_true(lake.is_walkable(content().spot("home_lake")["start"]), "balıkçı yürünebilir yerde başlar")


func test_shore_distance_and_depth() -> void:
	var lake := _lake()
	assert_between(lake.shore_distance(Vector2(0, 0)), 6.2, 6.8, "ortada kıyıya ~6,5 m")
	assert_true(lake.shore_distance(Vector2(0, 12)) < 0.0, "karada kıyı uzaklığı eksi")
	assert_eq(lake.depth_at(Vector2(20, 0)), 0.0, "karada derinlik 0")
	var near := lake.depth_at(Vector2(8.5, 0))
	var mid := lake.depth_at(Vector2(7, 0))
	var deep := lake.depth_at(Vector2(4, 0))
	assert_true(near < mid and mid < deep, "kıyıdan uzaklaştıkça derinleşir (%.2f, %.2f, %.2f)" % [near, mid, deep])
	assert_true(near < content().rules.min_depth, "kıyı dibi sığ: gölgeler girmez")
	assert_between(lake.depth_at(Vector2(0, 0)), 3.4, 3.5, "en derin yer max_depth")
	assert_eq(lake.shore.size(), lake.width * lake.height, "ızgara dolu")
	# Izgaranın dışında da gerçek uzaklık: içeride shore_distance ile aynı, dışarıda uzaklaştıkça artar.
	assert_eq(lake.land_distance(Vector2(0, 0)), lake.shore_distance(Vector2(0, 0)), "ızgarada aynı")
	var far := lake.land_distance(Vector2(0, 30))
	var farther := lake.land_distance(Vector2(0, 40))
	assert_true(far < -LakeShape.MARGIN - 10.0, "ızgaranın 20 m ötesi kıyıdan da uzak (%.1f)" % far)
	assert_between(far - farther, 9.9, 10.1, "10 m daha uzak, 10 m daha eksi")


func test_landing_point() -> void:
	var lake := _lake()
	var from := Vector2(0, 4)
	var min_shore := content().rules.min_shore
	var p := lake.landing_point(from, Vector2(0, 0), 9.0, min_shore)
	assert_true(p.distance_to(Vector2(0, 0)) < 0.01, "menzil içi su hedefi aynen")
	p = lake.landing_point(from, Vector2(0, -20), 9.0, min_shore)
	assert_true(Dice.is_point(p) and absf(p.distance_to(from) - 9.0) < 0.01, "menzil dışı: menzilin ucuna düşer")
	assert_true(lake.is_water(p), "menzil dışı atış suya düşer")
	p = lake.landing_point(from, Vector2(0, -12), 30.0, min_shore)
	assert_true(Dice.is_point(p) and lake.is_water(p), "karşı kıyıya atış suya düşer")
	assert_true(Dice.is_point(p) and lake.shore_distance(p) >= min_shore, "kıyıya çok yakın düşmez")
	assert_between(p.y, -6.5, -5.5, "karşı kıyının hemen önüne")
	assert_true(not Dice.is_point(lake.landing_point(Vector2(0, 15), Vector2(0, 30), 9.0, min_shore)),
			"çizgide su yoksa atış yok")
	assert_true(not Dice.is_point(lake.landing_point(from, Vector2(0, 6), 9.0, min_shore)),
			"iskeleye atış olmaz")


func test_deep_paths() -> void:
	var lake := _lake()
	var min_depth := content().rules.min_depth
	assert_true(lake.segment_is_deep(Vector2(-2, 0), Vector2(2, 0), min_depth), "göl ortası derin yol")
	assert_true(not lake.segment_is_deep(Vector2(0, 0), Vector2(0, 7), min_depth), "iskele ve kıyıdan geçen yol derin değil")
	assert_true(not lake.is_deep(Vector2(0, 3.2), min_depth), "iskelenin ucunun dibine gölge girmez")
	assert_true(lake.water_bounds.has_point(Vector2(-12, -5)), "yan göl sınır kutusunda")
	assert_true(lake.is_water(Vector2(-10, -4)), "yan gölün içi su")
