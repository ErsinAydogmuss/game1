extends Node3D
## Ana sahne: her şeyi bağlar. Göl (LakeScene), balıkçı (Angler), şamandıra, misina, gölgeler,
## kamera, arayüz ve balık tutma oturumu (FishingSession). Oyun mantığı oturumdadır; burası
## olayları dinleyip ses, titreşim, hareket ve yazıya çevirir. Her sesin bir görsel ve titreşim
## karşılığı vardır (iPhone'un sessiz anahtarı açık olabilir).
## Girdiyi InputRouter okur; --autoplay botu (yalnızca debug) gerçek dokunma olayları gönderir.

const SPOT := "home_lake"
## Olta sudayken kamera eğimi; çekişmede yakınlaşma.
const LINE_PITCH := deg_to_rad(60.0)
const FIGHT_ZOOM := 0.9
## Kartsız yakalayışta (tekrar eden balık) bildirimden sonra bu kadar sn içinde yeni atış serbest.
const QUICK_CATCH_TIME := 1.3
## Space ya da AT düğmesiyle balıkçının önüne atış uzaklığı (m).
const FORWARD_CAST := 6.0
## Dede'nin ipuçları bu kadar balık tutulana kadar görünür.
const HINT_CATCHES := 3
const STEP_SOUND_EVERY := 0.36
## İlk atıştan önce ilk av gölgesinin çevresinde halka aralığı (sn): "bu gölge!"
const FIRST_CUE_EVERY := 1.6

var session: FishingSession
var lake: LakeShape
var scene: LakeScene
var angler: Angler
var bobber: Bobber
var line: FishingLine
var shadows: ShadowLayer
var ripples: Ripples
var camera: FollowCamera
var input: InputRouter
var hud: Hud
var card: FishCard
var settings_panel: SettingsPanel

var _save_ref: SaveData
var _paused: bool = false
var _pending_cast := Dice.NO_POINT
var _quick_catch: float = -1.0
var _step_clock: float = 0.0
var _cue_clock: float = 0.0


func _ready() -> void:
	lake = GameState.db.lake(SPOT)
	scene = LakeScene.new()
	add_child(scene)
	scene.setup(lake)
	shadows = ShadowLayer.new()
	add_child(shadows)
	ripples = Ripples.new()
	add_child(ripples)
	angler = Angler.new()
	angler.lake = lake
	angler.height_at = scene.stand_height
	add_child(angler)
	bobber = Bobber.new()
	add_child(bobber)
	camera = FollowCamera.new()
	add_child(camera)
	line = FishingLine.new()
	line.camera = camera
	line.visible = false
	add_child(line)
	_build_ui()
	_build_input()
	_start_session()
	GameState.changed.connect(_on_state_changed)
	GameState.focus_lost.connect(_on_focus_lost)
	GameState.focus_gained.connect(func() -> void: _paused = false)
	ItemArt.register_fish_colors(GameState.db.fish_colors())
	Sounds.set_ambience("lake")
	if OS.is_debug_build() and OS.get_cmdline_user_args().has("--autoplay"):
		var bot: Node = load("res://scripts/dev/autoplay.gd").new()
		bot.set("main", self)
		add_child(bot)


## Kayda göre yeni bir oturum (yeni gölgeler); ilk balık tutulmadıysa ilk av senaryolu.
func _start_session() -> void:
	var save := GameState.save
	_save_ref = save
	var rod := save.rod if not GameState.db.rod(save.rod).is_empty() else "bamboo"
	session = FishingSession.new(GameState.db, SPOT, rod, Dice.derive(save.seed, save.session),
			bool(GameState.setting("easy", false)), save.catches == 0)
	angler.place(session.angler)
	angler.face(Vector2(0, -1))
	bobber.hide_bobber()
	line.visible = false
	_pending_cast = Dice.NO_POINT
	_quick_catch = -1.0
	camera.pitch = FollowCamera.PITCH
	camera.zoom = 1.0
	camera.snap(_focus())


func _on_state_changed() -> void:
	hud.refresh()
	if GameState.save != _save_ref:
		# Kayıt değişti (sıfırlama): göl baştan.
		if card.visible:
			card.close_card()
		_start_session()
		return
	session.easy = bool(GameState.setting("easy", false))


func _on_focus_lost() -> void:
	# Arama, Denetim Merkezi, arka plan: çekişme donar, parmak bırakılmış sayılır.
	_paused = true
	input.release_all()
	session.release()
	Sounds.set_loop("reel", false)
	Sounds.set_loop("strain", false)


