class_name CatchOdds
extends RefCounted
## Hangi balığın geleceği (docs/gdd.md §10.2): bölgenin tür ağırlıkları × yemin (yapay yemin,
## sineğin) çekimi × türün teknik yatkınlığı (fish.json affinity) ve gölün o anki koşulları (Dalga 4:
## vakit, hava ve göl sevgisi; WorldState). Oranlar ppm'dir (toplam tam 1e6). Doğan her gölge, Balık
## Defteri ve katalog aynı işlevleri kullanır (bağlamı context kurar): ekranda yazan oran gerçek
## orandır (gelir kuralı 10). Şamandırada Dalga 3 öncesi bütün türlerin yatkınlığı 1: oranlar bit
## bit aynı.
##
## Koşullar iki aşamada girer: önce bugünkü hesap (yalnızca belli vakitte ya da havada gelen tür,
## fish.json "only", o koşulda yoksa 0), sonra çıkan ppm türün koşul çarpanıyla (vakit × hava ×
## sevgi, binde) yeniden dağıtılır. Bütün çarpanlar 1000'se ikinci aşama atlanır: koşulsuz bağlamda
## (koşul anahtarı yok) tercihler sayılmaz, "only" türler gelmez ve her sayı eskisi gibidir (altın
## test). Tek aşamada çarpılsaydı 64 bitlik ara çarpım taşabilirdi.
##
## Şans garantisi: bir nadirlik ve üstü uzun süre gelmezse (rarities.json "pity" av) yakında
## doğan sıradaki gölge o nadirlikten olur. Garanti bir gölge doğurur, balığı tutmak yine
## oyuncunun becerisi; sayaç ancak o nadirlikte bir balık tutulunca sıfırlanır.
@warning_ignore_start("integer_division")

const PPM := Dice.PPM


## Koşul anahtarları (WorldState.conditions; bağlamda olmayan koşul sayılmaz).
const CONDITIONS: Array[String] = ["phase", "weather", "love"]


## Türlerin oranları: fish_id -> ppm (toplam 1e6; teknikle gelen tür yoksa boş). ctx:
## { "attract": {fish_id: çarpan}, "technique": teknik (varsayılan şamandıra), "phase": vakit,
## "weather": hava, "love": göl sevgisinin seviyesi } (context kurar). spot bir bölgeyse ve teknik
## orada avlanılmıyorsa (techniques) boş.
static func species_ppm(db: ContentDB, spot: Dictionary, ctx: Dictionary = {}) -> Dictionary:
	var ids: PackedStringArray = spot.get("fish_ids", PackedStringArray())
	var weights: PackedInt32Array = spot.get("fish_weights", PackedInt32Array())
	var attract: Dictionary = ctx.get("attract", {})
	var technique := str(ctx.get("technique", "float"))
	if not allows(spot, technique):
		return {}
	var conditioned := has_conditions(ctx)
	var raw: Array[int] = []
	var factors := PackedInt32Array()
	var neutral := true
	for i in ids.size():
		var mult := roundi(float(attract.get(ids[i], 1.0)) * 1000.0)
		var aff := roundi(db.affinity(ids[i], technique) * 1000.0)
		var here := 1 if available(db, ids[i], ctx) else 0
		raw.append(maxi(0, weights[i]) * maxi(0, mult) * maxi(0, aff) * here)
		var factor := factor_pm(db, ids[i], ctx) if conditioned else 1000
		factors.append(factor)
		neutral = neutral and factor == 1000
	var out := _normalize(ids, raw)
	if neutral or out.is_empty():
		return out
	# İkinci aşama: ilk aşamanın oranı × koşul çarpanı (ilk aşamadaki türler, aynı sırayla).
	var kept := PackedStringArray()
	var raw2: Array[int] = []
	for i in ids.size():
		if out.has(ids[i]):
			kept.append(ids[i])
			raw2.append(int(out[ids[i]]) * factors[i])
	return _normalize(kept, raw2)


## Oranların bağlamı: kuşanılmış takımın yem çekimi, teknik ve gölün koşulları (WorldState.conditions;
## verilmezse koşulsuz). Oranı gösteren ve kullanan her yer bunu kurar.
static func context(gear: GearStats, technique: String, conditions: Dictionary = {}) -> Dictionary:
	var ctx := { "attract": gear.attract if gear != null else {}, "technique": technique }
	for key in CONDITIONS:
		if conditions.has(key):
			ctx[key] = conditions[key]
	return ctx


## Bağlamda koşul var mı (vakit, hava ya da sevgi)?
static func has_conditions(ctx: Dictionary) -> bool:
	for key in CONDITIONS:
		if ctx.has(key):
			return true
	return false


## Tür bu koşulda gelir mi? Yalnızca belli vakitlerde ya da havalarda gelen tür (fish.json "only")
## bağlamda o vakit ve hava yoksa gelmez; ötekiler hep gelir.
static func available(db: ContentDB, fish_id: String, ctx: Dictionary) -> bool:
	return db.fish_available(fish_id, str(ctx.get("phase", "")), str(ctx.get("weather", "")))


