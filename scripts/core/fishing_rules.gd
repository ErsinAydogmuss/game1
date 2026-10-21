class_name FishingRules
extends RefCounted
## Balık tutma kuralları (data/rules.json). Varsayılanlar docs/gdd.md §5'teki sayılardır.
## Süreler saniye olarak okunur, adım (1/60 sn) olarak da tutulur: çekirdek mantık sayaçları
## tamsayı adımla işler (pencere sınırları her fps'te aynı).

const HZ := 60

# --- Atış ---------------------------------------------------------------------------
var flight_base: float = 0.45
var flight_per_m: float = 0.05
## Atış yayının yüksekliği / mesafe (sunum).
var arc: float = 0.25
## Şamandıra kıyıya en az bu kadar uzağa düşer.
var min_shore: float = 0.3
## Bundan kısa atış yapılmaz.
var min_cast: float = 1.0
var retrieve_steps: int = 21
## Kaçırınca sonraki atışa kadar bekleme.
var lost_steps: int = 48

# --- Gölgeler -------------------------------------------------------------------------
var shadow_speed := Vector2(0.3, 0.5)
var pause_steps := Vector2i(60, 180)
var min_depth: float = 0.8
var respawn_steps := Vector2i(180, 480)
var approach_speed: float = 0.45
var flee_speed: float = 2.2
var flee_steps: int = 96
## Dönüş hızı (1/sn): yön her adımda hedefe bu oranda yaklaşır.
var turn: float = 2.5
## Yolu kapalı (kıyı arada) balık bu kadar adım sonra vazgeçer (ilk av vazgeçmez).
var give_up_steps: int = 20 * HZ
## Şamandıra bu kadar adımdır suyadaysa gölgeler (gather_ppm olasılıkla) onun gather_radius
## çevresine doğru dolaşmaya başlar: bekleme uzamasın.
var gather_after_steps: int = 360
var gather_ppm: int = 500_000
var gather_radius: float = 2.5
## Doğan gölgeler birbirine bundan yakın olmaz.
var spacing: float = 1.2
var spawn_from_angler: float = 3.0
## Bölgeli gölde gölgeler balıkçıya menzil + reach_extra metre içinde doğar; menzil + reach_extra +
## leash_extra'dan uzakta kalan gölge gölden çekilir (recycle_check adımda bir bakılır) ve yerine
## recycle_steps içinde yenisi doğar.
var reach_extra: float = 2.0
var leash_extra: float = 8.0
var recycle_steps := Vector2i(24, 72)
var recycle_check_steps: int = 15

# --- Korkutma ve fark etme -------------------------------------------------------------
var scare_extra: float = 0.3
## Önündeki koninin yarım açısının kosinüsü (70° → 0,342).
var notice_cos: float = 0.342
var notice_front: float = 3.0
var notice_side: float = 1.8

# --- Dürtme ve ısırma ------------------------------------------------------------------
## 0, 1, 2, 3 dürtmenin ağırlıkları.
var nibble_weights := PackedInt32Array([15, 30, 35, 20])
var gap_steps := Vector2i(48, 84)
var window_steps: int = 60
var window_easy_steps: int = 96

# --- Çekişme ---------------------------------------------------------------------------
## Gerilim sınırı (kırmızı bölge bunun üstü).
var limit: float = 0.85
var warn_steps: int = 30
## Sınırın üstünde toplam bu kadar adım kalınca misina kopar.
var snap_steps: int = 48
## Sınırın altında sayaç saniyede bu kadar saniye geri iner.
var snap_recover: float = 0.35
## Gerilimin artış ve düşüş hızı (1/sn).
var rise: float = 2.4
var fall: float = 2.0
## Bırakınca sakin balığın uzaklaşma hızı (m/sn).
var drift: float = 0.25
var catch_m: float = 0.6
var escape_extra: float = 2.0
## Kolay modda patlamada basılı tutunca misina kaçış hızının bu katı kayar.
var easy_slip: float = 2.0
var first_burst_steps := Vector2i(96, 144)
# İri balık (docs/gdd.md §5): iri türün (fight.heavy) boyu çekişini artırır; yıldızı takımın
# taşımasını aşan fazla iridir.
## Takımsız taşıma (yıldız): bambu olta ve ince misina.
var carry: int = 3
## İri türde sakin çekişe boy yüzdeliğiyle eklenen (en irisinde bu kadar).
var size_pull: float = 0.08
## Fazla iride sakin çekiş sınırın bu kadar üstünde (fazla yıldız başına): sakinken de kırmızı.
var over_pull: float = 0.12
## Fazla iride patlamanın çekişine eklenen (fazla yıldız başına).
var over_burst: float = 0.1
## Fazla iride bırakınca uzaklaşma × (1 + over_drift × fazla yıldız); Kolay modda artmaz.
var over_drift: float = 3.0
## Kolay modda fazla iri balığın sarma hızı çarpanı (kopmaz, yalnızca yavaş gelir).
var over_easy_reel: float = 0.9

