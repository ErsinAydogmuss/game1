class_name LoadoutPanel
extends Dialog
## Takım paneli (testçi: "takım çantasında misina, kamış, yem değişmiyor; Nine'ye gitmek gerekiyor; en azından
## envanterimizdekileri çantada görelim"): Takım Çantası'nda bir tekniğin karosuna (ya da elindeki tekniğin
## TAKIM düğmesine) dokununca açılır. Tekniğin her yuvası (kamış, makara, misina; iğne, şamandıra, yem, yapay
## yem, kurşun, sinek) bir satır: adı ve sahip olunan takımlar (resmi, adı; yemde kaç tane kaldığı). Takılı olan
## yeşil kenarlı; ötekine dokununca takılır (Economy.equip; gear_changed). Satın alma Nine'de: başlıkta NİNE'DE
## (dükkân o tekniğin Kamış sekmesinde, uzaktan da açılır: shop_requested; telefonda panel küçülmeden sığsın diye
## başlıkta).
## Makara ve misina her teknikte ortak (değişince bütün teknikleri etkiler; satırın adında yazar).

signal gear_changed
signal shop_requested(technique: String)

## Panelin genişliği (Takım Çantası'yla aynı), iki sütun.
const WIDTH := 1640.0
const COLUMNS := 2
## Bir yuvanın genişliği (sütun) ve bir takımın karosu (en az 122: dokunma).
const SLOT_W := 760.0
## Bir yuvada en çok 6 takım (gear.json: makara, misina, yem, yapay yem 6'şar): hepsi sığsın diye karo daralır
## (kaydırma yok: gizli kalan takım olmasın, sürüklerken yanlışlıkla takılmasın), en az MIN_ITEM_W (dokunma).
const ITEM := Vector2(176, 164)
const MIN_ITEM_W := 122.0
const ITEM_ICON := 96.0
const ITEM_GAP := 12
const TIGHT_GAP := 5
const SHOP_BUTTON := Vector2(340, 122)

## Bakılan teknik (open_loadout verir).
var technique: String = "float"

var _grid: GridContainer
var _shop: Button


func _build() -> void:
	set_header(tr("UI_LOADOUT_TITLE") % tr("UI_TECH_float"), "tech_float", WIDTH)
	_grid = GridContainer.new()
	_grid.name = "Slots"
	_grid.columns = COLUMNS
	_grid.add_theme_constant_override("h_separation", 28)
	_grid.add_theme_constant_override("v_separation", 14)
	body.add_child(_grid)
	_shop = UiKit.button("", UiKit.PRIMARY, UiKit.SIZE_SMALL + 4, SHOP_BUTTON)
	_shop.name = "Shop"
	_shop.icon = ItemArt.ui("shop")
	_shop.expand_icon = true
	_shop.add_theme_constant_override("icon_max_width", 52)
	_shop.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_shop.pressed.connect(func() -> void:
		Sounds.play("ui_tap")
		close_panel()
		shop_requested.emit(technique))
	header_extra.add_child(_shop)


func open_loadout(id: String) -> void:
	technique = id
	open()


func refresh() -> void:
	var db := GameState.db
	var save := GameState.save
	set_header(tr("UI_LOADOUT_TITLE") % tr("UI_TECH_" + technique), "tech_" + technique, WIDTH)
	Dialog.clear(_grid)
	for slot: String in slots_of(db, technique):
		_grid.add_child(_slot(db, save, slot))
	_shop.text = UiKit.upper(tr("UI_BAG_SHOP"))


## Tekniğin yuvaları gösterilme sırasıyla: önce kamış, sonra tekniğin kendi küçük takımı ve yemi, en sonda
## ortak makara ve misina.
static func slots_of(db: ContentDB, id: String) -> Array[String]:
	var own: Array[String] = []
	var shared: Array[String] = []
	for slot: String in db.slots_for(id):
		if db.is_shared(slot):
			shared.append(slot)
		else:
			own.append(slot)
	return own + shared


## Bir yuvada sahip olunan takımlar (gear.json sırasıyla): kamışta yalnızca o tekniğinkiler; yemde elde kalanlar
## (bedava yem hep); ötekilerde sahip olunanlar (bedava başlangıç takımı hep).
static func owned_for(db: ContentDB, save: SaveData, id: String, slot: String) -> Array[String]:
	var out: Array[String] = []
	for g in db.gear_in(slot):
		var gear_id := str(g["id"])
		if slot == "rod" and str(g["technique"]) != id:
			continue
		if slot == "bait":
			if int(g["pack"]) > 0 and int(save.baits.get(gear_id, 0)) <= 0:
				continue
		elif not Economy.owns(db, save, gear_id):
			continue
		out.append(gear_id)
	return out


