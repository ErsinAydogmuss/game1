extends BaseTest
## Gölün Sırrı (Secret; Dalga 4, 5. adım): altı mektup her bölgeden bir, sırayla, rütbesi gelince ve aralarında
## LETTER_GAP balıkla; son mektubun şişesi sandal ister; şişe o bölgenin suyunda, atış noktasının (derin ortada
## ilk şamandıranın) yakınında ve hep aynı yerde; mektup ancak şişe varken okunur; altın hamur göl sevgisinin
## 6. seviyesinde bir kez; final altı mektup, dört parça ve altın hamurla hazır.

const SPOT := "big_lake"


func test_letters_cover_every_zone_once() -> void:
	var db := content()
	assert_eq(Secret.LETTERS.size(), SaveData.MAX_LETTERS, "kayıt bütün mektupları tutar")
	var seen := {}
	var last_rank := 0
	for letter in Secret.LETTERS:
		var zone_id := str(letter["zone"])
		assert_true(not db.zone(SPOT, zone_id).is_empty(), "bölge ana gölde: " + zone_id)
		assert_true(not seen.has(zone_id), "her bölgeden bir mektup: " + zone_id)
		seen[zone_id] = true
		assert_true(int(letter["rank"]) >= last_rank, "rütbeler sırayla")
		last_rank = int(letter["rank"])
	assert_eq(seen.size(), db.zones_of(SPOT).size(), "her bölgede bir mektup")
	var last: Dictionary = db.zone(SPOT, str(Secret.LETTERS[Secret.LETTERS.size() - 1]["zone"]))
	assert_true(bool(last["boat"]), "son mektup sandalla (derin orta)")


func test_bottle_needs_rank_catches_and_open_zone() -> void:
	var db := content()
	var save := _save(2)
	save.catches = 40
	assert_true(not Secret.bottle_due(db, save, SPOT), "rütbe 2'de şişe yok")
	_rank(save, 3)
	assert_true(Secret.bottle_due(db, save, SPOT), "rütbe 3'te sazlıkta şişe")
	assert_eq(Secret.bottle_zone(save), "reeds", "ilk şişe sazlıkta")
	save.letter_at = save.catches - Secret.LETTER_GAP + 1
	assert_true(not Secret.bottle_due(db, save, SPOT), "son mektuptan beri az balık")
	save.letter_at = save.catches - Secret.LETTER_GAP
	assert_true(Secret.bottle_due(db, save, SPOT), "yeterince balık")
	assert_eq(Secret.read_letter(db, save, SPOT), 1, "ilk mektup")
	assert_eq(save.letter_at, save.catches, "sıradaki şişe bundan sonraki balıklarla")
	assert_true(not Secret.bottle_due(db, save, SPOT), "okununca şişe gider")
	save.catches += Secret.LETTER_GAP
	assert_true(not Secret.bottle_due(db, save, SPOT), "ikinci mektup rütbe 4 ister")
	_rank(save, 4)
	assert_eq(Secret.bottle_zone(save), "dock_cove", "ikinci şişe iskele koyunda")
	assert_true(Secret.bottle_due(db, save, SPOT), "rütbe 4 ve 15 balık")
	# Son mektup derin ortada: sandal yokken bölge kapalı, şişe beklemez (alınca hemen çıkar).
	save.letters = Secret.LETTERS.size() - 1
	save.letter_at = 0
	_rank(save, 12)
	assert_true(not Secret.bottle_due(db, save, SPOT), "sandalsız derin orta kapalı")
	save.owned.append(Zones.BOAT)
	assert_true(Secret.bottle_due(db, save, SPOT), "sandalla son şişe")
	assert_eq(Secret.read_letter(db, save, SPOT), Secret.LETTERS.size(), "son mektup")
	assert_eq(Secret.next_letter(save), -1, "mektuplar bitti")
	assert_true(not Secret.bottle_due(db, save, SPOT), "başka şişe yok")
	assert_eq(Secret.bottle_zone(save), "", "bölge yok")


func test_letter_is_read_only_with_a_bottle() -> void:
	var db := content()
	var save := _save(2)
	save.catches = 40
	assert_eq(Secret.read_letter(db, save, SPOT), 0, "şişe yokken mektup yok")
	assert_eq(save.letters, 0, "sayaç aynı")
	# Bölgesi olmayan gölde (testlerin gölü) şişe hiç çıkmaz.
	_rank(save, 20)
	assert_true(not Secret.bottle_due(db, save, "home_lake"), "eski gölde şişe yok")


