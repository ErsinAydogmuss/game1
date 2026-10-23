extends BaseTest
## Gölün Bekçisi oturumda (Dalga 4, final; docs/gdd.md §10.5). Sunum onu sandalın yanına çağırır
## (summon): göldeyken takımı yalnızca o fark eder, kurşundan korkmaz, vazgeçmez; koklamada dokunmayı ve
## kaçan koşuyu bağışlar (ilk av gibi) ama dürter ve dalışlarıyla gerçekten çekişir. Tutulunca çöp çıkmaz,
## yerine yeni gölge doğmaz; varlığı öteki gölgelerin zarını kaydırmaz; sabah olunca gider, balıkçı başka
## yere geçince kalkar.

const SPOT := "big_lake"
const HZ := FishingRules.HZ
## Final gecesi: sisli gece (göl sevgisi altın hamurun seviyesinde).
const NIGHT_FOG := { "phase": "night", "weather": "fog", "love": 6 }


func _bottom_gear() -> GearStats:
	var db := content()
	var items := db.gear_start.duplicate()
	items["rod"] = "rod_carp_2"
	items["rig"] = "sinker"
	var owned: Array[String] = ["sinker"]
	return GearStats.from_items(db, items, owned)


## Sandalın haritanın X'indeki yeri (LakeScene.moor_boat gibi).
func _boat() -> Vector2:
	return Secret.keeper_x(content(), SPOT) + LakeScene.BUOY_MOOR


## Sandalda, X'te, dip takımıyla, sisli gecede bir oturum.
func _x_session(seed_value: int = 5, easy: bool = false) -> FishingSession:
	var session := FishingSession.new(content(), SPOT, _bottom_gear(), seed_value, easy, false, -1,
			PackedStringArray(["deep_water"]), NIGHT_FOG)
	session.relocate(_boat())
	session.poll_events()
	return session


func _steps(session: FishingSession, count: int, log: Array[Dictionary]) -> void:
	for i in count:
		session.step()
		log.append_array(session.poll_events())


func _run_until(session: FishingSession, wanted: FishingSession.State, max_seconds: float,
		log: Array[Dictionary]) -> bool:
	for i in int(max_seconds * HZ):
		if session.state == wanted:
			return true
		session.step()
		log.append_array(session.poll_events())
	return session.state == wanted


