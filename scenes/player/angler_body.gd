class_name AnglerBody
extends Node3D
## Balıkçı: kız KayKit "Rogue", oğlan KayKit "Knight" modelinden (CC0, bkz. assets/CREDITS.md; Dalga 5:
## görünüş `look`, SaveData.CHARACTERS). İkisi aynı iskelet ve animasyonları taşır. Doku balıkçı renklerine
## boyanır (tools/recolor_texture.gd); kızda pelerin, bıçaklar, arbaletler ve bomba, oğlanda miğfer, pelerin,
## kılıçlar ve kalkanlar gizlenir. Kodla bir balıkçı şapkası başa takılır; olta sağ elin yuvasına (handslot_r)
## bağlanır (rod_mount).
## Kıyafetler (Dalga 5, set_outfit): şapka HatModel'in biçimlerinden (tek ağ), yelek rengi gövdenin malzemesinde
## (angler.gdshader: dokunun yelek hücresi boyanır; tek malzeme, çizim eklemez).
##
## Animasyonlar AnimationTree ile karışır:
## - free: hıza göre bekleme / yürüme;
## - hold: olta suda, balık bekleniyor (oltayı önde tutar);
## - reel: çekişme (oltayı iki elle tutar); gerilimle geriye yaslanır (AimModifier);
## - tek seferlik: atış (Throw), balığı havaya kaldırıp gösterme ve sevinç (Cheer).
## Duruşlar tools/character_sheet.gd ile seçildi (Use_Item iksir içmeye, PickUp eğilmeye benziyor).
## Model +z yönüne bakar; burada ters çevrilir: gövde -z'ye (Angler'ın ilerisine) bakar.
## Kökü ayak hizasındadır. Model dosyası yoksa Angler ToyAngler'a düşer (available()).

const SCENE_PATH := "res://assets/models/characters/Rogue.glb"
const TEXTURE_PATH := "res://assets/models/characters/angler_texture.png"
## Balıkçı oğlan (Dalga 5): KayKit Knight.
const BOY_SCENE := "res://assets/models/characters/Knight.glb"
const BOY_TEXTURE := "res://assets/models/characters/angler_boy_texture.png"
const BOY_HIDDEN: Array[String] = ["Knight_Helmet", "Knight_Cape", "1H_Sword", "1H_Sword_Offhand", "2H_Sword",
		"Badge_Shield", "Rectangle_Shield", "Round_Shield", "Spike_Shield"]
