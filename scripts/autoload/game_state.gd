extends Node
## Oyunun kalıcı durumu (autoload "GameState"): içerik veritabanı ve oyuncu kaydı.
## Kayıt/yükleme, dil seçimi, ayarlar ve klavye kontrolleri burada kurulur.

## Kayıttaki bir değer (ayar, kayıt defteri...) değişti.
signal changed
## Uygulama odağı kaybetti (arama, Denetim Merkezi) ya da arka plana geçti: oyun donmalı.
signal focus_lost
## Uygulama odağı geri geldi.
signal focus_gained

const SAVE_PATH := "user://save.json"

var db: ContentDB
var save: SaveData
var clock := TimeProvider.new()
## false iken kayıt diske yazılmaz (--autoplay gibi geliştirici modları için).
var persist: bool = true


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_setup_input()
	db = ContentDB.load_default()
	for e in db.errors:
		push_error("İçerik hatası: " + e)
	load_game()
	apply_locale()


func load_game() -> void:
	var loaded: SaveData = SaveStore.read(SAVE_PATH) if persist else null
	if loaded == null:
		loaded = SaveData.create_new(clock.now_unix())
	if loaded.player_id.is_empty():
		loaded.player_id = SaveData.generate_player_id()
	if loaded.seed == 0:
		loaded.seed = SaveData.generate_seed()
	loaded.session += 1
	loaded.last_seen_unix = clock.now_unix()
	use_save(loaded)
	save_game()


## Verilen kaydı etkin yapar.
func use_save(s: SaveData) -> void:
	save = s
	changed.emit()


func save_game() -> void:
	if not persist or save == null:
		return
	save.last_seen_unix = clock.now_unix()
	SaveStore.write(save, SAVE_PATH)


func reset_save() -> void:
	var locale := str(save.settings.get("locale", ""))
	var fresh := SaveData.create_new(clock.now_unix())
	fresh.session = 1
	if not locale.is_empty():
		fresh.settings["locale"] = locale
	use_save(fresh)
	save_game()


## Genel bir ayarı kaydeder (ses, titreşim, Kolay çekme...).
func set_setting(key: String, value: Variant) -> void:
	save.settings[key] = value
	save_game()
	changed.emit()


func setting(key: String, default: Variant) -> Variant:
	return save.settings.get(key, default)


func set_hint_step(step: int) -> void:
	save.hint_step = step
	save_game()


func set_flag(key: String, value: Variant) -> void:
	save.flags[key] = value
	save_game()


## Bir kez gösterilecek bayrağı okur ve siler (yoksa default).
func take_flag(key: String, default: Variant = null) -> Variant:
	if not save.flags.has(key):
		return default
	var value: Variant = save.flags[key]
	save.flags.erase(key)
	save_game()
	return value


## Kayıtta dil seçimi yoksa cihaz dilini kullan (Türkçe değilse İngilizce).
func apply_locale() -> void:
	var locale := str(save.settings.get("locale", ""))
	if locale.is_empty():
		locale = "tr" if OS.get_locale_language() == "tr" else "en"
	TranslationServer.set_locale(locale)


func toggle_locale() -> void:
	var next := "en" if TranslationServer.get_locale().begins_with("tr") else "tr"
	save.settings["locale"] = next
	TranslationServer.set_locale(next)
	save_game()
	changed.emit()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_WM_CLOSE_REQUEST:
			focus_lost.emit()
			save_game()
		NOTIFICATION_APPLICATION_FOCUS_OUT:
			focus_lost.emit()
			save_game()
		NOTIFICATION_APPLICATION_RESUMED, NOTIFICATION_APPLICATION_FOCUS_IN:
			focus_gained.emit()


## Klavye kontrolleri (Mac'te test için). Dokunmatik kontroller sahnede.
func _setup_input() -> void:
	_add_keys(&"move_left", [KEY_A, KEY_LEFT])
	_add_keys(&"move_right", [KEY_D, KEY_RIGHT])
	_add_keys(&"move_forward", [KEY_W, KEY_UP])
	_add_keys(&"move_back", [KEY_S, KEY_DOWN])
	_add_keys(&"action", [KEY_SPACE])


func _add_keys(action: StringName, keys: Array[Key]) -> void:
	if not InputMap.has_action(action):
		InputMap.add_action(action)
	for key in keys:
		var ev := InputEventKey.new()
		ev.physical_keycode = key
		InputMap.action_add_event(action, ev)
