class_name SessionSim
extends RefCounted
## Denge botu (docs/gdd.md §8 ve §10.4): oyuncuyu istatistiksel olarak taklit eder; tools/
## economy_report.gd ve test_session_sim.gd korkulukları kullanır. Oyunun kurallarını aynen
## kullanır, yalnızca zamanı ve el becerisini taklit eder:
## 1. Atış, gölgenin gelmesi ve dürtmeler: data/sim.json'daki süreler (zarla).
## 2. Tür ve boy: oyunun zarları (CatchOdds, şans garantisi, FishTable), kuşanılan yemle. Fark:
##    oyunda garanti tek bir gölge doğurur (oyuncu önce başka bir gölgeyi tutabilir); bot garantiyi
##    sıradaki ısırmaya uygular. 40 avda Nadir gelmeme olasılığı ~%0,4: ekonomiye etkisi yok.
## 3. Isırmada kaçırma: miss_ppm. Takılınca yem harcanır (Economy.use_bait).
## 4. Çekişme: ReelModel kuşanılan takımla ve balığın boyuyla (fazla iri kaçar), ReelBot (tepkili
##    oyuncu, reaction_s) oynar.
## 5. Tutulan balık: defter, şans garantisi sayaçları, rütbe puanı, kova (doluysa bırakılır).
## 6. Kova dolunca Nine'ye gider (sell_s), hepsini satar, alışveriş yapar (shop). Kova doluyken
##    atmaz (oyunda SAT): tuzaktan gelen kerevitler kovayı doldurduysa atıştan önce yine satar.
## 7. Bölgeli göl: kıyı bölgesini oyuncu gibi seçer: önce gidilmemiş açık bölge (merak; yeni
##    bölge açılınca hemen gider), sonra defterde tutulmamış türü en çok olan, sonra balık başına
##    en çok kazandıran. Sandalı rütbesi yetince öncelikle alır (parası yetene kadar biriktirir),
##    sonra kovaların boat_share kadarını derin ortada doldurur. Bölge değiştirmek ve satmak için
##    iskeleye dönmek travel_s sürer; oranlar ve süreler (sim.json zones) bölgenin.
## 8. Teknikler (Dalga 3): yeni bir tekniğin ilk kamışı öncelikli (Dede haber verir, düğme atar:
##    oyuncu merak eder; rütbesi yetince parası yetene kadar biriktirir); sonraki kamışları ve küçük
##    takımı (yapay yem...) sıradan takım gibi. Her bölge seçiminden sonra elindeki tekniği seçer:
##    hiç denenmemiş teknik önce (merak); defterde olmayan, burada gelen bir tür varsa onu en çabuk
##    getiren (dakikada yeni tür); yoksa dakikada en çok kazandıran (tekniğin süreleriyle: sim.json
##    techniques). Teknik değiştirmek switch_s sürer; oranlar, şans garantisi ve süreler tekniğin.
## 9. Kerevit tuzağı (rütbe 3): ilk tuzak öncelikli (Dede haber verir); sonrakiler sıradan takım gibi.
##    Her satıştan sonra tuzağına kerevit girmiş olan toplanır (kova boşken; tuzağın bölgesine gidilir),
##    boştaki tuzak sazlığın atış noktasının yakınına bırakılır (yer kalmazsa açık başka bir tuzak
##    bölgesine); tuzak başına trap_s. Tuzaklar botun oyun süresiyle dolar (TrapSim; şimdi = geçen sn).
## 10. Canlı dünya (Dalga 4): oyun saati botun geçen süresinden akar (dükkân, takım çantası, harita ve
##    kararma sürerken durur: sell_s, switch_s, travel_s sayılmaz); her atışın oranı, şans garantisi ve
##    sayacı gölün o anki koşuluyla (WorldState: vakit, hava, sevgi); yağmurda balık daha çabuk gelir
##    (sim.json weather, yoksa rules.json rain_approach'ın tersi). Yalnızca belli vakitte gelen türü (Ay
##    Turnası) o vakitte kovalar (bölge ve teknik seçimi); bölgenin balık başına değeri koşulsuz (vakit ve
##    hava kazancı ±%5'te tutar: test_economy); vakit değişince bölgeyi ve tekniği yeniden seçer. Vakitlerde
##    ve havalarda geçen süre: phase_time, weather_time.
## 11. Tut-bırak ve çöp (Dalga 4): satıştan hemen önce değeri sim.json release_value_max'ı geçmeyen balıklar
##    göle bırakılır (rütbe release_from_rank'ten sonra: oyuncu önce takım için her şeyi satar, sonra küçük
##    balığı satmak yerine bırakır: göl sevgisi; 0 ise hiç); dolu kovaya gelen balık da bırakılır. Dipte tutulan balığın yanında ve tuzaktan gelen çöp toplanır (Trash; zarı botun
##    kendi tuzlu zarı: oranları ve sırayı kaydırmaz). Göl sevgisi oranlara girer (Nadir+); seviyelerin ilk
##    dakikası love_<seviye>.
## 12. Dede'nin istekleri (Dalga 4): yeni günde boş yuvalar dolar (rütbe 2'den sonra; oyuncu Bugün paneline
##    bakar: request_s, saat durur); günde bir, dünden kalan bir istek değiştirilir (önce hiç ilerlemeyen, sonra
##    en eski; yağmurlu günde yağmur isteği değil). Oyunun olayları (av, bırakma, çöp, tuzaktan her kerevit) isteklere
##    sayılır; biten istek oyundaki gibi öder (para earned'e de girer: saatte para; rütbe puanı, göl sevgisi).
##    Bot istekleri kovalamaz (bölge ve teknik seçimi aynı); ucuz balık bıraktığı rütbeden sonra bırakma isteği
##    varken satıştan önce kalanı kadar en ucuz balığı bırakır (daha önce bırakma isteği takılır ve değiştirilir:
##    her rütbede bırakan bot erken alışverişleri geciktiriyordu). İlk biten istek request_1, onuncusu
##    requests_10.
## 13. Gölün Sırrı (Dalga 4, 5. adım): suda şişe varsa (bildirim, haritada işaret, Dede söyler) oyuncu gidip alır:
##    şişenin bölgesine gidilir (travel_s), şişe alınır (bottle_s) ve mektup okunur (letter_s; panel açıkken saat
##    durur), sonra avlandığı bölgeye döner. Altın istek gelebiliyorsa altın yuvaya gelir (Bugün paneline bakılır).
##    Altın av isteği vakti ve havası gelince kovalanır (oyuncu haritanın parçasını ister): bölgesi seçilir, tekniği
##    ya da türünü en çok getiren teknik ele alınır (akşam nilüferli koyda turna, gece derin ortada diple yayın);
##    bırakma isteği günlük bırakma isteği gibi satıştan önce en ucuz balıklarla. Göl sevgisi 6'da Nine altın hamuru
##    verir (satışta, dükkân açıkken). İlk dakikalar: letter_<n>, golden_<parça> (altın istek geldi), piece_<parça>,
##    dough, final_ready (altı mektup, dört parça, altın hamur).
## 14. Final (Dalga 4, 6. adım): final gecesinde gece olunca oyuncu sandalla X'e (derin orta) gider, dibe atar: Gölün
##    Bekçisi gelir (keeper_s), dalışlarıyla çekişir (ReelModel, ReelBot); tutulunca göle bırakılır (final biter),
##    bitiş filmi ve jenerik (ending_s; saat durur), şafakta sonraki sabah. Kaçarsa Secret.KEEPER_RETURN_S bekleyip
##    yeniden atar. İlk dakikası "keeper". Oyun sonrası Bekçi kovalanmaz.
## Aynı seed aynı sonucu verir.