# --- Kerevit tuzağı (Dalga 3) ------------------------------------------------------------
## Gerçek saatle bu kadar sn'de bir kerevit girer; en çok trap_max birikir (boşta biriken üst
## sınırda durur: gelir kuralı 7).
var trap_fill_s: int = 1200
var trap_max: int = 4
## Tuzak en çok trap_depth (m) derin suya, balıkçıya trap_near aralığında (m), öteki tuzaklara en az
## trap_spacing (m) uzağa kurulur.
var trap_depth: float = 1.2
var trap_near := Vector2(1.2, 3.5)
var trap_spacing: float = 2.0

# --- Oyun saati, hava ve göl sevgisi (Dalga 4, docs/gdd.md §10.5) --------------------------
## Bir vaktin süresi (oyun saniyesi: oynanan saniye); gün DayClock.PHASES kadar vakit.
var phase_s: int = 360
## Sabahın başladığı saat (saat çipi; 1 gerçek sn = 1 oyun dakikası).
var start_hour: int = 6
## Günün havasının ağırlıkları (Weather.KINDS sırasıyla: açık, bulutlu, yağmur, sis).
var weather_weights := PackedInt32Array([55, 20, 15, 10])
## İlk oyun gününün havası (yeni oyuncu berrak gölde öğrensin).
var first_weather: String = "clear"
## Sisli günde sisin olduğu vakitler; öteki vakitlerde fog_else.
var fog_phases := PackedStringArray(["morning", "night"])
var fog_else: String = "cloudy"
## Yağmurda gölgeler takımı bu kat uzaktan fark eder ve bu kat hızlı yaklaşır (her teknikte:
## TechniqueRules.with_boost).
var rain_notice: float = 1.3
var rain_approach: float = 1.25
## Göl sevgisinin seviye eşikleri (toplam sevgi; [0] = 1. seviye = 0). Hiç azalmaz.
var love_levels := PackedInt32Array([0, 12, 30, 60, 110, 180, 270, 380, 520, 700])
## Her seviye love_from ve üstündeki nadirliklerin ağırlığını bu kadar artırır (seviye 1'de 0).
var love_rare_bonus: float = 0.04
var love_from: String = "rare"
## Çöp (Trash): dipte tutulan balığın yanında ve tuzağın her yeni içeriğinde çıkma olasılığı (ppm);
## eşyalar (kimlik, ağırlık, toplanınca göl sevgisi; sırası zarın sırası).
var trash_bottom_ppm: int = 50_000
var trash_trap_ppm: int = 200_000
var trash_ids := PackedStringArray(["boot", "tin_can", "plastic_bottle", "rusty_key"])
var trash_weights := PackedInt32Array([35, 35, 25, 5])
var trash_love := PackedInt32Array([3, 3, 3, 5])


## Tekniklerin profilleri (kimlik → TechniqueRules). Şamandıranınki üst düzey bölümlerden.
var _techniques: Dictionary = {}


static func to_steps(seconds: float) -> int:
	return int(round(seconds * HZ))


## Tekniğin profili; bilinmeyen teknikte şamandıranınki.
func technique(id: String) -> TechniqueRules:
	if not _techniques.has("float"):
		_techniques["float"] = TechniqueRules.from_float(self)
	return _techniques.get(id, _techniques["float"])


