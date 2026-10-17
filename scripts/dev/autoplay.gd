extends Node
## Geliştirici aracı (yalnızca debug): kayda dokunmadan botla oynar, ekran görüntüsü alır ve
## çıkar. Bot gerçek bir telefon gibi dokunma olayları gönderir (Input.parse_input_event).
## Ekran gerektirir (headless çalışmaz); --fixed-fps ile oyun zamanı sabit akar:
##   xvfb-run -a -s "-screen 0 1920x1080x24" godot --path . --rendering-driver opengl3 \
##     --audio-driver Dummy --resolution 1280x720 --fixed-fps 30 -- --autoplay --scenario=controls \
##     [--shots=/mutlak/yol] [--locale=tr] [--safe-inset=130]
## Senaryolar:
##   controls: kontrollerin denemesi; KONTROL satırları TAMAM olmalı (Dede'ye dokun konuşsun,
##     Nine'ye dokun selam versin, sandala dokun Dede konuşsun (atış yok), yürü, kıyıda dur,
##     Dede'nin yanından ve dükkânın önünden geç,
##     at, geri sar, gölgeyi korkut, gölgeyi çek, erken
##     dokunuş, ekranın her yeri VUR, basılı tut tut, kart açıkken atış yok, patlamada bırakmazsa
##     kopar, 8 sn'de yeni balık, düğme boyu ve güvenli alan).
##   first: ilk açılış; senaryolu ilk balık (ekran görüntüleri; 45 sn denetimi).
##   hero: balıkçı, Dede ve Nine yakın çekim (kamerayı bot sürer): Dede konuşur, ikisi, dükkân,
##     Nine selam verir, atış, bekleme, çekme, balığı gösterme, Dede sevinir.
##   fish: beş balık elde ve kartlarıyla, sonra ayarlar paneli (görsel denetim; kurallar işlemez).
##   shop: Nine'nin dükkânı (KONTROL satırları): dokununca açılır, para yetmezse ve rütbe tutmazsa
##     satın alınmaz, satın al ve kuşan, yem al, kova dolunca Dede uyarır, doluyken balık göle döner,
##     hepsini sat, son yem bitince solucana döner; sekme görüntüleri.
##   rarity: nadirlik ipuçları (görsel denetim): her nadirlikten bir gölge yan yana (pırıltı, ışıltı,
##     kabarcık), sonra her nadirliğin rozeti; gri tonlamalı kopyayla renk körü denetimi yapılır.
##   video: kısa tanıtım (--write-movie ile kaydedilir, ~70 sn): dönen bir oyuncu; Dede'ye dokun,
##     pırıltılı gölgeden nadir bir turna (VUR, çekişme, ışık sütunu, kart), kova dolar; Nine'ye git,
##     hepsini sat, cam kamışı al; Balık Defteri; mor ışıltılı Destansı bir yayın.
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
		"hero":
			_play_hero.call_deferred()
		"fish":
			_play_fish.call_deferred()
		"video":
			_play_video.call_deferred()
		"shop":
			_play_shop.call_deferred()
		"rarity":
			_play_rarity.call_deferred()
		_:
			_play_controls.call_deferred()


# --- Senaryolar ------------------------------------------------------------------