const SIM_PATH := "res://data/sim.json"
## Botun çöp zarının tuzu (dipte balığın yanında; oyunda gölgenin seed'i).
const TRASH_SALT := 9161
## Alışverişe giren kategoriler (yem alınmaz: bot solucanla avlanır). Öteki tekniklerin kamışları
## ("rod:<teknik>") ve küçük takımı ayrıca (_buy_categories).
const BUY_CATEGORIES: Array[String] = ["rod", "reel", "line", "hook", "bobber", "bucket", "extra", "boat", "trap"]
## Teknik seçiminde defterde olmayan bir türün değeri (para cinsinden): kazançtan önce gelir.
const NEW_SPECIES_WORTH := 100000.0
## rate'in boy zarı: balığın ortalama değeri bu kadar eşit aralıklı örnekle hesaplanır.
const RATE_SAMPLES := 50
## Teknik seçiminde kovalanan altın isteğin değeri: yeni türden önce gelir (hiç denenmemiş teknikten sonra).
const GOLDEN_WORTH := 1.0e9
## Atıştan önce kova doluysa en çok bu kadar satış turu (satıştan sonra toplanan tuzaklar kovayı yine
## doldurabilir; her turda tuzaklar boşalır).
const SELL_ROUNDS := 4

var db: ContentDB
var save: SaveData
var spot_id: String
var timing: Dictionary
var rng := RandomNumberGenerator.new()
## Geçen oyun süresi (sn).
var elapsed: float = 0.0
var casts: int = 0
var catches: int = 0
var lost: int = 0
var sells: int = 0
var earned: int = 0
## Tuzaklardan toplanan kerevit.
var trapped: int = 0
## Göle bırakılan balık (satıştan önce ucuz olanlar, koruma altındakiler ve dolu kovaya gelenler), bunlardan
## kova dolu olduğu için bırakılan (bot doluyken atmaz: hep 0 olmalı) ve toplanan çöp.
var released: int = 0
var full_released: int = 0
var trash: int = 0
## Dede'nin günlük istekleri: biten istek, isteklerden gelen para (earned'in içinde) ve değiştirilen istek (altın
## istekler sayılmaz: parçaları save.map_pieces, parası earned'de).
var requests_done: int = 0
var request_coins: int = 0
var rerolls: int = 0
## Olayların ilk olduğu dakika: "rank_3", "buy" (ilk alışveriş), "buy:<takım>", "sell", "species_4",
## "rarity_<id>", "zone:<bölge>" (o bölgede ilk avlanış), "tech:<teknik>" (o teknikle ilk atış),
## "trap_set" (ilk tuzak bırakıldı), "trap" (tuzaktan ilk kerevit), "release" (ilk bırakılan balık), "trash"
## (ilk çöp), "love_<seviye>" (göl sevgisinin seviyesi), "requests" (ilk istekler), "request_1" (ilk biten
## istek), "requests_10" (onuncusu), "letter_<n>" (okunan mektup), "golden_<parça>" (altın istek geldi),
## "piece_<parça>" (harita parçası), "dough" (altın hamur), "final_ready", "keeper" (Gölün Bekçisi göle döndü).
var milestones: Dictionary = {}
## Botun elindeki teknik ve her teknikte geçen süre (sn).
var technique: String = "float"
var technique_time: Dictionary = {}
## Botun avlandığı bölge (bölgesiz gölde boş) ve dakika dakika her bölgede geçen süre (sn).
var zone_id: String = ""
var zone_time: Dictionary = {}
## Vakitlerde ve havalarda geçen süre (sn; rapor).
var phase_time: Dictionary = {}
var weather_time: Dictionary = {}
## Oyun saatinin durduğu süre (dükkân, takım çantası, harita; sn): saat = elapsed - _paused_s.
var _paused_s: float = 0.0
## Son atıştaki vakit: vakit değişince oyuncu gibi bölgesini ve tekniğini yeniden seçer (gece nilüferli
## koyda Ay Turnası; yoksa yalnızca satıştan sonra seçtiği için geceye denk gelmek şansa kalıyordu).
var _last_phase: String = ""

## Oranların geldiği yer: botun bölgesi (bölgesiz gölde gölün kendisi).
var _spot: Dictionary
## Başlangıç bölgesi (Nine'nin dükkânı orada) ve dolan kova sayısı (sandal sırası).
var _home: String = ""
var _trips: int = 0
## Bölge kimliği -> solucanla balık başına ortalama değer (bölge seçimi; bir kez hesaplanır).
var _zone_values: Dictionary = {}


