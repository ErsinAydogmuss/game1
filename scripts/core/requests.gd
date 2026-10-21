class_name Requests
extends RefCounted
## Dede'nin istekleri (Dalga 4, docs/gdd.md §10.5; kurallar data/requests.json, RequestRules). Rütbe
## unlock_rank'ta açılır. Günlük yuvalar (0..slots-1) her yeni oyun gününde yalnızca boşsa dolar: istek
## bitmeden kalabilir, süresi dolmaz (gelir kuralı 7). Günde bir istek ücretsiz değiştirilir. İstek
## oluştuğu anda bellidir (gelir kuralı 4): zar kaydın seed'i ve isteğin sıra numarasıyla (request_serial);
## zar sırası şablon, hedef, sayı, (boy), ödülün saçılması. Ekrandaki isteklerle aynı istek gelmez.
## İlerleme isteğin içinde: oyunun olayları (av, bırakma, çöp, tuzak) note'a gelir; biten istek pay ile
## bir kez öder (para, rütbe puanı, göl sevgisi) ve yuvası boşalır. Saf mantık: oyun, Bugün paneli ve
## denge botu aynı kuralı kullanır. Yazıyı UI kurar (describe: çeviri anahtarı ve değerler).
@warning_ignore_start("integer_division")

## İsteğin zarının tuzu (Dice.derive(seed, SALT, request_serial)).
const SALT := 7507
## İstenen nadirlik isteğinin alt sınırı (rarities.json sırası: Nadir).
const RARE_FROM := "rare"


## İstekler açık mı (rütbe)?
static func unlocked(db: ContentDB, save: SaveData) -> bool:
	return Rank.rank(db, save) >= db.requests.unlock_rank


## Günlük yuvalardaki istekler, yuva sırasıyla.
static func daily(db: ContentDB, save: SaveData) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for slot in db.requests.slots:
		var r := find_slot(save, slot)
		if not r.is_empty():
			out.append(r)
	return out


## Yuvadaki istek (yoksa boş).
static func find_slot(save: SaveData, slot: int) -> Dictionary:
	for r in save.requests:
		if int(r["slot"]) == slot:
			return r
	return {}


