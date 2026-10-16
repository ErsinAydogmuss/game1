class_name FishCard
extends Control
## Yakalanan balığın kartı: yeni tür, yeni rekor ya da Nadir ve üstü için açılır (Records.wants_card).
## Açıkken oyun bekler ("modal": atış yok); kısa bir süre sonra dokununca ya da düğmeyle kapanır.
## Kart, kart açıkken başlayan bir dokunuşun parmağı kalkınca kapanır: basışta kapansaydı aynı
## dokunuş (Godot dokunuştan önce taklit fare olayını işler) arkadaki suya atış da yapardı;
## çekerken basılı kalan parmağın kalkması da kartı kapatmaz.
## İçerik: nadirlik, balığın resmi (Ersin'in görseli gelene kadar renkli madalyon), adı, boyu,
## yıldızları, kısa tanımı ve "Yeni tür!" / "Yeni rekor!" şeritleri. Destansı ve üstünde konfeti.
## Süreler _process(delta) toplamıyla ölçülür.

signal closed

## Bu kadar sn geçmeden dokunuş kartı kapatmaz (çekerken basılı kalan parmak kapatmasın).
const MIN_OPEN := 0.6
const CONFETTI_COLORS: Array[Color] = [Color("#ffcf3c"), Color("#ff5a7a"), Color("#4fd2ff"), Color("#7cf06a"), Color("#c47bff"), Color.WHITE]

var ok_button: Button

var _card: PanelContainer
var _age: float = 0.0
## Kart açıkken (MIN_OPEN'dan sonra) bir basış oldu: parmak kalkınca kapanır.
var _armed: bool = false


func _ready() -> void:
	theme = UiKit.theme()
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	add_to_group("modal")
	var dim := ColorRect.new()
	dim.color = Color(0.02, 0.02, 0.05, 0.55)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(dim)
	hide()


