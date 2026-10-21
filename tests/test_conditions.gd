extends BaseTest
## Gölün koşulları ve oranlar (Dalga 4, docs/gdd.md §10.5): vakit, hava ve göl sevgisi türlerin
## oranını değiştirir (CatchOdds iki aşamada); yalnızca belli vakitte gelen türler (Ay Turnası gece,
## Kocabaş yağmurlu gece) o koşulda gelir; koşulsuz bağlamda her sayı eskisi gibi; şans garantisi o
## koşulda gelmeyen kademeyi zorlamaz; oturumun koşulu değişince oranlar, takım profili ve gölgeler
## yenilenir.

const SPOT := "big_lake"
const LILY := Vector2(14.0, 4.2)
const BUOY := Vector2(-3.0, -17.0)
const OPEN_ALL: Array[String] = ["dock_cove", "reeds", "lily_cove", "rocky_point", "stream_mouth", "deep_water"]
## Dalga 4'ten önceki sürümün (dfa423b) koşulsuz oranları (büyük gölün bölgeleri; yeni türlerin bölgeleri
## dahil: Ay Turnası ve Kocabaş koşulsuz bağlamda hiç çıkmaz). Bütün bölge × teknik satırları o sürümle
## karşılaştırıldı (19 satır, hepsi aynı); burada bir kısmı.
const BEFORE_WAVE_4 := {
	"dock_cove/float": { "bream": 100000, "carp": 200000, "perch": 180000, "pike": 80000, "rudd": 260000,
		"silverside": 140000, "wels": 40000 },
	"dock_cove/spin": { "perch": 608108, "pike": 378378, "wels": 13514 },
	"lily_cove/float": { "carp": 240000, "golden_carp": 60000, "perch": 260000, "pike": 220000, "rudd": 220000 },
	"lily_cove/spin": { "perch": 457746, "pike": 542254 },
	"stream_mouth/fly": { "brook_trout": 72727, "chub": 327273, "rudd": 54545, "trout": 545455 },
	"deep_water/bottom": { "bream": 119272, "carp": 251098, "mirror_carp": 75329, "perch": 28876, "pike": 30132,
		"sturgeon": 28249, "wels": 414313, "zander": 52731 },
}


static func _cond(phase: String, weather: String = "clear", love: int = 1) -> Dictionary:
	return { "phase": phase, "weather": weather, "love": love }


static func _with(ctx: Dictionary, technique: String) -> Dictionary:
	var out := ctx.duplicate()
	out["technique"] = technique
	return out


## Koşul anahtarı olmayan bağlamda (ya da yalnızca sevgi 1: bütün çarpanlar 1000) oranlar bit bit
## eskisi gibi: ikinci aşama hiç çalışmaz.
func test_no_conditions_keep_every_number() -> void:
	var db := content()
	for z in db.zones_of(SPOT) + [db.spot("home_lake")]:
		for technique: String in ContentDB.TECHNIQUES:
			var plain := CatchOdds.species_ppm(db, z, { "technique": technique })
			assert_eq(CatchOdds.species_ppm(db, z, { "technique": technique, "love": 1 }), plain,
					"%s, %s: sevgi 1 oranı değiştirmez" % [z["id"], technique])
			assert_true(not plain.has("moon_pike") and not plain.has("kocabas"), "%s: koşulsuz efsane yok" % z["id"])
	var home := CatchOdds.species_ppm(db, db.spot("home_lake"))
	assert_eq(int(home["rudd"]), 350000, "testlerin gölünde kızılkanat yine %35")
	for key: String in BEFORE_WAVE_4:
		var zone := db.zone(SPOT, key.get_slice("/", 0))
		assert_eq(CatchOdds.species_ppm(db, zone, { "technique": key.get_slice("/", 1) }), BEFORE_WAVE_4[key],
				"%s: Dalga 4'ten önceki sayılar" % key)


