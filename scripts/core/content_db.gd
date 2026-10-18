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
## Balıklar: id, rarity (sıra), value (para), release_only (koruma altında: yalnızca bırakılır),
## shadow_m, size_cm (Vector2i), weight, color, back, accent, fight { reel, pull, burst_pull,
## burst_every, burst_len (sn, Vector2), *_steps (Vector2i), run, heavy (iri tür) },
## affinity { teknik: çarpan } (türün teknik yatkınlığı; yazılmayan teknikte 0, alan hiç yoksa
## yalnızca şamandıra 1).
var fish: Array[Dictionary] = []
## Takım (gear.json): id, category, price, rank, icon, kind ve kategoriye göre değerler
## (rod: technique, range_m, power, carry; reel: reel_speed, drag; line: snap_after, stealth, carry;
## hook: escape_extra; bobber: window_add; bait: attract {tür: çarpan}, pack; extra: catch_m;
## bucket: capacity).
var gear: Array[Dictionary] = []
## Başlangıç takımı: yuva (rod, reel, line, hook, bobber, bait, bucket ...) -> takım kimliği.
var gear_start: Dictionary = {}
## Kuşanılan yuvalar (gear.json "slots"): her teknikte ortak olanlar (makara, misina) ve tekniğin
## kendi yuvaları (teknik -> yuvalar; hepsinde kamış var).
var shared_slots: Array[String] = []
var technique_slots: Dictionary = {}
## Rütbe eşikleri (her rütbeye geçmek için toplam puan; [0] = 1. rütbe = 0) ve unvanlar
## [{from, id}].
var rank_xp: PackedInt32Array = []
var rank_titles: Array[Dictionary] = []
## Atış noktaları (göller): id, basins [{center, radius, angle (radyan), zone, max_depth, shelf_m}],
## zones [_zone_def], dock (Rect2), start, max_shadows, fish_ids ve fish_weights (gölün bütün
## türleri; bölgelerin toplamı), first_fish, first_shadow {pos, heading}. Eski şemadaki göl
## (ellipses + tek derinlik + fish) tek bölgeli ("main") sayılır.
var spots: Array[Dictionary] = []
## Oyunun açıldığı atış noktası (spots.json "main").
var main_spot: String = ""
var rules: FishingRules
var errors: PackedStringArray = []

## Takım kategorileri ve kuşanılan yuvalar (bucket, extra ve boat kuşanılmaz: sahip olunan en iyisi
## ya da hepsi işler; sandal derin ortayı açar, Zones.BOAT). Yuvaların sırası takımın okunma
## sırasıdır (şamandırada v0.3'teki gibi kamış, makara, misina, iğne, şamandıra, yem); yeni yuvalar
## sona eklenir: lure (yapay yem, spin), rig (kurşun ya da yem sepeti, dip), fly (sinek).
const GEAR_CATEGORIES: Array[String] = ["rod", "reel", "line", "hook", "bobber", "bait", "lure", "rig", "fly",
		"extra", "bucket", "boat"]
const GEAR_SLOTS: Array[String] = ["rod", "reel", "line", "hook", "bobber", "bait", "lure", "rig", "fly"]
const TECHNIQUES: Array[String] = ["float", "spin", "bottom", "fly"]
## Bölgede yazılmayan teknikler (sinek yalnızca akıntılı bölgede, açıkça yazılır).
const ZONE_TECHNIQUES: Array[String] = ["float", "spin", "bottom"]
const RARITY_SHAPES: Array[String] = ["circle", "triangle", "diamond", "star", "sparkle", "medallion"]
const SHADOW_FX: Array[String] = ["none", "glint", "shimmer", "trail", "guardian"]

var _rarity_index: Dictionary = {}
var _fish_index: Dictionary = {}
var _gear_index: Dictionary = {}
var _spot_index: Dictionary = {}
## Atış noktası id -> LakeShape (bir kez kurulur).
var _lakes: Dictionary = {}
var _all_lakes: bool = true


## all_lakes: bütün göllerin şekli kurulup denetlensin (testler). Oyun yalnızca açıldığı gölü
## kurar (her göl bir kıyı ızgarası demek; açılışı yavaşlatmasın).
static func load_default(all_lakes: bool = true) -> ContentDB:
	return load_from(DATA_DIR, all_lakes)


