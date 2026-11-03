class_name AquariumTank
extends Control
## Akvaryum panelinin canlı tankı (Dalga 5, docs/gdd.md §10.6). Üç kat: arka plan (Ersin'in aquarium_bg
## görseli; yoksa kodla: derinleşen su, ışık hüzmeleri, kum, taşlar, uzak bitkiler), kendi dünyası olan saydam
## bir SubViewport'ta yüzen balıklar (her türün en irisi; FishMesh, dış çizgisiz: balık başına bir çizim) ve
## ön kat (öndeki bitkiler, yükselen kabarcıklar). Çerçeve en üstte. Balıklar görünür alanın içinde kendi
## şeritlerinde gidip döner, hafifçe iner kalkar; kerevit kumda yürür. Yerleşim türün sırasından tohumlanır:
## her açılışta aynı. Tank yalnızca görünürken çizilir.

## Kamera: dikey görüş açısı ve balıkların düzlemine uzaklık (m).
const FOV := 30.0
const CAMERA_Z := 6.0
## Balıkların derinlik aralığı (kameradan uzak → yakın) ve görünür alanın kenarından payı (m).
const DEPTH := Vector2(-1.4, 0.7)
const MARGIN := 0.35
## Tankta balığın boyu: elde gösterilen boyun bu katı (FishMesh.display_length; küçük balık da seçilsin).
const LENGTH_SCALE := 0.95
## Yüzme hızı (m/sn; boyla biraz artar) ve dönüş süresi (sn).
const SPEED := Vector2(0.32, 0.55)
const TURN_TIME := 0.7
const WATER_TOP := Color("#8fd8ea")
const WATER_DEEP := Color("#2a78a3")
const SAND := Color("#e3c88f")
const SAND_DARK := Color("#c7a96c")
const STONE := Color("#7d858c")
const PLANT := Color("#3f8f45")
const PLANT_LIGHT := Color("#6cbf5a")
const FRAME := Color("#4a2f1a")
const BUBBLES := 9

var _viewport: SubViewport
var _world: Node3D
var _camera: Camera3D
var _back: _Layer
var _front: _Layer
var _art: TextureRect
var _empty: Label
## Yüzen balıklar: { node, dir, speed, lane_y, z, phase, turn (0 = dönmüyor), crawl }.
var _swimmers: Array[Dictionary] = []
var _ids: PackedStringArray = []
var _time := 0.0


func _init() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_art = TextureRect.new()
	_art.texture = ItemArt.art("aquarium_bg.png")
	_art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_art.visible = _art.texture != null
	_art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(_art)
	_back = _Layer.new(self, false)
	_back.visible = _art.texture == null
	add_child(_back)
	var container := SubViewportContainer.new()
	container.stretch = true
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(container)
	_viewport = SubViewport.new()
	_viewport.transparent_bg = true
	_viewport.own_world_3d = true
	_viewport.msaa_3d = Viewport.MSAA_2X
	_viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	container.add_child(_viewport)
	_world = Node3D.new()
	_viewport.add_child(_world)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_CLEAR_COLOR
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("#d6f0ff")
	env.environment.ambient_light_energy = 0.75
	_world.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.light_color = Color("#fff6e0")
	sun.light_energy = 1.1
	_world.add_child(sun)
	sun.rotation = Vector3(deg_to_rad(-55.0), deg_to_rad(20.0), 0.0)
	_camera = Camera3D.new()
	_camera.fov = FOV
	_camera.position = Vector3(0.0, 0.0, CAMERA_Z)
	_camera.current = true
	_world.add_child(_camera)
	_front = _Layer.new(self, true)
	add_child(_front)
	var frame := Panel.new()
	var style := StyleBoxFlat.new()
	style.draw_center = false
	style.border_color = FRAME
	style.set_border_width_all(12)
	style.set_corner_radius_all(6)
	frame.add_theme_stylebox_override("panel", style)
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(frame)
	_empty = UiKit.ink("", UiKit.SIZE_BODY, Color.WHITE)
	_empty.add_theme_color_override("font_outline_color", Color("#1d4a66"))
	_empty.add_theme_constant_override("outline_size", 12)
	_empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_empty.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_empty.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_empty.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_empty.offset_left = 60
	_empty.offset_right = -60
	add_child(_empty)


