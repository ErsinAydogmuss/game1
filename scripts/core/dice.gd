class_name Dice
extends RefCounted
## Seed'li zar yardımcıları. Oynanışı etkileyen her rastgelelik buradan ya da seed'i buradan
## türetilmiş bir RandomNumberGenerator'dan geçer. Olasılıklar ppm (milyonda bir) tamsayıdır:
## karşılaştırmalar tamsayıyla yapılır, cihazdan cihaza fark çıkmaz. Global randf/randi yok.

const PPM := 1_000_000
## Geçersiz nokta (ör. "suya düşecek yer yok").
const NO_POINT := Vector2(INF, INF)


## base tohumundan ve tuzlardan yeni bir tohum türetir (deterministik; 64 bit taşması olmaz).
## Aynı (base, salt_a, salt_b) hep aynı sonucu verir; tuzlardan biri değişince bambaşka olur.
static func derive(base: int, salt_a: int, salt_b: int = 0) -> int:
	var rng := RandomNumberGenerator.new()
	rng.seed = base
	rng.seed = rng.randi() ^ ((salt_a & 0x7FFFFFFF) * 40503)
	rng.seed = rng.randi() ^ ((salt_b & 0x7FFFFFFF) * 40503)
	return rng.randi()


## ppm olasılıkla true (0 = hiç, PPM = hep).
static func chance(rng: RandomNumberGenerator, ppm: int) -> bool:
	return rng.randi_range(0, PPM - 1) < ppm


## Tamsayı ağırlıklarla seçim; dönen değer sıra numarası. Ağırlıkların toplamı 0 ise -1.
static func pick_weighted(rng: RandomNumberGenerator, weights: PackedInt32Array) -> int:
	var total := 0
	for w in weights:
		total += maxi(0, w)
	if total <= 0:
		return -1
	var roll := rng.randi_range(0, total - 1)
	for i in weights.size():
		roll -= maxi(0, weights[i])
		if roll < 0:
			return i
	return weights.size() - 1


## [lo, hi] aralığında tamsayı (ör. adım sayısı).
static func between(rng: RandomNumberGenerator, range_steps: Vector2i) -> int:
	return rng.randi_range(range_steps.x, range_steps.y)


## Birim çember içinde rastgele bir nokta (reddetme yöntemi; trigonometri yok).
static func in_disc(rng: RandomNumberGenerator, radius: float) -> Vector2:
	for i in 32:
		var p := Vector2(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0))
		if p.length_squared() <= 1.0:
			return p * radius
	return Vector2.ZERO


## Rastgele bir birim yön.
static func direction(rng: RandomNumberGenerator) -> Vector2:
	for i in 32:
		var p := Vector2(rng.randf_range(-1.0, 1.0), rng.randf_range(-1.0, 1.0))
		var len2 := p.length_squared()
		if len2 > 0.01 and len2 <= 1.0:
			return p / sqrt(len2)
	return Vector2(0.0, -1.0)


static func is_point(p: Vector2) -> bool:
	return is_finite(p.x) and is_finite(p.y)
