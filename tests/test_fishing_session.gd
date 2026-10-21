extends BaseTest
## Balık tutma oturumu: durum geçişleri, korkutma ve fark etme, erken dokunuş, vuruş penceresi
## sınırları, kart beklemesi, ilk av, rastgele girdiyle takılmama ve fps'ten bağımsızlık.

const HZ := FishingRules.HZ
## Şamandıranın test atışlarında düştüğü yer (balıkçı (0, 4)'te, iskelenin ucunda).
const BOBBER := Vector2(0, 0)
## Gölgeleri park etmek için şamandıradan uzak, derin yerler.
const PARK := [Vector2(-10, -4), Vector2(-7, -5), Vector2(5.5, -2.5), Vector2(-4, -3)]


func _session(easy: bool = false, first: bool = false, seed: int = 99) -> FishingSession:
	return FishingSession.new(content(), "home_lake", GearStats.starter(content()), seed, easy, first)


## Bir gölge dışındakileri uzağa koyar ve uyutur (testi bozmasınlar).
func _park_others(session: FishingSession, keep: FishShadow) -> void:
	var i := 0
	for s in session.sim.shadows:
		if s == keep:
			continue
		s.pos = PARK[i % PARK.size()]
		s.mode = FishShadow.Mode.PAUSE
		s.timer = 1_000_000
		i += 1


func _run_until(session: FishingSession, wanted: FishingSession.State, max_seconds: float) -> bool:
	for i in int(max_seconds * HZ):
		if session.state == wanted:
			return true
		session.step()
	return session.state == wanted


## Gerçek zamanı kare kare ilerletir (bir karede en fazla 0,5 sn işlenir).
func _advance_seconds(session: FishingSession, seconds: float) -> void:
	var left := seconds
	while left > 0.0:
		var chunk := minf(left, 0.25)
		session.advance(chunk)
		left -= chunk


func _types(events: Array[Dictionary]) -> PackedStringArray:
	var out := PackedStringArray()
	for e in events:
		out.append(str(e["type"]))
	return out


## Şamandırayı target'a atar; bir gölgeyi şamandıranın 2 m önüne, ona bakacak şekilde koyar.
func _setup_approach(session: FishingSession, target: Vector2 = BOBBER) -> FishShadow:
	var s := session.sim.shadows[0]
	_park_others(session, s)
	s.pos = target + Vector2(0, -2.0)
	s.heading = Vector2(0, 1)
	s.mode = FishShadow.Mode.PAUSE
	s.timer = 1_000_000
	assert_true(session.cast(target), "atış yapılır")
	return s


func _to_nibbling(session: FishingSession, target: Vector2 = BOBBER) -> FishShadow:
	var s := _setup_approach(session, target)
	assert_true(_run_until(session, FishingSession.State.NIBBLING, 15.0), "balık gelip dürtmeye başlar")
	return s


func _to_biting(session: FishingSession, target: Vector2 = BOBBER) -> FishShadow:
	var s := _to_nibbling(session, target)
	assert_true(_run_until(session, FishingSession.State.BITING, 10.0), "balık ısırır")
	return s


func test_cast_and_land() -> void:
	var session := _session()
	assert_eq(session.state, FishingSession.State.IDLE, "başta boş")
	assert_eq(session.action_kind(), "cast", "eylem: at")
	assert_true(session.cast(BOBBER), "suya atış")
	assert_eq(session.state, FishingSession.State.CASTING, "şamandıra uçuyor")
	assert_true(not session.cast(BOBBER), "uçarken yeni atış yok")
	var flight := FishingRules.to_steps(0.45 + 0.05 * 4.0)
	for i in flight - 1:
		session.step()
	assert_eq(session.state, FishingSession.State.CASTING, "uçuş süresi 0,45 + 0,05 × mesafe")
	session.step()
	assert_eq(session.state, FishingSession.State.WAITING, "şamandıra suda")
	assert_eq(session.bobber, BOBBER, "hedefe düştü")
	var types := _types(session.poll_events())
	assert_true("cast" in types and "land" in types, "atış ve düşme olayları")
	assert_true(session.line_out(), "olta suda")
	assert_eq(session.action_kind(), "retrieve", "beklerken eylem: geri sar")


