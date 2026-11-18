class_name FirstSteps
extends RefCounted
## İlk adımlar (testçi: "oyuna görevler eklenebilir"): yeni oyuncuyu yönlendiren kısa liste; Görevler panelinde
## Dede'nin isteklerinin üstünde. Her adım kayıttan türer (ayrı liste yok: eski kayıtta biten adım bitmiş görünür;
## kayıt sürümü değişmez). Ödül yok: ekonomi aynı (para, puan ve sevgi Dede'nin isteklerinden gelir, rütbe 2'de).
## Biten adımın bildirimi bir kez: bayrak STEP_FLAG ("seen"); bütün adımlar bitince liste panelden kalkar.

## Adımlar sırasıyla: ilk balık, ilk satış, Nine'den ilk takım, ilk yeni bölge, rütbe 2 (Dede'nin istekleri).
const STEPS: Array[String] = ["catch", "sell", "buy", "zone", "rank"]
## Adımların yazısı (Görevler paneli, "Görev tamam" bildirimi).
const STEP_KEYS := {"catch": "UI_STEP_CATCH", "sell": "UI_STEP_SELL", "buy": "UI_STEP_BUY", "zone": "UI_STEP_ZONE",
		"rank": "UI_STEP_RANK"}
## Rütbe adımı (yazısı "Rütbe 2'ye çık"): Dede'nin istekleri bu rütbede başlar (requests.json unlock_rank 2).
const RANK := 2
const STEP_FLAG := "step_%s"
## Bölge adımı: oyunun başladığı bölgeden (gölün ilk bölgesi) başka bir bölgeye gidilmiş olmalı.
const VISITED := "visited_"


## Adım bitti mi (kayıttan)?
static func done(db: ContentDB, save: SaveData, spot_id: String, id: String) -> bool:
	match id:
		"catch":
			return save.catches >= 1
		"sell":
			return int(save.stats.get("sold", 0)) >= 1
		"buy":
			return int(save.stats.get("spent", 0)) > 0
		"zone":
			var zones := db.zones_of(spot_id)
			var home := str(zones[0]["id"]) if not zones.is_empty() else ""
			for key: Variant in save.flags:
				var flag := str(key)
				if flag.begins_with(VISITED) and flag.substr(VISITED.length()) != home:
					return true
			return false
		"rank":
			return Rank.rank(db, save) >= RANK
	return false


## Kaç adım bitti?
static func done_count(db: ContentDB, save: SaveData, spot_id: String) -> int:
	var n := 0
	for id in STEPS:
		if done(db, save, spot_id, id):
			n += 1
	return n


## Bütün adımlar bitti mi (liste panelden kalkar)?
static func all_done(db: ContentDB, save: SaveData, spot_id: String) -> bool:
	return done_count(db, save, spot_id) == STEPS.size()


## Bitmiş ama haberi verilmemiş adımlar (sırasıyla). Eski kayıtta (ilk sürümde) önceden bitmiş adımlar da çıkar:
## çağıran ilk kez bakarken hepsini sessizce "görülmüş" sayabilir (mark_all_seen).
static func fresh(db: ContentDB, save: SaveData, spot_id: String) -> Array[String]:
	var out: Array[String] = []
	for id in STEPS:
		if done(db, save, spot_id, id) and not save.flags.has(STEP_FLAG % id):
			out.append(id)
	return out


## Adımın haberi verildi (bildirim).
static func mark_seen(save: SaveData, id: String) -> void:
	save.flags[STEP_FLAG % id] = "seen"


## Bitmiş adımların hepsi görülmüş sayılır (bildirim çıkmaz): eski kayıt ilk açılışta.
static func mark_all_seen(db: ContentDB, save: SaveData, spot_id: String) -> void:
	for id in fresh(db, save, spot_id):
		mark_seen(save, id)
