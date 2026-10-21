class_name SaveData
extends RefCounted
## Oyuncunun kalıcı durumu. Tek bir serileştirilebilir nesne: ileride bulut kaydına doğrudan
## taşınabilir. Alan eklerken VERSION'ı artır, migrate()'e adım ekle ve test_save_data.gd'ye
## göç testi yaz.

const VERSION := 5
## Kayıtta en çok bu kadar tuzak ve tuzak başına içerik tutulur (bozuk kayıt büyümesin).
const MAX_TRAPS := 8
const MAX_TRAP_ITEMS := 8
## Dede'nin istekleri (v5): 3 günlük yuva ve hikâyenin altın yuvası.
const MAX_REQUESTS := 4
## Gölün Sırrı (v5): her bölgeden bir mektup, dört harita parçası.
const MAX_LETTERS := 6
const MAX_MAP_PIECES := 4
## Rütbe eğrileri (progression.json "xp"): kaydın sürümüyle değişen eğri, göçte rütbe puanı yeni
## eğriye taşınır (rütbe düşmesin). Bunlar o sürümün eğrisidir, değiştirilmez; eğri yeniden
## değişirse yeni sürüm ve yeni sabit eklenir (test_save_data denetler).
const XP_CURVE_V2: Array[int] = [0, 40, 110, 220, 380, 600, 900, 1300, 1800, 2400, 3100, 3900, 4800,
		5800, 6900, 8100, 9400, 10800, 12300, 13900]
const XP_CURVE_V3: Array[int] = [0, 60, 300, 600, 950, 1400, 2050, 2900, 4000, 5000, 6200, 7600, 9200,
		11000, 13000, 15200, 17600, 20200, 23000, 26000]

var player_id: String = ""
var created_unix: int = 0
var last_seen_unix: int = 0
var coins: int = 0
## Gölgelerin seed'i (1..2^31-1). Her oturum seed + oturum sayacıyla yeni gölgeler doğurur.
var seed: int = 0
## Kaçıncı açılış (her açılışta bir artar).
var session: int = 0
## Balık Defteri: balık id -> { count, best_cm, best_stars, first_unix, released }.
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
## Kovadaki balıklar (satılmayı bekleyen): [{ fish, size_cm, stars }].
var bucket: Array[Dictionary] = []
## Satın alınan takım kimlikleri (gear.json). Fiyatı 0 olan başlangıç takımı hep sahiplidir.
## Takım kimlikle tutulur, kademe numarasıyla değil: araya yeni kademe eklenince kayıt bozulmaz.
var owned: PackedStringArray = []
## Teknik -> kuşanılan takım { yuva: kimlik } (eksik yuvada başlangıç takımı); her teknikte ortak
## yuvalar (makara, misina) "shared" altında (v4).
var loadouts: Dictionary = {}
## Elindeki teknik (float, spin, bottom, fly; v4).
var technique: String = "float"
## Göldeki kerevit tuzakları (v4): [{ id, zone, x, z, placed_unix, last_unix, progress_s,
## items: [{ fish, size_cm, stars }] }]. İçerik tuzak kurulunca belli olur (gelir kuralı 4); dolma
## gerçek saatle, üst sınırlı (TrapSim).
var traps: Array[Dictionary] = []
## Kurulan tuzakların sayacı (tuzağın kimliği ve içeriğinin zarı).
var trap_serial: int = 0
## Tükenen yemler: yem kimliği -> kalan sayı (solucan sınırsız, burada tutulmaz).
var baits: Dictionary = {}
## Rütbe puanı ve göl sevgisi (bırakılan balık, toplanan çöp, istekler; hiç azalmaz).
var xp: int = 0
var love: int = 0
## Şans garantisi sayaçları: nadirlik kimliği -> o nadirlik ve üstü gelmeden geçen av sayısı.
var pity: Dictionary = {}
## Sayaçlar (istekler ve denge için): earned, spent, sold, released...
var stats: Dictionary = {}
## Oyun saati (v5, docs/gdd.md §10.5): oynanan saniye; vakit ve gün bundan türer (DayClock). Oyuncu
## yokken durur.
var clock_s: int = 0
## Son çay içildiğinde tutulan balık sayısı (iki çay arasında en az bir balık; -1 = hiç içilmedi).
var tea_at: int = -1
## Dede'nin istekleri (v5): [{ slot, kind, want: { tür, teknik, bölge, vakit ... }, goal, progress,
## day, serial, reward: { coins, xp, love, piece } }]. İstek oluşunca belli (gelir kuralı 4);
## süresi dolmaz.
var requests: Array[Dictionary] = []
## Kurulan isteklerin sayacı (isteğin zarı), yuvaların en son dolduğu ve ücretsiz değiştirmenin en son
## kullanıldığı oyun günü (-1 = hiç).
var request_serial: int = 0
var request_day: int = -1
var reroll_day: int = -1
## Gölün Sırrı (v5): okunan mektup sayısı, sıradaki şişenin sayıldığı balık sayısı (son mektuptan beri
## tutulan balıklar), toplanan harita parçası, Gölün Bekçisi'nin kaç kez tutulup bırakıldığı.
var letters: int = 0
var letter_at: int = 0
var map_pieces: int = 0
var keeper: int = 0


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
		"bucket": bucket.duplicate(true),
		"owned": Array(owned),
		"loadouts": loadouts.duplicate(true),
		"technique": technique,
		"traps": traps.duplicate(true),
		"trap_serial": trap_serial,
		"baits": baits.duplicate(),
		"xp": xp,
		"love": love,
		"pity": pity.duplicate(),
		"stats": stats.duplicate(),
		"clock_s": clock_s,
		"tea_at": tea_at,
		"requests": requests.duplicate(true),
		"request_serial": request_serial,
		"request_day": request_day,
		"reroll_day": reroll_day,
		"letters": letters,
		"letter_at": letter_at,
		"map_pieces": map_pieces,
		"keeper": keeper,
	}


