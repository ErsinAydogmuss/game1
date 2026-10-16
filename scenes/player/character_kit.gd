class_name CharacterKit
extends RefCounted
## KayKit karakterleri için ortak yardımcılar (AnglerBody, ElderBody, tools/character_sheet.gd):
## boyanmış dokuyla giydirme, ters kabuk dış çizgi, kodla takılan parçalara dış çizgi,
## AnimationTree düğümleri ve üst gövde süzgeci.

const OUTLINE_WIDTH := 0.025
const OUTLINE_COLOR := Color("#2b1a10")
## Üst gövde süzgecinin dışında kalan kemikler (oturan Dede'nin bacakları yerinde kalsın).
const LOWER_BODY: Array[String] = ["root", "hips", "upperleg.l", "lowerleg.l", "foot.l", "toes.l",
		"upperleg.r", "lowerleg.r", "foot.r", "toes.r"]


## Modeli giydirir: her görünen parçaya doku ve dış çizgi; hidden'daki parçalar gizlenir.
static func dress(model: Node3D, texture: Texture2D, hidden: Array[String]) -> void:
	var material := StandardMaterial3D.new()
	material.albedo_texture = texture
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	material.roughness = 0.8
	material.rim_enabled = true
	material.rim = 0.25
	material.rim_tint = 0.6
	material.next_pass = outline(OUTLINE_WIDTH)
	for node in model.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		if hidden.has(str(mesh.name)):
			mesh.visible = false
			continue
		mesh.material_override = material


## Ters kabuk dış çizgi malzemesi: karakter suyun ve çimenin önünde seçilsin.
static func outline(width: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.cull_mode = BaseMaterial3D.CULL_FRONT
	material.grow = true
	material.grow_amount = width
	material.albedo_color = OUTLINE_COLOR
	return material


## Kodla kurulan parçalara (şapka) dış çizgi. Props'un paylaşılan malzemesi kopyalanır.
static func outline_parts(root: Node3D, width: float) -> void:
	for node in root.find_children("*", "MeshInstance3D", true, false):
		var mesh := node as MeshInstance3D
		var material := (mesh.material_override as StandardMaterial3D).duplicate() as StandardMaterial3D
		material.next_pass = outline(width)
		mesh.material_override = material


## KayKit animasyonları döngüsüz gelir; adı verilenler döngüye alınır.
static func set_looping(player: AnimationPlayer, names: Array[String]) -> void:
	var library := player.get_animation_library("")
	for anim_name in names:
		if library.has_animation(anim_name):
			library.get_animation(anim_name).loop_mode = Animation.LOOP_LINEAR


static func clip(anim_name: String) -> AnimationNodeAnimation:
	var node := AnimationNodeAnimation.new()
	node.animation = StringName(anim_name)
	return node


## Tek seferlik animasyon düğümü; upper_body ise yalnızca belden yukarısını oynatır.
static func one_shot(player: AnimationPlayer, anim_name: String, fade_in: float, fade_out: float,
		upper_body: bool) -> AnimationNodeOneShot:
	var one := AnimationNodeOneShot.new()
	one.fadein_time = fade_in
	one.fadeout_time = fade_out
	if upper_body and player.has_animation(anim_name):
		one.filter_enabled = true
		var anim := player.get_animation(anim_name)
		for i in anim.get_track_count():
			var path := anim.track_get_path(i)
			if not LOWER_BODY.has(str(path.get_concatenated_subnames())):
				one.set_filter_path(path, true)
	return one


## Kemiğe bağlı bir düğüm: modelde o kemiğin yuvası varsa o, yoksa yeni bir BoneAttachment3D.
static func bone_slot(model: Node3D, bone: String, slot_name: String) -> Node3D:
	var existing := model.find_child(slot_name, true, false) as BoneAttachment3D
	if existing != null:
		return existing
	var skeleton := model.find_child("Skeleton3D", true, false) as Skeleton3D
	if skeleton == null or skeleton.find_bone(bone) < 0:
		return null
	var slot := BoneAttachment3D.new()
	slot.name = slot_name
	slot.bone_name = bone
	skeleton.add_child(slot)
	return slot
