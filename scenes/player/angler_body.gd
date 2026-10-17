class_name AnglerBody
extends Node3D
## Balıkçı kız: KayKit "Rogue" modelinden (CC0, bkz. assets/CREDITS.md). Doku balıkçı renklerine
## boyanır (tools/recolor_texture.gd); pelerin, bıçaklar, arbaletler ve bomba gizlenir. Kodla bir
## balıkçı şapkası başa takılır; olta sağ elin yuvasına (handslot_r) bağlanır (rod_mount).
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

## Olta buraya bağlanır: el yuvasının çocuğu, modelin ölçeği geri alınmış; -Z oltanın ucu.
var rod_mount: Node3D

var _model: Node3D
var _tree: AnimationTree
var _aim: AimModifier
var _hand: Node3D
var _pose: String = "free"


## Model dosyası ve dokusu projede var mı?
static func available() -> bool:
	return ResourceLoader.exists(SCENE_PATH) and ResourceLoader.exists(TEXTURE_PATH)


func _ready() -> void:
	var scene: PackedScene = load(SCENE_PATH)
	_model = scene.instantiate() as Node3D
	_model.scale = Vector3.ONE * MODEL_SCALE
	_model.rotation.y = PI
	add_child(_model)
	dress(_model)
	_add_hat()
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


## Kıyafet: boyanmış doku, dış çizgi, gizlenen parçalar. Karakter sayfası aracı da kullanır.
static func dress(model: Node3D) -> void:
	CharacterKit.dress(model, load(TEXTURE_PATH), HIDDEN, SHADOWLESS)


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

## Kova biçimli balıkçı şapkası: baş kemiğine bağlanan düğümde (modelin ölçeğinde).
## Rogue'da baş yuvası yok; CharacterKit.bone_slot kurar.
func _add_hat() -> void:
	var head := CharacterKit.bone_slot(_model, "head", "HeadSlot")
	if head == null:
		return
	var hat := Props.pivot(head, Vector3(0, 0.74, 0.0), "Hat")
	Props.cylinder(hat, 0.42, 0.52, 0.34, Vector3(0, 0.13, 0), HAT_COLOR, 14)
	# Aşağı eğik geniş kenar (kova şapka).
	Props.cylinder(hat, 0.53, 0.76, 0.09, Vector3(0, -0.07, 0), HAT_COLOR.darkened(0.12), 18)
	Props.cylinder(hat, 0.515, 0.515, 0.08, Vector3(0, 0.0, 0), HAT_BAND, 14)
	# Tek ağ (bir çizim, bir dış çizgi, bir gölge).
	MeshBatch.merge(hat)
	CharacterKit.outline_parts(hat, CharacterKit.OUTLINE_WIDTH / MODEL_SCALE * 0.5)


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