const BOY_SHADOWLESS: Array[String] = ["Knight_ArmLeft", "Knight_ArmRight", "Knight_Head"]
## Modelin boyu ~2,2 birim; balıkçı ~1,45 m.
const MODEL_SCALE := 0.66
const HIDDEN: Array[String] = ["Rogue_Cape", "Knife", "Knife_Offhand", "1H_Crossbow", "2H_Crossbow", "Throwable"]
## Gölgesi görünmeyen parçalar: kollar gövdenin gölgesine, baş şapkanınkine karışır (CharacterKit.dress).
const SHADOWLESS: Array[String] = ["Rogue_ArmLeft", "Rogue_ArmRight", "Rogue_Head"]
const IDLE_ANIM := "Idle"
const WALK_ANIM := "Walking_A"
const HOLD_ANIM := "1H_Ranged_Aiming"
const REEL_ANIM := "2H_Ranged_Aiming"
const CAST_ANIM := "Throw"
const SHOW_ANIM := "Cheer"
const CHEER_ANIM := "Cheer"
const LOOPING: Array[String] = [IDLE_ANIM, WALK_ANIM, HOLD_ANIM, REEL_ANIM]
## Animasyonlar ve modelin parçaları (test_models.gd bunları denetler).
const REQUIRED_ANIMS: Array[String] = [IDLE_ANIM, WALK_ANIM, HOLD_ANIM, REEL_ANIM, CAST_ANIM, SHOW_ANIM, CHEER_ANIM]
const REQUIRED_NODES: Array[String] = ["Skeleton3D", "AnimationPlayer", "handslot_r"]
## İskelette olması gereken kemikler (şapka başa, eğilme omurga ve göğse).
const REQUIRED_BONES: Array[String] = ["head", "spine", "chest"]
## Yürüme animasyonunun tam hızı (m/sn).
const WALK_SPEED := 2.4
## Oltanın elde yukarı açısı (radyan).
const ROD_TILT := deg_to_rad(35.0)
## Gerilimde en çok geriye yaslanma (radyan).
const LEAN_BACK := 0.32
const HAT_COLOR := Color("#2c7d96")
const HAT_BAND := Color("#f0b637")
## Boyanmış dokuda yeleğin rengi (iki görünüşte de; tools/recolor_texture.gd): shader parlaklığını buna oranlar.
const VEST_PAINT := Color("#f0b637")
const SHADER := preload("res://scenes/player/angler.gdshader")
## KayKit dokusunun renk ızgarası (8 sütun, 4 satır).
const GRID := Vector2(8, 4)
## Görünüşler (SaveData.CHARACTERS): model, boyanmış doku, gizlenen ve gölgesi kapalı parçalar, şapkanın baş
## kemiğinden yüksekliği (modelin biriminde) ve büyüklüğü (oğlanın saçı hacimli: hasır, bere ve kasket içinden
## taşmasın), yeleğin dokudaki hücresi (sütun, satır: kızda tunik ve kollar, oğlanda yağmurluk ve çizmeler).
const LOOKS := {
	"girl": { "scene": SCENE_PATH, "texture": TEXTURE_PATH, "hidden": HIDDEN, "shadowless": SHADOWLESS, "hat_y": 0.74,
		"hat_scale": 1.0, "vest_cell": Vector2i(0, 1) },
	"boy": { "scene": BOY_SCENE, "texture": BOY_TEXTURE, "hidden": BOY_HIDDEN, "shadowless": BOY_SHADOWLESS,
		"hat_y": 0.88, "hat_scale": 1.12, "vest_cell": Vector2i(3, 0) },
}

## Görünüş (LOOKS'un anahtarı); ağaca eklenmeden önce verilir.
var look: String = "girl"
## Kıyafet (OutfitRules satırları: şapka { shape, color, band }, yelek { color, unlock }); boşsa varsayılan
## (kova şapka, dokunun sarısı). Ağaca eklenmeden önce de verilebilir (set_outfit).
var hat_look: Dictionary = {}
var vest_look: Dictionary = {}

## Olta buraya bağlanır: el yuvasının çocuğu, modelin ölçeği geri alınmış; -Z oltanın ucu.
var rod_mount: Node3D

var _model: Node3D
var _tree: AnimationTree
var _aim: AimModifier
var _hand: Node3D
var _pose: String = "free"
var _material: ShaderMaterial
var _hat: Node3D
var _hat_key: String = ""


## Görünüşün model dosyası ve dokusu projede var mı?
static func available(kind: String = "girl") -> bool:
	var spec: Dictionary = LOOKS.get(kind, LOOKS["girl"])
	return ResourceLoader.exists(str(spec["scene"])) and ResourceLoader.exists(str(spec["texture"]))


func _ready() -> void:
	var spec: Dictionary = LOOKS.get(look, LOOKS["girl"])
	var scene: PackedScene = load(str(spec["scene"]))
	_model = scene.instantiate() as Node3D
	_model.scale = Vector3.ONE * MODEL_SCALE
	_model.rotation.y = PI
	add_child(_model)
	_material = dress(_model, look)
	_apply_vest()
	_build_hat()
	_hand = _model.find_child("handslot_r", true, false) as Node3D
	rod_mount = Props.pivot(_hand, Vector3.ZERO, "RodMount")
	# Rogue'un el yuvasında nişan duruşlarında +X ileri, +Y yukarı bakar (tools/character_sheet.gd
	# ile ölçüldü). Olta -Z'ye kurulu: -Z'yi +X'ten ROD_TILT kadar yukarıya çevir; ölçeği geri al.
	var forward := Vector3(cos(ROD_TILT), sin(ROD_TILT), 0.0)
	rod_mount.transform = Transform3D(Basis.looking_at(forward, Vector3.UP).scaled(Vector3.ONE / MODEL_SCALE), Vector3.ZERO)
	var skeleton := _model.find_child("Skeleton3D", true, false) as Skeleton3D
	_aim = AimModifier.new()
	_aim.name = "Aim"
	skeleton.add_child(_aim)
	_build_tree(_model.find_child("AnimationPlayer", true, false) as AnimationPlayer)


