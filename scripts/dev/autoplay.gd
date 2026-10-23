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
##     Dede'nin yanından ve dükkânın önünden geç, yürüme halkası (sürükle → yürür, az itince yavaş,
##     bırakınca durur, dokunmak yürütmez, dışı oyuna geçer, defter açıkken çalışmaz, olta sudayken yok),
##     at, geri sar, gölgeyi korkut, gölgeyi çek, erken
##     dokunuş, ekranın her yeri VUR, basılı tut tut, kart açıkken atış yok, patlamada bırakmazsa
##     kopar, 8 sn'de yeni balık, düğme boyu ve güvenli alan).
##   first: ilk açılış; senaryolu ilk balık (ekran görüntüleri; 45 sn denetimi).
##   hero: balıkçı, Dede ve Nine yakın çekim (kamerayı bot sürer): Dede konuşur, ikisi, dükkân,
##     Nine selam verir, atış, bekleme, çekme, balığı gösterme, Dede sevinir.
##   fish: bütün türler elde ve kartlarıyla, sonra ayarlar paneli (görsel denetim; kurallar işlemez);
##     --fish=<kimlik> yalnızca o tür.
##   shop: Nine'nin dükkânı (KONTROL satırları): dokununca açılır, para yetmezse ve rütbe tutmazsa
##     satın alınmaz, satın al ve kuşan, yem al, kova dolunca Dede uyarır, doluyken atılmaz (eylem
##     düğmesi SAT): iskelede dükkân hemen açılır, sazlıktan ekran kararıp tezgâha gelinir; hepsini
##     sat, son yem bitince solucana döner; sekme görüntüleri.
##   rarity: nadirlik ipuçları (görsel denetim): her nadirlikten bir gölge yan yana (pırıltı, ışıltı,
##     kabarcık), sonra her nadirliğin rozeti; gri tonlamalı kopyayla renk körü denetimi yapılır.
##   map: harita ve hızlı geçiş (KONTROL satırları): ilk balıktan önce harita düğmesi yok; rütbe
##     atlayınca yeni bölge açılır (bildirim, Dede, nabız); haritaya dokun → açılır; ayarların
##     geliştirme düğmeleri (+1.000, +10.000 para, RÜTBE +1 iki kez: panel açıkken bildirim yok,
##     kapanınca rütbe ve kayalık burun); her açık bölgenin rozetine dokun → ekran kararır, balıkçı
##     oraya geçer, gölgeler gelir; kilitli bölgeye geçilmez; en yüksek rütbede RÜTBE +1 pasif.
##   boat: sandal (KONTROL satırları): sandal yokken Dede Nine'yi söyler; Nine'den sandalı al; iskeledeki
##     sandala dokun → ekran kararır, derin ortada sandaldasın; yürünmez, dokunuş atıştır; yayını tut;
##     haritadan sıradaki şamandıra; "Kıyıya dön" → iskele; sandalda kova dolunca SAT → kıyı, dükkân.
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
##   rods: kamışlar ve makaralar (görsel denetim; KONTROL satırları): dükkândaki kamışlar teknik teknik
##     adlarıyla yan yana, makaralar yakından (çıkrık ve sinek makarası); elde kuşanılan kamış ve
##     makara, dipte sehpadaki kuşanılan dip kamışı (zil ucunda).
##   guide: "Nasıl oynanır?" rehberi (KONTROL satırları; telefon oranında ve --safe-inset=130 ile; TR ve EN):
##     rütbe 3'ün oyuncusu. Ayarlar "Nasıl oynanır?" düğmesiyle küçülmeden sığar; düğme → rehber ilk
##     sayfada, ayarların üstünde. İLERİ ile baştan sona her sayfa: küçülmeden sığar, düğmeler büyük ve
##     güvenli alanda, panelin boyu aynı, karolar düzenin boyunda, metin, başlık ve alttaki satır karoya
##     sığar; ekran görüntüsü. Son sayfada İLERİ pasif; sekmeye dokununca o sayfa; kilitli teknik ve
##     bölgede rütbe hapı; rehber kapanınca ayarlar açık. Takım Çantası'nda "?" → Teknikler sayfası,
##     rehber kapanınca çanta açık. Dükkân: çantadan uzaktan açılan dükkânın Kamış sekmesinde ve
##     tezgâhtaki dükkânın Kamış, Ekstra, Takım ve Kova sekmelerinde "?" o sekmenin sayfası; rehber
##     kapanınca dükkân açık, Nine veda etmez (dükkân kapanınca uğurlar; uzaktan açılmışsa susar).
##     Dede'ye dokundukça öğütler; sonuncusu rehberi söyler.
##   world: canlı dünya (KONTROL satırları; telefon oranında ve --safe-inset=130 ile): saat akar (öteki
##     senaryolarda donuk: eski görüntüler sabah ışığında). Saat çipi üst ortada, haplara ve sağ üstteki
##     düğmelere binmez, sabahı gösterir; saat oyun akarken ilerler, ayarlar açıkken durur; geliştirme
##     düğmeleri: VAKİT + (öğle, sonra akşam ve gece: bildirim panel kapanınca, yalnızca sonuncusu), HAVA
##     (bugünün havası, çipte ikonu); Ay Turnası gündüz yok, gece nilüferli koyda defterde oranıyla; iskelede
##     gece ve havanın ikonuyla en çok TOUR_DRAWS çizim.
##   release: tut-bırak ve göl sevgisi (KONTROL satırları; telefon oranında ve --safe-inset=130 ile; TR ve EN):
##     dolu kovaya dokun → Kova paneli küçülmeden sığar; BIRAK (en küçüğü, sevgi, para aynı), HEPSİNİ BIRAK
##     (önce "Emin misin?"), seviye bildirimi ve Dede; yeni tür kartında "Göle bırak"; olta sudayken kovaya
##     dokunmak oyuna geçer; dipte çöp (bildirim, sevgi, Dede); paneldeki SAT Nine'nin Kova sekmesine götürür.
##   keeper: Gölün Bekçisi ve final (KONTROL satırları; telefon oranında ve --safe-inset=130 ile; TR ve EN): final
##     hazır kayıt (6 mektup, 4 parça, altın hamur; rütbe 13, dip kamışı ve sandal). Dede "bu gece sis basacak";
##     Bugün panelinde gecenin sisi; X'te gündüz Dede "gece gelir"; gece sisli, fırtına yok; X'te şamandırayla Dede
##     "dip kamışı"; dipte at → Bekçi belirir (bildirim, Dede, müziği), takıma o gelir, koklarken dokunmak onu
##     kaçırmaz, koşuda VUR. İlk çekişmede dalışta basılı tutulur: misina kopar, Dede "geri gelecek", 25 sn sonra
##     yine gelir ("geri geldi"); ikinci çekişmede dalış uyarısında ipucu BIRAK, iki dalış, tutulur → elde
##     gösterilmez, Masalsı kart ("Göle bırak"); kart kapanınca bitiş filmi (5 çekim; şafakta balıkçı iskelede,
##     saat sabah; göl çiçek açar), jenerik (ATLA). Sonra: final gecesi bitti, defterde Bekçi, Ayarlar'da BİTİŞ
##     (yeniden izlenir, saat değişmez), kendiliğinden sisli gecede X'te Bekçi yine gelir (Dede "yine göründü").
##     Her çekimde ÇİZİM ≤ TOUR_DRAWS.
## Bot dünyayı hazırlar (gölgeleri yerleştirir, türünü seçer); oyun kuralları aynen işler.

const WORLD_SEED := 4242
const HZ := FishingRules.HZ
## Gezide bir bakıştaki çizim sınırı (telefon hedefi; CLAUDE.md "Çizim sayısı").
const TOUR_DRAWS := 150
## Balık gölgesinin suya en düşük parlaklık karşıtlığı (1 − gölge / su; world senaryosu, her vakit ve havada).
const LOOK_CONTRAST := 0.25

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
## Çekişmede balık (şamandıra, gölge) karaya ya da iskeleye çıktı mı (_reel_like_player; çağıran sıfırlar).
var _fight_on_land: bool = false
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
## _shadow_at'in koyduğu gölgenin seed'i (≥ 0 ise; release: dipte çöp zarı tutan gölge). Türü, boyu ve yolu
## doğarken zarlandı: yalnızca çöp değişir.
var _shadow_seed: int = -1
var _no_bites: bool = false
## Botun kayıtlarında açılış filmi görülmüş sayılır (oynasaydı dokunuşları yutardı); first ve story
## senaryoları filmi ister.
var _intro: bool = false
## world senaryosunda yalnızca bu bölüm (--world-part=looks: vakit × hava görünüşleri; boşsa hepsi).
var _world_part: String = ""


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
		elif arg.begins_with("--world-part="):
			_world_part = arg.get_slice("=", 1)
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
		"guide":
			_play_guide.call_deferred()
		"rods":
			_play_rods.call_deferred()
		"story":
			_play_story.call_deferred()
		"film":
			_play_film.call_deferred()
		"world":
			_play_world.call_deferred()
		"release":
			_play_release.call_deferred()
		"requests":
			_play_requests.call_deferred()
		"secret":
			_play_secret.call_deferred()
		"keeper":
			_play_keeper.call_deferred()
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
	await _check_joystick()
	await _tap_world(Vector2(0.0, 4.0))
	await _wait_until(func() -> bool: return not angler.is_walking(), 8.0)
	# 3) Suya dokun: atmalı. Olta sudayken yürüme halkası yok.
	await _tap_world(Vector2(0.0, 0.0))
	_check("suya dokun → atar", _state() == FishingSession.State.CASTING)
	await _wait_state(FishingSession.State.WAITING, 3.0)
	_check("olta sudayken yürüme halkası yok", not _hud().joystick.visible)
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
	# Yeni oyun: önce açılış filmi (ATLA ile geçilir; filmin kendisi story senaryosunda), sonra
	# senaryolu ilk balık.
	_intro = true
	_use_save(0)
	var story: StoryPanel = main.get("story_panel")
	await _wait(1.5)
	_check("ilk açılışta film oynar, arayüz gizli", story.visible and not _hud().visible)
	await _shot("00_film")
	await _tap(story.skip_button.get_global_rect().get_center())
	await _wait_frames(2)
	_check("ATLA filmi bitirir: arayüz geri, film görüldü", not story.visible and _hud().visible
			and main.get("_film") == null and GameState.save.flags.has(Story.SEEN_FLAG))
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


## Açılış filmi (docs/gdd.md §10.5): yeni oyunda oynar (arayüz gizli, oltası elinde değil, ATLA
## güvenli alanda), ilk söz Nine'nin, dokununca sonraki söz (olta atılmaz), söz kendiliğinden de
## ilerler, her söz en çok iki satır, Bekçi'nin dev gölgesi derin ortada ekranda geçer, hediyede olta
## elde, sonunda arayüz ve ilk ipucu geri; kayıt değişince film temiz durur. Her çekimin çizim sayısı
## (≤150). Sonra Ayarlar'da HİKÂYE (sazlıktan: film iskelede baştan, ATLA, balık sayısı aynı; olta
## sudayken pasif) ve rütbe bölümleri (rütbe 3'te Dede'ye dokun: ilk bölüm; yine dokun: öğüt). Telefon
## oranında ve --safe-inset=130 ile, TR ve EN.
func _play_story() -> void:
	_intro = true
	_use_save(0)
	var story: StoryPanel = main.get("story_panel")
	var hud := _hud()
	var view := get_viewport().get_visible_rect().size
	var center := view * Vector2(0.5, 0.42)
	await _wait(0.6)
	_check("yeni oyunda film oynar, arayüz gizli", story.visible and not hud.visible and main.get("_film") != null)
	_check("oltası henüz elinde değil", not _angler().rod.visible)
	_check_panel_buttons(story, "ATLA düğmesi")
	var worst := { "draws": 0, "shot": "" }
	await _story_draws(worst, "opening")
	await _shot("01_logo")
	await _wait_until(func() -> bool: return story.index() == 0, StoryPanel.LOGO_TIME + 1.0)
	await _wait(StoryFilm.MOVE_TIME)
	var face: TextureRect = story.get("_face")
	_check("ilk söz Nine'nin, yüzüyle (%s)" % _story_text(story), story.index() == 0
			and str(Story.LINES[0][1]) == "nine" and face.visible)
	await _story_draws(worst, "nine")
	await _shot("02_nine")
	var lines_ok := true
	var notes := PackedStringArray()
	# Dokununca sonraki söz; olta atılmaz.
	await _tap(center)
	await _wait_frames(2)
	_check("dokununca sonraki söz, olta atılmaz", story.index() == 1 and _state() == FishingSession.State.IDLE
			and GameState.save.casts == 0 and not _angler().is_walking())
	await _wait(StoryFilm.MOVE_TIME)
	await _story_draws(worst, "lake")
	await _shot("03_gol")
	# Söz kendiliğinden de ilerler.
	var auto := await _wait_until(func() -> bool: return story.index() == 2, Story.LINE_MIN + 8.0)
	_check("söz kendiliğinden ilerler", auto)
	for i in range(2, Story.LINES.size()):
		if i > 2:
			await _tap(center)
			await _wait_until(func() -> bool: return story.index() == i, 2.0)
		var kind := str(Story.LINES[i][2])
		var text: Label = story.get("_text")
		if text.get_line_count() > 2:
			lines_ok = false
			notes.append("%s %d satır" % [Story.LINES[i][0], text.get_line_count()])
		await _wait(StoryFilm.MOVE_TIME)
		await _story_draws(worst, kind)
		if kind == "keeper":
			# Dev gölge belirdikten sonra: derin suda ve ekranda.
			await _wait(1.0)
			var film: StoryFilm = main.get("_film")
			var ghost := film.ghost_point() if film != null else Vector3.INF
			var camera: Camera3D = main.get("camera")
			var depth := _session().lake.depth_at(Vector2(ghost.x, ghost.z)) if ghost != Vector3.INF else 0.0
			var shown := ghost != Vector3.INF and not camera.is_position_behind(ghost) \
					and Rect2(Vector2.ZERO, view).grow(-40.0).has_point(camera.unproject_position(ghost))
			_check("Bekçi'nin dev gölgesi derin ortada, ekranda (%.1f m)" % depth, shown and depth >= Story.KEEPER_DEPTH)
		if kind == "gift":
			await _wait(0.5)
			var gift: Control = story.get("_gift")
			_check("hediyede olta elde, rozet ekranda", _angler().rod.visible and gift.visible
					and Rect2(Vector2.ZERO, view).encloses(gift.get_global_rect()))
		await _shot("%02d_%s" % [i + 2, kind])
	_check("her söz en çok iki satır%s" % ("" if lines_ok else ": " + ", ".join(notes)), lines_ok)
	_check("filmde ≤150 çizim (en çok %d, %s)" % [worst["draws"], worst["shot"]], int(worst["draws"]) <= 150)
	# Son söz kendiliğinden biter: arayüz, ilk ipucu, kamera oyunun açısında.
	var done := await _wait_until(func() -> bool: return not story.visible, Story.LINE_MIN + 8.0)
	await _wait(1.2)
	_check("film biter: arayüz geri, film görüldü, ilk ipucu", done and hud.visible and main.get("_film") == null
			and GameState.save.flags.has(Story.SEEN_FLAG) and str(main.get("_hint_shown")) == "UI_HINT_FIRST_SHADOW")
	var camera: FollowCamera = main.get("camera")
	await _wait(1.0)
	_check("kamera oyunun açısına döner (%.2f, %.0f°)" % [camera.zoom, rad_to_deg(camera.pitch)],
			absf(camera.zoom - 1.0) < 0.05 and absf(camera.pitch - FollowCamera.PITCH) < deg_to_rad(2.0))
	_check_buttons()
	await _shot("10_sonra")
	# Kayıt değişince (ayarlarda sıfırlama, bot) film yarıda temiz durur.
	_use_save(0)
	await _wait_until(func() -> bool: return story.index() == 0, StoryPanel.LOGO_TIME + 1.0)
	# Bekçi'ye kadar dokunarak (yeni söz TAP_GUARD dolmadan dokunuşla geçmez).
	for i in 5:
		await _wait(StoryPanel.TAP_GUARD + 0.15)
		await _tap(center)
	await _wait(1.0)
	var mid_ghost := (main.get("_film") as StoryFilm).ghost_point() if main.get("_film") != null else Vector3.INF
	_intro = false
	_use_save(1)
	await _wait_frames(3)
	var shadows: Node = main.get("shadows")
	_check("kayıt değişince film temiz durur: arayüz, olta, dev gölge, kamera", mid_ghost != Vector3.INF
			and not story.visible and hud.visible and main.get("_film") == null and _angler().rod.visible
			and shadows.find_child("Keeper", false, false) == null and absf(camera.zoom - 1.0) < 0.01)
	await _shot("11_durdu")
	await _story_replay(story)
	await _story_chapters()
	for line in _results:
		print("KONTROL ", line)
	_quit()


## Ayarlar'da HİKÂYE: sazlıktan açılır, film iskelenin başında baştan oynar, ATLA'dan sonra iskeledesin
## ve balık sayısı aynı; olta sudayken düğme pasif.
func _story_replay(story: StoryPanel) -> void:
	var hud := _hud()
	var fade: Fade = main.get("fade")
	var settings: SettingsPanel = main.get("settings_panel")
	var start: Vector2 = GameState.db.spot(GameState.db.main_spot)["start"]
	main.call("_travel", "reeds")
	await _wait_until(func() -> bool: return not fade.busy(), 4.0)
	await _wait(0.5)
	var catches := GameState.save.catches
	await _tap_control(hud.settings_button)
	await _wait_until(func() -> bool: return settings.visible, 2.0)
	await _wait(0.4)
	var replay := settings.find_child("Story", true, false) as Button
	_check("ayarlarda HİKÂYE, panel küçülmeden sığar (%.2f)" % settings.fit_scale(), replay != null
			and not replay.disabled and replay.text == UiKit.upper(tr("UI_STORY_REPLAY")) and settings.fit_scale() > 0.999)
	_check_panel_buttons(settings, "ayarların düğmeleri")
	await _shot("12_ayarlar")
	if replay == null:
		return
	await _tap_control(replay)
	var played := await _wait_until(func() -> bool: return story.visible and not fade.busy(), 5.0)
	_check("HİKÂYE: film baştan, balıkçı iskelenin başında (%.1f m)" % _angler().pos2().distance_to(start),
			played and not settings.visible and main.get("_film") != null and _angler().pos2().distance_to(start) < 0.3)
	await _wait(1.0)
	await _shot("13_yeniden")
	await _tap(story.skip_button.get_global_rect().get_center())
	await _wait_frames(3)
	_check("ATLA: iskeledesin, arayüz geri, balık sayısı aynı", not story.visible and hud.visible
			and GameState.save.catches == catches and _angler().pos2().distance_to(start) < 0.3)
	# Olta sudayken HİKÂYE pasif (film iskelede, olta boşken oynar).
	await _wait(0.6)
	await _tap_control(hud.action_button)
	await _wait_until(func() -> bool: return _session().line_out(), 3.0)
	await _tap_control(hud.settings_button)
	await _wait_until(func() -> bool: return settings.visible, 2.0)
	await _wait(0.3)
	replay = settings.find_child("Story", true, false) as Button
	_check("olta sudayken HİKÂYE pasif", _session().line_out() and replay != null and replay.disabled)
	settings.close_panel()
	await _wait(0.3)


## Hikâyenin devamı: rütbe 3'te Dede'ye dokununca ilk bölüm (bir kez), yine dokununca öğüt.
func _story_chapters() -> void:
	_use_save(1)
	GameState.save.xp = GameState.db.rank_xp[2]
	GameState.changed.emit()
	await _wait(1.0)
	await _tap(_screen(_elder().head_point()))
	await _wait_frames(3)
	_check("rütbe 3'te Dede'ye dokun: hikâyenin ilk bölümü", str(main.get("_hint_shown")) == "UI_DEDE_STORY_3"
			and GameState.save.flags.has(Story.TOLD_FLAG % 3))
	await _shot("14_bolum")
	await _wait(0.5)
	await _tap(_screen(_elder().head_point()))
	await _wait_frames(3)
	_check("yine dokun: öğüt, bölüm yinelenmez (%s)" % str(main.get("_hint_shown")),
			str(main.get("_hint_shown")).begins_with("UI_DEDE_TIP_"))


## Açılış filminin videosu (Movie Maker ile): yeni oyunda film kendi hızında baştan sona oynar (dokunuş
## yok), bitince ilk ipucuyla birkaç saniye; sonra çıkılır.
func _play_film() -> void:
	_intro = true
	_use_save(0)
	var story: StoryPanel = main.get("story_panel")
	await _wait_frames(2)
	await _wait_until(func() -> bool: return not story.visible, 120.0)
	await _wait(3.5)
	_quit()


## Filmdeki sözün yazısı (günlük için).
func _story_text(story: StoryPanel) -> String:
	return (story.get("_text") as Label).text


