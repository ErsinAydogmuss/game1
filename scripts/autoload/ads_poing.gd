extends RefCounted
## Ads'in telefondaki sağlayıcısı (Kazı'nın v0.14 köprüsü, Olta'da aynen): Poing Studios'un AdMob eklentisi (addons/admob, v5.1.0; Android'de
## Google Mobile Ads Next-Gen SDK, iOS'ta GoogleMobileAds; ikisinde de Google'ın onay penceresi UMP). Yalnızca Android
## ve iOS'ta, eklentinin yerel parçası varken yüklenir (Ads._ready): masaüstünde eklentinin sınıflarına hiç dokunulmaz
## (orada sahte sağlayıcı çalışır). Bütün çağrılar eklentinin geri çağrılarını bekleyen eşyordamlar; hiçbiri oyunu
## sonsuza kadar bekletmez (zaman aşımları gerçek saatle: reklam açıkken oyun duruyor).

signal changed

## Onay penceresi ve SDK'nın açılışı için en uzun bekleme (sn).
const CONSENT_TIMEOUT := 20.0
const INIT_TIMEOUT := 15.0
## Ödül, kapanıştan hemen sonra da gelebilir: kapanıştan sonra bu kadar kare beklenir.
const REWARD_GRACE_FRAMES := 20

var rewarded_unit: String = ""
var interstitial_unit: String = ""
var rewarded_failures: int = 0
var interstitial_failures: int = 0

var _rewarded: RewardedAd
var _interstitial: InterstitialAd
var _loading_rewarded: bool = false
var _loading_interstitial: bool = false


static func available() -> bool:
	return Engine.has_singleton("PoingGodotAdMob")


## İstek ayarları: en fazla PG içerik (aile oyunu); çocuk işareti yok (Play'de hedef kitle 13+).
func configure(test_devices: Array[String], child_directed: bool) -> void:
	var config := RequestConfiguration.new()
	config.max_ad_content_rating = RequestConfiguration.MAX_AD_CONTENT_RATING_PG
	config.tag_for_child_directed_treatment = (RequestConfiguration.TagForChildDirectedTreatment.TRUE
			if child_directed else RequestConfiguration.TagForChildDirectedTreatment.UNSPECIFIED)
	config.test_device_ids = test_devices
	MobileAds.set_request_configuration(config)


## Onay: bilgiyi günceller; gerekiyorsa (AB, İngiltere, İsviçre; iPhone'da izleme izninin açıklaması) formu gösterir.
## debug_geography: 0 kapalı, 1 AB'deymiş gibi, 2 AB dışı (yalnızca deneme reklamlarında).
func consent(debug_geography: int, test_devices: Array[String]) -> void:
	var params := ConsentRequestParameters.new()
	if debug_geography != 0:
		var debug := ConsentDebugSettings.new()
		debug.debug_geography = debug_geography
		debug.test_device_hashed_ids = test_devices
		params.consent_debug_settings = debug
	var state := { "done": false }
	var info := UserMessagingPlatform.consent_information
	var updated := func() -> void:
		state["done"] = true
	var update_failed := func(error: FormError) -> void:
		if error != null:
			push_warning("AdMob onay bilgisi alınamadı: " + error.message)
		state["done"] = true
	info.update(params, updated, update_failed)
	await _wait(state, CONSENT_TIMEOUT)
	if not info.get_is_consent_form_available():
		return
	if info.get_consent_status() != ConsentInformation.ConsentStatus.REQUIRED:
		return
	var form_state := { "done": false }
	var dismissed := func(_error: FormError) -> void:
		form_state["done"] = true
	var loaded := func(form: ConsentForm) -> void:
		form.show(dismissed)
	var load_failed := func(error: FormError) -> void:
		if error != null:
			push_warning("AdMob onay formu yüklenemedi: " + error.message)
		form_state["done"] = true
	UserMessagingPlatform.load_consent_form(loaded, load_failed)
	# Formu oyuncu okur: kapanana kadar beklenir (zaman aşımı yok).
	await _wait(form_state, INF)


## Onaya göre reklam istenebilir mi (onay gerekiyor ama alınmadıysa istenmez).
func can_request_ads() -> bool:
	return UserMessagingPlatform.consent_information.get_consent_status() != ConsentInformation.ConsentStatus.REQUIRED


func privacy_options_required() -> bool:
	return (UserMessagingPlatform.consent_information.get_privacy_options_requirement_status()
			== ConsentInformation.PrivacyOptionsRequirementStatus.REQUIRED)


## Gizlilik seçenekleri formu (oyuncu onayını değiştirir).
func show_privacy_options() -> void:
	var state := { "done": false }
	var dismissed := func(_error: FormError) -> void:
		state["done"] = true
	UserMessagingPlatform.show_privacy_options_form(dismissed)
	await _wait(state, INF)


