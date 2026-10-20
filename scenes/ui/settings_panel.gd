class_name SettingsPanel
extends Dialog
## Ayarlar: ses efektleri, müzik, titreşim, Kolay çekme, dil; başlıkta "Nasıl oynanır?" (rehber:
## help_requested). (Kazı'dan uyarlandı.)
## Sürüm yazısına arka arkaya 5 kez dokununca ölçüm açılır ya da kapanır (HUD'da FPS, çizim ve
## üçgen sayısı; telefonda hız ölçümü: docs/iphone-kurulum.md). Ölçüm açıkken geliştirme sürümünde
## iki satır daha görünür (normalde panel küçülmeden sığsın): deneme düğmeleri (hepsini aç, para,
## rütbe atlama: rank_up_requested, main gerçek akışla atlatır) ve kaydı sıfırlama.

## Bir rütbe atlatılsın (geliştirme sürümü; main gerçek akışla: bildirim, açılan yer, Dede).
signal rank_up_requested

## Satır düğmelerinin yüksekliği: en az 122 birim (iPhone'da ~44 pt, Apple'ın önerdiği dokunma boyu).
const ROW_BUTTON := Vector2(300, 122)
## Geliştirme satırındaki para düğmeleri (dükkânda takım denemek için).
const DEBUG_COINS: Array[int] = [1000, 10000]
## Başlıktaki oyun logosunun kutusu (kapat düğmesinin boyunda: başlık uzamasın).
const LOGO := Vector2(170, 122)
## Ölçümü açan dokunuş sayısı ve iki dokunuş arasındaki en uzun süre (sn).
const PERF_TAPS := 5
const TAP_GAP := 0.8

var _rows: VBoxContainer
## Başlıktaki "Nasıl oynanır?" düğmesi (rehberin ana girişi; yazısı refresh'te).
var _guide: Button
var _taps: int = 0
var _since_tap: float = 0.0


func _build() -> void:
	set_header(tr("UI_SETTINGS"), "settings", 1100.0)
	# Başlıkta ayar ikonu yerine oyunun logosu (Ersin'in; yoksa ikon kalır).
	var logo := ItemArt.art("logo.png")
	if logo != null:
		var rect := TextureRect.new()
		rect.texture = logo
		rect.custom_minimum_size = LOGO
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		_icon.get_parent().add_child(rect)
		_icon.get_parent().move_child(rect, _icon.get_index())
		_icon.visible = false
	# Rehber: başlıkta yazılı düğme (satır eklenince panel telefonda küçülürdü; başlıkta yer var).
	_guide = UiKit.button("", UiKit.SECONDARY, UiKit.SIZE_SMALL, Vector2(0, 122))
	_guide.name = "Guide"
	_guide.pressed.connect(func() -> void:
		Sounds.play("ui_tap")
		help_requested.emit("basics"))
	header_extra.add_child(_guide)
	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 12)
	body.add_child(_rows)
	GameState.changed.connect(func() -> void:
		if visible:
			refresh())


func refresh() -> void:
	set_header(tr("UI_SETTINGS"), "settings", 1100.0)
	_guide.text = UiKit.upper(tr("UI_GUIDE_OPEN"))
	clear(_rows)
	var settings := GameState.save.settings
	_toggle(tr("UI_SET_SFX"), "sound", bool(settings.get("sfx", true)),
			func(on: bool) -> void: GameState.set_setting("sfx", on))
	_toggle(tr("UI_SET_MUSIC"), "music", bool(settings.get("music", true)),
			func(on: bool) -> void: GameState.set_setting("music", on))
	_toggle(tr("UI_SET_VIBRATION"), "vibration", bool(settings.get("vibration", true)),
			func(on: bool) -> void: GameState.set_setting("vibration", on))
	_toggle(tr("UI_SET_EASY"), "easy", bool(settings.get("easy", false)),
			func(on: bool) -> void: GameState.set_setting("easy", on))
	var lang := _row(tr("UI_SET_LANGUAGE"), "globe")
	var lang_button := UiKit.button(tr("UI_LANG_NAME"), UiKit.SECONDARY, UiKit.SIZE_BODY, ROW_BUTTON)
	lang_button.pressed.connect(func() -> void: GameState.toggle_locale())
	lang.add_child(lang_button)
	# Oyunun adı ve sürüm (eskiden HUD'un sol üstündeydi; orada artık para, kova ve rütbe var).
	# Arka arkaya 5 dokunuş ölçümü açar ya da kapatır.
	var text := "%s · %s" % [tr("UI_GAME_TITLE"),
			tr("UI_VERSION") % str(ProjectSettings.get_setting("application/config/version", "0"))]
	if bool(settings.get("perf", false)):
		text += " · " + tr("UI_PERF_ON")
	var version := UiKit.ink(text, UiKit.SIZE_SMALL, UiKit.INK_SOFT)
	version.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	version.mouse_filter = Control.MOUSE_FILTER_STOP
	version.gui_input.connect(_on_version_input)
	_rows.add_child(version)
	if OS.is_debug_build() and bool(settings.get("perf", false)):
		_debug_row()
		var reset := _row(tr("UI_DEBUG_RESET"), "close")
		var reset_button := UiKit.button(tr("UI_DEBUG_RESET"), UiKit.DANGER, UiKit.SIZE_SMALL, ROW_BUTTON)
		# Tek dokunuş kaydı silmesin: ilk dokunuş sorar, 3 sn içinde ikincisi siler.
		var armed: Array[bool] = [false]
		reset_button.pressed.connect(func() -> void:
			if not armed[0]:
				armed[0] = true
				reset_button.text = UiKit.upper(tr("UI_DEBUG_RESET_SURE"))
				get_tree().create_timer(3.0).timeout.connect(func() -> void:
					armed[0] = false
					if is_instance_valid(reset_button):
						reset_button.text = UiKit.upper(tr("UI_DEBUG_RESET")))
				return
			close_panel()
			GameState.reset_save())
		reset.add_child(reset_button)


