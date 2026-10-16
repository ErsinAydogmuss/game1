class_name ShadowSim
extends RefCounted
## Göldeki balık gölgeleri: doğma, dolaşma, duraklama, fark etme, yaklaşma, kaçma ve yeniden
## doğma. Aynı anda en fazla max_shadows gölge; eksilenin yerine respawn aralığında yenisi
## gelir. Aynı anda yalnızca bir balık yaklaşır (approacher). Her adım 1/60 sn.
## Gölgeler yalnızca derin suda (min_depth) dolaşır ve iskelenin altına girmez.

const STEP := 1.0 / FishingRules.HZ
## Yolu kapalı (kıyı arada) bir balık bu kadar adım sonra vazgeçer (ilk av vazgeçmez).
const GIVE_UP_STEPS := 20 * FishingRules.HZ
## Önü kapalıysa denenecek sapma açıları (radyan): kıyı boyunca kayar.
const DETOURS := [0.5, -0.5, 1.0, -1.0, 1.5, -1.5]

var shadows: Array[FishShadow] = []
## Şamandıraya yaklaşan (ya da dürten) gölge.
var approacher: FishShadow = null

var _db: ContentDB
var _rules: FishingRules
var _lake: LakeShape
var _spot: Dictionary
var _seed: int = 0
var _serial: int = 0
var _max: int = 4
## Bekleyen doğumlar: her biri için kalan adım.
var _pending := PackedInt32Array()
## Sıradaki gölge ilk av mı (senaryolu)?
var _first_pending: bool = false


func _init(db: ContentDB, spot: Dictionary, lake: LakeShape, seed: int, first_catch: bool,
		angler: Vector2) -> void:
	_db = db
	_rules = db.rules
	_lake = lake
	_spot = spot
	_seed = seed
	_max = int(spot.get("max_shadows", 4))
	_first_pending = first_catch
	for i in _max:
		_spawn(angler, Vector2.ZERO, false)


