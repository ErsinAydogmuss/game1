class_name LakeLove
extends RefCounted
## Göl sevgisi (docs/gdd.md §10.5): göle bırakılan balık (nadirliğe göre), toplanan çöp ve
## istekler verir; hiç azalmaz. 10 seviye (rules.json love.levels); her seviye Nadir ve üstü
## türlerin ağırlığını %4 artırır (en çok %36; CatchOdds, defterdeki oranlara yansır). Seviye 6'da
## Nine altın hamuru verir (Gölün Sırrı). Göl seviyeyle güzelleşir (sunum).


## Sevginin seviyesi (1..max_level).
static func level(rules: FishingRules, love: int) -> int:
	var lvl := 1
	for i in range(1, rules.love_levels.size()):
		if love >= rules.love_levels[i]:
			lvl = i + 1
	return lvl


static func max_level(rules: FishingRules) -> int:
	return rules.love_levels.size()


## Sıradaki seviyenin eşiği (en yüksek seviyede -1).
static func next_at(rules: FishingRules, love: int) -> int:
	var lvl := level(rules, love)
	return rules.love_levels[lvl] if lvl < rules.love_levels.size() else -1


## Seviyenin içindeki ilerleme (0..1; en yüksek seviyede 1).
static func progress(rules: FishingRules, love: int) -> float:
	var lvl := level(rules, love)
	if lvl >= rules.love_levels.size():
		return 1.0
	var from := rules.love_levels[lvl - 1]
	var to := rules.love_levels[lvl]
	return clampf(float(love - from) / float(to - from), 0.0, 1.0)


## Seviyenin Nadir ve üstü türlere çarpanı (binde: seviye 1'de 1000).
static func rare_bonus_pm(rules: FishingRules, lvl: int) -> int:
	return 1000 + roundi(rules.love_rare_bonus * 1000.0 * float(clampi(lvl, 1, max_level(rules)) - 1))


## Sevgi eklenir. Döner: { old_level, new_level } (seviye atladıysa bildirim).
static func add(rules: FishingRules, save: SaveData, amount: int) -> Dictionary:
	var old := level(rules, save.love)
	save.love = maxi(0, save.love + maxi(0, amount))
	return { "old_level": old, "new_level": level(rules, save.love) }
