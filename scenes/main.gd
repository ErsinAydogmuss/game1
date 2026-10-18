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
## Fazla iri balıktan sonra Dede'nin takım öğüdü (UI_DEDE_TOO_BIG_BUY, _EQUIP, _BOTH, _RANK): atışta
## silinmez, biraz daha uzun kalır.
const TOO_BIG_PREFIX := "UI_DEDE_TOO_BIG_"
const ADVICE_TIME := 6.0
const STEP_SOUND_EVERY := 0.36
## İlk atıştan önce ilk av gölgesinin çevresinde halka aralığı (sn): "bu gölge!"
const FIRST_CUE_EVERY := 1.6
## Efsanevi bir gölge balıkçıya bu kadar yaklaşınca (m) Dede uyarır ve kısa ezgi çalar; Dede o
## gölgeye bu kadar sn bakar.
const LEGEND_NOTICE_M := 9.0
const LEGEND_LOOK_TIME := 3.0
## Çekilen yapay yemin arkasındaki iz halkalarının aralığı (sn); sürüklenen sineğinki.
const WAKE_EVERY := 0.2
const FLY_TRAIL_EVERY := 0.45
## Takım çantasından açılan dükkânda balıkçı Nine'ye bundan uzaksa kova satılmaz (tezgâha gelinir).
const SHOP_NEAR := 6.0
## Olta sudayken kameranın odağı balıkçıyla takımın arasında, yolun bu kadarında.
const FOCUS_SHARE := 0.45
## Dipte takım uzağa düşer (14–18 m): kamera biraz yatar (FAR_PITCH) ve ikisi de görünsün diye en
## çok FAR_MAX_ZOOM kadar uzaklaşır. Balıkçının ayağı ekranın FAR_LOW çizgisinin üstünde (ipucu
## çubuğunun üstü), takım FAR_HIGH çizgisinin altında (üstteki para ve kova göstergeleri) kalır;
## ekran payı: -1 alt kenar, 1 üst kenar. Sığmazsa balıkçı ve sehpa görünür kalır, takım yukarı
## taşar.
const FAR_PITCH := deg_to_rad(45.0)
const FAR_MAX_ZOOM := 1.3
## Sinekte takım akıntıda balıkçının önünde, 6–12 m'de: aynı çerçeve, eğim şamandıranınki gibi
## (LINE_PITCH), kamera en çok FLY_MAX_ZOOM kadar uzaklaşır (sinek küçük; uzaktan seçilmez).
const FLY_MAX_ZOOM := 1.15
const FAR_LOW := -0.5
const FAR_HIGH := 0.8
## Tuzağa bu kadar yakından (m) dokunulunca toplanır; uzaktaysa balıkçı önce yürür. Tuzakların dolması
## (gerçek saatle) bu aralıkla (sn) yenilenir.
const TRAP_REACH := 5.0
const TRAP_SYNC_EVERY := 1.0

var session: FishingSession
var lake: LakeShape
var scene: LakeScene
var angler: Angler
var elder: Elder
var nine: Nine
var shop: ShopStall
var bobber: Bobber
var line: FishingLine
## Dipte balıkçının yanındaki sehpa (kamış ve zil).
var stand: RodStand
## Kerevit tuzaklarının işaretleri (suda turuncu şamandıra, dolma rozeti).
var traps: TrapMarkers
var shadows: ShadowLayer
var ripples: Ripples
var catch_fx: CatchFx
## Çekişmede sudan sıçrayan balık (alabalıklar).
var fish_jump: FishJump
## Bölgede avlanılmadığı için şamandıraya dönülen teknik (sinek dere ağzı dışında; _fit_technique)
## ve oturumun bölgesinin bir kez belli olup olmadığı (ilk geçiş sessiz).
var _held_technique: String = ""
var _zone_known: bool = false
var camera: FollowCamera
var input: InputRouter
var hud: Hud
var card: FishCard
var settings_panel: SettingsPanel
var shop_panel: ShopPanel
var book_panel: BookPanel
var map_panel: MapPanel
## Takım çantası (sol alttaki teknik düğmesi): teknik seçilir, tuzak bırakılır.
var technique_panel: TechniquePanel
## Boş tuzağın paneli (bekle ya da kaldır).
var trap_panel: TrapPanel
## Haritadan hızlı geçişte ekran kararır (en üstte).
var fade: Fade
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
## Balıkçı sandalda mı (derin ortada, bir şamandıranın yanında) ve hangi şamandırada.
var in_boat: bool = false
## Oturumun bölge erişiminin ve çitlerin kurulduğu rütbe (rütbe dışarıdan değişirse yenilenir).
var _access_rank: int = 0
var _buoy: int = -1
var _card_wait: float = -1.0
## İpucu çubuğunda şu an gösterilen anahtar (değişince Dede konuşur).
var _hint_shown: String = ""
## Dede'nin ya da Nine'nin sözü (onlara dokununca, bir olayda), kalan süresi, biçimli sözün
## değerleri (ya da onları o anki dilde kuran işlev: takım adları dil değişince de doğru) ve konuşan.
var _line: String = ""
var _line_time: float = 0.0
var _line_args: Array = []
var _line_args_fn: Callable = Callable()
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
## Sahnede gösterilen teknik (elindeki kamış, suya atılan takım, teknik düğmesinin ikonu).
var _shown_technique: String = ""
var _wake_clock: float = 0.0
## Uzaktaki tuzağa dokunuldu: balıkçı yürür, varınca toplar (tuzağın kimliği; yoksa -1). Dokunma
## denetiminin bulduğu tuzak (hit_targets → _on_target) ve dolmanın yenilenme sayacı.
var _pending_trap: int = -1
var _trap_tap: int = -1
var _trap_clock: float = 0.0


func _ready() -> void:
	spot_id = GameState.db.main_spot
	lake = GameState.db.lake(spot_id)
	scene = LakeScene.new()
	scene.keep_clear.append(ShopStall.clear_zone(lake.dock))
	scene.zones = GameState.db.zones_of(spot_id)
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
	fish_jump = FishJump.new()
	add_child(fish_jump)
	fish_jump.left.connect(func(at: Vector2) -> void:
		ripples.spawn(at, 0.8, 0.6, Color(1, 1, 1, 0.85), 0.16)
		Sounds.play("splash", 2.0, 1.15)
		Sounds.haptic(30))
	fish_jump.landed.connect(func(at: Vector2) -> void:
		ripples.spawn(at, 1.1, 0.7, Color(1, 1, 1, 0.9), 0.18)
		Sounds.play("splash")
		Sounds.haptic(20))
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
	stand = RodStand.new()
	add_child(stand)
	traps = TrapMarkers.new()
	add_child(traps)
	traps.landed.connect(_on_trap_landed)
	camera = FollowCamera.new()
	add_child(camera)
	elder.camera = camera
	nine.camera = camera
	line = FishingLine.new()
	line.camera = camera
	line.visible = false
	line.from_point = func() -> Vector3: return stand.tip_point() if angler.rod_on_stand else angler.rod_tip()
	line.to_point = func() -> Vector3: return bobber.line_point()
	add_child(line)
	_build_ui()
	_build_input()
	_start_session()
	_refresh_status()
	# Eski kayıt: rütbesi çoktan gelmiş teknik de bir kez haber verilir.
	_announce_techniques()
	GameState.changed.connect(_on_state_changed)
	GameState.focus_lost.connect(_on_focus_lost)
	GameState.focus_gained.connect(_on_focus_gained)
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
	var gear := _gear()
	session = FishingSession.new(GameState.db, spot_id, gear, Dice.derive(save.seed, save.session),
			bool(GameState.setting("easy", false)), save.catches == 0,
			CatchOdds.pity_floor(GameState.db, save, start, gear.technique), Zones.open_ids(GameState.db, save, spot_id))
	zone_id = ""
	_zone_known = false
	_held_technique = ""
	in_boat = false
	_buoy = -1
	_access_rank = Rank.rank(GameState.db, save)
	if path != null:
		_update_gates()
	scene.dock_boat()
	hud.set_boat(false)
	_follow_zone()
	angler.place(session.angler)
	angler.face(Vector2(0, -1))
	bobber.hide_bobber()
	line.visible = false
	angler.rod_on_stand = false
	stand.show_stand(false)
	_sync_technique()
	_pending_cast = Dice.NO_POINT
	_pending_trap = -1
	traps.clear()
	_refresh_traps()
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
	hud.perf = bool(GameState.setting("perf", false))
	_refresh_traps()
	# Rütbe dışarıdan değiştiyse (geliştirme sürümünde "Bütün bölgeleri aç"): erişim ve çitler.
	var rank := Rank.rank(GameState.db, GameState.save)
	if rank != _access_rank:
		_access_rank = rank
		session.set_access(Zones.open_ids(GameState.db, GameState.save, spot_id, in_boat))
		_update_gates()
		_announce_techniques()
	session.easy = bool(GameState.setting("easy", false))
	# Ayar çekişmenin ortasında değişirse (Ayarlar açıkken oyun donuk) süren çekişmeye de geçer.
	if session.reel != null and session.hooked != null:
		session.reel.easy = session.easy or session.hooked.scripted


