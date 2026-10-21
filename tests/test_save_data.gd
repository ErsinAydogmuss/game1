extends BaseTest
## Kayıt: gidiş-dönüş, bozuk verinin ayıklanması, atomik yazma.


func test_roundtrip_keeps_every_field() -> void:
	var s := SaveData.create_new(1000)
	s.coins = 12
	s.session = 3
	s.casts = 40
	s.catches = 9
	s.hint_step = 4
	s.records = { "carp": { "count": 2, "best_cm": 61, "best_stars": 3, "first_unix": 1200, "released": 1 } }
	s.settings = { "sfx": false, "easy": true, "locale": "tr" }
	s.flags = { "seen_card": true }
	s.character = "rogue"
	s.bucket = [{ "fish": "rudd", "size_cm": 22, "stars": 3 }]
	s.owned = PackedStringArray(["reel_smooth", "bucket_big"])
	s.loadouts = { "shared": { "reel": "reel_smooth" }, "float": { "bait": "bait_corn" }, "spin": { "rod": "rod_spin_light" } }
	s.technique = "spin"
	s.traps = [{ "id": 2, "zone": "reeds", "x": -16.5, "z": 1.25, "placed_unix": 1100, "last_unix": 1500, "progress_s": 900,
			"items": [{ "fish": "crayfish", "size_cm": 11, "stars": 2 }], "trash": "boot" }]
	s.trap_serial = 3
	s.baits = { "bait_corn": 12 }
	s.xp = 150
	s.love = 9
	s.pity = { "rare": 14, "epic": 30 }
	s.stats = { "earned": 120, "sold": 11 }
	# v5 (Dalga 4): oyun saati, çay, istekler, Gölün Sırrı.
	s.clock_s = 2000
	s.tea_at = 7
	s.requests = [{ "slot": 1, "kind": "size", "want": { "fish": "tench", "size_cm": 30 }, "goal": 1, "progress": 0,
			"day": 1, "serial": 4, "reward": { "coins": 45, "xp": 22, "love": 4 } }]
	s.request_serial = 5
	s.request_day = 1
	s.reroll_day = 0
	s.letters = 2
	s.letter_at = 6
	s.map_pieces = 1
	s.keeper = 0
	var back := SaveData.from_dict(s.to_dict())
	assert_eq(back.to_dict(), s.to_dict(), "bütün alanlar aynen döner")
	assert_eq(back.to_dict()["version"], SaveData.VERSION, "sürüm yazılır")


func test_new_save_has_seed_and_id() -> void:
	var s := SaveData.create_new(5)
	assert_true(s.seed > 0, "seed atanır")
	assert_eq(s.player_id.length(), 32, "oyuncu kimliği 16 bayt hex")
	assert_eq(s.created_unix, 5, "oluşturma zamanı")


