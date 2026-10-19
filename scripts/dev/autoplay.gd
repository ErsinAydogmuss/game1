extends Node
## Geliştirici aracı (yalnızca debug): kayda dokunmadan botla oynar, ekran görüntüsü alır ve
## çıkar. Bot gerçek bir telefon gibi dokunma olayları gönderir (Input.parse_input_event).
## Ekran gerektirir (headless çalışmaz); --fixed-fps ile oyun zamanı sabit akar:
##   xvfb-run -a -s "-screen 0 1920x1080x24" godot --path . --rendering-driver opengl3 \
##     --audio-driver Dummy --resolution 1280x720 --fixed-fps 30 -- --autoplay --scenario=controls \
##     [--shots=/mutlak/yol] [--locale=tr] [--safe-inset=130]
## Senaryolar:
##   controls: kontrollerin denemesi; KONTROL satırları TAMAM olmalı (Dede'ye dokun konuşsun,
##     Nine'ye dokun selam versin, sandala dokun Dede konuşsun (atış yok), yürü, kıyı yolundan dolaş,
##     Dede'nin yanından ve dükkânın önünden geç,
##     at, geri sar, gölgeyi korkut, gölgeyi çek, erken
##     dokunuş, ekranın her yeri VUR, basılı tut tut, kart açıkken atış yok, patlamada bırakmazsa
##     kopar, 8 sn'de yeni balık, düğme boyu ve güvenli alan).
##   first: ilk açılış; senaryolu ilk balık (ekran görüntüleri; 45 sn denetimi).
##   hero: balıkçı, Dede ve Nine yakın çekim (kamerayı bot sürer): Dede konuşur, ikisi, dükkân,
##     Nine selam verir, atış, bekleme, çekme, balığı gösterme, Dede sevinir.
##   fish: bütün türler elde ve kartlarıyla, sonra ayarlar paneli (görsel denetim; kurallar işlemez);
##     --fish=<kimlik> yalnızca o tür.
##   shop: Nine'nin dükkânı (KONTROL satırları): dokununca açılır, para yetmezse ve rütbe tutmazsa
##     satın alınmaz, satın al ve kuşan, yem al, kova dolunca Dede uyarır, doluyken balık göle döner,
##     hepsini sat, son yem bitince solucana döner; sekme görüntüleri.
##   rarity: nadirlik ipuçları (görsel denetim): her nadirlikten bir gölge yan yana (pırıltı, ışıltı,
##     kabarcık), sonra her nadirliğin rozeti; gri tonlamalı kopyayla renk körü denetimi yapılır.
##   map: harita ve hızlı geçiş (KONTROL satırları): ilk balıktan önce harita düğmesi yok; rütbe
##     atlayınca yeni bölge açılır (bildirim, Dede, nabız); haritaya dokun → açılır; her açık bölgenin
##     rozetine dokun → ekran kararır, balıkçı oraya geçer, gölgeler gelir; kilitli bölgeye geçilmez.
##   boat: sandal (KONTROL satırları): sandal yokken Dede Nine'yi söyler; Nine'den sandalı al; iskeledeki
##     sandala dokun → ekran kararır, derin ortada sandaldasın; yürünmez, dokunuş atıştır; yayını tut;
##     haritadan sıradaki şamandıra; "Kıyıya dön" → iskele.
##   technique: teknikler (KONTROL satırları; telefon oranında ve --safe-inset=130 ile): rütbe 2'den
##     önce teknik düğmesi yok; rütbe atlayınca spin açılır (bildirim, Dede, nabız); teknik düğmesi →
##     Takım Çantası (spin "Nine'de") → dükkân spin kamışlarında; ilk spin kamışı → spin ele geçer,
##     gölgeler yırtıcı, Dede nasıl oynandığını söyler; spinde basılı tut → yem gelir, yırtıcı peşine
##     düşer, dur-kalk → saldırır (basılıyken kendiliğinden takılır, bırakılmışken VUR); sazlıkta
##     bekleyen yem takılır; çantadan şamandıraya dönülür. Dip: rütbe 4'te açılır, dip kamışı, uzağa
##     atış ve sehpa, zil tek tük (koklama) ve durmadan (koşu), koklarken dokunmak kaçırır, aynalı sazan.
##     Spin ile dip arasında tuzak bölümü (aşağıda trap), sonra sinek ve sandalda dip.
##   fly: yalnızca technique'in sinek bölümü (rütbe 6'nın kaydından; hızlı deneme).
##   trap: kerevit tuzağı (KONTROL satırları; telefon oranında ve --safe-inset=130 ile): rütbe 3'te açılır,
##     çantada tuzak satırı → Nine'nin Ekstra sekmesi, ilk tuzak; iskelede kurulmaz; sazlıkta "Tuzak bırak"
##     (uçar, sığ suya düşer); boş tuzağa dokun → panel; saat ileri alınır → rozet, dokun → kovaya ve
##     yeni tür kartı; üst sınır; kova dolunca kalanı tuzakta; saat geri alınınca kayıp yok; uzaktaki
##     tuzağa dokununca balıkçı yürür ve toplar; haritada tuzak; boş tuzak kaldırılır.
##   tour: gezi (hız ölçümü): ayarlarda "Bölgeleri ve teknikleri aç" (geliştirme düğmesi) ve sürüm yazısına 5
##     dokunuş (ölçüm açılır: sol üstte FPS, çizim, üçgen); sonra her bölgenin atış noktasına ve
##     sandalla derin ortaya geçer; her yerde ÇİZİM satırı (çizim ve üçgen sayısı) ve ekran görüntüsü;
##     KONTROL: her yerde en çok TOUR_DRAWS çizim.
##   video: v0.4 tanıtımı, teknikler (--write-movie ile kaydedilir): rütbe 9'un oyuncusu; takım
##     çantasından spin, dur-kalk ve turna; haritadan sazlığa geç, dolu tuzağı topla (kerevitler);
##     çantadan dip, sehpa, zil ve koşu, aynalı sazan; haritadan dere ağzına geç, çantadan sinek,
##     sürüklenme, halka ve sıçrayan alabalık.
##   reels: Instagram Reels reklamının çekimi (--write-movie ile; tools/reels_ad.py dikey videoyu kurgular):
##     rütbe 9'un oyuncusu. İskelede Nine ve Dede yakın çekim, uzaklaşan geniş çekim; nilüferli koyda
##     altın sazan, kayalık burunda spinle turna, sazlıkta dolu tuzak ve dipte aynalı sazan, dere ağzında
##     sinekle alabalık, haritadan sandalla derin ortaya, efsanevi mersin (Dede haber verir) ve "Göle
##     bırak", defter. Kamerayı bot yönetir (aksiyon ortadaki kare kırpmada kalır); önemli anlar
##     günlüğe "REELS MARK <kare> <çekim>.<olay>" diye yazılır. --reels-only=gold,legend: yalnızca o çekimler.
## Bot dünyayı hazırlar (gölgeleri yerleştirir, türünü seçer); oyun kuralları aynen işler.

const WORLD_SEED := 4242
const HZ := FishingRules.HZ
## Gezide bir bakıştaki çizim sınırı (telefon hedefi; CLAUDE.md "Çizim sayısı").
const TOUR_DRAWS := 150

var main: Node
var _shots_dir: String = ""
var _scenario: String = "controls"
var _locale: String = ""
var _inset: float = 0.0
## fish senaryosunda yalnızca bu tür (--fish=<kimlik>; boşsa hepsi).
var _only_fish: String = ""
var _overlay: Control
var _finger_pos: Dictionary = {}
var _results: Array[String] = []
## Bir kez alınan ekran görüntüleri (_shot_once).
var _taken: Dictionary = {}
## Son çekişmede balık sudan sıçradı mı (_reel_like_player).
var _seen_jump: bool = false
## true iken dokunuşların izi çizilmez (yakın çekimde Dede'ye dokunmak, son kartın arka planı).
var _hide_fingers: bool = false
## _shadow_at öteki gölgeleri buraya bırakır (sıra, konulan balığın yeri → nokta); geçersizse iskelenin
## çevresindeki sabit yerlere.
var _park_fn: Callable = Callable()

## Reels: çekimler sırasıyla (--reels-only= ile bir kısmı), yakın çekimlerin eğimi (yüzler görünsün)
## ve efsanevi çekişmede bırakma gecikmesi (kare; geç bırakan oyuncu: gerilim kırmızıya çıkar, "BIRAK!").
## Çırpınma 0,5 sn'lik uyarıyla başlar (ReelModel WARN): 24 kare patlamanın 0,3 sn'sinde bırakır,
## gerilim yarım saniye kırmızıda kalır (kopma sayacı yarıya gelir, sonraki patlamaya kadar söner).
const REELS_TAKES: Array[String] = ["dock", "gold", "spin", "reeds", "fly", "legend", "book"]
const REELS_CLOSE_PITCH := deg_to_rad(42.0)
const REELS_LEGEND_REACTION := 24
## Defterde önceden olan türler [tür, boy, yıldız]: bot onlardan küçüğünü tutar (rekor kartı açılmaz);
## altın sazan ve mersin yeni tür, yayın ve dere alabalığı silüet kalır.
const REELS_RECORDS := [["rudd", 27, 3], ["carp", 66, 4], ["perch", 38, 3], ["silverside", 15, 3], ["bream", 48, 3],
		["tench", 44, 3], ["chub", 41, 3], ["crayfish", 14, 3], ["pike", 98, 4], ["mirror_carp", 80, 4],
		["trout", 50, 4], ["zander", 70, 3]]
## Rütbe 9'un takımı: iri balık (4★ altın sazan ve mersin) kopmasın; tekniklerin kamışları, tuzak, büyük
## file (kova dolmasın), sandal.
const REELS_GEAR := ["rod_float_carbon", "line_braid", "reel_pro", "hook_large", "bobber_bright", "rod_spin_heavy",
		"lure_crank", "rod_carp_2", "feeder", "rod_fly_2", "fly_streamer", "trap_1", "keepnet_big", "boat", "net"]
var _reels_only: PackedStringArray = PackedStringArray()
## Reels'te parmağın yeri: kırpmanın içinde, sağ altta (aksiyonu örtmez).
var _finger := Vector2(260, 520)
## Kamera yönetmeni: her kare istenen çerçeve ({point, zoom, pitch}); geçersizse oyunun kamerası.
var _cam_shot: Callable = Callable()
var _shot_rate: float = 2.5
## Çekimin kurulduğundan ve oturumun son durum değişikliğinden beri geçen süre (sn).
var _shot_t: float = 0.0
var _state_t: float = 0.0
## İşaretlerin öneki (çekimin adı), izlenen olayların son hâli, işaret sayıları ve bildirimler.
var _mark_tag: String = "setup"
var _watch: Dictionary = {}
var _marks: Dictionary = {}
var _toasts: Array[String] = []
## _shadow_at'in son yerleştirdiği balık: reels'te takıma yalnızca o gelir (öteki gölge fark ederse
## geri çekilir; dipte uzağa atılan kurşunun yanında bekleyen gölge 20 sn yolu kapatıyordu).
var _placed: FishShadow = null
var _no_bites: bool = false


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
		elif arg.begins_with("--fish="):
			_only_fish = arg.get_slice("=", 1)
		elif arg.begins_with("--reels-only="):
			_reels_only = arg.get_slice("=", 1).split(",", false)
	# Kamera yönetmeni ve olay günlüğü yalnızca reels'te (_process).
	set_process(_scenario == "reels")
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
		"map":
			_play_map.call_deferred()
		"boat":
			_play_boat.call_deferred()
		"tour":
			_play_tour.call_deferred()
		"technique":
			_play_technique.call_deferred()
		"fly":
			_play_fly_only.call_deferred()
		"trap":
			_play_trap_only.call_deferred()
		"reels":
			_play_reels.call_deferred()
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
	# 10) Patlamada bırakmazsa misina kopar (2★ Yayın: bambu olta taşır; hep basılı).
	var wels := _shadow_at(Vector2(-0.5, -3.2), Vector2(0, 1), "wels", 300000)
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
	# 12) Çok iri balık (rütbe 2, bambu olta ve ince misina 3★ taşır): 4★ yayın takılınca "Çok iri!";
	# sakinken de kırmızıya çeker, basılı tutan koparır; Dede eksik takımı adıyla söyler (Nine'de var).
	var db := GameState.db
	GameState.save.xp = maxi(GameState.save.xp, db.rank_xp[1])
	GameState.changed.emit()
	_shadow_at(Vector2(0.5, -3.2), Vector2(0, 1), "wels", 800000)
	await _tap_world(Vector2(0.5, -1.0))
	await _wait_state(FishingSession.State.BITING, 20.0)
	_touch(1, Vector2(260, 520), true)
	await _wait_frames(2)
	var toast: Label = _hud().get("_toast")
	var warned := _state() == FishingSession.State.FIGHTING and _session().too_big == 4 \
			and toast.is_visible_in_tree() and toast.text == UiKit.upper(tr("UI_TOO_BIG"))
	await _wait(0.6)
	var red_calm := _session().reel != null and _session().reel.in_red and _session().reel.phase == ReelModel.Phase.CALM
	await _shot("09_cok_iri")
	await _wait_until(func() -> bool: return _state() != FishingSession.State.FIGHTING, 10.0)
	_touch(1, Vector2(260, 520), false)
	var told := await _wait_until(func() -> bool: return str(main.get("_hint_shown")) == "UI_DEDE_TOO_BIG_BUY", 3.0)
	var hint: Label = _hud().get("_hint_label")
	var names := hint.text.contains(tr("GEAR_rod_float_glass").to_lower()) and hint.text.contains(tr("GEAR_line_mono").to_lower())
	_check("çok iri balık: \"Çok iri!\", sakinken de kırmızı, kopar, Dede takımı söyler (%s)" % hint.text,
			warned and red_calm and _session().last_loss == "snapped" and told and names)
	await _wait(0.4)
	await _shot("10_dede_takim")
	# 13) Rütbe 2'de (spin açık) sol altta teknik düğmesi; düğmeler yeterince büyük ve güvenli alanda.
	await _wait_state(FishingSession.State.IDLE, 3.0)
	_check("rütbe 2'de teknik düğmesi görünür", _hud().technique_button.visible)
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
	# 5b) Başlıktaki teknik düğmesi: spinin kamışları ve yapay yemleri görünür; rütbesi yetmiyorsa
	# Nine söyler (kilitli teknik de görünür).
	await _tap_control(shop.find_child("Tab_rod", true, false))
	await _tap_control(shop.find_child("Tech_spin", true, false))
	await _wait_frames(2)
	_check("teknik düğmesi → spinin kamışları, rütbe kilidi", shop.technique == "spin"
			and shop.find_child("Card_rod_spin_light", true, false) != null
			and shop.find_child("Card_rod_bamboo", true, false) == null and str(shop.get("_line_key")) == "UI_NINE_RANK")
	await _tap_control(shop.find_child("Tab_tackle", true, false))
	await _wait_frames(2)
	_check("spinde iğne sekmesi yapay yem", shop.find_child("Card_lure_spoon", true, false) != null
			and shop.find_child("Card_hook_small", true, false) == null)
	await _wait(0.3)
	await _shot("06_spin_yapay_yem")
	# Kartlar ShopPanel.CARD boyunu aşmaz; panel sekmeden sekmeye ve teknikten tekniğe büyüyüp küçülmez.
	var biggest := Vector2.ZERO
	var heights: Array[float] = []
	var dialog: Control = shop.get("_panel")
	for look: String in ContentDB.TECHNIQUES:
		if not db.has_technique(look):
			continue
		await _tap_control(shop.find_child("Tech_" + look, true, false))
		for tab in ["rod", "reel", "line", "tackle", "bait", "extra", "sell"]:
			await _tap_control(shop.find_child("Tab_" + tab, true, false))
			await _wait_frames(3)
			for node in shop.find_children("Card_*", "PanelContainer", true, false):
				biggest = biggest.max((node as Control).get_combined_minimum_size())
			heights.append(dialog.size.y)
	await _tap_control(shop.find_child("Tech_float", true, false))
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
	# Dalga 3: 16 tür iki sayfada; ikinci sayfada teknik türleri. Kerevitin ipucu tuzağı, alabalığınki
	# sineği söyler; oranların başlığında elindeki tekniğin adı.
	var pages := 0
	for node in book.find_children("*", "Button", true, false):
		if (node as Button).text.is_valid_int():
			pages += 1
	var count := BookPanel.species(db, str(main.get("spot_id"))).size()
	_check("defterde %d tür, %d sayfa" % [count, pages], count == db.fish.size() and pages == 2)
	book.open_book("crayfish")
	await _wait(0.4)
	await _shot("22_defter_kerevit")
	var crayfish_text := _texts_in(book)
	_check("kerevitin ipucu tuzağı söyler, oranlarda teknik", crayfish_text.contains(tr("UI_BOOK_HINT_TRAP").split("%")[0])
			and crayfish_text.contains(tr("UI_TECH_" + save.technique)))
	book.open_book("trout")
	await _wait(0.4)
	await _shot("23_defter_alabalik")
	var trout_text := _texts_in(book)
	_check("alabalığın ipucu sineği söyler", trout_text.contains(tr("UI_BOOK_FLY_HINT").split("%")[0])
			and trout_text.contains(tr("UI_TECH_fly")))
	_check("defter ekrana sığar (%.2f)" % book.fit_scale(), book.fit_scale() > 0.75)
	book.close_panel()
	for line in _results:
		print("KONTROL ", line)
	_quit()