func test_bottle_lies_in_its_zone_near_the_stand() -> void:
	var db := content()
	var lake := db.lake(SPOT)
	for letter in Secret.LETTERS:
		var zone_id := str(letter["zone"])
		var zone := db.zone(SPOT, zone_id)
		var p := Secret.bottle_point(db, SPOT, zone_id)
		assert_true(Dice.is_point(p), "şişenin yeri var: " + zone_id)
		if not Dice.is_point(p):
			continue
		assert_eq(Secret.bottle_point(db, SPOT, zone_id), p, "hep aynı yer: " + zone_id)
		assert_true(lake.is_water(p) and not lake.on_dock(p, 0.5), "suda, iskelenin dışında: " + zone_id)
		assert_eq(lake.zone_at(p), lake.zone_index(zone_id), "kendi bölgesinin suyunda: " + zone_id)
		assert_true(lake.shore_distance(p) >= Secret.BOTTLE_SHORE, "kıyıdan içeride: " + zone_id)
		if bool(zone["boat"]):
			var buoys: Array[Vector2] = zone["buoys"]
			assert_between(p.distance_to(buoys[0]), 1.3, 2.3, "ilk şamandıranın yanında: " + zone_id)
		else:
			var stands: Array[Vector2] = zone["stands"]
			assert_between(p.distance_to(stands[0]), 2.1, 3.9, "atış noktasının yakınında: " + zone_id)
	assert_true(not Dice.is_point(Secret.bottle_point(db, SPOT, "nowhere")), "bilinmeyen bölge")


## Her şişeye uzanılır: kıyıdakine kıyı yolunun en yakın noktasından (yoldaki engellere pay bırakarak), derin
## ortadakine ilk şamandıraya bağlanan sandaldan (LakeScene.BUOY_MOOR); main Secret.REACH içinde alır.
func test_every_bottle_is_within_reach() -> void:
	var db := content()
	var lake := db.lake(SPOT)
	var path := ShorePath.new(lake, lake.world_rect if lake.world_band != INF else Rect2())
	for letter in Secret.LETTERS:
		var zone_id := str(letter["zone"])
		var zone := db.zone(SPOT, zone_id)
		var p := Secret.bottle_point(db, SPOT, zone_id)
		if not Dice.is_point(p):
			continue
		if bool(zone["boat"]):
			var buoys: Array[Vector2] = zone["buoys"]
			var boat := buoys[0] + LakeScene.BUOY_MOOR
			assert_true(p.distance_to(boat) <= Secret.REACH - 1.0, "sandaldan uzanılır: %s (%.2f m)" % [zone_id,
					p.distance_to(boat)])
		else:
			var stands: Array[Vector2] = zone["stands"]
			var walk := path.nearest_open(p)
			assert_true(p.distance_to(walk) <= Secret.REACH - 1.0, "kıyıdan uzanılır: %s (%.2f m)" % [zone_id,
					p.distance_to(walk)])
			# Sandaldan inilince bölgenin atış noktasına geçilir: şişe oradan da alınır.
			assert_true(p.distance_to(stands[0]) <= Secret.REACH, "atış noktasından uzanılır: " + zone_id)


func test_golden_dough_at_love_six() -> void:
	var db := content()
	var save := _save(6)
	var levels := db.rules.love_levels
	save.love = levels[Secret.DOUGH_LOVE - 1] - 1
	assert_true(not Secret.dough_due(db, save), "seviye 5'te hamur yok")
	assert_true(not Secret.give_dough(db, save), "verilmez")
	save.love = levels[Secret.DOUGH_LOVE - 1]
	assert_true(Secret.dough_due(db, save), "seviye 6'da Nine'de")
	assert_true(Secret.give_dough(db, save), "Nine verir")
	assert_true(Secret.has_dough(save), "elde")
	assert_true(not Secret.dough_due(db, save), "bir kez")
	assert_true(not Secret.give_dough(db, save), "ikinci kez verilmez")
	var back := SaveData.from_dict(save.to_dict())
	assert_true(Secret.has_dough(back), "kayıtta kalır")