func _init(content: ContentDB, spot: String, seed_value: int, sim_timing: Dictionary = {}) -> void:
	db = content
	spot_id = spot
	var start: Dictionary = Zones.at(db, spot, db.spot(spot)["start"])
	_spot = start if not start.is_empty() else db.spot(spot)
	_home = str(start.get("id", ""))
	zone_id = _home
	save = SaveData.create_new(0)
	save.seed = seed_value
	save.catches = 1
	rng.seed = seed_value
	timing = sim_timing if not sim_timing.is_empty() else load_timing()
	if not _home.is_empty():
		_mark("zone:" + _home)


## data/sim.json (yoksa boş: varsayılanlar kullanılır).
static func load_timing() -> Dictionary:
	if not FileAccess.file_exists(SIM_PATH):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SIM_PATH))
	return parsed if parsed is Dictionary else {}


func minutes() -> float:
	return elapsed / 60.0


## Bir atış döngüsü: atış, bekleme, ısırma, çekişme, sonuç; kova dolarsa satış ve alışveriş.
func cast_once() -> void:
	# Kova doluyken atılmaz (oyunda eylem düğmesi SAT olur): satıştan sonra toplanan tuzaklar kovayı
	# yeniden doldurduysa yine satılır (her turda tuzaklar boşalır; birkaç turda biter).
	for i in SELL_ROUNDS:
		if not Bucket.is_full(db, save):
			break
		_sell_and_shop()
	_tend_secret()
	if _tend_keeper():
		return
	var phase := str(conditions()["phase"])
	if phase != _last_phase:
		if not _last_phase.is_empty():
			_choose_zone()
			_choose_technique()
		_last_phase = phase
	casts += 1
	var before := elapsed
	if technique != "float":
		_mark("tech:" + technique)
	_tend_requests()
	var cond := conditions()
	var approach := _range("approach_s", Vector2(3, 9))
	if str(cond["weather"]) == "rain":
		approach *= float((timing.get("weather", {}) as Dictionary).get("rain_approach", 1.0 / db.rules.rain_approach))
	elapsed += _num("cast_s", 1.6) + approach + _range("nibble_s", Vector2(1, 3))
	var gear := Economy.gear_for(db, save, technique)
	var species := CatchOdds.species_ppm(db, _spot, CatchOdds.context(gear, technique, cond))
	var fish_id := CatchOdds.roll(db, rng, species, CatchOdds.pity_floor(db, save, _spot, technique, cond))
	var def := db.fish_by_id(fish_id)
	var percentile := FishTable.roll_percentile(rng)
	if Dice.chance(rng, int(_num("miss_ppm", 150000))):
		lost += 1
		elapsed += _num("lost_s", 2.5)
		_count_zone(before, cond)
		return
	Economy.use_bait(db, save, technique)
	var rules := db.rules
	var max_distance := gear.range_m + rules.escape_extra + gear.escape_extra
	# Balık takımın düştüğü yerde takılır: menzilin ötesinde olamaz (ölçüm daha uzun kamışla yapılmış
	# olabilir; yem sepeti menzili kısaltır).
	var start := minf(_range("start_m", Vector2(4, 8)), gear.range_m)
	var model := ReelModel.new(rules, def["fight"], gear.reel_speed, start, max_distance, false, rng.randi(), gear,
			percentile)
	var fight := ReelBot.play(model, ReelBot.make(ReelBot.Style.REACT, _num("reaction_s", 0.45)))
	elapsed += float(fight["seconds"])
	if int(fight["outcome"]) != ReelModel.Outcome.CAUGHT:
		lost += 1
		elapsed += _num("lost_s", 2.5)
		_count_zone(before, cond)
		return
	_on_catch(def, percentile, cond)
	_count_zone(before, cond)
	if Bucket.is_full(db, save):
		_sell_and_shop()


## n döngü oynar (ya da dakika sınırına kadar).
func run(max_minutes: float, max_casts: int = 1_000_000) -> void:
	var n := 0
	while minutes() < max_minutes and n < max_casts:
		cast_once()
		n += 1


## Gölün botun saatindeki koşulu (oyun saati elapsed - _paused_s).
func conditions() -> Dictionary:
	save.clock_s = maxi(0, int(elapsed - _paused_s))
	return WorldState.conditions(db, save)


func _on_catch(def: Dictionary, percentile: int, cond: Dictionary = {}) -> void:
	var fish_id := str(def["id"])
	var rarity := int(def["rarity"])
	var size_cm := FishTable.size_cm(def, percentile)
	var stars := FishTable.stars(percentile)
	var outcome := Records.add(save.records, fish_id, size_cm, stars, int(elapsed))
	catches += 1
	save.catches += 1
	# Hikâyenin balığı (Gölün Bekçisi) şans garantisine sayılmaz, yanında çöp çıkmaz.
	var story := bool(def.get("story", false))
	if not story:
		CatchOdds.note_catch(db, save, rarity, _spot, technique, cond)
	var ranked := Rank.add_xp(db, save, Rank.catch_xp(db, rarity, stars))
	# Dede'nin istekleri: av sayılır (bölge botunki, vakit ve hava atışınki); biten isteğin puanı da rütbeye.
	var paid := _note_request({ "type": "catch", "fish": fish_id, "size_cm": size_cm, "rarity": rarity,
			"technique": technique, "zone": zone_id, "phase": str(cond.get("phase", "")),
			"weather": str(cond.get("weather", "")) })
	ranked["new_rank"] = paid["new_rank"]
	if int(ranked["new_rank"]) > int(ranked["old_rank"]):
		_note_rank(ranked)
		# Yeni bölge açıldı: oyuncu merak eder, hemen gider.
		if not Zones.unlocked_between(db, spot_id, int(ranked["old_rank"]), int(ranked["new_rank"])).is_empty():
			_choose_zone()
			_choose_technique()
	if not Bucket.add(db, save, fish_id, size_cm, stars):
		if not Bucket.release_only(db, fish_id):
			full_released += 1
		_released(fish_id)
	# Dipte balığın yanında çöp (oyunda zarı gölgenin seed'inden; botta kendi tuzlu zarı).
	if not story:
		_found(Trash.with_catch(db.rules, Dice.derive(save.seed, TRASH_SALT, catches), technique))
	elapsed += _num("show_s", 2.4)
	if Records.wants_card(rarity, outcome):
		elapsed += _num("card_s", 2.5)
	_mark("species_%d" % save.records.size())
	_mark("rarity_" + db.rarity_id(rarity))
	_mark("fish:" + fish_id)


