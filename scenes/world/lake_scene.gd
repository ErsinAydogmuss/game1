class_name LakeScene
extends Node3D
## Gölün sahnesi: ışık ve ortam, kıyıya doğru hafifçe yükselen arazi, su, iskele, sazlar ve
## çevre (KayKit orman paketi: ağaçlar, çalılar, çimen, yosunlu kayalar; kodla nilüfer ve çiçekler;
## Kenney kamp eşyaları, iskeleye bağlı sandal, kilitli bölgelerin çitleri, derin ortanın
## şamandıraları; uzakta tepeler). Süsler bölge bölge kurulur (her bölgenin takımı ZONE_KITS, kendi
## seed'i): bir bölgede sayı değişince ötekilerin süsleri kaymaz.
## Su ve zemin, göl şeklinden (LakeShape) üretilen tek bir veri dokusunu paylaşır (LakeTexture);
## zeminin ayrıca yürünebilen dünya ve taşlık dokusu var (çimen, orman zemini, yosunlu taş, kıyı
## yolu, kum; Ersin'in zemin karoları gelince onlarla). Çalı, çimen öbeği, çiçek ve yakın ağaçlar
## kıyı yoluna düşmez (yolun kıvrımı shader'la aynı formül: path_wobble).
## Hazır modeller yoksa (ModelLibrary.has) kodla kurulan basit parçalar (Props) kullanılır.
## Gölge ağaçlardan, kayalardan, iskeleden, kamp eşyalarından, sandaldan ve karakterlerden düşer.
## Çizim sayısı az tutulur: iskele tek ağ (köşe renkli), bir paketin modelleri bölge parçalarında
## tek ağ (ModelLibrary.merge), nilüfer ve çiçekler tek ağ (MeshBatch), arazinin opak suyun
## altında kalan kareleri hiç kurulmaz.

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
## Zemin dokusunun arazi ağının dışına taşan payı (m; yürünebilen dünyanın kenarı içinde kalsın).
const GROUND_PAD := 4.0
## Kıyı yolu: ortasının kıyıdan uzaklığı ve yarı genişliği (m; ground.gdshader path_at, path_half).
## Genişlik shader'da 0,8–1,2 katı arasında değişir; süsler en genişine göre uzak durur.
const PATH_AT := 2.6
const PATH_HALF := 0.42
## Ersin'in zemin karoları (Parti 3, tools/process_images.gd keser): hepsi varsa zemin onlarla çizilir.
const GROUND_TILES := {
	"grass_tex": "res://assets/textures/ground/grass.png",
	"sand_tex": "res://assets/textures/ground/sand.png",
	"path_tex": "res://assets/textures/ground/path.png",
	"stone_tex": "res://assets/textures/ground/moss_stone.png",
}
## Dört köşesi kıyıdan bu kadar içeride (suyun altında) olan arazi kareleri kurulmaz (su opak).
const HIDDEN_UNDER_WATER := 0.3
const SKY := Color("#a9d2ef")
const WOOD := Color("#9b6a3c")
const WOOD_DARK := Color("#6e4526")
## Hazır modeller var mı diye bakılan ağaç (yoksa kodla basit ağaçlar).
const FOREST_CHECK := "tree_1a"
const FOREST_TEXTURE := "res://assets/models/kaykit_forest/forest_texture.png"
## Orman parçalarının bölge boyu (m): her bölge tek ağ, ekranın dışındaki bölge çizilmez. Izgara
## gölün ortasına göre: kıyıdaki kayalar ve çalılar ortadaki tek bölgeye düşer.
const CHUNK := 30.0
const NEAR_TREES: Array[String] = ["tree_1a", "tree_1b", "tree_3a", "tree_3b"]
const FAR_TREES: Array[String] = ["tree_1a", "tree_1b", "tree_1c", "tree_3b", "tree_4a", "tree_4b"]
const BUSHES: Array[String] = ["bush_1c", "bush_1e", "bush_1f", "bush_3b"]
const GRASSES: Array[String] = ["grass_1c", "grass_2c"]
const SMALL_ROCKS: Array[String] = ["rock_3a", "rock_3c", "rock_3e"]
const BIG_ROCKS: Array[String] = ["rock_3g", "rock_3j", "rock_3l"]
const ROCK_CLUSTERS := 12
## Arkadaki orman: koru sayısı ve bir korunun yarıçapı (m).
const GROVES := 16
const GROVE_RADIUS := 3.2
## Kayanın boyunun gömülen payı (kumda ya da suda oturur, havada durmaz).
const ROCK_SINK := 0.28
const LILY_CLUSTERS := 7
## Nilüfer yaprağının çentiğinin yarı açısı.
const LILY_NOTCH := 0.3
const LOTUS_CHANCE := 0.35
const FLOWER_CLUSTERS := 18
const LILY := Color("#4f9a3c")
const LILY_LIGHT := Color("#68b04a")
const LOTUS := Color("#f48fb6")
const LOTUS_LIGHT := Color("#ffc6da")
const POLLEN := Color("#ffd23f")
const DAISY_COLORS: Array[Color] = [Color("#fbf7ee"), Color("#fff4dc"), Color("#ffd54a"), Color("#f7a8c8")]
## Kampın ocağı, iskelenin kara ucuna göre (m).
const CAMP := Vector2(4.2, 1.9)
## Sandal: iskelenin -x kenarından uzaklığı, suya uzanan ucundan kıyıya doğru yeri, su
## yüzeyine göre yüksekliği, dönüşü ve boyunun yarısı (m).
const BOAT_SIDE := 1.3
const BOAT_ALONG := 1.5
const BOAT_Y := -0.12
const BOAT_YAW := 0.0
const BOAT_HALF := 1.1
## Sandalda duran balıkçının ayaklarının sandalın ortasına göre yüksekliği ve şamandıraya göre
## sandalın yeri (şamandıra balıkçının önünde, kameranın karşı yanında görünsün).
const BOAT_FLOOR := 0.1
const BUOY_MOOR := Vector2(0.7, 2.2)
const SCENERY_SEED := 7
## Bölgenin süs takımı: küme ve kopya sayıları, sazların ve nilüferlerin kıyı bandı (m; suda +),
## büyük kaya payı. Eski şemadaki göl ("main") ve iskele koyu bugünkü göl gibi.
const DEFAULT_KIT := {
	"reeds": 26, "reed_band": Vector2(-0.35, 0.45), "lilies": 7, "lily_band": Vector2(0.7, 1.9), "lotus": LOTUS_CHANCE,
	"rocks": ROCK_CLUSTERS, "big_rocks": 0.5, "near": 14, "groves": GROVES, "far": 16, "bushes": 14, "bushes_far": 10,
	"grass": 46, "flowers": FLOWER_CLUSTERS,
}
const ZONE_KITS := {
	"main": DEFAULT_KIT,
	"dock_cove": DEFAULT_KIT,
	# Sazlık: sığ suyun içine kadar sık kamış.
	"reeds": { "reeds": 46, "reed_band": Vector2(-0.35, 1.3), "lilies": 3, "lily_band": Vector2(0.9, 2.0), "lotus": 0.2,
		"rocks": 3, "big_rocks": 0.3, "near": 6, "groves": 5, "far": 6, "bushes": 10, "bushes_far": 6, "grass": 30, "flowers": 8 },
	# Nilüferli koy: koyun yarısını kaplayan nilüfer tarlası, bol çiçek.
	"lily_cove": { "reeds": 8, "reed_band": Vector2(-0.35, 0.45), "lilies": 24, "lily_band": Vector2(0.5, 3.2), "lotus": 0.6,
		"rocks": 4, "big_rocks": 0.3, "near": 6, "groves": 5, "far": 6, "bushes": 8, "bushes_far": 6, "grass": 22, "flowers": 14 },
	# Kayalık burun: iri yosunlu kayalar, dik kıyı, karası yer yer taşlık (stone).
	"rocky_point": { "reeds": 3, "reed_band": Vector2(-0.35, 0.3), "lilies": 0, "lily_band": Vector2(0.7, 1.5), "lotus": 0.0,
		"rocks": 18, "big_rocks": 0.8, "near": 5, "groves": 5, "far": 6, "bushes": 6, "bushes_far": 6, "grass": 12, "flowers": 4,
		"stone": true },
	# Dere ağzı: derenin iki yanında saz, taşlar.
	"stream_mouth": { "reeds": 14, "reed_band": Vector2(-0.35, 0.5), "lilies": 2, "lily_band": Vector2(0.6, 1.2), "lotus": 0.2,
		"rocks": 9, "big_rocks": 0.3, "near": 6, "groves": 6, "far": 8, "bushes": 8, "bushes_far": 6, "grass": 16, "flowers": 6 },
	# Derin orta: suyu kıyıya değmez; süsü şamandıralar.
	"deep_water": {},
}
## Çit parçasının boyu (m; ModelLibrary "fence") ve şamandıraların suya göre yüksekliği.
const FENCE_PIECE := 1.08
const BUOY_Y := -0.05