func test_final_needs_letters_pieces_and_dough() -> void:
	var save := SaveData.create_new(0)
	assert_true(not Secret.final_ready(save), "yeni oyunda yok")
	save.letters = Secret.LETTERS.size()
	save.map_pieces = SaveData.MAX_MAP_PIECES
	assert_true(not Secret.final_ready(save), "hamursuz değil")
	save.flags[Secret.DOUGH_FLAG] = true
	assert_true(Secret.final_ready(save), "hepsi tamam")
	save.map_pieces -= 1
	assert_true(not Secret.final_ready(save), "parça eksik")


func test_letters_alternate_writers() -> void:
	for n in range(1, Secret.LETTERS.size() + 1):
		assert_true(Secret.letter_writer(n) in ["nine", "dede"], "yazan: %d" % n)
		if n > 1:
			assert_true(Secret.letter_writer(n) != Secret.letter_writer(n - 1), "karşılıklı: %d" % n)
	assert_eq(Secret.letter_writer(1), "nine", "ilk mektup Nine'nin")


## Her mektubun yazısı, adı ve imzası iki dilde var; yazı imzasıyla mektup kâğıdına kaydırmadan sığar (telefonda
## panel küçülmeden: LetterPanel.TEXT_H; sütun panelin iki yanından TEXT_PAD içeride).
func test_letters_are_written_and_fit_the_paper() -> void:
	var rows := {}
	var f := FileAccess.open("res://localization/strings.csv", FileAccess.READ)
	while f != null and not f.eof_reached():
		var row := f.get_csv_line()
		if row.size() >= 3:
			rows[row[0]] = row
	for n in range(1, Secret.LETTERS.size() + 1):
		for key: String in [Secret.letter_key(n), Secret.letter_title_key(n), Secret.letter_from_key(n),
				"UI_DEDE_LETTER_%d" % n]:
			var row: PackedStringArray = rows.get(key, PackedStringArray())
			assert_true(row.size() >= 3 and not row[1].is_empty() and not row[2].is_empty(), "iki dilde: " + key)
		var text_row: PackedStringArray = rows.get(Secret.letter_key(n), PackedStringArray())
		if text_row.size() < 3:
			continue
		for column: int in [1, 2]:
			var lang := "EN" if column == 1 else "TR"
			var text := text_row[column].c_unescape()
			var words := text.split(" ", false).size()
			assert_between(words, 40, 130, "mektup %d (%s) kısa ve okunur: %d kelime" % [n, lang, words])
			var height := LetterPanel.text_height(text)
			assert_true(height <= LetterPanel.TEXT_H, "mektup %d (%s) kâğıda sığar: %.0f > %.0f" % [n, lang, height,
					LetterPanel.TEXT_H])


## Final hazır bir kayıt: altı mektup, dört parça, altın hamur.
func _final_save() -> SaveData:
	var save := _save(13)
	save.letters = Secret.LETTERS.size()
	save.map_pieces = SaveData.MAX_MAP_PIECES
	save.flags[Secret.DOUGH_FLAG] = true
	return save


## Bekçi yalnızca hepsi birden tutunca çıkar: gece, sis, sandal X'te, elde dip, altın hamur, final hazır. Bırakılınca
## (oyun sonrası) kendiliğinden sisli gecelerde yine çıkar, ama bırakıldığı gün değil.
func test_keeper_needs_night_fog_x_bottom_and_the_final() -> void:
	var save := _final_save()
	assert_true(Secret.keeper_due(save, "night", "fog", true, "bottom", 3), "hepsi tamam: Bekçi çıkar")
	assert_true(not Secret.keeper_due(save, "evening", "fog", true, "bottom", 3), "gece değil")
	assert_true(not Secret.keeper_due(save, "night", "clear", true, "bottom", 3), "sis değil")
	assert_true(not Secret.keeper_due(save, "night", "fog", false, "bottom", 3), "sandal X'te değil")
	assert_true(not Secret.keeper_due(save, "night", "fog", true, "float", 3), "elde dip değil")
	var early := _final_save()
	early.map_pieces -= 1
	assert_true(not Secret.keeper_due(early, "night", "fog", true, "bottom", 3), "final hazır değil")
	var no_dough := _final_save()
	no_dough.flags.erase(Secret.DOUGH_FLAG)
	assert_true(not Secret.keeper_due(no_dough, "night", "fog", true, "bottom", 3), "altın hamursuz değil")
	# Oyun sonrası: Bekçi bırakıldı; aynı gün çıkmaz, ertesi sisli gecede çıkar.
	Secret.release_keeper(save, 3)
	assert_eq(save.keeper, 1, "Bekçi bir kez bırakıldı")
	assert_true(not Secret.keeper_night(save), "final gecesi bitti")
	assert_true(not Secret.keeper_due(save, "night", "fog", true, "bottom", 3), "bırakıldığı gün yeniden çıkmaz")
	assert_true(Secret.keeper_due(save, "night", "fog", true, "bottom", 4), "sonraki sisli gecede yine çıkar")
	assert_true(not Secret.keeper_due(save, "night", "rain", true, "bottom", 4), "sonra da yalnızca sisli gecede")