## Bir adım. listening: şamandıra suda ve balık bekliyor (fark etme açık).
## waiting_steps: şamandıra kaç adımdır suda. Olayları döndürür (spawn, despawn, notice, arrive).
func step(angler: Vector2, bobber: Vector2, listening: bool, waiting_steps: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for i in range(_pending.size() - 1, -1, -1):
		_pending[i] -= 1
		if _pending[i] <= 0:
			_pending.remove_at(i)
			var born := _spawn(angler, bobber, listening)
			if born != null:
				out.append({ "type": "spawn", "shadow": born.id })
			else:
				_pending.append(FishingRules.HZ)
	for s: FishShadow in shadows.duplicate():
		match s.mode:
			FishShadow.Mode.WANDER:
				_wander(s)
			FishShadow.Mode.PAUSE:
				s.timer -= 1
				if s.timer <= 0:
					_pick_target(s, bobber, listening, waiting_steps)
			FishShadow.Mode.APPROACH:
				s.timer += 1
				if _approach(s, bobber):
					s.mode = FishShadow.Mode.NIBBLE
					out.append({ "type": "arrive", "shadow": s.id })
				elif not s.scripted and s.timer > GIVE_UP_STEPS:
					lose_interest(s)
			FishShadow.Mode.FLEE:
				_flee_step(s)
				s.timer -= 1
				if s.timer <= 0:
					remove(s)
					out.append({ "type": "despawn", "shadow": s.id })
	if listening and approacher == null:
		# İlk av gölde oldukça şamandıraya yalnızca o gelir.
		var only_scripted := _has_scripted()
		var best: FishShadow = null
		var best_d := INF
		for s in shadows:
			if s.mode != FishShadow.Mode.WANDER and s.mode != FishShadow.Mode.PAUSE:
				continue
			if only_scripted and not s.scripted:
				continue
			if not (s.scripted or BiteRules.notices(s, bobber, _rules)):
				continue
			var d := s.pos.distance_squared_to(bobber)
			if d < best_d:
				best = s
				best_d = d
		if best != null:
			approacher = best
			best.mode = FishShadow.Mode.APPROACH
			best.timer = 0
			out.append({ "type": "notice", "shadow": best.id })
	return out


## Şamandıra point'e düştü: yakındaki gölgeler korkup kaçar (ilk av korkmaz).
func scare(point: Vector2) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for s in shadows:
		if s.scripted or s.mode == FishShadow.Mode.FLEE or s.mode == FishShadow.Mode.HOOKED:
			continue
		if BiteRules.scares(s, point, _rules):
			flee(s, point)
			out.append({ "type": "scare", "shadow": s.id })
	return out


## Gölge from'dan uzağa kaçar, sonra kaybolur.
func flee(s: FishShadow, from: Vector2) -> void:
	var away := s.pos - from
	s.heading = away.normalized() if away.length_squared() > 0.0001 else -s.heading
	s.mode = FishShadow.Mode.FLEE
	s.timer = _rules.flee_steps
	if approacher == s:
		approacher = null


## Yaklaşan balık ilgisini kaybeder (oyuncu oltayı geri sardı).
func lose_interest(s: FishShadow) -> void:
	s.mode = FishShadow.Mode.PAUSE
	s.timer = Dice.between(s.rng, _rules.pause_steps)
	if approacher == s:
		approacher = null


## Balık oltaya takıldı: çekişme bitene kadar sim onu yönetmez.
func hook(s: FishShadow) -> void:
	s.mode = FishShadow.Mode.HOOKED
	if approacher == s:
		approacher = null


## Gölgeyi gölden çıkarır (tutuldu ya da kaçtı) ve yerine yenisinin doğmasını planlar.
func remove(s: FishShadow) -> void:
	shadows.erase(s)
	if approacher == s:
		approacher = null
	_pending.append(Dice.between(s.rng, _rules.respawn_steps))


func find(id: int) -> FishShadow:
	for s in shadows:
		if s.id == id:
			return s
	return null


## Bekleyen doğumlar (test ve hata ayıklama için).
func pending_spawns() -> int:
	return _pending.size()


# --- İç işler ----------------------------------------------------------------------

func _has_scripted() -> bool:
	for s in shadows:
		if s.scripted:
			return true
	return false


func _spawn(angler: Vector2, bobber: Vector2, bobber_active: bool) -> FishShadow:
	if shadows.size() >= _max:
		return null
	var s := FishShadow.new()
	s.id = _serial
	_serial += 1
	s.seed = Dice.derive(_seed, s.id)
	s.rng.seed = s.seed
	var ids: PackedStringArray = _spot["fish_ids"]
	var scripted := _first_pending
	var fish_id := str(_spot.get("first_fish", ids[0])) if scripted else ids[FishTable.roll_species(s.rng, _spot["fish_weights"])]
	s.fish_index = _db.fish_index(fish_id)
	var def := _db.fish_def(s.fish_index)
	s.fish_id = fish_id
	s.rarity = int(def["rarity"])
	s.percentile = FishTable.roll_percentile(s.rng)
	s.size_cm = FishTable.size_cm(def, s.percentile)
	s.stars = FishTable.stars(s.percentile)
	s.length = FishTable.shadow_length(def, s.percentile)
	s.speed = s.rng.randf_range(_rules.shadow_speed.x, _rules.shadow_speed.y)
	if scripted:
		var first: Dictionary = _spot["first_shadow"]
		s.scripted = true
		s.pos = first["pos"]
		s.home = s.pos
		s.heading = first["heading"]
		s.mode = FishShadow.Mode.PAUSE
		s.timer = FishingRules.HZ
		_first_pending = false
	else:
		var p := _spawn_point(s.rng, angler, bobber, bobber_active)
		if not Dice.is_point(p):
			return null
		s.pos = p
		s.home = p
		s.heading = Dice.direction(s.rng)
		s.mode = FishShadow.Mode.PAUSE
		s.timer = Dice.between(s.rng, _rules.pause_steps)
	shadows.append(s)
	return s


func _spawn_point(rng: RandomNumberGenerator, angler: Vector2, bobber: Vector2, bobber_active: bool) -> Vector2:
	var bounds := _lake.water_bounds
	for strict: bool in [true, false]:
		for attempt in 40:
			var p := Vector2(rng.randf_range(bounds.position.x, bounds.end.x),
					rng.randf_range(bounds.position.y, bounds.end.y))
			if not _lake.is_deep(p, _rules.min_depth):
				continue
			if strict:
				if p.distance_to(angler) < _rules.spawn_from_angler:
					continue
				if bobber_active and p.distance_to(bobber) < 2.5:
					continue
				var crowded := false
				for o in shadows:
					if o.pos.distance_to(p) < _rules.spacing:
						crowded = true
						break
				if crowded:
					continue
			return p
	return Dice.NO_POINT


## Yeni bir dolaşma hedefi seçer. Şamandıra uzun süredir sudaysa gölgeler (yarı yarıya) onun
## çevresine yönelir; ilk av evinin yakınında dolaşır.
func _pick_target(s: FishShadow, bobber: Vector2, listening: bool, waiting_steps: int) -> void:
	var lure := listening and waiting_steps >= _rules.lure_after_steps and Dice.chance(s.rng, _rules.lure_ppm)
	var bounds := _lake.water_bounds
	for attempt in 12:
		var p: Vector2
		if lure:
			p = bobber + Dice.in_disc(s.rng, _rules.lure_radius)
		elif s.scripted:
			p = s.home + Dice.in_disc(s.rng, 1.5)
		else:
			p = Vector2(s.rng.randf_range(bounds.position.x, bounds.end.x),
					s.rng.randf_range(bounds.position.y, bounds.end.y))
		if _lake.is_deep(p, _rules.min_depth) and _lake.segment_is_deep(s.pos, p, _rules.min_depth * 0.75):
			s.target = p
			s.mode = FishShadow.Mode.WANDER
			return
	s.mode = FishShadow.Mode.PAUSE
	s.timer = FishingRules.HZ


func _wander(s: FishShadow) -> void:
	var to := s.target - s.pos
	var d := to.length()
	if d < 0.15:
		s.mode = FishShadow.Mode.PAUSE
		s.timer = Dice.between(s.rng, _rules.pause_steps)
		return
	_turn(s, to / d, _rules.turn)
	var next := s.pos + s.heading * s.speed * STEP
	if _lake.is_deep(next, _rules.min_depth * 0.75):
		s.pos = next
	else:
		s.mode = FishShadow.Mode.PAUSE
		s.timer = FishingRules.HZ >> 1


## Şamandıraya doğru yüzer; ağzı şamandıraya değince true. Önü kıyıysa kenarından kayar.
func _approach(s: FishShadow, bobber: Vector2) -> bool:
	var to := bobber - s.pos
	var d := to.length()
	var stop := s.length * 0.5
	if d <= stop + 0.05:
		return true
	_turn(s, to / d, _rules.turn * 2.0)
	var step_len := minf(_rules.approach_speed * STEP, d - stop)
	var next := s.pos + s.heading * step_len
	if _lake.is_water(next):
		s.pos = next
		return false
	for angle: float in DETOURS:
		var dir := s.heading.rotated(angle)
		next = s.pos + dir * step_len
		if _lake.is_water(next):
			s.pos = next
			s.heading = dir
			return false
	return false


func _flee_step(s: FishShadow) -> void:
	var next := s.pos + s.heading * _rules.flee_speed * STEP
	if _lake.is_water(next) and not _lake.on_dock(next, 0.3):
		s.pos = next


## Yönü istenen yöne doğru yumuşakça çevirir (trigonometri yok: normalize edilmiş karışım).
func _turn(s: FishShadow, desired: Vector2, rate: float) -> void:
	var h := s.heading.lerp(desired, minf(1.0, rate * STEP))
	if h.length_squared() < 0.000001:
		h = Vector2(-s.heading.y, s.heading.x)
	s.heading = h.normalized()
