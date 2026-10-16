class_name NineBody
extends Node3D
## Nine: KayKit "Mage" modelinden (CC0, bkz. assets/CREDITS.md), Dede'nin eşi, dükkânı işleten
## güler yüzlü nine. Ersin'in portre tarifine göre (docs/gorsel-istekleri.md §9) giydirilir:
## - doku boyanır (tools/recolor_texture.gd): gümüş saç, hardal sarısı hırka, krem yün kenarlar;
## - büyücü şapkası, pelerin, asa, değnek ve kitap gizlenir;
## - kodla beyaz, mavi çiçekli bir yazma (başın arkasını örter, yüzü çevreler, çenenin altında
##   bağlı), turkuaz puantiyeli önlük (etek kalçaya, göğüslük göğse bağlı) ve yuvarlak gözlük.
##
## Duruşlar (AnimationTree):
## - bekleme: Idle (tezgâhın arkasında ayakta; Unarmed_Idle yumruk sıkıp dövüşe hazırlanıyor);
## - tek seferlik, yalnızca üst gövde: Interact (tezgâha uzanıp bir şey verir), Cheer (sevinç).
## Baş LookModifier ile hedefe döner, konuşurken sallanır. Duruşlar tools/character_sheet.gd
## --nine ile denetlenir. Model +z yönüne bakar; kökü ayak hizasındadır. Model dosyası yoksa Nine
## ToyNine'a düşer.

const SCENE_PATH := "res://assets/models/characters/Mage.glb"
const TEXTURE_PATH := "res://assets/models/characters/nine_texture.png"
## Modelin boyu ~2,2 birim; Nine balıkçıdan biraz kısa (~1,3 m).
const MODEL_SCALE := 0.6
const HIDDEN: Array[String] = ["Mage_Hat", "Mage_Cape", "Spellbook", "Spellbook_open", "1H_Wand", "2H_Staff"]
const IDLE_ANIM := "Idle"
const GIVE_ANIM := "Interact"
const CHEER_ANIM := "Cheer"
const REQUIRED_ANIMS: Array[String] = [IDLE_ANIM, GIVE_ANIM, CHEER_ANIM]
const REQUIRED_NODES: Array[String] = ["Skeleton3D", "AnimationPlayer", "head"]
const REQUIRED_BONES: Array[String] = ["head", "chest", "hips"]
## Başın ortası (model uzayında, ölçeksiz; ayakta): balon ve dokunma buna göre. Baş kemiği
## 1,24'te; kafa ağı kemiğin 0,96 üstüne kadar çıkar.
const HEAD_CENTER := Vector3(0.0, 1.66, -0.08)
## Baş sallama: genlik (radyan) ve süre (sn).
const NOD_ANGLE := 0.2
const NOD_TIME := 0.9
const SCARF := Color("#f7f2e7")
const SCARF_FLOWER := Color("#3f6fb5")
const FLOWER_HEART := Color("#f0c24a")
const APRON := Color("#2a9d96")
const APRON_DOT := Color("#f7f2e7")
const GLASSES := Color("#5a3b22")
const CHEEK := Color("#f09c94")

var _model: Node3D
var _tree: AnimationTree
var _look: LookModifier
var _nod_time: float = -1.0


## Model dosyası ve dokusu projede var mı?
static func available() -> bool:
	return ResourceLoader.exists(SCENE_PATH) and ResourceLoader.exists(TEXTURE_PATH)