## Sözlükten kayıt. Alanların türü bozuksa (elle değiştirilmiş ya da hatalı kayıt) o alan
## varsayılana döner, gerisi korunur: tek bir bozuk değer bütün ilerlemeyi sildirmez.
static func from_dict(raw: Dictionary) -> SaveData:
	var d := migrate(raw)
	var s := SaveData.new()
	s.player_id = _text(d, "player_id", "")
	s.created_unix = _int(d, "created_unix", 0)
	s.last_seen_unix = _int(d, "last_seen_unix", 0)
	s.coins = maxi(0, _int(d, "coins", 0))
	s.seed = maxi(0, _int(d, "seed", 0))
	s.session = maxi(0, _int(d, "session", 0))
	s.records = _records(d.get("records", {}))
	s.casts = maxi(0, _int(d, "casts", 0))
	s.catches = maxi(0, _int(d, "catches", 0))
	s.hint_step = maxi(0, _int(d, "hint_step", 0))
	var raw_flags: Variant = d.get("flags", {})
	if typeof(raw_flags) == TYPE_DICTIONARY:
		s.flags = (raw_flags as Dictionary).duplicate()
	var raw_settings: Variant = d.get("settings", {})
	if typeof(raw_settings) == TYPE_DICTIONARY:
		s.settings = (raw_settings as Dictionary).duplicate()
	var character := _text(d, "character", "rogue")
	s.character = character if not character.is_empty() else "rogue"
	s.bucket = _bucket(d.get("bucket", []))
	s.owned = _ids(d.get("owned", []))
	s.loadouts = _loadouts(d.get("loadouts", {}))
	var technique := _text(d, "technique", "float")
	s.technique = technique if not technique.is_empty() else "float"
	s.traps = _traps(d.get("traps", []))
	s.trap_serial = maxi(0, _int(d, "trap_serial", 0))
	# Tuzak kimliğiyle bulunur (dokunma, toplama, kaldırma): sayaç kurulu tuzakların kimliğinin üstünde
	# kalmalı, yoksa yeni tuzak eskisinin kimliğini alır (elle düzenlenmiş ya da bozuk kayıt).
	for trap in s.traps:
		s.trap_serial = maxi(s.trap_serial, int(trap["id"]) + 1)
	s.baits = _counts(d.get("baits", {}))
	s.xp = maxi(0, _int(d, "xp", 0))
	s.love = maxi(0, _int(d, "love", 0))
	s.pity = _counts(d.get("pity", {}))
	s.stats = _counts(d.get("stats", {}))
	s.clock_s = maxi(0, _int(d, "clock_s", 0))
	s.tea_at = maxi(-1, _int(d, "tea_at", -1))
	s.requests = _requests(d.get("requests", []))
	s.request_serial = maxi(0, _int(d, "request_serial", 0))
	s.request_day = maxi(-1, _int(d, "request_day", -1))
	s.reroll_day = maxi(-1, _int(d, "reroll_day", -1))
	s.letters = clampi(_int(d, "letters", 0), 0, MAX_LETTERS)
	s.letter_at = maxi(0, _int(d, "letter_at", 0))
	s.map_pieces = clampi(_int(d, "map_pieces", 0), 0, MAX_MAP_PIECES)
	s.keeper = maxi(0, _int(d, "keeper", 0))
	return s