static func load_from(dir: String, all_lakes: bool = true) -> ContentDB:
	var db := ContentDB.new()
	db._all_lakes = all_lakes
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


## Bir tekniğin kamışları (gear.json sırasıyla).
func rods_of(technique: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for g in gear_in("rod"):
		if str(g["technique"]) == technique:
			out.append(g)
	return out


## Teknik oyunda var mı (kamışı var mı)?
func has_technique(technique: String) -> bool:
	return not rods_of(technique).is_empty()


## Tekniğin açıldığı rütbe: en erken açılan kamışınınki (kamışı yoksa 0).
func technique_rank(technique: String) -> int:
	var rank := 0
	for g in rods_of(technique):
		rank = int(g["rank"]) if rank == 0 else mini(rank, int(g["rank"]))
	return rank


## Bu teknikte kuşanılan yuvalar (GEAR_SLOTS sırasıyla: ortaklar ve tekniğinkiler). Bilinmeyen
## teknikte şamandıranınkiler.
func slots_for(technique: String) -> Array[String]:
	var own: Array = technique_slots.get(technique, technique_slots.get("float", []))
	var out: Array[String] = []
	for slot in GEAR_SLOTS:
		if slot in shared_slots or slot in own:
			out.append(slot)
	return out


## Yuva her teknikte ortak mı (makara, misina)?
func is_shared(slot: String) -> bool:
	return slot in shared_slots


## Teknik bu yuvayı kullanır mı?
func uses_slot(technique: String, slot: String) -> bool:
	return slot in slots_for(technique)


## Yalnızca bir tekniğin kullandığı yuvanın tekniği (iğne ve şamandıra → şamandıra, yapay yem →
## spin, kurşun → dip, sinek → sinek); ortak ya da birden çok teknikte olan yuvada (kamış, yem) "".
func slot_technique(slot: String) -> String:
	var found := ""
	for t: String in TECHNIQUES:
		if slot in (technique_slots.get(t, []) as Array):
			if not found.is_empty():
				return ""
			found = t
	return found


## Türün bu teknikle gelme çarpanı (yatkınlık; yazılmamışsa 0).
func affinity(fish_id: String, technique: String) -> float:
	var f := fish_by_id(fish_id)
	if f.is_empty():
		return 0.0
	return float((f["affinity"] as Dictionary).get(technique, 0.0))


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


## Atış noktasının bölgeleri (sıra = LakeShape.zone_grid'deki değer).
func zones_of(spot_id: String) -> Array[Dictionary]:
	var s := spot(spot_id)
	if s.is_empty():
		return []
	return s["zones"]


## Atış noktasının bir bölgesi (yoksa boş).
func zone(spot_id: String, zone_id: String) -> Dictionary:
	for z in zones_of(spot_id):
		if str(z["id"]) == zone_id:
			return z
	return {}


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
			"heavy": bool(raw_fight.get("heavy", false)),
		}
		var affinity := {}
		var raw_affinity: Variant = d.get("affinity", { "float": 1.0 })
		if typeof(raw_affinity) == TYPE_DICTIONARY:
			for t: Variant in raw_affinity:
				affinity[str(t)] = float((raw_affinity as Dictionary)[t])
		var def := {
			"id": id,
			"rarity": maxi(0, rarity_index(rarity_name)),
			"value": int(d.get("value", 0)),
			"release_only": bool(d.get("release_only", false)),
			"shadow_m": float(d.get("shadow_m", 0.5)),
			"size_cm": Vector2i(int(size.x), int(size.y)),
			"weight": int(d.get("weight", 0)),
			"color": Color(str(d.get("color", "#9fb3c8"))),
			"back": Color(str(d.get("back", "#4a5560"))),
			"accent": Color(str(d.get("accent", "#e2463a"))),
			"fight": fight,
			"affinity": affinity,
		}
		_fish_index[id] = fish.size()
		fish.append(def)


