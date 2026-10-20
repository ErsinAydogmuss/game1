class_name GuidePanel
extends Dialog
## "Nasıl oynanır?" rehberi: oyunun baştan sona anlatımı, 9 sayfa (içerik GuidePages'te). Panelde
## yukarıdan aşağıya:
## - sayfanın ikonu ve adı, sağda kaçıncı sayfa olduğu;
## - bir satırlık giriş cümlesi;
## - karolar;
## - sayfa sekmeleri (numaralı ikonlar) ve İLERİ (son sayfada pasif).
## Açılmamış teknik, bölge ve takım da görünür: görseli soluk, kilidinde açıldığı rütbe yazar.
## Ayarlar'dan, Takım Çantası'ndan ve Nine'nin dükkânından (o sekmenin sayfası) açılır. Açıldığı
## panelin üstünde durur (main en son kurar); kapanınca o panel açık kalır.

const WIDTH := 1760.0
const TAB := Vector2(122, 122)
const TAB_ICON := 84.0
const NEXT := Vector2(260, 122)
const TAB_GAP := 12
## Kilitli karo: soluk görsel ve biraz koyu zemin (dükkân ve çantadaki gibi).
const LOCKED_ART := Color(1, 1, 1, 0.55)
const LOCKED_FILL := Color("#efe2c6")
const LOCK_PILL := Color(0.18, 0.1, 0.04, 0.85)
const WHERE_PILL := Color("#2f6fcc")
## Eylem karosunun düğme yazısı (sığmazsa küçülür) ve ikonu.
const CHIP_TEXT := 44
const CHIP_ICON := 64.0

var _page: String = "basics"
var _lead: Label
var _area: CenterContainer
var _tabs: HBoxContainer
var _tab_buttons: Dictionary = {}
var _next: Button
var _counter: Label


func _build() -> void:
	set_header("", "question", WIDTH)
	var count := PanelContainer.new()
	count.add_theme_stylebox_override("panel", UiKit.pill_style(Color(0.18, 0.1, 0.04, 0.85)))
	_counter = UiKit.title("", 46, UiKit.ACCENT, HORIZONTAL_ALIGNMENT_CENTER, 10)
	count.add_child(_counter)
	header_extra.add_child(count)
	_lead = UiKit.ink("", GuidePages.LEAD_SIZE, UiKit.INK)
	_lead.custom_minimum_size = Vector2(GuidePages.LEAD_W, 0)
	body.add_child(_lead)
	_area = CenterContainer.new()
	_area.custom_minimum_size = GuidePages.AREA
	_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
	body.add_child(_area)
	_tabs = HBoxContainer.new()
	_tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	_tabs.add_theme_constant_override("separation", TAB_GAP)
	body.add_child(_tabs)
	for i in GuidePages.PAGES.size():
		var b := _tab_button(i)
		_tabs.add_child(b)
		_tab_buttons[str(GuidePages.PAGES[i]["id"])] = b
	_next = UiKit.button("", UiKit.SECONDARY, UiKit.SIZE_BODY, NEXT)
	_next.name = "Next"
	_next.pressed.connect(func() -> void:
		var i := GuidePages.page_index(_page)
		if i >= 0 and i < GuidePages.PAGES.size() - 1:
			Sounds.play("ui_tap")
			_show(str(GuidePages.PAGES[i + 1]["id"])))
	_tabs.add_child(_next)


## Rehberi bir sayfada açar (bilinmeyen sayfada ilk sayfa); açıksa yalnızca sayfayı değiştirir.
func open_guide(page_id: String = "basics") -> void:
	_page = page_id if GuidePages.page_index(page_id) >= 0 else str(GuidePages.PAGES[0]["id"])
	if visible:
		refresh()
	else:
		open()


## Bot ve testler: açık sayfa.
func current_page() -> String:
	return _page


func refresh() -> void:
	var db := GameState.db
	var save := GameState.save
	var def := GuidePages.page(_page)
	var index := GuidePages.page_index(_page)
	set_header(tr(str(def["title"])), str(def["icon"]), WIDTH)
	_counter.text = "%d / %d" % [index + 1, GuidePages.PAGES.size()]
	_lead.text = tr(str(def["lead"]))
	_next.text = UiKit.upper(tr("UI_GUIDE_NEXT"))
	_next.disabled = index >= GuidePages.PAGES.size() - 1
	for id: String in _tab_buttons:
		_style_tab(_tab_buttons[id] as Button, id == _page)
	clear(_area)
	var layout := str(def["layout"])
	var grid := GridContainer.new()
	grid.name = "Tiles"
	grid.columns = int((GuidePages.LAYOUTS[layout] as Array)[0])
	grid.add_theme_constant_override("h_separation", int(GuidePages.GAP))
	grid.add_theme_constant_override("v_separation", int(GuidePages.GAP))
	grid.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_area.add_child(grid)
	for tile in GuidePages.tiles_of(db, _page):
		grid.add_child(_tile(db, save, tile, layout))


