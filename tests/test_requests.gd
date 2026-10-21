extends BaseTest
## Dede'nin istekleri (Requests, data/requests.json; Dalga 4): rütbe 2'de açılır; yuvalar yalnızca yeni
## günde ve yalnızca boşsa dolar; istekler oluşunca belli (aynı seed aynı istek) ve ekrandakilerden farklı;
## şablonların şartları (rütbe, takım, açık bölge, tahmin); olaylar ilerletir; biten istek bir kez öder;
## süresi dolmaz; günde bir değiştirme; ödül rütbeyle artar; kayıtta gidip gelir; yazıları iki dilde var.

const SPOT := "big_lake"


func test_requests_open_at_rank_two() -> void:
	var db := content()
	var save := _save(1)
	assert_true(not Requests.unlocked(db, save), "rütbe 1'de kapalı")
	assert_eq(Requests.refill(db, save, SPOT).size(), 0, "rütbe 1'de istek yok")
	assert_eq(save.request_day, -1, "gün sayılmaz")
	_rank(save, db.requests.unlock_rank)
	var fresh := Requests.refill(db, save, SPOT)
	assert_eq(fresh.size(), db.requests.slots, "açılınca bütün yuvalar dolar")
	assert_eq(save.request_day, DayClock.day(db.rules, save.clock_s), "bugün dolduruldu")
	var slots := {}
	for r in save.requests:
		slots[int(r["slot"])] = true
		assert_true(int(r["goal"]) >= 1 and int(r["progress"]) == 0, "hedef ve ilerleme: %s" % r)
		assert_true(str(r["kind"]) in RequestRules.KINDS, "bilinen tür: %s" % r["kind"])
	assert_eq(slots.size(), db.requests.slots, "her yuvaya bir istek")


func test_same_seed_same_requests() -> void:
	var db := content()
	var a := _save(6)
	var b := _save(6)
	Requests.refill(db, a, SPOT)
	Requests.refill(db, b, SPOT)
	assert_eq(a.requests, b.requests, "aynı kayıt aynı istekler")
	var different := 0
	for seed_value in 30:
		var c := _save(6)
		c.seed = 1000 + seed_value
		Requests.refill(db, c, SPOT)
		if c.requests != a.requests:
			different += 1
	assert_true(different >= 25, "başka seed çoğunlukla başka istekler (%d/30)" % different)


func test_requests_on_screen_differ() -> void:
	var db := content()
	for seed_value in 200:
		var save := _save(10)
		save.seed = seed_value
		_own(save, ["rod_spin_light", "rod_carp_1", "trap_1"])
		Requests.refill(db, save, SPOT)
		var keys := {}
		for r in save.requests:
			assert_true(not keys.has(Requests.key_of(r)), "seed %d: aynı istek iki kez: %s" % [seed_value, Requests.key_of(r)])
			keys[Requests.key_of(r)] = true


func test_refill_only_on_a_new_day_and_only_empty_slots() -> void:
	var db := content()
	var save := _save(4)
	Requests.refill(db, save, SPOT)
	var first := save.requests.duplicate(true)
	var done := _finish(db, save, 0)
	assert_true(not done.is_empty(), "istek bitti ve ödendi")
	assert_eq(Requests.refill(db, save, SPOT).size(), 0, "aynı gün yuva boş kalır")
	assert_true(Requests.find_slot(save, 0).is_empty(), "yuva boş")
	save.clock_s += DayClock.day_s(db.rules)
	var fresh := Requests.refill(db, save, SPOT)
	assert_eq(fresh.size(), 1, "yeni günde yalnızca boş yuva dolar")
	assert_eq(int(fresh[0]["slot"]), 0, "boşalan yuva")
	for slot in [1, 2]:
		assert_eq(Requests.find_slot(save, slot), _slot_of(first, slot), "dolu yuva %d dokunulmaz" % slot)
	assert_eq(Requests.refill(db, save, SPOT).size(), 0, "aynı gün ikinci doldurma yok")


func test_unfinished_requests_never_expire() -> void:
	var db := content()
	var save := _save(5)
	Requests.refill(db, save, SPOT)
	var r := Requests.find_slot(save, 1)
	r["progress"] = int(r["goal"]) - 1 if int(r["goal"]) > 1 else 0
	var kept := save.requests.duplicate(true)
	save.clock_s += 10 * DayClock.day_s(db.rules)
	assert_eq(Requests.refill(db, save, SPOT).size(), 0, "yuvalar dolu: yeni istek yok")
	assert_eq(save.requests, kept, "10 gün sonra istekler ve ilerlemeleri aynı (süre sınırı yok)")