func test_bad_values_are_sanitized() -> void:
	var back := SaveData.from_dict({
		"version": 1, "coins": -5, "session": -1, "records": {
			"carp": { "count": 1, "best_cm": 50, "best_stars": 9 },
			"pike": { "count": 0 },
			"bad": "yok",
		},
		"settings": "bozuk", "character": "",
		"bucket": [{ "fish": "rudd", "size_cm": 20 }, { "fish": "", "size_cm": 9 }, "yok", { "fish": "carp", "size_cm": -3 }],
		"owned": ["reel_smooth", "reel_smooth", 5, ""],
		"loadouts": { "float": { "reel": "reel_smooth", "line": 7 }, "spin": "bozuk" },
		"baits": { "bait_corn": 5, "bait_dough": -2, "bait_maggot": "çok" },
		"xp": -10, "pity": { "rare": "3" },
	})
	var v4 := SaveData.from_dict({
		"version": 4, "technique": 5, "trap_serial": -2,
		"traps": [
			{ "id": 1, "zone": "reeds", "x": 1.0, "z": 2, "placed_unix": -9, "items": [{ "fish": "crayfish", "size_cm": 9 }, "yok"] },
			{ "zone": "", "x": 1.0, "z": 2.0 }, { "zone": "reeds", "x": "bir", "z": 2.0 }, "bozuk",
		],
	})
	assert_eq(back.coins, 0, "negatif para sıfırlanır")
	assert_eq(back.session, 0, "negatif oturum sıfırlanır")
	assert_true(back.records.has("carp"), "geçerli kayıt kalır")
	assert_eq(int(back.records["carp"]["best_stars"]), 5, "yıldız 1..5'e sıkıştırılır")
	assert_true(not back.records.has("pike"), "sayısı 0 olan kayıt düşer")
	assert_true(not back.records.has("bad"), "bozuk kayıt düşer")
	assert_eq(back.settings, {}, "bozuk ayarlar boş sözlük olur")
	assert_eq(back.character, "rogue", "boş karakter varsayılana döner")
	assert_eq(back.bucket.size(), 1, "kovada yalnızca geçerli satır kalır")
	assert_eq(int(back.bucket[0]["stars"]), 1, "eksik yıldız 1 olur")
	assert_eq(back.owned, PackedStringArray(["reel_smooth"]), "takım listesi tekrarsız ve yalnızca yazı")
	assert_eq(back.loadouts, { "float": {}, "shared": { "reel": "reel_smooth" } },
			"bozuk kuşanma düşer (makara v4 göçüyle ortak sete geçer)")
	assert_eq(back.baits, { "bait_corn": 5 }, "eksi ve bozuk yem sayısı düşer")
	assert_eq(back.xp, 0, "eksi rütbe puanı sıfırlanır")
	assert_eq(back.pity, { "rare": 3 }, "sayı yazısı okunur")
	assert_eq(v4.technique, "float", "yazı olmayan teknik şamandıra olur")
	assert_eq(v4.trap_serial, 2, "eksi tuzak sayacı sıfırlanır, kurulu tuzağın kimliğinin üstüne çıkar")
	assert_eq(v4.traps.size(), 1, "bölgesi ya da yeri bozuk tuzak düşer")
	assert_eq(int(v4.traps[0]["placed_unix"]), 0, "eksi zaman sıfırlanır")
	assert_eq(float(v4.traps[0]["z"]), 2.0, "tamsayı yer okunur")
	assert_eq(v4.traps[0]["items"], [{ "fish": "crayfish", "size_cm": 9, "stars": 1 }], "tuzağın içi kova gibi ayıklanır")


## Tuzak kimliğiyle bulunur: kimliği aynı ikinci tuzak düşer, sayaç kurulu tuzakların kimliğinin
## üstüne çıkar (yeni tuzak eskisinin kimliğini almaz).
func test_trap_ids_stay_unique() -> void:
	var trap := { "zone": "reeds", "x": -16.5, "z": 1.25, "items": [] }
	var a := trap.duplicate(true)
	a["id"] = 5
	var b := trap.duplicate(true)
	b["id"] = 5
	b["x"] = -14.0
	var c := trap.duplicate(true)
	c["id"] = 2
	var s := SaveData.from_dict({ "version": SaveData.VERSION, "trap_serial": 1, "traps": [a, b, c] })
	assert_eq(s.traps.size(), 2, "kimliği aynı ikinci tuzak düşer")
	assert_eq(float(s.traps[0]["x"]), -16.5, "ilki kalır")
	assert_eq(s.trap_serial, 6, "sayaç en büyük kimliğin üstünde")
	var db := content()
	var placed := TrapSim.place(db, s, db.main_spot, "reeds", Vector2(-16.0, 1.0), 100)
	assert_true(TrapSim.find(s, int(placed["id"])) == s.traps.size() - 1, "yeni tuzağın kimliği eşsiz")


