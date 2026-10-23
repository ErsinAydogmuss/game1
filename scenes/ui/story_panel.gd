class_name StoryPanel
extends Control
## Açılış filminin örtüsü (docs/gdd.md §10.5). FishCard gibi "modal" örtü, Dialog değil: göl arkada
## yaşar (main'in _process'i sürer, kamerayı StoryFilm sürer), oyun girdisi kapalıdır. Sinema
## şeritleri (üstte ve altta), başta oyunun logosu, altta konuşanın portresi (Dede ya da Nine; sözün
## ifadesiyle: Moods), adı ve en çok iki satır yazı. Dokununca (parmak kalkınca) sonraki söz; söz
## kendiliğinden de ilerler. Sağ üstte ATLA (güvenli alanda, 122 boy). Son sözde hediye rozeti:
## bambu kamışın resmi ve "Dede'nin ilk oltası". Süreler _process(delta) toplamıyla. Bitiş filmi de aynı örtüyle
## (play(Story.ENDING, false): logosuz başlar).
## line_started(sıra): main o sözün çekimine geçer; finished(atlandı mı): film bitti.

signal line_started(index: int)
signal finished(skipped: bool)

## Şeritlerin boyu (ekran yüksekliğinin oranı).
const BAR := 0.1
## Yazının boyu, adın boyu, yazı kutusunun genişliği ve konuşanın yüzü (test_story iki dilde ölçer).
const TEXT_SIZE := 44
const NAME_SIZE := 34
const BOX_WIDTH := 1500.0
const FACE := 150.0
const BOX_GAP := 24
## Logonun ekranda kaldığı süre (sn; sözlerinki Story.line_time).
const LOGO_TIME := 2.4
## Yeni söz bu kadar sn dolmadan dokunuşla geçmez (art arda iki dokunuş iki söz atlamasın).
const TAP_GUARD := 0.45
const SKIP_SIZE := Vector2(260, 122)
const GIFT_ICON := 200.0
## Hediye rozetinin ortası ekran genişliğinin bu kadarında.
const GIFT_AT := 0.76
## Konuşanların adının anahtarı.
const NAMES := { "dede": "UI_STORY_DEDE", "nine": "UI_STORY_NINE" }

var skip_button: Button
## true iken film durur (odak kaybı: main verir).
var held: bool = false

var _top: ColorRect
var _bottom: ColorRect
var _logo: Control
var _box: PanelContainer
var _face: TextureRect
var _name: Label
var _text: Label
var _gift: Control
## Filmin sözleri (Story.LINES ya da Story.ENDING).
var _lines: Array[Array] = Story.LINES
var _index: int = -1
## Logo, sözler; sözün ne kadar sürdüğü ve kalan süresi (sn).
var _in_logo: bool = false
var _age: float = 0.0
var _left: float = 0.0
## Basılan dokunuş parmak kalkınca sözü geçirir.
var _armed: bool = false
var _bars: float = 0.0


func _ready() -> void:
	theme = UiKit.theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_to_group("modal")
	_top = _bar()
	_bottom = _bar()
	_logo = _build_logo()
	add_child(_logo)
	_box = _build_box()
	add_child(_box)
	_gift = _build_gift()
	add_child(_gift)
	skip_button = UiKit.button("", UiKit.NEUTRAL, UiKit.SIZE_SMALL, SKIP_SIZE)
	skip_button.name = "Skip"
	skip_button.pressed.connect(func() -> void:
		Sounds.play("ui_tap")
		_finish(true))
	add_child(skip_button)
	get_viewport().size_changed.connect(_layout)
	hide()


## Film baştan: logo (logo verilirse), sonra sözler (lines).
func play(lines: Array[Array] = Story.LINES, logo: bool = true) -> void:
	_lines = lines
	_index = -1
	_in_logo = logo
	_age = 0.0
	_left = LOGO_TIME if logo else 0.6
	_armed = false
	_bars = 0.0
	_logo.visible = logo
	_logo.modulate.a = 0.0
	_box.visible = false
	_gift.visible = false
	show()
	_refresh_texts()


## Oynayan filmin sözleri.
func lines() -> Array[Array]:
	return _lines


## Şu anki sözün sırası (logodayken -1).
func index() -> int:
	return _index


## Film yarıda kesildi (kayıt değişti): örtü gizlenir, finished yayılmaz.
func stop() -> void:
	hide()


func _process(delta: float) -> void:
	if not visible or held:
		return
	_age += delta
	_left -= delta
	_bars = minf(1.0, _bars + delta * 2.5)
	_layout_bars()
	_place_box()
	if _in_logo:
		_logo.modulate.a = clampf(minf(_age / 0.6, (_left) / 0.5), 0.0, 1.0)
	else:
		_box.modulate.a = clampf(_age / 0.3, 0.0, 1.0)
		if _gift.visible:
			var grow := clampf(_age / 0.35, 0.0, 1.0)
			_gift.pivot_offset = _gift.size * 0.5
			_gift.scale = Vector2.ONE * (0.4 + 0.6 * grow + 0.04 * sin(_age * 5.0))
	if _left <= 0.0:
		_next()


func _gui_input(event: InputEvent) -> void:
	var press := event is InputEventScreenTouch or event is InputEventMouseButton
	if not press:
		return
	accept_event()
	if event.is_pressed():
		_armed = true
	elif _armed:
		_armed = false
		if _age >= TAP_GUARD:
			_next()


