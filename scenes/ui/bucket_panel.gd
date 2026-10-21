class_name BucketPanel
extends Dialog
## Kova paneli (Dalga 4; docs/gdd.md §10.4, §10.5): sol üstteki kovaya dokununca her yerde açılır (olta
## boştayken). Kovadaki balıklar tür başına bir satırda: resmi, adı, kaç tane, nadirliği, göle bırakınca
## bir balığın verdiği göl sevgisi, değeri, BIRAK (o türün en küçüğü göle döner: release_requested). Bir sayfada
## en çok ROWS satır; fazlası sonraki sayfada (altta sayfa düğmesi; sıra aynı, panelin boyu sabit). Altta HEPSİNİ
## BIRAK (çocuk yanlışlıkla basmasın: ilk dokunuş "Emin misin?", SURE_GUARD sn sonra ve SURE_TIME sn içinde
## ikincisi bırakır: release_all_requested; hızlı çift dokunuş saymaz), kovanın toplam değeri ve SAT
## (sell_requested: main Nine'nin tezgâhına götürür). Başlıkta göl sevgisinin seviyesi ve çubuğu: bıraktıkça
## dolar. Bırakmak para vermez, göl sevgisi verir (gelir kuralı yok: bedava). Yazılar refresh'te.

signal release_requested(fish_id: String)
signal release_all_requested
signal sell_requested

## Panelin genişliği (iki sütun satır; telefonda küçülmeden sığar), satırın boyu (yüksekliği BIRAK'ın 122'si ve
## üstte, altta 4 pay), satır sayısı.
const WIDTH := 1640.0
const ROW := Vector2(770, 130)
const ROWS := 6
## Satırın parçaları: balığın resmi, adın en geniş hali (uzun ad küçülür, yine
## sığmazsa "…"), değer sütunu (satırlar hizalı), BIRAK.
const ROW_ICON := 84.0
const NAME_W := 300.0
const VALUE_W := 130.0
const RELEASE_BUTTON := Vector2(180, 122)
const FOOT_BUTTON := Vector2(340, 122)
const PAGE_BUTTON := Vector2(240, 122)
## HEPSİNİ BIRAK'ın onay süresi (sn) ve ilk dokunuştan sonra ikincinin sayılmadığı süre (çift dokunuş).
const SURE_TIME := 3.0
const SURE_GUARD := 0.6

var _love_bar: LoveBar
var _love_label: Label
var _count_label: Label
var _rows: GridContainer
var _foot: HBoxContainer
var _empty: Label
var _release_all: Button
var _sure: float = -1.0
var _page: int = 0


func _build() -> void:
	set_header(tr("UI_BUCKET_PANEL"), "bucket", WIDTH)
	# Başlıkta göl sevgisi (kalp, seviye, çubuk) ve kovanın doluluğu.
	var love := PanelContainer.new()
	love.add_theme_stylebox_override("panel", UiKit.pill_style(Color(0.18, 0.1, 0.04, 0.85)))
	var love_row := HBoxContainer.new()
	love_row.add_theme_constant_override("separation", 10)
	love.add_child(love_row)
	love_row.add_child(GameIcon.make("love", 56))
	var love_text := VBoxContainer.new()
	love_text.add_theme_constant_override("separation", 2)
	love_text.alignment = BoxContainer.ALIGNMENT_CENTER
	love_row.add_child(love_text)
	_love_label = UiKit.label("", 26, UiKit.TEXT)
	love_text.add_child(_love_label)
	_love_bar = LoveBar.new()
	love_text.add_child(_love_bar)
	header_extra.add_child(love)
	var count := PanelContainer.new()
	count.add_theme_stylebox_override("panel", UiKit.pill_style(Color(0.18, 0.1, 0.04, 0.85)))
	_count_label = UiKit.title("", 44, UiKit.ACCENT, HORIZONTAL_ALIGNMENT_CENTER, 10)
	count.add_child(_count_label)
	header_extra.add_child(count)
	_rows = GridContainer.new()
	_rows.columns = 2
	_rows.add_theme_constant_override("h_separation", 18)
	_rows.add_theme_constant_override("v_separation", 12)
	body.add_child(_rows)
	_empty = UiKit.ink("", UiKit.SIZE_BODY, UiKit.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER)
	_empty.custom_minimum_size = Vector2(0, 200)
	body.add_child(_empty)
	_foot = HBoxContainer.new()
	_foot.add_theme_constant_override("separation", 18)
	_foot.alignment = BoxContainer.ALIGNMENT_END
	body.add_child(_foot)


