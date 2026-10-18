class_name TechniqueRules
extends RefCounted
## Bir tekniğin sayıları: gölgelerin takımı nasıl fark ettiği, ona nasıl yaklaştığı ve çevresine
## nasıl toplandığı ("takım profili"; ShadowSim okur), dürtme ve vuruş penceresi. Süreler adımdır
## (1/60 sn). Şamandıranın profili rules.json'ın üst düzey bölümlerinden (shadows, notice, bite)
## aynen kopyalanır: şamandıranın davranışı bit bit aynı kalır (altın test). Öteki tekniklerinki
## rules.json "techniques" bölümünden gelir (docs/gdd.md §10.3).

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

# --- Dürtme ve ısırma -------------------------------------------------------------------
## 0, 1, 2, 3 dürtmenin ağırlıkları.
var nibble_weights := PackedInt32Array([15, 30, 35, 20])
var gap_steps := Vector2i(48, 84)
var window_steps: int = 60
var window_easy_steps: int = 96


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
