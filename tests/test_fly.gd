extends BaseTest
## Sinek (Dalga 3): yalnızca akıntılı suda (dere ağzı). Sinek akıntıyla sürüklenir; alabalık altına
## gelir, bir süre bekler (bu sırada dokunmak kaçırır), halka çıkarır (VUR penceresi). Sinek durgun
## suya, kıyıya ya da en uzun sürüklenmenin sonuna gelince kendiliğinden döner. Aynı girdilerle her
## fps'te aynı sonuç.

const HZ := FishingRules.HZ
const SPOT := "big_lake"


func _fly_gear(fly: String = "fly_dry") -> GearStats:
	var items := { "rod": "rod_fly_1", "fly": fly }
	var owned: Array[String] = [fly]
	return GearStats.from_items(content(), items, owned)


static func _stand() -> Vector2:
	return (content().zone(SPOT, "stream_mouth")["stands"] as Array)[0]


## Dere ağzının atış noktasında bir sinek oturumu (bütün bölgeler açık).
func _session(seed: int = 7, easy: bool = false) -> FishingSession:
	var session := FishingSession.new(content(), SPOT, _fly_gear(), seed, easy, false)
	session.relocate(_stand())
	session.poll_events()
	return session


func _park_all(session: FishingSession, keep: FishShadow = null) -> void:
	for s in session.sim.shadows:
		if s == keep:
			continue
		s.pos = _stand() + Vector2(12.0, 6.0)
		s.mode = FishShadow.Mode.PAUSE
		s.timer = 1_000_000


func _run_until(session: FishingSession, wanted: FishingSession.State, max_seconds: float,
		log: Array[Dictionary] = []) -> bool:
	for i in int(max_seconds * HZ):
		if session.state == wanted:
			return true
		session.step()
		log.append_array(session.poll_events())
	return session.state == wanted


static func _first(log: Array[Dictionary], type: String) -> Dictionary:
	for e in log:
		if str(e["type"]) == type:
			return e
	return {}


## Akıntının güçlü olduğu suya atar (atış noktasından derenin içine, akıntıya karşı yönlere bakar).
func _cast_on_current(session: FishingSession) -> bool:
	var up := -session.lake.strongest_flow().normalized()
	for k in 13:
		var dir := up.rotated(deg_to_rad(15.0 * ((k + 1) >> 1)) * (1.0 if k % 2 == 1 else -1.0))
		for d: float in [6.0, 5.0, 7.0, 4.0, 8.0, 9.0]:
			var target := _stand() + dir * d
			if session.lake.is_water(target) and session.lake.flow_at(target).length() > 0.6 \
					and session.cast(target):
				return _run_until(session, FishingSession.State.WAITING, 3.0)
	return false


func test_fly_profile_and_species() -> void:
	var db := content()
	var session := _session()
	assert_true(session.technique is FlyTechnique, "sinek kamışıyla teknik sinek")
	var rig := session.technique.rig
	assert_eq(rig.window_steps, int(0.5 * HZ), "halka penceresi 0,5 sn")
	assert_eq(rig.window_easy_steps, int(0.9 * HZ), "Kolay modda 0,9 sn")
	var stream := Zones.place(db, SPOT, "stream_mouth")
	var fly := CatchOdds.species_ppm(db, stream, { "technique": "fly" })
	assert_true(int(fly.get("trout", 0)) > int(fly.get("chub", 0)), "dere ağzında sinekle en çok alabalık: %s" % str(fly))
	assert_true(int(fly.get("brook_trout", 0)) > 0, "dere alabalığı da gelir")
	var float_odds := CatchOdds.species_ppm(db, stream, { "technique": "float" })
	assert_true(not float_odds.has("trout") and not float_odds.has("brook_trout"), "şamandırayla alabalık gelmez")


func test_fly_only_in_flowing_water() -> void:
	var db := content()
	for z in db.zones_of(SPOT):
		var flowing := not (z["current"] as Vector2).is_zero_approx()
		assert_eq(CatchOdds.allows(z, "fly"), flowing, "%s: sinek yalnızca akıntılı bölgede" % z["id"])
	assert_true(Economy.technique_allowed(db, SPOT, "stream_mouth", "fly"), "dere ağzında sinek")
	assert_true(not Economy.technique_allowed(db, SPOT, "dock_cove", "fly"), "iskele koyunda sinek yok")


func test_fly_drifts_with_the_current() -> void:
	var session := _session()
	_park_all(session)
	assert_true(_cast_on_current(session), "akıntıya atış")
	var start := session.bobber
	var flow := session.lake.flow_at(start)
	for i in HZ:
		session.step()
	session.poll_events()
	var moved := session.bobber - start
	assert_true(moved.length() > 0.3, "sinek sürüklenir (%.2f m)" % moved.length())
	assert_true(moved.normalized().dot(flow.normalized()) > 0.8, "akıntının yönünde")


func test_fly_comes_back_by_itself() -> void:
	var session := _session()
	_park_all(session)
	assert_true(_cast_on_current(session), "akıntıya atış")
	var log: Array[Dictionary] = []
	assert_true(_run_until(session, FishingSession.State.RETRIEVING, 16.5, log), "sinek kendiliğinden döner")
	assert_eq(str(_first(log, "retrieve").get("reason", "")), "drift", "nedeni sürüklenme")
	assert_true(_run_until(session, FishingSession.State.IDLE, 2.0), "sonra boşa döner")