func test_cast_beyond_range_lands_in_water() -> void:
	var session := _session()
	assert_true(session.cast(Vector2(0, -40)), "menzil dışına atış")
	assert_true(absf(session.bobber.distance_to(session.angler) - session.range_m()) < 0.01, "menzilin ucuna")
	assert_true(session.lake.is_water(session.bobber), "suya düşer")
	var inland := _session()
	inland.angler = Vector2(0, 15)
	assert_true(not inland.cast(Vector2(0, 30)), "çizgide su yoksa atış olmaz")
	assert_eq(inland.state, FishingSession.State.IDLE, "durum değişmez")


func test_retrieve_returns_to_idle() -> void:
	var session := _session()
	session.cast(BOBBER)
	_run_until(session, FishingSession.State.WAITING, 2.0)
	session.press()
	assert_eq(session.state, FishingSession.State.RETRIEVING, "beklerken dokunuş geri sarar")
	session.release()
	assert_true(_run_until(session, FishingSession.State.IDLE, 1.0), "geri sarma kısa sürer")
	assert_true(session.cast(BOBBER), "sonra yeniden atılır")


func test_landing_on_a_shadow_scares_it() -> void:
	var session := _session()
	var s := session.sim.shadows[0]
	_park_others(session, s)
	s.pos = BOBBER
	s.mode = FishShadow.Mode.PAUSE
	s.timer = 1_000_000
	session.cast(BOBBER + Vector2(0.1, 0))
	_run_until(session, FishingSession.State.WAITING, 2.0)
	var events := session.poll_events()
	var scared := false
	for e in events:
		if str(e["type"]) == "scare" and int(e["shadow"]) == s.id:
			scared = true
	assert_true(scared, "gölgenin üstüne atış onu korkutur")
	assert_eq(s.mode, FishShadow.Mode.FLEE, "gölge kaçar")
	for i in HZ * 2:
		session.step()
	assert_true(session.sim.find(s.id) == null, "kaçan gölge kaybolur")
	assert_true(session.sim.pending_spawns() >= 1, "yerine yenisi planlanır")


func test_landing_in_front_draws_the_fish() -> void:
	var session := _session()
	var s := _setup_approach(session)
	_run_until(session, FishingSession.State.WAITING, 2.0)
	assert_true(s.mode != FishShadow.Mode.FLEE, "önüne atış korkutmaz")
	for i in 3:
		session.step()
	assert_true(session.sim.approacher == s, "gölge şamandırayı fark eder")
	assert_eq(s.mode, FishShadow.Mode.APPROACH, "yaklaşır")
	assert_true(_run_until(session, FishingSession.State.NIBBLING, 10.0), "şamandıraya varır")
	assert_true(s.pos.distance_to(session.bobber) <= s.length * 0.5 + 0.06, "ağzı şamandırada")
	assert_eq(session.action_kind(), "wait", "dürtmede eylem: bekle")


func test_early_tap_loses_the_fish() -> void:
	var session := _session()
	var s := _to_nibbling(session)
	session.poll_events()
	session.press()
	var types := _types(session.poll_events())
	assert_true("early" in types and "lost" in types, "erken dokunuş: Erken davrandın + kaçtı")
	assert_eq(session.last_loss, "early", "neden: erken")
	assert_eq(s.mode, FishShadow.Mode.FLEE, "balık kaçar")
	assert_true(_run_until(session, FishingSession.State.IDLE, 1.5), "kısa süre sonra yeniden atılabilir")


func test_easy_first_early_tap_only_startles() -> void:
	var session := _session(true)
	_to_nibbling(session)
	session.press()
	session.release()
	assert_eq(session.state, FishingSession.State.NIBBLING, "Kolay: ilk erken dokunuşta balık kalır")
	session.press()
	assert_eq(session.state, FishingSession.State.LOST, "Kolay: ikincisinde kaçar")


