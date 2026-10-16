class_name Hud
extends Control
## Oyun arayüzü (HUD): köşelerdeki göstergeler ve butonlar. Dokunuşları engellemez
## (MOUSE_FILTER_IGNORE); parmağı yalnızca TouchButton'lar yakalar. Çentik ve yuvarlak köşeler
## için güvenli alan payı her kenara eklenir (UiKit.safe_insets).
## 2. adımda iskelet: başlık, sürüm, ayarlar düğmesi, ipucu çubuğu ve hata ayıklama FPS etiketi.
## Eylem düğmesi ve gerilim çubuğu 4. adımda gelir.

signal settings_pressed

## Ekran kenarından en az bu kadar boşluk (güvenli alan payına eklenir).
const MARGIN := 28.0
## FPS etiketi bu aralıkla (saniye) yenilenir.
const FPS_INTERVAL := 0.5

var settings_button: TouchButton

var _frames: Array[MarginContainer] = []
var _title: Label
var _version: Label
var _fps: Label
var _hint: PanelContainer
var _hint_label: Label
var _hint_key: String = ""
var _fps_clock: float = 0.0


func _ready() -> void:
	theme = UiKit.theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_build_top()
	_build_bottom()
	get_viewport().size_changed.connect(_apply_safe_area)
	_apply_safe_area()
	refresh()


func _process(delta: float) -> void:
	if not _fps.visible:
		return
	_fps_clock += delta
	if _fps_clock >= FPS_INTERVAL:
		_fps_clock = 0.0
		_fps.text = tr("UI_FPS") % int(round(Engine.get_frames_per_second()))


## Dil değişince metinleri yeniden yazar.
func refresh() -> void:
	_title.text = UiKit.upper(tr("UI_GAME_TITLE"))
	_version.text = tr("UI_VERSION") % str(ProjectSettings.get_setting("application/config/version", "0"))
	if not _hint_key.is_empty():
		_hint_label.text = tr(_hint_key)


## Alttaki ipucu çubuğunu gösterir (çeviri anahtarıyla; boş anahtar gizler).
func show_hint(key: String) -> void:
	_hint_key = key
	_hint.visible = not key.is_empty()
	if _hint.visible:
		_hint_label.text = tr(key)


# --- Kurulum ---------------------------------------------------------------------

func _frame() -> MarginContainer:
	var frame := MarginContainer.new()
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(frame)
	_frames.append(frame)
	return frame


func _build_top() -> void:
	# Sol üst: oyunun adı ve sürüm.
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
	# Sağ üst: ayarlar.
	settings_button = TouchButton.make("", "settings", UiKit.NEUTRAL, Vector2(132, 132), UiKit.SIZE_BODY, 84.0)
	settings_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	settings_button.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	settings_button.pressed.connect(func() -> void: settings_pressed.emit())
	_frame().add_child(settings_button)


func _build_bottom() -> void:
	# Alt orta: ipucu çubuğu (ileride Dede'nin ağzından konuşur).
	_hint = PanelContainer.new()
	_hint.add_theme_stylebox_override("panel", UiKit.pill_style())
	_hint.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_hint.size_flags_vertical = Control.SIZE_SHRINK_END
	_hint.visible = false
	_frame().add_child(_hint)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_hint.add_child(row)
	row.add_child(GameIcon.make("bobber", 64))
	_hint_label = UiKit.label("", UiKit.SIZE_BODY)
	row.add_child(_hint_label)
	# Sol alt: FPS (yalnızca geliştirme sürümünde).
	_fps = UiKit.label("", UiKit.SIZE_SMALL, UiKit.MUTED)
	_fps.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_fps.size_flags_vertical = Control.SIZE_SHRINK_END
	_fps.visible = OS.is_debug_build()
	_frame().add_child(_fps)


func _apply_safe_area() -> void:
	var inset := UiKit.safe_insets(self)
	for frame in _frames:
		frame.add_theme_constant_override("margin_left", int(MARGIN + inset.x))
		frame.add_theme_constant_override("margin_top", int(MARGIN + inset.y))
		frame.add_theme_constant_override("margin_right", int(MARGIN + inset.z))
		frame.add_theme_constant_override("margin_bottom", int(MARGIN + inset.w))