func _play_controls() -> void:
	_use_save(1)
	await _wait(1.0)
	await _shot("01_basla")
	var angler := _angler()
	var lake := _session().lake
	# 0) Dede'ye dokun: konuşmalı (öğüt ipucu çubuğunda, balon); balıkçı yürümemeli.
	var elder := _elder()
	await _tap(_screen(elder.head_point()))
	await _wait_frames(2)
	_check("Dede'ye dokun → konuşur", str(main.get("_hint_shown")) == Elder.TIP_KEY % 1
			and elder.bubble.is_showing() and not angler.is_walking())
	# 0b) Nine'ye dokun: selam verir ve dükkân açılır; balıkçı yürümez. Kapatınca Nine uğurlar
	# (sözü ipucu çubuğunda Nine'nin yüzüyle).
	var nine := _nine()
	var shop: ShopPanel = main.get("shop_panel")
	await _tap(_screen(nine.head_point()))
	await _wait_frames(3)
	var opened := shop.visible and nine.bubble.is_showing() and not angler.is_walking()
	await _tap(shop.close_button.get_global_rect().get_center())
	await _wait_frames(3)
	_check("Nine'ye dokun → dükkân açılır, kapanınca uğurlar", opened and not shop.visible
			and str(main.get("_hint_shown")) == Nine.LINE_KEY % 1 and _hud().hint_speaker() == "nine")
	# 0c) Defter düğmesi: Balık Defteri açılır; kapat düğmesiyle kapanır.
	var book: BookPanel = main.get("book_panel")
	await _tap(_hud().book_button.get_global_rect().get_center())
	await _wait_frames(3)
	var book_open := book.visible
	await _tap(book.close_button.get_global_rect().get_center())
	await _wait_frames(3)
	_check("defter düğmesi → defter açılır", book_open and not book.visible and not angler.is_walking())
	# 0d) Sandala dokun: Dede sandaldan söz eder; olta atılmaz, balıkçı yürümez.
	var scene: LakeScene = main.get("scene")
	await _tap(_screen(scene.boat_point()))
	await _wait_frames(3)
	_check("sandala dokun → Dede konuşur, atış yok", str(main.get("_hint_shown")) == "UI_DEDE_BOAT"
			and _session().state == FishingSession.State.IDLE and not angler.is_walking())
	# 1) Suyun öbür yanındaki karaya dokun: düz yol suyun üstünden geçer; balıkçı kıyı yolundan
	# dolaşıp varmalı, yolda hiç suya basmamalı.
	var across := Vector2(5.0, 7.0)
	var wet: Array[bool] = [false]
	await _tap_world(across)
	await _wait_until(func() -> bool:
		wet[0] = wet[0] or not lake.is_walkable(angler.pos2())
		return not angler.is_walking(), 12.0)
	_check("karşı kıyıya dokun → kıyı yolundan dolaşır (suya basmaz)", not wet[0] and angler.pos2().distance_to(across) < 0.4)
	# 2) Karaya (iskelenin kara ucuna) dokun: oraya yürümeli.
	var land := Vector2(0.0, 7.8)
	await _tap_world(land)
	await _wait_until(func() -> bool: return not angler.is_walking(), 8.0)
	_check("karaya dokun → yürür", angler.pos2().distance_to(land) < 0.4)
	# 2b) Dede'nin ötesindeki bir yere yürü: içinden geçmeden yanından kayıp varmalı.
	var block := elder.blocker()
	var center := Vector2(block.x, block.y)
	var nearest: Array[float] = [INF]
	var far_end := Vector2(0.6, 3.8)
	await _tap_world(far_end)
	await _wait_until(func() -> bool:
		nearest[0] = minf(nearest[0], angler.pos2().distance_to(center))
		return not angler.is_walking(), 8.0)
	_check("Dede'nin yanından geçer (en yakın %.2f m)" % nearest[0],
			nearest[0] >= block.z + Angler.BODY - 0.03 and angler.pos2().distance_to(far_end) < 0.4)
	# 2c) İskelenin kara ucundan dükkânın önünden geçip ötesine yürü: dükkânın (olta sehpası dahil)
	# içine girmemeli, sehpanın yanından kayıp varmalı.
	await _tap_world(land)
	await _wait_until(func() -> bool: return not angler.is_walking(), 8.0)
	var shop_blocks: Array[Vector3] = (main.get("shop") as ShopStall).blockers()
	var gap: Array[float] = [INF]
	var past_shop := Vector2(-3.0, 11.3)
	await _tap_world(past_shop)
	await _wait_until(func() -> bool:
		for b in shop_blocks:
			gap[0] = minf(gap[0], angler.pos2().distance_to(Vector2(b.x, b.y)) - b.z - Angler.BODY)
		return not angler.is_walking(), 8.0)
	_check("dükkânın içinden geçmez (pay %.2f m, hedefe %.2f m)" % [gap[0], angler.pos2().distance_to(past_shop)],
			gap[0] > -0.05 and angler.pos2().distance_to(past_shop) < 0.6)
	# İskeleye kara ucundan dön (düz yol kıyıya çıkar).
	await _tap_world(land)
	await _wait_until(func() -> bool: return not angler.is_walking(), 8.0)
	# 2d) Kilitli bölgeye (nilüferli koy, rütbe 3) yürü: balıkçı çitin önünde durur, Dede söyler.
	# Doğudaki hedef ekranda AT düğmesinin altına düşmesin diye balıkçı önce çitin yakınına konur.
	var gate_ok := (main.get("path") as ShorePath).gate_closed("lily_cove_0")
	angler.place(Vector2(7.0, 6.0))
	(main.get("camera") as FollowCamera).snap(main.call("_focus"))
	await _wait_frames(4)
	await _tap_world(Vector2(11.5, 3.0))
	await _wait_until(func() -> bool: return not angler.is_walking(), 8.0)
	_check("kilitli bölgenin çitinde durur, Dede söyler (%s, %s)" % [angler.pos2(), main.get("_hint_shown")],
			gate_ok and angler.pos2().x < 9.6 and str(main.get("_hint_shown")) == "UI_DEDE_GATE")
	angler.place(land)
	(main.get("camera") as FollowCamera).snap(main.call("_focus"))
	await _wait_frames(4)
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
	# Kart en kısa açık kalma süresinden önce düğmeyle de kapanmaz (görülmeden kapanmasın).
	await _wait(FishCard.MIN_OPEN)
	# Kart ekrana sığmak için küçülür (fit_scale): açıldıktan sonra HARİKA düğmesi yine en az 122 birim.
	var ok_side := 0.0
	if card.visible and card.ok_button != null:
		var ok_rect := card.ok_button.get_global_rect()
		ok_side = minf(ok_rect.size.x, ok_rect.size.y)
	_check("kartın düğmesi büyük (%.0f birim)" % ok_side, ok_side >= 121.5)
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