func _load_gear(raw: Dictionary) -> void:
	var start: Dictionary = raw.get("start", {})
	for slot: Variant in start:
		gear_start[str(slot)] = str(start[slot])
	# Yuvalar: verilmezse v0.3'teki gibi (ortak makara ve misina, şamandıranın kamış, iğne,
	# şamandıra ve yemi).
	var slots: Dictionary = raw.get("slots", { "shared": ["reel", "line"], "float": ["rod", "hook", "bobber", "bait"] })
	for slot: Variant in slots.get("shared", []):
		shared_slots.append(str(slot))
	for t: Variant in slots:
		if str(t) == "shared" or typeof(slots[t]) != TYPE_ARRAY:
			continue
		var own: Array[String] = []
		for slot: Variant in slots[t]:
			own.append(str(slot))
		technique_slots[str(t)] = own
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
				def["carry"] = int(d.get("carry", rules.carry))
			"reel":
				def["reel_speed"] = float(d.get("reel_speed", 1.6))
				def["drag"] = float(d.get("drag", 0.0))
			"line":
				def["snap_after"] = float(d.get("snap_after", 0.8))
				def["stealth"] = float(d.get("stealth", 0.0))
				def["carry"] = int(d.get("carry", rules.carry))
			"hook":
				def["escape_extra"] = float(d.get("escape_extra", 0.0))
			"bobber":
				def["window_add"] = float(d.get("window_add", 0.0))
			"bait":
				def["pack"] = int(d.get("pack", 0))
				def["attract"] = _attract(d)
			"lure", "fly":
				def["attract"] = _attract(d)
			"rig":
				def["range_add"] = float(d.get("range_add", 0.0))
				def["pull"] = float(d.get("pull", 0.0))
			"extra":
				def["catch_m"] = float(d.get("catch_m", 0.0))
			"bucket":
				def["capacity"] = int(d.get("capacity", 6))
		_gear_index[id] = gear.size()
		gear.append(def)


## Yemin (yapay yemin, sineğin) tür çekimi: tür kimliği -> çarpan.
static func _attract(d: Dictionary) -> Dictionary:
	var attract := {}
	var raw_attract: Variant = d.get("attract", {})
	if typeof(raw_attract) == TYPE_DICTIONARY:
		for fid: Variant in raw_attract:
			attract[str(fid)] = float((raw_attract as Dictionary)[fid])
	return attract


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
		var basins: Array[Dictionary] = []
		var zones: Array[Dictionary] = []
		if d.has("basins"):
			for z: Variant in d.get("zones", []):
				zones.append(_zone_def(z))
			for b: Variant in d.get("basins", []):
				var bd: Dictionary = b
				basins.append(_basin_def(bd.get("ellipse", {}), str(bd.get("zone", "")),
						float(bd.get("max_depth", 3.5)), float(bd.get("shelf_m", 4.0))))
		else:
			# Eski şema (home_lake): elipsler tek profilli havzalar, göl tek bölge ("main").
			zones.append(_zone_def({ "id": "main", "fish": d.get("fish", {}) }))
			for e: Variant in d.get("ellipses", []):
				basins.append(_basin_def(e, "main", float(d.get("max_depth", 3.5)), float(d.get("shelf_m", 4.0))))
		var dock_raw: Dictionary = d.get("dock", {})
		var dock_size := _vec2(dock_raw.get("size"), Vector2.ZERO)
		var dock_center := _vec2(dock_raw.get("center"), Vector2.ZERO)
		# Gölün bütün türleri (defter ve katalog), bölgelerdeki ilk görülüş sırasıyla.
		var ids := PackedStringArray()
		var weights := PackedInt32Array()
		for z in zones:
			var zone_ids: PackedStringArray = z["fish_ids"]
			var zone_weights: PackedInt32Array = z["fish_weights"]
			for i in zone_ids.size():
				var k := ids.find(zone_ids[i])
				if k < 0:
					ids.append(zone_ids[i])
					weights.append(zone_weights[i])
				else:
					weights[k] += zone_weights[i]
		var first_raw: Dictionary = d.get("first_shadow", {})
		# Yürünebilen dünya (yoksa sınırsız): kutu [[x0, z0], [x1, z1]] ve suya en çok band_m metre.
		var world_raw: Dictionary = d.get("world", {})
		var corners: Array = world_raw.get("rect", [])
		var world_rect := Rect2()
		if corners.size() == 2:
			var a := _vec2(corners[0], Vector2.ZERO)
			var b := _vec2(corners[1], Vector2.ZERO)
			world_rect = Rect2(a, Vector2.ZERO).expand(b)
		var def := {
			"id": id,
			"basins": basins,
			"zones": zones,
			"world_rect": world_rect,
			"world_band": float(world_raw.get("band_m", INF)),
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
		}
		_spot_index[id] = spots.size()
		spots.append(def)
	if main_spot.is_empty() and not spots.is_empty():
		main_spot = str(spots[0]["id"])