## Bir yuva: adı (ortaksa "her teknikte") ve sahip olunan takımların karoları (çoksa daralır: hepsi görünür).
func _slot(db: ContentDB, save: SaveData, slot: String) -> Control:
	var column := VBoxContainer.new()
	column.name = "Slot_" + slot
	column.custom_minimum_size = Vector2(SLOT_W, 0)
	column.add_theme_constant_override("separation", 6)
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 12)
	column.add_child(head)
	var title := UiKit.ink(UiKit.upper(tr("UI_SLOT_" + slot)), UiKit.SIZE_SMALL, UiKit.INK)
	title.add_theme_font_override("font", UiKit.display_font())
	head.add_child(title)
	if db.is_shared(slot):
		var shared := UiKit.ink(tr("UI_LOADOUT_SHARED"), 24, UiKit.INK_SOFT)
		shared.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		head.add_child(shared)
	var row := HBoxContainer.new()
	row.custom_minimum_size = Vector2(0.0, ITEM.y)
	column.add_child(row)
	var on := Economy.equipped(db, save, slot, technique)
	var owned := owned_for(db, save, technique, slot)
	var gap := gap_for(owned.size())
	row.add_theme_constant_override("separation", gap)
	var width := item_width(owned.size())
	for gear_id in owned:
		row.add_child(_item(db, save, gear_id, gear_id == on, width))
	return column


## Yuvadaki karo sayısına göre aralık ve karonun genişliği: dört karo tam boyda, fazlası SLOT_W'ye sığacak kadar dar.
static func gap_for(count: int) -> int:
	return ITEM_GAP if count <= 4 else TIGHT_GAP


static func item_width(count: int) -> float:
	if count <= 4:
		return ITEM.x
	var gap := gap_for(count)
	return clampf(floorf((SLOT_W - gap * (count - 1)) / count), MIN_ITEM_W, ITEM.x)


## Bir takımın karosu: resmi ve adı (yemde kalan sayısı); takılıysa yeşil kenarlı, değilse dokununca takılır.
func _item(db: ContentDB, save: SaveData, gear_id: String, equipped: bool, width: float) -> Control:
	var item := db.gear_item(gear_id)
	var b := Button.new()
	b.name = "Item_" + gear_id
	b.custom_minimum_size = Vector2(width, ITEM.y)
	b.focus_mode = Control.FOCUS_NONE
	var edge := ShopPanel.BETTER if equipped else UiKit.CREAM_EDGE
	var style := UiKit.card_style(edge, 22, UiKit.CREAM_CARD, 6 if equipped else 3)
	for state: String in ["normal", "hover", "pressed", "focus", "disabled"]:
		b.add_theme_stylebox_override(state, style)
	var box := VBoxContainer.new()
	box.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 0)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(box)
	var art := ItemArt.gear(str(item.get("icon", gear_id)))
	var icon: Control
	if art != null:
		var rect := TextureRect.new()
		rect.texture = art
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		icon = rect
	else:
		icon = GameIcon.make(str(item.get("kind", item["category"])), ITEM_ICON)
	icon.custom_minimum_size = Vector2(ITEM_ICON, ITEM_ICON)
	icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(icon)
	var text := tr("GEAR_" + gear_id)
	if str(item["category"]) == "bait" and int(item["pack"]) > 0:
		text = "%s ×%d" % [text, int(save.baits.get(gear_id, 0))]
	var name_label := UiKit.ink(text, 21 if width >= ITEM.x else 19, UiKit.INK, HORIZONTAL_ALIGNMENT_CENTER)
	name_label.custom_minimum_size = Vector2(width - 16.0, 0)
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(name_label)
	b.pressed.connect(func() -> void: _equip(gear_id, equipped))
	return b


func _equip(gear_id: String, equipped: bool) -> void:
	if equipped:
		Sounds.play("ui_tap")
		return
	if not Economy.equip(GameState.db, GameState.save, gear_id, technique):
		Sounds.play("error")
		return
	GameState.save_game()
	Sounds.play("equip")
	Sounds.haptic(10)
	gear_changed.emit()
	refresh()
