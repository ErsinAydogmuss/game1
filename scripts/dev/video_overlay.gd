extends Control
## Geliştirici aracı (yalnızca debug): tanıtım videosunda parmakların nereye dokunduğunu,
## başlık kartlarını ve alt yazıları çizer. Oyunun kendisi bunu kullanmaz.

const FINGER_RADIUS := 44.0

var _fingers: Dictionary = {}
var _ripples: Array[Dictionary] = []
var _title: Label
var _subtitle: Label
var _caption: PanelContainer
var _caption_label: Label
var _fast: Label
var _caption_tween: Tween
var _title_tweens: Array[Tween] = []
## Senk parlaması: kalan kare sayısı ve bu karede ekranın tamamı beyaz mı (reels: kurgu aracı kaydın
## karelerini günlükle bununla eşler).
var _flash: int = 0
var _flashing: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	theme = UiKit.theme()
	var center := VBoxContainer.new()
	center.alignment = BoxContainer.ALIGNMENT_CENTER
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	_title = UiKit.label("", 132, UiKit.ACCENT, HORIZONTAL_ALIGNMENT_CENTER)
	_title.add_theme_constant_override("outline_size", 18)
	_title.add_theme_color_override("font_outline_color", Color(0.1, 0.07, 0.04))
	center.add_child(_title)
	_subtitle = UiKit.label("", UiKit.SIZE_TITLE, UiKit.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	_subtitle.add_theme_constant_override("outline_size", 12)
	_subtitle.add_theme_color_override("font_outline_color", Color(0.1, 0.07, 0.04))
	center.add_child(_subtitle)
	_title.modulate.a = 0.0
	_subtitle.modulate.a = 0.0
	_caption = PanelContainer.new()
	_caption.add_theme_stylebox_override("panel", UiKit.pill_style(Color(0.05, 0.06, 0.1, 0.78)))
	_caption.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_caption.modulate.a = 0.0
	add_child(_caption)
	_caption_label = UiKit.label("", UiKit.SIZE_TITLE, UiKit.TEXT, HORIZONTAL_ALIGNMENT_CENTER)
	_caption.add_child(_caption_label)
	_fast = UiKit.label("3×", UiKit.SIZE_HERO, UiKit.TEXT)
	_fast.add_theme_constant_override("outline_size", 12)
	_fast.add_theme_color_override("font_outline_color", Color(0.05, 0.05, 0.08))
	_fast.visible = false
	add_child(_fast)


## Hızlı sarma işareti (▶▶ 3×).
func set_fast_forward(value: bool) -> void:
	_fast.visible = value


## Başlık kartı (ortada büyük yazı). duration sonunda kaybolur; 0 ise kalır.
func show_title(title: String, subtitle: String, duration: float) -> void:
	_title.text = title
	_subtitle.text = subtitle
	for old in _title_tweens:
		old.kill()
	_title_tweens.clear()
	for label: Label in [_title, _subtitle]:
		var tween := label.create_tween()
		tween.tween_property(label, "modulate:a", 1.0, 0.5)
		if duration > 0.0:
			tween.tween_interval(duration)
			tween.tween_property(label, "modulate:a", 0.0, 0.5)
		_title_tweens.append(tween)


## Alt yazı: ekranın alt ortasında kısa açıklama.
func show_caption(text: String, duration: float) -> void:
	_caption_label.text = text
	_caption.reset_size()
	# Önceki alt yazının animasyonu sürüyorsa durdur (yoksa yenisini erken söndürür).
	if _caption_tween != null:
		_caption_tween.kill()
	_caption_tween = _caption.create_tween()
	_caption_tween.tween_property(_caption, "modulate:a", 1.0, 0.3)
	_caption_tween.tween_interval(duration)
	_caption_tween.tween_property(_caption, "modulate:a", 0.0, 0.4)


## Sonraki frames kare (çağrıldığı kare dahil) ekranın tamamı beyaz.
func flash(frames: int) -> void:
	_flash = frames


func finger_down(index: int, pos: Vector2) -> void:
	_fingers[index] = pos


func finger_move(index: int, pos: Vector2) -> void:
	if _fingers.has(index):
		_fingers[index] = pos


func finger_up(index: int) -> void:
	if _fingers.has(index):
		_ripples.append({ "pos": _fingers[index], "t": 0.0 })
		_fingers.erase(index)


func _process(delta: float) -> void:
	_flashing = _flash > 0
	if _flash > 0:
		_flash -= 1
	for ripple in _ripples:
		ripple["t"] = float(ripple["t"]) + delta
	_ripples = _ripples.filter(func(r: Dictionary) -> bool: return float(r["t"]) < 0.45)
	# Alt yazı kutusu alt ortada dursun (eylem düğmesinin solunda).
	_caption.position = Vector2((size.x - _caption.size.x) * 0.5, size.y - _caption.size.y - 150.0)
	_fast.position = Vector2(size.x - 230.0, size.y * 0.36)
	queue_redraw()


func _draw() -> void:
	if _flashing:
		draw_rect(Rect2(Vector2.ZERO, size), Color.WHITE)
		return
	if _fast.visible:
		# İki üçgen: hızlı sarma simgesi.
		var o := _fast.position + Vector2(-150.0, 18.0)
		for k in 2:
			var x := o.x + k * 56.0
			draw_colored_polygon(PackedVector2Array([Vector2(x, o.y), Vector2(x + 58.0, o.y + 34.0),
					Vector2(x, o.y + 68.0)]), Color(1, 1, 1, 0.92))
	for index: int in _fingers:
		var p: Vector2 = _fingers[index]
		draw_circle(p, FINGER_RADIUS, Color(1, 1, 1, 0.32))
		draw_arc(p, FINGER_RADIUS, 0.0, TAU, 48, Color(1, 1, 1, 0.85), 5.0, true)
	for ripple in _ripples:
		var t := float(ripple["t"]) / 0.45
		draw_arc(ripple["pos"], FINGER_RADIUS * (1.0 + t), 0.0, TAU, 48, Color(1, 1, 1, 0.7 * (1.0 - t)), 5.0, true)
