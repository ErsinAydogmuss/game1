extends BaseTest
## Spin (Dalga 3): basılı tutunca yem gelir, bırakınca durur; yırtıcı oynayan yemi fark edip
## peşine düşer ve dur-kalk ritminde saldırır (basılıysa kendiliğinden takılır, değilse VUR anı);
## uzun bekletilen yemden vazgeçer; otlu yerde bekleyen yem takılır; yem gelince atış biter.
## Yalnızca yırtıcılar doğar; aynı girdilerle her fps'te aynı sonuç.

const HZ := FishingRules.HZ
## Testlerin gölünde (home_lake) balıkçı (0, 4)'te; yem (0, -4)'e atılır.
const TARGET := Vector2(0, -4)
## Gölgeleri park etmek için yemin yolundan uzak, derin yerler.
const PARK := [Vector2(-10, -4), Vector2(-7, -5), Vector2(5.5, -2.5), Vector2(-9.5, -3.5)]
const PREDATORS: Array[String] = ["perch", "pike", "zander", "chub", "wels"]


func _spin_gear() -> GearStats:
	var items := { "rod": "rod_spin_light" }
	var none: Array[String] = []
	return GearStats.from_items(content(), items, none)


func _session(easy: bool = false, seed: int = 99) -> FishingSession:
	return FishingSession.new(content(), "home_lake", _spin_gear(), seed, easy, false)


func _spin(session: FishingSession) -> SpinTechnique:
	return session.technique as SpinTechnique


func _park_all(session: FishingSession, keep: FishShadow = null) -> void:
	var i := 0
	for s in session.sim.shadows:
		if s == keep:
			continue
		s.pos = PARK[i % PARK.size()]
		s.mode = FishShadow.Mode.PAUSE
		s.timer = 1_000_000
		i += 1


func _steps(session: FishingSession, count: int, log: Array[Dictionary] = []) -> void:
	for i in count:
		session.step()
		log.append_array(session.poll_events())


func _run_until(session: FishingSession, wanted: FishingSession.State, max_seconds: float,
		log: Array[Dictionary] = []) -> bool:
	for i in int(max_seconds * HZ):
		if session.state == wanted:
			return true
		session.step()
		log.append_array(session.poll_events())
	return session.state == wanted


static func _has(log: Array[Dictionary], type: String) -> bool:
	for e in log:
		if str(e["type"]) == type:
			return true
	return false


static func _first(log: Array[Dictionary], type: String) -> Dictionary:
	for e in log:
		if str(e["type"]) == type:
			return e
	return {}


## Yemi atar, bir yırtıcıyı yemin önüne (balıkçı tarafına), yeme bakacak şekilde koyar ve
## basılı tutarak peşine düşürür.
func _to_following(session: FishingSession) -> FishShadow:
	var fish := session.sim.shadows[0]
	_park_all(session, fish)
	assert_true(session.cast(TARGET), "atış")
	assert_true(_run_until(session, FishingSession.State.WAITING, 2.0), "yem suya düşer")
	fish.pos = session.bobber + Vector2(0, 1.6)
	fish.heading = Vector2(0, -1)
	fish.mode = FishShadow.Mode.PAUSE
	fish.timer = 1_000_000
	session.press()
	var log: Array[Dictionary] = []
	assert_true(_run_until(session, FishingSession.State.FOLLOWING, 6.0, log), "yırtıcı peşine düşer")
	assert_true(_has(log, "notice") and _has(log, "follow"), "fark etti ve izliyor")
	return fish


func test_spin_session_and_only_predators() -> void:
	var session := _session()
	assert_true(session.technique is SpinTechnique, "spin kamışıyla teknik spin")
	assert_eq(session.action_kind(), "cast", "boşta atış")
	for seed_value: int in [1, 7, 99, 1234]:
		var s := FishingSession.new(content(), "big_lake", _spin_gear(), seed_value, false, false)
		for fish in s.sim.shadows:
			assert_true(fish.fish_id in PREDATORS, "spinle yalnızca yırtıcı doğar: " + fish.fish_id)