## Kayıt bu yapının bilmediği daha yeni bir sürümden mi (eski bir yapı yüklendiyse)?
static func is_newer(raw: Dictionary) -> bool:
	return _int(raw, "version", 0) > VERSION


## Eski sürüm kayıtları güncel biçime getirir. Her sürüm için bir adım (v1 ilk sürüm).
static func migrate(raw: Dictionary) -> Dictionary:
	var d := raw.duplicate(true)
	var v := _int(d, "version", 0)
	if v < 1:
		v = 1
	if v < 2:
		# v2 (H2 dükkân): tek "rod" alanı gitti. v1'de yalnızca bambu olta vardı; o da başlangıç
		# takımında (rod_bamboo), yani hep sahipli ve boş kuşanılmışta zaten seçili. Kova, takım,
		# yem, rütbe puanı, göl sevgisi ve sayaçlar boş başlar; bütün balık kayıtları korunur.
		d.erase("rod")
		for key: String in ["bucket", "owned"]:
			if not d.has(key):
				d[key] = []
		for key: String in ["loadouts", "baits", "pity", "stats"]:
			if not d.has(key):
				d[key] = {}
		v = 2
	if v < 3:
		# v3 (Dalga 2, büyük göl): rütbeler bölgeleri açtığı için rütbe eğrisi uzadı. Puan yeni
		# eğriye taşınır: oyuncunun rütbesi ve rütbesindeki ilerlemesi aynı kalır.
		d["xp"] = remap_xp(_int(d, "xp", 0), XP_CURVE_V2, XP_CURVE_V3)
		v = 3
	if v < 4:
		# v4 (Dalga 3, teknikler): makara ve misina her teknikte ortak; şamandıranın setindekiler
		# "shared" setine taşınır (kuşanılan takım aynı kalır). Elindeki teknik şamandıra; tuzak yok.
		var loadouts: Variant = d.get("loadouts", {})
		if typeof(loadouts) == TYPE_DICTIONARY:
			var float_set: Variant = (loadouts as Dictionary).get("float", {})
			if typeof(float_set) == TYPE_DICTIONARY:
				var shared := {}
				for slot: String in ["reel", "line"]:
					if (float_set as Dictionary).has(slot):
						shared[slot] = (float_set as Dictionary)[slot]
						(float_set as Dictionary).erase(slot)
				if not shared.is_empty():
					(loadouts as Dictionary)["shared"] = shared
		d["technique"] = "float"
		d["traps"] = []
		d["trap_serial"] = 0
		v = 4
	if v < 5:
		# v5 (Dalga 4, canlı dünya): oyun saati sabahtan başlar; istek, mektup ve harita parçası yok.
		# İlk şişe şimdiki balık sayısından sayılır (eski oyuncu da onu yeni balıklarla bulur);
		# tuzaklarda çöp yok (sanitize: trash "").
		d["clock_s"] = 0
		d["tea_at"] = -1
		d["requests"] = []
		d["request_serial"] = 0
		d["request_day"] = -1
		d["reroll_day"] = -1
		d["letters"] = 0
		d["letter_at"] = maxi(0, _int(d, "catches", 0))
		d["map_pieces"] = 0
		d["keeper"] = 0
		v = 5
	d["version"] = v
	return d


