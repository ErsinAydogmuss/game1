class_name Secret
extends RefCounted
## Gölün Sırrı (Dalga 4, 5. adım; docs/gdd.md §10.5). Genç Nine ile Dede'nin gölün iki yakasından şişelerle
## gönderdiği altı mektup, Dede'nin altın isteklerinden dört harita parçası (Requests.offer_golden) ve göl
## sevgisinden Nine'nin altın hamuru; üçü tamamlanınca final hazır (Gölün Bekçisi, 6. adım). Saf mantık: oyun,
## defter ve denge botu aynı kuralı kullanır. Kayıtta okunan mektup sayısı (letters), sıradaki şişenin
## sayıldığı balık (letter_at), harita parçaları (map_pieces) ve altın hamurun bayrağı. Süresi dolan ya da
## kaybolan bir şey yok (gelir kuralı 7): şişe alınana kadar suda bekler.

## Mektuplar, okunma sırasıyla: şişenin çıktığı bölge ve rütbesi (her bölgeden bir; sonuncusu sandalla).
const LETTERS: Array[Dictionary] = [
	{ "zone": "reeds", "rank": 3 },
	{ "zone": "dock_cove", "rank": 4 },
	{ "zone": "lily_cove", "rank": 6 },
	{ "zone": "rocky_point", "rank": 8 },
	{ "zone": "stream_mouth", "rank": 10 },
	{ "zone": "deep_water", "rank": 12 },
]
## İki mektup arasında en az bu kadar balık (ilki yeni oyunun ya da v5 göçünün başından sayılır).
const LETTER_GAP := 15
## Şişenin yeri: bölgenin atış noktasından bu uzaklıklarda (m, sırayla denenir) bölgenin suyuna doğru, kıyıdan
## en az BOTTLE_SHORE içeride; sandal bölgesinde ilk şamandıranın yanında (BOTTLE_BUOY; sandal şamandıranın
## kamera tarafına bağlanır, şişe şamandıranın yanında görünür ve sandaldan uzanılır).
const BOTTLE_RANGE: Array[float] = [3.0, 2.6, 3.4, 2.2, 3.8]
const BOTTLE_BUOY: Array[float] = [1.8, 2.2, 1.4]
const BOTTLE_SHORE := 0.6
## Altın hamur: göl sevgisinin bu seviyesinde Nine verir (dükkâna uğrayınca; bayrak kayıtta).
const DOUGH_LOVE := 6
const DOUGH_FLAG := "golden_dough"


## Sıradaki mektubun sırası (0'dan; hepsi okunduysa -1).
static func next_letter(save: SaveData) -> int:
	return save.letters if save.letters < LETTERS.size() else -1


## Suda bir şişe var mı: sıradaki mektubun rütbesi geldi, son mektuptan beri LETTER_GAP balık tutuldu ve
## şişenin bölgesi açık (derin orta sandal ister). Bölgesi olmayan gölde (testlerin gölü) şişe yok.
static func bottle_due(db: ContentDB, save: SaveData, spot_id: String) -> bool:
	var i := next_letter(save)
	if i < 0:
		return false
	var letter := LETTERS[i]
	if Rank.rank(db, save) < int(letter["rank"]) or save.catches - save.letter_at < LETTER_GAP:
		return false
	var zone := db.zone(spot_id, str(letter["zone"]))
	return not zone.is_empty() and Zones.unlocked(db, save, zone)


## Sıradaki şişenin bölgesi (hepsi okunduysa boş).
static func bottle_zone(save: SaveData) -> String:
	var i := next_letter(save)
	return str(LETTERS[i]["zone"]) if i >= 0 else ""


## Şişenin yeri (xz; hep aynı): bölgenin atış noktasından bölgenin suyunun ortasına bakan yönden başlayıp 15°'lik
## adımlarla iki yana, BOTTLE_RANGE uzaklıklarında o bölgenin suyu (kıyıdan en az BOTTLE_SHORE, iskelenin
## dışında); sandal bölgesinde ilk şamandıranın +x yanından başlar. Yer yoksa Dice.NO_POINT.
static func bottle_point(db: ContentDB, spot_id: String, zone_id: String) -> Vector2:
	var zone := db.zone(spot_id, zone_id)
	if zone.is_empty():
		return Dice.NO_POINT
	var lake := db.lake(spot_id)
	var k := lake.zone_index(zone_id)
	if k < 0:
		return Dice.NO_POINT
	var center := Dice.NO_POINT
	var dir0 := Vector2(1, 0)
	var distances := BOTTLE_RANGE
	if bool(zone["boat"]):
		var buoys: Array[Vector2] = zone["buoys"]
		if not buoys.is_empty():
			center = buoys[0]
			distances = BOTTLE_BUOY
	else:
		var stands: Array[Vector2] = zone["stands"]
		if not stands.is_empty():
			center = stands[0]
			var toward := lake.zone_centers[k] - center if k < lake.zone_centers.size() else Vector2.ZERO
			if toward.length_squared() > 0.0001:
				dir0 = toward.normalized()
	if not Dice.is_point(center):
		return Dice.NO_POINT
	for i in 24:
		var dir := dir0.rotated(deg_to_rad(15.0 * ((i + 1) >> 1)) * (1.0 if i % 2 == 1 else -1.0))
		for d: float in distances:
			var p := center + dir * d
			if lake.is_water(p) and not lake.on_dock(p, 0.5) and lake.shore_distance(p) >= BOTTLE_SHORE \
					and lake.zone_at(p) == k:
				return p
	return Dice.NO_POINT


## Şişe alındı, mektup okundu: sayaç bir artar, sıradaki şişe bundan sonraki balıklarla sayılır. Döner: okunan
## mektubun numarası (1..6; şişe yoksa 0).
static func read_letter(db: ContentDB, save: SaveData, spot_id: String) -> int:
	if not bottle_due(db, save, spot_id):
		return 0
	save.letters += 1
	save.letter_at = save.catches
	return save.letters


## Mektubun çeviri anahtarları: yazısı, başlığı ve imzası (numara 1..6).
static func letter_key(n: int) -> String:
	return "LETTER_%d" % n


static func letter_title_key(n: int) -> String:
	return "LETTER_%d_TITLE" % n


static func letter_from_key(n: int) -> String:
	return "LETTER_%d_FROM" % n


## Mektubu kim yazdı ("nine" ya da "dede"): tek numaralı mektuplar Nine'nin, çiftler Dede'nin (karşılıklı).
static func letter_writer(n: int) -> String:
	return "nine" if n % 2 == 1 else "dede"


## Altın hamur Nine'de mi bekliyor (göl sevgisi DOUGH_LOVE ve henüz verilmedi)?
static func dough_due(db: ContentDB, save: SaveData) -> bool:
	return not has_dough(save) and LakeLove.level(db.rules, save.love) >= DOUGH_LOVE


static func has_dough(save: SaveData) -> bool:
	return bool(save.flags.get(DOUGH_FLAG, false))


## Nine altın hamuru verir (bir kez). Verdiyse true.
static func give_dough(db: ContentDB, save: SaveData) -> bool:
	if not dough_due(db, save):
		return false
	save.flags[DOUGH_FLAG] = true
	return true


## Final hazır mı: altı mektup, dört harita parçası ve altın hamur (6. adım: sisli gece, derin orta, Bekçi).
static func final_ready(save: SaveData) -> bool:
	return save.letters >= LETTERS.size() and save.map_pieces >= SaveData.MAX_MAP_PIECES and has_dough(save)