func _sell_and_shop() -> void:
	# Nine'nin dükkânı başlangıç bölgesinde: uzaktaysa (sandalda) önce oraya dönülür.
	if zone_id != _home:
		_travel()
		zone_id = _home
		_spot = Zones.place(db, spot_id, _home)
	elapsed += _num("sell_s", 30.0)
	# Dükkân açıkken oyun saati durur.
	_paused_s += _num("sell_s", 30.0)
	_release_cheap()
	earned += Economy.sell_all(db, save)
	sells += 1
	_mark("sell")
	shop()
	# Göl sevgisi 6'da Nine altın hamuru verir (dükkân açılınca).
	if Secret.give_dough(db, save):
		_mark("dough")
		_check_final()
	_tend_traps()
	_trips += 1
	_choose_zone()
	_choose_technique()


## Kerevit tuzakları (satıştan sonra, kova boşken): kerevit girmiş tuzaklar toplanır (kovaya,
## deftere, rütbe puanına), boştaki tuzaklar bırakılır. Tuzağın bölgesine gitmek travel_s, tuzak başına
## trap_s.
func _tend_traps() -> void:
	var rules := db.rules
	TrapSim.update_all(rules, save, int(elapsed))
	for i in save.traps.size():
		if TrapSim.ready(rules, save.traps[i]) <= 0 or Bucket.is_full(db, save):
			continue
		_go_to(str(save.traps[i]["zone"]))
		elapsed += _num("trap_s", 4.0)
		var result := TrapSim.collect(db, save, spot_id, i, int(elapsed))
		var got := (result["items"] as Array).size()
		if got > 0:
			trapped += got
			_mark("trap")
			_mark("species_%d" % save.records.size())
		_found(str(result.get("trash", "")))
		_note_rank(result["ranked"])
		# Tuzaktan gelen her kerevit tuzak isteğine, türün ve boyun isteğine (oyundaki gibi).
		for item: Dictionary in result["items"]:
			_note_rank(_note_request({ "type": "trap", "fish": str(item["fish"]), "size_cm": int(item["size_cm"]),
					"count": 1 }))
	while TrapSim.spare(db, save) > 0:
		var placed := false
		for z in db.zones_of(spot_id):
			if not TrapSim.zone_allows(db, spot_id, str(z["id"])) or not Zones.unlocked(db, save, z):
				continue
			var stands: Array[Vector2] = z["stands"]
			if stands.is_empty():
				continue
			var p := TrapSim.spot_near(db, save, spot_id, str(z["id"]), stands[0], Vector2(0, -1))
			if not Dice.is_point(p):
				continue
			_go_to(str(z["id"]))
			elapsed += _num("trap_s", 4.0)
			TrapSim.place(db, save, spot_id, str(z["id"]), p, int(elapsed))
			_mark("trap_set")
			placed = true
			break
		if not placed:
			return


## Satıştan önce ucuz balıklar göle (Kova panelinin BIRAK'ı): değeri release_value_max'ı geçmeyenler,
## rütbe release_from_rank'ten sonra (oyuncu önce takım için her şeyi satar). O rütbeden sonra Dede'nin
## bırakma isteği varsa önce kalanı kadar en ucuz balık bırakılır (daha önce istek takılır, ertesi gün
## değiştirilir: _tend_requests).
func _release_cheap() -> void:
	var limit := int(_num("release_value_max", 0.0))
	if limit <= 0 or Rank.rank(db, save) < int(_num("release_from_rank", 1.0)):
		return
	_release_for_request()
	var i := 0
	while i < save.bucket.size():
		var entry: Dictionary = save.bucket[i]
		var fish_id := str(entry["fish"])
		if Economy.fish_value(db, fish_id, int(entry["size_cm"])) <= limit:
			save.bucket.remove_at(i)
			_released(fish_id)
		else:
			i += 1


## Dede'nin bitmemiş bırakma isteği (günlük ya da altın): kalanı kadar en ucuz balık göle (oyuncu "3 balık bırak"ı
## görünce kovadan küçükleri bırakır).
func _release_for_request() -> void:
	var left := 0
	for r in save.requests:
		if Requests.counts_for(r, { "type": "release" }) > 0:
			left = maxi(left, int(r["goal"]) - int(r["progress"]))
	while left > 0 and not save.bucket.is_empty():
		var cheapest := 0
		for i in save.bucket.size():
			var entry: Dictionary = save.bucket[i]
			var best: Dictionary = save.bucket[cheapest]
			if Economy.fish_value(db, str(entry["fish"]), int(entry["size_cm"])) \
					< Economy.fish_value(db, str(best["fish"]), int(best["size_cm"])):
				cheapest = i
		var fish_id := str(save.bucket[cheapest]["fish"])
		save.bucket.remove_at(cheapest)
		_released(fish_id)
		left -= 1


## Balık göle döndü: defter, göl sevgisi ve sayaç (WorldState.release; oyundaki gibi).
func _released(fish_id: String) -> void:
	released += 1
	_mark("release")
	_note_love(WorldState.release(db, save, fish_id))
	_note_rank(_note_request({ "type": "release" }))


## Çöp çıktı ("" yoksa): göl sevgisi ve sayaçlar (Trash.collect).
func _found(item: String) -> void:
	if item.is_empty():
		return
	trash += 1
	_mark("trash")
	_note_love(Trash.collect(db.rules, save, item))
	_note_rank(_note_request({ "type": "trash" }))