## info: FishingSession.last_catch; outcome: Records.add sonucu.
func show_catch(db: ContentDB, info: Dictionary, outcome: Dictionary) -> void:
	if _card != null:
		_card.queue_free()
	var rarity := int(info["rarity"])
	var color := UiKit.rarity_color(db, rarity)
	var fish_id := str(info["fish"])
	_card = PanelContainer.new()
	var sb := UiKit.card_style(color, 44, UiKit.CREAM, 10)
	sb.set_content_margin_all(34)
	sb.shadow_color = Color(color, 0.55)
	sb.shadow_size = 38
	# Ersin'in nadirlik çerçevesi varsa o (arayüz kiti), yoksa nadirlik renginde kenar.
	_card.add_theme_stylebox_override("panel", UiKit.framed("frame_" + db.rarity_id(rarity), sb, 72.0))
	_card.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 10)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_card.add_child(column)
	var badges := HBoxContainer.new()
	badges.alignment = BoxContainer.ALIGNMENT_CENTER
	badges.add_theme_constant_override("separation", 14)
	badges.add_child(UiKit.rarity_badge(db, rarity, 40))
	if bool(outcome.get("new_species", false)):
		badges.add_child(_pill(tr("UI_NEW_SPECIES"), UiKit.SUCCESS))
	elif bool(outcome.get("new_record", false)):
		badges.add_child(_pill(tr("UI_NEW_RECORD"), UiKit.SECONDARY))
	column.add_child(badges)
	var art := TextureRect.new()
	art.texture = ItemArt.fish(fish_id)
	art.custom_minimum_size = Vector2(300, 300)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(art)
	column.add_child(UiKit.title(tr("FISH_" + fish_id), 84, color.lightened(0.05), HORIZONTAL_ALIGNMENT_CENTER, 14))
	var size_row := HBoxContainer.new()
	size_row.alignment = BoxContainer.ALIGNMENT_CENTER
	size_row.add_theme_constant_override("separation", 22)
	size_row.add_child(UiKit.title(tr("UI_SIZE_CM") % int(info["size_cm"]), 60, UiKit.INK, HORIZONTAL_ALIGNMENT_CENTER, 0))
	size_row.add_child(UiKit.stars(int(info["stars"]), 52.0))
	column.add_child(size_row)
	var desc := UiKit.ink(tr("FISH_%s_DESC" % fish_id), UiKit.SIZE_BODY, UiKit.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.custom_minimum_size = Vector2(900, 0)
	column.add_child(desc)
	ok_button = UiKit.button(tr("UI_CARD_OK"), UiKit.SUCCESS, UiKit.SIZE_TITLE, Vector2(420, 130))
	ok_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	# Kart görülmeden kapanmasın: düğme de en kısa açık kalma süresine uyar.
	ok_button.pressed.connect(func() -> void:
		if _age >= MIN_OPEN:
			close_card())
	column.add_child(ok_button)
	add_child(_card)
	show()
	_age = 0.0
	_armed = false
	_card.reset_size()
	_card.position = (size - _card.size) * 0.5
	_card.pivot_offset = _card.size * 0.5
	_card.scale = Vector2(0.4, 0.4)
	_card.modulate.a = 0.0
	var tween := _card.create_tween().set_parallel(true).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(_card, "scale", Vector2.ONE, 0.35)
	tween.tween_property(_card, "modulate:a", 1.0, 0.15)
	Sounds.play("card")
	if rarity >= db.rarity_index("epic"):
		_confetti(size * 0.5, 120 if rarity >= db.rarities.size() - 1 else 70)
		Sounds.haptic(160)


func close_card() -> void:
	if not visible:
		return
	hide()
	if _card != null:
		_card.queue_free()
		_card = null
	closed.emit()


func _process(delta: float) -> void:
	if visible:
		_age += delta
		if _card != null:
			_card.position = (size - _card.size) * 0.5


func _gui_input(event: InputEvent) -> void:
	var press := event is InputEventScreenTouch or event is InputEventMouseButton
	if not press:
		return
	accept_event()
	if event.is_pressed():
		if _age >= MIN_OPEN:
			_armed = true
	elif _armed:
		close_card()


func _pill(text: String, color: Color) -> PanelContainer:
	var pill := PanelContainer.new()
	var sb := UiKit.flat(color, 30)
	sb.content_margin_left = 20
	sb.content_margin_right = 20
	sb.content_margin_top = 4
	sb.content_margin_bottom = 2
	pill.add_theme_stylebox_override("panel", sb)
	pill.add_child(UiKit.title(text, 34, UiKit.TEXT, HORIZONTAL_ALIGNMENT_CENTER, 6))
	return pill


func _confetti(at: Vector2, amount: int) -> void:
	var particles := CPUParticles2D.new()
	particles.position = at
	particles.amount = amount
	particles.one_shot = true
	particles.explosiveness = 0.92
	particles.lifetime = 2.2
	particles.direction = Vector2(0, -1)
	particles.spread = 75.0
	particles.initial_velocity_min = 650.0
	particles.initial_velocity_max = 1250.0
	particles.gravity = Vector2(0, 1500)
	particles.angular_velocity_min = -540.0
	particles.angular_velocity_max = 540.0
	particles.scale_amount_min = 10.0
	particles.scale_amount_max = 18.0
	var ramp := Gradient.new()
	var offsets := PackedFloat32Array()
	var colors := PackedColorArray()
	for i in CONFETTI_COLORS.size():
		offsets.append(float(i) / (CONFETTI_COLORS.size() - 1))
		colors.append(CONFETTI_COLORS[i])
	ramp.offsets = offsets
	ramp.colors = colors
	ramp.interpolation_mode = Gradient.GRADIENT_INTERPOLATE_CONSTANT
	particles.color_initial_ramp = ramp
	add_child(particles)
	particles.emitting = true
	get_tree().create_timer(2.6).timeout.connect(particles.queue_free)