func test_finished_request_pays_once() -> void:
	var db := content()
	var save := _save(8)
	Requests.refill(db, save, SPOT)
	var r := Requests.find_slot(save, 2)
	var reward: Dictionary = r["reward"]
	var coins := save.coins
	var xp := save.xp
	var love := save.love
	r["progress"] = int(r["goal"])
	var paid := Requests.pay(db, save, r)
	assert_true(not paid.is_empty(), "öder")
	assert_eq(save.coins, coins + int(reward["coins"]), "para")
	assert_eq(save.xp, xp + int(reward["xp"]), "rütbe puanı")
	assert_eq(save.love, love + int(reward["love"]), "göl sevgisi")
	assert_eq(int(save.stats.get("requests", 0)), 1, "sayaç")
	assert_true(Requests.find_slot(save, 2).is_empty(), "yuva boşalır")
	assert_eq(Requests.pay(db, save, r), {}, "ikinci kez ödemez")
	assert_eq(save.coins, coins + int(reward["coins"]), "para bir kez")
	var other := Requests.find_slot(save, 0)
	assert_eq(Requests.pay(db, save, other), {}, "bitmemiş istek ödemez")


func test_one_free_reroll_a_day() -> void:
	var db := content()
	var save := _save(6)
	Requests.refill(db, save, SPOT)
	var old := Requests.find_slot(save, 1).duplicate(true)
	assert_true(Requests.can_reroll(db, save, 1), "bugün değiştirilebilir")
	var fresh := Requests.reroll(db, save, SPOT, 1)
	assert_true(not fresh.is_empty(), "yeni istek")
	assert_true(Requests.key_of(fresh) != Requests.key_of(old), "başka istek (%s, %s)" % [Requests.key_of(old),
			Requests.key_of(fresh)])
	assert_eq(int(fresh["slot"]), 1, "aynı yuva")
	assert_eq(int(fresh["progress"]), 0, "ilerleme sıfır")
	assert_eq(save.requests.size(), db.requests.slots, "istek sayısı aynı")
	for slot in db.requests.slots:
		assert_true(not Requests.can_reroll(db, save, slot), "bugün ikinci değiştirme yok (yuva %d)" % slot)
	assert_eq(Requests.reroll(db, save, SPOT, 0), {}, "değiştirmez")
	assert_true(Requests.rerolled_today(db, save), "hak kullanıldı")
	save.clock_s += DayClock.day_s(db.rules)
	assert_true(Requests.can_reroll(db, save, 0), "yarın yine")
	# Biten istek değiştirilmez (ödenmeyi bekler).
	var r := Requests.find_slot(save, 0)
	r["progress"] = int(r["goal"])
	assert_true(not Requests.can_reroll(db, save, 0), "biten istek değiştirilmez")


func test_template_conditions() -> void:
	var db := content()
	# Rütbe 2: yalnızca tür, vakit ve bırakma (spin kamışı yoksa teknik de yok).
	var low := _save(2)
	var options := Requests.candidates(db, low, SPOT)
	assert_eq(_sorted(options.keys()), ["phase", "release", "species"], "rütbe 2'nin şablonları")
	_own(low, ["rod_spin_light"])
	options = Requests.candidates(db, low, SPOT)
	assert_eq(options.get("technique", []), [{ "technique": "spin" }], "spin kamışı alınınca spin isteği")
	# Tür isteği: açık bölgede gelen, Sıradan / Güzel / Nadir, koruma altında değil.
	var open := Requests.open_zones(db, low, SPOT)
	for want: Dictionary in options["species"]:
		var def := db.fish_by_id(str(want["fish"]))
		assert_true(not bool(def.get("release_only", false)), "koruma altındaki tür istenmez: %s" % want)
		assert_true(int(def["rarity"]) <= db.rarity_index("rare"), "en çok Nadir: %s" % want)
		assert_true(_comes_in(db, str(want["fish"]), open), "açık bölgede gelir: %s" % want)
	# Rütbe 10, tuzak ve dip kamışı: bölge, nadir, çöp, tuzak; sandal yokken derin orta yok.
	var high := _save(10)
	_own(high, ["rod_spin_light", "rod_carp_1", "trap_1"])
	options = Requests.candidates(db, high, SPOT)
	for kind: String in ["size", "zone", "rare", "trash", "trap"]:
		assert_true(options.has(kind), "rütbe 10'da %s isteği olabilir" % kind)
	for want: Dictionary in options["zone"]:
		assert_true(str(want["zone"]) != "deep_water", "sandal yokken derin orta istenmez")
	_own(high, ["boat"])
	var zones: Array = []
	for want: Dictionary in Requests.candidates(db, high, SPOT)["zone"]:
		zones.append(str(want["zone"]))
	assert_true("deep_water" in zones, "sandalla derin orta da")
	# Tuzak yoksa tuzak isteği yok; dip kamışı da yoksa çöp isteği yok.
	var plain := _save(10)
	options = Requests.candidates(db, plain, SPOT)
	assert_true(not options.has("trap") and not options.has("trash"), "tuzak ve dip kamışı yokken tuzak, çöp yok")


