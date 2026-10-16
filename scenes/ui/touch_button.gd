class_name TouchButton
extends PanelContainer
## Çoklu dokunmaya uygun buton: başka bir parmak ekrandayken de basılabilir (normal Button
## yalnızca ilk parmağı fare gibi alır). Basılı tutma desteklenir (SAR). Masaüstünde fareyle de
## çalışır. Basılı parmak kayarsa dragged yayılır. (Kazı'dan.)

signal pressed
signal released
## Basılı parmak / fare kaydı (piksel).
signal dragged(relative: Vector2)

## Fareyle basıldığında _touch bu değeri alır (dokunma indeksleri 0'dan başlar).
const MOUSE_TOUCH := -2

var held: bool = false
var color: Color = UiKit.PRIMARY
## Basınca arayüz tıkı çalsın mı (SAR gibi basılı tutulanlarda kapalı).
var click: bool = true

var _touch: int = -1
var _icon: GameIcon
var _label: Label
var _normal: StyleBox
var _down: StyleBox
var _shade: CooldownShade


static func make(text: String, icon_kind: String, button_color: Color, min_size: Vector2,
		font_size: int = UiKit.SIZE_TITLE, icon_size: float = 72.0) -> TouchButton:
	var b := TouchButton.new()
	b.color = button_color
	b.custom_minimum_size = min_size
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := VBoxContainer.new()
	box.alignment = BoxContainer.ALIGNMENT_CENTER
	box.add_theme_constant_override("separation", 2)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(box)
	var tint := UiKit.DARK_TEXT if button_color.get_luminance() > 0.45 else UiKit.TEXT
	if not icon_kind.is_empty():
		b._icon = GameIcon.make(icon_kind, icon_size, tint)
		b._icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		box.add_child(b._icon)
	b._label = UiKit.title(text, font_size, UiKit.TEXT, HORIZONTAL_ALIGNMENT_CENTER, 9)
	b._label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
	b._label.visible = not text.is_empty()
	box.add_child(b._label)
	b.set_color(button_color)
	return b


## İçeriğini çağıranın kurduğu buton; verilen normal / basılı kutularla.
static func make_plain(normal: StyleBox, down: StyleBox) -> TouchButton:
	var b := TouchButton.new()
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b._normal = normal
	b._down = down
	b.add_theme_stylebox_override("panel", normal)
	return b


## Butonun rengini değiştirir (ör. AT ↔ VUR).
func set_color(button_color: Color) -> void:
	color = button_color
	# Parlak doku paylaşılıyor: kenar boşlukları için kopyası alınır.
	_normal = UiKit.glossy(button_color, false, 40).duplicate()
	_down = UiKit.glossy(button_color, true, 40).duplicate()
	for sb: StyleBox in [_normal, _down]:
		sb.content_margin_left = 10
		sb.content_margin_right = 10
	_normal.content_margin_top = 6
	_down.content_margin_top = 14
	add_theme_stylebox_override("panel", _down if held else _normal)


func set_text(text: String) -> void:
	if _label == null:
		return
	_label.text = UiKit.upper(text)
	_label.visible = not text.is_empty()


func set_icon(icon_kind: String) -> void:
	if _icon != null:
		_icon.kind = icon_kind


## Bekleme göstergesi: butonun üstünde saat yönünde açılan koyu dilim (1 = yeni basıldı, 0 = hazır).
func set_cooldown(fraction: float) -> void:
	if _shade == null:
		_shade = CooldownShade.new()
		add_child(_shade)
	_shade.fraction = clampf(fraction, 0.0, 1.0)


## Butonu kaplayan, kalan bekleme kadar koyu pasta dilimi (dokunuşları engellemez).
class CooldownShade extends Control:
	var fraction: float = 0.0:
		set(value):
			if not is_equal_approx(value, fraction):
				fraction = value
				queue_redraw()

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		if fraction <= 0.0:
			return
		var c := size * 0.5
		var r := size.length() * 0.5
		var points := PackedVector2Array([c])
		var steps := 32
		for i in steps + 1:
			var a := -PI * 0.5 + TAU * (1.0 - fraction) + TAU * fraction * float(i) / steps
			points.append(c + Vector2(cos(a), sin(a)) * r)
		# Butonun yuvarlak köşelerinin dışına taşmasın diye kırpılır.
		var clipped := Geometry2D.intersect_polygons(points, _rounded_rect(Rect2(Vector2.ZERO, size), 34.0))
		for poly in clipped:
			draw_colored_polygon(poly, Color(0.05, 0.05, 0.1, 0.55))

	static func _rounded_rect(rect: Rect2, radius: float) -> PackedVector2Array:
		var out := PackedVector2Array()
		var corners := [rect.position + Vector2(radius, radius), Vector2(rect.end.x - radius, rect.position.y + radius),
				rect.end - Vector2(radius, radius), Vector2(rect.position.x + radius, rect.end.y - radius)]
		for k in 4:
			for i in 7:
				var a := PI + k * PI * 0.5 + float(i) / 6.0 * PI * 0.5
				out.append((corners[k] as Vector2) + Vector2(cos(a), sin(a)) * radius)
		return out


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree():
		if held:
			_set_held(false)
		_touch = -1
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed and _touch == -1 and get_global_rect().has_point(touch.position) and not _under_modal():
			_touch = touch.index
			_set_held(true)
			get_viewport().set_input_as_handled()
		elif not touch.pressed and touch.index == _touch:
			_touch = -1
			_set_held(false)
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == _touch:
			dragged.emit(drag.relative)
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		if _touch == MOUSE_TOUCH and motion.device != InputEvent.DEVICE_ID_EMULATION:
			dragged.emit(motion.relative)
	elif event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		# Dokunmadan üretilen sahte fare olayları yukarıda zaten işlendi.
		if mouse.device == InputEvent.DEVICE_ID_EMULATION or mouse.button_index != MOUSE_BUTTON_LEFT:
			return
		if mouse.pressed and _touch == -1 and get_global_rect().has_point(mouse.position) and not _under_modal():
			_touch = MOUSE_TOUCH
			_set_held(true)
			get_viewport().set_input_as_handled()
		elif not mouse.pressed and _touch == MOUSE_TOUCH:
			_touch = -1
			_set_held(false)
			get_viewport().set_input_as_handled()


## Bu buton açık bir panelin (Dialog, kart) altında mı kalıyor: o zaman basış
## panele aittir (yoksa HUD düğmesi tıklamayı yutar, paneldeki düğme basılmaz).
func _under_modal() -> bool:
	for node in get_tree().get_nodes_in_group("modal"):
		var modal := node as CanvasItem
		if modal != null and modal.is_visible_in_tree() and not modal.is_ancestor_of(self):
			return true
	return false


func _set_held(value: bool) -> void:
	if held == value:
		return
	held = value
	add_theme_stylebox_override("panel", _down if held else _normal)
	if held:
		if click:
			Sounds.play("ui_tap")
		pressed.emit()
	else:
		released.emit()
