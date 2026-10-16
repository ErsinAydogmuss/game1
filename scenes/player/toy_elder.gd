class_name ToyElder
extends Node3D
## Dede'nin yedek görünümü (KayKit modeli yoksa): kodla kurulan, oturan bir figür (Props).
## ElderBody ile aynı arayüz: seat_offset, head_point, look_at_point, nod, cheer.
## +z yönüne bakar; kökü ayak hizasında. Kare başı hareket _process'te.

## Oturma noktası (diz arkası) ve başın ortası (m).
const SEAT := Vector3(0.0, 0.27, 0.02)
const HEAD := Vector3(0.0, 1.0, -0.2)
const CHEER_TIME := 1.2
const SWEATER := Color("#a8443a")
const PANTS := Color("#5c5242")
const BOOT := Color("#4a3426")
const SKIN := Color("#e8ae8c")
const WHITE := Color("#f4f1ea")
const CAP := Color("#5b5148")

var _head: Node3D
var _arms: Array[Node3D] = []
var _target := Vector3.ZERO
var _has_target: bool = false
var _yaw: float = 0.0
var _nod_time: float = -1.0
var _cheer_time: float = -1.0


func _ready() -> void:
	# Oturak ve bacaklar: uyluklar öne uzanır, baldırlar kenardan aşağı sarkar.
	Props.box(self, Vector3(0.36, 0.14, 0.3), Vector3(0, 0.34, -0.2), PANTS)
	for side: float in [-1.0, 1.0]:
		Props.box(self, Vector3(0.13, 0.12, 0.3), Vector3(side * 0.1, 0.34, 0.0), PANTS)
		Props.box(self, Vector3(0.12, 0.22, 0.12), Vector3(side * 0.1, 0.2, 0.12), PANTS)
		Props.box(self, Vector3(0.13, 0.08, 0.2), Vector3(side * 0.1, 0.07, 0.16), BOOT)
	Props.capsule(self, 0.19, 0.56, Vector3(0, 0.62, -0.2), SWEATER)
	_head = Props.pivot(self, Vector3(0, 0.86, -0.2), "Head")
	Props.sphere(_head, 0.2, Vector3(0, 0.14, 0), SKIN)
	# Sakal, kasket ve siperi.
	Props.sphere(_head, 0.16, Vector3(0, 0.04, 0.1), WHITE, 12, 6, Vector3(1.1, 0.9, 0.75))
	Props.cylinder(_head, 0.2, 0.21, 0.08, Vector3(0, 0.3, 0), CAP, 14)
	Props.box(_head, Vector3(0.24, 0.03, 0.14), Vector3(0, 0.27, 0.2), CAP.darkened(0.15))
	# Kollar omuzdan döner; eller dizlerde.
	for side: float in [-1.0, 1.0]:
		var arm := Props.pivot(self, Vector3(side * 0.22, 0.76, -0.2), "Arm")
		Props.capsule(arm, 0.06, 0.4, Vector3(0, -0.15, 0.06), SWEATER, Vector3(0.4, 0, 0))
		Props.sphere(arm, 0.06, Vector3(0, -0.33, 0.16), SKIN)
		_arms.append(arm)


func seat_offset() -> Vector3:
	return SEAT


func head_point() -> Vector3:
	return to_global(HEAD)


func look_at_point(point: Vector3, has_target: bool) -> void:
	_target = point
	_has_target = has_target


func nod() -> void:
	_nod_time = 0.0


func cheer() -> void:
	_cheer_time = 0.0


func _process(delta: float) -> void:
	var want := 0.0
	if _has_target:
		var local := to_local(_target) - _head.position
		want = clampf(atan2(local.x, local.z), -1.3, 1.3)
	_yaw = lerpf(_yaw, want, 1.0 - exp(-LookModifier.SMOOTH * delta))
	var pitch := 0.0
	if _nod_time >= 0.0:
		_nod_time += delta
		var t := minf(_nod_time / ElderBody.NOD_TIME, 1.0)
		pitch = ElderBody.NOD_ANGLE * maxf(0.0, sin(t * TAU * 2.0)) * (1.0 - t)
		if t >= 1.0:
			_nod_time = -1.0
	_head.rotation = Vector3(pitch, _yaw, 0.0)
	var raise := 0.0
	if _cheer_time >= 0.0:
		_cheer_time += delta
		raise = sin(clampf(_cheer_time / CHEER_TIME, 0.0, 1.0) * PI)
		if _cheer_time >= CHEER_TIME:
			_cheer_time = -1.0
	for arm in _arms:
		arm.rotation.x = -2.4 * raise
