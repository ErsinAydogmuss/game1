class_name FishingSession
extends RefCounted
## Bir balık tutma oturumu: BOŞ → ATIŞ → BEKLEME → DÜRTME → ISIRMA → ÇEKİŞME → TUTULDU / KAÇTI.
## Saf mantık (Node yok). Sunum her karede advance(delta) çağırır, olayları poll_events() ile
## alır, gölgeleri `sim.shadows`'tan okur. İç adım sabit 1/60 sn: aynı girdilerle her fps'te ve
## video kaydında aynı sonuç çıkar.
##
## Girdiler:
## - angler: balıkçının yeri (sunum her karede yazar).
## - cast(hedef): yalnızca BOŞ durumda. Hedef karadaysa ya da menzil dışındaysa şamandıra yine
##   suya düşer; çizgide hiç su yoksa false (sunum o zaman yürür).
## - press() / release(): eylem; parmak değdiği an işler. Beklerken oltayı geri sarar, dürtmede
##   erken sayılır, ısırmada VUR, çekişmede basılı tutunca sarar.
## - acknowledge(): yakalanan balığın kartı kapandı; yeni atış serbest.
##
## Olaylar (sözlük; "type" ve "step" alanlı):
## cast {from, to, steps} · land {pos} · scare {shadow} · notice {shadow} · arrive {shadow} ·
## nibble {shadow, index} · bite {shadow} · early {shadow, startle} · retry {shadow} (ilk av
## kaçırılınca yeniden ısıracak) · hook {shadow, fish, distance} · warn · burst · burst_end ·
## strain · strain_end · lost {reason: early | missed | snapped | escaped} ·
## catch {fish, fish_index, size_cm, stars, rarity, percentile, shadow} · retrieve · idle ·
## spawn {shadow} · despawn {shadow}

enum State { IDLE, CASTING, WAITING, NIBBLING, BITING, FIGHTING, RETRIEVING, CAUGHT, LOST }

const STEP := 1.0 / FishingRules.HZ
## Bir karede en fazla bu kadar adım (uzun bir takılmadan sonra oyun "koşmasın").
const MAX_STEPS_PER_FRAME := 30
## Çekişmede balık kıyıya bu kadar yaklaşabilir (m): şamandıra ve gölge karaya çizilmez.
const FIGHT_SHORE := 0.3

var state: State = State.IDLE
## Toplam adım (oturum saati).
var steps: int = 0
var angler := Vector2.ZERO
var bobber := Vector2.ZERO
var cast_from := Vector2.ZERO
var easy: bool = false
## Parmak (ya da eylem tuşu) basılı mı?
var holding: bool = false
var sim: ShadowSim
## Çekişme sürerken dolu.
var reel: ReelModel
var hooked: FishShadow
## Oltaya takılan balığın yönü (balıkçıdan şamandıraya).
var hook_dir := Vector2(0.0, -1.0)
## Çekişmede balığın hook_dir yönünde gidebileceği en uzak su (balıkçıdan uzaklık, m).
var fight_reach: float = 0.0
## Son yakalanan balık (catch olayının içeriği) ve son kaçırma nedeni.
var last_catch: Dictionary = {}
var last_loss: String = ""
var lake: LakeShape
var rules: FishingRules

var _db: ContentDB
var _rod: Dictionary
var _acc: float = 0.0
var _timer: int = 0
var _waiting_steps: int = 0
var _nibbles_left: int = 0
var _nibble_index: int = 0
var _bite_steps: int = 0
var _window: int = 60
var _events: Array[Dictionary] = []


## seed: oturum tohumu (Dice.derive(kayıt seed'i, oturum sayısı)). first_catch: ilk av
## senaryolu olsun (oyuncu henüz balık tutmadı).
func _init(db: ContentDB, spot_id: String, rod_id: String, seed: int, easy_mode: bool,
		first_catch: bool) -> void:
	_db = db
	rules = db.rules
	_rod = db.rod(rod_id)
	var spot := db.spot(spot_id)
	lake = db.lake(spot_id)
	angler = spot.get("start", Vector2.ZERO)
	easy = easy_mode
	sim = ShadowSim.new(db, spot, lake, seed, first_catch, angler)


## Gerçek zamanı sabit adımlara çevirir.
func advance(delta: float) -> void:
	_acc = minf(_acc + maxf(delta, 0.0), STEP * MAX_STEPS_PER_FRAME)
	while _acc >= STEP - 0.000001:
		_acc -= STEP
		step()


