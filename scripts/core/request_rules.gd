class_name RequestRules
extends RefCounted
## Dede'nin isteklerinin kuralları (data/requests.json; Dalga 4, docs/gdd.md §10.5). Oranlar ppm, ödül
## çarpanları binde (tamsayı hesap: her cihazda aynı istek). Yükleyen ContentDB denetler (validate).

## İsteklerin türleri (kayıtta isteğin kind'ı: kimlikler değişmez, yeni tür sona eklenir).
const KINDS: Array[String] = ["species", "size", "technique", "zone", "phase", "rare", "rain", "release", "trash",
		"trap"]

## Günlük yuva sayısı ve isteklerin açıldığı rütbe.
var slots: int = 3
var unlock_rank: int = 2
## Ödül: para (taban + rütbe başına) × çarpan × saçılma (binde), rütbe puanı (taban + rütbe başına) × çarpan.
var coins_base: int = 15
var coins_per_rank: int = 6
var spread_min_pm: int = 750
var spread_max_pm: int = 1250
var xp_base: int = 10
var xp_per_rank: int = 4
## Tür isteğinin sayısı nadirliğe göre: nadirlik kimliği -> Vector2i(en az, en çok); listede olmayan
## nadirlik istenmez.
var species_count: Dictionary = {}
## Tür ve boy isteği: türün bir açık bölgede elindeki bir teknikle en az bu payla (ppm) gelmesi.
var species_min_ppm: int = 20_000
## Boy isteğinin yüzdeliği (ppm): türün bu aralıktaki boyu (3 yıldızın içinde kalır).
var size_percentile := Vector2i(350_000, 600_000)
## Şablonlar: [{ kind, weight, rank, count: Vector2i, love, mult_pm }], dosyadaki sırayla.
var templates: Array[Dictionary] = []


static func from_dict(d: Dictionary, errors: PackedStringArray) -> RequestRules:
	var r := RequestRules.new()
	if d.is_empty():
		errors.append("requests.json: boş ya da okunamadı")
		return r
	r.slots = int(d.get("slots", r.slots))
	r.unlock_rank = int(d.get("unlock_rank", r.unlock_rank))
	var reward: Dictionary = d.get("reward", {})
	r.coins_base = int(reward.get("coins_base", r.coins_base))
	r.coins_per_rank = int(reward.get("coins_per_rank", r.coins_per_rank))
	r.spread_min_pm = roundi(float(reward.get("spread_min", 0.75)) * 1000.0)
	r.spread_max_pm = roundi(float(reward.get("spread_max", 1.25)) * 1000.0)
	r.xp_base = int(reward.get("xp_base", r.xp_base))
	r.xp_per_rank = int(reward.get("xp_per_rank", r.xp_per_rank))
	var counts: Dictionary = d.get("species_count", {})
	for key: Variant in counts:
		r.species_count[str(key)] = _range(counts[key])
	r.species_min_ppm = roundi(float(d.get("species_min_ppm", r.species_min_ppm)))
	var pct: Variant = d.get("size_percentile", [])
	if typeof(pct) == TYPE_ARRAY and (pct as Array).size() == 2:
		r.size_percentile = Vector2i(roundi(float(pct[0]) * Dice.PPM), roundi(float(pct[1]) * Dice.PPM))
	for raw: Variant in d.get("templates", []):
		if typeof(raw) != TYPE_DICTIONARY:
			errors.append("requests.json: şablon bir nesne olmalı")
			continue
		var t: Dictionary = raw
		r.templates.append({
			"kind": str(t.get("kind", "")),
			"weight": int(t.get("weight", 0)),
			"rank": int(t.get("rank", 1)),
			"count": _range(t.get("count", [1, 1])),
			"love": int(t.get("love", 0)),
			"mult_pm": roundi(float(t.get("mult", 1.0)) * 1000.0),
		})
	return r


## Şablon (kind'ı; yoksa boş).
func template(kind: String) -> Dictionary:
	for t in templates:
		if str(t["kind"]) == kind:
			return t
	return {}


## Denetim (ContentDB): yuvalar 1..SaveData.MAX_REQUESTS - 1 (sonuncu hikâyenin altın isteğine), bilinen ve
## tekrarsız şablonlar, pozitif ağırlık, geçerli sayı aralıkları, bilinen nadirlikler.
func validate(db: ContentDB, errors: PackedStringArray) -> void:
	if slots < 1 or slots >= SaveData.MAX_REQUESTS:
		errors.append("requests.json: slots 1..%d olmalı" % (SaveData.MAX_REQUESTS - 1))
	if unlock_rank < 1 or unlock_rank > db.max_rank():
		errors.append("requests.json: unlock_rank 1..%d olmalı" % db.max_rank())
	if spread_min_pm <= 0 or spread_max_pm < spread_min_pm or coins_base < 0 or coins_per_rank < 0 \
			or xp_base < 0 or xp_per_rank < 0:
		errors.append("requests.json: reward: sayılar sıfır ya da pozitif, spread_min ≤ spread_max olmalı")
	if size_percentile.x < 0 or size_percentile.y >= 700_000 or size_percentile.x > size_percentile.y:
		errors.append("requests.json: size_percentile 0..0,7 aralığında olmalı (3 yıldızın içinde)")
	if species_min_ppm <= 0 or species_min_ppm >= Dice.PPM:
		errors.append("requests.json: species_min_ppm 0..1 aralığında olmalı")
	for key: String in species_count:
		var range_v: Vector2i = species_count[key]
		if db.rarity_index(key) < 0 or range_v.x < 1 or range_v.y < range_v.x:
			errors.append("requests.json: species_count: %s bilinmiyor ya da aralık bozuk" % key)
	var seen := {}
	for t in templates:
		var kind := str(t["kind"])
		var count: Vector2i = t["count"]
		if not kind in KINDS or seen.has(kind):
			errors.append("requests.json: şablon bilinmiyor ya da tekrar: %s" % kind)
		seen[kind] = true
		if int(t["weight"]) <= 0 or int(t["love"]) < 0 or int(t["mult_pm"]) <= 0 or count.x < 1 or count.y < count.x:
			errors.append("requests.json: %s: ağırlık ve çarpan pozitif, sayı aralığı geçerli olmalı" % kind)


static func _range(raw: Variant) -> Vector2i:
	if typeof(raw) == TYPE_ARRAY and (raw as Array).size() == 2:
		return Vector2i(int(raw[0]), int(raw[1]))
	return Vector2i(1, 1)
