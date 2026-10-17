extends BaseTest
## Su ve zemin shader'larının veri dokuları (LakeTexture): göl dokusunda kıyı uzaklığı ve akıntı
## (yalnızca derede); zemin dokusunda yürünebilen dünya ve kayalık burnun taşlığı.

const SPOT := "big_lake"


func test_lake_data_has_the_stream_current() -> void:
	var db := content()
	var lake := db.lake(SPOT)
	var image := LakeTexture.build_image(lake)
	assert_eq(image.get_size(), Vector2i(lake.width, lake.height), "ızgara boyunda")
	var channel := _cell(image, lake, Vector2(-20.5, -16.0))
	assert_true(channel.a > 0.95, "derede akıntı tam güçte (%.2f)" % channel.a)
	assert_true(_cell(image, lake, Vector2(0.0, -3.0)).a < 0.01, "iskele koyunda akıntı yok")
	var shore := _cell(image, lake, Vector2(0.0, -3.0)).g * LakeTexture.SHORE_SPAN + LakeTexture.SHORE_MIN
	assert_between(shore, lake.shore_distance(Vector2(0.0, -3.0)) - 0.15, lake.shore_distance(Vector2(0.0, -3.0)) + 0.15,
			"kıyı uzaklığı ızgarayla aynı")
	var home := db.lake("home_lake")
	var still := LakeTexture.build_image(home)
	assert_true(_cell(still, home, Vector2.ZERO).a < 0.01, "testlerin gölünde akıntı yok")


func test_ground_data() -> void:
	var db := content()
	var lake := db.lake(SPOT)
	var area := lake.water_bounds.grow(10.0)
	var image := LakeTexture.ground_image(lake, area, PackedInt32Array([lake.zone_index("rocky_point")]))
	assert_true(_ground(image, area, Vector2(0.0, 10.0)).r > 0.5, "köy yürünebilir")
	assert_true(_ground(image, area, Vector2(-3.5, -26.0)).r < 0.5, "gölün kuzeyi orman")
	var rocky: Vector2 = (db.zone(SPOT, "rocky_point")["stands"] as Array)[0]
	# Atış noktasının doğusu kayalık burnun karası (güneyi nilüferli koyun).
	assert_true(_ground(image, area, rocky + Vector2(2.0, 0.0)).g > 0.5, "kayalık burnun karası taşlık")
	assert_true(_ground(image, area, Vector2(0.0, 10.0)).g < 0.5, "köyde taşlık yok")


static func _cell(image: Image, lake: LakeShape, p: Vector2) -> Color:
	var x := clampi(floori((p.x - lake.origin.x) / LakeShape.CELL), 0, lake.width - 1)
	var y := clampi(floori((p.y - lake.origin.y) / LakeShape.CELL), 0, lake.height - 1)
	return image.get_pixel(x, y)


static func _ground(image: Image, area: Rect2, p: Vector2) -> Color:
	var x := clampi(floori((p.x - area.position.x) / LakeTexture.GROUND_STEP), 0, image.get_width() - 1)
	var y := clampi(floori((p.y - area.position.y) / LakeTexture.GROUND_STEP), 0, image.get_height() - 1)
	return image.get_pixel(x, y)
