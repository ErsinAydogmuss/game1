extends BaseTest
## Hazır modeller: balıkçı (KayKit Rogue), Dede (KayKit Barbarian) ve Nine (KayKit Mage) başsız
## yüklenir; gereken parçalar, yuvalar, kemikler ve animasyonlar yerinde (paket güncellenince adlar
## değişirse burada yakalanır). Göl çevresinin modelleri listede ve dosyaları var. Balık ağı her tür
## için kurulur. Balıkçı Dede'nin içinden geçmez ama içinde kalırsa dışarı çıkabilir. Nine'nin
## dükkânı az çizimle kurulur; Nine tezgâhın arkasında durur, tezgâhın önü serbesttir.
## Göl süsleri bir paketin modellerini tek ağda birleştirir; dükkânın ve kampın yerini boş bırakır.

## Göl sahnesinin en çok çizimi (her ağ bir, gölgesi bir daha; ekranda olmayan bölgeler sayılır).
const SCENE_DRAWS := 50


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


## Bir paketin farklı modelleri tek ağda birleşir (üçgenleri toplanır); uzak bölgeler ayrı ağ olur.
func test_merge_combines_models_by_chunk() -> void:
	var root := Node3D.new()
	var tree_only: Array[Array] = [["tree_1a", Transform3D.IDENTITY]]
	var rock_only: Array[Array] = [["rock_3a", Transform3D.IDENTITY]]
	var both: Array[Array] = [["tree_1a", Transform3D.IDENTITY], ["rock_3a", Transform3D(Basis.IDENTITY, Vector3(2, 0, 1))]]
	var merged := ModelLibrary.merge(root, "Both", both, 20.0)
	assert_eq(merged.size(), 1, "aynı bölgedeki iki model tek ağ")
	if merged.size() == 1:
		var faces := merged[0].mesh.get_faces().size()
		var tree_faces := ModelLibrary.merge(root, "Tree", tree_only)[0].mesh.get_faces().size()
		var rock_faces := ModelLibrary.merge(root, "Rock", rock_only)[0].mesh.get_faces().size()
		assert_eq(faces, tree_faces + rock_faces, "birleşik ağ iki modelin üçgenlerini taşır")
	var far: Array[Array] = [["tree_1a", Transform3D.IDENTITY], ["tree_1a", Transform3D(Basis.IDENTITY, Vector3(45, 0, 0))]]
	assert_eq(ModelLibrary.merge(root, "Far", far, 20.0).size(), 2, "uzak bölgeler ayrı ağ")
	assert_between(ModelLibrary.bounds("rock_3g").size.y, 0.8, 3.0, "büyük kaya ölçekle ~1-2 m")
	assert_between(ModelLibrary.bounds("boat").size.z, 1.6, 3.2, "sandal ~2-3 m")
	root.free()


## Göl süsleri dükkânın ve kampın yerine, iskelenin üstüne düşmez; sahne az çizimle kurulur.
func test_lake_scenery_keeps_clear_and_cheap() -> void:
	var db := content()
	var lake := db.lake(db.main_spot)
	var scene := LakeScene.new()
	scene.keep_clear.append(Vector3(-2.7, 8.4, 2.4))
	scene.setup(lake)
	var occupied: Array[Vector3] = scene.get("_occupied")
	assert_true(occupied.size() > 50, "süsler yerleşti (%d)" % occupied.size())
	var bad := 0
	for c in occupied:
		var p := Vector2(c.x, c.y)
		if lake.on_dock(p, 1.0):
			bad += 1
		for zone in scene.keep_clear:
			if p.distance_to(Vector2(zone.x, zone.y)) < zone.z + c.z - 0.001:
				bad += 1
	assert_eq(bad, 0, "iskeleye ve boş kalacak yerlere süs düşmez")
	var draws := 0
	for node in scene.find_children("*", "GeometryInstance3D", true, false):
		var geometry := node as GeometryInstance3D
		draws += 2 if geometry.cast_shadow != GeometryInstance3D.SHADOW_CASTING_SETTING_OFF else 1
	assert_true(draws <= SCENE_DRAWS, "göl sahnesi az çizimle kurulur (%d, gölgeler dahil)" % draws)
	scene.free()


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
