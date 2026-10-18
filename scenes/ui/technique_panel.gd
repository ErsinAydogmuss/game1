class_name TechniquePanel
extends Dialog
## Takım çantası (docs/gdd.md §10.3, §10.7): sol alttaki teknik düğmesiyle açılır (olta boştayken).
## Her teknik bir karo: ikonu, adı, nasıl oynandığı ve o tekniğin kuşanılmış kamışı ile küçük
## takımı (makara ve misina her teknikte ortak). Karonun tek düğmesi:
## - ELİNDE: elindeki teknik;
## - SEÇ: hazır (kamışı alınmış): teknik ele geçer (technique_selected);
## - NİNE'DE: rütbesi yetiyor ama kamışı yok: dükkân o tekniğin Kamış sekmesinde açılır
##   (shop_requested);
## - rütbe kilidi: açıldığı rütbe yazar;
## - yer: kamışı var ama bu bölgede avlanılmaz (sinek yalnızca dere ağzında): nerede olduğu yazar.
## Kamışı oyunda olmayan teknik (henüz yazılmamış) gösterilmez.

signal technique_selected(id: String)
signal shop_requested(id: String)

## Karonun boyu ve panelin genişliği (4 karo yan yana; telefonda küçülmeden sığar).
const TILE := Vector2(360, 470)
const WIDTH := 1640.0
const BUTTON := Vector2(300, 122)

## Balıkçının gölü ve avlandığı bölge (main verir): bölgede avlanılmayan teknik seçilmez.
var spot_id: String = ""
var zone_id: String = ""

var _row: HBoxContainer


func _build() -> void:
	set_header(tr("UI_BAG_TITLE"), "tackle_bag", WIDTH)
	_row = HBoxContainer.new()
	_row.add_theme_constant_override("separation", 16)
	_row.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_child(_row)


func refresh() -> void:
	set_header(tr("UI_BAG_TITLE"), "tackle_bag", WIDTH)
	Dialog.clear(_row)
	for id: String in ContentDB.TECHNIQUES:
		if GameState.db.has_technique(id):
			_row.add_child(_tile(id))


## Teknik karosunun durumu: active, ready, shop, rank ya da zone (kamışı var ama bu bölgede
## avlanılmaz; spot verilmezse bakılmaz).
static func state_of(db: ContentDB, save: SaveData, id: String, spot: String = "", zone: String = "") -> String:
	if Economy.technique_ready(db, save, id):
		if save.technique == id:
			return "active"
		if not spot.is_empty() and not Economy.technique_allowed(db, spot, zone, id):
			return "zone"
		return "ready"
	if Rank.rank(db, save) < db.technique_rank(id):
		return "rank"
	return "shop"


func _tile(id: String) -> Control:
	var db := GameState.db
	var save := GameState.save
	var state := state_of(db, save, id, spot_id, zone_id)
	var panel := PanelContainer.new()
	panel.name = "Tile_" + id
	panel.custom_minimum_size = TILE
	var edge := ShopPanel.BETTER if state == "active" else UiKit.CREAM_EDGE
	var style := UiKit.framed("card", UiKit.card_style(edge, 28, UiKit.CREAM_CARD, 6 if state == "active" else 4), UiKit.CARD_CORNER)
	panel.add_theme_stylebox_override("panel", style)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(column)
	var icon := GameIcon.make("tech_" + id, 130)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	if state == "rank":
		icon.modulate_art = Color(1, 1, 1, 0.55)
	column.add_child(icon)
	var title := UiKit.ink(UiKit.upper(tr("UI_TECH_" + id)), UiKit.SIZE_BODY, UiKit.INK, HORIZONTAL_ALIGNMENT_CENTER)
	title.add_theme_font_override("font", UiKit.display_font())
	column.add_child(title)
	var how := UiKit.ink(tr("UI_TECH_%s_HOW" % id), 26, UiKit.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER)
	how.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	how.custom_minimum_size = Vector2(TILE.x - 50.0, 0)
	how.max_lines_visible = 3
	column.add_child(how)
	column.add_child(_gear_row(id))
	column.add_child(UiKit.spacer(true))
	var button := _button(id, state)
	button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(button)
	if style is StyleBoxTexture and state == "active":
		var ring := PanelContainer.new()
		ring.add_theme_stylebox_override("panel", UiKit.ring_style(ShopPanel.BETTER))
		ring.add_child(panel)
		return ring
	return panel


## Tekniğin kendi takımı (kamış ve küçük takım; ortak makara ve misina değil): kuşanılanların
## resmi. Kamışı yoksa yalnızca küçük takımın başlangıcı.
func _gear_row(id: String) -> Control:
	var db := GameState.db
	var save := GameState.save
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.custom_minimum_size = Vector2(0, 76)
	for slot: String in db.slots_for(id):
		if db.is_shared(slot):
			continue
		var gear_id := Economy.equipped(db, save, slot, id)
		if gear_id.is_empty():
			continue
		var item := db.gear_item(gear_id)
		var art := ItemArt.gear(str(item.get("icon", gear_id)))
		if art != null:
			var rect := TextureRect.new()
			rect.texture = art
			rect.custom_minimum_size = Vector2(72, 72)
			rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			row.add_child(rect)
		else:
			row.add_child(GameIcon.make(str(item.get("kind", slot)), 72))
	return row


func _button(id: String, state: String) -> Button:
	var b: Button
	match state:
		"active":
			b = UiKit.button(tr("UI_BAG_ACTIVE"), UiKit.SUCCESS, UiKit.SIZE_SMALL + 4, BUTTON)
			b.pressed.connect(func() -> void: Sounds.play("ui_tap"))
		"ready":
			b = UiKit.button(tr("UI_BAG_SELECT"), UiKit.SECONDARY, UiKit.SIZE_SMALL + 4, BUTTON)
			b.pressed.connect(func() -> void:
				Sounds.play("equip")
				Sounds.haptic(10)
				technique_selected.emit(id)
				close_panel())
		"shop":
			b = UiKit.button(tr("UI_BAG_SHOP"), UiKit.PRIMARY, UiKit.SIZE_SMALL + 4, BUTTON)
			b.icon = ItemArt.ui("shop")
			b.pressed.connect(func() -> void:
				Sounds.play("ui_tap")
				close_panel()
				shop_requested.emit(id))
		"zone":
			b = UiKit.button(tr("UI_TECH_%s_WHERE" % id), UiKit.NEUTRAL, UiKit.SIZE_SMALL, BUTTON)
			b.pressed.connect(func() -> void: Sounds.play("error"))
		_:
			b = UiKit.button(tr("UI_SHOP_RANK") % GameState.db.technique_rank(id), UiKit.NEUTRAL, UiKit.SIZE_SMALL + 4, BUTTON)
			b.icon = ItemArt.ui("lock")
			b.pressed.connect(func() -> void: Sounds.play("error"))
	b.name = "Button_" + id
	b.expand_icon = true
	b.add_theme_constant_override("icon_max_width", 52)
	return b
