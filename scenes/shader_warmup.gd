class_name ShaderWarmup
extends CanvasLayer
## Gölgelendirici ısındırma (Kazı'dan, docs/performans-notlari.md §2.1). Compatibility çizicisi her malzemeyi ilk
## çizildiği karede derler (telefonda onlarca, yüzlerce ms); derleme anahtarı malzeme ile ışık ve sis düzenidir. Olta'da
## gölün ışığı ve sisi oyun boyunca aynı düzende (gölgeli güneş, dolgu ışığı, derinlik sisi; lambalar gölgelendiricide,
## gök yok), ama sonradan görünen malzemeler ilk göründükleri karede derleniyordu (tools/shader_compiles.py, perf
## --part=cold): ilk atışta şamandıra, ilk balıkta balığın gölgelendiricisi ve dış çizgisi, gölge ve su halkası (filmde
## de), ilk gecede ateşböcekleri, ilk yağmurda damlalar, kelebekler, derin ortanın şamandıraları, dolabın önizlemesi
## (kendi dünyası). Açılışta, açılış görseliyle aynı perdenin (logo) arkasında bunların hepsi birkaç kare çizilir;
## derlenenler Godot'nun gölgelendirici önbelleğine (user://shader_cache) yazılır, sonraki açılışlarda oradan yüklenir.
## Perde FRAMES kare sonra kalkar (derleme o karelerde olur; telefonda ilk açılışta biraz uzun sürer).
## Isındırmaya ışık kaynağı konmaz (çevresini "ışıklı" derletirdi).

signal finished

## Isındırma kareleri: ilk ikisi balıkçının önü (raf), üçüncüsü derin ortanın şamandıraları, dördüncüsü yine raf.
const FRAMES := 4
const DEEP_FRAME := 2
## Perdenin sönmesi (sn).
const FADE := 0.2

var _cover: Control
var _shelf: Node3D
var _temporary: Array[Node] = []


## main: oyunun ana düğümü (kamera, göl, gölgeler, halkalar). Bittiğinde perde söner, düğüm kendini siler.
func run(main: Node) -> void:
	name = "ShaderWarmup"
	layer = 120
	var started := Time.get_ticks_msec()
	var frame_ms := PackedStringArray()
	_build_cover()
	_build_shelf(main)
	var built := Time.get_ticks_msec()
	var last := built
	# Derin ortaya bakış: kamera bir kare oraya, sonra eski yerine (film oynuyorsa kameraya dokunulmaz: film açılışın
	# çekimini bir kez verir, logo boyunca kamerayı yeniden yazmaz).
	var camera: FollowCamera = main.get("camera")
	var free_camera: bool = main.get("_film") == null
	var saved := camera.target
	var saved_zoom := camera.zoom
	var saved_pitch := camera.pitch
	for i in FRAMES:
		if free_camera and i == DEEP_FRAME:
			var deep := _deep_point()
			if deep.is_finite():
				camera.snap(deep)
		elif free_camera and i == DEEP_FRAME + 1:
			camera.zoom = saved_zoom
			camera.pitch = saved_pitch
			camera.snap(saved)
		await RenderingServer.frame_post_draw
		frame_ms.append(str(Time.get_ticks_msec() - last))
		last = Time.get_ticks_msec()
	_clear()
	print("Gölgelendiriciler ısındı: %d kare, %d ms (kurulum %d ms; kareler %s ms)" % [FRAMES,
			Time.get_ticks_msec() - started, built - started, " + ".join(frame_ms)])
	var tween := create_tween()
	tween.tween_property(_cover, "modulate:a", 0.0, FADE)
	await tween.finished
	finished.emit()
	queue_free()