## Yakın çekim: balıkçı ve Dede. Kamerayı bot sürer (main.bot_camera).
func _play_hero() -> void:
	_use_save(1)
	main.set("bot_camera", true)
	var angler := _angler()
	var elder := _elder()
	await _wait(1.2)
	_frame_on(elder.head_point() + Vector3(0.0, -0.3, 0.0), 0.3)
	await _wait_frames(2)
	await _tap(_screen(elder.head_point()))
	await _wait(0.5)
	await _shot("01_dede_konusur")
	_frame_on(angler.global_position.lerp(elder.global_position, 0.5) + Vector3(0.0, 0.6, 0.0), 0.42)
	await _wait(0.3)
	await _shot("02_balikci_ve_dede")
	# Nine ve dükkânı: önce dükkânın tamamı, sonra Nine'ye dokun (selam) ve yakın çekim.
	var nine := _nine()
	_frame_on(nine.head_point() + Vector3(0.5, -0.5, 0.4), 0.55)
	await _wait(0.3)
	await _shot("02b_dukkan")
	_frame_on(nine.head_point() + Vector3(0.0, -0.3, 0.0), 0.3)
	await _wait_frames(2)
	# Dokunmak dükkânı açar (shop senaryosu); burada yalnızca selam.
	nine.greet()
	await _wait(0.6)
	await _shot("02c_nine_selam")
	# Atış normal görünümde (dokunulan su ekranda olsun), sonra yakına.
	_frame_on(angler.global_position + Vector3(0.0, 0.6, 0.0), 1.0)
	await _wait_frames(2)
	_shadow_at(Vector2(1.0, -3.2), Vector2(0, 1), "rudd")
	await _tap_world(Vector2(1.0, -1.0))
	var near := angler.global_position + Vector3(0.0, 0.8, 0.0)
	_frame_on(near, 0.36)
	await _wait(0.15)
	await _shot("03_atis")
	await _wait_state(FishingSession.State.WAITING, 3.0)
	await _wait(0.6)
	await _shot("04_bekleme")
	await _wait_state(FishingSession.State.BITING, 20.0)
	_touch(1, Vector2(260, 520), true)
	await _wait(1.4)
	await _shot("05_cekme")
	await _wait_state(FishingSession.State.CAUGHT, 25.0)
	_touch(1, Vector2(260, 520), false)
	# Kart açılmadan (CARD_DELAY) önce: elde balık, sonra sevinen Dede.
	await _wait(0.4)
	_frame_on(main.call("_show_point"), 0.34)
	await _wait_frames(2)
	await _shot("06_gosterme")
	_frame_on(elder.head_point() + Vector3(0.0, -0.25, 0.0), 0.34)
	await _wait_frames(2)
	await _shot("07_dede_sevinir")
	_quit()