func _process(delta: float) -> void:
	# Odak kaybında ve ayarlar açıkken oyun donar (çekişmedeki balık kaçmasın).
	if _paused or settings_panel.visible:
		return
	if session.state == FishingSession.State.IDLE:
		session.angler = angler.pos2()
	_check_pending_cast()
	session.advance(delta)
	for e in session.poll_events():
		_on_event(e)
	if _quick_catch >= 0.0:
		_quick_catch += delta
		if _quick_catch >= QUICK_CATCH_TIME:
			_quick_catch = -1.0
			session.acknowledge()
	_present(delta)


# --- Girdi -------------------------------------------------------------------------

func _build_input() -> void:
	input = InputRouter.new()
	input.lake = lake
	input.ground_point = ground_point
	input.line_out = func() -> bool: return session.line_out()
	add_child(input)
	input.walk_requested.connect(_on_walk_requested)
	input.cast_requested.connect(_on_cast_requested)
	input.action_pressed.connect(_on_action_down)
	input.action_released.connect(_on_action_up)
	input.walk_step.connect(func(dir: Vector2) -> void:
		_pending_cast = Dice.NO_POINT
		angler.step_dir(dir, get_process_delta_time()))


## Ekran noktasının göldeki karşılığı: önce iskele güvertesi, sonra su / zemin düzlemi.
func ground_point(screen: Vector2) -> Vector2:
	var origin := camera.project_ray_origin(screen)
	var dir := camera.project_ray_normal(screen)
	if absf(dir.y) < 0.0001:
		return Dice.NO_POINT
	var deck := (LakeScene.DOCK_HEIGHT + 0.04 - origin.y) / dir.y
	if deck > 0.0:
		var on_deck := origin + dir * deck
		var q := Vector2(on_deck.x, on_deck.z)
		if lake.on_dock(q):
			return q
	var t := -origin.y / dir.y
	if t <= 0.0:
		return Dice.NO_POINT
	var p := origin + dir * t
	return Vector2(p.x, p.z)


func _on_walk_requested(target: Vector2) -> void:
	if session.state != FishingSession.State.IDLE:
		return
	_pending_cast = Dice.NO_POINT
	angler.walk_to(target)


## Suya dokunuş: menzildeyse hemen atar; değilse önce yaklaşır (kıyıda durursa oradan atar).
func _on_cast_requested(target: Vector2) -> void:
	if session.state != FishingSession.State.IDLE:
		return
	if angler.pos2().distance_to(target) <= session.range_m() - 0.3:
		angler.stop()
		_try_cast(target)
		return
	_pending_cast = target
	angler.walk_to(target)


func _check_pending_cast() -> void:
	if not Dice.is_point(_pending_cast) or session.state != FishingSession.State.IDLE:
		return
	var close := angler.pos2().distance_to(_pending_cast) <= session.range_m() - 0.5
	if close or not angler.is_walking():
		var target := _pending_cast
		_pending_cast = Dice.NO_POINT
		angler.stop()
		_try_cast(target)


func _try_cast(target: Vector2) -> void:
	session.angler = angler.pos2()
	angler.face(target - angler.pos2())
	if not session.cast(target):
		Sounds.play("error")
		hud.toast(tr("UI_NO_WATER"), UiKit.MUTED)


func _on_action_down() -> void:
	if card.visible:
		return
	if session.state == FishingSession.State.IDLE:
		# Space / AT: balıkçının önüne; önü kara ise gölün ortasına doğru.
		var forward := angler.pos2() + angler.facing * FORWARD_CAST
		var landing := lake.landing_point(angler.pos2(), forward, session.range_m(), session.rules.min_shore)
		_try_cast(forward if Dice.is_point(landing) else lake.water_bounds.get_center())
		return
	session.press()


func _on_action_up() -> void:
	session.release()


# --- Olaylar -------------------------------------------------------------------------

