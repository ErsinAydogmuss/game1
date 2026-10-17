extends BaseTest
## Kıyı yolu (ShorePath): sudan geçmez, koyu kısa yönden dolaşır, düz çizgi açıksa düz gider,
## engellerin çevresinden geçer, kapalı çitte durur (kilitli bölge).


func _home() -> LakeShape:
	return content().lake("home_lake")


## Yolun her parçası yürünebilir yerden geçer (0,1 m aralıkla).
func _walkable(lake: LakeShape, from: Vector2, points: PackedVector2Array) -> bool:
	var prev := from
	for p in points:
		var count := maxi(1, ceili(prev.distance_to(p) / 0.1))
		for i in count + 1:
			if not lake.is_walkable(prev.lerp(p, float(i) / count)):
				return false
		prev = p
	return true


func test_route_goes_around_the_water() -> void:
	var lake := _home()
	var path := ShorePath.new(lake)
	var from := Vector2(0, 9.5)
	var to := Vector2(0, -9.0)
	var route := path.route(from, to)
	assert_true(route.size() >= 2, "koyun öbür yakasına dolaşan yol (%d nokta)" % route.size())
	assert_true(_walkable(lake, from, route), "yol sudan geçmez")
	assert_true(route.size() > 0 and route[route.size() - 1].distance_to(to) < 0.01, "hedefe varır")
	var length := ShorePath.length_of(from, route)
	assert_between(length, 18.5, 45.0, "yol uzunluğu makul (%.1f m)" % length)


func test_route_takes_the_short_side() -> void:
	var lake := _home()
	var path := ShorePath.new(lake)
	var from := Vector2(10.5, 0.0)
	var to := Vector2(6.0, -8.0)
	var route := path.route(from, to)
	var west := 0.0
	for p in route:
		west = minf(west, p.x)
	assert_true(not route.is_empty() and west > -2.0, "doğudan dolaşır, batıya gitmez (en batı x %.1f)" % west)
	assert_true(_walkable(lake, from, route), "yol sudan geçmez")


func test_straight_line_when_clear() -> void:
	var path := ShorePath.new(_home())
	var route := path.route(Vector2(0, 9.5), Vector2(3, 10.5))
	assert_eq(route, PackedVector2Array([Vector2(3, 10.5)]), "açık yolda düz yürür")


## Suya dokunulursa en yakın yürünebilir yere (burada iskelenin ucu).
func test_water_target_ends_on_the_nearest_walkable_spot() -> void:
	var lake := _home()
	var path := ShorePath.new(lake)
	var route := path.route(Vector2(0, 9.5), Vector2(0, 0))
	assert_true(not route.is_empty(), "yol var")
	if route.is_empty():
		return
	var end := route[route.size() - 1]
	assert_true(lake.on_dock(end), "iskelenin ucunda biter: %s" % end)
	assert_true(end.distance_to(Vector2(0, 3.5)) < 0.8, "iskelenin suya bakan ucu")


func test_obstacles_are_avoided() -> void:
	var lake := _home()
	var path := ShorePath.new(lake)
	var circles: Array[Vector3] = [Vector3(1.5, 10.0, 0.8)]
	path.set_obstacles(circles)
	var from := Vector2(0, 10)
	var route := path.route(from, Vector2(3, 10))
	assert_true(route.size() >= 2, "engelin çevresinden dolaşır")
	var prev := from
	var hit := false
	for p in route:
		for i in 21:
			hit = hit or prev.lerp(p, i / 20.0).distance_to(Vector2(1.5, 10.0)) < 0.8
		prev = p
	assert_true(not hit, "engelin içinden geçmez")


## Büyük gölde çitler: kapalıyken kilitli bölgenin atış noktasına varılmaz, açılınca varılır.
func test_gates_close_locked_zones() -> void:
	var db := content()
	var lake := db.lake("big_lake")
	var path := ShorePath.new(lake, lake.world_rect)
	var start := Vector2(0, 9.0)
	for closed: bool in [true, false]:
		for z in db.zones_of("big_lake"):
			var gates: Array = z["gates"]
			for i in gates.size():
				var g: PackedVector2Array = gates[i]
				path.set_gate("%s_%d" % [z["id"], i], g[0], g[1], closed)
		for z in db.zones_of("big_lake"):
			var gated := not (z["gates"] as Array).is_empty()
			for stand: Vector2 in z["stands"]:
				var route := path.route(start, stand)
				var end: Vector2 = route[route.size() - 1] if not route.is_empty() else start
				var reached := end.distance_to(stand) < 0.01
				assert_eq(reached, not (closed and gated), "%s: çit %s" % [z["id"], "kapalı" if closed else "açık"])
				if reached:
					assert_true(_walkable(lake, start, route), "%s yolu sudan geçmez" % z["id"])
	assert_true(path.gate_closed("lily_cove_0") == false, "çit açıldı")


## Kapalı çiti kesen adım (düz yürüyüş, klavye) geçilmez; açık çit ya da çiti kesmeyen adım serbest.
## Değişmeyen çit ızgarayı yeniden kurmaz.
func test_steps_do_not_cross_closed_gates() -> void:
	var db := content()
	var lake := db.lake("big_lake")
	var path := ShorePath.new(lake, lake.world_rect)
	var gate: PackedVector2Array = (db.zone("big_lake", "lily_cove")["gates"] as Array)[0]
	var mid := (gate[0] + gate[1]) * 0.5
	var across := (gate[1] - gate[0]).orthogonal().normalized()
	assert_true(path.set_gate("lily_cove_0", gate[0], gate[1], true), "çit kuruldu")
	assert_true(not path.set_gate("lily_cove_0", gate[0], gate[1], true), "değişmeyen çit: yeniden kurulmaz")
	assert_true(path.crosses_closed_gate(mid - across * 0.5, mid + across * 0.5), "kapalı çiti kesen adım")
	assert_true(not path.crosses_closed_gate(mid - across * 1.5, mid - across * 0.5), "çiti kesmeyen adım")
	path.set_gate("lily_cove_0", gate[0], gate[1], false)
	assert_true(not path.crosses_closed_gate(mid - across * 0.5, mid + across * 0.5), "açık çitten geçilir")
