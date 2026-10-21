class_name TrapSim
extends RefCounted
## Kerevit tuzakları (Dalga 3, rütbe 3; docs/gdd.md §10.3). Saf işlevler: kayıt (SaveData.traps,
## trap_serial) ve zaman (now: gerçek saat, unix sn) parametre olarak gelir.
## - Kurulum: bölgenin trap tablosu olan yerde (sazlık, kayalık burun), sığ suya (rules.trap_depth),
##   balıkçının yakınına (rules.trap_near), öteki tuzaklara uzak (rules.trap_spacing). En çok sahip
##   olunan tuzak kadar (dükkândaki trap_1..3).
## - İçerik kurulurken belli olur (gelir kuralı 4): tuzağa girecek trap_max kerevit o an zarlanır
##   (Dice.derive(seed, SALT, trap_serial); her zarlama sayacı bir artırır) ve "items"te sırayla
##   bekler; aynı zarlamada ayrı bir tuzla çöp de (Trash.in_trap: "trash", kerevitler aynı kalır).
##   Hızlandırma yok.
## - Dolma gerçek saatle, oyun kapalıyken de: progress_s her trap_fill_s sn'de bir kerevit
##   "girdirir", en çok trap_max (boşta biriken üst sınırda durur: gelir kuralı 7). Saat geri
##   alınırsa bir şey kaybolmaz ya da kazanılmaz (yalnızca dayanak last_unix yenilenir); ileri
##   alınırsa en çok trap_max.
## - Toplama: giren kerevitler kovaya (kova dolarsa kalanı tuzakta bekler: kayıp yok), kayıt
##   defterine ve rütbe puanına; şans garantisi sayaçları ilerlemez. Tuzaktaki çöp ilk kerevitle
##   birlikte çıkar (çağıran toplar: Trash.collect). Toplanan yerine yeni içerik zarlanır (tuzak yeniden
##   kurulur), artan süre sonraki kerevite sayılır.

const SALT := 7301


## Bölgeye tuzak kurulur mu (bölgenin trap tablosu)?
static func zone_allows(db: ContentDB, spot_id: String, zone_id: String) -> bool:
	var z := db.zone(spot_id, zone_id)
	return not z.is_empty() and not (z["trap_ids"] as PackedStringArray).is_empty()


## Tuzağın açıldığı rütbe (dükkândaki en erken tuzağınki; tuzak yoksa 0).
static func rank(db: ContentDB) -> int:
	var low := 0
	for g in db.gear_in("trap"):
		if low == 0 or int(g["rank"]) < low:
			low = int(g["rank"])
	return low


## Sahip olunan tuzak sayısı (dükkândan alınan trap_1..3).
static func owned(db: ContentDB, save: SaveData) -> int:
	var n := 0
	for g in db.gear_in("trap"):
		if Economy.owns(db, save, str(g["id"])):
			n += 1
	return n


## Kurulmayı bekleyen tuzak sayısı.
static func spare(db: ContentDB, save: SaveData) -> int:
	return maxi(0, owned(db, save) - save.traps.size())


## Dükkânda gösterilen tuzak: alınmamışların en ucuzu; hepsi alındıysa en pahalısı (tuzaklar tek
## kartta, kovalar gibi). Tuzak yoksa boş.
static func next_trap(db: ContentDB, save: SaveData) -> Dictionary:
	var next: Dictionary = {}
	var last: Dictionary = {}
	for g in db.gear_in("trap"):
		if last.is_empty() or int(g["price"]) > int(last["price"]):
			last = g
		if not Economy.owns(db, save, str(g["id"])) and (next.is_empty() or int(g["price"]) < int(next["price"])):
			next = g
	return next if not next.is_empty() else last


## Tuzağın yeri (xz).
static func position(trap: Dictionary) -> Vector2:
	return Vector2(float(trap["x"]), float(trap["z"]))


## Tuzak buraya kurulur mu: "" uygunsa; değilse nedeninin çeviri anahtarı (UI_TRAP_...).
static func place_block(db: ContentDB, save: SaveData, spot_id: String, zone_id: String, pos: Vector2,
		angler: Vector2) -> String:
	if owned(db, save) <= 0:
		return "UI_TRAP_NONE"
	if spare(db, save) <= 0:
		return "UI_TRAP_ALL_SET"
	if not zone_allows(db, spot_id, zone_id):
		return "UI_TRAP_ZONE"
	var lake := db.lake(spot_id)
	var rules := db.rules
	var zones := db.zones_of(spot_id)
	var k := lake.zone_at(pos)
	if not lake.is_water(pos) or lake.on_dock(pos, 0.3) or k < 0 or k >= zones.size() or str(zones[k]["id"]) != zone_id:
		return "UI_TRAP_NO_SPOT"
	if lake.depth_at(pos) > rules.trap_depth:
		return "UI_TRAP_DEEP"
	var d := pos.distance_to(angler)
	if d < rules.trap_near.x or d > rules.trap_near.y:
		return "UI_TRAP_NO_SPOT"
	for t in save.traps:
		if position(t).distance_to(pos) < rules.trap_spacing:
			return "UI_TRAP_CLOSE"
	return ""


