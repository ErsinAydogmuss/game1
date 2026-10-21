class_name DayPanel
extends Dialog
## "Bugün" paneli (Dalga 4; docs/gdd.md §10.5, §10.7): üst ortadaki saat çipine dokununca açılır (olta
## boştayken). Üç kart:
## - Şimdi: vaktin ikonu ve adı, saat, sonraki vakte kalan süre (gerçek dakika; panel açıkken saat durur);
## - Hava: bugünün ve yarının havası (önceden belli: gelir kuralı 4; yağmurlu günün gecesi fırtına, sisli
##   günde sis sabah ve gece);
## - Dede'yle çay: sonraki vakte geçilir (ücretsiz; tea_requested, main kararmayla geçer). İki çay arasında
##   en az bir balık tutulmalı (WorldState.can_tea): yoksa düğme pasif, Dede'nin sözü "Önce bir balık tut".
## - Göl sevgisi (çayın yanında): seviye, çubuk, Nadir+ payı, nasıl artar.
## - Dede'nin istekleri (rütbe 2'den sonra; Requests): yuva başına bir kart: ikon, ne istendiği, ilerleme
##   ("1/3"), ödül (para ve göl sevgisi), değiştir düğmesi (günde bir: reroll_requested); boş yuvada "Yarın yeni
##   istek". Biten istek kendiliğinden öder (main).
## - Dede'nin altın isteği (Gölün Sırrı; varsa): günlük kartların üstünde tek satırlık altın şerit (harita parçası,
##   ne istendiği, ilerleme, ödül); değiştirilmez.
## Yazılar refresh'te (her açılışta, o anki dilde); panel dil uygulanmadan önce kurulur.

signal tea_requested
signal reroll_requested(slot: int)

## Panelin genişliği (iki kart yan yana, altında çay ve sevgi, en altta üç istek; telefonda küçülmeden sığar).
const WIDTH := 1500.0
## Şimdi kartındaki vaktin ikonu, hava satırının ikonu, çay kartının ikonu.
const NOW_ICON := 140.0
const WEATHER_ICON := 76.0
const TEA_ICON := 110.0
const TEA_BUTTON := Vector2(340, 122)
## Hava satırında "Bugün" ve "Yarın" yazısının sütunu (iki satır hizalı dursun).
const DAY_COLUMN := 190.0
## Göl sevgisi kartının genişliği ve ikonu.
const LOVE_CARD := 470.0
const LOVE_ICON := 96.0
## İstek kartı: ikonu, yazının sütunu (iki satıra sığar: test_requests ve bot ölçer), yazının boyu, değiştir
## düğmesi.
const REQUEST_ICON := 64.0
const REQUEST_TEXT_W := 200.0
const REQUEST_TEXT_SIZE := 26
const REROLL_BUTTON := Vector2(122, 122)
const REROLL_ICON := 76.0
## Dede'nin altın isteği (Gölün Sırrı): günlük kartların üstünde tek satırlık altın şerit; yazının en geniş
## hâli (test_requests iki dilde ölçer) ve boyu.
const GOLDEN_TEXT_W := 720.0
const GOLDEN_TEXT_SIZE := 28
const GOLDEN_ICON := 64.0
const GOLDEN_EDGE := Color("#e0a015")
const GOLDEN_FILL := Color("#fff3c8")

