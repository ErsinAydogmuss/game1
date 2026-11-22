extends BaseTest
## Grafik kalitesi (GraphicsRules; Kazı'dan): Düşük / Orta / Yüksek; Android'de varsayılan Orta. Düşük ve Orta'da 3D
## seviyenin piksel bütçesinde çizilir; Düşük'te gölge, kenar yumuşatma ve parlama yok; telefonda 90/120 Hz ekranda
## kare sınırı 60, 60 Hz ekranda sınır yok.


func test_medium_is_android_default() -> void:
	assert_eq(GraphicsRules.default_level("Android"), GraphicsRules.MEDIUM, "Android'de Orta")
	for os_name: String in ["iOS", "macOS", "Linux", "Windows"]:
		assert_eq(GraphicsRules.default_level(os_name), GraphicsRules.HIGH, "varsayılan Yüksek: " + os_name)
	assert_eq(GraphicsRules.level_of(null, "Android"), GraphicsRules.MEDIUM, "ayar yoksa varsayılan")
	assert_eq(GraphicsRules.level_of("bozuk", "iOS"), GraphicsRules.HIGH, "bilinmeyen değer varsayılana döner")
	assert_eq(GraphicsRules.level_of("low", "iOS"), GraphicsRules.LOW, "kayıttaki seviye")


func test_render_scale_keeps_small_screens_sharp() -> void:
	assert_eq(GraphicsRules.render_scale(Vector2i(1280, 720), GraphicsRules.LOW), 1.0, "720p: Düşük'te de tam")
	assert_eq(GraphicsRules.render_scale(Vector2i(1600, 720), GraphicsRules.MEDIUM), 1.0, "HD+ telefon: Orta'da tam")
	assert_eq(GraphicsRules.render_scale(Vector2i(2532, 1170), GraphicsRules.HIGH), 1.0, "Yüksek'te ölçek yok (iPhone 14)")
	assert_eq(GraphicsRules.render_scale(Vector2i(3840, 2160), GraphicsRules.HIGH), 1.0, "Yüksek'te 4K da tam")


func test_render_scale_fits_the_pixel_budget() -> void:
	for level: String in [GraphicsRules.LOW, GraphicsRules.MEDIUM]:
		var budget := float(int(GraphicsRules.PIXEL_BUDGET[level]))
		for size: Vector2i in [Vector2i(2400, 1080), Vector2i(2532, 1170), Vector2i(2000, 1200)]:
			var s := GraphicsRules.render_scale(size, level)
			var pixels := size.x * s * size.y * s
			assert_true(s < 1.0 and absf(pixels - budget) < 1000.0,
					"%s %s: ölçek %.3f, %d piksel" % [level, size, s, roundi(pixels)])
	var medium := GraphicsRules.render_scale(Vector2i(2400, 1080), GraphicsRules.MEDIUM)
	var low := GraphicsRules.render_scale(Vector2i(2400, 1080), GraphicsRules.LOW)
	assert_true(medium > 0.78 and medium < 0.84, "FHD+ telefonda Orta ~0,81 (%.3f)" % medium)
	assert_true(low > 0.6 and low < medium, "Düşük Orta'dan küçük (%.3f)" % low)
	assert_eq(GraphicsRules.render_scale(Vector2i(7680, 4320), GraphicsRules.LOW), GraphicsRules.MIN_SCALE,
			"çok büyük ekranda alt sınır")


