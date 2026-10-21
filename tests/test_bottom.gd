extends BaseTest
## Dip (Dalga 3): dokunulan yöne menzilin sonuna (avlanılan bölgenin suyunda) atılır; balık her
## yönden sezer ve toplanır; zil tek tük çalar (koklama: dokunmak kaçırır), sonra durmadan çalar
## (koşu): vuruş penceresinde dokunulur. Yem sepeti toplanmayı hızlandırır. Yalnızca dipte gelen
## türler doğar; aynı girdilerle her fps'te aynı sonuç.

const HZ := FishingRules.HZ
## Testlerin gölünde (home_lake) balıkçı (0, 4)'te; dip kuzeye (−z) atılır.
const TARGET := Vector2(0, -4)
const PARK := [Vector2(-10, -4), Vector2(-7, -5), Vector2(5.5, -2.5), Vector2(-9.5, -3.5)]


func _bottom_gear(rig: String = "sinker") -> GearStats:
	var items := { "rod": "rod_carp_1", "rig": rig }
	var owned: Array[String] = [rig]
	return GearStats.from_items(content(), items, owned)


func _session(easy: bool = false, seed: int = 99, rig: String = "sinker") -> FishingSession:
	return FishingSession.new(content(), "home_lake", _bottom_gear(rig), seed, easy, false)


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


static func _count(log: Array[Dictionary], type: String) -> int:
	var n := 0
	for e in log:
		if str(e["type"]) == type:
			n += 1
	return n


## Atar, bir balığı takımın yanına koyar (her yönden sezer) ve koklamaya kadar ilerletir.
func _to_sniffing(session: FishingSession, log: Array[Dictionary]) -> FishShadow:
	var fish := session.sim.shadows[0]
	_park_all(session, fish)
	assert_true(session.cast(TARGET), "atış")
	assert_true(_run_until(session, FishingSession.State.WAITING, 3.0), "kurşun suya düşer")
	# Balık takımla balıkçının arasında, takıma sırtı dönük (balıkçıya bakar): dipte her yönden sezer.
	fish.pos = session.bobber + Vector2(0.4, 1.8)
	fish.heading = Vector2(0, 1)
	fish.mode = FishShadow.Mode.PAUSE
	fish.timer = 1_000_000
	assert_true(_run_until(session, FishingSession.State.NIBBLING, 12.0, log), "balık gelir, koklar")
	return fish


func test_bottom_profile_and_species() -> void:
	var session := _session()
	assert_true(session.technique is BottomTechnique, "dip kamışıyla teknik dip")
	var rig := session.technique.rig
	assert_eq(rig.notice_front, 4.5, "önde 4,5 m")
	assert_eq(rig.notice_side, 4.5, "her yönden 4,5 m")
	assert_eq(rig.window_steps, int(2.5 * HZ), "koşu penceresi 2,5 sn")
	assert_eq(rig.window_easy_steps, int(3.5 * HZ), "Kolay modda 3,5 sn")
	assert_eq(rig.nibble_weights[0], 0, "en az bir koklama")
	assert_true(session.technique.uses_bait(), "dip yem kullanır")
	for seed_value: int in [1, 7, 99, 1234]:
		var s := FishingSession.new(content(), "big_lake", _bottom_gear(), seed_value, false, false)
		for fish in s.sim.shadows:
			assert_true(content().affinity(fish.fish_id, "bottom") > 0.0, "dipte gelmeyen tür doğmaz: " + fish.fish_id)


## Aynalı sazan yalnızca dipte: şamandırada sazlığın oranında yok, dipte var.
func test_mirror_carp_only_on_the_bottom() -> void:
	var db := content()
	var reeds := Zones.place(db, "big_lake", "reeds")
	var by_float := CatchOdds.species_ppm(db, reeds, { "technique": "float" })
	var by_bottom := CatchOdds.species_ppm(db, reeds, { "technique": "bottom" })
	assert_true(not by_float.has("mirror_carp"), "şamandırada aynalı sazan yok")
	assert_true(int(by_bottom.get("mirror_carp", 0)) > 0, "dipte aynalı sazan var")
	assert_true(not by_bottom.has("silverside"), "gümüş balığı dipte gelmez")


func test_cast_goes_far_and_stays_in_the_zone() -> void:
	var session := _session()
	_park_all(session)
	assert_true(session.cast(TARGET), "atış")
	var reach := session.angler.distance_to(session.bobber)
	assert_true(reach > TARGET.distance_to(session.angler) + 1.0, "dokunulan yerden öteye, menzilin sonuna (%.1f m)" % reach)
	assert_true(reach <= session.range_m() + 0.01, "menzili aşmaz")
	# Büyük göl: iskele koyundan kuzeye en uzağa atış derin ortaya (başka bölgeye) düşmez.
	var big := FishingSession.new(content(), "big_lake", _bottom_gear(), 5, false, false)
	assert_true(big.cast(big.angler + Vector2(0, -30)), "büyük gölde atış")
	assert_eq(big.lake.zone_at(big.bobber), big.zone(), "takım avlanılan bölgenin suyunda")
	assert_true(big.angler.distance_to(big.bobber) > 6.0, "yine de uzağa (%.1f m)" % big.angler.distance_to(big.bobber))


