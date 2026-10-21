class_name DayPanel
extends Dialog
## "Bugün" paneli (Dalga 4; docs/gdd.md §10.5, §10.7): üst ortadaki saat çipine dokununca açılır (olta
## boştayken). Üç kart:
## - Şimdi: vaktin ikonu ve adı, saat, sonraki vakte kalan süre (gerçek dakika; panel açıkken saat durur);
## - Hava: bugünün ve yarının havası (önceden belli: gelir kuralı 4; yağmurlu günün gecesi fırtına, sisli
##   günde sis sabah ve gece);
## - Dede'yle çay: sonraki vakte geçilir (ücretsiz; tea_requested, main kararmayla geçer). İki çay arasında
##   en az bir balık tutulmalı (WorldState.can_tea): yoksa düğme pasif, Dede'nin sözü "Önce bir balık tut".
## İleride (Dalga 4'ün 3. ve 4. adımı) göl sevgisi ve Dede'nin istekleri de burada. Yazılar refresh'te (her
## açılışta, o anki dilde); panel dil uygulanmadan önce kurulur.

signal tea_requested

## Panelin genişliği (iki kart yan yana, altta çay; telefonda küçülmeden sığar).
const WIDTH := 1300.0
## Şimdi kartındaki vaktin ikonu, hava satırının ikonu, çay kartının ikonu.
const NOW_ICON := 140.0
const WEATHER_ICON := 76.0
const TEA_ICON := 110.0
const TEA_BUTTON := Vector2(340, 122)
## Hava satırında "Bugün" ve "Yarın" yazısının sütunu (iki satır hizalı dursun).
const DAY_COLUMN := 190.0

var _cards: HBoxContainer
var _tea_box: VBoxContainer
## Başlıktaki günün hapı (yazısı refresh'te).
var _day_pill: PanelContainer
var _day_label: Label


func _build() -> void:
	set_header(tr("UI_DAY_TITLE"), "phase_morning", WIDTH)
	_day_pill = PanelContainer.new()
	_day_pill.add_theme_stylebox_override("panel", UiKit.pill_style(Color(0.18, 0.1, 0.04, 0.85)))
	_day_label = UiKit.title("", 44, UiKit.ACCENT, HORIZONTAL_ALIGNMENT_CENTER, 10)
	_day_pill.add_child(_day_label)
	header_extra.add_child(_day_pill)
	_cards = HBoxContainer.new()
	_cards.add_theme_constant_override("separation", 20)
	body.add_child(_cards)
	_tea_box = VBoxContainer.new()
	body.add_child(_tea_box)


func refresh() -> void:
	var db := GameState.db
	var rules := db.rules
	var save := GameState.save
	var phase := DayClock.phase(rules, save.clock_s)
	set_header(tr("UI_DAY_TITLE"), "phase_" + phase, WIDTH)
	_day_label.text = UiKit.upper(tr("UI_DAY_NUMBER") % (DayClock.day(rules, save.clock_s) + 1))
	Dialog.clear(_cards)
	_cards.add_child(_now_card(rules, save, phase))
	_cards.add_child(_weather_card(rules, save))
	Dialog.clear(_tea_box)
	_tea_box.add_child(_tea_card(rules, save))


## Şimdi: vaktin ikonu ve adı, saat ("18:24"), sonraki vakte kalan süre ("Geceye 3 dk").
func _now_card(rules: FishingRules, save: SaveData, phase: String) -> Control:
	var panel := _card("NowCard")
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	panel.add_child(row)
	var icon := GameIcon.make("phase_" + phase, NOW_ICON)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon)
	var text := VBoxContainer.new()
	text.add_theme_constant_override("separation", 0)
	text.alignment = BoxContainer.ALIGNMENT_CENTER
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text)
	text.add_child(_display(tr("PHASE_" + phase), UiKit.SIZE_TITLE, UiKit.PRIMARY))
	var clock := _display(DayClock.clock_text(rules, save.clock_s), 46, UiKit.INK)
	clock.name = "Clock"
	text.add_child(clock)
	var next := DayClock.next_phase(rules, save.clock_s)
	var until := UiKit.ink(tr("UI_DAY_UNTIL_" + next) % duration_text(DayClock.phase_left_s(rules, save.clock_s)),
			UiKit.SIZE_SMALL, UiKit.INK_SOFT)
	until.name = "Until"
	text.add_child(until)
	return panel