func _show(page_id: String) -> void:
	_page = page_id
	refresh()


# --- Sekmeler ----------------------------------------------------------------------

## Sayfa sekmesi: sayfanın ikonu ve sol üstte sırası (baştan sona okunsun).
func _tab_button(index: int) -> Button:
	var def := GuidePages.PAGES[index]
	var id := str(def["id"])
	var b := Button.new()
	b.name = "Page_" + id
	b.custom_minimum_size = TAB
	b.focus_mode = Control.FOCUS_NONE
	var icon := GameIcon.make(str(def["icon"]), TAB_ICON)
	icon.position = (TAB - Vector2(TAB_ICON, TAB_ICON)) * 0.5 + Vector2(6, 6)
	b.add_child(icon)
	var number := UiKit.title(str(index + 1), 30, UiKit.TEXT, HORIZONTAL_ALIGNMENT_LEFT, 8)
	number.position = Vector2(12, 4)
	b.add_child(number)
	b.pressed.connect(func() -> void:
		if _page != id:
			Sounds.play("ui_tap")
			_show(id))
	return b


## Açık sayfanın sekmesi yeşil halkalı (dükkânın teknik düğmeleri gibi).
static func _style_tab(b: Button, selected: bool) -> void:
	var sb := UiKit.card_style(ShopPanel.BETTER if selected else UiKit.CREAM_EDGE, 24,
			UiKit.CREAM_CARD if selected else Color("#ead8b5"), 6 if selected else 3)
	for state: String in ["normal", "hover", "pressed", "hover_pressed"]:
		b.add_theme_stylebox_override(state, sb)


# --- Karolar -----------------------------------------------------------------------

## Karo: görsel, başlık, metin ve alttaki satır (ikonlar, yıldızlar, kilit ya da yer hapı). Boyu
## düzenin karo boyu; metin sabit boylu bir kutuda (uzun metin karoyu büyütmez; test_guide sığdığını
## ölçer, bot da bakar).
func _tile(db: ContentDB, save: SaveData, tile: Dictionary, layout: String) -> Control:
	var state := GuidePages.lock_state(db, save, tile)
	var panel := PanelContainer.new()
	panel.name = "Tile_" + str(tile["id"])
	panel.custom_minimum_size = GuidePages.tile_size(layout)
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", UiKit.card_style(UiKit.CREAM_EDGE, 28,
			UiKit.CREAM_CARD if state.is_empty() else LOCKED_FILL, 4))
	var vertical := GuidePages.vertical(layout)
	var box: BoxContainer = VBoxContainer.new() if vertical else HBoxContainer.new()
	box.add_theme_constant_override("separation", int(GuidePages.SEP if vertical else GuidePages.GAP))
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(box)
	var width := GuidePages.column_width(layout)
	var visual := _visual(tile, width if vertical else GuidePages.VISUAL)
	if not state.is_empty():
		_fade(visual)
	box.add_child(visual)
	var column := box
	if not vertical:
		visual.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		column = VBoxContainer.new()
		column.add_theme_constant_override("separation", int(GuidePages.SEP))
		column.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_child(column)
	var titled := not str(tile["title"]).is_empty()
	if titled:
		column.add_child(_tile_title(db, tile, width))
	var holder := Control.new()
	holder.name = "Text"
	holder.custom_minimum_size = GuidePages.text_box(layout, titled)
	holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(holder)
	var text := UiKit.ink(GuidePages.text_of(tile, func(key: String) -> String: return tr(key)), GuidePages.TEXT_SIZE,
			UiKit.INK)
	text.name = "Label"
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	text.add_theme_constant_override("line_spacing", GuidePages.LINE_SPACING)
	text.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	holder.add_child(text)
	column.add_child(_footer(tile, state))
	return panel