func _basin_def(raw: Variant, zone: String, deepest: float, shelf_m: float) -> Dictionary:
	var e: Dictionary = raw if typeof(raw) == TYPE_DICTIONARY else {}
	return {
		"center": _vec2(e.get("center"), Vector2.ZERO),
		"radius": _vec2(e.get("radius"), Vector2.ONE),
		"angle": deg_to_rad(float(e.get("angle", 0.0))),
		"zone": zone,
		"max_depth": deepest,
		"shelf_m": shelf_m,
	}


## Bölge: id, rank (açıldığı rütbe), boat (yalnızca sandalla; boat_from: kıyıdan bu kadar metre
## içeride başlar), min_depth (gölgelerin girdiği en sığ su), fish_ids ve fish_weights (CatchOdds
## bölge sözlüğünü atış noktası gibi okur), stands (hızlı geçişte balıkçının durduğu yerler),
## gates (bölge kilitliyken kıyı yolunu kesen çitler: iki uç), buoys (sandalın gittiği
## şamandıralar), current (akıntı yönü; görsel ve sinek), map (haritada rozetin yeri; yoksa
## Dice.NO_POINT: bölgenin suyunun ortası), techniques (bölgede avlanılan teknikler; yazılmazsa
## ZONE_TECHNIQUES, sinek yalnızca akıntılı bölgede açıkça), snag_s (otlu ya da kayalık bölgede
## bu kadar sn bekleyen yapay yem takılır; 0 = takılmaz).
func _zone_def(raw: Variant) -> Dictionary:
	var z: Dictionary = raw if typeof(raw) == TYPE_DICTIONARY else {}
	var techniques := PackedStringArray()
	for t: Variant in z.get("techniques", ZONE_TECHNIQUES):
		techniques.append(str(t))
	var ids := PackedStringArray()
	var weights := PackedInt32Array()
	var raw_fish: Dictionary = z.get("fish", {})
	for fid: Variant in raw_fish:
		ids.append(str(fid))
		weights.append(int(raw_fish[fid]))
	var stands: Array[Vector2] = []
	for p: Variant in z.get("stands", []):
		stands.append(_vec2(p, Vector2.ZERO))
	var buoys: Array[Vector2] = []
	for p: Variant in z.get("buoys", []):
		buoys.append(_vec2(p, Vector2.ZERO))
	var gates: Array[PackedVector2Array] = []
	for g: Variant in z.get("gates", []):
		var ends := PackedVector2Array()
		if typeof(g) == TYPE_ARRAY:
			for p: Variant in g:
				ends.append(_vec2(p, Vector2.ZERO))
		gates.append(ends)
	return {
		"id": str(z.get("id", "")),
		"rank": int(z.get("rank", 1)),
		"boat": bool(z.get("boat", false)),
		"boat_from": float(z.get("boat_from", 5.0)),
		"min_depth": float(z.get("min_depth", rules.min_depth if rules != null else 0.8)),
		"fish_ids": ids,
		"fish_weights": weights,
		"stands": stands,
		"gates": gates,
		"buoys": buoys,
		"current": _vec2(z.get("current"), Vector2.ZERO),
		"map": _vec2(z.get("map"), Dice.NO_POINT),
		"techniques": techniques,
		"snag_s": float(z.get("snag_s", 0.0)),
	}


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
		_validate_spot(s, _all_lakes or str(s["id"]) == main_spot)