func test_rain_only_with_a_rain_forecast() -> void:
	var db := content()
	var rules := db.rules
	var dry := _save(6)
	var found := false
	for seed_value in 500:
		dry.seed = seed_value
		if not "rain" in Weather.forecast(rules, dry, 2):
			found = true
			break
	assert_true(found, "yağmursuz tahminli bir kayıt")
	assert_true(not Requests.candidates(db, dry, SPOT).has("rain"), "yağmur yokken yağmur isteği yok")
	var wet := _save(6)
	wet.flags[Weather.DEBUG_DAY] = DayClock.day(rules, wet.clock_s)
	wet.flags[Weather.DEBUG_KIND] = "rain"
	assert_eq(Requests.candidates(db, wet, SPOT).get("rain", []), [{ "weather": "rain" }], "bugün yağmur: yağmur isteği")


func test_size_target_is_round_and_within_three_stars() -> void:
	var db := content()
	for f in db.fish:
		var range_cm: Vector2i = f["size_cm"]
		for p: int in [db.requests.size_percentile.x, db.requests.size_percentile.y]:
			var cm := Requests.size_target(f, p)
			var top := FishTable.size_cm(f, FishTable.STAR_LIMITS[2] - 1)
			assert_true(cm > range_cm.x and cm <= maxi(range_cm.x + 1, top), "%s: %d cm türün boyunda, 3 yıldızın içinde"
					% [f["id"], cm])
			assert_true(cm % 5 == 0 or cm == range_cm.x + 1 or cm == top, "%s: %d cm 5'e yuvarlı" % [f["id"], cm])


func test_events_count_towards_requests() -> void:
	var catch_event := { "type": "catch", "fish": "tench", "size_cm": 40, "rarity": 1, "technique": "spin",
			"zone": "reeds", "phase": "night", "weather": "rain" }
	var cases := [
		[_req("species", { "fish": "tench" }), catch_event, 1],
		[_req("species", { "fish": "rudd" }), catch_event, 0],
		[_req("size", { "fish": "tench", "min_cm": 40 }), catch_event, 1],
		[_req("size", { "fish": "tench", "min_cm": 45 }), catch_event, 0],
		[_req("technique", { "technique": "spin" }), catch_event, 1],
		[_req("zone", { "zone": "reeds" }), catch_event, 1],
		[_req("zone", { "zone": "lily_cove" }), catch_event, 0],
		[_req("phase", { "phase": "night" }), catch_event, 1],
		[_req("rare", { "rarity": 2 }), catch_event, 0],
		[_req("rain", { "weather": "rain" }), catch_event, 1],
		[_req("release", {}), { "type": "release", "count": 1 }, 1],
		[_req("trash", {}), { "type": "trash", "count": 1 }, 1],
		[_req("trap", {}), { "type": "trap", "fish": "crayfish", "count": 3 }, 3],
		[_req("species", { "fish": "crayfish" }), { "type": "trap", "fish": "crayfish", "count": 2 }, 2],
		[_req("zone", { "zone": "reeds" }), { "type": "trap", "fish": "crayfish", "count": 2 }, 0],
		[_req("release", {}), catch_event, 0],
	]
	for c: Array in cases:
		assert_eq(Requests.counts_for(c[0], c[1]), int(c[2]), "%s ← %s" % [c[0]["kind"], c[1]["type"]])
	var save := SaveData.create_new(0)
	var r := _req("release", {})
	r["goal"] = 2
	save.requests.append(r)
	assert_eq(Requests.note(save, { "type": "release" }).size(), 0, "1/2")
	assert_eq(int(r["progress"]), 1, "ilerleme")
	assert_eq(Requests.note(save, { "type": "release" }).size(), 1, "2/2: bitti")
	assert_eq(Requests.note(save, { "type": "release" }).size(), 0, "biten istek yeniden bitmez")
	assert_eq(int(r["progress"]), 2, "ilerleme hedefte durur")


