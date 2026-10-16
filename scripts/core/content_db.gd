class_name ContentDB
extends RefCounted
## Oyun içeriği: data/*.json dosyalarını yükler ve doğrular. Hatalar `errors` listesine yazılır
## (oyun açılışta bunları konsola basar, testler boş olmasını bekler).
##
## Olasılıklar ppm (milyonda bir) tamsayıdır: seed'li zarlar tamsayı karşılaştırır, float
## yuvarlaması cihazdan cihaza fark yaratmaz.

const DATA_DIR := "res://data"
const PPM := 1_000_000

## Nadirlikler, sırayla (0 Sıradan .. 4 Efsanevi). Kayıtlar sıra numarasını tutar: yalnızca
## sona eklenir.
var rarities: Array[Dictionary] = []
var errors: PackedStringArray = []

var _rarity_index: Dictionary = {}


static func load_default() -> ContentDB:
	return load_from(DATA_DIR)


static func load_from(dir: String) -> ContentDB:
	var db := ContentDB.new()
	db._load_rarities(db._read_json(dir.path_join("rarities.json")))
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
		}
		_rarity_index[def["id"]] = rarities.size()
		rarities.append(def)


# --- Doğrulama ----------------------------------------------------------------------

func _validate() -> void:
	if rarities.is_empty():
		errors.append("rarities.json: nadirlik yok")
	_check_unique("rarities", rarities)


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
