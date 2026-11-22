class_name Bosses
extends RefCounted
## Bölge canavarları (yapı 5; testçi: "her bölgenin bölge sonu canavarı olsun; yalnızca o bölgenin etkili oltasıyla ve
## takım son seviyeye kadar kasılınca tutulsun; oyun yine Bekçi'yle bitsin"; Ersin'in seçimi "6 canavar, final için
## şart"; docs/gdd.md §10.9). Saf: kayıt ve içerik parametre.
##
## Her bölgenin bir canavarı var (fish.json boss: bölgenin kimliği; story: zarla gelmez, oyun çağırır; release_only:
## tutulunca göle bırakılır, satılmaz). Canavar şu hâlde çıkar (due):
##   - bölgenin canavarı henüz tutulmadı (kayıttan türer: records; ayrı alan yok),
##   - balıkçı o bölgede avlanıyor ve elindeki teknik bölgenin etkili tekniği (ContentDB effective),
##   - canavarın istediği takımın hepsi kuşanılı (fight.gear: kamış, küçük takım, makara, misina; ReelModel.missing_gear),
##   - atışın zarı tutar (CHANCE_PPM; zar kaydın seed'inden ve atış sayısından: Dice.derive(seed, SALT, atış)).
## Kaçarsa RETURN_S sonra yine gelir (oyuncu bölgede ve takımı aynıyken); tutulunca ödülü (fish.json reward) ve göle
## bırakılır. Altısı tutulunca final hazır olabilir (Secret.final_ready).

## Canavarların kimlikleri (bölgelerin sırasıyla; değişmez: Secret.final_ready içeriksiz bakar; test_bosses
## fish.json'la karşılaştırır).
const IDS: Array[String] = ["pier_king", "reed_baron", "lily_queen", "rock_jaw", "stream_ghost", "deep_lord"]
## Atışın zarının tuzu (öteki zarları kaydırmaz).
const SALT := 9311
## Koşullar tutunca bir atışta canavarın çıkma şansı (ppm).
const CHANCE_PPM := 350000
## Canavarın boy yüzdeliği (5★).
const PERCENTILE := 925000
## Kaçan canavar bu kadar sn sonra yine gelir (sunum ve denge botu).
const RETURN_S := 20.0
## Belirdiği yer: takımdan bu uzaklıklarda (m), balıkçıdan takıma bakan yönün bu açılarıyla (derece) sapan yönlerde;
## takımın bölgesinin derin suyu, balıkçıya en az NEAR uzakta.
## Önce yanlar (ekranda takımın sağı ya da solu; arkası ekranın üst kenarına düşebilir).
const FROM: Array[float] = [3.5, 4.5, 3.0, 5.5]
const TURN: Array[float] = [70.0, -70.0, 45.0, -45.0, 110.0, -110.0, 0.0, 140.0, -140.0, 180.0]
const NEAR := 3.0


## Bölgenin canavarının kimliği (yoksa "").
static func of_zone(db: ContentDB, zone_id: String) -> String:
	return db.boss_of(zone_id)


## Canavar tutuldu mu (kayıtta rekoru var)?
static func caught(save: SaveData, boss_id: String) -> bool:
	return not boss_id.is_empty() and save.records.has(boss_id)


## Gölün canavarları (bölgelerin sırasıyla).
static func all_of(db: ContentDB, spot_id: String) -> Array[String]:
	var out: Array[String] = []
	for z in db.zones_of(spot_id):
		var id := db.boss_of(str(z["id"]))
		if not id.is_empty():
			out.append(id)
	return out


## Kaç canavar tutuldu.
static func caught_count(db: ContentDB, save: SaveData, spot_id: String) -> int:
	var n := 0
	for id in all_of(db, spot_id):
		if caught(save, id):
			n += 1
	return n


## Bütün canavarlar tutuldu mu (final için şart: Secret.final_ready)?
static func all_caught(save: SaveData) -> bool:
	for id in IDS:
		if not caught(save, id):
			return false
	return true


## Canavarın istediği takımdan kuşanılmamış olanlar (kimlikler; hepsi kuşanılıysa boş).
static func missing(db: ContentDB, boss_id: String, gear: GearStats) -> Array[String]:
	var def := db.fish_by_id(boss_id)
	if def.is_empty():
		return []
	return ReelModel.missing_gear(def["fight"], gear)


## Canavarın tekniği (bölgesinin etkili tekniği).
static func technique_of(db: ContentDB, spot_id: String, boss_id: String) -> String:
	var def := db.fish_by_id(boss_id)
	if def.is_empty():
		return ""
	return str(db.zone(spot_id, str(def["boss"])).get("effective", ""))


## Koşullar tutuyor mu (zarı saymadan): canavar tutulmadı, bölge açık, teknik etkili, takım tam.
static func ready(db: ContentDB, save: SaveData, spot_id: String, zone_id: String, technique: String,
		gear: GearStats) -> bool:
	var id := db.boss_of(zone_id)
	if id.is_empty() or caught(save, id):
		return false
	var z := db.zone(spot_id, zone_id)
	if z.is_empty() or not Zones.unlocked(db, save, z):
		return false
	return technique == str(z.get("effective", "")) and missing(db, id, gear).is_empty()


## Bu atışta canavar çıkar mı (koşullar ve atışın zarı)? cast: kaydın atış sayısı (save.casts).
static func due(db: ContentDB, save: SaveData, spot_id: String, zone_id: String, technique: String, gear: GearStats,
		cast: int) -> bool:
	return ready(db, save, spot_id, zone_id, technique, gear) and roll(save, cast)


## Atışın zarı (CHANCE_PPM).
static func roll(save: SaveData, cast: int) -> bool:
	var rng := RandomNumberGenerator.new()
	rng.seed = Dice.derive(save.seed, SALT, cast)
	return Dice.chance(rng, CHANCE_PPM)


## Canavarın belirdiği yer: takımdan (rig) FROM uzaklıklarında, balıkçıdan (angler) takıma bakan yönden TURN
## açılarıyla sapan yönlerde; takımın bölgesinin derin suyu (bölgenin min_depth'i), balıkçıya en az NEAR. Yer yoksa
## Dice.NO_POINT.
static func rise_point(db: ContentDB, spot_id: String, angler: Vector2, rig: Vector2) -> Vector2:
	var lake := db.lake(spot_id)
	var k := lake.zone_at(rig)
	if k < 0:
		return Dice.NO_POINT
	var depth := float(db.zone(spot_id, lake.zone_ids[k]).get("min_depth", db.rules.min_depth))
	var to := rig - angler
	var dir := to.normalized() if to.length_squared() > 0.0001 else Vector2(0.0, -1.0)
	for d: float in FROM:
		for turn: float in TURN:
			var p := rig + dir.rotated(deg_to_rad(turn)) * d
			if lake.zone_at(p) == k and lake.is_deep(p, depth) and p.distance_to(angler) >= NEAR:
				return p
	return Dice.NO_POINT


## Geliştirme ve testler: bütün canavarlar tutulmuş sayılır (defterde birer kayıt; boy canavarın en küçüğü).
static func debug_catch_all(db: ContentDB, save: SaveData) -> void:
	for id in IDS:
		if not caught(save, id):
			var def := db.fish_by_id(id)
			var size := (def["size_cm"] as Vector2i).x if not def.is_empty() else 100
			Records.add(save.records, id, size, 5, 0)


## Tutulan canavarın ödülü (para; fish.json reward).
static func reward(db: ContentDB, boss_id: String) -> int:
	return int(db.fish_by_id(boss_id).get("reward", 0))
