class_name Hud
extends Control
## Oyun arayüzü (HUD). Dokunuşları engellemez (MOUSE_FILTER_IGNORE); parmağı yalnızca
## TouchButton'lar yakalar. Çentik ve yuvarlak köşeler için güvenli alan payı her kenara eklenir
## (UiKit.safe_insets).
## - Sol üst: oyunun adı ve sürüm. Sağ üst: ayarlar.
## - Sağ alt: büyük eylem düğmesi (AT / GERİ SAR / BEKLE / VUR! / SAR); ekranın her yeri de
##   aynı işi yapar, düğme ne olacağını yazar.
## - Üst orta: çekişmede gerilim çubuğu (renk + ikon + sarsıntı + "BIRAK!" yazısı: renk körü
##   oyuncu da okusun).
## - Orta: kısa bildirimler ("Erken davrandın!"). Alt orta: Dede'nin ipucu çubuğu.
## - Sol alt: geliştirme sürümünde FPS.

signal settings_pressed
signal action_down
signal action_up

## Ekran kenarından en az bu kadar boşluk (güvenli alan payına eklenir).
const MARGIN := 28.0
const FPS_INTERVAL := 0.5
const ACTION_SIZE := Vector2(300, 300)
const TOAST_TIME := 1.7

var settings_button: TouchButton
var action_button: TouchButton
var tension_bar: TensionBar

var _frames: Array[MarginContainer] = []
## İpucu çubuğunun çerçevesi: iki yanda eylem düğmesi kadar boşluk (düğmenin altına girmesin).
var _hint_frame: MarginContainer
var _title: Label
var _version: Label
var _fps: Label
var _hint: PanelContainer
var _hint_label: Label
## İpucu çubuğundaki Dede yüzü; resim yoksa yer tutucu ikon.
var _face: TextureRect
var _face_icon: Control
var _hint_key: String = ""
var _toast: Label
var _toast_age: float = -1.0
var _action_kind: String = "-"
var _clock: float = 0.0
var _fps_clock: float = 0.0


func _ready() -> void:
	theme = UiKit.theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_top()
	_build_bottom()
	_build_center()
	get_viewport().size_changed.connect(_apply_safe_area)
	_apply_safe_area()
	refresh()


func _process(delta: float) -> void:
	_clock += delta
	if _fps.visible:
		_fps_clock += delta
		if _fps_clock >= FPS_INTERVAL:
			_fps_clock = 0.0
			_fps.text = tr("UI_FPS") % int(round(Engine.get_frames_per_second()))
	if _toast_age >= 0.0:
		_toast_age += delta
		var t := _toast_age / TOAST_TIME
		_toast.modulate.a = clampf((1.0 - t) * 4.0, 0.0, 1.0)
		_toast.scale = Vector2.ONE * (1.0 + 0.25 * maxf(0.0, 1.0 - _toast_age / 0.15))
		if t >= 1.0:
			_toast_age = -1.0
			_toast.visible = false
	# VUR! anında eylem düğmesi nabız gibi atar.
	if _action_kind == "hook":
		action_button.pivot_offset = action_button.size * 0.5
		action_button.scale = Vector2.ONE * (1.0 + 0.07 * sin(_clock * 22.0))
	else:
		action_button.scale = Vector2.ONE


## Dil değişince metinleri yeniden yazar.
func refresh() -> void:
	_title.text = UiKit.upper(tr("UI_GAME_TITLE"))
	_version.text = tr("UI_VERSION") % str(ProjectSettings.get_setting("application/config/version", "0"))
	if not _hint_key.is_empty():
		_hint_label.text = tr(_hint_key)
	var kind := _action_kind
	_action_kind = "-"
	set_action(kind)


## Alttaki ipucu çubuğu (çeviri anahtarıyla; boş anahtar gizler).
## İpucu çubuğundaki yüz (Ersin'in portresi ya da modelden çekilen); null ise yer tutucu ikon.
func set_portrait(texture: Texture2D) -> void:
	_face.texture = texture
	_face.visible = texture != null
	_face_icon.visible = texture == null


func show_hint(key: String) -> void:
	if key == _hint_key:
		return
	_hint_key = key
	_hint.visible = not key.is_empty()
	if _hint.visible:
		_hint_label.text = tr(key)


