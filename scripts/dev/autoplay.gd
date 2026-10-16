extends Node
## Geliştirici aracı (yalnızca debug): kayda dokunmadan botla oynar, ekran görüntüsü alır ve
## çıkar. Bot gerçek bir telefon gibi dokunma olayları gönderir (Input.parse_input_event).
## Ekran gerektirir (headless çalışmaz); --fixed-fps ile oyun zamanı sabit akar:
##   xvfb-run -a -s "-screen 0 1920x1080x24" godot --path . --rendering-driver opengl3 \
##     --audio-driver Dummy --resolution 1280x720 --fixed-fps 30 -- --autoplay --scenario=controls \
##     [--shots=/mutlak/yol] [--locale=tr] [--safe-inset=130]
## Senaryolar:
##   controls: kontrollerin denemesi; KONTROL satırları TAMAM olmalı (yürü, kıyıda dur, at,
##     geri sar, gölgeyi korkut, gölgeyi çek, erken dokunuş, ekranın her yeri VUR, basılı tut tut,
##     kart açıkken atış yok, patlamada bırakmazsa kopar, 8 sn'de yeni balık, düğme boyu ve
##     güvenli alan).
##   first: ilk açılış; senaryolu ilk balık (ekran görüntüleri; 45 sn denetimi).
## Bot dünyayı hazırlar (gölgeleri yerleştirir, türünü seçer); oyun kuralları aynen işler.

const WORLD_SEED := 4242
const HZ := FishingRules.HZ

var main: Node
var _shots_dir: String = ""
var _scenario: String = "controls"
var _locale: String = ""
var _inset: float = 0.0
var _overlay: Control
var _finger_pos: Dictionary = {}
var _results: Array[String] = []


func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--shots="):
			_shots_dir = arg.get_slice("=", 1)
		elif arg.begins_with("--scenario="):
			_scenario = arg.get_slice("=", 1)
		elif arg.begins_with("--locale="):
			_locale = arg.get_slice("=", 1)
		elif arg.begins_with("--safe-inset="):
			_inset = float(arg.get_slice("=", 1))
	if not _shots_dir.is_empty():
		DirAccess.make_dir_recursive_absolute(_shots_dir)
	GameState.persist = false
	var layer := CanvasLayer.new()
	layer.layer = 50
	add_child(layer)
	_overlay = load("res://scripts/dev/video_overlay.gd").new()
	layer.add_child(_overlay)
	if _inset > 0.0:
		# Yatay iPhone: çentik solda ya da sağda, ev çubuğu altta.
		UiKit.debug_insets = Vector4(_inset, 0.0, _inset, _inset * 0.45)
		_hud().call("_apply_safe_area")
	match _scenario:
		"first":
			_play_first.call_deferred()
		_:
			_play_controls.call_deferred()


# --- Senaryolar ------------------------------------------------------------------

