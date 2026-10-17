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


## Eski şemadaki göl (home_lake): tek bölge, tek derinlik profili, dünya sınırı yok. Bugünkü gibi
## davranır (kıyı ızgarası eski kurulumla bit bit aynı; scratch karşılaştırmasıyla doğrulandı).
func test_old_schema_is_one_zone() -> void:
	var lake := _lake()
	assert_true(lake.uniform, "tek derinlik profili")
	assert_eq(lake.zone_ids, PackedStringArray(["main"]), "tek bölge")
	assert_eq(lake.zone_at(Vector2(0, 0)), 0, "suyun bölgesi")
	assert_eq(lake.zone_at(Vector2(0, 9)), 0, "kıyıdaki karanın bölgesi")
	assert_eq(lake.zone_at(Vector2(500, 0)), -1, "ızgaranın dışı bölgesiz")
	assert_true(lake.is_walkable(Vector2(0, 60)), "dünya sınırı yok")


## Büyük gölün havzaları: her bölgenin kendi derinliği, havzaların birleştiği yerde yumuşak geçiş.
func test_basins_have_their_own_depth() -> void:
	var lake := content().lake("lake_v2")
	assert_true(not lake.uniform, "havzalar farklı derin")
	assert_between(lake.depth_at(Vector2(0, 0)), 3.0, 3.6, "iskele koyu bugünkü gibi ~3,5 m")
	assert_between(lake.depth_at(Vector2(-3.5, -14.5)), 7.0, 10.0, "derin orta")
	assert_true(lake.depth_at(Vector2(-17.5, -3.5)) <= 1.7, "sazlık sığ")
	assert_true(lake.depth_at(Vector2(14.0, -1.5)) <= 2.6, "nilüferli koy sığ")
	assert_eq(lake.max_depth, 10.0, "gölün en derini")
	# Kayalık burnun kıyısı dik: kıyıdan 2 m içeride 3 m'den derin; iskele koyunda değil.
	var rocky := _point_at_shore(lake, Vector2(14.0, -8.5), Vector2(12.0, -13.0), 2.0)
	var cove := _point_at_shore(lake, Vector2(0.0, 4.0), Vector2(0.0, 0.0), 2.0)
	assert_true(lake.depth_at(rocky) > 3.0, "kayalık burun dik (%.1f m)" % lake.depth_at(rocky))
	assert_true(lake.depth_at(cove) < 2.5, "iskele koyu yavaş derinleşir (%.1f m)" % lake.depth_at(cove))
	# Yumuşak geçiş: iskele koyundan derin ortaya 0,25 m adımlarla derinlik sıçramaz.
	var prev := lake.depth_at(Vector2(0, 0))
	var worst := 0.0
	for i in range(1, 61):
		var d := lake.depth_at(Vector2(0, 0).lerp(Vector2(-3.5, -14.5), i / 60.0))
		worst = maxf(worst, absf(d - prev))
		prev = d
	assert_true(worst < 0.8, "derinlik yumuşak değişir (en büyük adım %.2f m)" % worst)