## Her açılışta ilk sayfa (bırakınca yenilenen panel sayfasında kalır).
func open() -> void:
	_page = 0
	super.open()


func refresh() -> void:
	var db := GameState.db
	var save := GameState.save
	set_header(tr("UI_BUCKET_PANEL"), "bucket", WIDTH)
	var level := LakeLove.level(db.rules, save.love)
	_love_label.text = tr("UI_LOVE_LEVEL") % level
	_love_bar.progress = LakeLove.progress(db.rules, save.love)
	_love_bar.queue_redraw()
	_count_label.text = "%d/%d" % [save.bucket.size(), Bucket.capacity(db, save)]
	Dialog.clear(_rows)
	Dialog.clear(_foot)
	_sure = -1.0
	var rows := rows_of(db, save)
	var pages := maxi(1, ceili(rows.size() / float(ROWS)))
	_page = clampi(_page, 0, pages - 1)
	_empty.visible = rows.is_empty()
	_empty.text = tr("UI_BUCKET_EMPTY")
	_rows.visible = not rows.is_empty()
	var first := _page * ROWS
	var last := mini(rows.size(), first + ROWS)
	for i in range(first, last):
		_rows.add_child(_row(db, rows[i]))
	# Sayfalı kovada son sayfanın boş yerleri tutulur: panelin boyu sayfadan sayfaya değişmez.
	if pages > 1:
		for i in first + ROWS - last:
			var gap := Control.new()
			gap.custom_minimum_size = ROW
			_rows.add_child(gap)
	if rows.is_empty():
		return
	_release_all = UiKit.button(tr("UI_BUCKET_RELEASE_ALL"), UiKit.SECONDARY, UiKit.SIZE_SMALL + 4, FOOT_BUTTON)
	_release_all.name = "ReleaseAll"
	_release_all.pressed.connect(_on_release_all)
	_foot.add_child(_release_all)
	if pages > 1:
		var page := UiKit.button(tr("UI_BUCKET_PAGE") % [_page + 1, pages], UiKit.SECONDARY, UiKit.SIZE_SMALL + 4,
				PAGE_BUTTON)
		page.name = "Page"
		page.pressed.connect(func() -> void:
			Sounds.play("ui_tap")
			_page = (_page + 1) % pages
			refresh())
		_foot.add_child(page)
	_foot.add_child(UiKit.spacer())
	_foot.add_child(UiKit.ink(tr("UI_SHOP_TOTAL"), UiKit.SIZE_BODY))
	_foot.add_child(GameIcon.make("coin", 64))
	_foot.add_child(UiKit.title(UiKit.format_int(Economy.bucket_value(db, save)), UiKit.SIZE_TITLE, UiKit.ACCENT))
	var sell := UiKit.button(tr("UI_ACT_SELL"), UiKit.SUCCESS, UiKit.SIZE_SMALL + 4, FOOT_BUTTON)
	sell.name = "Sell"
	sell.icon = ItemArt.ui("sell")
	sell.add_theme_constant_override("icon_max_width", 64)
	sell.pressed.connect(func() -> void:
		Sounds.play("ui_tap")
		close_panel()
		sell_requested.emit())
	_foot.add_child(sell)


func _process(delta: float) -> void:
	if _sure < 0.0:
		return
	_sure -= delta
	if _sure < 0.0 and is_instance_valid(_release_all):
		_release_all.text = UiKit.upper(tr("UI_BUCKET_RELEASE_ALL"))


## HEPSİNİ BIRAK: ilk dokunuş sorar ("Emin misin?"), SURE_TIME içinde ikincisi bırakır; ilk dokunuştan sonraki
## SURE_GUARD içinde gelen dokunuş sayılmaz (hızlı çift dokunuş sormadan bırakmasın).
func _on_release_all() -> void:
	if _sure < 0.0:
		_sure = SURE_TIME
		_release_all.text = UiKit.upper(tr("UI_BUCKET_SURE"))
		Sounds.haptic(10)
		return
	if _sure > SURE_TIME - SURE_GUARD:
		return
	_sure = -1.0
	release_all_requested.emit()


