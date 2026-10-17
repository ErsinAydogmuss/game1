extends Node3D
## Ana sahne: her şeyi bağlar. Göl (LakeScene), balıkçı (Angler), iskelede oturan Dede (Elder),
## iskelenin başında Nine ve dükkânı (Nine, ShopStall), şamandıra, misina, gölgeler, kamera, arayüz
## ve balık tutma oturumu (FishingSession). Oyun mantığı oturumdadır; burası
## olayları dinleyip ses, titreşim, hareket ve yazıya çevirir. Her sesin bir görsel ve titreşim
## karşılığı vardır (iPhone'un sessiz anahtarı açık olabilir).
## Girdiyi InputRouter okur; --autoplay botu (yalnızca debug) gerçek dokunma olayları gönderir.

## Olta sudayken kamera eğimi; çekişmede ve balık gösterilirken yakınlaşma.
const LINE_PITCH := deg_to_rad(60.0)
const FIGHT_ZOOM := 0.9
const SHOW_ZOOM := 0.62
## Balık gösterilirken balıkçının önünde, kameraya doğru bu kadar uzakta (m).
const SHOW_REACH := 0.95
## Kartsız yakalayışta (tekrar eden balık) bildirimden sonra bu kadar sn içinde yeni atış serbest.
const QUICK_CATCH_TIME := 1.3
## Space ya da AT düğmesiyle balıkçının önüne atış uzaklığı (m).
const FORWARD_CAST := 6.0
## Kart, balık elde gösterildikten bu kadar sn sonra açılır.
const CARD_DELAY := 0.9
## Kart kapandıktan bu kadar sonra bekleyen bildirimler gelir (sn).
const TOAST_AFTER_CARD := 0.5
## Dede'nin ipuçları bu kadar balık tutulana kadar görünür.
const HINT_CATCHES := 3
## Dede iskelenin +x kenarında, suya bakan uçtan bu kadar geride oturur; yüzü kameraya dönük
## olsun diye +x'ten +z'ye bu kadar döner (kamera +x +z tarafında).
const ELDER_ALONG := 2.4
const ELDER_TURN := deg_to_rad(25.0)
## Dede'nin ya da Nine'nin sözü ipucu çubuğunda bu kadar kalır (sn).
const LINE_TIME := 4.0
const STEP_SOUND_EVERY := 0.36
## İlk atıştan önce ilk av gölgesinin çevresinde halka aralığı (sn): "bu gölge!"
const FIRST_CUE_EVERY := 1.6
## Efsanevi bir gölge balıkçıya bu kadar yaklaşınca (m) Dede uyarır ve kısa ezgi çalar; Dede o
## gölgeye bu kadar sn bakar.
const LEGEND_NOTICE_M := 9.0
const LEGEND_LOOK_TIME := 3.0

var session: FishingSession
var lake: LakeShape
var scene: LakeScene
var angler: Angler
var elder: Elder
var nine: Nine
var shop: ShopStall
var bobber: Bobber
var line: FishingLine
var shadows: ShadowLayer
var ripples: Ripples
var catch_fx: CatchFx
var camera: FollowCamera
var input: InputRouter
var hud: Hud
var card: FishCard
var settings_panel: SettingsPanel
var shop_panel: ShopPanel
var book_panel: BookPanel
## true iken kamerayı main sürmez (yalnızca debug: bot yakın çekim yapar).
var bot_camera: bool = false

var _save_ref: SaveData
var _paused: bool = false
var _pending_cast := Dice.NO_POINT
var _quick_catch: float = -1.0
var _step_clock: float = 0.0
var _cue_clock: float = 0.0
## Açılacak kart (balık elde gösterilirken bekler) ve kalan süre.
var _card_info: Dictionary = {}
var _card_outcome: Dictionary = {}
## Kıyı yolu: dokunulan yere sudan geçmeden yürünür (ShorePath).
var path: ShorePath
## Oyunun gölü (spots.json "main") ve balıkçının bölgesi (değişince oranlar ve garanti yenilenir).
var spot_id: String = ""
var zone_id: String = ""
var _card_wait: float = -1.0
## İpucu çubuğunda şu an gösterilen anahtar (değişince Dede konuşur).
var _hint_shown: String = ""
## Dede'nin ya da Nine'nin sözü (onlara dokununca, bir olayda), kalan süresi ve konuşan.
var _line: String = ""
var _line_time: float = 0.0
## Yem bu atışta bitti: olta dönünce Dede söyler.
var _bait_out: bool = false
var _line_speaker: String = "dede"
## Dede'nin haber verdiği efsanevi gölgeler (kimlik → true) ve o gölgeye bakma süresi.
var _announced: Dictionary = {}
var _legend_id: int = -1
var _legend_look: float = 0.0
## Dede'nin son öğüdünün ve Nine'nin son uğurlama sözünün sırası.
var _tip_index: int = 0
var _nine_index: int = 0