## Elle bozulmuş ya da hatalı yazılmış tek bir değer bütün ilerlemeyi sildirmez: o alan
## varsayılana döner, gerisi korunur.
func test_wrong_types_keep_the_rest() -> void:
	var back := SaveData.from_dict({
		"version": 1, "coins": null, "catches": "yedi", "casts": "12", "seed": 4242,
		"player_id": 99, "records": { "rudd": { "count": "3", "best_cm": null } },
	})
	assert_true(back != null, "türü bozuk alanlarla da kayıt okunur")
	if back == null:
		return
	assert_eq(back.coins, 0, "null para varsayılana döner")
	assert_eq(back.catches, 0, "sayı olmayan yazı varsayılana döner")
	assert_eq(back.casts, 12, "sayı yazısı okunur")
	assert_eq(back.seed, 4242, "sağlam alan korunur")
	assert_eq(back.player_id, "", "yazı olmayan kimlik boş kalır (açılışta yenisi verilir)")
	assert_true(back.records.has("rudd") and int(back.records["rudd"]["count"]) == 3, "kayıt defteri korunur")


## Okunamayan kayıt üstüne yazılmadan kenara alınır: bozuksa .corrupt, daha yeni bir sürümün
## kaydıysa (eski bir yapı yüklendiyse) .newer.
func test_unreadable_saves_are_set_aside() -> void:
	var path := "user://test_save_aside.json"
	var abs_path := ProjectSettings.globalize_path(path)
	for suffix: String in [".corrupt", ".newer"]:
		DirAccess.remove_absolute(abs_path + suffix)
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify({ "version": SaveData.VERSION + 1, "coins": 9 }))
	f.close()
	assert_true(SaveStore.read(path) == null, "yeni sürümün kaydı okunmaz")
	assert_true(FileAccess.file_exists(path + ".newer") and not FileAccess.file_exists(path),
			"yeni sürümün kaydı kenara alınır")
	f = FileAccess.open(path, FileAccess.WRITE)
	f.store_string("{ bozuk")
	f.close()
	assert_true(SaveStore.read(path) == null, "bozuk kayıt okunmaz")
	assert_true(FileAccess.file_exists(path + ".corrupt"), "bozuk kayıt kenara alınır")
	for suffix: String in [".corrupt", ".newer"]:
		DirAccess.remove_absolute(abs_path + suffix)


func test_old_version_is_migrated() -> void:
	var d := SaveData.migrate({ "coins": 3 })
	assert_eq(int(d["version"]), SaveData.VERSION, "sürümsüz kayıt güncel sürüme gelir")


## Gerçek bir v1 kaydı (tests/fixtures/save_v1.json, değiştirme): v2'de olta alanı gider,
## defter, ayarlar ve sayaçlar korunur, yeni alanlar boş başlar, bambu kamış kuşanılı kalır.
func test_v1_save_migrates_to_v2() -> void:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/save_v1.json"))
	assert_eq(typeof(raw), TYPE_DICTIONARY, "v1 kaydı okunur")
	if typeof(raw) != TYPE_DICTIONARY:
		return
	var s := SaveData.from_dict(raw)
	var out := s.to_dict()
	assert_eq(int(out["version"]), SaveData.VERSION, "güncel sürüm")
	assert_true(not out.has("rod"), "eski olta alanı gider")
	assert_eq(s.seed, 4242, "seed korunur")
	assert_eq(s.catches, 9, "sayaçlar korunur")
	assert_eq(int(s.records["rudd"]["count"]), 7, "defter korunur")
	assert_eq(int(s.records["rudd"]["released"]), 0, "bırakılan sayısı 0 başlar")
	assert_eq(str(s.settings["locale"]), "tr", "ayarlar korunur")
	assert_true(s.bucket.is_empty() and s.owned.is_empty() and s.baits.is_empty(), "kova, takım ve yem boş")
	assert_eq(s.xp, 0, "rütbe puanı 0")
	assert_eq(Economy.equipped(content(), s, "rod"), "rod_bamboo", "bambu kamış kuşanılı kalır")
	assert_eq(SaveData.from_dict(out).to_dict(), out, "göçten sonraki kayıt gidiş-dönüşte aynı")