## İkinci aşama (koşullu): oran, ağırlık × yatkınlık × vakit × hava × sevginin Nadir+ payıyla ondalıklı
## bağımsız bir hesapla aynı; toplam tam 1e6. Pay: koşul çarpanı binde tamsayıyla kesilir (factor_pm, en çok
## üç kesme: göreli %0,3) ve iki normalleştirmenin yuvarlaması (birkaç ppm). Eksik ya da yanlış bir çarpan
## en az %20 saptırır.
func test_second_pass_matches_reference() -> void:
	var db := content()
	var love_from := db.rarity_index(db.rules.love_from)
	var cases := [["lily_cove", "float", _cond("night", "rain", 5)], ["lily_cove", "spin", _cond("night", "cloudy", 2)],
			["deep_water", "bottom", _cond("night", "rain", 10)], ["rocky_point", "spin", _cond("morning", "fog", 3)],
			["stream_mouth", "fly", _cond("evening", "rain", 7)], ["dock_cove", "float", _cond("noon", "cloudy", 1)]]
	for c: Array in cases:
		var zone := db.zone(SPOT, str(c[0]))
		var technique := str(c[1])
		var cond: Dictionary = c[2]
		var got := CatchOdds.species_ppm(db, zone, _with(cond, technique))
		var ids: PackedStringArray = zone["fish_ids"]
		var weights: PackedInt32Array = zone["fish_weights"]
		var share := {}
		var total := 0.0
		for i in ids.size():
			var id := ids[i]
			if not CatchOdds.available(db, id, cond):
				continue
			var w := float(weights[i]) * db.affinity(id, technique) * db.when_mult(id, str(cond["phase"])) \
					* db.weather_mult(id, str(cond["weather"]))
			if int(db.fish_by_id(id)["rarity"]) >= love_from:
				w *= LakeLove.rare_bonus_pm(db.rules, int(cond["love"])) / 1000.0
			if w > 0.0:
				share[id] = w
				total += w
		var sum := 0
		for id: String in got:
			sum += int(got[id])
		assert_eq(sum, Dice.PPM, "%s/%s: toplam 1e6" % [c[0], technique])
		assert_eq(got.size(), share.size(), "%s/%s: aynı türler" % [c[0], technique])
		for id: String in share:
			var want := float(share[id]) / total * Dice.PPM
			var slack := want * 0.003 + 4.0
			assert_between(float(got.get(id, -100)), want - slack, want + slack, "%s/%s %s: %d ≈ %.0f" % [c[0], technique,
					id, int(got.get(id, -1)), want])


func test_moon_pike_only_at_night() -> void:
	var db := content()
	var lily := db.zone(SPOT, "lily_cove")
	for phase: String in ["morning", "noon", "evening"]:
		var day := CatchOdds.species_ppm(db, lily, _with(_cond(phase), "spin"))
		assert_true(not day.has("moon_pike"), "%s: Ay Turnası yok" % phase)
	var night := CatchOdds.species_ppm(db, lily, _with(_cond("night"), "spin"))
	assert_between(float(night.get("moon_pike", 0)) / Dice.PPM, 0.04, 0.12, "gece spinle Ay Turnası (%s)" % str(night.get("moon_pike", 0)))
	var floater := CatchOdds.species_ppm(db, lily, _with(_cond("night"), "float"))
	assert_between(float(floater.get("moon_pike", 0)) / Dice.PPM, 0.01, 0.05, "gece şamandırayla Ay Turnası az")
	for z in db.zones_of(SPOT):
		if str(z["id"]) != "lily_cove":
			assert_true(not CatchOdds.species_ppm(db, z, _with(_cond("night"), "float")).has("moon_pike"),
					"%s: Ay Turnası yalnızca nilüferli koyda" % z["id"])


func test_kocabas_only_on_rainy_nights() -> void:
	var db := content()
	var deep := db.zone(SPOT, "deep_water")
	var storm := CatchOdds.species_ppm(db, deep, _with(_cond("night", "rain"), "bottom"))
	assert_between(float(storm.get("kocabas", 0)) / Dice.PPM, 0.03, 0.12, "fırtınalı gece dipte Kocabaş (%s)" % str(storm.get("kocabas", 0)))
	for c: Dictionary in [_cond("night", "clear"), _cond("night", "fog"), _cond("evening", "rain"), _cond("morning", "rain")]:
		assert_true(not CatchOdds.species_ppm(db, deep, _with(c, "bottom")).has("kocabas"), "Kocabaş yok: %s" % str(c))