func _ready() -> void:
	spot_id = GameState.db.main_spot
	lake = GameState.db.lake(spot_id)
	scene = LakeScene.new()
	scene.keep_clear.append(ShopStall.clear_zone(lake.dock))
	add_child(scene)
	scene.setup(lake)
	shadows = ShadowLayer.new()
	shadows.db = GameState.db
	add_child(shadows)
	ripples = Ripples.new()
	add_child(ripples)
	shadows.ripples = ripples
	catch_fx = CatchFx.new()
	add_child(catch_fx)
	angler = Angler.new()
	angler.lake = lake
	angler.height_at = scene.stand_height
	add_child(angler)
	elder = Elder.new()
	add_child(elder)
	shop = ShopStall.new()
	add_child(shop)
	nine = Nine.new()
	add_child(nine)
	_seat_elder()
	_place_shop()
	bobber = Bobber.new()
	add_child(bobber)
	camera = FollowCamera.new()
	add_child(camera)
	elder.camera = camera
	nine.camera = camera
	line = FishingLine.new()
	line.camera = camera
	line.visible = false
	line.from_point = func() -> Vector3: return angler.rod_tip()
	line.to_point = func() -> Vector3: return bobber.global_position + Vector3(0, Bobber.RADIUS * 1.4, 0)
	add_child(line)
	_build_ui()
	_build_input()
	_start_session()
	_refresh_status()
	GameState.changed.connect(_on_state_changed)
	GameState.focus_lost.connect(_on_focus_lost)
	GameState.focus_gained.connect(func() -> void: _paused = false)
	ItemArt.register_fish_colors(GameState.db.fish_colors())
	FishPortrait.render_all(self, GameState.db)
	_load_faces()
	Sounds.set_ambience("lake")
	if OS.is_debug_build() and OS.get_cmdline_user_args().has("--autoplay"):
		var bot: Node = load("res://scripts/dev/autoplay.gd").new()
		bot.set("main", self)
		add_child(bot)


## Kayda göre yeni bir oturum (yeni gölgeler); ilk balık tutulmadıysa ilk av senaryolu.
func _start_session() -> void:
	var save := GameState.save
	_save_ref = save
	var start: Dictionary = Zones.at(GameState.db, spot_id, GameState.db.spot(spot_id)["start"])
	session = FishingSession.new(GameState.db, spot_id, Economy.gear_for(GameState.db, save), Dice.derive(save.seed, save.session),
			bool(GameState.setting("easy", false)), save.catches == 0, CatchOdds.pity_floor(GameState.db, save, start),
			Zones.open_ids(GameState.db, save, spot_id))
	zone_id = ""
	_follow_zone()
	angler.place(session.angler)
	angler.face(Vector2(0, -1))
	bobber.hide_bobber()
	line.visible = false
	_pending_cast = Dice.NO_POINT
	_quick_catch = -1.0
	_announced.clear()
	_legend_look = 0.0
	camera.pitch = FollowCamera.PITCH
	camera.zoom = 1.0
	camera.snap(_focus())


func _on_state_changed() -> void:
	hud.refresh()
	shop.refresh()
	# Kayıt dışarıdan değiştiyse (ayarlar, bot) para, kova ve rütbe de güncel olsun.
	_refresh_status()
	if GameState.save != _save_ref:
		# Kayıt değişti (sıfırlama): göl baştan.
		if card.visible:
			card.close_card()
		_card_wait = -1.0
		catch_fx.clear()
		_start_session()
		return
	session.easy = bool(GameState.setting("easy", false))
	# Ayar çekişmenin ortasında değişirse (Ayarlar açıkken oyun donuk) süren çekişmeye de geçer.
	if session.reel != null and session.hooked != null:
		session.reel.easy = session.easy or session.hooked.scripted


