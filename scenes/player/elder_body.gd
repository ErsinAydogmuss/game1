class_name ElderBody
extends Node3D
## Dede: KayKit "Barbarian" modelinden (CC0, bkz. assets/CREDITS.md), beyaz sakallı yaşlı balıkçı.
## Doku boyanır (tools/recolor_texture.gd); boynuzlu miğfer, pelerin, baltalar, kalkan ve kupa
## gizlenir (kupa bira bardağına benziyor: oyun her yaşa). Kodla kasket takılır.
##
## Duruşlar (AnimationTree):
## - oturma: Sit_Chair_Idle. KayKit'te bacaklar sandalyeden sarkar; iskelenin kenarına uyar;
## - sevinç: Cheer'in yalnızca üst gövdesi (oturduğu yerde kollarını kaldırır).
## Baş LookModifier ile hedefe döner, konuşurken sallanır. Duruşlar tools/character_sheet.gd
## --elder ile denetlenir.
## Model +z yönüne bakar; kökü ayak hizasındadır. Model dosyası yoksa Elder ToyElder'a düşer.

const SCENE_PATH := "res://assets/models/characters/Barbarian.glb"
const TEXTURE_PATH := "res://assets/models/characters/dede_texture.png"
## Modelin boyu ~2,2 birim; balıkçıyla aynı ölçek (Barbarian daha iri yapılı).
const MODEL_SCALE := 0.66
const HIDDEN: Array[String] = ["Barbarian_Hat", "Barbarian_Cape", "1H_Axe_Offhand",
		"Barbarian_Round_Shield", "1H_Axe", "2H_Axe", "Mug"]
const SIT_ANIM := "Sit_Chair_Idle"
const CHEER_ANIM := "Cheer"
const REQUIRED_ANIMS: Array[String] = [SIT_ANIM, CHEER_ANIM]
const REQUIRED_NODES: Array[String] = ["Skeleton3D", "AnimationPlayer", "head"]
const REQUIRED_BONES: Array[String] = ["head", "chest", "hips"]
## Oturma noktası (model uzayında, ölçeksiz): kalçanın altı ve diz arkası. İskelenin kenarı buraya
## gelir (Elder.seat). Sit_Chair_Idle'da ölçüldü: kalça (0, 0,48, -0,40), diz (0,19, 0,55, -0,16).
const SEAT := Vector3(0.0, 0.42, -0.2)
## Başın ortası (model uzayında, ölçeksiz; oturuşta): konuşma balonu ve dokunma buna göre.
const HEAD_CENTER := Vector3(0.0, 1.78, -0.38)
## Baş sallama: genlik (radyan) ve süre (sn).
const NOD_ANGLE := 0.22
const NOD_TIME := 0.9
const CAP_COLOR := Color("#7a5f45")
const CAP_TOP := Color("#8c7052")

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
	_add_cap()
	var skeleton := _model.find_child("Skeleton3D", true, false) as Skeleton3D
	_look = LookModifier.new()
	_look.name = "Look"
	skeleton.add_child(_look)
	_build_tree(_model.find_child("AnimationPlayer", true, false) as AnimationPlayer)


## Kıyafet: boyanmış doku, dış çizgi, gizlenen parçalar. Karakter sayfası aracı da kullanır.
static func dress(model: Node3D) -> void:
	CharacterKit.dress(model, load(TEXTURE_PATH), HIDDEN)


## İpucu çubuğu için yüz resmi: oturan Dede'nin başı, hafif yandan (Ersin'in portresi gelene
## kadar). Model ya da ekran yoksa null.
static func portrait(parent: Node, pixels: int) -> Texture2D:
	if not available():
		return null
	var head := HEAD_CENTER * MODEL_SCALE + Vector3(0.0, -0.04, 0.0)
	return await PortraitStudio.shoot(parent, ElderBody.new(), head + Vector3(0.7, 0.18, 2.4), head, 0.92, pixels, 4)


## Oturma noktasının köke göre yeri (ölçekli).
func seat_offset() -> Vector3:
	return SEAT * MODEL_SCALE


## Başın ortası (dünya). Animasyondan bağımsız (oturuştaki yer): balon ve dokunma için.
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

## Kasket: başın üstünde yassı, yuvarlak bir tepe ve önde kısa bir siper (modelin ölçeğinde).
## Barbarian'ın miğferinin bağlı olduğu "head" yuvası kullanılır.
func _add_cap() -> void:
	var head := CharacterKit.bone_slot(_model, "head", "head")
	if head == null:
		return
	# Başın arkasına doğru oturur: yukarıdan bakan kamerada yüzü örtmesin.
	var cap := Props.pivot(head, Vector3(0, 0.88, -0.06), "Cap")
	# Tepe: yassı ve dolgun; altında bant; siper önde (+z), hafif aşağı eğik.
	Props.sphere(cap, 0.46, Vector3(0, 0.02, -0.02), CAP_TOP, 16, 8, Vector3(1.04, 0.4, 1.06))
	Props.cylinder(cap, 0.46, 0.5, 0.13, Vector3(0, -0.06, -0.02), CAP_COLOR, 18)
	Props.box(cap, Vector3(0.56, 0.05, 0.24), Vector3(0, -0.1, 0.52), CAP_COLOR.darkened(0.18), Vector3(-0.22, 0, 0))
	CharacterKit.outline_parts(cap, CharacterKit.OUTLINE_WIDTH / MODEL_SCALE * 0.5)


func _build_tree(player: AnimationPlayer) -> void:
	CharacterKit.set_looping(player, [SIT_ANIM])
	var blend := AnimationNodeBlendTree.new()
	blend.add_node("sit", CharacterKit.clip(SIT_ANIM))
	blend.add_node("cheer_shot", CharacterKit.one_shot(player, CHEER_ANIM, 0.2, 0.35, true))
	blend.add_node("cheer_clip", CharacterKit.clip(CHEER_ANIM))
	blend.connect_node("cheer_shot", 0, "sit")
	blend.connect_node("cheer_shot", 1, "cheer_clip")
	blend.connect_node("output", 0, "cheer_shot")
	_tree = AnimationTree.new()
	_tree.name = "AnimationTree"
	_model.add_child(_tree)
	_tree.tree_root = blend
	_tree.anim_player = _tree.get_path_to(player)
	_tree.active = true
