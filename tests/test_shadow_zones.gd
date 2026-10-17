extends BaseTest
## Bölgeli gölde gölgeler (Dalga 2; data/spots.json big_lake): balıkçının çevresinde ve yalnızca
## avlandığı bölgede doğar (defterin gösterdiği oran gelen balığın oranı); türü o bölgeden;
## dolaşırken bölgesinde kalır; balıkçı yürüyünce ya da başka yere geçince gölgeler de gelir; şans
## garantisi avlanılan bölgede doğar.

const SPOT := "big_lake"
const DOCK := Vector2(0, 4)
const REEDS := Vector2(-17.5, 2.0)
const LILY := Vector2(14.0, 4.2)
const STREAM := Vector2(-16.0, -10.2)
const BUOY := Vector2(-3.0, -17.0)
const OPEN_START: Array[String] = ["dock_cove", "reeds"]
const OPEN_ALL: Array[String] = ["dock_cove", "reeds", "lily_cove", "rocky_point", "stream_mouth"]
const REACH := 8.0


func _sim(seed_value: int, angler: Vector2, open: Array[String], pity_floor: int = -1) -> ShadowSim:
	var db := content()
	return ShadowSim.new(db, db.spot(SPOT), db.lake(SPOT), seed_value, false, angler,
			{ "reach": REACH, "open": PackedStringArray(open), "pity_floor": pity_floor })


func _zone_of(s: FishShadow) -> Dictionary:
	return content().zones_of(SPOT)[s.zone]


## Doğan her gölge balıkçının çevresinde (menzil + reach_extra), avlandığı bölgenin derin suyunda:
## başka bölgelerin suyu menzildeyken de (dere ağzında sazlık ve iskele koyu, kayalık burunda
## nilüferli koy).
func test_spawns_near_the_angler_in_the_fishing_zone() -> void:
	var lake := content().lake(SPOT)
	var reach := REACH + content().rules.reach_extra
	for place: Array in [[REEDS, "reeds"], [STREAM, "stream_mouth"], [LILY, "lily_cove"],
			[Vector2(14.0, -8.5), "rocky_point"], [DOCK, "dock_cove"]]:
		var at: Vector2 = place[0]
		var bad := 0
		var born := 0
		for seed_value in 8:
			var sim := _sim(seed_value, at, OPEN_ALL)
			# Doğduğu andaki yer (sonra dolaşır).
			var fresh: Array[Array] = []
			for s in sim.shadows:
				fresh.append([s, s.pos])
			for step in 900:
				for e in sim.step(at, Vector2.ZERO, false, 0):
					if str(e["type"]) == "spawn":
						var s := sim.find(int(e["shadow"]))
						fresh.append([s, s.pos])
			for pair in fresh:
				born += 1
				var s: FishShadow = pair[0]
				var pos: Vector2 = pair[1]
				var zone := _zone_of(s)
				var ok: bool = str(zone["id"]) == place[1] and pos.distance_to(at) <= reach + 0.01 \
						and lake.is_deep(pos, float(zone["min_depth"]))
				if not ok:
					bad += 1
		assert_true(born >= 32, "%s: gölgeler doğdu (%d)" % [place[1], born])
		assert_eq(bad, 0, "%s: hepsi balıkçının çevresinde, avlandığı bölgenin derin suyunda" % place[1])


## Gölgenin türü doğduğu bölgenin listesinden; sazlıkta derin ortanın yayını yok.
func test_species_come_from_the_zone() -> void:
	var counts := {}
	for seed_value in 60:
		var sim := _sim(seed_value, DOCK, OPEN_ALL)
		for s in sim.shadows:
			var zone := _zone_of(s)
			var ids: PackedStringArray = zone["fish_ids"]
			assert_true(s.fish_id in ids, "%s %s bölgesinin türü" % [s.fish_id, zone["id"]])
			counts[zone["id"]] = int(counts.get(zone["id"], 0)) + 1
	assert_true(int(counts.get("dock_cove", 0)) > 100 and counts.size() == 1, "iskelede bütün gölgeler iskele koyunda (%s)" % str(counts))


## Dolaşan gölge kendi bölgesinde kalır (kaçarken ve şamandıraya giderken sınırı geçebilir).
func test_wandering_stays_in_the_zone() -> void:
	var lake := content().lake(SPOT)
	var samples := 0
	var outside := 0
	for seed_value in 6:
		var sim := _sim(100 + seed_value, DOCK, OPEN_ALL)
		for step in 3600:
			sim.step(DOCK, Vector2.ZERO, false, 0)
			if step % 60 != 0:
				continue
			for s in sim.shadows:
				if s.mode == FishShadow.Mode.FLEE:
					continue
				samples += 1
				if lake.zone_at(s.pos) != s.zone:
					outside += 1
	assert_true(samples > 1000, "örnek (%d)" % samples)
	assert_true(outside * 50 <= samples, "dolaşırken bölgede kalır (%d / %d dışarıda)" % [outside, samples])


