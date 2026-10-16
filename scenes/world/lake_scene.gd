class_name LakeScene
extends Node3D
## Gölün sahnesi: ışık ve ortam, kıyıya doğru hafifçe yükselen arazi, su, iskele, sazlar ve
## çevre (KayKit ağaçları, kayalar, tepeler, iskelenin yanında küçük bir kamp).
## Su ve zemin, göl şeklinden (LakeShape) üretilen tek bir veri dokusunu paylaşır (LakeTexture).
## Hazır modeller yoksa (ModelLibrary.has) kodla kurulan basit parçalar (Props) kullanılır.
## Gölge yalnızca ağaçlardan, iskeleden, kamp eşyalarından ve karakterlerden düşer.

## İskele güvertesinin su üstündeki yüksekliği (m).
const DOCK_HEIGHT := 0.35
## Kara, kıyıdan BANK_RISE metrede BANK metre yükselir (hafif bir set).
const BANK := 0.22
const BANK_RISE := 2.5
## Kıyı çizgisinde zeminin su yüzeyinin altında kaldığı pay (m).
const SHORE_DIP := 0.05
## Arazi ağı aralığı (m) ve suyun çevresinde kapladığı pay.
const TERRAIN_STEP := 0.5
const TERRAIN_MARGIN := 6.0
## Ağın dışındaki düz zeminin genişliği (m).
const OUTER_SIZE := 70.0
const SKY := Color("#a9d2ef")
const WOOD := Color("#9b6a3c")
const WOOD_DARK := Color("#6e4526")

var lake: LakeShape
var data_texture: ImageTexture
var environment: Environment

var _rng := RandomNumberGenerator.new()


func setup(shape: LakeShape) -> void:
	lake = shape
	data_texture = LakeTexture.build(lake)
	_rng.seed = 7
	_build_environment()
	_build_terrain()
	_build_water()
	_build_dock()
	_build_reeds()
	_build_scenery()


## Zemin yüksekliği: karada kıyıdan uzaklaştıkça BANK'a çıkar; suyun altı iner (opak suyun
## altında görünmez). Kıyı çizgisinin iki yanında zemin suyun biraz altındadır: görünen kıyı,
## ağın kaba üçgenleri değil, suyun pürüzsüz kenarı olur.
func ground_height(p: Vector2) -> float:
	var shore := lake.shore_distance(p)
	if shore >= 0.0:
		return -SHORE_DIP - 0.3 * smoothstep(0.0, 1.5, shore)
	return -SHORE_DIP + (BANK + SHORE_DIP) * smoothstep(0.35, BANK_RISE, -shore)


## Balıkçının duracağı yükseklik: iskelede güverte, karada zemin.
func stand_height(p: Vector2) -> float:
	return DOCK_HEIGHT + 0.04 if lake.on_dock(p) else maxf(ground_height(p), 0.0)


# --- Işık ve ortam -------------------------------------------------------------------

func _build_environment() -> void:
	environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = SKY
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("#d4e4f7")
	environment.ambient_light_energy = 0.5
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	environment.tonemap_white = 6.0
	environment.glow_enabled = true
	environment.glow_intensity = 0.7
	environment.glow_bloom = 0.03
	environment.glow_hdr_threshold = 0.95
	environment.fog_enabled = true
	environment.fog_mode = Environment.FOG_MODE_EXPONENTIAL
	environment.fog_light_color = SKY
	environment.fog_density = 0.006
	environment.fog_sky_affect = 0.0
	environment.adjustment_enabled = true
	environment.adjustment_contrast = 1.08
	environment.adjustment_saturation = 1.16
	var world := WorldEnvironment.new()
	world.environment = environment
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.light_color = Color("#fff1db")
	sun.light_energy = 1.15
	sun.shadow_enabled = true
	sun.shadow_blur = 1.5
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.directional_shadow_max_distance = 30.0
	add_child(sun)
	# Işık kameranın arkasından, biraz soldan gelsin: görünen yüzler aydınlık olsun.
	sun.look_at_from_position(Vector3.ZERO, Vector3(-0.35, -1.0, -0.55), Vector3.UP)
	var fill := DirectionalLight3D.new()
	fill.light_color = Color("#b9d4ff")
	fill.light_energy = 0.35
	add_child(fill)
	fill.look_at_from_position(Vector3.ZERO, Vector3(0.6, -0.5, 0.4), Vector3.UP)


# --- Arazi ve su -----------------------------------------------------------------------

