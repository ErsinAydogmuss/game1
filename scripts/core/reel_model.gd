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
## - Takım (GearStats, isteğe bağlı): kamışın gücü sarmayı hızlandırır ve patlamadaki kaçışı
##   yavaşlatır; makaranın freni patlamadaki gerilimi kırpar; misina kopma süresini, kepçe
##   tutma uzaklığını belirler. Takım verilmezse kurallardaki (bambu olta) sayılar.
## - İri tür (fight.heavy): boy yüzdeliği sakin çekişi size_pull kadar artırır (yine sınırın
##   altında). Yıldızı takımın taşımasını (carry) aşan balık fazla iridir (excess = fazla yıldız):
##   sakinken de basılı tutmak kırmızıya çıkar, patlama sertleşir, bırakınca daha hızlı uzaklaşır.
##   Kolay modda kopmaz, kaçmaz; yalnızca yavaş gelir.
## - Dalışlar (fight.stages; Gölün Bekçisi): balık takıldığı uzaklığın bu paylarına yaklaşınca, sakin
##   evredeyse, "dive_warn" (dive_warn_steps uyarı) ve "dive" gelir: dalış boyunca bırakınca balık dive_run
##   hızla uzaklaşır (en çok kaçma sınırının DIVE_MARGIN içine), basılı tutunca gerilim dive_pull'a (sınırın
##   üstüne) çıkar: koparır. Dalış bitince "dive_end". Kolay modda dalış EASY_DIVE kadar hızlı, kopma yok.
##   Dalışın zarı yalnızca dalışlı balıkta çekilir (öteki balıkların zar sırası aynı kalır).

## Evreler sona eklenir (DIVE_WARN, DIVE: Gölün Bekçisi'nin dalışları).
enum Phase { CALM, WARN, BURST, DIVE_WARN, DIVE }
enum Outcome { NONE, CAUGHT, SNAPPED, ESCAPED }

## Kopma sayacının birimi: sınır üstündeki her adım UNIT ekler.
const UNIT := 1000
## Dalış balığı kaçma sınırına en çok bu kadar (m) yaklaştırır; Kolay modda dalışın hız çarpanı.
const DIVE_MARGIN := 0.5
const EASY_DIVE := 0.6
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
## Fazla iri: iri türün yıldızı takımın taşımasını kaç aşıyor (0: aşmıyor).
var excess: int = 0
## Gerilim sınırı ve basılı tutunca bir adımdaki artış (botlar ve sunum okur).
var limit: float = 0.85
var rise_step: float = 0.04

var _rules: FishingRules
var _reel_speed: float = 1.0
var _pull: float = 0.5
var _burst_pull: float = 1.1
var _run: float = 1.0
var _every := Vector2i(120, 180)
var _len := Vector2i(30, 60)
var _recover: int = 350
var _snap_units: int = 48000
var _catch_m: float = 0.6
var _drift: float = 0.25
## Fazla iride Normal modun değerleri ve Kolay modun sarma hızı (fazla iri değilse temel değerler).
## Mod ayarlardan çekişme sürerken de değişebilir: hangisinin geçerli olduğuna her adımda bakılır.
var _strained_pull: float = 0.5
var _strained_burst: float = 1.1
var _strained_drift: float = 0.25
var _easy_reel: float = 1.0
## Dalışlar: kalan paylar (uzaklık takıldığı uzaklığın bu payına inince), takıldığı uzaklık, uyarı ve
## dalış süresi (adım), dalışta kaçış hızı ve basılı tutunca gerilim.
var _stages := PackedFloat32Array()
var _start: float = 0.0
var _dive_warn: int = 72
var _dive_len := Vector2i(120, 156)
var _dive_run: float = 1.8
var _dive_pull: float = 1.4
## Dalış bekliyor (pay geçildi, sakin evre bekleniyor) ve dalışlı balık mı.
var _dive_due: bool = false
var _has_dives: bool = false
var _rng := RandomNumberGenerator.new()


## fight: balığın çekişme ayarları (ContentDB fish["fight"]); reel_speed: makaranın sarma hızı
## (m/sn); seed: patlama zamanlarının zarı; gear: kuşanılmış takım (yoksa kurallardaki sayılar);
## percentile: balığın boy yüzdeliği (ppm; iri türde çekişi ve fazla iriliği belirler).
func _init(rules: FishingRules, fight: Dictionary, reel_speed: float, start_distance: float,
		max_dist: float, easy_mode: bool, seed: int, gear: GearStats = null, percentile: int = 0) -> void:
	_rules = rules
	_reel_speed = reel_speed * float(fight["reel"])
	_pull = fight["pull"]
	_burst_pull = fight["burst_pull"]
	_run = fight["run"]
	_every = fight["burst_every_steps"]
	_len = fight["burst_len_steps"]
	_recover = int(round(rules.snap_recover * UNIT))
	_snap_units = rules.snap_steps * UNIT
	_catch_m = rules.catch_m
	_drift = rules.drift
	limit = rules.limit
	rise_step = rules.rise * STEP
	var carry := rules.carry
	if gear != null:
		_reel_speed *= 1.0 + gear.power
		_run *= 1.0 - gear.power
		_burst_pull *= 1.0 - gear.drag
		_snap_units = gear.snap_steps * UNIT
		_catch_m = gear.catch_m
		carry = gear.carry
	if bool(fight.get("heavy", false)):
		_pull += rules.size_pull * float(clampi(percentile, 0, Dice.PPM)) / Dice.PPM
	excess = excess_for(fight, percentile, carry)
	_strained_pull = _pull
	_strained_burst = _burst_pull
	_strained_drift = _drift
	_easy_reel = _reel_speed
	if excess > 0:
		# Normal modda takım taşımaz: sakinken de kırmızı, sert patlama, bırakınca hızla uzaklaşır.
		# Kolay modda yalnızca yavaş gelir.
		_strained_pull = rules.limit + rules.over_pull * excess
		_strained_burst = _burst_pull + rules.over_burst * excess
		_strained_drift = _drift * (1.0 + rules.over_drift * excess)
		_easy_reel = _reel_speed * rules.over_easy_reel
	var stages: PackedFloat32Array = fight.get("stages", PackedFloat32Array())
	if not stages.is_empty():
		_has_dives = true
		_stages = stages.duplicate()
		_dive_warn = int(fight["dive_warn_steps"])
		_dive_len = fight["dive_len_steps"]
		_dive_run = float(fight["dive_run"])
		_dive_pull = float(fight["dive_pull"])
	_start = start_distance
	_rng.seed = seed
	distance = start_distance
	max_distance = max_dist
	easy = easy_mode
	phase = Phase.CALM
	# first_burst uyarıyı da içerir: ilk patlama tam o anda başlar. Türün kendi ilk çırpınması varsa
	# o (alabalık takılır takılmaz sıçrar).
	var first: Vector2i = fight.get("first_burst_steps", rules.first_burst_steps)
	phase_steps = maxi(1, Dice.between(_rng, first) - rules.warn_steps)


