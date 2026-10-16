class_name CatchFx
extends Node3D
## Yakalanan balığın gösterisi: balık balıkçının önünde kıvrılır (FishMesh, küçültülmüş boy),
## üstünde nadirlik simgesi, adı ve boyu (CatchTag, 2B) yükselip söner; Nadir ve üstünde balıkçının
## çevresinde nadirlik renginde ışık sütunu yükselir. Sütun balığın arkasında kalır (toplamalı ışık
## balığı soldurmasın): balık kameraya doğru uzatılmıştır.
## Balık kameraya yan döner (profilinden görünsün). Süreler _process(delta) toplamıyla ölçülür.

const HOLD_TIME := 2.2
const BEAM_TIME := 1.8

var _fish: FishMesh
var _tag: CatchTag
## Etiketin bağlı olduğu 3B nokta (balığın üstü; yükselir).
var _tag_point := Vector3.ZERO
var _beam: MeshInstance3D
var _beam_material: StandardMaterial3D
var _hand: Callable
var _origin: Callable
var _age: float = -1.0
var _beam_age: float = -1.0


## def: balığın tanımı; size_cm: boyu; title: çevrilmiş adı; color: nadirlik rengi;
## hand: balığın gösterileceği yeri veren fonksiyon (her kare okunur); beam: ışık sütunu olsun mu;
## origin: sütunun ortası (balıkçının yeri; verilmezse balığın yeri); icon: nadirlik simgesi
## (GameIcon adı, UiKit.rarity_icon).
func show_catch(def: Dictionary, size_cm: int, title: String, color: Color, hand: Callable, beam: bool,
		origin: Callable = Callable(), icon: String = "") -> void:
	clear()
	_hand = hand
	_origin = origin
	var length := FishMesh.display_length(size_cm)
	_fish = FishMesh.make(def, length)
	_fish.set_wiggle(0.16, 11.0)
	_fish.rotation.y = FollowCamera.YAW
	_fish.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(_fish)
	if _tag == null:
		_tag = CatchTag.new()
		_tag.name = "Tag"
		add_child(_tag)
	_tag_point = (hand.call() as Vector3) + Vector3(0.0, 0.85, 0.0) if hand.is_valid() else Vector3.ZERO
	_place_tag()
	_tag.show_tag(title, tr("UI_SIZE_CM") % size_cm, color, icon, HOLD_TIME)
	_age = 0.0
	if beam:
		_make_beam(color)
	_place()


## Gösteri sürüyor mu (kamera yakınlaşır)?
func is_showing() -> bool:
	return _age >= 0.0 and _age < HOLD_TIME * 0.8


func clear() -> void:
	for node: Node in [_fish, _beam]:
		if node != null:
			node.queue_free()
	if _tag != null:
		_tag.clear()
	_fish = null
	_beam = null
	_age = -1.0
	_beam_age = -1.0


func _process(delta: float) -> void:
	if _age < 0.0:
		return
	_age += delta
	_place()
	var t := _age / HOLD_TIME
	_tag_point.y += delta * 0.25
	_place_tag()
	if _fish != null:
		_fish.set_wiggle(0.16 * maxf(0.3, 1.0 - t), 11.0)
	if _beam != null:
		_beam_age += delta
		var b := _beam_age / BEAM_TIME
		_beam_material.albedo_color.a = 0.55 * clampf((1.0 - b) * 2.0, 0.0, 1.0) * clampf(_beam_age * 5.0, 0.0, 1.0)
		_beam.scale = Vector3(1.0 + b * 0.3, minf(1.0, _beam_age * 3.0), 1.0 + b * 0.3)
	if _age >= HOLD_TIME:
		clear()


func _place() -> void:
	if not _hand.is_valid() or _fish == null:
		return
	var hand: Vector3 = _hand.call()
	_fish.position = hand + Vector3(0.0, 0.05 * sin(_age * 9.0), 0.0)
	if _beam != null:
		# Sütunun dibi yerde kalsın (ölçek ortadan büyür).
		var base: Vector3 = _origin.call() if _origin.is_valid() else hand
		_beam.position = Vector3(base.x, 3.5 * _beam.scale.y, base.z)


## Etiket 3B noktanın ekrandaki yerine (kamera arkasındaysa gizli).
func _place_tag() -> void:
	if _tag == null:
		return
	var view := get_viewport().get_camera_3d()
	if view == null or view.is_position_behind(_tag_point):
		_tag.modulate.a = 0.0
		return
	_tag.anchor = view.unproject_position(_tag_point)


func _make_beam(color: Color) -> void:
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.42
	mesh.bottom_radius = 0.55
	mesh.height = 7.0
	mesh.radial_segments = 16
	mesh.rings = 1
	mesh.cap_top = false
	mesh.cap_bottom = false
	_beam_material = StandardMaterial3D.new()
	_beam_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_beam_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_beam_material.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	_beam_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_beam_material.no_depth_test = false
	_beam_material.albedo_color = Color(color, 0.0)
	_beam = MeshInstance3D.new()
	_beam.mesh = mesh
	_beam.material_override = _beam_material
	_beam.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_beam.position.y = 3.5
	add_child(_beam)
	_beam_age = 0.0