## Bir düğümün altındaki bütün yazılar (Label), satır satır.
static func _texts_in(root: Node) -> String:
	var lines := PackedStringArray()
	for node in root.find_children("*", "Label", true, false):
		if (node as Label).is_visible_in_tree():
			lines.append((node as Label).text)
	return "\n".join(lines)


## Harita ve hızlı geçiş. Kayıt rütbe 3'ün bir puan altında başlar: tutulan balık rütbe atlatır,
## nilüferli koy açılır. Sonra rütbe 7: beş bölgeye geçilir; derin orta sandal ister.
func _play_map() -> void:
	_use_save(0)
	await _wait(1.0)
	var hud := _hud()
	_check("ilk balıktan önce harita düğmesi yok", not hud.map_button.visible)
	_use_save(3)
	var db := GameState.db
	var save := GameState.save
	var spot := str(main.get("spot_id"))
	save.xp = db.rank_xp[2] - 1
	Records.add(save.records, "rudd", 999, 3, 0)
	GameState.changed.emit()
	await _wait(1.0)
	_check("ilk balıktan sonra harita düğmesi var", hud.map_button.visible)
	# Rütbe atlatan balık: nilüferli koy açılır.
	_shadow_at(Vector2(1.0, -3.2), Vector2(0, 1), "rudd")
	await _tap_world(Vector2(1.0, -1.0))
	await _wait_state(FishingSession.State.BITING, 20.0)
	_touch(1, Vector2(260, 520), true)
	await _wait_state(FishingSession.State.CAUGHT, 25.0)
	_touch(1, Vector2(260, 520), false)
	await _wait_frames(2)
	var pulsing := float(hud.get("_map_pulse")) > 0.0
	await _wait_until(func() -> bool: return str(main.get("_hint_shown")) == "UI_DEDE_ZONE_OPEN", 6.0)
	var lily := Zones.unlocked(db, save, db.zone(spot, "lily_cove"))
	_check("rütbe 3: nilüferli koy açılır, Dede söyler, harita düğmesi atar", lily and pulsing
			and str(main.get("_hint_shown")) == "UI_DEDE_ZONE_OPEN")
	await _wait(1.0)
	await _shot("01_bolge_acildi")
	await _wait_state(FishingSession.State.IDLE, 4.0)
	# Rütbe 3'te harita: kayalık burun, dere ağzı ve derin orta kilitli (çitleri ve tabelaları).
	var panel: MapPanel = main.get("map_panel")
	var fade: Fade = main.get("fade")
	await _tap_control(hud.map_button)
	await _wait_until(func() -> bool: return panel.visible, 2.0)
	_check("harita düğmesine dokun → harita açılır", panel.visible)
	await _wait(0.3)
	_check("harita paneli küçülmeden sığar (%.2f; kapatma düğmesi %.0f)" % [panel.fit_scale(),
			panel.close_button.get_global_rect().size.y], panel.fit_scale() > 0.999
			and panel.close_button.get_global_rect().size.y >= 121.5)
	await _wait(0.5)
	await _shot("02_harita")
	_check_map_badges(panel)
	panel.close_panel()
	await _wait(0.3)
	# Rütbe 7: kayalık burun ve dere ağzı da açık (oturumun erişimi ve çitler).
	save.xp = db.rank_xp[6]
	_session().set_access(Zones.open_ids(db, save, spot))
	main.call("_update_gates")
	GameState.changed.emit()
	var index := 3
	var reach := _session().range_m() + db.rules.reach_extra
	for zone_id: String in ["reeds", "lily_cove", "rocky_point", "stream_mouth", "dock_cove"]:
		if not panel.visible:
			await _tap_control(hud.map_button)
			await _wait_until(func() -> bool: return panel.visible, 2.0)
			await _wait(0.3)
		var badge := panel.view.badge(zone_id)
		if badge == null:
			_results.append("rozet yok: " + zone_id)
			continue
		await _tap_control(badge)
		var dark := await _wait_until(func() -> bool: return fade.busy(), 1.0)
		var arrived := await _wait_until(func() -> bool: return str(main.get("zone_id")) == zone_id and not fade.busy(), 4.0)
		var stand: Vector2 = (db.zone(spot, zone_id)["stands"] as Array)[0]
		var near := 0
		for sh in _session().sim.shadows:
			if sh.mode != FishShadow.Mode.FLEE and sh.pos.distance_to(stand) <= reach + 0.5:
				near += 1
		_check("%s rozetine dokun → ekran kararır, oraya geçilir (%d gölge yakında)" % [zone_id, near],
				dark and arrived and _angler().pos2().distance_to(stand) < 0.3 and near >= 2)
		await _wait(0.6)
		await _shot("%02d_%s" % [index, zone_id])
		index += 1
	# Kilitli: derin orta sandal ister; geçilmez, nedeni yazılır.
	await _tap_control(hud.map_button)
	await _wait_until(func() -> bool: return panel.visible, 2.0)
	await _wait(0.3)
	var before := _angler().pos2()
	await _tap_control(panel.view.badge("deep_water"))
	await _wait(0.6)
	var note: Label = panel.get("_note")
	_check("kilitli bölgeye geçilmez, nedeni yazılır", panel.visible and not fade.busy()
			and _angler().pos2() == before and str(main.get("zone_id")) == "dock_cove"
			and note.text.begins_with(tr("ZONE_deep_water")))
	await _shot("%02d_kilitli" % index)
	panel.close_panel()
	await _wait(0.3)
	_check_buttons()
	for line in _results:
		print("KONTROL ", line)
	_quit()


## Sandal: rütbe 9, parası var ama sandalı yok.
func _play_boat() -> void:
	_use_save(3)
	var db := GameState.db
	var save := GameState.save
	var spot := str(main.get("spot_id"))
	save.xp = db.rank_xp[8]
	save.coins = 6000
	Records.add(save.records, "wels", 999, 3, 0)
	_session().set_access(Zones.open_ids(db, save, spot))
	main.call("_update_gates")
	GameState.changed.emit()
	await _wait(1.0)
	var scene: LakeScene = main.get("scene")
	var fade: Fade = main.get("fade")
	var hud := _hud()
	# 1) Sandal yokken sandala dokun: Dede, Nine'nin sandal sattığını söyler; binilmez.
	await _tap(_screen(scene.boat_point()))
	await _wait_frames(3)
	_check("sandal yokken sandala dokun → Dede Nine'yi söyler", str(main.get("_hint_shown")) == "UI_DEDE_BOAT_SHOP"
			and not bool(main.get("in_boat")))
	# 2) Nine'den sandalı al (Ekstra sekmesi: kepçe, sandal, sıradaki kova).
	var shop: ShopPanel = main.get("shop_panel")
	await _tap(_screen(_nine().head_point()))
	await _wait_until(func() -> bool: return shop.visible, 2.0)
	await _tap_control(shop.find_child("Tab_extra", true, false))
	await _wait(0.4)
	await _shot("01_ekstra")
	await _tap_card(shop, "boat", -1)
	await _wait_frames(2)
	_check("Nine'den sandal alınır", Economy.owns(db, save, Zones.BOAT) and save.coins == 6000 - int(db.gear_item("boat")["price"]))
	shop.close_panel()
	await _wait(0.8)
	# 3) Sandala dokun: ekran kararır, balıkçı derin ortada, ilk şamandıranın yanında sandalda.
	await _tap(_screen(scene.boat_point()))
	var dark := await _wait_until(func() -> bool: return fade.busy(), 1.0)
	await _wait_until(func() -> bool: return bool(main.get("in_boat")) and not fade.busy(), 4.0)
	var buoys: Array = db.zone(spot, "deep_water")["buoys"]
	var at := _angler().pos2()
	_check("sandala dokun → ekran kararır, derin ortada sandaldasın", dark and bool(main.get("in_boat"))
			and str(main.get("zone_id")) == "deep_water" and at.distance_to(buoys[0]) < 3.5 and hud.shore_button.visible
			and scene.boat_away())
	await _wait(0.8)
	await _shot("02_sandalda")
	var deep := _session().lake.zone_index("deep_water")
	var only_deep := true
	for sh in _session().sim.shadows:
		only_deep = only_deep and sh.zone == deep
	_check("sandaldayken gölgeler derin ortada", only_deep and _session().sim.shadows.size() > 0)
	# 4) Sandalda yürünmez: suya dokunmak atıştır, balıkçı yerinden oynamaz.
	# 3★ yayın: başlangıç takımı taşır (fazla iri olsa kopardı).
	_shadow_at(at + Vector2(0.0, -7.0), Vector2(0, 1), "wels", 600000)
	await _tap_world(at + Vector2(0.0, -5.0))
	await _wait_frames(3)
	_check("sandalda suya dokun → atış (yürüme yok)", _state() in [FishingSession.State.CASTING, FishingSession.State.WAITING]
			and _angler().pos2().distance_to(at) < 0.05)
	# 5) Yayını tut (bırakmayı bilen oyuncu gibi).
	await _wait_state(FishingSession.State.BITING, 25.0)
	await _shot("03_isirdi")
	await _reel_like_player(8, 60.0)
	_check("sandaldan yayın tutulur", _state() == FishingSession.State.CAUGHT
			and str(_session().last_catch.get("fish", "")) == "wels")
	await _wait(1.2)
	await _shot("04_tuttu")
	# Destansı balığın kartı: düğmeyle kapanır.
	var card: FishCard = main.get("card")
	await _wait_until(func() -> bool: return card.visible, 3.0)
	await _wait(FishCard.MIN_OPEN + 0.2)
	if card.visible and card.ok_button != null:
		await _tap(card.ok_button.get_global_rect().get_center())
	await _wait_until(func() -> bool: return _state() == FishingSession.State.IDLE, 6.0)
	await _wait(0.5)
	# 6) Haritadan derin ortaya dokun: sıradaki şamandıra.
	var panel: MapPanel = main.get("map_panel")
	await _tap_control(hud.map_button)
	await _wait_until(func() -> bool: return panel.visible, 2.0)
	await _wait(0.4)
	await _shot("05_harita")
	await _tap_control(panel.view.badge("deep_water"))
	await _wait_until(func() -> bool: return fade.busy(), 1.0)
	await _wait_until(func() -> bool: return not fade.busy(), 4.0)
	_check("haritadan derin ortaya dokun → sıradaki şamandıra", bool(main.get("in_boat"))
			and _angler().pos2().distance_to(buoys[1]) < 3.5)
	await _wait(0.5)
	await _shot("06_ikinci_samandira")
	_check_buttons()
	# 7) Kıyıya dön: iskele koyunun atış noktası, sandal iskelede.
	await _tap_control(hud.shore_button)
	await _wait_until(func() -> bool: return fade.busy(), 1.0)
	await _wait_until(func() -> bool: return not fade.busy() and not bool(main.get("in_boat")), 4.0)
	var stand: Vector2 = (db.zone(spot, "dock_cove")["stands"] as Array)[0]
	_check("Kıyıya dön → iskele, sandal yerinde", not bool(main.get("in_boat")) and _angler().pos2().distance_to(stand) < 0.3
			and not scene.boat_away() and not hud.shore_button.visible and str(main.get("zone_id")) == "dock_cove")
	await _wait(0.5)
	await _shot("07_kiyida")
	for line in _results:
		print("KONTROL ", line)
	_quit()