func _next() -> void:
	_in_logo = false
	_logo.visible = false
	_index += 1
	if _index >= _lines.size():
		_finish(false)
		return
	var line: Array = _lines[_index]
	var speaker := str(line[1])
	_face.texture = Moods.face(speaker, str(line[0]))
	_face.visible = _face.texture != null
	_refresh_texts()
	_box.visible = true
	_box.modulate.a = 0.0
	_gift.visible = str(line[2]) == "gift"
	_age = 0.0
	_left = Story.line_time(_index, _text.text, _lines)
	Sounds.play("hint")
	line_started.emit(_index)


## Yazılar o anki dilde (film açılırken dil henüz uygulanmamış olabilir: dil değişince yenilenir).
func _refresh_texts() -> void:
	skip_button.text = UiKit.upper(tr("UI_INTRO_SKIP"))
	if _index >= 0 and _index < _lines.size():
		var line: Array = _lines[_index]
		_name.text = UiKit.upper(tr(str(NAMES[str(line[1])])))
		_text.text = tr(str(line[0]))
	_layout()


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSLATION_CHANGED and skip_button != null and visible:
		_refresh_texts()


func _finish(skipped: bool) -> void:
	if not visible:
		return
	hide()
	finished.emit(skipped)


func _bar() -> ColorRect:
	var r := ColorRect.new()
	r.color = Color(0.02, 0.02, 0.04, 1.0)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(r)
	return r


func _build_logo() -> Control:
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var art := ItemArt.art("logo.png")
	if art != null:
		var rect := TextureRect.new()
		rect.texture = art
		rect.custom_minimum_size = Vector2(760, 420)
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		center.add_child(rect)
	else:
		center.add_child(UiKit.title(tr("UI_GAME_TITLE"), UiKit.SIZE_HERO))
	return center


## Alttaki kutu: konuşanın yüzü, adı ve sözü (krem hap, ipucu çubuğu gibi).
func _build_box() -> PanelContainer:
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", Hud.hint_style())
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", BOX_GAP)
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(row)
	_face = TextureRect.new()
	_face.custom_minimum_size = Vector2(FACE, FACE)
	_face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_face.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(_face)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 0)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(column)
	_name = UiKit.title("", NAME_SIZE, UiKit.ACCENT, HORIZONTAL_ALIGNMENT_LEFT, 8)
	column.add_child(_name)
	_text = UiKit.ink("", TEXT_SIZE)
	_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_text.custom_minimum_size = Vector2(text_width(), 0)
	column.add_child(_text)
	return box


## Sözün yazısına kalan genişlik (kutunun genişliğinden yüz, boşluk ve hapın payları çıkar).
static func text_width() -> float:
	var pill := Hud.hint_style()
	return BOX_WIDTH - FACE - BOX_GAP - pill.get_margin(SIDE_LEFT) - pill.get_margin(SIDE_RIGHT)


func _build_gift() -> Control:
	var column := VBoxContainer.new()
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 6)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var art := ItemArt.gear("rod_bamboo")
	if art != null:
		var rect := TextureRect.new()
		rect.texture = art
		rect.custom_minimum_size = Vector2(GIFT_ICON, GIFT_ICON)
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rect.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
		column.add_child(rect)
	else:
		column.add_child(GameIcon.make("rod", GIFT_ICON))
	var label := UiKit.title("", UiKit.SIZE_TITLE, UiKit.ACCENT, HORIZONTAL_ALIGNMENT_CENTER, 10)
	label.name = "GiftLabel"
	column.add_child(label)
	return column


func _layout() -> void:
	if not is_inside_tree():
		return
	var view := get_viewport_rect().size
	var inset := UiKit.safe_insets(self)
	_layout_bars()
	skip_button.size = SKIP_SIZE
	skip_button.position = Vector2(view.x - inset.z - Hud.MARGIN - SKIP_SIZE.x, inset.y + Hud.MARGIN)
	(_gift.find_child("GiftLabel", true, false) as Label).text = UiKit.upper(tr("UI_INTRO_GIFT"))
	_place_box()


## Söz kutusu altta ortada (boyu sözün satırıyla; autowrap'lı yazının boyu genişliği belli olunca doğru
## çıkar: her kare yeniden), hediye rozeti sağda, şeritle kutunun arasında (ortada balıkçı ve Dede).
func _place_box() -> void:
	if not is_inside_tree():
		return
	var view := get_viewport_rect().size
	var inset := UiKit.safe_insets(self)
	var bar := view.y * BAR
	_box.reset_size()
	var box := _box.get_combined_minimum_size()
	_box.size = Vector2(maxf(box.x, BOX_WIDTH), box.y)
	_box.position = Vector2((view.x - _box.size.x) * 0.5, view.y - bar - _box.size.y - 18.0 - inset.w * 0.5)
	_gift.reset_size()
	_gift.size = _gift.get_combined_minimum_size()
	_gift.position = Vector2(view.x * GIFT_AT - _gift.size.x * 0.5,
			maxf(bar + 8.0, (bar + _box.position.y - _gift.size.y) * 0.5))


## Sinema şeritleri açılışta yukarıdan ve aşağıdan kayarak gelir.
func _layout_bars() -> void:
	var view := get_viewport_rect().size
	var h := view.y * BAR * _bars
	_top.position = Vector2.ZERO
	_top.size = Vector2(view.x, h)
	_bottom.position = Vector2(0.0, view.y - h)
	_bottom.size = Vector2(view.x, h)