## Tek bir sabit adım (1/60 sn). Testler doğrudan çağırabilir.
func step() -> void:
	steps += 1
	match state:
		State.CASTING:
			_timer -= 1
			if _timer <= 0:
				_land()
		State.WAITING:
			_waiting_steps += 1
		State.NIBBLING:
			_timer -= 1
			if _timer <= 0:
				_next_nibble()
		State.BITING:
			_bite_steps += 1
			if _bite_steps >= _window:
				_missed()
		State.FIGHTING:
			_step_fight()
		State.RETRIEVING, State.LOST:
			_timer -= 1
			if _timer <= 0:
				_to_idle()
	var listening := state == State.WAITING
	for e in sim.step(angler, bobber, listening, _waiting_steps):
		if str(e["type"]) != "arrive":
			_emit(e)
			continue
		var s := sim.find(int(e["shadow"]))
		if s == null:
			continue
		if state == State.WAITING and s == sim.approacher:
			_emit(e)
			_start_nibbling()
		else:
			sim.lose_interest(s)


func poll_events() -> Array[Dictionary]:
	var out := _events
	_events = []
	return out


# --- Girdiler --------------------------------------------------------------------------

func cast(target: Vector2) -> bool:
	if state != State.IDLE:
		return false
	var range_m: float = _rod["range_m"]
	var point := lake.landing_point(angler, target, range_m, rules.min_shore)
	if not Dice.is_point(point) or angler.distance_to(point) < rules.min_cast:
		return false
	cast_from = angler
	bobber = point
	var dist := angler.distance_to(point)
	_timer = maxi(1, FishingRules.to_steps(rules.flight_base + rules.flight_per_m * dist))
	state = State.CASTING
	_emit({ "type": "cast", "from": angler, "to": point, "steps": _timer })
	return true


func press() -> void:
	holding = true
	match state:
		State.WAITING:
			_retrieve()
		State.NIBBLING:
			_early()
		State.BITING:
			_hook()
		State.FIGHTING:
			reel.holding = true


func release() -> void:
	holding = false
	if state == State.FIGHTING:
		reel.holding = false


func acknowledge() -> void:
	if state == State.CAUGHT:
		_to_idle()


# --- Sunum için sorgular ---------------------------------------------------------------

## Olta suda mı (ekranın her yeri eylem düğmesi)?
func line_out() -> bool:
	return state in [State.CASTING, State.WAITING, State.NIBBLING, State.BITING, State.FIGHTING]


## Eylem düğmesinin şu anki işi: cast, retrieve, wait (dürtme: dokunma!), hook, reel ya da "".
func action_kind() -> String:
	match state:
		State.IDLE:
			return "cast"
		State.WAITING:
			return "retrieve"
		State.NIBBLING:
			return "wait"
		State.BITING:
			return "hook"
		State.FIGHTING:
			return "reel"
	return ""


## Çekişmede balığın yeri (balıkçıdan hook_dir yönünde, reel.distance uzakta; suyun bittiği
## yerin ötesine çizilmez).
func fight_point() -> Vector2:
	if reel == null:
		return bobber
	return angler + hook_dir * minf(reel.distance, fight_reach)


func range_m() -> float:
	return float(_rod["range_m"])


func state_name() -> String:
	return str(State.find_key(state)).to_lower()


func seconds() -> float:
	return float(steps) / FishingRules.HZ


# --- Durum geçişleri -------------------------------------------------------------------

func _emit(e: Dictionary) -> void:
	e["step"] = steps
	_events.append(e)


func _land() -> void:
	state = State.WAITING
	_waiting_steps = 0
	_emit({ "type": "land", "pos": bobber })
	for e in sim.scare(bobber):
		_emit(e)


func _retrieve() -> void:
	if sim.approacher != null:
		sim.lose_interest(sim.approacher)
	state = State.RETRIEVING
	_timer = maxi(1, rules.retrieve_steps)
	_emit({ "type": "retrieve" })


func _start_nibbling() -> void:
	var s := sim.approacher
	state = State.NIBBLING
	_nibbles_left = 0 if s.scripted else BiteRules.roll_nibbles(s.rng, rules)
	_nibble_index = 0
	_timer = BiteRules.roll_gap(s.rng, rules)


