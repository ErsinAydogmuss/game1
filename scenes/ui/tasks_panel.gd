class_name TasksPanel
extends DayPanel
## Görevler paneli (testçi: "oyuna görevler eklenebilir": Dede'nin istekleri vardı ama saat çipinin ardında
## görünmüyordu): sağ üstteki Görevler düğmesiyle açılır (olta boştayken).
## - İlk adımlar (FirstSteps; bütün adımlar bitene kadar): iki sütun, her adım bir kart: ikon, ne yapılacağı,
##   yıldız (bitti) ya da boş yıldız; başlıkta "3/5". Rütbe 1'de beşi de (ilerleme görünsün); istekler açılınca
##   yalnızca bitmemişler (en çok iki sıra: altın istek şeridiyle de panel telefonda küçülmeden sığsın).
## - Dede'nin istekleri: Bugün panelindeki kartların aynısı (DayPanel'den: altın istek şeridi, yuva başına kart,
##   değiştir düğmesi: reroll_requested); rütbe 2'den önce kilitli kart ("Rütbe 2'de başlar", rütbe ilerlemesi).
## Yazılar refresh'te (her açılışta, o anki dilde).

## Panelin genişliği (Bugün paneliyle aynı) ve ilk adımların kartı.
const STEP_CARD := Vector2(724, 92)
const STEP_ICON := 64.0
const STEP_STAR := 56.0
const STEP_ICONS := {"catch": "fish", "sell": "sell", "buy": "shop", "zone": "map", "rank": "trophy"}

## Görevlerin gölü (main verir): bölge adımı gölün ilk bölgesinden başka bir bölgeye bakar.
var spot_id: String = ""

var _steps_head: HBoxContainer
var _steps: GridContainer
var _locked_box: VBoxContainer


func _build() -> void:
	set_header(tr("UI_TASKS_TITLE"), "requests", WIDTH)
	_steps_head = HBoxContainer.new()
	_steps_head.add_theme_constant_override("separation", 16)
	body.add_child(_steps_head)
	_steps = GridContainer.new()
	_steps.name = "Steps"
	_steps.columns = 2
	_steps.add_theme_constant_override("h_separation", 20)
	_steps.add_theme_constant_override("v_separation", 12)
	body.add_child(_steps)
	_requests_head = HBoxContainer.new()
	_requests_head.add_theme_constant_override("separation", 16)
	body.add_child(_requests_head)
	_golden_box = VBoxContainer.new()
	body.add_child(_golden_box)
	_requests_box = HBoxContainer.new()
	_requests_box.name = "Requests"
	_requests_box.add_theme_constant_override("separation", 20)
	body.add_child(_requests_box)
	_locked_box = VBoxContainer.new()
	_locked_box.name = "Locked"
	body.add_child(_locked_box)


func refresh() -> void:
	var db := GameState.db
	var save := GameState.save
	set_header(tr("UI_TASKS_TITLE"), "requests", WIDTH)
	# İlk adımlar (hepsi bitince kalkar).
	Dialog.clear(_steps_head)
	Dialog.clear(_steps)
	var steps_open := not FirstSteps.all_done(db, save, spot_id)
	var open := Requests.unlocked(db, save)
	_steps_head.visible = steps_open
	_steps.visible = steps_open
	if steps_open:
		_steps_head.add_child(GameIcon.make("star", 52))
		var title := _display(tr("UI_STEPS_TITLE"), UiKit.SIZE_SMALL + 4, UiKit.INK)
		title.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_steps_head.add_child(title)
		_steps_head.add_child(UiKit.spacer())
		var count := _display("%d/%d" % [FirstSteps.done_count(db, save, spot_id), FirstSteps.STEPS.size()], 30,
				UiKit.PRIMARY)
		count.name = "StepsCount"
		count.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		_steps_head.add_child(count)
		for id in FirstSteps.STEPS:
			var finished := FirstSteps.done(db, save, spot_id, id)
			if not (open and finished):
				_steps.add_child(_step_card(id, finished))
	# Dede'nin istekleri: Bugün panelindeki kartlar; rütbe 2'den önce kilitli kart.
	Dialog.clear(_requests_head)
	Dialog.clear(_golden_box)
	Dialog.clear(_requests_box)
	Dialog.clear(_locked_box)
	_requests_head.add_child(GameIcon.make("requests", 52))
	var head := _display(tr("UI_REQ_TITLE"), UiKit.SIZE_SMALL + 4, UiKit.INK)
	head.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_requests_head.add_child(head)
	_requests_head.add_child(UiKit.spacer())
	_requests_box.visible = open
	_locked_box.visible = not open
	var golden := Requests.golden(db, save)
	_golden_box.visible = open and not golden.is_empty()
	if not open:
		_locked_box.add_child(_locked_card(db, save))
		return
	if not golden.is_empty():
		_golden_box.add_child(_golden_card(db, golden))
	var note := UiKit.ink(tr("UI_REQ_REROLL_USED") if Requests.rerolled_today(db, save) else tr("UI_REQ_REROLL_HINT"),
			24, UiKit.INK_SOFT)
	note.name = "RerollNote"
	note.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_requests_head.add_child(note)
	for slot in db.requests.slots:
		_requests_box.add_child(_request_card(db, save, slot))


## İlk adımın kartı: ikon, ne yapılacağı (tek satır), yıldız (bitti) ya da boş yıldız.
func _step_card(id: String, finished: bool) -> Control:
	var panel := _card("Step_" + id)
	panel.custom_minimum_size = STEP_CARD
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	panel.add_child(row)
	var icon := GameIcon.make(str(STEP_ICONS.get(id, "star")), STEP_ICON)
	icon.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(icon)
	var text := UiKit.ink(tr(str(FirstSteps.STEP_KEYS.get(id, ""))), 30, UiKit.INK_SOFT if finished else UiKit.INK)
	text.name = "Text"
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	text.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	row.add_child(text)
	var star := GameIcon.make("star" if finished else "star_empty", STEP_STAR)
	star.name = "Done" if finished else "Open"
	star.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(star)
	if finished:
		panel.modulate = Color(1, 1, 1, 0.8)
	return panel


## Rütbe 2'den önce: istekler kilitli; ne zaman başladığı ve rütbenin ilerlemesi.
func _locked_card(db: ContentDB, save: SaveData) -> Control:
	var panel := _card("RequestsLocked")
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	panel.add_child(row)
	var lock := GameIcon.make("lock", 64)
	lock.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(lock)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(column)
	var text := UiKit.ink(tr("UI_TASKS_LOCKED") % db.requests.unlock_rank, 30, UiKit.INK)
	text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	column.add_child(text)
	var bar := Hud.RankBar.new()
	bar.custom_minimum_size = Vector2(420, 16)
	bar.progress = Rank.progress(db, save)
	column.add_child(bar)
	return panel
