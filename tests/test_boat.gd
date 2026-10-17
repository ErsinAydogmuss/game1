extends BaseTest
## Sandal (docs/gdd.md §10.1): şamandıraların yanındaki bağlama noktası derin ortanın suyunda;
## sandaldan her yöne atılır; balık sandala çekilip tutulur; dolaşan gölgeler sandalın altına girmez;
## sandal bölgesi sandal ister.

const SPOT := "big_lake"
const HZ := FishingRules.HZ


## Sandalın şamandıradaki yeri (LakeScene.moor_boat gibi).
func _moor(buoy: Vector2) -> Vector2:
	return buoy + LakeScene.BUOY_MOOR


func _boat_session(at: Vector2, seed_value: int = 5) -> FishingSession:
	var db := content()
	var session := FishingSession.new(db, SPOT, GearStats.starter(db), seed_value, false, false, -1,
			PackedStringArray(["deep_water"]))
	session.relocate(at)
	session.poll_events()
	return session


func test_moorings_are_in_deep_water() -> void:
	var db := content()
	var lake := db.lake(SPOT)
	var deep := lake.zone_index("deep_water")
	for p: Vector2 in db.zone(SPOT, "deep_water")["buoys"]:
		var at := _moor(p)
		assert_eq(lake.zone_at(at), deep, "sandal derin ortada: %s" % at)
		assert_true(lake.shore_distance(at) >= 3.0, "kıyıdan uzak (%.1f m)" % lake.shore_distance(at))


## Sandaldan sekiz yöne 6 m'ye atılır: şamandıra suya, menzilin içine düşer.
func test_cast_in_every_direction() -> void:
	var db := content()
	for p: Vector2 in db.zone(SPOT, "deep_water")["buoys"]:
		var at := _moor(p)
		for k in 8:
			var session := _boat_session(at)
			var target := at + Vector2.from_angle(TAU * k / 8.0) * 6.0
			assert_true(session.cast(target), "%s'ten %d. yöne atılır" % [at, k])
			assert_true(session.bobber.distance_to(at) <= session.range_m() + 0.01, "menzilin içinde")


## Sandaldan atılan şamandıraya gelen balık takılır, sandala çekilip tutulur.
func test_fight_from_the_boat() -> void:
	var db := content()
	var at := _moor(db.zone(SPOT, "deep_water")["buoys"][1])
	var session := _boat_session(at, 11)
	var bobber := at + Vector2(0, -5.0)
	var s := session.sim.shadows[0]
	for o in session.sim.shadows:
		if o != s:
			o.mode = FishShadow.Mode.PAUSE
			o.timer = 1_000_000
			o.pos = at + Vector2(8.0, 3.0)
	s.pos = bobber + Vector2(0, -2.0)
	s.heading = Vector2(0, 1)
	s.mode = FishShadow.Mode.PAUSE
	s.timer = 1_000_000
	assert_true(session.cast(bobber), "atılır")
	var bit := false
	for i in 40 * HZ:
		session.step()
		if session.state == FishingSession.State.BITING:
			bit = true
			break
	assert_true(bit, "balık ısırır")
	session.press()
	assert_eq(session.state, FishingSession.State.FIGHTING, "takılır")
	# İyi oyuncu gibi: uyarıda bırakır, patlama bitince yeniden basar.
	for i in 90 * HZ:
		if session.state != FishingSession.State.FIGHTING:
			break
		var reel := session.reel
		if reel.thrashing() or reel.in_red:
			session.release()
		else:
			session.press()
		session.step()
		assert_true(db.lake(SPOT).is_water(session.fight_point()), "balık hep suda")
	assert_eq(session.state, FishingSession.State.CAUGHT, "sandala çekilip tutulur (%s)" % session.state_name())


## Dolaşan gölgeler sandalın altına girmez (şamandıraya yaklaşmayan, kaçmayan gölge).
func test_shadows_keep_clear_of_the_boat() -> void:
	var db := content()
	var at := _moor(db.zone(SPOT, "deep_water")["buoys"][0])
	var closest := INF
	var samples := 0
	for seed_value in 6:
		var session := _boat_session(at, 30 + seed_value)
		for i in 60 * HZ:
			session.sim.step(at, Vector2.ZERO, false, 0)
			if i % 30 != 0:
				continue
			for s in session.sim.shadows:
				if s.mode == FishShadow.Mode.FLEE:
					continue
				samples += 1
				closest = minf(closest, s.pos.distance_to(at))
	assert_true(samples > 200, "örnek (%d)" % samples)
	assert_true(closest >= ShadowSim.BOAT_CLEAR * 0.55, "gölge sandala en çok %.2f m yaklaştı" % closest)


## Sandal bölgesi sandal ister; sandalla açılır, karadan avlanılmaz.
func test_boat_zone_needs_the_boat() -> void:
	var db := content()
	var save := SaveData.create_new(0)
	save.xp = db.rank_xp[8]
	var deep := db.zone(SPOT, "deep_water")
	assert_true(not Zones.unlocked(db, save, deep), "rütbe 9 ama sandal yok: kapalı")
	assert_eq(str(Zones.lock_reason(db, save, deep).get("key", "")), "UI_ZONE_LOCKED_BOAT", "nedeni sandal")
	save.coins = 100000
	assert_eq(Economy.buy_block(db, save, Zones.BOAT), "", "sandal satılır (rütbe 9)")
	assert_true(Economy.buy(db, save, Zones.BOAT), "satın alınır")
	assert_true(Zones.unlocked(db, save, deep), "sandalla açık")
	assert_eq(Zones.open_ids(db, save, SPOT, true), PackedStringArray(["deep_water"]), "sandalda yalnızca derin orta")
	assert_true(not "deep_water" in Zones.open_ids(db, save, SPOT), "karadan derin ortada gölge yok")