## Teknikler: rütbe 2'de spin açılır, takım çantası, ilk spin kamışı, dur-kalk saldırısı (iki yolu da),
## sazlıkta takılan yem, şamandıraya dönüş.
func _play_technique() -> void:
	_use_save(5)
	var db := GameState.db
	var save := GameState.save
	var hud := _hud()
	var shop: ShopPanel = main.get("shop_panel")
	var bag: TechniquePanel = main.get("technique_panel")
	var bobber: Bobber = main.get("bobber")
	# Kızılkanat önceden büyük bir rekorla defterde: yeni tür ya da rekor kartı açılmasın.
	Records.add(save.records, "rudd", 999, 3, 0)
	save.xp = db.rank_xp[1] - 1
	GameState.changed.emit()
	await _wait(1.5)
	# 1) Rütbe 2'den önce teknik düğmesi yok.
	_check("rütbe 2'den önce teknik düğmesi yok", not hud.technique_button.visible)
	# 2) Bir balık rütbe atlatır: spin açılır (bildirim tekniğin ikonuyla, Dede söyler, düğme nabız gibi atar).
	_shadow_at(Vector2(1.0, -3.2), Vector2(0, 1), "rudd")
	await _tap_world(Vector2(1.0, -1.0))
	await _wait_state(FishingSession.State.BITING, 20.0)
	_touch(1, Vector2(260, 520), true)
	await _wait_state(FishingSession.State.CAUGHT, 25.0)
	_touch(1, Vector2(260, 520), false)
	await _wait_frames(3)
	var told := str(main.get("_hint_shown")) == "UI_DEDE_TECH_OPEN_spin"
	var toasted := await _wait_toast(UiKit.upper(tr("UI_TECH_OPEN") % tr("UI_TECH_spin")), 8.0)
	_check("rütbe 2: spin açılır (bildirim, Dede, nabız)", told and toasted and hud.technique_button.visible
			and float(hud.get("_tech_pulse")) > 0.0 and (hud.get("_toast_icon") as GameIcon).kind == "tech_spin")
	await _shot("01_spin_acildi")
	await _wait_state(FishingSession.State.IDLE, 5.0)
	# 3) Teknik düğmesi → Takım Çantası: spin "Nine'de".
	await _tap_control(hud.technique_button)
	await _wait_frames(3)
	await _wait(0.4)
	_check("teknik düğmesi → takım çantası (spin Nine'de)", bag.visible and TechniquePanel.state_of(db, save, "spin") == "shop"
			and bag.find_child("Button_spin", true, false) != null)
	await _shot("02_canta")
	_check_panel_buttons(bag, "takım çantası düğmeleri")
	# 4) "Nine'de" → dükkân spin kamışlarında.
	await _tap_control(bag.find_child("Button_spin", true, false))
	await _wait_frames(3)
	await _wait(0.4)
	_check("Nine'de → dükkân spin kamışlarında", not bag.visible and shop.visible and shop.technique == "spin"
			and shop.current_tab() == "rod" and shop.find_child("Card_rod_spin_light", true, false) != null)
	await _shot("03_dukkan_spin")
	# 5) İlk spin kamışı: spin ele geçer, gölgeler yeniden doğar (yalnızca spinle gelen türler).
	save.coins = 500
	shop.refresh()
	await _wait_frames(2)
	await _tap_card(shop, "rod_spin_light", -1)
	await _wait_frames(3)
	var predators := not _session().sim.shadows.is_empty()
	for s in _session().sim.shadows:
		predators = predators and db.affinity(s.fish_id, "spin") > 0.0
	_check("ilk spin kamışı → spin elde, gölgeler yırtıcı", Economy.owns(db, save, "rod_spin_light")
			and save.technique == "spin" and _session().technique.id == "spin" and predators)
	await _wait(0.3)
	await _shot("04_spin_kamisi")
	await _tap(shop.close_button.get_global_rect().get_center())
	await _wait_frames(4)
	_check("spin elde: kamış, yem, düğme ve Dede'nin sözü", _angler().rod.style == "spin" and bobber.kind == "lure"
			and (hud.technique_button.get("_icon") as GameIcon).kind == "tech_spin"
			and str(main.get("_hint_shown")) == "UI_DEDE_TECH_FIRST_spin")
	await _wait(0.5)
	await _shot("05_spin_elde")
	# 6) Spinde atışlar: basılı tut → yem gelir; yırtıcı peşine düşer; dur-kalk → saldırır. Saldırı
	# basılıyken olduysa balık kendiliğinden takılır, bırakılmışken VUR anı açılır. İki yol da görülene
	# kadar (en çok 6 atış).
	var seen := { "auto": false, "tap": false }
	var first := {}
	for i in 6:
		var out := await _spin_cast(Vector2(0.5, -2.5), Vector2(0.5, -5.0))
		if i == 0:
			first = out
		if bool(out["caught"]) and seen.has(str(out["strike"])):
			seen[str(out["strike"])] = true
		if bool(seen["auto"]) and bool(seen["tap"]):
			break
	_check("spin: basılı tut → yem gelir (%.1f m), olta sudayken teknik düğmesi gizli" % float(first.get("moved", 0.0)),
			float(first.get("moved", 0.0)) > 0.3 and bool(first.get("hidden", false)))
	_check("spin: yırtıcı oynayan yemin peşine düşer, Dede yol gösterir", bool(first.get("followed", false))
			and bool(first.get("reel_hint", false)) and bool(first.get("follow_hint", false)))
	_check("spin: dur-kalk → basılıyken kendiliğinden takılır, tutulur", bool(seen["auto"]))
	_check("spin: dur-kalk → bırakılmışken VUR, dokununca takılır, tutulur", bool(seen["tap"]))
	_check("spin: iskelede yem çekilirken (iz halkaları) en çok %d çizim (%d)" % [TOUR_DRAWS, int(first.get("draws", 0))],
			int(first.get("draws", 0)) > 0 and int(first.get("draws", 0)) <= TOUR_DRAWS)
	# 7) Sazlıkta bekleyen yem otlara takılır: bildirim, Dede söyler, geri sarma uzun sürer.
	await _travel_to("reeds")
	await _tap_control(hud.action_button)
	await _wait_state(FishingSession.State.WAITING, 3.0)
	var snagged := await _wait_state(FishingSession.State.RETRIEVING, 6.0)
	var long_pull := _session().timer > _session().rules.retrieve_steps
	await _wait_frames(2)
	_check("sazlıkta bekleyen yem takılır (bildirim, Dede, uzun geri sarma)", snagged and long_pull
			and str(main.get("_hint_shown")) == "UI_DEDE_SNAG"
			and (hud.get("_toast") as Label).text == UiKit.upper(tr("UI_SNAGGED")))
	await _shot("10_takildi")
	await _wait_state(FishingSession.State.IDLE, 4.0)
	# 8) Çantadan şamandıraya dön: kamış, takım ve düğme şamandıranın.
	await _travel_to("dock_cove")
	await _tap_control(hud.technique_button)
	await _wait_frames(3)
	await _wait(0.4)
	_check("takım çantasında spin elinde, şamandıra seçilebilir", bag.visible
			and TechniquePanel.state_of(db, save, "spin") == "active" and TechniquePanel.state_of(db, save, "float") == "ready")
	await _shot("11_canta_spin")
	await _tap_control(bag.find_child("Button_float", true, false))
	await _wait_frames(4)
	_check("şamandıraya dönülür (kamış, takım, düğme)", not bag.visible and save.technique == "float"
			and _session().technique.id == "float" and _angler().rod.style == "float" and bobber.kind == "float"
			and (hud.technique_button.get("_icon") as GameIcon).kind == "tech_float")
	await _wait(0.4)
	await _shot("12_samandira")
	await _play_trap()
	await _travel_to("dock_cove")
	await _play_bottom()
	await _play_fly()
	await _play_boat_bottom()
	_check_buttons()
	for line in _results:
		print("KONTROL ", line)
	_quit()


## Dip (rütbe 4): rütbe gelince haber verilir; çantadan Nine'ye, dip kamışı; uzağa atış, olta sehpada;
## zil tek tük (koklama), sonra durmadan (koşu): VUR, olta ele alınır; koklarken dokunmak kaçırır;
## sazlıkta aynalı sazan.
func _play_bottom() -> void:
	var db := GameState.db
	var save := GameState.save
	var hud := _hud()
	var shop: ShopPanel = main.get("shop_panel")
	var bag: TechniquePanel = main.get("technique_panel")
	var stand: RodStand = main.get("stand")
	save.xp = maxi(save.xp, db.rank_xp[3])
	GameState.changed.emit()
	await _wait_frames(3)
	var told := str(main.get("_hint_shown")) == "UI_DEDE_TECH_OPEN_bottom"
	var toasted := await _wait_toast(UiKit.upper(tr("UI_TECH_OPEN") % tr("UI_TECH_bottom")), 6.0)
	_check("rütbe 4: dip açılır (bildirim, Dede, nabız)", told and toasted and float(hud.get("_tech_pulse")) > 0.0)
	await _shot("13_dip_acildi")
	await _tap_control(hud.technique_button)
	await _wait_frames(3)
	await _wait(0.3)
	_check("takım çantasında dip Nine'de", bag.visible and TechniquePanel.state_of(db, save, "bottom") == "shop")
	await _tap_control(bag.find_child("Button_bottom", true, false))
	await _wait_frames(3)
	save.coins = maxi(save.coins, 900)
	shop.refresh()
	await _wait_frames(2)
	_check("dükkân dip kamışlarında", shop.visible and shop.technique == "bottom"
			and shop.find_child("Card_rod_carp_1", true, false) != null)
	await _tap_card(shop, "rod_carp_1", -1)
	await _wait_frames(3)
	await _tap_control(shop.find_child("Tab_tackle", true, false))
	await _wait(0.3)
	await _shot("14_dukkan_kursun")
	_check("dipte iğne sekmesi kurşun (kurşun ve yem sepeti)", shop.find_child("Card_sinker", true, false) != null
			and shop.find_child("Card_feeder", true, false) != null)
	await _tap(shop.close_button.get_global_rect().get_center())
	await _wait_frames(4)
	_check("dip elde: kamış, düğme, Dede'nin sözü", _session().technique.id == "bottom" and _angler().rod.style == "bottom"
			and (hud.technique_button.get("_icon") as GameIcon).kind == "tech_bottom"
			and str(main.get("_hint_shown")) == "UI_DEDE_TECH_FIRST_bottom")
	# Uzağa atış: olta sehpaya konur; bir balık takımın yanına gelir, koklar (zil tek tük), koşar.
	var caught := await _bottom_cast(true)
	_check("dip: uzağa atar (%.1f m), olta sehpada, misina sehpadan" % float(caught["reach"]),
			float(caught["reach"]) >= 8.0 and bool(caught["on_stand"]) and bool(caught["line_from_stand"]))
	_check("dip: iskelede sehpayla en çok %d çizim (%d)" % [TOUR_DRAWS, int(caught["draws"])],
			int(caught["draws"]) > 0 and int(caught["draws"]) <= TOUR_DRAWS)
	_check("dip: zil tek tük çalar (koklama), dokunulmaz", bool(caught["sniffed"]))
	_check("dip: zil durmadan (koşu) → VUR → olta ele alınır, tutulur", bool(caught["ran"]) and bool(caught["picked_up"])
			and bool(caught["caught"]))
	# Koklarken dokunmak balığı kaçırır.
	var early := await _bottom_cast(false)
	_check("dip: koklarken dokunmak kaçırır", bool(early["early"]))
	# Sazlıkta aynalı sazan (yalnızca dip).
	await _travel_to("reeds")
	var mirror := await _bottom_cast(true, "mirror_carp")
	_check("sazlıkta dipte aynalı sazan (botun koyduğu gölge) tutulur", bool(mirror["caught"])
			and str(_session().last_catch.get("fish", "")) == "mirror_carp")
	await _shot_once("18_aynali_sazan")
	var card: FishCard = main.get("card")
	if card.visible:
		await _close_card(card)
	await _wait_state(FishingSession.State.IDLE, 5.0)
	_check("dip bitince sehpa kalkar", not stand.visible and not _angler().rod_on_stand)


## Sandalda dip (rütbe 9; sinekten sonra, rütbe atlayışı sineği erken açmasın): çantadan dip seçilir,
## sandal alınır, binilir; sehpa teknenin içinde, küpeştede (suyun üstünde).
func _play_boat_bottom() -> void:
	var db := GameState.db
	var save := GameState.save
	var hud := _hud()
	var bag: TechniquePanel = main.get("technique_panel")
	var stand: RodStand = main.get("stand")
	var fade: Fade = main.get("fade")
	await _tap_control(hud.technique_button)
	await _wait_frames(3)
	await _wait(0.3)
	await _tap_control(bag.find_child("Button_bottom", true, false))
	await _wait_frames(4)
	_check("çantadan dip seçilir", not bag.visible and _session().technique.id == "bottom")
	save.xp = maxi(save.xp, db.rank_xp[8])
	save.coins = maxi(save.coins, int(db.gear_item(Zones.BOAT)["price"]))
	Economy.buy(db, save, Zones.BOAT)
	GameState.changed.emit()
	await _wait_frames(3)
	main.call("_go_boat", 0)
	await _wait_until(func() -> bool: return bool(main.get("in_boat")) and not fade.busy(), 5.0)
	await _wait(0.5)
	await _tap_control(hud.action_button)
	var cast_out := await _wait_state(FishingSession.State.WAITING, 3.0)
	await _wait(1.0)
	# Sandalın tabanı su hizasında (LakeScene.BOAT_Y + BOAT_FLOOR): sehpa balıkçıyla aynı tabanda.
	var on_board := Vector2(stand.global_position.x, stand.global_position.z).distance_to(_angler().pos2())
	var floor_gap := absf(stand.global_position.y - _angler().global_position.y)
	_check("sandalda dip: sehpa teknede (yanda %.2f m, tabandan %.2f m)" % [on_board, floor_gap],
			cast_out and stand.visible and on_board < 0.45 and floor_gap < 0.06)
	await _shot("19_sandalda_dip")
	await _tap(Vector2(260, 520))
	await _wait_state(FishingSession.State.IDLE, 5.0)


## Yalnızca sinek bölümü (hızlı deneme): rütbe 6'nın kaydı; spin ve dipin haberi verilmiş (açılışta
## Dede sineği söylesin).
func _play_fly_only() -> void:
	_use_save(5)
	var db := GameState.db
	var save := GameState.save
	Records.add(save.records, "rudd", 999, 3, 0)
	for t: String in ["spin", "bottom"]:
		save.flags["told_open_" + t] = true
	save.xp = db.rank_xp[5]
	GameState.changed.emit()
	await _wait(1.5)
	await _play_fly()
	_check_buttons()
	for line in _results:
		print("KONTROL ", line)
	_quit()


## Yalnızca tuzak bölümü (rütbe 2'nin kaydından; hızlı deneme).
func _play_trap_only() -> void:
	_use_save(5)
	var db := GameState.db
	var save := GameState.save
	Records.add(save.records, "rudd", 999, 3, 0)
	save.flags["told_open_spin"] = true
	save.xp = db.rank_xp[1]
	GameState.changed.emit()
	await _wait(1.5)
	await _play_trap()
	_check_buttons()
	for line in _results:
		print("KONTROL ", line)
	_quit()


