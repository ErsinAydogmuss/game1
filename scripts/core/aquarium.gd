class_name Aquarium
extends RefCounted
## Akvaryum (Dalga 5, docs/gdd.md §10.6). Saf işlevler: kayıt ve zaman (now: gerçek saat, unix sn)
## parametre olarak gelir.
## - Tank: Nine'nin tezgâhındaki camda her türün en irisi yüzer. Defterden türer (Records: best_cm,
##   best_stars), ayrı bir liste tutulmaz; tanktaki, tutulan balığın kopyasıdır (kovadaki balık yine
##   satılır). Satılmayan türler (koruma altındaki mersin, gece efsaneleri, Gölün Bekçisi: değeri 0)
##   göle döner, tanka girmez.
## - Bağış kutusu: tankı görmeye gelen ziyaretçiler saatte rate_ph para bırakır (tanktaki tür sayısı
##   ve balıkların değeri). Kutu gerçek saatle dolar, oyun kapalıyken de (TrapSim gibi); en çok
##   rules.aquarium_cap_s'lik birikimde durur (boşta biriken üst sınırda durur: gelir kuralı 7). Saat
##   geri alınırsa bir şey kaybolmaz ya da kazanılmaz (yalnızca dayanak aquarium_unix yenilenir).
##   Dükkâna uğrayınca ya da Akvaryum panelinde toplanır.
## - Kutu 1/UNIT'lik birimle tutulur (saatlik kazanç × geçen saniye): kesir kaybolmaz; tank değişmedikçe her
##   saniye güncellenen oyun da tek seferde güncellenen denge botu da aynı parayı bulur. Bot kutuyu yalnızca
##   satışta günceller: araya giren yeni tür önceki satıştan beri tankta sayılır (300 dakikada ~15 para, ihmal
##   edilir).
@warning_ignore_start("integer_division")

## Kutunun birimi: bir para = UNIT birim (saatte rate_ph para = saniyede rate_ph birim).
const UNIT := 3600


## Tanka girebilen türler (değeri olan; fish.json sırasıyla).
static func species(db: ContentDB) -> PackedStringArray:
	var out := PackedStringArray()
	for f in db.fish:
		if int(f["value"]) > 0 and not bool(f.get("release_only", false)):
			out.append(str(f["id"]))
	return out


## Tankın alabileceği tür sayısı ("12/15 tür").
static func capacity(db: ContentDB) -> int:
	return species(db).size()


## Tanktaki balıklar: her tutulmuş türün en irisi [{ fish, size_cm, stars, value }] (fish.json
## sırasıyla).
static func fish(db: ContentDB, save: SaveData) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for id in species(db):
		var entry: Variant = save.records.get(id)
		if typeof(entry) != TYPE_DICTIONARY or int((entry as Dictionary).get("count", 0)) <= 0:
			continue
		var e: Dictionary = entry
		var size := int(e.get("best_cm", 0))
		if size <= 0:
			continue
		out.append({
			"fish": id,
			"size_cm": size,
			"stars": clampi(int(e.get("best_stars", 1)), 1, 5),
			"value": Economy.fish_value(db, id, size),
		})
	return out


## Saatte kutuya düşen para: tür başına aquarium_species_ph ve balıkların değerinin binde
## aquarium_value_pm'i.
static func rate_ph(db: ContentDB, save: SaveData) -> int:
	return rate_of(db.rules, fish(db, save))


## Tanktaki balıklardan saatlik kazanç (fish()'in sonucuyla: panel bir kez hesaplar).
static func rate_of(rules: FishingRules, tank: Array[Dictionary]) -> int:
	var value := 0
	for f in tank:
		value += int(f["value"])
	return tank.size() * rules.aquarium_species_ph + (value * rules.aquarium_value_pm + 500) / 1000


## Kutunun alabileceği en çok para (üst sınır: aquarium_cap_s'lik kazanç).
static func cap_coins(db: ContentDB, save: SaveData) -> int:
	return rate_ph(db, save) * db.rules.aquarium_cap_s / UNIT


## Kutu now'a: geçen gerçek saniye kadar dolar, en çok üst sınıra. Saat geri alınınca yalnızca
## dayanak yenilenir (kazanç da kayıp da yok). Kutunun saati ilk çağrıda başlar.
static func update(db: ContentDB, save: SaveData, now: int) -> void:
	save.aquarium_box = _box_at(db, save, now)
	save.aquarium_unix = now


## Kutudaki para (now'da; kaydı değiştirmez).
static func pending(db: ContentDB, save: SaveData, now: int) -> int:
	return _box_at(db, save, now) / UNIT


## Kutu dolu mu (üst sınırda; daha fazla birikmez)?
static func is_full(db: ContentDB, save: SaveData, now: int) -> bool:
	var rate := rate_ph(db, save)
	return rate > 0 and _box_at(db, save, now) >= rate * db.rules.aquarium_cap_s


## Kutudaki para toplanır (kesir kutuda kalır): paraya ve sayaca (stats.aquarium_coins). Döner: toplanan.
static func collect(db: ContentDB, save: SaveData, now: int) -> int:
	update(db, save, now)
	var coins := save.aquarium_box / UNIT
	if coins <= 0:
		return 0
	save.aquarium_box -= coins * UNIT
	save.coins += coins
	save.stats["aquarium_coins"] = int(save.stats.get("aquarium_coins", 0)) + coins
	return coins


## Kutunun now'daki birimi. Kutu üst sınırın üstündeyse (tür verisi değişti) azalmaz.
static func _box_at(db: ContentDB, save: SaveData, now: int) -> int:
	var box := save.aquarium_box
	if save.aquarium_unix < 0 or now <= save.aquarium_unix:
		return box
	var rate := rate_ph(db, save)
	var cap := rate * db.rules.aquarium_cap_s
	if box >= cap:
		return box
	return mini(cap, box + rate * (now - save.aquarium_unix))