func _on_focus_lost() -> void:
	# Arama, Denetim Merkezi, arka plan: çekişme donar, parmak bırakılmış sayılır.
	_paused = true
	input.release_all()
	session.release()
	Sounds.set_loop("reel", false)
	Sounds.set_loop("strain", false)


func _process(delta: float) -> void:
	# Odak kaybında ve bir panel (ayarlar, dükkân, defter...) açıkken oyun donar (çekişmedeki
	# balık kaçmasın). Balık kartı panel değildir: kart açıkken balık gösterimi sürer.
	if _paused or _panel_open():
		return
	if session.state == FishingSession.State.IDLE:
		session.angler = angler.pos2()
	_check_pending_cast()
	session.advance(delta)
	for e in session.poll_events():
		_on_event(e)
	if _card_wait >= 0.0:
		_card_wait -= delta
		if _card_wait < 0.0:
			card.show_catch(GameState.db, _card_info, _card_outcome)
	if _card_up():
		# Kart açıkken (ya da açılacakken) rütbe ve kova bildirimleri bekler: kartın arkasında kalmasın.
		hud.hold_toasts(TOAST_AFTER_CARD)
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
	input.action_button = hud.action_button
	input.ground_point = ground_point
	input.line_out = func() -> bool: return session.line_out()
	input.hit_targets = [
		["dede", func(screen: Vector2) -> bool: return elder.hit(camera, screen)],
		["shop", func(screen: Vector2) -> bool: return nine.hit(camera, screen) or shop.hit(camera, screen)],
		["boat", func(screen: Vector2) -> bool: return scene.boat_hit(camera, screen)],
	]
	input.targets_active = func() -> bool: return session.state == FishingSession.State.IDLE and not card.visible
	add_child(input)
	input.target_tapped.connect(_on_target)
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
	_walk_route(target)


## Suya dokunuş: menzildeyse hemen atar; değilse önce yaklaşır (kıyıda durursa oradan atar).
## Olta dönerken (kaçtı, geri sarma, kartsız kısa yakalama) gelen dokunuş kaybolmaz: dönünce
## atılır. Kartlı yakalamada saklanmaz: kartı kapatan dokunuş olta da atmasın.
func _on_cast_requested(target: Vector2) -> void:
	var returning := session.state in [FishingSession.State.LOST, FishingSession.State.RETRIEVING] \
			or (session.state == FishingSession.State.CAUGHT and _quick_catch >= 0.0 and not card.visible)
	if returning:
		_pending_cast = target
		return
	if session.state != FishingSession.State.IDLE:
		return
	if angler.pos2().distance_to(target) <= session.range_m() - 0.3:
		angler.stop()
		_try_cast(target)
		return
	_pending_cast = target
	# Düz yürüyünce (kıyıda durur) menzile giriyorsa düz yürür; girmiyorsa (koyun öbür yakası) kıyı
	# yolundan hedefe en yakın kıyıya gider. Menzile girince atar.
	if _straight_reach(target) <= session.range_m() - 0.5:
		angler.walk_to(target)
	else:
		_walk_route(target)


## Kıyı yolundan yürür (yol bulunamazsa düz: eski göller ızgaranın dışında da yürünür). Hedef
## kilitli bir bölgedeyse balıkçı çitin önünde durur, Dede ne zaman gidileceğini söyler.
func _walk_route(target: Vector2) -> void:
	var points := path.route(angler.pos2(), target)
	if points.is_empty():
		angler.walk_to(target)
		return
	angler.walk_path(points)
	var goal := path.nearest_open(target)
	if Dice.is_point(goal) and points[points.size() - 1].distance_to(goal) > 1.0:
		var reason := Zones.lock_reason(GameState.db, GameState.save, Zones.at(GameState.db, spot_id, target))
		if not reason.is_empty():
			var key := str(reason["key"])
			_say("UI_DEDE_GATE")
			hud.toast(tr(key) % int(reason["rank"]) if key == "UI_ZONE_LOCKED_RANK" else tr(key), UiKit.ACCENT, "lock")


