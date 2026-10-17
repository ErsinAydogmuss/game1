class_name Zones
extends RefCounted
## Göl bölgelerine erişim (docs/gdd.md §10.1): bölge rütbeyle açılır; sandal bölgesi (derin orta)
## ayrıca sandal ister ve yalnızca sandaldayken avlanılır. Saf mantık: oturum, sunum ve denge botu
## aynı kuralı kullanır.

## Sandal takımı (gear.json kimliği).
const BOAT := "boat"


## Bölge açık mı (rütbe yetiyor ve sandal bölgesiyse sandal var)?
static func unlocked(db: ContentDB, save: SaveData, zone: Dictionary) -> bool:
	if zone.is_empty() or Rank.rank(db, save) < int(zone["rank"]):
		return false
	return not bool(zone["boat"]) or Economy.owns(db, save, BOAT)


## Gölge doğabilen bölgeler: sandaldayken açık sandal bölgeleri, karadayken açık öteki bölgeler.
static func open_ids(db: ContentDB, save: SaveData, spot_id: String, in_boat: bool = false) -> PackedStringArray:
	var out := PackedStringArray()
	for z in db.zones_of(spot_id):
		if bool(z["boat"]) == in_boat and unlocked(db, save, z):
			out.append(str(z["id"]))
	return out


## Kilitli bölgenin nedeni: { "key": çeviri anahtarı, "rank": gereken rütbe } (açıksa boş).
static func lock_reason(db: ContentDB, save: SaveData, zone: Dictionary) -> Dictionary:
	if unlocked(db, save, zone):
		return {}
	if Rank.rank(db, save) < int(zone["rank"]):
		return { "key": "UI_ZONE_LOCKED_RANK", "rank": int(zone["rank"]) }
	return { "key": "UI_ZONE_LOCKED_BOAT", "rank": int(zone["rank"]) }


## Rütbe old_rank'tan new_rank'a çıkınca açılan bölgeler (sandal bölgesi sandalla birlikte açılır).
static func unlocked_between(db: ContentDB, spot_id: String, old_rank: int, new_rank: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for z in db.zones_of(spot_id):
		var rank := int(z["rank"])
		if rank > old_rank and rank <= new_rank and not bool(z["boat"]):
			out.append(z)
	return out


## Oranların geldiği yer (CatchOdds bunu atış noktası gibi okur): bölge (verilirse ve varsa) ya da
## gölün kendisi.
static func place(db: ContentDB, spot_id: String, zone_id: String) -> Dictionary:
	var z := db.zone(spot_id, zone_id) if not zone_id.is_empty() else {}
	return z if not z.is_empty() else db.spot(spot_id)


## Noktanın bölgesi (sözlük; bölgesiz yerde boş).
static func at(db: ContentDB, spot_id: String, p: Vector2) -> Dictionary:
	var k := db.lake(spot_id).zone_at(p)
	var zones := db.zones_of(spot_id)
	return zones[k] if k >= 0 and k < zones.size() else {}