## Balıkçı gölün öbür ucuna yürüyünce eski gölgeler çekilir, yenileri yeni yerin çevresinde doğar.
func test_walking_brings_shadows_along() -> void:
	var reach := REACH + content().rules.reach_extra
	var sim := _sim(7, STREAM, OPEN_ALL)
	for step in 300:
		sim.step(STREAM, Vector2.ZERO, false, 0)
	for step in 8 * FishingRules.HZ:
		sim.step(LILY, Vector2.ZERO, false, 0)
	var near := 0
	for s in sim.shadows:
		if s.pos.distance_to(LILY) <= reach and s.mode != FishShadow.Mode.FLEE:
			near += 1
	assert_true(near >= 3, "8 sn içinde yeni yerin çevresinde en az 3 gölge (%d)" % near)


## Balıkçı komşu bölgeye yürüyünce eski bölgenin dolaşan gölgeleri çekilir, yenileri yeni bölgede
## doğar (defterin oranı yeni bölgenin).
func test_shadows_follow_the_angler_into_a_new_zone() -> void:
	var reeds := content().lake(SPOT).zone_index("reeds")
	var sim := _sim(9, DOCK, OPEN_ALL)
	for step in 300:
		sim.step(DOCK, Vector2.ZERO, false, 0)
	for step in 12 * FishingRules.HZ:
		sim.step(REEDS, Vector2.ZERO, false, 0)
	assert_eq(sim.player_zone, reeds, "balıkçı sazlıkta avlanıyor")
	var here := 0
	for s in sim.shadows:
		if s.mode == FishShadow.Mode.FLEE:
			continue
		assert_eq(s.zone, reeds, "dolaşan gölge sazlığın")
		here += 1
	assert_true(here >= 3, "12 sn içinde sazlıkta en az 3 gölge (%d)" % here)


## Kilitli bölgenin çitinin önünde (en yakın su kilitli bölgenin): açık komşu bölgede avlanılır.
func test_locked_neighbour_falls_back_to_an_open_zone() -> void:
	var lake := content().lake(SPOT)
	var dock := lake.zone_index("dock_cove")
	var near_gate := Vector2(9.9, 3.6)
	assert_eq(lake.zone_of(near_gate), lake.zone_index("lily_cove"), "en yakın su nilüferli koyun")
	var sim := _sim(4, near_gate, OPEN_START)
	assert_eq(sim.player_zone, dock, "kilitli nilüferli koy yerine iskele koyunda avlanılır")
	for s in sim.shadows:
		assert_eq(s.zone, dock, "gölgeler açık bölgede")


## Izgaranın dışındaki çayır (dükkânın arkası): bölge en yakın hücreninki; kilit nedeni boş bölgede
## hata vermez.
func test_zone_beyond_the_grid() -> void:
	var db := content()
	var behind := Vector2(0.0, 11.5)
	assert_eq(db.lake(SPOT).zone_at(behind), -1, "ızgaranın dışı")
	assert_eq(str(Zones.at(db, SPOT, behind).get("id", "")), "dock_cove", "en yakın hücrenin bölgesi")
	var session := FishingSession.new(db, SPOT, GearStats.starter(db), 3, false, false, -1, PackedStringArray(OPEN_START))
	session.relocate(behind)
	assert_eq(session.zone_id(), "dock_cove", "dükkânın arkasında da iskele koyunda avlanılır")
	assert_eq(Zones.lock_reason(db, SaveData.new(), {}), {}, "bölge yoksa neden de yok")


## Hızlı geçiş: gölgeler hemen yeni yerin çevresinde.
func test_relocate_is_immediate() -> void:
	var reach := REACH + content().rules.reach_extra
	var sim := _sim(11, DOCK, OPEN_ALL)
	var events := sim.relocate(LILY)
	assert_eq(sim.shadows.size(), 4, "gölgeler hemen doğar")
	var spawned := 0
	for e in events:
		spawned += 1 if str(e["type"]) == "spawn" else 0
	assert_eq(spawned, 4, "doğma olayları")
	for s in sim.shadows:
		assert_true(s.pos.distance_to(LILY) <= reach + 0.01, "yeni yerin çevresinde")
	assert_eq(sim.player_zone, content().lake(SPOT).zone_index("lily_cove"), "balıkçının bölgesi")