## Kilitli bölgelerin çitleri kıyı yolunu keser; bölge açılınca (rütbe) çit açılır.
func _update_gates() -> void:
	var db := GameState.db
	for z in db.zones_of(spot_id):
		var gates: Array = z["gates"]
		var closed := not Zones.unlocked(db, GameState.save, z)
		for i in gates.size():
			var g: PackedVector2Array = gates[i]
			path.set_gate("%s_%d" % [z["id"], i], g[0], g[1], closed)


## Hedefe düz yürüyünce (kıyıda ya da dünyanın sınırında durur) hedefe kalan uzaklık.
func _straight_reach(target: Vector2) -> float:
	var from := angler.pos2()
	var dir := (target - from).normalized()
	var stop := from
	var length := from.distance_to(target)
	var d := 0.2
	while d <= length:
		var p := from + dir * d
		if not lake.is_walkable(p):
			break
		stop = p
		d += 0.2
	return stop.distance_to(target)


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
	# Hangi yoldan gelirse gelsin (dokunuş, AT, bekleyen atış) önceki hedef unutulur, yürüme biter.
	_pending_cast = Dice.NO_POINT
	angler.stop()
	session.angler = angler.pos2()
	# Çok yakına (en kısa atıştan az) dokunulduysa o yönde biraz öteye atılır: suya dokunan
	# oyuncu "suya dokun" hatası almasın.
	var offset := target - angler.pos2()
	var near := session.rules.min_cast + 0.3
	if offset.length() > 0.001 and offset.length() < near:
		target = angler.pos2() + offset.normalized() * near
	angler.face(target - angler.pos2())
	if not session.cast(target):
		Sounds.play("error")
		hud.toast(tr("UI_NO_WATER"), UiKit.MUTED)


func _on_action_down() -> void:
	if card.visible:
		return
	if session.state == FishingSession.State.IDLE:
		# Space / AT: balıkçının önüne; önü kara ise suyun olduğu en yakın yöne.
		_try_cast(angler.pos2() + _cast_dir() * FORWARD_CAST)
		return
	session.press()


## AT düğmesinin yönü: balıkçının baktığı yön; orada su yoksa 15° adımlarla iki yana (arkaya kadar)
## bakılır, baktığı yöne yakın ve suya iyi düşen yön seçilir.
func _cast_dir() -> Vector2:
	var from := angler.pos2()
	var best := angler.facing
	var best_score := -INF
	for k in 25:
		var angle := deg_to_rad(15.0 * ((k + 1) >> 1)) * (1.0 if k % 2 == 1 else -1.0)
		var dir := angler.facing.rotated(angle)
		var landing := lake.landing_point(from, from + dir * FORWARD_CAST, session.range_m(), session.rules.min_shore)
		if not Dice.is_point(landing):
			continue
		# Önce baktığı yöne yakın, sonra suya iyi düşen yön.
		var score := lake.shore_distance(landing) - absf(angle)
		if k == 0:
			return dir
		if score > best_score:
			best_score = score
			best = dir
	return best


func _on_action_up() -> void:
	session.release()


# --- Olaylar -------------------------------------------------------------------------