var lake: LakeShape
var data_texture: ImageTexture
var environment: Environment

## Süslerin girmeyeceği daireler (x, z, yarıçap): main dükkânın yerini setup'tan önce verir.
var keep_clear: Array[Vector3] = []

var _rng := RandomNumberGenerator.new()
## Toplu çizilecek modeller: "id|gölge" -> yerleşimler (_flush_batches).
var _batches: Dictionary = {}
## Yerleşmiş ağaç, kaya ve çalıların yerleri (x, z, yarıçap): üst üste binmesinler.
var _occupied: Array[Vector3] = []
## Kampın yeri (x, z, yarıçap).
var _camp := Vector3.ZERO
## Gölün bölgeleri (ContentDB; çitler ve şamandıralar için): main setup'tan önce verir.
var zones: Array[Dictionary] = []
## Kurulan bölge (sıra) ve takımı.
var _zone: int = -1
var _kit: Dictionary = DEFAULT_KIT
## Bölge kimliği -> çitin parçaları (bölge açılınca gizlenir).
var _gates: Dictionary = {}
var _buoys: Array[Node3D] = []
var _buoy_base: Array[Vector3] = []
var _boat: Node3D
var _boat_base := Vector3.ZERO
## Sandal iskeleden ayrıldı mı (balıkçı içinde, bir şamandıranın yanında)?
var _boat_away: bool = false
var _clock := 0.0


func setup(shape: LakeShape) -> void:
	lake = shape
	data_texture = LakeTexture.build(lake)
	_build_environment()
	_build_terrain()
	_build_water()
	_build_dock()
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
	if _boat_away and _boat != null and p.distance_to(Vector2(_boat_base.x, _boat_base.z)) < BOAT_HALF:
		return _boat.position.y + BOAT_FLOOR
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
	_apply_ground(material, area.grow(GROUND_PAD))
	var cols := ceili(area.size.x / TERRAIN_STEP)
	var rows := ceili(area.size.y / TERRAIN_STEP)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var under := PackedByteArray()
	under.resize((rows + 1) * (cols + 1))
	for j in rows + 1:
		for i in cols + 1:
			var p := area.position + Vector2(i, j) * TERRAIN_STEP
			st.set_uv(Vector2(float(i) / cols, float(j) / rows))
			st.add_vertex(Vector3(p.x, ground_height(p), p.y))
			under[j * (cols + 1) + i] = 1 if lake.shore_distance(p) > HIDDEN_UNDER_WATER else 0
	for j in rows:
		for i in cols:
			var a := j * (cols + 1) + i
			var b := a + 1
			var c := a + cols + 1
			var d := c + 1
			# Opak suyun altında kalan kare görünmez: kurulmaz (telefonda boşa piksel boyanmasın).
			if under[a] == 1 and under[b] == 1 and under[c] == 1 and under[d] == 1:
				continue
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