## v0.2'nin gerçek bir kaydı (oyunun mantığıyla üretildi; değiştirilmez): v3'e göçer. Rütbe
## eğrisi uzadı; rütbe puanı yeni eğriye taşınır, rütbe (7) ve rütbedeki ilerleme aynı kalır.
func test_v2_save_migrates_to_v3() -> void:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/save_v2.json"))
	assert_eq(typeof(raw), TYPE_DICTIONARY, "v2 kaydı okunur")
	if typeof(raw) != TYPE_DICTIONARY:
		return
	var db := content()
	var s := SaveData.from_dict(raw)
	assert_eq(int(s.to_dict()["version"]), SaveData.VERSION, "güncel sürüm")
	assert_eq(s.seed, 4242, "seed")
	assert_eq(s.coins, 195, "para")
	assert_eq(s.bucket.size(), 2, "kovadaki balıklar")
	assert_eq(str(s.bucket[0]["fish"]), "pike", "kovadaki ilk balık")
	assert_true("reel_smooth" in s.owned and "bobber_sensitive" in s.owned, "alınan takım")
	assert_eq(Economy.equipped(db, s, "reel"), "reel_smooth", "kuşanılan makara")
	assert_eq(Economy.equipped(db, s, "bait"), "bait_maggot", "kuşanılan yem")
	assert_eq(int(s.baits["bait_maggot"]), 17, "yem sayısı")
	assert_eq(_rank_in(SaveData.XP_CURVE_V2, 902), 7, "v2'de rütbe 7 (902 puan)")
	assert_eq(Rank.rank(db, s), 7, "göçten sonra da rütbe 7")
	assert_eq(s.xp, 2054, "puan yeni eğride rütbe 7'nin aynı yerinde (900 + 2 → 2050 + 4)")
	assert_eq(int(s.pity["epic"]), 18, "Destansı sayacı")
	assert_eq(int(s.records["rudd"]["released"]), 1, "bırakılan balık")
	assert_eq(s.love, 1, "göl sevgisi")
	assert_eq(SaveData.from_dict(s.to_dict()).to_dict(), s.to_dict(), "gidiş-dönüşte aynı")


## v0.3'ün gerçek bir kaydı (denge botu büyük gölde sandalı alıp mersini bırakana kadar oynadı;
## değiştirilmez): v4'e göçer. Makara ve misina her teknikte ortak sete taşınır; kuşanılan takım,
## rütbe ve kova aynı kalır; elindeki teknik şamandıra, tuzak yok.
func test_v3_save_migrates_to_v4() -> void:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/save_v3.json"))
	assert_eq(typeof(raw), TYPE_DICTIONARY, "v3 kaydı okunur")
	if typeof(raw) != TYPE_DICTIONARY:
		return
	var db := content()
	var s := SaveData.from_dict(raw)
	assert_eq(int(s.to_dict()["version"]), SaveData.VERSION, "güncel sürüm")
	assert_eq(s.xp, 7802, "rütbe puanı aynen")
	assert_eq(Rank.rank(db, s), 12, "rütbe")
	assert_true(Zones.BOAT in s.owned, "sandal alınmış")
	assert_true(Zones.unlocked(db, s, db.zone(db.main_spot, "deep_water")), "derin orta açık")
	assert_true(bool(s.flags.get("visited_deep_water", false)), "gidilen bölgeler bayrakta")
	assert_eq(s.bucket.size(), 4, "kovadaki balıklar")
	assert_eq(str(s.bucket[0]["fish"]), "bream", "kovadaki ilk balık")
	assert_eq(Economy.equipped(db, s, "rod"), "rod_float_glass", "kuşanılan olta")
	assert_eq(Economy.equipped(db, s, "reel"), "reel_quick", "kuşanılan makara (ortak sette)")
	assert_eq(Economy.equipped(db, s, "line"), "line_fluoro", "kuşanılan misina (ortak sette)")
	assert_eq(Economy.equipped(db, s, "hook"), "hook_large", "kuşanılan iğne")
	assert_eq(s.loadouts["shared"], { "reel": "reel_quick", "line": "line_fluoro" }, "ortak set")
	assert_true(not (s.loadouts["float"] as Dictionary).has("reel"), "makara şamandıranın setinden çıktı")
	assert_eq(s.technique, "float", "elindeki teknik şamandıra")
	assert_true(s.traps.is_empty() and s.trap_serial == 0, "tuzak yok")
	assert_eq(int(s.records["sturgeon"]["released"]), 1, "mersin göle bırakıldı")
	assert_eq(s.love, 40, "göl sevgisi")
	assert_eq(int(s.pity["legendary"]), 4, "Efsanevi sayacı")
	assert_eq(SaveData.from_dict(s.to_dict()).to_dict(), s.to_dict(), "gidiş-dönüşte aynı")