## Balıkçının çevresinde tuzağın kurulacağı yer: baktığı yöne en yakın, uygun uzaklıktaki sığ su
## (place_block ""); yoksa Dice.NO_POINT.
static func spot_near(db: ContentDB, save: SaveData, spot_id: String, zone_id: String, angler: Vector2,
		facing: Vector2) -> Vector2:
	for p in _candidates(db.rules, angler, facing):
		if place_block(db, save, spot_id, zone_id, p, angler).is_empty():
			return p
	return Dice.NO_POINT


## Balıkçının çevresine neden tuzak kurulamıyor (spot_near yer bulamadıysa): önce genel neden (tuzağı
## yok, hepsi kurulu, bölge), sonra denenen yerlerde görülen: öteki tuzağa çok yakın sığ su, çok derin
## su, yoksa yakında sığ su yok. Kurulabiliyorsa "".
static func why_not(db: ContentDB, save: SaveData, spot_id: String, zone_id: String, angler: Vector2,
		facing: Vector2) -> String:
	var general := place_block(db, save, spot_id, zone_id, angler, angler)
	if general != "UI_TRAP_NO_SPOT":
		return general
	var seen := {}
	for p in _candidates(db.rules, angler, facing):
		var why := place_block(db, save, spot_id, zone_id, p, angler)
		if why.is_empty():
			return ""
		seen[why] = true
	for why: String in ["UI_TRAP_CLOSE", "UI_TRAP_DEEP"]:
		if seen.has(why):
			return why
	return "UI_TRAP_NO_SPOT"


## spot_near'ın denediği yerler, sırayla: baktığı yönden başlayıp 15°'lik adımlarla iki yana, her yönde
## uygun uzaklığın ortası, iki yanı ve uçları.
static func _candidates(rules: FishingRules, angler: Vector2, facing: Vector2) -> Array[Vector2]:
	var out: Array[Vector2] = []
	var dir0 := facing.normalized() if facing.length_squared() > 0.0001 else Vector2(0, -1)
	var mid := (rules.trap_near.x + rules.trap_near.y) * 0.5
	var distances: Array[float] = [mid, lerpf(rules.trap_near.x, mid, 0.5), lerpf(mid, rules.trap_near.y, 0.5),
			rules.trap_near.x + 0.05, rules.trap_near.y - 0.05]
	for k in 24:
		var dir := dir0.rotated(deg_to_rad(15.0 * ((k + 1) >> 1)) * (1.0 if k % 2 == 1 else -1.0))
		for d: float in distances:
			out.append(angler + dir * d)
	return out


## Tuzağı kurar (place_block'u çağıran denetler): kimliği trap_serial, içeriği o an zarlanır.
static func place(db: ContentDB, save: SaveData, spot_id: String, zone_id: String, pos: Vector2, now: int) -> Dictionary:
	var trap := {
		"id": save.trap_serial,
		"zone": zone_id,
		"x": pos.x,
		"z": pos.y,
		"placed_unix": now,
		"last_unix": now,
		"progress_s": 0,
		"items": [],
		"trash": "",
	}
	_top_up(db, save, spot_id, trap)
	save.traps.append(trap)
	return trap


## Tuzağın dolması now'a getirilir: saat ileri gittiyse geçen süre eklenir (en çok dolu), geri
## gittiyse yalnızca dayanak yenilenir (bir şey kaybolmaz ya da kazanılmaz).
static func update(rules: FishingRules, trap: Dictionary, now: int) -> void:
	var last := int(trap["last_unix"])
	if now > last:
		var full := rules.trap_fill_s * mini(rules.trap_max, (trap["items"] as Array).size())
		trap["progress_s"] = mini(full, int(trap["progress_s"]) + (now - last))
	trap["last_unix"] = now


## Bütün tuzaklar now'a (uygulama öne gelince, kayıt açılınca).
static func update_all(rules: FishingRules, save: SaveData, now: int) -> void:
	for t in save.traps:
		update(rules, t, now)


## Tuzağa girmiş kerevit sayısı (en çok trap_max).
static func ready(rules: FishingRules, trap: Dictionary) -> int:
	var entered := int(float(trap["progress_s"]) / float(rules.trap_fill_s))
	return mini(entered, mini(rules.trap_max, (trap["items"] as Array).size()))