## Kıyafet: boyanmış doku (yeleği boyanabilen malzeme), dış çizgi, gizlenen parçalar (görünüşün). Karakter
## sayfası aracı da kullanır. Döner: gövdenin malzemesi (yeleğin rengi onda: set_vest_color).
static func dress(model: Node3D, kind: String = "girl") -> ShaderMaterial:
	var spec: Dictionary = LOOKS.get(kind, LOOKS["girl"])
	var hidden: Array[String] = []
	hidden.assign(spec["hidden"])
	var shadowless: Array[String] = []
	shadowless.assign(spec["shadowless"])
	var material := ShaderMaterial.new()
	material.shader = SHADER
	material.set_shader_parameter("albedo_texture", load(str(spec["texture"])))
	var cell: Vector2i = spec["vest_cell"]
	material.set_shader_parameter("vest_cell", Vector4(cell.x / GRID.x, cell.y / GRID.y, 1.0 / GRID.x, 1.0 / GRID.y))
	var paint := VEST_PAINT.srgb_to_linear()
	material.set_shader_parameter("vest_base", 0.2126 * paint.r + 0.7152 * paint.g + 0.0722 * paint.b)
	material.next_pass = CharacterKit.outline(CharacterKit.OUTLINE_WIDTH)
	CharacterKit.apply(model, material, hidden, shadowless)
	return material


## Yeleğin rengi: boyanmış dokunun sarısı yerine (default true: dokunun kendi rengi).
static func set_vest_color(material: ShaderMaterial, color: Color, default: bool) -> void:
	material.set_shader_parameter("vest_on", not default)
	material.set_shader_parameter("vest_color", color)


## Kıyafeti giyer (Dalga 5): şapka değiştiyse yeniden kurulur, yeleğin rengi malzemede. Boş satır varsayılan.
func set_outfit(hat: Dictionary, vest: Dictionary) -> void:
	hat_look = hat
	vest_look = vest
	if _model == null:
		return
	_apply_vest()
	_build_hat()


func _apply_vest() -> void:
	var start := vest_look.is_empty() or str(vest_look.get("unlock", "start")) == "start"
	var color := Color(str(vest_look.get("color", VEST_PAINT.to_html(false))))
	set_vest_color(_material, color, start)


## Her kare. speed: yatay hız (m/sn). pose: free, hold ya da reel. tension: çekişmede gerilim (0..1+).
func animate(delta: float, speed: float, pose: String, tension: float) -> void:
	if pose != _pose:
		_pose = pose
		_tree.set("parameters/state/transition_request", pose)
	_tree.set("parameters/move/blend_position", clampf(speed / WALK_SPEED, 0.0, 1.0))
	_tree.set("parameters/reel_speed/scale", 0.8 + 0.9 * clampf(tension, 0.0, 1.2))
	var lean := -LEAN_BACK * clampf(tension, 0.0, 1.0) if pose == "reel" else 0.0
	_aim.pitch = lerpf(_aim.pitch, lean, 1.0 - exp(-10.0 * delta))
	_aim.shake = 0.02 if pose == "reel" and tension > 0.85 else 0.0


