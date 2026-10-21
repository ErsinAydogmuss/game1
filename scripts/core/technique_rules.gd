class_name TechniqueRules
extends RefCounted
## Bir tekniğin sayıları: gölgelerin takımı nasıl fark ettiği, ona nasıl yaklaştığı ve çevresine
## nasıl toplandığı ("takım profili"; ShadowSim okur), dürtme ve vuruş penceresi. Süreler adımdır
## (1/60 sn). Şamandıranın profili rules.json'ın üst düzey bölümlerinden (shadows, notice, bite)
## aynen kopyalanır: şamandıranın davranışı bit bit aynı kalır (altın test). Öteki tekniklerinki
## rules.json "techniques" bölümünden gelir (docs/gdd.md §10.3); yazılmayan sayı şamandıranınki.
## Tekniğe özgü sayılar (spinde yemin hızı, saldırı kuralı) params'ta: teknik kendisi okur.

var id: String = "float"

# --- Fark etme ve yaklaşma (ShadowSim) -------------------------------------------------
## Önündeki koninin yarım açısının kosinüsü; önde notice_front, başka yönde notice_side metreden
## yakın takımı fark eder.
var notice_cos: float = 0.342
var notice_front: float = 3.0
var notice_side: float = 1.8
## Takıma yaklaşma hızı (m/sn).
var approach_speed: float = 0.45
## Yolu kapalı balık bu kadar adım sonra vazgeçer (ilk av vazgeçmez).
var give_up_steps: int = 20 * FishingRules.HZ
## Takım gather_after_steps adımdır sudaysa dolaşan gölge yeni hedef seçerken gather_ppm
## olasılıkla takımın gather_radius çevresine yönelir (0 = hiç; bekleme uzamasın).
var gather_after_steps: int = 360
var gather_ppm: int = 500_000
var gather_radius: float = 2.5
## Toplanan gölgenin yüzme hızı çarpanı (dipte yemin kokusu; şamandırada 1: eskisi gibi).
var gather_speed: float = 1.0
## Takıma varan balık hareket eden takımı bu hızla izler (m/sn; 0 = takım durur, balık da: şamandıra).
var follow_speed: float = 0.0

# --- Dürtme ve ısırma -------------------------------------------------------------------
## 0, 1, 2, 3 dürtmenin ağırlıkları.
var nibble_weights := PackedInt32Array([15, 30, 35, 20])
var gap_steps := Vector2i(48, 84)
var window_steps: int = 60
var window_easy_steps: int = 96

## Tekniğe özgü sayılar (rules.json'daki bölüm olduğu gibi; num, steps ile okunur).
var params: Dictionary = {}


## Şamandıranın profili: kuralların üst düzey bölümlerindeki sayıların aynısı (hesaplanmaz,
## kopyalanır).
static func from_float(r: FishingRules) -> TechniqueRules:
	var t := TechniqueRules.new()
	t.id = "float"
	t.notice_cos = r.notice_cos
	t.notice_front = r.notice_front
	t.notice_side = r.notice_side
	t.approach_speed = r.approach_speed
	t.give_up_steps = r.give_up_steps
	t.gather_after_steps = r.gather_after_steps
	t.gather_ppm = r.gather_ppm
	t.gather_radius = r.gather_radius
	t.nibble_weights = r.nibble_weights.duplicate()
	t.gap_steps = r.gap_steps
	t.window_steps = r.window_steps
	t.window_easy_steps = r.window_easy_steps
	return t


## rules.json "techniques" bölümündeki bir tekniğin profili; yazılmayan sayı base'inki (şamandıra).
static func from_dict(technique_id: String, d: Dictionary, base: TechniqueRules) -> TechniqueRules:
	var t := TechniqueRules.new()
	t.id = technique_id
	var notice: Dictionary = d.get("notice", {})
	t.notice_cos = cos(deg_to_rad(float(notice["cone_deg"]))) if notice.has("cone_deg") else base.notice_cos
	t.notice_front = float(notice.get("front_m", base.notice_front))
	t.notice_side = float(notice.get("side_m", base.notice_side))
	t.approach_speed = float(d.get("approach_speed", base.approach_speed))
	t.give_up_steps = FishingRules.to_steps(float(d["give_up"])) if d.has("give_up") else base.give_up_steps
	t.gather_after_steps = FishingRules.to_steps(float(d["gather_after"])) if d.has("gather_after") else base.gather_after_steps
	t.gather_ppm = int(round(float(d["gather_chance"]) * Dice.PPM)) if d.has("gather_chance") else base.gather_ppm
	t.gather_radius = float(d.get("gather_radius", base.gather_radius))
	t.gather_speed = float(d.get("gather_speed", base.gather_speed))
	t.follow_speed = float(d.get("follow_speed", 0.0))
	t.nibble_weights = base.nibble_weights.duplicate()
	if d.has("nibbles") and typeof(d["nibbles"]) == TYPE_ARRAY:
		t.nibble_weights = PackedInt32Array()
		for w: Variant in d["nibbles"]:
			t.nibble_weights.append(int(w))
	t.gap_steps = FishingRules._steps2(d.get("gap"), base.gap_steps)
	t.window_steps = FishingRules.to_steps(float(d["window"])) if d.has("window") else base.window_steps
	t.window_easy_steps = FishingRules.to_steps(float(d["window_easy"])) if d.has("window_easy") else base.window_easy_steps
	t.params = d.duplicate(true)
	return t