var _cards: HBoxContainer
var _tea_box: HBoxContainer
var _requests_head: HBoxContainer
var _golden_box: VBoxContainer
var _requests_box: HBoxContainer
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
	_tea_box = HBoxContainer.new()
	_tea_box.add_theme_constant_override("separation", 20)
	body.add_child(_tea_box)
	_requests_head = HBoxContainer.new()
	_requests_head.add_theme_constant_override("separation", 16)
	body.add_child(_requests_head)
	_golden_box = VBoxContainer.new()
	body.add_child(_golden_box)
	_requests_box = HBoxContainer.new()
	_requests_box.name = "Requests"
	_requests_box.add_theme_constant_override("separation", 20)
	body.add_child(_requests_box)


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
	_tea_box.add_child(_love_card(db, save))
	Dialog.clear(_requests_head)
	Dialog.clear(_golden_box)
	Dialog.clear(_requests_box)
	var open := Requests.unlocked(db, save)
	_requests_head.visible = open
	_requests_box.visible = open
	var golden := Requests.golden(db, save)
	_golden_box.visible = open and not golden.is_empty()
	if not open:
		return
	if not golden.is_empty():
		_golden_box.add_child(_golden_card(db, golden))
	_requests_head.add_child(GameIcon.make("requests", 52))
	var title := _display(tr("UI_REQ_TITLE"), UiKit.SIZE_SMALL + 4, UiKit.INK)
	title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_requests_head.add_child(title)
	_requests_head.add_child(UiKit.spacer())
	var note := UiKit.ink(tr("UI_REQ_REROLL_USED") if Requests.rerolled_today(db, save) else tr("UI_REQ_REROLL_HINT"),
			24, UiKit.INK_SOFT)
	note.name = "RerollNote"
	note.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_requests_head.add_child(note)
	for slot in db.requests.slots:
		_requests_box.add_child(_request_card(db, save, slot))


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


## Göl sevgisi: kalp, seviye, seviye içindeki ilerleme, Nadir+ payı (seviye 1'de nasıl artar).
func _love_card(db: ContentDB, save: SaveData) -> Control:
	var panel := _card("LoveCard")
	panel.size_flags_horizontal = Control.SIZE_FILL
	panel.custom_minimum_size.x = LOVE_CARD
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	panel.add_child(row)
	var icon := GameIcon.make("love", LOVE_ICON)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon)
	var text := VBoxContainer.new()
	text.add_theme_constant_override("separation", 2)
	text.alignment = BoxContainer.ALIGNMENT_CENTER
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(text)
	var level := LakeLove.level(db.rules, save.love)
	text.add_child(_display(tr("UI_LOVE_LEVEL") % level, UiKit.SIZE_BODY - 4, UiKit.INK))
	var bar := BucketPanel.LoveBar.new()
	bar.custom_minimum_size = Vector2(280, 16)
	bar.progress = LakeLove.progress(db.rules, save.love)
	text.add_child(bar)
	var note := tr("UI_LOVE_HOW")
	if level > 1:
		note = tr("UI_LOVE_BONUS") % UiKit.format_percent((LakeLove.rare_bonus_pm(db.rules, level) - 1000) * 1000)
	var how := UiKit.ink(note, 24, UiKit.INK_SOFT)
	how.name = "LoveNote"
	how.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	how.max_lines_visible = 2
	text.add_child(how)
	return panel


## Dede'nin bir isteği: ikon, ne istendiği (en çok iki satır), ilerleme, ödül (para ve göl sevgisi) ve değiştir
## düğmesi (günde bir; biten ya da değiştirme hakkı kullanılmışsa pasif). Boş yuvada "Yarın yeni istek".
func _request_card(db: ContentDB, save: SaveData, slot: int) -> Control:
	var panel := _card("Request%d" % slot)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	panel.add_child(row)
	var r := Requests.find_slot(save, slot)
	if r.is_empty():
		var empty := UiKit.ink(tr("UI_REQ_EMPTY"), REQUEST_TEXT_SIZE, UiKit.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER)
		empty.name = "Empty"
		empty.custom_minimum_size.y = REROLL_BUTTON.y
		empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		empty.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(empty)
		return panel
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 4)
	left.alignment = BoxContainer.ALIGNMENT_CENTER
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(left)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 10)
	left.add_child(top)
	var icon := GameIcon.make(icon_of(db, r), REQUEST_ICON)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	top.add_child(icon)
	var text := UiKit.ink(text_of(db, r), REQUEST_TEXT_SIZE, UiKit.INK)
	text.name = "Text"
	text.custom_minimum_size.x = REQUEST_TEXT_W
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text.max_lines_visible = 2
	top.add_child(text)
	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 6)
	left.add_child(bottom)
	var progress := _display("%d/%d" % [int(r["progress"]), int(r["goal"])], 30, UiKit.PRIMARY)
	progress.name = "Progress"
	bottom.add_child(progress)
	bottom.add_child(UiKit.spacer())
	var reward: Dictionary = r["reward"]
	bottom.add_child(UiKit.icon_text("coin", UiKit.format_int(int(reward.get("coins", 0))), 34, 26))
	if int(reward.get("love", 0)) > 0:
		bottom.add_child(UiKit.icon_text("love", "+%d" % int(reward["love"]), 30, 26))
	var reroll := UiKit.button("", UiKit.SECONDARY, UiKit.SIZE_SMALL, REROLL_BUTTON)
	reroll.name = "Reroll%d" % slot
	reroll.disabled = not Requests.can_reroll(db, save, slot)
	reroll.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var arrows := GameIcon.make("reroll", REROLL_ICON, UiKit.TEXT)
	# Düğmenin ortasında (düğme kapsayıcı değil: çocuğun yerini kendimiz veririz).
	arrows.position = (REROLL_BUTTON - Vector2.ONE * REROLL_ICON) * 0.5
	arrows.modulate.a = 0.4 if reroll.disabled else 1.0
	reroll.add_child(arrows)
	reroll.pressed.connect(func() -> void:
		Sounds.play("ui_tap")
		reroll_requested.emit(slot))
	row.add_child(reroll)
	return panel


