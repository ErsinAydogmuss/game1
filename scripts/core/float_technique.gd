class_name FloatTechnique
extends Technique
## Şamandıra (v0.1'den beri oyunun tekniği): şamandıra düştüğü yerde durur; yakına düşerse
## gölge korkar. Fark eden balık yaklaşır, 0–3 kez dürter, ısırır; ısırınca vuruş penceresinde
## dokunulur. Beklerken dokunmak oltayı geri sarar, dürtmede erken sayılır. Kurallar ve zarlar
## v0.3'tekinin aynısı (altın test: tests/fixtures/golden_home_lake.json).


func _init(fishing_rules: FishingRules) -> void:
	super(fishing_rules, "float")


func land(s: FishingSession) -> void:
	s.land_rig()
	for e in s.sim.scare(s.bobber, s.gear.stealth):
		s.push_event(e)


func step(s: FishingSession) -> void:
	match s.state:
		FishingSession.State.WAITING:
			s.waiting_steps += 1
		FishingSession.State.NIBBLING:
			s.timer -= 1
			if s.timer <= 0:
				s.next_nibble()
		FishingSession.State.BITING:
			s.bite_steps += 1
			if s.bite_steps >= s.window:
				s.missed()


func listening(s: FishingSession) -> bool:
	return s.state == FishingSession.State.WAITING


func on_arrive(s: FishingSession, fish: FishShadow, e: Dictionary) -> void:
	if s.state == FishingSession.State.WAITING and fish == s.sim.approacher:
		s.push_event(e)
		s.start_nibbling()
	else:
		s.sim.lose_interest(fish)


func press(s: FishingSession) -> void:
	match s.state:
		FishingSession.State.WAITING:
			s.retrieve()
		FishingSession.State.NIBBLING:
			s.early()
		FishingSession.State.BITING:
			s.hook_fish()


func action_kind(s: FishingSession) -> String:
	match s.state:
		FishingSession.State.WAITING:
			return "retrieve"
		FishingSession.State.NIBBLING:
			return "wait"
		FishingSession.State.BITING:
			return "hook"
	return ""


func roll_nibbles(rng: RandomNumberGenerator) -> int:
	return BiteRules.roll_nibbles(rng, rules)


func roll_gap(rng: RandomNumberGenerator) -> int:
	return BiteRules.roll_gap(rng, rules)


## Şamandıra hassasiyeti (gear.window_add_steps) pencereyi uzatır.
func window(s: FishingSession, fish: FishShadow) -> int:
	return BiteRules.window_steps(rules, s.easy or fish.scripted) + s.gear.window_add_steps