## v0.4'ün gerçek bir kaydı (denge botu spin, dip ve sinek kamışını, ilk tuzağı alıp sazlığa bırakana
## kadar oynadı; botun saniyeleri gerçek saate taşındı; değiştirilmez): okunur ve gidiş-dönüşte aynı
## kalır (v5 göçü bundan sınanır: test_v4_save_migrates_to_v5). Teknik başına setler, ortak makara ve
## misina, elindeki teknik, kurulmuş tuzak ve içeriği, tuzak sayacı.
func test_v4_save_reads_back() -> void:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/save_v4.json"))
	assert_eq(typeof(raw), TYPE_DICTIONARY, "v4 kaydı okunur")
	if typeof(raw) != TYPE_DICTIONARY:
		return
	var db := content()
	var rules := db.rules
	var s := SaveData.from_dict(raw)
	assert_eq(int(s.to_dict()["version"]), SaveData.VERSION, "güncel sürüm")
	assert_eq(s.technique, "fly", "elindeki teknik")
	for t: String in ["spin", "bottom", "fly"]:
		assert_true(Economy.technique_ready(db, s, t), "%s kamışı alınmış" % t)
	assert_eq(Economy.equipped(db, s, "rod", "spin"), "rod_spin_light", "spin kamışı spinin setinde")
	assert_eq(Economy.equipped(db, s, "lure", "spin"), "lure_spinner", "kuşanılan yapay yem")
	assert_eq(Economy.equipped(db, s, "rod", "bottom"), "rod_carp_1", "dip kamışı dipin setinde")
	assert_eq(Economy.equipped(db, s, "rod"), "rod_float_glass", "şamandıranın kamışı")
	assert_eq(Economy.equipped(db, s, "reel", "bottom"), "reel_smooth", "makara her teknikte ortak")
	assert_eq(Economy.equipped(db, s, "line", "fly"), "line_mono", "misina her teknikte ortak")
	assert_eq(s.traps.size(), 1, "bir tuzak kurulu")
	assert_eq(TrapSim.owned(db, s), 1, "bir tuzağı var")
	assert_eq(TrapSim.spare(db, s), 0, "boşta tuzak yok")
	assert_eq(s.trap_serial, 4, "tuzak zarı sayacı")
	if s.traps.size() == 1:
		var trap := s.traps[0]
		assert_eq(str(trap["zone"]), "reeds", "tuzak sazlıkta")
		assert_eq((trap["items"] as Array).size(), rules.trap_max, "içeriği kurulunca belli")
		assert_eq(int(trap["progress_s"]), 270, "dolma")
		TrapSim.update(rules, trap, int(trap["last_unix"]) + 2 * rules.trap_fill_s)
		assert_eq(TrapSim.ready(rules, trap), 2, "kayıttan sonra da gerçek saatle dolar")
	assert_eq(int(s.records["crayfish"]["count"]), 4, "kerevit defterde")
	assert_eq(int(s.stats["trapped"]), 3, "tuzaktan toplanan")
	var fresh := SaveData.from_dict(raw)
	assert_eq(SaveData.from_dict(fresh.to_dict()).to_dict(), fresh.to_dict(), "gidiş-dönüşte aynı")