## Hava: bugünün ve yarının havası (ikon, adı, gerekirse ne zaman: yağmurlu günün gecesi fırtına, sisli
## günde sabah ve gece).
func _weather_card(rules: FishingRules, save: SaveData) -> Control:
	var panel := _card("WeatherCard")
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(column)
	var days := Weather.forecast(rules, save, 2)
	for i in days.size():
		var row := HBoxContainer.new()
		row.name = "Day%d" % i
		row.add_theme_constant_override("separation", 16)
		column.add_child(row)
		var when := _display(tr("UI_DAY_TODAY" if i == 0 else "UI_DAY_TOMORROW"), UiKit.SIZE_SMALL, UiKit.INK_SOFT)
		when.custom_minimum_size.x = DAY_COLUMN
		when.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(when)
		var kind := days[i]
		var icon := GameIcon.make("weather_" + kind, WEATHER_ICON)
		icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(icon)
		var text := VBoxContainer.new()
		text.add_theme_constant_override("separation", -6)
		text.alignment = BoxContainer.ALIGNMENT_CENTER
		text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(text)
		text.add_child(UiKit.ink(tr("WEATHER_" + kind), UiKit.SIZE_BODY, UiKit.INK))
		var detail := weather_detail(kind)
		if not detail.is_empty():
			text.add_child(UiKit.ink(tr(detail), 26, UiKit.INK_SOFT))
	return panel


## Dede'yle çay: ikon, ne olacağı ("Çay demlenirken gece olur.") ya da neden içilemediği ("Önce bir balık
## tut..."), ÇAY İÇ düğmesi (içilemezse pasif).
func _tea_card(rules: FishingRules, save: SaveData) -> Control:
	var panel := _card("TeaCard")
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	panel.add_child(row)
	var icon := GameIcon.make("tea", TEA_ICON)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon)
	var text := VBoxContainer.new()
	text.add_theme_constant_override("separation", 0)
	text.alignment = BoxContainer.ALIGNMENT_CENTER
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text)
	text.add_child(_display(tr("UI_TEA_TITLE"), UiKit.SIZE_BODY, UiKit.INK))
	var can := WorldState.can_tea(save)
	var note := UiKit.ink(tr("UI_TEA_TO_" + DayClock.next_phase(rules, save.clock_s)) if can else tr("UI_TEA_WAIT"),
			28, UiKit.INK_SOFT)
	note.name = "TeaNote"
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note.max_lines_visible = 2
	text.add_child(note)
	var button := UiKit.button(tr("UI_TEA_BUTTON"), UiKit.SUCCESS, UiKit.SIZE_SMALL + 4, TEA_BUTTON)
	button.name = "TeaButton"
	button.disabled = not can
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.pressed.connect(func() -> void:
		Sounds.play("ui_tap")
		close_panel()
		tea_requested.emit())
	row.add_child(button)
	return panel


## Çay düğmesi (bot denetimi).
func tea_button() -> Button:
	return find_child("TeaButton", true, false) as Button


## Kalan sürenin yazısı: bir dakikadan uzunsa yukarı yuvarlanmış dakika ("3 dk"), yoksa saniye ("45 sn").
## Saat oyun saniyesiyle akar: bir oyun vakti 6 gerçek dakika.
static func duration_text(seconds: int) -> String:
	if seconds >= 60:
		return UiKit.translate("UI_MINUTES") % ceili(seconds / 60.0)
	return UiKit.translate("UI_SECONDS") % maxi(1, seconds)


## Havanın ne zaman olduğu (çeviri anahtarı; yoksa ""): yağmurlu günün gecesi fırtınalı, sisli günde sis
## sabah ve gece (öğle ve akşam bulutlu: Weather.at).
static func weather_detail(kind: String) -> String:
	match kind:
		"rain":
			return "UI_DAY_DETAIL_rain"
		"fog":
			return "UI_DAY_DETAIL_fog"
	return ""


## Krem kart (iki kart yan yana eşit pay alır).
func _card(id: String) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.name = id
	var style := UiKit.card_style(UiKit.CREAM_EDGE, 28, UiKit.CREAM_CARD, 4)
	style.content_margin_left = 26.0
	style.content_margin_right = 22.0
	style.content_margin_top = 14.0
	style.content_margin_bottom = 14.0
	panel.add_theme_stylebox_override("panel", style)
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return panel


## Krem kart üstündeki başlık yazısı: Luckiest Guy, büyük harf, mürekkep renginde (dış çizgisiz).
static func _display(text: String, size: int, color: Color) -> Label:
	var label := UiKit.ink(UiKit.upper(text), size, color)
	label.add_theme_font_override("font", UiKit.display_font())
	return label
