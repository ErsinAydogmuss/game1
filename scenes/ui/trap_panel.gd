class_name TrapPanel
extends Dialog
## Boş tuzak (docs/gdd.md §10.3): şamandırasına dokunulan tuzakta kerevit yoksa açılır. Sıradaki
## kerevitin ne zaman gireceği (gerçek saatle; oyun kapalıyken de dolar, hızlandırma yok) ve iki
## düğme: BEKLE (kapanır) ya da KALDIR (tuzak geri alınır, takım çantasından yeniden bırakılır;
## girmemiş içerik girmemiş sayılır). Kalan süre panel açıkken her saniye yenilenir.

signal remove_requested(id: int)

const WIDTH := 1150.0
const BUTTON := Vector2(340, 122)

var trap_id: int = -1

var _text: Label
var _remove: Button
var _wait: Button
var _clock: float = 0.0


func _build() -> void:
	set_header(tr("UI_BAG_TRAP"), "tech_trap", WIDTH)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 28)
	body.add_child(row)
	var art := TextureRect.new()
	art.texture = ItemArt.item("crayfish")
	art.custom_minimum_size = Vector2(150, 150)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	art.modulate = Color(1, 1, 1, 0.6)
	row.add_child(art)
	_text = UiKit.ink("", UiKit.SIZE_BODY, UiKit.INK)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.custom_minimum_size = Vector2(WIDTH - 330.0, 0)
	_text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(_text)
	var buttons := HBoxContainer.new()
	buttons.alignment = BoxContainer.ALIGNMENT_CENTER
	buttons.add_theme_constant_override("separation", 40)
	body.add_child(buttons)
	_remove = UiKit.button("", UiKit.NEUTRAL, UiKit.SIZE_SMALL + 4, BUTTON)
	_remove.name = "Button_remove"
	_remove.pressed.connect(func() -> void:
		Sounds.play("ui_tap")
		var id := trap_id
		close_panel()
		remove_requested.emit(id))
	buttons.add_child(_remove)
	_wait = UiKit.button("", UiKit.SUCCESS, UiKit.SIZE_SMALL + 4, BUTTON)
	_wait.name = "Button_wait"
	_wait.pressed.connect(func() -> void:
		Sounds.play("ui_tap")
		close_panel())
	buttons.add_child(_wait)


## Tuzağın panelini açar (kimliğiyle).
func open_trap(id: int) -> void:
	trap_id = id
	open()


## Yazılar her açılışta o anki dilde (panel, dil uygulanmadan önce kurulur).
func refresh() -> void:
	set_header(tr("UI_BAG_TRAP"), "tech_trap", WIDTH)
	_remove.text = UiKit.upper(tr("UI_TRAP_REMOVE"))
	_wait.text = UiKit.upper(tr("UI_TRAP_WAIT"))
	var db := GameState.db
	var save := GameState.save
	var index := TrapSim.find(save, trap_id)
	if index < 0:
		_text.text = ""
		return
	var trap := save.traps[index]
	TrapSim.update(db.rules, trap, GameState.clock.now_unix())
	var minutes := maxi(1, ceili(TrapSim.seconds_to_next(db.rules, trap) / 60.0))
	_text.text = tr("UI_TRAP_EMPTY") % minutes


func _process(delta: float) -> void:
	if not visible:
		return
	_clock += delta
	if _clock >= 1.0:
		_clock = 0.0
		refresh()
