class_name WardrobePanel
extends Dialog
## Dolap (Dalga 5): balıkçıya dokununca açılır. Sekmeler başlıkta:
## - Balıkçı: kız ya da oğlan, her biri canlı önizlemeyle (AnglerPreview, giyilen kıyafetle) ve SEÇ düğmesiyle;
##   seçilen hemen değişir, ilerleme aynen kalır.
## - Şapka, Yelek, Olta: solda balıkçının canlı önizlemesi, sağda kıyafetlerin karoları (OutfitIcon; giyilen yeşil
##   kenarlı, kilitlide kilit ve nasıl açılacağı, yeni açılanda "Yeni!"). Açık karoya dokununca hemen giyilir
##   (outfit_chosen: main giydirir), kilitliye dokununca altta şartı ve ilerlemesi yazar.
## Yeni kıyafet olan sekmede kırmızı rozet; sekme açılınca kıyafetleri görülmüş sayılır (Outfits.mark_seen).
## Panelin boyu sekmeden sekmeye değişmez (içerik aynı yükseklikte).
## Yeni oyunda açılış filminden önce seçim ekranı olarak açılır (open_first: başlık "Balıkçını seç", sekme ve
## kapatma yok, yalnızca balıkçı kartları; seçmeden geçilmez).

signal chosen(kind: String)
## Açık bir kıyafete dokunuldu (main giydirir: Outfits.equip, balıkçı, kayıt).
signal outfit_chosen(id: String)

const WIDTH := 1300.0
const WIDTH_TABS := 1440.0
const PREVIEW := Vector2(420, 380)
const BUTTON := Vector2(300, 122)
const TAB := Vector2(150, 122)
const TAB_ICON := 58.0
const TILE := Vector2(190, 190)
const TILE_ICON := 104.0
const COLUMNS := 4
## Kıyafet sekmelerinin önizlemesi ve içeriğin boyu (balıkçı kartlarıyla kıyafet sekmeleri aynı boyda: sekme
## değişince panel oynamaz; kartların doğal boyu ~609).
const OUTFIT_PREVIEW := Vector2(360, 540)
const CONTENT_H := 616.0
## Sekmeler: kimlik (balıkçı ya da kıyafet yuvası), adının anahtarı, ikonu (OutfitIcon).
const TABS: Array[Array] = [["angler", "UI_WARDROBE_TAB_ANGLER", "angler"], ["hat", "UI_WARDROBE_TAB_HAT", "hat"],
		["vest", "UI_WARDROBE_TAB_VEST", "vest"], ["rod", "UI_WARDROBE_TAB_ROD", "rod"]]
const NAMES := { "girl": "UI_CHAR_GIRL", "boy": "UI_CHAR_BOY" }
const BADGE := Color("#e5484d")

var _first: bool = false
var _tab: String = "angler"
var _note: Label
var _tabs: HBoxContainer
var _tab_buttons: Dictionary = {}
var _tab_labels: Dictionary = {}
var _tab_badges: Dictionary = {}
var _cards_row: HBoxContainer
var _cards: Dictionary = {}
var _buttons: Dictionary = {}
var _names: Dictionary = {}
var _previews: Dictionary = {}
var _outfit_row: HBoxContainer
var _outfit_preview: AnglerPreview
var _grid: GridContainer
var _status: Label
## Altta yazan: giyilen kıyafet ya da dokunulan kilitli kıyafet (kimlik).
var _focus: String = ""


func _build() -> void:
	set_header(tr("UI_WARDROBE"), "wardrobe", WIDTH)
	_tabs = HBoxContainer.new()
	_tabs.add_theme_constant_override("separation", 12)
	header_extra.add_child(_tabs)
	for t: Array in TABS:
		_tabs.add_child(_tab_button(str(t[0]), str(t[2])))
	_note = UiKit.ink("", UiKit.SIZE_SMALL, UiKit.INK)
	_note.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_note.custom_minimum_size = Vector2(WIDTH - 200.0, 0)
	body.add_child(_note)
	_build_cards()
	_build_outfits()


func _build_cards() -> void:
	_cards_row = HBoxContainer.new()
	_cards_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_cards_row.add_theme_constant_override("separation", 60)
	_cards_row.custom_minimum_size = Vector2(0, CONTENT_H)
	body.add_child(_cards_row)
	for kind: String in SaveData.CHARACTERS:
		var column := Dialog.card(_cards_row)
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


