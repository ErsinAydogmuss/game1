class_name Hud
extends Control
## Oyun arayüzü (HUD). Dokunuşları engellemez (MOUSE_FILTER_IGNORE); parmağı yalnızca
## TouchButton'lar yakalar. Çentik ve yuvarlak köşeler için güvenli alan payı her kenara eklenir
## (UiKit.safe_insets).
## - Sol üst: para, kova (dolu/kapasite) ve rütbe (çekişmede gizli; oyunun adı ve sürüm
##   ayarlarda). Sağ üst: Balık Defteri (olta sudayken gizli) ve ayarlar.
## - Sağ alt: büyük eylem düğmesi (AT / GERİ SAR / BEKLE / VUR! / SAR); ekranın her yeri de
##   aynı işi yapar, düğme ne olacağını yazar.
## - Üst orta: çekişmede gerilim çubuğu (renk + ikon + sarsıntı + "BIRAK!" yazısı: renk körü
##   oyuncu da okusun).
## - Orta: kısa bildirimler ("Erken davrandın!"). Alt orta: ipucu çubuğu (konuşanın yüzü ve sözü:
##   Dede ya da Nine).
## - Sol alt: geliştirme sürümünde FPS.

signal settings_pressed
signal book_pressed
signal action_down
signal action_up

## Ekran kenarından en az bu kadar boşluk (güvenli alan payına eklenir).
const MARGIN := 28.0
const FPS_INTERVAL := 0.5
const ACTION_SIZE := Vector2(300, 300)
## Eylem düğmesi: tür → [yazı anahtarı, ikon].
const ACTIONS := {
	"cast": ["UI_ACT_CAST", "rod"], "retrieve": ["UI_ACT_RETRIEVE", "reel"], "wait": ["UI_ACT_WAIT", "hand"],
	"hook": ["UI_ACT_HOOK", "hook"], "reel": ["UI_ACT_REEL", "reel"],
}
const TOAST_TIME := 1.7
## Bildirimin yanındaki ikonun boyu.
const TOAST_ICON := 104.0
## Defter düğmesinin rengi (deri kapak).
## Defter düğmesi turuncu (arayüz kitindeki düğme görseli; palet dışı renk kodla çizilirdi).
const BOOK_COLOR := UiKit.PRIMARY

var settings_button: TouchButton
var book_button: TouchButton
var action_button: TouchButton
var tension_bar: TensionBar
## Olta sudayken gizlenen düğmeler (eylem ve ayarlar dışındakiler): VUR dokunuşu onlara gitmesin.
var line_out_hidden: Array[Control] = []

var _frames: Array[MarginContainer] = []
## İpucu çubuğunun çerçevesi: iki yanda eylem düğmesi kadar boşluk (düğmenin altına girmesin).
var _hint_frame: MarginContainer
var _status: HBoxContainer
var _coins: Label
var _bucket: Label
var _rank: Label
var _rank_bar: RankBar
var _fps: Label
var _hint: PanelContainer
var _hint_label: Label
## İpucu çubuğundaki konuşanın yüzü; resim yoksa yer tutucu ikon.
var _face: TextureRect
var _face_icon: Control
## Ersin'in portresi yokken konuşanların modelden çekilen yedek yüzleri: "dede", "nine" -> Texture2D.
var _faces: Dictionary = {}
var _hint_key: String = ""
var _speaker: String = "dede"
var _toast: Label
## Bildirimin ikonu (ör. kova dolu: göle dönen balık) ve ikonla yazının kutusu (canlandırılan).
var _toast_icon: GameIcon
var _toast_box: HBoxContainer
var _toast_age: float = -1.0
## Sırası gelince gösterilecek bildirimler: [metin, renk, ses, ikon] (ör. rütbe atlama, kova dolu).
var _toast_queue: Array[Array] = []
## Açılıştan sonra kare başına bir tane çizilecek düğme dokuları (panellerin renkleri: dükkân,
## ayarlar). Hepsi açılışta çizilse açılış uzar; ilk açılan panelde çizilse panel takılır.
var _warm_later: Array[Array] = []
## Sıradaki bildirimler bu kadar sn bekler (yakalanan balığın etiketi ekrandayken).
var _toast_hold: float = 0.0
var _action_kind: String = "-"
var _clock: float = 0.0
var _fps_clock: float = 0.0