func test_levels_trade_effects_for_speed() -> void:
	assert_true(not GraphicsRules.shadows(GraphicsRules.LOW), "Düşük: gölge yok")
	assert_true(GraphicsRules.shadows(GraphicsRules.MEDIUM) and GraphicsRules.shadows(GraphicsRules.HIGH), "Orta ve Yüksek: gölge")
	assert_true(GraphicsRules.shadow_size(GraphicsRules.MEDIUM) < GraphicsRules.shadow_size(GraphicsRules.HIGH),
			"Orta'da küçük gölge haritası")
	assert_eq(GraphicsRules.shadow_size(GraphicsRules.HIGH), int(ProjectSettings.get_setting(
			"rendering/lights_and_shadows/directional_shadow/size", 0)), "Yüksek: projenin gölge haritası")
	assert_eq(GraphicsRules.msaa(GraphicsRules.LOW), Viewport.MSAA_DISABLED, "Düşük: kenar yumuşatma yok")
	assert_eq(GraphicsRules.msaa(GraphicsRules.HIGH), int(ProjectSettings.get_setting(
			"rendering/anti_aliasing/quality/msaa_3d", -1)), "Yüksek: projenin kenar yumuşatması")
	assert_eq(GraphicsRules.preview_msaa(GraphicsRules.LOW), Viewport.MSAA_DISABLED, "Düşük: önizlemede de yok")
	assert_eq(GraphicsRules.preview_msaa(GraphicsRules.HIGH), Viewport.MSAA_2X, "Yüksek: önizlemede 2x (eskisi gibi)")
	assert_true(not GraphicsRules.glow(GraphicsRules.LOW) and GraphicsRules.glow(GraphicsRules.MEDIUM), "Düşük: parlama yok")


## Kazı 0.14.4'ün düzeltmesi (docs/performans-notlari.md §3.6): Kazı'nın Android'deki kendiliğinden kapanmaları Mali
## sürücüsünde, MSAA'lı çizim tamponu bağlanırken / temizlenirken bellek alınamıyordu. Android'de gölde de önizlemelerde
## de (akvaryum, dolap) kenar yumuşatma hiçbir seviyede yok; iPhone ve bilgisayarda eskisi gibi; projenin ilk karesi de
## Android'de MSAA'sız.
func test_no_msaa_on_android() -> void:
	for level: String in GraphicsRules.LEVELS:
		assert_eq(GraphicsRules.msaa(level, "Android"), Viewport.MSAA_DISABLED, "Android göl: " + level)
		assert_eq(GraphicsRules.preview_msaa(level, "Android"), Viewport.MSAA_DISABLED, "Android önizleme: " + level)
	assert_eq(GraphicsRules.msaa(GraphicsRules.MEDIUM, "iOS"), Viewport.MSAA_2X, "iPhone Orta: 2x")
	assert_eq(GraphicsRules.preview_msaa(GraphicsRules.HIGH, "iOS"), Viewport.MSAA_2X, "iPhone önizleme: 2x")
	var config := ConfigFile.new()
	assert_eq(config.load("res://project.godot"), OK, "project.godot okunur")
	assert_eq(int(config.get_value("rendering", "anti_aliasing/quality/msaa_3d.android", -1)),
			Viewport.MSAA_DISABLED, "projede Android'in ilk karesi de MSAA'sız")
	# Önizlemeler kurulurken de (görünmeden önce) seviyenin kuralıyla: kodda sabit MSAA_2X yok.
	for path: String in ["res://scenes/ui/aquarium_tank.gd", "res://scenes/ui/angler_preview.gd"]:
		assert_true(not FileAccess.get_file_as_string(path).contains("msaa_3d = Viewport.MSAA_2X"),
				path + ": sabit MSAA yok")


func test_frame_limit() -> void:
	assert_eq(GraphicsRules.max_fps("Android", 120.0), 60, "120 Hz Android: 60 fps")
	assert_eq(GraphicsRules.max_fps("Android", 90.0), 60, "90 Hz Android: 60 fps")
	assert_eq(GraphicsRules.max_fps("Android", 60.0), 0, "60 Hz Android: sınır yok (V-Sync)")
	assert_eq(GraphicsRules.max_fps("Android", -1.0), 60, "tazelenme hızı bilinmiyor: 60 fps")
	assert_eq(GraphicsRules.max_fps("iOS", 120.0), 60, "ProMotion iPhone: 60 fps")
	assert_eq(GraphicsRules.max_fps("iOS", 60.0), 0, "60 Hz iPhone: sınır yok (V-Sync)")
	assert_eq(GraphicsRules.max_fps("Linux", 144.0), 0, "bilgisayarda sınır yok")
	assert_eq(int(ProjectSettings.get_setting("application/run/max_fps", -1)), 0,
			"projede sabit kare sınırı yok (GraphicsRules koyar: 60 Hz ekranda V-Sync'le birlikte kare kaçırtıyordu)")
