extends BaseTest
## Reklam kimlikleri: data/ads.json'daki reklam birimleri ve project.godot'taki AdMob uygulama kimlikleri. İki hâl:
## - Ersin'in AdMob'daki Olta uygulamaları açılmadan önce: birimler boş, uygulama kimlikleri Google'ın örnekleri (SDK
##   açılışta uygulama kimliği ister; yoksa uygulama kapanır). Örnek kimlik eklentinin varsayılanı olduğu için
##   project.godot'ta yazmaz (editör varsayılanı kaydetmez). Sürüm derlemesinde reklam yok, debug derleme deneme
##   reklamı gösterir.
## - Gerçek kimliklerle (mağazaya giden sürüm): bütün birimler dolu, biçimleri doğru, hepsi aynı yayıncının, Google'ın
##   örnek ya da deneme kimliği kalmamış; uygulama kimlikleri birimlerin yayıncısının.
## Yarım hâl (bir birim dolu, öteki boş) olmaz.

const IDS := "res://data/ads.json"
## Google'ın örnek ve deneme kimliklerinin yayıncısı.
const SAMPLE_PUB := "3940256099942544"
const PLATFORMS: Array[String] = ["android", "ios"]
const UNITS: Array[String] = ["rewarded", "interstitial"]


func _ids() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(IDS))
	assert_true(typeof(parsed) == TYPE_DICTIONARY, "ads.json okunur")
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}


## "ca-app-pub-<16 rakam><ayraç><10 rakam>" ise yayıncının 16 rakamı, değilse boş. Reklam biriminde ayraç "/",
## uygulamada "~".
func _publisher(id: String, separator: String) -> String:
	var re := RegEx.create_from_string("^ca-app-pub-(\\d{16})" + separator + "\\d{10}$")
	var found := re.search(id)
	return found.get_string(1) if found != null else ""


## Eklentinin varsayılanları (addons/admob/internal/services/project_settings_service.gd): ayar bu değerdeyken editör
## onu project.godot'a yazmaz, dışa aktarma yine bunu kullanır.
const PLUGIN_DEFAULTS := { "android": "ca-app-pub-3940256099942544~3347511713",
		"ios": "ca-app-pub-3940256099942544~1458002511" }


func _app_id(platform: String) -> String:
	var id := str(ProjectSettings.get_setting("admob/general/%s/app_id" % platform, ""))
	return id if not id.is_empty() else str(PLUGIN_DEFAULTS[platform])


func _units_filled(ids: Dictionary) -> int:
	var filled := 0
	for platform: String in PLATFORMS:
		var units: Dictionary = ids.get(platform, {})
		for unit: String in UNITS:
			if not str(units.get(unit, "")).is_empty():
				filled += 1
	return filled


func test_ids_are_all_or_nothing() -> void:
	var ids := _ids()
	assert_eq(ids.get("test_ads", true), false, "sürüm derlemesi deneme reklamı göstermez (test_ads kapalı)")
	var filled := _units_filled(ids)
	assert_true(filled == 0 or filled == PLATFORMS.size() * UNITS.size(),
			"birimler ya hepsi boş ya hepsi dolu (dolu: %d)" % filled)


func test_app_ids_exist_and_differ() -> void:
	for platform: String in PLATFORMS:
		assert_true(_publisher(_app_id(platform), "~") != "", "%s uygulama kimliğinin biçimi: '%s'" % [platform,
				_app_id(platform)])
	assert_true(_app_id("android") != _app_id("ios"), "Android ve iOS ayrı uygulamalar")


func test_real_ids_match_one_publisher() -> void:
	var ids := _ids()
	if _units_filled(ids) == 0:
		# Gerçek kimlikler henüz yok: uygulama kimlikleri Google'ın örnekleri olmalı (karışık hâl yok).
		for platform: String in PLATFORMS:
			assert_eq(_publisher(_app_id(platform), "~"), SAMPLE_PUB,
					"%s: birimler boşken uygulama kimliği Google'ın örneği" % platform)
		return
	var seen: Dictionary = {}
	for platform: String in PLATFORMS:
		var app_pub := _publisher(_app_id(platform), "~")
		assert_true(app_pub != SAMPLE_PUB, "%s uygulama kimliği Google'ın örneği değil" % platform)
		var units: Dictionary = ids.get(platform, {})
		for unit: String in UNITS:
			var id := str(units.get(unit, ""))
			var publisher := _publisher(id, "/")
			assert_true(publisher != "", "%s %s biriminin biçimi: '%s'" % [platform, unit, id])
			assert_true(publisher != SAMPLE_PUB, "%s %s Google'ın deneme birimi değil" % [platform, unit])
			assert_eq(publisher, app_pub, "%s %s birimi uygulamayla aynı yayıncının" % [platform, unit])
			assert_true(not seen.has(id), "%s %s başka bir birimle aynı değil" % [platform, unit])
			seen[id] = true
