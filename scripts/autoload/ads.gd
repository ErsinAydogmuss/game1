extends Node
## Reklamlar (autoload Ads; Kazı'nın v0.14 katmanının Olta'ya uyarlanmışı). Kurallar AdRules'ta (saf mantık);
## burası reklamı yükler, gösterir ve sayar. Hedef kitle 13 yaş ve üstü (Ersin'in kararı, 4 Kasım 2026): istekler
## çocuğa yönelik işaretlenmez, reklamların içeriği en çok PG.
##
## Sağlayıcı: telefonda (Android, iOS) Poing Studios'un AdMob eklentisi (ads_poing.gd; yalnızca orada ve eklentinin
## yerel parçası varken yüklenir, masaüstünde eklentinin sınıflarına hiç dokunulmaz). Masaüstünde ve botta sahte
## sağlayıcı: ekranda kısa bir "deneme reklamı" kartı (fake_mode: "reward" izlenince ödül, "fail" yarıda kalır,
## "none" reklam yok). Botta varsayılan "none": eski senaryolarda teklif görünmez; ads senaryosu açar.
##
## Akış: main uygun anda (ısınmadan sonra, olta boşken, panel ve film yokken) önce "Reklamlar hakkında" kartını (bir
## kez; KVKK aydınlatması) açar, sonra start(): onay (UMP; AB'de form, iPhone'da izleme izninin açıklaması ve ATT),
## SDK'nın açılışı, ödüllü ve geçiş reklamının önceden yüklenmesi. Yüklenemeyen reklam artan aralıklarla yeniden
## denenir. Reklam açıkken oyun durur (SceneTree.paused) ve ses kısılır.

signal ready_changed
## Ödüllü reklamın para ödülü verildi (main duyurur ve sesini çalar).
signal coins_rewarded(amount: int)
## Ödüllü reklam sonuna kadar izlenmedi (main söyler: ödül yok).
signal reward_missed(place: String)

const IDS_PATH := "res://data/ads.json"
## Gizlilik politikası (Ersin'in GitHub Pages sitesi; Ayarlar ve "Reklamlar hakkında" kartı açar).
const PRIVACY_URL := "https://ersinaydogmuss.github.io/olta-gizlilik/"
## Google'ın deneme reklam birimleri (debug derlemede ve ads.json "test_ads" açıkken).
const TEST_UNITS := {
	"android": { "rewarded": "ca-app-pub-3940256099942544/5224354917",
			"interstitial": "ca-app-pub-3940256099942544/1033173712" },
	"ios": { "rewarded": "ca-app-pub-3940256099942544/1712485313",
			"interstitial": "ca-app-pub-3940256099942544/4411468910" },
}
## Oyuncu kitlesi 13+ (Play'deki hedef kitle): reklam istekleri çocuğa yönelik işaretlenmez. Play bir gün "çocuklara da
## hitap ediyor" derse true yapılır (bütün istekler çocuğa uygun ve kişiselleştirilmemiş olur).
const CHILD_DIRECTED := false
## Yüklenemeyen reklamı yeniden deneme aralıkları (sn, gerçek saat).
const RETRY_DELAYS: Array[float] = [20.0, 45.0, 90.0, 180.0]
## Reklam bu kadar sürede açılmazsa oyun beklemez (sn).
const SHOW_TIMEOUT := 5.0
## Sahte reklamın süresi (sn).
const FAKE_SECONDS := 1.2

## Reklamlar başladı mı (bildirimden ve onaydan sonra; oturum boyunca bir kez).
var started: bool = false
## main her kare verir: oyun ekranda ve akıyor mu (film, kararma, panel ve odak kaybında değil). Oyun süresi yalnızca
## o zaman sayılır (geçiş reklamının 20 dakikası, bekleme süreleri).
var playing: bool = false
## Reklam şu an ekranda mı.
var showing: bool = false
## Sahte sağlayıcının kipi (masaüstü ve bot).
var fake_mode: String = "reward"
## Sahte sağlayıcıda "Reklam seçimleri" gerekli mi (bot denetler).
var fake_privacy: bool = false
## Sahte reklam sayaçları (bot denetler).
var fake_rewarded_shown: int = 0
var fake_interstitials_shown: int = 0

var _platform: String = ""
var _ids: Dictionary = {}
var _provider: RefCounted
var _retry_rewarded: float = 0.0
var _retry_interstitial: float = 0.0
var _was_paused: bool = false
var _was_muted: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ids = _read_ids()
	if OS.has_feature("android"):
		_platform = "android"
	elif OS.has_feature("ios"):
		_platform = "ios"
	if OS.is_debug_build() and OS.get_cmdline_user_args().has("--autoplay"):
		fake_mode = "none"
	if not _platform.is_empty() and Engine.has_singleton("PoingGodotAdMob"):
		var units := _units()
		if not str(units.get("rewarded", "")).is_empty() or not str(units.get("interstitial", "")).is_empty():
			_provider = load("res://scripts/autoload/ads_poing.gd").new()
			_provider.set("rewarded_unit", str(units.get("rewarded", "")))
			_provider.set("interstitial_unit", str(units.get("interstitial", "")))


