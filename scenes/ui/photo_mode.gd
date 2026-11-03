class_name PhotoMode
extends Control
## Fotoğraf modu (Dalga 5, docs/gdd.md §10.6). Tam ekran "modal" örtü; Dialog değil: göl arkada yaşar, oyun donar
## (main: _panel_open), oyunun arayüzü gizli (main: hud). Dünyadaki 2B yazılar (konuşma balonları, balığın etiketi,
## tuzak rozeti, zil) görünürlük katmanı WORLD_LABELS'ta: açıkken viewport'un canvas_cull_mask'ından çıkar,
## görüntüye girmez.
## - Sürükle: kamera döner (yatayda ±YAW_RANGE, eğim PITCH_MIN..PITCH_MAX; FollowCamera.yaw_offset ve pitch).
##   Yakınlaştırma düğmeleri (ZOOM_MIN..ZOOM_MAX). Kamera hedefe yumuşakça gider (_process).
## - Çerçeve seçimi (PhotoFrame.KINDS: yok, ahşap, polaroid, çiçek, eski kâğıt); köşede oyunun logosu: ikisi de
##   fotoğrafa girer.
## - Deklanşör: düğmeler bir kare gizlenir, görüntü alınır, user://photos/olta_<tarih>.png'ye yazılır (iPhone'da
##   Dosyalar → Olta → photos); flaş, ses, titreşim, "Fotoğraf kaydedildi". Çıkışta kamera eski açısına döner.

signal closed
signal saved(path: String)

const PHOTO_DIR := "user://photos"
## Dünyadaki 2B yazıların görünürlük katmanı (CanvasItem.visibility_layer; balon, etiket, rozet, zil kendileri
## verir): fotoğraf modunda viewport bu katmanı çizmez.
const WORLD_LABELS := 1 << 1
const YAW_RANGE := deg_to_rad(40.0)
const PITCH_MIN := deg_to_rad(30.0)
const PITCH_MAX := deg_to_rad(72.0)
const ZOOM_MIN := 0.35
const ZOOM_MAX := 1.6
const ZOOM_STEP := 0.8
## Sürüklemenin açıya oranı (radyan / birim; ekranın 1080'lik yüksekliğinde).
const DRAG_RATE := 0.0028
## Kameranın hedef açıya yaklaşma hızı.
const EASE := 10.0
const BUTTON := Vector2(122, 122)
const SHUTTER := 170.0
const MARGIN := 24.0
const LOGO_H := 92.0

var camera: FollowCamera
## Son kaydedilen fotoğraf (yolu ve boyutu; bot denetler).
var last_path: String = ""
var last_size: Vector2i = Vector2i.ZERO

var _frame: PhotoFrame
var _logo: TextureRect
var _ui: Control
var _close: BaseButton
var _shutter: Button
var _zoom_in: Button
var _zoom_out: Button
var _frame_buttons: Dictionary = {}
var _hint: Label
var _note: Label
var _flash: ColorRect
var _yaw: float = 0.0
var _pitch: float = FollowCamera.PITCH
var _zoom: float = 1.0
var _saved_pitch: float = FollowCamera.PITCH
var _saved_zoom: float = 1.0
var _saved_mask: int = 0
var _shooting: bool = false
var _note_time: float = 0.0


func _ready() -> void:
	theme = UiKit.theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_to_group("modal")
	_frame = PhotoFrame.new()
	_frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_frame)
	_logo = TextureRect.new()
	_logo.texture = ItemArt.art("logo.png")
	_logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_logo.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_logo.visible = _logo.texture != null
	add_child(_logo)
	_ui = Control.new()
	_ui.name = "Controls"
	_ui.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_ui)
	_build_controls()
	_flash = ColorRect.new()
	_flash.color = Color(1, 1, 1, 0)
	_flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_flash)
	resized.connect(_layout)
	hide()