func _build_outfits() -> void:
	_outfit_row = HBoxContainer.new()
	_outfit_row.alignment = BoxContainer.ALIGNMENT_CENTER
	_outfit_row.add_theme_constant_override("separation", 30)
	_outfit_row.custom_minimum_size = Vector2(0, CONTENT_H)
	body.add_child(_outfit_row)
	var frame := Dialog.card(_outfit_row)
	(frame.get_parent() as PanelContainer).size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_outfit_preview = AnglerPreview.new()
	_outfit_preview.name = "OutfitPreview"
	_outfit_preview.custom_minimum_size = OUTFIT_PREVIEW
	frame.add_child(_outfit_preview)
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 18)
	right.alignment = BoxContainer.ALIGNMENT_CENTER
	_outfit_row.add_child(right)
	_grid = GridContainer.new()
	_grid.name = "Tiles"
	_grid.columns = COLUMNS
	_grid.add_theme_constant_override("h_separation", 14)
	_grid.add_theme_constant_override("v_separation", 14)
	right.add_child(_grid)
	_status = UiKit.ink("", UiKit.SIZE_SMALL, UiKit.INK)
	_status.name = "Status"
	_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_status.custom_minimum_size = Vector2(COLUMNS * TILE.x + (COLUMNS - 1) * 14.0, 96)
	right.add_child(_status)


func _tab_button(id: String, icon_kind: String) -> Button:
	var b := Button.new()
	b.name = "Tab_" + id
	b.custom_minimum_size = TAB
	b.focus_mode = Control.FOCUS_NONE
	var icon := OutfitIcon.make(icon_kind, {}, TAB_ICON)
	icon.position = Vector2((TAB.x - TAB_ICON) * 0.5, 10)
	b.add_child(icon)
	var label := UiKit.ink("", 21, UiKit.INK, HORIZONTAL_ALIGNMENT_CENTER)
	label.position = Vector2(4, 74)
	label.size = Vector2(TAB.x - 8, 40)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(label)
	_tab_labels[id] = label
	var badge := Label.new()
	badge.name = "Badge"
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	badge.add_theme_font_size_override("font_size", 22)
	badge.add_theme_color_override("font_color", Color.WHITE)
	var round := StyleBoxFlat.new()
	round.bg_color = BADGE
	round.set_corner_radius_all(20)
	badge.add_theme_stylebox_override("normal", round)
	badge.position = Vector2(TAB.x - 42, 4)
	badge.size = Vector2(38, 38)
	badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(badge)
	_tab_badges[id] = badge
	b.pressed.connect(func() -> void:
		if _tab != id:
			Sounds.play("ui_tap")
			select_tab(id))
	_tab_buttons[id] = b
	return b


## Yeni oyunda seçim ekranı: sekme ve kapatma düğmesi yok, seçince kapanır (main açılış filmini başlatır).
func open_first() -> void:
	_first = true
	_tab = "angler"
	open()


## Dolap: balıkçıya dokununca; yeni kıyafet olan ilk sekmede açılır (yoksa en son bakılan sekmede).
func open_wardrobe() -> void:
	_first = false
	var db := GameState.db
	for slot: String in SaveData.OUTFIT_SLOTS:
		if Outfits.new_count(db, GameState.save, slot) > 0:
			_tab = slot
			break
	_focus = ""
	open()


## Seçim ekranı olarak mı açık (yeni oyun)?
func is_first() -> bool:
	return _first


## Açık sekme (angler, hat, vest, rod).
func current_tab() -> String:
	return _tab


func select_tab(tab: String) -> void:
	_tab = tab
	_focus = ""
	refresh()


## Yazılar her açılışta o anki dilde (panel, dil uygulanmadan önce kurulur).
func refresh() -> void:
	var db := GameState.db
	var save := GameState.save
	set_header(tr("UI_CHAR_TITLE") if _first else tr("UI_WARDROBE"), "wardrobe", WIDTH if _first else WIDTH_TABS)
	close_button.visible = not _first
	_tabs.visible = not _first
	_note.visible = _first
	_note.text = tr("UI_CHAR_NOTE_FIRST")
	var angler_tab := _first or _tab == "angler"
	_cards_row.visible = angler_tab
	_outfit_row.visible = not angler_tab
	var look := Outfits.look(db, save)
	for t: Array in TABS:
		var id := str(t[0])
		var selected := id == _tab
		var b: Button = _tab_buttons[id]
		for state: String in ["normal", "hover", "pressed", "hover_pressed"]:
			b.add_theme_stylebox_override(state, ShopPanel._tab_style(selected))
		var label: Label = _tab_labels[id]
		label.text = UiKit.upper(tr(str(t[1])))
		label.add_theme_color_override("font_color", UiKit.INK if selected else UiKit.INK_SOFT)
	if angler_tab:
		_refresh_cards(look)
	else:
		_refresh_outfits(look)
	# Açık sekmenin kıyafetleri gösterildi: görülmüş sayılır (karodaki "Yeni!" bu açılışta kalır).
	if not angler_tab:
		for e in db.outfits.of_slot(_tab):
			Outfits.mark_seen(db, save, str(e["id"]))
	for slot: String in SaveData.OUTFIT_SLOTS:
		var n := Outfits.new_count(db, save, slot)
		var badge: Label = _tab_badges[slot]
		badge.visible = n > 0 and not _first
		badge.text = str(n)
	(_tab_badges["angler"] as Label).visible = false