## Aynı sayılarla yeni bir profil (params paylaşılır: yalnızca okunur).
func copy() -> TechniqueRules:
	var t := TechniqueRules.new()
	t.id = id
	t.notice_cos = notice_cos
	t.notice_front = notice_front
	t.notice_side = notice_side
	t.approach_speed = approach_speed
	t.give_up_steps = give_up_steps
	t.gather_after_steps = gather_after_steps
	t.gather_ppm = gather_ppm
	t.gather_radius = gather_radius
	t.gather_speed = gather_speed
	t.follow_speed = follow_speed
	t.nibble_weights = nibble_weights.duplicate()
	t.gap_steps = gap_steps
	t.window_steps = window_steps
	t.window_easy_steps = window_easy_steps
	t.params = params
	return t


## Yem sepeti (dip; pull 0–1): gölgeler takımın çevresine daha erken ve daha sık toplanır. Eşik en
## az 1 adım: bekleme adımı 1'den sayılır (BottomTechnique eşitlikle bakar).
func with_pull(pull: float) -> TechniqueRules:
	var t := copy()
	var p := clampf(pull, 0.0, 1.0)
	t.gather_after_steps = maxi(1, roundi(gather_after_steps * (1.0 - p)))
	t.gather_ppm = mini(Dice.PPM, roundi(gather_ppm * (1.0 + p)))
	return t


## Yağmur (Dalga 4, rules.json weather): gölgeler takımı daha uzaktan fark eder ve daha hızlı
## yaklaşır (her teknikte aynı; dürtme ve vuruş penceresi değişmez).
func with_boost(notice_mult: float, approach_mult: float) -> TechniqueRules:
	var t := copy()
	t.notice_front = notice_front * notice_mult
	t.notice_side = notice_side * notice_mult
	t.approach_speed = approach_speed * approach_mult
	return t


## Tekniğe özgü sayı (params'ta; iç içe bölüm "strike.stop" gibi noktayla).
func num(key: String, fallback: float) -> float:
	var v: Variant = _lookup(key)
	return float(v) if typeof(v) in [TYPE_INT, TYPE_FLOAT] else fallback


## Tekniğe özgü süre (sn → adım).
func steps(key: String, fallback_s: float) -> int:
	return FishingRules.to_steps(num(key, fallback_s))


## Tekniğe özgü olasılık (0–1 → ppm).
func ppm(key: String, fallback: float) -> int:
	return int(round(num(key, fallback) * Dice.PPM))


func _lookup(key: String) -> Variant:
	var at: Variant = params
	for part in key.split("."):
		if typeof(at) != TYPE_DICTIONARY or not (at as Dictionary).has(part):
			return null
		at = (at as Dictionary)[part]
	return at


## Profilin denetimi (FishingRules._validate çağırır).
func validate(errors: PackedStringArray) -> void:
	var checks := {
		"fark etme uzaklıkları": notice_front >= notice_side and notice_side > 0.0,
		"yaklaşma hızı ve vazgeçme": approach_speed > 0.0 and give_up_steps > 0,
		"toplanma": gather_ppm >= 0 and gather_ppm <= Dice.PPM and gather_radius >= 0.0 and gather_speed >= 1.0,
		"izleme hızı": follow_speed >= 0.0,
		"dürtme ağırlıkları (4 değer, toplam > 0)": nibble_weights.size() == 4 and FishingRules._sum(nibble_weights) > 0,
		"dürtme arası": gap_steps.x > 0 and gap_steps.y >= gap_steps.x,
		"vuruş penceresi (Kolay >= normal)": window_steps > 0 and window_easy_steps >= window_steps,
	}
	for label: String in checks:
		if not bool(checks[label]):
			errors.append("rules.json: techniques.%s: geçersiz: %s" % [id, label])