## Türün koşul çarpanı (binde; en az 1): vaktin ve havanın tercihi (fish.json when, weather) ve göl
## sevgisinin Nadir+ payı (LakeLove). Bağlamda olmayan koşul 1000 sayılır.
static func factor_pm(db: ContentDB, fish_id: String, ctx: Dictionary) -> int:
	var f := 1000
	if ctx.has("phase"):
		f = f * roundi(db.when_mult(fish_id, str(ctx["phase"])) * 1000.0) / 1000
	if ctx.has("weather"):
		f = f * roundi(db.weather_mult(fish_id, str(ctx["weather"])) * 1000.0) / 1000
	if ctx.has("love") and int(db.fish_by_id(fish_id).get("rarity", 0)) >= db.rarity_index(db.rules.love_from):
		f = f * LakeLove.rare_bonus_pm(db.rules, int(ctx["love"])) / 1000
	return maxi(1, f)


## Bölgede bu teknikle avlanılır mı (bölgenin "techniques"i; atış noktasının bütünü hep evet)?
static func allows(spot: Dictionary, technique: String) -> bool:
	return not spot.has("techniques") or technique in (spot["techniques"] as PackedStringArray)


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
## Birden çok kademe dolduysa en yükseği. spot verilirse yalnızca o gölde (o teknikle, o koşulda:
## ctx) tutulabilen kademeler sayılır: gölde Efsanevi tür yokken dolan Efsanevi sayacı Nadir ve
## Destansı garantisini kilitlemez (ve gölde olmayan bir şey vaat edilmez: gündüz Ay Turnası yok).
static func pity_floor(db: ContentDB, save: SaveData, spot: Dictionary = {}, technique: String = "float",
		ctx: Dictionary = {}) -> int:
	var top := top_rarity(db, spot, technique, ctx) if not spot.is_empty() else db.rarities.size() - 1
	var floor := -1
	for i in mini(db.rarities.size(), top + 1):
		var every := int(db.rarities[i]["pity"])
		if every > 0 and int(save.pity.get(db.rarity_id(i), 0)) >= every:
			floor = i
	return floor


## Bu gölde (bölgede) bu teknikle doğabilen en yüksek nadirlik (doğma ağırlığı ve teknik yatkınlığı
## olan ve o koşulda gelen türlerden: ctx; tür yoksa -1).
static func top_rarity(db: ContentDB, spot: Dictionary, technique: String = "float", ctx: Dictionary = {}) -> int:
	if not allows(spot, technique):
		return -1
	var ids: PackedStringArray = spot.get("fish_ids", PackedStringArray())
	var weights: PackedInt32Array = spot.get("fish_weights", PackedInt32Array())
	var top := -1
	for i in ids.size():
		if weights[i] > 0 and db.affinity(ids[i], technique) > 0.0 and available(db, ids[i], ctx):
			top = maxi(top, int(db.fish_by_id(ids[i]).get("rarity", -1)))
	return top


## Kademenin garantisine kaç av kaldı (defterde gösterilir; garantisi yoksa -1).
static func pity_left(db: ContentDB, save: SaveData, rarity: int) -> int:
	var every := int(db.rarity_def(rarity).get("pity", 0))
	if every <= 0:
		return -1
	return maxi(0, every - int(save.pity.get(db.rarity_id(rarity), 0)))


## Bir balık tutuldu: tutulan nadirlik ve altındaki kademelerin sayacı sıfırlanır, üstündekiler
## bir artar. spot verilirse o gölde tutulamayan kademelerin sayacı ilerlemez (olduğu gibi kalır):
## sayaç yalnızca o kademenin gelebildiği avları sayar; gölde olmayan bir şey için biriken sayaç,
## kademe bir gün göle gelince anında garanti vermesin. Teknik ve koşul (ctx) de öyle: o teknikle ya
## da o vakitte gelmeyen kademenin sayacı ilerlemez.
static func note_catch(db: ContentDB, save: SaveData, rarity: int, spot: Dictionary = {}, technique: String = "float",
		ctx: Dictionary = {}) -> void:
	var top := top_rarity(db, spot, technique, ctx) if not spot.is_empty() else db.rarities.size() - 1
	for i in db.rarities.size():
		if int(db.rarities[i]["pity"]) <= 0:
			continue
		var id := db.rarity_id(i)
		if rarity >= i:
			save.pity[id] = 0
		elif i <= top:
			save.pity[id] = int(save.pity.get(id, 0)) + 1


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
	# Bu teknikle (ya da bu yemle) hiç gelmeyen tür listede olmaz. Kalanlar ona hiç düşmez
	# (kalan birim sayısı, kalanı olan türlerden azdır): ötekilerin oranı değişmez.
	for i in ids.size():
		if raw[i] <= 0:
			out.erase(ids[i])
	return out
