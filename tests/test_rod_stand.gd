extends BaseTest
## Dipteki sehpa (RodStand) balıkçının yanına konur ve atış yönüne bakar; o yanda yer yoksa (iskele
## kenarı, su) öteki yanına, o da yoksa arkasına (önce biraz yana kayık); sandalda küpeştede.


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


func test_stand_behind_keeps_the_rod_clear_and_boat_is_closer() -> void:
	var stand := RodStand.new()
	# Yanlar su, arkada yer var: önce biraz sağa kayık (atış yönüne uzanan kamış balıkçıdan geçmesin).
	var behind := func(p: Vector2) -> bool: return p.y > 0.0 and absf(p.x) < 0.5
	stand.place(Vector3.ZERO, Vector2(0, -1), behind)
	assert_true(stand.position.z > 0.0 and absf(stand.position.x - RodStand.BEHIND_SIDE) < 0.001,
			"arkada, biraz yanda (%s)" % str(stand.position))
	# Sandalda küpeştede: teknenin içinde kalacak kadar yakın.
	var everywhere := func(_p: Vector2) -> bool: return true
	stand.place(Vector3.ZERO, Vector2(0, -1), everywhere, RodStand.BOAT_SIDE)
	assert_true(absf(stand.position.x - RodStand.BOAT_SIDE) < 0.001 and RodStand.BOAT_SIDE < 0.45,
			"sandalda yakın (%s)" % str(stand.position))
	stand.free()


## Sehpadaki kamış kuşanılan dip kamışı: değişince yeniden kurulur, zil yeni kamışın ucunda.
func test_stand_rod_follows_the_equipped_rod() -> void:
	var stand := RodStand.new()
	stand.build()
	assert_eq(stand.rod.style, "bottom", "dip kamışı")
	stand.set_rod("rod_carp_3", "reel_master")
	assert_eq(stand.rod.gear_id, "rod_carp_3", "kuşanılan kamış")
	assert_eq(stand.rod.reel_id, "reel_master", "kuşanılan makara")
	var bell := stand.find_child("Bell", true, false)
	assert_true(bell != null and bell.get_parent() == stand.rod.tip, "zil yeni kamışın ucunda")
	var rods := 0
	for child in stand.get_children():
		if child is RodModel:
			rods += 1
	assert_eq(rods, 1, "sehpada tek kamış")
	stand.free()


func test_rod_rests_on_both_supports() -> void:
	# Kamışın altı arka desteğin ve ön çatalın yüksekliğinde: ön çatal arkadan yüksek (kamış yükselir).
	var rear := RodStand.rest_height(RodStand.REAR_Z, 0.03)
	var front := RodStand.rest_height(RodStand.FRONT_Z, 0.026)
	assert_true(rear > 0.2 and front > rear + 0.3 and front < 1.0, "arka %.2f, ön %.2f m" % [rear, front])