func test_hook_window_edges() -> void:
	for easy: bool in [false, true]:
		var window := 1.6 if easy else 1.0
		var label := "Kolay" if easy else "Normal"
		var inside := _session(easy)
		_to_biting(inside)
		assert_eq(inside.action_kind(), "hook", "ısırmada eylem: VUR")
		_advance_seconds(inside, window - 0.01)
		inside.press()
		assert_eq(inside.state, FishingSession.State.FIGHTING, "%s: %.2f sn'de VUR tutar" % [label, window - 0.01])
		var late := _session(easy)
		_to_biting(late)
		_advance_seconds(late, window + 0.01)
		late.press()
		assert_eq(late.state, FishingSession.State.LOST, "%s: %.2f sn'de geç kalınmıştır" % [label, window + 0.01])
		assert_eq(late.last_loss, "missed", "%s: neden: kaçırdı" % label)


func test_missed_fish_is_replaced_within_8_seconds() -> void:
	var session := _session()
	var s := _to_biting(session)
	assert_true(_run_until(session, FishingSession.State.LOST, 2.0), "pencere geçince kaçar")
	var gone_at := -1
	var born_at := -1
	for i in HZ * 15:
		session.step()
		for e in session.poll_events():
			if str(e["type"]) == "despawn" and int(e["shadow"]) == s.id:
				gone_at = session.steps
			elif str(e["type"]) == "spawn" and gone_at >= 0 and born_at < 0:
				born_at = session.steps
	assert_true(gone_at >= 0, "kaçan gölge kaybolur")
	assert_true(born_at >= 0 and born_at - gone_at <= 8 * HZ, "8 sn içinde yeni gölge (%d adım)" % (born_at - gone_at))
	assert_eq(session.sim.shadows.size(), 4, "gölde yine 4 gölge")


## Çöp (Dalga 4) yalnızca dipte: şamandırayla tutulan balığın yanında hiç çıkmaz (gölgenin seed'i dipte
## çöp getirse de).
func test_no_trash_with_the_float() -> void:
	var rules := content().rules
	var trash_seed := 0
	while Trash.with_catch(rules, trash_seed, "bottom").is_empty():
		trash_seed += 1
	var session := _session(true)
	var s := _to_biting(session)
	s.seed = trash_seed
	session.press()
	assert_true(_run_until(session, FishingSession.State.CAUGHT, 90.0), "Kolay'da basılı tutunca tutulur")
	assert_eq(int(session.last_catch["seed"]), trash_seed, "gölgenin seed'i yakalayışta")
	assert_eq(str(session.last_catch["trash"]), "", "şamandırada çöp yok")


func test_catch_waits_for_the_card() -> void:
	var session := _session(true)
	var s := _to_biting(session)
	session.press()
	assert_eq(session.state, FishingSession.State.FIGHTING, "VUR: çekişme başlar")
	assert_eq(session.action_kind(), "reel", "çekişmede eylem: sar")
	assert_true(_run_until(session, FishingSession.State.CAUGHT, 90.0), "Kolay'da basılı tutunca tutulur")
	assert_eq(str(session.last_catch["fish"]), s.fish_id, "gölgenin balığı çıkar")
	assert_eq(int(session.last_catch["size_cm"]), s.size_cm, "boyu doğduğu andaki gibi")
	var caught_event := false
	for e in session.poll_events():
		if str(e["type"]) == "catch":
			caught_event = true
	assert_true(caught_event, "yakalama olayı")
	assert_true(session.sim.find(s.id) == null, "tutulan gölge gölden çıkar")
	for i in HZ:
		session.step()
	assert_eq(session.state, FishingSession.State.CAUGHT, "kart açıkken bekler")
	assert_true(not session.cast(BOBBER), "kart açıkken atış olmaz")
	session.acknowledge()
	assert_eq(session.state, FishingSession.State.IDLE, "kart kapanınca boş")
	assert_true(session.cast(BOBBER), "yeni atış serbest")


