class_name PortraitStudio
extends RefCounted
## Bir 3D nesnenin küçük resmini çeker: kendi dünyası olan saydam bir SubViewport'ta, dik
## izdüşümlü kamerayla birkaç kare çizip görüntüyü alır. Kartlardaki balık resimleri
## (FishPortrait) ve ipucu çubuğundaki Dede yüzü buradan gelir. Ekransız çalışmada (testler,
## headless) SubViewport çizilmez: null döner.


## subject sahneye eklenir, resimden sonra silinir. eye → target: kamera; size: dik izdüşümün
## yüksekliği (m); pixels: kare resmin kenarı; frames: resimden önce beklenen kare (iskeletli
## modelin duruşu oturana kadar).
static func shoot(parent: Node, subject: Node3D, eye: Vector3, target: Vector3, size: float,
		pixels: int, frames: int = 2) -> Texture2D:
	if DisplayServer.get_name() == "headless":
		subject.free()
		return null
	var viewport := SubViewport.new()
	viewport.size = Vector2i(pixels, pixels)
	viewport.transparent_bg = true
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
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
	sun.look_at_from_position(target + Vector3(0.6, 1.2, 1.5), target, Vector3.UP)
	world.add_child(subject)
	var camera := Camera3D.new()
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = size
	world.add_child(camera)
	camera.look_at_from_position(eye, target, Vector3.UP)
	camera.current = true
	for i in frames:
		await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	viewport.queue_free()
	if image == null or image.is_empty():
		return null
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)
