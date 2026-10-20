extends BaseTest
## Sol alttaki yürüme halkası (TouchJoystick): ölü bölge, sınır ve yön; ekrandaki yön dünyada
## kameraya göre (InputRouter.world_dir, klavyeyle aynı formül).


## Ölü bölgenin içinde 0; dışında 0'dan 1'e yeniden ölçeklenir; halkanın dışı 1'de kalır; yön korunur.
func test_dead_zone_and_limit() -> void:
	var r := TouchJoystick.RING
	assert_eq(TouchJoystick.shape(Vector2(r * TouchJoystick.DEAD_ZONE * 0.9, 0.0), r), Vector2.ZERO, "ölü bölgede 0")
	var edge := TouchJoystick.shape(Vector2(0.0, -r), r)
	assert_between(edge.length(), 0.999, 1.001, "halkanın kenarında tam")
	assert_true(edge.y < -0.99, "yukarı")
	var far := TouchJoystick.shape(Vector2(r * 3.0, 0.0), r)
	assert_between(far.length(), 0.999, 1.001, "halkanın dışında da en çok 1")
	var half := TouchJoystick.shape(Vector2(r * 0.5, r * 0.5) / sqrt(2.0), r)
	var want := (0.5 - TouchJoystick.DEAD_ZONE) / (1.0 - TouchJoystick.DEAD_ZONE)
	assert_between(half.length(), want - 0.001, want + 0.001, "yarı itince yavaş")
	assert_between(half.normalized().dot(Vector2(1, 1).normalized()), 0.999, 1.001, "yön korunur")


## Ekranın yukarısı kameradan uzağa, sağı ekranın sağına (kamera +x +z tarafında); uzunluk korunur.
func test_screen_direction_to_world() -> void:
	var yaw := FollowCamera.YAW
	var up := InputRouter.world_dir(Vector2(0, -1), yaw)
	assert_true(up.distance_to(Vector2(-sin(yaw), -cos(yaw))) < 0.001, "yukarı: kameradan uzağa")
	var right := InputRouter.world_dir(Vector2(1, 0), yaw)
	assert_true(right.distance_to(Vector2(cos(yaw), -sin(yaw))) < 0.001, "sağ")
	assert_between(InputRouter.world_dir(Vector2(0.3, 0.4), yaw).length(), 0.499, 0.501, "uzunluk korunur")
	assert_between(up.dot(right), -0.001, 0.001, "yukarı ile sağ dik")
