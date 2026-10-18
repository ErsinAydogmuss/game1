class_name Economy
extends RefCounted
## Para ve takım (docs/gdd.md §10.4): balığın değeri, satış, satın alma, kuşanma ve yem.
## Saf fonksiyonlar; SaveData'yı yerinde günceller. Para yalnızca oynayarak kazanılır, gerçek
## parayla asla satılmaz (CLAUDE.md, gelir kuralları): oranı değiştiren yem bu sayede satılabilir.
##
## Değerler tamsayı binde birle hesaplanır (Kazı'daki Economy gibi): cihazdan cihaza fark olmaz.
@warning_ignore_start("integer_division")

## Boy çarpanı binde bir: en küçük boy 600 (0,6), en büyük boy 1600 (1,6).
const SIZE_MIN := 600
const SIZE_SPAN := 1000


## Balığın satış değeri: türün değeri × boy çarpanı (boyun türün aralığındaki yerine göre
## 0,6–1,6), en az 1. Masalsı balık (değeri 0 olan) satılmaz: 0 döner.
static func fish_value(db: ContentDB, fish_id: String, size_cm: int) -> int:
	var f := db.fish_by_id(fish_id)
	if f.is_empty() or int(f["value"]) <= 0:
		return 0
	var span: Vector2i = f["size_cm"]
	var range_cm := maxi(1, span.y - span.x)
	var permille := clampi((size_cm - span.x) * 1000 / range_cm, 0, 1000)
	var factor := SIZE_MIN + SIZE_SPAN * permille / 1000
	return maxi(1, (int(f["value"]) * factor + 500) / 1000)


## Kovadaki bütün balıkların değeri.
static func bucket_value(db: ContentDB, save: SaveData) -> int:
	var total := 0
	for entry in save.bucket:
		total += fish_value(db, str(entry["fish"]), int(entry["size_cm"]))
	return total


## Kovayı Nine'ye satar: para eklenir, satılan balıklar kovadan çıkar. Değeri 0 olan (Masalsı)
## balık satılmaz, kovada kalır. Kazanılan parayı döndürür (0 ise kayıt değişmez).
static func sell_all(db: ContentDB, save: SaveData) -> int:
	var earned := 0
	var sold := 0
	var kept: Array[Dictionary] = []
	for entry in save.bucket:
		var value := fish_value(db, str(entry["fish"]), int(entry["size_cm"]))
		if value <= 0:
			kept.append(entry)
			continue
		earned += value
		sold += 1
	if sold == 0:
		return 0
	save.coins += earned
	save.bucket = kept
	_add_stat(save, "earned", earned)
	_add_stat(save, "sold", sold)
	return earned


## Takım sahipli mi? Bedava başlangıç takımı hep sahiplidir. Yemler sahiplikle değil sayıyla
## tutulur (has_bait).
static func owns(db: ContentDB, save: SaveData, id: String) -> bool:
	var item := db.gear_item(id)
	if item.is_empty():
		return false
	return int(item["price"]) == 0 or id in save.owned


## Satın alınabilir mi? "" (evet) ya da neden: "unknown", "owned", "rank", "coins".
static func buy_block(db: ContentDB, save: SaveData, id: String) -> String:
	var item := db.gear_item(id)
	if item.is_empty():
		return "unknown"
	var consumable := str(item["category"]) == "bait" and int(item["pack"]) > 0
	if not consumable and owns(db, save, id):
		return "owned"
	# Kapasite en büyük kovadan gelir: daha küçüğü (ya da eşiti) bir şey katmaz, "sende" sayılır.
	if str(item["category"]) == "bucket" and int(item["capacity"]) <= Bucket.capacity(db, save):
		return "owned"
	if Rank.rank(db, save) < int(item["rank"]):
		return "rank"
	if save.coins < int(item["price"]):
		return "coins"
	return ""