## Tanktaki balıklar (Aquarium.fish); aynı türler gelirse yüzenler yerinde kalır.
func show_fish(tank: Array[Dictionary], db: ContentDB) -> void:
	var ids := PackedStringArray()
	for f in tank:
		ids.append("%s:%d" % [str(f["fish"]), int(f["size_cm"])])
	_empty.text = tr("UI_AQUARIUM_EMPTY") if tank.is_empty() else ""
	if ids == _ids:
		return
	_ids = ids
	for s in _swimmers:
		(s["node"] as Node).queue_free()
	_swimmers.clear()
	for i in tank.size():
		var def := db.fish_by_id(str(tank[i]["fish"]))
		if def.is_empty():
			continue
		_swimmers.append(_make_swimmer(def, int(tank[i]["size_cm"]), i, tank.size()))


## Yüzen balık sayısı (bot ve testler).
func swimmer_count() -> int:
	return _swimmers.size()


func _make_swimmer(def: Dictionary, size_cm: int, index: int, count: int) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(def["id"])) ^ 9173
	var length := FishMesh.display_length(size_cm) * LENGTH_SCALE * FishMesh.show_scale(def)
	var fish := FishMesh.make(def, length)
	fish.set_wiggle(0.09, 5.0)
	# Dış çizgisiz (balık başına bir çizim): make malzemeyi kopyaladı, yalnızca bu balığınki değişir.
	(fish.material_override as ShaderMaterial).next_pass = null
	fish.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_world.add_child(fish)
	var crawl := FishMesh.is_crayfish(def)
	# Şeritler türler arasında dağılır: sıra yüksekliği, tohum derinliği ve yönü seçer.
	var lane := lerpf(0.85, -0.75, (float(index) + 0.5) / float(maxi(1, count)))
	var z := rng.randf_range(DEPTH.x, DEPTH.y)
	var swimmer := {
		"node": fish,
		"dir": 1.0 if rng.randf() < 0.5 else -1.0,
		"speed": lerpf(SPEED.x, SPEED.y, clampf(length, 0.0, 1.0)) * (0.35 if crawl else rng.randf_range(0.85, 1.15)),
		"lane_y": -1.25 if crawl else lane + rng.randf_range(-0.12, 0.12),
		"z": 0.3 if crawl else z,
		"phase": rng.randf() * TAU,
		"turn": 0.0,
		"crawl": crawl,
		"half": length * 0.5,
	}
	var half_w := _half_width(float(swimmer["z"])) - MARGIN - float(swimmer["half"])
	fish.position = Vector3(rng.randf_range(-half_w, half_w), float(swimmer["lane_y"]), float(swimmer["z"]))
	_face(swimmer, 0.0)
	return swimmer


## z derinliğinde görünen alanın yarı genişliği (m).
func _half_width(z: float) -> float:
	var box := size if size.y > 0.0 else custom_minimum_size
	var aspect := box.x / box.y if box.y > 0.0 else 2.0
	return (CAMERA_Z - z) * tan(deg_to_rad(FOV * 0.5)) * aspect


func _half_height(z: float) -> float:
	return (CAMERA_Z - z) * tan(deg_to_rad(FOV * 0.5))


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_time += delta
	for s in _swimmers:
		_swim(s, delta)
	_front.queue_redraw()