## Dede'nin istekleri: yeni günde (ve istekler açılınca) boş yuvalar dolar; günde bir, dünden kalan bir istek
## değiştirilir: önce hiç ilerlemeyen, sonra en eski (oyuncu takılanı değiştirir; yağmurlu günde yağmur isteği
## kalır). Bugün paneline bakmak request_s (saat durur).
func _tend_requests() -> void:
	var cond := conditions()
	if not Requests.refill(db, save, spot_id).is_empty():
		_mark("requests")
		_look_at_requests()
	var today := DayClock.day(db.rules, save.clock_s)
	var pick := {}
	for r in Requests.daily(db, save):
		if int(r["day"]) >= today or not Requests.can_reroll(db, save, int(r["slot"])) \
				or (str(r["kind"]) == "rain" and str(cond["weather"]) == "rain"):
			continue
		if pick.is_empty() or _reroll_first(r, pick):
			pick = r
	if not pick.is_empty() and not Requests.reroll(db, save, spot_id, int(pick["slot"])).is_empty():
		rerolls += 1
		_look_at_requests()


## Değiştirme sırası: hiç ilerlemeyen istek önce, sonra eskisi (sıra numarası küçük).
static func _reroll_first(a: Dictionary, b: Dictionary) -> bool:
	var a_stuck := int(a["progress"]) == 0
	var b_stuck := int(b["progress"]) == 0
	if a_stuck != b_stuck:
		return a_stuck
	return int(a["serial"]) < int(b["serial"])


## Bugün paneline bakılır (istekler, değiştirme): request_s geçer, oyun saati durur.
func _look_at_requests() -> void:
	elapsed += _num("request_s", 5.0)
	_paused_s += _num("request_s", 5.0)


## Olay Dede'nin isteklerine sayılır (Requests.note); biten istek oyundaki gibi öder (Requests.pay: para,
## rütbe puanı, göl sevgisi). Döner: { old_rank, new_rank } (isteklerin puanıyla rütbe değişimi).
func _note_request(event: Dictionary) -> Dictionary:
	var before := Rank.rank(db, save)
	for r in Requests.note(save, event):
		var paid := Requests.pay(db, save, r)
		if paid.is_empty():
			continue
		earned += int(paid["coins"])
		_note_love(paid["loved"])
		# Altın istek: harita parçası (günlük isteklerin sayaçlarına ve request_1, requests_10'a girmez).
		if int(paid["piece"]) > 0:
			_mark("piece_%d" % int(paid["piece"]))
			_check_final()
			continue
		requests_done += 1
		request_coins += int(paid["coins"])
		_mark("request_1")
		if requests_done >= 10:
			_mark("requests_10")
	return { "old_rank": before, "new_rank": Rank.rank(db, save) }


## Göl sevgisinin seviyesi arttıysa atlanan her seviyenin dakikası.
func _note_love(result: Dictionary) -> void:
	for level in range(int(result.get("old_level", 1)) + 1, int(result.get("new_level", 1)) + 1):
		_mark("love_%d" % level)


## Haritadan geçiş (travel_s): harita açıkken ve ekran kararırken oyun saati durur.
func _travel() -> void:
	elapsed += _num("travel_s", 6.0)
	_paused_s += _num("travel_s", 6.0)


## Bölgeye gider (başka bölgedeyse travel_s; balık tutmadığı için "zone:" sayılmaz).
func _go_to(id: String) -> void:
	if id.is_empty() or id == zone_id:
		return
	_travel()
	zone_id = id
	_spot = Zones.place(db, spot_id, id)


## Rütbe atladıysa atlanan her rütbenin dakikası.
func _note_rank(ranked: Dictionary) -> void:
	for r in range(int(ranked["old_rank"]) + 1, int(ranked["new_rank"]) + 1):
		_mark("rank_%d" % r)


## Avlanılacak bölge: açılan en yeni kıyı bölgesi; sandal bölgesi açıksa kovaların boat_share
## kadarı orada (sırayla). Bölge değişince travel_s geçer.
func _choose_zone() -> void:
	var zones := db.zones_of(spot_id)
	if zones.size() <= 1:
		return
	var shore: Dictionary = {}
	var shore_score := -INF
	var boat: Dictionary = {}
	for z in zones:
		if not Zones.unlocked(db, save, z):
			continue
		if bool(z["boat"]):
			boat = z
			continue
		var score := _zone_score(z)
		if score > shore_score:
			shore = z
			shore_score = score
	var next := shore
	var share := _num("boat_share", 0.5)
	if not boat.is_empty() and share > 0.0 and fmod(float(_trips) * share, 1.0) + share >= 1.0 - 0.0001:
		next = boat
	# Altın istek vakti gelince bölgesinde kovalanır (akşam nilüferli koy, gece derin orta).
	var want := _golden_want()
	if want.has("zone"):
		var target := db.zone(spot_id, str(want["zone"]))
		if not target.is_empty() and Zones.unlocked(db, save, target):
			next = target
	var id := str(next.get("id", ""))
	if id.is_empty() or id == zone_id:
		return
	_travel()
	zone_id = id
	_spot = next
	_mark("zone:" + id)


## Kıyı bölgesinin çekiciliği: gidilmemiş bölge (merak), sonra defterde tutulmamış tür sayısı,
## sonra balık başına ortalama değer; eşitlikte yeni (rütbesi yüksek) bölge.
func _zone_score(z: Dictionary) -> float:
	var id := str(z["id"])
	var score := 0.0 if milestones.has("zone:" + id) else 10000.0
	for fid: String in z["fish_ids"]:
		if not save.records.has(fid) and _catchable(z, fid):
			score += 100.0
	if not _zone_values.has(id):
		var value := 0.0
		var odds := CatchOdds.species_ppm(db, z)
		for fid: String in odds:
			var f := db.fish_by_id(fid)
			var span: Vector2i = f["size_cm"]
			value += float(odds[fid]) / ContentDB.PPM * Economy.fish_value(db, fid, (span.x + span.y) >> 1)
		_zone_values[id] = value
	return score + float(_zone_values[id]) + int(z["rank"]) * 0.01