## Satın alır: para düşer; takım sahiplenir ya da yem paketi eklenir. Takım kendiliğinden
## kuşanılır (dükkânda "al" = "al ve tak"): kendi tekniğinin setine; yem, dükkânda bakılan
## tekniğin setine (o teknik yem kullanmıyorsa şamandıranınkine). Başardıysa true.
static func buy(db: ContentDB, save: SaveData, id: String, technique: String = "float") -> bool:
	if not buy_block(db, save, id).is_empty():
		return false
	var item := db.gear_item(id)
	save.coins -= int(item["price"])
	_add_stat(save, "spent", int(item["price"]))
	if str(item["category"]) == "bait" and int(item["pack"]) > 0:
		save.baits[id] = int(save.baits.get(id, 0)) + int(item["pack"])
	else:
		save.owned.append(id)
	equip(db, save, id, technique)
	return true


## Kuşanır (sahipliyse ve kuşanılan bir yuvaya aitse). Makara ve misina her teknikte ortak
## (loadouts.shared); kamış kendi tekniğinin setine; iğne, şamandıra, yapay yem, kurşun ve sinek
## yuvasının tekniğine; yem verilen tekniğe (yem kullanmıyorsa şamandıraya) girer.
static func equip(db: ContentDB, save: SaveData, id: String, technique: String = "float") -> bool:
	var item := db.gear_item(id)
	if item.is_empty():
		return false
	var slot := str(item["category"])
	if not slot in ContentDB.GEAR_SLOTS:
		return false
	if slot == "bait":
		if int(item["pack"]) > 0 and int(save.baits.get(id, 0)) <= 0:
			return false
	elif not owns(db, save, id):
		return false
	var set_for := set_of(db, slot, technique)
	if slot == "rod":
		set_for = str(item["technique"])
	var slots: Dictionary = save.loadouts.get(set_for, {})
	slots[slot] = id
	save.loadouts[set_for] = slots
	return true


## Bir yuvanın kuşanıldığı set: ortak yuvada "shared", tek tekniğin yuvasında o teknik, kamış ve
## yemde verilen teknik (yem kullanmıyorsa şamandıra).
static func set_of(db: ContentDB, slot: String, technique: String) -> String:
	if db.is_shared(slot):
		return "shared"
	var owner := db.slot_technique(slot)
	if not owner.is_empty():
		return owner
	return technique if db.uses_slot(technique, slot) else "float"


## Kuşanılan takım kimliği (yuva için; boşsa ya da artık geçersizse başlangıç takımı). Teknik o
## yuvayı kullanmıyorsa "". Kamış o tekniğin olmalı: kuşanılan geçersizse sahip olunan en iyi
## kamışı; hiç yoksa şamandırada bambu olta, öteki tekniklerde "" (teknik hazır değil).
static func equipped(db: ContentDB, save: SaveData, slot: String, technique: String = "float") -> String:
	if not db.uses_slot(technique, slot):
		return ""
	var set_for := set_of(db, slot, technique)
	var id := _loadout_id(save, set_for, slot)
	if id.is_empty() and set_for == "shared":
		# Göçten önceki biçim: makara ve misina şamandıranın setindeydi.
		id = _loadout_id(save, "float", slot)
	var item := db.gear_item(id)
	var usable := not item.is_empty() and str(item["category"]) == slot
	if usable and slot == "bait":
		usable = int(item["pack"]) == 0 or int(save.baits.get(id, 0)) > 0
	elif usable:
		usable = owns(db, save, id)
	if usable and slot == "rod":
		usable = str(item["technique"]) == technique
	if usable:
		return id
	if slot == "rod" and technique != "float":
		return best_owned_rod(db, save, technique)
	return str(db.gear_start.get(slot, ""))


## Sahip olunan en pahalı kamış bu teknikte (yoksa "").
static func best_owned_rod(db: ContentDB, save: SaveData, technique: String) -> String:
	var best := ""
	var best_price := -1
	for g in db.rods_of(technique):
		if owns(db, save, str(g["id"])) and int(g["price"]) > best_price:
			best = str(g["id"])
			best_price = int(g["price"])
	return best


## Teknik kullanılabilir mi: şamandıra hep; öteki tekniklerde o tekniğin bir kamışı alınmış olmalı.
static func technique_ready(db: ContentDB, save: SaveData, technique: String) -> bool:
	return technique == "float" or not best_owned_rod(db, save, technique).is_empty()