func initialize() -> void:
	var state := { "done": false }
	var listener := OnInitializationCompleteListener.new()
	listener.on_initialization_complete = func(_status: InitializationStatus) -> void:
		state["done"] = true
	MobileAds.initialize(listener)
	await _wait(state, INIT_TIMEOUT)


func rewarded_ready() -> bool:
	return _rewarded != null


func interstitial_ready() -> bool:
	return _interstitial != null


func load_rewarded() -> void:
	if _loading_rewarded or _rewarded != null or rewarded_unit.is_empty():
		return
	_loading_rewarded = true
	var callback := RewardedAdLoadCallback.new()
	callback.on_ad_loaded = func(ad: RewardedAd) -> void:
		_rewarded = ad
		_loading_rewarded = false
		rewarded_failures = 0
		changed.emit()
	callback.on_ad_failed_to_load = func(error: AdError) -> void:
		_loading_rewarded = false
		rewarded_failures += 1
		if error != null:
			push_warning("Ödüllü reklam yüklenemedi: %d %s" % [error.code, error.message])
		changed.emit()
	RewardedAdLoader.new().load(rewarded_unit, AdRequest.new(), callback)


func load_interstitial() -> void:
	if _loading_interstitial or _interstitial != null or interstitial_unit.is_empty():
		return
	_loading_interstitial = true
	var callback := InterstitialAdLoadCallback.new()
	callback.on_ad_loaded = func(ad: InterstitialAd) -> void:
		_interstitial = ad
		_loading_interstitial = false
		interstitial_failures = 0
		changed.emit()
	callback.on_ad_failed_to_load = func(error: AdError) -> void:
		_loading_interstitial = false
		interstitial_failures += 1
		if error != null:
			push_warning("Geçiş reklamı yüklenemedi: %d %s" % [error.code, error.message])
		changed.emit()
	InterstitialAdLoader.new().load(interstitial_unit, AdRequest.new(), callback)


## Ödüllü reklamı gösterir; ödül kazanıldıysa true. show_timeout: reklam bu kadar sürede açılmazsa vazgeçilir.
func show_rewarded(show_timeout: float) -> bool:
	if _rewarded == null:
		return false
	var ad := _rewarded
	_rewarded = null
	var state := { "shown": false, "done": false, "earned": false }
	_watch(ad.full_screen_content_callback, state)
	var listener := OnUserEarnedRewardListener.new()
	listener.on_user_earned_reward = func(_item: RewardedItem) -> void:
		state["earned"] = true
	ad.show(listener)
	await _wait_show(state, show_timeout)
	var tree := Engine.get_main_loop() as SceneTree
	for i in REWARD_GRACE_FRAMES:
		if bool(state["earned"]):
			break
		await tree.process_frame
	ad.destroy()
	changed.emit()
	return bool(state["earned"])


## Geçiş reklamını gösterir; gösterildiyse true.
func show_interstitial(show_timeout: float) -> bool:
	if _interstitial == null:
		return false
	var ad := _interstitial
	_interstitial = null
	var state := { "shown": false, "done": false, "earned": false }
	_watch(ad.full_screen_content_callback, state)
	ad.show()
	await _wait_show(state, show_timeout)
	ad.destroy()
	changed.emit()
	return bool(state["shown"])


func _watch(callback: FullScreenContentCallback, state: Dictionary) -> void:
	callback.on_ad_showed_full_screen_content = func() -> void:
		state["shown"] = true
	callback.on_ad_dismissed_full_screen_content = func() -> void:
		state["done"] = true
	callback.on_ad_failed_to_show_full_screen_content = func(error: AdError) -> void:
		if error != null:
			push_warning("Reklam gösterilemedi: %d %s" % [error.code, error.message])
		state["done"] = true


## Reklam kapanana kadar bekler; açılmadan show_timeout geçerse vazgeçer.
func _wait_show(state: Dictionary, show_timeout: float) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var start := Time.get_ticks_msec()
	while not bool(state["done"]):
		if not bool(state["shown"]) and float(Time.get_ticks_msec() - start) / 1000.0 > show_timeout:
			push_warning("Reklam %.0f sn'de açılmadı" % show_timeout)
			return
		await tree.process_frame


## state["done"] olana ya da limit (sn, gerçek saat) dolana kadar bekler.
func _wait(state: Dictionary, limit: float) -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var start := Time.get_ticks_msec()
	while not bool(state["done"]):
		if float(Time.get_ticks_msec() - start) / 1000.0 > limit:
			return
		await tree.process_frame