## Zemin dokusu (yürünebilen dünya, taşlık), kıyı yolu ve Ersin'in zemin karoları (hepsi varsa).
func _apply_ground(material: ShaderMaterial, area: Rect2) -> void:
	var stony := PackedInt32Array()
	for k in lake.zone_ids.size():
		var kit: Dictionary = ZONE_KITS.get(lake.zone_ids[k], {})
		if bool(kit.get("stone", false)):
			stony.append(k)
	LakeTexture.apply_ground(material, area, LakeTexture.build_ground(lake, area, stony))
	material.set_shader_parameter("path_at", PATH_AT)
	material.set_shader_parameter("path_half", PATH_HALF)
	var tiles := true
	for key: String in GROUND_TILES:
		tiles = tiles and ResourceLoader.exists(str(GROUND_TILES[key]))
	material.set_shader_parameter("use_tiles", tiles)
	if tiles:
		for key: String in GROUND_TILES:
			material.set_shader_parameter(key, load(str(GROUND_TILES[key])))


## Kıyı yolunun ortasının kıvrımı (m; ground.gdshader'daki path_wobble ile aynı formül).
static func path_wobble(p: Vector2) -> float:
	return 0.35 * sin(p.x * 0.31 + sin(p.y * 0.23) * 1.7) + 0.2 * sin(p.y * 0.57 + p.x * 0.11)


## Nokta kıyı yolunun üstünde mi (margin: yolun en geniş kenarından öte pay)? Yol yürünebilen
## dünyada çizilir. Uzaklık land_distance'tan: ızgaranın dışında da doğru (shore_distance orada
## −MARGIN'de durur).
func on_path(p: Vector2, margin: float = 0.0) -> bool:
	var lane := absf(lake.land_distance(p) + PATH_AT + path_wobble(p))
	return lane < PATH_HALF * 1.2 + margin and lake.in_world(p)


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

## İskele: enine tahtalar, iki yanda kiriş, ayaklar. Uzun kenarı z boyunca. Parçalar renk başına
## tek ağda birleşir (51 parça → 3 çizim).
func _build_dock() -> void:
	var dock := Props.pivot(self, Vector3.ZERO, "Dock")
	var rect := lake.dock
	var parts := MeshBatch.new()
	var plank := 0.3
	var count := maxi(1, int(rect.size.y / (plank + 0.04)))
	for i in count:
		var z := rect.position.y + (float(i) + 0.5) * rect.size.y / count
		var shade := WOOD if i % 2 == 0 else WOOD.darkened(0.08)
		_dock_part(parts, _box_mesh(Vector3(rect.size.x, 0.08, plank)), Vector3(rect.get_center().x, DOCK_HEIGHT, z), shade)
	for side: float in [-1.0, 1.0]:
		var x := rect.get_center().x + side * (rect.size.x * 0.5 - 0.06)
		_dock_part(parts, _box_mesh(Vector3(0.1, 0.12, rect.size.y)), Vector3(x, DOCK_HEIGHT - 0.09, rect.get_center().y), WOOD_DARK)
	var post_z := rect.position.y + 0.15
	while post_z < rect.end.y:
		for side: float in [-1.0, 1.0]:
			var x := rect.get_center().x + side * (rect.size.x * 0.5 - 0.08)
			_dock_part(parts, _post_mesh(0.09, 0.09, 1.2), Vector3(x, -0.2, post_z), WOOD_DARK)
		post_z += 1.4
	# Ucunda iki kısa direk (halat bağı).
	for side: float in [-1.0, 1.0]:
		var x := rect.get_center().x + side * (rect.size.x * 0.5 - 0.08)
		_dock_part(parts, _post_mesh(0.07, 0.08, 0.35), Vector3(x, DOCK_HEIGHT + 0.2, rect.position.y + 0.15), WOOD_DARK)
	parts.build(dock, "Planks")


## Parçayı birleşik ağa ekler (rengi köşe rengi: bütün iskele tek çizim).
static func _dock_part(parts: MeshBatch, mesh: PrimitiveMesh, pos: Vector3, color: Color) -> void:
	parts.add(mesh, Transform3D(Basis.IDENTITY, pos), color)


static func _box_mesh(size: Vector3) -> BoxMesh:
	var mesh := BoxMesh.new()
	mesh.size = size
	return mesh


static func _post_mesh(top_radius: float, bottom_radius: float, height: float) -> CylinderMesh:
	var mesh := CylinderMesh.new()
	mesh.top_radius = top_radius
	mesh.bottom_radius = bottom_radius
	mesh.height = height
	mesh.radial_segments = 6
	mesh.rings = 1
	return mesh


## Kıyı boyunca saz kümeleri: sallanan ince yapraklar ve kamış başları (iki MultiMesh, bütün
## bölgeler birlikte).
func _build_reeds(blades: Array[Transform3D], heads: Array[Transform3D]) -> void:
	var count := int(_kit.get("reeds", 0))
	var band: Vector2 = _kit.get("reed_band", Vector2(-0.35, 0.45))
	var bounds := _area(1.0)
	var clusters := 0
	var tries := 0
	while clusters < count and tries < count * 200:
		tries += 1
		var c := Vector2(_rng.randf_range(bounds.position.x, bounds.end.x), _rng.randf_range(bounds.position.y, bounds.end.y))
		var shore := lake.shore_distance(c)
		if shore < band.x or shore > band.y or lake.on_dock(c, 2.2) or not _mine(c):
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