func _on_event(e: Dictionary) -> void:
	match str(e["type"]):
		"cast":
			GameState.save.casts += 1
			# Dede'nin öğüdü (Nine'nin sözü) atışın ipuçlarına yer açar.
			_line_time = 0.0
			catch_fx.clear()
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
			bobber.land(Vector3(session.bobber.x, 0.0, session.bobber.y))
			hud.toast(tr("UI_RETRY"), UiKit.ACCENT)
			Sounds.play("hint")
		"hook":
			# Yem balık takılınca harcanır (kaçan gölge yemi yemez). Biten yem solucana döner; oturumun
			# takımı da: yeni gölgeler solucanın oranlarıyla doğar (defter ve dükkânla aynı). Dede,
			# olta dönünce ve o an başka bir söz (kova dolu) yokken söyler.
			var bait_id := Economy.equipped(GameState.db, GameState.save, "bait")
			Economy.use_bait(GameState.db, GameState.save)
			if Economy.equipped(GameState.db, GameState.save, "bait") != bait_id:
				session.set_gear(Economy.gear_for(GameState.db, GameState.save))
				_bait_out = true
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
			# Gıcırtı döngüsü _present'te her kare (duraklamadan sonra da) açılır.
			Sounds.haptic(25)
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
	var db := GameState.db
	var size_cm := int(info["size_cm"])
	var stars := int(info["stars"])
	var outcome := Records.add(save.records, fish_id, size_cm, stars, GameState.clock.now_unix())
	save.catches += 1
	CatchOdds.note_catch(db, save, rarity, Zones.place(db, spot_id, str(info.get("zone", ""))))
	session.set_pity_floor(CatchOdds.pity_floor(db, save, Zones.place(db, spot_id, zone_id)))
	var ranked := Rank.add_xp(db, save, Rank.catch_xp(db, rarity, stars))
	# Balık kovaya girer; kova doluysa oyun durmaz: balık göle döner (göl sevgisi verir).
	var was_full := Bucket.is_full(db, save)
	var kept := Bucket.add(db, save, fish_id, size_cm, stars)
	if not kept:
		_release(fish_id, rarity)
	GameState.save_game()
	_refresh_status()
	# Rütbe atlama, kova dolu gibi bildirimler balığın etiketi sönünce (üst üste binmesin).
	hud.hold_toasts(CatchFx.HOLD_TIME)
	if int(ranked["new_rank"]) > int(ranked["old_rank"]):
		session.set_access(Zones.open_ids(db, save, spot_id))
		_update_gates()
		var rank := int(ranked["new_rank"])
		hud.toast_later(tr("UI_RANK_UP") % [rank, tr("RANK_" + db.rank_title(rank))], UiKit.ACCENT, "rank_up", "star")
	if not kept:
		hud.toast_later(tr("UI_BUCKET_FULL"), UiKit.ACCENT, "", "release")
	elif Bucket.is_full(db, save) and not was_full:
		# Kova bu balıkla doldu: Dede hatırlatır (Nine'ye sat ki yenileri de sığsın).
		_say("UI_DEDE_BUCKET")
	bobber.hide_bobber()
	ripples.spawn(angler.pos2() + angler.facing * 0.8, 1.0, 0.8)
	# Balık elde: kaldırıp gösterir, üstünde adı ve boyu; Nadir ve üstünde ışık sütunu.
	var color := UiKit.rarity_color(GameState.db, rarity)
	catch_fx.show_catch(GameState.db.fish_by_id(fish_id), int(info["size_cm"]), tr("FISH_" + fish_id), color,
			_show_point, rarity >= Records.CARD_RARITY, func() -> Vector3: return angler.global_position,
			UiKit.rarity_icon(db, rarity))
	if bool(outcome["new_species"]) or bool(outcome["new_record"]) or rarity >= Records.CARD_RARITY:
		angler.cheer()
		elder.cheer()
	else:
		angler.show_fish()
		elder.approve()
	Sounds.play("reel_in")
	Sounds.find(rarity)
	Sounds.haptic(50)
	if bool(outcome["new_record"]):
		Sounds.play("record")
	if Records.wants_card(rarity, outcome):
		_card_info = info
		_card_outcome = outcome
		_card_wait = CARD_DELAY
	else:
		# Kartsız yakalama: adı ve boyu balığın üstündeki etikette (CatchTag); bildirim yok.
		_quick_catch = 0.0


# --- Sunum ---------------------------------------------------------------------------

## Balıkçının bölgesi değişti mi (yürüdü, geçti): oranlar, defter ve dükkân o bölgenin; şans
## garantisi o bölgede gelebilen kademeler için.
func _follow_zone() -> void:
	var now := session.zone_id()
	if now == zone_id:
		return
	zone_id = now
	shop_panel.zone_id = now
	book_panel.zone_id = now
	session.set_pity_floor(CatchOdds.pity_floor(GameState.db, GameState.save, Zones.place(GameState.db, spot_id, now)))