func play_cast() -> void:
	_tree.set("parameters/cast_shot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)


## Yakalanan balığı kaldırıp gösterir.
func show_fish() -> void:
	_tree.set("parameters/show_shot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)


func cheer() -> void:
	_tree.set("parameters/cheer_shot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)


## Sağ elin dünyadaki yeri (tutulan balık buraya).
func hand_point() -> Vector3:
	return _hand.global_position


# --- Kurulum ---------------------------------------------------------------------

## Şapka (HatModel'in biçimi; varsayılan turkuaz kova şapka): baş kemiğine bağlanan düğümde (modelin ölçeğinde),
## kemikten görünüşün hat_y'si kadar yukarıda (bere ve taç biraz aşağıda: HatModel.DROP). Tek ağ (bir çizim, bir
## dış çizgi, bir gölge). Biçim ve renkler değişmediyse yeniden kurulmaz. Rogue'da baş yuvası yok;
## CharacterKit.bone_slot kurar (Knight'ın miğfer yuvası gizli kalır).
func _build_hat() -> void:
	var shape := str(hat_look.get("shape", "bucket"))
	var color := Color(str(hat_look.get("color", HAT_COLOR.to_html(false))))
	var band := Color(str(hat_look.get("band", HAT_BAND.to_html(false))))
	var key := "%s|%s|%s" % [shape, color.to_html(), band.to_html()]
	if key == _hat_key:
		return
	var head := CharacterKit.bone_slot(_model, "head", "HeadSlot")
	if head == null:
		return
	_hat_key = key
	if _hat != null:
		_hat.get_parent().remove_child(_hat)
		_hat.queue_free()
	var spec: Dictionary = LOOKS.get(look, LOOKS["girl"])
	var scale := float(spec["hat_scale"])
	_hat = Props.pivot(head, Vector3(0, float(spec["hat_y"]) - HatModel.drop(shape) * scale, 0.0), "Hat")
	_hat.scale = Vector3.ONE * scale
	var node := HatModel.build(shape, color, band).build(_hat, "HatMesh", MeshBatch.vertex_material())
	var material := (node.material_override as StandardMaterial3D).duplicate() as StandardMaterial3D
	material.next_pass = CharacterKit.outline(CharacterKit.OUTLINE_WIDTH / MODEL_SCALE * 0.5)
	node.material_override = material


func _build_tree(player: AnimationPlayer) -> void:
	CharacterKit.set_looping(player, LOOPING)
	var blend := AnimationNodeBlendTree.new()
	var move := AnimationNodeBlendSpace1D.new()
	move.add_blend_point(_clip(IDLE_ANIM), 0.0, -1, &"idle")
	move.add_blend_point(_clip(WALK_ANIM), 1.0, -1, &"walk")
	blend.add_node("move", move)
	blend.add_node("hold", _clip(HOLD_ANIM))
	blend.add_node("reel", _clip(REEL_ANIM))
	blend.add_node("reel_speed", AnimationNodeTimeScale.new())
	blend.connect_node("reel_speed", 0, "reel")
	var state := AnimationNodeTransition.new()
	state.xfade_time = 0.2
	var inputs: Array[String] = ["free", "hold", "reel"]
	state.input_count = inputs.size()
	for i in inputs.size():
		state.set_input_name(i, inputs[i])
	blend.add_node("state", state)
	blend.connect_node("state", 0, "move")
	blend.connect_node("state", 1, "hold")
	blend.connect_node("state", 2, "reel_speed")
	var previous := "state"
	for shot: Array in [["cast_shot", CAST_ANIM, 0.08, 0.2], ["show_shot", SHOW_ANIM, 0.12, 0.3], ["cheer_shot", CHEER_ANIM, 0.15, 0.3]]:
		var shot_name := str(shot[0])
		blend.add_node(shot_name, CharacterKit.one_shot(player, str(shot[1]), float(shot[2]), float(shot[3]), false))
		blend.add_node(shot_name + "_clip", _clip(str(shot[1])))
		blend.connect_node(shot_name, 0, previous)
		blend.connect_node(shot_name, 1, shot_name + "_clip")
		previous = shot_name
	blend.connect_node("output", 0, previous)
	_tree = AnimationTree.new()
	_tree.name = "AnimationTree"
	_model.add_child(_tree)
	_tree.tree_root = blend
	_tree.anim_player = _tree.get_path_to(player)
	_tree.active = true


static func _clip(anim_name: String) -> AnimationNodeAnimation:
	return CharacterKit.clip(anim_name)
