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
## kuşanılır (dükkânda "al" = "al ve tak"). Başardıysa true.
static func buy(db: ContentDB, save: SaveData, id: String) -> bool:
	if not buy_block(db, save, id).is_empty():
		return false
	var item := db.gear_item(id)
	save.coins -= int(item["price"])
	_add_stat(save, "spent", int(item["price"]))
	if str(item["category"]) == "bait" and int(item["pack"]) > 0:
		save.baits[id] = int(save.baits.get(id, 0)) + int(item["pack"])
	else:
		save.owned.append(id)
	equip(db, save, id)
	return true


## Kuşanır (sahipliyse ve kuşanılan bir yuvaya aitse). Kamış kendi tekniğinin setine, öteki
## takım teknik setine (H2 Dalga 1: yalnızca şamandıra) girer.
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
	var set_for := str(item["technique"]) if slot == "rod" else technique
	var slots: Dictionary = save.loadouts.get(set_for, {})
	slots[slot] = id
	save.loadouts[set_for] = slots
	return true


## Kuşanılan takım kimliği (yuva için; boşsa ya da artık geçersizse başlangıç takımı).
static func equipped(db: ContentDB, save: SaveData, slot: String, technique: String = "float") -> String:
	var slots: Dictionary = save.loadouts.get(technique, {})
	var id := str(slots.get(slot, ""))
	var item := db.gear_item(id)
	var usable := not item.is_empty() and str(item["category"]) == slot
	if usable and slot == "bait":
		usable = int(item["pack"]) == 0 or int(save.baits.get(id, 0)) > 0
	elif usable:
		usable = owns(db, save, id)
	return id if usable else str(db.gear_start.get(slot, ""))


## Bu teknik için kuşanılmış takımın etkisi (oturum bunu kullanır). Tükenmiş yem solucana döner.
static func gear_for(db: ContentDB, save: SaveData, technique: String = "float") -> GearStats:
	var items := {}
	for slot: String in ContentDB.GEAR_SLOTS:
		items[slot] = equipped(db, save, slot, technique)
	var extras: Array[String] = []
	for g in db.gear_in("extra"):
		if owns(db, save, str(g["id"])):
			extras.append(str(g["id"]))
	return GearStats.from_items(db, items, extras)


## Balık oltaya takılınca yem harcanır (atışta değil: kaçan gölge yemi yemez).
static func use_bait(db: ContentDB, save: SaveData, technique: String = "float") -> void:
	var id := equipped(db, save, "bait", technique)
	var item := db.gear_item(id)
	if item.is_empty() or int(item["pack"]) <= 0:
		return
	save.baits[id] = maxi(0, int(save.baits.get(id, 0)) - 1)


static func _add_stat(save: SaveData, key: String, amount: int) -> void:
	save.stats[key] = int(save.stats.get(key, 0)) + amount