## Tür bu bölgede kamışı alınmış bir teknikle gelir mi? Yalnızca belli vakitte ya da havada gelen tür
## (fish.json only) şimdi o koşulda değilse gelmez (bot onun için bölgeye gitmez; gece gider).
func _catchable(z: Dictionary, fish_id: String) -> bool:
	if not CatchOdds.available(db, fish_id, conditions()):
		return false
	for t: String in ContentDB.TECHNIQUES:
		if Economy.technique_ready(db, save, t) and CatchOdds.allows(z, t) and db.affinity(fish_id, t) > 0.0:
			return true
	return false


## Elindeki teknik: bu bölgede avlanılan ve kamışı alınmış tekniklerden en çekicisi; değişirse
## switch_s (takım çantası).
func _choose_technique() -> void:
	var best := "float"
	var best_score := -INF
	for t: String in ContentDB.TECHNIQUES:
		if not Economy.technique_ready(db, save, t) or not CatchOdds.allows(_spot, t):
			continue
		var score := _technique_score(t)
		if score > best_score:
			best = t
			best_score = score
	if best == technique:
		return
	technique = best
	elapsed += _num("switch_s", 3.0)
	# Takım çantası açıkken oyun saati durur.
	_paused_s += _num("switch_s", 3.0)


## Tekniğin çekiciliği: hiç denenmemişse merak; sonra dakikada kazanç (rate) ve defterde olmayan türün
## payı (NEW_SPECIES_WORTH: yeni tür kazançtan önce gelir), tekniğin bu bölgedeki süreleriyle.
func _technique_score(t: String) -> float:
	var score := 0.0 if t == "float" or milestones.has("tech:" + t) else 1.0e12
	var gear := Economy.gear_for(db, save, t)
	# Yeni türün payı gölün şimdiki koşuluyla (gece spinle Ay Turnası); kazanç (rate) koşulsuz.
	var odds := CatchOdds.species_ppm(db, _spot, CatchOdds.context(gear, t, conditions()))
	var fresh := 0.0
	for fid: String in odds:
		if not save.records.has(fid):
			fresh += float(odds[fid]) / ContentDB.PPM
	var per_minute := (1.0 - miss_share(timing, zone_id, t)) * 60.0 / cycle_s(timing, zone_id, t)
	return score + rate(db, timing, _spot, t, gear) + fresh * NEW_SPECIES_WORTH * per_minute + _golden_score(t, odds)


## Gölün Sırrı: önce altın istek (gelebiliyorsa altın yuvaya; Bugün paneline bakılır, vakti gelmişse kovalanır);
## suda şişe varsa bölgesine gidilir (travel_s), şişe alınır (bottle_s), mektup okunur (letter_s: panel açıkken
## saat durur), sonra avlandığı bölgeye dönülür. Okunan mektup sıradaki altın isteği getirebilir.
func _tend_secret() -> void:
	_offer_golden()
	if not Secret.bottle_due(db, save, spot_id):
		return
	_go_to(Secret.bottle_zone(save))
	elapsed += _num("bottle_s", 4.0)
	var n := Secret.read_letter(db, save, spot_id)
	elapsed += _num("letter_s", 30.0)
	_paused_s += _num("letter_s", 30.0)
	_mark("letter_%d" % n)
	_check_final()
	_choose_zone()
	_choose_technique()
	_offer_golden()


## Sıradaki altın istek gelebiliyorsa (Requests.offer_golden) altın yuvaya gelir: bildirim, Dede; oyuncu Bugün
## paneline bakar (request_s). Vakti şimdiyse hemen kovalanır.
func _offer_golden() -> void:
	var r := Requests.offer_golden(db, save)
	if r.is_empty():
		return
	_mark("golden_%d" % int((r["reward"] as Dictionary)["piece"]))
	_look_at_requests()
	if not _golden_want().is_empty():
		_choose_zone()
		_choose_technique()


## Kovalanan altın istek (oyuncu haritanın parçasını ister): altın yuvadaki av isteği, vakti ve havası şimdiyse
## (akşam nilüferli koyda turna, gece derin ortada diple yayın). Döner: isteğin istedikleri (want) ya da boş.
func _golden_want() -> Dictionary:
	var r := Requests.golden(db, save)
	if r.is_empty():
		return {}
	var want: Dictionary = r["want"]
	if str(want.get("event", "")) != "catch":
		return {}
	var cond := conditions()
	for field: String in ["phase", "weather"]:
		if want.has(field) and str(want[field]) != str(cond[field]):
			return {}
	return want


## Tekniğin altın istekteki payı (GOLDEN_WORTH): isteğin bölgesindeyken istediği teknik; türü varsa o türün bu
## teknikle oranıyla (odds: tekniğin şimdiki oranları).
func _golden_score(t: String, odds: Dictionary) -> float:
	var want := _golden_want()
	if want.is_empty() or str(want.get("zone", zone_id)) != zone_id:
		return 0.0
	if want.has("technique") and str(want["technique"]) != t:
		return 0.0
	var share := 1.0
	if want.has("fish"):
		share = float(odds.get(str(want["fish"]), 0)) / ContentDB.PPM
	return share * GOLDEN_WORTH