## Dede'nin altın isteği (Gölün Sırrı): tek satır: harita parçası, başlık, ne istendiği (GOLDEN_TEXT_W içinde;
## test_requests ölçer), ilerleme, ödül (para ve parça). Değiştirme düğmesi yok.
func _golden_card(db: ContentDB, r: Dictionary) -> Control:
	var panel := PanelContainer.new()
	panel.name = "Golden"
	var style := UiKit.card_style(GOLDEN_EDGE, 28, GOLDEN_FILL, 5)
	style.content_margin_left = 22.0
	style.content_margin_right = 22.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	panel.add_theme_stylebox_override("panel", style)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 14)
	panel.add_child(row)
	var icon := GameIcon.make("item:map_piece", GOLDEN_ICON)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon)
	var title := _display(tr("UI_GOLDEN_TITLE"), UiKit.SIZE_SMALL, GOLDEN_EDGE.darkened(0.25))
	title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(title)
	var text := UiKit.ink(text_of(db, r), GOLDEN_TEXT_SIZE, UiKit.INK)
	text.name = "Text"
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	text.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	row.add_child(text)
	var progress := _display("%d/%d" % [int(r["progress"]), int(r["goal"])], 30, UiKit.PRIMARY)
	progress.name = "Progress"
	progress.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(progress)
	var reward: Dictionary = r["reward"]
	row.add_child(UiKit.icon_text("coin", UiKit.format_int(int(reward.get("coins", 0))), 34, 26))
	row.add_child(UiKit.icon_text("item:map_piece", "+1", 40, 26))
	return panel


## İsteğin yazısı o anki dilde (Requests.describe: değerlerdeki yazılar da çevrilir).
static func text_of(db: ContentDB, request: Dictionary) -> String:
	var described := Requests.describe(db, request)
	var args: Array = []
	for value: Variant in described[1]:
		args.append(UiKit.translate(str(value)) if value is String else value)
	return UiKit.translate(str(described[0])) % args


## İsteğin ikonu: istenen tür, teknik, bölge, vakit, nadirlik, yağmur, bırakma, çöp ya da tuzak.
static func icon_of(db: ContentDB, request: Dictionary) -> String:
	var want: Dictionary = request["want"]
	match str(request["kind"]):
		"species", "size":
			return "fish:" + str(want.get("fish", ""))
		"technique":
			return "tech_" + str(want.get("technique", ""))
		"zone":
			return "zone:" + str(want.get("zone", ""))
		"phase":
			return "phase_" + str(want.get("phase", ""))
		"rare":
			return UiKit.rarity_icon(db, int(want.get("rarity", 0)))
		"rain":
			return "weather_rain"
		"release":
			return "release"
		"trash":
			return "item:boot"
		"trap":
			return "tech_trap"
		"secret":
			return "item:map_piece"
	return "requests"


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