func _play_controls() -> void:
	_use_save(1)
	await _wait(1.0)
	await _shot("01_basla")
	var angler := _angler()
	var lake := _session().lake
	# 1) Suyun öbür yanındaki karaya dokun: iskelenin kenarında (kıyıda) durmalı.
	var across := Vector2(5.0, 7.0)
	await _tap_world(across)
	await _wait_until(func() -> bool: return not angler.is_walking(), 6.0)
	var edge := angler.pos2()
	_check("kıyıda durur", lake.is_walkable(edge) and edge.distance_to(across) > 2.0 and lake.on_dock(edge))
	# 2) Karaya (iskelenin kara ucuna) dokun: oraya yürümeli.
	var land := Vector2(0.0, 7.8)
	await _tap_world(land)
	await _wait_until(func() -> bool: return not angler.is_walking(), 8.0)
	_check("karaya dokun → yürür", angler.pos2().distance_to(land) < 0.4)
	await _tap_world(Vector2(0.0, 4.0))
	await _wait_until(func() -> bool: return not angler.is_walking(), 8.0)
	# 3) Suya dokun: atmalı.
	await _tap_world(Vector2(0.0, 0.0))
	_check("suya dokun → atar", _state() == FishingSession.State.CASTING)
	await _wait_state(FishingSession.State.WAITING, 3.0)
	await _shot("02_atis")
	# 4) Beklerken dokun: geri sarmalı.
	await _tap(Vector2(400, 380))
	_check("beklerken dokun → geri sarar", _state() == FishingSession.State.RETRIEVING)
	await _wait_state(FishingSession.State.IDLE, 2.0)
	# 5) Gölgenin üstüne at: korkup kaçmalı.
	var target := _shadow_at(Vector2(1.5, -1.0), Vector2(0, 1), "")
	await _tap_world(target.pos)
	await _wait_state(FishingSession.State.WAITING, 3.0)
	await _wait_frames(2)
	_check("gölgenin üstüne atış → kaçar", target.mode == FishShadow.Mode.FLEE)
	await _tap(Vector2(400, 380))
	await _wait_state(FishingSession.State.IDLE, 2.0)
	# 6) Gölgenin önüne at: fark edip yaklaşmalı.
	var fish := _shadow_at(Vector2(-1.0, -3.2), Vector2(0, 1), "")
	await _tap_world(Vector2(-1.0, -1.0))
	await _wait_state(FishingSession.State.WAITING, 3.0)
	await _wait_until(func() -> bool: return fish.mode == FishShadow.Mode.APPROACH, 2.0)
	_check("gölgenin önüne atış → yaklaşır", fish.mode == FishShadow.Mode.APPROACH)
	await _wait(1.2)
	await _shot("03_yaklasiyor")
	# 7) Dürtmede dokun: "Erken davrandın", balık kaçar.
	await _wait_state(FishingSession.State.NIBBLING, 12.0)
	await _tap(Vector2(400, 380))
	_check("dürtmede dokunuş → erken", _state() == FishingSession.State.LOST and _session().last_loss == "early")
	await _wait(0.3)
	await _shot("04_erken")
	await _wait_state(FishingSession.State.IDLE, 3.0)
	# 8) Isırmada ekranın her yeri VUR; basılı tutunca tutulur (Kızılkanat).
	var rudd := _shadow_at(Vector2(1.0, -3.2), Vector2(0, 1), "rudd")
	await _tap_world(Vector2(1.0, -1.0))
	await _wait_state(FishingSession.State.BITING, 20.0)
	await _shot("05_isirdi")
	_touch(1, Vector2(260, 520), true)
	await _wait_frames(1)
	_check("ısırmada ekranın her yeri → çekişme", _state() == FishingSession.State.FIGHTING)
	await _wait(1.5)
	await _shot("06_cekisme")
	await _wait_state(FishingSession.State.CAUGHT, 25.0)
	_touch(1, Vector2(260, 520), false)
	_check("basılı tut → yakalanır", _state() == FishingSession.State.CAUGHT and str(_session().last_catch.get("fish", "")) == rudd.fish_id)
	await _wait(0.9)
	await _shot("07_kart")
	# 9) Kart açıkken suya dokun: atış olmamalı (dokunuş kartı kapatır); kart düğmeyle de kapanır.
	var card: FishCard = main.get("card")
	_check("yeni tür kartı açılır", card.visible)
	await _tap_world(Vector2(0.0, 0.0))
	_check("kart açıkken atış olmaz", _state() != FishingSession.State.CASTING and _state() != FishingSession.State.WAITING)
	if card.visible and card.ok_button != null:
		await _tap(card.ok_button.get_global_rect().get_center())
	await _wait_state(FishingSession.State.IDLE, 2.0)
	_check("kart kapanınca yeni atış", _state() == FishingSession.State.IDLE)
	# 10) Patlamada bırakmazsa misina kopar (Yayın, hep basılı).
	var wels := _shadow_at(Vector2(-0.5, -3.2), Vector2(0, 1), "wels")
	await _tap_world(Vector2(-0.5, -1.0))
	await _wait_state(FishingSession.State.BITING, 20.0)
	_touch(1, Vector2(260, 520), true)
	# Dokunuş olayı bir sonraki karede işlenir.
	await _wait_frames(2)
	var hooked := _state() == FishingSession.State.FIGHTING
	await _wait_until(func() -> bool: return _state() != FishingSession.State.FIGHTING, 20.0)
	await _shot("08_koptu")
	_touch(1, Vector2(260, 520), false)
	_check("patlamada bırakmazsa → kopar", hooked and _session().last_loss == "snapped")
	# 11) Kaçan balığın yerine 8 sn içinde yenisi gelir.
	var gone := await _wait_until(func() -> bool: return _session().sim.find(wels.id) == null, 4.0)
	var gone_at := _session().steps
	await _wait_until(func() -> bool: return _session().sim.shadows.size() >= 4, 10.0)
	var waited := float(_session().steps - gone_at) / HZ
	_check("8 sn içinde yeni balık (%.1f sn)" % waited, gone and _session().sim.shadows.size() >= 4 and waited <= 8.0)
	# 12) Düğmeler yeterince büyük ve güvenli alanın içinde.
	_check_buttons()
	for line in _results:
		print("KONTROL ", line)
	_quit()