## Gölün çevresinde ızgara ağ (kıyıya doğru hafif set), dışında düz büyük bir zemin.
func _build_terrain() -> void:
	var material := _shader_material("res://scenes/world/ground.gdshader")
	var area := lake.water_bounds.grow(TERRAIN_MARGIN)
	var cols := ceili(area.size.x / TERRAIN_STEP)
	var rows := ceili(area.size.y / TERRAIN_STEP)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for j in rows + 1:
		for i in cols + 1:
			var p := area.position + Vector2(i, j) * TERRAIN_STEP
			st.set_uv(Vector2(float(i) / cols, float(j) / rows))
			st.add_vertex(Vector3(p.x, ground_height(p), p.y))
	for j in rows:
		for i in cols:
			var a := j * (cols + 1) + i
			var b := a + 1
			var c := a + cols + 1
			var d := c + 1
			st.add_index(a)
			st.add_index(b)
			st.add_index(c)
			st.add_index(b)
			st.add_index(d)
			st.add_index(c)
	st.generate_normals()
	var terrain := MeshInstance3D.new()
	terrain.name = "Terrain"
	terrain.mesh = st.commit()
	terrain.material_override = material
	terrain.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(terrain)
	# Dışarısı: ağın çevresinde dört düz şerit (ortası boş: suyu örtmesin).
	var outer := area.grow(OUTER_SIZE)
	var strips: Array[Rect2] = [
		Rect2(outer.position, Vector2(outer.size.x, area.position.y - outer.position.y)),
		Rect2(Vector2(outer.position.x, area.end.y), Vector2(outer.size.x, outer.end.y - area.end.y)),
		Rect2(Vector2(outer.position.x, area.position.y), Vector2(area.position.x - outer.position.x, area.size.y)),
		Rect2(Vector2(area.end.x, area.position.y), Vector2(outer.end.x - area.end.x, area.size.y)),
	]
	for r in strips:
		var plane := PlaneMesh.new()
		plane.size = r.size + Vector2(0.02, 0.02)
		var strip := MeshInstance3D.new()
		strip.name = "Ground"
		strip.mesh = plane
		strip.position = Vector3(r.get_center().x, BANK, r.get_center().y)
		strip.material_override = material
		strip.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(strip)


func _build_water() -> void:
	var bounds := lake.water_bounds.grow(0.5)
	var plane := PlaneMesh.new()
	plane.size = bounds.size
	var water := MeshInstance3D.new()
	water.name = "Water"
	water.mesh = plane
	water.position = Vector3(bounds.get_center().x, 0.0, bounds.get_center().y)
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	water.material_override = _shader_material("res://scenes/world/water.gdshader")
	add_child(water)


func _shader_material(path: String) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = load(path)
	LakeTexture.apply(material, lake, data_texture)
	return material


# --- İskele ve sazlar --------------------------------------------------------------------

## İskele: enine tahtalar, iki yanda kiriş, ayaklar (Props). Uzun kenarı z boyunca.
func _build_dock() -> void:
	var dock := Props.pivot(self, Vector3.ZERO, "Dock")
	var rect := lake.dock
	var plank := 0.3
	var count := maxi(1, int(rect.size.y / (plank + 0.04)))
	for i in count:
		var z := rect.position.y + (float(i) + 0.5) * rect.size.y / count
		var shade := WOOD if i % 2 == 0 else WOOD.darkened(0.08)
		Props.box(dock, Vector3(rect.size.x, 0.08, plank), Vector3(rect.get_center().x, DOCK_HEIGHT, z), shade)
	for side: float in [-1.0, 1.0]:
		var x := rect.get_center().x + side * (rect.size.x * 0.5 - 0.06)
		Props.box(dock, Vector3(0.1, 0.12, rect.size.y), Vector3(x, DOCK_HEIGHT - 0.09, rect.get_center().y), WOOD_DARK)
	var post_z := rect.position.y + 0.15
	while post_z < rect.end.y:
		for side: float in [-1.0, 1.0]:
			var x := rect.get_center().x + side * (rect.size.x * 0.5 - 0.08)
			Props.cylinder(dock, 0.09, 0.09, 1.2, Vector3(x, -0.2, post_z), WOOD_DARK, 6)
		post_z += 1.4
	# Ucunda iki kısa direk (halat bağı).
	for side: float in [-1.0, 1.0]:
		var x := rect.get_center().x + side * (rect.size.x * 0.5 - 0.08)
		Props.cylinder(dock, 0.07, 0.08, 0.35, Vector3(x, DOCK_HEIGHT + 0.2, rect.position.y + 0.15), WOOD_DARK, 6)