## Nine'nin dükkânı: Nine'ye dokun → dükkân açılır; parası yetmeyince satın alınmaz; satın al →
## kuşanılır ve oturumun takımı değişir; eskisini yeniden kuşan; rütbe kilidi; yem al ve tak; kova
## dolunca Dede uyarır; hepsini sat → para; kapatınca Nine uğurlar. Her sekmenin ekran görüntüsü.
func _play_shop() -> void:
	_use_save(3)
	var db := GameState.db
	var save := GameState.save
	var angler := _angler()
	var nine := _nine()
	var shop: ShopPanel = main.get("shop_panel")
	await _wait(1.5)
	# 1) Nine'ye dokun: dükkân açılır (kova boş: Kamış sekmesi).
	await _tap(_screen(nine.head_point()))
	await _wait_frames(3)
	_check("Nine'ye dokun → dükkân açılır", shop.visible and nine.bubble.is_showing() and not angler.is_walking()
			and shop.current_tab() == "rod")
	await _wait(0.4)
	await _shot("01_kamis")
	# 2) Para yetmezken satın alma olmaz; Nine söyler.
	await _tap_control(shop.find_child("Tab_reel", true, false))
	await _wait_frames(2)
	await _shot("02_makara")
	var smooth := "reel_smooth"
	await _tap_card(shop, smooth, -1)
	_check("parası yetmeyince satın alınmaz", save.coins == 0 and not Economy.owns(db, save, smooth)
			and str(shop.get("_line_key")) == "UI_NINE_NO_COINS")
	# 3) Para ver (bot); satın al → kuşanılır, oturumun takımı değişir.
	save.coins = 1000
	shop.refresh()
	await _wait_frames(2)
	await _tap_card(shop, smooth, -1)
	await _wait_frames(2)
	_check("satın al → kuşanılır", Economy.owns(db, save, smooth) and Economy.equipped(db, save, "reel") == smooth
			and save.coins == 1000 - int(db.gear_item(smooth)["price"])
			and is_equal_approx(_session().gear.reel_speed, float(db.gear_item(smooth)["reel_speed"])))
	await _wait(0.3)
	await _shot("03_satin_alindi")
	# 4) Eski makarayı yeniden kuşan.
	await _tap_card(shop, "reel_basic", 0)
	await _wait_frames(2)
	_check("kuşan → eski makara takılır", Economy.equipped(db, save, "reel") == "reel_basic"
			and is_equal_approx(_session().gear.reel_speed, float(db.gear_item("reel_basic")["reel_speed"])))
	# 5) Rütbe kilidi: cam kamış rütbe 2 ister.
	await _tap_control(shop.find_child("Tab_rod", true, false))
	await _wait_frames(2)
	var coins := save.coins
	await _tap_card(shop, "rod_float_glass", -1)
	_check("rütbe kilidi → satın alınmaz", save.coins == coins and not Economy.owns(db, save, "rod_float_glass")
			and str(shop.get("_line_key")) == "UI_NINE_RANK")
	await _wait(0.3)
	await _shot("04_kamis_kilit")
	# 6) Yem: kurtçuk al (20 adet) ve tak; oturumun yem çekimi değişir.
	await _tap_control(shop.find_child("Tab_bait", true, false))
	await _wait_frames(2)
	await _tap_card(shop, "bait_maggot", -1)
	await _wait_frames(2)
	_check("yem al → takılır", int(save.baits.get("bait_maggot", 0)) == 20 and Economy.equipped(db, save, "bait") == "bait_maggot"
			and _session().gear.attraction("perch") > 1.0)
	await _wait(0.3)
	await _shot("05_yem")
	_check_panel_buttons(shop, "dükkân düğmeleri")
	for tab in ["line", "tackle", "extra"]:
		await _tap_control(shop.find_child("Tab_" + tab, true, false))
		await _wait(0.3)
		await _shot("06_%s" % tab)
	# Kartlar ShopPanel.CARD boyunu aşmaz; panel sekmeden sekmeye büyüyüp küçülmez.
	var biggest := Vector2.ZERO
	var heights: Array[float] = []
	var dialog: Control = shop.get("_panel")
	for tab in ["rod", "reel", "line", "tackle", "bait", "extra", "sell"]:
		await _tap_control(shop.find_child("Tab_" + tab, true, false))
		await _wait_frames(3)
		for node in shop.find_children("Card_*", "PanelContainer", true, false):
			biggest = biggest.max((node as Control).get_combined_minimum_size())
		heights.append(dialog.size.y)
	_check("kartlar CARD boyunda (en büyüğü %dx%d), panel boyu sabit (%d-%d)" % [int(biggest.x), int(biggest.y),
			int(heights.min()), int(heights.max())], biggest.x <= ShopPanel.CARD.x + 0.5
			and biggest.y <= ShopPanel.CARD.y + 0.5 and float(heights.max()) - float(heights.min()) < 1.0)
	await _tap(shop.close_button.get_global_rect().get_center())
	await _wait_frames(3)
	_check("kapanınca Nine uğurlar", not shop.visible and _hud().hint_speaker() == "nine")
	# 7) Kovada bir yer kala bir balık tut: kova dolar, Dede uyarır. Kızılkanat önceden büyük bir
	# rekorla defterde: yeni tür ya da rekor kartı açılmasın.
	Records.add(save.records, "rudd", 999, 3, 0)
	var fill: Array[String] = ["rudd", "carp", "perch"]
	for i in Bucket.capacity(db, save) - 1:
		Bucket.add(db, save, fill[i % fill.size()], 20 + i * 3, 1)
	_shadow_at(Vector2(1.0, -3.2), Vector2(0, 1), "rudd")
	await _tap_world(Vector2(1.0, -1.0))
	await _wait_state(FishingSession.State.BITING, 20.0)
	_touch(1, Vector2(260, 520), true)
	await _wait_state(FishingSession.State.CAUGHT, 25.0)
	_touch(1, Vector2(260, 520), false)
	await _wait_frames(3)
	_check("kova dolunca Dede uyarır", Bucket.is_full(db, save) and str(main.get("_hint_shown")) == "UI_DEDE_BUCKET")
	await _wait(0.3)
	await _shot("07a_kova_doldu")
	await _wait_state(FishingSession.State.IDLE, 5.0)
	# 7b) Kova doluyken bir balık daha: kovaya girmez, göle döner; bildirimi göle dönen balıkla.
	var held := save.bucket.size()
	_shadow_at(Vector2(1.0, -3.2), Vector2(0, 1), "rudd")
	await _tap_world(Vector2(1.0, -1.0))
	await _wait_state(FishingSession.State.BITING, 20.0)
	_touch(1, Vector2(260, 520), true)
	await _wait_state(FishingSession.State.CAUGHT, 25.0)
	_touch(1, Vector2(260, 520), false)
	var toast: Label = _hud().get("_toast")
	var toast_icon: GameIcon = _hud().get("_toast_icon")
	for i in 200:
		if toast.is_visible_in_tree() and toast.text == UiKit.upper(tr("UI_BUCKET_FULL")):
			break
		await _wait_frames(1)
	_check("kova doluyken balık göle döner (bildirim ikonlu)", save.bucket.size() == held
			and toast.is_visible_in_tree() and toast_icon.visible and toast_icon.kind == "release")
	await _wait(0.2)
	await _shot("07b_kova_dolu_birak")
	await _wait_state(FishingSession.State.IDLE, 5.0)
	# 8) Nine'ye dokun: kova dolu, Kova sekmesi açılır; hepsini sat → para.
	await _tap(_screen(nine.head_point()))
	await _wait_frames(3)
	await _wait(0.4)
	await _shot("07_kova_dolu")
	var value := Economy.bucket_value(db, save)
	coins = save.coins
	_check("kova doluyken Kova sekmesi açılır", shop.visible and shop.current_tab() == "sell" and value > 0)
	await _tap_control(shop.find_child("SellAll", true, false))
	await _wait_frames(3)
	_check("hepsini sat → para", save.bucket.is_empty() and save.coins == coins + value
			and str(shop.get("_line_key")) == "UI_NINE_SOLD")
	await _wait(0.4)
	await _shot("08_satildi")
	await _tap(shop.close_button.get_global_rect().get_center())
	await _wait_frames(3)
	# 9) Son yem balık takılınca biter: oturum solucana döner (yeni gölgeler solucanın oranlarıyla,
	# defterdeki gibi); olta dönünce Dede söyler.
	save.baits["bait_maggot"] = 1
	Economy.equip(db, save, "bait_maggot")
	main.call("_on_gear_changed")
	_shadow_at(Vector2(1.0, -3.2), Vector2(0, 1), "rudd")
	await _tap_world(Vector2(1.0, -1.0))
	await _wait_state(FishingSession.State.BITING, 20.0)
	_touch(1, Vector2(260, 520), true)
	await _wait_state(FishingSession.State.FIGHTING, 3.0)
	await _wait_frames(2)
	var reverted := Economy.equipped(db, save, "bait") == "bait_worm" \
			and is_equal_approx(_session().gear.attraction("perch"), 1.0)
	await _wait_state(FishingSession.State.CAUGHT, 25.0)
	_touch(1, Vector2(260, 520), false)
	await _wait_until(func() -> bool: return str(main.get("_hint_shown")) == "UI_DEDE_BAIT_OUT", 10.0)
	_check("son yem biter → solucana döner, Dede söyler", reverted
			and str(main.get("_hint_shown")) == "UI_DEDE_BAIT_OUT")
	await _wait(0.3)
	await _shot("09_yem_bitti")
	_check_buttons()
	for line in _results:
		print("KONTROL ", line)
	_quit()