## Sıradaki kerevitin girmesine kalan sn (tuzak doluysa 0).
static func seconds_to_next(rules: FishingRules, trap: Dictionary) -> int:
	if ready(rules, trap) >= rules.trap_max:
		return 0
	return rules.trap_fill_s - int(trap["progress_s"]) % rules.trap_fill_s


## Kimliğiyle tuzağın sırası (yoksa -1).
static func find(save: SaveData, id: int) -> int:
	for i in save.traps.size():
		if int(save.traps[i]["id"]) == id:
			return i
	return -1


## Tuzaktaki kerevitler toplanır: kovaya (sığmayan tuzakta bekler), kayıt defterine ve rütbe
## puanına (şans garantisi ilerlemez). Toplanan kadar yeni içerik zarlanır. Döner: { items: toplanan
## [{ fish, size_cm, stars }], left: tuzakta kalan, new_species: defterde yeni tür, ranked:
## Rank.add_xp sonucu (rütbe atlama), trash: kerevitle çıkan çöp ("" yoksa; çağıran toplar) }.
static func collect(db: ContentDB, save: SaveData, spot_id: String, index: int, now: int) -> Dictionary:
	var out: Array[Dictionary] = []
	var result := { "items": out, "left": 0, "new_species": false, "ranked": {}, "trash": "" }
	if index < 0 or index >= save.traps.size():
		return result
	var rules := db.rules
	var trap := save.traps[index]
	update(rules, trap, now)
	var items: Array = trap["items"]
	var n := ready(rules, trap)
	var xp := 0
	for k in n:
		var item: Dictionary = items[0]
		var fish_id := str(item["fish"])
		if not Bucket.add(db, save, fish_id, int(item["size_cm"]), int(item["stars"])):
			break
		items.remove_at(0)
		trap["progress_s"] = int(trap["progress_s"]) - rules.trap_fill_s
		var outcome := Records.add(save.records, fish_id, int(item["size_cm"]), int(item["stars"]), now)
		if bool(outcome.get("new_species", false)):
			result["new_species"] = true
		xp += Rank.catch_xp(db, int(db.fish_by_id(fish_id)["rarity"]), int(item["stars"]))
		out.append(item)
	result["left"] = ready(rules, trap)
	if not out.is_empty():
		result["trash"] = str(trap.get("trash", ""))
		trap["trash"] = ""
		_top_up(db, save, spot_id, trap)
		save.stats["trapped"] = int(save.stats.get("trapped", 0)) + out.size()
	result["ranked"] = Rank.add_xp(db, save, xp)
	return result


## Tuzağı kaldırır (dükkândaki tuzak geri kurulabilir). Girmiş kerevit varsa önce toplanmalı
## (çağıran toplar); girmemiş içerik bekler hiç girmemiş sayılır.
static func remove(save: SaveData, index: int) -> void:
	if index >= 0 and index < save.traps.size():
		save.traps.remove_at(index)


## Tuzağın bekleyen içeriği trap_max'a tamamlanır: bir zarlama, trap_serial'dan türeyen bir RNG ile
## (bölgenin trap tablosundan tür, FishTable'dan boy ve yıldız). Tuzakta bekleyen çöp yoksa aynı sıra
## numarasıyla çöp de zarlanır (Trash.in_trap: başka tuz, kerevitlerin zarına dokunmaz; payı yeni kerevit
## sayısıyla: bir kerevit toplayıp yenileyen, dördünü birden toplayandan kerevit başına çok çöp bulmaz).
static func _top_up(db: ContentDB, save: SaveData, spot_id: String, trap: Dictionary) -> void:
	var items: Array = trap["items"]
	if items.size() >= db.rules.trap_max:
		return
	var z := db.zone(spot_id, str(trap["zone"]))
	var ids: PackedStringArray = z.get("trap_ids", PackedStringArray())
	var weights: PackedInt32Array = z.get("trap_weights", PackedInt32Array())
	if ids.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = Dice.derive(save.seed, SALT, save.trap_serial)
	if str(trap.get("trash", "")).is_empty():
		var added := db.rules.trap_max - items.size()
		trap["trash"] = Trash.in_trap(db.rules, save.seed, save.trap_serial, added / float(db.rules.trap_max))
	save.trap_serial += 1
	while items.size() < db.rules.trap_max:
		var fish_id := ids[maxi(0, Dice.pick_weighted(rng, weights))]
		var def := db.fish_by_id(fish_id)
		var percentile := FishTable.roll_percentile(rng)
		items.append({ "fish": fish_id, "size_cm": FishTable.size_cm(def, percentile), "stars": FishTable.stars(percentile) })