## Bölgeler: suda havzanın bölgesi, karada en yakın suyunki; atış noktaları kendi bölgelerinde,
## derin orta kıyıya değmez (sandal bölgesi kıyıdan boat_from metre içeride başlar).
func test_zones() -> void:
	var db := content()
	var lake := db.lake("lake_v2")
	assert_eq(_zone_name(lake, Vector2(0, 0)), "dock_cove", "iskele koyu")
	assert_eq(_zone_name(lake, Vector2(0, 4)), "dock_cove", "iskelenin üstü")
	assert_eq(_zone_name(lake, Vector2(-8, -3.5)), "dock_cove", "bugünkü yan göl iskele koyunda kalır")
	assert_eq(_zone_name(lake, Vector2(-17.5, -3.5)), "reeds", "sazlık")
	assert_eq(_zone_name(lake, Vector2(14, -1.5)), "lily_cove", "nilüferli koy")
	assert_eq(_zone_name(lake, Vector2(-3.5, -14.5)), "deep_water", "derin orta")
	for z in db.zones_of("lake_v2"):
		for p: Vector2 in z["stands"]:
			assert_eq(_zone_name(lake, p), z["id"], "atış noktası kendi bölgesinde: %s" % z["id"])
		for p: Vector2 in z["buoys"]:
			assert_eq(_zone_name(lake, p), z["id"], "şamandıra kendi bölgesinde")
	var deep := lake.zone_index("deep_water")
	var near_shore := 0
	for i in lake.shore.size():
		if lake.zone_grid[i] == deep and lake.shore[i] < 4.0:
			near_shore += 1
	assert_eq(near_shore, 0, "derin orta kıyıdan 4 m içeride başlar")
	for k in lake.zone_ids.size():
		assert_true(lake.zone_bounds[k].size.x > 1.0, "bölgenin suyu var: " + lake.zone_ids[k])
		assert_eq(lake.zone_at(lake.zone_centers[k]) >= 0, true, "bölgenin merkezi ızgarada")


## Yürünebilen dünya: köy ve kıyılar; gölün kuzeyi ve ormanın derini değil (U biçimi).
func test_world_boundary() -> void:
	var lake := content().lake("lake_v2")
	assert_true(lake.is_walkable(Vector2(0, 4)), "iskele")
	assert_true(lake.is_walkable(Vector2(0, 10)), "köy")
	assert_true(not lake.is_walkable(Vector2(-3.5, -26.0)), "gölün kuzeyi orman")
	assert_true(not lake.is_walkable(Vector2(0, 20)), "dünyanın güneyi kapalı")
	assert_true(not lake.in_world(Vector2(-29.0, 9.0)), "kıyıdan 9 m öte orman")
	assert_true(not lake.is_walkable(Vector2(0, 0)), "suda yürünmez")


## Kıyı ızgarası önbelleği: önbellekten gelen ızgara yeni kurulanla bit bit aynı; gölün tanımı
## değişince yeniden kurulur ve eski önbellek silinir.
func test_cache_matches_fresh_build() -> void:
	var spot := content().spot("lake_v2").duplicate(true)
	spot["id"] = "cache_test"
	var fresh := LakeShape.from_spot(spot, false)
	assert_true(not fresh.from_cache, "önbelleksiz kurulum")
	LakeShape.from_spot(spot)
	var cached := LakeShape.from_spot(spot)
	assert_true(cached.from_cache, "ikinci kurulum önbellekten")
	assert_eq(cached.shore, fresh.shore, "kıyı uzaklığı aynı")
	assert_eq(cached.depth, fresh.depth, "derinlik aynı")
	assert_eq(cached.zone_grid, fresh.zone_grid, "bölgeler aynı")
	assert_eq(cached.zone_centers, fresh.zone_centers, "bölge merkezleri aynı")
	var basins: Array[Dictionary] = spot["basins"]
	basins[0]["radius"] = Vector2(9.5, 6.5)
	var changed := LakeShape.from_spot(spot)
	assert_true(not changed.from_cache, "tanımı değişen göl yeniden kurulur")
	var mine: Array[String] = []
	for file in DirAccess.get_files_at(LakeShape.CACHE_DIR):
		if file.begins_with("lake_cache_test_"):
			mine.append(file)
	assert_eq(mine.size(), 1, "aynı gölün eski önbelleği silinir")
	for file in mine:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(LakeShape.CACHE_DIR.path_join(file)))


static func _zone_name(lake: LakeShape, p: Vector2) -> String:
	var k := lake.zone_at(p)
	return lake.zone_ids[k] if k >= 0 else ""


## from'dan to'ya giden çizgide kıyıdan shore metre içerideki ilk nokta.
static func _point_at_shore(lake: LakeShape, from: Vector2, to: Vector2, shore: float) -> Vector2:
	for i in 401:
		var p := from.lerp(to, i / 400.0)
		if lake.shore_distance(p) >= shore:
			return p
	return to