## Kerevit tuzağı (rütbe 3): rütbe gelince haber; çantada tuzak satırı "Nine'de" → dükkânın Ekstra
## sekmesi, ilk tuzak alınır (Nine nasıl bırakılacağını söyler); iskele koyunda kurulmaz; sazlıkta
## "Tuzak bırak": tuzak uçar, sığ suya düşer (Dede anlatır); boş tuzağa dokun → panel (bekle); saat
## ileri alınır → rozet 2/4, dokun → kerevitler kovaya, yeni tür kartı; uzun süre sonra en çok 4; kova
## dolunca kalanı tuzakta bekler; saat geri alınınca bir şey kaybolmaz; uzaktaki tuzağa dokununca
## balıkçı yürür ve toplar; haritada tuzak; boş tuzak kaldırılır. Saat bot süresince sabit (fixed_unix).
func _play_trap() -> void:
	var db := GameState.db
	var save := GameState.save
	var rules := db.rules
	var hud := _hud()
	var spot := str(main.get("spot_id"))
	var shop: ShopPanel = main.get("shop_panel")
	var bag: TechniquePanel = main.get("technique_panel")
	var traps: TrapMarkers = main.get("traps")
	var trap_panel: TrapPanel = main.get("trap_panel")
	var card: FishCard = main.get("card")
	var clock := GameState.clock
	var t0 := clock.now_unix()
	clock.fixed_unix = t0
	await _travel_to("dock_cove")
	# 1) Rütbe 3: tuzak açılır (bildirim, Dede, nabız).
	save.xp = maxi(save.xp, db.rank_xp[2])
	GameState.changed.emit()
	await _wait_frames(3)
	var told := str(main.get("_hint_shown")) == "UI_DEDE_TRAP_OPEN"
	var toasted := await _wait_toast(UiKit.upper(tr("UI_TRAP_OPEN")), 8.0)
	_check("rütbe 3: tuzak açılır (bildirim, Dede, nabız)", told and toasted and float(hud.get("_tech_pulse")) > 0.0)
	await _shot("40_tuzak_acildi")
	# 2) Çantada tuzak satırı "Nine'de" → dükkânın Ekstra sekmesi; ilk tuzak alınır.
	await _tap_control(hud.technique_button)
	await _wait_frames(3)
	await _wait(0.4)
	_check("çantada tuzak satırı (Nine'de)", bag.visible and bag.find_child("TrapRow", true, false) != null
			and TechniquePanel.trap_state(db, save) == "shop" and bag.find_child("Button_trap", true, false) != null)
	_check("çanta tuzak satırıyla küçülmeden sığar (%.2f)" % bag.fit_scale(), bag.fit_scale() > 0.999)
	await _shot("41_canta_tuzak")
	_check_panel_buttons(bag, "çanta düğmeleri (tuzak satırıyla)")
	await _tap_control(bag.find_child("Button_trap", true, false))
	await _wait_frames(3)
	await _wait(0.4)
	_check("Nine'de → dükkân Ekstra sekmesinde ilk tuzak", not bag.visible and shop.visible
			and shop.current_tab() == "extra" and shop.find_child("Card_trap_1", true, false) != null)
	save.coins = maxi(save.coins, 600)
	shop.refresh()
	await _wait_frames(2)
	await _tap_card(shop, "trap_1", -1)
	await _wait_frames(3)
	_check("ilk tuzak alınır (Nine nasıl bırakılacağını söyler)", Economy.owns(db, save, "trap_1")
			and str(shop.get("_line_key")) == "UI_NINE_TRAP")
	await _shot("42_dukkan_tuzak")
	await _tap(shop.close_button.get_global_rect().get_center())
	await _wait_frames(4)
	# 3) İskele koyunda tuzak kurulmaz.
	_check("iskele koyunda tuzak satırı: Sazlık, kayalık", TechniquePanel.trap_state(db, save, spot,
			str(main.get("zone_id"))) == "zone")
	# 4) Sazlıkta "Tuzak bırak": tuzak uçar ve balıkçının yakınındaki sığ suya düşer; Dede anlatır.
	await _travel_to("reeds")
	await _tap_control(hud.technique_button)
	await _wait_frames(3)
	await _wait(0.4)
	_check("sazlıkta tuzak satırı: Tuzak bırak", bag.visible
			and TechniquePanel.trap_state(db, save, spot, str(main.get("zone_id"))) == "place")
	await _tap_control(bag.find_child("Button_trap", true, false))
	await _wait_frames(2)
	var flying := traps.is_flying()
	await _wait_until(func() -> bool: return not traps.is_flying(), 3.0)
	await _wait_frames(3)
	var id := int(save.traps[0]["id"]) if save.traps.size() == 1 else -1
	var near := id >= 0 and TrapSim.position(save.traps[0]).distance_to(_angler().pos2()) <= rules.trap_near.y + 0.1
	var placed_toast := await _wait_toast(UiKit.upper(tr("UI_TRAP_PLACED") % roundi(rules.trap_fill_s / 60.0)), 3.0)
	_check("tuzak uçar, yakındaki sığ suya düşer (Dede anlatır)", flying and near and traps.has_mark(id) and placed_toast
			and str(main.get("_hint_shown")) == "UI_DEDE_TRAP_FIRST")
	await _wait(0.6)
	await _shot("43_tuzak_kuruldu")
	# 5) Boş tuzağa dokun: panel (sıradaki kerevit ne zaman), Bekle.
	await _tap(_screen(traps.mark_point(id)))
	await _wait_frames(3)
	_check("boş tuzağa dokun → panel (yazılar oyunun dilinde)", trap_panel.visible and trap_panel.trap_id == id
			and (trap_panel.find_child("Button_wait", true, false) as Button).text == UiKit.upper(tr("UI_TRAP_WAIT")))
	await _wait(0.4)
	_check_panel_buttons(trap_panel, "boş tuzak paneli düğmeleri")
	await _shot("44_bos_tuzak")
	await _tap_control(trap_panel.find_child("Button_wait", true, false))
	await _wait_frames(3)
	# 6) Saat ilerler (oyun kapalıyken gibi): rozet 2/4; dokun → kerevitler kovaya, yeni tür kartı.
	var bucket := save.bucket.size()
	clock.fixed_unix = t0 + 2 * rules.trap_fill_s + 30
	await _wait(1.3)
	_check("saat ilerleyince rozet 2/%d" % rules.trap_max, traps.shown_count(id) == 2)
	await _shot("45_tuzak_2")
	await _tap(_screen(traps.mark_point(id)))
	await _wait_frames(3)
	var got := save.bucket.size() - bucket
	await _wait(0.8)
	await _shot("46_kerevit_elde")
	await _wait_until(func() -> bool: return card.visible, 3.0)
	_check("dokun → 2 kerevit kovaya, yeni tür kartı, rozet 0", got == 2 and save.records.has("crayfish") and card.visible
			and traps.shown_count(id) == 0)
	await _wait(FishCard.MIN_OPEN + 0.2)
	await _shot("47_kerevit_karti")
	if card.visible and card.ok_button != null:
		await _tap(card.ok_button.get_global_rect().get_center())
	await _wait_until(func() -> bool: return not card.visible, 3.0)
	await _wait(0.5)
	# 7) Uzun süre sonra en çok trap_max (üst sınır); kova dolunca kalanı tuzakta bekler.
	clock.fixed_unix = t0 + 50 * rules.trap_fill_s
	await _wait(1.3)
	_check("uzun süre sonra en çok %d (üst sınır)" % rules.trap_max, traps.shown_count(id) == rules.trap_max)
	await _shot("48_tuzak_dolu")
	while Bucket.capacity(db, save) - save.bucket.size() > 1:
		save.bucket.append({ "fish": "rudd", "size_cm": 20, "stars": 1 })
	await _tap(_screen(traps.mark_point(id)))
	await _wait_frames(3)
	# Kartsız toplama: kerevit elde (kodla kurulan model, sırtı kameraya dönük).
	await _wait(0.5)
	await _shot("48b_kerevit_elde")
	var left_toast := await _wait_toast(UiKit.upper(tr("UI_TRAP_LEFT") % (rules.trap_max - 1)), 5.0)
	_check("kova dolunca kalanı tuzakta bekler", Bucket.is_full(db, save) and traps.shown_count(id) == rules.trap_max - 1
			and left_toast)
	# 8) Saat geri alınınca bir şey kaybolmaz.
	clock.fixed_unix = t0
	await _wait(1.3)
	_check("saat geri alınınca kerevit kaybolmaz", traps.shown_count(id) == rules.trap_max - 1)
	# 9) Uzaktaki tuzağa dokun: balıkçı kıyı yolundan yürür, varınca toplar.
	save.bucket.clear()
	GameState.changed.emit()
	var trap_at := TrapSim.position(save.traps[0])
	var lake := _session().lake
	var reach := float((main.get_script() as Script).get_script_constant_map().get("TRAP_REACH", 5.0))
	var away := Dice.NO_POINT
	for k in 24:
		var p := _angler().pos2() + Vector2.from_angle(TAU * k / 24.0) * 7.5
		if lake.in_world(p) and lake.shore_distance(p) < -0.8 and p.distance_to(trap_at) > reach + 2.0 \
				and str(Zones.at(db, spot, p).get("id", "")) == "reeds":
			away = p
			break
	if Dice.is_point(away):
		_angler().place(away)
		main.call("_snap_camera")
		await _wait(0.5)
		await _tap(_screen(traps.mark_point(id)))
		var walked := await _wait_until(func() -> bool: return save.bucket.size() >= rules.trap_max - 1, 15.0)
		_check("uzaktaki tuzağa dokun → balıkçı yürür ve toplar", walked
				and _angler().pos2().distance_to(trap_at) <= reach + 0.6)
	else:
		_check("uzaktaki tuzağa dokun: uzak yer bulunamadı", false)
	await _wait(2.5)
	# 10) Haritada tuzak işareti.
	var map_panel: MapPanel = main.get("map_panel")
	await _tap_control(hud.map_button)
	await _wait_until(func() -> bool: return map_panel.visible, 2.0)
	await _wait(0.4)
	var marks := 0
	for node in map_panel.find_children("*", "GameIcon", true, false):
		if (node as GameIcon).kind == "trap":
			marks += 1
	_check("haritada tuzak işareti", marks == save.traps.size())
	await _shot("49_harita_tuzak")
	map_panel.close_panel()
	await _wait(0.3)
	# 11) Boş tuzak kaldırılır: çantaya döner.
	await _tap(_screen(traps.mark_point(id)))
	await _wait_frames(3)
	if trap_panel.visible:
		await _wait(0.3)
		await _tap_control(trap_panel.find_child("Button_remove", true, false))
		await _wait_frames(3)
	_check("boş tuzak kaldırılır (çantaya döner)", save.traps.is_empty() and not traps.has_mark(id)
			and TrapSim.spare(db, save) == 1)
	# Sonraki bölümler boş kovayla ve gerçek saatle başlar.
	clock.fixed_unix = -1
	save.bucket.clear()
	GameState.changed.emit()
	await _wait_frames(2)


## Sinek (rütbe 7): rütbe gelince haber; iskelede çantadan Nine'ye, sinek kamışı alınır ama ele
## geçmez (Nine dere ağzını söyler), Sinek sekmesi; çantada "Dere ağzında"; dere ağzında sinek
## seçilir; akıntıya atış: sinek sürüklenir, alabalık altına gelir, halka çıkınca VUR, çırpınırken
## sudan sıçrar, tutulur; halkadan önce dokunmak kaçırır; durgun suda sinek kendiliğinden döner (Dede
## söyler); dere ağzından çıkınca şamandıraya dönülür (bildirim).
func _play_fly() -> void:
	var db := GameState.db
	var save := GameState.save
	var spot := str(main.get("spot_id"))
	var hud := _hud()
	var shop: ShopPanel = main.get("shop_panel")
	var bag: TechniquePanel = main.get("technique_panel")
	var bobber: Bobber = main.get("bobber")
	await _travel_to("dock_cove")
	save.xp = maxi(save.xp, db.rank_xp[6])
	GameState.changed.emit()
	await _wait_frames(3)
	var told := str(main.get("_hint_shown")) == "UI_DEDE_TECH_OPEN_fly"
	var toasted := await _wait_toast(UiKit.upper(tr("UI_TECH_OPEN") % tr("UI_TECH_fly")), 6.0)
	_check("rütbe 7: sinek açılır (bildirim, Dede, nabız)", told and toasted and float(hud.get("_tech_pulse")) > 0.0)
	await _shot("20_sinek_acildi")
	# İskelede: çantada sinek Nine'de; sinek kamışı alınır ama ele geçmez.
	await _tap_control(hud.technique_button)
	await _wait_frames(3)
	await _wait(0.3)
	var at_nine := bag.visible and TechniquePanel.state_of(db, save, "fly", spot, "dock_cove") == "shop"
	await _tap_control(bag.find_child("Button_fly", true, false))
	await _wait_frames(3)
	save.coins = maxi(save.coins, 2000)
	shop.refresh()
	await _wait_frames(2)
	_check("çantada sinek Nine'de → dükkân sinek kamışlarında", at_nine and shop.visible and shop.technique == "fly"
			and shop.current_tab() == "rod" and shop.find_child("Card_rod_fly_1", true, false) != null)
	var before := save.technique
	await _tap_card(shop, "rod_fly_1", -1)
	await _wait_frames(3)
	_check("iskelede sinek kamışı: teknik ele geçmez, Nine dere ağzını söyler", Economy.owns(db, save, "rod_fly_1")
			and save.technique == before and _session().technique.id == before
			and str(shop.get("_line_key")) == "UI_NINE_FLY_ZONE")
	await _tap_control(shop.find_child("Tab_tackle", true, false))
	await _wait(0.3)
	_check("sinekte iğne sekmesi Sinek (kuru sinek, nimf, streamer)", shop.find_child("Card_fly_dry", true, false) != null
			and shop.find_child("Card_fly_nymph", true, false) != null
			and shop.find_child("Card_fly_streamer", true, false) != null)
	await _shot("21_dukkan_sinek")
	await _tap(shop.close_button.get_global_rect().get_center())
	await _wait_frames(4)
	# Çantada sinek "Dere ağzında": seçilmez.
	await _tap_control(hud.technique_button)
	await _wait_frames(3)
	await _wait(0.3)
	var where := bag.find_child("Button_fly", true, false) as Button
	var where_ok := where != null and where.text == UiKit.upper(tr("UI_TECH_fly_WHERE"))
	if where != null:
		await _tap_control(where)
		await _wait_frames(3)
	_check("iskelede çantada sinek \"Dere ağzında\", seçilmez", where_ok and bag.visible and save.technique == before)
	await _shot("22_canta_dere_agzinda")
	await _tap(bag.close_button.get_global_rect().get_center())
	await _wait_frames(4)
	# Dere ağzında sinek seçilir: kamış, sinek, düğme ve Dede'nin sözü.
	await _travel_to("stream_mouth")
	await _tap_control(hud.technique_button)
	await _wait_frames(3)
	await _wait(0.3)
	var ready := TechniquePanel.state_of(db, save, "fly", spot, "stream_mouth") == "ready"
	await _tap_control(bag.find_child("Button_fly", true, false))
	await _wait_frames(4)
	_check("dere ağzında sinek seçilir: kamış, sinek, düğme, Dede'nin sözü", ready and not bag.visible
			and save.technique == "fly" and _session().technique.id == "fly" and _angler().rod.style == "fly"
			and bobber.kind == "fly" and (hud.technique_button.get("_icon") as GameIcon).kind == "tech_fly"
			and str(main.get("_hint_shown")) == "UI_DEDE_TECH_FIRST_fly")
	await _wait(0.5)
	await _shot("23_sinek_elde")
	# Akıntıya atış: sinek sürüklenir, alabalık altına gelir, halka çıkınca VUR; çırpınırken sıçrar.
	var out := await _fly_cast("trout", true)
	_check("sinek: akıntıyla sürüklenir (%.1f m), misina sineğe uzanır, Dede halkayı bekletir" % float(out["drift"]),
			float(out["drift"]) > 0.5 and bool(out["line"]) and bool(out["drift_hint"]))
	_check("sinek: alabalık altına gelir, halka çıkar, VUR'la takılır", bool(out["under"]) and bool(out["rise"])
			and bool(out["hooked"]))
	_check("sinek: alabalık çırpınırken sudan sıçrar, tutulur", bool(out["jumped"]) and bool(out["caught"]))
	var early := await _fly_cast("trout", false)
	_check("sinek: halkadan önce dokunmak kaçırır", bool(early["early"]))
	var still := await _fly_cast("", false)
	_check("sinek: durgun suda kendiliğinden döner, Dede akıntıyı söyler", bool(still["came_back"])
			and str(main.get("_hint_shown")) == "UI_DEDE_FLY_STILL")
	# Dere ağzından çıkınca şamandıraya dönülür (bölgenin adından sonra bildirim).
	main.call("_travel", "dock_cove")
	var switched := await _wait_toast(UiKit.upper(tr("UI_TECH_FLY_ONLY")), 8.0)
	_check("dere ağzından çıkınca şamandıraya dönülür (bildirim, kamış, takım)", switched and save.technique == "float"
			and _session().technique.id == "float" and _angler().rod.style == "float" and bobber.kind == "float")
	await _shot("27_samandiraya_dondu")
	await _wait_until(func() -> bool: return not (main.get("fade") as Fade).busy(), 4.0)