## Kovadaki balıklar tür başına: { fish, count, value, love, rarity }; nadirden sıradana, sonra değere göre.
static func rows_of(db: ContentDB, save: SaveData) -> Array[Dictionary]:
	var by_fish := {}
	for entry in save.bucket:
		var id := str(entry["fish"])
		if not by_fish.has(id):
			var rarity := int(db.fish_by_id(id).get("rarity", 0))
			by_fish[id] = { "fish": id, "count": 0, "value": 0, "rarity": rarity,
					"love": int(db.rarity_def(rarity).get("love", 0)) }
		var row: Dictionary = by_fish[id]
		row["count"] = int(row["count"]) + 1
		row["value"] = int(row["value"]) + Economy.fish_value(db, id, int(entry["size_cm"]))
	var rows: Array[Dictionary] = []
	for id: String in by_fish:
		rows.append(by_fish[id])
	rows.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a["rarity"]) > int(b["rarity"]) if int(a["rarity"]) != int(b["rarity"]) \
				else int(a["value"]) > int(b["value"]))
	return rows


## Bir türün satırı: resmi, adı, altında kaç tane, nadirliği ve bir balığın göl sevgisi, değeri, BIRAK.
func _row(db: ContentDB, row: Dictionary) -> Control:
	var fish_id := str(row["fish"])
	var panel := PanelContainer.new()
	panel.name = "Row_" + fish_id
	panel.custom_minimum_size = ROW
	var style := UiKit.card_style(UiKit.rarity_color(db, int(row["rarity"])), 22)
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	panel.add_theme_stylebox_override("panel", style)
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 12)
	panel.add_child(line)
	var icon := GameIcon.make("fish:" + fish_id, ROW_ICON)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	line.add_child(icon)
	var name_box := VBoxContainer.new()
	name_box.add_theme_constant_override("separation", 0)
	name_box.alignment = BoxContainer.ALIGNMENT_CENTER
	name_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(name_box)
	var title := tr("FISH_" + fish_id)
	var name_label := UiKit.ink(title, UiKit.SIZE_BODY)
	name_label.add_theme_font_size_override("font_size", UiKit.fit_size(title, UiKit.body_font(), UiKit.SIZE_BODY, NAME_W, 26))
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_box.add_child(name_label)
	# Adın altında: kaç tane ("×3"; Luckiest Guy'ın × işareti küçükte okunmuyor), nadirlik, sevgi.
	var tags := HBoxContainer.new()
	tags.add_theme_constant_override("separation", 10)
	name_box.add_child(tags)
	var count := UiKit.ink("×%d" % int(row["count"]), UiKit.SIZE_SMALL)
	count.name = "Count"
	tags.add_child(count)
	tags.add_child(UiKit.rarity_badge(db, int(row["rarity"]), 22))
	var love := UiKit.icon_text("love", "+%d" % int(row["love"]), 34, 26)
	love.name = "Love"
	tags.add_child(love)
	var value := UiKit.icon_text("coin", UiKit.format_int(int(row["value"])), 44, UiKit.SIZE_SMALL + 2)
	value.custom_minimum_size.x = VALUE_W
	line.add_child(value)
	var release := UiKit.button(tr("UI_BUCKET_RELEASE"), UiKit.SECONDARY, UiKit.SIZE_SMALL, RELEASE_BUTTON)
	release.name = "Release_" + fish_id
	release.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	release.pressed.connect(func() -> void: release_requested.emit(fish_id))
	line.add_child(release)
	return panel


## Göl sevgisinin seviye içindeki ilerlemesi: ince çubuk (hapın içinde, yazının altında).
class LoveBar extends Control:
	var progress: float = 0.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		custom_minimum_size = Vector2(170, 14)

	func _draw() -> void:
		var rect := Rect2(Vector2.ZERO, size)
		draw_rect(rect, Color(0.0, 0.0, 0.0, 0.35))
		draw_rect(Rect2(rect.position, Vector2(rect.size.x * clampf(progress, 0.0, 1.0), rect.size.y)), Color("#ff7aa8"))
