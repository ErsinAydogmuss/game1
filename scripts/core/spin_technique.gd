class_name SpinTechnique
extends Technique
## Spin (Dalga 3, rütbe 2; docs/gdd.md §10.3): yapay yem atılır. Basılı tutunca yem balıkçıya
## gelir, bırakınca durur ve batar. Yırtıcı yalnızca oynayan yemi fark eder (bırakınca kısa bir
## süre daha), peşine düşer (FOLLOWING) ve "dur-kalk" ritminde saldırır: izlerken her duruşta ve
## kalkışta bir zar, belli sayıda ritim değişiminden sonra kesin; ritimsiz çekişte seyrek. Saldırı
## anında basılıysa balık kendiliğinden takılır, değilse kısa bir VUR anı açılır. Uzun bekletilen
## yemden balık vazgeçer; otlu ve kayalık yerde (bölgenin snag_s'i) bekleyen yem takılır (yalnızca
## zaman kaybı). Yem balıkçıya gelince atış biter. Sayılar rules.json techniques.spin; zarlar
## izleyen balığın kendi zarından (aynı girdilerle aynı sonuç).

## Yemin geliş hızı (m/sn; makaradan bağımsız: balık yetişebilsin).
var lure_speed: float = 0.8
## Bırakılan yemi balıklar bu kadar adım daha fark eder.
var grace_steps: int = 30
var min_cast_m: float = 2.0
## Yem balıkçıya bu kadar yaklaşınca atış biter (m).
var end_m: float = 1.2
## Saldırı kuralı: balık bu kadar izlemeden saldırmaz; bir ritim evresi (basılı ya da bırakılı) en
## az min_phase sürmeli; duruşta ve kalkışta zar; sure_after'ıncı değişimde kesin; kesintisiz
## basılı tutarken steady_steps'te bir zar.
var min_follow_steps: int = 36
var min_phase_steps: int = 15
var stop_ppm: int = 400_000
var go_ppm: int = 300_000
var steady_steps: int = 60
var steady_ppm: int = 120_000
var sure_after: int = 4
## Yem bu kadar adım durursa ya da balık bu kadar izlerse vazgeçer.
var rest_lose_steps: int = 180
var follow_max_steps: int = 600
## Takılan yemi kurtarmak (geri sarma süresi, adım).
var snag_steps: int = 150

# Atış başına durum.
## Yem en son kaç adım önce hareket etti.
var _since_move: int = 0
## Yemin kesintisiz durduğu adım (takılma, vazgeçme).
var _rest: int = 0
## Şimdiki ritim evresinin (basılı ya da bırakılı) süresi.
var _phase: int = 0
## Balığın izlediği adım, sayılan ritim değişimleri, kesintisiz basılı adım.
var _follow: int = 0
var _changes: int = 0
var _steady: int = 0


func _init(fishing_rules: FishingRules) -> void:
	super(fishing_rules, "spin")
	lure_speed = rig.num("lure_speed", lure_speed)
	grace_steps = rig.steps("moving_grace", 0.5)
	min_cast_m = rig.num("min_cast_m", min_cast_m)
	end_m = rig.num("end_m", end_m)
	min_follow_steps = rig.steps("strike.min_follow", 0.6)
	min_phase_steps = rig.steps("strike.min_phase", 0.25)
	stop_ppm = rig.ppm("strike.stop", 0.4)
	go_ppm = rig.ppm("strike.go", 0.3)
	steady_steps = maxi(1, rig.steps("strike.steady_every", 1.0))
	steady_ppm = rig.ppm("strike.steady", 0.12)
	sure_after = maxi(1, int(rig.num("strike.sure_after", 4)))
	rest_lose_steps = rig.steps("strike.rest_lose", 3.0)
	follow_max_steps = rig.steps("strike.follow_max", 10.0)
	snag_steps = rig.steps("snag_cost", 2.5)


func min_cast(_s: FishingSession) -> float:
	return min_cast_m


func land(s: FishingSession) -> void:
	s.land_rig()
	for e in s.sim.scare(s.bobber, s.gear.stealth):
		s.push_event(e)
	_since_move = grace_steps + 1
	_rest = 0
	_phase = 0
	_reset_follow()


func step(s: FishingSession) -> void:
	match s.state:
		FishingSession.State.WAITING:
			s.waiting_steps += 1
			if _reel_lure(s):
				_check_snag(s)
		FishingSession.State.FOLLOWING:
			s.waiting_steps += 1
			if _reel_lure(s):
				_follow_step(s)
		FishingSession.State.BITING:
			s.bite_steps += 1
			if s.bite_steps >= s.window:
				s.missed()


## Yalnızca oynayan (ya da az önce duran) yemi fark ederler.
func listening(s: FishingSession) -> bool:
	return s.state == FishingSession.State.WAITING and (s.holding or _since_move <= grace_steps)