static func from_dict(d: Dictionary, errors: PackedStringArray) -> FishingRules:
	var r := FishingRules.new()
	if d.is_empty():
		errors.append("rules.json: boş ya da okunamadı")
		return r
	var cast: Dictionary = d.get("cast", {})
	r.flight_base = float(cast.get("flight_base", r.flight_base))
	r.flight_per_m = float(cast.get("flight_per_m", r.flight_per_m))
	r.arc = float(cast.get("arc", r.arc))
	r.min_shore = float(cast.get("min_shore_m", r.min_shore))
	r.min_cast = float(cast.get("min_m", r.min_cast))
	r.retrieve_steps = to_steps(float(cast.get("retrieve", 0.35)))
	r.lost_steps = to_steps(float(cast.get("lost", 0.8)))
	var shadows: Dictionary = d.get("shadows", {})
	r.shadow_speed = _vec2(shadows.get("speed"), r.shadow_speed)
	r.pause_steps = _steps2(shadows.get("pause"), r.pause_steps)
	r.min_depth = float(shadows.get("min_depth", r.min_depth))
	r.respawn_steps = _steps2(shadows.get("respawn"), r.respawn_steps)
	r.approach_speed = float(shadows.get("approach_speed", r.approach_speed))
	r.flee_speed = float(shadows.get("flee_speed", r.flee_speed))
	r.flee_steps = to_steps(float(shadows.get("flee", 1.6)))
	r.turn = float(shadows.get("turn", r.turn))
	r.give_up_steps = to_steps(float(shadows.get("give_up", 20.0)))
	r.gather_after_steps = to_steps(float(shadows.get("gather_after", 6.0)))
	r.gather_ppm = int(round(float(shadows.get("gather_chance", 0.5)) * Dice.PPM))
	r.gather_radius = float(shadows.get("gather_radius", r.gather_radius))
	r.spacing = float(shadows.get("spacing", r.spacing))
	r.spawn_from_angler = float(shadows.get("spawn_from_angler", r.spawn_from_angler))
	r.reach_extra = float(shadows.get("reach_extra", r.reach_extra))
	r.leash_extra = float(shadows.get("leash_extra", r.leash_extra))
	r.recycle_steps = _steps2(shadows.get("recycle"), r.recycle_steps)
	r.recycle_check_steps = maxi(1, to_steps(float(shadows.get("recycle_check", 0.25))))
	var scare: Dictionary = d.get("scare", {})
	r.scare_extra = float(scare.get("extra_m", r.scare_extra))
	var notice: Dictionary = d.get("notice", {})
	r.notice_cos = cos(deg_to_rad(float(notice.get("cone_deg", 70.0))))
	r.notice_front = float(notice.get("front_m", r.notice_front))
	r.notice_side = float(notice.get("side_m", r.notice_side))
	var bite: Dictionary = d.get("bite", {})
	var weights: Array = bite.get("nibbles", [15, 30, 35, 20])
	r.nibble_weights = PackedInt32Array()
	for w: Variant in weights:
		r.nibble_weights.append(int(w))
	r.gap_steps = _steps2(bite.get("gap"), r.gap_steps)
	r.window_steps = to_steps(float(bite.get("window", 1.0)))
	r.window_easy_steps = to_steps(float(bite.get("window_easy", 1.6)))
	var reel: Dictionary = d.get("reel", {})
	r.limit = float(reel.get("limit", r.limit))
	r.warn_steps = to_steps(float(reel.get("warn", 0.5)))
	r.snap_steps = to_steps(float(reel.get("snap_after", 0.8)))
	r.snap_recover = float(reel.get("snap_recover", r.snap_recover))
	r.rise = float(reel.get("rise", r.rise))
	r.fall = float(reel.get("fall", r.fall))
	r.drift = float(reel.get("drift", r.drift))
	r.catch_m = float(reel.get("catch_m", r.catch_m))
	r.escape_extra = float(reel.get("escape_extra_m", r.escape_extra))
	r.easy_slip = float(reel.get("easy_slip", r.easy_slip))
	r.first_burst_steps = _steps2(reel.get("first_burst"), r.first_burst_steps)
	r.carry = int(reel.get("carry", r.carry))
	r.size_pull = float(reel.get("size_pull", r.size_pull))
	r.over_pull = float(reel.get("over_pull", r.over_pull))
	r.over_burst = float(reel.get("over_burst", r.over_burst))
	r.over_drift = float(reel.get("over_drift", r.over_drift))
	r.over_easy_reel = float(reel.get("over_easy_reel", r.over_easy_reel))
	var trap: Dictionary = d.get("trap", {})
	r.trap_fill_s = int(trap.get("fill_s", r.trap_fill_s))
	r.trap_max = int(trap.get("max", r.trap_max))
	r.trap_depth = float(trap.get("depth_max_m", r.trap_depth))
	r.trap_near = _vec2(trap.get("near_m"), r.trap_near)
	r.trap_spacing = float(trap.get("spacing_m", r.trap_spacing))
	var clock: Dictionary = d.get("clock", {})
	r.phase_s = int(clock.get("phase_s", r.phase_s))
	r.start_hour = int(clock.get("start_hour", r.start_hour))
	var weather: Dictionary = d.get("weather", {})
	var chance: Variant = weather.get("chance", {})
	if typeof(chance) == TYPE_DICTIONARY and not (chance as Dictionary).is_empty():
		r.weather_weights = PackedInt32Array()
		for kind in Weather.KINDS:
			r.weather_weights.append(int((chance as Dictionary).get(kind, 0)))
		for kind: Variant in chance:
			if not str(kind) in Weather.KINDS:
				errors.append("rules.json: weather.chance: bilinmeyen hava: %s" % kind)
	r.first_weather = str(weather.get("first_day", r.first_weather))
	var fog: Variant = weather.get("fog_phases")
	if typeof(fog) == TYPE_ARRAY:
		r.fog_phases = PackedStringArray()
		for phase: Variant in fog:
			r.fog_phases.append(str(phase))
	r.fog_else = str(weather.get("fog_else", r.fog_else))
	r.rain_notice = float(weather.get("rain_notice", r.rain_notice))
	r.rain_approach = float(weather.get("rain_approach", r.rain_approach))
	var love: Dictionary = d.get("love", {})
	var levels: Variant = love.get("levels")
	if typeof(levels) == TYPE_ARRAY:
		r.love_levels = PackedInt32Array()
		for at: Variant in levels:
			r.love_levels.append(int(at))
	r.love_rare_bonus = float(love.get("rare_bonus", r.love_rare_bonus))
	r.love_from = str(love.get("rare_from", r.love_from))
	var trash: Dictionary = d.get("trash", {})
	r.trash_bottom_ppm = roundi(float(trash.get("bottom", r.trash_bottom_ppm / float(Dice.PPM))) * Dice.PPM)
	r.trash_trap_ppm = roundi(float(trash.get("trap", r.trash_trap_ppm / float(Dice.PPM))) * Dice.PPM)
	var items: Variant = trash.get("items")
	if typeof(items) == TYPE_ARRAY:
		r.trash_ids = PackedStringArray()
		r.trash_weights = PackedInt32Array()
		r.trash_love = PackedInt32Array()
		for item: Variant in items:
			if typeof(item) != TYPE_DICTIONARY:
				errors.append("rules.json: trash.items: her eşya bir bölüm olmalı")
				continue
			var it: Dictionary = item
			r.trash_ids.append(str(it.get("id", "")))
			r.trash_weights.append(int(it.get("weight", 0)))
			r.trash_love.append(int(it.get("love", 0)))
	r._validate(errors)
	# Teknikler: şamandıra üst düzey bölümlerden; ötekiler "techniques" bölümünden.
	var base := r.technique("float")
	var techniques: Dictionary = d.get("techniques", {})
	for id: Variant in techniques:
		if typeof(techniques[id]) != TYPE_DICTIONARY or str(id) == "float":
			errors.append("rules.json: techniques.%s: bölüm olmalı (şamandıra üst düzeyde)" % id)
			continue
		var t := TechniqueRules.from_dict(str(id), techniques[id], base)
		t.validate(errors)
		r._techniques[str(id)] = t
	return r


