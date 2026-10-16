class_name FishPortrait
extends RefCounted
## Balık portreleri: her türün FishMesh'i açılışta bir kez, saydam arka planlı küçük bir
## görüntüye (SubViewport) çizilir; ItemArt.register_fish_portrait ile kartlara ve ikonlara verilir.
## Ersin'in balık görselleri gelince onlar kullanılır (ItemArt önce dosyaya bakar). Ekransız
## çalışmada (testler, headless) çizim olmaz; yer tutucu madalyon kalır.

const SIZE := 256


## Bütün balıkların portresini çizer (birkaç kare sürer; await ile beklenir).
static func render_all(parent: Node, db: ContentDB) -> void:
	if DisplayServer.get_name() == "headless":
		return
	for f in db.fish:
		await render(parent, f)


static func render(parent: Node, def: Dictionary) -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(SIZE, SIZE)
	viewport.transparent_bg = true
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	parent.add_child(viewport)
	var world := Node3D.new()
	viewport.add_child(world)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_CLEAR_COLOR
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("#e6eefc")
	env.environment.ambient_light_energy = 0.7
	world.add_child(env)
	var sun := DirectionalLight3D.new()
	world.add_child(sun)
	sun.look_at_from_position(Vector3(0.6, 1.2, 1.5), Vector3.ZERO, Vector3.UP)
	var fish := FishMesh.make(def, 1.0)
	fish.set_wiggle(0.0, 0.0)
	# Hafifçe eğik: hem yandan hem biraz yukarıdan.
	fish.rotation = Vector3(deg_to_rad(-12.0), deg_to_rad(-18.0), deg_to_rad(8.0))
	world.add_child(fish)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 1.15
	world.add_child(camera)
	camera.look_at_from_position(Vector3(0.0, 0.25, 3.0), Vector3.ZERO, Vector3.UP)
	camera.current = true
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	if image != null and not image.is_empty():
		image.generate_mipmaps()
		ItemArt.register_fish_portrait(str(def["id"]), ImageTexture.create_from_image(image))
	viewport.queue_free()