static func _of_type(log: Array[Dictionary], type: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for e in log:
		if str(e["type"]) == type:
			out.append(e)
	return out


## Dolaşan gölgeler (çağrılan gölge sayılmaz).
static func _wild(session: FishingSession) -> Array[FishShadow]:
	var out: Array[FishShadow] = []
	for s in session.sim.shadows:
		if not s.summoned:
			out.append(s)
	return out


## X derin ortanın batı ucunda: derin su doğuya, gölün ortasına uzanır. Takım oraya atılır.
const EAST := Vector2(1, 0)


## Sandaldan doğuya 12 m'ye düşen takıma karşı Bekçi'nin belirdiği yer (derin su).
func _keeper_spot() -> Vector2:
	var boat := _boat()
	return Secret.keeper_point(content(), SPOT, boat, boat + EAST * 12.0)


## Kurşunu atar (sandaldan doğuya), suya düşünce Bekçi'yi çağırır. Döner: Bekçi'nin gölgesi.
func _cast_and_summon(session: FishingSession, log: Array[Dictionary]) -> FishShadow:
	var boat := _boat()
	assert_true(session.cast(boat + EAST * 10.0), "dip takımı atılır")
	assert_true(_run_until(session, FishingSession.State.WAITING, 4.0, log), "kurşun suya düşer")
	var point := Secret.keeper_point(content(), SPOT, boat, session.bobber)
	assert_true(Dice.is_point(point), "Bekçi'nin yeri var")
	var id := session.summon(Secret.KEEPER_ID, point, Secret.KEEPER_PERCENTILE)
	assert_true(id >= 0, "Bekçi çağrılır")
	log.append_array(session.poll_events())
	return session.sim.find(id)


func test_keeper_is_a_story_fish() -> void:
	var db := content()
	var f := db.fish_by_id(Secret.KEEPER_ID)
	assert_true(bool(f["story"]) and bool(f["release_only"]), "hikâyenin balığı, göle bırakılır")
	assert_eq(int(f["value"]), 0, "satılmaz")
	assert_eq(db.rarity_id(int(f["rarity"])), "mythic", "Masalsı")
	assert_true(Secret.KEEPER_ID in (db.spot(SPOT)["story_fish"] as PackedStringArray), "gölün hikâye balığı")
	for z in db.zones_of(SPOT):
		assert_true(not Secret.KEEPER_ID in (z["fish_ids"] as PackedStringArray), "%s tablosunda yok" % z["id"])
	assert_eq(FishTable.stars(Secret.KEEPER_PERCENTILE), 5, "5★")
	assert_true(FishTable.shadow_length(f, Secret.KEEPER_PERCENTILE) >= 4.5, "gölgesi dev (en az 4,5 m)")
	var session := _x_session()
	var land: Vector2 = db.zone(SPOT, "reeds")["stands"][0]
	assert_true(not session.lake.is_water(land), "atış noktası karada")
	assert_eq(session.summon(Secret.KEEPER_ID, land, 0), -1, "karada çağrılamaz")
	assert_eq(session.summon("nope", _keeper_spot(), 0), -1, "bilinmeyen tür çağrılmaz")


## Bekçi göldeyken takımı yalnızca o fark eder: kurşunun dibinde bekleyen balık bile gelmez; Bekçi gelir, koklar.
func test_only_the_keeper_comes_to_the_rig() -> void:
	var session := _x_session(7)
	var log: Array[Dictionary] = []
	var keeper := _cast_and_summon(session, log)
	if keeper == null:
		return
	# Bekçi çağrılmadan önce fark eden balık ilgisini kaybetti (summon): yalnızca sonrası sayılır.
	log.clear()
	assert_true(not _wild(session).is_empty(), "gölde başka gölge var")
	if _wild(session).is_empty():
		return
	var bait := _wild(session)[0]
	bait.pos = session.bobber + Vector2(0.8, 0.0)
	bait.heading = Vector2(-1, 0)
	bait.mode = FishShadow.Mode.PAUSE
	bait.timer = 1_000_000
	assert_true(_run_until(session, FishingSession.State.NIBBLING, 30.0, log), "Bekçi gelir ve koklar")
	assert_true(session.sim.approacher == keeper, "takıma gelen Bekçi")
	for e in _of_type(log, "notice"):
		assert_eq(int(e["shadow"]), keeper.id, "takımı yalnızca Bekçi fark eder")


## Kurşun Bekçi'nin dibine düşse de korkmaz; yaklaşmakta olan öteki balık Bekçi çağrılınca ilgisini kaybeder.
func test_keeper_is_not_scared_and_takes_over() -> void:
	var session := _x_session(13)
	var boat := _boat()
	var target := boat + EAST * 10.0
	var point := _keeper_spot()
	var id := session.summon(Secret.KEEPER_ID, point, Secret.KEEPER_PERCENTILE)
	var keeper := session.sim.find(id)
	var log: Array[Dictionary] = []
	assert_true(session.cast(target), "atış")
	assert_true(_run_until(session, FishingSession.State.WAITING, 4.0, log), "kurşun suya düşer")
	keeper.pos = session.bobber + Vector2(0.5, 0.5)
	for e in session.sim.scare(session.bobber):
		assert_true(int(e["shadow"]) != keeper.id, "Bekçi kurşundan korkmaz")
	assert_true(keeper.mode != FishShadow.Mode.FLEE, "kaçmaz")
	# Öteki balık yaklaşırken Bekçi yeniden çağrılır: yol onun.
	var other := FishingSession.new(content(), SPOT, _bottom_gear(), 13, false, false, -1,
			PackedStringArray(["deep_water"]), NIGHT_FOG)
	other.relocate(boat)
	other.poll_events()
	var other_log: Array[Dictionary] = []
	assert_true(other.cast(target), "ikinci oturumda atış")
	assert_true(_run_until(other, FishingSession.State.WAITING, 4.0, other_log), "kurşun suya düşer")
	assert_true(not _wild(other).is_empty(), "gölde başka gölge var")
	if _wild(other).is_empty():
		return
	var fish := _wild(other)[0]
	fish.pos = other.bobber + Vector2(1.5, 0.0)
	fish.mode = FishShadow.Mode.PAUSE
	fish.timer = 1
	for i in 3 * HZ:
		if other.sim.approacher != null:
			break
		other.step()
	var first := other.sim.approacher
	assert_true(first != null and not first.summoned, "öteki balık yaklaşıyor")
	var summoned := other.sim.find(other.summon(Secret.KEEPER_ID, point, Secret.KEEPER_PERCENTILE))
	assert_true(other.sim.approacher == null, "Bekçi gelince öteki balık ilgisini kaybeder")
	assert_true(_run_until(other, FishingSession.State.NIBBLING, 30.0, other_log), "Bekçi gelir")
	assert_true(other.sim.approacher == summoned, "takıma Bekçi gelir")


## Koklarken dokunmak Bekçi'yi kaçırmaz (irkilir); kaçan koşudan sonra yeniden koklar; vurunca gerçek çekişme
## (dalışlı, Kolay değil).
func test_keeper_forgives_early_touches_and_a_missed_run() -> void:
	var session := _x_session(17)
	var log: Array[Dictionary] = []
	var keeper := _cast_and_summon(session, log)
	if keeper == null:
		return
	assert_true(_run_until(session, FishingSession.State.NIBBLING, 30.0, log), "Bekçi koklar")
	session.press()
	session.release()
	_steps(session, 1, log)
	var early := _of_type(log, "early")
	assert_true(not early.is_empty() and bool(early[-1]["startle"]), "koklarken dokunmak: irkilir")
	assert_true(session.sim.approacher == keeper, "Bekçi gitmez")
	assert_true(_run_until(session, FishingSession.State.BITING, 20.0, log), "koşu başlar")
	_steps(session, session.window + 2, log)
	assert_true(not _of_type(log, "retry").is_empty(), "koşu kaçınca yeniden ısırır")
	assert_true(session.sim.approacher == keeper, "Bekçi yine orada")
	assert_true(_run_until(session, FishingSession.State.BITING, 20.0, log), "yeniden koşu")
	session.press()
	_steps(session, 1, log)
	assert_eq(session.state, FishingSession.State.FIGHTING, "vurunca çekişme")
	if session.reel != null:
		assert_true(session.reel.has_dives(), "Bekçi dalar")
		assert_true(not session.reel.easy, "Normal'de gerçek çekişme")
	assert_eq(session.too_big, 0, "Bekçi fazla iri sayılmaz")


## Tutulan Bekçi hikâyenin avı: 5★, derin ortada, çöp yok; yerine yeni gölge doğmaz.
func test_caught_keeper_is_a_story_catch() -> void:
	var session := _x_session(23)
	var log: Array[Dictionary] = []
	var keeper := _cast_and_summon(session, log)
	if keeper == null:
		return
	assert_true(_run_until(session, FishingSession.State.BITING, 40.0, log), "Bekçi koşar")
	session.press()
	var bot := ReelBot.make(ReelBot.Style.PERFECT)
	for i in ReelBot.LIMIT_STEPS:
		if session.state != FishingSession.State.FIGHTING:
			break
		var hold := bot.decide(session.reel, PackedStringArray())
		if hold and not session.holding:
			session.press()
		elif not hold and session.holding:
			session.release()
		session.step()
		log.append_array(session.poll_events())
	assert_eq(session.state, FishingSession.State.CAUGHT, "Bekçi tutulur")
	assert_eq(_of_type(log, "dive").size(), 2, "iki dalış")
	var c := session.last_catch
	assert_eq(str(c.get("fish", "")), Secret.KEEPER_ID, "Bekçi")
	assert_true(bool(c.get("story", false)), "hikâyenin avı")
	assert_eq(str(c.get("trash", "x")), "", "yanında çöp yok")
	assert_eq(int(c.get("stars", 0)), 5, "5★")
	assert_eq(str(c.get("zone", "")), "deep_water", "derin ortada")
	assert_true(session.summoned() == null, "gölde Bekçi kalmadı")


## Bekçi'nin varlığı (takım sudayken değil) öteki gölgelerin doğuşunu ve yolunu değiştirmez.
func test_summoning_does_not_shift_other_shadows() -> void:
	var a := _x_session(31)
	var b := _x_session(31)
	assert_true(b.summon(Secret.KEEPER_ID, _keeper_spot(), Secret.KEEPER_PERCENTILE) >= 0, "Bekçi çağrılır")
	for i in 40 * HZ:
		a.step()
		b.step()
	var wa := _wild(a)
	var wb := _wild(b)
	assert_eq(wb.size(), wa.size(), "aynı sayıda gölge")
	for k in mini(wa.size(), wb.size()):
		assert_eq(wb[k].id, wa[k].id, "aynı gölge")
		assert_eq(wb[k].fish_id, wa[k].fish_id, "aynı tür")
		assert_true(wb[k].pos == wa[k].pos, "aynı yer (%s, %s)" % [wa[k].pos, wb[k].pos])
	assert_true(b.summoned() != null, "Bekçi hâlâ gölde (vazgeçmez, çekilmez)")


## Sabah olunca Bekçi gider (dolaşırken; yerine yeni gölge doğmaz: öteki gölgeler Bekçisiz oturumdakiyle aynı);
## takıma yaklaşırken gitmez; tutulunca da yerine gölge doğmaz; balıkçı başka yere geçince kalkar.
func test_keeper_leaves_without_a_replacement() -> void:
	var session := _x_session(41)
	var twin := _x_session(41)
	var point := _keeper_spot()
	session.summon(Secret.KEEPER_ID, point, Secret.KEEPER_PERCENTILE)
	assert_true(session.dismiss_summoned(), "Bekçi gider")
	var log: Array[Dictionary] = []
	for i in session.rules.flee_steps + 5:
		if session.summoned() == null:
			break
		_steps(session, 1, log)
		twin.step()
	assert_true(session.summoned() == null, "Bekçi gölden çıktı")
	assert_eq(session.sim.pending_spawns(), twin.sim.pending_spawns(), "yerine yeni gölge doğmaz")
	assert_eq(_wild(session).size(), _wild(twin).size(), "öteki gölgeler Bekçisiz oturumdaki gibi")
	var caught := session.sim.find(session.summon(Secret.KEEPER_ID, point, Secret.KEEPER_PERCENTILE))
	var pending := session.sim.pending_spawns()
	session.sim.remove(caught)
	assert_eq(session.sim.pending_spawns(), pending, "tutulan Bekçi'nin yerine gölge doğmaz")
	var approaching := _x_session(43)
	var keeper := _cast_and_summon(approaching, log)
	if keeper != null:
		for i in 5 * HZ:
			if approaching.sim.approacher == keeper:
				break
			approaching.step()
		assert_true(approaching.sim.approacher == keeper, "Bekçi takıma yaklaşıyor")
		assert_true(not approaching.dismiss_summoned(), "yaklaşırken gitmez")
	session.summon(Secret.KEEPER_ID, point, Secret.KEEPER_PERCENTILE)
	session.relocate(content().zone(SPOT, "dock_cove")["stands"][0])
	assert_true(session.summoned() == null, "balıkçı başka yere geçince Bekçi kalkar")