## Sinekte bir atış: atış noktasından akıntının güçlü olduğu suya (fish_id boşsa durgun suya) atar.
## fish_id verilirse o türden bir gölge sineğin akıntı aşağısında ona bakar (ötekiler uzakta).
## strike: halka çıkınca VUR'a dokunur ve bir oyuncu gibi çekişir; değilse balık sineğin altına
## gelince dokunur (erken). Balık yoksa sinek kendiliğinden dönene kadar bekler. Her an bir kez
## görüntülenir. finger: dokunulan yer (ekranın her yeri eylem).
func _fly_cast(fish_id: String, strike: bool, finger: Vector2 = Vector2(260, 520)) -> Dictionary:
	var out := { "drift": 0.0, "drift_hint": false, "line": false, "under": false, "rise": false, "hooked": false,
			"jumped": false, "caught": false, "early": false, "came_back": false }
	var session := _session()
	var card: FishCard = main.get("card")
	var target := _fly_target(session, not fish_id.is_empty())
	if not target.is_finite():
		_results.append("sinek: atılacak su bulunamadı")
		return out
	if fish_id.is_empty():
		for s in session.sim.shadows:
			s.pos = target + Vector2(30.0, 30.0)
			s.mode = FishShadow.Mode.PAUSE
			s.timer = 1_000_000
	else:
		var down := session.lake.flow_at(target).normalized()
		_shadow_at(target + down * 2.0, -down, fish_id, 300000)
	_seen_jump = false
	await _tap_world(target)
	if not await _wait_state(FishingSession.State.WAITING, 3.0):
		return out
	var landed := session.bobber
	await _wait_frames(8)
	out["drift_hint"] = str(main.get("_hint_shown")) == "UI_HINT_FLY_DRIFT"
	var line: FishingLine = main.get("line")
	out["line"] = line.visible and line.to.distance_to(_angler().rod_tip()) > 2.0
	await _shot_once("24_sinek_akintida")
	if fish_id.is_empty():
		# Durgun suda sinek kımıldamaz: kısa bir süre sonra kendiliğinden döner.
		out["came_back"] = await _wait_state(FishingSession.State.RETRIEVING, 4.0)
		await _wait_frames(3)
		await _wait_state(FishingSession.State.IDLE, 4.0)
		return out
	out["under"] = await _wait_state(FishingSession.State.NIBBLING, 8.0)
	out["drift"] = session.bobber.distance_to(landed)
	if not out["under"]:
		return out
	await _wait_frames(2)
	await _shot_once("25_altinda_alabalik")
	if not strike:
		await _tap(finger)
		await _wait_frames(2)
		out["early"] = _state() == FishingSession.State.LOST and session.last_loss == "early"
		await _wait_state(FishingSession.State.IDLE, 4.0)
		return out
	out["rise"] = await _wait_state(FishingSession.State.BITING, 4.0) and str(main.get("_hint_shown")) == "UI_HINT_FLY_RISE"
	if _state() != FishingSession.State.BITING:
		return out
	await _shot_once("26_halka")
	_touch(1, finger, true)
	await _wait_frames(2)
	out["hooked"] = _state() == FishingSession.State.FIGHTING
	_touch(1, finger, false)
	await _wait_frames(1)
	if _state() == FishingSession.State.FIGHTING:
		await _reel_like_player(6, 40.0, finger)
	out["jumped"] = _seen_jump
	out["caught"] = _state() == FishingSession.State.CAUGHT
	await _wait_until(func() -> bool: return _state() == FishingSession.State.IDLE or card.visible, 4.0)
	if card.visible:
		await _close_card(card)
	await _wait_state(FishingSession.State.IDLE, 5.0)
	return out


## Sinek için hedef: atış noktasından menzilde, akıntının güçlü olduğu su (akıntı yukarısına bakan
## yönlerden; akıntı aşağısında 2 m de su, balık oraya konur) ya da (flowing false) durgun su.
## Bulunamazsa sonsuz.
func _fly_target(session: FishingSession, flowing: bool) -> Vector2:
	var lake := session.lake
	var up := -lake.strongest_flow().normalized()
	var reach := session.range_m() - 0.5
	for k in 24:
		var dir := up.rotated(deg_to_rad(15.0 * ((k + 1) >> 1)) * (1.0 if k % 2 == 1 else -1.0))
		for d: float in [6.0, 5.0, 7.0, 4.0, 8.0]:
			if d > reach:
				continue
			var p := session.angler + dir * d
			if not lake.is_water(p) or lake.shore_distance(p) < 0.8:
				continue
			var flow := lake.flow_at(p)
			if flowing and flow.length() > 0.6 and lake.is_water(p + flow.normalized() * 2.0) \
					and lake.flow_at(p + flow.normalized() * 2.0).length() > 0.3:
				return p
			if not flowing and flow.length() < 0.02:
				return p
	return Vector2.INF


## Haritadan geçer (main._travel) ve kararmanın bitmesini bekler.
func _travel_to(zone: String) -> void:
	var fade: Fade = main.get("fade")
	main.call("_travel", zone)
	await _wait_frames(2)
	await _wait_until(func() -> bool: return not fade.busy(), 4.0)
	await _wait(0.4)


## Dipte bir atış: balıkçının baktığı yöne atar (takım menzilin sonuna düşer); bir balığı (fish_id)
## takımla balıkçının arasına koyar; koklamada dokunmaz (strike false ise ilk koklamada dokunur:
## erken), koşuda (tap_delay kare sonra) VUR'a dokunur ve bir oyuncu gibi çekişir. finger: dokunulan yer.
func _bottom_cast(strike: bool, fish_id: String = "carp", finger: Vector2 = Vector2(260, 520), tap_delay: int = 6) -> Dictionary:
	var out := { "reach": 0.0, "on_stand": false, "line_from_stand": false, "sniffed": false, "ran": false,
			"picked_up": false, "caught": false, "early": false, "draws": 0 }
	var stand: RodStand = main.get("stand")
	var card: FishCard = main.get("card")
	var fish := _shadow_at(_angler().pos2() + _angler().facing * 3.0, Vector2(0, 1), fish_id, 300000)
	await _tap_control(_hud().action_button)
	if not await _wait_state(FishingSession.State.WAITING, 3.0):
		return out
	await _wait_frames(3)
	var session := _session()
	out["reach"] = session.angler.distance_to(session.bobber)
	out["on_stand"] = stand.visible and _angler().rod_on_stand
	var line: FishingLine = main.get("line")
	out["line_from_stand"] = (line.from_point.call() as Vector3).distance_to(stand.tip_point()) < 0.01
	out["draws"] = int((await _measure_draws())["draws"])
	if fish != null:
		var toward := (session.angler - session.bobber).normalized()
		fish.pos = session.bobber + toward * 2.0
		# Kurşuna dönük: tam ters bakan gölge dönemez (yönün karışımı aynı doğruda kalır), uzaklaşırdı.
		fish.heading = -toward
		fish.mode = FishShadow.Mode.PAUSE
		fish.timer = 1_000_000
	await _shot_once("15_dip_sehpa")
	if not _taken.has("15b_sehpa_yakin"):
		# Sehpa, kamış ve zil yakından (bir kez): kamerayı bot sürer, sonra main'e bırakır.
		main.set("bot_camera", true)
		_frame_on(stand.global_position + Vector3(0.0, 0.45, 0.0), 0.32, deg_to_rad(40.0))
		await _wait_frames(3)
		await _shot_once("15b_sehpa_yakin")
		main.set("bot_camera", false)
	if not await _wait_state(FishingSession.State.NIBBLING, 25.0):
		return out
	# İlk koklama: zil çınlar, kamışın ucu seğirir (sehpanın seğirmesi olayın görünen izi).
	out["sniffed"] = await _wait_until(func() -> bool: return float(stand.get("_twitch")) > 0.0, 4.0)
	await _wait_frames(2)
	await _shot_once("16_koklama")
	if not strike:
		await _tap(finger)
		await _wait_frames(2)
		out["early"] = _state() == FishingSession.State.LOST and _session().last_loss == "early"
		await _wait_state(FishingSession.State.IDLE, 4.0)
		return out
	if not await _wait_state(FishingSession.State.BITING, 12.0):
		return out
	await _wait_frames(tap_delay)
	out["ran"] = stand.get("_running") == true
	await _shot_once("17_kosu")
	_touch(1, finger, true)
	await _wait_frames(3)
	out["picked_up"] = _state() == FishingSession.State.FIGHTING and not _angler().rod_on_stand
	_touch(1, finger, false)
	await _wait_frames(1)
	if _state() == FishingSession.State.FIGHTING:
		await _reel_like_player(6, 40.0, finger)
	out["caught"] = _state() == FishingSession.State.CAUGHT
	await _wait_until(func() -> bool: return _state() == FishingSession.State.IDLE or card.visible, 4.0)
	if card.visible and fish_id != "mirror_carp":
		await _close_card(card)
	if fish_id != "mirror_carp":
		await _wait_state(FishingSession.State.IDLE, 5.0)
	return out


## Spinde bir atış: bir levreği (fish_id) p'ye (balıkçıdan uzağa bakan) koyar, ötesine atar, basılı tutup yemi
## getirir (yem balığın önünden gelir); balık peşine düşünce dur-kalk yapar (evreler kuraldaki en kısa
## evreden uzun). Saldırı anında basılıysa balık kendiliğinden takılır ("auto"), değilse VUR'a dokunur
## ("tap"); sonra bir oyuncu gibi çekişir. Her an bir kez görüntülenir. heading: balığın baktığı yön
## (atışın yönü); finger: dokunulan yer.
func _spin_cast(p: Vector2, cast_to: Vector2, fish_id: String = "perch", heading: Vector2 = Vector2(0, -1),
		finger: Vector2 = Vector2(260, 520)) -> Dictionary:
	var out := { "moved": 0.0, "hidden": false, "followed": false, "reel_hint": false, "follow_hint": false,
			"strike": "", "caught": false, "draws": 0 }
	var card: FishCard = main.get("card")
	_shadow_at(p, heading, fish_id, 300000)
	await _tap_world(cast_to)
	if not await _wait_state(FishingSession.State.WAITING, 3.0):
		return out
	await _wait_frames(2)
	out["hidden"] = not _hud().technique_button.visible
	out["reel_hint"] = str(main.get("_hint_shown")) == "UI_HINT_SPIN_REEL"
	var start := _session().bobber
	_touch(1, finger, true)
	var hold := true
	await _wait_frames(12)
	await _shot_once("06_yem_geliyor")
	# Yem çekilirken arkasında iz halkaları (her biri bir çizim): iskelede de sınırın altında kalmalı.
	out["draws"] = int((await _measure_draws(8))["draws"])
	await _wait_until(func() -> bool: return _state() != FishingSession.State.WAITING, 6.0)
	out["moved"] = _session().bobber.distance_to(start)
	out["followed"] = _state() == FishingSession.State.FOLLOWING
	await _wait_frames(2)
	out["follow_hint"] = str(main.get("_hint_shown")) == "UI_HINT_SPIN_FOLLOW"
	# Dur-kalk: 14 karede (30 fps'te ~0,47 sn) bir bırak ya da bas.
	var frames := 0
	while _state() == FishingSession.State.FOLLOWING:
		await get_tree().process_frame
		frames += 1
		if frames == 20:
			await _shot_once("07_pesinde")
		if frames % 14 == 0:
			hold = not hold
			_touch(1, finger, hold)
	await _wait_frames(1)
	if _state() == FishingSession.State.BITING:
		await _shot_once("08_vur")
		out["strike"] = "tap"
		_touch(1, finger, true)
		hold = true
		await _wait_frames(2)
	elif _state() == FishingSession.State.FIGHTING:
		out["strike"] = "auto"
	if hold:
		_touch(1, finger, false)
		await _wait_frames(1)
	if _state() == FishingSession.State.FIGHTING:
		await _shot_once("09_cekisme")
		await _reel_like_player(6, 25.0, finger)
	elif _state() == FishingSession.State.WAITING:
		# Saldırı olmadı (balık vazgeçti): yem sonuna kadar getirilir.
		_touch(1, finger, true)
		await _wait_until(func() -> bool: return _state() != FishingSession.State.WAITING, 10.0)
		_touch(1, finger, false)
	out["caught"] = _state() == FishingSession.State.CAUGHT
	# Kart (yeni tür, rekor) açıldıysa kapanır; olta boşa döner.
	await _wait_until(func() -> bool: return _state() == FishingSession.State.IDLE or card.visible, 4.0)
	if card.visible:
		await _close_card(card)
	await _wait_state(FishingSession.State.IDLE, 5.0)
	return out


## Ortadaki bildirim bu yazıyla görünene kadar bekler.
func _wait_toast(text: String, timeout: float) -> bool:
	var toast: Label = _hud().get("_toast")
	return await _wait_until(func() -> bool: return toast.is_visible_in_tree() and toast.text == text, timeout)


## Bu adla ilk kez görüntü alınıyorsa alır (tekrarlanan atışlarda bir kez).
func _shot_once(shot_name: String) -> void:
	if _taken.has(shot_name):
		return
	_taken[shot_name] = true
	await _shot(shot_name)


## Gezi: ayarlardan bütün bölgeler açılır ve ölçüm açılır (gerçek dokunuşlarla); her bölgenin atış
## noktası, sonra sandalla derin orta. Her yerde çizim ve üçgen sayısı (ÇİZİM satırları) ve ekran
## görüntüsü.
func _play_tour() -> void:
	_use_save(3)
	var db := GameState.db
	var save := GameState.save
	var spot := str(main.get("spot_id"))
	Records.add(save.records, "rudd", 999, 3, 0)
	GameState.changed.emit()
	await _wait(1.0)
	var hud := _hud()
	var settings: SettingsPanel = main.get("settings_panel")
	# Ölçüm kapalı başlar (yüklenen kayıtta açık kalmış olabilir: 5 dokunuş onu kapatırdı).
	save.settings["perf"] = false
	GameState.changed.emit()
	await _tap_control(hud.settings_button)
	await _wait_until(func() -> bool: return settings.visible, 2.0)
	await _wait(0.4)
	_check("ayarlar paneli küçülmeden sığar (%.2f)" % settings.fit_scale(), settings.fit_scale() > 0.999)
	# Sürüm yazısına arka arkaya 5 dokunuş: ölçüm açılır; geliştirme satırları görünür.
	var version: Label = null
	for node in settings.find_children("*", "Label", true, false):
		if (node as Label).text.begins_with(tr("UI_GAME_TITLE")):
			version = node as Label
	if version != null:
		for i in SettingsPanel.PERF_TAPS:
			await _tap_control(version)
			await _wait(0.15)
	await _wait(0.3)
	# Geliştirme düğmesi: rütbe en yüksek bölgeninki, sandal (çitler açılır, erişim yenilenir).
	var unlock := _button_with_text(settings, UiKit.upper(tr("UI_DEBUG_UNLOCK_GO")))
	# Dokunuştan sonra panel satırlarını yeniden kurar (düğme silinir): bulunduğu önceden yazılır.
	var found := unlock != null
	if found:
		await _tap_control(unlock)
		await _wait_frames(3)
	var all_open := true
	for z in db.zones_of(spot):
		all_open = all_open and Zones.unlocked(db, save, z)
	_check("ölçüm açıkken \"Bölgeleri ve teknikleri aç\" → rütbe %d ve sandal, bütün bölgeler açık" % Rank.rank(db, save),
			found and all_open and Economy.owns(db, save, Zones.BOAT) and int(main.get("_access_rank")) == Rank.rank(db, save))
	await _shot("00_ayarlar")
	settings.close_panel()
	await _wait(1.0)
	var fps: Label = hud.get("_fps")
	_check("sürüm yazısına 5 dokunuş → ölçüm açık (sol üstte FPS, çizim, üçgen)", bool(GameState.setting("perf", false))
			and fps.visible and fps.text.count("·") == 2)
	var fade: Fade = main.get("fade")
	var worst := 0
	var where := ""
	var index := 1
	for z in db.zones_of(spot):
		var id := str(z["id"])
		main.call("_travel", id)
		await _wait_until(func() -> bool: return fade.busy(), 1.0)
		var arrived := await _wait_until(func() -> bool: return not fade.busy() and str(main.get("zone_id")) == id, 5.0)
		if not arrived:
			_check("%s bölgesine geçilir" % id, false)
			continue
		await _wait(1.5)
		var info := await _measure_draws()
		print("ÇİZİM %-13s %3d çizim, %6d üçgen%s" % [id, info["draws"], info["primitives"],
				" (sandalda)" if bool(main.get("in_boat")) else ""])
		if int(info["draws"]) > worst:
			worst = int(info["draws"])
			where = id
		await _shot("%02d_%s" % [index, id])
		index += 1
	_check("her yerde en çok %d çizim (en çok %d: %s)" % [TOUR_DRAWS, worst, where], worst <= TOUR_DRAWS and worst > 0)
	for line in _results:
		print("KONTROL ", line)
	_quit()