## v0.4'ün gerçek kaydı (tests/fixtures/save_v4.json, değiştirilmez) v5'e göçer: oyun saati sabahtan
## (gün 0), çay içilmedi, istek, mektup ve harita parçası yok; ilk şişe kaydın balık sayısından
## sayılır (eski oyuncu da onu yeni balıklarla bulur); tuzakta çöp yok; v4'ün her şeyi aynen.
func test_v4_save_migrates_to_v5() -> void:
	var raw: Variant = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/save_v4.json"))
	assert_eq(typeof(raw), TYPE_DICTIONARY, "v4 kaydı okunur")
	if typeof(raw) != TYPE_DICTIONARY:
		return
	assert_eq(int((raw as Dictionary)["version"]), 4, "örnek v4 kaydı")
	var s := SaveData.from_dict(raw)
	var db := content()
	assert_eq(int(s.to_dict()["version"]), 5, "v5'e göçtü")
	assert_eq(s.clock_s, 0, "oyun saati sabahtan")
	assert_eq(DayClock.phase(db.rules, s.clock_s), "morning", "ilk vakit sabah")
	assert_eq(s.tea_at, -1, "çay içilmedi")
	assert_true(s.requests.is_empty() and s.request_day == -1 and s.reroll_day == -1, "istek yok")
	assert_eq(s.letters, 0, "mektup yok")
	assert_eq(s.letter_at, s.catches, "ilk şişe şimdiki balık sayısından sayılır")
	assert_true(s.catches > 0, "örnek kayıtta balık var")
	assert_eq(s.map_pieces, 0, "harita parçası yok")
	assert_eq(s.keeper, 0, "Bekçi tutulmadı")
	for trap in s.traps:
		assert_eq(str(trap["trash"]), "", "tuzakta çöp yok")
	assert_eq(s.love, int((raw as Dictionary)["love"]), "göl sevgisi aynen")
	assert_eq(SaveData.from_dict(s.to_dict()).to_dict(), s.to_dict(), "göçten sonra gidiş-dönüşte aynı")


## v5'in alanları bozuksa ayıklanır: eksi saat sıfır, mektup ve parça sınırda, istekler (türü yazı,
## yuvası 0..3 ve tekrarsız, hedef en az 1, ilerleme hedefte kalır), tuzağın çöpü yazı.
func test_v5_bad_values_are_sanitized() -> void:
	var s := SaveData.from_dict({
		"version": 5, "clock_s": -40, "tea_at": -9, "letters": 99, "letter_at": -3, "map_pieces": 7, "keeper": -1,
		"request_serial": -2, "request_day": -5, "reroll_day": "dün",
		"requests": [
			{ "slot": 0, "kind": "fish", "want": { "fish": "rudd", "size_cm": -4, "bad": [1] }, "goal": 3, "progress": 9,
				"reward": { "coins": 30, "xp": -1 } },
			{ "slot": 0, "kind": "zone", "goal": 2 },
			{ "slot": 7, "kind": "fish" }, { "slot": 2, "kind": "" }, "bozuk",
			{ "slot": 3, "kind": "special", "goal": 0, "want": "yok" },
		],
		"traps": [{ "id": 1, "zone": "reeds", "x": 1.0, "z": 2.0, "items": [], "trash": 5 }],
	})
	assert_eq(s.clock_s, 0, "eksi saat sıfırlanır")
	assert_eq(s.tea_at, -1, "çay sayacı en az -1")
	assert_eq(s.letters, SaveData.MAX_LETTERS, "mektup sınırda")
	assert_eq(s.letter_at, 0, "eksi şişe sayacı sıfırlanır")
	assert_eq(s.map_pieces, SaveData.MAX_MAP_PIECES, "parça sınırda")
	assert_eq(s.keeper, 0, "eksi Bekçi sayısı sıfırlanır")
	assert_eq(s.request_serial, 1, "eksi istek sayacı kayıttaki isteklerin sırasının üstünde (sırasız istek 0)")
	assert_eq(s.request_day, -1, "gün en az -1")
	assert_eq(s.reroll_day, -1, "yazı olan gün varsayılana döner")
	assert_eq(s.requests.size(), 2, "yuvası tekrarlı, bozuk ya da türsüz istek düşer")
	if s.requests.size() == 2:
		var first := s.requests[0]
		assert_eq(int(first["progress"]), 3, "ilerleme hedefte kalır")
		assert_eq(first["want"], { "fish": "rudd" }, "eksi ve yazı olmayan istek bilgisi düşer")
		assert_eq(first["reward"], { "coins": 30 }, "eksi ödül düşer")
		assert_eq(int(s.requests[1]["goal"]), 1, "hedef en az 1")
		assert_eq(s.requests[1]["want"], {}, "bozuk istek bilgisi boş")
	assert_eq(str(s.traps[0]["trash"]), "", "yazı olmayan çöp boş")