func _present(delta: float) -> void:
	_follow_zone()
	var reel := session.reel
	var fighting := session.state == FishingSession.State.FIGHTING and reel != null
	shadows.sync(session.sim, angler.pos2(), fighting and reel.thrashing(), delta)
	if fighting:
		var fp := session.fight_point()
		bobber.fight_point = Vector3(fp.x, 0.0, fp.y)
	var show_line := session.line_out() or bobber.look == Bobber.Look.RETURNING
	line.visible = show_line and bobber.visible
	if line.visible:
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
	var tension := reel.tension if fighting else 0.0
	angler.tension = tension
	# Dede olta sudayken şamandırayı izler (efsanevi gölgeyi haber verdiyse önce ona bakar); Nine
	# yaklaşan balıkçıya bakar.
	_notice_legends(delta)
	elder.has_focus = session.line_out() and bobber.visible
	elder.focus = bobber.global_position
	if _legend_look > 0.0:
		var point := shadows.shadow_point(_legend_id)
		if point != Vector3.INF:
			elder.focus = point
			elder.has_focus = true
	nine.watch(angler.global_position + Vector3(0.0, 1.1, 0.0))
	# Köylünün sözü kart açıkken saymaz (ipucu çubuğu kartın altında gizli).
	if not _card_up():
		_line_time = maxf(0.0, _line_time - delta)
	if _bait_out and _line_time <= 0.0 and session.state == FishingSession.State.IDLE and not _card_up():
		_bait_out = false
		_say("UI_DEDE_BAIT_OUT")
	match session.state:
		FishingSession.State.FIGHTING:
			angler.pose = "reel"
		FishingSession.State.CASTING, FishingSession.State.WAITING, FishingSession.State.NIBBLING, FishingSession.State.BITING:
			angler.pose = "hold"
		_:
			angler.pose = "free"
	Sounds.set_loop("reel", fighting and reel.holding, 0.0, 0.9 + 0.3 * tension)
	Sounds.set_loop("strain", fighting and reel.in_red)
	# Arayüz.
	hud.set_action("" if card.visible else session.action_kind())
	hud.tension_bar.visible = fighting
	hud.set_fighting(fighting)
	hud.set_line_out(session.line_out())
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
	if bot_camera:
		return
	camera.target = _focus()
	var line_view := session.line_out() or session.state == FishingSession.State.LOST
	camera.pitch = lerpf(camera.pitch, LINE_PITCH if line_view else FollowCamera.PITCH, minf(1.0, delta * 2.5))
	var zoom := 1.0
	if fighting:
		zoom = FIGHT_ZOOM
	elif catch_fx.is_showing():
		zoom = SHOW_ZOOM
	camera.zoom = lerpf(camera.zoom, zoom, minf(1.0, delta * 2.5))


## Yakalanan balığın gösterildiği yer: balıkçının önünde, kameraya doğru uzatılmış ve göğüs
## hizasında. Yukarıdan bakan kamerada şapkanın kenarı (~0,5 m) altında kalmasın; ekranda
## iskelenin açık tahtasının önünde görünür.
func _show_point() -> Vector3:
	var toward := Vector3(sin(FollowCamera.YAW), 0.0, cos(FollowCamera.YAW))
	return angler.global_position + toward * SHOW_REACH + Vector3(0.0, 1.0, 0.0)


func _focus() -> Vector3:
	var a := angler.position + Vector3(0, 0.6, 0)
	if catch_fx.is_showing():
		return _show_point() + Vector3(0, -0.2, 0)
	if session.line_out() or session.state == FishingSession.State.LOST:
		var p := session.fight_point() if session.state == FishingSession.State.FIGHTING else session.bobber
		return a.lerp(Vector3(p.x, 0.0, p.y), 0.45)
	return a


## Efsanevi (ve üstü) bir gölge yaklaşınca Dede bir kez haber verir: sözü, kısa ezgi, titreşim ve
## o gölgeye bakışı. Çekişmede ve kart açıkken söylemez (sırası gelince söyler).
func _notice_legends(delta: float) -> void:
	_legend_look = maxf(0.0, _legend_look - delta)
	if card.visible or session.state == FishingSession.State.FIGHTING:
		return
	var legendary := GameState.db.rarity_index("legendary")
	for s in session.sim.shadows:
		if s.rarity < legendary or _announced.has(s.id) or s.mode == FishShadow.Mode.FLEE:
			continue
		if s.pos.distance_to(angler.pos2()) > LEGEND_NOTICE_M:
			continue
		_announced[s.id] = true
		_legend_id = s.id
		_legend_look = LEGEND_LOOK_TIME
		_say("UI_DEDE_LEGEND_NEAR")
		Sounds.play("sting")
		Sounds.haptic(30)
		return


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
	var key := _hint_key()
	var speaker := _line_speaker if _line_time > 0.0 and key == _line else "dede"
	if key != _hint_shown:
		_hint_shown = key
		# Yeni bir söz: konuşan konuşur (balon, baş sallama, oyuncuya bakış). Nine'nin selamı
		# dokunuşta söylenir (_on_shop).
		if not key.is_empty() and speaker == "dede":
			elder.say()
	hud.show_hint(key, speaker)