## Kıyı boyunca saz kümeleri: sallanan ince yapraklar ve kamış başları (iki MultiMesh).
func _build_reeds() -> void:
	var blades: Array[Transform3D] = []
	var heads: Array[Transform3D] = []
	var bounds := lake.water_bounds.grow(1.0)
	var clusters := 0
	var tries := 0
	while clusters < 26 and tries < 4000:
		tries += 1
		var c := Vector2(_rng.randf_range(bounds.position.x, bounds.end.x), _rng.randf_range(bounds.position.y, bounds.end.y))
		var shore := lake.shore_distance(c)
		if shore < -0.35 or shore > 0.45 or lake.on_dock(c, 2.2):
			continue
		clusters += 1
		for k in _rng.randi_range(6, 11):
			var p := c + Dice.in_disc(_rng, 0.32)
			var height := _rng.randf_range(0.7, 1.3)
			var yaw := _rng.randf() * TAU
			var basis := Basis(Vector3.UP, yaw).scaled(Vector3(1.0, height, 1.0))
			var y := minf(ground_height(p), 0.0) - 0.05
			blades.append(Transform3D(basis, Vector3(p.x, y, p.y)))
			if _rng.randf() < 0.3:
				heads.append(Transform3D(Basis(Vector3.UP, yaw), Vector3(p.x, y + height * 0.96, p.y)))
	_multimesh(_blade_mesh(), blades, false)
	var head := CapsuleMesh.new()
	head.radius = 0.035
	head.height = 0.2
	head.radial_segments = 6
	head.rings = 2
	_multimesh(head, heads, true)


## Sivri uçlu ince yaprak: 4 katlı şerit (yükseklik 0..1; UV.y tepeye doğru 1).
func _blade_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	var levels := 4
	for i in levels + 1:
		var t := float(i) / levels
		var half := 0.03 * (1.0 - t * 0.85)
		st.set_normal(Vector3(0, 0, 1))
		st.set_uv(Vector2(0.0, t))
		st.add_vertex(Vector3(-half, t, 0.0))
		st.set_normal(Vector3(0, 0, 1))
		st.set_uv(Vector2(1.0, t))
		st.add_vertex(Vector3(half, t, 0.0))
	return st.commit()


func _multimesh(mesh: Mesh, transforms: Array[Transform3D], rigid: bool) -> void:
	if transforms.is_empty():
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = transforms.size()
	for i in transforms.size():
		mm.set_instance_transform(i, transforms[i])
	var material := ShaderMaterial.new()
	material.shader = load("res://scenes/world/reeds.gdshader")
	material.set_shader_parameter("rigid_top", rigid)
	if rigid:
		material.set_shader_parameter("base_color", Color("#6b4426"))
	var node := MultiMeshInstance3D.new()
	node.multimesh = mm
	node.material_override = material
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(node)


# --- Çevre -------------------------------------------------------------------------------