func _flush_reeds(blades: Array[Transform3D], heads: Array[Transform3D]) -> void:
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

## Kıyı boyunca ve ötesinde (hedef ekran: docs/img/hedef_ekran.jpg): yosunlu kayalar, kıyıya yakın
## yuvarlak ağaçlar, arkada karışık orman, çalılar, çimen öbekleri, çiçekler; suda nilüferler;
## iskelenin yanında kamp ve bağlı sandal; uzakta tepeler. Orman parçaları (tek doku) bölge
## parçalarında tek ağda birleşir (ModelLibrary.merge), nilüfer ve çiçekler kodla tek ağ (MeshBatch).
func _build_scenery() -> void:
	var dock := lake.dock
	var land := Vector2(dock.get_center().x, dock.end.y)
	# Kampın yeri boş kalsın (çalı, çimen, kaya oraya düşmesin).
	_camp = Vector3(land.x + CAMP.x, land.y + CAMP.y, 2.1)
	keep_clear.append(_camp)
	var plants := MeshBatch.new()
	var blades: Array[Transform3D] = []
	var heads: Array[Transform3D] = []
	var rocks: Array[Array] = []
	var trees: Array[Array] = []
	var low: Array[Array] = []
	var forest := ModelLibrary.has(FOREST_CHECK)
	# Bölge bölge: her bölgenin kendi takımı ve kendi zarı.
	for k in lake.zone_ids.size():
		_zone = k
		_kit = ZONE_KITS.get(lake.zone_ids[k], DEFAULT_KIT)
		if _kit.is_empty():
			continue
		_rng.seed = Dice.derive(SCENERY_SEED, lake.zone_ids[k].hash())
		_build_reeds(blades, heads)
		_build_lilies(plants)
		_build_flowers(plants)
		if not forest:
			continue
		_build_rocks(rocks)
		# Kıyıya yakın yuvarlak ağaçlar, arkada korular (çamlar da). Kameranın önü boş kalır.
		_scatter_band(trees, int(_kit["near"]), Vector2(-5.0, -2.7), NEAR_TREES, 1.4, false, 9.0)
		_build_groves(trees)
		_scatter_band(trees, int(_kit["far"]), Vector2(-40.0, -5.0), FAR_TREES, 1.5, false, 16.0)
		# Çalılar kumsalın bittiği yerde ve ağaçların dibinde; çimen öbekleri kıyı boyunca.
		_scatter_band(low, int(_kit["bushes"]), Vector2(-3.2, -1.3), BUSHES, 0.7, false, 4.0, Vector2(0.8, 1.2))
		_scatter_band(low, int(_kit["bushes_far"]), Vector2(-8.0, -3.2), BUSHES, 0.8, false, 9.0, Vector2(0.9, 1.3))
		_scatter_band(low, int(_kit["grass"]), Vector2(-5.0, -0.9), GRASSES, 0.3, true, 6.0, Vector2(0.7, 1.2))
	_zone = -1
	_kit = DEFAULT_KIT
	_flush_reeds(blades, heads)
	if not plants.is_empty():
		var node := plants.build(self, "Plants")
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	if not forest:
		_rng.seed = SCENERY_SEED
		_build_fallback_trees()
		return
	var center := lake.water_bounds.get_center()
	var material := ShaderMaterial.new()
	material.shader = load("res://scenes/world/moss.gdshader")
	material.set_shader_parameter("albedo_texture", load(FOREST_TEXTURE))
	for node in ModelLibrary.merge(self, "Rocks", rocks, CHUNK, material, center):
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	for node in ModelLibrary.merge(self, "Trees", trees, CHUNK, null, center):
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	for node in ModelLibrary.merge(self, "Undergrowth", low, CHUNK, null, center):
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_build_backdrop()
	_build_camp(land)
	_build_boat()
	_build_gates()
	_build_buoys()
	_flush_batches()


## Uzakta tepeler ve dağlar: çerçeve. Eski şemadaki göl bugünkü yerleşim; büyük gölde yürünebilen
## dünyanın kenarlarının ötesinde (kuzeyde sıra, batıda ve doğuda birer).
func _build_backdrop() -> void:
	var center := lake.water_bounds.get_center()
	var far: Array[Array] = [
		["mountain_a", Vector2(-24, -24), 0.4], ["mountain_b", Vector2(4, -30), 2.2], ["hills", Vector2(26, -20), 1.1],
		["hills", Vector2(-34, -2), 3.0], ["mountain_b", Vector2(-14, -34), 5.0], ["hills", Vector2(30, 6), 4.4],
	]
	if lake.world_band != INF:
		var w := lake.water_bounds
		far = [
			["mountain_a", Vector2(w.position.x - 6.0, w.position.y - 20.0), 0.4],
			["mountain_b", Vector2(w.get_center().x + 6.0, w.position.y - 26.0), 2.2],
			["hills", Vector2(w.end.x + 10.0, w.position.y - 14.0), 1.1],
			["hills", Vector2(w.position.x - 22.0, w.get_center().y), 3.0],
			["mountain_b", Vector2(w.position.x + 12.0, w.position.y - 30.0), 5.0],
			["hills", Vector2(w.end.x + 22.0, w.get_center().y + 4.0), 4.4],
		]
		center = Vector2.ZERO
	for f in far:
		_spawn(f[0], center + (f[1] as Vector2), f[2], 1.0, false)