## Filmin bu çekiminin çizim sayısı; en kötüsü worst'te.
func _story_draws(worst: Dictionary, shot: String) -> void:
	var m := await _measure_draws()
	print("ÇİZİM film %s: %d çizim, %d üçgen" % [shot, m["draws"], m["primitives"]])
	if int(m["draws"]) > int(worst["draws"]):
		worst["draws"] = m["draws"]
		worst["shot"] = shot


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
## dolunca Dede uyarır; doluyken atılmaz, SAT Nine'ye götürür; hepsini sat → para; kapatınca Nine
## uğurlar. Her sekmenin ekran görüntüsü.
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
	# 7b) Kova doluyken atılmaz: eylem düğmesi yeşil SAT; suya dokunmak atmaz (balıkçı yürümez), Dede
	# SAT'ı söyler.
	var hud := _hud()
	var before := _angler().pos2()
	_check("kova dolu → eylem düğmesi yeşil SAT", str(hud.get("_action_kind")) == "sell"
			and hud.action_button.color == UiKit.SUCCESS)
	await _tap_world(Vector2(1.0, -1.0))
	await _wait_frames(4)
	_check("kova doluyken suya dokun → atılmaz, Dede SAT'ı söyler", _state() == FishingSession.State.IDLE
			and str(main.get("_hint_shown")) == "UI_DEDE_BUCKET_CAST" and _angler().pos2().distance_to(before) < 0.05
			and not _angler().is_walking())
	await _wait(0.3)
	await _shot("07b_kova_dolu_sat")
	# 8) İskelede SAT: Nine yakında, dükkân hemen Kova sekmesinde açılır (kararmadan).
	var fade: Fade = main.get("fade")
	await _tap_control(hud.action_button)
	await _wait_frames(3)
	_check("iskelede SAT → dükkân hemen Kova sekmesinde (kararmadan)", shop.visible and shop.current_tab() == "sell"
			and not fade.busy())
	shop.close_panel()
	await _wait(0.4)
	# 8b) Sazlıktan SAT: ekran kararır, balıkçı tezgâhın önüne Nine'ye dönük gelir, dükkân Kova sekmesinde.
	await _travel_to("reeds")
	await _tap_control(hud.action_button)
	var dark := await _wait_until(func() -> bool: return fade.busy(), 1.0)
	await _wait_until(func() -> bool: return shop.visible, 6.0)
	await _wait(0.4)
	var at := _angler().pos2()
	var nine_at := Vector2(nine.global_position.x, nine.global_position.z)
	await _shot("07_kova_dolu")
	var value := Economy.bucket_value(db, save)
	coins = save.coins
	_check("sazlıktan SAT → ekran kararır, tezgâhın önünde (%.1f m), Kova sekmesi açık" % at.distance_to(nine_at),
			dark and shop.visible and shop.current_tab() == "sell" and value > 0 and at.distance_to(nine_at) < 3.0
			and _angler().facing.dot((nine_at - at).normalized()) > 0.9 and str(main.get("zone_id")) == "dock_cove")
	await _tap_control(shop.find_child("SellAll", true, false))
	await _wait_frames(3)
	_check("hepsini sat → para", save.bucket.is_empty() and save.coins == coins + value
			and str(shop.get("_line_key")) == "UI_NINE_SOLD")
	await _wait(0.4)
	await _shot("08_satildi")
	await _tap(shop.close_button.get_global_rect().get_center())
	await _wait_frames(3)
	_check("satınca eylem düğmesi yine AT", str(hud.get("_action_kind")) == "cast")
	await _travel_to("dock_cove")
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
	# 19 tür iki sayfada (Dalga 3 ve 4; 19. Gölün Bekçisi); ikinci sayfada teknik ve gece türleri. Kerevitin ipucu tuzağı, alabalığınki
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
	_check("defter ekrana ve güvenli alana sığar (%.2f, %s)" % [book.fit_scale(), book.panel_rect()],
			book.fit_scale() > 0.75 and _panel_inside(book))
	book.close_panel()
	for line in _results:
		print("KONTROL ", line)
	_quit()


## Panelin kutusu (ölçekli) güvenli alanın içinde mi (en çok 1 birim taşma)?
func _panel_inside(panel: Dialog) -> bool:
	var view := get_viewport().get_visible_rect()
	var inset := UiKit.safe_insets(_hud())
	var safe := Rect2(view.position + Vector2(inset.x, inset.y),
			view.size - Vector2(inset.x + inset.z, inset.y + inset.w))
	return safe.grow(1.0).encloses(panel.panel_rect())


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
	await _check_debug_buttons()
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
	# En yüksek rütbede RÜTBE +1 pasif.
	save.xp = db.rank_xp[db.max_rank() - 1]
	save.settings["perf"] = true
	GameState.changed.emit()
	var settings: SettingsPanel = main.get("settings_panel")
	await _tap_control(hud.settings_button)
	await _wait_until(func() -> bool: return settings.visible, 2.0)
	await _wait(0.3)
	var top := settings.find_child("DebugRankUp", true, false) as Button
	_check("en yüksek rütbede RÜTBE +1 pasif", top != null and top.disabled)
	settings.close_panel()
	save.settings["perf"] = false
	GameState.changed.emit()
	await _wait(0.3)
	_check_buttons()
	for line in _results:
		print("KONTROL ", line)
	_quit()


## Ayarların geliştirme düğmeleri (geliştirme sürümü, ölçüm açıkken): +1.000 ve +10.000 para; RÜTBE +1
## iki kez rütbe 3'ten 5'e. Panel açıkken bildirim çıkmaz (karartmanın altında kalmasın); kapanınca
## rütbe ve kayalık burun bildirimi, Dede söyler, harita düğmesi atar.
func _check_debug_buttons() -> void:
	var db := GameState.db
	var save := GameState.save
	var hud := _hud()
	var settings: SettingsPanel = main.get("settings_panel")
	save.settings["perf"] = true
	GameState.changed.emit()
	await _tap_control(hud.settings_button)
	await _wait_until(func() -> bool: return settings.visible, 2.0)
	await _wait(0.4)
	var coins := save.coins
	for amount: int in SettingsPanel.DEBUG_COINS:
		await _tap_control(settings.find_child("DebugCoins%d" % amount, true, false))
		await _wait_frames(2)
	_check("+1.000 ve +10.000: para %d → %d (sol üstte)" % [coins, save.coins], save.coins == coins + 11000
			and (hud.get("_coins") as Label).text == UiKit.format_int(save.coins))
	var rank := Rank.rank(db, save)
	for i in 2:
		await _tap_control(settings.find_child("DebugRankUp", true, false))
		await _wait_frames(2)
	await _wait(1.0)
	var toast_box: Control = hud.get("_toast_box")
	_check("RÜTBE +1 iki kez: rütbe %d → %d; panel açıkken bildirim yok" % [rank, Rank.rank(db, save)],
			Rank.rank(db, save) == rank + 2 and settings.visible and not toast_box.visible)
	await _shot("02b_gelistirici")
	settings.close_panel()
	await _wait_frames(3)
	var said := str(main.get("_hint_shown"))
	var pulsing := float(hud.get("_map_pulse")) > 0.0
	var title := tr("RANK_" + db.rank_title(rank + 1))
	var ranked := await _wait_toast(UiKit.upper(tr("UI_RANK_UP") % [rank + 1, title]), 4.0)
	var opened := await _wait_toast(UiKit.upper(tr("UI_ZONE_OPENED") % tr("ZONE_rocky_point")), 10.0)
	_check("panel kapanınca rütbe ve kayalık burun bildirimi, Dede söyler, harita düğmesi atar (%s, %s, %s, %s)" % [
			ranked, opened, said, pulsing], ranked and opened and said == "UI_DEDE_ZONE_OPEN" and pulsing
			and Zones.unlocked(db, save, db.zone(str(main.get("spot_id")), "rocky_point")))
	save.settings["perf"] = false
	GameState.changed.emit()
	await _wait(0.3)


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
	_check("sandala dokun → ekran kararır, derin ortada sandaldasın (yürüme halkası yok)", dark and bool(main.get("in_boat"))
			and str(main.get("zone_id")) == "deep_water" and at.distance_to(buoys[0]) < 3.5 and hud.shore_button.visible
			and scene.boat_away() and not hud.joystick.visible)
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
	# 8) Sandalda kova dolar: SAT → ekran kararır, kıyıya inilir, tezgâhın önünde dükkân Kova sekmesinde.
	await _tap(_screen(scene.boat_point()))
	await _wait_until(func() -> bool: return bool(main.get("in_boat")) and not fade.busy(), 5.0)
	while not Bucket.is_full(db, save):
		save.bucket.append({ "fish": "bream", "size_cm": 30, "stars": 1 })
	GameState.changed.emit()
	await _wait_frames(3)
	_check("sandalda kova dolu → eylem düğmesi SAT", bool(main.get("in_boat")) and str(hud.get("_action_kind")) == "sell")
	await _tap_control(hud.action_button)
	var sold_dark := await _wait_until(func() -> bool: return fade.busy(), 1.0)
	await _wait_until(func() -> bool: return shop.visible, 6.0)
	await _wait(0.4)
	var nine_at := Vector2(_nine().global_position.x, _nine().global_position.z)
	_check("sandalda SAT → kıyıya inilir, tezgâhta dükkân Kova sekmesinde", sold_dark and not bool(main.get("in_boat"))
			and not scene.boat_away() and shop.visible and shop.current_tab() == "sell"
			and _angler().pos2().distance_to(nine_at) < 3.0)
	await _shot("08_sandaldan_sat")
	shop.close_panel()
	await _wait(0.3)
	for line in _results:
		print("KONTROL ", line)
	_quit()