## Gösterilecek ipucu: önce Dede'nin öğüdü ya da Nine'nin sözü (onlara dokununca), sonra ilk 3
## balığa kadar oyunun durumuna göre ipucu. Kart açıkken ipucu yok.
func _hint_key() -> String:
	if card.visible:
		return ""
	if _line_time > 0.0:
		return _line
	if GameState.save.catches >= HINT_CATCHES:
		return ""
	match session.state:
		FishingSession.State.IDLE:
			return "UI_HINT_FIRST_SHADOW" if GameState.save.catches == 0 else "UI_HINT_CAST"
		FishingSession.State.CASTING, FishingSession.State.WAITING:
			return "UI_HINT_COMING" if session.sim.approacher != null else "UI_HINT_WAIT"
		FishingSession.State.NIBBLING:
			return "UI_HINT_NIBBLE"
		FishingSession.State.BITING:
			return "UI_HINT_BITE"
		FishingSession.State.FIGHTING:
			return "UI_HINT_REEL"
	# Kayıp, yakalama, geri sarma: önceki ipucu kalır (süresi biten öğüt söner).
	return "" if _hint_shown == _line else _hint_shown


# --- Dede ------------------------------------------------------------------------

## Dede iskelenin +x kenarında oturur (bacakları suya sarkar); balıkçı onun içinden geçmez.
func _seat_elder() -> void:
	var dock := lake.dock
	var edge := Vector2(dock.end.x, dock.position.y + ELDER_ALONG)
	elder.seat(edge, Vector2(1.0, 0.0).rotated(ELDER_TURN), LakeScene.DOCK_HEIGHT + 0.04)


## Nine'nin dükkânı iskelenin kara ucunun solunda; Nine tezgâhın arkasında. Döşeme, altındaki
## zeminin en yüksek yerine oturur (eğimli kıyıda etek boşluğu örter). Balıkçı Dede'nin,
## dükkânın ve Nine'nin içinden geçmez.
func _place_shop() -> void:
	var front := ShopStall.front_for(lake.dock)
	var facing := ShopStall.facing_dir()
	var side := Vector2(facing.y, -facing.x)
	var floor_y := 0.0
	for u: float in [-0.5, 0.0, 0.5]:
		for v: float in [0.0, 0.5, 1.0]:
			var p := front + side * u * ShopStall.WIDTH - facing * v * ShopStall.DEPTH
			floor_y = maxf(floor_y, scene.ground_height(p))
	shop.build(Vector3(front.x, floor_y, front.y), facing, scene.ground_height)
	nine.stand(shop.keeper_spot(), shop.facing())
	var blockers: Array[Vector3] = [elder.blocker()]
	blockers.append_array(shop.blockers())
	angler.blockers = blockers
	# Kıyı yolu: Dede, dükkân, kamp ve büyük süsler geçilmez.
	path = ShorePath.new(lake, lake.world_rect if lake.world_band != INF else Rect2())
	var obstacles := blockers.duplicate()
	obstacles.append_array(scene.blockers())
	path.set_obstacles(obstacles)
	_update_gates()


## Balık göle bırakıldı: defterde bırakılan sayısı, göl sevgisi ve sayaç.
func _release(fish_id: String, rarity: int) -> void:
	var save := GameState.save
	Records.release(save.records, fish_id)
	save.love += int(GameState.db.rarity_def(rarity).get("love", 0))
	save.stats["released"] = int(save.stats.get("released", 0)) + 1


## Sol üstteki para, kova ve rütbe.
func _refresh_status() -> void:
	var db := GameState.db
	var save := GameState.save
	hud.set_status(save.coins, save.bucket.size(), Bucket.capacity(db, save), Rank.rank(db, save),
			Rank.progress(db, save))


## Balık kartı açık mı ya da açılmak üzere mi?
func _card_up() -> bool:
	return card.visible or _card_wait >= 0.0