func test_reward_follows_rank() -> void:
	var db := content()
	var rules := db.requests
	for rank: int in [2, 6, 12, 20]:
		for seed_value in 20:
			var save := _save(rank)
			save.seed = seed_value
			_own(save, ["rod_spin_light", "rod_carp_1", "trap_1"])
			Requests.refill(db, save, SPOT)
			for r in save.requests:
				var mult := int(rules.template(str(r["kind"]))["mult_pm"])
				var base := (rules.coins_base + rules.coins_per_rank * rank) * mult / 1000.0
				var reward: Dictionary = r["reward"]
				var coins := int(reward["coins"])
				assert_true(coins % 5 == 0 and coins >= floori(base * 0.75 / 5.0) * 5 and coins <= ceili(base * 1.25 / 5.0) * 5,
						"rütbe %d %s: %d para (taban %.0f)" % [rank, r["kind"], coins, base])
				assert_eq(int(reward["xp"]), int((rules.xp_base + rules.xp_per_rank * rank) * mult / 1000.0),
						"rütbe %d %s: rütbe puanı" % [rank, r["kind"]])
				assert_eq(int(reward["love"]), int(rules.template(str(r["kind"]))["love"]), "sevgi şablondan")


func test_requests_survive_saving() -> void:
	var db := content()
	var save := _save(10)
	_own(save, ["rod_spin_light", "trap_1"])
	Requests.refill(db, save, SPOT)
	Requests.find_slot(save, 0)["progress"] = 1
	save.reroll_day = 3
	var back := SaveData.from_dict(save.to_dict())
	assert_eq(back.requests, save.requests, "istekler")
	assert_eq(back.request_serial, save.request_serial, "zarın sırası")
	assert_eq(back.request_day, save.request_day, "doldurulan gün")
	assert_eq(back.reroll_day, 3, "değiştirme günü")


## Her istek türünün yazısı iki dilde var ve değer sayısı yazının %'leriyle aynı; değerlerdeki adlar da.
func test_every_kind_has_a_text() -> void:
	var db := content()
	var table := _translations()
	var samples := {
		"species": { "fish": "tench" }, "size": { "fish": "tench", "min_cm": 35 }, "technique": { "technique": "spin" },
		"zone": { "zone": "reeds" }, "phase": { "phase": "night" }, "rare": { "rarity": db.rarity_index("rare") },
		"rain": { "weather": "rain" }, "release": {}, "trash": {}, "trap": {},
	}
	for kind: String in RequestRules.KINDS:
		assert_true(samples.has(kind), "örnek: " + kind)
		var r := _req(kind, samples.get(kind, {}))
		r["goal"] = 3
		var text := Requests.describe(db, r)
		var key: String = text[0]
		var args: Array = text[1]
		var row: PackedStringArray = table.get(key, PackedStringArray())
		assert_true(row.size() >= 3, "çevirisi yok: " + key)
		if row.size() < 3:
			continue
		for column in [1, 2]:
			assert_eq(row[column].count("%"), args.size(), "%s: %s değer sayısı" % [key, "EN" if column == 1 else "TR"])
		for arg: Variant in args:
			if arg is String:
				assert_true(table.has(str(arg)), "%s: adın çevirisi: %s" % [key, arg])


func _save(rank: int) -> SaveData:
	var save := SaveData.create_new(0)
	save.seed = 4242
	_rank(save, rank)
	return save


func _rank(save: SaveData, rank: int) -> void:
	save.xp = content().rank_xp[maxi(0, rank - 1)]


static func _own(save: SaveData, ids: Array) -> void:
	for id: String in ids:
		if not id in save.owned:
			save.owned.append(id)


static func _req(kind: String, want: Dictionary) -> Dictionary:
	return { "slot": 0, "kind": kind, "want": want, "goal": 5, "progress": 0, "day": 0, "serial": 0, "reward": {} }


## Yuvadaki isteği bitirip öder (döner: pay'in sonucu).
static func _finish(db: ContentDB, save: SaveData, slot: int) -> Dictionary:
	var r := Requests.find_slot(save, slot)
	r["progress"] = int(r["goal"])
	return Requests.pay(db, save, r)


static func _slot_of(list: Array, slot: int) -> Dictionary:
	for r: Dictionary in list:
		if int(r["slot"]) == slot:
			return r
	return {}


static func _sorted(list: Array) -> Array:
	var out := list.duplicate()
	out.sort()
	return out


## Tür bu açık bölgelerden birinde şamandıra ya da spinle (koşulsuz) gelir mi?
static func _comes_in(db: ContentDB, fish_id: String, zones: PackedStringArray) -> bool:
	for z in zones:
		for tech: String in ["float", "spin"]:
			if int(CatchOdds.species_ppm(db, db.zone(SPOT, z), { "technique": tech }).get(fish_id, 0)) > 0:
				return true
	return false


static func _translations() -> Dictionary:
	var table := {}
	var f := FileAccess.open("res://localization/strings.csv", FileAccess.READ)
	if f == null:
		return table
	while not f.eof_reached():
		var row := f.get_csv_line()
		if row.size() >= 1 and not row[0].is_empty():
			table[row[0]] = row
	return table