## İri balık takım ister: bambu olta ve ince misinayla (3★) 4★ yayın fazla iridir. hook olayı
## too_big (yıldızı) taşır; basılı tutunca kopar ve lost olayında too_big gelir (Dede eksik takımı
## söyler). Cam elyafı kamış ve naylon misinayla (4★) aynı balık fazla iri değildir.
func test_too_big_fish_is_flagged() -> void:
	var db := content()
	var mid_items := db.gear_start.duplicate()
	mid_items["rod"] = "rod_float_glass"
	mid_items["line"] = "line_mono"
	var none: Array[String] = []
	for setup: Array in [[GearStats.starter(db), 4], [GearStats.from_items(db, mid_items, none), 0]]:
		var session := FishingSession.new(db, "home_lake", setup[0], 99, false, false)
		var s := _to_biting(session)
		s.fish_id = "wels"
		s.fish_index = db.fish_index("wels")
		s.percentile = 800000
		s.stars = FishTable.stars(s.percentile)
		session.poll_events()
		session.press()
		var hook := {}
		for e in session.poll_events():
			if str(e["type"]) == "hook":
				hook = e
		var want: int = setup[1]
		assert_eq(int(hook.get("too_big", -1)), want, "hook olayında too_big (taşıma %d★)" % (setup[0] as GearStats).carry)
		assert_eq(session.too_big, want, "oturumda too_big")
		if want == 0:
			continue
		var lost := {}
		for i in 5 * HZ:
			session.step()
			for e in session.poll_events():
				if str(e["type"]) == "lost":
					lost = e
			if not lost.is_empty():
				break
		assert_eq(str(lost.get("reason", "")), "snapped", "fazla iri balık basılı tutunca koparır")
		assert_eq(int(lost.get("too_big", 0)), 4, "lost olayında too_big")
		assert_eq(session.too_big, 0, "kayıptan sonra sıfırlanır")


## Senaryolu ilk balık (öğretici) iri bir türün en irisi olsa da fazla iri sayılmaz.
func test_scripted_first_fish_is_never_too_big() -> void:
	var db := content()
	var session := _session(false, true)
	var first := session.sim.shadows[0]
	first.fish_id = "wels"
	first.fish_index = db.fish_index("wels")
	first.percentile = 990000
	first.stars = FishTable.stars(first.percentile)
	assert_true(session.cast(Vector2(4.5, -2.0)), "atış")
	assert_true(_run_until(session, FishingSession.State.BITING, 30.0), "ilk balık ısırır")
	session.press()
	assert_eq(session.state, FishingSession.State.FIGHTING, "çekişme")
	assert_eq(session.too_big, 0, "senaryolu balık fazla iri değil")
	assert_eq(session.reel.excess, 0, "çekişmede fazla iri kuralı yok")


## Balıkçı kıyıdan geride (karada) dururken kopan balık karada değil suda kaçar.
func test_lost_fight_flees_through_water() -> void:
	var session := _session()
	session.angler = Vector2(5, 6.4)
	assert_true(session.lake.is_walkable(session.angler), "balıkçı karada")
	var s := _to_biting(session, Vector2(3, 1))
	session.press()
	assert_eq(session.state, FishingSession.State.FIGHTING, "çekişme")
	session.reel.distance = 0.8
	session.reel.over = 1_000_000
	session.step()
	assert_eq(session.last_loss, "snapped", "misina koptu")
	assert_eq(s.mode, FishShadow.Mode.FLEE, "balık kaçıyor")
	assert_true(session.lake.is_water(s.pos), "kaçan balık suda: %s" % str(s.pos))


func test_first_catch_is_scripted() -> void:
	var session := _session(false, true)
	var first := session.sim.shadows[0]
	assert_true(first.scripted and first.fish_id == "rudd", "ilk gölge senaryolu Kızılkanat")
	# Oyuncu biraz düşünür, sonra gölgeden uzağa atar; ilk balık yine gelir.
	for i in 2 * HZ:
		session.step()
	assert_true(session.cast(Vector2(4.5, -2.0)), "uzağa atış")
	var nibbles := 0
	var early_taps := 0
	var missed_once := false
	var caught := false
	while session.steps < 45 * HZ:
		session.step()
		for e in session.poll_events():
			match str(e["type"]):
				"nibble":
					nibbles += 1
				"retry":
					missed_once = true
				"catch":
					caught = true
		if session.state == FishingSession.State.NIBBLING and early_taps < 2:
			session.press()
			session.release()
			early_taps += 1
		elif session.state == FishingSession.State.BITING and missed_once:
			session.press()
		if caught:
			break
	assert_true(caught, "ilk balık 45 sn içinde tutulur (%.1f sn)" % session.seconds())
	assert_eq(nibbles, 0, "ilk av dürtmesiz")
	assert_true(missed_once, "ilk avda pencere kaçarsa balık gitmez, yeniden ısırır")
	assert_eq(str(session.last_catch.get("fish", "")), "rudd", "ilk av Kızılkanat")


