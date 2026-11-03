class_name CatRules
extends RefCounted
## Tekir (Dalga 5, 2. adım; docs/gdd.md §7). Saf işlevler: kayıt parametre olarak gelir.
## - İskelenin kedisi balıkçının peşinden gelir, arada bir acıkır: son beslenmeden (ya da gelişinden) beri
##   rules.cat_meal_every balık tutulunca. Acıkma balık sayısından türer, gerçek saatten değil: oyuncu yokken
##   aç kalmaz, beklemesi uzamaz, bir şey kaybolmaz (gelir kuralı 7).
## - Acıkmışken dokununca kovadaki en ucuz balığı yer (değeri eşitse en küçüğü, sonra ilk gireni). Kova boşsa
##   bekler (ceza yok).
## - Her rules.cat_gift_every beslemede sıradaki hediyeyi getirir (sabit sıra, zar yok). Hediyeler kıyafettir
##   (4. adım: data/outfits.json'da şartı "cat" olanlar, değerleri sırası: OutfitRules.cat_gift); sayıları besleme
##   sayısından türer: önceden kazanılan hediye kaybolmaz. Hediyeler bitince Tekir yine yer, hediye getirmez.


## Acıktı mı?
static func is_hungry(rules: FishingRules, save: SaveData) -> bool:
	return save.catches - save.cat_meal_at >= rules.cat_meal_every


## Acıkmasına kalan balık (acıktıysa 0).
static func meals_left(rules: FishingRules, save: SaveData) -> int:
	return maxi(0, rules.cat_meal_every - (save.catches - save.cat_meal_at))


## Kediye verilecek balığın kovadaki sırası: en ucuzu (değeri eşitse en küçüğü, sonra ilk gireni); kova boşsa -1.
static func pick(db: ContentDB, save: SaveData) -> int:
	var best := -1
	var best_value := 0
	for i in save.bucket.size():
		var entry := save.bucket[i]
		var value := Economy.fish_value(db, str(entry["fish"]), int(entry["size_cm"]))
		if best < 0 or value < best_value \
				or (value == best_value and int(entry["size_cm"]) < int(save.bucket[best]["size_cm"])):
			best = i
			best_value = value
	return best


## Besler: kovadaki en ucuz balık gider, sayaçlar ilerler. Acıkmamışsa ya da kova boşsa {} (kedi bekler).
## Döner: { fish, size_cm, stars, value, fed: toplam besleme, gift: bu beslemeyle gelen hediyenin sırası (1'den;
## yoksa 0), gift_id: o hediyenin kıyafeti (hediyeler bittiyse boş) }.
static func feed(db: ContentDB, save: SaveData) -> Dictionary:
	if not is_hungry(db.rules, save):
		return {}
	var index := pick(db, save)
	if index < 0:
		return {}
	var entry: Dictionary = save.bucket[index]
	save.bucket.remove_at(index)
	save.cat_fed += 1
	save.cat_meal_at = save.catches
	save.stats["cat_fed"] = int(save.stats.get("cat_fed", 0)) + 1
	var every := db.rules.cat_gift_every
	var gift := floori(float(save.cat_fed) / every) if save.cat_fed % every == 0 else 0
	return {
		"fish": str(entry["fish"]),
		"size_cm": int(entry["size_cm"]),
		"stars": int(entry["stars"]),
		"value": Economy.fish_value(db, str(entry["fish"]), int(entry["size_cm"])),
		"fed": save.cat_fed,
		"gift": gift,
		"gift_id": db.outfits.cat_gift(gift) if gift > 0 else "",
	}


## Kazanılan hediye sayısı (her cat_gift_every beslemede bir).
static func gifts(rules: FishingRules, save: SaveData) -> int:
	return floori(float(save.cat_fed) / rules.cat_gift_every)