func _on_event(e: Dictionary) -> void:
	match str(e["type"]):
		"cast":
			GameState.save.casts += 1
			angler.play_cast()
			var to: Vector2 = e["to"]
			var from: Vector2 = e["from"]
			var seconds := float(int(e["steps"])) / FishingRules.HZ
			bobber.fly(angler.rod_tip(), Vector3(to.x, 0.0, to.y), seconds, from.distance_to(to) * session.rules.arc)
			Sounds.play("cast")
			Sounds.haptic(8)
		"land":
			var p: Vector2 = e["pos"]
			bobber.land(Vector3(p.x, 0.0, p.y))
			ripples.spawn(p, 0.7, 0.9)
			Sounds.play("plop")
			Sounds.haptic(12)
		"scare":
			var s := session.sim.find(int(e["shadow"]))
			if s != null:
				ripples.spawn(s.pos, s.length, 0.6, Color(1, 1, 1, 0.6), 0.16)
			Sounds.play("scare")
			if GameState.save.catches < HINT_CATCHES:
				hud.toast(tr("UI_SCARED"), UiKit.ACCENT)
		"nibble":
			bobber.nibble()
			ripples.spawn(session.bobber, 0.45, 0.6, Color(1, 1, 1, 0.7), 0.12)
			Sounds.play("nibble")
			Sounds.haptic(15)
		"bite":
			bobber.go_under()
			ripples.spawn(session.bobber, 1.0, 0.8, Color(1, 1, 1, 0.9), 0.14)
			Sounds.play("bite")
			Sounds.haptic(70)
			camera.shake(0.06)
		"early":
			if bool(e["startle"]):
				hud.toast(tr("UI_STARTLE"), UiKit.ACCENT)
				Sounds.play("nibble")
			else:
				hud.toast(tr("UI_EARLY"), UiKit.BAD)
				Sounds.play("escape")
			Sounds.haptic(30)
		"retry":
			hud.toast(tr("UI_RETRY"), UiKit.ACCENT)
			Sounds.play("hint")
		"hook":
			bobber.start_fight(bobber.global_position)
			ripples.spawn(session.bobber, 1.2, 0.7, Color(1, 1, 1, 0.9), 0.18)
			Sounds.play("hook")
			Sounds.haptic(40)
			camera.shake(0.09)
		"warn":
			Sounds.play("warn")
			Sounds.haptic(35)
		"burst":
			ripples.spawn(session.fight_point(), 0.9, 0.5, Color(1, 1, 1, 0.8), 0.18)
			Sounds.play("splash")
			Sounds.haptic(20)
		"strain":
			Sounds.set_loop("strain", true)
			Sounds.haptic(25)
		"strain_end":
			Sounds.set_loop("strain", false)
		"lost":
			_on_lost(str(e["reason"]))
		"catch":
			_on_catch()
		"retrieve":
			bobber.fly_back(angler.rod_tip(), float(session.rules.retrieve_steps) / FishingRules.HZ)
			Sounds.play("reel_in")
		"idle":
			if bobber.look != Bobber.Look.RETURNING:
				bobber.hide_bobber()


func _on_lost(reason: String) -> void:
	Sounds.set_loop("reel", false)
	Sounds.set_loop("strain", false)
	match reason:
		"missed":
			hud.toast(tr("UI_MISSED"), UiKit.BAD)
			Sounds.play("escape")
		"snapped":
			hud.toast(tr("UI_SNAPPED"), UiKit.BAD)
			Sounds.play("snap")
			Sounds.haptic(90)
			camera.shake(0.12)
		"escaped":
			hud.toast(tr("UI_ESCAPED"), UiKit.BAD)
			Sounds.play("escape")
	if reason == "snapped":
		bobber.hide_bobber()
	else:
		bobber.fly_back(angler.rod_tip(), float(session.rules.lost_steps) / FishingRules.HZ)


func _on_catch() -> void:
	Sounds.set_loop("reel", false)
	Sounds.set_loop("strain", false)
	var info := session.last_catch
	var fish_id := str(info["fish"])
	var rarity := int(info["rarity"])
	var save := GameState.save
	var outcome := Records.add(save.records, fish_id, int(info["size_cm"]), int(info["stars"]), GameState.clock.now_unix())
	save.catches += 1
	GameState.save_game()
	bobber.hide_bobber()
	ripples.spawn(angler.pos2() + angler.facing * 0.8, 1.0, 0.8)
	angler.cheer()
	Sounds.play("reel_in")
	Sounds.find(rarity)
	Sounds.haptic(50)
	if bool(outcome["new_record"]):
		Sounds.play("record")
	if Records.wants_card(rarity, outcome):
		card.show_catch(GameState.db, info, outcome)
	else:
		hud.toast(tr("UI_CAUGHT_TOAST") % [tr("FISH_" + fish_id), int(info["size_cm"])],
				UiKit.rarity_color(GameState.db, rarity))
		_quick_catch = 0.0


# --- Sunum ---------------------------------------------------------------------------