func _ready() -> void:
	theme = UiKit.theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	warm_styles()
	# Paneldeki düğme renkleri (UiKit.style_button'ın dört hâli): sonraki karelerde birer birer.
	for color: Color in [UiKit.SECONDARY, UiKit.NEUTRAL]:
		_warm_later.append([color, false])
		_warm_later.append([color.lightened(0.06), false])
		_warm_later.append([color, true])
		_warm_later.append([color.lerp(Color("#8c8f9e"), 0.7), false])
	_build_top()
	_build_bottom()
	_build_center()
	get_viewport().size_changed.connect(_apply_safe_area)
	_apply_safe_area()
	refresh()


func _process(delta: float) -> void:
	_clock += delta
	if _toast_hold > 0.0:
		_toast_hold -= delta
		if _toast_hold <= 0.0 and _toast_age < 0.0 and not _toast_queue.is_empty():
			_show_queued()
	if not _warm_later.is_empty():
		var job: Array = _warm_later.pop_front()
		UiKit.glossy(job[0], bool(job[1]))
	if _fps.visible:
		_fps_clock += delta
		if _fps_clock >= FPS_INTERVAL:
			_fps_clock = 0.0
			_fps.text = tr("UI_FPS") % int(round(Engine.get_frames_per_second()))
	if _toast_age >= 0.0:
		_toast_age += delta
		var t := _toast_age / TOAST_TIME
		_toast_box.modulate.a = clampf((1.0 - t) * 4.0, 0.0, 1.0)
		# Boyut yeni yazıya göre ancak yerleşimden sonra belli: merkez her kare güncellenir.
		_toast_box.pivot_offset = _toast_box.size * 0.5
		_toast_box.scale = Vector2.ONE * (1.0 + 0.25 * maxf(0.0, 1.0 - _toast_age / 0.15))
		if t >= 1.0:
			_toast_age = -1.0
			_toast_box.visible = false
			if not _toast_queue.is_empty():
				_show_queued()
	# VUR! anında eylem düğmesi nabız gibi atar.
	if _action_kind == "hook":
		action_button.pivot_offset = action_button.size * 0.5
		action_button.scale = Vector2.ONE * (1.0 + 0.07 * sin(_clock * 22.0))
	else:
		action_button.scale = Vector2.ONE


## Dil değişince metinleri yeniden yazar.
func refresh() -> void:
	if not _hint_key.is_empty():
		_hint_label.text = tr(_hint_key)
	var kind := _action_kind
	_action_kind = "-"
	set_action(kind)


## İpucu çubuğunda bir konuşanın yedek yüzü (Ersin'in portresi yokken modelden çekilen). Portre
## varsa yüz sözün ifadesiyle portreden gelir (Moods); ikisi de yoksa yer tutucu ikon.
func set_portrait(texture: Texture2D, speaker: String = "dede") -> void:
	_faces[speaker] = texture
	if speaker == _speaker:
		_show_face()


## Alttaki ipucu çubuğu: çeviri anahtarı ve konuşan ("dede", "nine"); boş anahtar gizler.
func show_hint(key: String, speaker: String = "dede") -> void:
	if key == _hint_key and speaker == _speaker:
		return
	_hint_key = key
	_speaker = speaker
	_show_face()
	_hint.visible = not key.is_empty()
	if _hint.visible:
		_hint_label.text = tr(key)


## Şu an ipucu çubuğunda konuşan.
func hint_speaker() -> String:
	return _speaker


func _show_face() -> void:
	var texture := Moods.face(_speaker, _hint_key)
	if texture == null:
		texture = _faces.get(_speaker) as Texture2D
	_face.texture = texture
	_face.visible = texture != null
	_face_icon.visible = texture == null


