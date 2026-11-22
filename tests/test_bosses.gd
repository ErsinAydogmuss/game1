extends BaseTest
## Bölge canavarları (yapı 5; Bosses, docs/gdd.md §10.9): her bölgenin bir canavarı, yalnızca bölgenin etkili tekniğiyle
## ve istediği takımın hepsi (ya da daha iyisi) kuşanılıyken çıkar; atış başına zar; belirme yeri; çekişme beceri ister
## ve eksik takımla tutulmaz; altısı finalin şartı.

const SPOT := "big_lake"
const RUNS := 30
## Tekniğin takılma uzaklıkları (test_reel_model ile aynı).
const DISTANCES := {
	"float": [4.0, 5.0, 6.0, 7.0, 8.0, 9.0],
	"bottom": [8.0, 9.5, 11.0, 12.5, 14.0, 15.0],
	"spin": [3.5, 4.5, 5.5, 6.0, 7.0, 8.0],
	"fly": [3.0, 3.5, 4.0, 4.5, 5.0, 5.5],
}


## Canavarın istediği takımla (başlangıç takımının üstüne) kurulan takım.
static func _boss_gear(boss_id: String) -> GearStats:
	var db := content()
	var items := db.gear_start.duplicate()
	for gid: String in (db.fish_by_id(boss_id)["fight"]["gear"] as PackedStringArray):
		items[str(db.gear_item(gid)["category"])] = gid
	var none: Array[String] = []
	return GearStats.from_items(db, items, none)


## Yeterince ilerlemiş bir kayıt: rütbe en yüksek bölgenin rütbesi, sandal var.
static func _save() -> SaveData:
	var db := content()
	var save := SaveData.create_new(77)
	save.xp = db.rank_xp[13]
	save.owned.append("boat")
	return save


func _model(boss_id: String, gear: GearStats, distance: float, i: int) -> ReelModel:
	var db := content()
	return ReelModel.new(db.rules, db.fish_by_id(boss_id)["fight"], gear.reel_speed, distance,
			gear.range_m + db.rules.escape_extra + gear.escape_extra, false, Dice.derive(5151, i), gear,
			Bosses.PERCENTILE)


func _caught(boss_id: String, gear: GearStats, style: ReelBot.Style, reaction: float) -> Dictionary:
	var technique := Bosses.technique_of(content(), SPOT, boss_id)
	var distances: Array = DISTANCES[technique]
	var caught := 0
	var total := 0.0
	for i in RUNS:
		var result := ReelBot.play(_model(boss_id, gear, distances[i % distances.size()], i), ReelBot.make(style, reaction))
		if int(result["outcome"]) == ReelModel.Outcome.CAUGHT:
			caught += 1
			total += float(result["seconds"])
	return { "caught": float(caught) / RUNS, "mean": total / maxi(1, caught) }


## Her bölgenin bir canavarı var (fish.json boss), kimlikleri Bosses.IDS'te bölgelerin sırasıyla; canavar hikâye
## balığı gibi (zarla gelmez, satılmaz), Efsanevi, yalnızca bölgesinin etkili tekniğiyle gelir, ödülü var.
func test_every_zone_has_one_boss() -> void:
	var db := content()
	assert_eq(Bosses.all_of(db, SPOT), Bosses.IDS, "kimlikler bölgelerin sırasıyla")
	for z in db.zones_of(SPOT):
		var id := db.boss_of(str(z["id"]))
		assert_true(not id.is_empty(), "%s: canavarı var" % z["id"])
		var def := db.fish_by_id(id)
		assert_true(bool(def["story"]) and bool(def["release_only"]), "%s: çağrılır, göle bırakılır" % id)
		assert_eq(db.rarity_id(int(def["rarity"])), "legendary", "%s: Efsanevi" % id)
		assert_eq(Bosses.technique_of(db, SPOT, id), str(z["effective"]), "%s: bölgenin etkili tekniği" % id)
		assert_true(db.affinity(id, str(z["effective"])) > 0.0, "%s: o teknikle gelir" % id)
		assert_true(Bosses.reward(db, id) > 0, "%s: ödülü var" % id)
		assert_true(not (id in (z["fish_ids"] as PackedStringArray)), "%s: bölgenin tablosunda yok" % id)
		assert_true(not (id in (db.spot(SPOT)["story_fish"] as PackedStringArray)), "%s: defterin balıklarında değil" % id)
	var rewards: Array[int] = []
	for id in Bosses.IDS:
		rewards.append(Bosses.reward(db, id))
	assert_eq(rewards.max(), Bosses.reward(db, "deep_lord"), "en büyük ödül Derin Bey'in")