func _present(delta: float) -> void:
	var reel := session.reel
	var fighting := session.state == FishingSession.State.FIGHTING and reel != null
	shadows.sync(session.sim, angler.pos2(), fighting and reel.thrashing(), delta)
	if fighting:
		var fp := session.fight_point()
		bobber.fight_point = Vector3(fp.x, 0.0, fp.y)
	var show_line := session.line_out() or bobber.look == Bobber.Look.RETURNING
	line.visible = show_line and bobber.visible
	if line.visible:
		line.from = angler.rod_tip()
		line.to = bobber.global_position + Vector3(0, Bobber.RADIUS * 1.4, 0)
		match session.state:
			FishingSession.State.CASTING:
				line.sag = 0.08
			FishingSession.State.FIGHTING:
				line.sag = 0.03
			_:
				line.sag = 0.35
		line.shake = 0.0
		if fighting:
			line.shake = clampf(reel.tension, 0.0, 1.3) * (1.6 if reel.thrashing() else 0.6)
	angler.rod_raise = clampf(reel.tension, 0.0, 1.0) if fighting else 0.0
	var tension := reel.tension if fighting else 0.0
	Sounds.set_loop("reel", fighting and reel.holding, 0.0, 0.9 + 0.3 * tension)
	# Arayüz.
	hud.set_action("" if card.visible else session.action_kind())
	hud.tension_bar.visible = fighting
	hud.set_fighting(fighting)
	if fighting:
		hud.tension_bar.tension = reel.tension
		hud.tension_bar.limit = session.rules.limit
		hud.tension_bar.strain = reel.strain()
		hud.tension_bar.warn = reel.thrashing()
		hud.tension_bar.red = reel.in_red
		hud.tension_bar.distance = reel.distance
	_update_hint()
	_first_cue(delta)
	input.walking_allowed = session.state == FishingSession.State.IDLE and not card.visible
	# Yürürken adım sesi.
	if angler.is_walking():
		_step_clock += delta
		if _step_clock >= STEP_SOUND_EVERY:
			_step_clock = 0.0
			Sounds.play("step")
	# Kamera: olta sudayken eğilir ve balıkçı ile şamandıranın ortasına bakar; çekişmede yakınlaşır.
	camera.target = _focus()
	var line_view := session.line_out() or session.state == FishingSession.State.LOST
	camera.pitch = lerpf(camera.pitch, LINE_PITCH if line_view else FollowCamera.PITCH, minf(1.0, delta * 2.5))
	camera.zoom = lerpf(camera.zoom, FIGHT_ZOOM if fighting else 1.0, minf(1.0, delta * 2.0))


func _focus() -> Vector3:
	var a := angler.position + Vector3(0, 0.6, 0)
	if session.line_out() or session.state == FishingSession.State.LOST:
		var p := session.fight_point() if session.state == FishingSession.State.FIGHTING else session.bobber
		return a.lerp(Vector3(p.x, 0.0, p.y), 0.45)
	return a


## İlk av gölgesi, ilk atışa kadar arada bir halkayla gösterilir.
func _first_cue(delta: float) -> void:
	if GameState.save.catches > 0 or GameState.save.casts > 0 or session.state != FishingSession.State.IDLE:
		return
	_cue_clock += delta
	if _cue_clock < FIRST_CUE_EVERY:
		return
	_cue_clock = 0.0
	for s in session.sim.shadows:
		if s.scripted:
			ripples.spawn(s.pos, 1.0, 1.3, Color(1.0, 0.97, 0.75, 0.75), 0.08)


func _update_hint() -> void:
	if GameState.save.catches >= HINT_CATCHES or card.visible:
		hud.show_hint("")
		return
	var key := ""
	match session.state:
		FishingSession.State.IDLE:
			key = "UI_HINT_FIRST_SHADOW" if GameState.save.catches == 0 else "UI_HINT_CAST"
		FishingSession.State.CASTING, FishingSession.State.WAITING:
			key = "UI_HINT_COMING" if session.sim.approacher != null else "UI_HINT_WAIT"
		FishingSession.State.NIBBLING:
			key = "UI_HINT_NIBBLE"
		FishingSession.State.BITING:
			key = "UI_HINT_BITE"
		FishingSession.State.FIGHTING:
			key = "UI_HINT_REEL"
		_:
			return
	hud.show_hint(key)


# --- Arayüz ----------------------------------------------------------------------

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	hud = Hud.new()
	layer.add_child(hud)
	card = FishCard.new()
	layer.add_child(card)
	card.closed.connect(func() -> void: session.acknowledge())
	settings_panel = SettingsPanel.new()
	layer.add_child(settings_panel)
	hud.settings_pressed.connect(func() -> void:
		input.release_all()
		session.release()
		Sounds.set_loop("reel", false)
		Sounds.set_loop("strain", false)
		settings_panel.open())
	hud.action_down.connect(_on_action_down)
	hud.action_up.connect(_on_action_up)