## Bir paneldeki bütün düğmeler en az 122 birim ve güvenli alanın içinde mi? (Telefon oranında
## çalıştır: 16:9 ve çentik payıyla panel ekrana sığmak için küçülür.)
func _check_panel_buttons(panel: Control, label: String) -> void:
	var view := get_viewport().get_visible_rect()
	var inset := UiKit.safe_insets(panel)
	var safe := Rect2(view.position + Vector2(inset.x, inset.y), view.size - Vector2(inset.x + inset.z, inset.y + inset.w))
	var notes := PackedStringArray()
	var count := 0
	for node in panel.find_children("*", "BaseButton", true, false):
		var b := node as BaseButton
		if not b.is_visible_in_tree():
			continue
		count += 1
		var r := b.get_global_rect()
		if minf(r.size.x, r.size.y) < 121.5:
			notes.append("%s küçük %s" % [b.name, str(r.size)])
		if not safe.encloses(r):
			notes.append("%s güvenli alan dışında" % b.name)
	_check("%s büyük ve güvenli alanda (%d düğme)%s" % [label, count, "" if notes.is_empty() else ": " + ", ".join(notes)],
			notes.is_empty() and count > 0)


## Nadirlik ipuçları: her nadirlikten bir gölge iskelenin önünde yan yana; birkaç anda görüntü
## (Nadir'in pırıltısı aralıklı). Sonra kartları nadirlik rozetleriyle.
func _play_rarity() -> void:
	_use_save(3)
	main.set("bot_camera", true)
	var db := GameState.db
	var sim := _session().sim
	await _wait(1.0)
	var kinds: Array[String] = ["rudd", "carp", "pike", "wels"]
	for i in mini(kinds.size(), sim.shadows.size()):
		var s := sim.shadows[i]
		var def := db.fish_by_id(kinds[i])
		s.fish_id = kinds[i]
		s.fish_index = db.fish_index(kinds[i])
		s.rarity = int(def["rarity"])
		s.percentile = 700000
		s.length = FishTable.shadow_length(def, s.percentile)
		s.pos = Vector2(-2.4 + i * 1.6, 0.6)
		s.heading = Vector2(1, 0)
		s.mode = FishShadow.Mode.PAUSE
		s.timer = 1_000_000
	_frame_on(Vector3(0.0, 0.0, 0.8), 0.55, deg_to_rad(62.0))
	for k in 4:
		await _wait(0.65)
		await _shot("0%d_golgeler" % (k + 1))
	var card: FishCard = main.get("card")
	for r in db.rarities.size():
		var rarity := r
		var fish_id := ""
		for f in db.fish:
			if int(f["rarity"]) == rarity:
				fish_id = str(f["id"])
		if fish_id.is_empty():
			continue
		var def := db.fish_by_id(fish_id)
		card.show_catch(db, {"fish": fish_id, "size_cm": FishTable.size_cm(def, 800000), "stars": 3, "rarity": rarity},
				{"new_species": true})
		await _wait(0.5)
		await _shot("1%d_kart_%s" % [rarity, db.rarity_id(rarity)])
		card.close_card()
		await _wait(0.1)
	# Balık Defteri: iki tür tutulmuş (kızılkanat, turna), öbürleri siluet; tutulan ve tutulmayan
	# bir türün ayrıntısı.
	var save := GameState.save
	Records.add(save.records, "rudd", 27, 3, 0)
	Records.add(save.records, "pike", 96, 4, 0)
	Records.add(save.records, "pike", 81, 2, 0)
	Records.release(save.records, "pike")
	save.pity["rare"] = 31
	save.pity["epic"] = 140
	var book: BookPanel = main.get("book_panel")
	book.open_book("pike")
	await _wait(0.4)
	await _shot("20_defter_turna")
	book.open_book("wels")
	await _wait(0.4)
	await _shot("21_defter_yayin_siluet")
	book.close_panel()
	_quit()