## Açık bir panel (Dialog) var mı? Varken oyun donar.
func _panel_open() -> bool:
	for node in get_tree().get_nodes_in_group("modal"):
		if node is Dialog and (node as Dialog).visible:
			return true
	return false


## Dede (ya da Nine) bir söz söyler: ipucu çubuğunda, konuşanın yüzüyle (söz değişince
## _update_hint Dede'yi konuşturur).
func _say(key: String, speaker: String = "dede") -> void:
	_line = key
	_line_time = LINE_TIME
	_line_speaker = speaker
	Sounds.play("hint")


## Dünyadaki bir hedefe dokunuldu (InputRouter.hit_targets).
func _on_target(id: String) -> void:
	match id:
		"dede":
			_on_talk()
		"shop":
			_on_shop()
		"boat":
			_on_boat()


## Sandala dokunuldu: Dede sandalla derin sulara açılmaktan söz eder (Dalga 2'de binilir).
func _on_boat() -> void:
	if session.state != FishingSession.State.IDLE or card.visible:
		return
	_say("UI_DEDE_BOAT")
	Sounds.haptic(10)


## Dede'ye dokunuldu: sıradaki öğüdü ipucu çubuğunda söyler (balon, baş sallama).
func _on_talk() -> void:
	if session.state != FishingSession.State.IDLE or card.visible:
		return
	_tip_index = _tip_index % Elder.TIP_COUNT + 1
	_say(Elder.TIP_KEY % _tip_index)
	Sounds.haptic(10)


## Nine'ye ya da dükkânına dokunuldu: Nine selam verir (balon, baş sallama, tezgâha uzanma) ve
## dükkân açılır (kova doluysa Kova sekmesi). Olta suda değilken açılır: oturum zaten boşta.
func _on_shop() -> void:
	if session.state != FishingSession.State.IDLE or card.visible:
		return
	nine.greet()
	Sounds.haptic(10)
	angler.stop()
	_pending_cast = Dice.NO_POINT
	input.release_all()
	shop_panel.open_shop()


## Dükkân kapandı: Nine uğurlar (ipucu çubuğunda, sırayla uğurlama ve öğüt sözleri).
func _on_shop_closed() -> void:
	_nine_index = _nine_index % Nine.LINE_COUNT + 1
	_say(Nine.LINE_KEY % _nine_index, "nine")


## Takım değişti (dükkânda satın alma ya da kuşanma): oturumun takımı ve oranları yenilenir.
func _on_gear_changed() -> void:
	session.set_gear(Economy.gear_for(GameState.db, GameState.save))
	_refresh_status()


## Kova satıldı: para göstergesi ve Nine'nin sevinci.
func _on_sold(_coins: int) -> void:
	_refresh_status()
	nine.cheer()


## Dede ve Nine'nin yüzleri (ipucu çubuğu, kart, dükkân) Ersin'in portrelerinden, sözün ifadesiyle
## (Moods). Portre yoksa yedek yüz modelden çekilir (birkaç kare sürer).
func _load_faces() -> void:
	if ItemArt.portrait("dede_smile") == null:
		var dede_face := await ElderBody.portrait(self, 192)
		if dede_face != null:
			hud.set_portrait(dede_face)
			card.dede_face = dede_face
	if ItemArt.portrait("nine_smile") == null:
		var nine_face := await NineBody.portrait(self, 192)
		if nine_face != null:
			hud.set_portrait(nine_face, "nine")
			shop_panel.set_face(nine_face)


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
	shop_panel = ShopPanel.new()
	layer.add_child(shop_panel)
	shop_panel.spot_id = spot_id
	shop_panel.gear_changed.connect(_on_gear_changed)
	shop_panel.sold.connect(_on_sold)
	shop_panel.closed.connect(_on_shop_closed)
	book_panel = BookPanel.new()
	book_panel.spot_id = spot_id
	layer.add_child(book_panel)
	hud.book_pressed.connect(func() -> void:
		input.release_all()
		book_panel.open_book())
	hud.settings_pressed.connect(func() -> void:
		input.release_all()
		session.release()
		Sounds.set_loop("reel", false)
		Sounds.set_loop("strain", false)
		settings_panel.open())
	hud.action_down.connect(func() -> void: input.pointer(InputRouter.BUTTON_POINTER, true))
	hud.action_up.connect(func() -> void: input.pointer(InputRouter.BUTTON_POINTER, false))
