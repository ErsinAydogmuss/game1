extends BaseTest
## Sesler: koddaki her ses adının dosyası var (tools/make_sounds.py üretir) ve kod yalnızca
## tanımlı sesleri çalar. Sounds autoload'u -s modunda kurulmaz; listesi betikten okunur.

const SOUNDS_SCRIPT := "res://scripts/autoload/sounds.gd"


func _constants() -> Dictionary:
	return (load(SOUNDS_SCRIPT) as GDScript).get_script_constant_map()


func test_every_sound_has_a_file() -> void:
	var c := _constants()
	var bank: Dictionary = c["BANK"]
	for sound: String in bank:
		assert_true(ResourceLoader.exists("%s%s_1.wav" % [c["SFX_DIR"], sound]), "efekt dosyası yok: " + sound)
	var loops: Dictionary = c["LOOPS"]
	for loop_name: String in loops:
		assert_true(ResourceLoader.exists("%s%s.wav" % [c["LOOP_DIR"], loop_name]), "döngü yok: " + loop_name)
	for track: String in c["AMBIENCE"]:
		assert_true(ResourceLoader.exists("%s%s.ogg" % [c["AMBIENCE_DIR"], track]), "ortam sesi yok: " + track)
	# Müzik: her vaktin parçası ve dükkânın valsi (Dalga 4).
	var music: Array = c["MUSIC"]
	for phase: String in DayClock.PHASES:
		assert_true(phase in music, "vaktin müziği listede: " + phase)
	assert_true("shop" in music, "dükkânın müziği listede")
	for track: String in music:
		assert_true(ResourceLoader.exists("%s%s.ogg" % [c["MUSIC_DIR"], track]), "müzik yok: " + track)


func test_code_plays_only_known_sounds() -> void:
	var c := _constants()
	var bank: Dictionary = c["BANK"]
	var loops: Dictionary = c["LOOPS"]
	var play := RegEx.create_from_string("Sounds\\.play\\(\"([a-z_0-9]+)\"[,)]")
	var loop := RegEx.create_from_string("Sounds\\.set_loop\\(\"([a-z_0-9]+)\"")
	var checked := 0
	for path in _scripts("res://scenes") + _scripts("res://scripts"):
		var text := FileAccess.get_file_as_string(path)
		for m in play.search_all(text):
			checked += 1
			assert_true(bank.has(m.get_string(1)), "%s: tanımsız ses %s" % [path, m.get_string(1)])
		for m in loop.search_all(text):
			assert_true(loops.has(m.get_string(1)), "%s: tanımsız döngü %s" % [path, m.get_string(1)])
	assert_true(checked > 10, "ses çağrıları bulundu (%d)" % checked)
	# Her nadirliğin buluntu sesi (Sounds.find: 0 Sıradan .. 5 Masalsı → find_1..6).
	for rarity in range(1, 7):
		assert_true(bank.has("find_%d" % rarity), "buluntu sesi: %d" % rarity)
	# Vakit değişimi ve fener bildirimle (toast_later) çalar.
	for sound: String in ["phase", "lantern", "thunder", "tea"]:
		assert_true(bank.has(sound), "Dalga 4 sesi: " + sound)


static func _scripts(dir: String) -> Array[String]:
	var out: Array[String] = []
	for file in DirAccess.get_files_at(dir):
		if file.ends_with(".gd"):
			out.append(dir.path_join(file))
	for sub in DirAccess.get_directories_at(dir):
		out.append_array(_scripts(dir.path_join(sub)))
	return out
