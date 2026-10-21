class_name Trash
extends RefCounted
## Çöp (Dalga 4; docs/gdd.md §6, §10.5): gölde eski çizme, teneke kutu, plastik şişe, paslı anahtar
## (rules.json trash). Dipte tutulan balığın yanında (trash_bottom_ppm: kurşun dibi tarar; şamandıra, spin
## ve sinek yüzeyde) ya da tuzağın içeriğiyle (trash_trap_ppm) çıkar. Ne çıkacağı önceden bellidir (gelir
## kuralı 4): balıkta gölgenin seed'inin kendi tuzu (gölgenin türü, boyu ve yolu kaymaz), tuzakta içerik
## zarlanırken ayrı bir tuzla (kerevitler aynı kalır). Toplanınca göl sevgisi verir; kovaya girmez,
## satılmaz; sayaçlar stats.trash ve stats.trash_<eşya>.

## Gölgenin seed'inden çöp zarının tuzu (2: tür, 3: boy: FishShadow).
const SHADOW_SALT := 4
## Tuzağın içeriğinden ayrı tuz (kerevitler TrapSim.SALT ile).
const TRAP_SALT := 7302
## Çöp çıkaran teknik.
const TECHNIQUE := "bottom"


## Tutulan balığın yanında çıkan çöp ("" yoksa): yalnızca dip tekniğinde; zar gölgenin seed'inden.
static func with_catch(rules: FishingRules, shadow_seed: int, technique: String) -> String:
	if technique != TECHNIQUE:
		return ""
	return _roll(rules, Dice.derive(shadow_seed, SHADOW_SALT), rules.trash_bottom_ppm)


## Tuzağın yeni içeriğiyle gelen çöp ("" yoksa): kaydın seed'i ve içeriğin sıra numarası (trap_serial;
## kerevitlerle aynı sayı, başka tuz).
static func in_trap(rules: FishingRules, save_seed: int, serial: int) -> String:
	return _roll(rules, Dice.derive(save_seed, TRAP_SALT, serial), rules.trash_trap_ppm)


static func _roll(rules: FishingRules, roll_seed: int, chance_ppm: int) -> String:
	var rng := RandomNumberGenerator.new()
	rng.seed = roll_seed
	if not Dice.chance(rng, chance_ppm):
		return ""
	var i := Dice.pick_weighted(rng, rules.trash_weights)
	return rules.trash_ids[i] if i >= 0 else ""


## Eşyanın göl sevgisi (bilinmeyen eşyada 0).
static func love_of(rules: FishingRules, item: String) -> int:
	var i := rules.trash_ids.find(item)
	return rules.trash_love[i] if i >= 0 else 0


## Çöp toplandı: göl sevgisi ve sayaçlar (kovaya girmez, para vermez). Döner: LakeLove.add'in sonucu
## ({ old_level, new_level }) ve "love" (kaç sevgi).
static func collect(rules: FishingRules, save: SaveData, item: String) -> Dictionary:
	var love := love_of(rules, item)
	var out := LakeLove.add(rules, save, love)
	out["love"] = love
	save.stats["trash"] = int(save.stats.get("trash", 0)) + 1
	save.stats["trash_" + item] = int(save.stats.get("trash_" + item, 0)) + 1
	return out


## Eşyadan kaç tane toplandı (Dede'nin ilk sözü, defter).
static func found(save: SaveData, item: String) -> int:
	return int(save.stats.get("trash_" + item, 0))