func _swim(s: Dictionary, delta: float) -> void:
	var fish: FishMesh = s["node"]
	var dir := float(s["dir"])
	var turn := float(s["turn"])
	var limit := _half_width(float(s["z"])) - MARGIN - float(s["half"])
	if turn > 0.0:
		turn = minf(1.0, turn + delta / TURN_TIME)
		if turn >= 1.0:
			s["dir"] = -dir
			dir = -dir
			turn = 0.0
		s["turn"] = turn
	else:
		var p := fish.position
		p.x += dir * float(s["speed"]) * delta
		if (dir > 0.0 and p.x > limit) or (dir < 0.0 and p.x < -limit):
			p.x = clampf(p.x, -limit, limit)
			s["turn"] = 0.0001
		fish.position.x = p.x
	var bob := 0.0 if bool(s["crawl"]) else sin(_time * 0.9 + float(s["phase"])) * 0.07
	var top := _half_height(float(s["z"])) - 0.35
	fish.position.y = clampf(float(s["lane_y"]) + bob, -top, top)
	_face(s, turn)


## Balık yüzdüğü yöne bakar (model +X'e bakar); dönerken yarım tur atar.
func _face(s: Dictionary, turn: float) -> void:
	var fish: FishMesh = s["node"]
	var right := float(s["dir"]) > 0.0
	var t := smoothstep(0.0, 1.0, turn)
	# Dönerken başı kameradan uzağa döner (tankın içine doğru yarım tur): kameraya ağzını dayamasın.
	fish.rotation = Vector3(0.0, (0.0 + PI * t) if right else (PI - PI * t), 0.0)