## Bir kontrolün ortasına dokunur.
func _tap_control(control: Control) -> void:
	await _tap(control.get_global_rect().get_center())


## Dükkânda bir kartın düğmesine dokunur (which: sıra; -1 sonuncusu, ör. fiyat).
func _tap_card(shop: ShopPanel, id: String, which: int) -> void:
	var card := shop.find_child("Card_" + id, true, false)
	if card == null:
		_results.append("kart yok: " + id)
		return
	var buttons := card.find_children("*", "Button", true, false)
	if buttons.is_empty():
		_results.append("kartta düğme yok: " + id)
		return
	await _tap_control(buttons[which] as Control)


## Beş balık: elde (CatchFx) ve kartı. Görsel denetim; oturum kuralları işlemez.
func _play_fish() -> void:
	_use_save(1)
	main.set("bot_camera", true)
	var db := GameState.db
	var catch_fx: CatchFx = main.get("catch_fx")
	var card: FishCard = main.get("card")
	# Balık portreleri (kart resimleri) açılışta çizilir.
	await _wait(2.0)
	var show: Vector3 = main.call("_show_point")
	var index := 0
	for def in db.fish:
		index += 1
		var id := str(def["id"])
		var percentile := 800000
		var rarity := int(def["rarity"])
		var info := {"fish": id, "size_cm": FishTable.size_cm(def, percentile),
				"stars": FishTable.stars(percentile), "rarity": rarity}
		catch_fx.show_catch(def, int(info["size_cm"]), tr("FISH_" + id), UiKit.rarity_color(db, rarity),
				func() -> Vector3: return show, rarity >= Records.CARD_RARITY,
				func() -> Vector3: return _angler().global_position, UiKit.rarity_icon(db, rarity))
		# Oyundaki gösteri kamerası (main: SHOW_ZOOM, odak gösteri noktasının biraz altı).
		_frame_on(show + Vector3(0.0, -0.2, 0.0), float(main.get("SHOW_ZOOM")))
		await _wait(0.7)
		await _shot("%d_%s_elde" % [index, id])
		card.show_catch(db, info, {"new_species": true})
		await _wait(0.5)
		await _shot("%d_%s_kart" % [index, id])
		card.close_card()
		catch_fx.clear()
		await _wait(0.2)
	# Ayarlar paneli (düğme boyları, sığma).
	(main.get("settings_panel") as SettingsPanel).open()
	await _wait(0.5)
	await _shot("6_ayarlar")
	_quit()