func test_holding_brings_the_lure_in() -> void:
	var session := _session()
	_park_all(session)
	assert_true(session.cast(TARGET), "atış")
	assert_true(_run_until(session, FishingSession.State.WAITING, 2.0), "yem suya düşer")
	assert_eq(session.action_kind(), "reel", "beklerken eylem: sar (basılı tut)")
	var start := session.bobber
	_steps(session, HZ)
	assert_eq(session.bobber, start, "basılmazsa yem durur")
	session.press()
	_steps(session, HZ)
	var moved := start.distance_to(session.bobber)
	assert_between(moved, 0.75, 0.85, "1 sn basılı: yem ~0,8 m gelir (%.2f)" % moved)
	assert_true(session.bobber.distance_to(session.angler) < start.distance_to(session.angler), "yem balıkçıya gelir")
	session.release()
	var stopped := session.bobber
	_steps(session, HZ)
	assert_eq(session.bobber, stopped, "bırakınca durur")
	session.press()
	var log: Array[Dictionary] = []
	assert_true(_run_until(session, FishingSession.State.RETRIEVING, 15.0, log), "yem gelince atış biter")
	assert_eq(str(_first(log, "retrieve").get("reason", "")), "home", "neden: yem geldi")
	assert_true(_run_until(session, FishingSession.State.IDLE, 2.0), "boşa döner")


func test_resting_lure_is_not_noticed() -> void:
	var session := _session()
	var fish := session.sim.shadows[0]
	_park_all(session, fish)
	assert_true(session.cast(TARGET), "atış")
	assert_true(_run_until(session, FishingSession.State.WAITING, 2.0), "yem suda")
	fish.pos = session.bobber + Vector2(0, 1.6)
	fish.heading = Vector2(0, -1)
	fish.mode = FishShadow.Mode.PAUSE
	fish.timer = 1_000_000
	var log: Array[Dictionary] = []
	_steps(session, 2 * HZ, log)
	assert_true(not _has(log, "notice"), "duran yemi fark etmez")
	session.press()
	_steps(session, 2, log)
	assert_true(_has(log, "notice"), "oynayan yemi hemen fark eder")


func test_stop_go_rhythm_strikes() -> void:
	for seed_value: int in [99, 5, 77, 2024]:
		var session := _session(false, seed_value)
		_to_following(session)
		var spin := _spin(session)
		# Kesintisiz çekişin zarı olmasın: yalnızca ritim değişimleri sayılsın.
		spin.steady_ppm = 0
		var log: Array[Dictionary] = []
		_steps(session, int(0.7 * HZ), log)
		var changes := 0
		while changes < spin.sure_after and session.state == FishingSession.State.FOLLOWING:
			if session.holding:
				session.release()
			else:
				session.press()
			changes += 1
			log.append_array(session.poll_events())
			_steps(session, int(0.3 * HZ), log)
		var strike := _first(log, "strike")
		assert_true(not strike.is_empty(), "seed %d: dur-kalk %d değişimde saldırı getirir" % [seed_value, changes])
		if strike.is_empty():
			continue
		if bool(strike["auto"]):
			assert_true(session.state == FishingSession.State.FIGHTING or _has(log, "hook"), "basılıyken kendiliğinden takılır")
		else:
			assert_eq(session.state, FishingSession.State.BITING, "bırakılıyken VUR anı")
			session.press()
			assert_eq(session.state, FishingSession.State.FIGHTING, "VUR ile takılır")


func test_strike_while_released_needs_a_tap() -> void:
	var session := _session()
	_to_following(session)
	var spin := _spin(session)
	spin.stop_ppm = Dice.PPM
	spin.steady_ppm = 0
	_steps(session, int(0.7 * HZ))
	session.release()
	var log := session.poll_events()
	var strike := _first(log, "strike")
	assert_true(not strike.is_empty() and not bool(strike["auto"]), "duruşta saldırır, kendiliğinden takılmaz")
	assert_eq(session.state, FishingSession.State.BITING, "VUR anı açık")
	assert_eq(session.action_kind(), "hook", "eylem: VUR")
	assert_eq(session.window, spin.rig.window_steps, "pencere 0,6 sn")
	var lost: Array[Dictionary] = []
	assert_true(_run_until(session, FishingSession.State.LOST, 1.0, lost), "dokunulmazsa kaçar")
	assert_eq(str(_first(lost, "lost").get("reason", "")), "missed", "neden: kaçırıldı")