## Çıkma şartı: canavar tutulmadı, bölge açık, elindeki teknik etkili, istediği takımın hepsi kuşanılı; aynı yuvada
## daha iyisi de sayılır. Tutulunca o bölgede bir daha çıkmaz.
func test_boss_needs_the_effective_technique_and_full_gear() -> void:
	var db := content()
	var save := _save()
	for id in Bosses.IDS:
		var zone_id := str(db.fish_by_id(id)["boss"])
		var technique := Bosses.technique_of(db, SPOT, id)
		var gear := _boss_gear(id)
		assert_true(Bosses.missing(db, id, gear).is_empty(), "%s: istediği takımla eksik yok" % id)
		assert_true(Bosses.ready(db, save, SPOT, zone_id, technique, gear), "%s: şartlar tutuyor" % id)
		assert_true(not Bosses.ready(db, save, SPOT, zone_id, "float" if technique != "float" else "spin", gear),
				"%s: başka teknikle çıkmaz" % id)
		var best := GearStats.best(db, technique)
		assert_true(Bosses.missing(db, id, best).is_empty(), "%s: en iyi takım (daha iyisi) da sayılır" % id)
		var rods := db.rods_of(technique)
		if rods.size() > 1:
			var items := gear.items.duplicate()
			items["rod"] = str(rods[0]["id"])
			var none: Array[String] = []
			var weak := GearStats.from_items(db, items, none)
			assert_true(not Bosses.missing(db, id, weak).is_empty(), "%s: ilk kamışla eksik" % id)
			assert_true(not Bosses.ready(db, save, SPOT, zone_id, technique, weak), "%s: eksik takımla çıkmaz" % id)
		var low := SaveData.create_new(77)
		assert_true(not Bosses.ready(db, low, SPOT, zone_id, technique, gear) or Zones.unlocked(db, low,
				db.zone(SPOT, zone_id)), "%s: kilitli bölgede çıkmaz" % id)
		var caught := _save()
		Records.add(caught.records, id, 100, 5, 0)
		assert_true(Bosses.caught(caught, id), "%s: tutuldu" % id)
		assert_true(not Bosses.ready(db, caught, SPOT, zone_id, technique, gear), "%s: tutulunca çıkmaz" % id)
	# Kilitli bölge: rütbe 1'de derin orta.
	var fresh := SaveData.create_new(77)
	assert_true(not Bosses.ready(db, fresh, SPOT, "deep_water", "bottom", _boss_gear("deep_lord")), "kilitli bölgede çıkmaz")


## Atış başına zar: kaydın seed'inden ve atış sayısından (aynı atış aynı sonuç), oranı CHANCE_PPM civarında; arka
## arkaya çok uzun bekletmez.
func test_boss_roll_per_cast() -> void:
	var save := _save()
	var hits := 0
	var longest := 0
	var dry := 0
	for cast in 2000:
		var hit := Bosses.roll(save, cast)
		assert_eq(hit, Bosses.roll(save, cast), "aynı atış aynı zar")
		if hit:
			hits += 1
			dry = 0
		else:
			dry += 1
			longest = maxi(longest, dry)
	assert_between(float(hits) / 2000.0, Bosses.CHANCE_PPM / 1e6 - 0.04, Bosses.CHANCE_PPM / 1e6 + 0.04, "oran")
	assert_true(longest <= 25, "en uzun boş seri kısa (%d)" % longest)