## Tanıtım videosu. Oyun zamanı --fixed-fps ile kare kare akar; bekleyişler oyun zamanıyla.
func _play_video() -> void:
	# Dönen bir oyuncu: üç tür defterde, kovada bir yer kalmış, rütbe 2, biraz para.
	_use_save(4)
	var db := GameState.db
	var save := GameState.save
	save.coins = 260
	save.xp = 60
	for f: Array in [["rudd", 26, 4], ["carp", 52, 3], ["perch", 31, 2]]:
		Records.add(save.records, f[0], f[1], f[2], 0)
	var fill: Array[String] = ["rudd", "carp", "perch", "rudd", "rudd"]
	for i in Bucket.capacity(db, save) - 1:
		Bucket.add(db, save, fill[i % fill.size()], 20 + i * 4, 2)
	GameState.changed.emit()
	var session := _session()
	var elder := _elder()
	var nine := _nine()
	var angler := _angler()
	var card: FishCard = main.get("card")
	var shop: ShopPanel = main.get("shop_panel")
	var book: BookPanel = main.get("book_panel")
	await _wait(1.4)
	# Dede'ye dokun: öğüdünü söyler.
	await _tap(_screen(elder.head_point()))
	await _wait(2.0)
	# Nadir bir turna: gölgesinde pırıltı; önüne at, dürtmeler, VUR, çekişme, ışık sütunu, kart.
	# Kovanın son yeri dolar: Dede uyarır.
	_shadow_at(Vector2(-1.2, -3.0), Vector2(0.2, 1.0), "pike", 860000)
	await _wait(1.6)
	await _tap_world(Vector2(-1.0, -0.8))
	await _wait_state(FishingSession.State.BITING, 30.0)
	await _wait(0.2)
	await _reel_like_player(7, 40.0)
	await _wait(3.4)
	await _shot("v1_turna_kart")
	if card.visible and card.ok_button != null:
		await _tap(card.ok_button.get_global_rect().get_center())
	await _wait_state(FishingSession.State.IDLE, 3.0)
	await _wait(1.0)
	# İskelenin kara ucuna yürü, Nine'ye dokun: kova dolu, Kova sekmesi; hepsini sat.
	await _tap_world(Vector2(0.0, 7.8))
	await _wait_until(func() -> bool: return not angler.is_walking(), 8.0)
	await _wait(0.3)
	await _tap(_screen(nine.head_point()))
	await _wait(1.6)
	await _shot("v2_kova")
	await _tap_control(shop.find_child("SellAll", true, false))
	await _wait(1.6)
	await _shot("v3_satildi")
	# Kamış sekmesi: cam kamışı al (kuşanılır).
	await _tap_control(shop.find_child("Tab_rod", true, false))
	await _wait(1.0)
	await _tap_card(shop, "rod_float_glass", -1)
	await _wait(1.8)
	await _shot("v4_cam_kamis")
	await _tap(shop.close_button.get_global_rect().get_center())
	await _wait(1.4)
	# Balık Defteri: turna artık defterde; yayın bir siluet (ipuçları ve şansı).
	await _tap(_hud().book_button.get_global_rect().get_center())
	await _wait(1.2)
	await _tap_control(book.find_child("Fish_pike", true, false))
	await _wait(1.6)
	await _tap_control(book.find_child("Fish_wels", true, false))
	await _wait(2.2)
	await _shot("v5_defter_yayin")
	await _tap(book.close_button.get_global_rect().get_center())
	await _wait(0.8)
	# İskelenin ucuna dön (Dede'nin önünden değil, sol kenardan: dokunuş Dede'ye denk gelmesin);
	# Destansı bir yayın: mor ışıltılı gölge, uzun çekişme, kart.
	await _tap_world(Vector2(-0.4, 3.9))
	await _wait_frames(3)
	if not angler.is_walking():
		print("video: iskelenin ucuna yürümedi")
	await _wait_until(func() -> bool: return not angler.is_walking(), 8.0)
	_shadow_at(Vector2(1.6, -2.6), Vector2(-0.2, 1.0), "wels", 720000)
	await _wait(1.8)
	await _shot("v6_yayin_golge")
	await _tap_world(Vector2(1.3, -0.4))
	await _wait_state(FishingSession.State.BITING, 30.0)
	await _wait(0.2)
	await _reel_like_player(7, 50.0)
	await _wait(3.4)
	await _shot("v7_yayin_kart")
	if card.visible and card.ok_button != null:
		await _tap(card.ok_button.get_global_rect().get_center())
	await _wait(1.2)
	if session.state != FishingSession.State.IDLE:
		print("video: oturum %s durumunda bitti" % session.state_name())
	_quit()