func test_random_input_never_gets_stuck() -> void:
	var lake := content().lake("home_lake")
	var stands := [Vector2(0, 4), Vector2(0, 8), Vector2(9.6, 0), Vector2(-3, -7.2)]
	for run in 6:
		var session := _session(run % 2 == 1, run % 3 == 0, 1000 + run)
		var rng := RandomNumberGenerator.new()
		rng.seed = 555 + run
		var since_change := 0
		var last_state := session.state
		var casts := 0
		var ok := true
		var problem := ""
		for i in 60 * HZ:
			match session.state:
				FishingSession.State.IDLE:
					if rng.randf() < 0.01:
						session.angler = stands[rng.randi_range(0, stands.size() - 1)]
					if rng.randf() < 0.05 and session.cast(Vector2(rng.randf_range(-16, 10), rng.randf_range(-10, 12))):
						casts += 1
				FishingSession.State.CAUGHT:
					if rng.randf() < 0.05:
						session.acknowledge()
				_:
					if rng.randf() < 0.02:
						session.press()
					if rng.randf() < 0.04:
						session.release()
			session.step()
			session.poll_events()
			if session.state != last_state:
				last_state = session.state
				since_change = 0
			else:
				since_change += 1
			# Kolay modda balık kaçmaz: oyuncu sarmazsa çekişme sürer (tasarım gereği), sınır yok.
			var limits := {
				FishingSession.State.CASTING: 1.0, FishingSession.State.NIBBLING: 12.0,
				FishingSession.State.BITING: 1.7, FishingSession.State.RETRIEVING: 0.5,
				FishingSession.State.LOST: 1.0,
			}
			if not session.easy:
				limits[FishingSession.State.FIGHTING] = 50.0
			if limits.has(session.state) and since_change > float(limits[session.state]) * HZ:
				problem = "%s durumunda takıldı" % session.state_name()
			if session.state in [FishingSession.State.WAITING, FishingSession.State.NIBBLING, FishingSession.State.BITING]:
				if not lake.is_water(session.bobber) or lake.on_dock(session.bobber):
					problem = "şamandıra suda değil: %s" % str(session.bobber)
				if session.state != FishingSession.State.WAITING and session.sim.approacher == null:
					problem = "dürtme/ısırmada balık yok"
			if session.state == FishingSession.State.FIGHTING and (session.reel == null or session.hooked == null):
				problem = "çekişmede model yok"
			# Çekişmede balık karaya ve iskelenin altına çıkmaz: ne şamandıranın ötesine kaçarken ne de
			# son metrelerde (balıkçının dibi kara ya da iskele olabilir; balık suyun kenarında durur).
			if session.state == FishingSession.State.FIGHTING and session.reel != null \
					and (not lake.is_water(session.fight_point()) or lake.on_dock(session.fight_point())):
				problem = "çekişmede balık karada ya da iskelede: %s" % str(session.fight_point())
			if session.sim.shadows.size() > 4:
				problem = "4'ten çok gölge"
			for s in session.sim.shadows:
				if s.mode != FishShadow.Mode.HOOKED and not lake.is_water(s.pos):
					problem = "gölge karada: %s" % str(s.pos)
			if not problem.is_empty():
				ok = false
				break
		assert_true(ok, "deneme %d: %s" % [run, problem])
		assert_true(casts >= 3, "deneme %d: oyun ilerler (%d atış)" % [run, casts])