## Final gecesinde gece: sandalla X'e (derin orta), dip takımı, Bekçi gelir ve çekişir (dalışlarıyla, tepkili oyuncu).
## Tutulursa göle döner (WorldState.release: final biter), bitiş filmi ve jenerik (ending_s, saat durur), şafakta
## sonraki sabahın başı; kaçarsa KEEPER_RETURN_S bekler. Bekçi'yle uğraşıldıysa true (atış sayılır).
func _tend_keeper() -> bool:
	if not Secret.keeper_night(save) or not Economy.technique_ready(db, save, "bottom"):
		return false
	var cond := conditions()
	if str(cond["phase"]) != "night":
		return false
	var deep: Dictionary = {}
	for z in db.zones_of(spot_id):
		if bool(z["boat"]) and Zones.unlocked(db, save, z):
			deep = z
	if deep.is_empty():
		return false
	var before := elapsed
	var id := str(deep["id"])
	if zone_id != id:
		_travel()
		zone_id = id
		_spot = deep
		_mark("zone:" + id)
	if technique != "bottom":
		technique = "bottom"
		elapsed += _num("switch_s", 3.0)
		_paused_s += _num("switch_s", 3.0)
	_mark("tech:bottom")
	casts += 1
	elapsed += _num("cast_s", 1.6) + _range("keeper_s", Vector2(8.0, 14.0))
	var rules := db.rules
	var gear := Economy.gear_for(db, save, "bottom")
	var def := db.fish_by_id(Secret.KEEPER_ID)
	var model := ReelModel.new(rules, def["fight"], gear.reel_speed, gear.range_m,
			gear.range_m + rules.escape_extra + gear.escape_extra, false, rng.randi(), gear, Secret.KEEPER_PERCENTILE)
	var fight := ReelBot.play(model, ReelBot.make(ReelBot.Style.REACT, _num("reaction_s", 0.45)))
	elapsed += float(fight["seconds"])
	if int(fight["outcome"]) != ReelModel.Outcome.CAUGHT:
		lost += 1
		elapsed += _num("lost_s", 2.5) + Secret.KEEPER_RETURN_S
		_count_zone(before, cond)
		return true
	_on_catch(def, Secret.KEEPER_PERCENTILE, cond)
	_mark("keeper")
	var ending := _num("ending_s", 65.0)
	elapsed += ending
	_paused_s += ending
	var now := maxi(0, int(elapsed - _paused_s))
	if DayClock.phase(rules, now) == "night":
		_paused_s -= float(DayClock.next_phase_start(rules, now) - now)
	_count_zone(before, cond)
	_choose_zone()
	_choose_technique()
	return true


## Final hazır olduysa (altı mektup, dört parça, altın hamur) ilk dakikası.
func _check_final() -> void:
	if Secret.final_ready(save):
		_mark("final_ready")


## Bir teknikle bu yerde (bölge ya da göl) dakikada ortalama kazanç (para): oranlar (takımın yeminin,
## yapay yeminin, sineğin çekimiyle) × takılan balığın ortalama değeri (kept_value: takımın
## taşıyamadığı iri balık kaçar), tekniğin bu bölgedeki atış döngüsüyle (cycle_s) ve kaçırılan ısırma
## payıyla. Botun teknik seçimi ve test_economy (bölgenin önerdiği teknik orada şamandıradan az
## kazandırmaz) kullanır.
static func rate(db: ContentDB, sim_timing: Dictionary, place: Dictionary, t: String, gear: GearStats) -> float:
	var odds := CatchOdds.species_ppm(db, place, {"attract": gear.attract, "technique": t})
	var worth := 0.0
	for fid: String in odds:
		worth += float(odds[fid]) / ContentDB.PPM * kept_value(db, fid, gear.carry)
	var zone := str(place.get("id", ""))
	return worth * (1.0 - miss_share(sim_timing, zone, t)) * 60.0 / cycle_s(sim_timing, zone, t)


## Takılan bir balığın ortalama değeri (para): boy zarının eşit aralıklı RATE_SAMPLES örneğiyle;
## takımın taşıyamadığı boy (fazla iri: ReelModel.excess_for) kaçar, değeri 0.
static func kept_value(db: ContentDB, fish_id: String, carry: int) -> float:
	var def := db.fish_by_id(fish_id)
	var fight: Dictionary = def["fight"]
	var total := 0
	for i in RATE_SAMPLES:
		var percentile := FishTable.percentile_for(int((float(i) + 0.5) / RATE_SAMPLES * Dice.PPM))
		if ReelModel.excess_for(fight, percentile, carry) == 0:
			total += Economy.fish_value(db, fish_id, FishTable.size_cm(def, percentile))
	return float(total) / RATE_SAMPLES


## Bir atışın ortalama süresi (sn): atış, balığın gelişi, dürtme (ısırmaya kadar), çekişme ve
## gösteri (sim.json; tekniğin bölgedeki, tekniğin, bölgenin, genel ölçümü: timing_of).
static func cycle_s(sim_timing: Dictionary, zone: String, t: String) -> float:
	var cycle := 0.0
	for key: String in ["cast_s", "fight_s", "show_s"]:
		cycle += float(timing_of(sim_timing, zone, t, key, 4.0 if key != "show_s" else 1.3))
	for key: String in ["approach_s", "nibble_s"]:
		var r: Variant = timing_of(sim_timing, zone, t, key, [2.0, 6.0])
		cycle += (float(r[0]) + float(r[1])) * 0.5 if r is Array and (r as Array).size() >= 2 else 4.0
	return maxf(1.0, cycle)


## Kaçırılan ısırmaların payı (0–1; miss_ppm: sinekte VUR anı kısa, daha çok kaçırılır).
static func miss_share(sim_timing: Dictionary, zone: String, t: String) -> float:
	return float(timing_of(sim_timing, zone, t, "miss_ppm", 150000)) / ContentDB.PPM


## sim.json'da bir ölçüm: önce tekniğin bu bölgedeki, sonra tekniğin, sonra bölgenin, sonra genel
## değeri (_range'in sırası); hiçbiri yoksa fallback.
static func timing_of(sim_timing: Dictionary, zone: String, t: String, key: String, fallback: Variant) -> Variant:
	var own: Dictionary = (sim_timing.get("techniques", {}) as Dictionary).get(t, {})
	for source: Dictionary in [own, sim_timing]:
		var here: Dictionary = (source.get("zones", {}) as Dictionary).get(zone, {})
		if here.has(key):
			return here[key]
		if source.has(key):
			return source[key]
	return fallback