func _play_first() -> void:
	_use_save(0)
	var session := _session()
	await _wait(1.5)
	await _shot("01_ilk_acilis")
	var first := session.sim.shadows[0]
	var start := session.steps
	await _tap_world(first.pos + Vector2(-0.4, 1.4))
	await _wait_state(FishingSession.State.WAITING, 3.0)
	await _wait(1.0)
	await _shot("02_ilk_gelir")
	await _wait_state(FishingSession.State.BITING, 30.0)
	await _shot("03_ilk_isirdi")
	_touch(1, Vector2(260, 520), true)
	await _wait(1.0)
	await _shot("04_ilk_cekisme")
	await _wait_state(FishingSession.State.CAUGHT, 25.0)
	_touch(1, Vector2(260, 520), false)
	var seconds := float(session.steps - start) / HZ + 1.5
	_check("ilk balık 45 sn içinde (%.1f sn)" % seconds, _state() == FishingSession.State.CAUGHT and seconds <= 45.0)
	await _wait(0.9)
	await _shot("05_ilk_kart")
	for line in _results:
		print("KONTROL ", line)
	_quit()


func _check_buttons() -> void:
	var view := get_viewport().get_visible_rect()
	var inset := UiKit.safe_insets(_hud())
	var safe := Rect2(view.position + Vector2(inset.x, inset.y),
			view.size - Vector2(inset.x + inset.z, inset.y + inset.w))
	var hud := _hud()
	var ok := true
	var notes := PackedStringArray()
	for b: TouchButton in hud.buttons():
		if not b.visible:
			continue
		var r := b.get_global_rect()
		var min_side := 280.0 if b == hud.action_button else 122.0
		if minf(r.size.x, r.size.y) < min_side - 0.5:
			ok = false
			notes.append("küçük %s" % str(r.size))
		if not safe.encloses(r):
			ok = false
			notes.append("güvenli alan dışında %s" % str(r))
	_check("düğmeler büyük ve güvenli alanda (pay %.0f)%s" % [inset.x, "" if ok else ": " + ", ".join(notes)], ok)


# --- Hazırlık ----------------------------------------------------------------------

## Bot için kayıt: sabit seed; catches = 0 ise ilk av senaryolu.
func _use_save(catches: int) -> void:
	var save := SaveData.create_new(GameState.clock.now_unix())
	save.seed = WORLD_SEED
	save.session = 1
	save.catches = catches
	save.settings = GameState.save.settings.duplicate()
	if not _locale.is_empty():
		save.settings["locale"] = _locale
	GameState.use_save(save)
	GameState.apply_locale()
	GameState.changed.emit()