## Derin orta yalnızca sandalla: sandalsız oradaki suda gölge doğmaz; sandalda yalnızca orada.
func test_boat_zone_needs_the_boat() -> void:
	var deep := content().lake(SPOT).zone_index("deep_water")
	for seed_value in 20:
		var ashore := _sim(seed_value, BUOY, OPEN_ALL)
		for s in ashore.shadows:
			assert_true(s.zone != deep, "sandalsız derin ortada gölge yok")
		var boat := _sim(seed_value, BUOY, ["deep_water"] as Array[String])
		for s in boat.shadows:
			assert_eq(s.zone, deep, "sandaldayken gölgeler derin ortada")


## Şans garantisi balıkçının bölgesinde doğar.
func test_pity_spawns_in_the_players_zone() -> void:
	var db := content()
	var rare := db.rarity_index("rare")
	var dock := db.lake(SPOT).zone_index("dock_cove")
	for seed_value in 10:
		var sim := _sim(seed_value, DOCK, OPEN_ALL, rare)
		var pity := 0
		for s in sim.shadows:
			if s.pity:
				pity += 1
				assert_eq(s.zone, dock, "garanti gölgesi balıkçının bölgesinde")
				assert_true(s.rarity >= rare, "garanti nadir ya da üstü")
		assert_eq(pity, 1, "tek garanti gölgesi")


## Aynı seed ve aynı yol: aynı gölgeler.
func test_same_seed_same_shadows() -> void:
	var a := _run_path(5)
	var b := _run_path(5)
	var c := _run_path(6)
	assert_eq(a, b, "aynı seed, aynı yol: aynı gölgeler")
	assert_true(a != c, "başka seed: başka gölgeler")


func _run_path(seed_value: int) -> PackedStringArray:
	var sim := _sim(seed_value, DOCK, OPEN_ALL)
	var out := PackedStringArray()
	for step in 2400:
		var angler := DOCK.lerp(LILY, clampf(float(step - 600) / 900.0, 0.0, 1.0))
		sim.step(angler, Vector2.ZERO, false, 0)
	for s in sim.shadows:
		out.append("%s %d %.4f %.4f" % [s.fish_id, s.size_cm, s.pos.x, s.pos.y])
	return out


## Oturum: balıkçının bölgesi, erişim ve yakalanan balığın bölgesi.
func test_session_tracks_the_zone() -> void:
	var db := content()
	var session := FishingSession.new(db, SPOT, GearStats.starter(db), 3, false, false, -1, PackedStringArray(OPEN_START))
	assert_eq(session.zone_id(), "dock_cove", "iskelede başlar")
	session.relocate(REEDS)
	assert_eq(session.zone_id(), "reeds", "sazlığa geçti")
	assert_eq(session.angler, REEDS, "balıkçının yeri")
	var types := PackedStringArray()
	for e in session.poll_events():
		types.append(str(e["type"]))
	assert_true("spawn" in types and "despawn" in types, "geçişte gölgeler yenilenir")


## Erişim: rütbe ve sandal.
func test_zone_access() -> void:
	var db := content()
	var save := SaveData.new()
	assert_eq(Zones.open_ids(db, save, SPOT), PackedStringArray(["dock_cove", "reeds"]), "başta iskele koyu ve sazlık")
	save.xp = db.rank_xp[4]
	assert_eq(Zones.open_ids(db, save, SPOT), PackedStringArray(["dock_cove", "reeds", "lily_cove", "rocky_point"]),
			"rütbe 5: nilüferli koy ve kayalık burun")
	save.xp = db.rank_xp[8]
	assert_true(not "deep_water" in Zones.open_ids(db, save, SPOT), "derin orta karadan avlanmaz")
	assert_eq(Zones.open_ids(db, save, SPOT, true), PackedStringArray(), "sandal yoksa derin orta kapalı")
	var lily := db.zone(SPOT, "lily_cove")
	save.xp = 0
	assert_eq(str(Zones.lock_reason(db, save, lily).get("key", "")), "UI_ZONE_LOCKED_RANK", "kilidin nedeni rütbe")
	assert_eq(Zones.unlocked_between(db, SPOT, 2, 3).size(), 1, "rütbe 3'te bir bölge açılır")
	assert_eq(Zones.place(db, SPOT, "reeds"), db.zone(SPOT, "reeds"), "oranlar bölgeden")
	assert_eq(Zones.place(db, "home_lake", ""), db.spot("home_lake"), "bölgesiz: gölün kendisi")