func _validate(errors: PackedStringArray) -> void:
	var checks := {
		"uçuş süresi pozitif": flight_base > 0.0 and flight_per_m >= 0.0,
		"gölge hızı aralığı": shadow_speed.x > 0.0 and shadow_speed.y >= shadow_speed.x,
		"duraklama aralığı": pause_steps.x > 0 and pause_steps.y >= pause_steps.x,
		"yeniden doğma aralığı": respawn_steps.x > 0 and respawn_steps.y >= respawn_steps.x,
		"geri dönüşüm (pozitif, aralık)": recycle_steps.x > 0 and recycle_steps.y >= recycle_steps.x \
				and reach_extra >= 0.0 and leash_extra > 0.0,
		"dürtme ağırlıkları (4 değer, toplam > 0)": nibble_weights.size() == 4 and _sum(nibble_weights) > 0,
		"dürtme arası": gap_steps.x > 0 and gap_steps.y >= gap_steps.x,
		"vuruş penceresi (Kolay >= normal)": window_steps > 0 and window_easy_steps >= window_steps,
		"gerilim sınırı 0..1": limit > 0.0 and limit < 1.0,
		"uyarı ve kopma süresi": warn_steps > 0 and snap_steps > 0,
		"gerilim hızları": rise > 0.0 and fall > 0.0,
		"fark etme uzaklıkları": notice_front >= notice_side and notice_side > 0.0,
		"ilk patlama uyarıdan sonra": first_burst_steps.x > warn_steps and first_burst_steps.y >= first_burst_steps.x,
		"iri balık (taşıma 1–5, fazla iri sınırın üstünde, Kolay'da yavaş ama gelir)": carry >= 1 and carry <= 5 \
				and size_pull >= 0.0 and over_pull > 0.0 and over_burst >= 0.0 and over_drift >= 0.0 \
				and over_easy_reel > 0.0 and over_easy_reel <= 1.0,
		"tuzak (dolma süresi, en çok kayıt sınırı kadar, sığ su, yakın aralık)": trap_fill_s > 0 and trap_max >= 1 \
				and trap_max <= SaveData.MAX_TRAP_ITEMS and trap_depth > 0.0 and trap_near.x > 0.0 \
				and trap_near.y > trap_near.x and trap_spacing >= 0.0,
		"saat (vakit en az 1 dk, sabah 0–23)": phase_s >= 60 and start_hour >= 0 and start_hour < 24,
		"hava (4 ağırlık, toplam > 0, ilk gün ve sisin yerine bilinen hava, sis bilinen vakitlerde)": \
				weather_weights.size() == Weather.KINDS.size() and _sum(weather_weights) > 0 \
				and first_weather in Weather.KINDS and fog_else in Weather.KINDS and fog_else != "fog" \
				and _known_phases(fog_phases),
		"yağmur (fark etme ve yaklaşma en az 1 kat)": rain_notice >= 1.0 and rain_approach >= 1.0,
		"göl sevgisi (0 ile başlar, artar; nadirlik payı 0–0,1)": love_levels.size() >= 2 and love_levels[0] == 0 \
				and _rising(love_levels) and love_rare_bonus >= 0.0 and love_rare_bonus <= 0.1,
		"çöp (olasılıklar 0–1, en az bir eşya, kimlikler dolu ve eşsiz, ağırlıklar pozitif, sevgi 0–100)": \
				trash_bottom_ppm >= 0 and trash_bottom_ppm <= Dice.PPM and trash_trap_ppm >= 0 \
				and trash_trap_ppm <= Dice.PPM and _trash_ok(),
	}
	for label: String in checks:
		if not bool(checks[label]):
			errors.append("rules.json: geçersiz: " + label)