func test_strike_while_holding_hooks_by_itself() -> void:
	var session := _session()
	_to_following(session)
	var spin := _spin(session)
	spin.go_ppm = Dice.PPM
	spin.stop_ppm = 0
	spin.steady_ppm = 0
	_steps(session, int(0.7 * HZ))
	session.release()
	_steps(session, int(0.3 * HZ))
	session.press()
	var log := session.poll_events()
	var strike := _first(log, "strike")
	assert_true(not strike.is_empty() and bool(strike["auto"]), "kalkışta saldırır, basılı: kendiliğinden")
	assert_true(_has(log, "hook"), "takıldı")
	assert_eq(session.state, FishingSession.State.FIGHTING, "çekişme")
	assert_true(session.reel.holding, "parmak basılı: sarar")


func test_easy_mode_window_is_longer() -> void:
	var session := _session(true)
	_to_following(session)
	var spin := _spin(session)
	spin.stop_ppm = Dice.PPM
	spin.steady_ppm = 0
	_steps(session, int(0.7 * HZ))
	session.release()
	assert_eq(session.state, FishingSession.State.BITING, "VUR anı")
	assert_eq(session.window, spin.rig.window_easy_steps, "Kolay modda pencere 1 sn")


func test_resting_too_long_loses_the_fish() -> void:
	var session := _session()
	var fish := _to_following(session)
	var spin := _spin(session)
	spin.stop_ppm = 0
	spin.steady_ppm = 0
	_steps(session, int(0.7 * HZ))
	session.release()
	var log: Array[Dictionary] = []
	_steps(session, int(3.2 * HZ), log)
	assert_true(_has(log, "turn_away"), "3 sn bekleyen yemden vazgeçer")
	assert_eq(session.state, FishingSession.State.WAITING, "yem suda kalır")
	assert_true(fish.bored, "bu yemi yeniden fark etmez")


func test_lure_snags_in_the_weeds() -> void:
	var db := content()
	var session := FishingSession.new(db, "big_lake", _spin_gear(), 31, false, false)
	var stand: Vector2 = (db.zone("big_lake", "reeds")["stands"] as Array)[0]
	session.relocate(stand)
	session.poll_events()
	var cast_ok := false
	for dir: Vector2 in [Vector2(0, -1), Vector2(1, -1).normalized(), Vector2(-1, -1).normalized(), Vector2(0, 1)]:
		if session.cast(stand + dir * 6.0):
			cast_ok = true
			break
	assert_true(cast_ok, "sazlıkta atış")
	assert_true(_run_until(session, FishingSession.State.WAITING, 2.0), "yem suda")
	assert_eq(session.zone_def(session.lake.zone_at(session.bobber)).get("snag_s", 0.0), 4.0, "yem sazlıkta")
	var log: Array[Dictionary] = []
	_steps(session, int(3.9 * HZ), log)
	assert_true(not _has(log, "snag"), "4 sn dolmadan takılmaz")
	_steps(session, int(0.2 * HZ), log)
	assert_true(_has(log, "snag"), "sazlıkta 4 sn bekleyen yem takılır")
	assert_eq(str(_first(log, "retrieve").get("reason", "")), "snag", "geri sarma nedeni")
	assert_eq(session.state, FishingSession.State.RETRIEVING, "geri sarılıyor")
	assert_true(not _run_until(session, FishingSession.State.IDLE, 2.3), "kurtarmak uzun sürer (2,5 sn)")
	assert_true(_run_until(session, FishingSession.State.IDLE, 0.5), "sonra boşa döner")


func test_switching_to_spin_respawns_predators() -> void:
	var db := content()
	var session := FishingSession.new(db, "big_lake", GearStats.starter(db), 1, false, false)
	session.set_gear(_spin_gear())
	assert_true(session.technique is SpinTechnique, "boştayken teknik değişir")
	for fish in session.sim.shadows:
		assert_true(fish.fish_id in PREDATORS, "yeni gölgeler yırtıcı: " + fish.fish_id)
	assert_true(session.sim.rig == db.rules.technique("spin"), "gölgeler spinin profilini okur")