func on_arrive(s: FishingSession, fish: FishShadow, _e: Dictionary) -> void:
	if s.state == FishingSession.State.WAITING and fish == s.sim.approacher:
		s.state = FishingSession.State.FOLLOWING
		_reset_follow()
		s.push_event({ "type": "follow", "shadow": fish.id })
	else:
		s.sim.lose_interest(fish)


## Kalkış (yem yeniden oynar): izleyen balık için bir ritim değişimi.
func press(s: FishingSession) -> void:
	match s.state:
		FishingSession.State.FOLLOWING:
			_change(s, go_ppm)
		FishingSession.State.BITING:
			s.hook_fish()
	_phase = 0


## Duruş (yem batar): izleyen balık için bir ritim değişimi.
func release(s: FishingSession) -> void:
	if s.state == FishingSession.State.FOLLOWING:
		_change(s, stop_ppm)
	_phase = 0


func action_kind(s: FishingSession) -> String:
	match s.state:
		FishingSession.State.WAITING, FishingSession.State.FOLLOWING:
			return "reel"
		FishingSession.State.BITING:
			return "hook"
	return ""


func uses_bait() -> bool:
	return false


# --- İç işler ----------------------------------------------------------------------

func _reset_follow() -> void:
	_follow = 0
	_changes = 0
	_steady = 0


## Basılıysa yemi balıkçıya doğru getirir. Yem geldiyse (balıkçının dibine ya da kıyıya) atış
## biter: false.
func _reel_lure(s: FishingSession) -> bool:
	_phase += 1
	if not s.holding:
		_since_move += 1
		_rest += 1
		return true
	var to := s.angler - s.bobber
	var d := to.length()
	var next := s.bobber + to / maxf(d, 0.0001) * lure_speed * FishingSession.STEP
	if d <= end_m or not s.lake.is_water(next) or s.lake.on_dock(next) \
			or s.lake.shore_distance(next) < s.rules.min_shore:
		_end(s, "home", -1)
		return false
	s.bobber = next
	_since_move = 0
	_rest = 0
	return true


## İzleyen balık: kesintisiz basılı tutunca seyrek saldırır; uzun bekletilen yemden ve uzun
## izlemeden sonra vazgeçer.
func _follow_step(s: FishingSession) -> void:
	var fish := s.sim.approacher
	if fish == null:
		s.state = FishingSession.State.WAITING
		return
	_follow += 1
	if s.holding:
		_steady += 1
		if _follow >= min_follow_steps and _steady >= steady_steps:
			_steady = 0
			if Dice.chance(fish.rng, steady_ppm):
				_strike(s, fish)
				return
	else:
		_steady = 0
		if _rest >= rest_lose_steps:
			_turn_away(s, fish)
			_check_snag(s)
			return
	if _follow >= follow_max_steps:
		_turn_away(s, fish)
		return
	_check_snag(s)


## Ritim değişimi (dur ya da kalk): evre yeterince sürdüyse ve balık yeterince izlediyse zar.
func _change(s: FishingSession, chance_ppm: int) -> void:
	var fish := s.sim.approacher
	if fish == null or _phase < min_phase_steps or _follow < min_follow_steps:
		return
	_changes += 1
	if _changes >= sure_after or Dice.chance(fish.rng, chance_ppm):
		_strike(s, fish)


## Saldırı: basılıysa balık kendiliğinden takılır; değilse VUR anı.
func _strike(s: FishingSession, fish: FishShadow) -> void:
	if s.holding:
		s.push_event({ "type": "strike", "shadow": fish.id, "auto": true })
		s.hook_fish()
	else:
		s.open_window("strike", { "auto": false })


func _turn_away(s: FishingSession, fish: FishShadow) -> void:
	s.sim.lose_interest(fish)
	# Bu atışın yemini yeniden fark etmez (yeni atışta unutur: ShadowSim.scare).
	fish.bored = true
	s.state = FishingSession.State.WAITING
	_reset_follow()
	s.push_event({ "type": "turn_away", "shadow": fish.id })


## Otlu ya da kayalık yerde bekleyen yem takılır: geri sarma uzun sürer (yalnızca zaman kaybı).
func _check_snag(s: FishingSession) -> void:
	if s.state != FishingSession.State.WAITING and s.state != FishingSession.State.FOLLOWING:
		return
	var limit := float(s.zone_def(s.lake.zone_at(s.bobber)).get("snag_s", 0.0))
	if limit > 0.0 and _rest >= FishingRules.to_steps(limit):
		s.push_event({ "type": "snag" })
		_end(s, "snag", snag_steps)


## Atış biter (izleyen balık varsa vazgeçer).
func _end(s: FishingSession, reason: String, retrieve_steps: int) -> void:
	var fish := s.sim.approacher
	if s.state == FishingSession.State.FOLLOWING and fish != null:
		_turn_away(s, fish)
	s.retrieve(retrieve_steps, reason)
