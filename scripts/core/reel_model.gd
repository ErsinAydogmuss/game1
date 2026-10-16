class_name ReelModel
extends RefCounted
## Çekişme: gerilim, balığın uzaklığı ve patlamalar. Her step() 1/60 sn'dir.
## - Basılı tutunca gerilim bir hedefe doğru yükselir, bırakınca düşer. Balık sakinken hedef
##   (pull) hep sınırın altındadır: sakin balıkta basılı tutmak kırmızıya hiç çıkmaz.
## - Balık zaman zaman çırpınır (patlama). Her patlamadan warn kadar önce "warn" olayı gelir
##   (sunum: çırpınma, misina titremesi, gıcırtı, titreşim, "!"). Patlamada basılı tutunca
##   hedef (burst_pull) sınırın üstündedir.
## - Sınırın üstünde toplam snap_steps kalınırsa misina kopar; sayaç sınırın altında
##   snap_recover hızıyla geri iner.
## - Basılı tutunca (patlama dışında) balık yaklaşır; bırakınca uzaklaşır, patlamada hızla.
##   catch_m'ye gelince tutulur; max_distance'ı geçerse kaçar.
## - Kolay mod: gerilim sınırda durur (kopma yok); patlamada basılı tutunca misina kayar
##   (balık uzaklaşır); balık kaçmaz. Beceri yalnızca hızı belirler.

enum Phase { CALM, WARN, BURST }
enum Outcome { NONE, CAUGHT, SNAPPED, ESCAPED }

## Kopma sayacının birimi: sınır üstündeki her adım UNIT ekler.
const UNIT := 1000
const STEP := 1.0 / FishingRules.HZ

var distance: float = 0.0
var max_distance: float = 11.0
var tension: float = 0.0
var holding: bool = false
var easy: bool = false
var phase: Phase = Phase.CALM
## Evredeki kalan adım.
var phase_steps: int = 0
var outcome: Outcome = Outcome.NONE
var in_red: bool = false
var steps: int = 0
## Kopma sayacı (adım × UNIT).
var over: int = 0

var _rules: FishingRules
var _reel_speed: float = 1.0
var _pull: float = 0.5
var _burst_pull: float = 1.1
var _run: float = 1.0
var _every := Vector2i(120, 180)
var _len := Vector2i(30, 60)
var _recover: int = 350
var _snap_units: int = 48000
var _rng := RandomNumberGenerator.new()


## fight: balığın çekişme ayarları (ContentDB fish["fight"]); rod_reel_speed: oltanın sarma
## hızı (m/sn); seed: patlama zamanlarının zarı.
func _init(rules: FishingRules, fight: Dictionary, rod_reel_speed: float, start_distance: float,
		max_dist: float, easy_mode: bool, seed: int) -> void:
	_rules = rules
	_reel_speed = rod_reel_speed * float(fight["reel"])
	_pull = fight["pull"]
	_burst_pull = fight["burst_pull"]
	_run = fight["run"]
	_every = fight["burst_every_steps"]
	_len = fight["burst_len_steps"]
	_recover = int(round(rules.snap_recover * UNIT))
	_snap_units = rules.snap_steps * UNIT
	_rng.seed = seed
	distance = start_distance
	max_distance = max_dist
	easy = easy_mode
	phase = Phase.CALM
	# first_burst uyarıyı da içerir: ilk patlama tam o anda başlar.
	phase_steps = maxi(1, Dice.between(_rng, rules.first_burst_steps) - rules.warn_steps)


## Bir adım ilerler; bu adımda olanları döndürür: warn, burst, burst_end, strain (gerilim
## kırmızıya girdi), strain_end, snap, caught, escaped.
func step() -> PackedStringArray:
	var out := PackedStringArray()
	if outcome != Outcome.NONE:
		return out
	steps += 1
	phase_steps -= 1
	if phase_steps <= 0:
		match phase:
			Phase.CALM:
				phase = Phase.WARN
				phase_steps = _rules.warn_steps
				out.append("warn")
			Phase.WARN:
				phase = Phase.BURST
				phase_steps = Dice.between(_rng, _len)
				out.append("burst")
			Phase.BURST:
				phase = Phase.CALM
				phase_steps = maxi(1, Dice.between(_rng, _every) - _rules.warn_steps)
				out.append("burst_end")
	var bursting := phase == Phase.BURST
	if holding:
		tension = move_toward(tension, _burst_pull if bursting else _pull, _rules.rise * STEP)
	else:
		tension = move_toward(tension, 0.0, _rules.fall * STEP)
	if easy:
		tension = minf(tension, _rules.limit)
	if bursting:
		if not holding:
			distance += _run * STEP
		elif easy and tension >= _rules.limit:
			distance += _run * _rules.easy_slip * STEP
	elif holding:
		distance -= _reel_speed * STEP
	else:
		distance += _rules.drift * STEP
	var red := tension > _rules.limit
	if red != in_red:
		in_red = red
		out.append("strain" if red else "strain_end")
	if red:
		over += UNIT
	else:
		over = maxi(0, over - _recover)
	if not easy and over >= _snap_units:
		outcome = Outcome.SNAPPED
		out.append("snap")
		return out
	if distance <= _rules.catch_m:
		distance = _rules.catch_m
		outcome = Outcome.CAUGHT
		out.append("caught")
	elif distance >= max_distance:
		if easy:
			distance = max_distance
		else:
			outcome = Outcome.ESCAPED
			out.append("escaped")
	return out


## Kopmaya ne kadar yakın (0..1; sunumdaki kırmızı dolgu).
func strain() -> float:
	return clampf(float(over) / _snap_units, 0.0, 1.0)


## Uyarı ya da patlama sürüyor mu (sunum: çırpınma)?
func thrashing() -> bool:
	return phase != Phase.CALM


func seconds() -> float:
	return float(steps) / FishingRules.HZ