## Rütbe puanını bir eğriden ötekine taşır: rütbe ve rütbedeki ilerleme oranı korunur; en yüksek
## rütbenin ötesindeki puan son aralığın oranıyla büyür.
static func remap_xp(xp: int, from: Array[int], to: Array[int]) -> int:
	if xp <= 0:
		return xp
	var last := from.size() - 1
	for r in last:
		if xp < from[r + 1]:
			var part := float(xp - from[r]) / float(from[r + 1] - from[r])
			return to[r] + floori(part * float(to[r + 1] - to[r]))
	var scale := float(to[last] - to[last - 1]) / float(from[last] - from[last - 1])
	return to[last] + floori(float(xp - from[last]) * scale)


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
		var count := maxi(0, _int(e, "count", 0))
		if count <= 0:
			continue
		out[str(key)] = {
			"count": count,
			"best_cm": maxi(0, _int(e, "best_cm", 0)),
			"best_stars": clampi(_int(e, "best_stars", 1), 1, 5),
			"first_unix": maxi(0, _int(e, "first_unix", 0)),
			"released": clampi(_int(e, "released", 0), 0, count),
		}
	return out


## Kova satırları: balık kimliği yazı, boy ve yıldız sayı olmalı; bozuk satır düşer.
static func _bucket(raw: Variant) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if typeof(raw) != TYPE_ARRAY:
		return out
	for entry: Variant in raw:
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		var e: Dictionary = entry
		var fish := _text(e, "fish", "")
		var size := _int(e, "size_cm", 0)
		if fish.is_empty() or size <= 0:
			continue
		out.append({ "fish": fish, "size_cm": size, "stars": clampi(_int(e, "stars", 1), 1, 5) })
	return out


## Tekrarsız kimlik listesi (yazı olmayan ve boş öğeler düşer).
static func _ids(raw: Variant) -> PackedStringArray:
	var out := PackedStringArray()
	if typeof(raw) != TYPE_ARRAY:
		return out
	for item: Variant in raw:
		if typeof(item) == TYPE_STRING and not str(item).is_empty() and not str(item) in out:
			out.append(str(item))
	return out


## Teknik -> { yuva: kimlik }; yazı olmayan değerler düşer.
static func _loadouts(raw: Variant) -> Dictionary:
	var out := {}
	if typeof(raw) != TYPE_DICTIONARY:
		return out
	for technique: Variant in raw:
		var slots: Variant = (raw as Dictionary)[technique]
		if typeof(slots) != TYPE_DICTIONARY:
			continue
		var clean := {}
		for slot: Variant in slots:
			var id: Variant = (slots as Dictionary)[slot]
			if typeof(id) == TYPE_STRING and not str(id).is_empty():
				clean[str(slot)] = str(id)
		out[str(technique)] = clean
	return out


