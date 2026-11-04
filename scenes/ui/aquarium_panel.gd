class_name AquariumPanel
extends Dialog
## Akvaryum (Dalga 5, docs/gdd.md §10.6): Nine'nin tezgâhındaki tanka dokununca açılır. Solda canlı tank
## (AquariumTank: her tutulmuş türün en irisi yüzer), sağda tür sayısı ("12/15 tür"), ziyaretçilerin saatlik
## bağışı, bağış kutusundaki para (gerçek saatle dolar, en çok 2 saatlik) ve TOPLA; altta tanka kimin girdiği.
## Kutu panel açıkken her saniye yenilenir. TOPLA'yı main işler (dükkândaki kendiliğinden toplamayla aynı yol).
## Reklamlar (AdRules.AQUARIUM): kutuda yeterince para varken alt satırda "Reklam izle: 2 katı topla"; reklam sonuna
## kadar izlenirse ad_rewarded (main kutuyu toplar, aynı parayı bir kez daha verir).

signal collect_requested
## Akvaryumun reklamı sonuna kadar izlendi: kutu 2 katıyla toplansın.
signal ad_rewarded

const WIDTH := 1500.0
## Tank ve yan sütun: sütun tanktan uzun olmasın (satırın boyu ikisinin büyüğü; telefonda panel küçülmeden sığsın).
const TANK := Vector2(940, 470)
const SIDE_W := 420.0
const BUTTON := Vector2(330, 122)
## Alt satırın reklam teklifi (notun yanında; satırın boyu hep düğmeninki: teklif gelip gidince panel oynamasın).
const AD_OFFER := Vector2(560, 122)

var _tank: AquariumTank
var _count: Label
var _species: Label
var _rate: Label
var _box_title: Label
var _box: Label
var _cap: Label
var _collect: Button
var _note: Label
var _coins: HBoxContainer
var _clock := 0.0
## Reklam teklifi (bot) ve reklam açık mı.
var ad_button: Button
var _ad_busy: bool = false


func _build() -> void:
	set_header(tr("UI_AQUARIUM"), "aquarium", WIDTH)
	_coins = HBoxContainer.new()
	header_extra.add_child(_coins)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 28)
	body.add_child(row)
	_tank = AquariumTank.new()
	_tank.name = "Tank"
	_tank.custom_minimum_size = TANK
	row.add_child(_tank)
	var side := VBoxContainer.new()
	side.custom_minimum_size = Vector2(SIDE_W, 0)
	side.add_theme_constant_override("separation", 14)
	row.add_child(side)
	# Tür sayısı ve saatlik bağış.
	var count_card := Dialog.card(side)
	count_card.add_theme_constant_override("separation", 4)
	var count_row := HBoxContainer.new()
	count_row.alignment = BoxContainer.ALIGNMENT_CENTER
	count_row.add_theme_constant_override("separation", 12)
	count_card.add_child(count_row)
	_count = UiKit.title("", 64, UiKit.PRIMARY)
	count_row.add_child(_count)
	_species = UiKit.ink("", UiKit.SIZE_SMALL, UiKit.INK)
	_species.size_flags_vertical = Control.SIZE_SHRINK_END
	count_row.add_child(_species)
	_rate = UiKit.ink("", UiKit.SIZE_SMALL - 2, UiKit.INK)
	_rate.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_rate.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_rate.custom_minimum_size = Vector2(SIDE_W - 40.0, 0)
	count_card.add_child(_rate)
	# Bağış kutusu: ikon, ad ve para; üst sınır; TOPLA.
	var box_card := Dialog.card(side)
	(box_card.get_parent() as Control).size_flags_vertical = Control.SIZE_EXPAND_FILL
	box_card.alignment = BoxContainer.ALIGNMENT_CENTER
	box_card.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var box_row := HBoxContainer.new()
	box_row.alignment = BoxContainer.ALIGNMENT_CENTER
	box_row.add_theme_constant_override("separation", 14)
	box_card.add_child(box_row)
	box_row.add_child(GameIcon.make("donation_box", 84))
	var box_text := VBoxContainer.new()
	box_text.add_theme_constant_override("separation", -6)
	box_row.add_child(box_text)
	_box_title = UiKit.ink("", UiKit.SIZE_SMALL - 2, UiKit.INK)
	box_text.add_child(_box_title)
	_box = UiKit.title("", 60, UiKit.ACCENT, HORIZONTAL_ALIGNMENT_LEFT, 10)
	_box.name = "Box"
	box_text.add_child(_box)
	_cap = UiKit.ink("", UiKit.SIZE_SMALL - 4, UiKit.INK)
	_cap.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_cap.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_cap.custom_minimum_size = Vector2(SIDE_W - 40.0, 0)
	box_card.add_child(_cap)
	var center := CenterContainer.new()
	box_card.add_child(center)
	_collect = UiKit.button("", UiKit.SUCCESS, UiKit.SIZE_SMALL + 4, BUTTON)
	_collect.name = "Button_collect"
	_collect.pressed.connect(func() -> void:
		Sounds.play("ui_tap")
		collect_requested.emit())
	center.add_child(_collect)
	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 24)
	foot.custom_minimum_size = Vector2(TANK.x + SIDE_W + 28.0, 0)
	body.add_child(foot)
	_note = UiKit.ink("", UiKit.SIZE_SMALL - 4, UiKit.INK)
	_note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_note.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_note.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_note.custom_minimum_size = Vector2(TANK.x + SIDE_W + 28.0 - AD_OFFER.x - 24.0, 0)
	foot.add_child(_note)
	ad_button = AdOffer.button("", AD_OFFER, UiKit.SIZE_SMALL)
	ad_button.pressed.connect(_watch_ad)
	foot.add_child(ad_button)