func _validate_gear() -> void:
	if gear.is_empty():
		errors.append("gear.json: takım yok")
		return
	_validate_slots()
	# Her yuvanın bedava başlangıç eşyası var: şamandıranın bütün yuvaları ve kova; kamışı olan
	# öteki tekniklerin kamış dışındaki yuvaları (o tekniğin kamışı Nine'den alınır).
	var needed: Array[String] = []
	for t: String in TECHNIQUES:
		if t != "float" and not has_technique(t):
			continue
		for slot in slots_for(t):
			if (t == "float" or slot != "rod") and not slot in needed:
				needed.append(slot)
	needed.append("bucket")
	for slot in needed:
		var item := gear_item(str(gear_start.get(slot, "")))
		if item.is_empty() or str(item["category"]) != slot or int(item["price"]) != 0:
			errors.append("gear.json: start.%s ücretsiz ve o kategoriden olmalı" % slot)
	if str(gear_item(str(gear_start.get("rod", ""))).get("technique", "")) != "float":
		errors.append("gear.json: start.rod şamandıra kamışı olmalı")
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
				if int(g["carry"]) < 1 or int(g["carry"]) > 5:
					errors.append("gear.json: %s: carry (taşıma) 1–5 yıldız olmalı" % id)
			"reel":
				if float(g["reel_speed"]) <= 0.0 or float(g["drag"]) < 0.0 or float(g["drag"]) > 0.25:
					errors.append("gear.json: %s: sarma hızı ya da fren geçersiz" % id)
				strongest_drag = maxf(strongest_drag, float(g["drag"]))
			"line":
				if float(g["snap_after"]) <= 0.0 or float(g["stealth"]) < 0.0 or float(g["stealth"]) > 0.5:
					errors.append("gear.json: %s: dayanım ya da görünmezlik geçersiz" % id)
				if int(g["carry"]) < 1 or int(g["carry"]) > 5:
					errors.append("gear.json: %s: carry (taşıma) 1–5 yıldız olmalı" % id)
			"hook":
				if float(g["escape_extra"]) < 0.0:
					errors.append("gear.json: %s: escape_extra eksi olamaz" % id)
			"bobber":
				if float(g["window_add"]) < 0.0:
					errors.append("gear.json: %s: window_add eksi olamaz" % id)
			"bait":
				_validate_attract(id, g["attract"])
				if int(g["pack"]) < 0 or (int(g["pack"]) == 0 and int(g["price"]) > 0):
					errors.append("gear.json: %s: satılan yemin paketi olmalı" % id)
			"lure", "fly":
				_validate_attract(id, g["attract"])
			"rig":
				if float(g["pull"]) < 0.0 or float(g["pull"]) > 1.0 or absf(float(g["range_add"])) > 5.0:
					errors.append("gear.json: %s: pull 0–1, range_add en çok ±5 m olmalı" % id)
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


## Yuvalar: ortaklar kamış olamaz ve tekniklerin yuvalarıyla çakışmaz; her tekniğin kamışı var;
## her yuva bir yerde kullanılır.
func _validate_slots() -> void:
	var listed := {}
	for slot in shared_slots:
		if not slot in GEAR_SLOTS or slot == "rod":
			errors.append("gear.json: slots.shared: bilinmeyen ya da ortak olamayan yuva: %s" % slot)
		listed[slot] = true
	for t: Variant in technique_slots:
		if not str(t) in TECHNIQUES:
			errors.append("gear.json: slots: bilinmeyen teknik: %s" % t)
	for t: String in TECHNIQUES:
		var own: Array = technique_slots.get(t, [])
		if not "rod" in own:
			errors.append("gear.json: slots.%s: kamış yuvası yok" % t)
		for slot: Variant in own:
			if not str(slot) in GEAR_SLOTS or str(slot) in shared_slots:
				errors.append("gear.json: slots.%s: bilinmeyen ya da ortak yuva: %s" % [t, slot])
			listed[str(slot)] = true
	for slot in GEAR_SLOTS:
		if not listed.has(slot):
			errors.append("gear.json: slots: %s yuvası hiçbir teknikte yok" % slot)


