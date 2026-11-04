extends BaseTest
## Dışa aktarma ayarları (export_presets.cfg) ve reklamın proje ayarları: iPhone (paket kimliği, takım, en az iOS 15,
## izleme izninin açıklaması), Android (Gradle derlemesi, AAB, izinler, ikonlar, imza), pakete girmeyenler (testler,
## araçlar, botlar, reklam eklentisinin editör parçaları), Ads autoload'u ve AdMob eklentisi.

const PRESETS := "res://export_presets.cfg"
const BUNDLE := "com.juiloot.olta"
const EXCLUDED: Array[String] = ["tests/*", "tools/*", "scripts/dev/*", "addons/admob/assets/*",
		"addons/admob/internal/mock/*", "addons/admob/internal/editor/*"]


func _presets() -> ConfigFile:
	var cfg := ConfigFile.new()
	assert_eq(cfg.load(PRESETS), OK, "export_presets.cfg okunur")
	return cfg


## Adı verilen ayarın bölümü ("preset.N"); yoksa boş.
func _section(cfg: ConfigFile, preset_name: String) -> String:
	for section in cfg.get_sections():
		if section.begins_with("preset.") and not section.ends_with(".options") \
				and str(cfg.get_value(section, "name", "")) == preset_name:
			return section
	return ""


func _filters_ok(cfg: ConfigFile, section: String, label: String) -> void:
	var exclude := str(cfg.get_value(section, "exclude_filter", ""))
	for f: String in EXCLUDED:
		assert_true(exclude.contains(f), "%s: %s pakete girmez" % [label, f])
	assert_true(str(cfg.get_value(section, "include_filter", "")).contains("data/*.json"), label + ": data/*.json pakete girer")


func test_iphone_preset() -> void:
	var cfg := _presets()
	var section := _section(cfg, "iPhone")
	assert_true(section != "", "iPhone ayarı var")
	assert_eq(str(cfg.get_value(section, "platform", "")), "iOS", "iPhone ayarı iOS")
	_filters_ok(cfg, section, "iPhone")
	var options := section + ".options"
	assert_eq(str(cfg.get_value(options, "application/bundle_identifier", "")), BUNDLE, "paket kimliği")
	assert_true(str(cfg.get_value(options, "application/app_store_team_id", "")).length() == 10, "Apple takım kimliği")
	assert_true(float(str(cfg.get_value(options, "application/min_ios_version", "0"))) >= 15.0, "en az iOS 15 (reklam SDK'sı)")
	# Görünen sürüm (CFBundleShortVersionString) project.godot'un config/version'ı; yapı numarası (CFBundleVersion)
	# her App Store yüklemesinde artar.
	var build := str(cfg.get_value(options, "application/version", ""))
	assert_true(build.is_valid_int() and int(build) >= 1, "iPhone yapı numarası (%s)" % build)
	assert_eq(str(cfg.get_value(options, "application/short_version", "")), "",
			"görünen sürüm config/version'dan gelir (iki yerde yazılmaz)")
	var plist := str(cfg.get_value(options, "application/additional_plist_content", ""))
	assert_true(plist.contains("NSUserTrackingUsageDescription"), "izleme izninin açıklaması Info.plist'te")
	assert_true(plist.contains("ITSAppUsesNonExemptEncryption"), "şifreleme beyanı Info.plist'te")
	assert_true(bool(cfg.get_value(options, "user_data/accessible_from_files_app", false)), "fotoğraflar Dosyalar'da")


## Mağazaların görünen sürümü (iPhone'da CFBundleShortVersionString, Android'de versionName): üç sayı, noktayla.
func test_store_version() -> void:
	var version := str(ProjectSettings.get_setting("application/config/version", ""))
	var parts := version.split(".")
	assert_eq(parts.size(), 3, "sürüm üç parça (%s)" % version)
	for part in parts:
		assert_true(part.is_valid_int() and int(part) >= 0, "sürümün parçası sayı (%s)" % version)


func test_android_preset() -> void:
	var cfg := _presets()
	var section := _section(cfg, "Android")
	assert_true(section != "", "Android ayarı var")
	assert_eq(str(cfg.get_value(section, "platform", "")), "Android", "Android ayarı Android")
	_filters_ok(cfg, section, "Android")
	var options := section + ".options"
	assert_true(bool(cfg.get_value(options, "gradle_build/use_gradle_build", false)), "Gradle derlemesi (reklam SDK'sı)")
	assert_eq(int(cfg.get_value(options, "gradle_build/export_format", 0)), 1, "biçim AAB (Google Play)")
	assert_eq(str(cfg.get_value(options, "package/unique_name", "")), BUNDLE, "paket adı")
	assert_true(bool(cfg.get_value(options, "package/signed", false)), "imzalı")
	assert_true(int(cfg.get_value(options, "version/code", 0)) >= 1, "sürüm kodu")
	assert_true(bool(cfg.get_value(options, "architectures/arm64-v8a", false)), "64 bit")
	for permission: String in ["internet", "access_network_state", "vibrate"]:
		assert_true(bool(cfg.get_value(options, "permissions/" + permission, false)), "izin: " + permission)
	for icon: String in ["launcher_icons/main_192x192", "launcher_icons/adaptive_foreground_432x432",
			"launcher_icons/adaptive_background_432x432"]:
		var path := str(cfg.get_value(options, icon, ""))
		assert_true(path != "" and ResourceLoader.exists(path), "ikon var: " + icon)


func test_ads_are_wired_into_the_project() -> void:
	assert_eq(str(ProjectSettings.get_setting("autoload/Ads", "")), "*res://scripts/autoload/ads.gd", "Ads autoload'u")
	var plugins: PackedStringArray = ProjectSettings.get_setting("editor_plugins/enabled", PackedStringArray())
	assert_true(plugins.has("res://addons/admob/plugin.cfg"), "AdMob eklentisi açık (dışa aktarmada kimliği yazar)")
	assert_true(FileAccess.file_exists("res://addons/admob/LICENSE"), "eklentinin lisansı depoda")
	for part: String in ["res://addons/admob/android/bin/ads/libs/poing-godot-admob-ads-release.aar",
			"res://addons/admob/ios/bin/ads/poing_godot_admob_ads.gd"]:
		assert_true(FileAccess.file_exists(part), "eklentinin yerel parçası depoda: " + part.get_file())
