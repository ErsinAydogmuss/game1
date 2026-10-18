class_name BiteRules
extends RefCounted
## Fark etme, korkutma, dürtme ve ısırma kuralları (saf fonksiyonlar). Süreler adımdır
## (1/60 sn). Sayılar data/rules.json'dan (FishingRules) gelir; docs/gdd.md §5.


## Gölge şamandırayı fark eder mi? Önündeki ±70°'lik konide notice_front'tan, başka yönde
## notice_side'dan yakınsa evet.
static func notices(shadow: FishShadow, bobber: Vector2, rules: FishingRules) -> bool:
	return notices_in(shadow, bobber, rules.notice_front, rules.notice_side, rules.notice_cos)


## Gölge takımı (şamandıra, yapay yem, kurşun, sinek) fark eder mi? Önündeki konide (yarım açının
## kosinüsü cone_cos) front'tan, başka yönde side'dan yakınsa evet (tekniğin profili: TechniqueRules).
static func notices_in(shadow: FishShadow, rig: Vector2, front: float, side: float, cone_cos: float) -> bool:
	var to := rig - shadow.pos
	var d := to.length()
	if d <= side:
		return true
	if d > front:
		return false
	return shadow.heading.dot(to / d) >= cone_cos


## Şamandıra buraya düşerse gölge korkup kaçar mı? Gölgenin merkezine "gölge boyunun yarısı
## + scare_extra"dan yakınsa evet. stealth: misinanın görünmezliği (yarıçap × (1 − stealth)).
static func scares(shadow: FishShadow, point: Vector2, rules: FishingRules, stealth: float = 0.0) -> bool:
	return shadow.pos.distance_to(point) < (shadow.length * 0.5 + rules.scare_extra) * (1.0 - stealth)


## Isırmadan önce kaç kez dürter (0..3)?
static func roll_nibbles(rng: RandomNumberGenerator, rules: FishingRules) -> int:
	return maxi(0, Dice.pick_weighted(rng, rules.nibble_weights))


## İki dürtme (ya da son dürtme ile ısırma) arası adım.
static func roll_gap(rng: RandomNumberGenerator, rules: FishingRules) -> int:
	return Dice.between(rng, rules.gap_steps)


## Vuruş penceresi (adım). Isırmadan bu kadar adım sonra dokunuş artık geç kalmıştır.
static func window_steps(rules: FishingRules, easy: bool) -> int:
	return rules.window_easy_steps if easy else rules.window_steps


## Dürtme sırasında erken dokunuş: "startle" (balık yalnızca irkilir, sıra sürer) ya da
## "flee" (balık kaçar). Kolay modda ilk erken dokunuş irkiltir; ilk av hep irkilir.
static func early_outcome(easy: bool, scripted: bool, startles_used: int) -> String:
	if scripted or (easy and startles_used == 0):
		return "startle"
	return "flee"