## Yemin, yapay yemin ya da sineğin çektiği türler bilinmeli, çarpan pozitif olmalı.
func _validate_attract(id: String, attract: Dictionary) -> void:
	for fid: Variant in attract:
		if fish_index(str(fid)) < 0 or float(attract[fid]) <= 0.0:
			errors.append("gear.json: %s: bilinmeyen balık ya da geçersiz çarpan: %s" % [id, fid])


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
	# Masalsı ve koruma altındaki (yalnızca bırakılan) balık satılmaz: değeri 0; ötekiler pozitif.
	var unsold := rarity_id(int(f["rarity"])) == "mythic" or bool(f["release_only"])
	if int(f["value"]) < 0 or (int(f["value"]) == 0) != unsold:
		errors.append("fish.json: %s: value pozitif olmalı (yalnızca Masalsı ve yalnızca bırakılan balıkta 0)" % id)
	var size: Vector2i = f["size_cm"]
	if size.x <= 0 or size.y < size.x:
		errors.append("fish.json: %s: boy aralığı geçersiz" % id)
	if float(f["shadow_m"]) <= 0.0:
		errors.append("fish.json: %s: gölge uzunluğu geçersiz" % id)
	var fight: Dictionary = f["fight"]
	# Sakin balıkta basılı tutmak kırmızıya hiç çıkmamalı (iri türün en irisinde de, takım taşıyorsa);
	# patlamada çıkmalı.
	var calm := float(fight["pull"]) + (rules.size_pull if bool(fight["heavy"]) else 0.0)
	if calm >= rules.limit - 0.05 or float(fight["pull"]) <= 0.0:
		errors.append("fish.json: %s: pull (iri türde + size_pull) sınırın (%.2f) en az 0,05 altında olmalı" % [id, rules.limit])
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
	var affinity: Dictionary = f["affinity"]
	var any := false
	for t: Variant in affinity:
		if not str(t) in TECHNIQUES or float(affinity[t]) < 0.0:
			errors.append("fish.json: %s: bilinmeyen teknik ya da eksi yatkınlık: %s" % [id, t])
		elif float(affinity[t]) > 0.0:
			any = true
	if not any:
		errors.append("fish.json: %s: hiçbir teknikle gelmiyor (affinity)" % id)


## geometry: göl şekli kurulup başlangıç, atış noktaları, şamandıralar ve bölgeler de denetlensin.
func _validate_spot(s: Dictionary, geometry: bool = true) -> void:
	var id := str(s["id"])
	var basins: Array[Dictionary] = s["basins"]
	var zones: Array[Dictionary] = s["zones"]
	if basins.is_empty() or zones.is_empty():
		errors.append("spots.json: %s: havza ya da bölge yok" % id)
		return
	var known := {}
	for z in zones:
		_validate_zone(id, z, known)
	for b in basins:
		var r: Vector2 = b["radius"]
		if r.x <= 0.5 or r.y <= 0.5:
			errors.append("spots.json: %s: elips yarıçapı çok küçük" % id)
			return
		if not known.has(str(b["zone"])):
			errors.append("spots.json: %s: havzanın bölgesi bilinmiyor: %s" % [id, b["zone"]])
	if fish_index(str(s["first_fish"])) < 0:
		errors.append("spots.json: %s: ilk av balığı bilinmiyor" % id)
	if int(s["max_shadows"]) < 1:
		errors.append("spots.json: %s: max_shadows en az 1" % id)
	if not geometry:
		return
	var shape := lake(id)
	var start: Vector2 = s["start"]
	if not shape.is_walkable(start):
		errors.append("spots.json: %s: başlangıç noktası suyun içinde" % id)
	if not _open_at_start(zones, shape.zone_at(start)):
		errors.append("spots.json: %s: başlangıç bölgesi baştan açık olmalı" % id)
	var first: Dictionary = s["first_shadow"]
	var first_zone := shape.zone_at(first["pos"])
	if not _open_at_start(zones, first_zone) or not shape.is_deep(first["pos"], float(zones[first_zone]["min_depth"])):
		errors.append("spots.json: %s: ilk gölge baştan açık bir bölgenin derin suyunda olmalı" % id)
	for k in zones.size():
		var z := zones[k]
		if shape.zone_bounds[k].size.x <= 0.0:
			errors.append("spots.json: %s: %s bölgesinin suyu yok" % [id, z["id"]])
		for p: Vector2 in z["stands"]:
			if not shape.is_walkable(p) or shape.zone_at(p) != k or shape.shore_distance(p) < -3.0:
				errors.append("spots.json: %s: %s atış noktası kendi bölgesinin suyuna bakmalı: %s" % [id, z["id"], p])
		for p: Vector2 in z["buoys"]:
			if not shape.is_water(p) or shape.zone_at(p) != k:
				errors.append("spots.json: %s: %s şamandırası kendi bölgesinin suyunda olmalı: %s" % [id, z["id"], p])
	# Bölgesiz su yalnızca sandal havzasının öteki havzalardan uzak kıyı şeridinde olabilir (kıyıdan
	# en çok boat_from metre; LakeShape.RIM_REACH). Daha içerideki bölgesiz su, bir havzanın
	# bölgesinin tanımsız olduğunu gösterir.
	var rim := 0.0
	for z in zones:
		if bool(z["boat"]):
			rim = maxf(rim, float(z["boat_from"]))
	var orphans := 0
	for i in shape.shore.size():
		if shape.shore[i] > rim and shape.zone_grid[i] == LakeShape.NO_ZONE:
			orphans += 1
	if orphans > 0:
		errors.append("spots.json: %s: %d su hücresinin bölgesi yok" % [id, orphans])


