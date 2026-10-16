extends BaseTest
## Hazır modeller: balıkçı (KayKit Rogue) ve Dede (KayKit Barbarian) başsız yüklenir; gereken
## parçalar, yuvalar, kemikler ve animasyonlar yerinde (paket güncellenince adlar değişirse burada
## yakalanır). Göl çevresinin modelleri listede ve dosyaları var. Balık ağı her tür için kurulur.
## Balıkçı Dede'nin içinden geçmez ama içinde kalırsa dışarı çıkabilir.


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