## Karonun görseli: eylem düğmesi, gerilim çubuğu, ikon, takım resmi ya da konuşanın yüzü. Dikey
## karoda genişliğince (ikon ortada), yatayda kare.
func _visual(tile: Dictionary, width: float) -> Control:
	var art := str(tile["art"])
	match str(tile["visual"]):
		"action":
			return _action_chip(art, width)
		"let_go":
			return LetGoChip.new(UiKit.upper(tr("UI_LET_GO")), width)
	var picture: Control
	match str(tile["visual"]):
		"gear":
			# Resmi yoksa kategorinin kodla çizilen ikonu (Ekstra: kepçe).
			var category := str(tile["category"])
			picture = _picture(ItemArt.gear(art), "net" if category == "extra" else category, "question")
		"portrait":
			picture = _picture(ItemArt.portrait(art), "", "question")
		_:
			picture = GameIcon.make(art, GuidePages.VISUAL)
	picture.name = "Art"
	picture.custom_minimum_size = Vector2(GuidePages.VISUAL, GuidePages.VISUAL)
	var frame := CenterContainer.new()
	frame.custom_minimum_size = Vector2(width, GuidePages.VISUAL)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.add_child(picture)
	return frame


## Resim (yoksa kodla çizilen ikon: önce resmin GameIcon adı, sonra yedek ad).
static func _picture(texture: Texture2D, kind: String, fallback: String) -> Control:
	if texture == null:
		return GameIcon.make(kind if not kind.is_empty() else fallback, GuidePages.VISUAL)
	var rect := TextureRect.new()
	rect.texture = texture
	rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return rect


## Kilitli karonun görseli soluk.
static func _fade(visual: Control) -> void:
	var art := visual.get_node_or_null("Art")
	if art is GameIcon:
		(art as GameIcon).modulate_art = LOCKED_ART
	elif art is CanvasItem:
		(art as CanvasItem).modulate = LOCKED_ART


## Oyundaki eylem düğmesinin küçüğü: aynı renk, ikon ve yazı (Hud.ACTIONS; doku Hud.warm_styles'ta
## hazır).
func _action_chip(kind: String, width: float) -> Control:
	var chip := PanelContainer.new()
	chip.name = "Chip"
	chip.custom_minimum_size = Vector2(width, GuidePages.VISUAL)
	chip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var style := UiKit.glossy(Hud.action_color(kind), false, 40)
	chip.add_theme_stylebox_override("panel", style)
	var row := HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.add_theme_constant_override("separation", 10)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	chip.add_child(row)
	var action: Array = Hud.ACTIONS[kind]
	row.add_child(GameIcon.make(str(action[1]), CHIP_ICON))
	var text := UiKit.upper(tr(str(action[0])))
	var room := width - style.get_margin(SIDE_LEFT) - style.get_margin(SIDE_RIGHT) - CHIP_ICON - 10.0
	row.add_child(UiKit.title(text, UiKit.fit_size(text, UiKit.display_font(), CHIP_TEXT, room, 24), UiKit.TEXT,
			HORIZONTAL_ALIGNMENT_LEFT, 10))
	return chip


## Karonun başlığı: Luckiest Guy, büyük harf; sığmazsa küçülür (en çok TITLE_MIN), yine sığmazsa üç
## nokta. Nadirlikte kademenin renginde.
func _tile_title(db: ContentDB, tile: Dictionary, width: float) -> Label:
	var text := UiKit.upper(tr(str(tile["title"])))
	var color := UiKit.INK
	if int(tile["rarity"]) >= 0:
		color = UiKit.rarity_color(db, int(tile["rarity"])).darkened(0.25)
	var label := UiKit.ink(text, UiKit.fit_size(text, UiKit.display_font(), GuidePages.TITLE_SIZE, width, GuidePages.TITLE_MIN),
			color)
	label.name = "Title"
	label.add_theme_font_override("font", UiKit.display_font())
	label.custom_minimum_size = Vector2(width, GuidePages.TITLE_H)
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	return label


## Alttaki satır: küçük ikonlar (Dede'nin yüzü ve önerisi, tekniğin ikonu, tuzak, sandal), yıldızlar
## ve sağda hap: kilitliyse kilit ve rütbe (ya da sandal), açıksa tekniğin yeri.
func _footer(tile: Dictionary, state: String) -> Control:
	var foot := HBoxContainer.new()
	foot.name = "Footer"
	foot.custom_minimum_size = Vector2(0, GuidePages.FOOT_H)
	foot.add_theme_constant_override("separation", int(GuidePages.FOOT_SEP))
	foot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if int(tile["step"]) > 0:
		foot.add_child(_step_badge(int(tile["step"])))
	for kind: String in (tile["icons"] as PackedStringArray):
		foot.add_child(_footer_icon(kind))
	var stars: Array = tile["stars"]
	if not stars.is_empty():
		var carry := UiKit.ink(tr("UI_STAT_CARRY"), GuidePages.PILL_SIZE, UiKit.INK_SOFT)
		foot.add_child(carry)
		var row := UiKit.stars(int(stars[0]), GuidePages.STAR, int(stars[1]))
		row.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		foot.add_child(row)
	foot.add_child(UiKit.spacer())
	match state:
		"rank":
			foot.add_child(_pill("Lock", tr("UI_SHOP_RANK") % int(tile["rank"]), "lock", LOCK_PILL))
		"boat":
			foot.add_child(_pill("Lock", tr("GEAR_boat"), "lock", LOCK_PILL))
		_:
			if not str(tile["where"]).is_empty():
				foot.add_child(_pill("Where", tr(str(tile["where"])), "", WHERE_PILL))
	return foot