func _trash_ok() -> bool:
	if trash_ids.is_empty() or trash_weights.size() != trash_ids.size() or trash_love.size() != trash_ids.size():
		return false
	for i in trash_ids.size():
		if trash_ids[i].is_empty() or trash_ids.find(trash_ids[i]) != i or trash_weights[i] <= 0 \
				or trash_love[i] < 0 or trash_love[i] > 100:
			return false
	return true


static func _known_phases(phases: PackedStringArray) -> bool:
	for phase in phases:
		if not phase in DayClock.PHASES:
			return false
	return true


static func _rising(values: PackedInt32Array) -> bool:
	for i in range(1, values.size()):
		if values[i] <= values[i - 1]:
			return false
	return true


static func _sum(values: PackedInt32Array) -> int:
	var total := 0
	for v in values:
		total += v
	return total


static func _vec2(raw: Variant, fallback: Vector2) -> Vector2:
	if typeof(raw) != TYPE_ARRAY or (raw as Array).size() != 2:
		return fallback
	var a: Array = raw
	return Vector2(float(a[0]), float(a[1]))


static func _steps2(raw: Variant, fallback: Vector2i) -> Vector2i:
	if typeof(raw) != TYPE_ARRAY or (raw as Array).size() != 2:
		return fallback
	var a: Array = raw
	return Vector2i(to_steps(float(a[0])), to_steps(float(a[1])))
