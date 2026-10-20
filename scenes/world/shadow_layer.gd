class_name ShadowLayer
extends Node3D
## Göldeki balık gölgelerini çizer: her karede sim.shadows ile eşlenir. Doğan gölge yavaşça
## belirir, kaçan solar; yüzerken hafifçe kıvrılır. Oltadaki balık çekişme noktasında çırpınır.
## Gölge dörtgeni suyun 2 cm üstünde; -Z yönü balığın başı (shadow.gdshader). Göl ve veri dokusu
## verilirse (set_lake) gölge kıyıda söner: kıyıya çekilen iri balığın kuyruğu kuma çizilmez.
## Nadirlik tutmadan önce belli olur (rarities.json "shadow_fx"): Nadir arada pırıldar, Destansı
## kenarından mor ışıldar ve kabarcık çıkarır, Efsanevi altın parlar ve arkasında dalga izi bırakır.

const Y := 0.02
## Gölgenin eni / boyu.
const WIDTH_RATIO := 0.4
## Gölge, telefonda okunsun diye balığın boyundan biraz büyük çizilir (oyun kuralları gerçek boyu kullanır).
const DRAW_SCALE := 1.25
const FADE_IN := 1.2
const FADE_OUT := 4.0
## shadow_fx → shader'daki fx numarası.
const FX := { "none": 0, "glint": 1, "shimmer": 2, "trail": 3, "guardian": 4 }
## Destansının kabarcık aralığı ve Efsanevinin dalga izi aralığı (sn).
const BUBBLE_EVERY := Vector2(0.9, 1.7)
const WAKE_EVERY := 0.32

## Nadirliklerin tanımı (main verir); yoksa ipucu çizilmez.
var db: ContentDB
## Kabarcık ve dalga izi halkaları (main verir).
var ripples: Ripples

var _nodes: Dictionary = {}
var _fade: Dictionary = {}
## Gölge kimliği → sıradaki kabarcık ya da iz halkasına kalan süre (sn).
var _fx_clock: Dictionary = {}
## Gölge kimliği → ipucunun kurulduğu nadirlik (bot gölgenin türünü sonradan değiştirebilir).
var _fx_rarity: Dictionary = {}
var _shader: Shader
var _mesh: PlaneMesh
var _clock: float = 0.0
## Kıyıda solma: göl ve veri dokusu (set_lake; yoksa solmaz).
var _lake: LakeShape
var _lake_texture: Texture2D


func _ready() -> void:
	_shader = load("res://scenes/world/shadow.gdshader")
	_mesh = PlaneMesh.new()
	_mesh.size = Vector2.ONE


## Gölgeler kıyıda sönsün (LakeTexture.apply_shore): göl ve onun veri dokusu.
func set_lake(lake: LakeShape, texture: Texture2D) -> void:
	_lake = lake
	_lake_texture = texture
	for node: MeshInstance3D in _nodes.values():
		LakeTexture.apply_shore(node.material_override as ShaderMaterial, lake, texture)