## Belirme yeri: her bölgede atış noktasından (derin ortada şamandıradan) atılan takımın çevresinde, bölgenin derin
## suyu, balıkçıdan en az NEAR uzakta.
func test_boss_rises_in_its_zone() -> void:
	var db := content()
	var lake := db.lake(SPOT)
	for z in db.zones_of(SPOT):
		var zone_id := str(z["id"])
		var k := lake.zone_ids.find(zone_id)
		var angler: Vector2 = (z["buoys"] as Array)[0] if bool(z["boat"]) else (z["stands"] as Array)[0]
		var rig := Dice.NO_POINT
		for d: float in [6.0, 5.0, 7.0, 4.0, 8.0]:
			for a in 36:
				var p: Vector2 = angler + Vector2.from_angle(deg_to_rad(a * 10.0)) * d
				if lake.zone_at(p) == k and lake.is_deep(p, float(z.get("min_depth", db.rules.min_depth))):
					rig = p
					break
			if Dice.is_point(rig):
				break
		assert_true(Dice.is_point(rig), "%s: takım suya düşer" % zone_id)
		var point := Bosses.rise_point(db, SPOT, angler, rig)
		assert_true(Dice.is_point(point), "%s: canavar belirir" % zone_id)
		if Dice.is_point(point):
			assert_eq(lake.zone_at(point), k, "%s: bölgenin suyunda" % zone_id)
			assert_true(point.distance_to(angler) >= Bosses.NEAR, "%s: balıkçıdan uzakta" % zone_id)


## Çekişme: istediği takımla kusursuz oyuncu ve 0,4 sn tepkili oyuncu tutar, 0,7 sn tepkili çoğunlukla; hep basılı
## tutan tutamaz (dalışta misina kopar); ilk kamışla (eksik takım: fazla iri gibi) kimse tutamaz. 0,4 sn tepkiyle
## çekişme 20–60 sn.
func test_boss_fight_needs_skill_and_gear() -> void:
	var db := content()
	for id in Bosses.IDS:
		var gear := _boss_gear(id)
		var perfect := _caught(id, gear, ReelBot.Style.PERFECT, 0.0)
		assert_eq(perfect["caught"], 1.0, "%s: kusursuz oyuncu tutar" % id)
		var good := _caught(id, gear, ReelBot.Style.REACT, 0.4)
		assert_true(float(good["caught"]) >= 0.95, "%s: 0,4 sn tepkiyle tutulur (%.2f)" % [id, good["caught"]])
		assert_between(float(good["mean"]), 20.0, 60.0, "%s: 0,4 sn tepkiyle süre" % id)
		var slow := _caught(id, gear, ReelBot.Style.REACT, 0.7)
		assert_true(float(slow["caught"]) >= 0.7, "%s: 0,7 sn tepkiyle çoğunlukla (%.2f)" % [id, slow["caught"]])
		var hold := _caught(id, gear, ReelBot.Style.ALWAYS, 0.0)
		assert_eq(hold["caught"], 0.0, "%s: hep basılı tutan tutamaz" % id)
		var technique := Bosses.technique_of(db, SPOT, id)
		var items := gear.items.duplicate()
		items["rod"] = str(db.rods_of(technique)[0]["id"])
		var none: Array[String] = []
		var weak := GearStats.from_items(db, items, none)
		var lost := _caught(id, weak, ReelBot.Style.PERFECT, 0.0)
		assert_eq(lost["caught"], 0.0, "%s: ilk kamışla tutulmaz" % id)


## Altı canavar finalin şartı (Secret.final_ready); debug_catch_all hepsini defterde tutulmuş sayar.
func test_all_bosses_open_the_final() -> void:
	var db := content()
	var save := _save()
	save.letters = Secret.LETTERS.size()
	save.map_pieces = SaveData.MAX_MAP_PIECES
	save.flags[Secret.DOUGH_FLAG] = true
	assert_true(not Bosses.all_caught(save) and not Secret.final_ready(save), "canavarsız final yok")
	for i in Bosses.IDS.size():
		Records.add(save.records, Bosses.IDS[i], 100, 5, 0)
		assert_eq(Bosses.caught_count(db, save, SPOT), i + 1, "sayaç")
		assert_eq(Secret.final_ready(save), i == Bosses.IDS.size() - 1, "final yalnızca altısıyla (%d)" % (i + 1))
	var other := _save()
	Bosses.debug_catch_all(db, other)
	assert_true(Bosses.all_caught(other), "debug_catch_all")
	assert_eq(Records.species_count(other.records), 0, "canavarlar defterin tür sayısına (kıyafetlerin şartı) girmez")