## Bir düğümün altında yazısı bu olan düğme (yoksa null).
static func _button_with_text(root: Node, text: String) -> Button:
	for node in root.find_children("*", "Button", true, false):
		if (node as Button).text == text:
			return node as Button
	return null


## Son karelerin en yüksek çizim ve üçgen sayısı (karenin bütün çizimleri: 3B sahne ve arayüz).
func _measure_draws(frames: int = 10) -> Dictionary:
	var draws := 0
	var primitives := 0
	for i in frames:
		await get_tree().process_frame
		draws = maxi(draws, RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME))
		primitives = maxi(primitives, RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME))
	return { "draws": draws, "primitives": primitives }


## Haritanın rozetleri büyük (en az 122 birim) ve güvenli alanda mı?
func _check_map_badges(panel: MapPanel) -> void:
	var view := get_viewport().get_visible_rect()
	var inset := UiKit.safe_insets(panel)
	var safe := Rect2(view.position + Vector2(inset.x, inset.y), view.size - Vector2(inset.x + inset.z, inset.y + inset.w))
	var notes := PackedStringArray()
	var count := 0
	for zone in GameState.db.zones_of(str(main.get("spot_id"))):
		var badge := panel.view.badge(str(zone["id"]))
		if badge == null:
			continue
		count += 1
		var r := badge.get_global_rect()
		if minf(r.size.x, r.size.y) < 121.5:
			notes.append("%s küçük %s" % [zone["id"], str(r.size)])
		if not safe.encloses(r):
			notes.append("%s güvenli alan dışında" % zone["id"])
	_check("harita rozetleri büyük ve güvenli alanda (%d)%s" % [count, "" if notes.is_empty() else ": " + ", ".join(notes)],
			notes.is_empty() and count > 0)


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


## Gölün bütün balıkları (16; kerevit dahil): elde (CatchFx) ve kartı. Görsel denetim; oturum kuralları
## işlemez. --fish=<kimlik> yalnızca o tür.
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
		if not _only_fish.is_empty() and id != _only_fish:
			continue
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
	await _shot("99_ayarlar")
	_quit()


## Tanıtım videosu (Dalga 3, v0.4: teknikler). Oyun zamanı --fixed-fps ile kare kare akar; bekleyişler
## oyun zamanıyla. Dönen bir oyuncu (rütbe 9; spin, dip ve sinek kamışı alınmış, sazlıkta dolu bir
## tuzak): iskelede Takım Çantası'ndan spin, dur-kalk ve saldıran turna; haritadan sazlık, dolu tuzağı
## topla (kerevit ×4), dip: uzağa atış, sehpa, zil tek tük ve durmadan, aynalı sazan; haritadan dere
## ağzı, sinek: akıntıda süzülen sinek, halka, VUR, sudan sıçrayan alabalık.
func _play_video() -> void:
	_use_save(40)
	var db := GameState.db
	var save := GameState.save
	var spot := str(main.get("spot_id"))
	save.coins = 1800
	save.xp = db.rank_xp[8]
	for f: Array in [["rudd", 26, 4], ["carp", 52, 3], ["perch", 31, 2], ["silverside", 14, 2], ["bream", 40, 3],
			["tench", 38, 3], ["crayfish", 11, 3]]:
		Records.add(save.records, f[0], f[1], f[2], 0)
	# Büyük kova: turna, dört kerevit, aynalı sazan ve alabalık sığsın (kova dolu bildirimi videoda yok).
	for id: String in ["rod_spin_light", "rod_carp_1", "rod_fly_1", "line_mono", "trap_1", "bucket_big"]:
		if not id in save.owned:
			save.owned.append(id)
		Economy.equip(db, save, id)
	# Bot ekran görüntüsü almaz; dipteki sehpa yakın çekimi (kamera sıçraması) videoda yok.
	_taken["15b_sehpa_yakin"] = true
	# Sazlıkta dolu bir tuzak: atış noktasının önündeki sığ suda, oyun kapalıyken dolmuş.
	var reeds := db.zone(spot, "reeds")
	var stand: Vector2 = (reeds["stands"] as Array)[0]
	var clock := GameState.clock
	var t0 := clock.now_unix()
	clock.fixed_unix = t0
	var at := TrapSim.spot_near(db, save, spot, "reeds", stand, Vector2(0.0, -1.0))
	if at != Dice.NO_POINT:
		TrapSim.place(db, save, spot, "reeds", at, t0 - (db.rules.trap_max + 1) * db.rules.trap_fill_s)
		TrapSim.update_all(db.rules, save, t0)
	GameState.changed.emit()
	main.call("_on_gear_changed")
	var hud := _hud()
	var bag: TechniquePanel = main.get("technique_panel")
	var panel: MapPanel = main.get("map_panel")
	var fade: Fade = main.get("fade")
	var traps: TrapMarkers = main.get("traps")
	var card: FishCard = main.get("card")
	await _wait(1.4)
	# Takım Çantası: dört teknik ve tuzak; spin seçilir (kamış, yapay yem, Dede'nin sözü).
	await _tap_control(hud.technique_button)
	await _wait_until(func() -> bool: return bag.visible, 2.0)
	await _wait(1.8)
	await _shot("v1_canta")
	await _tap_control(bag.find_child("Button_spin", true, false))
	await _wait(1.2)
	_check("video: spin elde", save.technique == "spin" and _session().technique.id == "spin")
	# Spin: yemin ötesine atılır, basılı tutunca gelir; turna peşine düşer, dur-kalkta saldırır.
	var spin := await _spin_cast(Vector2(0.4, -2.6), Vector2(0.4, -5.4), "pike")
	_check("video: spinle turna tutulur", bool(spin["caught"]))
	await _wait(0.6)
	# Haritadan sazlığa: dolu tuzak (yeşil, nabız gibi atan 4/4 rozeti).
	await _map_to(panel, fade, "reeds")
	# Bölgenin adı sönsün: rozet (4/4, nabız gibi atan yeşil) açıkça görünsün.
	await _wait(2.6)
	await _shot("v2_tuzak_dolu")
	var trap_id := int(save.traps[0]["id"]) if not save.traps.is_empty() else -1
	_check("video: sazlıkta dolu tuzak (%d)" % traps.shown_count(trap_id), trap_id >= 0
			and traps.shown_count(trap_id) == db.rules.trap_max)
	if trap_id >= 0:
		await _tap(_screen(traps.mark_point(trap_id)))
		await _wait(2.6)
		await _shot("v3_kerevitler")
		_check("video: tuzak toplanır (kerevitler kovada)", save.bucket.filter(
				func(b: Dictionary) -> bool: return str(b["fish"]) == "crayfish").size() == db.rules.trap_max)
	# Dip: çantadan; uzağa atış, olta sehpada; zil tek tük çalar (kokluyor), sonra durmadan: VUR.
	await _tap_control(hud.technique_button)
	await _wait_until(func() -> bool: return bag.visible, 2.0)
	await _wait(1.0)
	await _tap_control(bag.find_child("Button_bottom", true, false))
	await _wait(1.6)
	var bottom := await _bottom_cast(true, "mirror_carp")
	_check("video: dipte aynalı sazan tutulur", bool(bottom["caught"]))
	await _wait(3.0)
	await _shot("v4_aynali_sazan")
	await _close_card(card)
	await _wait_state(FishingSession.State.IDLE, 5.0)
	await _wait(0.6)
	# Haritadan dere ağzına; sinek: akıntıya at, sinek süzülür, alabalık altına gelir, halka: VUR.
	await _map_to(panel, fade, "stream_mouth")
	await _wait(0.8)
	await _tap_control(hud.technique_button)
	await _wait_until(func() -> bool: return bag.visible, 2.0)
	await _wait(1.0)
	await _tap_control(bag.find_child("Button_fly", true, false))
	await _wait(1.6)
	_check("video: sinek elde (dere ağzında)", save.technique == "fly")
	var fly := await _fly_cast("trout", true)
	_check("video: sinekle alabalık tutulur, sudan sıçrar", bool(fly["caught"]) and bool(fly["jumped"]))
	await _wait(2.0)
	await _shot("v5_son")
	clock.fixed_unix = -1
	for line in _results:
		print("KONTROL ", line)
	_quit()


# --- Reels: Instagram reklamının çekimi -------------------------------------------------

## Reels reklamının çekimi (kurgu: tools/reels_ad.py; CLAUDE.md "Reels videosu"). Dönen bir oyuncu
## (rütbe 9, en iyi takımın çoğu, sandal, sazlıkta dolu tuzak); her çekim bir bölgede. Kamerayı bot
## yönetir (_cam_shot): aksiyon ortadaki kare kırpmada kalır. Sözler kurguda yazıyla verilir: ipucu çubuğu
## kırpmaya sığmaz, gizlenir. Nadir balıkları bot sahneler (türü ve boyu); kurallar aynen işler.
## Günlük: REELS SYNC (kayıtta 2 karelik beyaz parlama), TAKE, MARK, CUT (kamera sıçraması, kararma),
## PANEL (panelin ekrandaki yeri), TOAST, AIM, END; kare numarası Engine.get_frames_drawn().
func _play_reels() -> void:
	_reels_setup()
	await _wait(1.2)
	# Kurgu aracı kaydın karelerini günlükle bu parlamayla eşler.
	_overlay.call("flash", 2)
	var view := get_viewport().get_visible_rect().size
	_reels_log("SYNC", "%d %d" % [int(view.x), int(view.y)])
	await _wait(0.4)
	var db := GameState.db
	var save := GameState.save
	var start_rank := Rank.rank(db, save)
	for take in REELS_TAKES:
		if not _reels_only.is_empty() and not take in _reels_only:
			continue
		match take:
			"dock":
				await _reels_dock()
			"gold":
				await _reels_gold()
			"spin":
				await _reels_spin()
			"reeds":
				await _reels_reeds()
			"fly":
				await _reels_fly()
			"legend":
				await _reels_legend()
			"book":
				await _reels_book()
	_set_shot(Callable())
	_check("reels: rütbe değişmedi (%d), kova dolmadı (%d/%d)" % [Rank.rank(db, save), save.bucket.size(),
			Bucket.capacity(db, save)], Rank.rank(db, save) == start_rank and not Bucket.is_full(db, save))
	_reels_log("END", "")
	GameState.clock.fixed_unix = -1
	for line in _results:
		print("KONTROL ", line)
	_quit()


## Reels oyuncusu: rütbe 9 (rütbe 10'a çekimdeki balıklar yetmez), defterde 12 tür, takım (REELS_GEAR),
## Dede'nin ve Nine'nin ilk kez söylenen sözleri, bölge önerileri ve tekniklerin ipuçları çoktan
## görülmüş; sazlıkta oyun kapalıyken dolmuş bir tuzak. Ortam sesi kapalı (kurguda kesintisiz eklenir).
func _reels_setup() -> void:
	_use_save(40)
	var db := GameState.db
	var save := GameState.save
	var spot := str(main.get("spot_id"))
	save.coins = 2450
	save.xp = db.rank_xp[8] + 100
	save.settings["easy"] = false
	save.settings["perf"] = false
	for f: Array in REELS_RECORDS:
		Records.add(save.records, f[0], f[1], f[2], 0)
	for id: String in REELS_GEAR:
		if not id in save.owned:
			save.owned.append(id)
		Economy.equip(db, save, id)
	for t: String in ContentDB.TECHNIQUES:
		save.flags["told_open_" + t] = true
		save.flags["told_tech_" + t] = true
		save.flags["tech_casts_" + t] = 9
	for key: String in ["told_open_trap", "told_trap_line", "told_trap_first", "told_snag", "told_fly_still"]:
		save.flags[key] = true
	for z in db.zones_of(spot):
		save.flags["visited_" + str(z["id"])] = true
		save.flags[Elder.SUGGEST_FLAG % str(z["id"])] = true
	var reeds := db.zone(spot, "reeds")
	var stand: Vector2 = (reeds["stands"] as Array)[0]
	var clock := GameState.clock
	var t0 := clock.now_unix()
	clock.fixed_unix = t0
	var at := TrapSim.spot_near(db, save, spot, "reeds", stand, Vector2(0.0, -1.0))
	if at != Dice.NO_POINT:
		TrapSim.place(db, save, spot, "reeds", at, t0 - (db.rules.trap_max + 1) * db.rules.trap_fill_s)
		TrapSim.update_all(db.rules, save, t0)
	GameState.changed.emit()
	main.call("_on_gear_changed")
	# Dipteki sehpa yakın çekimini (bir kez, kamera sıçraması) yönetmen yapar.
	_taken["15b_sehpa_yakin"] = true
	_park_fn = _reels_park_point
	# İpucu çubuğu ve sol üstteki durum hapları (para, kova, rütbe çubuğu) ortadaki kareye taşar, gizlenir.
	(_hud().get("_hint") as Control).modulate.a = 0.0
	(_hud().get("_status") as Control).modulate.a = 0.0
	for player: AudioStreamPlayer in (Sounds.get("_ambience") as Array):
		player.stop()
	var view := get_viewport().get_visible_rect().size
	_finger = Vector2(view.x * 0.5 + 360.0, view.y * 0.7)


## İskele: Nine tezgâhında selam verir, Dede gölün sırrını söyler (yakın çekimler, yavaşça yaklaşan
## kamera); son kartın arka planı için uzaklaşan geniş çekim (balıkçı atar, Dede şamandırayı izler).
func _reels_dock() -> void:
	var nine := _nine()
	var elder := _elder()
	var nine_at := nine.head_point() + Vector3(0.1, -0.35, 0.1)
	_set_shot(func() -> Dictionary: return _frame(nine_at, _ease(0.4, 0.31, 2.6, _shot_t), REELS_CLOSE_PITCH))
	await _reels_go("dock_cove")
	await _reels_technique("float")
	_take("dock")
	await _wait(0.8)
	nine.greet()
	_mark("nine")
	var greeted := nine.bubble.is_showing()
	await _wait(2.0)
	_check("reels: iskele: Nine selam verir", greeted)
	var elder_at := elder.head_point() + Vector3(0.0, -0.3, 0.0)
	_set_shot(func() -> Dictionary: return _frame(elder_at, _ease(0.42, 0.32, 3.0, _shot_t), REELS_CLOSE_PITCH))
	_snap_shot()
	await _wait(0.7)
	# Sıradaki öğüt gölün sırrı (UI_DEDE_TIP_5): Dede'ye gerçek bir dokunuş (iz çizilmez: yakın çekim).
	var tips := Elder.tips(GameState.db, GameState.save)
	main.set("_tip_index", tips.find(Elder.TIP_KEY % 5))
	_hide_fingers = true
	await _tap(_screen(elder.head_point()))
	_hide_fingers = false
	_mark("dede")
	_check("reels: iskele: Dede gölün sırrını söyler", str(main.get("_hint_shown")) == Elder.TIP_KEY % 5
			and elder.bubble.is_showing())
	await _wait(2.6)
	# Uzaklaşan geniş çekim: balıkçı atar; gölgeler uzakta (balık gelmez, "Kaçırdın" çıkmaz).
	var up := FollowCamera.screen_up()
	var wide := _angler().global_position.lerp(elder.global_position, 0.5) + Vector3(up.x, 0.0, up.y) * 1.5
	_set_shot(func() -> Dictionary: return _frame(wide, _ease(0.85, 1.5, 5.5, _shot_t), deg_to_rad(52.0)))
	_snap_shot()
	_mark("outro")
	_park_all()
	var spot := _reels_spot(5.0, 0.0)
	await _wait(0.8)
	_hide_fingers = true
	if not spot.is_empty():
		await _tap_world(spot[0])
	await _wait(5.2)
	if _session().line_out():
		await _tap(_finger)
	_hide_fingers = false
	await _wait_state(FishingSession.State.IDLE, 4.0)


