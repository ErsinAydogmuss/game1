class_name ToyNine
extends Node3D
## Nine'nin yedek görünümü (KayKit modeli yoksa): kodla kurulan, ayakta bir figür (Props).
## NineBody ile aynı arayüz: head_point, look_at_point, nod, cheer, give.
## +z yönüne bakar; kökü ayak hizasında. Kare başı hareket _process'te.

const HEAD := Vector3(0.0, 1.05, 0.0)
const MOVE_TIME := 1.2
const CARDIGAN := Color("#d39b2f")
const SKIRT := Color("#7a4a5e")
const SKIN := Color("#f2c0a0")
const HAIR := Color("#c4bfba")
const SHOE := Color("#5b3a28")

var _head: Node3D
var _arms: Array[Node3D] = []
var _target := Vector3.ZERO
var _has_target: bool = false
var _yaw: float = 0.0
var _nod_time: float = -1.0
var _cheer_time: float = -1.0
var _give_time: float = -1.0


func _ready() -> void:
	# Uzun etek, hırka, önlük.
	Props.cylinder(self, 0.2, 0.27, 0.5, Vector3(0, 0.29, 0), SKIRT, 12)
	Props.capsule(self, 0.19, 0.5, Vector3(0, 0.66, 0), CARDIGAN)
	Props.box(self, Vector3(0.3, 0.42, 0.03), Vector3(0, 0.42, 0.22), NineBody.APRON, Vector3(0.12, 0, 0))
	for side: float in [-1.0, 1.0]:
		Props.box(self, Vector3(0.1, 0.06, 0.16), Vector3(side * 0.09, 0.03, 0.04), SHOE)
	_head = Props.pivot(self, Vector3(0, 0.88, 0), "Head")
	Props.sphere(_head, 0.19, Vector3(0, 0.14, 0), SKIN)
	Props.sphere(_head, 0.2, Vector3(0, 0.2, -0.05), HAIR, 12, 6, Vector3(1.0, 0.9, 1.0))
	# Yazma (başın üstü ve arkası) ve çene altındaki düğüm.
	Props.sphere(_head, 0.215, Vector3(0, 0.2, -0.08), NineBody.SCARF, 14, 7, Vector3(1.04, 0.95, 1.05))
	Props.sphere(_head, 0.04, Vector3(0, -0.03, 0.13), NineBody.SCARF)
	for side: float in [-1.0, 1.0]:
		var lens := Props.cylinder(_head, 0.045, 0.045, 0.01, Vector3(side * 0.07, 0.15, 0.185), NineBody.GLASSES, 10,
				Vector3(PI * 0.5, 0, 0))
		lens.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var arm := Props.pivot(self, Vector3(side * 0.21, 0.82, 0), "Arm")
		Props.capsule(arm, 0.055, 0.38, Vector3(0, -0.15, 0.04), CARDIGAN, Vector3(0.3, 0, 0))
		Props.sphere(arm, 0.055, Vector3(0, -0.32, 0.12), SKIN)
		_arms.append(arm)


func head_point() -> Vector3:
	return to_global(HEAD)


func look_at_point(point: Vector3, has_target: bool) -> void:
	_target = point
	_has_target = has_target


func nod() -> void:
	_nod_time = 0.0


func cheer() -> void:
	_cheer_time = 0.0


func give() -> void:
	_give_time = 0.0


func _process(delta: float) -> void:
	var want := 0.0
	if _has_target:
		var local := to_local(_target) - _head.position
		var raw := atan2(local.x, local.z)
		if absf(raw) < LookModifier.BEHIND:
			want = clampf(raw, -1.3, 1.3)
	_yaw = lerpf(_yaw, want, 1.0 - exp(-LookModifier.SMOOTH * delta))
	var pitch := 0.0
	if _nod_time >= 0.0:
		_nod_time += delta
		var t := minf(_nod_time / NineBody.NOD_TIME, 1.0)
		pitch = NineBody.NOD_ANGLE * maxf(0.0, sin(t * TAU * 2.0)) * (1.0 - t)
		if t >= 1.0:
			_nod_time = -1.0
	_head.rotation = Vector3(pitch, _yaw, 0.0)
	var raise := _pulse(delta, "_cheer_time")
	var reach := _pulse(delta, "_give_time")
	for arm in _arms:
		arm.rotation.x = -2.4 * raise - 1.1 * reach


## Tek seferlik hareketin o anki gücü (0..1..0); süre bitince sayaç kapanır.
func _pulse(delta: float, field: String) -> float:
	var t := float(get(field))
	if t < 0.0:
		return 0.0
	t += delta
	set(field, t if t < MOVE_TIME else -1.0)
	return sin(clampf(t / MOVE_TIME, 0.0, 1.0) * PI)
