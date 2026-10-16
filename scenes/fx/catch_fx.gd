class_name CatchFx
extends Node3D
## Yakalanan balığın gösterisi: balık balıkçının önünde kıvrılır (FishMesh, logaritmik boy),
## üstünde adı ve boyu yükselip söner; Nadir ve üstünde nadirlik renginde ışık sütunu yükselir.
## Balık kameraya yan döner (profilinden görünsün). Süreler _process(delta) toplamıyla ölçülür.

const HOLD_TIME := 2.2
const BEAM_TIME := 1.8

var _fish: FishMesh
var _label: Label3D
var _beam: MeshInstance3D
var _beam_material: StandardMaterial3D
var _hand: Callable
var _age: float = -1.0
var _beam_age: float = -1.0


## def: balığın tanımı; size_cm: boyu; title: çevrilmiş adı; color: nadirlik rengi;
## point: balığın gösterileceği yeri veren fonksiyon (her kare okunur); beam: ışık sütunu olsun mu.
func show_catch(def: Dictionary, size_cm: int, title: String, color: Color, hand: Callable, beam: bool) -> void:
	clear()
	_hand = hand
	var length := FishMesh.display_length(size_cm)
	_fish = FishMesh.make(def, length)
	_fish.set_wiggle(0.16, 11.0)
	_fish.rotation.y = FollowCamera.YAW
	_fish.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(_fish)
	_label = Label3D.new()
	_label.text = "%s\n%s" % [UiKit.upper(title), tr("UI_SIZE_CM") % size_cm]
	_label.font = UiKit.display_font()
	_label.font_size = 96
	_label.pixel_size = 0.0042
	_label.outline_size = 22
	_label.modulate = color.lightened(0.15)
	_label.outline_modulate = UiKit.OUTLINE
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.no_depth_test = true
	_label.fixed_size = false
	add_child(_label)
	_age = 0.0
	if beam:
		_make_beam(color)
	_place()


## Gösteri sürüyor mu (kamera yakınlaşır)?
func is_showing() -> bool:
	return _age >= 0.0 and _age < HOLD_TIME * 0.8


func clear() -> void:
	for node: Node in [_fish, _label, _beam]:
		if node != null:
			node.queue_free()
	_fish = null
	_label = null
	_beam = null
	_age = -1.0
	_beam_age = -1.0


func _process(delta: float) -> void:
	if _age < 0.0:
		return
	_age += delta
	_place()
	var t := _age / HOLD_TIME
	_label.position.y += delta * 0.25
	_label.modulate.a = clampf((1.0 - t) * 3.0, 0.0, 1.0)
	_label.outline_modulate.a = _label.modulate.a
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
	if _age < 0.05:
		_label.position = hand + Vector3(0.0, 1.45, 0.0)
	if _beam != null:
		# Sütunun dibi yerde kalsın (ölçek ortadan büyür).
		_beam.position = Vector3(hand.x, 3.5 * _beam.scale.y, hand.z)


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
