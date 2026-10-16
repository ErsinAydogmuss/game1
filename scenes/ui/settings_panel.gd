class_name SettingsPanel
extends Dialog
## Ayarlar: ses efektleri, müzik, titreşim, Kolay çekme, dil. (Kazı'dan uyarlandı.)
## Geliştirme sürümünde kaydı sıfırlama da burada.

## Satır düğmelerinin yüksekliği: en az 122 birim (iPhone'da ~44 pt, Apple'ın önerdiği dokunma boyu).
const ROW_BUTTON := Vector2(300, 122)

var _rows: VBoxContainer


func _build() -> void:
	set_header(tr("UI_SETTINGS"), "settings", 1100.0)
	_rows = VBoxContainer.new()
	_rows.add_theme_constant_override("separation", 12)
	body.add_child(_rows)
	GameState.changed.connect(func() -> void:
		if visible:
			refresh())


func refresh() -> void:
	set_header(tr("UI_SETTINGS"), "settings", 1100.0)
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
	if OS.is_debug_build():
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
