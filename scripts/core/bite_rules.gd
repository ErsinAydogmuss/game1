class_name BiteRules
extends RefCounted
## Fark etme, korkutma, dürtme ve ısırma kuralları (saf fonksiyonlar). Süreler adımdır
## (1/60 sn). Sayılar data/rules.json'dan (FishingRules) gelir; docs/gdd.md §5.


## Gölge şamandırayı fark eder mi? Önündeki ±70°'lik konide notice_front'tan, başka yönde
## notice_side'dan yakınsa evet.
static func notices(shadow: FishShadow, bobber: Vector2, rules: FishingRules) -> bool:
	var to := bobber - shadow.pos
	var d := to.length()
	if d <= rules.notice_side:
		return true
	if d > rules.notice_front:
		return false
	return shadow.heading.dot(to / d) >= rules.notice_cos


## Şamandıra buraya düşerse gölge korkup kaçar mı? Gölgenin merkezine "gölge boyunun yarısı
## + scare_extra"dan yakınsa evet.
static func scares(shadow: FishShadow, point: Vector2, rules: FishingRules) -> bool:
	return shadow.pos.distance_to(point) < shadow.length * 0.5 + rules.scare_extra


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
