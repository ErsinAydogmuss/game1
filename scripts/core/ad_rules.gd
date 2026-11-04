class_name AdRules
extends RefCounted
## Reklamların kuralları (Ersin'in kararı, 4 Kasım 2026; Kazı'nın v0.14 yaklaşımı): ödüllü reklamın yerleri, günlük
## sınırlar, bekleme süreleri ve geçiş reklamının ne zaman çıkacağı. Ödüllü reklamı oyuncu ister; izlemezse hiçbir şey
## kaybetmez, ödül sabittir (zar yok: oranlara ve şans garantisine dokunmaz). Geçiş reklamı yalnızca oyuncunun kendi
## başlattığı bir geçişten sonra çıkar (haritayla bölge değiştirme, Dede'yle çay: ekran zaten kararıyor).
##
## Durum tek bir sözlükte (kaydın ayarlarındaki "ads"; kayıt sürümü değişmez): gün (yyyymmdd) ve o günün sayaçları,
## toplam oyun süresi ve son reklamların zamanı (oyun saniyesi; Ads her kare ekler), bildirim görüldü mü. JSON'dan
## sayılar float gelir: okurken çevrilir.

## Ödüllü reklamın yerleri.
## Satıştan sonra satışın tutarı kadar para daha.
const SELL := "sell"
## Nadir ya da daha üstü bir balık çekişmede kaçınca (misina koptu, kaçtı) balık kurtarılır.
const RESCUE := "rescue"
## Dede'nin isteği bitince ödülün parası 2 katı.
const REQUEST := "request"
## Akvaryumun bağış kutusu toplanınca kutunun parası kadar para daha.
const AQUARIUM := "aquarium"
const PLACES: Array[String] = [SELL, RESCUE, REQUEST, AQUARIUM]
## Günün sayacında geçiş reklamının anahtarı.
const INTERSTITIAL := "interstitial"

## Yer başına günlük sınır.
const DAILY_CAP := { SELL: 8, RESCUE: 6, REQUEST: 6, AQUARIUM: 4 }
## Bir öncekinden en az bu kadar oyun saniyesi sonra (ekonomi fazla hızlanmasın): satış ve akvaryum.
const SELL_COOLDOWN := 600.0
const AQUARIUM_COOLDOWN := 900.0
## Bundan küçük satışa ve kutuya teklif yok (para).
const SELL_MIN := 30
const AQUARIUM_MIN := 40
## Isınma: bu kadar balık tutulmadan hiç teklif yok (açılış filmi, senaryolu ilk balık, ilk satış).
const WARMUP_CATCHES := 3
## Geçiş reklamı: toplam oyun en az bu kadar olmalı ve son reklamdan (geçiş ya da ödüllü) beri bu kadar geçmeli.
const INTERSTITIAL_GRACE := 1200.0
const INTERSTITIAL_GAP := 480.0
## Hiç olmamış bir olayın zamanı.
const NEVER := -1.0


## Ayarlardaki reklam durumu (yoksa kurulur; aynı sözlük döner).
static func state(settings: Dictionary) -> Dictionary:
	var raw: Variant = settings.get("ads")
	if typeof(raw) != TYPE_DICTIONARY:
		raw = {}
		settings["ads"] = raw
	var st: Dictionary = raw
	for key: String in ["last_ad", "sell_at", "aquarium_at"]:
		if not st.has(key):
			st[key] = NEVER
	if not st.has("play"):
		st["play"] = 0.0
	if typeof(st.get("n")) != TYPE_DICTIONARY:
		st["n"] = {}
	return st


## Gün değiştiyse günün sayaçları sıfırlanır.
static func roll_day(st: Dictionary, today: int) -> void:
	if int(st.get("day", 0)) != today:
		st["day"] = today
		st["n"] = {}


## Bugün bu yerde (ya da geçiş reklamında) kaç reklam izlendi.
static func count(st: Dictionary, place: String, today: int) -> int:
	roll_day(st, today)
	var n: Dictionary = st["n"]
	return int(n.get(place, 0))


## Toplam oyun süresi (sn).
static func play_time(st: Dictionary) -> float:
	return float(st.get("play", 0.0))


static func add_play(st: Dictionary, seconds: float) -> void:
	st["play"] = play_time(st) + maxf(seconds, 0.0)


## Olaydan bu yana geçen oyun süresi; olay hiç olmadıysa çok büyük.
static func since(st: Dictionary, key: String) -> float:
	var at := float(st.get(key, NEVER))
	if at < 0.0:
		return INF
	return play_time(st) - at


## Isınma bitti mi (kaydın balık sayısı).
static func warmed_up(catches: int) -> bool:
	return catches >= WARMUP_CATCHES


## Bu yerde ödüllü reklam teklif edilebilir mi (reklamın yüklü olup olmadığına bakmaz: o Ads'in işi).
static func can_offer(st: Dictionary, place: String, today: int, catches: int) -> bool:
	if not warmed_up(catches) or not PLACES.has(place):
		return false
	if count(st, place, today) >= int(DAILY_CAP[place]):
		return false
	match place:
		SELL:
			return since(st, "sell_at") >= SELL_COOLDOWN
		AQUARIUM:
			return since(st, "aquarium_at") >= AQUARIUM_COOLDOWN
	return true


## Satış teklifi bu tutar için mi (küçük satışa teklif yok).
static func sale_worth_offer(amount: int) -> bool:
	return amount >= SELL_MIN


## Akvaryum teklifi bu tutar için mi.
static func box_worth_offer(amount: int) -> bool:
	return amount >= AQUARIUM_MIN


## Kaçan balık kurtarılmaya değer mi: nadirliği en az Nadir (rare_index: ContentDB.rarity_index("rare")), hikâyenin
## balığı değil (Gölün Bekçisi tutulmak için oynanır) ve takımın taşıyamadığı fazla iri balık değil (iri balık takım
## ister: reklam bunu atlatmaz).
static func rescue_worth_offer(rarity: int, rare_index: int, story: bool, too_big: int) -> bool:
	return rarity >= rare_index and not story and too_big <= 0


## Ödüllü reklamın ödülü verildi: sayaç, zaman.
static func record_reward(st: Dictionary, place: String, today: int) -> void:
	count(st, place, today)
	var n: Dictionary = st["n"]
	n[place] = int(n.get(place, 0)) + 1
	st["last_ad"] = play_time(st)
	match place:
		SELL:
			st["sell_at"] = play_time(st)
		AQUARIUM:
			st["aquarium_at"] = play_time(st)


## Geçişten sonra geçiş reklamı çıkmalı mı.
static func interstitial_due(st: Dictionary, catches: int) -> bool:
	if not warmed_up(catches):
		return false
	if play_time(st) < INTERSTITIAL_GRACE:
		return false
	return since(st, "last_ad") >= INTERSTITIAL_GAP


static func record_interstitial(st: Dictionary, today: int) -> void:
	count(st, INTERSTITIAL, today)
	var n: Dictionary = st["n"]
	n[INTERSTITIAL] = int(n.get(INTERSTITIAL, 0)) + 1
	st["last_ad"] = play_time(st)


## "Reklamlar hakkında" kartı görüldü mü.
static func notice_seen(st: Dictionary) -> bool:
	return bool(st.get("notice", false))


static func mark_notice_seen(st: Dictionary) -> void:
	st["notice"] = true


## Yerel tarihten gün anahtarı (yyyymmdd): günlük sınırlar yerel gece yarısında sıfırlanır.
static func day_key(date: Dictionary) -> int:
	return int(date.get("year", 0)) * 10000 + int(date.get("month", 0)) * 100 + int(date.get("day", 0))
