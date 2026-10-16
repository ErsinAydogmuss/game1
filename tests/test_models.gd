extends BaseTest
## Hazır modeller: balıkçı (KayKit Rogue), Dede (KayKit Barbarian) ve Nine (KayKit Mage) başsız
## yüklenir; gereken parçalar, yuvalar, kemikler ve animasyonlar yerinde (paket güncellenince adlar
## değişirse burada yakalanır). Göl çevresinin modelleri listede ve dosyaları var. Balık ağı her tür
## için kurulur. Balıkçı Dede'nin içinden geçmez ama içinde kalırsa dışarı çıkabilir. Nine'nin
## dükkânı az çizimle kurulur; Nine tezgâhın arkasında durur, tezgâhın önü serbesttir.


func test_angler_model_has_parts_and_animations() -> void:
	assert_true(AnglerBody.available(), "balıkçı modeli ve dokusu var")
	if not AnglerBody.available():
		return
	var model := (load(AnglerBody.SCENE_PATH) as PackedScene).instantiate() as Node3D
	for part: String in AnglerBody.REQUIRED_NODES:
		assert_true(model.find_child(part, true, false) != null, "modelde parça yok: " + part)
	var skeleton := model.find_child("Skeleton3D", true, false) as Skeleton3D
	if skeleton != null:
		for bone: String in AnglerBody.REQUIRED_BONES:
			assert_true(skeleton.find_bone(bone) >= 0, "iskelette kemik yok: " + bone)
	for part: String in AnglerBody.HIDDEN:
		assert_true(model.find_child(part, true, false) != null, "gizlenecek parça yok (adı değişmiş olabilir): " + part)
	var player := model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	assert_true(player != null, "animasyon oynatıcı var")
	if player != null:
		for anim: String in AnglerBody.REQUIRED_ANIMS:
			assert_true(player.has_animation(anim), "animasyon yok: " + anim)
	model.free()


func test_elder_model_has_parts_and_animations() -> void:
	assert_true(ElderBody.available(), "Dede modeli ve dokusu var")
	if not ElderBody.available():
		return
	var model := (load(ElderBody.SCENE_PATH) as PackedScene).instantiate() as Node3D
	for part: String in ElderBody.REQUIRED_NODES:
		assert_true(model.find_child(part, true, false) != null, "Dede modelinde parça yok: " + part)
	var skeleton := model.find_child("Skeleton3D", true, false) as Skeleton3D
	if skeleton != null:
		for bone: String in ElderBody.REQUIRED_BONES:
			assert_true(skeleton.find_bone(bone) >= 0, "Dede iskeletinde kemik yok: " + bone)
		# Oturarak sevinçte bacaklar süzülür: süzgeçteki kemik adları iskelette olmalı.
		for bone: String in CharacterKit.LOWER_BODY:
			assert_true(skeleton.find_bone(bone) >= 0, "alt gövde kemiği yok: " + bone)
	for part: String in ElderBody.HIDDEN:
		assert_true(model.find_child(part, true, false) != null, "gizlenecek parça yok (adı değişmiş olabilir): " + part)
	var player := model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	assert_true(player != null, "Dede'nin animasyon oynatıcısı var")
	if player != null:
		for anim: String in ElderBody.REQUIRED_ANIMS:
			assert_true(player.has_animation(anim), "Dede animasyonu yok: " + anim)
		var cheer := CharacterKit.one_shot(player, ElderBody.CHEER_ANIM, 0.1, 0.1, true)
		assert_true(cheer.filter_enabled, "oturarak sevinç yalnızca üst gövdeyi oynatır")
	model.free()


func test_nine_model_has_parts_and_animations() -> void:
	assert_true(NineBody.available(), "Nine modeli ve dokusu var")
	if not NineBody.available():
		return
	var model := (load(NineBody.SCENE_PATH) as PackedScene).instantiate() as Node3D
	for part: String in NineBody.REQUIRED_NODES:
		assert_true(model.find_child(part, true, false) != null, "Nine modelinde parça yok: " + part)
	var skeleton := model.find_child("Skeleton3D", true, false) as Skeleton3D
	if skeleton != null:
		for bone: String in NineBody.REQUIRED_BONES:
			assert_true(skeleton.find_bone(bone) >= 0, "Nine iskeletinde kemik yok: " + bone)
		for bone: String in CharacterKit.LOWER_BODY:
			assert_true(skeleton.find_bone(bone) >= 0, "alt gövde kemiği yok: " + bone)
	for part: String in NineBody.HIDDEN:
		assert_true(model.find_child(part, true, false) != null, "gizlenecek parça yok (adı değişmiş olabilir): " + part)
	var player := model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	assert_true(player != null, "Nine'nin animasyon oynatıcısı var")
	if player != null:
		for anim: String in NineBody.REQUIRED_ANIMS:
			assert_true(player.has_animation(anim), "Nine animasyonu yok: " + anim)
	model.free()


