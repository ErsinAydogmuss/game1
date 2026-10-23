class_name Secret
extends RefCounted
## Gölün Sırrı (Dalga 4, 5. adım; docs/gdd.md §10.5). Genç Nine ile Dede'nin gölün iki yakasından şişelerle
## gönderdiği altı mektup, Dede'nin altın isteklerinden dört harita parçası (Requests.offer_golden) ve göl
## sevgisinden Nine'nin altın hamuru; üçü tamamlanınca final hazır (Gölün Bekçisi, 6. adım). Saf mantık: oyun,
## defter ve denge botu aynı kuralı kullanır. Kayıtta okunan mektup sayısı (letters), sıradaki şişenin
## sayıldığı balık (letter_at), harita parçaları (map_pieces) ve altın hamurun bayrağı. Süresi dolan ya da
## kaybolan bir şey yok (gelir kuralı 7): şişe alınana kadar suda bekler.
##
## Final (6. adım): Gölün Bekçisi haritanın X'inde (derin ortanın KEEPER_BUOY şamandırası) sisli bir gecede,
## altın hamurlu dip takımına gelir (keeper_due). Final hazırken Bekçi bırakılana kadar her gece sisli
## (Weather.at: keeper_night); bırakılınca (WorldState.release → release_keeper) geceler eski havasına döner,
## Bekçi kendiliğinden sisli gecelerde X'te yine çıkabilir (günde bir; filmsiz).

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
## Şişeye uzanma payı (m): balıkçı (ya da sandal) bu kadar yakındayken şişeyi alır; her şişe kıyı yolunun ya da
## ilk şamandıraya bağlanan sandalın bu kadar yakınında (test_secret).
const REACH := 5.0
## Altın hamur: göl sevgisinin bu seviyesinde Nine verir (dükkâna uğrayınca; bayrak kayıtta).
const DOUGH_LOVE := 6
const DOUGH_FLAG := "golden_dough"
## Gölün Bekçisi: hikâyenin balığı (fish.json story; hiçbir bölgenin tablosunda yok, spots.json story_fish).
const KEEPER_ID := "keeper"
## Haritanın X'i: derin ortanın bu şamandırası (sandal ona bağlanınca Bekçi çıkabilir).
const KEEPER_BUOY := 0
## Bekçi'nin boy yüzdeliği (ppm; 5★, ~517 cm, gölgesi ~5 m): boyu hep aynı.
const KEEPER_PERCENTILE := 925000
## Bekçi sandaldan bu uzaklıklarda (m) belirir, takıma doğru bakan yönden bu açılarla (derece) sapan
## yönlerde (sırayla denenir; ilk uygun yer). X derin ortanın batı ucunda: derin su doğuya, gölün ortasına
## uzanır; takım başka yöne atıldıysa Bekçi çemberin öbür yanından gelir.
const KEEPER_FROM: Array[float] = [8.0, 7.0, 9.0, 6.0]
const KEEPER_TURN: Array[float] = [25.0, -25.0, 40.0, -40.0, 10.0, -10.0, 60.0, -60.0, 0.0, 80.0, -80.0, 100.0,
		-100.0, 120.0, -120.0, 140.0, -140.0, 160.0, -160.0, 180.0]
## Bekçi'nin belirdiği yer takımdan en az bu kadar (m) uzak: yaklaşırken görünsün.
const KEEPER_GAP := 3.0
## Bekçi'nin son bırakıldığı oyun günü (bayrak): aynı gün yeniden çıkmaz.
const KEEPER_DAY_FLAG := "keeper_day"
## Kaçan Bekçi bu kadar sn sonra yine gelir (sunum ve denge botu).
const KEEPER_RETURN_S := 25.0


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


## Final gecesi: final hazır ve Bekçi henüz bırakılmadı. Bu sürede her gece sisli (Weather.at): sisli gece
## kendiliğinden ~10 günde bir gelir, final için beklemek ceza gibi olmasın.
static func keeper_night(save: SaveData) -> bool:
	return save.keeper == 0 and final_ready(save)


