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
	s.loadouts = { "float": { "reel": "reel_smooth", "bait": "bait_corn" } }
	s.baits = { "bait_corn": 12 }
	s.xp = 150
	s.love = 9
	s.pity = { "rare": 14, "epic": 30 }
	s.stats = { "earned": 120, "sold": 11 }
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
	assert_eq(back.loadouts, { "float": { "reel": "reel_smooth" } }, "bozuk kuşanma düşer")
	assert_eq(back.baits, { "bait_corn": 5 }, "eksi ve bozuk yem sayısı düşer")
	assert_eq(back.xp, 0, "eksi rütbe puanı sıfırlanır")
	assert_eq(back.pity, { "rare": 3 }, "sayı yazısı okunur")


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