## Kilitli bölgelerin çitleri: çizginin karada kalan yeri boyunca çit parçaları, kıyı ucunda tabela.
## Bölge açılınca main gizler (set_gate_open).
func _build_gates() -> void:
	if not ModelLibrary.has("fence"):
		return
	for z in zones:
		var parts: Array[Array] = []
		for g: PackedVector2Array in z["gates"]:
			if g.size() != 2:
				continue
			var dir := (g[1] - g[0]).normalized()
			var yaw := atan2(-dir.y, dir.x)
			var count := ceili(g[0].distance_to(g[1]) / FENCE_PIECE)
			var signed := false
			for i in count:
				var p := g[0] + dir * (i + 0.5) * FENCE_PIECE
				if lake.shore_distance(p) > -0.2 or not lake.in_world(p + dir * 0.5):
					continue
				parts.append(["fence", Transform3D(Basis(Vector3.UP, yaw), Vector3(p.x, ground_height(p), p.y))])
				if not signed and ModelLibrary.has("gate_sign"):
					# Tabela kıyıya yakın uçta, çitin kameraya bakan yanında.
					var side := Vector2(-dir.y, dir.x)
					var spot := p + side * 0.6
					parts.append(["gate_sign", Transform3D(Basis(Vector3.UP, yaw + PI * 0.5), Vector3(spot.x, ground_height(spot), spot.y))])
					signed = true
		if parts.is_empty():
			continue
		var nodes := ModelLibrary.merge(self, "Gate_" + str(z["id"]), parts)
		for node in nodes:
			node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		_gates[str(z["id"])] = nodes


## Bölgenin çiti açıldı mı (açılınca gizlenir)?
func set_gate_open(zone_id: String, open: bool) -> void:
	for node: Node3D in _gates.get(zone_id, []):
		node.visible = not open


## Derin ortanın şamandıraları (sandalla gidilir): suyla iner kalkar.
func _build_buoys() -> void:
	if not ModelLibrary.has("buoy"):
		return
	for z in zones:
		for p: Vector2 in z["buoys"]:
			var base := Vector3(p.x, BUOY_Y, p.y)
			var node := ModelLibrary.spawn(self, "buoy", base, _rng.randf() * TAU)
			if node == null:
				continue
			set_shadows(node, false)
			_buoys.append(node)
			_buoy_base.append(base)


## Süs bu bölgenin mi (karada en yakın suyun bölgesi; eski şemada hep)?
func _mine(p: Vector2) -> bool:
	return _zone < 0 or lake.zone_of(p) == _zone


## Kurulan bölgenin çevresi (suyunun kutusu, grow kadar geniş); bölge yoksa gölün kutusu.
func _area(grow: float) -> Rect2:
	if _zone >= 0 and _zone < lake.zone_bounds.size() and lake.zone_bounds[_zone].size.x > 0.0 and lake.zone_ids.size() > 1:
		return lake.zone_bounds[_zone].grow(grow)
	return lake.water_bounds.grow(grow)


## Kıyı uzaklığı band (x: en uzak, y: en yakın; karada negatif; ızgaranın dışında da gerçek
## uzaklık: LakeShape.land_distance) aralığına count kopya serper.
## Kopyalar birbirine, dükkâna ve kampa radius'tan yakın düşmez; camera_ok değilse kameranın önüne
## (iskelenin arkası) de düşmez. area_grow: gölün kutusunun ne kadar dışına kadar aranacağı.
func _scatter_band(out: Array[Array], count: int, band: Vector2, kinds: Array[String], radius: float,
		camera_ok: bool, area_grow: float, size: Vector2 = Vector2(0.85, 1.15)) -> void:
	var area := _area(area_grow)
	var placed := 0
	var tries := 0
	while placed < count and tries < count * 400:
		tries += 1
		var p := Vector2(_rng.randf_range(area.position.x, area.end.x), _rng.randf_range(area.position.y, area.end.y))
		var shore := lake.land_distance(p)
		if shore < band.x or shore > band.y or lake.on_dock(p, 1.2) or (not camera_ok and _near_camera_side(p, radius < 1.0)):
			continue
		if not _mine(p):
			continue
		if not _free_spot(p, radius) or on_path(p, radius * 0.5):
			continue
		_occupied.append(Vector3(p.x, p.y, radius))
		var id := kinds[_rng.randi_range(0, kinds.size() - 1)]
		var basis := Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * _rng.randf_range(size.x, size.y))
		out.append([id, Transform3D(basis, Vector3(p.x, ground_height(p), p.y))])
		placed += 1


## Arkadaki orman: korular (birkaç ağaç bir arada; aralarında açıklık kalır).
func _build_groves(out: Array[Array]) -> void:
	var area := _area(15.0)
	var count := int(_kit.get("groves", GROVES))
	var groves := 0
	var tries := 0
	while groves < count and tries < count * 250:
		tries += 1
		var c := Vector2(_rng.randf_range(area.position.x, area.end.x), _rng.randf_range(area.position.y, area.end.y))
		if lake.land_distance(c) > -6.5 or _near_camera_side(c) or not _mine(c):
			continue
		groves += 1
		for k in _rng.randi_range(3, 6):
			var p := c + Dice.in_disc(_rng, GROVE_RADIUS)
			if lake.land_distance(p) > -4.8 or _near_camera_side(p) or not _free_spot(p, 1.2):
				continue
			_occupied.append(Vector3(p.x, p.y, 1.2))
			var id := FAR_TREES[_rng.randi_range(0, FAR_TREES.size() - 1)]
			var basis := Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * _rng.randf_range(0.8, 1.2))
			out.append([id, Transform3D(basis, Vector3(p.x, ground_height(p), p.y))])


## Balıkçının içinden geçmediği yerler (kıyı yolu): kamp, ağaçlar, kayalar ve çalılar (çimen ve
## çiçek değil). Daireler: x, z, yarıçap; süsün yarıçapı yerleşim payıdır (taç), gövde bunun yarısı.
func blockers() -> Array[Vector3]:
	var out: Array[Vector3] = []
	if _camp.z > 0.0:
		out.append(_camp)
	for c in _occupied:
		if c.z >= 0.7:
			out.append(Vector3(c.x, c.y, c.z * 0.5))
	return out