func _process(delta: float) -> void:
	if playing and not showing:
		var st := _state()
		if not st.is_empty():
			AdRules.add_play(st, delta)
	if _provider != null and started:
		_retry(delta)


# --- Durum ---------------------------------------------------------------------

## Reklam bu cihazda var mı (telefonda eklenti ve kimlikler; masaüstünde sahte kip).
func available() -> bool:
	if _platform.is_empty():
		return fake_mode != "none"
	return _provider != null


## "Reklamlar hakkında" kartı gösterilmeli mi (ısınmadan sonra, bir kez).
func needs_notice() -> bool:
	var st := _state()
	return available() and not st.is_empty() and not AdRules.notice_seen(st) \
			and AdRules.warmed_up(GameState.save.catches)


func accept_notice() -> void:
	var st := _state()
	if not st.is_empty():
		AdRules.mark_notice_seen(st)
		GameState.save_game()


func rewarded_ready() -> bool:
	if not started or showing:
		return false
	if _provider != null:
		return bool(_provider.call("rewarded_ready"))
	return _platform.is_empty() and fake_mode != "none"


func interstitial_ready() -> bool:
	if not started or showing:
		return false
	if _provider != null:
		return bool(_provider.call("interstitial_ready"))
	return _platform.is_empty() and fake_mode != "none"


## Bu yerde ödüllü reklam teklif edilebilir mi (reklam yüklü ve kurallar izin veriyor).
func offer_ok(place: String) -> bool:
	if not rewarded_ready() or GameState.save == null:
		return false
	return AdRules.can_offer(_state(), place, today(), GameState.save.catches)


## Geçişten sonra geçiş reklamı gösterilmeli mi.
func interstitial_due() -> bool:
	if not interstitial_ready() or GameState.save == null:
		return false
	return AdRules.interstitial_due(_state(), GameState.save.catches)


func privacy_options_required() -> bool:
	if _provider != null:
		return started and bool(_provider.call("privacy_options_required"))
	return _platform.is_empty() and fake_privacy


## Günlük sınırların günü (yerel tarih, yyyymmdd).
func today() -> int:
	return AdRules.day_key(Time.get_date_dict_from_system())


# --- Akış ----------------------------------------------------------------------

## Onay, SDK ve önceden yükleme (bir kez). Bildirim kartı main'de, bundan önce.
func start() -> void:
	if started or not available():
		return
	started = true
	if _provider != null:
		_provider.call("configure", _test_devices(), CHILD_DIRECTED)
		await _provider.call("consent", _debug_geography(), _test_devices())
		if not bool(_provider.call("can_request_ads")):
			ready_changed.emit()
			return
		await _provider.call("initialize")
		_provider.connect("changed", _on_provider_changed)
		_provider.call("load_rewarded")
		_provider.call("load_interstitial")
	ready_changed.emit()


## Ödüllü reklamı gösterir; oyuncu sonuna kadar izlediyse true (ödülü çağıran verir; sayaç burada).
func show_rewarded(place: String) -> bool:
	if not rewarded_ready():
		return false
	showing = true
	_hold_game(true)
	var earned := false
	if _provider != null:
		earned = await _provider.call("show_rewarded", SHOW_TIMEOUT)
	else:
		earned = await _fake_show(true)
	_hold_game(false)
	showing = false
	if earned:
		AdRules.record_reward(_state(), place, today())
		GameState.save_game()
	else:
		reward_missed.emit(place)
	_reload()
	ready_changed.emit()
	return earned


## Ödüllü reklamın para ödülü (kayda; satış sayaçlarına girmez).
func reward_coins(amount: int) -> void:
	if amount <= 0 or GameState.save == null:
		return
	GameState.save.coins += amount
	GameState.save_game()
	GameState.changed.emit()
	coins_rewarded.emit(amount)


## Geçiş reklamını gösterir; gösterildiyse true.
func show_interstitial() -> bool:
	if not interstitial_ready():
		return false
	showing = true
	_hold_game(true)
	var shown := false
	if _provider != null:
		shown = await _provider.call("show_interstitial", SHOW_TIMEOUT)
	else:
		shown = await _fake_show(false)
	_hold_game(false)
	showing = false
	if shown:
		AdRules.record_interstitial(_state(), today())
		GameState.save_game()
	_reload()
	ready_changed.emit()
	return shown