func _refresh_cards(look: Dictionary) -> void:
	var current := GameState.save.character
	for kind: String in _buttons:
		(_names[kind] as Label).text = UiKit.upper(tr(str(NAMES[kind])))
		var button: Button = _buttons[kind]
		var picked := not _first and kind == current
		button.text = UiKit.upper(tr("UI_CHAR_PICKED") if picked else tr("UI_CHAR_PICK"))
		button.disabled = picked
		var panel: PanelContainer = _cards[kind]
		panel.add_theme_stylebox_override("panel", UiKit.card_style(UiKit.SUCCESS if picked else UiKit.CREAM_EDGE))
		(_previews[kind] as AnglerPreview).set_outfit(look)


func _refresh_outfits(look: Dictionary) -> void:
	var db := GameState.db
	var save := GameState.save
	_outfit_preview.show_look(save.character)
	_outfit_preview.set_outfit(look)
	Dialog.clear(_grid)
	for e in db.outfits.of_slot(_tab):
		_grid.add_child(_tile(e))
	if _focus.is_empty():
		_focus = Outfits.equipped(db, save, _tab)
	_status.text = status_text(db, save, _focus)


## Alttaki yazı: giyilen kıyafette "Giyilen: Hasır şapka", kilitlide nasıl açılacağı ve ilerlemesi
## ("Kırmızı şapka · kilitli: Rütbe 3 (2/3)"), açık ama giyilmeyende adı.
static func status_text(db: ContentDB, save: SaveData, id: String) -> String:
	var e := db.outfits.item(id)
	if e.is_empty():
		return ""
	var name := str(TranslationServer.translate("OUTFIT_" + id))
	if not Outfits.unlocked(db, save, id):
		var why := Outfits.reason(db, id)
		var values: Array = why[1]
		var text := str(TranslationServer.translate(str(why[0])))
		if not values.is_empty():
			text = text % values
		var at := Outfits.progress(db, save, id)
		if at.y > 1:
			text += " (%d/%d)" % [mini(at.x, at.y), at.y]
		return str(TranslationServer.translate("UI_OUTFIT_LOCKED")) % [name, text]
	if Outfits.equipped(db, save, str(e["slot"])) == id:
		return str(TranslationServer.translate("UI_OUTFIT_WORN")) % name
	return name


func _tile(e: Dictionary) -> Button:
	var db := GameState.db
	var save := GameState.save
	var id := str(e["id"])
	var open := Outfits.unlocked(db, save, id)
	var worn := Outfits.equipped(db, save, str(e["slot"])) == id
	var b := Button.new()
	b.name = "Item_" + id
	b.custom_minimum_size = TILE
	b.focus_mode = Control.FOCUS_NONE
	var fill := UiKit.CREAM_CARD if open else Color("#ead8b5")
	for state: String in ["normal", "hover", "pressed", "hover_pressed"]:
		b.add_theme_stylebox_override(state, UiKit.card_style(UiKit.SUCCESS if worn else UiKit.CREAM_EDGE, 24, fill,
				7 if worn else 3))
	var icon := OutfitIcon.make(str(e["slot"]), e, TILE_ICON)
	icon.position = Vector2((TILE.x - TILE_ICON) * 0.5, 12)
	if not open:
		icon.modulate = Color(1, 1, 1, 0.35)
	b.add_child(icon)
	var label := UiKit.ink(tr("OUTFIT_" + id), 21, UiKit.INK if open else UiKit.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.position = Vector2(6, 118)
	label.size = Vector2(TILE.x - 12, 66)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(label)
	if not open:
		var lock := GameIcon.make("lock", 46)
		lock.position = Vector2(TILE.x - 54, 8)
		lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(lock)
	elif Outfits.is_new(save, id):
		var badge := UiKit.ink(UiKit.upper(tr("UI_OUTFIT_NEW_BADGE")), 20, Color.WHITE, HORIZONTAL_ALIGNMENT_CENTER)
		var pill := StyleBoxFlat.new()
		pill.bg_color = BADGE
		pill.set_corner_radius_all(16)
		pill.content_margin_left = 8
		pill.content_margin_right = 8
		badge.add_theme_stylebox_override("normal", pill)
		badge.position = Vector2(8, 8)
		badge.name = "New"
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(badge)
	b.pressed.connect(func() -> void: _on_tile(id))
	return b


func _on_tile(id: String) -> void:
	var db := GameState.db
	var save := GameState.save
	_focus = id
	if not Outfits.unlocked(db, save, id):
		Sounds.play("error")
		Sounds.haptic(10)
		_status.text = status_text(db, save, id)
		return
	var e := db.outfits.item(id)
	if Outfits.equipped(db, save, str(e["slot"])) == id:
		Sounds.play("ui_tap")
		_status.text = status_text(db, save, id)
		return
	Sounds.play("equip")
	Sounds.haptic(15)
	outfit_chosen.emit(id)
	refresh()


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