## Gölgeleri oturumla eşler. angler: balıkçının yeri (oltadaki balık ona ters bakar);
## thrash: oltadaki balık çırpınıyor mu.
func sync(sim: ShadowSim, angler: Vector2, thrash: bool, delta: float) -> void:
	_clock += delta
	var alive := {}
	for s in sim.shadows:
		alive[s.id] = true
		var node: MeshInstance3D = _nodes.get(s.id)
		if node == null:
			node = _make()
			_nodes[s.id] = node
			_fade[s.id] = 0.0
		if int(_fx_rarity.get(s.id, -1)) != s.rarity:
			_fx_rarity[s.id] = s.rarity
			_set_fx(node, s)
		var target := 0.0 if s.mode == FishShadow.Mode.FLEE else 1.0
		var rate := FADE_OUT if target < float(_fade[s.id]) else FADE_IN
		_fade[s.id] = move_toward(float(_fade[s.id]), target, delta * rate)
		var heading := s.heading
		var wiggle := sin(_clock * 7.0 + s.id * 1.7) * 0.07
		if s.mode == FishShadow.Mode.HOOKED:
			var away := s.pos - angler
			heading = away.normalized() if away.length_squared() > 0.01 else heading
			wiggle = sin(_clock * (18.0 if thrash else 9.0)) * (0.35 if thrash else 0.15)
		elif s.mode == FishShadow.Mode.PAUSE or s.mode == FishShadow.Mode.NIBBLE:
			wiggle *= 0.4
		node.position = Vector3(s.pos.x, Y, s.pos.y)
		node.rotation = Vector3(0.0, atan2(-heading.x, -heading.y) + wiggle, 0.0)
		node.scale = Vector3(s.length * WIDTH_RATIO, 1.0, s.length) * Vector3(DRAW_SCALE, 1.0, DRAW_SCALE)
		(node.material_override as ShaderMaterial).set_shader_parameter("fade", float(_fade[s.id]))
		_step_fx(s, heading, float(_fade[s.id]), delta)
	for id: int in _nodes.keys():
		if not alive.has(id):
			(_nodes[id] as Node).queue_free()
			_nodes.erase(id)
			_fade.erase(id)
			_fx_clock.erase(id)
			_fx_rarity.erase(id)


## Gölgenin dünyadaki yeri (yoksa Vector3.INF): sunum efektleri için.
func shadow_point(id: int) -> Vector3:
	var node: MeshInstance3D = _nodes.get(id)
	return node.global_position if node != null else Vector3.INF


## Gölgenin nadirlik ipucu (shader): fx numarası, rengi ve evresi.
func _set_fx(node: MeshInstance3D, s: FishShadow) -> void:
	if db == null:
		return
	var def := db.rarity_def(s.rarity)
	var fx := int(FX.get(str(def.get("shadow_fx", "none")), 0))
	var material := node.material_override as ShaderMaterial
	material.set_shader_parameter("fx", fx)
	var color: Color = def.get("color", Color.WHITE)
	# Nadirin pırıltısı rengine göre çok açık (mavi beyaz); öbürleri kendi renginde.
	material.set_shader_parameter("tint", color.lightened(0.55) if fx == 1 else color.lightened(0.15))
	material.set_shader_parameter("phase", fmod(s.id * 0.37, 1.0))


## Destansı: arada bir gövdenin üstünde küçük kabarcık halkaları; Efsanevi: kuyruktan geriye doğru
## altın renkli dalga izi. Görünmeyen (solan) gölgede çıkmaz.
func _step_fx(s: FishShadow, heading: Vector2, fade: float, delta: float) -> void:
	if db == null or ripples == null or fade < 0.5:
		return
	var fx := int(FX.get(str(db.rarity_def(s.rarity).get("shadow_fx", "none")), 0))
	if fx < 2:
		return
	var left := float(_fx_clock.get(s.id, 0.3)) - delta
	if left > 0.0:
		_fx_clock[s.id] = left
		return
	var color: Color = db.rarity_def(s.rarity).get("color", Color.WHITE)
	if fx == 2:
		var side := Vector2(-heading.y, heading.x) * randf_range(-0.25, 0.25) * s.length
		ripples.spawn(s.pos + heading * randf_range(-0.3, 0.3) * s.length + side, 0.12, 0.7,
				Color(color.lightened(0.5), 0.85), 0.22)
		_fx_clock[s.id] = randf_range(BUBBLE_EVERY.x, BUBBLE_EVERY.y)
	else:
		ripples.spawn(s.pos - heading * s.length * 0.55, s.length * 0.55, 1.3, Color(color.lightened(0.2), 0.7), 0.12)
		_fx_clock[s.id] = WAKE_EVERY


func _make() -> MeshInstance3D:
	var node := MeshInstance3D.new()
	node.mesh = _mesh
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := ShaderMaterial.new()
	material.shader = _shader
	material.render_priority = 1
	if _lake != null:
		LakeTexture.apply_shore(material, _lake, _lake_texture)
	node.material_override = material
	add_child(node)
	return node