## Gizlilik seçenekleri formu (Ayarlar).
func show_privacy_options() -> void:
	if _provider != null:
		await _provider.call("show_privacy_options")


## Bot: sahte sağlayıcının kipi ("reward", "fail", "none").
func use_fake(mode: String) -> void:
	fake_mode = mode
	ready_changed.emit()


# --- İç işler ------------------------------------------------------------------

func _state() -> Dictionary:
	if GameState.save == null:
		return {}
	return AdRules.state(GameState.save.settings)


func _read_ids() -> Dictionary:
	if not FileAccess.file_exists(IDS_PATH):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(IDS_PATH))
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}


## Deneme reklamı mı: debug derleme ya da ads.json "test_ads".
func _test_ads() -> bool:
	return OS.is_debug_build() or bool(_ids.get("test_ads", false))


func _units() -> Dictionary:
	if _test_ads():
		return TEST_UNITS.get(_platform, {})
	var raw: Variant = _ids.get(_platform, {})
	return raw if typeof(raw) == TYPE_DICTIONARY else {}


func _test_devices() -> Array[String]:
	var out: Array[String] = []
	var raw: Variant = _ids.get("test_devices", [])
	if typeof(raw) == TYPE_ARRAY:
		for id: Variant in raw:
			out.append(str(id))
	return out


## Onay penceresini denemek için coğrafya (yalnızca deneme reklamlarında): 0 kapalı, 1 AB, 2 AB dışı.
func _debug_geography() -> int:
	if not _test_ads():
		return 0
	match str(_ids.get("debug_geography", "")):
		"eea":
			return 1
		"not_eea":
			return 2
	return 0


func _hold_game(on: bool) -> void:
	var master := AudioServer.get_bus_index(&"Master")
	if on:
		_was_paused = get_tree().paused
		_was_muted = AudioServer.is_bus_mute(master)
		get_tree().paused = true
		AudioServer.set_bus_mute(master, true)
	else:
		get_tree().paused = _was_paused
		AudioServer.set_bus_mute(master, _was_muted)


func _reload() -> void:
	if _provider == null:
		return
	_provider.call("load_rewarded")
	_provider.call("load_interstitial")


func _on_provider_changed() -> void:
	if _provider == null:
		return
	var rewarded_failures := int(_provider.get("rewarded_failures"))
	if not bool(_provider.call("rewarded_ready")) and rewarded_failures > 0 and _retry_rewarded <= 0.0:
		_retry_rewarded = RETRY_DELAYS[mini(rewarded_failures, RETRY_DELAYS.size()) - 1]
	var interstitial_failures := int(_provider.get("interstitial_failures"))
	if not bool(_provider.call("interstitial_ready")) and interstitial_failures > 0 and _retry_interstitial <= 0.0:
		_retry_interstitial = RETRY_DELAYS[mini(interstitial_failures, RETRY_DELAYS.size()) - 1]
	ready_changed.emit()


func _retry(delta: float) -> void:
	if _retry_rewarded > 0.0:
		_retry_rewarded -= delta
		if _retry_rewarded <= 0.0:
			_provider.call("load_rewarded")
	if _retry_interstitial > 0.0:
		_retry_interstitial -= delta
		if _retry_interstitial <= 0.0:
			_provider.call("load_interstitial")


## Sahte reklam: ekranı kaplayan kısa bir kart. Ödüllüde ödül fake_mode "reward" ise.
func _fake_show(rewarded: bool) -> bool:
	var layer := CanvasLayer.new()
	layer.layer = 120
	add_child(layer)
	var back := ColorRect.new()
	back.color = Color(0.05, 0.05, 0.09, 0.96)
	back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	back.mouse_filter = Control.MOUSE_FILTER_STOP
	layer.add_child(back)
	var column := VBoxContainer.new()
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.add_theme_constant_override("separation", 24)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back.add_child(column)
	column.add_child(UiKit.title(tr("UI_AD_TEST"), 110, UiKit.ACCENT, HORIZONTAL_ALIGNMENT_CENTER, 16))
	var kind := tr("UI_AD_TEST_REWARDED") if rewarded else tr("UI_AD_TEST_INTERSTITIAL")
	column.add_child(UiKit.label(kind, UiKit.SIZE_TITLE, UiKit.TEXT, HORIZONTAL_ALIGNMENT_CENTER))
	if rewarded:
		fake_rewarded_shown += 1
	else:
		fake_interstitials_shown += 1
	await get_tree().create_timer(FAKE_SECONDS, true, false, true).timeout
	layer.queue_free()
	if rewarded:
		return fake_mode == "reward"
	return fake_mode != "none"
