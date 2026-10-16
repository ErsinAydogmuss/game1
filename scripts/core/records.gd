class_name Records
extends RefCounted
## Balık kayıt defteri (Balık Defteri'nin verisi): tür başına sayı, en büyük boy, en iyi yıldız,
## ilk yakalanma zamanı ve bırakılan sayı. SaveData.records sözlüğünü yerinde günceller.

## Kart kuralı: tam kart yalnızca yeni tür, yeni rekor ya da bu nadirlik ve üstü için açılır.
const CARD_RARITY := 2


## Yakalanan balığı deftere yazar. Döner: { new_species, new_record, count }.
static func add(records: Dictionary, fish_id: String, size_cm: int, stars: int, now_unix: int) -> Dictionary:
	var entry: Dictionary = records.get(fish_id, {})
	var new_species := entry.is_empty()
	var best := int(entry.get("best_cm", 0))
	var new_record := not new_species and size_cm > best
	var count := int(entry.get("count", 0)) + 1
	records[fish_id] = {
		"count": count,
		"best_cm": maxi(best, size_cm),
		"best_stars": maxi(int(entry.get("best_stars", 1)), stars),
		"first_unix": now_unix if new_species else int(entry.get("first_unix", now_unix)),
		"released": int(entry.get("released", 0)),
	}
	return { "new_species": new_species, "new_record": new_record, "count": count }


## Yakalanmış bir balık göle bırakıldı (deftere yazılmış olmalı).
static func release(records: Dictionary, fish_id: String) -> void:
	if not records.has(fish_id):
		return
	var entry: Dictionary = records[fish_id]
	entry["released"] = mini(int(entry.get("count", 0)), int(entry.get("released", 0)) + 1)


## Bu yakalayış tam kartla mı gösterilsin (yoksa kısa bildirim)?
static func wants_card(rarity: int, outcome: Dictionary) -> bool:
	return bool(outcome.get("new_species", false)) or bool(outcome.get("new_record", false)) \
			or rarity >= CARD_RARITY


static func species_count(records: Dictionary) -> int:
	return records.size()