func _build_controls() -> void:
	var close := TextureButton.new()
	close.name = "Close"
	close.texture_normal = ItemArt.ui("close")
	close.ignore_texture_size = true
	close.stretch_mode = TextureButton.STRETCH_KEEP_ASPECT_CENTERED
	close.custom_minimum_size = BUTTON
	close.size = BUTTON
	close.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	if close.texture_normal == null:
		var fallback := UiKit.button("X", UiKit.DANGER, UiKit.SIZE_BODY, BUTTON)
		fallback.name = "Close"
		_close = fallback
	else:
		_close = close
	_close.pressed.connect(close_photo)
	_ui.add_child(_close)
	_shutter = Button.new()
	_shutter.name = "Shutter"
	_shutter.focus_mode = Control.FOCUS_NONE
	_shutter.custom_minimum_size = Vector2(SHUTTER, SHUTTER)
	_shutter.size = Vector2(SHUTTER, SHUTTER)
	for state: String in ["normal", "hover", "pressed", "hover_pressed"]:
		var round := StyleBoxFlat.new()
		round.bg_color = Color("#ffffff") if state != "pressed" else Color("#e6e6e6")
		round.border_color = Color("#3a2414")
		round.set_border_width_all(10)
		round.set_corner_radius_all(int(SHUTTER))
		round.shadow_color = Color(0, 0, 0, 0.3)
		round.shadow_size = 10
		_shutter.add_theme_stylebox_override(state, round)
	var lens := GameIcon.make("camera", 92)
	lens.position = Vector2((SHUTTER - 92.0) * 0.5, (SHUTTER - 92.0) * 0.5)
	lens.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_shutter.add_child(lens)
	_shutter.pressed.connect(shoot)
	_ui.add_child(_shutter)
	_zoom_in = UiKit.button("+", UiKit.SECONDARY, UiKit.SIZE_TITLE, BUTTON)
	_zoom_in.name = "ZoomIn"
	_zoom_in.pressed.connect(func() -> void: _set_zoom(_zoom * ZOOM_STEP))
	_ui.add_child(_zoom_in)
	_zoom_out = UiKit.button("-", UiKit.SECONDARY, UiKit.SIZE_TITLE, BUTTON)
	_zoom_out.name = "ZoomOut"
	_zoom_out.pressed.connect(func() -> void: _set_zoom(_zoom / ZOOM_STEP))
	_ui.add_child(_zoom_out)
	for frame: String in PhotoFrame.KINDS:
		var b := Button.new()
		b.name = "Frame_" + frame
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = BUTTON
		b.size = BUTTON
		var mini := MiniFrame.new()
		mini.kind = frame
		mini.position = Vector2(14, 14)
		mini.size = BUTTON - Vector2(28, 28)
		mini.mouse_filter = Control.MOUSE_FILTER_IGNORE
		b.add_child(mini)
		b.pressed.connect(func() -> void: select_frame(frame))
		_ui.add_child(b)
		_frame_buttons[frame] = b
	_hint = UiKit.title("", 34, UiKit.TEXT, HORIZONTAL_ALIGNMENT_CENTER, 8)
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_ui.add_child(_hint)
	_note = UiKit.title("", 40, UiKit.TEXT, HORIZONTAL_ALIGNMENT_CENTER, 10)
	_note.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_note.visible = false
	_ui.add_child(_note)


## Açılır: kameranın açısı ve uzaklığı saklanır (çıkışta döner), dünyadaki 2B yazılar görüntüden çıkar. zoom:
## başlangıçtaki uzaklık çarpanı (0: kameranınki; karttan açılınca balıkçıya yakın).
func open_photo(view: FollowCamera, zoom: float = 0.0) -> void:
	camera = view
	_saved_pitch = camera.pitch
	_saved_zoom = camera.zoom
	_yaw = 0.0
	_pitch = camera.pitch
	_zoom = clampf(zoom, ZOOM_MIN, ZOOM_MAX) if zoom > 0.0 else camera.zoom
	_saved_mask = get_viewport().canvas_cull_mask
	get_viewport().canvas_cull_mask = _saved_mask & ~WORLD_LABELS
	_note.visible = false
	_flash.color.a = 0.0
	show()
	refresh()
	_layout()
	Sounds.play("panel_open")