## Bir adım ilerler; bu adımda olanları döndürür: warn, burst, burst_end, strain (gerilim
## kırmızıya girdi), strain_end, snap, caught, escaped.
func step() -> PackedStringArray:
	var out := PackedStringArray()
	if outcome != Outcome.NONE:
		return out
	steps += 1
	phase_steps -= 1
	# Dalışın payı geçildiyse sakin evrede dalış uyarısı başlar (patlama sürüyorsa bitince).
	if not _stages.is_empty() and distance <= _start * _stages[0]:
		_stages.remove_at(0)
		_dive_due = true
	if _dive_due and phase == Phase.CALM:
		_dive_due = false
		phase = Phase.DIVE_WARN
		phase_steps = _dive_warn
		out.append("dive_warn")
	elif phase_steps <= 0:
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
			Phase.DIVE_WARN:
				phase = Phase.DIVE
				phase_steps = Dice.between(_rng, _dive_len)
				out.append("dive")
			Phase.DIVE:
				phase = Phase.CALM
				phase_steps = maxi(1, Dice.between(_rng, _every) - _rules.warn_steps)
				out.append("dive_end")
	if phase == Phase.DIVE:
		_dive_step()
		return _finish(out)
	var bursting := phase == Phase.BURST
	var strained := excess > 0 and not easy
	if holding:
		var target := (_strained_burst if strained else _burst_pull) if bursting else (_strained_pull if strained else _pull)
		tension = move_toward(tension, target, _rules.rise * STEP)
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
		distance -= (_easy_reel if easy else _reel_speed) * STEP
	else:
		distance += (_strained_drift if strained else _drift) * STEP
	return _finish(out)


## Dalışta bir adım: basılı tutunca gerilim dive_pull'a çıkar (Kolay'da sınırda durur), bırakınca düşer;
## balık dalış hızıyla uzaklaşır (Kolay'da yavaş), kaçma sınırının DIVE_MARGIN içinde durur.
func _dive_step() -> void:
	if holding:
		tension = move_toward(tension, _dive_pull, _rules.rise * STEP)
	else:
		tension = move_toward(tension, 0.0, _rules.fall * STEP)
	if easy:
		tension = minf(tension, _rules.limit)
	var speed := _dive_run * (EASY_DIVE if easy else 1.0)
	if not holding or easy:
		distance = maxf(distance, minf(distance + speed * STEP, max_distance - DIVE_MARGIN))


## Adımın sonu: kırmızı, kopma sayacı, tutma ve kaçma (her evrede aynı).
func _finish(out: PackedStringArray) -> PackedStringArray:
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
	if distance <= _catch_m:
		distance = _catch_m
		outcome = Outcome.CAUGHT
		out.append("caught")
	elif distance >= max_distance:
		if easy:
			distance = max_distance
		else:
			outcome = Outcome.ESCAPED
			out.append("escaped")
	return out


## Fazla iri mi: iri türün (fight.heavy) yıldızı taşımayı (carry, yıldız) kaç aşıyor; iri tür
## değilse ya da takım taşıyorsa 0.
static func excess_for(fight: Dictionary, percentile: int, carry: int) -> int:
	if not bool(fight.get("heavy", false)):
		return 0
	return maxi(0, FishTable.stars(percentile) - carry)


## Kopmaya ne kadar yakın (0..1; sunumdaki kırmızı dolgu).
func strain() -> float:
	return clampf(float(over) / _snap_units, 0.0, 1.0)


## Uyarı ya da patlama sürüyor mu (sunum: çırpınma; dalış ve uyarısı da)?
func thrashing() -> bool:
	return phase != Phase.CALM


## Dalış ya da uyarısı sürüyor mu (sunum: "BIRAK! Bekçi dalıyor")?
func diving() -> bool:
	return phase == Phase.DIVE_WARN or phase == Phase.DIVE


## Dalışlı balık mı (fight.stages)?
func has_dives() -> bool:
	return _has_dives


func seconds() -> float:
	return float(steps) / FishingRules.HZ
