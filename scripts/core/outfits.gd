class_name Outfits
extends RefCounted
## Kıyafetlerin kuralları (Dalga 5, docs/gdd.md §7; saf). Verisi OutfitRules'ta (data/outfits.json).
## - Açılma kayıttan türer: rütbe, defterdeki tür, biten istek, göl sevgisi, Gölün Bekçisi, Tekir'in hediyeleri
##   (beslemeden türer: CatRules.gifts). Ayrı bir "sahip olunanlar" listesi yok: geriye dönük de açılır.
## - Giyilen kıyafet kayıtta (SaveData.outfit: yuva → kimlik); eksik, bilinmeyen, başka yuvanın ya da kilitli
##   kimlik varsayılana döner (equipped).
## - Yeni açılan kıyafet bir kez duyurulur: bayrak FLAG ("new": dolapta rozet; dolapta görülünce "seen").
##   Başlangıç kıyafetleri duyurulmaz.

const FLAG := "outfit_%s"
const NEW := "new"
const SEEN := "seen"


## Kıyafet açık mı?
static func unlocked(db: ContentDB, save: SaveData, id: String) -> bool:
	var e := db.outfits.item(id)
	if e.is_empty():
		return false
	var at := progress(db, save, id)
	return at.x >= at.y


## Şartın ilerlemesi: Vector2i(şimdiki, hedef). Başlangıç kıyafetinde (1, 1), Bekçi'de (0 ya da 1, 1).
static func progress(db: ContentDB, save: SaveData, id: String) -> Vector2i:
	var e := db.outfits.item(id)
	if e.is_empty():
		return Vector2i(0, 1)
	var value := int(e["value"])
	match str(e["unlock"]):
		"start":
			return Vector2i(1, 1)
		"rank":
			return Vector2i(Rank.rank(db, save), value)
		"species":
			return Vector2i(Records.species_count(save.records), value)
		"requests":
			return Vector2i(int(save.stats.get("requests", 0)), value)
		"love":
			return Vector2i(LakeLove.level(db.rules, save.love), value)
		"keeper":
			return Vector2i(1 if save.keeper > 0 else 0, 1)
		"cat":
			return Vector2i(CatRules.gifts(db.rules, save), value)
	return Vector2i(0, 1)


## Kilitli kıyafetin nasıl açılacağı: [çeviri anahtarı, değerler] (UI_OUTFIT_<ŞART>; başlangıç kıyafetinde boş).
static func reason(db: ContentDB, id: String) -> Array:
	var e := db.outfits.item(id)
	if e.is_empty() or str(e["unlock"]) == "start":
		return []
	var kind := str(e["unlock"])
	if kind == "keeper":
		return ["UI_OUTFIT_KEEPER", []]
	return ["UI_OUTFIT_" + kind.to_upper(), [int(e["value"])]]


## Yuvada giyilen kıyafet: kayıttaki kimlik bu yuvanın açık bir kıyafetiyse o, değilse varsayılan.
static func equipped(db: ContentDB, save: SaveData, slot: String) -> String:
	var id := str(save.outfit.get(slot, ""))
	var e := db.outfits.item(id)
	if not e.is_empty() and str(e["slot"]) == slot and unlocked(db, save, id):
		return id
	return db.outfits.default_of(slot)


## Giyer: açık değilse ya da bilinmiyorsa false. Varsayılan da kimliğiyle yazılır.
static func equip(db: ContentDB, save: SaveData, id: String) -> bool:
	var e := db.outfits.item(id)
	if e.is_empty() or not unlocked(db, save, id):
		return false
	save.outfit[str(e["slot"])] = id
	return true


## Giyilen kıyafetler: yuva → kıyafetin satırı (OutfitRules; görünüş buradan kurulur).
static func look(db: ContentDB, save: SaveData) -> Dictionary:
	var out := {}
	for slot: String in SaveData.OUTFIT_SLOTS:
		out[slot] = db.outfits.item(equipped(db, save, slot))
	return out


## Açılmış ama henüz duyurulmamış ve dolapta görülmemiş kıyafetler (dosyadaki sırayla).
static func fresh(db: ContentDB, save: SaveData) -> Array[String]:
	var out: Array[String] = []
	for e in db.outfits.items:
		var id := str(e["id"])
		if str(e["unlock"]) != "start" and not save.flags.has(FLAG % id) and unlocked(db, save, id):
			out.append(id)
	return out


## Duyurulanlar "yeni" (dolapta rozet).
static func announce(save: SaveData, ids: Array[String]) -> void:
	for id in ids:
		save.flags[FLAG % id] = NEW


## Dolapta görülmemiş yeni kıyafet mi?
static func is_new(save: SaveData, id: String) -> bool:
	return str(save.flags.get(FLAG % id, "")) == NEW


## Dolapta görüldü (açıksa; duyurulmamışsa da: sonradan yine duyurulmaz).
static func mark_seen(db: ContentDB, save: SaveData, id: String) -> void:
	var e := db.outfits.item(id)
	if not e.is_empty() and str(e["unlock"]) != "start" and unlocked(db, save, id):
		save.flags[FLAG % id] = SEEN


## Görülmemiş yeni kıyafetlerin sayısı (yuva verilirse yalnızca onun: dolabın sekme rozeti).
static func new_count(db: ContentDB, save: SaveData, slot: String = "") -> int:
	var n := 0
	for e in db.outfits.items:
		if (slot.is_empty() or str(e["slot"]) == slot) and is_new(save, str(e["id"])):
			n += 1
	return n