## Ortada kısa bir bildirim (metin hazır çevrilmiş gelir).
func toast(text: String, color: Color = UiKit.TEXT) -> void:
	_toast.text = UiKit.upper(text)
	_toast.add_theme_color_override("font_color", color)
	_toast.visible = true
	_toast_age = 0.0
	_toast.pivot_offset = _toast.size * 0.5


## Çekişmede oyunun adı gizlenir (gerilim çubuğuna yer).
func set_fighting(on: bool) -> void:
	_title.visible = not on
	_version.visible = not on


## Eylem düğmesinin işi: cast, retrieve, wait, hook, reel ya da "" (gizli).
func set_action(kind: String) -> void:
	if kind == _action_kind:
		return
	_action_kind = kind
	action_button.visible = not kind.is_empty()
	match kind:
		"cast":
			_set_button(tr("UI_ACT_CAST"), "rod", UiKit.PRIMARY)
		"retrieve":
			_set_button(tr("UI_ACT_RETRIEVE"), "reel", UiKit.NEUTRAL)
		"wait":
			_set_button(tr("UI_ACT_WAIT"), "hand", UiKit.NEUTRAL.darkened(0.25))
		"hook":
			_set_button(tr("UI_ACT_HOOK"), "hook", UiKit.DANGER)
		"reel":
			_set_button(tr("UI_ACT_REEL"), "reel", UiKit.SUCCESS)


func _set_button(text: String, icon_kind: String, color: Color) -> void:
	action_button.set_text(text)
	action_button.set_icon(icon_kind)
	action_button.set_color(color)


## Ekrandaki düğmeler (bot denetimi: boyut ve güvenli alan).
func buttons() -> Array[TouchButton]:
	return [settings_button, action_button]


# --- Kurulum ---------------------------------------------------------------------

func _frame() -> MarginContainer:
	var frame := MarginContainer.new()
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(frame)
	_frames.append(frame)
	return frame


func _build_top() -> void:
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 0)
	left.mouse_filter = Control.MOUSE_FILTER_IGNORE
	left.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	left.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_frame().add_child(left)
	_title = UiKit.title("", UiKit.SIZE_TITLE)
	left.add_child(_title)
	_version = UiKit.label("", UiKit.SIZE_SMALL, UiKit.MUTED)
	left.add_child(_version)
	settings_button = TouchButton.make("", "settings", UiKit.NEUTRAL, Vector2(132, 132), UiKit.SIZE_BODY, 84.0)
	settings_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	settings_button.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	settings_button.pressed.connect(func() -> void: settings_pressed.emit())
	_frame().add_child(settings_button)
	tension_bar = TensionBar.new()
	tension_bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	tension_bar.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	tension_bar.visible = false
	_frame().add_child(tension_bar)


func _build_bottom() -> void:
	_hint = PanelContainer.new()
	_hint.add_theme_stylebox_override("panel", UiKit.pill_style())
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_hint.size_flags_vertical = Control.SIZE_SHRINK_END
	_hint.visible = false
	_hint_frame = _frame()
	_hint_frame.add_child(_hint)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint.add_child(row)
	_face = TextureRect.new()
	_face.custom_minimum_size = Vector2(84, 84)
	_face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(_face)
	_face_icon = GameIcon.make("bobber", 64)
	row.add_child(_face_icon)
	set_portrait(ItemArt.portrait("dede_smile"))
	_hint_label = UiKit.label("", UiKit.SIZE_BODY)
	row.add_child(_hint_label)
	action_button = TouchButton.make("", "rod", UiKit.PRIMARY, ACTION_SIZE, UiKit.SIZE_TITLE, 120.0)
	action_button.click = false
	action_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	action_button.size_flags_vertical = Control.SIZE_SHRINK_END
	action_button.pressed.connect(func() -> void: action_down.emit())
	action_button.released.connect(func() -> void: action_up.emit())
	_frame().add_child(action_button)
	set_action("cast")
	_fps = UiKit.label("", UiKit.SIZE_SMALL, UiKit.MUTED)
	_fps.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_fps.size_flags_vertical = Control.SIZE_SHRINK_END
	_fps.visible = OS.is_debug_build()
	_frame().add_child(_fps)


func _build_center() -> void:
	_toast = UiKit.title("", 64, UiKit.TEXT, HORIZONTAL_ALIGNMENT_CENTER, 14)
	_toast.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_toast.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_toast.visible = false
	var frame := _frame()
	# Bildirim ortanın biraz üstünde: şamandırayı ve balıkçıyı kapatmasın.
	var box := VBoxContainer.new()
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	box.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 230)
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(spacer)
	box.add_child(_toast)
	frame.add_child(box)