## Atışın süresi bölgenin, tekniğin, vaktin ve havanın hanesine (rapor: nerede, nasıl, ne zaman).
func _count_zone(since: float, cond: Dictionary = {}) -> void:
	zone_time[zone_id] = float(zone_time.get(zone_id, 0.0)) + elapsed - since
	technique_time[technique] = float(technique_time.get(technique, 0.0)) + elapsed - since
	if not cond.is_empty():
		var phase := str(cond["phase"])
		var weather := str(cond["weather"])
		phase_time[phase] = float(phase_time.get(phase, 0.0)) + elapsed - since
		weather_time[weather] = float(weather_time.get(weather, 0.0)) + elapsed - since


## Alışveriş (Kazı'nın botu gibi): her kategorinin sıradaki takımından rütbesi yetenlerin en
## ucuzunu, para yettikçe alır. En ucuz olana para yetmiyorsa biriktirir (daha pahalısını almaz).
## Sandal, yeni tekniğin ilk kamışı ve ilk tuzak öncelikli: rütbesi yetince önce onlar alınır, parası
## yetene kadar başka şey alınmaz (oyuncu derin ortayı, yeni tekniği merak eder). Sıradaki kova da
## öncelikli ama onun için biriktirilmez: parası yetiyorsa ötekilerden önce alınır (sık dolan kovayı
## oyuncu önce büyütür; Dede her dolduğunda söyler). Satın alınan kendiliğinden kuşanılır. Döner:
## alınanlar.
func shop() -> Array[String]:
	var bought: Array[String] = []
	var first: Array[Dictionary] = [next_upgrade("boat")]
	for t: String in ContentDB.TECHNIQUES:
		if t != "float" and db.has_technique(t) and not Economy.technique_ready(db, save, t):
			first.append(next_upgrade("rod:" + t))
	# İlk kerevit tuzağı da öncelikli (rütbe 3'te Dede haber verir, düğme atar).
	if TrapSim.owned(db, save) == 0:
		first.append(TrapSim.next_trap(db, save))
	for item in first:
		if item.is_empty() or Rank.rank(db, save) < int(item["rank"]):
			continue
		if not Economy.buy_block(db, save, str(item["id"])).is_empty():
			return bought
		Economy.buy(db, save, str(item["id"]))
		bought.append(str(item["id"]))
		_mark("buy")
		_mark("buy:" + str(item["id"]))
	var bucket := next_upgrade("bucket")
	if not bucket.is_empty() and Rank.rank(db, save) >= int(bucket["rank"]) \
			and Economy.buy_block(db, save, str(bucket["id"])).is_empty():
		Economy.buy(db, save, str(bucket["id"]))
		bought.append(str(bucket["id"]))
		_mark("buy")
		_mark("buy:" + str(bucket["id"]))
	while true:
		var cheapest: Dictionary = {}
		for category in _buy_categories():
			if category == "boat":
				continue
			var next := next_upgrade(category)
			if next.is_empty() or Rank.rank(db, save) < int(next["rank"]):
				continue
			if cheapest.is_empty() or int(next["price"]) < int(cheapest["price"]):
				cheapest = next
		if cheapest.is_empty() or not Economy.buy_block(db, save, str(cheapest["id"])).is_empty():
			break
		Economy.buy(db, save, str(cheapest["id"]))
		bought.append(str(cheapest["id"]))
		_mark("buy")
		_mark("buy:" + str(cheapest["id"]))
	return bought


## Alışverişin kategorileri: BUY_CATEGORIES, öteki tekniklerin kamışları ("rod:<teknik>") ve kamışı
## alınmış tekniğin küçük takımı (yapay yem, kurşun, sinek; yem alınmaz).
func _buy_categories() -> Array[String]:
	var out: Array[String] = BUY_CATEGORIES.duplicate()
	for t: String in ContentDB.TECHNIQUES:
		if t == "float" or not db.has_technique(t):
			continue
		out.append("rod:" + t)
		if not Economy.technique_ready(db, save, t):
			continue
		for slot: String in db.slots_for(t):
			if db.slot_technique(slot) == t and slot != "rod" and not slot in out:
				out.append(slot)
	return out


## Bir kategoride sahip olunmayan en ucuz takım ("rod" şamandıranın kamışları, "rod:<teknik>" o
## tekniğin; daha büyüğü alınmış kova sahip sayılır); yoksa boş.
func next_upgrade(category: String) -> Dictionary:
	var best: Dictionary = {}
	var rod_technique := "float"
	if category.begins_with("rod:"):
		rod_technique = category.substr(4)
		category = "rod"
	for g in db.gear_in(category):
		if category == "rod" and str(g["technique"]) != rod_technique:
			continue
		if Economy.buy_block(db, save, str(g["id"])) == "owned":
			continue
		if best.is_empty() or int(g["price"]) < int(best["price"]):
			best = g
	return best


func _mark(id: String) -> void:
	if not milestones.has(id):
		milestones[id] = minutes()


## Sayı: elindeki tekniğin ölçümü (sim.json techniques.<teknik>) varsa o, yoksa genel değer.
func _num(key: String, fallback: float) -> float:
	var own: Dictionary = (timing.get("techniques", {}) as Dictionary).get(technique, {})
	return float(own.get(key, timing.get(key, fallback)))


## Süre aralığı: önce tekniğin (bölgesinin, sonra genel) ölçümü, sonra genel ölçüm (botun bölgesinin
## varsa o: sim.json zones).
func _range(key: String, fallback: Vector2) -> float:
	var r: Variant = null
	var own: Dictionary = (timing.get("techniques", {}) as Dictionary).get(technique, {})
	for source: Dictionary in [own, timing]:
		var zones: Dictionary = source.get("zones", {})
		var here: Dictionary = zones.get(zone_id, {})
		if here.has(key):
			r = here[key]
			break
		if source.has(key):
			r = source[key]
			break
	var lo := fallback.x
	var hi := fallback.y
	if r is Array and (r as Array).size() >= 2:
		lo = float(r[0])
		hi = float(r[1])
	return rng.randf_range(lo, hi)
