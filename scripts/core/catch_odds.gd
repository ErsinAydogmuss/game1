class_name CatchOdds
extends RefCounted
## Hangi balığın geleceği (docs/gdd.md §10.2): atış noktasının tür ağırlıkları × yemin çekimi
## (sonraki dalgalarda bölge, teknik, vakit, hava ve göl sevgisi de girer). Oranlar ppm'dir
## (toplam tam 1e6). Doğan her gölge, Balık Defteri ve katalog aynı işlevleri kullanır: ekranda
## yazan oran gerçek orandır (gelir kuralı 10).
##
## Şans garantisi: bir nadirlik ve üstü uzun süre gelmezse (rarities.json "pity" av) yakında
## doğan sıradaki gölge o nadirlikten olur. Garanti bir gölge doğurur, balığı tutmak yine
## oyuncunun becerisi; sayaç ancak o nadirlikte bir balık tutulunca sıfırlanır.

const PPM := Dice.PPM


## Türlerin oranları: fish_id -> ppm (toplam 1e6). ctx: { "attract": {fish_id: çarpan} }.
static func species_ppm(db: ContentDB, spot: Dictionary, ctx: Dictionary = {}) -> Dictionary:
	var ids: PackedStringArray = spot.get("fish_ids", PackedStringArray())
	var weights: PackedInt32Array = spot.get("fish_weights", PackedInt32Array())
	var attract: Dictionary = ctx.get("attract", {})
	var raw: Array[int] = []
	for i in ids.size():
		var mult := roundi(float(attract.get(ids[i], 1.0)) * 1000.0)
		raw.append(maxi(0, weights[i]) * maxi(0, mult))
	return _normalize(ids, raw)


## Nadirlik başına oran (ppm; dizi sırası = nadirlik sırası, toplam 1e6).
static func rarity_ppm(db: ContentDB, species: Dictionary) -> PackedInt32Array:
	var out := PackedInt32Array()
	out.resize(db.rarities.size())
	for id: String in species:
		var rarity := int(db.fish_by_id(id).get("rarity", 0))
		out[rarity] += int(species[id])
	return out


## Tür seçer. min_rarity >= 0 ise (şans garantisi) yalnızca o nadirlik ve üstündeki türler
## arasından, aralarındaki oranlar korunarak; böyle tür yoksa normal seçim.
static func roll(db: ContentDB, rng: RandomNumberGenerator, species: Dictionary, min_rarity: int = -1) -> String:
	var ids := PackedStringArray()
	var weights := PackedInt32Array()
	var total := 0
	for id: String in species:
		if min_rarity >= 0 and int(db.fish_by_id(id).get("rarity", 0)) < min_rarity:
			continue
		ids.append(id)
		weights.append(int(species[id]))
		total += maxi(0, int(species[id]))
	if total <= 0:
		return roll(db, rng, species, -1) if min_rarity >= 0 else ""
	return ids[Dice.pick_weighted(rng, weights)]


## Şans garantisi: sıradaki gölge en az hangi nadirlikte olmalı (garanti dolmadıysa -1).
## Birden çok kademe dolduysa en yükseği.
static func pity_floor(db: ContentDB, save: SaveData) -> int:
	var floor := -1
	for i in db.rarities.size():
		var every := int(db.rarities[i]["pity"])
		if every > 0 and int(save.pity.get(db.rarity_id(i), 0)) >= every:
			floor = i
	return floor


## Kademenin garantisine kaç av kaldı (defterde gösterilir; garantisi yoksa -1).
static func pity_left(db: ContentDB, save: SaveData, rarity: int) -> int:
	var every := int(db.rarity_def(rarity).get("pity", 0))
	if every <= 0:
		return -1
	return maxi(0, every - int(save.pity.get(db.rarity_id(rarity), 0)))


## Bir balık tutuldu: tutulan nadirlik ve altındaki kademelerin sayacı sıfırlanır, üstündekiler
## bir artar.
static func note_catch(db: ContentDB, save: SaveData, rarity: int) -> void:
	for i in db.rarities.size():
		if int(db.rarities[i]["pity"]) <= 0:
			continue
		var id := db.rarity_id(i)
		save.pity[id] = 0 if rarity >= i else int(save.pity.get(id, 0)) + 1


## Ağırlıkları toplamı tam 1e6 olan ppm'e çevirir (en büyük kalan yöntemi; eşitlikte sıra).
static func _normalize(ids: PackedStringArray, raw: Array[int]) -> Dictionary:
	var out := {}
	var total := 0
	for w in raw:
		total += w
	if total <= 0:
		return out
	var given := 0
	var rests: Array[int] = []
	for i in ids.size():
		var exact := raw[i] * PPM
		out[ids[i]] = exact / total
		given += exact / total
		rests.append(exact % total)
	var order: Array[int] = []
	for i in ids.size():
		order.append(i)
	order.sort_custom(func(a: int, b: int) -> bool: return rests[a] > rests[b] or (rests[a] == rests[b] and a < b))
	var k := 0
	while given < PPM and k < order.size():
		out[ids[order[k]]] = int(out[ids[order[k]]]) + 1
		given += 1
		k += 1
	return out