## Teknik bu bölgede avlanılır mı (bölgenin techniques'i; sinek yalnızca dere ağzında)?
static func technique_allowed(db: ContentDB, spot_id: String, zone_id: String, technique: String) -> bool:
	var z := db.zone(spot_id, zone_id)
	return z.is_empty() or CatchOdds.allows(z, technique)


## Bu teknik için kuşanılmış takımın etkisi (oturum bunu kullanır). Tükenmiş yem solucana döner.
## Teknik hazır değilse (kamışı yok) şamandıranınki.
static func gear_for(db: ContentDB, save: SaveData, technique: String = "float") -> GearStats:
	if not technique_ready(db, save, technique):
		technique = "float"
	var items := {}
	for slot: String in db.slots_for(technique):
		items[slot] = equipped(db, save, slot, technique)
	var extras: Array[String] = []
	for g in db.gear_in("extra"):
		if owns(db, save, str(g["id"])):
			extras.append(str(g["id"]))
	return GearStats.from_items(db, items, extras)


## Fazla iri balık için ne gerek (Dede'nin öğüdü): kuşanılan kamışın ya da misinanın taşıması
## stars'tan azsa o yuvada stars'ı taşıyan takım. Önce sahip olunan, sonra rütbesi yeten (en ucuzu),
## sonra en erken açılan. Döner: { "buy": Nine'den alınacaklar, "equip": sende olup takılacaklar
## (kimlikler; kamış, misina sırasıyla), "rank": alınacaklardan rütbesi yetmeyen varsa açıldığı en
## yüksek rütbe (yoksa 0) }.
static func gear_for_stars(db: ContentDB, save: SaveData, stars: int, technique: String = "float") -> Dictionary:
	var buy: Array[String] = []
	var equip: Array[String] = []
	var rank := 0
	var my_rank := Rank.rank(db, save)
	for slot: String in ["rod", "line"]:
		var current := db.gear_item(equipped(db, save, slot, technique))
		if int(current.get("carry", db.rules.carry)) >= stars:
			continue
		var pick: Dictionary = {}
		var pick_key := Vector3i.ZERO
		for g in db.gear_in(slot):
			if int(g["carry"]) < stars or (slot == "rod" and str(g["technique"]) != technique):
				continue
			var id := str(g["id"])
			# Küçük olan önce: sahip olunan (0), rütbesi yeten (0) ya da açıldığı rütbe, fiyat.
			var locked := my_rank < int(g["rank"])
			var key := Vector3i(0 if owns(db, save, id) else 1, int(g["rank"]) if locked else 0, int(g["price"]))
			if pick.is_empty() or key < pick_key:
				pick = g
				pick_key = key
		if pick.is_empty():
			continue
		var pick_id := str(pick["id"])
		if owns(db, save, pick_id):
			equip.append(pick_id)
		else:
			buy.append(pick_id)
			if my_rank < int(pick["rank"]):
				rank = maxi(rank, int(pick["rank"]))
	return { "buy": buy, "equip": equip, "rank": rank }


## Balık oltaya takılınca yem harcanır (atışta değil: kaçan gölge yemi yemez). Yapay yem ve sinek
## tükenmez.
static func use_bait(db: ContentDB, save: SaveData, technique: String = "float") -> void:
	if not db.uses_slot(technique, "bait"):
		return
	var id := equipped(db, save, "bait", technique)
	var item := db.gear_item(id)
	if item.is_empty() or int(item["pack"]) <= 0:
		return
	save.baits[id] = maxi(0, int(save.baits.get(id, 0)) - 1)


static func _add_stat(save: SaveData, key: String, amount: int) -> void:
	save.stats[key] = int(save.stats.get(key, 0)) + amount


static func _loadout_id(save: SaveData, set_name: String, slot: String) -> String:
	var slots: Variant = save.loadouts.get(set_name, {})
	if typeof(slots) != TYPE_DICTIONARY:
		return ""
	return str((slots as Dictionary).get(slot, ""))