## Bekçi'yi göle bırakmak (WorldState.release) finali bitirir: sayaç, bugünün bayrağı, sevgi; para yok.
func test_releasing_the_keeper_ends_the_final() -> void:
	var db := content()
	var save := _final_save()
	save.clock_s = 7 * DayClock.day_s(db.rules) + 3 * db.rules.phase_s + 30
	var coins := save.coins
	assert_true(Secret.keeper_night(save), "final gecesi")
	Records.add(save.records, Secret.KEEPER_ID, 517, 5, 0)
	var out := WorldState.release(db, save, Secret.KEEPER_ID)
	assert_eq(save.keeper, 1, "Bekçi bırakıldı")
	assert_eq(int(save.flags.get(Secret.KEEPER_DAY_FLAG, -1)), 7, "bırakıldığı gün")
	assert_true(not Secret.keeper_night(save), "geceler eski havasına döner")
	assert_eq(int(out["love"]), int(db.rarity_def(db.rarity_index("mythic"))["love"]), "Masalsı sevgi")
	assert_eq(save.coins, coins, "para vermez")
	assert_eq(int((save.records.get(Secret.KEEPER_ID, {}) as Dictionary).get("released", 0)), 1, "defterde bırakıldı")


## Bekçi haritanın X'inde (derin ortanın KEEPER_BUOY şamandırası) çıkar: sandaldan her yöne atılan dip takımına
## (kurşun derin ortanın suyunda kalır) karşı sandaldan 6–9 m ötede, derin ortanın derin suyunda, takımdan en az
## KEEPER_GAP uzakta belirir.
func test_keeper_rises_in_deep_water_near_the_boat() -> void:
	var db := content()
	var lake := db.lake(SPOT)
	var x := Secret.keeper_x(db, SPOT)
	assert_true(Dice.is_point(x), "haritanın X'i var")
	if not Dice.is_point(x):
		return
	var deep := lake.zone_index("deep_water")
	assert_eq(lake.zone_at(x), deep, "X derin ortada")
	var boat := x + LakeScene.BUOY_MOOR
	var depth := float(db.zone(SPOT, "deep_water")["min_depth"])
	var technique := BottomTechnique.new(db.rules)
	var session := FishingSession.new(db, SPOT, GearStats.best(db, "bottom"), 3, false, false, -1,
			PackedStringArray(["deep_water"]))
	session.relocate(boat)
	var cast := 0
	for k in 16:
		# Kıyıya bakan yönlerde (güney ve batı) derin ortanın suyu kurşunun en kısa atışından dar: atılmaz.
		var rig := technique.landing_point(session, boat + Vector2.from_angle(TAU * k / 16.0) * 10.0)
		if not Dice.is_point(rig):
			continue
		cast += 1
		assert_eq(lake.zone_at(rig), deep, "%d. yönde kurşun derin ortaya düşer" % k)
		var p := Secret.keeper_point(db, SPOT, boat, rig)
		assert_true(Dice.is_point(p), "%d. yönde Bekçi'nin yeri var" % k)
		if not Dice.is_point(p):
			continue
		assert_eq(lake.zone_at(p), deep, "%d. yön: derin ortada" % k)
		assert_true(lake.is_deep(p, depth), "%d. yön: derin suda" % k)
		assert_between(p.distance_to(boat), 6.0 - 0.001, 9.0 + 0.001, "%d. yön: sandaldan uzaklık" % k)
		assert_true(p.distance_to(rig) >= Secret.KEEPER_GAP, "%d. yön: takımdan uzak" % k)
	assert_true(cast >= 8, "X'ten en az sekiz yöne dip atılır (%d)" % cast)


func _save(rank: int) -> SaveData:
	var save := SaveData.create_new(0)
	save.seed = 4242
	_rank(save, rank)
	return save


func _rank(save: SaveData, rank: int) -> void:
	save.xp = content().rank_xp[maxi(0, rank - 1)]
