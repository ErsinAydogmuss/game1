class_name TouchJoystick
extends Control
## Sol alttaki sabit yürüme halkası (Kazı'nın joystick'inden; orada parmağın altında belirirdi).
## Yalnızca halkanın içinde başlayan dokunuşu alır ve o dokunuş oyuna geçmez: halkanın dışında
## dokunarak yürüme, atış ve köylüye dokunma aynen sürer. Parmak sürüklendikçe topuz halkanın
## içinde kalır. output: ekrandaki yön (x sağ, y aşağı), uzunluğu 0..1; ölü bölgede 0, az itince
## yavaş yürünür. Çoklu dokunmaya uygun (bir parmak halkadayken öbürü suya atar); masaüstünde
## fareyle de sürülür. Açık bir panelin altında dokunuş almaz (TouchButton gibi). Soluk iken
## (dimmed: kart, yakalama, geri sarma) görünür ama dokunuş almaz: düğmeler zıplamasın.

## Kutunun boyu; halkanın ve topuzun yarıçapı (birim); ölü bölge (halkanın oranı).
const SIZE := Vector2(252, 252)
const RING := 112.0
const KNOB := 48.0
const DEAD_ZONE := 0.12
## Fareyle basıldığında _touch bu değeri alır (dokunma indeksleri 0'dan başlar).
const MOUSE_TOUCH := -2

var output := Vector2.ZERO
var dimmed: bool = false:
	set(value):
		if value == dimmed:
			return
		dimmed = value
		if dimmed:
			release()
		queue_redraw()

var _touch: int = -1
## Topuzun halkanın ortasına göre yeri (birim).
var _knob := Vector2.ZERO
## Halka ve topuz yuvarlak StyleBox: zemin, kenar ve yumuşak kenar tek çizimde (draw_circle ve
## kenar yumuşatmalı draw_arc ile halka karede 13 çizim tutuyordu; iskele 150 sınırını aştı).
var _ring := StyleBoxFlat.new()
var _knob_box := StyleBoxFlat.new()


func _init() -> void:
	custom_minimum_size = SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	for box: StyleBoxFlat in [_ring, _knob_box]:
		box.anti_aliasing = true
		box.corner_detail = 16
	_ring.set_corner_radius_all(int(RING))
	_ring.set_border_width_all(7)
	_knob_box.set_corner_radius_all(int(KNOB))
	_knob_box.set_border_width_all(4)
	_knob_box.shadow_size = 2
	_knob_box.shadow_offset = Vector2(0, 5)


## Halka basılı mı?
func active() -> bool:
	return _touch != -1


## Parmak bırakılmış sayılır (odak kaybı, panel, gizlenme).
func release() -> void:
	_touch = -1
	_knob = Vector2.ZERO
	output = Vector2.ZERO
	queue_redraw()


## Ekrandaki bir nokta halkanın içinde mi?
func hits(screen: Vector2) -> bool:
	var rect := get_global_rect()
	return screen.distance_to(rect.get_center()) <= RING * rect.size.x / SIZE.x


## Ölü bölgeli yön: uzunluk 0..1 (DEAD_ZONE'un altı 0, üstü 0'dan 1'e yeniden ölçeklenir).
static func shape(offset: Vector2, radius: float) -> Vector2:
	var v := (offset / radius).limit_length(1.0)
	var length := v.length()
	if length < DEAD_ZONE:
		return Vector2.ZERO
	return v / length * ((length - DEAD_ZONE) / (1.0 - DEAD_ZONE))


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or dimmed:
		if _touch != -1:
			release()
		return
	if event is InputEventScreenTouch:
		var touch := event as InputEventScreenTouch
		if touch.pressed and _touch == -1 and hits(touch.position) and not _under_modal():
			_touch = touch.index
			_move(touch.position)
			get_viewport().set_input_as_handled()
		elif not touch.pressed and touch.index == _touch:
			release()
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		var drag := event as InputEventScreenDrag
		if drag.index == _touch:
			_move(drag.position)
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		# Dokunmadan üretilen sahte fare olayları yukarıda zaten işlendi.
		if mouse.device == InputEvent.DEVICE_ID_EMULATION or mouse.button_index != MOUSE_BUTTON_LEFT:
			return
		if mouse.pressed and _touch == -1 and hits(mouse.position) and not _under_modal():
			_touch = MOUSE_TOUCH
			_move(mouse.position)
			get_viewport().set_input_as_handled()
		elif not mouse.pressed and _touch == MOUSE_TOUCH:
			release()
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		if _touch == MOUSE_TOUCH and motion.device != InputEvent.DEVICE_ID_EMULATION:
			_move(motion.position)


## Parmağın ekrandaki yerine göre topuz ve yön.
func _move(screen: Vector2) -> void:
	var rect := get_global_rect()
	var scale_to_local := SIZE.x / maxf(rect.size.x, 1.0)
	var offset := (screen - rect.get_center()) * scale_to_local
	_knob = offset.limit_length(RING)
	output = shape(offset, RING)
	queue_redraw()


## Bu halka açık bir panelin (Dialog, kart) altında mı: o zaman dokunuş panele aittir.
func _under_modal() -> bool:
	for node in get_tree().get_nodes_in_group("modal"):
		var modal := node as CanvasItem
		if modal != null and modal.is_visible_in_tree() and not modal.is_ancestor_of(self):
			return true
	return false


func _draw() -> void:
	var c := size * 0.5
	var alpha := 0.45 if dimmed else 1.0
	var pressed := _touch != -1
	# Halka: koyu yarı saydam zemin ve açık kenar (su ve kum üstünde de seçilsin); basılıyken parlak.
	_ring.bg_color = Color(0.05, 0.12, 0.18, (0.36 if pressed else 0.28) * alpha)
	_ring.border_color = Color(1, 1, 1, (0.9 if pressed else 0.75) * alpha)
	draw_style_box(_ring, Rect2(c - Vector2.ONE * RING, Vector2.ONE * RING * 2.0))
	# Dört yön işareti (küçük oklar): tek üçgen dizisi.
	var points := PackedVector2Array()
	var colors := PackedColorArray()
	var indices := PackedInt32Array()
	for k in 4:
		var dir := Vector2.from_angle(TAU * k / 4.0)
		var tip := c + dir * (RING - 16.0)
		var side := Vector2(-dir.y, dir.x) * 9.0
		points.append_array(PackedVector2Array([tip, tip - dir * 14.0 + side, tip - dir * 14.0 - side]))
		indices.append_array(PackedInt32Array([k * 3, k * 3 + 1, k * 3 + 2]))
		for i in 3:
			colors.append(Color(1, 1, 1, 0.55 * alpha))
	RenderingServer.canvas_item_add_triangle_array(get_canvas_item(), indices, points, colors)
	# Topuz (gölgesiyle).
	var knob := c + _knob
	_knob_box.bg_color = Color(1, 1, 1, (0.92 if pressed else 0.75) * alpha)
	_knob_box.border_color = Color(0.16, 0.32, 0.4, 0.8 * alpha)
	_knob_box.shadow_color = Color(0, 0, 0, 0.25 * alpha)
	draw_style_box(_knob_box, Rect2(knob - Vector2.ONE * KNOB, Vector2.ONE * KNOB * 2.0))
