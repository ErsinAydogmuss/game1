class_name SaveData
extends RefCounted
## Oyuncunun kalıcı durumu. Tek bir serileştirilebilir nesne: ileride bulut kaydına doğrudan
## taşınabilir. Alan eklerken VERSION'ı artır, migrate()'e adım ekle ve test_save_data.gd'ye
## göç testi yaz.

const VERSION := 1

var player_id: String = ""
var created_unix: int = 0
var last_seen_unix: int = 0
var coins: int = 0
## Gölgelerin seed'i (1..2^31-1). Her oturum seed + oturum sayacıyla yeni gölgeler doğurur.
var seed: int = 0
## Kaçıncı açılış (her açılışta bir artar).
var session: int = 0
## Ansiklopedi: balık id -> { count, best_cm, best_stars, first_unix }.
var records: Dictionary = {}
## Toplam atış ve yakalanan balık sayısı.
var casts: int = 0
var catches: int = 0
## Dede'nin ipucu adımı (0 = ilk açılış; ilk av senaryolu).
var hint_step: int = 0
## Bir kez gösterilen bildirimler ve benzeri bayraklar.
var flags: Dictionary = {}
## sfx, music, vibration (bool), locale ("tr"/"en"), easy (Kolay çekme, bool).
var settings: Dictionary = {}
## Seçilen balıkçı (KayKit karakteri). H2'de seçim ekranı gelir.
var character: String = "rogue"


static func create_new(now_unix: int) -> SaveData:
	var s := SaveData.new()
	s.player_id = generate_player_id()
	s.created_unix = now_unix
	s.last_seen_unix = now_unix
	s.seed = generate_seed()
	return s


static func generate_player_id() -> String:
	return Crypto.new().generate_random_bytes(16).hex_encode()


## 1 ile 2^31-1 arasında rastgele seed (0 "atanmadı" demek).
static func generate_seed() -> int:
	var bytes := Crypto.new().generate_random_bytes(4)
	var value := (bytes[0] << 24 | bytes[1] << 16 | bytes[2] << 8 | bytes[3]) & 0x7FFFFFFF
	return maxi(1, value)


func to_dict() -> Dictionary:
	return {
		"version": VERSION,
		"player_id": player_id,
		"created_unix": created_unix,
		"last_seen_unix": last_seen_unix,
		"coins": coins,
		"seed": seed,
		"session": session,
		"records": records.duplicate(true),
		"casts": casts,
		"catches": catches,
		"hint_step": hint_step,
		"flags": flags.duplicate(),
		"settings": settings.duplicate(),
		"character": character,
	}


static func from_dict(raw: Dictionary) -> SaveData:
	var d := migrate(raw)
	var s := SaveData.new()
	s.player_id = str(d.get("player_id", ""))
	s.created_unix = int(d.get("created_unix", 0))
	s.last_seen_unix = int(d.get("last_seen_unix", 0))
	s.coins = maxi(0, int(d.get("coins", 0)))
	s.seed = maxi(0, int(d.get("seed", 0)))
	s.session = maxi(0, int(d.get("session", 0)))
	s.records = _records(d.get("records", {}))
	s.casts = maxi(0, int(d.get("casts", 0)))
	s.catches = maxi(0, int(d.get("catches", 0)))
	s.hint_step = maxi(0, int(d.get("hint_step", 0)))
	var raw_flags: Variant = d.get("flags", {})
	if typeof(raw_flags) == TYPE_DICTIONARY:
		s.flags = (raw_flags as Dictionary).duplicate()
	var raw_settings: Variant = d.get("settings", {})
	if typeof(raw_settings) == TYPE_DICTIONARY:
		s.settings = (raw_settings as Dictionary).duplicate()
	var character := str(d.get("character", "rogue"))
	s.character = character if not character.is_empty() else "rogue"
	return s


## Eski sürüm kayıtları güncel biçime getirir. Her sürüm için bir adım (v1 ilk sürüm).
static func migrate(raw: Dictionary) -> Dictionary:
	var d := raw.duplicate(true)
	var v := int(d.get("version", 0))
	if v < 1:
		v = 1
	d["version"] = v
	return d


## Bozuk ya da eksik kayıt satırlarını ayıklar.
static func _records(raw: Variant) -> Dictionary:
	var out := {}
	if typeof(raw) != TYPE_DICTIONARY:
		return out
	for key: Variant in raw:
		var entry: Variant = (raw as Dictionary)[key]
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var e: Dictionary = entry
		var count := maxi(0, int(e.get("count", 0)))
		if count <= 0:
			continue
		out[str(key)] = {
			"count": count,
			"best_cm": maxi(0, int(e.get("best_cm", 0))),
			"best_stars": clampi(int(e.get("best_stars", 1)), 1, 5),
			"first_unix": maxi(0, int(e.get("first_unix", 0))),
		}
	return out