## Nilüferli koy: Destansı altın sazan şamandıraya süzülür (yaklaşan kamera), dalar, bir vuruş sonra
## VUR, çekişme (kamera geri çekilir); elde mor ışık sütunu, kart.
func _reels_gold() -> void:
	_set_shot(func() -> Dictionary: return _game_frame(0.9))
	await _reels_go("lily_cove")
	await _reels_technique("float")
	_take("gold")
	await _wait(0.6)
	# Koy küçük: nilüfersiz su (kıyıdan 3,2 m'den uzak) dar. Şamandıra en açık yere, balık oraya en
	# nilüfersiz yoldan gelir (nilüfer gölgenin üstünde çizilir).
	var spot := _reels_spot(5.0, 0.0, 3.8)
	if spot.is_empty():
		_check("reels: nilüferli koy: atılacak su", false)
		return
	var land: Vector2 = spot[0]
	var from := _reels_open_path(land, 2.6)
	var fish := _shadow_at(from, land - from, "golden_carp", 800000)
	await _tap_world(land)
	if fish == null or not await _wait_state(FishingSession.State.WAITING, 3.0):
		_check("reels: nilüferli koy: atış", false)
		return
	_set_shot(func() -> Dictionary:
		if _state() in [FishingSession.State.WAITING, FishingSession.State.NIBBLING, FishingSession.State.BITING]:
			var b := _session().bobber
			var near := Vector3(b.x, 0.0, b.y).lerp(Vector3(fish.pos.x, 0.0, fish.pos.y), 0.3)
			return _frame(near, _ease(0.9, 0.5, 4.5, _shot_t), float(main.get("LINE_PITCH")))
		return _game_frame(0.88))
	var caught := await _reels_bite("altın sazan", 6)
	var shown := await _reels_show("altın sazan", 2.2)
	_check("reels: nilüferli koy: altın sazan tutulur, ışık sütunu ve kart", caught and shown
			and str(_session().last_catch.get("fish", "")) == "golden_carp")


## Kayalık burun: spinle turna (yem gelir, turna peşine düşer, dur-kalk, saldırı), kartı.
func _reels_spin() -> void:
	_set_shot(func() -> Dictionary: return _game_frame(0.85))
	await _reels_go("rocky_point")
	await _reels_technique("spin")
	_take("spin")
	await _wait(0.6)
	var spot := _reels_spot(5.6, 0.0)
	if spot.is_empty():
		_check("reels: kayalık burun: atılacak su", false)
		return
	var dir: Vector2 = spot[1]
	# Yem gelirken kamera yemle turnaya yakın (turna peşinde, dur-kalk, saldırı); çekişmede geri çekilir.
	_set_shot(func() -> Dictionary:
		if _state() in [FishingSession.State.WAITING, FishingSession.State.FOLLOWING, FishingSession.State.BITING]:
			var lure := _session().bobber
			return _frame(_angler().global_position.lerp(Vector3(lure.x, 0.0, lure.y), 0.62), 0.6,
					float(main.get("LINE_PITCH")))
		return _game_frame(0.82))
	var out := await _spin_cast(_session().angler + dir * 2.8, spot[0], "pike", dir, _finger)
	_check("reels: kayalık burun: spinle turna tutulur (%s)" % out["strike"], bool(out["followed"])
			and bool(out["caught"]) and str(_session().last_catch.get("fish", "")) == "pike")


## Sazlık: dolu tuzak (4/4, nabız gibi atan yeşil rozet) toplanır; dip: sehpa yakın çekim, zil tek tük
## (koklama), sonra durmadan (koşu): bir vuruş sonra VUR, aynalı sazan.
func _reels_reeds() -> void:
	var db := GameState.db
	var save := GameState.save
	var traps: TrapMarkers = main.get("traps")
	var catch_fx: CatchFx = main.get("catch_fx")
	var trap_id := int(save.traps[0]["id"]) if not save.traps.is_empty() else -1
	var at := traps.mark_point(trap_id) if trap_id >= 0 and traps.has_mark(trap_id) else Vector3.INF
	_set_shot(func() -> Dictionary:
		if catch_fx.is_showing() or not at.is_finite():
			return _game_frame(0.85)
		return _frame(_angler().global_position.lerp(at, 0.7), _ease(0.74, 0.64, 2.2, _shot_t), FollowCamera.PITCH))
	await _reels_go("reeds")
	await _reels_technique("float")
	_take("trap")
	if not at.is_finite():
		_check("reels: sazlık: dolu tuzak", false)
	else:
		var full := traps.shown_count(trap_id) == db.rules.trap_max
		await _wait(1.8)
		_aim("trap.full", at)
		_mark("tap")
		await _tap(_screen(at))
		await _wait(2.6)
		var kept := save.bucket.filter(func(b: Dictionary) -> bool: return str(b["fish"]) == "crayfish").size()
		_check("reels: sazlık: dolu tuzak (%s) toplanır, kerevit ×%d kovada" % [full, kept], full
				and kept == db.rules.trap_max)
	await _reels_technique("bottom")
	_take("dip")
	var stand: RodStand = main.get("stand")
	var card: FishCard = main.get("card")
	_set_shot(func() -> Dictionary:
		if stand.visible and _state() in [FishingSession.State.WAITING, FishingSession.State.NIBBLING,
				FishingSession.State.BITING]:
			# Sehpa, yatan kamış ve ucundaki zil (balıkçının şapkası kadrajın kenarında).
			return _frame(stand.global_position.lerp(stand.tip_point(), 0.45) + Vector3(0.0, 0.2, 0.0), 0.5,
					deg_to_rad(48.0))
		return _game_frame(0.9))
	await _wait(0.6)
	var out := await _bottom_cast(true, "mirror_carp", _finger, 15)
	_check("reels: sazlık: dipte zil tek tük, sonra durmadan; aynalı sazan tutulur", bool(out["sniffed"])
			and bool(out["ran"]) and bool(out["caught"]))
	if await _wait_until(func() -> bool: return card.visible, 3.0):
		await _wait(1.4)
		if card.visible and card.ok_button != null:
			await _tap(card.ok_button.get_global_rect().get_center())
	await _wait_state(FishingSession.State.IDLE, 5.0)


## Dere ağzı: sinek akıntıda süzülür, alabalık altına gelir, halka: VUR, sudan sıçrar; sonra şamandıra
## (sinek derin ortada avlanılmaz).
func _reels_fly() -> void:
	var bobber: Bobber = main.get("bobber")
	# Sinek ve altına gelen alabalık yakından; takılınca ilk sıçrayış da (çekişmenin ilk 1,4 sn'si) yakın.
	_set_shot(func() -> Dictionary:
		var state := _state()
		var session := _session()
		if bobber.visible and state in [FishingSession.State.WAITING, FishingSession.State.NIBBLING,
				FishingSession.State.BITING]:
			var f := session.bobber
			return _frame(_angler().global_position.lerp(Vector3(f.x, 0.0, f.y), 0.85),
					0.62 if state == FishingSession.State.WAITING else 0.52, float(main.get("LINE_PITCH")))
		if state == FishingSession.State.FIGHTING and _state_t < 1.4:
			var p := session.fight_point()
			return _frame(_angler().global_position.lerp(Vector3(p.x, 0.0, p.y), 0.75), 0.6, float(main.get("LINE_PITCH")))
		return _game_frame(0.82))
	await _reels_go("stream_mouth")
	await _reels_technique("fly")
	_take("fly")
	await _wait(0.6)
	var out := await _fly_cast("trout", true, _finger)
	# Halka (rise) Dede'nin ipucuyla denetlenir; ipuçları bu kayıtta susturuldu: halkayı işaret (fly.biting) gösterir.
	_check("reels: dere ağzı: sinekle alabalık, halka, sudan sıçrar", bool(out["under"]) and _marks.has("fly.biting")
			and bool(out["hooked"]) and bool(out["jumped"]) and bool(out["caught"]))
	await _reels_technique("float")


## Haritadan sandalla derin ortaya; efsanevi mersin: altın izli gölge şamandıraya yüzer, balıkçıya 9 m
## kalınca Dede haber verir; çekişmede geç bırakılınca kırmızı ("BIRAK!"); elde altın ışık sütunu, kart,
## "Göle bırak" ve bildirim.
func _reels_legend() -> void:
	await _reels_technique("float")
	_set_shot(func() -> Dictionary: return _game_frame(1.0))
	await _wait_state(FishingSession.State.IDLE, 5.0)
	_take("map")
	var panel: MapPanel = main.get("map_panel")
	var fade: Fade = main.get("fade")
	await _tap_control(_hud().map_button)
	if not await _wait_until(func() -> bool: return panel.visible, 2.0):
		_check("reels: harita açılır", false)
		return
	await _wait(0.4)
	_panel_log("map", panel.get("_panel"))
	_mark("open")
	await _wait(1.2)
	_mark("tap")
	await _tap_control(panel.view.badge("deep_water"))
	await _wait_until(func() -> bool: return fade.busy(), 1.0)
	await _wait_until(func() -> bool: return not fade.busy(), 4.0)
	_take("legend")
	_check("reels: haritadan sandalla derin ortaya", bool(main.get("in_boat")))
	await _wait(1.4)
	var spot := _reels_spot(5.5, 5.1)
	if spot.is_empty():
		_check("reels: derin orta: atılacak su", false)
		return
	var land: Vector2 = spot[0]
	var dir: Vector2 = spot[1]
	_park_all()
	await _tap_world(land)
	if not await _wait_state(FishingSession.State.WAITING, 3.0):
		_check("reels: derin orta: atış", false)
		return
	await _wait(0.5)
	# Mersin balıkçıdan 10,6 m uzakta, şamandıranın ötesinde; şamandıraya yüzer, 3 m kalınca fark eder.
	var fish := _shadow_at(_session().angler + dir * 10.6, -dir, "sturgeon", 750000)
	if fish == null:
		_check("reels: derin orta: mersin", false)
		return
	fish.mode = FishShadow.Mode.WANDER
	fish.target = land
	fish.speed = 0.5
	_set_shot(func() -> Dictionary:
		if _state() in [FishingSession.State.WAITING, FishingSession.State.NIBBLING, FishingSession.State.BITING]:
			var b := _session().bobber
			var near := Vector3(b.x, 0.0, b.y).lerp(Vector3(fish.pos.x, 0.0, fish.pos.y), 0.45)
			return _frame(near, _ease(0.95, 0.62, 6.0, _shot_t), float(main.get("LINE_PITCH")))
		return _game_frame(0.85))
	var sim := _session().sim
	var noticed := await _wait_until(func() -> bool: return (main.get("_announced") as Dictionary).has(fish.id), 10.0)
	_check("reels: derin orta: efsanevi gölge, Dede haber verir", noticed
			and str(main.get("_hint_shown")) == "UI_DEDE_LEGEND_NEAR")
	await _wait_until(func() -> bool: return sim.approacher == fish, 10.0)
	var caught := await _reels_bite("mersin", REELS_LEGEND_REACTION)
	var red := int(_marks.get("legend.red", 0))
	_check("reels: derin orta: mersin tutulur (kırmızı %d kez)" % red, caught and red > 0
			and str(_session().last_catch.get("fish", "")) == "sturgeon")
	var shown := await _reels_show("mersin", 2.4)
	await _wait(1.6)
	var told := UiKit.upper(tr("UI_RELEASED") % tr("FISH_sturgeon"))
	_check("reels: mersin göle bırakılır (kart, bildirim)", shown and told in _toasts)


## Balık Defteri: ilk sayfa (12 tür), ikinci sayfa (altın sazan ve mersin, yayın ve dere alabalığı silüet).
func _reels_book() -> void:
	await _wait_state(FishingSession.State.IDLE, 5.0)
	_take("book")
	var book: BookPanel = main.get("book_panel")
	await _tap_control(_hud().book_button)
	if not await _wait_until(func() -> bool: return book.visible, 2.0):
		_check("reels: defter açılır", false)
		return
	await _wait(0.4)
	_panel_log("book", book.get("_panel"))
	_panel_log("book_grid", book.get("_grid"))
	_mark("open")
	await _wait(1.8)
	var pager: HBoxContainer = book.get("_pager")
	if pager.get_child_count() > 1:
		_mark("page2")
		await _tap_control(pager.get_child(1) as Control)
	await _wait(1.8)
	_check("reels: defter açılır, iki sayfa (%d tür)" % Records.species_count(GameState.save.records),
			pager.get_child_count() > 1)
	await _tap(book.close_button.get_global_rect().get_center())
	await _wait(0.6)


## Şamandıra ısırması: dalınca bir vuruş (16 kare) sonra VUR, sonra bir oyuncu gibi çekişir (reaction
## kare gecikmeyle bırakır). Tutulduysa true.
func _reels_bite(label: String, reaction: int) -> bool:
	if not await _wait_state(FishingSession.State.BITING, 40.0):
		_check("reels: %s ısırmadı" % label, false)
		return false
	await _wait_frames(15)
	_touch(1, _finger, true)
	await _wait_frames(2)
	_touch(1, _finger, false)
	await _wait_frames(1)
	if _state() == FishingSession.State.FIGHTING:
		await _reel_like_player(reaction, 60.0, _finger)
	return _state() == FishingSession.State.CAUGHT


## Balık elde (ışık sütunu) ve kartı: kart hold sn açık kalır, sonra düğmesine dokunulur ("Harika!" ya
## da koruma altındaki türde "Göle bırak"; MARK <çekim>.ok). Kart açıldıysa true.
func _reels_show(label: String, hold: float) -> bool:
	var catch_fx: CatchFx = main.get("catch_fx")
	var card: FishCard = main.get("card")
	if not await _wait_until(func() -> bool: return catch_fx.is_showing(), 3.0):
		_check("reels: %s elde gösterilmedi" % label, false)
		return false
	if not await _wait_until(func() -> bool: return card.visible, 3.0):
		return false
	await _wait(hold)
	if card.visible and card.ok_button != null:
		_mark("ok")
		await _tap(card.ok_button.get_global_rect().get_center())
	await _wait_state(FishingSession.State.IDLE, 5.0)
	return true


## Haritadan geçer; geçiş olmadıysa (zaten oradaydı) kamera istenen çerçeveye hemen geçer. Kararmada
## yönetmen yeni yeri hemen çerçeveler (_direct).
func _reels_go(zone: String) -> void:
	var fade: Fade = main.get("fade")
	main.call("_travel", zone)
	await _wait_frames(2)
	if fade.busy():
		await _wait_until(func() -> bool: return not fade.busy(), 4.0)
	else:
		_snap_shot()
	await _wait(0.4)