func _validate_zone(spot_id: String, z: Dictionary, known: Dictionary) -> void:
	var id := str(z["id"])
	if id.is_empty() or known.has(id):
		errors.append("spots.json: %s: bölge kimliği boş ya da iki kez: %s" % [spot_id, id])
	known[id] = true
	if int(z["rank"]) < 1 or int(z["rank"]) > maxi(1, rank_xp.size()):
		errors.append("spots.json: %s: %s bölgesinin rütbesi geçersiz" % [spot_id, id])
	if float(z["min_depth"]) <= 0.0:
		errors.append("spots.json: %s: %s bölgesinin min_depth'i pozitif olmalı" % [spot_id, id])
	var ids: PackedStringArray = z["fish_ids"]
	var weights: PackedInt32Array = z["fish_weights"]
	if ids.is_empty():
		errors.append("spots.json: %s: %s bölgesinin balık listesi boş" % [spot_id, id])
	for i in ids.size():
		if fish_index(ids[i]) < 0:
			errors.append("spots.json: %s: %s: bilinmeyen balık: %s" % [spot_id, id, ids[i]])
		if weights[i] <= 0:
			errors.append("spots.json: %s: %s: %s ağırlığı pozitif olmalı" % [spot_id, id, ids[i]])
	var stands: Array[Vector2] = z["stands"]
	var buoys: Array[Vector2] = z["buoys"]
	if bool(z["boat"]):
		if buoys.is_empty() or float(z["boat_from"]) < 1.0:
			errors.append("spots.json: %s: %s sandal bölgesinin şamandırası ve kıyı payı (boat_from ≥ 1) olmalı" % [spot_id, id])
	elif stands.is_empty() and id != "main":
		errors.append("spots.json: %s: %s bölgesinin atış noktası (stands) yok" % [spot_id, id])
	for g: PackedVector2Array in z["gates"]:
		if g.size() != 2:
			errors.append("spots.json: %s: %s: çitin iki ucu olmalı" % [spot_id, id])
	# Her bölgede şamandıra var; sinek yalnızca akıntıda; bölgede avlanılan her teknikle gelen bir
	# tür olmalı (yoksa gölge doğmaz).
	var techniques: PackedStringArray = z["techniques"]
	if not "float" in techniques:
		errors.append("spots.json: %s: %s bölgesinde şamandıra olmalı" % [spot_id, id])
	for t in techniques:
		if not t in TECHNIQUES:
			errors.append("spots.json: %s: %s: bilinmeyen teknik: %s" % [spot_id, id, t])
			continue
		if t == "fly" and (z["current"] as Vector2).is_zero_approx():
			errors.append("spots.json: %s: %s: sinek yalnızca akıntılı bölgede" % [spot_id, id])
		var reach := 0.0
		for i in ids.size():
			reach += float(maxi(0, weights[i])) * affinity(ids[i], t)
		if reach <= 0.0:
			errors.append("spots.json: %s: %s: %s tekniğiyle gelen tür yok" % [spot_id, id, t])


## Bölge oyunun başında açık mı (rütbe 1, sandalsız)?
static func _open_at_start(zones: Array[Dictionary], k: int) -> bool:
	return k >= 0 and k < zones.size() and int(zones[k]["rank"]) <= 1 and not bool(zones[k]["boat"])


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
