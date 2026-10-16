extends BaseTest
## Kayıt: gidiş-dönüş, bozuk verinin ayıklanması, atomik yazma.


func test_roundtrip_keeps_every_field() -> void:
	var s := SaveData.create_new(1000)
	s.coins = 12
	s.session = 3
	s.casts = 40
	s.catches = 9
	s.hint_step = 4
	s.records = { "carp": { "count": 2, "best_cm": 61, "best_stars": 3, "first_unix": 1200 } }
	s.settings = { "sfx": false, "easy": true, "locale": "tr" }
	s.flags = { "seen_card": true }
	s.character = "rogue"
	s.rod = "bamboo"
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
		"settings": "bozuk", "character": "", "rod": "",
	})
	assert_eq(back.coins, 0, "negatif para sıfırlanır")
	assert_eq(back.session, 0, "negatif oturum sıfırlanır")
	assert_true(back.records.has("carp"), "geçerli kayıt kalır")
	assert_eq(int(back.records["carp"]["best_stars"]), 5, "yıldız 1..5'e sıkıştırılır")
	assert_true(not back.records.has("pike"), "sayısı 0 olan kayıt düşer")
	assert_true(not back.records.has("bad"), "bozuk kayıt düşer")
	assert_eq(back.settings, {}, "bozuk ayarlar boş sözlük olur")
	assert_eq(back.character, "rogue", "boş karakter varsayılana döner")
	assert_eq(back.rod, "bamboo", "boş olta varsayılana döner")


func test_old_version_is_migrated() -> void:
	var d := SaveData.migrate({ "coins": 3 })
	assert_eq(int(d["version"]), 1, "sürümsüz kayıt v1 olur")


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