func _build_scenery() -> void:
	if not ModelLibrary.has("trees_a_large"):
		_build_fallback_trees()
		return
	var center := lake.water_bounds.get_center()
	# Uzakta tepeler ve dağlar: çerçeve.
	var far: Array[Array] = [
		["mountain_a", Vector2(-24, -24), 0.4], ["mountain_b", Vector2(4, -30), 2.2], ["hills", Vector2(26, -20), 1.1],
		["hills", Vector2(-34, -2), 3.0], ["mountain_b", Vector2(-14, -34), 5.0], ["hills", Vector2(30, 6), 4.4],
	]
	for f in far:
		var p: Vector2 = center + (f[1] as Vector2)
		_spawn(f[0], p, f[2], 1.0, false)
	# Ağaç kümeleri: kumsalın dışında; iskelenin önünü (kameraya yakın taraf) boş bırak.
	var groups := ["trees_a_large", "trees_a_medium", "trees_b_large", "trees_b_medium", "trees_a_small", "trees_b_small"]
	var placed := 0
	var tries := 0
	var area := lake.water_bounds.grow(12.0)
	while placed < 18 and tries < 3000:
		tries += 1
		var p := Vector2(_rng.randf_range(area.position.x, area.end.x), _rng.randf_range(area.position.y, area.end.y))
		var shore := lake.shore_distance(p)
		if shore > -3.2 or _near_camera_side(p):
			continue
		_spawn(groups[placed % groups.size()], p, _rng.randf() * TAU, _rng.randf_range(0.85, 1.15), true)
		placed += 1
	# Tek ağaçlar kıyıya biraz daha yakın.
	placed = 0
	tries = 0
	while placed < 7 and tries < 3000:
		tries += 1
		var p := Vector2(_rng.randf_range(area.position.x, area.end.x), _rng.randf_range(area.position.y, area.end.y))
		var shore := lake.shore_distance(p)
		if shore > -2.4 or shore < -4.5 or _near_camera_side(p):
			continue
		_spawn("tree_a" if placed % 2 == 0 else "tree_b", p, _rng.randf() * TAU, _rng.randf_range(0.8, 1.1), true)
		placed += 1
	# Kayalar: kumsalda ve kıyının hemen içinde.
	placed = 0
	tries = 0
	var rocks := ["rock_a", "rock_b", "rock_c", "rock_d", "rock_e"]
	var near := lake.water_bounds.grow(2.0)
	while placed < 12 and tries < 3000:
		tries += 1
		var p := Vector2(_rng.randf_range(near.position.x, near.end.x), _rng.randf_range(near.position.y, near.end.y))
		var shore := lake.shore_distance(p)
		if shore < -1.4 or shore > 0.35 or lake.on_dock(p, 1.5):
			continue
		_spawn(rocks[placed % rocks.size()], p, _rng.randf() * TAU, _rng.randf_range(0.6, 1.1), true)
		placed += 1
	_build_camp()


## İskelenin kara ucunun yanında küçük bir balıkçı kampı (ileride Dede'nin yeri).
func _build_camp() -> void:
	var dock := lake.dock
	var land := Vector2(dock.get_center().x, dock.end.y)
	_spawn("tent", land + Vector2(4.2, 1.6), deg_to_rad(-120.0), 1.0, true)
	_spawn("barrel", land + Vector2(1.6, 0.2), 0.3, 1.0, true)
	_spawn("crate", land + Vector2(2.3, 0.7), 0.9, 1.0, true)
	_spawn("sack", land + Vector2(1.9, 1.1), 0.0, 1.0, true)
	_spawn("lumber", land + Vector2(5.6, -0.4), 1.2, 0.9, true)
	_spawn("lantern_post", land + Vector2(-1.15, -1.6), 0.0, 1.0, true)
	_spawn("bench", land + Vector2(-2.3, -0.6), deg_to_rad(15.0), 1.0, true)
	var bucket := ModelLibrary.spawn(self, "bucket", Vector3(dock.get_center().x - 0.45, DOCK_HEIGHT + 0.04, dock.position.y + 0.55), 0.4)
	if bucket != null:
		_set_shadows(bucket, true)


## Kameraya yakın taraf: iskelenin arkası (kamera +x +z yönünde). Ağaçlar balıkçıyı örtmesin.
func _near_camera_side(p: Vector2) -> bool:
	var dock := lake.dock
	return p.y > dock.position.y - 1.0 and p.x > dock.get_center().x - 7.0 and p.x < dock.get_center().x + 14.0


func _spawn(id: String, p: Vector2, yaw: float, size: float, shadows: bool) -> void:
	var node := ModelLibrary.spawn(self, id, Vector3(p.x, maxf(ground_height(p), -0.05), p.y), yaw, size)
	if node != null:
		_set_shadows(node, shadows)


static func _set_shadows(root: Node, on: bool) -> void:
	for node in root.find_children("*", "GeometryInstance3D", true, false):
		(node as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if on \
				else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## Modeller yoksa kodla basit ağaçlar ve kayalar.
func _build_fallback_trees() -> void:
	var far := lake.water_bounds.grow(9.0)
	var placed := 0
	var tries := 0
	while placed < 26 and tries < 2000:
		tries += 1
		var p := Vector2(_rng.randf_range(far.position.x, far.end.x), _rng.randf_range(far.position.y, far.end.y))
		if lake.shore_distance(p) > -3.0 or _near_camera_side(p):
			continue
		var size := _rng.randf_range(0.8, 1.3)
		var y := ground_height(p)
		Props.cylinder(self, 0.12 * size, 0.16 * size, 0.9 * size, Vector3(p.x, y + 0.45 * size, p.y), WOOD_DARK, 6)
		Props.cylinder(self, 0.0, 0.9 * size, 2.2 * size, Vector3(p.x, y + 1.9 * size, p.y), Color("#3f8f4a"), 7)
		placed += 1