## Uygulama öne geldi: oyun sürer, tuzakların dolması (oyun kapalıyken de) yenilenir.
func _on_focus_gained() -> void:
	_paused = false
	_refresh_traps()


func _on_focus_lost() -> void:
	# Arama, Denetim Merkezi, arka plan: çekişme donar, parmak bırakılmış sayılır.
	_paused = true
	input.release_all()
	session.release()
	_stop_loops()


## Makara, gerilim ve zil döngüleri susar (kaçtı, tutuldu, odak kaybı, ayarlar).
func _stop_loops() -> void:
	Sounds.set_loop("reel", false)
	Sounds.set_loop("strain", false)
	Sounds.set_loop("bell_run", false)


func _process(delta: float) -> void:
	# Odak kaybında ve bir panel (ayarlar, dükkân, defter...) açıkken oyun donar (çekişmedeki
	# balık kaçmasın). Balık kartı panel değildir: kart açıkken balık gösterimi sürer.
	if _paused or _panel_open():
		return
	if session.state == FishingSession.State.IDLE:
		session.angler = angler.pos2()
	_check_pending_cast()
	_check_pending_trap()
	_trap_clock += delta
	if _trap_clock >= TRAP_SYNC_EVERY:
		_trap_clock = 0.0
		_refresh_traps()
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
		["boat", func(screen: Vector2) -> bool: return not in_boat and scene.boat_hit(camera, screen)],
		["trap", func(screen: Vector2) -> bool:
			_trap_tap = -1 if in_boat else traps.hit(camera, screen)
			return _trap_tap >= 0],
	]
	input.targets_active = func() -> bool: return session.state == FishingSession.State.IDLE and not _card_up()
	add_child(input)
	input.target_tapped.connect(_on_target)
	input.walk_requested.connect(_on_walk_requested)
	input.cast_requested.connect(_on_cast_requested)
	input.action_pressed.connect(_on_action_down)
	input.action_released.connect(_on_action_up)
	input.walk_step.connect(func(dir: Vector2) -> void:
		if in_boat:
			return
		_pending_cast = Dice.NO_POINT
		_pending_trap = -1
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
	if session.state != FishingSession.State.IDLE or in_boat or _card_up():
		return
	_pending_cast = Dice.NO_POINT
	_pending_trap = -1
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
	# Tuzaktan ilk kerevitin kartı açılmak üzere (oturum boşta): dokunuş atış değil.
	if session.state != FishingSession.State.IDLE or _card_up():
		return
	_pending_trap = -1
	# Sandalda yürünmez: dokunulan yöne atılır (şamandıra menzilin içine düşer).
	if in_boat or angler.pos2().distance_to(target) <= session.range_m() - 0.3:
		angler.stop()
		_try_cast(target)
		return
	_pending_cast = target
	# Düz yürüyünce (kıyıda ya da kapalı çitte durur) menzile giriyorsa düz yürür; girmiyorsa (koyun
	# öbür yakası) kıyı yolundan hedefe en yakın kıyıya gider. Menzile girince atar.
	if _straight_reach(target) <= session.range_m() - 0.5:
		angler.walk_to(target)
	else:
		_walk_route(target)


## Kıyı yolundan yürür (yol bulunamazsa eski göllerde düz: ızgaranın dışında da yürünür;
## sınırlı dünyada yürünmez). Hedef kilitli bir bölgedeyse balıkçı çitin önünde durur, Dede ne
## zaman gidileceğini söyler; bekleyen atış iptal olur (kilitli suya atılmaz).
func _walk_route(target: Vector2) -> void:
	var points := path.route(angler.pos2(), target)
	if points.is_empty():
		if lake.world_band == INF:
			angler.walk_to(target)
		return
	angler.walk_path(points)
	var goal := path.nearest_open(target)
	if Dice.is_point(goal) and points[points.size() - 1].distance_to(goal) > 1.0:
		var reason := Zones.lock_reason(GameState.db, GameState.save, Zones.at(GameState.db, spot_id, target))
		if not reason.is_empty():
			_pending_cast = Dice.NO_POINT
			var key := str(reason["key"])
			_say("UI_DEDE_GATE")
			hud.toast(tr(key) % int(reason["rank"]) if key == "UI_ZONE_LOCKED_RANK" else tr(key), UiKit.ACCENT, "lock")


## Kilitli bölgelerin çitleri kıyı yolunu keser; bölge açılınca (rütbe) çit açılır. Yolun ızgarası
## yalnızca bir çit değiştiyse ve bir kez kurulur.
func _update_gates() -> void:
	var db := GameState.db
	var changed := false
	for z in db.zones_of(spot_id):
		var gates: Array = z["gates"]
		var closed := not Zones.unlocked(db, GameState.save, z)
		scene.set_gate_open(str(z["id"]), not closed)
		for i in gates.size():
			var g: PackedVector2Array = gates[i]
			changed = path.set_gate("%s_%d" % [z["id"], i], g[0], g[1], closed, false) or changed
	if changed:
		path.refresh()


## Hedefe düz yürüyünce (kıyıda, dünyanın sınırında ya da kapalı çitte durur) hedefe kalan uzaklık.
func _straight_reach(target: Vector2) -> float:
	var from := angler.pos2()
	var dir := (target - from).normalized()
	var stop := from
	var length := from.distance_to(target)
	var d := 0.2
	while d <= length:
		var p := from + dir * d
		if not lake.is_walkable(p) or path.crosses_closed_gate(from, p + dir * Angler.BODY):
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
	# Hangi yoldan gelirse gelsin (dokunuş, AT, bekleyen atış) önceki hedef (bekleyen tuzak da)
	# unutulur, yürüme biter.
	_pending_cast = Dice.NO_POINT
	_pending_trap = -1
	angler.stop()
	# Balıkçının yeri ve avlandığı bölge hemen (yürüyüş bu karede bittiyse): teknik bölgeye uyar
	# (sinek dere ağzı dışında atılmasın), kamış ve takımın görünüşü de.
	session.locate(angler.pos2())
	_follow_zone()
	_sync_technique()
	# Çok yakına (en kısa atıştan az) dokunulduysa o yönde biraz öteye atılır: suya dokunan
	# oyuncu "suya dokun" hatası almasın.
	var offset := target - angler.pos2()
	var near := session.technique.min_cast(session) + 0.3
	if offset.length() > 0.001 and offset.length() < near:
		target = angler.pos2() + offset.normalized() * near
	angler.face(target - angler.pos2())
	if session.cast(target):
		return
	# Dipte dokunuş bir yöndür: o yönde avlanılan bölgenin suyu yoksa (komşu bölgenin suyu) en yakın
	# uygun yöne atılır.
	var dir := _cast_dir(offset) if session.technique.id == "bottom" else Vector2.ZERO
	if dir != Vector2.ZERO and session.cast(angler.pos2() + dir * FORWARD_CAST):
		angler.face(dir)
		return
	Sounds.play("error")
	hud.toast(tr("UI_NO_WATER"), UiKit.MUTED)


func _on_action_down() -> void:
	if _card_up():
		return
	if session.state == FishingSession.State.IDLE:
		# Space / AT: balıkçının önüne; önü kara ise suyun olduğu en yakın yöne.
		var dir := _cast_dir()
		_try_cast(angler.pos2() + (dir if dir != Vector2.ZERO else angler.facing) * FORWARD_CAST)
		return
	session.press()


## Atış yönü: base yönü (verilmezse balıkçının baktığı yön); orada takım suya düşmüyorsa 15°
## adımlarla iki yana (arkaya kadar) bakılır, o yöne yakın ve suya iyi düşen yön seçilir. Hiçbir
## yönde düşmüyorsa Vector2.ZERO.
func _cast_dir(base: Vector2 = Vector2.ZERO) -> Vector2:
	var from := angler.pos2()
	session.angler = from
	var shortest := session.technique.min_cast(session)
	var facing := base.normalized() if base.length_squared() > 0.0001 else angler.facing
	var best := Vector2.ZERO
	var best_score := -INF
	for k in 25:
		var angle := deg_to_rad(15.0 * ((k + 1) >> 1)) * (1.0 if k % 2 == 1 else -1.0)
		var dir := facing.rotated(angle)
		# Takımın düşeceği yer tekniğin kuralıyla (spinde en kısa atış daha uzun).
		var landing := session.technique.landing_point(session, from + dir * FORWARD_CAST)
		if not Dice.is_point(landing) or from.distance_to(landing) < shortest:
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
			TechniqueHints.note_cast(GameState.save, session.technique.id)
			# Dede'nin öğüdü (Nine'nin sözü) atışın ipuçlarına yer açar. Takım öğüdü kalır: hangi takımın
			# gerektiğini söyleyen tek yer (kopunca hemen yeniden atan oyuncu da okuyabilsin).
			if not _line.begins_with(TOO_BIG_PREFIX):
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
			match bobber.kind:
				"lure":
					ripples.spawn(p, 0.45, 0.7)
					Sounds.play("lure")
				"sinker":
					# Ağır kurşun: büyük halka, pes şapırtı.
					ripples.spawn(p, 0.9, 1.0)
					Sounds.play("plop", 0.0, 0.8)
				"fly":
					# Sinek tüy gibi konar: küçük halka, kısık tıkırtı.
					ripples.spawn(p, 0.3, 0.6, Color(1, 1, 1, 0.6), 0.1)
					Sounds.play("lure", -8.0, 1.4)
				_:
					ripples.spawn(p, 0.7, 0.9)
					Sounds.play("plop")
			Sounds.haptic(12)
		"follow":
			# Yırtıcı oynayan yemin peşine düştü: arkasında bir halka, hafif titreşim.
			var follower := session.sim.find(int(e["shadow"]))
			if follower != null:
				ripples.spawn(follower.pos, follower.length * 0.7, 0.6, Color(1, 1, 1, 0.55), 0.1)
			Sounds.haptic(10)
		"strike":
			# Saldırı: su sıçrar. Basılıyken balık kendiliğinden takılır (ardından hook); değilse yemi
			# alır, VUR anı.
			if not bool(e.get("auto", false)):
				bobber.go_under()
			ripples.spawn(session.bobber, 1.0, 0.7, Color(1, 1, 1, 0.9), 0.16)
			Sounds.play("strike")
			Sounds.haptic(70)
			camera.shake(0.07)
		"turn_away":
			var bored := session.sim.find(int(e["shadow"]))
			if bored != null:
				ripples.spawn(bored.pos, bored.length * 0.6, 0.5, Color(1, 1, 1, 0.45), 0.1)
			hud.toast(tr("UI_TURNED_AWAY"), UiKit.MUTED)
		"snag":
			ripples.spawn(session.bobber, 0.5, 0.6, Color(1, 1, 1, 0.6), 0.12)
			hud.toast(tr("UI_SNAGGED"), UiKit.ACCENT)
			Sounds.play("snag")
			Sounds.haptic(40)
			# İlk takılmada Dede nedenini söyler (otlu yerde yem bekletilmez).
			if not GameState.save.flags.has("told_snag"):
				GameState.save.flags["told_snag"] = true
				_say("UI_DEDE_SNAG")
		"scare":
			var s := session.sim.find(int(e["shadow"]))
			if s != null:
				ripples.spawn(s.pos, s.length, 0.6, Color(1, 1, 1, 0.6), 0.16)
			Sounds.play("scare")
			if GameState.save.catches < HINT_CATCHES:
				hud.toast(tr("UI_SCARED"), UiKit.ACCENT)
		"sniff":
			# Dipte balık kokluyor: zil bir kez çınlar, kamışın ucu seğirir, kurşunun üstünde halka.
			stand.sniff()
			ripples.spawn(session.bobber, 0.4, 0.6, Color(1, 1, 1, 0.6), 0.1)
			Sounds.play("bell")
			Sounds.haptic(15)
		"run":
			# Koşu: zil durmadan çalar (döngü ve 2B zil _present_bottom'da), misina akar.
			ripples.spawn(session.bobber, 1.0, 0.8, Color(1, 1, 1, 0.9), 0.14)
			Sounds.haptic(70)
			camera.shake(0.06)
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
			var technique := session.technique.id
			var bait_id := Economy.equipped(GameState.db, GameState.save, "bait", technique)
			Economy.use_bait(GameState.db, GameState.save, technique)
			if Economy.equipped(GameState.db, GameState.save, "bait", technique) != bait_id:
				session.set_gear(_gear())
				_bait_out = true
			bobber.start_fight(bobber.global_position)
			ripples.spawn(session.bobber, 1.2, 0.7, Color(1, 1, 1, 0.9), 0.18)
			Sounds.play("hook")
			if int(e.get("too_big", 0)) > 0:
				# Takım bu iriliği taşımıyor: sakinken de kırmızıya çeker (Kolay'da yalnızca yavaş gelir).
				hud.toast(tr("UI_TOO_BIG"), UiKit.BAD, "burst")
				Sounds.haptic(80)
				camera.shake(0.16)
			else:
				Sounds.haptic(40)
				camera.shake(0.09)
		"warn":
			Sounds.play("warn")
			Sounds.haptic(35)
		"burst":
			# Alabalık sudan sıçrar (şapırtısı ve halkası sıçrayışın); öteki balık yerinde çırpınır.
			if not _jump_if_trout():
				ripples.spawn(session.fight_point(), 0.9, 0.5, Color(1, 1, 1, 0.8), 0.18)
				Sounds.play("splash")
				Sounds.haptic(20)
		"rise":
			# Sinek: alabalık halka çıkarır, sinek suya çekilir: VUR anı.
			bobber.go_under()
			ripples.spawn(session.bobber, 0.8, 0.8, Color(1, 1, 1, 0.9), 0.12)
			Sounds.play("rise")
			Sounds.haptic(50)
			camera.shake(0.04)
		"strain":
			# Gıcırtı döngüsü _present'te her kare (duraklamadan sonra da) açılır.
			Sounds.haptic(25)
		"lost":
			_on_lost(str(e["reason"]), int(e.get("too_big", 0)))
		"catch":
			_on_catch()
		"retrieve":
			# Süre oturumdan: takılan yemi kurtarmak uzun sürer.
			var steps := session.timer if session.state == FishingSession.State.RETRIEVING else session.rules.retrieve_steps
			bobber.fly_back(angler.rod_tip(), float(steps) / FishingRules.HZ)
			Sounds.play("reel_in")
			if str(e.get("reason", "")) == "still":
				# Sinek akmayan suya düştü: kımıldamadan döndü. İlk kez Dede nedenini söyler.
				hud.toast(tr("UI_FLY_STILL"), UiKit.ACCENT, "tech_fly")
				Sounds.haptic(20)
				if not GameState.save.flags.has("told_fly_still"):
					GameState.save.flags["told_fly_still"] = true
					_say("UI_DEDE_FLY_STILL")
		"idle":
			if bobber.look != Bobber.Look.RETURNING:
				bobber.hide_bobber()


## too_big: kaçan balık fazla iriyse yıldızı (Dede eksik takımı söyler).
func _on_lost(reason: String, too_big: int = 0) -> void:
	_stop_loops()
	if too_big > 0 and reason in ["snapped", "escaped"]:
		_advise_gear(too_big)
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
	_stop_loops()
	var info := session.last_catch
	var fish_id := str(info["fish"])
	var rarity := int(info["rarity"])
	var save := GameState.save
	var db := GameState.db
	var size_cm := int(info["size_cm"])
	var stars := int(info["stars"])
	var outcome := Records.add(save.records, fish_id, size_cm, stars, GameState.clock.now_unix())
	save.catches += 1
	var technique := session.technique.id
	CatchOdds.note_catch(db, save, rarity, Zones.place(db, spot_id, str(info.get("zone", ""))), technique)
	session.set_pity_floor(CatchOdds.pity_floor(db, save, Zones.place(db, spot_id, zone_id), technique))
	var ranked := Rank.add_xp(db, save, Rank.catch_xp(db, rarity, stars))
	var zone_news := false
	# Balık kovaya girer; kova doluysa oyun durmaz: balık göle döner (göl sevgisi verir). Koruma
	# altındaki tür (mersin) hep göle döner.
	var protected := Bucket.release_only(db, fish_id)
	var was_full := Bucket.is_full(db, save)
	var kept := Bucket.add(db, save, fish_id, size_cm, stars)
	if not kept:
		_release(fish_id, rarity)
	GameState.save_game()
	_refresh_status()
	# Rütbe atlama, kova dolu gibi bildirimler balığın etiketi sönünce (üst üste binmesin).
	hud.hold_toasts(CatchFx.HOLD_TIME)
	zone_news = _after_rank(ranked)
	# Bölgenin önerdiği teknik (Dede bir kez; yeni haber varsa sonraki balıkta). Oyuncu orada o teknikle
	# tuttuysa öneriye gerek kalmadı.
	if technique == str(db.zone(spot_id, zone_id).get("suggest", "")):
		save.flags[Elder.SUGGEST_FLAG % zone_id] = true
	var suggestion := "" if zone_news else Elder.suggestion(db, save, spot_id, zone_id, technique)
	if protected:
		hud.toast_later(tr("UI_RELEASED") % tr("FISH_" + fish_id), UiKit.ACCENT, "", "release")
	elif not kept:
		hud.toast_later(tr("UI_BUCKET_FULL"), UiKit.ACCENT, "", "release")
	elif Bucket.is_full(db, save) and not was_full and not zone_news:
		# Kova bu balıkla doldu: Dede hatırlatır (Nine'ye sat ki yenileri de sığsın). Aynı balıkla
		# yeni bölge açıldıysa Dede onu söyler; kova, sonraki balıkta "Kova dolu" bildirimiyle hatırlanır.
		_say("UI_DEDE_BUCKET")
	elif not suggestion.is_empty():
		save.flags[Elder.SUGGEST_FLAG % zone_id] = true
		_say(suggestion)
	elif not zone_news and _trap_line_due():
		_say_trap_open()
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


## Rütbe atladıysa (av ya da tuzak): oturumun erişimi ve çitler yenilenir; rütbe bildirimi, açılan
## bölge (adı rozetiyle, Dede söyler, harita düğmesi nabız gibi atar), açılan teknik ve tuzak. Dede
## bir haber söylediyse true (kovanın hatırlatması o zaman sonraki balığa kalır).
func _after_rank(ranked: Dictionary) -> bool:
	if int(ranked["new_rank"]) <= int(ranked["old_rank"]):
		return false
	var db := GameState.db
	var save := GameState.save
	var news := false
	session.set_access(Zones.open_ids(db, save, spot_id, in_boat))
	_update_gates()
	var rank := int(ranked["new_rank"])
	_access_rank = rank
	hud.toast_later(tr("UI_RANK_UP") % [rank, tr("RANK_" + db.rank_title(rank))], UiKit.ACCENT, "rank_up", "star")
	var opened := Zones.unlocked_between(db, spot_id, int(ranked["old_rank"]), rank)
	for z in opened:
		hud.toast_later(tr("UI_ZONE_OPENED") % tr("ZONE_" + str(z["id"])), UiKit.ACCENT, "", "zone:" + str(z["id"]))
	if not opened.is_empty():
		news = true
		_say("UI_DEDE_ZONE_OPEN")
		hud.pulse_map()
	# Yeni teknik ya da tuzak açıldı (tekniğin sözü bölgeninkinden önemli: Nine'nin sattığı kamış;
	# tuzağın sözü bölgenin sözünü ezmez, sonraki balığa kalır).
	if _announce_techniques(not opened.is_empty()):
		news = true
	return news


# --- Sunum ---------------------------------------------------------------------------

## Balıkçının bölgesi değişti mi (yürüdü, geçti): oranlar, defter ve dükkân o bölgenin; şans
## garantisi o bölgede gelebilen kademeler için.
func _follow_zone() -> void:
	var now := session.zone_id()
	if now != zone_id:
		# Başka bir bölgeye girildi (oturumun başı sayılmaz): adı kısa bir bildirimle. Gidilen bölge
		# haritada artık "Yeni!" değil.
		if not zone_id.is_empty() and not now.is_empty() and GameState.db.zones_of(spot_id).size() > 1:
			hud.toast(tr("ZONE_" + now), UiKit.TEXT, "zone:" + now)
		if not now.is_empty():
			GameState.save.flags["visited_" + now] = true
		zone_id = now
		shop_panel.zone_id = now
		book_panel.zone_id = now
		technique_panel.zone_id = now
		session.set_pity_floor(CatchOdds.pity_floor(GameState.db, GameState.save, Zones.place(GameState.db, spot_id, now),
				session.technique.id))
	_fit_technique()
	_zone_known = true


## Elindeki teknik bu bölgede avlanılmıyorsa (sinek dere ağzı dışında) olta boşken şamandıraya
## dönülür (bölgenin adından sonra bildirim; oturumun başında sessizce) ve teknik hatırlanır:
## avlanıldığı bölgeye dönünce kendiliğinden yeniden ele geçer (oyuncu bu arada başka teknik
## seçmediyse). Dere ağzının kıyı şeridi dar: sınırda gidip gelen balıkçı sineği yitirmez. Her kare.
func _fit_technique() -> void:
	if session.state != FishingSession.State.IDLE:
		return
	var db := GameState.db
	var save := GameState.save
	if save.technique != "float":
		_held_technique = ""
	if not _held_technique.is_empty() and Economy.technique_allowed(db, spot_id, zone_id, _held_technique) \
			and Economy.technique_ready(db, save, _held_technique):
		save.technique = _held_technique
		_held_technique = ""
		_use_technique_gear()
		if _zone_known:
			hud.toast_later(tr("UI_TECH_" + save.technique), UiKit.TEXT, "", "tech_" + save.technique)
		return
	if Economy.technique_allowed(db, spot_id, zone_id, save.technique):
		return
	_held_technique = save.technique
	save.technique = "float"
	_use_technique_gear()
	if _zone_known:
		hud.toast_later(tr("UI_TECH_FLY_ONLY"), UiKit.ACCENT, "", "tech_float")


## Elindeki tekniğin (save.technique) takımı oturuma geçer; şans garantisi o tekniğe göre.
func _use_technique_gear() -> void:
	_technique_pity(GameState.save.technique)
	session.set_gear(_gear())


func _present(delta: float) -> void:
	_follow_zone()
	_sync_technique()
	var reel := session.reel
	var fighting := session.state == FishingSession.State.FIGHTING and reel != null
	shadows.sync(session.sim, angler.pos2(), fighting and reel.thrashing(), delta)
	if fighting:
		var fp := session.fight_point()
		bobber.fight_point = Vector3(fp.x, 0.0, fp.y)
	var lure_reeling := _present_lure(delta)
	_present_fly(delta)
	var on_stand := _present_bottom()
	var show_line := session.line_out() or bobber.look == Bobber.Look.RETURNING
	line.visible = show_line and bobber.visible
	if line.visible:
		match session.state:
			FishingSession.State.CASTING:
				line.sag = 0.08
			FishingSession.State.FIGHTING:
				line.sag = 0.03
			_:
				# Çekilen yemde misina gergin; dipte uzun misina sehpadan kurşuna gerili.
				if lure_reeling:
					line.sag = 0.05
				elif bobber.kind == "sinker":
					line.sag = 0.1
				elif bobber.kind == "fly":
					line.sag = 0.22
				else:
					line.sag = 0.25 if bobber.kind == "lure" else 0.35
		line.shake = 0.0
		if fighting:
			line.shake = clampf(reel.tension, 0.0, 1.3) * (1.6 if reel.thrashing() else 0.6)
		elif on_stand and session.state == FishingSession.State.BITING:
			# Koşu: misina akar ve titrer.
			line.shake = 0.8
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
		FishingSession.State.CASTING, FishingSession.State.WAITING, FishingSession.State.NIBBLING, \
				FishingSession.State.BITING, FishingSession.State.FOLLOWING:
			# Dipte kamış sehpada: balıkçının eli boş.
			angler.pose = "free" if on_stand else ("reel" if lure_reeling else "hold")
		_:
			angler.pose = "free"
	if lure_reeling:
		# Yem çekilirken makaranın tıkırtısı (çekişmedekinden kısık ve pes).
		Sounds.set_loop("reel", true, -4.0, 0.8)
	elif on_stand and session.state == FishingSession.State.BITING:
		# Dipte koşu: misina makaradan akar (hızlı tıkırtı, zilin altında).
		Sounds.set_loop("reel", true, -6.0, 1.7)
	else:
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
	input.walking_allowed = session.state == FishingSession.State.IDLE and not _card_up() and not in_boat
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
	var far := _far_frame()
	var pitch := FollowCamera.PITCH
	if far.x >= 0.0:
		pitch = _far_pitch()
	elif line_view:
		pitch = LINE_PITCH
	camera.pitch = lerpf(camera.pitch, pitch, minf(1.0, delta * 2.5))
	var zoom := 1.0
	if far.x >= 0.0:
		zoom = far.y
	elif fighting:
		zoom = FIGHT_ZOOM
	elif catch_fx.is_showing():
		zoom = SHOW_ZOOM
	camera.zoom = lerpf(camera.zoom, zoom, minf(1.0, delta * 2.5))


## Yapay yem suda: oturumun yerinde (basılıyken balıkçıya gelir); oynarken arkasında iz halkaları
## (üst üste binince V biçimli iz), bırakınca batar. Yem çekiliyorsa true.
func _present_lure(delta: float) -> bool:
	if bobber.kind != "lure" or bobber.look != Bobber.Look.FLOATING:
		return false
	bobber.drag_to(Vector3(session.bobber.x, 0.0, session.bobber.y))
	var moving := session.holding and session.state in [FishingSession.State.WAITING, FishingSession.State.FOLLOWING]
	bobber.sink = move_toward(bobber.sink, 0.0 if moving else 1.0, delta * (5.0 if moving else 1.2))
	if moving:
		_wake_clock += delta
		if _wake_clock >= WAKE_EVERY:
			_wake_clock = 0.0
			ripples.spawn(session.bobber, 0.28, 0.6, Color(1, 1, 1, 0.5), 0.12)
	return moving


## Sinek suda: oturumun yerinde (akıntıyla sürüklenir), arkasında seyrek, küçük iz halkaları.
func _present_fly(delta: float) -> void:
	if bobber.kind != "fly" or bobber.look != Bobber.Look.FLOATING:
		return
	bobber.drag_to(Vector3(session.bobber.x, 0.0, session.bobber.y))
	_wake_clock += delta
	if _wake_clock >= FLY_TRAIL_EVERY:
		_wake_clock = 0.0
		ripples.spawn(session.bobber, 0.18, 0.5, Color(1, 1, 1, 0.4), 0.08)


## Çekişmede çırpınan balık sıçrayan türdense (fish.json fight.jumps) sudan sıçrar: balıkçıdan uzağa,
## orası su değilse (dar dere) suya düşen en yakın yöne, hiçbiri değilse yerinde. Sıçradıysa true.
func _jump_if_trout() -> bool:
	var fish := session.hooked
	if fish == null or session.state != FishingSession.State.FIGHTING or fish_jump.is_jumping():
		return false
	var def := GameState.db.fish_by_id(fish.fish_id)
	if not bool((def["fight"] as Dictionary).get("jumps", false)):
		return false
	var at := session.fight_point()
	var reach := FishJump.reach_for(fish.size_cm)
	var away := (at - angler.pos2()).normalized()
	var heading := Vector2.ZERO
	for k in 7:
		var dir := away.rotated(deg_to_rad(45.0 * ((k + 1) >> 1)) * (1.0 if k % 2 == 1 else -1.0))
		if lake.is_water(at + dir * reach) and not lake.on_dock(at + dir * reach):
			heading = dir
			break
	return fish_jump.jump(def, fish.size_cm, at, heading)


## Dip: kurşun suya düşünce kamış sehpaya konur (balıkçının yanında, atış yönüne bakar); koklamada
## zil tek tük çalar (sniff olayı), koşuda durmadan çalar ve 2B zil işareti çıkar. Kamış
## sehpadaysa true.
func _present_bottom() -> bool:
	var on := session.technique.id == "bottom" and session.state in [FishingSession.State.WAITING,
			FishingSession.State.NIBBLING, FishingSession.State.BITING]
	if on != angler.rod_on_stand:
		angler.rod_on_stand = on
		if on:
			stand.place(angler.global_position, session.bobber - angler.pos2(), _stand_room,
					RodStand.BOAT_SIDE if in_boat else RodStand.SIDE)
			stand.position.y = scene.stand_height(Vector2(stand.position.x, stand.position.z))
		stand.show_stand(on)
	var running := on and session.state == FishingSession.State.BITING
	stand.set_running(running)
	Sounds.set_loop("bell_run", running)
	return on


## Sehpa burada durabilir mi: karada ya da iskelede (sandalda balıkçının yanı: küpeşte).
func _stand_room(p: Vector2) -> bool:
	return in_boat or lake.is_walkable(p)


## Oturumun tekniği değişti (Takım Çantası, ilk kamış): elindeki kamış, suya atılan takımın görünüşü
## ve teknik düğmesinin ikonu. Takım suda ya da dönerken beklenir. Yeni bir tekniğe ilk geçişte Dede
## nasıl oynandığını söyler (ilk atışlarda ipuçları da: TechniqueHints).
func _sync_technique() -> void:
	var technique := session.technique.id
	if technique == _shown_technique or bobber.look != Bobber.Look.HIDDEN:
		return
	_shown_technique = technique
	angler.set_rod_style(technique)
	bobber.set_kind(Bobber.kind_for(technique))
	hud.set_technique(technique)
	var intro := "told_tech_" + technique
	if technique != "float" and not GameState.save.flags.has(intro):
		GameState.save.flags[intro] = true
		_say("UI_DEDE_TECH_FIRST_" + technique)
		_line_time = ADVICE_TIME


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
		var p := _line_point()
		var far := _far_frame()
		return a.lerp(Vector3(p.x, 0.0, p.y), far.x if far.x >= 0.0 else FOCUS_SHARE)
	return a


## Kameranın baktığı takım: çekişmede balık; kaçtıktan sonra geri dönen takımın görünen yeri (balık
## çekişmede kaçtıysa oturumun takımı eski atış noktasında kalır); yoksa oturumun takımı.
func _line_point() -> Vector2:
	match session.state:
		FishingSession.State.FIGHTING:
			return session.fight_point()
		FishingSession.State.LOST:
			return Vector2(bobber.position.x, bobber.position.z)
	return session.bobber


## Uzağa atılan teknikte (dip, sinek) olta suda: kameranın çerçevesi (odağın balıkçıyla takım
## arasındaki yoldaki payı, zoom; eğim _far_pitch). Takım (ya da çekişmedeki balık) uzaktaysa kamera
## uzaklaşır, balıkçı ipucu çubuğunun üstünde kalır; yakınsa eskisi gibi. Başka teknikte ya da olta
## suda değilse (-1, 1).
func _far_frame() -> Vector2:
	var technique := session.technique.id
	if not technique in ["bottom", "fly"] or not (session.line_out() or session.state == FishingSession.State.LOST):
		return Vector2(-1.0, 1.0)
	var fighting := session.state == FishingSession.State.FIGHTING
	var base := FIGHT_ZOOM if fighting else 1.0
	var ahead := (_line_point() - angler.pos2()).dot(FollowCamera.screen_up())
	if ahead < 1.0:
		return Vector2(FOCUS_SHARE, base)
	var max_zoom := maxf(base, FAR_MAX_ZOOM if technique == "bottom" else FLY_MAX_ZOOM)
	var view := FollowCamera.fit(ahead, _far_pitch(), FOCUS_SHARE, base, max_zoom, FAR_LOW, FAR_HIGH)
	return Vector2(view.x / ahead, view.y)


## Uzağa atılan teknikte kameranın eğimi: dipte yatık (FAR_PITCH), sinekte şamandıranınki gibi.
func _far_pitch() -> float:
	return FAR_PITCH if session.technique.id == "bottom" else LINE_PITCH


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
	var spoken := _line_time > 0.0 and key == _line
	var speaker := _line_speaker if spoken else "dede"
	if key != _hint_shown:
		_hint_shown = key
		# Yeni bir söz: konuşan konuşur (balon, baş sallama, oyuncuya bakış). Nine'nin selamı
		# dokunuşta söylenir (_on_shop).
		if not key.is_empty() and speaker == "dede":
			elder.say()
	var args: Array = []
	if spoken:
		args = _line_args_fn.call() if _line_args_fn.is_valid() else _line_args
	hud.show_hint(key, speaker, args)


## Gösterilecek ipucu: önce Dede'nin öğüdü ya da Nine'nin sözü (onlara dokununca), sonra ilk 3
## balığa kadar oyunun durumuna göre ipucu; yeni bir teknikte ilk atışlarda o tekniğin ipuçları
## (TechniqueHints). Kart açıkken ipucu yok.
func _hint_key() -> String:
	if card.visible:
		return ""
	if _line_time > 0.0:
		return _line
	var technique := session.technique.id
	if technique != "float":
		if not TechniqueHints.active(GameState.save, technique):
			return ""
		var key := TechniqueHints.key(technique, session.state)
		# Fazla iri balıkta "basılı tut" misinayı koparır (Kolay modda yalnızca yavaş gelir).
		if key == "UI_HINT_REEL" and session.too_big > 0 and not session.easy:
			key = "UI_HINT_TOO_BIG"
		if not key.is_empty():
			return key
		return "" if _hint_shown == _line else _hint_shown
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
			# Fazla iri balıkta "basılı tut" misinayı koparır (Kolay modda yalnızca yavaş gelir).
			return "UI_HINT_TOO_BIG" if session.too_big > 0 and not session.easy else "UI_HINT_REEL"
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
	angler.can_step = func(a: Vector2, b: Vector2) -> bool: return not path.crosses_closed_gate(a, b)
	_update_gates()


## Balık göle bırakıldı: defterde bırakılan sayısı, göl sevgisi ve sayaç.
func _release(fish_id: String, rarity: int) -> void:
	var save := GameState.save
	Records.release(save.records, fish_id)
	save.love += int(GameState.db.rarity_def(rarity).get("love", 0))
	save.stats["released"] = int(save.stats.get("released", 0)) + 1


## Sol üstteki para, kova ve rütbe; harita düğmesi ilk balıktan sonra (bölgeli gölde).
func _refresh_status() -> void:
	var db := GameState.db
	var save := GameState.save
	hud.set_status(save.coins, save.bucket.size(), Bucket.capacity(db, save), Rank.rank(db, save),
			Rank.progress(db, save))
	hud.map_allowed = save.catches > 0 and db.zones_of(spot_id).size() > 1
	hud.technique_allowed = _other_technique_open()


## Rütbesi gelmiş ama haber verilmemiş teknik (rütbe atladı ya da eski kayıt): adı ikonuyla, Dede
## söyler, teknik düğmesi nabız gibi atar. Her teknik bir kez (flags["told_open_<teknik>"]); kamışı
## zaten alınmışsa haber verilmez. Kerevit tuzağı da (flags["told_open_trap"]; tuzağı varsa haber
## verilmez; Dede'nin sözü flags["told_trap_line"]). Haber verildiyse true.
func _announce_techniques(quiet_trap: bool = false) -> bool:
	var db := GameState.db
	var save := GameState.save
	var rank := Rank.rank(db, save)
	var told := false
	for t: String in ContentDB.TECHNIQUES:
		var flag := "told_open_" + t
		if t == "float" or not db.has_technique(t) or rank < db.technique_rank(t) or save.flags.has(flag):
			continue
		save.flags[flag] = true
		if Economy.technique_ready(db, save, t):
			continue
		hud.toast_later(tr("UI_TECH_OPEN") % tr("UI_TECH_" + t), UiKit.ACCENT, "", "tech_" + t)
		_say("UI_DEDE_TECH_OPEN_" + t)
		hud.pulse_technique()
		told = true
	# Kerevit tuzağı (rütbe 3): bildirim ve nabız hemen; Dede'nin sözü aynı anda bir bölge (quiet_trap) ya
	# da teknik açıldıysa onları ezmez, sonraki balığa kalır (_trap_line_due).
	var trap_rank := TrapSim.rank(db)
	if trap_rank > 0 and rank >= trap_rank and not save.flags.has("told_open_trap"):
		save.flags["told_open_trap"] = true
		if TrapSim.owned(db, save) == 0:
			hud.toast_later(tr("UI_TRAP_OPEN"), UiKit.ACCENT, "", "tech_trap")
			hud.pulse_technique()
			if not quiet_trap and not told:
				_say_trap_open()
			told = true
	return told


## Dede tuzağı anlatır (bir kez).
func _say_trap_open() -> void:
	GameState.save.flags["told_trap_line"] = true
	_say("UI_DEDE_TRAP_OPEN")


## Tuzak açıldı ama Dede'nin sözü başka bir habere yenildi ve tuzak hâlâ alınmadı: sıradaki balıkta söyler.
func _trap_line_due() -> bool:
	var save := GameState.save
	return save.flags.has("told_open_trap") and not save.flags.has("told_trap_line") \
			and TrapSim.owned(GameState.db, save) == 0


## Şamandıradan başka bir teknik açıldı mı (rütbesi geldi ya da kamışı alındı): teknik düğmesi.
func _other_technique_open() -> bool:
	var db := GameState.db
	var save := GameState.save
	for t: String in ContentDB.TECHNIQUES:
		if t != "float" and db.has_technique(t) and (Rank.rank(db, save) >= db.technique_rank(t)
				or Economy.technique_ready(db, save, t)):
			return true
	return false


## Haritadan hızlı geçiş (docs/gdd.md §10.1): ekran kararır, balıkçı bölgenin atış noktasına geçer
## (kamera hemen gelir, gölgeler yeni yerin çevresinde doğar, bölgenin adı çıkar), ekran açılır.
func _travel(target: String) -> void:
	var db := GameState.db
	var z := db.zone(spot_id, target)
	if z.is_empty() or not Zones.unlocked(db, GameState.save, z) or session.state != FishingSession.State.IDLE:
		return
	# Sandal bölgesi: sandalla şamandıraya (sandaldaysa sıradaki şamandıraya).
	if bool(z["boat"]):
		_go_boat(_buoy + 1 if in_boat else 0)
		return
	var stands: Array[Vector2] = z["stands"]
	if stands.is_empty() or fade.busy():
		return
	var stand := stands[0]
	if not in_boat and angler.pos2().distance_to(stand) < 0.5:
		return
	_stop_for_travel()
	fade.play(func() -> void:
		_leave_boat()
		angler.place(stand)
		var k := lake.zone_index(target)
		angler.face_now(MapView.badge_anchor(lake, k) - stand)
		# Yeni yerin gölgeleri o bölgenin şans garantisiyle doğsun.
		session.set_pity_floor(CatchOdds.pity_floor(db, GameState.save, Zones.place(db, spot_id, target),
				session.technique.id))
		session.relocate(stand)
		_follow_zone()
		_snap_camera())


## Geçişten önce: yürüme ve bekleyen atış biter, parmaklar bırakılır; geçiş sesi ve titreşim.
func _stop_for_travel() -> void:
	angler.stop()
	_pending_cast = Dice.NO_POINT
	_pending_trap = -1
	input.release_all()
	Sounds.play("travel")
	Sounds.haptic(15)


## Kamera yeni yere hemen gelir (geçişte ekran karanlıkken).
func _snap_camera() -> void:
	camera.pitch = FollowCamera.PITCH
	camera.zoom = 1.0
	camera.snap(_focus())


## Haritadaki işaretler: Nine'nin dükkânı, Dede, iskeledeki sandal (sandaldayken sandal iğnenin
## yerinde, işareti yok) ve kerevit tuzakları.
func _map_marks() -> Array[Dictionary]:
	var front := ShopStall.front_for(lake.dock)
	var stall := front - ShopStall.facing_dir() * ShopStall.DEPTH * 0.5
	var marks: Array[Dictionary] = [
		{ "kind": "shop", "pos": stall },
		{ "kind": "dede", "pos": Vector2(elder.global_position.x, elder.global_position.z) },
	]
	if not in_boat:
		var boat := scene.boat_point()
		marks.append({ "kind": "boat", "pos": Vector2(boat.x, boat.z) })
	for t in GameState.save.traps:
		marks.append({ "kind": "trap", "pos": TrapSim.position(t) })
	return marks


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
## _update_hint Dede'yi konuşturur). args: biçimli sözün değerleri (tr(key) % args).
func _say(key: String, speaker: String = "dede", args: Array = []) -> void:
	_line = key
	_line_time = LINE_TIME
	_line_speaker = speaker
	_line_args = args
	_line_args_fn = Callable()
	Sounds.play("hint")


## Fazla iri balık kaçtı: Dede eksik takımı adıyla söyler: Nine'den alınacak, sende olup takılacak
## ya da Nine'nin onu hangi rütbede sattığı. Adlar her gösterişte o anki dilde kurulur.
func _advise_gear(stars: int) -> void:
	var advice := Economy.gear_for_stars(GameState.db, GameState.save, stars, session.technique.id)
	var buy: Array[String] = advice["buy"]
	var equip: Array[String] = advice["equip"]
	if buy.is_empty() and equip.is_empty():
		return
	if int(advice["rank"]) > 0:
		_say("UI_DEDE_TOO_BIG_RANK", "dede", [int(advice["rank"])])
	elif equip.is_empty():
		_say("UI_DEDE_TOO_BIG_BUY")
		_line_args_fn = func() -> Array: return [_gear_list(buy)]
	elif buy.is_empty():
		_say("UI_DEDE_TOO_BIG_EQUIP")
		_line_args_fn = func() -> Array: return [_gear_list(equip)]
	else:
		_say("UI_DEDE_TOO_BIG_BOTH")
		_line_args_fn = func() -> Array: return [_gear_list(buy), _gear_list(equip)]
	_line_time = ADVICE_TIME


## Takım adları cümlenin ortasında: ilk harf küçük ("cam elyafı kamış ve naylon misina").
func _gear_list(ids: Array[String]) -> String:
	var names: Array[String] = []
	for id in ids:
		var gear_name := tr("GEAR_" + id)
		names.append(gear_name.left(1).to_lower() + gear_name.substr(1))
	return names[0] if names.size() == 1 else tr("UI_LIST_AND") % [names[0], names[1]]


## Dünyadaki bir hedefe dokunuldu (InputRouter.hit_targets).
func _on_target(id: String) -> void:
	match id:
		"dede":
			_on_talk()
		"shop":
			_on_shop()
		"boat":
			_on_boat()
		"trap":
			_on_trap_tapped(_trap_tap)


## Sandala dokunuldu: sandal alındıysa binilir (derin ortanın ilk şamandırası); yoksa Dede söyler
## (rütbe yetiyorsa Nine'nin sandal sattığını).
func _on_boat() -> void:
	if session.state != FishingSession.State.IDLE or _card_up() or in_boat:
		return
	var db := GameState.db
	var deep := _boat_zone()
	if not deep.is_empty() and Zones.unlocked(db, GameState.save, deep):
		_go_boat(0)
		return
	var ready := not deep.is_empty() and Rank.rank(db, GameState.save) >= int(deep["rank"])
	_say("UI_DEDE_BOAT_SHOP" if ready else "UI_DEDE_BOAT")
	Sounds.haptic(10)


# --- Kerevit tuzakları --------------------------------------------------------------

## Tuzakların dolması şimdiye getirilir (gerçek saat; oyun kapalıyken de dolar) ve işaretler kayda
## uyar.
func _refresh_traps() -> void:
	var save := GameState.save
	TrapSim.update_all(GameState.db.rules, save, GameState.clock.now_unix())
	traps.sync(save, GameState.db.rules)


## Takım çantasında "Tuzak bırak": balıkçının yakınındaki sığ suya (baktığı yöne en yakın uygun yer)
## atılır; içeriği o an belli olur (TrapSim.place). Uygun yer yoksa nedeni bildirilir.
func _place_trap() -> void:
	if session.state != FishingSession.State.IDLE or _card_up() or traps.is_flying():
		return
	var db := GameState.db
	var save := GameState.save
	var at := angler.pos2()
	var p := TrapSim.spot_near(db, save, spot_id, zone_id, at, angler.facing)
	if not Dice.is_point(p):
		# Nedeni: tuzak yok, hepsi kurulu, bölge, öteki tuzağa çok yakın, çok derin ya da sığ su yok.
		var why := TrapSim.why_not(db, save, spot_id, zone_id, at, angler.facing)
		hud.toast(tr(why if not why.is_empty() else "UI_TRAP_NO_SPOT"), UiKit.ACCENT, "tech_trap")
		Sounds.play("error")
		return
	angler.stop()
	_pending_cast = Dice.NO_POINT
	_pending_trap = -1
	angler.face(p - at)
	angler.play_cast()
	var trap := TrapSim.place(db, save, spot_id, zone_id, p, GameState.clock.now_unix())
	GameState.save_game()
	traps.sync(save, db.rules)
	traps.throw(int(trap["id"]), angler.hand_point())
	Sounds.play("cast")
	Sounds.haptic(10)


## Atılan tuzak suya düştü: halka, ses, titreşim ve bildirim; ilk tuzakta Dede nasıl olduğunu söyler.
func _on_trap_landed(at: Vector2) -> void:
	ripples.spawn(at, 1.0, 0.8)
	Sounds.play("trap_place")
	Sounds.haptic(30)
	hud.toast(tr("UI_TRAP_PLACED") % roundi(GameState.db.rules.trap_fill_s / 60.0), UiKit.SUCCESS, "tech_trap")
	if not GameState.save.flags.has("told_trap_first"):
		GameState.save.flags["told_trap_first"] = true
		_say("UI_DEDE_TRAP_FIRST")


## Bir tuzağa dokunuldu (kıyıdayken): yakınsa toplanır; uzaktaysa balıkçı kıyı yolundan yürür, varınca
## toplar.
func _on_trap_tapped(id: int) -> void:
	if session.state != FishingSession.State.IDLE or _card_up():
		return
	_pending_trap = -1
	var index := TrapSim.find(GameState.save, id)
	if index < 0:
		return
	var p := TrapSim.position(GameState.save.traps[index])
	_pending_cast = Dice.NO_POINT
	Sounds.haptic(10)
	if angler.pos2().distance_to(p) <= TRAP_REACH:
		angler.stop()
		_collect_trap(id)
		return
	_pending_trap = id
	_walk_route(p)


## Yürüyüş bitti: bekleyen tuzağa yetişildiyse toplanır.
func _check_pending_trap() -> void:
	if _pending_trap < 0 or angler.is_walking() or session.state != FishingSession.State.IDLE:
		return
	var id := _pending_trap
	_pending_trap = -1
	var index := TrapSim.find(GameState.save, id)
	if index >= 0 and angler.pos2().distance_to(TrapSim.position(GameState.save.traps[index])) <= TRAP_REACH + 0.5:
		_collect_trap(id)


## Tuzak toplanır: içindeki kerevitler kovaya (sığmayan tuzakta bekler), deftere ve rütbe puanına
## (şans garantisi ilerlemez); tuzak yeniden kurulur. En irisi elde gösterilir, yeni türse kartı açılır.
## Boşsa boş tuzağın paneli açılır (bekle ya da kaldır); kova doluysa Dede Nine'yi söyler.
func _collect_trap(id: int) -> void:
	var db := GameState.db
	var save := GameState.save
	var rules := db.rules
	var index := TrapSim.find(save, id)
	if index < 0:
		return
	var trap := save.traps[index]
	var now := GameState.clock.now_unix()
	TrapSim.update(rules, trap, now)
	var p := TrapSim.position(trap)
	angler.face(p - angler.pos2())
	if TrapSim.ready(rules, trap) <= 0:
		input.release_all()
		trap_panel.open_trap(id)
		return
	if Bucket.is_full(db, save):
		hud.toast(tr("UI_TRAP_BUCKET_FULL"), UiKit.ACCENT, "tech_trap")
		_say("UI_DEDE_BUCKET")
		Sounds.play("error")
		return
	var result := TrapSim.collect(db, save, spot_id, index, now)
	var items: Array = result["items"]
	if items.is_empty():
		return
	GameState.save_game()
	_refresh_status()
	_refresh_traps()
	traps.bounce(id)
	ripples.spawn(p, 0.9, 0.7)
	Sounds.play("trap_collect")
	Sounds.haptic(40)
	var best: Dictionary = items[0]
	for item: Dictionary in items:
		if int(item["size_cm"]) > int(best["size_cm"]):
			best = item
	var fish_id := str(best["fish"])
	var def := db.fish_by_id(fish_id)
	var rarity := int(def["rarity"])
	var fresh := bool(result["new_species"])
	catch_fx.show_catch(def, int(best["size_cm"]), "%s ×%d" % [tr("FISH_" + fish_id), items.size()],
			UiKit.rarity_color(db, rarity), _show_point, false, func() -> Vector3: return angler.global_position,
			UiKit.rarity_icon(db, rarity))
	if fresh:
		angler.cheer()
		elder.cheer()
	else:
		angler.show_fish()
		elder.approve()
	Sounds.find(rarity)
	hud.hold_toasts(CatchFx.HOLD_TIME)
	var news := _after_rank(result["ranked"])
	var left := int(result["left"])
	if left > 0:
		hud.toast_later(tr("UI_TRAP_LEFT") % left, UiKit.ACCENT, "", "tech_trap")
	if (left > 0 or Bucket.is_full(db, save)) and not news:
		_say("UI_DEDE_BUCKET")
	if fresh:
		_card_info = { "fish": fish_id, "rarity": rarity, "size_cm": int(best["size_cm"]), "stars": int(best["stars"]) }
		_card_outcome = { "new_species": true }
		_card_wait = CARD_DELAY


## Boş tuzak kaldırıldı (panelden): tuzak takım çantasına döner. Panel açıkken kerevit girdiyse
## kaldırılmaz, toplanır (kayıp yok).
func _on_trap_remove(id: int) -> void:
	var save := GameState.save
	var rules := GameState.db.rules
	var index := TrapSim.find(save, id)
	if index < 0:
		return
	var trap := save.traps[index]
	TrapSim.update(rules, trap, GameState.clock.now_unix())
	if TrapSim.ready(rules, trap) > 0:
		_collect_trap(id)
		return
	var p := TrapSim.position(trap)
	TrapSim.remove(save, index)
	GameState.save_game()
	_refresh_traps()
	ripples.spawn(p, 0.8, 0.6)
	Sounds.play("trap_collect")
	Sounds.haptic(20)
	hud.toast(tr("UI_TRAP_REMOVED"), UiKit.TEXT, "tech_trap")


## Gölün sandal bölgesi (derin orta; yoksa boş).
func _boat_zone() -> Dictionary:
	for z in GameState.db.zones_of(spot_id):
		if bool(z["boat"]):
			return z
	return {}


## Sandalla bir şamandıraya (ekran kararır): sandal şamandıranın yanına gider, balıkçı içinde
## (yürünmez), gölgeler yalnızca derin ortada doğar; "Kıyıya dön" düğmesi çıkar. İlk açılışta Dede
## uyarır.
func _go_boat(buoy: int) -> void:
	var zone := _boat_zone()
	if zone.is_empty() or fade.busy() or session.state != FishingSession.State.IDLE:
		return
	var buoys: Array[Vector2] = zone["buoys"]
	if buoys.is_empty():
		return
	var index := posmod(buoy, buoys.size())
	var first := not GameState.save.flags.has("visited_" + str(zone["id"]))
	_stop_for_travel()
	fade.play(func() -> void:
		var at := scene.moor_boat(buoys[index])
		in_boat = true
		_buoy = index
		angler.place(at)
		angler.face_now(buoys[index] - at)
		session.set_access(Zones.open_ids(GameState.db, GameState.save, spot_id, true))
		session.set_pity_floor(CatchOdds.pity_floor(GameState.db, GameState.save,
				Zones.place(GameState.db, spot_id, str(zone["id"])), session.technique.id))
		session.relocate(at)
		hud.set_boat(true)
		_follow_zone()
		_snap_camera()
		if first:
			_say("UI_DEDE_BOAT_DEEP"))


## Sandaldan iner (sandal iskeleye döner, gölgeler yine kıyı bölgelerinde doğar). Kararmanın içinde.
func _leave_boat() -> void:
	if not in_boat:
		return
	in_boat = false
	_buoy = -1
	scene.dock_boat()
	session.set_access(Zones.open_ids(GameState.db, GameState.save, spot_id))
	hud.set_boat(false)


## "Kıyıya dön": iskele koyunun atış noktasına (ekran kararır).
func _return_to_shore() -> void:
	var start: Dictionary = Zones.at(GameState.db, spot_id, GameState.db.spot(spot_id)["start"])
	_travel(str(start.get("id", "")))


## Dede'ye dokunuldu: sıradaki öğüdü ipucu çubuğunda söyler (balon, baş sallama).
func _on_talk() -> void:
	if session.state != FishingSession.State.IDLE or _card_up():
		return
	var tips := Elder.tips(GameState.db, GameState.save)
	_tip_index = _tip_index % tips.size() + 1
	_say(tips[_tip_index - 1], "dede", Elder.tip_args(GameState.db, tips[_tip_index - 1]))
	Sounds.haptic(10)


## Nine'ye ya da dükkânına dokunuldu: Nine selam verir (balon, baş sallama, tezgâha uzanma) ve
## dükkân açılır (kova doluysa Kova sekmesi). Olta suda değilken açılır: oturum zaten boşta.
func _on_shop() -> void:
	if session.state != FishingSession.State.IDLE or _card_up():
		return
	nine.greet()
	Sounds.haptic(10)
	angler.stop()
	_pending_cast = Dice.NO_POINT
	_pending_trap = -1
	input.release_all()
	shop_panel.open_shop()


## Dükkân kapandı: Nine uğurlar (ipucu çubuğunda, sırayla uğurlama ve öğüt sözleri).
func _on_shop_closed() -> void:
	_nine_index = _nine_index % Nine.LINE_COUNT + 1
	_say(Nine.LINE_KEY % _nine_index, "nine")


## Takım değişti (dükkânda satın alma ya da kuşanma; bir tekniğin ilk kamışı o tekniği ele verir):
## oturumun takımı ve oranları yenilenir (teknik değiştiyse gölgeler yeniden doğar).
func _on_gear_changed() -> void:
	var gear := _gear()
	_technique_pity(gear.technique)
	session.set_gear(gear)
	_refresh_status()


## Takım çantasında bir teknik seçildi (olta boşta; panel kapanınca gölgeler yeni tekniğin oranıyla
## doğmuş olur).
func _on_technique_selected(technique: String) -> void:
	if session.state != FishingSession.State.IDLE or not Economy.technique_ready(GameState.db, GameState.save, technique):
		return
	_held_technique = ""
	GameState.save.technique = technique
	GameState.save_game()
	var gear := _gear()
	_technique_pity(gear.technique)
	session.set_gear(gear)
	hud.toast(tr("UI_TECH_" + technique), UiKit.TEXT, "tech_" + technique)


## Şans garantisi elindeki tekniğe göre (o teknikle gelebilen kademeler): teknik değişmeden önce
## verilir, gölgeler bu garantiyle yeniden doğar.
func _technique_pity(technique: String) -> void:
	session.set_pity_floor(CatchOdds.pity_floor(GameState.db, GameState.save, Zones.place(GameState.db, spot_id, zone_id),
			Techniques.resolve(technique)))


## Elindeki tekniğin kuşanılmış takımı (teknik hazır değilse şamandıranınki).
func _gear() -> GearStats:
	return Economy.gear_for(GameState.db, GameState.save, GameState.save.technique)


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
	hud.perf = bool(GameState.setting("perf", false))
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
	map_panel = MapPanel.new()
	map_panel.spot_id = spot_id
	layer.add_child(map_panel)
	map_panel.travel_requested.connect(_travel)
	technique_panel = TechniquePanel.new()
	technique_panel.spot_id = spot_id
	layer.add_child(technique_panel)
	technique_panel.technique_selected.connect(_on_technique_selected)
	technique_panel.shop_requested.connect(func(technique: String) -> void:
		var far := in_boat or angler.global_position.distance_to(nine.global_position) > SHOP_NEAR
		# Tuzak Ekstra sekmesinde (bakılan teknik elindeki).
		if technique == "trap":
			shop_panel.open_shop("extra", GameState.save.technique, far)
		else:
			shop_panel.open_shop("rod", technique, far))
	technique_panel.trap_requested.connect(_place_trap)
	trap_panel = TrapPanel.new()
	layer.add_child(trap_panel)
	trap_panel.remove_requested.connect(_on_trap_remove)
	var top := CanvasLayer.new()
	top.layer = 20
	add_child(top)
	fade = Fade.new()
	top.add_child(fade)
	hud.book_pressed.connect(func() -> void:
		input.release_all()
		book_panel.open_book())
	hud.shore_pressed.connect(func() -> void:
		if session.state == FishingSession.State.IDLE and not _card_up():
			_return_to_shore())
	hud.map_pressed.connect(func() -> void:
		if session.state != FishingSession.State.IDLE or _card_up():
			return
		input.release_all()
		angler.stop()
		_pending_cast = Dice.NO_POINT
		_pending_trap = -1
		map_panel.open_map(angler.pos2(), zone_id, _map_marks()))
	hud.technique_pressed.connect(func() -> void:
		if session.state != FishingSession.State.IDLE or _card_up():
			return
		input.release_all()
		angler.stop()
		_pending_cast = Dice.NO_POINT
		_pending_trap = -1
		technique_panel.open())
	hud.settings_pressed.connect(func() -> void:
		input.release_all()
		session.release()
		_stop_loops()
		settings_panel.open())
	hud.action_down.connect(func() -> void: input.pointer(InputRouter.BUTTON_POINTER, true))
	hud.action_up.connect(func() -> void: input.pointer(InputRouter.BUTTON_POINTER, false))
