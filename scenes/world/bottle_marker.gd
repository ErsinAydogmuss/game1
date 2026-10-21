class_name BottleMarker
extends Node3D
## Gölün Sırrı'nın şişesi (Dalga 4, 5. adım; docs/gdd.md §10.5): suda yan yatmış, mantarlı cam şişe; içinde
## mühürlü rulo mektup. Kodla, tek ağ ve tek malzeme (tek çizim, gölgesiz). Suyla iner kalkar, yavaşça döner,
## nabız gibi parlar; arada çevresinde küçük bir halka (ripples verilirse). Dokunma denetimi hit (ekran noktası).
## Alınınca suyun üstüne kalkıp küçülür ve söner (pick_up). Süreler _process(delta) toplamıyla.

## Dokunma payı: şişenin ekrandaki yerine bu kadar yakın (1080 birimlik ekranda).
const HIT_RADIUS := 80.0
## Şişenin boyu (gerçeğinden iri: kameradan ~12 m'de seçilsin).
const SCALE := 1.45
## Şişenin ortası su yüzeyinin bu kadar üstünde (yarısı suda); iniş kalkış ve sallanma.
const FLOAT_Y := 0.02
const BOB := 0.025
## Parıltı: köşe renginin üstüne sıcak bir ışık, bu iki güç arasında nabız gibi.
const GLOW := Color("#ffe39a")
const GLOW_ENERGY := Vector2(0.15, 0.7)
## Alınınca kalkış süresi (sn) ve yüksekliği (m); çevresindeki halkaların aralığı (sn).
const PICK_TIME := 0.6
const PICK_RISE := 0.7
const RIPPLE_EVERY := 2.4
const GLASS := Color("#93e0cf")
const GLASS_EDGE := Color("#5fb9a7")
const CORK := Color("#a8743f")
const PAPER := Color("#f5e8c6")
const SEAL := Color("#d8423a")

## Halkalar (main verir; yoksa halka çıkmaz).
var ripples: Ripples
var _node: MeshInstance3D
var _material: StandardMaterial3D
var _base := Vector3.ZERO
var _clock: float = 0.0
## Alınıyor: geçen süre (alınmıyorsa -1).
var _pick: float = -1.0
var _ripple: float = 0.0


## Şişenin ağı: x ekseni boyunca yatan gövde, omuz, boyun, mantar; gövdenin ortasında camın ardından görünen
## rulo kâğıt ve kırmızı mühür bandı (sahnede tek şişe: önbelleklenmez, çıkışta kaynak sızmasın).
static func bottle_mesh() -> ArrayMesh:
	var batch := MeshBatch.new()
	var side := Vector3(0.0, 0.0, PI * 0.5)
	batch.cylinder(0.085, 0.085, 0.3, Vector3.ZERO, GLASS, 14, side)
	batch.sphere(0.085, Vector3(-0.15, 0.0, 0.0), GLASS_EDGE, Vector3(0.35, 1.0, 1.0), 14, 6)
	batch.sphere(0.085, Vector3(0.15, 0.0, 0.0), GLASS, Vector3(0.7, 1.0, 1.0), 14, 6)
	batch.cylinder(0.034, 0.04, 0.12, Vector3(0.24, 0.0, 0.0), GLASS, 10, side)
	batch.cylinder(0.041, 0.041, 0.022, Vector3(0.295, 0.0, 0.0), GLASS_EDGE, 10, side)
	batch.cylinder(0.036, 0.032, 0.07, Vector3(0.335, 0.0, 0.0), CORK, 10, side)
	batch.cylinder(0.088, 0.088, 0.13, Vector3(-0.01, 0.0, 0.0), PAPER, 14, side)
	batch.cylinder(0.09, 0.09, 0.025, Vector3(-0.01, 0.0, 0.0), SEAL, 14, side)
	return batch.mesh()


func _ready() -> void:
	_material = StandardMaterial3D.new()
	_material.vertex_color_use_as_albedo = true
	_material.vertex_color_is_srgb = true
	_material.roughness = 0.25
	_material.metallic_specular = 0.9
	_material.emission_enabled = true
	_material.emission = GLOW
	_material.emission_energy_multiplier = GLOW_ENERGY.x
	_node = MeshInstance3D.new()
	_node.name = "Bottle"
	_node.mesh = bottle_mesh()
	_node.material_override = _material
	_node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_node)
	visible = false


## Şişe p noktasında suda belirir (görünmüyorsa ya da başka yerdeyse).
func show_at(p: Vector2) -> void:
	_base = Vector3(p.x, FLOAT_Y, p.y)
	_pick = -1.0
	_node.scale = Vector3.ONE * SCALE
	_node.position = _base
	visible = true


## Şişe kalkar (dokunuş kaybolmasın: alındı sayılır); kalkış bitince gizlenir.
func pick_up() -> void:
	if visible and _pick < 0.0:
		_pick = 0.0
		if ripples != null:
			ripples.spawn(Vector2(_base.x, _base.z), 0.9, 0.7)


## Şişe gizlenir (mektup okundu, kayıt değişti, şişe artık yok).
func hide_bottle() -> void:
	visible = false
	_pick = -1.0


func is_picking() -> bool:
	return _pick >= 0.0


## Şişenin yeri (xz; görünmüyorsa Dice.NO_POINT).
func spot() -> Vector2:
	return Vector2(_base.x, _base.z) if visible else Dice.NO_POINT


## Şişenin ortası (dünya; botun dokunuşu için). Görünmüyorsa Vector3.INF.
func point() -> Vector3:
	return _node.global_position if visible else Vector3.INF


## Ekran noktası şişenin üstünde mi (yeri HIT_RADIUS içinde; alınırken değil).
func hit(view: Camera3D, screen: Vector2) -> bool:
	if view == null or not visible or _pick >= 0.0 or not is_inside_tree():
		return false
	var at := _node.global_position
	if view.is_position_behind(at):
		return false
	var scale := get_viewport().get_visible_rect().size.y / 1080.0
	return view.unproject_position(at).distance_to(screen) <= HIT_RADIUS * scale


func _process(delta: float) -> void:
	if not visible:
		return
	_clock += delta
	if _pick >= 0.0:
		_pick += delta
		var t := clampf(_pick / PICK_TIME, 0.0, 1.0)
		_node.position = _base + Vector3(0.0, sin(t * PI * 0.5) * PICK_RISE, 0.0)
		_node.scale = Vector3.ONE * SCALE * (1.0 - t * 0.85)
		_node.rotation.y += delta * 6.0
		_material.emission_energy_multiplier = lerpf(GLOW_ENERGY.y, 1.6, t)
		if t >= 1.0:
			hide_bottle()
		return
	_node.position = _base + Vector3(0.0, sin(_clock * 1.6) * BOB, 0.0)
	_node.rotation = Vector3(sin(_clock * 1.2) * 0.12, _clock * 0.25, 0.18 + sin(_clock * 0.9) * 0.08)
	var pulse := 0.5 + 0.5 * sin(_clock * 2.6)
	_material.emission_energy_multiplier = lerpf(GLOW_ENERGY.x, GLOW_ENERGY.y, pulse)
	_ripple += delta
	if ripples != null and _ripple >= RIPPLE_EVERY:
		_ripple = 0.0
		ripples.spawn(Vector2(_base.x, _base.z), 0.55, 1.1, Color(1.0, 0.96, 0.8, 0.7), 0.08)