## Arka ve ön kat: kodla çizilen su, ışık, kum, taş ve bitkiler; önde bitkiler ve kabarcıklar. Her kat tek
## üçgen dizisi (tek çizim).
class _Layer:
	extends Control

	var _tank: AquariumTank
	var _front: bool

	func _init(tank: AquariumTank, front: bool) -> void:
		_tank = tank
		_front = front
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		resized.connect(queue_redraw)

	func _draw() -> void:
		var points := PackedVector2Array()
		var colors := PackedColorArray()
		var w := size.x
		var h := size.y
		if _front:
			_front_layer(points, colors, w, h)
		else:
			_back_layer(points, colors, w, h)
		if points.is_empty():
			return
		var indices := PackedInt32Array()
		for i in points.size():
			indices.append(i)
		RenderingServer.canvas_item_add_triangle_array(get_canvas_item(), indices, points, colors)

	func _back_layer(points: PackedVector2Array, colors: PackedColorArray, w: float, h: float) -> void:
		# Su: yukarıda açık, aşağıda koyu.
		_quad(points, colors, [Vector2(0, 0), Vector2(w, 0), Vector2(w, h), Vector2(0, h)],
				[AquariumTank.WATER_TOP, AquariumTank.WATER_TOP, AquariumTank.WATER_DEEP, AquariumTank.WATER_DEEP])
		# Işık hüzmeleri: yüzeyden eğik inen soluk şeritler.
		for spec: Vector3 in [Vector3(0.18, 0.08, 0.5), Vector3(0.46, 0.1, 0.42), Vector3(0.74, 0.07, 0.48)]:
			var x := spec.x * w
			var top_w := spec.y * w
			var bottom := Vector2(x - 0.12 * w, h * 0.92)
			var light := Color(1, 1, 1, 0.13)
			var clear := Color(1, 1, 1, 0.0)
			_quad(points, colors, [Vector2(x, 0), Vector2(x + top_w, 0), bottom + Vector2(top_w * 1.6, 0), bottom],
					[light, light, clear, clear])
		# Uzak bitkiler (koyu).
		for i in 7:
			var x := (0.07 + i * 0.145) * w
			var tall := (0.28 + 0.14 * float((i * 5) % 3)) * h
			_blade(points, colors, Vector2(x, h * 0.86), tall, 0.022 * w, 0.06 * w * (1.0 if i % 2 == 0 else -1.0),
					AquariumTank.PLANT.darkened(0.25))
		# Kum: dalgalı tepe.
		var sand_top := h * 0.84
		var steps := 16
		for i in steps:
			var x0 := w * i / float(steps)
			var x1 := w * (i + 1) / float(steps)
			var y0 := sand_top + sin(i * 0.9) * h * 0.02
			var y1 := sand_top + sin((i + 1) * 0.9) * h * 0.02
			_quad(points, colors, [Vector2(x0, y0), Vector2(x1, y1), Vector2(x1, h), Vector2(x0, h)],
					[AquariumTank.SAND, AquariumTank.SAND, AquariumTank.SAND_DARK, AquariumTank.SAND_DARK])
		# Taşlar.
		for spec: Vector3 in [Vector3(0.12, 0.9, 0.05), Vector3(0.62, 0.92, 0.07), Vector3(0.86, 0.89, 0.04)]:
			_ellipse(points, colors, Vector2(spec.x * w, spec.y * h), Vector2(spec.z * w, spec.z * w * 0.55),
					AquariumTank.STONE)

	func _front_layer(points: PackedVector2Array, colors: PackedColorArray, w: float, h: float) -> void:
		# Öndeki bitkiler köşelerde (balıkları örtmesin).
		for spec: Vector4 in [Vector4(0.03, 0.42, 0.03, 0.05), Vector4(0.06, 0.3, 0.025, -0.04), Vector4(0.95, 0.38, 0.03, -0.05),
				Vector4(0.92, 0.26, 0.022, 0.04)]:
			_blade(points, colors, Vector2(spec.x * w, h), spec.y * h, spec.z * w, spec.w * w, AquariumTank.PLANT_LIGHT)
		# Kabarcıklar: sağ köşedeki taştan yükselir, yüzeyde söner.
		var t := _tank._time
		for i in AquariumTank.BUBBLES:
			var life := fposmod(t * 0.22 + i / float(AquariumTank.BUBBLES), 1.0)
			var x := w * (0.84 + 0.02 * sin(t * 2.0 + i)) + (i % 3) * 6.0
			var y := h * (0.9 - 0.85 * life)
			var r := 4.0 + (i % 3) * 2.0
			_ellipse(points, colors, Vector2(x, y), Vector2(r, r), Color(1, 1, 1, 0.55 * (1.0 - life * 0.6)))

	## Dörtgen (iki üçgen; köşe renkleriyle).
	static func _quad(points: PackedVector2Array, colors: PackedColorArray, p: Array, c: Array) -> void:
		for i: int in [0, 1, 2, 0, 2, 3]:
			points.append(p[i])
			colors.append(c[i])

	## Kumdan yükselen kıvrık yaprak (alttan üste daralan şerit).
	static func _blade(points: PackedVector2Array, colors: PackedColorArray, root: Vector2, tall: float, width: float,
			bend: float, color: Color) -> void:
		var steps := 6
		for i in steps:
			var a := i / float(steps)
			var b := (i + 1) / float(steps)
			var ca := root + Vector2(bend * a * a, -tall * a)
			var cb := root + Vector2(bend * b * b, -tall * b)
			var wa := width * (1.0 - a * 0.85)
			var wb := width * (1.0 - b * 0.85)
			_quad(points, colors, [ca - Vector2(wa, 0), ca + Vector2(wa, 0), cb + Vector2(wb, 0), cb - Vector2(wb, 0)],
					[color, color.lightened(0.08), color.lightened(0.15), color.lightened(0.05)])

	static func _ellipse(points: PackedVector2Array, colors: PackedColorArray, center: Vector2, radius: Vector2,
			color: Color) -> void:
		var sides := 10
		for i in sides:
			var a := TAU * i / sides
			var b := TAU * (i + 1) / sides
			points.append(center)
			points.append(center + Vector2(cos(a), sin(a)) * radius)
			points.append(center + Vector2(cos(b), sin(b)) * radius)
			colors.append(color.lightened(0.1))
			colors.append(color)
			colors.append(color)