## Yeni oyun gününde boş günlük yuvaları doldurur (açılınca hemen de: request_day -1). Bugün zaten
## doldurulduysa, istekler kapalıysa ya da yuvalar doluysa bir şey yapmaz. Döner: yeni istekler.
static func refill(db: ContentDB, save: SaveData, spot_id: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if not unlocked(db, save):
		return out
	var day := DayClock.day(db.rules, save.clock_s)
	if save.request_day >= day:
		return out
	save.request_day = day
	for slot in db.requests.slots:
		if not find_slot(save, slot).is_empty():
			continue
		var r := roll(db, save, spot_id, slot, day)
		if not r.is_empty():
			save.requests.append(r)
			out.append(r)
	return out


## Yuvaya yeni bir istek zarlar (kayda eklemez; sayaç ilerler). avoid: ayrıca kaçınılacak istekler
## (değiştirilen). Uygun şablon yoksa boş.
static func roll(db: ContentDB, save: SaveData, spot_id: String, slot: int, day: int,
		avoid: Array[Dictionary] = []) -> Dictionary:
	var rules := db.requests
	var taken := {}
	for r in save.requests:
		taken[key_of(r)] = true
	for r in avoid:
		taken[key_of(r)] = true
	var options := candidates(db, save, spot_id)
	var kinds: Array[Dictionary] = []
	var lists: Array[Array] = []
	var weights := PackedInt32Array()
	for t in rules.templates:
		var kind := str(t["kind"])
		var free: Array = []
		for want: Dictionary in options.get(kind, []):
			if not taken.has(_key(kind, want)):
				free.append(want)
		if free.is_empty():
			continue
		kinds.append(t)
		lists.append(free)
		weights.append(int(t["weight"]))
	var rng := RandomNumberGenerator.new()
	rng.seed = Dice.derive(save.seed, SALT, save.request_serial)
	var k := Dice.pick_weighted(rng, weights)
	if k < 0:
		return {}
	var template := kinds[k]
	var kind := str(template["kind"])
	var wants: Array = lists[k]
	var want: Dictionary = (wants[rng.randi_range(0, wants.size() - 1)] as Dictionary).duplicate()
	var count: Vector2i = template["count"]
	if kind == "species":
		var def := db.fish_by_id(str(want["fish"]))
		count = rules.species_count.get(db.rarity_id(int(def["rarity"])), count)
	var goal := rng.randi_range(count.x, count.y)
	if kind == "size":
		var def := db.fish_by_id(str(want["fish"]))
		want["min_cm"] = size_target(def, rng.randi_range(rules.size_percentile.x, rules.size_percentile.y))
	var spread := rng.randi_range(rules.spread_min_pm, rules.spread_max_pm)
	var rank := Rank.rank(db, save)
	var mult := int(template["mult_pm"])
	var raw := (rules.coins_base + rules.coins_per_rank * rank) * mult * spread
	var coins := maxi(5, (raw + 2_500_000) / 5_000_000 * 5)
	var xp := (rules.xp_base + rules.xp_per_rank * rank) * mult / 1000
	var serial := save.request_serial
	save.request_serial += 1
	return {
		"slot": slot,
		"kind": kind,
		"want": want,
		"goal": goal,
		"progress": 0,
		"day": day,
		"serial": serial,
		"reward": { "coins": coins, "xp": xp, "love": int(template["love"]) },
	}


## Her şablonun olası hedefleri (want'lar; kayıttaki rütbe, takım, açık bölgeler ve tahminle), sabit
## sırayla: kind -> Array[Dictionary]. Şablonu olmayan ya da şartı tutmayan tür listede yok.
static func candidates(db: ContentDB, save: SaveData, spot_id: String) -> Dictionary:
	var out := {}
	var rules := db.requests
	var rank := Rank.rank(db, save)
	var zones := open_zones(db, save, spot_id)
	var ready := ready_techniques(db, save, spot_id, zones)
	for t in rules.templates:
		var kind := str(t["kind"])
		if rank < int(t["rank"]):
			continue
		var list: Array = []
		match kind:
			"species", "size":
				for id in catchable(db, spot_id, zones, ready):
					list.append({ "fish": id })
			"technique":
				for tech in ready:
					if tech != "float":
						list.append({ "technique": tech })
			"zone":
				for z in zones:
					list.append({ "zone": z })
			"phase":
				for p in DayClock.PHASES:
					list.append({ "phase": p })
			"rare":
				list.append({ "rarity": db.rarity_index(RARE_FROM) })
			"rain":
				if "rain" in Weather.forecast(db.rules, save, 2):
					list.append({ "weather": "rain" })
			"release":
				list.append({})
			"trash":
				if Economy.technique_ready(db, save, "bottom") or TrapSim.owned(db, save) > 0:
					list.append({})
			"trap":
				if TrapSim.owned(db, save) > 0:
					list.append({})
		if not list.is_empty():
			out[kind] = list
	return out


## Açık bölgeler: kıyı bölgeleri ve (sandal varsa) sandal bölgeleri, spots.json sırasıyla.
static func open_zones(db: ContentDB, save: SaveData, spot_id: String) -> PackedStringArray:
	var out := PackedStringArray()
	for z in db.zones_of(spot_id):
		if Zones.unlocked(db, save, z):
			out.append(str(z["id"]))
	return out


## Kamışı alınmış ve açık bir bölgede avlanılan teknikler (ContentDB.TECHNIQUES sırasıyla; şamandıra hep).
static func ready_techniques(db: ContentDB, save: SaveData, spot_id: String, zones: PackedStringArray) -> Array[String]:
	var out: Array[String] = []
	for tech: String in ContentDB.TECHNIQUES:
		if not db.has_technique(tech) and tech != "float":
			continue
		if not Economy.technique_ready(db, save, tech):
			continue
		for z in zones:
			if Economy.technique_allowed(db, spot_id, z, tech):
				out.append(tech)
				break
	return out


## İstenebilen türler (fish.json sırasıyla): nadirliği species_count'ta, koruma altında değil ve bir açık
## bölgede elindeki bir teknikle en az species_min_ppm gelen (koşulsuz oran: vakit ve hava sayılmaz).
static func catchable(db: ContentDB, spot_id: String, zones: PackedStringArray, ready: Array[String]) -> PackedStringArray:
	var rules := db.requests
	var best := {}
	for z in zones:
		var place := db.zone(spot_id, z)
		for tech in ready:
			var odds := CatchOdds.species_ppm(db, place, { "technique": tech })
			for id: String in odds:
				best[id] = maxi(int(best.get(id, 0)), int(odds[id]))
	var out := PackedStringArray()
	for f in db.fish:
		var id := str(f["id"])
		if bool(f.get("release_only", false)) or not rules.species_count.has(db.rarity_id(int(f["rarity"]))):
			continue
		if int(best.get(id, 0)) >= rules.species_min_ppm:
			out.append(id)
	return out


## Boy isteğinin sınırı: türün o yüzdelikteki boyu, 5 cm'ye yuvarlanmış; türün en küçüğünden büyük ve
## 3 yıldızın (yüzdelik 0,7) içinde.
static func size_target(def: Dictionary, percentile: int) -> int:
	var range_cm: Vector2i = def["size_cm"]
	var cm := (FishTable.size_cm(def, percentile) + 2) / 5 * 5
	var top := FishTable.size_cm(def, FishTable.STAR_LIMITS[2] - 1)
	return clampi(cm, range_cm.x + 1, maxi(range_cm.x + 1, top))


## Oyunun bir olayı isteklere sayılır. event: { "type": "catch", "fish", "size_cm", "rarity", "technique",
## "zone", "phase", "weather" } | { "type": "release" | "trash", "count" } | { "type": "trap", "fish",
## "size_cm", "count" } (tuzaktan gelen her kerevit ayrı olay: boy isteği de sayar). Döner: bu olayla biten
## istekler (ödemesi pay ile).
static func note(save: SaveData, event: Dictionary) -> Array[Dictionary]:
	var done: Array[Dictionary] = []
	for r in save.requests:
		var goal := int(r["goal"])
		if int(r["progress"]) >= goal:
			continue
		var add := counts_for(r, event)
		if add <= 0:
			continue
		r["progress"] = mini(goal, int(r["progress"]) + add)
		if int(r["progress"]) >= goal:
			done.append(r)
	return done


## Olayın isteğe katkısı (kaç; sayılmıyorsa 0). Tuzaktaki kerevit tuzak isteğine, kerevit türü ve boy
## isteğine sayılır; bölge, vakit, hava, teknik ve nadirlik istekleri oltayla tutulan balığa bakar. Boy
## isteği "en az": sınırdaki boy da sayılır (sınır 3 yıldızın içinde: daha irisi takım isteyebilir).
static func counts_for(request: Dictionary, event: Dictionary) -> int:
	var want: Dictionary = request["want"]
	var type := str(event.get("type", ""))
	var n := maxi(1, int(event.get("count", 1)))
	match str(request["kind"]):
		"species":
			if type in ["catch", "trap"] and str(event.get("fish", "")) == str(want.get("fish", "")):
				return n
		"size":
			if type in ["catch", "trap"] and str(event.get("fish", "")) == str(want.get("fish", "")) \
					and int(event.get("size_cm", 0)) >= int(want.get("min_cm", 0)):
				return 1
		"technique":
			if type == "catch" and str(event.get("technique", "")) == str(want.get("technique", "")):
				return 1
		"zone":
			if type == "catch" and str(event.get("zone", "")) == str(want.get("zone", "")):
				return 1
		"phase":
			if type == "catch" and str(event.get("phase", "")) == str(want.get("phase", "")):
				return 1
		"rare":
			if type == "catch" and int(event.get("rarity", -1)) >= int(want.get("rarity", 0)):
				return 1
		"rain":
			if type == "catch" and str(event.get("weather", "")) == "rain":
				return 1
		"release", "trash", "trap":
			if type == str(request["kind"]):
				return n
	return 0


## Biten isteği öder (bir kez: kayıttan çıkar, yuvası boşalır): para, rütbe puanı, göl sevgisi. Döner:
## { request, coins, xp, love, ranked: Rank.add_xp, loved: LakeLove.add } (istek kayıtta yoksa ya da
## bitmediyse boş).
static func pay(db: ContentDB, save: SaveData, request: Dictionary) -> Dictionary:
	var index := -1
	for i in save.requests.size():
		if int(save.requests[i]["serial"]) == int(request["serial"]):
			index = i
			break
	if index < 0:
		return {}
	var r: Dictionary = save.requests[index]
	if int(r["progress"]) < int(r["goal"]):
		return {}
	save.requests.remove_at(index)
	var reward: Dictionary = r["reward"]
	var coins := int(reward.get("coins", 0))
	save.coins += coins
	var xp := int(reward.get("xp", 0))
	var love := int(reward.get("love", 0))
	save.stats["requests"] = int(save.stats.get("requests", 0)) + 1
	save.stats["request_coins"] = int(save.stats.get("request_coins", 0)) + coins
	return {
		"request": r,
		"coins": coins,
		"xp": xp,
		"love": love,
		"ranked": Rank.add_xp(db, save, xp),
		"loved": LakeLove.add(db.rules, save, love),
	}


## Hedefine varmış ama ödenmemiş istekler (normal oyunda olmaz: note ile pay aynı karede; bozuk ya da yarıda
## kalmış kayıt). Yuvasını tutmasın diye çağıran öder.
static func finished(save: SaveData) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for r in save.requests:
		if int(r["progress"]) >= int(r["goal"]):
			out.append(r)
	return out


## Bugün bu yuvanın isteği değiştirilebilir mi (günde bir, bitmemiş istek)?
static func can_reroll(db: ContentDB, save: SaveData, slot: int) -> bool:
	var r := find_slot(save, slot)
	return unlocked(db, save) and not r.is_empty() and int(r["progress"]) < int(r["goal"]) \
			and save.reroll_day < DayClock.day(db.rules, save.clock_s)


## Bugünün değiştirme hakkı kullanıldı mı?
static func rerolled_today(db: ContentDB, save: SaveData) -> bool:
	return save.reroll_day >= DayClock.day(db.rules, save.clock_s)


## Yuvadaki isteği başkasıyla değiştirir (eskisi ve ekrandakiler gelmez; ilerleme sıfır). Döner: yeni
## istek (değiştirilemezse boş).
static func reroll(db: ContentDB, save: SaveData, spot_id: String, slot: int) -> Dictionary:
	if not can_reroll(db, save, slot):
		return {}
	var day := DayClock.day(db.rules, save.clock_s)
	var old := find_slot(save, slot)
	save.requests.erase(old)
	var avoid: Array[Dictionary] = [old]
	var fresh := roll(db, save, spot_id, slot, day, avoid)
	if fresh.is_empty():
		save.requests.append(old)
		return {}
	save.requests.append(fresh)
	save.reroll_day = day
	return fresh


## İsteğin yazısı: [çeviri anahtarı, değerler]; değerlerdeki yazılar da çeviri anahtarıdır (tür, teknik,
## bölge, vakit, nadirlik adı), sayılar olduğu gibi. Türkçesi eksiz kurulur ("3 Kadife tut", "Sazlık: 4
## balık", "Gece vakti 3 balık").
static func describe(db: ContentDB, request: Dictionary) -> Array:
	var want: Dictionary = request["want"]
	var goal := int(request["goal"])
	match str(request["kind"]):
		"species":
			return ["UI_REQ_species", [goal, "FISH_" + str(want.get("fish", ""))]]
		"size":
			return ["UI_REQ_size", ["FISH_" + str(want.get("fish", "")), int(want.get("min_cm", 0))]]
		"technique":
			return ["UI_REQ_technique", ["UI_TECH_" + str(want.get("technique", "")), goal]]
		"zone":
			return ["UI_REQ_zone", ["ZONE_" + str(want.get("zone", "")), goal]]
		"phase":
			return ["UI_REQ_phase", ["PHASE_" + str(want.get("phase", "")), goal]]
		"rare":
			return ["UI_REQ_rare", [goal, "RARITY_" + db.rarity_id(int(want.get("rarity", 0)))]]
		_:
			return ["UI_REQ_" + str(request["kind"]), [goal]]


## İsteğin aynı olanını tanıyan anahtar (tür + hedef).
static func key_of(request: Dictionary) -> String:
	return _key(str(request["kind"]), request["want"])


static func _key(kind: String, want: Dictionary) -> String:
	for field: String in ["fish", "technique", "zone", "phase"]:
		if want.has(field):
			return kind + ":" + str(want[field])
	return kind
