class_name FlyTechnique
extends Technique
## Sinek (Dalga 3, rütbe 7; docs/gdd.md §10.3): yalnızca akıntılı suda (dere ağzı; bölgenin
## techniques'i). Kuru sinek düştüğü yerden akıntıyla sürüklenir (LakeShape.flow_at × drift).
## Alabalık sineği altından fark eder, altına gelir ve bir süre bekler (NIBBLING: dürtme yok; bu
## sırada dokunmak balığı kaçırır), sonra halka çıkarır ("rise"): vuruş penceresinde dokunulur.
## Sinek durgun suya, kıyıya ya da en uzun sürüklenmenin sonuna gelince kendiliğinden geri sarılır
## (retrieve{drift}; hiç akmayan suya düştüyse retrieve{still}: oyuncuya akıntıya atması söylenir);
## beklerken dokunmak da geri sarar. Yem kullanmaz. Sayılar rules.json
## techniques.fly; zarlar balığın kendi zarından (aynı girdilerle aynı sonuç).

## Sürüklenme: akıntının bu payı (sinek suyun yüzünde, akıntıdan biraz yavaş).
var drift_share: float = 0.85
## Akıntı bundan yavaşsa durgun su (m/sn); sinek bu kadar adım durgun suda kalırsa döner.
var still_speed: float = 0.08
var still_steps: int = 90
## En uzun sürüklenme (bekleme adımı).
var drift_max_steps: int = 900
var min_cast_m: float = 3.0
## Geri sarma süresi (adım; sinek hafif, çabuk gelir).
var retrieve_steps: int = 48

## Sineğin kesintisiz durgun suda kaldığı adım; düştüğünden beri akıntıya kapıldı mı.
var _still: int = 0
var _flowed: bool = false


func _init(fishing_rules: FishingRules) -> void:
	super(fishing_rules, "fly")
	drift_share = rig.num("drift", drift_share)
	still_speed = rig.num("still_speed", still_speed)
	still_steps = rig.steps("still_s", 1.5)
	drift_max_steps = rig.steps("drift_max_s", 15.0)
	min_cast_m = rig.num("min_cast_m", min_cast_m)
	retrieve_steps = rig.steps("retrieve", 0.8)


func min_cast(_s: FishingSession) -> float:
	return min_cast_m


## Sinek suya konar: yakındaki gölgeler ürker (görünmezlik payıyla).
func land(s: FishingSession) -> void:
	s.land_rig()
	for e in s.sim.scare(s.bobber, s.gear.stealth):
		s.push_event(e)
	_still = 0
	_flowed = false


func step(s: FishingSession) -> void:
	match s.state:
		FishingSession.State.WAITING:
			s.waiting_steps += 1
			_drift(s)
		FishingSession.State.NIBBLING:
			# Balık sineğin altında, onunla birlikte sürüklenir (rig.follow_speed); halka sırası.
			if not _drift(s):
				return
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
			s.retrieve(retrieve_steps)
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


func bite_event() -> String:
	return "rise"


func uses_bait() -> bool:
	return false


## Sinek akıntıyla bir adım sürüklenir. Kıyıya (ya da iskeleye) varınca, durgun suda kalınca ya da
## en uzun sürüklenmenin sonunda geri sarılır: false. Hiç akmayan suya düşen sinek "still" nedeniyle
## döner.
func _drift(s: FishingSession) -> bool:
	var flow := s.lake.flow_at(s.bobber) * drift_share
	var next := s.bobber + flow * FishingSession.STEP
	if not s.lake.is_water(next) or s.lake.on_dock(next) or s.lake.shore_distance(next) < s.rules.min_shore:
		s.retrieve(retrieve_steps, "drift")
		return false
	s.bobber = next
	if flow.length() < still_speed:
		_still += 1
	else:
		_still = 0
		_flowed = true
	if _still >= still_steps or s.waiting_steps >= drift_max_steps:
		s.retrieve(retrieve_steps, "drift" if _flowed else "still")
		return false
	return true
