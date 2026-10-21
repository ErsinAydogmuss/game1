class_name LetterPanel
extends Dialog
## Gölün Sırrı'nın mektubu (Dalga 4, 5. adım; docs/gdd.md §10.5): şişeden çıkan ya da defterden yeniden okunan
## mektup. Ersin'in mektup kâğıdı (9 dilimli "letter_paper"; yoksa kodla sarımsı kâğıt), başlıkta "Mektup 3/6",
## mektubun adı (yanında genç yazanın portresi, varsa), yazı ve sonunda imza. Yazı kaydırılır ama altı mektup da
## kâğıda kaydırmadan sığar (test_secret ölçer: telefonda panel küçülmeden). Kapanınca closed: ilk okumada main
## Dede'yi konuşturur. Yazılar refresh'te (her açılışta, o anki dilde).

## Panelin genişliği, mektubun yazısının boyu, yazının alanı (yükseklik), yazının sütununun panelin iki yanından
## payı (kâğıt ve kaydırma çubuğu; test_secret bu genişlikte ölçer), başlıktaki portre.
const WIDTH := 1500.0
const TEXT_SIZE := 32
const TEXT_H := 620.0
const TEXT_PAD := 70.0
const LINE_GAP := 4
const PORTRAIT := 96.0
const PAPER := Color("#f7ecd0")
const PAPER_EDGE := Color("#c79f62")
const LETTER_INK := Color("#3d2817")

## Gösterilen mektubun numarası (1..6).
var letter: int = 1
var _heading: Label
var _portrait: TextureRect
var _scroll: ScrollContainer
var _text: Label
var _from: Label


func _build() -> void:
	set_header(tr("UI_LETTER_N") % [1, Secret.LETTERS.size()], "item:letter", WIDTH)
	_panel.add_theme_stylebox_override("panel", UiKit.framed("letter_paper", _paper_style(), 64.0))
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 18)
	body.add_child(top)
	_portrait = TextureRect.new()
	_portrait.custom_minimum_size = Vector2(PORTRAIT, PORTRAIT)
	_portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	top.add_child(_portrait)
	_heading = UiKit.ink("", UiKit.SIZE_TITLE - 8, LETTER_INK)
	_heading.add_theme_font_override("font", UiKit.display_font())
	_heading.name = "Heading"
	_heading.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(_heading)
	_scroll = ScrollContainer.new()
	_scroll.name = "Scroll"
	_scroll.custom_minimum_size = Vector2(0, TEXT_H)
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	body.add_child(_scroll)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(column)
	_text = UiKit.ink("", TEXT_SIZE, LETTER_INK)
	_text.name = "Text"
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_text.add_theme_constant_override("line_spacing", LINE_GAP)
	column.add_child(_text)
	_from = UiKit.ink("", UiKit.SIZE_BODY - 4, LETTER_INK, HORIZONTAL_ALIGNMENT_RIGHT)
	_from.name = "From"
	_from.add_theme_font_override("font", UiKit.display_font())
	column.add_child(_from)


## Mektubu açar (n: 1..6).
func open_letter(n: int) -> void:
	letter = clampi(n, 1, Secret.LETTERS.size())
	open()
	Sounds.play("paper")
	Sounds.haptic(15)


func refresh() -> void:
	set_header(tr("UI_LETTER_N") % [letter, Secret.LETTERS.size()], "item:letter", WIDTH)
	_heading.text = UiKit.upper(tr(Secret.letter_title_key(letter)))
	_text.text = tr(Secret.letter_key(letter))
	_from.text = UiKit.upper(tr(Secret.letter_from_key(letter)))
	# Kâğıt yazının boyunda (kısa mektupta altı boş kalmasın), en çok TEXT_H (uzunsa kaydırılır).
	_scroll.custom_minimum_size.y = minf(TEXT_H, text_height(_text.text))
	# Başlığın yanında genç yazanın portresi (Parti 5a; yoksa yalnızca başlık).
	var face := ItemArt.portrait("young_" + Secret.letter_writer(letter))
	_portrait.texture = face
	_portrait.visible = face != null
	_scroll.scroll_vertical = 0


## Mektubun yazısının imzasıyla kâğıtta kapladığı yükseklik (sütun panelin iki yanından TEXT_PAD içeride;
## test_secret de bununla ölçer).
static func text_height(text: String) -> float:
	var font := UiKit.body_font()
	var flags := TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND | TextServer.BREAK_ADAPTIVE
	var measured := font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, WIDTH - 2.0 * TEXT_PAD, TEXT_SIZE,
			-1, flags)
	var lines := ceili(measured.y / font.get_height(TEXT_SIZE) - 0.01)
	return lines * (font.get_height(TEXT_SIZE) + LINE_GAP) + 10.0 + UiKit.display_font().get_height(UiKit.SIZE_BODY - 4)


## Yazının tamamı (imzayla) kaydırmadan görünüyor mu (bot: telefonda mektup kaydırılmadan okunur)?
func fits_without_scroll() -> bool:
	return (_text.get_parent() as Control).get_combined_minimum_size().y <= _scroll.size.y + 1.0


## Mektup kâğıdının yedeği: sarımsı kâğıt, kahverengi ince kenar, yumuşak gölge.
static func _paper_style() -> StyleBoxFlat:
	var sb := UiKit.dialog_style(18)
	sb.bg_color = PAPER
	sb.border_color = PAPER_EDGE
	sb.set_border_width_all(5)
	sb.set_content_margin_all(44)
	return sb
