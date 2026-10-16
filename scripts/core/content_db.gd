class_name ContentDB
extends RefCounted
## Oyun içeriği: data/*.json dosyalarını yükler ve doğrular. Hatalar `errors` listesine yazılır
## (oyun açılışta bunları konsola basar, testler boş olmasını bekler).
##
## Olasılıklar ppm (milyonda bir) tamsayıdır: seed'li zarlar tamsayı karşılaştırır, float
## yuvarlaması cihazdan cihaza fark yaratmaz.

const DATA_DIR := "res://data"
const PPM := 1_000_000

## Nadirlikler, sırayla (0 Sıradan .. 5 Masalsı): id, color, shape, shadow_fx, xp, love, pity.
## Kayıtlar sıra numarasını tutar: yalnızca sona eklenir.
var rarities: Array[Dictionary] = []
## Balıklar: id, rarity (sıra), value (para), shadow_m, size_cm (Vector2i), weight, color, back,
## accent, fight { reel, pull, burst_pull, burst_every, burst_len (sn, Vector2), *_steps (Vector2i),
## run }.
var fish: Array[Dictionary] = []
## Takım (gear.json): id, category, price, rank, icon, kind ve kategoriye göre değerler
## (rod: technique, range_m, power; reel: reel_speed, drag; line: snap_after, stealth;
## hook: escape_extra; bobber: window_add; bait: attract {tür: çarpan}, pack; extra: catch_m;
## bucket: capacity).
var gear: Array[Dictionary] = []
## Başlangıç takımı: yuva (rod, reel, line, hook, bobber, bait, bucket) -> takım kimliği.
var gear_start: Dictionary = {}
## Rütbe eşikleri (her rütbeye geçmek için toplam puan; [0] = 1. rütbe = 0) ve unvanlar
## [{from, id}].
var rank_xp: PackedInt32Array = []
var rank_titles: Array[Dictionary] = []
## Atış noktaları: id, ellipses [{center, radius, angle (radyan)}], dock (Rect2), start,
## max_shadows, fish_ids, fish_weights, first_fish, first_shadow {pos, heading}, max_depth, shelf_m.
var spots: Array[Dictionary] = []
## Oyunun açıldığı atış noktası (spots.json "main").
var main_spot: String = ""
var rules: FishingRules
var errors: PackedStringArray = []

## Takım kategorileri ve kuşanılan yuvalar (bucket ve extra kuşanılmaz: sahip olunan en iyisi
## ya da hepsi işler).
const GEAR_CATEGORIES: Array[String] = ["rod", "reel", "line", "hook", "bobber", "bait", "extra", "bucket"]
const GEAR_SLOTS: Array[String] = ["rod", "reel", "line", "hook", "bobber", "bait"]
const TECHNIQUES: Array[String] = ["float", "spin", "bottom", "fly"]
const RARITY_SHAPES: Array[String] = ["circle", "triangle", "diamond", "star", "sparkle", "medallion"]
const SHADOW_FX: Array[String] = ["none", "glint", "shimmer", "trail", "guardian"]

var _rarity_index: Dictionary = {}
var _fish_index: Dictionary = {}
var _gear_index: Dictionary = {}
var _spot_index: Dictionary = {}
## Atış noktası id -> LakeShape (bir kez kurulur).
var _lakes: Dictionary = {}


static func load_default() -> ContentDB:
	return load_from(DATA_DIR)


static func load_from(dir: String) -> ContentDB:
	var db := ContentDB.new()
	db._load_rarities(db._read_json(dir.path_join("rarities.json")))
	db.rules = FishingRules.from_dict(db._read_json(dir.path_join("rules.json")), db.errors)
	db._load_fish(db._read_json(dir.path_join("fish.json")))
	db._load_gear(db._read_json(dir.path_join("gear.json")))
	db._load_progression(db._read_json(dir.path_join("progression.json")))
	db._load_spots(db._read_json(dir.path_join("spots.json")))
	db._validate()
	return db


func rarity_index(rarity_id: String) -> int:
	return int(_rarity_index.get(rarity_id, -1))


func rarity_def(index: int) -> Dictionary:
	if index < 0 or index >= rarities.size():
		return {}
	return rarities[index]


func rarity_id(index: int) -> String:
	return str(rarity_def(index).get("id", ""))


func fish_index(id: String) -> int:
	return int(_fish_index.get(id, -1))


func fish_def(index: int) -> Dictionary:
	if index < 0 or index >= fish.size():
		return {}
	return fish[index]


func fish_by_id(id: String) -> Dictionary:
	return fish_def(fish_index(id))