## Vakit ve hava türün sevdiği zamanda payını artırır (yayın gece, kadife sabah, tatlısu kefali
## yağmurda).
func test_preferences_shift_the_odds() -> void:
	var db := content()
	var deep := db.zone(SPOT, "deep_water")
	var noon := CatchOdds.species_ppm(db, deep, _with(_cond("noon"), "bottom"))
	var night := CatchOdds.species_ppm(db, deep, _with(_cond("night"), "bottom"))
	assert_true(int(night["wels"]) > int(noon["wels"]), "yayın gece öğleden sık")
	var noon_ratio := float(noon["wels"]) / float(noon["carp"])
	var night_ratio := float(night["wels"]) / float(night["carp"])
	assert_true(night_ratio > noon_ratio * 1.5, "gece yayın sazana göre çok daha sık (%.2f → %.2f)" % [noon_ratio, night_ratio])
	var reeds := db.zone(SPOT, "reeds")
	var morning := CatchOdds.species_ppm(db, reeds, _with(_cond("morning"), "float"))
	var evening := CatchOdds.species_ppm(db, reeds, _with(_cond("noon"), "float"))
	assert_true(int(morning["tench"]) > int(evening["tench"]), "kadife sabah öğleden sık")
	var rocky := db.zone(SPOT, "rocky_point")
	var dry := CatchOdds.species_ppm(db, rocky, _with(_cond("noon", "clear"), "float"))
	var wet := CatchOdds.species_ppm(db, rocky, _with(_cond("noon", "rain"), "float"))
	assert_true(int(wet["chub"]) > int(dry["chub"]), "tatlısu kefali yağmurda sık")


## Her bölgede, her teknikte, her vakit, hava ve sevgi seviyesinde oranlar toplamı tam 1e6 (tür
## varsa); taşma payı: ilk aşamanın en büyük ara çarpımı ve ikinci aşamanınki 64 bitin çok altında.
func test_every_condition_sums_to_one_million() -> void:
	var db := content()
	var attracts: Array[Dictionary] = [{}]
	for g in db.gear:
		if g.has("attract"):
			attracts.append(g["attract"])
	var first_max := 0.0
	var factor_max := 0
	for z in db.zones_of(SPOT):
		var ids: PackedStringArray = z["fish_ids"]
		var weights: PackedInt32Array = z["fish_weights"]
		for technique: String in ContentDB.TECHNIQUES:
			for i in ids.size():
				for attract in attracts:
					first_max = maxf(first_max, float(weights[i]) * float(attract.get(ids[i], 1.0)) * 1000.0 \
							* db.affinity(ids[i], technique) * 1000.0 * Dice.PPM)
			for phase: String in DayClock.PHASES:
				for weather: String in Weather.KINDS:
					for love: int in [1, 6, 10]:
						var ctx := _with(_cond(phase, weather, love), technique)
						for i in ids.size():
							factor_max = maxi(factor_max, CatchOdds.factor_pm(db, ids[i], ctx))
						var odds := CatchOdds.species_ppm(db, z, ctx)
						if odds.is_empty():
							continue
						var total := 0
						for id: String in odds:
							total += int(odds[id])
							assert_true(int(odds[id]) > 0, "%s: %s oranı pozitif" % [z["id"], id])
						assert_eq(total, Dice.PPM, "%s, %s, %s, %s: toplam 1e6" % [z["id"], technique, phase, weather])
	assert_true(first_max < 9.0e17, "ilk aşamanın ara çarpımı 64 bitin altında (%s)" % str(first_max))
	assert_true(float(Dice.PPM) * factor_max * Dice.PPM < 9.0e17, "ikinci aşamanınki de (çarpan en çok binde %d)" % factor_max)


## Şans garantisi o koşulda gelebilen kademeyi verir: nilüferli koyda Efsanevi yalnızca gece.
func test_pity_follows_the_conditions() -> void:
	var db := content()
	var lily := db.zone(SPOT, "lily_cove")
	var legendary := db.rarity_index("legendary")
	assert_eq(CatchOdds.top_rarity(db, lily, "float", _cond("noon")), db.rarity_index("epic"), "öğle en çok Destansı")
	assert_eq(CatchOdds.top_rarity(db, lily, "float", _cond("night")), legendary, "gece Efsanevi")
	assert_eq(CatchOdds.top_rarity(db, lily, "float"), db.rarity_index("epic"), "koşulsuz Efsanevi yok")
	var save := SaveData.create_new(1_700_000_000)
	save.pity = { "rare": 0, "epic": 0, "legendary": 400 }
	assert_eq(CatchOdds.pity_floor(db, save, lily, "float", _cond("night")), legendary, "gece Efsanevi garantisi")
	assert_true(CatchOdds.pity_floor(db, save, lily, "float", _cond("noon")) < legendary, "öğle Efsanevi garantisi yok")
	# Sayaç yalnızca o kademenin gelebildiği avları sayar: öğle nilüferli koyda Efsanevi sayacı ilerlemez.
	save.pity = { "legendary": 10 }
	CatchOdds.note_catch(db, save, 0, lily, "float", _cond("noon"))
	assert_eq(int(save.pity["legendary"]), 10, "öğle Efsanevi sayacı durur")
	CatchOdds.note_catch(db, save, 0, lily, "float", _cond("night"))
	assert_eq(int(save.pity["legendary"]), 11, "gece ilerler")


