class_name WardrobePanel
extends Dialog
## Dolap (Dalga 5, 3. adım): balıkçıya dokununca açılır. Balıkçının görünüşü: kız ya da oğlan, her biri canlı
## önizlemeyle (AnglerPreview) ve SEÇ düğmesiyle; seçilen hemen değişir, ilerleme aynen kalır. Yeni oyunda açılış
## filminden önce seçim ekranı olarak açılır (open_first: başlık "Balıkçını seç", kapatma düğmesi yok: seçmeden
## geçilmez). Kıyafet sekmeleri (şapka, yelek, olta) 4. adımda.

signal chosen(kind: String)

const WIDTH := 1300.0
const PREVIEW := Vector2(420, 380)
const BUTTON := Vector2(300, 122)
const NAMES := { "girl": "UI_CHAR_GIRL", "boy": "UI_CHAR_BOY" }

var _first: bool = false
var _note: Label
var _cards: Dictionary = {}
var _buttons: Dictionary = {}
var _names: Dictionary = {}
var _previews: Dictionary = {}


func _build() -> void:
	set_header(tr("UI_WARDROBE"), "wardrobe", WIDTH)
	_note = UiKit.ink("", UiKit.SIZE_SMALL, UiKit.INK)
	_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_note.custom_minimum_size = Vector2(WIDTH - 200.0, 0)
	body.add_child(_note)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 60)
	body.add_child(row)
	for kind: String in SaveData.CHARACTERS:
		var column := Dialog.card(row)
		var panel := column.get_parent() as PanelContainer
		panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		panel.name = "Card_" + kind
		_cards[kind] = panel
		column.alignment = BoxContainer.ALIGNMENT_CENTER
		var preview := AnglerPreview.new()
		preview.custom_minimum_size = PREVIEW
		preview.show_look(kind)
		column.add_child(preview)
		_previews[kind] = preview
		var label := UiKit.title("", 46, UiKit.PRIMARY)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		column.add_child(label)
		_names[kind] = label
		var center := CenterContainer.new()
		column.add_child(center)
		var button := UiKit.button("", UiKit.SUCCESS, UiKit.SIZE_SMALL + 4, BUTTON)
		button.name = "Button_" + kind
		button.pressed.connect(func() -> void: _pick(kind))
		center.add_child(button)
		_buttons[kind] = button


## Yeni oyunda seçim ekranı: kapatma düğmesi yok, seçince kapanır (main açılış filmini başlatır).
func open_first() -> void:
	_first = true
	open()


## Dolap: balıkçıya dokununca; seçim hemen uygulanır, panel açık kalır.
func open_wardrobe() -> void:
	_first = false
	open()


## Seçim ekranı olarak mı açık (yeni oyun)?
func is_first() -> bool:
	return _first


## Yazılar her açılışta o anki dilde (panel, dil uygulanmadan önce kurulur).
func refresh() -> void:
	set_header(tr("UI_CHAR_TITLE") if _first else tr("UI_WARDROBE"), "wardrobe", WIDTH)
	close_button.visible = not _first
	_note.text = tr("UI_CHAR_NOTE_FIRST") if _first else tr("UI_WARDROBE_NOTE")
	var current := GameState.save.character
	for kind: String in _buttons:
		(_names[kind] as Label).text = UiKit.upper(tr(str(NAMES[kind])))
		var button: Button = _buttons[kind]
		var picked := not _first and kind == current
		button.text = UiKit.upper(tr("UI_CHAR_PICKED") if picked else tr("UI_CHAR_PICK"))
		button.disabled = picked
		var panel: PanelContainer = _cards[kind]
		panel.add_theme_stylebox_override("panel", UiKit.card_style(UiKit.SUCCESS if picked else UiKit.CREAM_EDGE))


## Dil açıkken değişirse yazılar yeni dilde (yeni oyunda seçim ekranı oturumun başında açılır).
func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and _note != null and visible:
		refresh()


func _pick(kind: String) -> void:
	Sounds.play("equip")
	Sounds.haptic(15)
	var first := _first
	chosen.emit(kind)
	if first:
		_first = false
		close_panel()
	else:
		refresh()
