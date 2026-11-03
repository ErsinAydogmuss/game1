class_name CatBody
extends Node3D
## Tekir'in gövdesi (Dalga 5): Quaternius "Animated Animales" kedisi (CC0; assets/models/cat). Model üç yüzeyli
## ve dokusuz gelir (malzemelerin rengi de yok): yüzeyler tek yüzeyde birleştirilir (köşe rengi: gövde gri,
## krem, pembe; kalıp pozdaki yer UV'de: tekir çizgileri cat.gdshader'da), tek malzeme, gölgesiz: tek çizim.
## Gerçeğinden iri (oyun kamerasından seçilsin) ve gri: kahverengi iskele tahtasına karışmasın. Animasyonlar
## (Idle, Walking) döngüsüz gelir: döngü açılır. Model +X'e bakar, ayakları y = 0'da.
## Model yoksa yedek: ToyCat (aynı arayüz).

const MODEL := "res://assets/models/cat/Cat.fbx"
const SCALE := 0.14
const IDLE := "CatArmature|Idle"
const WALK := "CatArmature|Walking"
## Yürüyüş animasyonu bu hızda (m/sn) kendi temposunda (adım boyla büyür); hızla tempo artar, en çok WALK_SPEED_MAX kat.
const WALK_PACE := 5.0 * SCALE
const WALK_SPEED_MAX := 3.2
const BLEND := 0.2
## Yüzeylerin rengi (malzemenin adına göre; sRGB) ve çizgili yüzey.
const COLORS := { "Grey": Color("#aaa69e"), "White": Color("#f4f0e6"), "Pink": Color("#e99aa0") }
const STRIPED := "Grey"
## Başın üstü (modelin kendi uzayında, ölçek 0,1'deki kemiklerden: baş x 0,2–0,31, y 0,27).
const HEAD := Vector3(0.27, 0.34, 0.0)
## Sevinç sıçrayışı (sn, m).
const HOP_TIME := 0.35
const HOP_HEIGHT := 0.08

var _model: Node3D
var _player: AnimationPlayer
var _anim: String = ""
var _hop: float = -1.0


static func available() -> bool:
	return ResourceLoader.exists(MODEL)


func _ready() -> void:
	_model = (load(MODEL) as PackedScene).instantiate() as Node3D
	_model.scale = Vector3.ONE * SCALE
	add_child(_model)
	for node in _model.find_children("*", "MeshInstance3D", true, false):
		var mi := node as MeshInstance3D
		mi.mesh = merged_mesh(mi.mesh)
		mi.material_override = material()
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_player = _model.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if _player != null:
		for anim: String in [IDLE, WALK]:
			if _player.has_animation(anim):
				_player.get_animation(anim).loop_mode = Animation.LOOP_LINEAR
	set_motion(0.0)


## Tekir'in malzemesi (her kediye ayrı: önbelleklenen kaynak çıkışta serbest kalmaz).
static func material() -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = load("res://scenes/player/cat.gdshader")
	return m


## Yürüme hızı (m/sn; 0: durur). Animasyon yürüyüş ya da bekleme, tempo hıza göre.
func set_motion(speed: float) -> void:
	if _player == null:
		return
	var anim := WALK if speed > 0.05 else IDLE
	if anim != _anim and _player.has_animation(anim):
		_anim = anim
		_player.play(anim, BLEND)
	_player.speed_scale = clampf(speed / WALK_PACE, 1.0, WALK_SPEED_MAX) if anim == WALK else 1.0


## Başın üstü (dünya): balonun ve dokunmanın yeri.
func head_point() -> Vector3:
	return to_global(HEAD * (SCALE / 0.1))


## Sevinç: küçük bir sıçrayış (mırlarken, yerken).
func hop() -> void:
	_hop = 0.0


func _process(delta: float) -> void:
	if _hop < 0.0 or _model == null:
		return
	_hop += delta
	var t := _hop / HOP_TIME
	if t >= 1.0:
		_hop = -1.0
		_model.position.y = 0.0
		return
	_model.position.y = sin(t * PI) * HOP_HEIGHT


## Modelin yüzeylerini tek yüzeyde birleştirir (çizim bütçesi): köşe rengi yüzeyin renginden (doğrusal renk; a 1
## çizgili yüzey), kalıp pozdaki yer UV'de (x: boy, y: yükseklik; UV2.x: en; modelin biriminde ×100: gövde ~5,7
## birim). Kemikler ve ağırlıklar korunur (8 ya da 4 kemik).
static func merged_mesh(mesh: Mesh) -> ArrayMesh:
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var colors := PackedColorArray()
	var uvs := PackedVector2Array()
	var uv2s := PackedVector2Array()
	var bones := PackedInt32Array()
	var weights := PackedFloat32Array()
	var indices := PackedInt32Array()
	var per := 4
	for s in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(s)
		var sv: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		if sv.is_empty():
			continue
		var sb: PackedInt32Array = arrays[Mesh.ARRAY_BONES] if arrays[Mesh.ARRAY_BONES] != null else PackedInt32Array()
		per = maxi(per, int(sb.size() / float(sv.size())))
	for s in mesh.get_surface_count():
		var arrays := mesh.surface_get_arrays(s)
		var sv: PackedVector3Array = arrays[Mesh.ARRAY_VERTEX]
		if sv.is_empty():
			continue
		var sn: PackedVector3Array = arrays[Mesh.ARRAY_NORMAL]
		var sb: PackedInt32Array = arrays[Mesh.ARRAY_BONES] if arrays[Mesh.ARRAY_BONES] != null else PackedInt32Array()
		var sw: PackedFloat32Array = arrays[Mesh.ARRAY_WEIGHTS] if arrays[Mesh.ARRAY_WEIGHTS] != null else PackedFloat32Array()
		var mat := mesh.surface_get_material(s)
		var surface_name := mat.resource_name if mat != null else ""
		var color: Color = COLORS.get(surface_name, COLORS[STRIPED])
		var linear := color.srgb_to_linear()
		linear.a = 1.0 if surface_name == STRIPED else 0.0
		var base := verts.size()
		var src := int(sb.size() / float(sv.size())) if not sb.is_empty() else 0
		for i in sv.size():
			var v := sv[i]
			verts.append(v)
			normals.append(sn[i])
			colors.append(linear)
			uvs.append(Vector2(v.x, v.z) * 100.0)
			uv2s.append(Vector2(v.y * 100.0, 0.0))
			for b in per:
				bones.append(sb[i * src + b] if b < src else 0)
				weights.append(sw[i * src + b] if b < src else 0.0)
		var si: Variant = arrays[Mesh.ARRAY_INDEX]
		if si == null:
			for i in sv.size():
				indices.append(base + i)
		else:
			for index in (si as PackedInt32Array):
				indices.append(base + index)
	var out := []
	out.resize(Mesh.ARRAY_MAX)
	out[Mesh.ARRAY_VERTEX] = verts
	out[Mesh.ARRAY_NORMAL] = normals
	out[Mesh.ARRAY_COLOR] = colors
	out[Mesh.ARRAY_TEX_UV] = uvs
	out[Mesh.ARRAY_TEX_UV2] = uv2s
	out[Mesh.ARRAY_BONES] = bones
	out[Mesh.ARRAY_WEIGHTS] = weights
	out[Mesh.ARRAY_INDEX] = indices
	var merged := ArrayMesh.new()
	merged.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, out, [], {},
			Mesh.ARRAY_FLAG_USE_8_BONE_WEIGHTS if per == 8 else 0)
	return merged