func close_photo() -> void:
	if not visible or _shooting:
		return
	hide()
	if camera != null:
		camera.yaw_offset = 0.0
		camera.pitch = _saved_pitch
		camera.zoom = _saved_zoom
	get_viewport().canvas_cull_mask = _saved_mask if _saved_mask != 0 else get_viewport().canvas_cull_mask | WORLD_LABELS
	Sounds.play("panel_close")
	closed.emit()


## Yazılar o anki dilde; seçili çerçevenin düğmesi işaretli.
func refresh() -> void:
	_hint.text = UiKit.upper(tr("UI_PHOTO_HINT"))
	for frame: String in _frame_buttons:
		var b: Button = _frame_buttons[frame]
		var picked := frame == _frame.kind
		for state: String in ["normal", "hover", "pressed", "hover_pressed"]:
			b.add_theme_stylebox_override(state, UiKit.card_style(UiKit.SUCCESS if picked else UiKit.CREAM_EDGE, 24,
					UiKit.CREAM_CARD, 7 if picked else 3))
		b.tooltip_text = tr("UI_PHOTO_FRAME_" + frame.to_upper())


func select_frame(frame: String) -> void:
	if not frame in PhotoFrame.KINDS:
		return
	Sounds.play("ui_tap")
	_frame.kind = frame
	refresh()
	_layout()


## Seçili çerçeve.
func frame_kind() -> String:
	return _frame.kind


## Kameranın hedef açısı (bot): yatay fark, eğim, uzaklık çarpanı.
func view_target() -> Vector3:
	return Vector3(_yaw, _pitch, _zoom)


func _set_zoom(value: float) -> void:
	Sounds.play("ui_tap")
	_zoom = clampf(value, ZOOM_MIN, ZOOM_MAX)


## Sürükleme: yatayda döndürür, dikeyde eğer (ekranın yüksekliğine göre aynı hız).
func rotate_by(relative: Vector2) -> void:
	var rate := DRAG_RATE * 1080.0 / maxf(1.0, get_viewport_rect().size.y)
	_yaw = clampf(_yaw - relative.x * rate, -YAW_RANGE, YAW_RANGE)
	_pitch = clampf(_pitch - relative.y * rate, PITCH_MIN, PITCH_MAX)


func _gui_input(event: InputEvent) -> void:
	if event is InputEventScreenDrag:
		rotate_by((event as InputEventScreenDrag).relative)
		accept_event()
	elif event is InputEventMouseMotion:
		var motion := event as InputEventMouseMotion
		if motion.device != InputEvent.DEVICE_ID_EMULATION and (motion.button_mask & MOUSE_BUTTON_MASK_LEFT) != 0:
			rotate_by(motion.relative)
			accept_event()


func _process(delta: float) -> void:
	if not visible:
		return
	if camera != null:
		var t := 1.0 - exp(-EASE * minf(delta, 0.1))
		camera.yaw_offset = lerpf(camera.yaw_offset, _yaw, t)
		camera.pitch = lerpf(camera.pitch, _pitch, t)
		camera.zoom = lerpf(camera.zoom, _zoom, t)
	if _flash.color.a > 0.0:
		_flash.color.a = maxf(0.0, _flash.color.a - delta * 2.6)
	if _note.visible:
		_note_time -= delta
		if _note_time <= 0.0:
			_note.visible = false


## Deklanşör: düğmeler gizlenir (çerçeve ve logo kalır), iki kare sonra görüntü alınır ve kaydedilir.
func shoot() -> void:
	if _shooting or not visible:
		return
	_shooting = true
	_ui.visible = false
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	_ui.visible = true
	# Geri bildirim hemen (flaş, ses, titreşim); PNG'yi yazmak telefonda bir an sürer: bir kare sonra.
	_flash.color.a = 0.85
	Sounds.play("shutter")
	Sounds.haptic(40)
	await get_tree().process_frame
	var path := save_photo(image)
	_shooting = false
	_note.text = UiKit.upper(tr("UI_PHOTO_SAVED") if not path.is_empty() else tr("UI_PHOTO_FAILED"))
	_note.visible = true
	_note_time = 2.4
	_layout()
	if not path.is_empty():
		saved.emit(path)


