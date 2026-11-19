class_name TrapPanel
extends Dialog
## Tuzağın paneli (docs/gdd.md §10.3; testçi: "kurulan tuzak geri alınmıyor"): tuzağın şamandırasına ya da
## rozetine dokununca açılır (uzaktaysa balıkçı yürür, varınca). İçinde kaç kerevit olduğu ya da boşsa sıradaki
## kerevitin ne zaman gireceği (gerçek saatle; oyun kapalıyken de dolar, hızlandırma yok) ve iki düğme:
## - KALDIR (remove_requested): tuzak çantaya döner (girmiş kerevitler önce kovaya; kova yetmezse main
##   kaldırmaz; girmemiş içerik girmemiş sayılır), takım çantasından yeniden bırakılır;
## - TOPLA (collect_requested; kerevit varsa) ya da BEKLE (boşsa: panel kapanır).
## Yazı panel açıkken her saniye yenilenir: bu arada bir kerevit girerse BEKLE TOPLA olur.

signal remove_requested(id: int)
signal collect_requested(id: int)

const WIDTH := 1150.0
const BUTTON := Vector2(340, 122)

var trap_id: int = -1

var _art: TextureRect
var _text: Label
var _remove: Button
var _main: Button
## Ana düğme TOPLA mı (kerevit var) yoksa BEKLE mi.
var _collect := false
var _clock: float = 0.0


func _build() -> void:
	set_header(tr("UI_BAG_TRAP"), "tech_trap", WIDTH)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 28)
	body.add_child(row)
	_art = TextureRect.new()
	_art.texture = ItemArt.item("crayfish")
	_art.custom_minimum_size = Vector2(150, 150)
	_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	row.add_child(_art)
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
	_main = UiKit.button("", UiKit.SUCCESS, UiKit.SIZE_SMALL + 4, BUTTON)
	_main.name = "Button_wait"
	_main.pressed.connect(func() -> void:
		Sounds.play("ui_tap")
		var id := trap_id
		var collect := _collect
		close_panel()
		if collect:
			collect_requested.emit(id))
	buttons.add_child(_main)


## Tuzağın panelini açar (kimliğiyle).
func open_trap(id: int) -> void:
	trap_id = id
	open()


## Yazılar her açılışta o anki dilde (panel, dil uygulanmadan önce kurulur).
func refresh() -> void:
	set_header(tr("UI_BAG_TRAP"), "tech_trap", WIDTH)
	_remove.text = UiKit.upper(tr("UI_TRAP_REMOVE"))
	var db := GameState.db
	var save := GameState.save
	var index := TrapSim.find(save, trap_id)
	if index < 0:
		_text.text = ""
		_set_main(false)
		return
	var trap := save.traps[index]
	TrapSim.update(db.rules, trap, GameState.clock.now_unix())
	var ready := TrapSim.ready(db.rules, trap)
	if ready > 0:
		_text.text = tr("UI_TRAP_HAS") % ready
		_set_main(true)
		return
	var minutes := maxi(1, ceili(TrapSim.seconds_to_next(db.rules, trap) / 60.0))
	_text.text = tr("UI_TRAP_EMPTY") % minutes
	_set_main(false)


## Ana düğme: kerevit varsa TOPLA (adı Button_collect), yoksa BEKLE (Button_wait); resim kerevit varken parlak.
func _set_main(collect: bool) -> void:
	_collect = collect
	_main.name = "Button_collect" if collect else "Button_wait"
	_main.text = UiKit.upper(tr("UI_TRAP_COLLECT") if collect else tr("UI_TRAP_WAIT"))
	_art.modulate = Color.WHITE if collect else Color(1, 1, 1, 0.6)


func _process(delta: float) -> void:
	if not visible:
		return
	_clock += delta
	if _clock >= 1.0:
		_clock = 0.0
		refresh()