func test_sniffs_then_run_and_strike() -> void:
	for seed_value: int in [99, 5, 77, 2024]:
		var session := _session(false, seed_value)
		var log: Array[Dictionary] = []
		_to_sniffing(session, log)
		assert_eq(session.action_kind(), "wait", "koklarken eylem: bekle")
		assert_true(_run_until(session, FishingSession.State.BITING, 12.0, log), "seed %d: koşu gelir" % seed_value)
		var sniffs := _count(log, "sniff")
		assert_between(sniffs, 1, 3, "seed %d: 1–3 koklama (%d)" % [seed_value, sniffs])
		assert_eq(_count(log, "run"), 1, "koşu olayı")
		assert_eq(_count(log, "nibble") + _count(log, "bite"), 0, "şamandıranın olayları yok")
		assert_eq(session.window, int(2.5 * HZ), "pencere 2,5 sn")
		assert_eq(session.action_kind(), "hook", "koşuda eylem: VUR")
		session.press()
		assert_eq(session.state, FishingSession.State.FIGHTING, "dokununca takılır")


## Çöp (Dalga 4): dipte tutulan balığın yanında; zarı gölgenin seed'inden (önceden belli, kovaya girmez:
## main toplar).
func test_trash_comes_with_a_bottom_catch() -> void:
	var rules := content().rules
	var trash_seed := 0
	while Trash.with_catch(rules, trash_seed, "bottom").is_empty():
		trash_seed += 1
	var session := _session(true)
	var log: Array[Dictionary] = []
	var fish := _to_sniffing(session, log)
	fish.seed = trash_seed
	assert_true(_run_until(session, FishingSession.State.BITING, 12.0, log), "koşu gelir")
	session.press()
	assert_true(_run_until(session, FishingSession.State.CAUGHT, 90.0, log), "Kolay'da basılı tutunca tutulur")
	assert_eq(str(session.last_catch["trash"]), Trash.with_catch(rules, trash_seed, "bottom"), "balığın yanında çöp")
	var other := trash_seed + 1
	while not Trash.with_catch(rules, other, "bottom").is_empty():
		other += 1
	var plain := _session(true)
	var quiet := _to_sniffing(plain, log)
	quiet.seed = other
	assert_true(_run_until(plain, FishingSession.State.BITING, 12.0, log), "koşu gelir")
	plain.press()
	assert_true(_run_until(plain, FishingSession.State.CAUGHT, 90.0, log), "tutulur")
	assert_eq(str(plain.last_catch["trash"]), "", "zarı tutmayan balıkta çöp yok")


func test_touch_while_sniffing_scares_the_fish() -> void:
	var session := _session()
	var log: Array[Dictionary] = []
	_to_sniffing(session, log)
	session.press()
	assert_eq(session.state, FishingSession.State.LOST, "koklarken dokunmak balığı kaçırır")
	assert_eq(session.last_loss, "early", "erken")


func test_run_window_is_longer_in_easy_mode() -> void:
	var session := _session(true)
	var log: Array[Dictionary] = []
	_to_sniffing(session, log)
	assert_true(_run_until(session, FishingSession.State.BITING, 12.0, log), "koşu gelir")
	assert_eq(session.window, int(3.5 * HZ), "Kolay modda 3,5 sn")
	_steps(session, int(3.0 * HZ))
	assert_eq(session.state, FishingSession.State.BITING, "3 sn sonra hâlâ vurulabilir")
	_steps(session, int(0.6 * HZ))
	assert_true(session.state != FishingSession.State.BITING, "pencere kapanır")


func test_touch_while_waiting_reels_in() -> void:
	var session := _session()
	_park_all(session)
	assert_true(session.cast(TARGET), "atış")
	assert_true(_run_until(session, FishingSession.State.WAITING, 3.0), "suda")
	assert_eq(session.action_kind(), "retrieve", "beklerken eylem: geri sar")
	session.press()
	assert_eq(session.state, FishingSession.State.RETRIEVING, "geri sarar")
	assert_eq(session.timer, int(1.0 * HZ), "uzun misina: 1 sn")