## Sıralı sayfada adımın numarası: turuncu daire (alttaki satırın boyunda).
static func _step_badge(step: int) -> Control:
	var badge := PanelContainer.new()
	badge.name = "Step"
	var sb := UiKit.flat(UiKit.PRIMARY, int(GuidePages.FOOT_H * 0.5))
	sb.border_color = UiKit.PRIMARY.darkened(0.4)
	sb.set_border_width_all(3)
	badge.add_theme_stylebox_override("panel", sb)
	badge.custom_minimum_size = Vector2(GuidePages.FOOT_H, GuidePages.FOOT_H)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var number := UiKit.title(str(step), 30, UiKit.TEXT, HORIZONTAL_ALIGNMENT_CENTER, 8)
	number.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.add_child(number)
	return badge


static func _footer_icon(kind: String) -> Control:
	if kind.begins_with("portrait:"):
		var face := _picture(ItemArt.portrait(kind.substr(9)), "", "question")
		face.custom_minimum_size = Vector2(GuidePages.FOOT_ICON, GuidePages.FOOT_ICON)
		face.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		return face
	var icon := GameIcon.make(kind, GuidePages.FOOT_ICON)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return icon


## Hap: isteğe bağlı ikon ve büyük harfli kısa yazı.
static func _pill(node_name: String, text: String, icon: String, color: Color) -> PanelContainer:
	var pill := PanelContainer.new()
	pill.name = node_name
	var sb := UiKit.flat(color, 24)
	sb.content_margin_left = GuidePages.PILL_MARGIN.x
	sb.content_margin_right = GuidePages.PILL_MARGIN.y
	sb.content_margin_top = 4
	sb.content_margin_bottom = 4
	pill.add_theme_stylebox_override("panel", sb)
	pill.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", int(GuidePages.FOOT_SEP))
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill.add_child(row)
	if not icon.is_empty():
		var mark := GameIcon.make(icon, GuidePages.PILL_ICON)
		mark.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(mark)
	row.add_child(UiKit.title(text, GuidePages.PILL_SIZE, UiKit.TEXT, HORIZONTAL_ALIGNMENT_LEFT, 8))
	return pill


## "BIRAK!" karosunun görseli: kırmızıya çıkmış gerilim çubuğu (oyundaki gibi: kırmızı bölge, sınır
## çizgisi) ve altında kırmızı "BIRAK!".
class LetGoChip:
	extends Control

	## Çubukta sınırın yeri: oyundaki gibi gerilim sınırı / çubuğun gösterdiği en yüksek gerilim.
	var _limit: float = GameState.db.rules.limit / Hud.TensionBar.SHOWN_MAX

	func _init(text: String, width: float) -> void:
		name = "Chip"
		custom_minimum_size = Vector2(width, GuidePages.VISUAL)
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		var label := UiKit.title(text, 40, UiKit.BAD, HORIZONTAL_ALIGNMENT_CENTER, 10)
		label.position = Vector2(0, 52)
		label.size = Vector2(width, 56)
		add_child(label)

	func _draw() -> void:
		var bar := Rect2(Vector2(14, 10), Vector2(size.x - 28, 34))
		draw_style_box(UiKit.flat(Color(0.05, 0.06, 0.1, 0.72), 20), bar.grow(5))
		var red_from := bar.position.x + bar.size.x * _limit
		draw_rect(Rect2(Vector2(red_from, bar.position.y), Vector2(bar.end.x - red_from, bar.size.y)), Color(0.9, 0.2, 0.22, 0.35))
		draw_style_box(UiKit.flat(UiKit.BAD, 16), Rect2(bar.position, Vector2(bar.size.x * 0.9, bar.size.y)))
		draw_line(Vector2(red_from, bar.position.y - 7), Vector2(red_from, bar.end.y + 7), UiKit.TEXT, 4.0)
