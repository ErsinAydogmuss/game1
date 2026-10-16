class_name FishTable
extends RefCounted
## Balık zarı: tür, boy yüzdeliği, boy (cm), yıldız ve gölge uzunluğu. Hepsi gölge doğduğu anda
## o gölgenin seed'li zarıyla belirlenir (gizli ama değişmez).
## Boylar çoğunlukla küçük, büyükler seyrek: yüzdelik = u^1,6. Eğri tamsayı düğümlerle
## (ppm) parça parça doğrusal: her cihazda aynı sonuç.
@warning_ignore_start("integer_division")

## round((k/16)^1,6 × 1e6), k = 0..16.
const CURVE := [0, 11842, 35897, 68676, 108819, 155511, 208185, 266419, 329877, 398287,
		471420, 549081, 631100, 717327, 807631, 901891, 1000000]
## Yıldız eşikleri (yüzdelik ppm): altındaysa 1, 2, 3, 4 yıldız; gerisi 5.
const STAR_LIMITS := [200000, 450000, 700000, 900000]


## Atış noktasının ağırlıklarına göre tür seçer; dönen değer listedeki sıra.
static func roll_species(rng: RandomNumberGenerator, weights: PackedInt32Array) -> int:
	return Dice.pick_weighted(rng, weights)


## Boy yüzdeliği (ppm, 0..1e6): u^1,6.
static func roll_percentile(rng: RandomNumberGenerator) -> int:
	return percentile_for(rng.randi_range(0, Dice.PPM - 1))


## u (ppm) → yüzdelik (ppm).
static func percentile_for(u_ppm: int) -> int:
	var u := clampi(u_ppm, 0, Dice.PPM)
	var scaled := u * 16
	var k := mini(scaled / Dice.PPM, 15)
	var rest := scaled - k * Dice.PPM
	var a: int = CURVE[k]
	var b: int = CURVE[k + 1]
	return a + ((b - a) * rest + Dice.PPM / 2) / Dice.PPM


## Boy (cm): türün en küçüğü ile en büyüğü arasında, yüzdeliğe göre.
static func size_cm(def: Dictionary, percentile: int) -> int:
	var range_cm: Vector2i = def["size_cm"]
	return range_cm.x + ((range_cm.y - range_cm.x) * clampi(percentile, 0, Dice.PPM) + Dice.PPM / 2) / Dice.PPM


static func stars(percentile: int) -> int:
	var count := 1
	for limit: int in STAR_LIMITS:
		if percentile >= limit:
			count += 1
	return count


## Gölge uzunluğu (m): türün taban gölgesi × (0,85 + 0,30 × yüzdelik).
static func shadow_length(def: Dictionary, percentile: int) -> float:
	var base: float = def["shadow_m"]
	return base * (0.85 + 0.30 * float(percentile) / Dice.PPM)