## Yaklaşırken iskelenin dibine ya da kıyının sığına sokulan balık, oyuncu geri sarınca orada
## donup kalmaz: derin suya geri yüzer.
func test_stranded_fish_swims_back_to_deep_water() -> void:
	for start: Vector2 in [Vector2(1.05, 4.3), Vector2(0.0, -6.1)]:
		var session := _session()
		var fish := session.sim.shadows[0]
		_park_others(session, fish)
		fish.pos = start
		fish.mode = FishShadow.Mode.PAUSE
		fish.timer = 1
		var limit := session.rules.min_depth * 0.75
		assert_true(session.lake.is_water(start) and not session.lake.is_deep(start, limit),
				"%s: balık dolaşma sınırının dışında başlar" % str(start))
		_advance_seconds(session, 20.0)
		assert_true(fish.pos.distance_to(start) > 0.5, "%s: balık yerinden kıpırdar" % str(start))
		assert_true(session.lake.is_deep(fish.pos, limit), "%s: balık derin suya döner (%s)" % [start, fish.pos])


## Çekişmede balık (yerinde çizilen şamandıra ve gölge) karaya çıkmaz: kıyı yakınsa kıyıda durur.
## Kaçış payı yine şamandıranın en az escape_extra ötesidir (Normal'de bırakan oyuncu hemen
## kaybetmez).
func test_fight_stays_in_water() -> void:
	for easy: bool in [true, false]:
		var session := _session(easy)
		# Balıkçı iskelenin ucunda (0, 4); +x yönünde kıyı ~7 m'de.
		_to_biting(session, Vector2(5.0, 4.0))
		session.press()
		session.step()
		assert_eq(session.state, FishingSession.State.FIGHTING, "çekişme başlar")
		session.release()
		var bobber_distance := session.reel.distance
		assert_true(session.reel.max_distance >= bobber_distance + session.rules.escape_extra - 0.01,
				"kaçış payı şamandıranın en az escape_extra ötesi")
		var on_land := false
		for i in 40 * HZ:
			if session.state != FishingSession.State.FIGHTING:
				break
			session.step()
			if session.state == FishingSession.State.FIGHTING and not session.lake.is_water(session.fight_point()):
				on_land = true
				break
		assert_true(not on_land, "%s: balık karaya çıkmaz" % ("Kolay" if easy else "Normal"))
		if easy:
			assert_eq(session.state, FishingSession.State.FIGHTING, "Kolay: bırakan oyuncunun balığı kaçmaz")
		else:
			assert_eq(session.last_loss, "escaped", "Normal: bırakan oyuncunun balığı sonunda kaçar")


## Sazlıkta balıkçı kumda durur (önünde ~1 m kum): çekişmenin her adımında balık suda, kıyıdan en
## az FIGHT_SHORE içeride; son metrelerde kuma çekilmez, suyun kenarında durur (Ersin: "kuma kadar
## gölgelik çıkıyor"). Çekişmenin kendisi değişmez: balık yine sarılıp tutulur.
func test_fight_stops_at_the_water_edge_in_the_reeds() -> void:
	var db := content()
	var spot := "big_lake"
	var lake := db.lake(spot)
	var stand: Vector2 = (db.zone(spot, "reeds")["stands"] as Array)[0]
	assert_true(not lake.is_water(stand), "sazlıkta balıkçı kumda durur")
	for easy: bool in [true, false]:
		var session := FishingSession.new(db, spot, GearStats.starter(db), 21, easy, false, -1,
				PackedStringArray(["reeds"]))
		session.relocate(stand)
		session.poll_events()
		var target := stand + Vector2(0.0, -4.5)
		var s := session.sim.shadows[0]
		for o in session.sim.shadows:
			if o != s:
				o.mode = FishShadow.Mode.PAUSE
				o.timer = 1_000_000
				o.pos = target + Vector2(-5.0, -2.5)
		s.pos = target + Vector2(0.0, -2.0)
		s.heading = Vector2(0, 1)
		s.mode = FishShadow.Mode.PAUSE
		s.timer = 1_000_000
		assert_true(session.cast(target), "atılır")
		assert_true(_run_until(session, FishingSession.State.BITING, 40.0), "balık ısırır")
		s.fish_id = "rudd"
		s.fish_index = db.fish_index("rudd")
		session.press()
		session.step()
		assert_eq(session.state, FishingSession.State.FIGHTING, "takılır")
		assert_true(session.fight_near > 0.5, "su balıkçının önünde başlar (%.1f m)" % session.fight_near)
		var nearest := INF
		var problem := ""
		for i in 90 * HZ:
			if session.state != FishingSession.State.FIGHTING:
				break
			# İyi oyuncu gibi: uyarıda bırakır, patlama bitince yeniden basar.
			if session.reel.thrashing() or session.reel.in_red:
				session.release()
			else:
				session.press()
			session.step()
			if session.state != FishingSession.State.FIGHTING:
				break
			var p := session.fight_point()
			nearest = minf(nearest, p.distance_to(stand))
			if not lake.is_water(p) or lake.on_dock(p) or lake.shore_distance(p) < FishingSession.FIGHT_SHORE - 0.001:
				problem = "balık suyun kenarının berisinde: %s (kıyı %.2f m)" % [p, lake.shore_distance(p)]
				break
		var mode := "Kolay" if easy else "Normal"
		assert_eq(problem, "", mode)
		assert_eq(session.state, FishingSession.State.CAUGHT, "%s: balık tutulur (%s)" % [mode, session.state_name()])
		assert_between(nearest, session.fight_near - 0.01, session.fight_near + 0.2,
				"%s: son metrelerde balık suyun kenarında durur (%.2f m)" % [mode, nearest])