## Sol üstteki durum: para, kova ve rütbe (progress: rütbe içindeki ilerleme 0..1).
func set_status(coins: int, bucket: int, capacity: int, rank: int, progress: float) -> void:
	_coins.text = UiKit.format_int(coins)
	_bucket.text = tr("UI_BUCKET_COUNT") % [bucket, capacity]
	_bucket.add_theme_color_override("font_color", UiKit.ACCENT if bucket >= capacity else UiKit.TEXT)
	_rank.text = str(rank)
	_rank_bar.progress = progress
	_rank_bar.queue_redraw()


## Bildirim: biri gösteriliyorsa ya da bekletiliyorsa (hold_toasts) sırasını bekler (rütbe atlama,
## kova dolu gibi ikincil haberler). sound: göründüğü an çalan ses (titreşimiyle; "" = yok);
## icon: yazının yanındaki GameIcon ("" = yok).
func toast_later(text: String, color: Color = UiKit.TEXT, sound: String = "", icon: String = "") -> void:
	_toast_queue.append([text, color, sound, icon])
	if _toast_age < 0.0 and _toast_hold <= 0.0:
		_show_queued()


func _show_queued() -> void:
	var next: Array = _toast_queue.pop_front()
	toast(str(next[0]), next[1], str(next[3]))
	var sound := str(next[2])
	if not sound.is_empty():
		Sounds.play(sound)
		Sounds.haptic(30)


## Olta suda mı: eylem ve ayarlar dışındaki düğmeler gizlenir (ekranın her yeri eylem).
func set_line_out(on: bool) -> void:
	for c in line_out_hidden:
		c.visible = not on


## Ortada kısa bir bildirim (metin hazır çevrilmiş gelir). icon: yanında GameIcon ("" = yok).
func toast(text: String, color: Color = UiKit.TEXT, icon: String = "") -> void:
	_toast.text = UiKit.upper(text)
	_toast.add_theme_color_override("font_color", color)
	_toast_icon.visible = not icon.is_empty()
	if not icon.is_empty():
		_toast_icon.kind = icon
	_toast_box.visible = true
	_toast_age = 0.0
	_toast_box.pivot_offset = _toast_box.size * 0.5


## Sıradaki bildirimleri bir süre bekletir (toast_later ile gelenler).
func hold_toasts(seconds: float) -> void:
	_toast_hold = maxf(_toast_hold, seconds)


## Çekişmede durum gizlenir (gerilim çubuğuna yer, dikkat balıkta).
func set_fighting(on: bool) -> void:
	_status.visible = not on


## Eylem düğmesinin işi: cast, retrieve, wait, hook, reel ya da "" (gizli).
func set_action(kind: String) -> void:
	if kind == _action_kind:
		return
	_action_kind = kind
	action_button.visible = not kind.is_empty()
	if ACTIONS.has(kind):
		var action: Array = ACTIONS[kind]
		_set_button(tr(str(action[0])), str(action[1]), action_color(kind))


## Eylem düğmesinin rengi.
static func action_color(kind: String) -> Color:
	match kind:
		"retrieve":
			return UiKit.NEUTRAL
		"wait":
			return UiKit.WAIT
		"hook":
			return UiKit.DANGER
		"reel":
			return UiKit.SUCCESS
	return UiKit.PRIMARY


## Oyunda sonradan görünen parlak düğme dokuları açılışta bir kez çizilir (her biri ~30-40 ms):
## ilk dürtme, VUR ve çekişme anında ya da ilk kartta takılma olmasın.
static func warm_styles() -> void:
	for kind: String in ACTIONS:
		UiKit.glossy(action_color(kind), false, 40)
		UiKit.glossy(action_color(kind), true, 40)
	# Balık kartının "Harika!" düğmesi.
	UiKit.button("", UiKit.SUCCESS).free()


func _set_button(text: String, icon_kind: String, color: Color) -> void:
	action_button.set_text(text)
	action_button.set_icon(icon_kind)
	action_button.set_color(color)


## Ekrandaki düğmeler (bot denetimi: boyut ve güvenli alan).
func buttons() -> Array[TouchButton]:
	return [book_button, settings_button, action_button]


# --- Kurulum ---------------------------------------------------------------------

func _frame() -> MarginContainer:
	var frame := MarginContainer.new()
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(frame)
	_frames.append(frame)
	return frame