## Tuzaklar: bölgesi yazı, yeri sayı, zamanları sıfır ya da pozitif olmalı; içerik satırları kova
## gibi ayıklanır; bozuk tuzak ve kimliği öncekiyle aynı olan tuzak düşer.
static func _traps(raw: Variant) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if typeof(raw) != TYPE_ARRAY:
		return out
	var ids := {}
	for entry: Variant in raw:
		if typeof(entry) != TYPE_DICTIONARY or out.size() >= MAX_TRAPS:
			continue
		var e: Dictionary = entry
		var zone := _text(e, "zone", "")
		var x: Variant = e.get("x")
		var z: Variant = e.get("z")
		if zone.is_empty() or not typeof(x) in [TYPE_INT, TYPE_FLOAT] or not typeof(z) in [TYPE_INT, TYPE_FLOAT] \
				or not is_finite(float(x)) or not is_finite(float(z)):
			continue
		var id := maxi(0, _int(e, "id", 0))
		if ids.has(id):
			continue
		ids[id] = true
		var items := _bucket(e.get("items", []))
		if items.size() > MAX_TRAP_ITEMS:
			items.resize(MAX_TRAP_ITEMS)
		out.append({
			"id": id,
			"zone": zone,
			"x": float(x),
			"z": float(z),
			"placed_unix": maxi(0, _int(e, "placed_unix", 0)),
			"last_unix": maxi(0, _int(e, "last_unix", 0)),
			"progress_s": maxi(0, _int(e, "progress_s", 0)),
			"items": items,
			# Tuzağa giren çöp (v5; kurulunca belli, boşsa yok).
			"trash": _text(e, "trash", ""),
		})
	return out


## İstekler: türü (kind) yazı olmalı; yuva 0..MAX_REQUESTS-1 ve tekrarsız; hedef en az 1, ilerleme
## 0..hedef; istenenler (want) yazı ya da sıfır/pozitif sayı; ödül sıfır/pozitif sayılar.
static func _requests(raw: Variant) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if typeof(raw) != TYPE_ARRAY:
		return out
	var slots := {}
	for entry: Variant in raw:
		if typeof(entry) != TYPE_DICTIONARY or out.size() >= MAX_REQUESTS:
			continue
		var e: Dictionary = entry
		var kind := _text(e, "kind", "")
		var slot := _int(e, "slot", -1)
		if kind.is_empty() or slot < 0 or slot >= MAX_REQUESTS or slots.has(slot):
			continue
		slots[slot] = true
		var want := {}
		var raw_want: Variant = e.get("want", {})
		if typeof(raw_want) == TYPE_DICTIONARY:
			for key: Variant in raw_want:
				var value: Variant = (raw_want as Dictionary)[key]
				if typeof(value) == TYPE_STRING:
					want[str(key)] = str(value)
				elif typeof(value) in [TYPE_INT, TYPE_FLOAT] and int(value) >= 0:
					want[str(key)] = int(value)
		var goal := maxi(1, _int(e, "goal", 1))
		out.append({
			"slot": slot,
			"kind": kind,
			"want": want,
			"goal": goal,
			"progress": clampi(_int(e, "progress", 0), 0, goal),
			"day": maxi(0, _int(e, "day", 0)),
			"serial": maxi(0, _int(e, "serial", 0)),
			"reward": _counts(e.get("reward", {})),
		})
	return out


## Kimlik -> sıfır ya da pozitif tamsayı; bozuk değerler düşer.
static func _counts(raw: Variant) -> Dictionary:
	var out := {}
	if typeof(raw) != TYPE_DICTIONARY:
		return out
	for key: Variant in raw:
		var holder := { "v": (raw as Dictionary)[key] }
		var n := _int(holder, "v", -1)
		if n >= 0:
			out[str(key)] = n
	return out


## Tamsayı alan: sayı ya da sayı yazısı değilse varsayılan (int(null) betiği durdurur).
static func _int(d: Dictionary, key: String, fallback: int) -> int:
	var v: Variant = d.get(key, fallback)
	match typeof(v):
		TYPE_INT, TYPE_FLOAT:
			return int(v)
		TYPE_STRING:
			var text: String = v
			return text.to_int() if text.is_valid_int() else fallback
	return fallback


## Yazı alan: yazı değilse varsayılan.
static func _text(d: Dictionary, key: String, fallback: String) -> String:
	var v: Variant = d.get(key, fallback)
	return str(v) if typeof(v) == TYPE_STRING else fallback