## Açılış görseliyle aynı: projenin açılış rengi, ortada logo (açılış görseli gibi kendi boyunda).
func _build_cover() -> void:
	_cover = Control.new()
	_cover.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cover.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_cover)
	var back := ColorRect.new()
	back.color = ProjectSettings.get_setting("application/boot_splash/bg_color", Color(0.16, 0.45, 0.52))
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_cover.add_child(back)
	var art := ItemArt.art("logo.png")
	if art == null:
		return
	var logo := TextureRect.new()
	logo.texture = art
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	# Açılış görseli pencerenin pikselinde kendi boyunda: tuvalin birimine çevrilir.
	var view := get_viewport().get_visible_rect().size
	var window := Vector2(DisplayServer.window_get_size())
	var px := view.y / maxf(1.0, window.y)
	var size := Vector2(art.get_size()) * px
	logo.size = size
	logo.position = (view - size) * 0.5
	_cover.add_child(logo)


## Raf: balıkçının önündeki suda, oyunda sonradan görünen her şeyden birer tane; perdenin altında dolabın önizlemesi.
func _build_shelf(main: Node) -> void:
	var db := GameState.db
	var save := GameState.save
	var angler: Angler = main.get("angler")
	var water := angler.pos2() + angler.facing.normalized() * 3.0
	var at := Vector3(water.x, 0.0, water.y)
	_shelf = Node3D.new()
	_shelf.name = "ShaderWarmup"
	(main.get("scene") as Node).add_child(_shelf)
	# Balık gölgesi (filmdeki dev gölge de aynı gölgelendirici) ve su halkası (havuza döner).
	var ghost: MeshInstance3D = (main.get("shadows") as ShadowLayer).make_ghost(2.0)
	ghost.position = at + Vector3(0.0, ShadowLayer.Y, 0.0)
	(ghost.material_override as ShaderMaterial).set_shader_parameter("fade", 1.0)
	_temporary.append(ghost)
	# Halka perde kalkmadan biter (önbellek ısınıkken perde birkaç karede kalkar).
	(main.get("ripples") as Ripples).spawn(water, 0.8, 0.05)
	# Suya atılan takımın dört görünüşü (şamandıra, yapay yem, kurşun, sinek) ve parıltısı.
	var bobber := Bobber.new()
	_shelf.add_child(bobber)
	# Kendi _process'i parıltıyı ve kurşunu her kare gizler: durdurulur.
	bobber.set_process(false)
	bobber.position = at + Vector3(-0.4, 0.15, 0.0)
	_show_all(bobber)
	# Tutulan balık (dış çizgisiyle) ve Gölün Sırrı'nın şişesi.
	var def := db.fish_by_id("rudd")
	if not def.is_empty():
		var fish := FishMesh.make(def, 0.5)
		_shelf.add_child(fish)
		fish.position = at + Vector3(0.4, 0.4, 0.0)
	var bottle := BottleMarker.new()
	_shelf.add_child(bottle)
	bottle.show_at(water + Vector2(0.0, 0.5))
	# Nadir balığın ışık sütunu (saydam, toplanan).
	var beam := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.1
	cylinder.bottom_radius = 0.1
	cylinder.height = 0.5
	beam.mesh = cylinder
	var beam_material := CatchFx.beam_material(Color.WHITE)
	beam_material.albedo_color = Color(1, 1, 1, 0.5)
	beam.material_override = beam_material
	beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_shelf.add_child(beam)
	beam.position = at + Vector3(0.0, 0.6, 0.3)
	# Sahnede kurulmuş ama henüz görünmemiş (gizli, uzakta) her malzeme bir kez.
	_sweep(main, at + Vector3(0.0, 0.8, -0.3))
	# Yağmur, ateşböcekleri, kelebekler (her biri kendi düğümünde, hemen dolu).
	for kind: String in ["rain", "fireflies", "butterflies"]:
		var particles := AmbientParticles.new()
		_shelf.add_child(particles)
		particles.set_kind(kind)
		particles.preprocess = 1.0
		particles.restart()
		particles.follow(at)
	# Dolabın önizlemesi (kendi dünyası: sissiz, gölgesiz bir düzen): perdenin altında.
	var preview := AnglerPreview.new()
	preview.size = Vector2(320, 480)
	add_child(preview)
	move_child(preview, 0)
	preview.show_look(save.character)
	preview.set_outfit(Outfits.look(db, save))
	_temporary.append(preview)