func _next_nibble() -> void:
	var s := sim.approacher
	if _nibbles_left > 0:
		_nibbles_left -= 1
		_nibble_index += 1
		_emit({ "type": "nibble", "shadow": s.id, "index": _nibble_index })
		_timer = BiteRules.roll_gap(s.rng, rules)
	else:
		state = State.BITING
		_bite_steps = 0
		_window = BiteRules.window_steps(rules, easy or s.scripted)
		_emit({ "type": "bite", "shadow": s.id })


func _early() -> void:
	var s := sim.approacher
	if BiteRules.early_outcome(easy, s.scripted, s.startles) == "startle":
		s.startles += 1
		# İlk av sözünü tutar: sık sık dokunan çocuk da ısırmayı görsün (sayaç baştan başlamaz).
		if not s.scripted:
			_timer = BiteRules.roll_gap(s.rng, rules)
		_emit({ "type": "early", "shadow": s.id, "startle": true })
		return
	_emit({ "type": "early", "shadow": s.id, "startle": false })
	sim.flee(s, bobber)
	_lose("early")


func _missed() -> void:
	var s := sim.approacher
	if s.scripted:
		# İlk av: balık gitmez, biraz sonra yeniden ısırır.
		state = State.NIBBLING
		_nibbles_left = 0
		_timer = BiteRules.roll_gap(s.rng, rules)
		_emit({ "type": "retry", "shadow": s.id })
		return
	sim.flee(s, bobber)
	_lose("missed")


func _hook() -> void:
	var s := sim.approacher
	hooked = s
	sim.hook(s)
	var offset := bobber - angler
	hook_dir = offset.normalized() if offset.length_squared() > 0.0001 else Vector2(0.0, -1.0)
	var dist := offset.length()
	var fight: Dictionary = _db.fish_def(s.fish_index)["fight"]
	# Balık kıyıya kadar kaçabilir; ama şamandıranın en az escape_extra ötesine (kıyı yakınsa
	# çizimi kıyıda durur), en çok menzil + escape_extra'ya.
	var cap := range_m() + rules.escape_extra
	fight_reach = _water_reach(dist, cap)
	reel = ReelModel.new(rules, fight, float(_rod["reel_speed"]), dist,
			clampf(fight_reach, minf(dist + rules.escape_extra, cap), cap), easy or s.scripted, Dice.derive(s.seed, 1))
	reel.holding = holding
	state = State.FIGHTING
	_emit({ "type": "hook", "shadow": s.id, "fish": s.fish_id, "distance": dist })


## Balıkçıdan hook_dir yönünde, from_dist'ten dışarı doğru suyun sürdüğü en uzak uzaklık
## (kıyıdan FIGHT_SHORE payıyla, en çok cap).
func _water_reach(from_dist: float, cap: float) -> float:
	var d := from_dist
	while d + 0.1 <= cap:
		var p := angler + hook_dir * (d + 0.1)
		if not lake.is_water(p) or lake.on_dock(p) or lake.shore_distance(p) < FIGHT_SHORE:
			break
		d += 0.1
	return d


func _step_fight() -> void:
	for what in reel.step():
		match what:
			"caught":
				_caught()
				return
			"snap":
				_fight_lost("snapped")
				return
			"escaped":
				_fight_lost("escaped")
				return
			_:
				_emit({ "type": what })
	hooked.pos = fight_point()


func _caught() -> void:
	var s := hooked
	last_catch = {
		"fish": s.fish_id, "fish_index": s.fish_index, "size_cm": s.size_cm, "stars": s.stars,
		"rarity": s.rarity, "percentile": s.percentile, "shadow": s.id,
	}
	sim.remove(s)
	hooked = null
	reel = null
	state = State.CAUGHT
	var e := last_catch.duplicate()
	e["type"] = "catch"
	_emit(e)


func _fight_lost(reason: String) -> void:
	hooked.pos = _water_near(fight_point())
	sim.flee(hooked, angler)
	hooked = null
	_lose(reason)


## p karadaysa (balıkçı kıyıdan geriye, balık kıyının ötesine kaçtı) şamandıraya doğru ilk su noktası.
func _water_near(p: Vector2) -> Vector2:
	var count := maxi(1, ceili(p.distance_to(bobber) / 0.1))
	for i in count + 1:
		var q := p.lerp(bobber, float(i) / count)
		if lake.is_water(q):
			return q
	return bobber


func _lose(reason: String) -> void:
	state = State.LOST
	_timer = maxi(1, rules.lost_steps)
	last_loss = reason
	reel = null
	_emit({ "type": "lost", "reason": reason })


func _to_idle() -> void:
	state = State.IDLE
	_emit({ "type": "idle" })