## Bu noktada radius'luk yer boş mu (dükkân, kamp ve yerleşmiş ağaç, kaya, çalı)?
func _free_spot(p: Vector2, radius: float) -> bool:
	for c in keep_clear:
		if p.distance_to(Vector2(c.x, c.y)) < c.z + radius:
			return false
	for c in _occupied:
		if p.distance_to(Vector2(c.x, c.y)) < c.z + radius:
			return false
	return true


## Yosunlu kayalar: kıyı çizgisinde öbek öbek (biri büyük, yanında küçükler), bir kısmı suyun
## içinde; tabanları gömülü. Hepsi tek ağ, yosun malzemesiyle.
func _build_rocks(rocks: Array[Array]) -> void:
	var near := _area(2.0)
	var count := int(_kit.get("rocks", ROCK_CLUSTERS))
	var big := float(_kit.get("big_rocks", 0.5))
	var clusters := 0
	var tries := 0
	while clusters < count and tries < count * 330:
		tries += 1
		var c := Vector2(_rng.randf_range(near.position.x, near.end.x), _rng.randf_range(near.position.y, near.end.y))
		var shore := lake.shore_distance(c)
		if shore < -1.0 or shore > 0.3 or lake.on_dock(c, 1.8) or not _free_spot(c, 0.9) or not _mine(c):
			continue
		clusters += 1
		# Büyük kaya payı: her kümenin ilk kayası bu oranda büyük (iskele koyunda yarı yarıya, sırayla).
		var kinds := BIG_ROCKS if (clusters % 2 == 0 if big == 0.5 else _rng.randf() < big) else SMALL_ROCKS
		_rock(rocks, c, kinds[_rng.randi_range(0, kinds.size() - 1)], 0.9)
		for k in _rng.randi_range(1, 3):
			var p := c + Vector2(_rng.randf_range(0.7, 1.2), 0.0).rotated(_rng.randf() * TAU)
			if lake.shore_distance(p) > 0.7 or lake.on_dock(p, 1.5) or not _free_spot(p, 0.35):
				continue
			_rock(rocks, p, SMALL_ROCKS[_rng.randi_range(0, SMALL_ROCKS.size() - 1)], 0.4)


func _rock(out: Array[Array], p: Vector2, id: String, radius: float) -> void:
	_occupied.append(Vector3(p.x, p.y, radius))
	var size := _rng.randf_range(0.8, 1.2)
	var height := ModelLibrary.bounds(id).size.y * size
	var basis := Basis(Vector3.UP, _rng.randf() * TAU).scaled(Vector3.ONE * size)
	out.append([id, Transform3D(basis, Vector3(p.x, ground_height(p) - height * ROCK_SINK, p.y))])


## Kıyıya yakın sığda nilüfer öbekleri: çentikli yapraklar, bazılarında pembe nilüfer çiçeği.
## İskelenin, sandalın ve oltanın sık düştüğü açıklığın dışında.
func _build_lilies(batch: MeshBatch) -> void:
	var bounds := _area(0.0)
	var count := int(_kit.get("lilies", LILY_CLUSTERS))
	var band: Vector2 = _kit.get("lily_band", Vector2(0.7, 1.9))
	var lotus := float(_kit.get("lotus", LOTUS_CHANCE))
	var clusters := 0
	var tries := 0
	while clusters < count and tries < count * 570:
		tries += 1
		var c := Vector2(_rng.randf_range(bounds.position.x, bounds.end.x), _rng.randf_range(bounds.position.y, bounds.end.y))
		var shore := lake.shore_distance(c)
		if shore < band.x or shore > band.y or lake.on_dock(c, 3.0) or _near_boat(c) or not _mine(c):
			continue
		clusters += 1
		for k in _rng.randi_range(3, 6):
			var p := c + Dice.in_disc(_rng, 0.8)
			if lake.shore_distance(p) < 0.4 or lake.on_dock(p, 2.6):
				continue
			var radius := _rng.randf_range(0.17, 0.3)
			var y := 0.012 + 0.003 * k
			_lily_pad(batch, Vector3(p.x, y, p.y), radius, _rng.randf() * TAU, LILY if k % 2 == 0 else LILY_LIGHT)
			if _rng.randf() < lotus:
				_lotus(batch, Vector3(p.x, y + 0.004, p.y), _rng.randf_range(1.1, 1.5), _rng.randf() * TAU)


## Nilüfer yaprağı: ortası hafif kabarık, çentikli disk (yukarı bakan yelpaze).
func _lily_pad(batch: MeshBatch, center: Vector3, radius: float, yaw: float, color: Color) -> void:
	var points := PackedVector3Array()
	var hub := center + Vector3(0, 0.012, 0)
	var steps := 12
	for i in steps:
		var a0 := yaw + LILY_NOTCH + (TAU - 2.0 * LILY_NOTCH) * float(i) / steps
		var a1 := yaw + LILY_NOTCH + (TAU - 2.0 * LILY_NOTCH) * float(i + 1) / steps
		points.append_array(PackedVector3Array([hub, center + Vector3(cos(a0), 0, sin(a0)) * radius,
				center + Vector3(cos(a1), 0, sin(a1)) * radius]))
	batch.triangles(points, color)


