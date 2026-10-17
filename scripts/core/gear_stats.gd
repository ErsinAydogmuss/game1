class_name GearStats
extends RefCounted
## Kuşanılmış takımın oyun mantığına etkisi (docs/gdd.md §10.4). FishingSession, ReelModel,
## BiteRules ve ShadowSim takımı yalnızca buradan okur. Başlangıç takımı prototipin bambu
## oltasıyla birebir aynı sayıları verir (testler bunu korur): bugünkü his değişmez.

## Kamışın tekniği (float, spin, bottom, fly).
var technique: String = "float"
## Atış menzili (m).
var range_m: float = 9.0
## 0–0,3: sarma hızı × (1 + power), patlamada balığın kaçışı × (1 − power).
var power: float = 0.0
## Makaranın sarma hızı (m/sn; balığın reel çarpanıyla çarpılır).
var reel_speed: float = 1.6
## 0–0,25 (fren): patlamada gerilim hedefi × (1 − drag).
var drag: float = 0.0
## Misina: sınırın üstünde kopmadan önce kaç adım (1/60 sn).
var snap_steps: int = 48
## 0–0,5 (görünmezlik): gölgeyi korkutma yarıçapı × (1 − stealth).
var stealth: float = 0.0
## Taşıma (yıldız): kamışın ve misinanın küçüğü. İri türün daha çok yıldızlısı fazla iridir
## (ReelModel.excess_for).
var carry: int = 3
## İğne: balığın kaçma payına eklenen metre.
var escape_extra: float = 0.0
## Şamandıra: VUR süresine eklenen adım.
var window_add_steps: int = 0
## Balığın tutulduğu uzaklık (m); kepçe büyütür.
var catch_m: float = 0.6
## Yemin tür çekimi: tür kimliği -> ağırlık çarpanı (boş = solucan, çekim yok).
var attract: Dictionary = {}
## Kuşanılan takım: yuva -> takım kimliği (ContentDB.GEAR_SLOTS).
var items: Dictionary = {}


## Başlangıç takımı (gear.json "start").
static func starter(db: ContentDB) -> GearStats:
	var none: Array[String] = []
	return from_items(db, db.gear_start, none)


## items: yuva -> takım kimliği. Eksik, bilinmeyen ya da yanlış kategoriden yuvaya başlangıç
## takımı konur (bozuk bir kayıt oyunu kilitlemesin). extras: sahip olunan ekstralar (kepçe).
static func from_items(db: ContentDB, items: Dictionary, extras: Array[String]) -> GearStats:
	var g := GearStats.new()
	g.snap_steps = db.rules.snap_steps
	g.catch_m = db.rules.catch_m
	var rod_carry := db.rules.carry
	var line_carry := db.rules.carry
	for slot: String in ContentDB.GEAR_SLOTS:
		var id := str(items.get(slot, ""))
		var item := db.gear_item(id)
		if item.is_empty() or str(item["category"]) != slot:
			id = str(db.gear_start.get(slot, ""))
			item = db.gear_item(id)
		if item.is_empty():
			continue
		g.items[slot] = id
		match slot:
			"rod":
				g.technique = str(item["technique"])
				g.range_m = float(item["range_m"])
				g.power = float(item["power"])
				rod_carry = int(item["carry"])
			"reel":
				g.reel_speed = float(item["reel_speed"])
				g.drag = float(item["drag"])
			"line":
				g.snap_steps = maxi(1, FishingRules.to_steps(float(item["snap_after"])))
				g.stealth = float(item["stealth"])
				line_carry = int(item["carry"])
			"hook":
				g.escape_extra = float(item["escape_extra"])
			"bobber":
				g.window_add_steps = FishingRules.to_steps(float(item["window_add"]))
			"bait":
				g.attract = (item["attract"] as Dictionary).duplicate()
	g.carry = mini(rod_carry, line_carry)
	for id in extras:
		var extra := db.gear_item(id)
		if str(extra.get("category", "")) == "extra":
			g.catch_m = maxf(g.catch_m, float(extra.get("catch_m", 0.0)))
	return g


## Bir teknik için her yuvadaki en pahalı takım ve bütün ekstralar (denge raporu ve testler:
## "en iyi takımla bile beceri gerekiyor mu?"). Yem solucan kalır: çekişmeyi değiştirmez.
static func best(db: ContentDB, technique: String = "float") -> GearStats:
	var items := {}
	for slot: String in ContentDB.GEAR_SLOTS:
		if slot == "bait":
			continue
		var top: Dictionary = {}
		for g in db.gear_in(slot):
			if slot == "rod" and str(g["technique"]) != technique:
				continue
			if top.is_empty() or int(g["price"]) > int(top["price"]):
				top = g
		if not top.is_empty():
			items[slot] = str(top["id"])
	var extras: Array[String] = []
	for g in db.gear_in("extra"):
		extras.append(str(g["id"]))
	return from_items(db, items, extras)


## Bu türü yem ne kadar çeker (çarpan; yem çekmiyorsa 1).
func attraction(fish_id: String) -> float:
	return float(attract.get(fish_id, 1.0))
