class_name Weather
extends RefCounted
## Hava (docs/gdd.md §10.5): her oyun günü için tohumlu zar (kaydın seed'i ve günün sırası):
## açık %55, bulutlu %20, yağmur %15, sis %10 (rules.json weather). Önceden belli olduğu için
## bugünün ve yarının havası gösterilir (gelir kuralı 4: gizli içerik baştan belli). İlk oyun günü
## hep açık. Sisli günde sis yalnızca sabah ve gecedir; öğle ve akşam bulutlu. Yağmurlu gece
## fırtınadır (gök gürültüsü ve şimşek; Kocabaş o gecelerde gelir). Final hazırken Gölün Bekçisi
## bırakılana kadar her gece sisli (Secret.keeper_night), bırakıldığı gece de sabaha kadar (sis şafakta
## kalkar: Secret.released_on). Yalnızca o anki hava (at) değişir; günün zarı (day_kind, forecast) aynı.
## Hava parayla satılmaz.

const KINDS: Array[String] = ["clear", "cloudy", "rain", "fog"]
## Günün zarının tuzu (Dice.derive(seed, SALT, gün)).
const SALT := 7411
## Geliştirme sürümünün HAVA düğmesi: bu günün havası kayıtta (flags) seçilene döner.
const DEBUG_DAY := "debug_weather_day"
const DEBUG_KIND := "debug_weather"


## Oyun gününün havası (zarla; gün 0 first_weather).
static func of_day(rules: FishingRules, seed: int, day: int) -> String:
	if day <= 0:
		return rules.first_weather
	var rng := RandomNumberGenerator.new()
	rng.seed = Dice.derive(seed, SALT, day)
	var k := Dice.pick_weighted(rng, rules.weather_weights)
	return KINDS[k] if k >= 0 else "clear"


## Kayıttaki günün havası: deneme düğmesiyle seçilen (o gün için) ya da zarınki.
static func day_kind(rules: FishingRules, save: SaveData, day: int) -> String:
	if int(save.flags.get(DEBUG_DAY, -1)) == day and str(save.flags.get(DEBUG_KIND, "")) in KINDS:
		return str(save.flags[DEBUG_KIND])
	return of_day(rules, save.seed, day)


## O anki hava (clock_s verilmezse kaydın saati): sisli günde sis yalnızca fog_phases'te. Final gecesinde
## (Secret.keeper_night: final hazır, Bekçi henüz bırakılmadı) her gece sisli, Bekçi'nin bırakıldığı gece
## sabaha kadar; o sürede fırtına olmaz.
static func at(rules: FishingRules, save: SaveData, clock_s: int = -1) -> String:
	var c := save.clock_s if clock_s < 0 else clock_s
	if DayClock.phase(rules, c) == "night" and (Secret.keeper_night(save)
			or Secret.released_on(save, DayClock.day(rules, c))):
		return "fog"
	var kind := day_kind(rules, save, DayClock.day(rules, c))
	if kind == "fog" and not DayClock.phase(rules, c) in rules.fog_phases:
		return rules.fog_else
	return kind


## Fırtına mı (yağmurlu gece)?
static func stormy(weather: String, phase: String) -> bool:
	return weather == "rain" and phase == "night"


## Bugünden başlayarak günlerin havası (bugün, yarın ...).
static func forecast(rules: FishingRules, save: SaveData, days: int = 2) -> Array[String]:
	var today := DayClock.day(rules, save.clock_s)
	var out: Array[String] = []
	for i in days:
		out.append(day_kind(rules, save, today + i))
	return out


## Deneme düğmesi: bugünün havası sıradakine döner (kayıtta; ertesi gün zar yine geçerli).
static func cycle_debug(rules: FishingRules, save: SaveData) -> String:
	var today := DayClock.day(rules, save.clock_s)
	var now := day_kind(rules, save, today)
	var next := KINDS[(KINDS.find(now) + 1) % KINDS.size()]
	save.flags[DEBUG_DAY] = today
	save.flags[DEBUG_KIND] = next
	return next