func _process(delta: float) -> void:
	_since_tap += delta


## Sürüm yazısına dokunuş (parmak kalkınca): arka arkaya PERF_TAPS dokunuşta ölçüm açılır ya da kapanır.
func _on_version_input(event: InputEvent) -> void:
	var mb := event as InputEventMouseButton
	if mb == null or mb.pressed or mb.button_index != MOUSE_BUTTON_LEFT:
		return
	_taps = _taps + 1 if _since_tap <= TAP_GAP else 1
	_since_tap = 0.0
	if _taps < PERF_TAPS:
		return
	_taps = 0
	Sounds.play("ui_tap")
	Sounds.haptic(20)
	GameState.set_setting("perf", not bool(GameState.setting("perf", false)))


## Geliştirme sürümünün deneme düğmeleri, tek satırda: hepsini aç, para ekle, bir rütbe atla (en
## yüksek rütbede pasif). Satır sayısı ölçüm açıkken de aynı kalsın diye etiketsiz.
func _debug_row() -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	_rows.add_child(row)
	_debug_button(row, "DebugUnlock", tr("UI_DEBUG_UNLOCK_GO")).pressed.connect(_unlock_zones)
	for amount: int in DEBUG_COINS:
		_debug_button(row, "DebugCoins%d" % amount, tr("UI_DEBUG_COINS") % UiKit.format_int(amount)).pressed.connect(
				_add_coins.bind(amount))
	var rank := _debug_button(row, "DebugRankUp", tr("UI_DEBUG_RANK_UP"))
	rank.disabled = Rank.rank(GameState.db, GameState.save) >= GameState.db.max_rank()
	rank.pressed.connect(func() -> void:
		Sounds.play("ui_tap")
		rank_up_requested.emit())


## Satırı eşit paylaşan düğme (bot adıyla bulur: dokunuştan sonra satırlar yeniden kurulur).
func _debug_button(row: HBoxContainer, id: String, text: String) -> Button:
	var b := UiKit.button(text, UiKit.SECONDARY, UiKit.SIZE_SMALL, Vector2(0, ROW_BUTTON.y))
	b.name = id
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(b)
	return b


## Geliştirme sürümü: para eklenir (dükkânda takım denemek için).
func _add_coins(amount: int) -> void:
	GameState.save.coins += amount
	Sounds.play("coins")
	Sounds.haptic(20)
	GameState.save_game()
	GameState.changed.emit()


## Geliştirme sürümü: rütbe en yüksek bölgenin rütbesine çıkar; sandal, tekniklerin ilk kamışları ve
## ilk tuzak verilir (bütün bölgeler ve teknikler açılır; telefonda her bölgede ölçüm ve deneme için).
## Para ve defter değişmez.
func _unlock_zones() -> void:
	var db := GameState.db
	var save := GameState.save
	var top := 1
	for z in db.zones_of(db.main_spot):
		top = maxi(top, int(z["rank"]))
	save.xp = maxi(save.xp, db.rank_xp[top - 1])
	if not Zones.BOAT in save.owned:
		save.owned.append(Zones.BOAT)
	# Telefonda bütün teknikleri denemek için tekniklerin ilk kamışı ve ilk tuzak da verilir.
	for t: String in ContentDB.TECHNIQUES:
		var rods := db.rods_of(t)
		if t != "float" and not rods.is_empty() and not Economy.technique_ready(db, save, t):
			save.owned.append(str(rods[0]["id"]))
			Economy.equip(db, save, str(rods[0]["id"]))
	if TrapSim.owned(db, save) == 0 and not TrapSim.next_trap(db, save).is_empty():
		save.owned.append(str(TrapSim.next_trap(db, save)["id"]))
	Sounds.play("ui_tap")
	GameState.save_game()
	GameState.changed.emit()


func _row(text: String, icon_kind: String) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	_rows.add_child(row)
	row.add_child(GameIcon.make(icon_kind, 72))
	var label := UiKit.ink(text, UiKit.SIZE_BODY)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	return row


func _toggle(text: String, icon_kind: String, on: bool, apply: Callable) -> void:
	var row := _row(text, icon_kind)
	var b := UiKit.button(tr("UI_ON") if on else tr("UI_OFF"), UiKit.SUCCESS if on else UiKit.NEUTRAL,
			UiKit.SIZE_BODY, ROW_BUTTON)
	b.pressed.connect(func() -> void: apply.call(not on))
	row.add_child(b)