## Yem sepeti: gölgeler takımın çevresine daha erken ve daha sık toplanır (oturumun profili).
func test_feeder_speeds_up_gathering() -> void:
	var plain := _session()
	var fed := _session(false, 99, "feeder")
	var base := plain.sim.rig
	var with_feeder := fed.sim.rig
	assert_true(with_feeder.gather_after_steps < base.gather_after_steps, "daha erken toplanır")
	assert_true(with_feeder.gather_ppm > base.gather_ppm, "daha sık toplanır")
	assert_true(fed.range_m() < plain.range_m(), "yem sepeti biraz ağır: menzil kısalır")
	# Takım değişince (aynı teknik) profil de değişir.
	plain.set_gear(_bottom_gear("feeder"))
	assert_eq(plain.sim.rig.gather_after_steps, with_feeder.gather_after_steps, "takım değişince profil yenilenir")


func test_same_result_at_any_fps() -> void:
	var logs: Array[PackedStringArray] = []
	for fps: int in [30, 60, 120]:
		var session := _session(false, 4321)
		var log := PackedStringArray()
		var targets := [Vector2(0, -4), Vector2(-3, -3), Vector2(3, -2), Vector2(1, -5)]
		var next_target := 0
		var acted_at := -1
		while session.steps < 90 * HZ:
			session.advance(1.0 / fps)
			for e in session.poll_events():
				log.append("%s@%d" % [e["type"], e["step"]])
			# Bot yalnızca çift adımlarda ve adım başına bir kez davranır (30 fps'te kare 2 adım).
			if session.steps == 0 or session.steps % 2 != 0 or session.steps == acted_at:
				continue
			acted_at = session.steps
			match session.state:
				FishingSession.State.IDLE:
					session.cast(targets[next_target % targets.size()])
					next_target += 1
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
	for run in 4:
		var session := _session(run % 2 == 1, 3000 + run)
		var rng := RandomNumberGenerator.new()
		rng.seed = 555 + run
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
					if rng.randf() < 0.06:
						session.press()
					if rng.randf() < 0.02:
						session.release()
				_:
					if rng.randf() < 0.004:
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
				FishingSession.State.CASTING: 1.6, FishingSession.State.BITING: 3.6, FishingSession.State.RETRIEVING: 1.1,
				FishingSession.State.LOST: 1.0, FishingSession.State.NIBBLING: 12.5,
			}
			if limits.has(session.state) and since_change > float(limits[session.state]) * HZ:
				problem = "%s durumunda takıldı" % session.state_name()
			if session.state in [FishingSession.State.WAITING, FishingSession.State.NIBBLING, FishingSession.State.BITING]:
				if not lake.is_water(session.bobber) or lake.on_dock(session.bobber):
					problem = "takım suda değil: %s" % str(session.bobber)
			if session.state == FishingSession.State.FIGHTING and (session.reel == null or session.hooked == null):
				problem = "çekişmede model yok"
			if not problem.is_empty():
				break
		assert_true(problem.is_empty(), "deneme %d: %s" % [run, problem])
		assert_true(casts >= 3, "deneme %d: oyun ilerler (%d atış)" % [run, casts])


## Yemin kokusu (gather_after) duraklayan ve dolaşan gölgeleri takıma çağırır: yeni hedefleri takımın
## çevresinde; geri sarınca toplanma biter (gölgeler yine olağan hızla dolaşır).
func test_smell_calls_fish_to_the_rig_until_reeled_in() -> void:
	var session := _session()
	for s in session.sim.shadows:
		s.mode = FishShadow.Mode.PAUSE
		s.timer = 1_000_000
	assert_true(session.cast(TARGET), "atış")
	assert_true(_run_until(session, FishingSession.State.WAITING, 3.0), "kurşun suya düşer")
	var rig := session.sim.rig
	while session.waiting_steps < rig.gather_after_steps and session.state == FishingSession.State.WAITING:
		session.step()
	var called := 0
	for s in session.sim.shadows:
		if s.gathering:
			called += 1
			assert_true(s.target.distance_to(session.bobber) <= rig.gather_radius + 0.001,
					"hedef takımın %.1f m çevresinde (%.2f)" % [rig.gather_radius, s.target.distance_to(session.bobber)])
	assert_true(called >= 1, "koku gölgeleri takıma çağırır (%d)" % called)
	session.press()
	assert_eq(session.state, FishingSession.State.RETRIEVING, "beklerken dokunmak geri sarar")
	for s in session.sim.shadows:
		assert_true(not s.gathering, "geri sarınca toplanma biter")


## Yem sepetinin çekişi en güçlüyken (1,0) de koku yayılır: eşik en az 1 adım.
func test_strongest_feeder_still_calls_fish() -> void:
	var rig := _session().technique.rig.with_pull(1.0)
	assert_true(rig.gather_after_steps >= 1, "eşik en az 1 adım (%d)" % rig.gather_after_steps)
	assert_eq(rig.gather_ppm, Dice.PPM, "hepsi toplanır")