## Nilüfer çiçeği: dışta 6 pembe, içte 5 açık pembe yaprak, ortada sarı göbek.
func _lotus(batch: MeshBatch, base: Vector3, size: float, yaw: float) -> void:
	var outer := PackedVector3Array()
	var inner := PackedVector3Array()
	for i in 6:
		_petal(outer, base, yaw + TAU * i / 6.0, 0.12 * size, 0.07 * size, 0.035 * size)
	for i in 5:
		_petal(inner, base + Vector3(0, 0.01, 0), yaw + 0.3 + TAU * i / 5.0, 0.08 * size, 0.1 * size, 0.026 * size)
	batch.triangles(outer, LOTUS)
	batch.triangles(inner, LOTUS_LIGHT)
	batch.triangles(_disc(base + Vector3(0, 0.05 * size, 0), 0.028 * size, 6), POLLEN)


## Çiçek yaprağı: tabandan dışa ve yukarı uzanan baklava (iki üçgen, yukarı bakar).
static func _petal(out: PackedVector3Array, base: Vector3, angle: float, length: float, lift: float, half: float) -> void:
	var dir := Vector3(cos(angle), 0, sin(angle))
	var side := Vector3(-dir.z, 0, dir.x)
	var root := base + dir * length * 0.12
	var mid := base + dir * length * 0.55 + Vector3(0, lift * 0.5, 0)
	var tip := base + dir * length + Vector3(0, lift, 0)
	_tri_up(out, root, mid + side * half, tip)
	_tri_up(out, root, tip, mid - side * half)


## Yukarı bakan düz çokgen (göbek).
static func _disc(center: Vector3, radius: float, steps: int) -> PackedVector3Array:
	var out := PackedVector3Array()
	for i in steps:
		var a0 := TAU * i / steps
		var a1 := TAU * (i + 1) / steps
		out.append_array(PackedVector3Array([center, center + Vector3(cos(a0), 0, sin(a0)) * radius,
				center + Vector3(cos(a1), 0, sin(a1)) * radius]))
	return out


## Üçgeni yukarı bakacak sırayla ekler (kamera hep yukarıdan bakar; tek yüz yeter).
static func _tri_up(out: PackedVector3Array, a: Vector3, b: Vector3, c: Vector3) -> void:
	if (c - a).cross(b - a).y >= 0.0:
		out.append_array(PackedVector3Array([a, b, c]))
	else:
		out.append_array(PackedVector3Array([a, c, b]))


## Çimende küçük çiçek öbekleri (papatya, düğün çiçeği, pembe): beş yapraklı yıldız ve göbek.
func _build_flowers(batch: MeshBatch) -> void:
	var area := _area(8.0)
	var count := int(_kit.get("flowers", FLOWER_CLUSTERS))
	var clusters := 0
	var tries := 0
	while clusters < count and tries < count * 220:
		tries += 1
		var c := Vector2(_rng.randf_range(area.position.x, area.end.x), _rng.randf_range(area.position.y, area.end.y))
		var shore := lake.land_distance(c)
		if shore < -7.5 or shore > -1.8 or lake.on_dock(c, 1.5) or not _free_spot(c, 0.4) or not _mine(c) or on_path(c, 0.6):
			continue
		clusters += 1
		var color := DAISY_COLORS[_rng.randi_range(0, DAISY_COLORS.size() - 1)]
		var petals := PackedVector3Array()
		var hearts := PackedVector3Array()
		for k in _rng.randi_range(4, 8):
			var p := c + Dice.in_disc(_rng, 0.55)
			var size := _rng.randf_range(0.09, 0.13)
			var base := Vector3(p.x, ground_height(p) + 0.04, p.y)
			var yaw := _rng.randf() * TAU
			for i in 5:
				_petal(petals, base, yaw + TAU * i / 5.0, size, 0.012, size * 0.3)
			hearts.append_array(_disc(base + Vector3(0, 0.008, 0), size * 0.3, 6))
		batch.triangles(petals, color)
		batch.triangles(hearts, POLLEN if color != DAISY_COLORS[2] else Color("#e07b1f"))


## İskelenin kara ucunun sağında küçük kamp (Dalga 4'te Dede'yle çay): ocak, iki kütük oturak,
## iskelenin başında tabela; iskeleye yakın fıçı, kasa ve çuval. Her paketin eşyaları tek ağ.
func _build_camp(land: Vector2) -> void:
	var kenney: Array[Array] = []
	var medieval: Array[Array] = []
	var camp := land + CAMP
	_prop(kenney, "campfire", camp, 0.0)
	_prop(kenney, "log_seat", camp + Vector2(-1.0, -0.15), deg_to_rad(80.0))
	_prop(kenney, "log_seat", camp + Vector2(0.6, 0.9), deg_to_rad(-25.0))
	_prop(kenney, "signpost", land + Vector2(1.05, -0.4), deg_to_rad(-35.0))
	_prop(medieval, "barrel", land + Vector2(1.6, 0.2), 0.3)
	_prop(medieval, "crate", land + Vector2(2.3, 0.75), 0.9)
	_prop(medieval, "sack", land + Vector2(1.85, 1.2), 0.0)
	# İskeledeki kova da ortaçağ paketinden: aynı ağda (ayrı çizim olmasın).
	var dock := lake.dock
	medieval.append(["bucket", Transform3D(Basis(Vector3.UP, 0.4), Vector3(dock.get_center().x - 0.45, DOCK_HEIGHT + 0.04, dock.position.y + 0.55))])
	var lantern: Array[Array] = []
	_prop(lantern, "lantern_post", land + Vector2(-1.15, -1.6), 0.0)
	for group: Array in [["CampKenney", kenney, true], ["CampMedieval", medieval, true], ["Lantern", lantern, false]]:
		# İnce fener direğinin gölgesi görünmüyor: kapalı (bir çizim az).
		for node in ModelLibrary.merge(self, str(group[0]), group[1]):
			node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if bool(group[2]) \
					else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _prop(out: Array[Array], id: String, p: Vector2, yaw: float) -> void:
	out.append([id, Transform3D(Basis(Vector3.UP, yaw), Vector3(p.x, ground_height(p), p.y))])


