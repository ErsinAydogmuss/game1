extends BaseTest
## Teknik altyapısı (Dalga 3): şamandıranın profili kuralların aynısı; oturum şamandırayla başlar;
## teknik yalnızca değişince (boştayken) gölgeler yeniden doğar. Şamandıranın davranışının bit
## bit aynı kaldığını altın test (test_golden.gd) denetler.


func _session(seed: int = 99) -> FishingSession:
	return FishingSession.new(content(), "home_lake", GearStats.starter(content()), seed, false, false)


func test_float_profile_copies_the_rules() -> void:
	var rules := content().rules
	var rig := rules.technique("float")
	assert_eq(rig.id, "float", "şamandıranın profili")
	assert_eq(rig.notice_cos, rules.notice_cos, "fark etme konisi")
	assert_eq(rig.notice_front, rules.notice_front, "önde fark etme")
	assert_eq(rig.notice_side, rules.notice_side, "yanda fark etme")
	assert_eq(rig.approach_speed, rules.approach_speed, "yaklaşma hızı")
	assert_eq(rig.give_up_steps, 20 * FishingRules.HZ, "kapalı yolda 20 sn sonra vazgeçer")
	assert_eq(rig.gather_after_steps, rules.gather_after_steps, "6 sn sonra toplanma")
	assert_eq(rig.gather_ppm, 500_000, "yarı yarıya toplanır")
	assert_eq(rig.gather_radius, rules.gather_radius, "toplanma yarıçapı")
	assert_eq(rig.nibble_weights, rules.nibble_weights, "dürtme ağırlıkları")
	assert_eq(rig.gap_steps, rules.gap_steps, "dürtme arası")
	assert_eq(rig.window_steps, rules.window_steps, "vuruş penceresi")
	assert_eq(rig.window_easy_steps, rules.window_easy_steps, "Kolay vuruş penceresi")
	assert_true(rules.technique("yok") == rig, "bilinmeyen teknik şamandıranın profilini alır")


func test_notice_matches_the_old_rule() -> void:
	var rules := content().rules
	var rig := rules.technique("float")
	var s := FishShadow.new()
	s.heading = Vector2(0, -1)
	for p: Vector2 in [Vector2(0, -2.9), Vector2(0, -3.1), Vector2(0, 1.7), Vector2(0, 1.9),
			Vector2(2.5, 0).rotated(deg_to_rad(-30)), Vector2(1.2, -1.4), Vector2(-2.2, -1.0)]:
		assert_eq(BiteRules.notices_in(s, p, rig.notice_front, rig.notice_side, rig.notice_cos),
				BiteRules.notices(s, p, rules), "profille fark etme eskisiyle aynı: %s" % p)


func test_session_starts_with_float() -> void:
	var session := _session()
	assert_true(session.technique is FloatTechnique, "oturum şamandırayla başlar")
	assert_eq(session.technique.id, "float", "tekniğin kimliği")
	assert_true(session.sim.rig == content().rules.technique("float"), "gölgeler şamandıranın profilini okur")
	assert_eq(Techniques.resolve("bilinmeyen"), "float", "kurulamayan teknik şamandıra olur")
	assert_eq(session.action_kind(), "cast", "boşta eylem atış")


func test_same_technique_keeps_the_shadows() -> void:
	var session := _session()
	var before := PackedInt32Array()
	for s in session.sim.shadows:
		before.append(s.id)
	session.set_gear(GearStats.starter(content()))
	var after := PackedInt32Array()
	for s in session.sim.shadows:
		after.append(s.id)
	assert_eq(after, before, "aynı teknikte gölgeler yerinde kalır")
	assert_true(session.poll_events().is_empty(), "olay yok")


## Teknik değişince (boştayken) gölgeler yeni profille, balıkçının çevresinde yeniden doğar.
func test_new_technique_respawns_the_shadows() -> void:
	var session := _session()
	session.technique = _Other.new(content().rules)
	session.set_gear(GearStats.starter(content()))
	assert_true(session.technique is FloatTechnique, "takımın tekniğine döner")
	var despawned := 0
	var spawned := 0
	for e in session.poll_events():
		match str(e["type"]):
			"despawn":
				despawned += 1
			"spawn":
				spawned += 1
	assert_eq(despawned, 4, "eski gölgeler kalkar")
	assert_eq(spawned, 4, "yenileri doğar")


## Teknik ancak boşa dönünce değişir (olta sudayken değil); atış eski takımla biter.
func test_technique_changes_only_when_idle() -> void:
	var session := _session()
	session.technique = _Other.new(content().rules)
	var old_gear := session.gear
	assert_true(session.cast(Vector2(0, 0)), "atış")
	var next := GearStats.starter(content())
	session.set_gear(next)
	assert_true(session.technique is _Other, "olta suda: teknik değişmez")
	assert_true(session.gear == old_gear, "atış eski takımla sürer")
	for i in 120:
		session.step()
		if session.state == FishingSession.State.WAITING:
			break
	assert_eq(session.state, FishingSession.State.WAITING, "şamandıra suda")
	session.press()
	session.release()
	for i in 120:
		session.step()
		if session.state == FishingSession.State.IDLE:
			break
	assert_eq(session.state, FishingSession.State.IDLE, "geri sarıldı")
	assert_true(session.technique is FloatTechnique, "boşa dönünce değişir")
	assert_true(session.gear == next, "boşa dönünce yeni takım kuşanılır")


## Testte başka bir tekniği taklit eder (davranışı şamandıranınki, kimliği farklı).
class _Other extends FloatTechnique:
	func _init(fishing_rules: FishingRules) -> void:
		super(fishing_rules)
		id = "other"