func test_shop_stall_layout() -> void:
	var tree := Engine.get_main_loop() as SceneTree
	var stall := ShopStall.new()
	tree.root.add_child(stall)
	stall.build(Vector3(2.0, 0.2, 3.0), Vector2(1.0, 0.0))
	assert_true(stall.facing().distance_to(Vector2(1.0, 0.0)) < 0.001, "dükkân önüne bakar")
	var keeper := stall.keeper_spot()
	assert_between(keeper.x, 2.0 - ShopStall.DEPTH + 0.3, 2.0 - ShopStall.COUNTER_D, "Nine tezgâhla duvarın arasında")
	assert_between(keeper.y, 0.3, 0.4, "Nine döşemenin üstünde")
	var inside := Vector2(keeper.x, keeper.z)
	var front := Vector2(2.6, 3.0)
	var inside_blocked := false
	var front_blocked := false
	for b in stall.blockers():
		var center := Vector2(b.x, b.y)
		inside_blocked = inside_blocked or center.distance_to(inside) < b.z
		front_blocked = front_blocked or center.distance_to(front) < b.z + Angler.BODY
	assert_true(inside_blocked, "balıkçı dükkânın içine giremez")
	assert_true(not front_blocked, "tezgâhın önünde durulur")
	var draws := stall.find_children("*", "GeometryInstance3D", true, false).size()
	assert_true(draws <= 6, "dükkân az çizimle kurulur (%d)" % draws)
	stall.free()


func test_angler_slides_around_blockers() -> void:
	var list: Array[Vector3] = [Vector3(0.0, 0.0, 0.4)]
	assert_eq(Angler.avoid(list, Vector2(1.0, 0.0), Vector2(-0.5, 0.0)), Vector2.ZERO, "tam karşıdan gelen durur")
	var from := Vector2(0.7, -0.4)
	var slid := Angler.avoid(list, from, Vector2(-0.5, 0.0))
	assert_true(slid.length() > 0.1, "yandan gelen kayar")
	assert_true((from + slid).length() >= from.length() - 0.001, "kayan adım engele yaklaşmaz")
	assert_eq(Angler.avoid(list, Vector2(0.3, 0.0), Vector2(0.2, 0.0)), Vector2(0.2, 0.0), "engelin içinden dışarı çıkılır")
	assert_eq(Angler.avoid(list, Vector2(2.0, 0.0), Vector2(-0.5, 0.0)), Vector2(-0.5, 0.0), "uzaktaki adım serbest")


func test_scenery_models_exist() -> void:
	for id: String in ModelLibrary.MODELS:
		assert_true(ModelLibrary.has(id), "model dosyası yok: " + id)


func test_every_fish_builds_a_mesh() -> void:
	for f in content().fish:
		var mesh := FishMesh.mesh_for(f)
		assert_true(mesh != null and mesh.get_surface_count() == 1, "%s: balık ağı kurulur" % f["id"])
		if mesh != null:
			var box := mesh.get_aabb()
			assert_between(box.size.x, 0.95, 1.15, "%s: boyu ~1 birim" % f["id"])
			assert_true(box.size.y < box.size.x * 0.75, "%s: boyu yüksekliğinden uzun" % f["id"])
	var pike := FishMesh.mesh_for(content().fish_by_id("pike")).get_aabb()
	var carp := FishMesh.mesh_for(content().fish_by_id("carp")).get_aabb()
	assert_true(pike.size.y < carp.size.y, "turna sazandan daha ince uzun")
	assert_between(FishMesh.display_length(15), 0.29, 0.31, "15 cm balık elde 0,3 m")
	assert_true(FishMesh.display_length(250) <= 1.1, "250 cm yayın en fazla 1,1 m görünür")
	assert_true(FishMesh.display_length(120) > FishMesh.display_length(30), "büyük balık büyük görünür")