## Bekçi çıkar mı: gece, sis, sandal X'te (at_x: derin ortanın KEEPER_BUOY şamandırasında), elindeki teknik
## dip (altın hamur dipte kullanılır) ve altın hamur var; ilk kez final hazırken, sonra (oyun sonrası) her
## sisli gecede ama bırakıldığı gün değil (day: şimdiki oyun günü).
static func keeper_due(save: SaveData, phase: String, weather: String, at_x: bool, technique: String, day: int) -> bool:
	if phase != "night" or weather != "fog" or not at_x or technique != "bottom" or not has_dough(save):
		return false
	if save.keeper == 0:
		return final_ready(save)
	return not released_on(save, day)


## Bekçi bu oyun gününde (gecesi dahil) göle bırakıldı mı (bayrak keeper_day)? O gün yeniden çıkmaz
## (keeper_due), bırakıldığı gece sabaha kadar sisli kalır (Weather.at: sis şafakta kalkar).
static func released_on(save: SaveData, day: int) -> bool:
	return save.keeper > 0 and int(save.flags.get(KEEPER_DAY_FLAG, -1)) == day


## Bekçi göle bırakıldı (WorldState.release): sayaç bir artar, bugün yeniden çıkmaz.
static func release_keeper(save: SaveData, day: int) -> void:
	save.keeper += 1
	save.flags[KEEPER_DAY_FLAG] = day


## Bekçi'nin gecesinin günü (release_keeper'ın günü): gece sürüyorsa bugün, değilse dün. Bekçi yalnızca gece
## çıkar; çekişme ya da kart şafağa taşınca bırakış sabaha düşer, gün yine o gecenin kalır (yoksa ertesi gece
## de sisli olurdu, fırtınası ve Kocabaş'ı gelmezdi; oyun sonrasında Bekçi o gece çıkmazdı).
static func night_day(rules: FishingRules, clock_s: int) -> int:
	var day := DayClock.day(rules, clock_s)
	return day if DayClock.phase(rules, clock_s) == "night" else maxi(0, day - 1)


## Haritanın X'i (derin ortanın KEEPER_BUOY şamandırası; yoksa Dice.NO_POINT).
static func keeper_x(db: ContentDB, spot_id: String) -> Vector2:
	for z in db.zones_of(spot_id):
		if bool(z["boat"]):
			var buoys: Array[Vector2] = z["buoys"]
			return buoys[KEEPER_BUOY] if KEEPER_BUOY < buoys.size() else Dice.NO_POINT
	return Dice.NO_POINT


## Bekçi'nin belirdiği yer: sandaldan (boat) takıma (rig) bakan yönden KEEPER_TURN açılarıyla sapan yönlerde,
## KEEPER_FROM uzaklıklarında takımın bölgesinin derin suyu (bölgenin min_depth'i), takımdan en az KEEPER_GAP
## uzakta (önce yön, sonra uzaklık). Yer yoksa Dice.NO_POINT.
static func keeper_point(db: ContentDB, spot_id: String, boat: Vector2, rig: Vector2) -> Vector2:
	var lake := db.lake(spot_id)
	var k := lake.zone_at(rig)
	if k < 0:
		return Dice.NO_POINT
	var depth := float(db.zone(spot_id, lake.zone_ids[k]).get("min_depth", db.rules.min_depth))
	var to := rig - boat
	var dir := to.normalized() if to.length_squared() > 0.0001 else Vector2(0.0, -1.0)
	for turn: float in KEEPER_TURN:
		for d: float in KEEPER_FROM:
			var p := boat + dir.rotated(deg_to_rad(turn)) * d
			if lake.zone_at(p) == k and lake.is_deep(p, depth) and p.distance_to(rig) >= KEEPER_GAP:
				return p
	return Dice.NO_POINT