func gear_item(id: String) -> Dictionary:
	return gear[int(_gear_index[id])] if _gear_index.has(id) else {}


## Bir kategorinin takımı, gear.json'daki sırayla (dükkân bu sırayı gösterir).
func gear_in(category: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for g in gear:
		if str(g["category"]) == category:
			out.append(g)
	return out


## Rütbe sayısı (en yüksek rütbe).
func max_rank() -> int:
	return rank_xp.size()


## Puanın denk geldiği rütbe (1..max_rank).
func rank_for_xp(xp: int) -> int:
	var rank := 1
	for i in range(1, rank_xp.size()):
		if xp >= rank_xp[i]:
			rank = i + 1
	return rank


## Rütbenin unvanı (strings.csv RANK_<id>).
func rank_title(rank: int) -> String:
	var id := ""
	for t in rank_titles:
		if rank >= int(t["from"]):
			id = str(t["id"])
	return id


func spot(id: String) -> Dictionary:
	return spots[int(_spot_index[id])] if _spot_index.has(id) else {}


## Atış noktasının göl şekli (önbellekli).
func lake(spot_id: String) -> LakeShape:
	if not _lakes.has(spot_id):
		_lakes[spot_id] = LakeShape.from_spot(spot(spot_id))
	return _lakes[spot_id]


## Balık id -> gövde rengi (ItemArt'ın yer tutucu madalyonları için).
func fish_colors() -> Dictionary:
	var out := {}
	for f in fish:
		out[f["id"]] = f["color"]
	return out


# --- Yükleme ------------------------------------------------------------------------

func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		errors.append("dosya yok: " + path)
		return {}
	var json := JSON.new()
	var err := json.parse(FileAccess.get_file_as_string(path))
	if err != OK:
		errors.append("%s: JSON hatası, satır %d: %s" % [path, json.get_error_line(), json.get_error_message()])
		return {}
	if typeof(json.data) != TYPE_DICTIONARY:
		errors.append(path + ": kök bir nesne olmalı")
		return {}
	return json.data


func _load_rarities(raw: Dictionary) -> void:
	for entry: Variant in raw.get("rarities", []):
		var d: Dictionary = entry
		var def := {
			"id": str(d.get("id", "")),
			"color": Color(str(d.get("color", "#ffffff"))),
			"shape": str(d.get("shape", "circle")),
			"shadow_fx": str(d.get("shadow_fx", "none")),
			"xp": int(d.get("xp", 0)),
			"love": int(d.get("love", 0)),
			"pity": int(d.get("pity", 0)),
		}
		_rarity_index[def["id"]] = rarities.size()
		rarities.append(def)


func _load_fish(raw: Dictionary) -> void:
	for entry: Variant in raw.get("fish", []):
		var d: Dictionary = entry
		var id := str(d.get("id", ""))
		var rarity_name := str(d.get("rarity", ""))
		if rarity_index(rarity_name) < 0:
			errors.append("fish.json: %s: bilinmeyen nadirlik: %s" % [id, rarity_name])
		var size := _vec2(d.get("size_cm"), Vector2(10, 20))
		var raw_fight: Dictionary = d.get("fight", {})
		var every := _vec2(raw_fight.get("burst_every"), Vector2(2, 3))
		var burst_len := _vec2(raw_fight.get("burst_len"), Vector2(0.5, 1))
		var fight := {
			"reel": float(raw_fight.get("reel", 1.0)),
			"pull": float(raw_fight.get("pull", 0.5)),
			"burst_pull": float(raw_fight.get("burst_pull", 1.1)),
			"burst_every": every,
			"burst_len": burst_len,
			"burst_every_steps": Vector2i(FishingRules.to_steps(every.x), FishingRules.to_steps(every.y)),
			"burst_len_steps": Vector2i(FishingRules.to_steps(burst_len.x), FishingRules.to_steps(burst_len.y)),
			"run": float(raw_fight.get("run", 1.0)),
		}
		var def := {
			"id": id,
			"rarity": maxi(0, rarity_index(rarity_name)),
			"value": int(d.get("value", 0)),
			"shadow_m": float(d.get("shadow_m", 0.5)),
			"size_cm": Vector2i(int(size.x), int(size.y)),
			"weight": int(d.get("weight", 0)),
			"color": Color(str(d.get("color", "#9fb3c8"))),
			"back": Color(str(d.get("back", "#4a5560"))),
			"accent": Color(str(d.get("accent", "#e2463a"))),
			"fight": fight,
		}
		_fish_index[id] = fish.size()
		fish.append(def)


func _load_gear(raw: Dictionary) -> void:
	var start: Dictionary = raw.get("start", {})
	for slot: Variant in start:
		gear_start[str(slot)] = str(start[slot])
	for entry: Variant in raw.get("gear", []):
		var d: Dictionary = entry
		var id := str(d.get("id", ""))
		var category := str(d.get("category", ""))
		var def := {
			"id": id,
			"category": category,
			"price": int(d.get("price", 0)),
			"rank": int(d.get("rank", 1)),
			"icon": str(d.get("icon", id)),
			"kind": str(d.get("kind", category)),
		}
		match category:
			"rod":
				def["technique"] = str(d.get("technique", "float"))
				def["range_m"] = float(d.get("range_m", 9.0))
				def["power"] = float(d.get("power", 0.0))
			"reel":
				def["reel_speed"] = float(d.get("reel_speed", 1.6))
				def["drag"] = float(d.get("drag", 0.0))
			"line":
				def["snap_after"] = float(d.get("snap_after", 0.8))
				def["stealth"] = float(d.get("stealth", 0.0))
			"hook":
				def["escape_extra"] = float(d.get("escape_extra", 0.0))
			"bobber":
				def["window_add"] = float(d.get("window_add", 0.0))
			"bait":
				def["pack"] = int(d.get("pack", 0))
				var attract := {}
				var raw_attract: Dictionary = d.get("attract", {})
				for fid: Variant in raw_attract:
					attract[str(fid)] = float(raw_attract[fid])
				def["attract"] = attract
			"extra":
				def["catch_m"] = float(d.get("catch_m", 0.0))
			"bucket":
				def["capacity"] = int(d.get("capacity", 6))
		_gear_index[id] = gear.size()
		gear.append(def)


func _load_progression(raw: Dictionary) -> void:
	for x: Variant in raw.get("xp", []):
		rank_xp.append(int(x))
	for entry: Variant in raw.get("titles", []):
		var d: Dictionary = entry
		rank_titles.append({ "from": int(d.get("from", 1)), "id": str(d.get("id", "")) })


func _load_spots(raw: Dictionary) -> void:
	main_spot = str(raw.get("main", ""))
	for entry: Variant in raw.get("spots", []):
		var d: Dictionary = entry
		var id := str(d.get("id", ""))
		var ellipses: Array[Dictionary] = []
		for e: Variant in d.get("ellipses", []):
			var ed: Dictionary = e
			ellipses.append({
				"center": _vec2(ed.get("center"), Vector2.ZERO),
				"radius": _vec2(ed.get("radius"), Vector2.ONE),
				"angle": deg_to_rad(float(ed.get("angle", 0.0))),
			})
		var dock_raw: Dictionary = d.get("dock", {})
		var dock_size := _vec2(dock_raw.get("size"), Vector2.ZERO)
		var dock_center := _vec2(dock_raw.get("center"), Vector2.ZERO)
		var ids := PackedStringArray()
		var weights := PackedInt32Array()
		var raw_fish: Dictionary = d.get("fish", {})
		for fid: Variant in raw_fish:
			ids.append(str(fid))
			weights.append(int(raw_fish[fid]))
		var first_raw: Dictionary = d.get("first_shadow", {})
		var def := {
			"id": id,
			"ellipses": ellipses,
			"dock": Rect2(dock_center - dock_size * 0.5, dock_size),
			"start": _vec2(d.get("start"), Vector2.ZERO),
			"max_shadows": int(d.get("max_shadows", 4)),
			"fish_ids": ids,
			"fish_weights": weights,
			"first_fish": str(d.get("first_fish", ids[0] if ids.size() > 0 else "")),
			"first_shadow": {
				"pos": _vec2(first_raw.get("pos"), Vector2.ZERO),
				"heading": _vec2(first_raw.get("heading"), Vector2(-1, 0)).normalized(),
			},
			"max_depth": float(d.get("max_depth", 3.5)),
			"shelf_m": float(d.get("shelf_m", 4.0)),
		}
		_spot_index[id] = spots.size()
		spots.append(def)
	if main_spot.is_empty() and not spots.is_empty():
		main_spot = str(spots[0]["id"])


# --- Doğrulama ----------------------------------------------------------------------

func _validate() -> void:
	if rarities.is_empty():
		errors.append("rarities.json: nadirlik yok")
	if fish.is_empty():
		errors.append("fish.json: balık yok")
	if spots.is_empty():
		errors.append("spots.json: atış noktası yok")
	_check_unique("rarities", rarities)
	_check_unique("fish", fish)
	_check_unique("gear", gear)
	_check_unique("spots", spots)
	for r in rarities:
		if not str(r["shape"]) in RARITY_SHAPES or not str(r["shadow_fx"]) in SHADOW_FX:
			errors.append("rarities.json: %s: shape ya da shadow_fx bilinmiyor" % r["id"])
		if int(r["xp"]) <= 0 or int(r["love"]) <= 0 or int(r["pity"]) < 0:
			errors.append("rarities.json: %s: xp ve love pozitif, pity sıfır ya da pozitif olmalı" % r["id"])
	for f in fish:
		_validate_fish(f)
	_validate_gear()
	_validate_progression()
	if spot(main_spot).is_empty():
		errors.append("spots.json: main bilinmiyor: " + main_spot)
	for s in spots:
		_validate_spot(s)


func _validate_gear() -> void:
	if gear.is_empty():
		errors.append("gear.json: takım yok")
		return
	for slot: String in GEAR_SLOTS + ["bucket"]:
		var item := gear_item(str(gear_start.get(slot, "")))
		if item.is_empty() or str(item["category"]) != slot or int(item["price"]) != 0:
			errors.append("gear.json: start.%s ücretsiz ve o kategoriden olmalı" % slot)
	var strongest_drag := 0.0
	for g in gear:
		var id := str(g["id"])
		var category := str(g["category"])
		if not category in GEAR_CATEGORIES:
			errors.append("gear.json: %s: bilinmeyen kategori: %s" % [id, category])
			continue
		if int(g["price"]) < 0 or int(g["rank"]) < 1 or int(g["rank"]) > maxi(1, rank_xp.size()):
			errors.append("gear.json: %s: fiyat ya da rütbe geçersiz" % id)
		match category:
			"rod":
				if not str(g["technique"]) in TECHNIQUES or float(g["range_m"]) < 3.0:
					errors.append("gear.json: %s: teknik ya da menzil geçersiz" % id)
				if float(g["power"]) < 0.0 or float(g["power"]) > 0.3:
					errors.append("gear.json: %s: power 0–0,3 olmalı" % id)
			"reel":
				if float(g["reel_speed"]) <= 0.0 or float(g["drag"]) < 0.0 or float(g["drag"]) > 0.25:
					errors.append("gear.json: %s: sarma hızı ya da fren geçersiz" % id)
				strongest_drag = maxf(strongest_drag, float(g["drag"]))
			"line":
				if float(g["snap_after"]) <= 0.0 or float(g["stealth"]) < 0.0 or float(g["stealth"]) > 0.5:
					errors.append("gear.json: %s: dayanım ya da görünmezlik geçersiz" % id)
			"hook":
				if float(g["escape_extra"]) < 0.0:
					errors.append("gear.json: %s: escape_extra eksi olamaz" % id)
			"bobber":
				if float(g["window_add"]) < 0.0:
					errors.append("gear.json: %s: window_add eksi olamaz" % id)
			"bait":
				var attract: Dictionary = g["attract"]
				for fid: Variant in attract:
					if fish_index(str(fid)) < 0 or float(attract[fid]) <= 0.0:
						errors.append("gear.json: %s: bilinmeyen balık ya da geçersiz çarpan: %s" % [id, fid])
				if int(g["pack"]) < 0 or (int(g["pack"]) == 0 and int(g["price"]) > 0):
					errors.append("gear.json: %s: satılan yemin paketi olmalı" % id)
			"extra":
				if float(g["catch_m"]) < 0.0:
					errors.append("gear.json: %s: catch_m eksi olamaz" % id)
			"bucket":
				if int(g["capacity"]) < 1:
					errors.append("gear.json: %s: kapasite en az 1" % id)
	# En güçlü frende bile patlama sınırın belirgin üstünde kalmalı: bırakmayı bilmek hep işe yarar.
	for f in fish:
		var burst := float((f["fight"] as Dictionary)["burst_pull"])
		if burst * (1.0 - strongest_drag) < rules.limit + 0.1:
			errors.append("gear.json: en güçlü fren %s'in patlamasını sınıra çok yaklaştırıyor" % f["id"])


func _validate_progression() -> void:
	if rank_xp.size() < 2 or rank_xp[0] != 0:
		errors.append("progression.json: xp listesi 0 ile başlamalı ve en az 2 rütbe olmalı")
	for i in range(1, rank_xp.size()):
		if rank_xp[i] <= rank_xp[i - 1]:
			errors.append("progression.json: xp eşikleri artmalı (%d. rütbe)" % (i + 1))
	if rank_titles.is_empty() or int(rank_titles[0]["from"]) != 1:
		errors.append("progression.json: ilk unvan 1. rütbeden başlamalı")


func _validate_fish(f: Dictionary) -> void:
	var id := str(f["id"])
	# Masalsı balık satılmaz (değeri 0); ötekiler pozitif.
	var mythic := rarity_id(int(f["rarity"])) == "mythic"
	if int(f["value"]) < 0 or (int(f["value"]) == 0) != mythic:
		errors.append("fish.json: %s: value pozitif olmalı (yalnızca Masalsı balıkta 0)" % id)
	var size: Vector2i = f["size_cm"]
	if size.x <= 0 or size.y < size.x:
		errors.append("fish.json: %s: boy aralığı geçersiz" % id)
	if float(f["shadow_m"]) <= 0.0:
		errors.append("fish.json: %s: gölge uzunluğu geçersiz" % id)
	var fight: Dictionary = f["fight"]
	# Sakin balıkta basılı tutmak kırmızıya hiç çıkmamalı; patlamada çıkmalı.
	if float(fight["pull"]) >= rules.limit - 0.05 or float(fight["pull"]) <= 0.0:
		errors.append("fish.json: %s: pull sınırın (%.2f) en az 0,05 altında olmalı" % [id, rules.limit])
	if float(fight["burst_pull"]) <= rules.limit:
		errors.append("fish.json: %s: burst_pull sınırın üstünde olmalı" % id)
	var every: Vector2i = fight["burst_every_steps"]
	var burst_len: Vector2i = fight["burst_len_steps"]
	if every.x <= rules.warn_steps or every.y < every.x:
		errors.append("fish.json: %s: burst_every uyarıdan uzun olmalı" % id)
	if burst_len.x <= 0 or burst_len.y < burst_len.x:
		errors.append("fish.json: %s: burst_len geçersiz" % id)
	if float(fight["reel"]) <= 0.0 or float(fight["run"]) < 0.0:
		errors.append("fish.json: %s: reel ya da run geçersiz" % id)


func _validate_spot(s: Dictionary) -> void:
	var id := str(s["id"])
	var ellipses: Array[Dictionary] = s["ellipses"]
	if ellipses.is_empty():
		errors.append("spots.json: %s: elips yok" % id)
		return
	for e in ellipses:
		var r: Vector2 = e["radius"]
		if r.x <= 0.5 or r.y <= 0.5:
			errors.append("spots.json: %s: elips yarıçapı çok küçük" % id)
			return
	var ids: PackedStringArray = s["fish_ids"]
	var weights: PackedInt32Array = s["fish_weights"]
	if ids.is_empty():
		errors.append("spots.json: %s: balık listesi boş" % id)
	for i in ids.size():
		if fish_index(ids[i]) < 0:
			errors.append("spots.json: %s: bilinmeyen balık: %s" % [id, ids[i]])
		if weights[i] <= 0:
			errors.append("spots.json: %s: %s ağırlığı pozitif olmalı" % [id, ids[i]])
	if fish_index(str(s["first_fish"])) < 0:
		errors.append("spots.json: %s: ilk av balığı bilinmiyor" % id)
	if int(s["max_shadows"]) < 1:
		errors.append("spots.json: %s: max_shadows en az 1" % id)
	var shape := lake(id)
	var start: Vector2 = s["start"]
	if not shape.is_walkable(start):
		errors.append("spots.json: %s: başlangıç noktası suyun içinde" % id)
	var first: Dictionary = s["first_shadow"]
	if not shape.is_deep(first["pos"], rules.min_depth):
		errors.append("spots.json: %s: ilk gölge derin suda değil" % id)


func _check_unique(label: String, list: Array[Dictionary]) -> void:
	var seen := {}
	for d in list:
		var id := str(d.get("id", ""))
		if id.is_empty():
			errors.append("%s: kimliği boş bir kayıt var" % label)
		elif seen.has(id):
			errors.append("%s: kimlik iki kez var: %s" % [label, id])
		seen[id] = true


## Oran: ppm'e çevrilmiş tamsayı (JSON sayıları float gelir).
static func _ppm(value: Variant) -> int:
	return int(round(float(value) * PPM))


static func _vec2(raw: Variant, fallback: Vector2) -> Vector2:
	if typeof(raw) != TYPE_ARRAY or (raw as Array).size() != 2:
		return fallback
	var a: Array = raw
	return Vector2(float(a[0]), float(a[1]))
