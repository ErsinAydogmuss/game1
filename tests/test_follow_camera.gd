extends BaseTest
## Kameranın çerçevesi (FollowCamera): zeminde görünen alan kameranın kendi ışınlarıyla aynı (ekran
## payıyla: -1 alt kenar, 1 üst kenar); dipte uzağa düşen takım balıkçıyla birlikte görünür (fit),
## sığmazsa balıkçı görünür kalır.

const LOW := -0.5
const HIGH := 0.8


func test_ground_extents_match_the_camera_rays() -> void:
	for pitch: float in [FollowCamera.PITCH, deg_to_rad(60.0), deg_to_rad(45.0)]:
		# Kamera _place'teki gibi: odak başlangıçta, ondan geriye ve yukarıya; bakış (-pitch, YAW).
		var basis := Basis.from_euler(Vector3(-pitch, FollowCamera.YAW, 0.0))
		var back := Vector3(sin(FollowCamera.YAW) * cos(pitch), sin(pitch), cos(FollowCamera.YAW) * cos(pitch))
		var eye := back * FollowCamera.SURFACE_DISTANCE
		var forward := -basis.z
		var center := eye + forward * (-eye.y / forward.y)
		assert_true(center.length() < 0.001, "kamera odağa bakar (%s)" % str(center))
		var spread := tan(deg_to_rad(FollowCamera.FOV * 0.5))
		for bounds: Vector2 in [Vector2(-1.0, 1.0), Vector2(LOW, HIGH)]:
			var reach: Array[float] = []
			for y: float in [bounds.x, bounds.y]:
				# Ekranın ortasındaki dikey çizgide, ekran payı y'deki ışın (perspektif: tan ile doğrusal).
				var ray := forward + basis.y * (y * spread)
				var g := eye + ray * (-eye.y / ray.y)
				reach.append(Vector2(g.x, g.z).dot(FollowCamera.screen_up()))
			var ext := FollowCamera.ground_extents(pitch, bounds.x, bounds.y)
			assert_true(absf(-reach[0] - ext.x) < 0.01 and absf(reach[1] - ext.y) < 0.01,
					"%.0f°, %s: alt %.2f / üst %.2f m, ışınla %s" % [rad_to_deg(pitch), str(bounds), ext.x, ext.y, str(reach)])


func test_far_rig_fits_with_the_angler() -> void:
	var pitch := deg_to_rad(45.0)
	var ext := FollowCamera.ground_extents(pitch, LOW, HIGH)
	# Yakın takım: eskisi gibi (yolun %45'i, zoom değişmez).
	var near := FollowCamera.fit(4.0, pitch, 0.45, 1.0, 1.3, LOW, HIGH)
	assert_true(absf(near.x - 1.8) < 0.001 and is_equal_approx(near.y, 1.0), "yakın takım: %s" % str(near))
	# Uzak takım: zoom sınırı aşmaz, balıkçı hep ipucu çubuğunun üstünde; zoom sınırda değilse takım da
	# üst çizginin altında.
	for ahead: float in [8.0, 10.0, 12.0, 14.0, 16.0, 18.0]:
		var view := FollowCamera.fit(ahead, pitch, 0.45, 1.0, 1.3, LOW, HIGH)
		assert_true(view.y >= 1.0 and view.y <= 1.3 + 0.0001, "%.0f m: zoom sınırda (%.2f)" % [ahead, view.y])
		assert_true(view.x <= ext.x * view.y + 0.001, "%.0f m: balıkçı ekranda (%s)" % [ahead, str(view)])
		if view.y < 1.3 - 0.0001:
			assert_true(ahead - view.x <= ext.y * view.y + 0.001, "%.0f m: takım ekranda (%s)" % [ahead, str(view)])
	# Çekişmede balık yaklaştıkça çekişmenin zoom'una döner.
	var close := FollowCamera.fit(3.0, pitch, 0.45, 0.9, 1.3, LOW, HIGH)
	assert_true(is_equal_approx(close.y, 0.9) and absf(close.x - 1.35) < 0.001, "yakındaki balık: %s" % str(close))