## Son çayın ve sıradaki şişenin sayacı tutulan balıktan büyük olamaz; istek sayacı kayıttaki isteklerin
## sırasının üstünde kalır (aynı zar aynı isteği vermesin).
func test_v5_counters_follow_the_save() -> void:
	var s := SaveData.from_dict({
		"version": 5, "catches": 3, "tea_at": 50, "letter_at": 80, "request_serial": 2,
		"requests": [{ "slot": 0, "kind": "fish", "serial": 7, "goal": 2 }, { "slot": 1, "kind": "zone", "serial": 4 }],
	})
	assert_eq(s.tea_at, 3, "çay sayacı balık sayısında kalır")
	assert_eq(s.letter_at, 3, "şişe sayacı balık sayısında kalır")
	assert_eq(s.request_serial, 8, "istek sayacı isteklerin en büyük sırasının bir üstü")
	var kept := SaveData.from_dict({ "version": 5, "catches": 9, "tea_at": 4, "letter_at": 6, "request_serial": 12 })
	assert_eq([kept.tea_at, kept.letter_at, kept.request_serial], [4, 6, 12], "doğru sayaçlar değişmez")


## Rütbe puanı eğriden eğriye taşınınca her eşikte ve aralığın içinde rütbe aynı kalır,
## rütbedeki ilerleme oranı korunur.
func test_xp_remap_keeps_rank_and_progress() -> void:
	var old := SaveData.XP_CURVE_V2
	var cur := SaveData.XP_CURVE_V3
	assert_eq(old.size(), cur.size(), "iki eğride rütbe sayısı aynı")
	var points: Array[int] = [0, 1, old[old.size() - 1] + 777]
	for r in old.size() - 1:
		points.append_array([old[r], old[r] + 1, (old[r] + old[r + 1]) >> 1, old[r + 1] - 1])
	for xp in points:
		var moved := SaveData.remap_xp(xp, old, cur)
		var rank := _rank_in(old, xp)
		assert_eq(_rank_in(cur, moved), rank, "%d puan (rütbe %d) → %d" % [xp, rank, moved])
		if rank < old.size():
			var before := float(xp - old[rank - 1]) / float(old[rank] - old[rank - 1])
			var after := float(moved - cur[rank - 1]) / float(cur[rank] - cur[rank - 1])
			assert_between(after, before - 0.02, before + 0.001, "%d puanda ilerleme korunur" % xp)
	assert_eq(SaveData.remap_xp(-5, old, cur), -5, "eksi puana dokunulmaz (okurken sıfırlanır)")


## progression.json'un eğrisi son kayıt sürümünün eğrisi: eğri değişirse eski kayıtların rütbesi
## düşer. Değiştirince SaveData'ya yeni sürüm, yeni eğri sabiti ve göç adımı ekle.
func test_rank_curve_is_the_latest() -> void:
	var curve: Array[int] = []
	for xp in content().rank_xp:
		curve.append(xp)
	assert_eq(curve, SaveData.XP_CURVE_V3, "progression.json xp = SaveData.XP_CURVE_V3")


static func _rank_in(curve: Array[int], xp: int) -> int:
	var rank := 1
	for i in range(1, curve.size()):
		if xp >= curve[i]:
			rank = i + 1
	return rank


func test_store_writes_atomically() -> void:
	var path := "user://test_save_store.json"
	var s := SaveData.create_new(77)
	s.coins = 5
	SaveStore.write(s, path)
	var back := SaveStore.read(path)
	assert_true(back != null, "yazılan kayıt okunur")
	if back != null:
		assert_eq(back.coins, 5, "para aynı")
	assert_true(not FileAccess.file_exists(path + ".tmp"), "geçici dosya kalmaz")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
	assert_true(SaveStore.read(path) == null, "olmayan kayıt null döner")