## Çekişmeyi bir oyuncu gibi oynar: eylem düğmesine basar (VUR), sakinken basılı tutar, balık
## çırpınınca (uyarı) reaction kare sonra bırakır, sakinleşince yeniden basar. Sonuç gelene kadar.
func _reel_like_player(reaction: int, timeout: float) -> void:
	var finger := _hud().action_button.get_global_rect().get_center()
	_touch(1, finger, true)
	await _wait_frames(2)
	var hold := true
	var lag := 0
	var elapsed := 0.0
	while _state() == FishingSession.State.FIGHTING and elapsed < timeout:
		var reel := _session().reel
		var want := reel != null and not reel.thrashing()
		lag = lag + 1 if want != hold else 0
		if lag >= reaction:
			hold = want
			lag = 0
			_touch(1, finger, hold)
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	if hold:
		_touch(1, finger, false)


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

## Yakın çekim: kamerayı noktaya hemen yerleştirir (main.bot_camera açıkken).
func _frame_on(point: Vector3, zoom: float, pitch: float = FollowCamera.PITCH) -> void:
	var camera: FollowCamera = main.get("camera")
	camera.zoom = zoom
	camera.pitch = pitch
	camera.snap(point)


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
## fish_id verilirse balığın türü o olur (çekişme kontrolleri için); percentile (ppm) verilirse
## boyu da (boy, yıldız ve gölge uzunluğu yeniden hesaplanır).
func _shadow_at(p: Vector2, heading: Vector2, fish_id: String, percentile: int = -1) -> FishShadow:
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
	if percentile >= 0:
		chosen.percentile = percentile
	if not fish_id.is_empty() or percentile >= 0:
		var db := GameState.db
		if not fish_id.is_empty():
			chosen.fish_index = db.fish_index(fish_id)
			chosen.fish_id = fish_id
		var def := db.fish_def(chosen.fish_index)
		chosen.rarity = int(def["rarity"])
		chosen.size_cm = FishTable.size_cm(def, chosen.percentile)
		chosen.stars = FishTable.stars(chosen.percentile)
		chosen.length = FishTable.shadow_length(def, chosen.percentile)
	return chosen


func _session() -> FishingSession:
	return main.get("session")


func _state() -> FishingSession.State:
	return _session().state


func _angler() -> Angler:
	return main.get("angler")


func _hud() -> Hud:
	return main.get("hud")


func _elder() -> Elder:
	return main.get("elder")


func _nine() -> Nine:
	return main.get("nine")


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