## Yazılar her açılışta o anki dilde (panel, dil uygulanmadan önce kurulur); kutu her saniye yenilenir.
func refresh() -> void:
	set_header(tr("UI_AQUARIUM"), "aquarium", WIDTH)
	var db := GameState.db
	var save := GameState.save
	var tank := Aquarium.fish(db, save)
	_tank.show_fish(tank, db)
	_count.text = "%d/%d" % [tank.size(), Aquarium.capacity(db)]
	_species.text = tr("UI_AQUARIUM_SPECIES")
	_rate.text = tr("UI_AQUARIUM_RATE") % UiKit.format_int(Aquarium.rate_of(db.rules, tank))
	_box_title.text = tr("UI_AQUARIUM_BOX")
	_refresh_box()
	_collect.text = UiKit.upper(tr("UI_AQUARIUM_COLLECT"))
	_note.text = tr("UI_AQUARIUM_NOTE")
	Dialog.clear(_coins)
	_coins.add_child(Dialog.coin_pill(save.coins))


func _refresh_box() -> void:
	var db := GameState.db
	var save := GameState.save
	var now := GameState.clock.now_unix()
	var pending := Aquarium.pending(db, save, now)
	_box.text = UiKit.format_int(pending)
	var hours := maxi(1, roundi(db.rules.aquarium_cap_s / 3600.0))
	_cap.text = tr("UI_AQUARIUM_FULL") if Aquarium.is_full(db, save, now) else tr("UI_AQUARIUM_CAP") % hours
	_collect.disabled = pending <= 0 or _ad_busy
	# Reklam teklifi yalnızca kutuda yeterince para varken. Reklamı olan cihazda yeri hep tutulur (görünmez düğme):
	# satır teklif gelip gidince oynamaz; reklamsız cihazda not bütün satırı kaplar.
	ad_button.visible = Ads.available()
	var offer := _ad_busy or (AdRules.box_worth_offer(pending) and Ads.offer_ok(AdRules.AQUARIUM))
	ad_button.modulate.a = 1.0 if offer else 0.0
	ad_button.mouse_filter = Control.MOUSE_FILTER_STOP if offer else Control.MOUSE_FILTER_IGNORE
	ad_button.disabled = not offer or _ad_busy
	ad_button.text = UiKit.upper(tr("UI_AD_DOUBLE") % UiKit.format_int(pending))


## Reklam teklifi görünüyor mu (bot).
func ad_offered() -> bool:
	return ad_button.visible and ad_button.modulate.a > 0.5 and not ad_button.disabled


## Akvaryumun reklamı (AdRules.AQUARIUM): sonuna kadar izlenirse ad_rewarded (main kutuyu 2 katıyla toplar).
func _watch_ad() -> void:
	if not ad_offered():
		return
	_ad_busy = true
	_refresh_box()
	Sounds.play("ui_tap")
	var earned := await Ads.show_rewarded(AdRules.AQUARIUM)
	_ad_busy = false
	if earned:
		ad_rewarded.emit()
	if visible:
		refresh()


## Tankta yüzen balık sayısı (bot).
func swimmer_count() -> int:
	return _tank.swimmer_count()


func _process(delta: float) -> void:
	if not visible:
		return
	_clock += delta
	if _clock >= 1.0:
		_clock = 0.0
		_refresh_box()
