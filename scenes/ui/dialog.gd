class_name Dialog
extends Control
## Ortak modal pencere: arkası karartılır, ortada krem renkli kutu; üstte ikon + başlık,
## sağda isteğe bağlı göstergeler ve kapat butonu. "modal" grubundadır: açıkken oyun girdisi
## (joystick dışındaki dokunmalar) oyuna geçmez. Alt sınıflar _build() içinde body'yi doldurur.
## Kutu ekrana (güvenli alan payıyla) sığmazsa küçültülür: dar ekranda (iPad) taşmasın.

signal closed

## İçerik buraya eklenir.
var body: VBoxContainer
## Başlık satırının sağ tarafı (ör. akçe göstergesi).
var header_extra: HBoxContainer
var close_button: TextureButton

var _panel: PanelContainer
var _title: Label
var _icon: GameIcon
var _width: float = 1600.0
## Açılış animasyonu sürüyor (ölçek animasyonda).
var _opening: bool = false


func _ready() -> void:
	theme = UiKit.theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_to_group("modal")
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.05, 0.62)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(dim)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(center)
	_panel = PanelContainer.new()
	_panel.add_theme_stylebox_override("panel", UiKit.framed("panel", UiKit.dialog_style(), 64.0))
	_panel.custom_minimum_size = Vector2(_width, 0)
	# Açılış animasyonu ortadan büyüsün: boyut her değişince merkez ve sığma ölçeği güncellenir.
	_panel.resized.connect(func() -> void:
		_panel.pivot_offset = _panel.size * 0.5
		if visible and not _opening:
			_panel.scale = Vector2.ONE * fit_scale())
	get_viewport().size_changed.connect(func() -> void:
		if visible and not _opening:
			_panel.scale = Vector2.ONE * fit_scale())
	center.add_child(_panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 22)
	_panel.add_child(column)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 18)
	column.add_child(header)
	_icon = GameIcon.make("shop", 92)
	header.add_child(_icon)
	_title = UiKit.title("", 66, UiKit.PRIMARY)
	header.add_child(_title)
	header.add_child(UiKit.spacer())
	header_extra = HBoxContainer.new()
	header_extra.add_theme_constant_override("separation", 16)
	header.add_child(header_extra)
	close_button = TextureButton.new()
	close_button.texture_normal = ItemArt.ui("close")
	close_button.ignore_texture_size = true
	close_button.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	close_button.custom_minimum_size = Vector2(122, 122)
	close_button.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	close_button.pressed.connect(close_panel)
	if close_button.texture_normal == null:
		var fallback := UiKit.button("X", UiKit.DANGER, UiKit.SIZE_BODY, Vector2(122, 122))
		fallback.pressed.connect(close_panel)
		header.add_child(fallback)
	else:
		header.add_child(close_button)
	body = VBoxContainer.new()
	body.add_theme_constant_override("separation", 20)
	column.add_child(body)
	_build()
	hide()


## Alt sınıf: başlık, ikon ve genişliği ayarlar, gövdeyi kurar.
func _build() -> void:
	pass


func set_header(text: String, icon_kind: String, width: float = 1600.0) -> void:
	_title.text = UiKit.upper(text)
	_icon.kind = icon_kind
	_width = width
	_panel.custom_minimum_size = Vector2(width, 0)


func open() -> void:
	show()
	refresh()
	Sounds.play("panel_open")
	# Kısa büyüme animasyonu. İlk açılışta boyut yerleşimden sonra belli olur: merkez boyut
	# değişince de güncellenir (resized).
	_panel.pivot_offset = _panel.size * 0.5
	var fit := fit_scale()
	_panel.scale = Vector2.ONE * fit * 0.92
	_panel.modulate.a = 0.0
	_opening = true
	var tween := _panel.create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_panel, "scale", Vector2.ONE * fit, 0.22)
	tween.tween_property(_panel, "modulate:a", 1.0, 0.12)
	tween.chain().tween_callback(func() -> void:
		_opening = false
		_panel.scale = Vector2.ONE * fit_scale())


func close_panel() -> void:
	if not visible:
		return
	hide()
	Sounds.play("panel_close")
	closed.emit()


## Alt sınıf: içeriği güncel kayda göre yeniden kurar.
func refresh() -> void:
	pass


## Kutunun ekrana sığma ölçeği (en çok 1): güvenli alan ve kenar payı çıkınca kalan yer.
func fit_scale() -> float:
	var view := get_viewport_rect().size
	var inset := UiKit.safe_insets(self)
	var room := Vector2(view.x - inset.x - inset.z, view.y - inset.y - inset.w) - Vector2(40.0, 24.0)
	var need := _panel.get_combined_minimum_size()
	if need.x <= 0.0 or need.y <= 0.0:
		return 1.0
	return clampf(minf(room.x / need.x, room.y / need.y), 0.5, 1.0)


## Bir kapsayıcının çocuklarını hemen siler (yeniden kurmadan önce).
static func clear(container: Node) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()


## Krem kart: içine yazılacak sütunu döner.
static func card(parent: Control, border: Color = UiKit.CREAM_EDGE, min_size: Vector2 = Vector2.ZERO) -> VBoxContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", UiKit.card_style(border))
	panel.custom_minimum_size = min_size
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(panel)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 12)
	panel.add_child(column)
	return column


## Akçe göstergesi (koyu hap üstünde altın sayı).
static func coin_pill(coins: int) -> PanelContainer:
	var pill := PanelContainer.new()
	pill.add_theme_stylebox_override("panel", UiKit.pill_style(Color(0.18, 0.1, 0.04, 0.85)))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	pill.add_child(row)
	row.add_child(GameIcon.make("coin", 58))
	row.add_child(UiKit.title(UiKit.format_int(coins), 52, UiKit.ACCENT, HORIZONTAL_ALIGNMENT_LEFT, 10))
	return pill
