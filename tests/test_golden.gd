extends BaseTest
## Altın test: testlerin gölünde (home_lake) gölgeler ve oturum olayları birebir aynı kalır.
## Dalga 2'de gölge kodu bölgelere göre değişiyor; eski şemadaki göl kaymamalı (aynı seed, aynı
## balıklar, aynı yollar, aynı olaylar). Beklenen değerler tests/fixtures/golden_home_lake.json'da;
## bilerek değiştirilen bir kural varsa (ör. gölge davranışı) dosya yeniden üretilir:
##   godot --headless --path . -s res://tests/make_golden.gd

const FIXTURE := "res://tests/fixtures/golden_home_lake.json"
const HZ := FishingRules.HZ


func test_home_lake_is_unchanged() -> void:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(FIXTURE))
	assert_eq(typeof(parsed), TYPE_DICTIONARY, "altın dosya okunur")
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var expected: Dictionary = parsed
	var actual := snapshot(content())
	for key: String in expected:
		var want: Array = expected[key]
		var got: PackedStringArray = actual.get(key, PackedStringArray())
		assert_eq(got.size(), want.size(), "%s: satır sayısı" % key)
		for i in mini(got.size(), want.size()):
			if got[i] != str(want[i]):
				assert_eq(got[i], str(want[i]), "%s: %d. satır ilk fark" % [key, i])
				break


## Bugünkü davranışın özeti: başlangıç gölgeleri (üç seed), uzun bir dolaşma ve şamandırayı
## fark etme, senaryolu bir oturumun olayları.
static func snapshot(db: ContentDB) -> Dictionary:
	var out := {}
	for seed_value: int in [99, 1, 7]:
		var session := FishingSession.new(db, "home_lake", GearStats.starter(db), seed_value, false, false)
		out["start_%d" % seed_value] = _shadows(session.sim)
	var spot := db.spot("home_lake")
	var sim := ShadowSim.new(db, spot, db.lake("home_lake"), 555, false, Vector2(0, 4))
	var log := PackedStringArray()
	for step in 6000:
		var listening := step >= 3000
		for e in sim.step(Vector2(0, 4), Vector2(0, 0), listening, maxi(0, step - 3000)):
			log.append("%s#%d@%d" % [e["type"], e["shadow"], step])
		if step % 500 == 499:
			log.append_array(_shadows(sim))
	out["wander"] = log
	out["session"] = _scripted_run(db)
	return out


static func _shadows(sim: ShadowSim) -> PackedStringArray:
	var lines := PackedStringArray()
	for s in sim.shadows:
		lines.append("%d %s %d %d %.4f %.4f %.4f %.4f %d" % [s.id, s.fish_id, s.size_cm, s.stars, s.pos.x, s.pos.y,
				s.heading.x, s.heading.y, s.mode])
	return lines


## test_fishing_session'daki senaryonun aynısı (60 fps).
static func _scripted_run(db: ContentDB) -> PackedStringArray:
	var session := FishingSession.new(db, "home_lake", GearStats.starter(db), 4321, false, false)
	var log := PackedStringArray()
	var targets := [Vector2(0, 0), Vector2(-3, -2), Vector2(3, -1), Vector2(-8, -3), Vector2(1, -4)]
	var next_target := 0
	var acted_at := -1
	var bitten := false
	while session.steps < 50 * HZ:
		session.advance(1.0 / 60.0)
		for e in session.poll_events():
			log.append("%s@%d" % [e["type"], e["step"]])
			if str(e["type"]) == "bite":
				bitten = true
			if str(e["type"]) == "catch":
				log.append("%s %d %d" % [e["fish"], e["size_cm"], e["stars"]])
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
	log.append_array(_shadows(session.sim))
	return log