## Aynı girdiler 30, 60 ve 120 fps'te birebir aynı olayları üretir. Bot yalnızca çift adımlarda
## (1/30 sn) karar verir; böylece üç hızda da aynı adımda aynı girdiyi verir.
func test_same_result_at_any_fps() -> void:
	var logs: Array[PackedStringArray] = []
	for fps: int in [30, 60, 120]:
		logs.append(_scripted_run(fps))
	assert_true(logs[0].size() > 20, "senaryo olay üretir (%d)" % logs[0].size())
	assert_eq(logs[1], logs[0], "60 fps = 30 fps")
	assert_eq(logs[2], logs[0], "120 fps = 30 fps")


func _scripted_run(fps: int) -> PackedStringArray:
	var session := _session(false, false, 4321)
	var log := PackedStringArray()
	var targets := [Vector2(0, 0), Vector2(-3, -2), Vector2(3, -1), Vector2(-8, -3), Vector2(1, -4)]
	var next_target := 0
	var acted_at := -1
	var bitten := false
	while session.steps < 50 * HZ:
		session.advance(1.0 / fps)
		for e in session.poll_events():
			log.append("%s@%d" % [e["type"], e["step"]])
			if str(e["type"]) == "bite":
				bitten = true
		if session.steps == 0 or session.steps % 2 != 0 or session.steps == acted_at:
			continue
		acted_at = session.steps
		match session.state:
			FishingSession.State.IDLE:
				session.cast(targets[next_target % targets.size()])
				next_target += 1
			FishingSession.State.WAITING:
				if session.steps % (12 * HZ) == 0:
					session.press()
					session.release()
			FishingSession.State.BITING:
				if bitten:
					bitten = false
					session.press()
			FishingSession.State.FIGHTING:
				var calm := session.reel.phase == ReelModel.Phase.CALM
				if calm and not session.holding:
					session.press()
				elif not calm and session.holding:
					session.release()
			FishingSession.State.CAUGHT:
				session.acknowledge()
	return log


func test_seed_decides_the_shadows() -> void:
	var a := _session(false, false, 1)
	var b := _session(false, false, 1)
	var c := _session(false, false, 2)
	var same := true
	var differ := false
	for i in a.sim.shadows.size():
		var sa := a.sim.shadows[i]
		var sb := b.sim.shadows[i]
		var sc := c.sim.shadows[i]
		if sa.fish_id != sb.fish_id or sa.size_cm != sb.size_cm or sa.pos != sb.pos:
			same = false
		if sa.fish_id != sc.fish_id or sa.size_cm != sc.size_cm:
			differ = true
	assert_true(same, "aynı seed: aynı gölgeler")
	assert_true(differ, "başka seed: başka gölgeler")
	for s in a.sim.shadows:
		assert_true(content().lake("home_lake").is_deep(s.pos, content().rules.min_depth), "gölgeler derin suda doğar")
		assert_true(s.pos.distance_to(a.angler) >= content().rules.spawn_from_angler, "balıkçının dibinde doğmaz")