## Aynı girdiler (saniyeye göre: 1 sn sar, 0,5 sn bırak) her fps'te aynı olayları verir.
func test_same_result_at_any_fps() -> void:
	var logs: Array[PackedStringArray] = []
	for fps: int in [30, 60, 120]:
		var session := _session(false, 4321)
		var log := PackedStringArray()
		var targets := [Vector2(0, -4), Vector2(-3, -3), Vector2(3, -2), Vector2(1, -5)]
		var next_target := 0
		var acted_at := -1
		while session.steps < 60 * HZ:
			session.advance(1.0 / fps)
			for e in session.poll_events():
				log.append("%s@%d" % [e["type"], e["step"]])
			if session.steps == 0 or session.steps % 2 != 0 or session.steps == acted_at:
				continue
			acted_at = session.steps
			var t := session.steps % (90)
			match session.state:
				FishingSession.State.IDLE:
					session.cast(targets[next_target % targets.size()])
					next_target += 1
				FishingSession.State.WAITING, FishingSession.State.FOLLOWING:
					if t < 60 and not session.holding:
						session.press()
					elif t >= 60 and session.holding:
						session.release()
				FishingSession.State.BITING:
					session.press()
				FishingSession.State.FIGHTING:
					var calm := session.reel.phase == ReelModel.Phase.CALM
					if calm and not session.holding:
						session.press()
					elif not calm and session.holding:
						session.release()
				FishingSession.State.CAUGHT:
					session.acknowledge()
		logs.append(log)
	assert_true(logs[0].size() > 10, "olaylar var (%d)" % logs[0].size())
	assert_eq(logs[1], logs[0], "60 fps = 30 fps")
	assert_eq(logs[2], logs[0], "120 fps = 30 fps")


func test_random_input_never_gets_stuck() -> void:
	var lake := content().lake("home_lake")
	for run in 6:
		var session := _session(run % 2 == 1, 2000 + run)
		var rng := RandomNumberGenerator.new()
		rng.seed = 777 + run
		var since_change := 0
		var last_state := session.state
		var casts := 0
		var problem := ""
		for i in 90 * HZ:
			match session.state:
				FishingSession.State.IDLE:
					if rng.randf() < 0.05 and session.cast(Vector2(rng.randf_range(-12, 8), rng.randf_range(-10, 2))):
						casts += 1
				FishingSession.State.CAUGHT:
					if rng.randf() < 0.05:
						session.acknowledge()
				FishingSession.State.FIGHTING:
					# Çekişmede çoğunlukla basılı (yarı yarıya basan rastgele girdi iri bir turnayı
					# dakikalarca çeker: takılma değil, yalnızca yavaş).
					if rng.randf() < 0.06:
						session.press()
					if rng.randf() < 0.02:
						session.release()
				_:
					if rng.randf() < 0.03:
						session.press()
					if rng.randf() < 0.03:
						session.release()
			session.step()
			session.poll_events()
			if session.state != last_state:
				last_state = session.state
				since_change = 0
			else:
				since_change += 1
			var limits := {
				FishingSession.State.CASTING: 1.0, FishingSession.State.FOLLOWING: 12.0,
				FishingSession.State.BITING: 1.1, FishingSession.State.RETRIEVING: 2.6,
				FishingSession.State.LOST: 1.0,
			}
			if limits.has(session.state) and since_change > float(limits[session.state]) * HZ:
				problem = "%s durumunda takıldı" % session.state_name()
			if session.state in [FishingSession.State.WAITING, FishingSession.State.FOLLOWING, FishingSession.State.BITING]:
				if not lake.is_water(session.bobber) or lake.on_dock(session.bobber):
					problem = "yem suda değil: %s" % str(session.bobber)
				if session.state != FishingSession.State.WAITING and session.sim.approacher == null:
					problem = "izlemede ya da saldırıda balık yok"
			if session.state == FishingSession.State.FIGHTING and (session.reel == null or session.hooked == null):
				problem = "çekişmede model yok"
			if session.sim.shadows.size() > 4:
				problem = "4'ten çok gölge"
			for s in session.sim.shadows:
				if s.mode != FishShadow.Mode.HOOKED and not lake.is_water(s.pos):
					problem = "gölge karada: %s" % str(s.pos)
			if not problem.is_empty():
				break
		assert_true(problem.is_empty(), "deneme %d: %s" % [run, problem])
		assert_true(casts >= 3, "deneme %d: oyun ilerler (%d atış)" % [run, casts])