## Canlı bir gölgeyi p'ye koyar (heading'e bakarak, uyuyan), diğerlerini uzağa park eder.
## fish_id verilirse balığın türü o olur (çekişme kontrolleri için).
func _shadow_at(p: Vector2, heading: Vector2, fish_id: String) -> FishShadow:
	var sim := _session().sim
	var parks := [Vector2(-10, -4), Vector2(-7, -5), Vector2(5.5, -2.5), Vector2(-12, -6)]
	var chosen: FishShadow = null
	var i := 0
	for s in sim.shadows:
		if s.mode == FishShadow.Mode.FLEE or s.mode == FishShadow.Mode.HOOKED:
			continue
		if chosen == null:
			chosen = s
			continue
		s.pos = parks[i % parks.size()]
		s.mode = FishShadow.Mode.PAUSE
		s.timer = 1_000_000
		i += 1
	if chosen == null:
		return null
	chosen.pos = p
	chosen.heading = heading.normalized()
	chosen.mode = FishShadow.Mode.PAUSE
	chosen.timer = 1_000_000
	if not fish_id.is_empty():
		var db := GameState.db
		chosen.fish_index = db.fish_index(fish_id)
		chosen.fish_id = fish_id
		chosen.rarity = int(db.fish_def(chosen.fish_index)["rarity"])
		chosen.size_cm = FishTable.size_cm(db.fish_def(chosen.fish_index), chosen.percentile)
		chosen.length = FishTable.shadow_length(db.fish_def(chosen.fish_index), chosen.percentile)
	return chosen


func _session() -> FishingSession:
	return main.get("session")


func _state() -> FishingSession.State:
	return _session().state


func _angler() -> Angler:
	return main.get("angler")


func _hud() -> Hud:
	return main.get("hud")


func _check(label: String, ok: bool) -> void:
	_results.append("%s: %s" % [label, "TAMAM" if ok else "OLMADI"])


# --- Dokunma taklidi -----------------------------------------------------------------

func _screen(world: Vector3) -> Vector2:
	return (main.get("camera") as Camera3D).unproject_position(world)


## Viewport koordinatını pencere koordinatına çevirir (Input.parse_input_event pencereyi bekler).
func _to_window(p: Vector2) -> Vector2:
	return get_viewport().get_screen_transform() * p


func _touch(index: int, pos: Vector2, pressed: bool) -> void:
	var ev := InputEventScreenTouch.new()
	ev.index = index
	ev.position = _to_window(pos)
	ev.pressed = pressed
	Input.parse_input_event(ev)
	if pressed:
		_finger_pos[index] = pos
		_overlay.call("finger_down", index, pos)
	else:
		_finger_pos.erase(index)
		_overlay.call("finger_up", index)


func _tap(pos: Vector2, index: int = 0) -> void:
	_touch(index, pos, true)
	await _wait_frames(2)
	_touch(index, pos, false)
	await _wait_frames(2)


## Göldeki bir noktaya dokunur (iskelede güverte yüksekliğinde).
func _tap_world(p: Vector2) -> void:
	var lake := _session().lake
	var y := LakeScene.DOCK_HEIGHT + 0.04 if lake.on_dock(p) else 0.0
	await _tap(_screen(Vector3(p.x, y, p.y)))


func _wait_state(state: FishingSession.State, timeout: float) -> bool:
	return await _wait_until(func() -> bool: return _state() == state, timeout)


func _quit() -> void:
	# Sesleri önce durdur: ses sunucusu çalanları bıraksın (çıkışta sızıntı uyarısı olmasın).
	Sounds.stop_all()
	await _wait_frames(6)
	get_tree().quit()


func _wait_frames(count: int) -> void:
	for i in count:
		await get_tree().process_frame


func _wait(seconds: float) -> void:
	await get_tree().create_timer(seconds).timeout


func _wait_until(condition: Callable, timeout: float) -> bool:
	var elapsed := 0.0
	while elapsed < timeout:
		if bool(condition.call()):
			return true
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	return bool(condition.call())


func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	if _shots_dir.is_empty():
		return
	var path := _shots_dir.path_join(shot_name + ".png")
	get_viewport().get_texture().get_image().save_png(path)
	print("ekran görüntüsü: ", path)
