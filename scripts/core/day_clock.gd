class_name DayClock
extends RefCounted
## Oyun saati (docs/gdd.md §10.5): bir gün 4 vakittir (sabah, öğle, akşam, gece; rules.json
## clock.phase_s, 6'şar dk). Saat yalnızca oynarken akar: kayıttaki clock_s oynanan saniyedir,
## oyuncu yokken durur, ceza yok. Gerçek saat kullanılmaz: hep aynı saatte oynayan da her vakti
## görür, çocuk gece balığı için uyanık kalmaz. 1 gerçek sn = 1 oyun dakikası; yeni oyun sabah
## start_hour'da (06:00) başlar. Saf işlevler (sayı alır, sayı verir); saati main ilerletir.
@warning_ignore_start("integer_division")

## Vakitler sırasıyla (sona eklenmez: bir gün hep bu dört vakit).
const PHASES: Array[String] = ["morning", "noon", "evening", "night"]


## Bir günün süresi (oyun saniyesi).
static func day_s(rules: FishingRules) -> int:
	return rules.phase_s * PHASES.size()


## Kaçıncı oyun günü (0'dan).
static func day(rules: FishingRules, clock_s: int) -> int:
	return maxi(0, clock_s) / day_s(rules)


static func phase_index(rules: FishingRules, clock_s: int) -> int:
	return (maxi(0, clock_s) % day_s(rules)) / rules.phase_s


static func phase(rules: FishingRules, clock_s: int) -> String:
	return PHASES[phase_index(rules, clock_s)]


## Vaktin bitmesine kalan süre (sn, 1..phase_s).
static func phase_left_s(rules: FishingRules, clock_s: int) -> int:
	return rules.phase_s - maxi(0, clock_s) % rules.phase_s


## Sıradaki vaktin başladığı an (clock_s).
static func next_phase_start(rules: FishingRules, clock_s: int) -> int:
	return maxi(0, clock_s) + phase_left_s(rules, clock_s)


static func next_phase(rules: FishingRules, clock_s: int) -> String:
	return phase(rules, next_phase_start(rules, clock_s))


## Günün saati dakika olarak (0..1439): gün başında start_hour, gün 24 saate yayılır.
static func minute_of_day(rules: FishingRules, clock_s: int) -> int:
	var into := maxi(0, clock_s) % day_s(rules)
	return (rules.start_hour * 60 + into * 1440 / day_s(rules)) % 1440


## Saat çipinin yazısı ("06:00").
static func clock_text(rules: FishingRules, clock_s: int) -> String:
	var m := minute_of_day(rules, clock_s)
	return "%02d:%02d" % [m / 60, m % 60]


## Saat seconds kadar ilerler. Döner: { old_phase, new_phase, old_day, new_day, phase_changed,
## day_changed } (vakit ya da gün değiştiyse sunum ve oturum yenilenir).
static func advance(rules: FishingRules, save: SaveData, seconds: int) -> Dictionary:
	var old := save.clock_s
	save.clock_s = maxi(0, old) + maxi(0, seconds)
	return change(rules, old, save.clock_s)


## Sıradaki vaktin başına geçer (Dede'yle çay; ücretsiz).
static func skip_phase(rules: FishingRules, save: SaveData) -> Dictionary:
	var old := save.clock_s
	save.clock_s = next_phase_start(rules, old)
	return change(rules, old, save.clock_s)


## İki an arasında vakit ve gün değişimi.
static func change(rules: FishingRules, old_clock: int, new_clock: int) -> Dictionary:
	var old_day := day(rules, old_clock)
	var new_day := day(rules, new_clock)
	var old_phase := phase_index(rules, old_clock)
	var new_phase := phase_index(rules, new_clock)
	return {
		"old_phase": PHASES[old_phase],
		"new_phase": PHASES[new_phase],
		"old_day": old_day,
		"new_day": new_day,
		"phase_changed": old_day != new_day or old_phase != new_phase,
		"day_changed": old_day != new_day,
	}