func _apply_safe_area() -> void:
	var inset := UiKit.safe_insets(self)
	for frame in _frames:
		frame.add_theme_constant_override("margin_left", int(MARGIN + inset.x))
		frame.add_theme_constant_override("margin_top", int(MARGIN + inset.y))
		frame.add_theme_constant_override("margin_right", int(MARGIN + inset.z))
		frame.add_theme_constant_override("margin_bottom", int(MARGIN + inset.w))
	var side := int(MARGIN + maxf(inset.x, inset.z) + ACTION_SIZE.x + 24.0)
	_hint_frame.add_theme_constant_override("margin_left", side)
	_hint_frame.add_theme_constant_override("margin_right", side)


## Gerilim çubuğu: yeşil → sarı → kırmızı dolgu, sınırda çizgi, altında kopma sayacı; balık
## çırpınırken "!" ve sarsıntı, kırmızıdayken "BIRAK!" yazısı.
class TensionBar extends Control:
	const BAR := Vector2(720, 54)
	## Çubuğun gösterdiği en yüksek gerilim (patlamada 1'in üstüne çıkar).
	const SHOWN_MAX := 1.3

	var tension: float = 0.0
	var limit: float = 0.85
	var strain: float = 0.0
	var warn: bool = false
	var red: bool = false
	var distance: float = 0.0
	var _clock: float = 0.0
	var _label: Label
	var _alert: Label
	var _shown_red: int = -1
	var _back := UiKit.flat(Color(0.05, 0.06, 0.1, 0.72), 27)
	var _fills := {}

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		custom_minimum_size = BAR + Vector2(0, 92)
		_label = UiKit.title("", UiKit.SIZE_TITLE, UiKit.TEXT, HORIZONTAL_ALIGNMENT_CENTER, 12)
		_label.position = Vector2(0, BAR.y + 26)
		_label.size = Vector2(BAR.x, 64)
		add_child(_label)
		_alert = UiKit.title("!", 76, UiKit.ACCENT, HORIZONTAL_ALIGNMENT_CENTER, 14)
		_alert.position = Vector2(-96, -14)
		_alert.size = Vector2(80, 80)
		add_child(_alert)

	func _process(delta: float) -> void:
		if not visible:
			return
		_clock += delta
		queue_redraw()
		_alert.visible = warn and fmod(_clock, 0.25) < 0.17
		if int(red) != _shown_red:
			_shown_red = int(red)
			_label.add_theme_color_override("font_color", UiKit.BAD if red else UiKit.TEXT)
		_label.text = UiKit.upper(tr("UI_LET_GO")) if red else tr("UI_DISTANCE") % distance

	func _fill(color: Color) -> StyleBoxFlat:
		if not _fills.has(color):
			_fills[color] = UiKit.flat(color, 22)
		return _fills[color]

	func _draw() -> void:
		var shake := Vector2.ZERO
		if warn or red:
			shake = Vector2(sin(_clock * 53.0), cos(_clock * 47.0)) * (7.0 if red else 3.5)
		var rect := Rect2(shake + Vector2(0, 12), BAR)
		draw_style_box(_back, rect.grow(6))
		var red_from := limit / SHOWN_MAX
		var zone := Rect2(rect.position + Vector2(rect.size.x * red_from, 0), Vector2(rect.size.x * (1.0 - red_from), rect.size.y))
		draw_rect(zone, Color(0.9, 0.2, 0.22, 0.35))
		var fill := clampf(tension / SHOWN_MAX, 0.0, 1.0)
		var color := UiKit.GOOD
		if tension > limit:
			color = UiKit.BAD
		elif tension > limit * 0.8:
			color = UiKit.ACCENT
		if fill > 0.0:
			draw_style_box(_fill(color), Rect2(rect.position, Vector2(maxf(rect.size.x * fill, 44.0), rect.size.y)))
		var x := rect.position.x + rect.size.x * red_from
		draw_line(Vector2(x, rect.position.y - 10), Vector2(x, rect.end.y + 10), UiKit.TEXT, 5.0)
		if strain > 0.0:
			draw_rect(Rect2(rect.position + Vector2(0, rect.size.y + 8), Vector2(rect.size.x * strain, 10)), UiKit.BAD)
