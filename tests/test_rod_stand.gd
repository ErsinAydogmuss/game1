extends BaseTest
## Dipteki sehpa (RodStand) balıkçının yanına konur ve atış yönüne bakar; o yanda yer yoksa (iskele
## kenarı, su) öteki yanına, o da yoksa arkasına.


func test_stand_goes_beside_the_angler() -> void:
	var stand := RodStand.new()
	var everywhere := func(_p: Vector2) -> bool: return true
	stand.place(Vector3(0, 0.5, 4), Vector2(0, -1), everywhere)
	assert_true(stand.position.distance_to(Vector3(RodStand.SIDE, 0.5, 4 - RodStand.AHEAD)) < 0.001,
			"sağ yanında, biraz önde (%s)" % str(stand.position))
	var forward := -stand.basis.z
	assert_true(forward.distance_to(Vector3(0, 0, -1)) < 0.001, "atış yönüne bakar (%s)" % str(forward))
	stand.free()


func test_stand_finds_room_on_the_other_side_or_behind() -> void:
	var stand := RodStand.new()
	# Sağ yan su (x > 0.3): sol yana.
	var left_only := func(p: Vector2) -> bool: return p.x < 0.3
	stand.place(Vector3(0, 0, 0), Vector2(0, -1), left_only)
	assert_true(stand.position.x < 0.0, "öteki yanına (%s)" % str(stand.position))
	# İki yan da su (iskelenin ucu dar): arkasına.
	var behind_only := func(p: Vector2) -> bool: return absf(p.x) < 0.2 and p.y > 0.0
	stand.place(Vector3(0, 0, 0), Vector2(0, -1), behind_only)
	assert_true(stand.position.z > 0.0 and absf(stand.position.x) < 0.001, "arkasına (%s)" % str(stand.position))
	stand.free()