## Oturumun koşulu: boş koşul hiçbir şeyi değiştirmez; yağmurda gölgeler daha uzaktan fark eder ve
## daha hızlı yaklaşır; gündüz olunca o koşulda gelmeyen türün dolaşan gölgesi çekilir.
func test_session_conditions() -> void:
	var db := content()
	var gear := GearStats.starter(db)
	var session := FishingSession.new(db, SPOT, gear, 11, false, false, -1, PackedStringArray(OPEN_ALL))
	var rig := session.sim.rig
	session.set_conditions(_cond("night", "rain"))
	session.set_conditions({})
	assert_eq(session.conditions(), {}, "koşul boşalır")
	assert_eq(session.sim.rig.notice_front, rig.notice_front, "boş koşulda profil koşulsuz (yağmursuz)")
	session.set_conditions(_cond("noon", "rain"))
	assert_between(session.sim.rig.notice_front, rig.notice_front * 1.29, rig.notice_front * 1.31, "yağmurda uzaktan fark eder")
	assert_between(session.sim.rig.approach_speed, rig.approach_speed * 1.24, rig.approach_speed * 1.26, "yağmurda hızlı yaklaşır")
	assert_eq(session.sim.rig.gather_after_steps, rig.gather_after_steps, "toplanma aynı")
	session.set_conditions(_cond("noon", "clear"))
	assert_eq(session.sim.rig.notice_front, rig.notice_front, "kuru havada profil eskisi gibi")
	assert_eq(session.conditions(), _cond("noon", "clear"), "koşul saklanır")
	# Gece nilüferli koyda bir gölge Ay Turnası olsun; sabah olunca çekilir.
	session.relocate(LILY)
	session.set_conditions(_cond("night"))
	var moon: FishShadow = null
	for s in session.sim.shadows:
		if not s.scripted and s.mode in [FishShadow.Mode.WANDER, FishShadow.Mode.PAUSE]:
			moon = s
			break
	assert_true(moon != null, "nilüferli koyda dolaşan gölge var")
	if moon == null:
		return
	moon.fish_id = "moon_pike"
	moon.fish_index = db.fish_index("moon_pike")
	session.set_conditions(_cond("night", "cloudy"))
	assert_true(moon.mode != FishShadow.Mode.FLEE, "gece Ay Turnası kaçmaz")
	session.set_conditions(_cond("morning"))
	assert_eq(moon.mode, FishShadow.Mode.FLEE, "sabah olunca Ay Turnası çekilir")
	assert_true(moon.recycled, "yerine yakında yenisi doğar")


## Koşullu oturumda ilk gölgeler de koşulla doğar (kurucunun son parametresi) ve aynı seed aynı
## gölgeleri verir; koşul vermek zar çekmez: gölgelerin yeri, hızı ve boyu koşulsuzla aynı.
func test_conditions_do_not_draw_dice() -> void:
	var db := content()
	var gear := GearStats.starter(db)
	var a := FishingSession.new(db, SPOT, gear, 21, false, false, -1, PackedStringArray(OPEN_ALL))
	var b := FishingSession.new(db, SPOT, gear, 21, false, false, -1, PackedStringArray(OPEN_ALL), _cond("evening"))
	assert_eq(a.sim.shadows.size(), b.sim.shadows.size(), "aynı sayıda gölge")
	for i in mini(a.sim.shadows.size(), b.sim.shadows.size()):
		assert_eq(a.sim.shadows[i].pos, b.sim.shadows[i].pos, "%d. gölgenin yeri aynı" % i)
		assert_eq(a.sim.shadows[i].percentile, b.sim.shadows[i].percentile, "%d. gölgenin boyu aynı" % i)
	assert_eq(b.conditions(), _cond("evening"), "koşul kurucudan")