## Görüntüyü user://photos'a yazar; yolu döner (yazılamadıysa boş).
func save_photo(image: Image) -> String:
	if image == null or image.is_empty():
		return ""
	DirAccess.make_dir_recursive_absolute(PHOTO_DIR)
	var path := PHOTO_DIR.path_join(photo_name(int(Time.get_unix_time_from_system())))
	# Aynı saniyede iki çekim: sona sıra eklenir.
	var n := 2
	while FileAccess.file_exists(path):
		path = PHOTO_DIR.path_join(photo_name(int(Time.get_unix_time_from_system())).get_basename() + "_%d.png" % n)
		n += 1
	if image.save_png(path) != OK:
		return ""
	last_path = path
	last_size = image.get_size()
	return path


## Dosya adı: olta_YYYYMMDD_HHMMSS.png (yerel saat).
static func photo_name(unix: int) -> String:
	var bias := int(Time.get_time_zone_from_system().get("bias", 0)) * 60
	var d := Time.get_datetime_dict_from_unix_time(unix + bias)
	return "olta_%04d%02d%02d_%02d%02d%02d.png" % [int(d["year"]), int(d["month"]), int(d["day"]), int(d["hour"]),
			int(d["minute"]), int(d["second"])]


## Düğmelerin ve logonun yeri: güvenli alanın içinde (çerçeve ekranın tamamında).
func _layout() -> void:
	if _ui == null:
		return
	var view := size
	var inset := UiKit.safe_insets(self)
	var left := inset.x + MARGIN
	var right := view.x - inset.z - MARGIN
	var top := inset.y + MARGIN
	var bottom := view.y - inset.w - MARGIN
	_close.position = Vector2(right - BUTTON.x, top)
	_shutter.position = Vector2(view.x * 0.5 - SHUTTER * 0.5, bottom - SHUTTER)
	_zoom_in.position = Vector2(right - BUTTON.x, view.y * 0.5 - BUTTON.y - 10.0)
	_zoom_out.position = Vector2(right - BUTTON.x, view.y * 0.5 + 10.0)
	var x := left
	for frame: String in PhotoFrame.KINDS:
		var b: Button = _frame_buttons[frame]
		b.position = Vector2(x, bottom - BUTTON.y)
		x += BUTTON.x + 14.0
	_hint.position = Vector2(view.x * 0.5 - 600.0, top + 30.0)
	_hint.size = Vector2(1200.0, 50.0)
	_note.position = Vector2(view.x * 0.5 - 600.0, bottom - SHUTTER - 80.0)
	_note.size = Vector2(1200.0, 60.0)
	# Logo: polaroid'de alttaki şeridin sağında, ötekilerde sağ alt köşede (çerçevenin içinde).
	var rect := Rect2(Vector2.ZERO, view)
	var b := PhotoFrame.border(rect, _frame.kind)
	var h := LOGO_H
	if _frame.kind == "polaroid":
		h = PhotoFrame.strip_height(rect) * 0.8
		_logo.size = Vector2(h * 2.2, h)
		_logo.position = Vector2(view.x - b - _logo.size.x - 12.0, view.y - PhotoFrame.strip_height(rect) * 0.9)
	else:
		# Ersin'in çerçevesinde köşe süsünün (sazlar, nilüfer, pusula) solunda (PhotoFrame.logo_inset).
		_logo.size = Vector2(h * 2.2, h)
		_logo.position = view - PhotoFrame.logo_inset(rect, _frame.kind) - _logo.size


## Düğmedeki küçük çerçeve önizlemesi (yok: çizgili kutu).
class MiniFrame extends Control:
	var kind: String = "none"

	func _draw() -> void:
		var rect := Rect2(Vector2.ZERO, size)
		draw_rect(rect, Color("#9fd3ea"))
		draw_rect(Rect2(Vector2(0, size.y * 0.62), Vector2(size.x, size.y * 0.38)), Color("#3c8fc0"))
		if kind == "none":
			draw_rect(rect, Color("#3a2414"), false, 3.0)
			draw_line(Vector2(6, 6), size - Vector2(6, 6), Color("#e5484d"), 4.0, true)
		else:
			PhotoFrame.draw_frame(self, rect, kind, false)