## Teknikler: rütbe 2'de spin açılır, takım çantası, ilk spin kamışı, dur-kalk saldırısı (iki yolu da),
## sazlıkta takılan yem, şamandıraya dönüş.
func _play_technique() -> void:
	_use_save(5)
	_roomy_bucket()
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
	_check("spin elde: kamış, yem, düğme ve Dede'nin sözü", _angler().rod.style == "spin"
			and _angler().rod.gear_id == "rod_spin_light" and bobber.kind == "lure"
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
			and _angler().rod.gear_id == "rod_carp_1"
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
	# Sazlıkta aynalı sazan (yalnızca dip). Balıkçı kumda: çekişmede balık kuma çekilmez, suyun
	# kenarında durur (Ersin: "kuma kadar gölgelik çıkıyor").
	await _travel_to("reeds")
	_fight_on_land = false
	var mirror := await _bottom_cast(true, "mirror_carp")
	_check("sazlıkta dipte aynalı sazan (botun koyduğu gölge) tutulur", bool(mirror["caught"])
			and str(_session().last_catch.get("fish", "")) == "mirror_carp")
	_check("sazlıkta çekişmede balık kumda değil, suyun kenarında durur (%.1f m)" % _session().fight_near,
			not _fight_on_land and _session().fight_near > 0.5 and _taken.has("26c_son_metreler_reeds"))
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
	_roomy_bucket()
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
	_roomy_bucket()
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
			and _angler().rod.gear_id == "rod_fly_1"
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
## görüntülenir. at: dokunulan yer (ekranın her yeri eylem); verilmezse sol kenar, çekişmede eylem düğmesi.
func _fly_cast(fish_id: String, strike: bool, at: Vector2 = Vector2.INF) -> Dictionary:
	var out := { "drift": 0.0, "drift_hint": false, "line": false, "under": false, "rise": false, "hooked": false,
			"jumped": false, "caught": false, "early": false, "came_back": false }
	var finger := at if at.is_finite() else Vector2(260, 520)
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
		await _reel_like_player(6, 40.0, at)
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
			# Arayüzün altındaki noktaya dokunulmaz: atış kısalmasın, yön biraz döner.
			if _under_hud(p):
				break
			if not lake.is_water(p) or lake.shore_distance(p) < 0.8:
				continue
			var flow := lake.flow_at(p)
			if flowing and flow.length() > 0.6 and lake.is_water(p + flow.normalized() * 2.0) \
					and lake.flow_at(p + flow.normalized() * 2.0).length() > 0.3:
				return p
			if not flowing and flow.length() < 0.02:
				return p
	return Vector2.INF


## Göldeki nokta ekranda arayüzün bir düğmesinin (saat çipi, kova, harita...) altında mı: bot düğmeye değil
## suya dokunsun (oyuncu da düğmenin altındaki suya dokunamaz; Dalga 4'ten beri saat çipi bir düğme).
func _under_hud(p: Vector2) -> bool:
	var screen := _screen(Vector3(p.x, 0.0, p.y))
	for b: TouchButton in _hud().buttons():
		if b.is_visible_in_tree() and b.hit_rect().grow(12.0).has_point(screen):
			return true
	return false


## Haritadan geçer (main._travel) ve kararmanın bitmesini bekler.
func _travel_to(zone: String) -> void:
	var fade: Fade = main.get("fade")
	main.call("_travel", zone)
	await _wait_frames(2)
	await _wait_until(func() -> bool: return not fade.busy(), 4.0)
	await _wait(0.4)


## Dipte bir atış: balıkçının baktığı yöne atar (takım menzilin sonuna düşer); bir balığı (fish_id)
## takımla balıkçının arasına koyar; koklamada dokunmaz (strike false ise ilk koklamada dokunur:
## erken), koşuda (tap_delay kare sonra) VUR'a dokunur ve bir oyuncu gibi çekişir. at: dokunulan yer;
## verilmezse sol kenar, çekişmede eylem düğmesi.
func _bottom_cast(strike: bool, fish_id: String = "carp", at: Vector2 = Vector2.INF, tap_delay: int = 6) -> Dictionary:
	var out := { "reach": 0.0, "on_stand": false, "line_from_stand": false, "sniffed": false, "ran": false,
			"picked_up": false, "caught": false, "early": false, "draws": 0 }
	var finger := at if at.is_finite() else Vector2(260, 520)
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
		await _reel_like_player(6, 40.0, at)
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
## (atışın yönü); at: dokunulan yer (verilmezse sol kenar, çekişmede eylem düğmesi).
func _spin_cast(p: Vector2, cast_to: Vector2, fish_id: String = "perch", heading: Vector2 = Vector2(0, -1),
		at: Vector2 = Vector2.INF) -> Dictionary:
	var out := { "moved": 0.0, "hidden": false, "followed": false, "reel_hint": false, "follow_hint": false,
			"strike": "", "caught": false, "draws": 0 }
	var finger := at if at.is_finite() else Vector2(260, 520)
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
		await _reel_like_player(6, 25.0, at)
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
	_check("ölçüm açıkken \"Hepsini aç\" → rütbe %d ve sandal, bütün bölgeler açık" % Rank.rank(db, save),
			found and all_open and Economy.owns(db, save, Zones.BOAT) and int(main.get("_access_rank")) == Rank.rank(db, save))
	_check("ölçüm açıkken ayarlar (geliştirme satırlarıyla) ekrana ve güvenli alana sığar (%.2f, %s)" % [
			settings.fit_scale(), settings.panel_rect()], _panel_inside(settings))
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


## Canlı dünya (Dalga 4): rütbe 3'ün oyuncusu, saat akar. Saat çipi, saatin akışı ve durması, geliştirme
## düğmeleriyle vakit ve hava, Ay Turnası'nın gece oranı, iskelede çizim sayısı.
func _play_world() -> void:
	if _world_part == "looks":
		_use_save(3)
		await _wait(1.0)
		await _world_looks()
		_finish_checks()
		return
	_use_save(3)
	var db := GameState.db
	var rules := db.rules
	var save := GameState.save
	var spot := str(main.get("spot_id"))
	var clock: WorldClock = main.get("world_clock")
	clock.frozen = false
	save.xp = db.rank_xp[2]
	Records.add(save.records, "rudd", 999, 3, 0)
	_session().set_access(Zones.open_ids(db, save, spot))
	main.call("_update_gates")
	GameState.changed.emit()
	await _wait(1.0)
	var hud := _hud()
	var chip := hud.world_chip()
	_check("saat çipi sabahı gösterir (%s, %s)" % [hud.world_text(), ",".join(hud.world_icons())],
			chip.is_visible_in_tree() and hud.world_text().begins_with("06:")
			and hud.world_icons() == PackedStringArray(["phase_morning"]))
	_check("sabah müziği ve göl sesi çalar (%s, %s)" % [Sounds.music_name(), Sounds.ambience_name()],
			Sounds.music_name() == "morning" and Sounds.ambience_name() == "lake")
	var right := hud.settings_button.get_global_rect().merge(hud.book_button.get_global_rect())
	if hud.map_button.visible:
		right = right.merge(hud.map_button.get_global_rect())
	var pills := (hud.get("_status") as Control).get_global_rect()
	# Dokunma kutusu (ekranın üst kenarından hapın altına, en az 122) haplara ve düğmelere binmez.
	var box := hud.world_button.hit_rect()
	_check("saat çipi haplara ve sağ üstteki düğmelere binmez (çipin dokunma kutusu %s, haplar %s, düğmeler %s)" % [
			box, pills, right], not box.intersects(pills) and not box.intersects(right) and box.encloses(chip.get_global_rect()))
	await _shot("01_sabah")
	var day_odds := BookPanel.odds(db, save, spot, "lily_cove")
	var start := save.clock_s
	await _wait(3.0)
	var moved := save.clock_s - start
	_check("saat oyun akarken ilerler (3 sn → %d oyun dakikası; çipte %s)" % [moved, hud.world_text()],
			moved >= 2 and moved <= 4 and hud.world_text() == DayClock.clock_text(rules, save.clock_s))
	# Ayarlar açıkken saat durur; geliştirme düğmeleri (ölçüm açıkken) vakti ve havayı değiştirir.
	var settings: SettingsPanel = main.get("settings_panel")
	var toast_box: Control = hud.get("_toast_box")
	save.settings["perf"] = true
	GameState.changed.emit()
	await _tap_control(hud.settings_button)
	await _wait_until(func() -> bool: return settings.visible, 2.0)
	var held := save.clock_s
	await _wait(2.0)
	_check("ayarlar açıkken saat durur (%d → %d)" % [held, save.clock_s], save.clock_s == held)
	await _tap_control(settings.find_child("DebugTime", true, false))
	await _wait_frames(3)
	_check("VAKİT + → öğle, çipte %s; panel açıkken bildirim yok; öğle müziği (%s)" % [hud.world_text(), Sounds.music_name()],
			DayClock.phase(rules, save.clock_s) == "noon" and hud.world_text() == "12:00"
			and hud.world_icons()[0] == "phase_noon" and not toast_box.visible and Sounds.music_name() == "noon")
	await _shot("02_gelistirici")
	settings.close_panel()
	var noon := await _wait_toast(UiKit.upper(tr("UI_PHASE_NOW_noon")), 4.0)
	_check("panel kapanınca \"%s\" bildirimi" % tr("UI_PHASE_NOW_noon"), noon)
	await _shot("03_ogle")
	await _wait_until(func() -> bool: return not toast_box.visible, 4.0)
	await _tap_control(hud.settings_button)
	await _wait_until(func() -> bool: return settings.visible, 2.0)
	for i in 2:
		await _tap_control(settings.find_child("DebugTime", true, false))
		await _wait_frames(3)
	settings.close_panel()
	# Panel kapanınca çıkan bildirimler izlenir: akşamınki gecenin yerine geçti (yalnızca sonuncusu), ilk
	# gece Nine fener verir (bildirim ve Dede'nin sözü).
	var toast: Label = hud.get("_toast")
	var seen := {}
	var lines := {}
	var watch := func() -> bool:
		if toast.is_visible_in_tree():
			seen[toast.text] = true
		lines[str(main.get("_line"))] = true
		return false
	await _wait_until(watch, 6.0)
	var night := seen.has(UiKit.upper(tr("UI_PHASE_NOW_night")))
	var only_last := night and not seen.has(UiKit.upper(tr("UI_PHASE_NOW_evening")))
	_check("VAKİT + iki kez → gece (çipte %s); yalnızca \"%s\" bildirimi" % [hud.world_text(), tr("UI_PHASE_NOW_night")],
			night and only_last and DayClock.phase(rules, save.clock_s) == "night"
			and hud.world_icons()[0] == "phase_night" and hud.world_text().begins_with("00:"))
	_check("ilk gece Nine fener verir (bildirim, Dede'nin sözü, kayıtta)", seen.has(UiKit.upper(tr("UI_LANTERN_GIFT")))
			and lines.has("UI_DEDE_LANTERN") and bool(save.flags.get(main.get("LANTERN_FLAG"), false)))
	_check("gece müziği ve gece sesi (cırcır böceği) çalar (%s, %s)" % [Sounds.music_name(), Sounds.ambience_name()],
			Sounds.music_name() == "night" and Sounds.ambience_name() == "night")
	# Gece nilüferli koy: Ay Turnası gelir (gündüz gelmez); defterde oranı ve "yalnızca gece".
	var fade: Fade = main.get("fade")
	main.call("_travel", "lily_cove")
	await _wait_until(func() -> bool: return fade.busy(), 1.0)
	await _wait_until(func() -> bool: return not fade.busy() and str(main.get("zone_id")) == "lily_cove", 5.0)
	await _wait(1.0)
	var night_odds := BookPanel.odds(db, save, spot, "lily_cove")
	_check("Ay Turnası nilüferli koyda gündüz gelmez, gece gelir (%s → %s)" % [
			UiKit.format_percent(int(day_odds.get("moon_pike", 0))), UiKit.format_percent(int(night_odds.get("moon_pike", 0)))],
			int(day_odds.get("moon_pike", 0)) == 0 and int(night_odds.get("moon_pike", 0)) > 0)
	var book: BookPanel = main.get("book_panel")
	await _tap_control(hud.book_button)
	await _wait_until(func() -> bool: return book.visible, 2.0)
	book.open_book("moon_pike")
	await _wait(0.5)
	var text := _texts_in(book)
	_check("gece defterde Ay Turnası: oranı, \"yalnızca gece\" ve şimdiki koşul",
			text.contains(tr("UI_BOOK_CHANCE") % UiKit.format_percent(int(night_odds.get("moon_pike", 0))))
			and text.contains(tr("UI_BOOK_HINT_ONLY_night"))
			and text.contains(tr("UI_BOOK_NOW") % [tr("PHASE_night"), tr("WEATHER_clear")]))
	_check("defter ekrana ve güvenli alana sığar (%.2f, %s)" % [book.fit_scale(), book.panel_rect()],
			book.fit_scale() > 0.75 and _panel_inside(book))
	await _shot("04_defter_ay_turnasi")
	book.close_panel()
	await _wait(0.3)
	# HAVA: bugünün havası sıradakine; çipte havanın ikonu.
	await _tap_control(hud.settings_button)
	await _wait_until(func() -> bool: return settings.visible, 2.0)
	var before := Weather.at(rules, save)
	await _tap_control(settings.find_child("DebugWeather", true, false))
	await _wait_frames(3)
	var weather := Weather.at(rules, save)
	settings.close_panel()
	await _wait(0.5)
	var want := "weather_storm" if Weather.stormy(weather, "night") else "weather_" + weather
	var icons := hud.world_icons()
	_check("HAVA → bugünün havası %s → %s, çipte %s" % [before, weather, ",".join(icons)], weather != before
			and (icons.size() == 1 if weather == "clear" else icons.size() == 2 and icons[1] == want))
	# İskele (en çok çizim): gece, havanın ikonu, ölçüm açık.
	main.call("_travel", "dock_cove")
	await _wait_until(func() -> bool: return fade.busy(), 1.0)
	await _wait_until(func() -> bool: return not fade.busy() and str(main.get("zone_id")) == "dock_cove", 5.0)
	await _wait(1.5)
	var info := await _measure_draws()
	print("ÇİZİM %-13s %3d çizim, %6d üçgen (gece, %s)" % ["dock_cove", info["draws"], info["primitives"], weather])
	_check("iskelede saat çipi ve havanın ikonuyla en çok %d çizim (%d)" % [TOUR_DRAWS, info["draws"]],
			int(info["draws"]) <= TOUR_DRAWS and int(info["draws"]) > 0)
	await _shot("05_iskele_gece")
	await _world_tea()
	save.settings["perf"] = false
	GameState.changed.emit()
	await _wait(0.3)
	_check_buttons()
	await _world_looks()
	await _world_storm()
	_finish_checks()


## Fırtına (yağmurlu gece; saat donuk, oyun zamanı hızlı: Engine.time_scale): şimşekler en az
## STORM_GAP.x arayla (yanıp sönme yok), her şimşeği uzak gök gürültüsü izler, ortam sesi yağmur.
func _world_storm() -> void:
	var rules := GameState.db.rules
	var save := GameState.save
	var clock: WorldClock = main.get("world_clock")
	var scene: LakeScene = main.get("scene")
	clock.frozen = true
	var day := 9
	save.clock_s = day * DayClock.day_s(rules) + 3 * rules.phase_s + (rules.phase_s >> 1)
	save.flags[Weather.DEBUG_DAY] = day
	save.flags[Weather.DEBUG_KIND] = "rain"
	clock.refresh(save)
	scene.set_look(DayLook.at(rules, save), true)
	var flashes: Array[float] = main.get("storm_log")
	flashes.clear()
	main.set("thunder_count", 0)
	Engine.time_scale = 8.0
	var waited := 0
	while flashes.size() < 3 and waited < 1500:
		await get_tree().process_frame
		waited += 1
	# Son şimşeğin gök gürültüsü (en çok THUNDER_DELAY.y sonra).
	await _wait_frames(30)
	Engine.time_scale = 1.0
	var gaps := PackedStringArray()
	var shortest := 999.0
	for i in range(1, flashes.size()):
		gaps.append("%.1f" % (flashes[i] - flashes[i - 1]))
		shortest = minf(shortest, flashes[i] - flashes[i - 1])
	var gap_min := float((main.get("STORM_GAP") as Vector2).x)
	var thunders := int(main.get("thunder_count"))
	_check("fırtınada şimşekler en az %.0f sn arayla (%s sn), her birini gök gürültüsü izler (%d/%d), ortam sesi %s" % [
			gap_min, ", ".join(gaps), thunders, flashes.size(), Sounds.ambience_name()],
			flashes.size() >= 3 and shortest >= gap_min - 0.01 and thunders == flashes.size()
			and Sounds.ambience_name() == "rain")
	await _shot("40_firtina")


## "Bugün" paneli (gece, iskelede): çipe dokun → panel (vakit, saat, yarının havası; küçülmeden sığar,
## açıkken saat durur), ÇAY İÇ → kararma, sonraki vakit (gece → yeni günün sabahı), bildirim, Dede'nin
## sözü, Dede yakındaysa kamera ona yaklaşır; balık tutmadan ikinci çay pasif ("Önce bir balık tut").
func _world_tea() -> void:
	var db := GameState.db
	var rules := db.rules
	var save := GameState.save
	var hud := _hud()
	var fade: Fade = main.get("fade")
	var day_panel: DayPanel = main.get("day_panel")
	var toast: Label = hud.get("_toast")
	var tomorrow := Weather.forecast(rules, save, 2)[1]
	var today := DayClock.day(rules, save.clock_s)
	await _tap_control(hud.world_button)
	await _wait_until(func() -> bool: return day_panel.visible, 2.0)
	await _wait(0.5)
	var text := _texts_in(day_panel)
	_check("çipe dokun → Bugün paneli: gece, saat, yarının havası (%s)" % tr("WEATHER_" + tomorrow),
			day_panel.visible and text.contains(UiKit.upper(tr("PHASE_night")))
			and text.contains(DayClock.clock_text(rules, save.clock_s)) and text.contains(tr("WEATHER_" + tomorrow)))
	_check("Bugün paneli telefonda küçülmeden sığar (%.2f, %s)" % [day_panel.fit_scale(), day_panel.panel_rect()],
			day_panel.fit_scale() >= 0.999 and _panel_inside(day_panel))
	var held := save.clock_s
	await _wait(1.0)
	_check("Bugün paneli açıkken saat durur (%d → %d)" % [held, save.clock_s], save.clock_s == held)
	await _shot("06_bugun")
	var tea := day_panel.tea_button()
	_check("çay içilebilir (son çaydan beri balık var)", tea != null and not tea.disabled)
	if tea == null:
		day_panel.close_panel()
		return
	var angler: Angler = main.get("angler")
	var elder: Elder = main.get("elder")
	var near := angler.global_position.distance_to(elder.global_position) <= float(main.get("TEA_NEAR"))
	var catches := save.catches
	var seen := {}
	var lines := {}
	var closest := [99.0]
	var watch := func() -> bool:
		if toast.is_visible_in_tree():
			seen[toast.text] = true
		lines[str(main.get("_line"))] = true
		return false
	await _tap_control(tea)
	await _wait_until(func() -> bool:
		watch.call()
		return fade.busy(), 1.0)
	await _wait_until(func() -> bool:
		watch.call()
		return not fade.busy(), 4.0)
	var landed := save.clock_s
	var shot_left := float(main.get("_tea_shot"))
	var camera: FollowCamera = main.get("camera")
	closest[0] = Vector2(camera.target.x - elder.global_position.x, camera.target.z - elder.global_position.z).length()
	await _shot("07_cay")
	await _wait_until(watch, 2.5)
	var dede_line := ""
	for key: String in lines:
		if key == "UI_DEDE_TEA" or key == "UI_DEDE_TIME_morning" or key.begins_with("UI_DEDE_WEATHER_"):
			dede_line = key
	_check("ÇAY → gece biter, %d. günün sabahı; \"%s\" bildirimi; son çay kayıtta" % [today + 2, tr("UI_PHASE_NOW_morning")],
			DayClock.phase(rules, landed) == "morning" and DayClock.day(rules, landed) == today + 1
			and landed - (today + 1) * DayClock.day_s(rules) <= 1 and save.tea_at == catches
			and seen.has(UiKit.upper(tr("UI_PHASE_NOW_morning"))))
	_check("çaydan sonra Dede konuşur (%s)" % dede_line, not dede_line.is_empty())
	if near:
		_check("Dede yakında: kamera ona yaklaşır (%.1f sn, Dede'ye %.1f m)" % [shot_left, closest[0]],
				shot_left > 0.5 and closest[0] < 2.5)
	await _tap_control(hud.world_button)
	await _wait_until(func() -> bool: return day_panel.visible, 2.0)
	await _wait(0.4)
	tea = day_panel.tea_button()
	var note := day_panel.find_child("TeaNote", true, false) as Label
	_check("balık tutmadan ikinci çay yok: düğme pasif, \"%s\"" % tr("UI_TEA_WAIT"),
			tea != null and tea.disabled and note != null and note.text == tr("UI_TEA_WAIT"))
	await _shot("08_cay_bekler")
	day_panel.close_panel()
	await _wait(0.4)
	# Dükkân açıkken Nine'nin valsi, kapanınca vaktin müziği.
	var shop: ShopPanel = main.get("shop_panel")
	main.call("_on_shop")
	await _wait_until(func() -> bool: return shop.visible, 2.0)
	var in_shop := Sounds.music_name()
	shop.close_panel()
	await _wait(0.3)
	_check("dükkânda Nine'nin valsi (%s), kapanınca sabah müziği (%s)" % [in_shop, Sounds.music_name()],
			in_shop == "shop" and Sounds.music_name() == "morning")


## İskelede her vakit × açık, yağmur ve sis (sisli günün öğle ve akşamı bulutlu): ekran görüntüsü, çizim
## sayısı ve ÖLÇÜ satırları (doygunluk, en koyu %5'in parlaklığı, gölgenin suya karşıtlığı). Saat donuk,
## görünüş hemen (geçişsiz). Gölge karşıtlığı her görünüşte (gece de) en az LOOK_CONTRAST.
func _world_looks() -> void:
	var db := GameState.db
	var rules := db.rules
	var save := GameState.save
	var clock: WorldClock = main.get("world_clock")
	var scene: LakeScene = main.get("scene")
	var fade: Fade = main.get("fade")
	clock.frozen = true
	if str(main.get("zone_id")) != "dock_cove":
		main.call("_travel", "dock_cove")
		await _wait_until(func() -> bool: return fade.busy(), 1.0)
		await _wait_until(func() -> bool: return not fade.busy(), 5.0)
	save.settings["perf"] = true
	# Nine'nin feneri (ilk gece hediyesi) var: gece balıkçının çevresinde ışık havuzu.
	save.flags[main.get("LANTERN_FLAG")] = true
	GameState.changed.emit()
	var day := 3
	var wrong_amb: PackedStringArray = []
	var worst_contrast := 1.0
	var worst_at := ""
	var worst_draws := 0
	var index := 10
	for weather: String in ["clear", "rain", "fog"]:
		for i in DayClock.PHASES.size():
			var phase := DayClock.PHASES[i]
			save.clock_s = day * DayClock.day_s(rules) + i * rules.phase_s + (rules.phase_s >> 1)
			save.flags[Weather.DEBUG_DAY] = day
			save.flags[Weather.DEBUG_KIND] = weather
			clock.refresh(save)
			main.call("_sync_world_chip")
			scene.set_look(DayLook.at(rules, save), true)
			var at := Vector2(1.0, -3.2)
			_shadow_at(at, Vector2(0, 1), "carp", 900000)
			await _wait(0.8)
			scene.set_look(DayLook.at(rules, save), true)
			var draws := await _measure_draws()
			await RenderingServer.frame_post_draw
			var image := get_viewport().get_texture().get_image()
			var stats := _image_stats(image)
			var contrast := _shadow_contrast(image, at, at + Vector2(1.6, 0.0))
			var shown := Weather.at(rules, save)
			var label := "%s/%s" % [phase, shown]
			var want_amb := "rain" if shown == "rain" else ("night" if phase == "night" else "lake")
			if Sounds.ambience_name() != want_amb:
				wrong_amb.append("%s: %s" % [label, Sounds.ambience_name()])
			print("ÖLÇÜ %-14s doygunluk %.3f, en koyu %%5 %.3f, ortalama %.3f, gölge karşıtlığı %.2f, %d çizim" % [label,
					stats["saturation"], stats["dark5"], stats["mean"], contrast, draws["draws"]])
			if contrast < worst_contrast:
				worst_contrast = contrast
				worst_at = label
			worst_draws = maxi(worst_draws, int(draws["draws"]))
			await _shot("%d_%s_%s" % [index, phase, shown])
			index += 1
		day += 1
	_check("her vakit ve havada gölge suda seçilir (en düşük karşıtlık %.2f: %s; en az %.2f)" % [worst_contrast, worst_at,
			LOOK_CONTRAST], worst_contrast >= LOOK_CONTRAST)
	_check("her vakit ve havada iskelede en çok %d çizim (%d)" % [TOUR_DRAWS, worst_draws], worst_draws <= TOUR_DRAWS)
	_check("ortam sesi görünüşle: yağmurda yağmur, gece cırcır böceği, gündüz göl%s" % (
			"" if wrong_amb.is_empty() else ": " + ", ".join(wrong_amb)), wrong_amb.is_empty())
	save.settings["perf"] = false
	GameState.changed.emit()


## Görüntünün ölçüleri (küçültülmüş kopyasından): ortalama doygunluk, en koyu %5'in ve bütününün ortalama
## parlaklığı (0..1).
static func _image_stats(image: Image) -> Dictionary:
	var small := image.duplicate() as Image
	small.resize(maxi(1, image.get_width() >> 2), maxi(1, image.get_height() >> 2), Image.INTERPOLATE_BILINEAR)
	var lum := PackedFloat32Array()
	var saturation := 0.0
	for y in small.get_height():
		for x in small.get_width():
			var c := small.get_pixel(x, y)
			lum.append(0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b)
			saturation += c.s
	lum.sort()
	var count := lum.size()
	var dark := 0.0
	var dark_n := maxi(1, count / 20)
	for i in dark_n:
		dark += lum[i]
	var mean := 0.0
	for v in lum:
		mean += v
	return { "saturation": saturation / count, "dark5": dark / dark_n, "mean": mean / count }


## Gölgenin ortasıyla yanındaki suyun parlaklık karşıtlığı: 1 − gölge / su (0: seçilmez).
## Noktalar görüntünün piksellerine çevrilir (görüntü pencerenin boyunda, _screen tuvalin biriminde).
func _shadow_contrast(image: Image, shadow: Vector2, water: Vector2) -> float:
	var scale := Vector2(image.get_size()) / get_viewport().get_visible_rect().size
	var a := _patch_lum(image, _screen(Vector3(shadow.x, 0.0, shadow.y)) * scale)
	var b := _patch_lum(image, _screen(Vector3(water.x, 0.0, water.y)) * scale)
	return 1.0 - a / maxf(b, 0.001)


static func _patch_lum(image: Image, at: Vector2) -> float:
	var sum := 0.0
	var n := 0
	for dy in range(-3, 4):
		for dx in range(-3, 4):
			var x := clampi(int(at.x) + dx, 0, image.get_width() - 1)
			var y := clampi(int(at.y) + dy, 0, image.get_height() - 1)
			var c := image.get_pixel(x, y)
			sum += 0.2126 * c.r + 0.7152 * c.g + 0.0722 * c.b
			n += 1
	return sum / n


## Dede'nin istekleri (Dalga 4, 4. adım; KONTROL satırları; telefon oranında, --safe-inset=130, TR ve EN):
## rütbe 1'de yok (rozet yok, Bugün panelinde istek bölümü gizli); rütbe 2'yi getiren balıkla yuvalar dolar, çipte
## rozet (çipin köşesinde), Dede saate dokunmayı söyler, çip nabız gibi atar; iskelede çizim sınırı rozetle. Bugün
## paneli küçülmeden sığar: istek kartları (yazı en çok iki satır, ilerleme, değiştir düğmesi), açılınca rozet
## söner. Bir yakalayışla biten istek: bildirim, para, rütbe puanı ve sevgi gelir, yuva boşalır ("Yarın yeni
## istek"), Dede "aferin" der; kovadan bırakmayla biten bırakma isteği de. Değiştir bir kez: yeni istek, not
## "Yarın yine", düğmeler pasif. Yeni günde (VAKİT +) boş yuva dolar: "Sabah oldu"dan sonra "Yeni gün!", rozet.
## İSTEK BİTİR deneme düğmesi. Rütbe 3'te yağmurlu günde yağmur isteği adayı. Rehberin "Göl yaşıyor" sayfası.
func _play_requests() -> void:
	_use_save(3)
	_roomy_bucket()
	var db := GameState.db
	var rules := db.rules
	var save := GameState.save
	var hud := _hud()
	var day_panel: DayPanel = main.get("day_panel")
	var toast: Label = hud.get("_toast")
	var badge: Control = hud.get("_world_badge")
	var spot := str(main.get("spot_id"))
	# Kartsız yakalamalar: bütün türler bilinir, rekor kırılmaz.
	for f in db.fish:
		Records.add(save.records, str(f["id"]), 999, 3, 0)
	save.xp = db.rank_xp[db.requests.unlock_rank - 1] - 1
	GameState.changed.emit()
	await _wait(1.0)
	# 1) Rütbe 1: istek yok.
	await _tap_control(hud.world_button)
	await _wait_until(func() -> bool: return day_panel.visible, 2.0)
	await _wait(0.4)
	var box := day_panel.find_child("Requests", true, false) as Control
	_check("rütbe 1'de istek yok: çipte rozet yok, Bugün panelinde istek bölümü gizli", day_panel.visible
			and save.requests.is_empty() and not hud.world_badge and box != null and not box.is_visible_in_tree())
	day_panel.close_panel()
	await _wait(0.4)
	# 2) Rütbe 2'yi getiren balık: yuvalar dolar, çipte rozet; Dede saate dokunmayı söyler, çip nabız gibi atar.
	var caught := await _catch_at_dock("rudd", 300_000)
	await _wait_frames(2)
	_check("rütbe 2'yi getiren balıkla %d istek, çipte rozet" % save.requests.size(), caught
			and Rank.rank(db, save) == db.requests.unlock_rank and save.requests.size() == db.requests.slots
			and hud.world_badge)
	var told := await _wait_until(func() -> bool: return str(main.get("_hint_shown")) == "UI_DEDE_REQ_FIRST", 20.0)
	var view := get_viewport().get_visible_rect()
	_check("Dede saate dokunmayı söyler, çip nabız gibi atar, rozet çipin köşesinde ve ekranda (%s, %s)" % [
			main.get("_hint_shown"), badge.get_global_rect()], told and float(hud.get("_world_pulse")) > 0.0
			and badge.is_visible_in_tree() and badge.get_global_rect().intersects(hud.world_button.hit_rect())
			and view.encloses(badge.get_global_rect()))
	await _shot("01_ilk_istekler")
	var hint: Control = hud.get("_hint")
	await _wait_until(func() -> bool: return not toast.is_visible_in_tree() and not hint.visible, 25.0)
	await _wait(0.5)
	var draws := int((await _measure_draws())["draws"])
	print("ÇİZİM istek rozeti: %d" % draws)
	_check("çipte rozetle iskelede en çok %d çizim (%d)" % [TOUR_DRAWS, draws], badge.is_visible_in_tree()
			and draws > 0 and draws <= TOUR_DRAWS)
	# 3) Bugün paneli: küçülmeden sığar; istek kartları (yazı en çok iki satır, ilerleme 0/N, değiştir düğmesi);
	# açılınca rozet söner.
	await _tap_control(hud.world_button)
	await _wait_until(func() -> bool: return day_panel.visible, 2.0)
	await _wait(0.5)
	var notes := PackedStringArray()
	for slot in db.requests.slots:
		var r := Requests.find_slot(save, slot)
		var holder := day_panel.find_child("Request%d" % slot, true, false) as Control
		var label := holder.find_child("Text", true, false) as Label if holder != null else null
		var progress := holder.find_child("Progress", true, false) as Label if holder != null else null
		var reroll := day_panel.find_child("Reroll%d" % slot, true, false) as Button
		if r.is_empty() or label == null or progress == null or reroll == null:
			notes.append("yuva %d eksik" % slot)
			continue
		print("İSTEK %d: %s (%s), ödül %s" % [slot, label.text, progress.text, r["reward"]])
		if label.get_line_count() > 2:
			notes.append("yuva %d: %d satır" % [slot, label.get_line_count()])
		if label.text != DayPanel.text_of(db, r) or progress.text != "0/%d" % int(r["goal"]):
			notes.append("yuva %d: %s, %s" % [slot, label.text, progress.text])
		if reroll.disabled:
			notes.append("yuva %d: değiştir pasif" % slot)
	_check("Bugün panelinde %d istek: yazı en çok iki satır, ilerleme, değiştir%s" % [db.requests.slots,
			"" if notes.is_empty() else ": " + ", ".join(notes)], notes.is_empty())
	_check("Bugün paneli telefonda küçülmeden sığar (%.3f, %s)" % [day_panel.fit_scale(), day_panel.panel_rect()],
			day_panel.fit_scale() >= 0.999 and _panel_inside(day_panel))
	_check_panel_buttons(day_panel, "Bugün panelinin düğmeleri")
	_check("panel açılınca rozet söner", not hud.world_badge and not badge.visible)
	await _shot("02_bugun_istekler")
	day_panel.close_panel()
	await _wait(0.4)
	# 4) Bir yakalayışla biten istek: ilerleme bir eksikken istenen balık tutulur → bildirim, para, rütbe puanı ve
	# sevgi gelir, yuva boşalır, Dede "aferin" der.
	var target := _request_by_catch(db, save)
	_check("bir yakalayışla bitebilen istek var (%s)" % (Requests.key_of(target[0]) if not target.is_empty() else "-"),
			not target.is_empty())
	var done_slot := -1
	if not target.is_empty():
		var r: Dictionary = target[0]
		done_slot = int(r["slot"])
		r["progress"] = int(r["goal"]) - 1
		var reward: Dictionary = r["reward"]
		var coins := save.coins
		var xp := save.xp
		var love := save.love
		var done_text := UiKit.upper(tr("UI_REQ_DONE") % UiKit.format_int(int(reward["coins"])))
		var got := await _catch_at_dock(str(target[1]), int(target[2]))
		var said := await _wait_until(func() -> bool: return str(main.get("_hint_shown")) == "UI_DEDE_REQ_DONE", 8.0)
		var shown := await _wait_toast(done_text, 8.0)
		var icon: GameIcon = hud.get("_toast_icon")
		_check("istenen balık (%s) → \"%s\" (istek ikonu), +%d para, +%d puan, +%d sevgi, yuva boş, Dede \"aferin\"" % [
				target[1], done_text, int(reward["coins"]), int(reward["xp"]), int(reward["love"])], got and shown
				and icon.kind == "requests" and save.coins == coins + int(reward["coins"])
				and save.xp >= xp + int(reward["xp"]) and save.love == love + int(reward["love"])
				and Requests.find_slot(save, done_slot).is_empty() and said
				and int(save.stats.get("requests", 0)) == 1)
		await _shot("03_istek_tamam")
	# 4b) Bırakma isteği: ilerleme bir eksikken kovadan bir balık bırakılır; bildirim panel kapanınca.
	var release_req := {}
	for r in Requests.daily(db, save):
		if str(r["kind"]) == "release":
			release_req = r
	if not release_req.is_empty() and not save.bucket.is_empty():
		# Önceki bildirim sönsün (bırakmanınki panel kapanınca gelmeli).
		await _wait_until(func() -> bool: return not toast.is_visible_in_tree(), 8.0)
		release_req["progress"] = int(release_req["goal"]) - 1
		var bucket_panel: BucketPanel = main.get("bucket_panel")
		var coins := save.coins
		var paid := int((release_req["reward"] as Dictionary)["coins"])
		await _tap_control(hud.bucket_button)
		await _wait_until(func() -> bool: return bucket_panel.visible, 2.0)
		await _wait(0.4)
		var fish := str(save.bucket[0]["fish"])
		var release := bucket_panel.find_child("Release_" + fish, true, false) as Button
		# Panel yenilenince düğme silinir: bulunduğu dokunmadan önce.
		var found := release != null
		if found:
			await _tap_control(release)
		await _wait_frames(2)
		var held := not toast.is_visible_in_tree()
		await _tap_control(bucket_panel.close_button)
		var shown := await _wait_toast(UiKit.upper(tr("UI_REQ_DONE") % UiKit.format_int(paid)), 6.0)
		_check("bırakma isteği: kovadan bırakınca biter (+%d para), bildirim panel kapanınca" % paid,
				found and held and shown and save.coins == coins + paid
				and Requests.find_slot(save, int(release_req["slot"])).is_empty())
		if done_slot < 0:
			done_slot = int(release_req["slot"])
	# 5) Değiştir: günde bir; yuvada yeni istek (eskisi ve ekrandakiler gelmez), not "Yarın yine", düğmeler pasif;
	# biten isteğin yuvasında "Yarın yeni istek".
	await _wait_state(FishingSession.State.IDLE, 4.0)
	await _tap_control(hud.world_button)
	await _wait_until(func() -> bool: return day_panel.visible, 2.0)
	await _wait(0.4)
	var empty_label := day_panel.find_child("Request%d" % done_slot, true, false)
	empty_label = empty_label.find_child("Empty", true, false) if empty_label != null else null
	_check("biten isteğin yuvasında \"%s\"" % tr("UI_REQ_EMPTY"), empty_label is Label
			and (empty_label as Label).text == tr("UI_REQ_EMPTY"))
	var slot_r := -1
	for slot in db.requests.slots:
		if slot_r < 0 and Requests.can_reroll(db, save, slot):
			slot_r = slot
	var old := Requests.find_slot(save, slot_r).duplicate(true)
	var reroll_button := day_panel.find_child("Reroll%d" % slot_r, true, false) as Button
	var can := reroll_button != null and not reroll_button.disabled
	if can:
		await _tap_control(reroll_button)
	await _wait_frames(3)
	var fresh := Requests.find_slot(save, slot_r)
	var note := day_panel.find_child("RerollNote", true, false) as Label
	var all_off := true
	for slot in db.requests.slots:
		var b := day_panel.find_child("Reroll%d" % slot, true, false) as Button
		all_off = all_off and (b == null or b.disabled)
	_check("değiştir: yuva %d'de yeni istek (%s → %s), \"%s\", değiştir düğmeleri pasif" % [slot_r,
			Requests.key_of(old) if not old.is_empty() else "-", Requests.key_of(fresh) if not fresh.is_empty() else "-",
			tr("UI_REQ_REROLL_USED")], can and not old.is_empty() and not fresh.is_empty()
			and int(fresh["serial"]) != int(old["serial"]) and Requests.key_of(fresh) != Requests.key_of(old)
			and note != null and note.text == tr("UI_REQ_REROLL_USED") and all_off and not hud.world_badge)
	await _shot("04_degistir")
	day_panel.close_panel()
	await _wait(0.4)
	# 6) Yeni gün (VAKİT + sabaha kadar): boş yuva dolar; "Sabah oldu"dan sonra "Yeni gün!" bildirimi, rozet.
	var today := DayClock.day(rules, save.clock_s)
	var seen: Array[String] = []
	var watch := func() -> bool:
		if toast.is_visible_in_tree() and (seen.is_empty() or seen[seen.size() - 1] != toast.text):
			seen.append(toast.text)
		return false
	var skips := 0
	while DayClock.day(rules, save.clock_s) == today and skips < 8:
		main.call("_debug_time")
		skips += 1
		await _wait_frames(2)
		watch.call()
	var new_day := UiKit.upper(tr("UI_REQ_NEW_DAY"))
	var morning := UiKit.upper(tr("UI_PHASE_NOW_morning"))
	await _wait_until(func() -> bool:
		watch.call()
		return seen.has(new_day), 15.0)
	_check("yeni gün: %d. yuva doldu, \"%s\" \"%s\"dan sonra, rozet (%s)" % [done_slot, new_day, morning, ", ".join(seen)],
			done_slot >= 0 and not Requests.find_slot(save, done_slot).is_empty()
			and save.request_day == today + 1 and seen.has(morning) and seen.find(morning) < seen.find(new_day)
			and hud.world_badge)
	await _shot("05_yeni_gun")
	# 7) İSTEK BİTİR (geliştirme sürümü, ölçüm açıkken): ilk bitmemiş istek biter, gerçek akışla öder; bildirim
	# panel kapanınca.
	var settings: SettingsPanel = main.get("settings_panel")
	save.settings["perf"] = true
	GameState.changed.emit()
	await _tap_control(hud.settings_button)
	await _wait_until(func() -> bool: return settings.visible, 2.0)
	await _wait(0.4)
	var first := {}
	for r in Requests.daily(db, save):
		if first.is_empty() and int(r["progress"]) < int(r["goal"]):
			first = r.duplicate(true)
	var finish := settings.find_child("DebugRequest", true, false) as Button
	var coins_before := save.coins
	var active := finish != null and not finish.disabled
	if active:
		await _tap_control(finish)
	await _wait_frames(3)
	var paid_coins := int((first.get("reward", {}) as Dictionary).get("coins", 0))
	settings.close_panel()
	var shown_debug := await _wait_toast(UiKit.upper(tr("UI_REQ_DONE") % UiKit.format_int(paid_coins)), 6.0)
	_check("İSTEK BİTİR: ilk bitmemiş istek (%s) biter ve öder (+%d para), bildirim panel kapanınca" % [
			Requests.key_of(first) if not first.is_empty() else "-", paid_coins], active and not first.is_empty()
			and Requests.find_slot(save, int(first["slot"])).is_empty() and save.coins == coins_before + paid_coins
			and shown_debug)
	save.settings["perf"] = false
	GameState.changed.emit()
	await _wait(0.3)
	# 8) Yağmur isteği yalnızca yağmur tahmininde: rütbe 3'te bugünün havası yağmur (HAVA) → aday.
	save.xp = maxi(save.xp, db.rank_xp[2])
	var tries := 0
	while Weather.at(rules, save) != "rain" and tries < 8:
		main.call("_debug_weather")
		tries += 1
	_check("rütbe 3'te yağmurlu günde yağmur isteği adayı", Weather.at(rules, save) == "rain"
			and Requests.candidates(db, save, spot).has("rain"))
	# 9) Rehberin "Göl yaşıyor" sayfası: karolar sığar, isteklerin kilidi açık (rütbe 2'den sonra).
	var guide: GuidePanel = main.get("guide_panel")
	main.call("_open_guide", "living")
	await _wait_until(func() -> bool: return guide.visible, 2.0)
	await _wait(0.5)
	_check_guide_tiles(guide, "living")
	_check("rehberin \"%s\" sayfası küçülmeden sığar, isteklerin kilidi açık" % tr("UI_GUIDE_LIVING"),
			guide.current_page() == "living" and guide.fit_scale() > 0.999 and not _guide_locked(guide, "requests"))
	await _shot("06_rehber")
	guide.close_panel()
	await _wait(0.3)
	_check_buttons()
	_finish_checks()


## Bir yakalayışla bitebilecek ilk istek ve onu bitirecek balık: [istek, tür, yüzdelik] (yoksa boş). İskelede
## şamandırayla: tür ve boy istekleri, iskele koyunun bölge isteği, şimdiki vaktin isteği.
func _request_by_catch(db: ContentDB, save: SaveData) -> Array:
	var zone := str(main.get("zone_id"))
	var phase := DayClock.phase(db.rules, save.clock_s)
	for r in Requests.daily(db, save):
		var want: Dictionary = r["want"]
		match str(r["kind"]):
			"species":
				return [r, str(want["fish"]), 300_000]
			"size":
				return [r, str(want["fish"]), FishTable.STAR_LIMITS[2] - 1]
			"zone":
				if str(want["zone"]) == zone:
					return [r, "rudd", 300_000]
			"phase":
				if str(want["phase"]) == phase:
					return [r, "rudd", 300_000]
	return []


## Gölün Sırrı (Dalga 4, 5. adım; KONTROL satırları; telefon oranında ve --safe-inset=130 ile, TR ve EN): rütbe 2'de
## şişe yok; rütbe 3'te sazlıkta şişe (bildirim, haritada işaret, Dede'nin sözü, iskelede ve sazlıkta ≤150 çizim);
## yakından dokununca şişe kalkar, mektup 1 açılır (kâğıda kaydırmadan sığar, panel küçülmeden ve güvenli alanda),
## kapanınca Dede yazanı tanır; uzaktaki şişeye dokununca balıkçı yürür ve alır (mektup 2, iskele koyu); mektup
## 3'ten sonra Dede'nin altın isteği (bildirim, Dede'nin haritası, Bugün panelinde altın şerit; panel küçülmeden
## sığar); akşam nilüferli koyda gerçek bir turnayla biter (harita parçası 1/4, para, Dede); derin ortanın şişesi:
## sandal başka şamandıradayken şişeye dokununca sandal ilk şamandıraya gider ve alır (mektup 6).
func _play_secret() -> void:
	_use_save(40)
	var db := GameState.db
	var save := GameState.save
	var spot := str(main.get("spot_id"))
	var bottle: BottleMarker = main.get("bottle")
	var letters: LetterPanel = main.get("letter_panel")
	_roomy_bucket()
	save.xp = db.rank_xp[1]
	GameState.changed.emit()
	await _wait(1.0)
	_check("rütbe 2'de şişe yok", not bottle.visible)
	var book: BookPanel = main.get("book_panel")
	await _tap_control(_hud().book_button)
	await _wait_until(func() -> bool: return book.visible, 2.0)
	await _wait(0.4)
	var early := book.find_child("ViewButton", true, false) as Button
	_check("ilk mektuptan önce defterde Gölün Sırrı yok", book.view() == "fish"
			and (early == null or not early.is_visible_in_tree()))
	book.close_panel()
	await _wait(0.4)
	# Rütbe 3: sazlıkta şişe.
	save.xp = db.rank_xp[2]
	GameState.changed.emit()
	await _wait(0.5)
	var p := bottle.spot()
	var reeds := db.lake(spot).zone_index("reeds")
	_check("rütbe 3'te sazlıkta suda şişe", bottle.visible and Dice.is_point(p) and db.lake(spot).zone_at(p) == reeds)
	_check("bildirim: suda bir şişe var (Sazlık)", await _wait_toast(UiKit.upper(tr("UI_BOTTLE_SEEN") % tr("ZONE_reeds")), 6.0))
	var marks: Array = main.call("_map_marks")
	var marked := false
	for m: Dictionary in marks:
		marked = marked or str(m["kind"]) == "bottle"
	_check("haritada şişenin işareti", marked)
	_check("Dede şişeyi söyler", await _wait_until(func() -> bool: return str(main.get("_line")) == "UI_DEDE_BOTTLE_FIRST", 8.0))
	await _travel_to("reeds")
	await _wait(1.0)
	var draws := await _measure_draws(20)
	_check("ÇİZİM sazlıkta şişeyle: %d (≤150)" % int(draws["draws"]), int(draws["draws"]) <= 150)
	await _shot("01_sazlikta_sise")
	# Yakından dokun: şişe kalkar, mektup açılır.
	var at := _screen(bottle.point())
	_check("şişe ekranda ve düğmelerin altında değil", get_viewport().get_visible_rect().has_point(at) and not _under_hud(p))
	await _tap(at)
	_check("dokununca mektup 1 açılır", await _wait_until(func() -> bool: return letters.visible, 3.0)
			and save.letters == 1 and letters.letter == 1)
	await _wait(0.6)
	_check("mektup kâğıda kaydırmadan sığar", letters.fits_without_scroll())
	_check("mektup paneli küçülmeden ve güvenli alanda (%.2f)" % letters.fit_scale(), letters.fit_scale() > 0.999
			and _panel_inside(letters))
	await _shot("02_mektup_1")
	_check("şişe gitti", await _wait_until(func() -> bool: return not bottle.visible, 2.0))
	await _tap_control(letters.close_button)
	_check("kapanınca Dede yazanı tanır", await _wait_until(func() -> bool:
			return str(main.get("_line")) == "UI_DEDE_LETTER_1", 3.0))
	# Defter: ilk mektuptan sonra Gölün Sırrı görünüşü (düğmesi sayfa düğmelerinin sağında).
	await _tap_control(_hud().book_button)
	await _wait_until(func() -> bool: return book.visible, 2.0)
	await _wait(0.5)
	var fish_size := book.panel_rect().size
	var view_button := book.find_child("ViewButton", true, false) as Button
	_check("defterde Gölün Sırrı düğmesi", view_button != null and view_button.is_visible_in_tree())
	if view_button != null:
		await _tap_control(view_button)
	await _wait(0.5)
	var card_1 := book.find_child("Letter1", true, false) as Button
	var card_2 := book.find_child("Letter2", true, false) as Button
	_check("Gölün Sırrı: mektup 1 okunmuş, 2 sıradaki", book.view() == "secret" and card_1 != null
			and not card_1.disabled and card_2 != null and card_2.disabled)
	# Balıkların görünüşü seçili türün ayrıntısıyla büyür (telefonda küçülerek sığar: rarity botu); sırrınki ondan
	# büyük olmamalı.
	_check("defterin sır görünüşü güvenli alanda, balıklarınkinden büyük değil (%s, %s)" % [fish_size,
			book.panel_rect().size], _panel_inside(book) and book.panel_rect().size.y <= fish_size.y + 1.0)
	await _shot("03_defter_sir")
	if card_1 != null:
		await _tap_control(card_1)
	_check("defterden mektup yeniden okunur", await _wait_until(func() -> bool:
			return letters.visible and letters.letter == 1, 2.0))
	await _tap_control(letters.close_button)
	await _wait(0.3)
	_check("defter açık kalır", book.visible)
	book.close_panel()
	await _wait(0.4)
	# Mektup 2: iskele koyunda; uzaktan dokununca balıkçı yürür ve alır.
	save.xp = db.rank_xp[3]
	save.catches += Secret.LETTER_GAP
	GameState.changed.emit()
	await _wait(0.5)
	_check("rütbe 4 ve 15 balık: iskele koyunda şişe", bottle.visible and Secret.bottle_zone(save) == "dock_cove")
	await _travel_to("dock_cove")
	await _wait(1.0)
	# İskelede (çizimin en çok olduğu yer) şişe ve arada çevresindeki halka: bir halka aralığı boyunca en çok.
	# Sınır kalıcı görünüşe bakar: geçici yazılar (bildirim, Dede'nin sözü) sönünce ölçülür (gezi botu gibi).
	var ripple_frames := int(BottleMarker.RIPPLE_EVERY * 30.0) + 10
	var busy_draws := int((await _measure_draws(ripple_frames))["draws"])
	var toast: Control = _hud().get("_toast")
	var hint: Control = _hud().get("_hint")
	await _wait_until(func() -> bool: return not toast.is_visible_in_tree() and not hint.visible, 25.0)
	await _wait(0.5)
	var dock_draws := int((await _measure_draws(ripple_frames))["draws"])
	print("ÇİZİM iskelede şişeyle: yazılarla %d, yazısız %d" % [busy_draws, dock_draws])
	_check("ÇİZİM iskelede şişe ve halkasıyla (yazılar sönünce): %d (≤%d)" % [dock_draws, TOUR_DRAWS],
			dock_draws > 0 and dock_draws <= TOUR_DRAWS)
	_angler().place(Vector2(0.0, 9.5))
	await _wait(0.8)
	var far := _angler().pos2().distance_to(bottle.spot())
	await _tap(_screen(bottle.point()))
	_check("uzaktaki şişe (%.1f m): balıkçı yürür" % far, far > 5.0 and
			await _wait_until(func() -> bool: return _angler().is_walking(), 1.5))
	_check("varınca alır: mektup 2", await _wait_until(func() -> bool: return letters.visible, 15.0) and save.letters == 2)
	await _wait(0.4)
	await _tap_control(letters.close_button)
	await _wait(0.5)
	# Mektup 3 ve ilk altın istek.
	save.xp = db.rank_xp[5]
	save.catches += Secret.LETTER_GAP
	GameState.changed.emit()
	await _travel_to("lily_cove")
	await _wait(0.5)
	await _tap(_screen(bottle.point()))
	_check("nilüferli koyda mektup 3", await _wait_until(func() -> bool: return letters.visible, 3.0) and save.letters == 3)
	await _wait(0.4)
	await _tap_control(letters.close_button)
	await _wait(0.3)
	var golden := Requests.golden(db, save)
	_check("mektup 3'ten sonra Dede'nin altın isteği (parça 1)", not golden.is_empty()
			and int((golden["reward"] as Dictionary).get("piece", 0)) == 1)
	_check("bildirim: altın istek", await _wait_toast(UiKit.upper(tr("UI_GOLDEN_NEW")), 6.0))
	_check("Dede eski haritasını anlatır", await _wait_until(func() -> bool:
			return str(main.get("_line")) == "UI_DEDE_GOLDEN_FIRST", 12.0))
	var day: DayPanel = main.get("day_panel")
	await _tap_control(_hud().world_button)
	await _wait_until(func() -> bool: return day.visible, 2.0)
	await _wait(0.6)
	_check("Bugün panelinde altın şerit", day.find_child("Golden", true, false) != null)
	_check("Bugün paneli altın şeritle küçülmeden sığar (%.2f)" % day.fit_scale(), day.fit_scale() > 0.999
			and _panel_inside(day))
	await _shot("03_altin_istek")
	day.close_panel()
	await _wait(0.5)
	# Akşam olur: nilüferli koyda bir turna tutulur.
	main.call("_debug_time")
	main.call("_debug_time")
	await _wait(1.0)
	var coins := save.coins
	var caught := await _catch_here("pike")
	_check("akşam nilüferli koyda turna tutuldu (%s)" % DayClock.phase(db.rules, save.clock_s), caught)
	_check("altın istek biter: harita parçası 1/4", save.map_pieces == 1 and Requests.golden(db, save).is_empty()
			and save.coins > coins)
	_check("bildirim: harita parçası", await _wait_toast(UiKit.upper(tr("UI_GOLDEN_DONE") % [1, SaveData.MAX_MAP_PIECES,
			UiKit.format_int(int((golden["reward"] as Dictionary)["coins"]))]), 8.0))
	_check("Dede: bir parça daha", await _wait_until(func() -> bool:
			return str(main.get("_line")) == "UI_DEDE_GOLDEN_DONE", 10.0))
	# Altın hamur: göl sevgisi 6 → Dede "Nine'ye uğra"; Nine'ye dokununca hamur, takım çantasında dipte.
	var old_love := LakeLove.level(db.rules, save.love)
	save.love = db.rules.love_levels[Secret.DOUGH_LOVE - 1]
	main.call("_after_love", { "old_level": old_love, "new_level": Secret.DOUGH_LOVE })
	_check("göl sevgisi 6: Dede Nine'yi söyler", await _wait_until(func() -> bool:
			return str(main.get("_line")) == "UI_DEDE_LOVE_6", 14.0))
	var shop: ShopPanel = main.get("shop_panel")
	main.call("_on_shop")
	await _wait_until(func() -> bool: return shop.visible, 2.0)
	await _wait(0.4)
	_check("Nine altın hamuru verir (dükkânda Nine'nin sözü)", Secret.has_dough(save)
			and str(shop.get("_line_key")) == "UI_NINE_DOUGH")
	await _shot("05_altin_hamur")
	shop.close_panel()
	_check("bildirim: altın hamur", await _wait_toast(UiKit.upper(tr("UI_DOUGH_GIVEN")), 6.0))
	var bag: TechniquePanel = main.get("technique_panel")
	bag.open()
	await _wait(0.5)
	_check("takım çantasında dipte altın hamur", bag.find_child("Dough", true, false) != null)
	bag.close_panel()
	await _wait(0.3)
	# Sandaldayken kıyıdaki şişeye (dere ağzı, mektup 5) dokununca sandaldan inilip dere ağzına geçilir, şişe alınır.
	save.letters = 4
	save.letter_at = save.catches - Secret.LETTER_GAP
	save.xp = db.rank_xp[9]
	if not Zones.BOAT in save.owned:
		save.owned.append(Zones.BOAT)
	GameState.changed.emit()
	await _wait(0.3)
	var fade: Fade = main.get("fade")
	main.call("_go_boat", 1)
	await _wait_frames(2)
	await _wait_until(func() -> bool: return not fade.busy(), 4.0)
	await _wait(0.5)
	_check("sandalda; dere ağzında şişe (mektup 5)", bool(main.get("in_boat")) and bottle.visible
			and Secret.bottle_zone(save) == "stream_mouth")
	main.call("_on_bottle_tapped")
	_check("sandaldan kıyıdaki şişeye: dere ağzına geçilir ve alınır (mektup 5)", await _wait_until(func() -> bool:
			return letters.visible, 8.0) and save.letters == 5 and not bool(main.get("in_boat")))
	await _wait(0.4)
	await _tap_control(letters.close_button)
	await _wait(0.5)
	# Derin ortanın şişesi: sandal üçüncü şamandırada, şişeye dokununca ilk şamandıraya gider ve alır.
	save.letters = Secret.LETTERS.size() - 1
	save.letter_at = save.catches - Secret.LETTER_GAP
	save.xp = db.rank_xp[11]
	GameState.changed.emit()
	await _wait(0.3)
	main.call("_go_boat", 2)
	await _wait_frames(2)
	await _wait_until(func() -> bool: return not fade.busy(), 4.0)
	await _wait(0.5)
	_check("derin ortada şişe ilk şamandıranın yanında", bottle.visible and Secret.bottle_zone(save) == "deep_water")
	main.call("_on_bottle_tapped")
	_check("sandal ilk şamandıraya gider ve alır: mektup 6", await _wait_until(func() -> bool:
			return letters.visible, 8.0) and save.letters == Secret.LETTERS.size() and int(main.get("_buoy")) == 0)
	await _wait(0.5)
	await _shot("04_mektup_6")
	await _tap_control(letters.close_button)
	await _wait(0.5)
	_check("mektuplar bitti: şişe yok", not bottle.visible and Secret.next_letter(save) == -1)
	# Kalan altın istekler (geliştirme düğmesi SIR +: gerçek akışla öder): dördüncü parçada harita tamam.
	_check("altıncı mektuptan sonra altın istek (parça 2)", int((Requests.golden(db, save).get("reward", {}) as Dictionary)
			.get("piece", 0)) == 2)
	for i in 3:
		main.call("_debug_secret")
		await _wait(0.3)
	_check("dört parça: harita tamam", save.map_pieces == SaveData.MAX_MAP_PIECES and Requests.golden(db, save).is_empty())
	_check("Dede: harita tamam", await _wait_until(func() -> bool:
			return str(main.get("_line")) == "UI_DEDE_MAP_DONE", 12.0))
	var x_marked := false
	for m: Dictionary in main.call("_map_marks"):
		x_marked = x_marked or str(m["kind"]) == "secret_x"
	_check("haritada Bekçi'nin X'i", x_marked)
	var map_panel: MapPanel = main.get("map_panel")
	main.call("_return_to_shore")
	await _wait_until(func() -> bool: return not fade.busy(), 4.0)
	await _wait(0.6)
	await _tap_control(_hud().map_button)
	await _wait_until(func() -> bool: return map_panel.visible, 2.0)
	await _wait(0.6)
	await _shot("06_haritada_x")
	map_panel.close_panel()
	await _wait(0.4)
	book.open_secret()
	await _wait(0.6)
	_check("defterde harita dört parça", (book.find_child("Map", true, false) as SecretMap).pieces == SaveData.MAX_MAP_PIECES)
	await _shot("07_harita_tamam")
	book.close_panel()
	_check("final hazır: 6 mektup, 4 parça, altın hamur", Secret.final_ready(save))
	_finish_checks()


## Bulunduğu atış noktasında şamandırayla bir balık tutar (fish_id): gölgeyi balıkçının önüne, ona bakarak
## koyar, atar, VUR, oyuncu gibi çeker; kart açılırsa kapatır, olta boşa dönene kadar bekler. Tutulduysa true.
func _catch_here(fish_id: String, percentile: int = 300_000) -> bool:
	await _wait_state(FishingSession.State.IDLE, 4.0)
	var a := _angler().pos2()
	var f := _angler().facing.normalized()
	_shadow_at(a + f * 4.4, -f, fish_id, percentile)
	await _tap_world(a + f * 2.4)
	if not await _wait_state(FishingSession.State.BITING, 25.0):
		return false
	await _reel_like_player(6, 40.0)
	var caught := _state() == FishingSession.State.CAUGHT and str(_session().last_catch.get("fish", "")) == fish_id
	var card: FishCard = main.get("card")
	await _wait(FishCard.MIN_OPEN)
	if card.visible or float(main.get("_card_wait")) >= 0.0:
		await _close_card(card)
	await _wait_state(FishingSession.State.IDLE, 6.0)
	return caught


## Gölün Bekçisi ve final (yukarıdaki keeper senaryosu).
func _play_keeper() -> void:
	_use_save(200)
	var db := GameState.db
	var save := GameState.save
	var rules := db.rules
	var fade: Fade = main.get("fade")
	var card: FishCard = main.get("card")
	var story: StoryPanel = main.get("story_panel")
	var credits: CreditsPanel = main.get("credits_panel")
	var keeper: KeeperPresenter = main.get("keeper")
	var scene: LakeScene = main.get("scene")
	var clock: WorldClock = main.get("world_clock")
	_roomy_bucket()
	save.xp = db.rank_xp[12]
	save.letters = Secret.LETTERS.size()
	save.letter_at = save.catches
	save.map_pieces = SaveData.MAX_MAP_PIECES
	save.flags[Secret.DOUGH_FLAG] = true
	save.love = db.rules.love_levels[Secret.DOUGH_LOVE - 1]
	# Göl sevgisinin seviye sözleri söylenmiş (finalin sözünü beklemesin).
	for at in [2, 6, 10]:
		save.flags["told_love_%d" % at] = true
	for id: String in ["rod_carp_2", "sinker", "line_braid", "reel_strong", Zones.BOAT]:
		if not id in save.owned:
			save.owned.append(id)
	Economy.equip(db, save, "rod_carp_2", "bottom")
	Economy.equip(db, save, "sinker", "bottom")
	Economy.equip(db, save, "line_braid", "bottom")
	Economy.equip(db, save, "reel_strong", "bottom")
	GameState.changed.emit()
	await _wait(1.0)
	_check("final hazır: final gecesi", Secret.final_ready(save) and Secret.keeper_night(save))
	_check("Dede: bu gece sis basacak", await _wait_until(func() -> bool: return str(main.get("_line")) == "UI_DEDE_FINAL", 10.0))
	await _shot("01_final_hazir")
	var day: DayPanel = main.get("day_panel")
	await _tap_control(_hud().world_button)
	await _wait_until(func() -> bool: return day.visible, 2.0)
	await _wait(0.6)
	_check("Bugün panelinde gecenin sisi (Bekçi'nin gecesi)", _label_with_text(day, tr("UI_DAY_DETAIL_keeper")) != null)
	_check("Bugün paneli küçülmeden sığar (%.2f)" % day.fit_scale(), day.fit_scale() > 0.999 and _panel_inside(day))
	await _shot("02_bugun_final")
	day.close_panel()
	await _wait(0.4)
	# Gündüz X'te: Dede gece gelir der.
	main.call("_go_boat", Secret.KEEPER_BUOY)
	await _wait_frames(2)
	await _wait_until(func() -> bool: return not fade.busy(), 4.0)
	_check("sandal X'te", bool(main.get("in_boat")) and int(main.get("_buoy")) == Secret.KEEPER_BUOY)
	_check("gündüz X'te Dede: Bekçi gece gelir", await _wait_until(func() -> bool:
			return str(main.get("_line")) == "UI_DEDE_KEEPER_WAIT", 6.0))
	# Gece: sisli, fırtına yok; şamandırayla Dede dip kamışını söyler.
	for i in 3:
		main.call("_debug_time")
		await _wait(0.4)
	var cond := clock.conditions()
	_check("gece (%s): sisli, fırtınasız" % str(cond["weather"]), str(cond["phase"]) == "night"
			and str(cond["weather"]) == "fog" and not Weather.stormy(str(cond["weather"]), "night"))
	_check("X'te şamandırayla Dede: dip kamışı", await _wait_until(func() -> bool:
			return str(main.get("_line")) == "UI_DEDE_KEEPER_BOTTOM", 8.0))
	await _wait(1.0)
	main.call("_on_technique_selected", "bottom")
	await _wait_frames(4)
	_check("elde dip", _session().technique.id == "bottom")
	await _wait_until(func() -> bool: return float(main.get("_line_time")) <= 0.0, 8.0)
	# İlk deneme: Bekçi gelir; koklarken dokunmak onu kaçırmaz; koşuda VUR; dalışta basılı tutulur, misina kopar.
	var first := await _keeper_cast(true)
	_check("dipte at: Bekçi belirir (bildirim, Dede, müziği)", bool(first["rose"]) and bool(first["toast"])
			and bool(first["dede"]) and bool(first["music"]))
	_check("ÇİZİM Bekçi gölde, sisli gecede: %d (≤%d)" % [int(first["draws"]), TOUR_DRAWS],
			int(first["draws"]) > 0 and int(first["draws"]) <= TOUR_DRAWS)
	_check("takıma Bekçi gelir, koklar", bool(first["sniffed"]))
	_check("koklarken dokunmak Bekçi'yi kaçırmaz (irkilir)", bool(first["forgiven"]))
	_check("koşuda VUR: çekişme, dalışlı", bool(first["hooked"]) and bool(first["dives"]))
	_check("dalışta basılı tutunca misina kopar", bool(first["snapped"]))
	_check("Dede: kaçırdık, geri gelecek", await _wait_until(func() -> bool:
			return str(main.get("_line")) == "UI_DEDE_KEEPER_LOST", 6.0))
	# Bekçi kaçtı: RETURN_TIME geçmeden gelmez; sonra yeniden atılınca gelir ("geri geldi").
	await _wait_state(FishingSession.State.IDLE, 6.0)
	await _wait(2.0)
	await _tap_world(_session().angler + Vector2(10.0, 0.0))
	await _wait_state(FishingSession.State.WAITING, 4.0)
	await _wait(KeeperPresenter.RISE_DELAY + 1.0)
	_check("kaçan Bekçi hemen gelmez", _session().summoned() == null)
	await _tap(Vector2(260, 520))
	await _wait_state(FishingSession.State.IDLE, 6.0)
	await _wait_until(func() -> bool: return float(keeper.get("_return_wait")) <= 0.0, KeeperPresenter.RETURN_TIME + 5.0)
	var second := await _keeper_cast(false)
	_check("%d sn sonra Bekçi yine gelir (Dede: geri geldi)" % roundi(KeeperPresenter.RETURN_TIME), bool(second["rose"])
			and bool(second["back"]))
	_check("dalış uyarısında ipucu: BIRAK! Bekçi dalıyor", bool(second["dive_hint"]))
	_check("ÇİZİM çekişmede, dalışta: %d (≤%d)" % [int(second["fight_draws"]), TOUR_DRAWS],
			int(second["fight_draws"]) > 0 and int(second["fight_draws"]) <= TOUR_DRAWS)
	_check("iki dalış, Bekçi tutulur", int(second["dive_count"]) == 2 and bool(second["caught"]))
	_check("Bekçi elde gösterilmez", not bool(second["in_hand"]))
	_check("Masalsı kart, düğmesi Göle bırak", await _wait_until(func() -> bool: return card.visible, 3.0)
			and card.ok_button != null and card.ok_button.text == UiKit.upper(tr("UI_CARD_RELEASE")))
	_check("Bekçi göle döndü: final bitti, sevgi, defterde", save.keeper == 1 and not Secret.keeper_night(save)
			and save.records.has(Secret.KEEPER_ID))
	await _wait(0.6)
	await _shot("05_bekci_kart")
	await _close_card(card)
	# Bitiş filmi: beş çekim; her çekimde görüntü ve çizim.
	_check("kart kapanınca bitiş filmi", await _wait_until(func() -> bool:
			return story.visible and story.lines() == Story.ENDING, 3.0) and not _hud().visible)
	_check("bitişin müziği", await _wait_until(func() -> bool: return Sounds.music_name() == "ending", 4.0))
	var worst := { "draws": 0, "shot": "" }
	var morning := false
	var docked := false
	for i in Story.ENDING.size():
		var kind := str(Story.ENDING[i][2])
		await _wait_until(func() -> bool: return story.index() == i or not story.visible, 15.0)
		await _wait(StoryFilm.MOVE_TIME + 0.6)
		var draws := int((await _measure_draws(20))["draws"])
		if draws > int(worst["draws"]):
			worst = { "draws": draws, "shot": kind }
		await _shot("06_bitis_%d_%s" % [i + 1, kind])
		if kind == "dawn":
			await _wait_until(func() -> bool: return not fade.busy(), 4.0)
			morning = DayClock.phase(rules, save.clock_s) == "morning"
			docked = not bool(main.get("in_boat")) and _angler().pos2().distance_to(db.spot(str(main.get("spot_id")))["start"]) < 0.5
		elif kind == "bloom":
			_check("göl çiçek açar: sevginin en üst görünüşü", scene.love_level() == LakeLove.max_level(rules))
	_check("şafakta balıkçı iskelede, saat sabah", morning and docked)
	_check("ÇİZİM bitiş filminde: en çok %d (%s) (≤%d)" % [int(worst["draws"]), worst["shot"], TOUR_DRAWS],
			int(worst["draws"]) <= TOUR_DRAWS)
	_check("film bitince jenerik", await _wait_until(func() -> bool: return credits.visible, 15.0) and not story.visible)
	await _wait(2.5)
	await _shot("07_jenerik")
	await _wait(2.0)
	await _shot("08_jenerik_2")
	_check("jeneriğin ATLA'sı büyük ve güvenli alanda", _inside_safe(credits.skip_button)
			and credits.skip_button.size.y >= 122.0)
	await _tap_control(credits.skip_button)
	_check("ATLA: oyun geri", await _wait_until(func() -> bool: return not credits.visible and _hud().visible, 3.0))
	await _wait(1.5)
	_check("bitiş görüldü (kayıtta)", save.flags.has(Story.ENDING_FLAG))
	# Defterde Bekçi.
	var book: BookPanel = main.get("book_panel")
	book.open_book(Secret.KEEPER_ID)
	await _wait_until(func() -> bool: return book.visible, 2.0)
	await _wait(0.6)
	_check("defterde Bekçi seçili, tutulmuş", book.selected() == Secret.KEEPER_ID)
	_check("defter güvenli alanda", _panel_inside(book))
	await _shot("09_defter_bekci")
	book.close_panel()
	await _wait(0.4)
	# Ayarlar'da BİTİŞ: yeniden izlenir, saat değişmez.
	var settings: SettingsPanel = main.get("settings_panel")
	await _tap_control(_hud().settings_button)
	await _wait_until(func() -> bool: return settings.visible, 2.0)
	await _wait(0.5)
	var ending := settings.find_child("Ending", true, false) as Button
	_check("Ayarlar'da BİTİŞ (büyük, güvenli alanda); panel küçülmeden sığar (%.2f)" % settings.fit_scale(),
			ending != null and ending.is_visible_in_tree() and not ending.disabled and ending.size.y >= 122.0
			and _inside_safe(ending) and settings.fit_scale() > 0.999)
	await _shot("10_ayarlar_bitis")
	var clock_before := save.clock_s
	if ending != null:
		await _tap_control(ending)
	_check("BİTİŞ: film baştan, sandal X'te (Bekçi onun çevresinde döner)", await _wait_until(func() -> bool:
			return story.visible and story.lines() == Story.ENDING, 5.0) and bool(main.get("in_boat"))
			and int(main.get("_buoy")) == Secret.KEEPER_BUOY)
	await _wait(1.0)
	await _tap_control(story.skip_button)
	_check("ATLA: jenerik", await _wait_until(func() -> bool: return credits.visible, 3.0))
	# Jeneriğin ATLA'sı hemen çalışmaz (filmin ATLA'sına çift dokunuş jeneriği atlamasın).
	await _tap_control(credits.skip_button)
	await _wait_frames(3)
	_check("jeneriğin ATLA'sı hemen çalışmaz", credits.visible)
	await _wait(CreditsPanel.SKIP_GUARD + 0.2)
	await _tap_control(credits.skip_button)
	await _wait_until(func() -> bool: return not credits.visible, 3.0)
	await _wait(0.5)
	_check("yeniden izlemek saati değiştirmez; ATLA'dan sonra balıkçı iskelede", save.clock_s == clock_before
			and not bool(main.get("in_boat")))
	# Oyun sonrası: kendiliğinden sisli bir gecede X'te Bekçi yine gelir (filmsiz).
	main.call("_debug_time")
	main.call("_debug_time")
	main.call("_debug_time")
	await _wait(0.5)
	while Weather.day_kind(rules, save, DayClock.day(rules, save.clock_s)) != "fog":
		main.call("_debug_weather")
		await _wait_frames(2)
	await _wait(0.6)
	cond = clock.conditions()
	_check("oyun sonrası sisli gece (%s, %s)" % [str(cond["phase"]), str(cond["weather"])], str(cond["phase"]) == "night"
			and str(cond["weather"]) == "fog")
	main.call("_go_boat", Secret.KEEPER_BUOY)
	await _wait_frames(2)
	await _wait_until(func() -> bool: return not fade.busy(), 4.0)
	await _wait(0.5)
	main.call("_on_technique_selected", "bottom")
	await _wait_frames(4)
	await _tap_world(_session().angler + Vector2(10.0, 0.0))
	await _wait_state(FishingSession.State.WAITING, 4.0)
	_check("oyun sonrası sisli gecede Bekçi yine gelir (Dede: yine göründü)", await _wait_until(func() -> bool:
			return _session().summoned() != null, 6.0) and await _wait_until(func() -> bool:
			return str(main.get("_line")) == "UI_DEDE_KEEPER_AGAIN", 4.0))
	await _shot("11_oyun_sonrasi")
	# Bekçi'nin kartı açıkken uygulama kapandıysa (Bekçi göle döndü, film görülmedi): açılışta bitiş filmi oynar,
	# balıkçı sandalla X'te; ATLA'da da filmin anları olur: iskelede, saat sabah, göl çiçekli, kayıtta.
	var copy := SaveData.from_dict(GameState.save.to_dict())
	copy.flags.erase(Story.ENDING_FLAG)
	copy.clock_s = DayClock.day(rules, copy.clock_s) * DayClock.day_s(rules) + 3 * rules.phase_s + 10
	GameState.use_save(copy)
	await _wait_frames(3)
	_check("Bekçi tutulmuş, film görülmemiş kayıt: açılışta bitiş filmi, sandal X'te", story.visible
			and story.lines() == Story.ENDING and bool(main.get("in_boat")) and int(main.get("_buoy")) == Secret.KEEPER_BUOY)
	await _wait(1.0)
	await _tap_control(story.skip_button)
	await _wait_until(func() -> bool: return credits.visible, 3.0)
	await _wait(0.4)
	var docked_after := not bool(main.get("in_boat")) \
			and _angler().pos2().distance_to(db.spot(str(main.get("spot_id")))["start"]) < 0.5
	_check("ATLA'da da şafak ve çiçek: iskelede, sabah, göl çiçekli, kayıtta", docked_after
			and DayClock.phase(rules, GameState.save.clock_s) == "morning"
			and scene.love_level() == LakeLove.max_level(rules) and GameState.save.flags.has(Story.ENDING_FLAG))
	await _wait(CreditsPanel.SKIP_GUARD + 0.2)
	await _tap_control(credits.skip_button)
	await _wait_until(func() -> bool: return not credits.visible, 3.0)
	_finish_checks()


## Bekçi'ye dip atışı (sandal X'te, gece sisli): doğuya atar, Bekçi belirir, koklar; ilk koklamada dokunur (bağışlanır),
## koşuda VUR; snap ise ilk dalışta basılı tutar (misina kopar), değilse oyuncu gibi çeker (uyarıda bırakır).
func _keeper_cast(snap: bool) -> Dictionary:
	var out := { "rose": false, "toast": false, "dede": false, "back": false, "music": false, "draws": 0, "sniffed": false,
			"forgiven": false, "hooked": false, "dives": false, "snapped": false, "dive_hint": false, "dive_count": 0,
			"fight_draws": 0, "caught": false, "in_hand": false }
	var finger := Vector2(260, 520)
	await _tap_world(_session().angler + Vector2(10.0, 0.0))
	if not await _wait_state(FishingSession.State.WAITING, 4.0):
		return out
	out["rose"] = await _wait_until(func() -> bool: return _session().summoned() != null, KeeperPresenter.RISE_DELAY + 3.0)
	out["toast"] = await _wait_toast(UiKit.upper(tr("UI_KEEPER_RISE")), 2.0)
	out["dede"] = await _wait_until(func() -> bool: return str(main.get("_line")) == "UI_DEDE_KEEPER_RISE", 2.0)
	out["back"] = str(main.get("_line")) == "UI_DEDE_KEEPER_BACK"
	out["music"] = await _wait_until(func() -> bool: return Sounds.music_name() == "keeper", 3.0)
	await _wait(1.2)
	await _shot_once("03_bekci_geldi")
	# Sınır kalıcı görünüşe bakar: geçici yazılar (bildirim, Dede'nin sözü) sönünce (öteki botlar gibi).
	var toast: Control = _hud().get("_toast")
	var hint: Control = _hud().get("_hint")
	await _wait_until(func() -> bool: return not toast.is_visible_in_tree() and not hint.visible, 6.0)
	out["draws"] = int((await _measure_draws(20))["draws"])
	if not await _wait_state(FishingSession.State.NIBBLING, 30.0):
		return out
	out["sniffed"] = _session().sim.approacher == _session().summoned()
	await _tap(finger)
	await _wait_frames(3)
	out["forgiven"] = _state() == FishingSession.State.NIBBLING and _session().sim.approacher != null \
			and _session().sim.approacher.summoned
	if not await _wait_state(FishingSession.State.BITING, 20.0):
		return out
	await _wait_frames(6)
	_touch(1, finger, true)
	await _wait_frames(3)
	out["hooked"] = _state() == FishingSession.State.FIGHTING
	out["dives"] = _session().reel != null and _session().reel.has_dives()
	if not bool(out["hooked"]):
		_touch(1, finger, false)
		return out
	var hold := true
	var lag := 0
	var elapsed := 0.0
	var was_diving := false
	while _state() == FishingSession.State.FIGHTING and elapsed < 120.0:
		var reel := _session().reel
		var diving := reel != null and reel.phase == ReelModel.Phase.DIVE
		if diving and not was_diving:
			out["dive_count"] = int(out["dive_count"]) + 1
			if not snap:
				await _shot_once("04_bekci_daliyor")
				out["fight_draws"] = maxi(int(out["fight_draws"]), int((await _measure_draws(5))["draws"]))
		was_diving = diving
		if reel != null and reel.diving() and str(main.get("_hint_shown")) == "UI_HINT_KEEPER_DIVE":
			out["dive_hint"] = true
		# Oyuncu gibi: çırpınma ya da dalış uyarısında 6 kare sonra bırakır; snap'te dalışta basılı tutar.
		var want := reel != null and (not reel.thrashing() or (snap and reel.diving()))
		lag = lag + 1 if want != hold else 0
		if lag >= 6:
			hold = want
			lag = 0
			_touch(1, finger, hold)
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	if hold:
		_touch(1, finger, false)
	out["snapped"] = _state() == FishingSession.State.LOST and _session().last_loss == "snapped"
	out["caught"] = _state() == FishingSession.State.CAUGHT and bool(_session().last_catch.get("story", false))
	await _wait_frames(4)
	out["in_hand"] = (main.get("catch_fx") as CatchFx).is_showing()
	return out


## Bir düğümün altında yazısı bu olan etiket (yoksa null).
static func _label_with_text(root: Node, text: String) -> Label:
	for node in root.find_children("*", "Label", true, false):
		if (node as Label).text == text:
			return node as Label
	return null


## Düğme ekranın güvenli alanının içinde mi?
func _inside_safe(control: Control) -> bool:
	var view := get_viewport().get_visible_rect()
	var inset := UiKit.safe_insets(control)
	var safe := Rect2(view.position + Vector2(inset.x, inset.y), view.size - Vector2(inset.x + inset.z, inset.y + inset.w))
	return safe.encloses(control.get_global_rect())


## İskelede şamandırayla bir balık tutar: gölgeyi koyar, atar, VUR, oyuncu gibi çeker; kart açılırsa kapatır,
## olta boşa dönene kadar bekler. Tutulduysa true.
func _catch_at_dock(fish_id: String, percentile: int = -1) -> bool:
	await _wait_state(FishingSession.State.IDLE, 4.0)
	_shadow_at(Vector2(1.0, -3.2), Vector2(0, 1), fish_id, percentile)
	await _tap_world(Vector2(1.0, -1.0))
	if not await _wait_state(FishingSession.State.BITING, 25.0):
		return false
	await _reel_like_player(6, 40.0)
	var caught := _state() == FishingSession.State.CAUGHT and str(_session().last_catch.get("fish", "")) == fish_id
	var card: FishCard = main.get("card")
	await _wait(FishCard.MIN_OPEN)
	if card.visible or float(main.get("_card_wait")) >= 0.0:
		await _close_card(card)
	await _wait_state(FishingSession.State.IDLE, 6.0)
	return caught


## Tut-bırak ve göl sevgisi (Dalga 4, 3. adım; KONTROL satırları; telefon oranında ve --safe-inset=130 ile,
## TR ve EN): kova dolu (10'luk kova, 7 tür; eylem düğmesi SAT). Kovaya dokun → Kova paneli küçülmeden
## sığar (6 satır, nadirden sıradana, sayfa düğmesi: 7. tür ikinci sayfada, panelin boyu aynı); BIRAK → türün
## en küçüğü göle döner (sevgi +1, para aynı, defterde ve sayaçta bırakılan); HEPSİNİ BIRAK önce "Emin misin?"
## (süre geçince eski yazı), hızlı çift dokunuş saymaz, biraz sonraki ikinci dokunuşla kova boşalır; panel
## kapanınca "Göl sevgisi 2!" (kalp) ve Dede'nin sözü, SAT gider. Yeni tür kartında "Göle bırak" (büyük): balık
## kovadan çıkar, bildirim. Kartsız kısa yakalamada (balık elde) kovaya dokunmak paneli açar (olta boşa döner,
## atış saklanmaz). Olta sudayken kovaya dokunmak oyuna geçer (geri sarar). Dipte balığın yanında çöp (eski çizme: resmiyle bildirim, sevgi, kovaya girmez; Dede'nin
## ilk sözü). Göl güzelleşir: sevgi 3'te daha çok bitki ve gündüz kelebekler, en yüksek sevgide çizim sınırı
## (ekran görüntüleri: seviye 1 ve 10). Paneldeki SAT Nine'nin Kova sekmesine götürür. Düğmeler büyük ve
## güvenli alanda.
func _play_release() -> void:
	_use_save(3)
	var db := GameState.db
	var rules := db.rules
	var save := GameState.save
	var hud := _hud()
	var panel: BucketPanel = main.get("bucket_panel")
	var toast: Label = hud.get("_toast")
	save.owned.append("bucket_big")
	var fill := [["rudd", 16], ["rudd", 22], ["rudd", 19], ["silverside", 10], ["silverside", 14],
			["perch", 30], ["carp", 50], ["pike", 80], ["chub", 30], ["tench", 35]]
	for f: Array in fill:
		Records.add(save.records, str(f[0]), int(f[1]), 1, 0)
		Bucket.add(db, save, str(f[0]), int(f[1]), 1)
	save.love = rules.love_levels[1] - 1
	GameState.changed.emit()
	await _wait(1.0)
	var scene: LakeScene = main.get("scene")
	var plants_1 := scene.plants_triangles()
	await _shot("00_sevgi_1")
	var cap := Bucket.capacity(db, save)
	_check("kova dolu (%d/%d): eylem düğmesi SAT" % [save.bucket.size(), cap],
			save.bucket.size() == cap and str(main.call("_action_kind")) == "sell")
	var pill := (hud.get("_bucket") as Control).get_parent().get_parent() as Control
	var box := hud.bucket_button.hit_rect()
	_check("kovanın dokunma kutusu hapı kapsar, saat çipine binmez (%s, hap %s)" % [box, pill.get_global_rect()],
			box.encloses(pill.get_global_rect()) and not box.intersects(hud.world_button.hit_rect()))
	# 1) Kovaya dokun: panel açılır, telefonda küçülmeden sığar; 6 satır ve "+1 tür daha".
	await _tap_control(hud.bucket_button)
	await _wait_until(func() -> bool: return panel.visible, 2.0)
	await _wait(0.4)
	var rows := panel.find_children("Row_*", "PanelContainer", true, false)
	var wide := PackedStringArray()
	for row: Control in rows:
		var need := row.get_combined_minimum_size()
		if need.x > BucketPanel.ROW.x + 0.5 or need.y > BucketPanel.ROW.y + 0.5:
			wide.append("%s %.0f×%.0f" % [row.name, need.x, need.y])
	var text := _texts_in(panel)
	_check("kovaya dokun → Kova paneli küçülmeden sığar (%.3f, %s)" % [panel.fit_scale(), panel.panel_rect()],
			panel.visible and panel.fit_scale() >= 0.999 and _panel_inside(panel))
	var page_button := panel.find_child("Page", true, false) as Button
	var page_text := UiKit.upper(tr("UI_BUCKET_PAGE") % [1, 2])
	_check("panelde 6 satır, sayfa düğmesi \"%s\", %d/%d, satırlar sığar%s" % [page_text, cap, cap,
			"" if wide.is_empty() else ": " + ", ".join(wide)], rows.size() == BucketPanel.ROWS
			and page_button != null and page_button.text == page_text and text.contains("%d/%d" % [cap, cap])
			and wide.is_empty() and str(BucketPanel.rows_of(db, save)[0]["fish"]) == "pike")
	await _shot("01_kova_paneli")
	# 1b) Sayfa düğmesi: 7. tür ikinci sayfada (kendi BIRAK'ıyla), panelin boyu aynı; yine dokununca ilk sayfa.
	var size_1 := panel.panel_rect().size
	var seventh := str(BucketPanel.rows_of(db, save)[BucketPanel.ROWS]["fish"])
	if page_button != null:
		await _tap_control(page_button)
	await _wait_frames(3)
	var second := panel.find_children("Row_*", "PanelContainer", true, false).size() == 1 \
			and panel.find_child("Release_" + seventh, true, false) != null
	var size_2 := panel.panel_rect().size
	await _shot("01b_kova_sayfa_2")
	var back := panel.find_child("Page", true, false) as Button
	if back != null:
		await _tap_control(back)
	await _wait_frames(3)
	_check("sayfa düğmesi: 2. sayfada %s (BIRAK'ıyla), panelin boyu aynı (%s, %s), yine dokununca ilk sayfa" % [
			seventh, size_1, size_2], second and size_1.is_equal_approx(size_2)
			and panel.find_children("Row_*", "PanelContainer", true, false).size() == BucketPanel.ROWS)
	# 2) BIRAK: kızılkanatın en küçüğü (16 cm) göle döner; sevgi +1 (seviye 2), para aynı.
	var coins := save.coins
	var love := save.love
	# Panel yenilenince satırlar (düğmeler de) yeniden kurulur: düğme dokunmadan önce aranır.
	var release := panel.find_child("Release_rudd", true, false) as Button
	var found := release != null
	if found:
		await _tap_control(release)
	await _wait_frames(2)
	var sizes := PackedInt32Array()
	for entry: Dictionary in save.bucket:
		if str(entry["fish"]) == "rudd":
			sizes.append(int(entry["size_cm"]))
	_check("BIRAK → en küçük kızılkanat göle döner (kalan %s), sevgi +1, para aynı, defterde bırakılan" % str(sizes),
			found and sizes.size() == 2 and not 16 in sizes and save.love == love + 1 and save.coins == coins
			and int((save.records["rudd"] as Dictionary).get("released", 0)) == 1
			and int(save.stats.get("released", 0)) == 1 and LakeLove.level(rules, save.love) == 2
			and _texts_in(panel).contains("%d/%d" % [cap - 1, cap]))
	# 3) HEPSİNİ BIRAK: ilk dokunuş sorar (kova aynı), süre geçince eski yazı; hızlı çift dokunuş saymaz
	# (SURE_GUARD), biraz sonraki ikinci dokunuşla kova boşalır.
	var all := panel.find_child("ReleaseAll", true, false) as Button
	var before := save.bucket.size()
	var expect := save.love
	for entry: Dictionary in save.bucket:
		expect += int(db.rarity_def(int(db.fish_by_id(str(entry["fish"])).get("rarity", 0))).get("love", 0))
	if all != null:
		await _tap_control(all)
	var asked := all != null and all.text == UiKit.upper(tr("UI_BUCKET_SURE")) and save.bucket.size() == before
	await _shot("02_emin_misin")
	await _wait(BucketPanel.SURE_TIME + 0.3)
	_check("HEPSİNİ BIRAK önce sorar, süre geçince eski yazı (\"%s\")" % (all.text if all != null else ""),
			asked and all.text == UiKit.upper(tr("UI_BUCKET_RELEASE_ALL")) and save.bucket.size() == before)
	if all != null:
		await _tap_control(all)
		await _tap_control(all)
	await _wait_frames(2)
	var guarded := all != null and all.text == UiKit.upper(tr("UI_BUCKET_SURE")) and save.bucket.size() == before
	await _wait(BucketPanel.SURE_GUARD + 0.1)
	if all != null:
		await _tap_control(all)
	await _wait_frames(2)
	_check("hızlı çift dokunuş bırakmaz; biraz sonraki dokunuşla kova boşalır: sevgi %d → %d (beklenen %d), para aynı, " \
			% [love + 1, save.love, expect] + "panelde \"%s\"" % tr("UI_BUCKET_EMPTY"), guarded and save.bucket.is_empty()
			and save.love == expect and save.coins == coins
			and int(save.stats.get("released", 0)) == fill.size() and _texts_in(panel).contains(tr("UI_BUCKET_EMPTY"))
			and panel.find_child("ReleaseAll", true, false) == null)
	await _shot("03_kova_bos")
	# 4) Panel kapanınca: "Göl sevgisi 2!" (kalp ikonu), Dede'nin sözü; kova dolu değil, SAT gider.
	await _tap_control(panel.close_button)
	var up := UiKit.upper(tr("UI_LOVE_UP") % 2)
	var shown := await _wait_until(func() -> bool: return toast.is_visible_in_tree() and toast.text == up, 3.0)
	var icon: GameIcon = hud.get("_toast_icon")
	_check("panel kapanınca \"%s\" bildirimi (kalp)" % up, shown and icon.visible and icon.kind == "love")
	var told := await _wait_until(func() -> bool: return str(main.get("_hint_shown")) == "UI_DEDE_LOVE_2", 4.0)
	_check("Dede göl sevgisini söyler (%s), eylem düğmesi artık AT" % main.get("_hint_shown"),
			told and str(main.call("_action_kind")) != "sell")
	await _shot("04_sevgi_2")
	# 5) Yeni tür kartında "Göle bırak": çapak kovaya girer, kartın ikinci düğmesiyle göle döner.
	await _wait_state(FishingSession.State.IDLE, 2.0)
	var card: FishCard = main.get("card")
	love = save.love
	_shadow_at(Vector2(1.0, -3.2), Vector2(0, 1), "bream")
	await _tap_world(Vector2(1.0, -1.0))
	await _wait_state(FishingSession.State.BITING, 20.0)
	_touch(1, Vector2(260, 520), true)
	await _wait_state(FishingSession.State.CAUGHT, 25.0)
	_touch(1, Vector2(260, 520), false)
	await _wait_until(func() -> bool: return card.visible, 3.0)
	await _wait(FishCard.MIN_OPEN)
	var side := 0.0
	if card.visible and card.release_button != null:
		var r := card.release_button.get_global_rect()
		side = minf(r.size.x, r.size.y)
	var kept := save.bucket.size() == 1 and str(save.bucket[0]["fish"]) == "bream"
	_check("yeni tür kartında \"%s\" (%.0f birim), balık kovada" % [tr("UI_CARD_RELEASE"), side],
			card.visible and side >= 121.5 and kept)
	await _shot("05_kart_birak")
	if card.visible and card.release_button != null:
		await _tap_control(card.release_button)
	var freed := UiKit.upper(tr("UI_RELEASED") % tr("FISH_bream"))
	var said := await _wait_until(func() -> bool: return toast.is_visible_in_tree() and toast.text == freed, 3.0)
	_check("\"Göle bırak\" → kart kapanır, çapak göle döner (sevgi +1), \"%s\"" % freed,
			not card.visible and save.bucket.is_empty() and save.love == love + 1 and said
			and int((save.records["bream"] as Dictionary).get("released", 0)) == 1)
	await _shot("06_birakildi")
	# 5b) Kartsız kısa yakalama (bilinen tür, rekor değil): balık eldeyken kovaya dokun → panel hemen açılır, olta
	# boşa döner, dokunuş atış olarak saklanmaz.
	await _wait_state(FishingSession.State.IDLE, 3.0)
	_shadow_at(Vector2(1.0, -3.2), Vector2(0, 1), "rudd", 5)
	await _tap_world(Vector2(1.0, -1.0))
	await _wait_state(FishingSession.State.BITING, 20.0)
	_touch(1, Vector2(260, 520), true)
	await _wait_state(FishingSession.State.CAUGHT, 25.0)
	_touch(1, Vector2(260, 520), false)
	await _wait_frames(3)
	var quick := float(main.get("_quick_catch")) >= 0.0 and not card.visible and _state() == FishingSession.State.CAUGHT
	await _tap_control(hud.bucket_button)
	var opened := await _wait_until(func() -> bool: return panel.visible, 1.0)
	_check("kartsız kısa yakalamada kovaya dokun → Kova paneli hemen, olta boşta, atış saklanmadı",
			quick and opened and _state() == FishingSession.State.IDLE and not Dice.is_point(main.get("_pending_cast")))
	if panel.visible:
		await _tap_control(panel.close_button)
	# 6) Saat çipinin hemen altındaki suya dokunmak oyuna geçer (atış ya da suya yürüyüş): "Bugün" paneli
	# açılmaz (dokunma kutusu aşağıya taşmaz; sinekte dere ağzının yukarısı oradaydı). Olta sudayken kovaya
	# dokunmak da oyuna geçer: panel açılmaz, olta geri sarılır.
	await _wait_state(FishingSession.State.IDLE, 3.0)
	var day_panel: DayPanel = main.get("day_panel")
	var chip_box := hud.world_button.hit_rect()
	var below := Vector2(chip_box.get_center().x, chip_box.end.y + 12.0)
	await _tap(below)
	await _wait_frames(2)
	var played := _state() != FishingSession.State.IDLE or _angler().is_walking()
	_check("saat çipinin hemen altındaki suya dokun → panel açılmaz, oyuna geçer (%s, kutu %s)" % [below, chip_box],
			not day_panel.visible and played)
	if _state() == FishingSession.State.CASTING or _state() == FishingSession.State.WAITING:
		await _wait_state(FishingSession.State.WAITING, 3.0)
		await _tap(Vector2(400, 380))
	await _wait_until(func() -> bool: return _state() == FishingSession.State.IDLE and not _angler().is_walking(), 8.0)
	if _angler().pos2().distance_to(Vector2(0.0, 4.0)) > 0.3:
		_angler().place(Vector2(0.0, 4.0))
		_angler().face_now(Vector2(0.0, -1.0))
		(main.get("camera") as FollowCamera).snap(main.call("_focus"))
		await _wait_frames(4)
	await _tap_world(Vector2(0.0, 0.0))
	await _wait_state(FishingSession.State.WAITING, 3.0)
	await _tap_control(hud.bucket_button)
	_check("olta sudayken kovaya dokun → panel yok, geri sarar", not panel.visible
			and _state() == FishingSession.State.RETRIEVING)
	await _wait_state(FishingSession.State.IDLE, 3.0)
	# 7) Dipte çöp: dip kamışıyla tutulan sazanın yanında eski çizme (gölgenin seed'i çöp zarını tutar);
	# eşyanın resmiyle bildirim, sevgi +3, sayaç, kovaya girmez; Dede'nin ilk sözü.
	save.xp = maxi(save.xp, db.rank_xp[3])
	if not "rod_carp_1" in save.owned:
		save.owned.append("rod_carp_1")
	save.technique = "bottom"
	GameState.changed.emit()
	main.call("_on_gear_changed")
	await _wait(1.0)
	var boot_seed := 0
	while Trash.with_catch(rules, boot_seed, "bottom") != "boot":
		boot_seed += 1
	_shadow_seed = boot_seed
	love = save.love
	var bottom := await _bottom_cast(true)
	_shadow_seed = -1
	var boot_text := UiKit.upper(tr("UI_TRASH_FOUND") % [tr("ITEM_boot"), Trash.love_of(rules, "boot")])
	var popped := await _wait_until(func() -> bool: return toast.is_visible_in_tree() and toast.text == boot_text, 8.0)
	var boots := 0
	for entry: Dictionary in save.bucket:
		if str(entry["fish"]) == "boot":
			boots += 1
	_check("dipte balığın yanında eski çizme: \"%s\" (resmiyle), sevgi +%d, kovaya girmez" % [boot_text,
			Trash.love_of(rules, "boot")], bool(bottom["caught"]) and popped and icon.kind == "item:boot"
			and save.love == love + Trash.love_of(rules, "boot") and Trash.found(save, "boot") == 1 and boots == 0)
	await _shot("07_cop")
	var talked := await _wait_until(func() -> bool: return str(main.get("_hint_shown")) == "UI_DEDE_TRASH_boot", 12.0)
	_check("Dede çizmeyi söyler (%s)" % main.get("_hint_shown"), talked)
	await _shot("08_dede_cop")
	await _wait_state(FishingSession.State.IDLE, 4.0)
	# 7b) Göl güzelleşir: sevgi 3'te bitkiler arttı (yine tek ağ), gündüz kelebekler; en yüksek sevgide daha da
	# çiçekli göl ve berrak su, iskelede çizim sınırı.
	var ambient: AmbientParticles = main.get("ambient")
	_check("göl sevgisi 3: bitkiler arttı (%d → %d üçgen), gündüz kelebekler (%s)" % [plants_1, scene.plants_triangles(),
			ambient.kind], scene.love_level() == 3 and scene.plants_triangles() > plants_1 and ambient.kind == "butterflies")
	var old_level := LakeLove.level(rules, save.love)
	save.love = rules.love_levels[rules.love_levels.size() - 1]
	main.call("_after_love", { "old_level": old_level, "new_level": LakeLove.level(rules, save.love) })
	await _wait(1.5)
	var busy_draws := int((await _measure_draws())["draws"])
	# Geçici yazılar (bildirim, Dede'nin sözleri) sönünce ölçülür (gezi botu gibi).
	var hint: Control = hud.get("_hint")
	await _wait_until(func() -> bool: return not toast.is_visible_in_tree() and not hint.visible, 25.0)
	await _wait(0.5)
	var love_draws := int((await _measure_draws())["draws"])
	print("ÇİZİM sevgi 10: yazılarla %d, yazısız %d" % [busy_draws, love_draws])
	_check("en yüksek sevgide (seviye %d, %d üçgen bitki) iskelede en çok %d çizim (%d)" % [scene.love_level(),
			scene.plants_triangles(), TOUR_DRAWS, love_draws], scene.love_level() == LakeLove.max_level(rules)
			and love_draws > 0 and love_draws <= TOUR_DRAWS)
	await _shot("08c_sevgi_10")
	# 8) Paneldeki SAT: Nine'nin tezgâhı, dükkân Kova sekmesinde.
	for cm in [18, 21, 24]:
		Records.add(save.records, "rudd", cm, 1, 0)
		Bucket.add(db, save, "rudd", cm, 1)
	GameState.changed.emit()
	await _wait_frames(2)
	await _tap_control(hud.bucket_button)
	await _wait_until(func() -> bool: return panel.visible, 2.0)
	await _wait(0.3)
	var shop: ShopPanel = main.get("shop_panel")
	var sell := panel.find_child("Sell", true, false) as Button
	if sell != null:
		await _tap_control(sell)
	var at_shop := await _wait_until(func() -> bool: return shop.visible, 6.0)
	_check("paneldeki SAT → Nine'nin dükkânı Kova sekmesinde (%s)" % shop.current_tab(),
			sell != null and at_shop and not panel.visible and shop.current_tab() == "sell")
	await _wait(0.4)
	await _shot("09_sat")
	shop.close_panel()
	await _wait(0.4)
	_check_buttons()
	_finish_checks()


## Kamışlar ve makaralar (görsel denetim; KONTROL satırları): dükkândaki kamışlar teknik teknik yan yana
## ve adlarıyla, suyun üstünde kameraya dönük (kuşanılan görünüş RodModel.LOOKS); makaralar yakından
## (çıkrık ve sinek makarası); sonra balıkçının elinde kuşanılan kamış ve dipte sehpadaki dip kamışı.
func _play_rods() -> void:
	_use_save(5)
	await _wait(1.0)
	var db := GameState.db
	var save := GameState.save
	var cam: FollowCamera = main.get("camera")
	main.set("bot_camera", true)
	_hide_fingers = true
	var pitch := deg_to_rad(16.0)
	var back := Vector3(sin(FollowCamera.YAW) * cos(pitch), sin(pitch), cos(FollowCamera.YAW) * cos(pitch))
	var right := Vector3(cos(FollowCamera.YAW), 0.0, -sin(FollowCamera.YAW))
	var up := back.cross(right).normalized()
	var center := Vector3(3.0, 1.6, -1.0)
	var groups := [["float", "spin"], ["bottom", "fly"]]
	var index := 1
	for pair: Array in groups:
		var shelf := Node3D.new()
		main.add_child(shelf)
		var ids: Array[String] = []
		for t: String in pair:
			for g in db.rods_of(t):
				ids.append(str(g["id"]))
		for i in ids.size():
			var id := ids[i]
			var look: Dictionary = RodModel.LOOKS[id]
			# Dükkândaki resimler gibi çapraz: kamışlar alt alta, ortaları aynı çizgide.
			var dir := (right * cos(deg_to_rad(28.0)) + up * sin(deg_to_rad(28.0))).normalized()
			var at := center + up * (0.95 - 0.38 * i) - dir * (float(look["length"]) * 0.5)
			_rod_on_shelf(shelf, str(look["technique"]), id, "reel_basic", at, dir, back, "GEAR_" + id)
		cam.pitch = pitch
		cam.zoom = 0.42
		cam.snap(center + right * 0.2 - up * 0.4)
		await _wait_frames(4)
		await _shot("%02d_kamislar_%s" % [index, "_".join(pair)])
		index += 1
		shelf.queue_free()
		await _wait_frames(2)
	# Makaralar yakından: her makara bir spin kamışında (çıkrık), iki sinek kamışında (sinek makarası).
	# Kamışlar kameradan uzağa uzanır: makaralar önde, yan yana.
	var reels := Node3D.new()
	main.add_child(reels)
	var reel_ids: Array[String] = []
	for g in db.gear_in("reel"):
		reel_ids.append(str(g["id"]))
	var away := (-back * cos(deg_to_rad(25.0)) + up * sin(deg_to_rad(25.0))).normalized()
	for i in reel_ids.size():
		var at := center + right * (-1.05 + 0.42 * i) + up * 0.12
		_rod_on_shelf(reels, "spin", "rod_spin_medium", reel_ids[i], at, away, right, "GEAR_" + reel_ids[i], true)
	var side := (right * cos(deg_to_rad(15.0)) + up * sin(deg_to_rad(15.0))).normalized()
	for i in 2:
		var at := center + right * (-0.75 + 0.75 * i) - up * 0.34
		var fly_reel: String = ["reel_smooth", "reel_master"][i]
		_rod_on_shelf(reels, "fly", ["rod_fly_1", "rod_fly_3"][i], fly_reel, at, side, back, "GEAR_" + fly_reel, true)
	cam.zoom = 0.21
	cam.snap(center - up * 0.08)
	await _wait_frames(4)
	await _shot("%02d_makaralar" % index)
	index += 1
	reels.queue_free()
	# Balıkçının elinde kuşanılan kamış ve makara: karbon kamış, altın makara.
	main.set("bot_camera", false)
	_hide_fingers = false
	for id: String in ["rod_float_carbon", "reel_master"]:
		save.owned.append(id)
		Economy.equip(db, save, id)
	main.call("_on_gear_changed")
	await _wait_frames(3)
	var rod: RodModel = _angler().rod
	_check("elde kuşanılan kamış ve makara (%s, %s)" % [rod.gear_id, rod.reel_id],
			rod.gear_id == "rod_float_carbon" and rod.reel_id == "reel_master" and rod.style == "float")
	main.set("bot_camera", true)
	_frame_on(_angler().global_position + Vector3(0.0, 1.0, 0.0), 0.3, deg_to_rad(35.0))
	await _wait_frames(4)
	await _shot("%02d_elde_karbon" % index)
	index += 1
	main.set("bot_camera", false)
	# Dip: üçüncü dip kamışı kuşanılır, sehpadaki kamış o olur (zil ucunda).
	save.xp = maxi(save.xp, db.rank_xp[9])
	for id: String in ["rod_carp_3"]:
		save.owned.append(id)
		Economy.equip(db, save, id, "bottom")
	save.technique = "bottom"
	main.call("_use_technique_gear")
	GameState.changed.emit()
	await _wait_frames(3)
	var stand: RodStand = main.get("stand")
	_check("dipte elde ve sehpada kuşanılan dip kamışı (%s, %s)" % [_angler().rod.gear_id, stand.rod.gear_id],
			_angler().rod.gear_id == "rod_carp_3" and stand.rod.gear_id == "rod_carp_3"
			and stand.find_child("Bell", true, false).get_parent() == stand.rod.tip)
	stand.place(_angler().global_position, _angler().facing, func(_p: Vector2) -> bool: return true)
	stand.show_stand(true)
	main.set("bot_camera", true)
	_frame_on(stand.global_position + Vector3(0.0, 0.45, 0.0), 0.32, deg_to_rad(40.0))
	await _wait_frames(4)
	await _shot("%02d_sehpa_karbon" % index)
	stand.show_stand(false)
	main.set("bot_camera", false)
	var draws := await _measure_draws()
	print("ÇİZİM iskelede %d çizim (kamış 4 ağ)" % int(draws["draws"]))
	for line in _results:
		print("KONTROL ", line)
	_quit()


## Rafta bir kamış: tekniği, kimliği ve makarası; at kökü, dir ucunun yönü, toward kameraya dönük yan
## (sinek makarasının yüzü kameraya bakar). Yanında label anahtarının yazısı.
func _rod_on_shelf(parent: Node3D, technique: String, id: String, reel_id: String, at: Vector3, dir: Vector3,
		toward: Vector3, label_key: String, close: bool = false) -> void:
	var rod := RodModel.new()
	rod.style = technique
	rod.gear_id = id
	rod.reel_id = reel_id
	parent.add_child(rod)
	var z := -dir
	var x := (toward - z * toward.dot(z)).normalized()
	rod.global_transform = Transform3D(Basis(x, z.cross(x), z), at)
	var label := Label3D.new()
	label.text = tr(label_key)
	label.font_size = 36
	# Makara yakın çekiminde yazı küçük ve makaranın altında.
	label.pixel_size = 0.0011 if close else 0.0028
	label.outline_size = 10
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.no_depth_test = true
	parent.add_child(label)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if close else HORIZONTAL_ALIGNMENT_RIGHT
	label.global_position = at - Vector3(0.0, 0.14, 0.0) if close else at - dir * 0.12 - Vector3(0.0, 0.1, 0.0)


## "Nasıl oynanır?" rehberi: ayarlardan girilir, İLERİ ile baştan sona okunur (KONTROL satırları;
## senaryonun anlatımı dosyanın başında).
func _play_guide() -> void:
	_use_save(3)
	var db := GameState.db
	var save := GameState.save
	# Rütbe 3: spin ve tuzak açık; dip, sinek, kayalık burun ve derin orta kilitli.
	save.xp = db.rank_xp[2]
	GameState.changed.emit()
	await _wait(1.0)
	var hud := _hud()
	var settings: SettingsPanel = main.get("settings_panel")
	var guide: GuidePanel = main.get("guide_panel")
	await _tap_control(hud.settings_button)
	await _wait_until(func() -> bool: return settings.visible, 2.0)
	await _wait(0.4)
	_check("ayarlar \"Nasıl oynanır?\" düğmesiyle küçülmeden sığar (%.2f)" % settings.fit_scale(), settings.fit_scale() > 0.999)
	var open := settings.find_child("Guide", true, false) as Button
	_check("ayarlarda \"Nasıl oynanır?\" düğmesi", open != null and open.text == UiKit.upper(tr("UI_GUIDE_OPEN")))
	_check_panel_buttons(settings, "ayarların düğmeleri")
	await _shot("00_ayarlar")
	if open == null:
		_finish_checks()
		return
	await _tap_control(open)
	await _wait_until(func() -> bool: return guide.visible, 2.0)
	await _wait(0.5)
	_check("\"Nasıl oynanır?\" → rehber ilk sayfada, ayarların üstünde", guide.visible and settings.visible
			and guide.current_page() == "basics" and guide.get_index() > settings.get_index())
	var panel: Control = guide.get("_panel")
	var size := panel.size
	var next := guide.find_child("Next", true, false) as Button
	for i in GuidePages.PAGES.size():
		var id := str(GuidePages.PAGES[i]["id"])
		if i > 0:
			await _tap_control(next)
			await _wait_frames(3)
		await _wait(0.15)
		_check("%d. sayfa (%s): İLERİ ile gelir, küçülmeden sığar (%.2f), boy aynı" % [i + 1, id, guide.fit_scale()],
				guide.current_page() == id and guide.fit_scale() > 0.999 and panel.size.is_equal_approx(size))
		_check_panel_buttons(guide, "%s sayfasının düğmeleri" % id)
		_check_guide_tiles(guide, id)
		await _shot("%02d_%s" % [i + 1, id])
	_check("son sayfada İLERİ pasif", next.disabled)
	await _tap_control(guide.find_child("Page_techniques", true, false) as Control)
	await _wait_frames(3)
	_check("sekmeye dokun → Teknikler", guide.current_page() == "techniques")
	_check("rütbe 3: dip ve sinek kilitli (rütbe hapı), spin ve tuzak açık", _guide_locked(guide, "bottom")
			and _guide_locked(guide, "fly") and not _guide_locked(guide, "spin") and not _guide_locked(guide, "trap"))
	await _tap_control(guide.find_child("Page_zones", true, false) as Control)
	await _wait_frames(3)
	_check("rütbe 3: nilüferli koy açık, kayalık burun ve derin orta kilitli", not _guide_locked(guide, "lily_cove")
			and _guide_locked(guide, "rocky_point") and _guide_locked(guide, "deep_water"))
	await _tap_control(guide.close_button)
	await _wait_frames(3)
	_check("rehber kapanınca ayarlar açık", not guide.visible and settings.visible)
	settings.close_panel()
	await _wait(0.4)
	# Sazlığa geç: Nine uzakta kalsın (çantadan açılan dükkân uzaktan açılır).
	await _guide_travel("reeds")
	# Takım Çantası: "?" → Teknikler; rehber kapanınca çanta açık.
	var bag: TechniquePanel = main.get("technique_panel")
	await _tap_control(hud.technique_button)
	await _wait_until(func() -> bool: return bag.visible, 2.0)
	await _wait(0.4)
	var bag_panel: Control = bag.get("_panel")
	_check("çanta \"?\" ile küçülmeden sığar (%.3f, %s)" % [bag.fit_scale(), str(bag_panel.get_combined_minimum_size())],
			bag.visible and bag.fit_scale() > 0.999)
	_check_panel_buttons(bag, "çantanın düğmeleri")
	var bag_help := bag.find_child("Help", true, false) as Control
	if bag_help != null:
		await _tap_control(bag_help)
		await _wait_until(func() -> bool: return guide.visible, 2.0)
		await _wait(0.4)
	_check("çantada \"?\" → rehber Teknikler sayfasında, çantanın üstünde", bag_help != null and guide.visible
			and bag.visible and guide.current_page() == "techniques")
	await _shot("10_canta_rehber")
	await _tap_control(guide.close_button)
	await _wait_frames(3)
	_check("rehber kapanınca çanta açık", not guide.visible and bag.visible)
	await _shot("11_canta")
	# Uzaktan açılan dükkân (çantada spin "Nine'de"): "?" → Kamış sayfası; rehber kapanınca dükkân açık,
	# dükkân kapanınca Nine susar (yanında değil).
	var shop: ShopPanel = main.get("shop_panel")
	var line := str(main.get("_line"))
	var spin := bag.find_child("Button_spin", true, false) as Control
	if spin != null:
		await _tap_control(spin)
		await _wait_until(func() -> bool: return shop.visible, 2.0)
		await _wait(0.4)
	_check("çantada spin \"Nine'de\" → uzaktan dükkân, Kamış sekmesi", spin != null and shop.visible and shop.is_remote()
			and shop.current_tab() == "rod")
	await _guide_from_shop(shop, guide, "rod", "rods", line)
	shop.close_panel()
	await _wait_frames(3)
	_check("uzaktan dükkân kapanınca Nine susar", str(main.get("_line")) == line)
	await _wait(0.4)
	await _guide_travel("dock_cove")
	# Tezgâhtaki dükkân: Nine'ye dokun; Kamış, Ekstra ve Kova sekmelerinde "?" o sekmenin sayfası; rehber
	# kapanınca dükkân açık, Nine veda etmez (yalnızca dükkân kapanınca).
	await _tap(_screen(_nine().head_point()))
	await _wait_until(func() -> bool: return shop.visible, 2.0)
	await _wait(0.4)
	_check("dükkân \"?\" ile küçülmeden sığar (%.2f)" % shop.fit_scale(), shop.visible and not shop.is_remote()
			and shop.fit_scale() > 0.999)
	_check_panel_buttons(shop, "dükkânın düğmeleri")
	# En geniş başlık: 6 basamaklı para, teknik düğmeleri ve "?" ile dükkân küçülmeden sığar.
	var coins := save.coins
	save.coins = 999_999
	shop.refresh()
	await _wait_frames(3)
	var header := (shop.get("_icon") as Control).get_parent() as Control
	_check("999.999 parayla başlık sığar (%.0f / %.0f), dükkân küçülmez (%.3f)" % [header.get_combined_minimum_size().x,
			header.size.x, shop.fit_scale()], header.get_combined_minimum_size().x <= header.size.x + 0.5
			and shop.fit_scale() > 0.999)
	await _shot("12_dukkan_para")
	save.coins = coins
	shop.refresh()
	await _wait_frames(2)
	line = str(main.get("_line"))
	for pair: Array in [["rod", "rods"], ["extra", "extras"], ["tackle", "tackle"], ["sell", "loop"]]:
		await _tap_control(shop.find_child("Tab_" + str(pair[0]), true, false) as Control)
		await _wait_frames(3)
		await _guide_from_shop(shop, guide, str(pair[0]), str(pair[1]), line)
	shop.close_panel()
	await _wait_frames(3)
	_check("dükkân kapanınca Nine uğurlar", str(main.get("_line")).begins_with("UI_NINE_LINE_"))
	await _wait(0.4)
	# Dede'nin son genel öğüdü rehberi söyler: Dede'ye dokundukça sıradaki öğüt.
	var last := Elder.TIP_KEY % Elder.TIP_COUNT
	for i in Elder.TIP_COUNT + Elder.TECH_TIPS.size() + 1:
		if str(main.get("_hint_shown")) == last:
			break
		await _tap(_screen(_elder().head_point()))
		await _wait(0.3)
	_check("Dede'nin son öğüdü rehberi söyler", str(main.get("_hint_shown")) == last)
	await _shot("13_dede_rehber")
	_finish_checks()


## Haritadaki gibi bir bölgeye geçer (ekran kararır, balıkçı bölgenin atış noktasında).
func _guide_travel(zone: String) -> void:
	var fade: Fade = main.get("fade")
	main.call("_travel", zone)
	await _wait_until(func() -> bool: return fade.busy(), 1.0)
	var arrived := await _wait_until(func() -> bool: return not fade.busy() and str(main.get("zone_id")) == zone, 5.0)
	_check("%s bölgesine geçilir" % zone, arrived)
	await _wait(0.8)


## Dükkânın açık sekmesinde "?": rehber o sekmenin sayfasında, dükkânın üstünde açılır; kapanınca
## dükkân açık kalır ve Nine veda etmez (main'in sözü line'da kalır).
func _guide_from_shop(shop: ShopPanel, guide: GuidePanel, tab: String, page_id: String, line: String) -> void:
	var help := shop.find_child("Help", true, false) as Control
	if help == null:
		_check("dükkânda \"?\" düğmesi", false)
		return
	await _tap_control(help)
	await _wait_until(func() -> bool: return guide.visible, 2.0)
	await _wait(0.3)
	_check("dükkânda %s sekmesinde \"?\" → rehber %s sayfasında, dükkânın üstünde" % [tab, page_id], guide.visible
			and shop.visible and shop.current_tab() == tab and guide.current_page() == page_id)
	await _shot("12_dukkan_%s%s" % [tab, "_uzak" if shop.is_remote() else ""])
	await _tap_control(guide.close_button)
	await _wait_frames(3)
	_check("rehber kapanınca dükkân açık (%s), Nine veda etmez" % tab, not guide.visible and shop.visible
			and str(main.get("_line")) == line)


## Rehberin açık sayfasındaki karolar: düzenin boyunda; metin kutusuna, başlık ve alttaki satır karoya
## sığar (uzun yazı karoyu büyütmez, taşar: burada yakalanır).
func _check_guide_tiles(guide: GuidePanel, page_id: String) -> void:
	var layout := str(GuidePages.page(page_id)["layout"])
	var want := GuidePages.tile_size(layout)
	var notes := PackedStringArray()
	var tiles := guide.find_children("Tile_*", "PanelContainer", true, false)
	for node in tiles:
		var tile := node as Control
		if not tile.size.is_equal_approx(want):
			notes.append("%s boyu %s" % [tile.name, str(tile.size)])
		var holder := tile.find_child("Text", true, false) as Control
		var text := holder.get_node("Label") as Label if holder != null else null
		if text == null or text.get_combined_minimum_size().y > holder.size.y + 0.5:
			notes.append("%s metni taşıyor" % tile.name)
		var title := tile.find_child("Title", true, false) as Label
		if title != null:
			var font := title.get_theme_font("font")
			var width := font.get_string_size(title.text, HORIZONTAL_ALIGNMENT_LEFT, -1, title.get_theme_font_size("font_size")).x
			if width > title.size.x + 0.5:
				notes.append("%s başlığı kısaldı" % tile.name)
		var footer := tile.find_child("Footer", true, false) as Control
		if footer != null and footer.get_combined_minimum_size().x > footer.size.x + 0.5:
			notes.append("%s alt satırı taşıyor" % tile.name)
	var lead: Label = guide.get("_lead")
	if lead.get_theme_font("font").get_string_size(lead.text, HORIZONTAL_ALIGNMENT_LEFT, -1,
			lead.get_theme_font_size("font_size")).x > lead.size.x + 0.5:
		notes.append("giriş tek satıra sığmıyor")
	_check("%s karoları (%d) sığar%s" % [page_id, tiles.size(), "" if notes.is_empty() else ": " + ", ".join(notes)],
			notes.is_empty() and tiles.size() == GuidePages.tiles_of(GameState.db, page_id).size())


## Rehberde karonun kilit hapı var mı?
static func _guide_locked(guide: GuidePanel, tile_id: String) -> bool:
	var tile := guide.find_child("Tile_" + tile_id, true, false)
	return tile != null and tile.find_child("Lock", true, false) != null


## KONTROL satırlarını yazar ve çıkar.
func _finish_checks() -> void:
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


## Gölün bütün balıkları (18; kerevit, Ay Turnası ve Kocabaş dahil): elde (CatchFx) ve kartı. Görsel denetim; oturum kuralları
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
		# Hikâyenin balığı (Gölün Bekçisi, 5 m) oyunda elde gösterilmez: yalnızca kartı.
		if not bool(def.get("story", false)):
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


## Tanıtım videosu (Dalga 4, v0.5: canlı dünya). Oyun zamanı --fixed-fps ile kare kare akar; bekleyişler oyun
## zamanıyla. Dönen bir oyuncu (rütbe 9, sandal, göl sevgisi 4, Dede'nin istekleri açık): akşam iskelede bir isteği
## bitiren balık (bildirim, Dede'nin aferini); saat çipine dokununca "Bugün" paneli, Dede'yle çay: gece olur; Nine'nin
## feneri (ilk gece), ateşböcekleri ve lambalar, gece balığı; sabah yağmur: damlalar ve halkalar, yağmurda balık;
## sazlıkta suda bir şişe: haritadan oraya, dokununca mektup açılır, Dede yazanı tanır; sisli gece sandalla derin
## ortada: turkuaz dev bir gölge sandalın çevresinde yüzüp dalar ve Dede söyler (Gölün Bekçisi yalnızca sezdirilir:
## karşılaşma yok, gölge yalnızca görünüş).
func _play_video() -> void:
	_use_save(60)
	var db := GameState.db
	var rules := db.rules
	var save := GameState.save
	var spot := str(main.get("spot_id"))
	var hud := _hud()
	var fade: Fade = main.get("fade")
	var day_panel: DayPanel = main.get("day_panel")
	var map_panel: MapPanel = main.get("map_panel")
	var letters: LetterPanel = main.get("letter_panel")
	var bottle: BottleMarker = main.get("bottle")
	_roomy_bucket()
	save.xp = db.rank_xp[8]
	save.love = rules.love_levels[3]
	save.coins = 1200
	for f: Array in [["rudd", 26, 4], ["carp", 52, 3], ["perch", 31, 2], ["silverside", 14, 2], ["bream", 40, 3],
			["tench", 38, 3], ["pike", 80, 3], ["zander", 60, 3], ["chub", 34, 2]]:
		Records.add(save.records, f[0], f[1], f[2], 0)
	for id: String in ["rod_spin_light", "rod_carp_1", Zones.BOAT]:
		if not id in save.owned:
			save.owned.append(id)
	# Haritada "Yeni!" yok; Dede'nin vakit, hava ve sevgi sözleri çoktan söylenmiş (videoda yalnızca isteğin, çayın,
	# fenerin, şişenin ve Bekçi'nin sözleri).
	for z in db.zones_of(spot):
		save.flags["visited_" + str(z["id"])] = true
	for phase: String in DayClock.PHASES:
		save.flags["told_time_" + phase] = true
	for kind: String in Weather.KINDS:
		save.flags["told_weather_" + kind] = true
	for level in range(2, LakeLove.max_level(rules) + 1):
		save.flags["told_love_%d" % level] = true
	# Akşam (saat donuk: vakitler çay ve VAKİT + ile değişir); Dede'nin istekleri açık (öteki senaryolarda kapalı).
	save.clock_s = 2 * rules.phase_s + 40
	save.request_day = -1
	main.call("_start_session")
	await _wait(1.6)
	_check("video: akşam, Dede'nin istekleri doldu", DayClock.phase(rules, save.clock_s) == "evening"
			and not Requests.daily(db, save).is_empty())
	# 1) Akşam iskelede bir yakalayışla biten istek (ilerleme bir eksik): bildirim, para, Dede'nin aferini.
	var target := _request_by_catch(db, save)
	if target.is_empty():
		target = [{}, "rudd", 300_000]
	elif not (target[0] as Dictionary).is_empty():
		(target[0] as Dictionary)["progress"] = int((target[0] as Dictionary)["goal"]) - 1
	var got := await _catch_at_dock(str(target[1]), int(target[2]))
	_check("video: akşam istenen balık, istek biter (Dede'nin aferini)", got and await _wait_until(func() -> bool:
			return str(main.get("_hint_shown")) == "UI_DEDE_REQ_DONE", 10.0))
	await _wait(1.4)
	await _shot("v1_aksam_istek")
	# 2) Saat çipi: "Bugün" paneli (akşam, bugünün ve yarının havası, çay, göl sevgisi, istekler); ÇAY İÇ: gece.
	await _tap_control(hud.world_button)
	await _wait_until(func() -> bool: return day_panel.visible, 2.0)
	await _wait(2.6)
	await _shot("v2_bugun")
	var tea := day_panel.tea_button()
	if tea != null and not tea.disabled:
		await _tap_control(tea)
	await _wait_until(func() -> bool: return DayClock.phase(rules, save.clock_s) == "night", 6.0)
	await _wait_until(func() -> bool: return not fade.busy(), 6.0)
	_check("video: Dede'yle çay, gece oldu", DayClock.phase(rules, save.clock_s) == "night")
	# 3) Gece: Nine'nin feneri (ilk gece: bildirim, Dede), ateşböcekleri, lambaların ışığı; gece balığı.
	await _wait(3.4)
	await _shot("v3_gece_fener")
	_check("video: ilk gece Nine'nin feneri", bool(save.flags.get("lantern", false)))
	await _catch_at_dock("zander", 640_000)
	await _wait(1.8)
	# 4) Sabah yağmur (VAKİT +, HAVA): damlalar ve halkalar, yağmurun sesi; yağmurda balık.
	main.call("_debug_time")
	await _wait(0.5)
	for i in Weather.KINDS.size():
		if Weather.at(rules, save) == "rain":
			break
		main.call("_debug_weather")
		await _wait_frames(2)
	await _wait(2.6)
	await _shot("v4_yagmur")
	_check("video: sabah yağmur", DayClock.phase(rules, save.clock_s) == "morning" and Weather.at(rules, save) == "rain")
	await _catch_at_dock("tench", 520_000)
	await _wait(1.6)
	# 5) Sazlıkta suda bir şişe (bildirim, Dede): haritadan sazlığa, dokununca mektup açılır; kapanınca Dede yazanı tanır.
	save.letter_at = save.catches - Secret.LETTER_GAP
	main.call("_sync_bottle")
	await _wait_until(func() -> bool: return bottle.visible, 3.0)
	await _wait(2.4)
	await _map_to(map_panel, fade, "reeds")
	await _wait(1.0)
	if bottle.visible:
		await _tap(_screen(bottle.point()))
	_check("video: şişeye dokununca mektup açılır", await _wait_until(func() -> bool: return letters.visible, 4.0))
	await _wait(3.6)
	await _shot("v5_mektup")
	await _tap_control(letters.close_button)
	await _wait_until(func() -> bool: return str(main.get("_line")) == "UI_DEDE_LETTER_1", 3.0)
	await _wait(2.6)
	# 6) Sisli gece, sandalla derin orta: turkuaz dev bir gölge sandalın çevresinde yüzüp dalar; Dede söyler.
	for i in 3:
		main.call("_debug_time")
		await _wait_frames(2)
	for i in Weather.KINDS.size():
		if Weather.at(rules, save) == "fog":
			break
		main.call("_debug_weather")
		await _wait_frames(2)
	await _map_to(map_panel, fade, "deep_water")
	await _wait(1.8)
	_check("video: sisli gece, sandal derin ortada", bool(main.get("in_boat")) and Weather.at(rules, save) == "fog"
			and DayClock.phase(rules, save.clock_s) == "night")
	await _video_ghost(_angler().pos2(), 4.8)
	main.call("_say", "UI_DEDE_STORY_15")
	await _wait(1.2)
	await _shot("v6_bekci")
	await _wait(2.6)
	for line in _results:
		print("KONTROL ", line)
	_quit()


## Tanıtım videosu: Gölün Bekçisi'nin dev gölgesi center'ın (sandal) çevresinde yarım tur yüzer, belirip söner,
## arkasında turkuaz iz halkaları; sonunda dalar (halkalar, ses, titreşim). Yalnızca görünüş (StoryFilm'in bitiş
## çekimi gibi): oturuma ve gölgelerin kuralına dokunmaz.
func _video_ghost(center: Vector2, seconds: float) -> void:
	var circle := Story.keeper_circle(GameState.db, str(main.get("spot_id")), center)
	if circle.size() < 4:
		return
	var path := circle.slice(0, (circle.size() >> 1) + 1)
	var layer: ShadowLayer = main.get("shadows")
	var rings: Ripples = main.get("ripples")
	var ghost := layer.make_ghost(StoryFilm.GHOST_LENGTH)
	var material := ghost.material_override as ShaderMaterial
	var age := 0.0
	var wake := 0.0
	Sounds.play("sting")
	Sounds.haptic(40)
	while age < seconds:
		var t := age / seconds
		var f := t * float(path.size() - 1)
		var i := mini(int(f), path.size() - 2)
		var p := path[i].lerp(path[i + 1], f - float(i))
		var heading := (path[i + 1] - path[i]).normalized()
		ghost.position = Vector3(p.x, ShadowLayer.Y, p.y)
		ghost.rotation = Vector3(0.0, atan2(-heading.x, -heading.y), 0.0)
		var shown := smoothstep(0.0, 0.18, t) * (1.0 - smoothstep(0.8, 1.0, t))
		material.set_shader_parameter("fade", shown)
		wake -= get_process_delta_time()
		if shown > 0.5 and wake <= 0.0:
			wake = StoryFilm.WAKE_EVERY
			rings.spawn(p - heading * StoryFilm.GHOST_LENGTH * 0.5, StoryFilm.GHOST_LENGTH * 0.4, 1.5,
					Color(0.7, 1.0, 0.96, 0.6), 0.1)
		await get_tree().process_frame
		age += get_process_delta_time()
	var end := path[path.size() - 1]
	for r: Vector3 in StoryFilm.DIVE_RINGS:
		rings.spawn(end, r.y, r.z, StoryFilm.TURQUOISE, 0.14)
	Sounds.play("dive")
	Sounds.haptic(80)
	ghost.queue_free()


# --- Reels: Instagram reklamının çekimi -------------------------------------------------

## Reels reklamının çekimi (kurgu: tools/reels_ad.py; CLAUDE.md "Reels videosu"). Dönen bir oyuncu
## (rütbe 9, en iyi takımın çoğu, sandal, sazlıkta dolu tuzak); her çekim bir bölgede. Kamerayı bot
## yönetir (_cam_shot): aksiyon ortadaki kare kırpmada kalır. Sözler kurguda yazıyla verilir: ipucu çubuğu
## kırpmaya sığmaz, gizlenir. Nadir balıkları bot sahneler (türü ve boyu); kurallar aynen işler.
## Günlük: REELS SYNC (kayıtta beyaz parlama; satır beyazın çizildiği karede), TAKE, MARK, CUT (kamera sıçraması, kararma),
## PANEL (panelin ekrandaki yeri), TOAST, AIM, END; kare numarası Engine.get_frames_drawn().
func _play_reels() -> void:
	_reels_setup()
	await _wait(1.2)
	# Kurgu aracı kaydın karelerini günlükle bu parlamayla eşler: SYNC beyazın çizildiği karede yazılır.
	var view := get_viewport().get_visible_rect().size
	var flashed := Signal(_overlay, "flashed")
	_overlay.call("flash", 2)
	await flashed
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
	# İpucu çubuğu, sol üstteki durum hapları (para, kova, rütbe çubuğu) ve üst ortadaki saat çipi (Dalga 4)
	# ortadaki kareye taşar, gizlenir.
	(_hud().get("_hint") as Control).modulate.a = 0.0
	(_hud().get("_status") as Control).modulate.a = 0.0
	_hud().world_chip().modulate.a = 0.0
	for player: AudioStreamPlayer in (Sounds.get("_ambience") as Array):
		player.stop()
	# Reels'in kendi müziği var (tools/reels_music.py): oyunun vakit müziği ve dükkân valsi kayda girmesin.
	GameState.save.settings["music"] = false
	Sounds.apply_settings()
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
		var session := _session()
		if session.state == FishingSession.State.FIGHTING and session.reel != null:
			var p := session.fight_point()
			if not session.lake.is_water(p) or session.lake.on_dock(p):
				_fight_on_land = true
			# Kıyıdan son metreler: balık suyun kenarında durur (kumun üstüne çekilmez). Bölge başına bir kez.
			if session.fight_near > 0.5 and session.reel.distance <= session.fight_near + 0.2:
				await _shot_once("26c_son_metreler_%s" % str(main.get("zone_id")))
		await get_tree().process_frame
		elapsed += get_process_delta_time()
	if hold:
		_touch(1, finger, false)


## Sol alttaki yürüme halkası (KONTROL satırları; balıkçı karada): sol altta ve güvenli alanda; halkaya
## dokunmak yürütmez, atmaz; sağa sürükleyince ekranın sağına yürür, az itince yavaş, bırakınca durur;
## halkanın kutusunun köşesine (halkanın dışı) dokunmak oyuna geçer; defter açıkken çalışmaz.
func _check_joystick() -> void:
	var hud := _hud()
	var stick := hud.joystick
	var angler := _angler()
	var lake := _session().lake
	angler.place(Vector2(-3.0, 11.3))
	(main.get("camera") as FollowCamera).snap(main.call("_focus"))
	await _wait_frames(4)
	var rect := stick.get_global_rect()
	var view := get_viewport().get_visible_rect()
	var inset := UiKit.safe_insets(hud)
	var safe := Rect2(view.position + Vector2(inset.x, inset.y), view.size - Vector2(inset.x + inset.z, inset.y + inset.w))
	_check("yürüme halkası sol altta, büyük, güvenli alanda (%s)" % rect, stick.visible and safe.encloses(rect)
			and rect.size.x >= 250.0 and rect.position.x < view.size.x * 0.25 and rect.end.y > view.size.y * 0.75)
	var center := rect.get_center()
	var k := rect.size.x / TouchJoystick.SIZE.x
	var start := angler.pos2()
	# Dokun ve bırak: yürümez, atılmaz.
	await _tap(center)
	await _wait_frames(4)
	_check("halkaya dokunmak yürütmez, atmaz", angler.pos2().distance_to(start) < 0.05
			and _state() == FishingSession.State.IDLE and not angler.is_walking())
	# Sağa sürükle (tam): ekranın sağına yürür; yarım itince yavaş; bırakınca durur.
	var screen_right := InputRouter.world_dir(Vector2(1, 0), FollowCamera.YAW)
	var walked: Array[float] = []
	for push: float in [1.0, 0.5]:
		var from := angler.pos2()
		_touch(3, center, true)
		await _wait_frames(2)
		_drag(3, center + Vector2(TouchJoystick.RING * k * push, 0.0))
		await _wait_frames(15)
		var moved := angler.pos2() - from
		walked.append(moved.length())
		_check("halkayı %%%d sağa it → ekranın sağına yürür (%.2f m)" % [int(push * 100), moved.length()],
				moved.length() > 0.2 and moved.normalized().dot(screen_right) > 0.85)
		_touch(3, center + Vector2(TouchJoystick.RING * k * push, 0.0), false)
		await _wait_frames(3)
		var stopped := angler.pos2()
		await _wait_frames(6)
		_check("bırakınca durur", angler.pos2().distance_to(stopped) < 0.02 and not stick.active())
	_check("az itince yavaş yürür (%.2f < %.2f m)" % [walked[1], walked[0]], walked[1] < walked[0] * 0.75)
	# Kutunun köşesi halkanın dışında: dokunuş oyuna geçer (karaysa yürür, suysa atar).
	var corner := rect.position + Vector2(14.0, 14.0) * k
	var p: Vector2 = main.call("ground_point", corner)
	var before := angler.pos2()
	await _tap(corner)
	await _wait_frames(6)
	var passed := angler.is_walking() or angler.pos2().distance_to(before) > 0.05 \
			or _state() != FishingSession.State.IDLE
	_check("halkanın dışına (kutunun köşesi) dokunmak oyuna geçer (%s)" % ("kara" if lake.is_walkable(p) else "su"),
			passed)
	await _wait_until(func() -> bool: return not angler.is_walking(), 6.0)
	if _state() != FishingSession.State.IDLE:
		await _tap(Vector2(400, 380))
		await _wait_state(FishingSession.State.IDLE, 4.0)
	# Defter açıkken halka çalışmaz.
	var book: BookPanel = main.get("book_panel")
	await _tap(hud.book_button.get_global_rect().get_center())
	await _wait_frames(3)
	var held := angler.pos2()
	_touch(3, center, true)
	await _wait_frames(2)
	_drag(3, center + Vector2(TouchJoystick.RING * k, 0.0))
	await _wait_frames(10)
	_touch(3, center + Vector2(TouchJoystick.RING * k, 0.0), false)
	await _wait_frames(2)
	_check("defter açıkken halka çalışmaz", book.visible and angler.pos2().distance_to(held) < 0.02)
	await _tap(book.close_button.get_global_rect().get_center())
	await _wait_frames(3)
	await _shot("01b_yurume_halkasi")


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
		var r := b.hit_rect()
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
	if not _intro:
		Story.mark_seen(save)
	# Dede'nin istekleri yalnızca requests senaryosunda: ötekilerde yuvalar hiç dolmaz, Dede'nin istek sözü yok
	# (rütbe 2'den sonra gelen istekler sözlerin sırasını, sevgiyi ve parayı değiştirip eski denetimleri
	# şaşırtmasın).
	if _scenario != "requests":
		save.request_day = 1 << 30
		save.flags["told_requests"] = true
	# Gölün Sırrı yalnızca secret senaryosunda: ötekilerde şişe hiç çıkmaz (sıradaki şişe çok uzak balıkta;
	# bildirim, Dede'nin sözü ve çizim eski denetimleri şaşırtmasın).
	if _scenario != "secret":
		save.letter_at = 1 << 30
	# Oyun saati donuk: senaryolar sabah ve açık havada, görüntüler eskisi gibi (world saati kendisi sürer).
	(main.get("world_clock") as WorldClock).frozen = true
	GameState.use_save(save)
	GameState.apply_locale()
	GameState.changed.emit()


## Uzun senaryolarda kova dolmasın (dolu kovada atılmaz, eylem düğmesi SAT olur): en büyük file.
func _roomy_bucket() -> void:
	if not "keepnet_huge" in GameState.save.owned:
		GameState.save.owned.append("keepnet_huge")


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
	if _shadow_seed >= 0:
		chosen.seed = _shadow_seed
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


## Basılı parmağı pos'a kaydırır (sürükleme olayı).
func _drag(index: int, pos: Vector2) -> void:
	var ev := InputEventScreenDrag.new()
	ev.index = index
	ev.position = _to_window(pos)
	ev.relative = ev.position - _to_window(_finger_pos.get(index, pos))
	Input.parse_input_event(ev)
	_finger_pos[index] = pos
	if not _hide_fingers:
		_overlay.call("finger_move", index, pos)


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