func _ready() -> void:
	var scene: PackedScene = load(SCENE_PATH)
	_model = scene.instantiate() as Node3D
	_model.scale = Vector3.ONE * MODEL_SCALE
	add_child(_model)
	dress(_model)
	var skeleton := _model.find_child("Skeleton3D", true, false) as Skeleton3D
	_look = LookModifier.new()
	_look.name = "Look"
	skeleton.add_child(_look)
	_build_tree(_model.find_child("AnimationPlayer", true, false) as AnimationPlayer)
	# Tentenin altında durur: gölgesi tentenin gölgesinde kaybolur, çizimi boşa gider.
	for node in _model.find_children("*", "GeometryInstance3D", true, false):
		(node as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## Kıyafet: boyanmış doku, dış çizgi, gizlenen parçalar, yazma, önlük ve gözlük. Karakter
## sayfası aracı da kullanır.
static func dress(model: Node3D) -> void:
	CharacterKit.dress(model, load(TEXTURE_PATH), HIDDEN)
	_add_scarf(model)
	_add_glasses(model)
	_add_apron(model)


## İpucu çubuğu için yüz resmi: Nine'nin başı, hafif yandan (Ersin'in portresi gelene kadar).
## Model ya da ekran yoksa null.
static func portrait(parent: Node, pixels: int) -> Texture2D:
	if not available():
		return null
	var head := HEAD_CENTER * MODEL_SCALE + Vector3(0.0, -0.06, 0.0)
	return await PortraitStudio.shoot(parent, NineBody.new(), head + Vector3(0.6, 0.2, 2.4), head, 0.86, pixels, 4)


## Başın ortası (dünya). Animasyondan bağımsız (ayaktaki yer): balon ve dokunma için.
func head_point() -> Vector3:
	return to_global(HEAD_CENTER * MODEL_SCALE)


## Bakılacak nokta (dünya); has_target false ise öne bakar.
func look_at_point(point: Vector3, has_target: bool) -> void:
	_look.target = point
	_look.has_target = has_target


## Konuşurken başını sallar.
func nod() -> void:
	_nod_time = 0.0


func cheer() -> void:
	_tree.set("parameters/cheer_shot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)


## Tezgâhın üstüne uzanıp bir şey verir (satın almada, selamda).
func give() -> void:
	_tree.set("parameters/give_shot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)


func _process(delta: float) -> void:
	if _nod_time < 0.0:
		return
	_nod_time += delta
	if _nod_time >= NOD_TIME:
		_nod_time = -1.0
		_look.nod = 0.0
		return
	# İki kez öne eğilip kalkar; sonda söner.
	var t := _nod_time / NOD_TIME
	_look.nod = NOD_ANGLE * maxf(0.0, sin(t * TAU * 2.0)) * (1.0 - t)


# --- Kurulum ---------------------------------------------------------------------
# Ölçüler modelin uzayında (ölçeksiz), kemiklerin dinlenme duruşuna göre: baş kemiği (0, 1,24, 0),
# göğüs (0, 0,97, 0), kalça (0, 0,41, 0). Kafa ağı baş kemiğine göre x ±0,54, y -0,17..0,96,
# z -0,75 (topuz)..0,52 (burun); gözler y 0,31..0,43, z 0,44'e kadar.

## Yazma: başın üstünü ve arkasını (topuzu) örten yuvarlak bir örtü; önü alnın gerisinde kalır,
## böylece gümüş perçem ve yüz açıkta kalır. Yanlardan inen iki bağ çenenin altında düğümlenir.
## Parçalar desenli kumaşla tek ağda birleşir (MeshBatch.merge: bir çizim, bir dış çizgi).
static func _add_scarf(model: Node3D) -> void:
	var head := CharacterKit.bone_slot(model, "head", "head")
	if head == null:
		return
	var scarf := Props.pivot(head, Vector3.ZERO, "Scarf")
	Props.sphere(scarf, 0.56, Vector3(0, 0.5, -0.2), Color.WHITE, 20, 10, Vector3(1.03, 0.95, 1.08))
	# Bağlar: şakaktan çeneye; düğüm ve iki ucu.
	for side: float in [-1.0, 1.0]:
		Props.capsule(scarf, 0.055, 0.6, Vector3(side * 0.26, 0.065, 0.22), Color.WHITE, Vector3(-0.4, 0.0, -side * 0.56))
	Props.sphere(scarf, 0.075, Vector3(0, -0.2, 0.33), Color.WHITE, 10, 5, Vector3(1.2, 0.9, 0.9))
	for side: float in [-1.0, 1.0]:
		Props.sphere(scarf, 0.06, Vector3(side * 0.08, -0.29, 0.34), Color.WHITE, 8, 4, Vector3(0.8, 1.4, 0.5))
	MeshBatch.merge(scarf, _patterned(_flower_tile(), Vector3(10, 5, 1))).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	CharacterKit.outline_parts(scarf, CharacterKit.OUTLINE_WIDTH / MODEL_SCALE * 0.5)


## Yuvarlak, ince çerçeveli gözlük ve pembe yanaklar.
static func _add_glasses(model: Node3D) -> void:
	var head := CharacterKit.bone_slot(model, "head", "head")
	if head == null:
		return
	var glasses := Props.pivot(head, Vector3.ZERO, "Glasses")
	for side: float in [-1.0, 1.0]:
		var ring := TorusMesh.new()
		ring.inner_radius = 0.085
		ring.outer_radius = 0.108
		ring.rings = 16
		ring.ring_segments = 6
		var frame := MeshInstance3D.new()
		frame.mesh = ring
		frame.material_override = Props.material(GLASSES, 0.5)
		frame.position = Vector3(side * 0.17, 0.37, 0.475)
		frame.rotation = Vector3(PI * 0.5, 0.0, 0.0)
		glasses.add_child(frame)
		Props.sphere(glasses, 0.075, Vector3(side * 0.3, 0.22, 0.42), CHEEK, 10, 5, Vector3(1.0, 0.7, 0.25))
	Props.box(glasses, Vector3(0.12, 0.022, 0.022), Vector3(0, 0.395, 0.49), GLASSES)
	MeshBatch.merge(glasses).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


## Önlük: kalçaya bağlı etek kısmı (cebiyle) ve göğse bağlı göğüslük. Kemer ve keseler dokuda
## önlüğün turkuazına boyalı: önlüğün bağı ve yan cepleri gibi görünür. Cep aynı kumaşın koyusu
## (köşe rengi gri: doku × gri).
static func _add_apron(model: Node3D) -> void:
	var material := _patterned(_dot_tile(), Vector3(9, 4, 1))
	var hips := CharacterKit.bone_slot(model, "hips", "apron_hips")
	if hips != null:
		var skirt := Props.pivot(hips, Vector3.ZERO, "Apron")
		# Hafif eğik: üstü kemerin, altı etek ucunun önünde (cüppe karında öne çıkar).
		Props.box(skirt, Vector3(0.6, 0.4, 0.03), Vector3(0, 0.18, 0.395), Color.WHITE, Vector3(0.1, 0, 0))
		Props.box(skirt, Vector3(0.24, 0.12, 0.035), Vector3(0, 0.12, 0.405), Color(0.74, 0.74, 0.74), Vector3(0.1, 0, 0))
		MeshBatch.merge(skirt, material).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		CharacterKit.outline_parts(skirt, CharacterKit.OUTLINE_WIDTH / MODEL_SCALE * 0.5)
	var chest := CharacterKit.bone_slot(model, "chest", "apron_chest")
	if chest != null:
		var bib := Props.pivot(chest, Vector3.ZERO, "Bib")
		Props.box(bib, Vector3(0.38, 0.32, 0.03), Vector3(0, -0.02, 0.33), Color.WHITE, Vector3(-0.08, 0, 0))
		MeshBatch.merge(bib, material).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		CharacterKit.outline_parts(bib, CharacterKit.OUTLINE_WIDTH / MODEL_SCALE * 0.5)


## Döşenen desenli malzeme (scale: UV tekrarı; BoxMesh her yüze dokunun 1/3 × 1/2'sini verir).
## Köşe rengiyle çarpılır (birleşik ağda beyaz parça dokunun kendisi, gri parça koyusu).
static func _patterned(tile: Texture2D, scale: Vector3) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_texture = tile
	material.uv1_scale = scale
	material.vertex_color_use_as_albedo = true
	material.vertex_color_is_srgb = true
	material.roughness = 0.85
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return material


## Yazmanın deseni: beyaz üstünde iki küçük mavi çiçek (beş taç yaprak, sarı göbek).
static func _flower_tile() -> Texture2D:
	var image := Image.create_empty(64, 64, false, Image.FORMAT_RGBA8)
	image.fill(SCARF)
	for center: Vector2 in [Vector2(16, 16), Vector2(48, 48)]:
		for i in 5:
			var petal := center + Vector2.from_angle(TAU * i / 5.0 - PI * 0.5) * 5.5
			_disc(image, petal, 4.2, SCARF_FLOWER)
		_disc(image, center, 2.6, FLOWER_HEART)
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)


## Önlüğün deseni: turkuaz üstünde iki beyaz puan.
static func _dot_tile() -> Texture2D:
	var image := Image.create_empty(64, 64, false, Image.FORMAT_RGBA8)
	image.fill(APRON)
	for center: Vector2 in [Vector2(16, 16), Vector2(48, 48)]:
		_disc(image, center, 7.0, APRON_DOT)
	image.generate_mipmaps()
	return ImageTexture.create_from_image(image)


## Kenarı yumuşak bir daire (döşenen dokuda kenardan taşanı öbür yana sarar).
static func _disc(image: Image, center: Vector2, radius: float, color: Color) -> void:
	var size := image.get_size()
	for y in range(floori(center.y - radius - 1.0), ceili(center.y + radius + 1.0) + 1):
		for x in range(floori(center.x - radius - 1.0), ceili(center.x + radius + 1.0) + 1):
			var d := Vector2(x + 0.5, y + 0.5).distance_to(center)
			var a := clampf(radius + 0.5 - d, 0.0, 1.0)
			if a <= 0.0:
				continue
			var px := posmod(x, size.x)
			var py := posmod(y, size.y)
			image.set_pixel(px, py, image.get_pixel(px, py).lerp(color, a))


func _build_tree(player: AnimationPlayer) -> void:
	CharacterKit.set_looping(player, [IDLE_ANIM])
	var blend := AnimationNodeBlendTree.new()
	blend.add_node("idle", CharacterKit.clip(IDLE_ANIM))
	blend.add_node("give_shot", CharacterKit.one_shot(player, GIVE_ANIM, 0.2, 0.3, true))
	blend.add_node("give_clip", CharacterKit.clip(GIVE_ANIM))
	blend.add_node("cheer_shot", CharacterKit.one_shot(player, CHEER_ANIM, 0.2, 0.35, true))
	blend.add_node("cheer_clip", CharacterKit.clip(CHEER_ANIM))
	blend.connect_node("give_shot", 0, "idle")
	blend.connect_node("give_shot", 1, "give_clip")
	blend.connect_node("cheer_shot", 0, "give_shot")
	blend.connect_node("cheer_shot", 1, "cheer_clip")
	blend.connect_node("output", 0, "cheer_shot")
	_tree = AnimationTree.new()
	_tree.name = "AnimationTree"
	_model.add_child(_tree)
	_tree.tree_root = blend
	_tree.anim_player = _tree.get_path_to(player)
	_tree.active = true