## İskelenin -x yanına bağlı sandal (Dalga 2'de binilir; şimdilik süs ve Dede'nin sözü). Suyla
## hafifçe iner kalkar (_process).
func _build_boat() -> void:
	if not ModelLibrary.has("boat"):
		return
	_boat = Node3D.new()
	_boat.name = "Boat"
	_boat_base = _boat_spot()
	_boat.position = _boat_base
	add_child(_boat)
	for node in ModelLibrary.merge(_boat, "BoatMesh", [["boat", Transform3D(Basis(Vector3.UP, BOAT_YAW), Vector3.ZERO)]]):
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON


## Sandal bir şamandıranın yanına gider (balıkçı biner): sandalın ortası (dünya xz) döner. Sandal
## modeli yoksa da yer aynıdır (balıkçı suyun üstünde durur).
func moor_boat(buoy: Vector2) -> Vector2:
	var at := buoy + BUOY_MOOR
	_boat_away = true
	_boat_base = Vector3(at.x, BOAT_Y, at.y)
	if _boat != null:
		_boat.position = _boat_base
	return at


## Sandal iskeledeki yerine döner (balıkçı indi).
func dock_boat() -> void:
	_boat_away = false
	_boat_base = _boat_spot()
	if _boat != null:
		_boat.position = _boat_base


func boat_away() -> bool:
	return _boat_away


## Sandalın ortası (dünya; botun dokunuşu için). Sandal yoksa yerinin su yüzeyindeki noktası.
func boat_point() -> Vector3:
	return _boat.global_position + Vector3(0, 0.2, 0) if _boat != null else _boat_spot()


## Sandalın yeri (su yüzeyindeki orta noktası).
func _boat_spot() -> Vector3:
	var dock := lake.dock
	return Vector3(dock.position.x - BOAT_SIDE, BOAT_Y, dock.position.y + BOAT_ALONG)


func _near_boat(p: Vector2) -> bool:
	var spot := _boat_spot()
	return p.distance_to(Vector2(spot.x, spot.z)) < BOAT_HALF + 1.0


func _process(delta: float) -> void:
	_clock += delta
	for i in _buoys.size():
		var phase := float(i) * 1.7
		_buoys[i].position = _buoy_base[i] + Vector3(0, sin(_clock * 1.6 + phase) * 0.04, 0)
	if _boat == null:
		return
	_boat.position = _boat_base + Vector3(0, sin(_clock * 1.3) * 0.025, 0)
	_boat.rotation = Vector3(sin(_clock * 1.1 + 1.0) * 0.015, 0.0, sin(_clock * 0.9) * 0.03)


## Ekrandaki bir nokta sandalın üstünde mi (sandalın boyunca bir çizgiye uzaklık)? main dokunma
## hedefi yapar: sandala dokununca atış yerine Dede konuşur.
func boat_hit(view: Camera3D, screen: Vector2) -> bool:
	if _boat == null or view == null or not _boat.is_inside_tree():
		return false
	var center := _boat.global_position + Vector3(0, 0.2, 0)
	var axis := _boat.global_transform.basis.z.normalized() * BOAT_HALF
	if view.is_position_behind(center + axis) or view.is_position_behind(center - axis):
		return false
	var a := view.unproject_position(center + axis)
	var b := view.unproject_position(center - axis)
	var scale := view.get_viewport().get_visible_rect().size.y / 1080.0
	var radius := maxf(24.0 * scale, a.distance_to(b) * 0.25)
	return Geometry2D.get_closest_point_to_segment(screen, a, b).distance_to(screen) <= radius


## Süs p'de balıkçıyı kameradan saklar mı? Kamera +x +z tarafında (FollowCamera.YAW): p'nin
## kameraya göre önündeki (1,5–9 m; alçak süste 1–3 m) noktalardan biri balıkçının durabileceği
## yerse (dünyanın karası ya da iskele) evet. Eski şemadaki göl (dünya sınırsız): iskelenin arkası.
func _near_camera_side(p: Vector2, low: bool = false) -> bool:
	var dock := lake.dock
	if lake.world_band == INF:
		return p.y > dock.position.y - 1.0 and p.x > dock.get_center().x - 7.0 and p.x < dock.get_center().x + 14.0
	var back := Vector2(sin(FollowCamera.YAW), cos(FollowCamera.YAW))
	var reach := 3.0 if low else 9.0
	var t := 1.0 if low else 1.5
	while t <= reach:
		var q := p - back * t
		if lake.on_dock(q) or (lake.in_world(q) and not lake.is_water(q)):
			return true
		t += 1.0 if low else 1.5
	return false


## Modeli yerleştirir; aynı modelin kopyaları _flush_batches'te tek MultiMesh olarak kurulur.
func _spawn(id: String, p: Vector2, yaw: float, size: float, shadows: bool) -> void:
	if not ModelLibrary.has(id):
		return
	var key := "%s|%d" % [id, 1 if shadows else 0]
	if not _batches.has(key):
		_batches[key] = []
	var basis := Basis(Vector3.UP, yaw).scaled(Vector3.ONE * size)
	(_batches[key] as Array).append(Transform3D(basis, Vector3(p.x, maxf(ground_height(p), -0.05), p.y)))


func _flush_batches() -> void:
	for key: String in _batches:
		var parts := key.split("|")
		var transforms: Array[Transform3D] = []
		transforms.assign(_batches[key])
		for node in ModelLibrary.scatter(self, parts[0], transforms):
			node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if parts[1] == "1" \
					else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_batches.clear()


static func set_shadows(root: Node, on: bool) -> void:
	for node in root.find_children("*", "GeometryInstance3D", true, false):
		(node as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if on \
				else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## Modeller yoksa kodla basit ağaçlar.
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
