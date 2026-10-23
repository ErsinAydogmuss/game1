class_name CreditsPanel
extends Control
## Jenerik (docs/gdd.md §10.5; bitiş filminden sonra): StoryPanel gibi "modal" örtü, Dialog değil: göl arkada
## yaşar, oyun girdisi kapalı. Koyu yarı saydam zemin; ortada aşağıdan yukarı kendiliğinden kayan yazılar: logo,
## emek verenler (ROLES: Ersin fikir ve görseller, Claude kod, KayKit ve Kenney 3B modeller, yazı tipleri, kodla
## üretilen sesler), teşekkür ve son söz. Sağ üstte ATLA (güvenli alanda, 122 boy; açıldıktan SKIP_GUARD sn
## sonra çalışır); yazılar bitince ya da ATLA'da finished. Süreler _process(delta) toplamıyla.

signal finished(skipped: bool)

## Kayma hızı (birim/sn) ve yazıların genişliği (test_story iki dilde ölçer: her satır tek satıra sığar).
const SPEED := 95.0
const WIDTH := 1400.0
const ROLE_SIZE := 34
const NAME_SIZE := 52
const END_SIZE := 46
const SKIP_SIZE := Vector2(260, 122)
## ATLA ancak bu kadar sn sonra çalışır: filmin ATLA'sına çift dokunuş jeneriği de atlamasın (iki düğme aynı yerde).
const SKIP_GUARD := 0.8
## Bir karenin en uzun adımı (sn): uygulama arka plandan dönünce jenerik sıçramasın.
const MAX_STEP := 0.1
## Emek verenler: [görevin anahtarı, adlar]. "UI_" ile başlayan ad çevrilir.
const ROLES: Array[Array] = [
	["UI_CREDITS_IDEA", ["Ersin"]],
	["UI_CREDITS_CODE", ["Claude"]],
	["UI_CREDITS_MODELS", ["KayKit · Kay Lousberg", "Kenney"]],
	["UI_CREDITS_FONTS", ["Luckiest Guy · Astigmatic", "Baloo 2 · Ek Type"]],
	["UI_CREDITS_SOUND", ["UI_CREDITS_SOUND_BY"]],
	["UI_CREDITS_THANKS", ["UI_CREDITS_PLAYERS"]],
]

var skip_button: Button
## true iken kayma durur (odak kaybı: main verir).
var held: bool = false

var _dim: ColorRect
var _column: VBoxContainer
var _offset: float = 0.0
## Jenerik kaç sn'dir ekranda (ATLA'nın koruması).
var _age: float = 0.0


func _ready() -> void:
	theme = UiKit.theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_to_group("modal")
	_dim = ColorRect.new()
	_dim.color = Color(0.02, 0.03, 0.06, 0.72)
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_dim)
	_column = VBoxContainer.new()
	_column.alignment = BoxContainer.ALIGNMENT_CENTER
	_column.add_theme_constant_override("separation", 10)
	_column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_column)
	skip_button = UiKit.button("", UiKit.NEUTRAL, UiKit.SIZE_SMALL, SKIP_SIZE)
	skip_button.name = "Skip"
	skip_button.pressed.connect(_on_skip)
	add_child(skip_button)
	get_viewport().size_changed.connect(_layout)
	hide()


## Jenerik baştan: yazılar o anki dilde kurulur, ekranın altından başlar.
func play() -> void:
	_build()
	show()
	_offset = 0.0
	_age = 0.0
	_layout()


## Yarıda kesildi (kayıt değişti): örtü gizlenir, finished yayılmaz.
func stop() -> void:
	hide()


## Yazıların toplam yüksekliği (bot ve testler: süre).
func content_height() -> float:
	return _column.get_combined_minimum_size().y


func _process(delta: float) -> void:
	if not visible or held:
		return
	# Uygulama arka plandan dönünce ilk karenin delta'sı uzakta geçen süredir: jenerik bir anda bitmesin.
	delta = minf(delta, MAX_STEP)
	_age += delta
	_offset += delta * SPEED
	_layout()
	var view := get_viewport_rect().size
	if _offset > view.y + content_height():
		_finish(false)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		accept_event()


func _on_skip() -> void:
	if _age < SKIP_GUARD:
		return
	Sounds.play("ui_tap")
	_finish(true)


func _finish(skipped: bool) -> void:
	if not visible:
		return
	hide()
	finished.emit(skipped)


func _build() -> void:
	skip_button.text = UiKit.upper(tr("UI_INTRO_SKIP"))
	for child in _column.get_children():
		child.queue_free()
	var art := ItemArt.art("logo.png")
	if art != null:
		var rect := TextureRect.new()
		rect.texture = art
		rect.custom_minimum_size = Vector2(620, 340)
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		_column.add_child(rect)
	else:
		_column.add_child(UiKit.title(tr("UI_GAME_TITLE"), UiKit.SIZE_HERO, UiKit.ACCENT))
	_column.add_child(_gap(60.0))
	for role: Array in ROLES:
		_column.add_child(_line(tr(str(role[0])), ROLE_SIZE, UiKit.ACCENT))
		for who: String in role[1]:
			_column.add_child(_line(credit_name(who), NAME_SIZE, UiKit.TEXT))
		_column.add_child(_gap(48.0))
	_column.add_child(_gap(40.0))
	_column.add_child(_line(tr("UI_CREDITS_END"), END_SIZE, UiKit.rarity_color(GameState.db,
			GameState.db.rarity_index("mythic")).lightened(0.2)))


static func _gap(height: float) -> Control:
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0.0, height)
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return gap


## Emek verenin adı: "UI_" ile başlayan çevrilir, öteki olduğu gibi.
static func credit_name(who: String) -> String:
	return TranslationServer.translate(who) if who.begins_with("UI_") else who


func _line(text: String, size: int, color: Color) -> Label:
	var label := UiKit.title(text, size, color, HORIZONTAL_ALIGNMENT_CENTER, 10)
	label.custom_minimum_size = Vector2(WIDTH, 0)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _layout() -> void:
	if not is_inside_tree():
		return
	var view := get_viewport_rect().size
	var inset := UiKit.safe_insets(self)
	skip_button.size = SKIP_SIZE
	skip_button.position = Vector2(view.x - inset.z - Hud.MARGIN - SKIP_SIZE.x, inset.y + Hud.MARGIN)
	_column.reset_size()
	_column.size = Vector2(WIDTH, content_height())
	_column.position = Vector2((view.x - WIDTH) * 0.5, view.y - _offset)