## Hiç akmayan suya düşen sinek kımıldamaz, durgun sudaki süre dolunca döner ("still": main oyuncuya
## akıntıya atmasını söyler).
func test_fly_on_still_water_comes_back_soon() -> void:
	var session := _session()
	_park_all(session)
	var cast := false
	for k in 24:
		var dir := Vector2.RIGHT.rotated(deg_to_rad(15.0 * k))
		for d: float in [5.0, 6.0, 7.0, 4.0]:
			var target := _stand() + dir * d
			if not cast and session.lake.is_water(target) and session.lake.shore_distance(target) > 0.8 \
					and session.lake.flow_at(target).length() < 0.01 and session.cast(target):
				cast = _run_until(session, FishingSession.State.WAITING, 3.0)
	assert_true(cast, "durgun suya atış")
	var start := session.bobber
	var log: Array[Dictionary] = []
	var still_s := float((session.technique as FlyTechnique).still_steps) / HZ
	assert_true(_run_until(session, FishingSession.State.RETRIEVING, still_s + 0.2, log), "durgun suda kısa sürede döner")
	assert_true(session.bobber.distance_to(start) < 0.05, "sinek kımıldamadı")
	assert_eq(str(_first(log, "retrieve").get("reason", "")), "still", "nedeni durgun su")


## Alabalık sineği altından fark eder, altına gelir; halka çıkınca dokunmak takar.
func test_trout_rises_then_strike() -> void:
	var session := _session()
	var fish := _trout(session)
	assert_true(_cast_on_current(session), "akıntıya atış")
	_put_below(session, fish)
	var log: Array[Dictionary] = []
	assert_true(_run_until(session, FishingSession.State.NIBBLING, 8.0, log), "alabalık sineğin altına gelir")
	assert_true(_run_until(session, FishingSession.State.BITING, 2.0, log), "halka çıkar")
	assert_true(not _first(log, "rise").is_empty(), "halka olayı")
	session.press()
	assert_eq(session.state, FishingSession.State.FIGHTING, "halkada dokununca takılır")


func test_touch_before_the_rise_scares_the_trout() -> void:
	var session := _session()
	var fish := _trout(session)
	assert_true(_cast_on_current(session), "akıntıya atış")
	_put_below(session, fish)
	assert_true(_run_until(session, FishingSession.State.NIBBLING, 8.0), "alabalık sineğin altında")
	session.press()
	assert_eq(session.state, FishingSession.State.LOST, "halkadan önce dokunmak kaçırır")
	assert_eq(session.last_loss, "early", "erken")


func test_same_result_at_any_fps() -> void:
	var results: Array[String] = []
	for fps: int in [30, 60, 120]:
		var session := _session(21)
		var fish := _trout(session)
		assert_true(_cast_on_current(session), "akıntıya atış")
		_put_below(session, fish)
		var log: Array[Dictionary] = []
		var t := 0.0
		while t < 9.0:
			session.advance(1.0 / fps)
			t += 1.0 / fps
			if session.state == FishingSession.State.BITING:
				session.press()
			log.append_array(session.poll_events())
		var types := PackedStringArray()
		for e in log:
			types.append("%s@%d" % [e["type"], int(e["step"])])
		results.append(",".join(types))
	assert_eq(results[1], results[0], "30 ve 60 fps aynı")
	assert_eq(results[2], results[0], "60 ve 120 fps aynı")


func test_random_input_never_gets_stuck() -> void:
	for seed_value in 4:
		var session := _session(300 + seed_value)
		var rng := RandomNumberGenerator.new()
		rng.seed = 900 + seed_value
		var casts := 0
		for i in 120 * HZ:
			if session.state == FishingSession.State.IDLE and rng.randi() % 30 == 0:
				if session.cast(_stand() + Vector2(rng.randf_range(-8, 8), rng.randf_range(-8, 8))):
					casts += 1
			elif rng.randi() % 40 == 0:
				session.press()
			elif rng.randi() % 40 == 0:
				session.release()
			if session.state == FishingSession.State.CAUGHT:
				session.acknowledge()
			session.step()
			session.poll_events()
		assert_true(casts >= 3, "seed %d: atışlar sürer (%d)" % [seed_value, casts])


## Alabalığı seçer (yoksa ilk gölgeyi alabalığa çevirir) ve ötekileri uzağa park eder.
func _trout(session: FishingSession) -> FishShadow:
	var fish: FishShadow = null
	for s in session.sim.shadows:
		if s.fish_id == "trout":
			fish = s
			break
	if fish == null:
		fish = session.sim.shadows[0]
		var db := content()
		fish.fish_id = "trout"
		fish.fish_index = db.fish_index("trout")
		fish.rarity = db.rarity_index("rare")
	_park_all(session, fish)
	return fish


## Balığı sineğin akıntı aşağısına, sineğe bakar koyar (sinek ona doğru gelir).
func _put_below(session: FishingSession, fish: FishShadow) -> void:
	var down := session.lake.flow_at(session.bobber).normalized()
	fish.pos = session.bobber + down * 1.6
	fish.heading = -down
	fish.mode = FishShadow.Mode.PAUSE
	fish.timer = 1_000_000