## Elindeki teknik (Takım Çantası'ndaki seçimin yolu); kamış ve takım değişene kadar bekler.
func _reels_technique(technique: String) -> void:
	if GameState.save.technique == technique and _session().technique.id == technique:
		return
	await _wait_state(FishingSession.State.IDLE, 5.0)
	main.call("_on_technique_selected", technique)
	var bobber: Bobber = main.get("bobber")
	await _wait_until(func() -> bool:
		return _session().technique.id == technique and bobber.kind == Bobber.kind_for(technique), 2.0)
	await _wait(0.3)


## Atış noktasından suya bir hedef: ekranın yukarısına en yakın yön (±15° adımlarla; dikey kırpmada
## balıkçı ile takım alt alta), dist m önde (bulunmazsa biraz uzak ya da yakın; menzilde), kıyıdan en
## az shore m (nilüferler kıyıdan 3,2 m'ye kadar: balık altlarında görünmez) ve iskeleden uzak; ötesinde
## beyond m de öyle su (balık oraya konur). [nokta, yön] ya da bulunamazsa boş.
func _reels_spot(dist: float, beyond: float, shore: float = 1.0) -> Array:
	var session := _session()
	var lake := session.lake
	for k in 24:
		var dir := FollowCamera.screen_up().rotated(deg_to_rad(15.0 * ((k + 1) >> 1)) * (1.0 if k % 2 == 1 else -1.0))
		for d: float in [dist, dist + 1.0, dist - 0.5, dist + 2.0]:
			var p := session.angler + dir * minf(d, session.range_m() - 0.5)
			var q := p + dir * beyond
			if lake.is_water(p) and lake.shore_distance(p) > shore and not lake.on_dock(p) and lake.is_deep(q, 1.0) \
					and lake.shore_distance(q) > shore and not lake.on_dock(q):
				return [p, dir]
	return []


## Takıma radius m uzaktan gelen balığın başlangıcı: yolu kıyıdan en uzak kalan yön (nilüferler ve sığ
## kıyı şeridi yolun üstünde olmasın).
func _reels_open_path(to: Vector2, radius: float) -> Vector2:
	var lake := _session().lake
	var best := to + FollowCamera.screen_up() * radius
	var best_score := -INF
	for k in 36:
		var start := to + Vector2.from_angle(TAU * k / 36.0) * radius
		var score := INF
		for i in 6:
			var p := start.lerp(to, i / 5.0)
			score = minf(score, lake.shore_distance(p) if lake.is_water(p) else -1.0)
		if score > best_score:
			best_score = score
			best = start
	return best


## Öteki gölgelerin bırakıldığı yer: balıkçının çevresinde 9–14 m'de derin su; konulan balıktan ve
## takımdan uzak (fark etmez), kadrajın dışında. Çok uzağa konan gölge çekilir, yenisi yakında doğardı.
func _reels_park_point(i: int, avoid: Vector2) -> Vector2:
	var session := _session()
	var lake := session.lake
	var rig := session.bobber if session.line_out() else avoid
	for r: float in [12.0, 10.0, 14.0, 9.0]:
		for k in 16:
			var p := session.angler + Vector2.from_angle(TAU * float((k * 5 + i * 3) % 16) / 16.0) * r
			if lake.is_deep(p, 0.8) and p.distance_to(avoid) >= 7.0 and p.distance_to(rig) >= 7.0:
				return p
	return session.angler + Vector2(40.0, 40.0)


## Bütün gölgeler kenara (çekişmedeki dışında); sonraki _shadow_at'e kadar takıma balık gelmez.
func _park_all() -> void:
	_placed = null
	_no_bites = true
	var i := 0
	for s in _session().sim.shadows:
		if s.mode == FishShadow.Mode.HOOKED:
			continue
		s.pos = _reels_park_point(i, _session().angler)
		s.mode = FishShadow.Mode.PAUSE
		s.timer = 1_000_000
		i += 1


## Bot kendi _process'inde: kamera yönetmeni ve reels günlüğü (yalnızca reels'te açık).
func _process(delta: float) -> void:
	_shot_t += delta
	_state_t += delta
	_reels_watch()
	if _cam_shot.is_valid():
		_direct(delta)


## Kamera _cam_shot'ın istediği çerçeveye gider: zoom ve eğim yumuşakça; kararma sürerken hemen (main'in
## _snap_camera'sı zoom'u 1'e çeker; yeni yer hazır çerçevelenmiş açılsın).
func _direct(delta: float) -> void:
	var camera: FollowCamera = main.get("camera")
	var want: Dictionary = _cam_shot.call()
	var point: Vector3 = want["point"]
	camera.target = point
	if (main.get("fade") as Fade).busy():
		camera.zoom = float(want["zoom"])
		camera.pitch = float(want["pitch"])
		camera.snap(point)
		return
	var k := minf(1.0, delta * _shot_rate)
	camera.zoom = lerpf(camera.zoom, float(want["zoom"]), k)
	camera.pitch = lerpf(camera.pitch, float(want["pitch"]), k)


## Yönetmenin çekimi (geçersiz Callable: kamera oyuna döner; main yumuşakça devralır).
func _set_shot(shot: Callable) -> void:
	_cam_shot = shot
	_shot_t = 0.0
	main.set("bot_camera", shot.is_valid())


## Kamera istenen çerçeveye hemen geçer (kesme: CUT).
func _snap_shot() -> void:
	if not _cam_shot.is_valid():
		return
	var camera: FollowCamera = main.get("camera")
	var want: Dictionary = _cam_shot.call()
	camera.zoom = float(want["zoom"])
	camera.pitch = float(want["pitch"])
	camera.snap(want["point"])
	_reels_log("CUT", "camera")


## Oyunun kendi çerçevesi (main._present'teki gibi: olta sudayken eğim, dipte ve sinekte uzak çerçeve,
## çekişmede ve balık elde yakınlaşma), zoom scale katı (dikey kırpma için biraz yakın).
func _game_frame(scale: float) -> Dictionary:
	var session := _session()
	var far: Vector2 = main.call("_far_frame")
	var pitch := FollowCamera.PITCH
	if far.x >= 0.0:
		pitch = float(main.call("_far_pitch"))
	elif session.line_out() or session.state == FishingSession.State.LOST:
		pitch = float(main.get("LINE_PITCH"))
	var zoom := 1.0
	if far.x >= 0.0:
		zoom = far.y
	elif session.state == FishingSession.State.FIGHTING and session.reel != null:
		zoom = float(main.get("FIGHT_ZOOM"))
	elif (main.get("catch_fx") as CatchFx).is_showing():
		zoom = float(main.get("SHOW_ZOOM"))
	return _frame(main.call("_focus"), zoom * scale, pitch)


func _frame(point: Vector3, zoom: float, pitch: float) -> Dictionary:
	return { "point": point, "zoom": zoom, "pitch": pitch }


## a'dan b'ye seconds sn'de yumuşak geçiş (t: geçen süre): yavaşça yaklaşan ya da uzaklaşan kamera.
static func _ease(a: float, b: float, seconds: float, t: float) -> float:
	return lerpf(a, b, smoothstep(0.0, seconds, t))


## Reels günlüğü: olayların karesi (MARK <çekim>.<olay>): oturumun durumu (waiting, nibbling, biting,
## fighting, caught...), balık elde (show), kart (card, card_off), çırpınma (burst), kırmızı (red),
## sıçrayış (jump), dipte koklama (sniff) ve koşu (bell_run), Dede'nin efsanevi gölge haberi (legend);
## kararma (CUT fade, fade_end) ve bildirimler (TOAST). Kırpma denetimi (AIM): ısırmada takım, dipte
## sehpa, elde balık, efsanevi gölge.
func _reels_watch() -> void:
	var session := _session()
	if session == null:
		return
	# Takıma yalnızca botun koyduğu balık gelir (son kartın geniş çekiminde hiçbiri): öteki gölge fark
	# ederse ilgisini kaybeder ve kenara çekilir.
	var sim := session.sim
	var intruder := sim.approacher
	if intruder != null and (_no_bites or (_placed != null and intruder != _placed and _placed in sim.shadows)):
		sim.lose_interest(intruder)
		intruder.pos = _reels_park_point(0, _placed.pos if _placed != null else session.angler)
		intruder.timer = 1_000_000
	var stand: RodStand = main.get("stand")
	var state := int(session.state)
	if state != int(_watch.get("state", -1)):
		_watch["state"] = state
		_state_t = 0.0
		_mark(str(FishingSession.State.find_key(state)).to_lower())
		if session.state in [FishingSession.State.BITING, FishingSession.State.FOLLOWING]:
			if session.technique.id == "bottom":
				_aim(_mark_tag + ".stand", stand.global_position + Vector3(0.0, 0.45, 0.0))
			else:
				_aim(_mark_tag + ".rig", Vector3(session.bobber.x, 0.0, session.bobber.y))
	var reel := session.reel
	var fighting := session.state == FishingSession.State.FIGHTING and reel != null
	if _edge("show", (main.get("catch_fx") as CatchFx).is_showing()):
		_aim(_mark_tag + ".show", main.call("_show_point"))
	_edge("card", (main.get("card") as FishCard).visible, "card_off")
	_edge("burst", fighting and reel.thrashing())
	_edge("red", fighting and reel.in_red)
	_edge("jump", (main.get("fish_jump") as FishJump).is_jumping())
	_edge("sniff", stand.visible and float(stand.get("_twitch")) > 0.0)
	_edge("bell_run", stand.visible and bool(stand.get("_running")))
	var legends := (main.get("_announced") as Dictionary).size()
	if legends > int(_watch.get("legends", 0)):
		_mark("legend")
		var point := (main.get("shadows") as ShadowLayer).shadow_point(int(main.get("_legend_id")))
		if point.is_finite():
			_aim(_mark_tag + ".legend", point)
	_watch["legends"] = legends
	var fading := (main.get("fade") as Fade).busy()
	if fading != bool(_watch.get("fade", false)):
		_reels_log("CUT", "fade" if fading else "fade_end")
	_watch["fade"] = fading
	var hud := _hud()
	var age := float(hud.get("_toast_age"))
	var last := float(_watch.get("toast_age", -1.0))
	if age >= 0.0 and (last < 0.0 or age < last):
		var text := (hud.get("_toast") as Label).text
		_toasts.append(text)
		_reels_log("TOAST", text)
	_watch["toast_age"] = age


## Bir olayın başlangıcı (ve istenirse bitişi) işaretlenir. Başladıysa true.
func _edge(event: String, on: bool, off_event: String = "") -> bool:
	var was := bool(_watch.get(event, false))
	_watch[event] = on
	if on and not was:
		_mark(event)
		return true
	if was and not on and not off_event.is_empty():
		_mark(off_event)
	return false


func _take(take: String) -> void:
	_mark_tag = take
	_reels_log("TAKE", take)


## Olay işareti; --shots verildiyse o anın görüntüsü de (kuru çekimde denetim; bir önceki kare).
func _mark(event: String) -> void:
	var key := "%s.%s" % [_mark_tag, event]
	_marks[key] = int(_marks.get(key, 0)) + 1
	_reels_log("MARK", key)
	if not _shots_dir.is_empty():
		var image := get_viewport().get_texture().get_image()
		if image != null:
			image.save_jpg(_shots_dir.path_join("%05d_%s.jpg" % [Engine.get_frames_drawn(), key]), 0.85)


func _reels_log(kind: String, text: String) -> void:
	print("REELS %s %d %s" % [kind, Engine.get_frames_drawn(), text])


## Bir kontrolün ekrandaki yeri (kurguda panel kırpması).
func _panel_log(panel: String, control: Control) -> void:
	var r := control.get_global_rect()
	_reels_log("PANEL", "%s %.0f %.0f %.0f %.0f" % [panel, r.position.x, r.position.y, r.size.x, r.size.y])


## Dikey kurgu ekranın ortasındaki kareyi (yükseklik kadar genişlik) kırpar: nokta onun içinde mi?
func _aim(label: String, world: Vector3, margin: float = 70.0) -> void:
	var p := _screen(world)
	var view := get_viewport().get_visible_rect().size
	var dx := p.x - view.x * 0.5
	_reels_log("AIM", "%s %.0f %.0f" % [label, p.x, p.y])
	_check("reels: %s kırpmada (dx %.0f, y %.0f)" % [label, dx, p.y], absf(dx) <= view.y * 0.5 - margin
			and p.y >= margin and p.y <= view.y - margin)


## Harita düğmesine dokunur, bölgenin rozetine dokunur ve kararmanın bitmesini bekler (videoda
## haritanın kendisi görünsün diye _travel_to yerine).
func _map_to(panel: MapPanel, fade: Fade, zone: String) -> void:
	await _tap_control(_hud().map_button)
	await _wait_until(func() -> bool: return panel.visible, 2.0)
	await _wait(1.2)
	await _tap_control(panel.view.badge(zone))
	await _wait_until(func() -> bool: return fade.busy(), 1.0)
	await _wait_until(func() -> bool: return not fade.busy(), 4.0)


## Açılan balık kartını düğmesiyle kapatır (kart açılana kadar bekler; en kısa açık kalma süresi).
func _close_card(card: FishCard) -> void:
	await _wait_until(func() -> bool: return card.visible, 3.0)
	await _wait(FishCard.MIN_OPEN + 0.2)
	if card.visible and card.ok_button != null:
		await _tap(card.ok_button.get_global_rect().get_center())


## Çekişmeyi bir oyuncu gibi oynar: eylem düğmesine (finger verilirse oraya: olta sudayken ekranın
## her yeri eylem) basar (VUR), sakinken basılı tutar, balık çırpınınca (uyarı) reaction kare sonra
## bırakır, sakinleşince yeniden basar. Sonuç gelene kadar. Balık sudan sıçrarsa (alabalıklar)
## _seen_jump olur, ilk sıçrayış görüntülenir.
func _reel_like_player(reaction: int, timeout: float, at: Vector2 = Vector2.INF) -> void:
	var finger := at if at.is_finite() else _hud().action_button.get_global_rect().get_center()
	_touch(1, finger, true)
	await _wait_frames(2)
	var hold := true
	var lag := 0
	var elapsed := 0.0
	var jump: FishJump = main.get("fish_jump")
	while _state() == FishingSession.State.FIGHTING and elapsed < timeout:
		var reel := _session().reel
		var want := reel != null and not reel.thrashing()
		lag = lag + 1 if want != hold else 0
		if lag >= reaction:
			hold = want
			lag = 0
			_touch(1, finger, hold)
		if jump.is_jumping() and not _seen_jump:
			_seen_jump = true
			await _shot_once("26b_sicrayis")
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
		s.pos = _park_fn.call(i, p) if _park_fn.is_valid() else parks[i % parks.size()]
		s.mode = FishShadow.Mode.PAUSE
		s.timer = 1_000_000
		i += 1
	if chosen == null:
		return null
	chosen.pos = p
	chosen.heading = heading.normalized()
	chosen.mode = FishShadow.Mode.PAUSE
	chosen.timer = 1_000_000
	_placed = chosen
	_no_bites = false
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
		if not _hide_fingers:
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
	# Geliştirme sürümünün FPS yazısı ekran görüntüsüne girmez (ölçüm açıkken girer: gezi).
	var hud := _hud()
	var fps: Label = hud.get("_fps")
	var hide := fps != null and fps.visible and not hud.perf
	if hide:
		fps.visible = false
	await RenderingServer.frame_post_draw
	if hide:
		fps.visible = true
	if _shots_dir.is_empty():
		return
	var path := _shots_dir.path_join(shot_name + ".png")
	get_viewport().get_texture().get_image().save_png(path)
	print("ekran görüntüsü: ", path)