## Gölün dünyasındaki bütün 3B malzemeler (gizli düğümlerinkiler ve sonraki geçişleri de) rafta küçük birer dörtgenle
## çizilir: oyunda ilk kez göründüklerinde (derin ortanın süsleri, sandaldaki parçalar) derlenmesinler. MultiMesh'te
## kullanılanlar tek örnekli bir MultiMesh'le (çizim düzenleri ayrı).
func _sweep(main: Node, origin: Vector3) -> void:
	var world := main.get_viewport().find_world_3d()
	var plain := {}
	var multi := {}
	for node in main.find_children("*", "GeometryInstance3D", true, false):
		var item := node as GeometryInstance3D
		if _shelf.is_ancestor_of(item) or item.get_world_3d() != world:
			continue
		var found: Array[Material] = []
		found.append(item.material_override)
		found.append(item.material_overlay)
		var mesh: Mesh = null
		if item is MeshInstance3D:
			mesh = (item as MeshInstance3D).mesh
			for i in (item as MeshInstance3D).get_surface_override_material_count():
				found.append((item as MeshInstance3D).get_surface_override_material(i))
		elif item is MultiMeshInstance3D and (item as MultiMeshInstance3D).multimesh != null:
			mesh = (item as MultiMeshInstance3D).multimesh.mesh
		elif item is CPUParticles3D:
			mesh = (item as CPUParticles3D).mesh
		if mesh != null:
			for i in mesh.get_surface_count():
				found.append(mesh.surface_get_material(i))
		var instanced := item is MultiMeshInstance3D or item is CPUParticles3D
		for material in found:
			while material != null:
				(multi if instanced else plain)[material] = true
				material = material.next_pass
	var quad := QuadMesh.new()
	quad.size = Vector2(0.04, 0.04)
	var k := 0
	for material: Material in plain:
		var part := MeshInstance3D.new()
		part.mesh = quad
		part.material_override = material
		_shelf.add_child(part)
		part.position = origin + Vector3(0.05 * (k % 16), 0.05 * (k >> 4), 0.0)
		k += 1
	for material: Material in multi:
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.use_custom_data = true
		mm.mesh = quad
		mm.instance_count = 1
		var part := MultiMeshInstance3D.new()
		part.multimesh = mm
		part.material_override = material
		_shelf.add_child(part)
		part.position = origin + Vector3(0.05 * (k % 16), 0.05 * (k >> 4), 0.0)
		k += 1
	# Arayüzün kendi gölgelendiricileri (harita): perdenin altında küçük birer dikdörtgen.
	var canvas := 0
	for node in main.find_children("*", "CanvasItem", true, false):
		var item := node as CanvasItem
		if item.material is ShaderMaterial and not is_ancestor_of(item):
			var rect := ColorRect.new()
			rect.size = Vector2(8, 8)
			rect.material = item.material
			rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
			add_child(rect)
			move_child(rect, 0)
			_temporary.append(rect)
			canvas += 1
	print("Isındırma rafı: %d malzeme, %d MultiMesh malzemesi, %d arayüz malzemesi" % [plain.size(), multi.size(), canvas])


## Derin ortanın ilk şamandırası (sandalın gittiği yer; yoksa INF).
func _deep_point() -> Vector3:
	var db := GameState.db
	for z in db.zones_of(db.main_spot):
		var buoys: Array = z.get("buoys", [])
		if not buoys.is_empty():
			var p: Vector2 = buoys[0]
			return Vector3(p.x, 0.0, p.y)
	return Vector3.INF


## Düğümün bütün parçaları görünür (gizli görünüşleri de derlensin).
static func _show_all(root: Node3D) -> void:
	root.visible = true
	for node in root.find_children("*", "Node3D", true, false):
		(node as Node3D).visible = true


func _clear() -> void:
	for node in _temporary:
		if is_instance_valid(node):
			node.queue_free()
	_temporary.clear()
	if is_instance_valid(_shelf):
		_shelf.queue_free()