func _build_top() -> void:
	_status = HBoxContainer.new()
	_status.add_theme_constant_override("separation", 14)
	_status.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_status.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	_status.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_frame().add_child(_status)
	_coins = _pill("coin")
	_bucket = _pill("bucket")
	_rank = _pill("star")
	_rank_bar = RankBar.new()
	_rank.get_parent().add_child(_rank_bar)
	var top_right := HBoxContainer.new()
	top_right.add_theme_constant_override("separation", 18)
	top_right.mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_right.size_flags_horizontal = Control.SIZE_SHRINK_END
	top_right.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	_frame().add_child(top_right)
	book_button = TouchButton.make("", "book", BOOK_COLOR, Vector2(132, 132), UiKit.SIZE_BODY, 84.0)
	book_button.pressed.connect(func() -> void: book_pressed.emit())
	top_right.add_child(book_button)
	# Olta sudayken ekranın her yeri eylem: defter düğmesi VUR dokunuşunu almasın.
	line_out_hidden.append(book_button)
	settings_button = TouchButton.make("", "settings", UiKit.NEUTRAL, Vector2(132, 132), UiKit.SIZE_BODY, 84.0)
	settings_button.pressed.connect(func() -> void: settings_pressed.emit())
	top_right.add_child(settings_button)
	tension_bar = TensionBar.new()
	tension_bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	tension_bar.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	tension_bar.visible = false
	_frame().add_child(tension_bar)


## Durum hapı: ikon + sayı (Luckiest Guy). Etiketi döndürür.
func _pill(icon_kind: String) -> Label:
	var pill := PanelContainer.new()
	pill.add_theme_stylebox_override("panel", UiKit.framed("pill", UiKit.pill_style(), 34.0))
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_status.add_child(pill)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	row.alignment = BoxContainer.ALIGNMENT_CENTER
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill.add_child(row)
	row.add_child(GameIcon.make(icon_kind, 58))
	var label := UiKit.title("0", UiKit.SIZE_BODY + 4)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)
	return label


func _build_bottom() -> void:
	_hint = PanelContainer.new()
	_hint.add_theme_stylebox_override("panel", UiKit.framed("pill", UiKit.pill_style(), 46.0))
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
	_face.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	row.add_child(_face)
	_face_icon = GameIcon.make("bobber", 64)
	row.add_child(_face_icon)
	_show_face()
	# Hap görseli krem: üstünde koyu mürekkep; görsel yoksa koyu hap üstünde açık yazı.
	_hint_label = UiKit.ink("", UiKit.SIZE_BODY) if ItemArt.frame("pill") != null else UiKit.label("", UiKit.SIZE_BODY)
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
	# Hata ayıklama FPS etiketi; video kaydında (Movie Maker, "movie" özelliği) gizli.
	_fps.visible = OS.is_debug_build() and not OS.has_feature("movie")
	_frame().add_child(_fps)


func _build_center() -> void:
	_toast_box = HBoxContainer.new()
	_toast_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_toast_box.add_theme_constant_override("separation", 16)
	_toast_box.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_toast_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_toast_box.visible = false
	_toast_icon = GameIcon.make("question", TOAST_ICON)
	_toast_icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_toast_icon.visible = false
	_toast_box.add_child(_toast_icon)
	_toast = UiKit.title("", 64, UiKit.TEXT, HORIZONTAL_ALIGNMENT_CENTER, 14)
	_toast.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_toast_box.add_child(_toast)
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
	box.add_child(_toast_box)
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


## Rütbe içindeki ilerleme: ince bir çubuk (sayının yanında).
class RankBar extends Control:
	var progress: float = 0.0

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		custom_minimum_size = Vector2(96, 18)
		size_flags_vertical = Control.SIZE_SHRINK_CENTER

	func _draw() -> void:
		var rect := Rect2(Vector2.ZERO, size)
		draw_rect(rect, Color(0.0, 0.0, 0.0, 0.35))
		draw_rect(Rect2(rect.position, Vector2(rect.size.x * clampf(progress, 0.0, 1.0), rect.size.y)), UiKit.ACCENT)


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
		_label.text = UiKit.upper(tr("UI_LET_GO")) if red else tr("UI_DISTANCE") % UiKit.format_float(distance)

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
