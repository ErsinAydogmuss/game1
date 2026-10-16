class_name ToyAngler
extends Node3D
## Kodla kurulan basit balıkçı (KayKit modeli yoksa yedek). AnglerBody ile aynı arayüz:
## rod_mount, animate(), play_cast(), show_fish(), cheer(), hand_point(). Gövde -z'ye bakar.

## Olta buraya bağlanır; -Z oltanın ucu.
var rod_mount: Node3D

var _body: Node3D
var _arm: Node3D
var _pose: String = "free"
var _cast_t: float = -1.0
var _cheer_t: float = -1.0
var _step: float = 0.0
var _angle: float = 0.0
var _tension: float = 0.0


func _ready() -> void:
	_body = Props.pivot(self, Vector3.ZERO, "Body")
	Props.capsule(_body, 0.24, 0.95, Vector3(0, 0.48, 0), Color("#f0b637"))
	Props.sphere(_body, 0.21, Vector3(0, 1.16, 0), Color("#f2c7a5"))
	Props.cylinder(_body, 0.17, 0.32, 0.14, Vector3(0, 1.34, 0), AnglerBody.HAT_COLOR, 12)
	Props.sphere(_body, 0.045, Vector3(-0.08, 1.2, -0.18), Color("#2b2f36"), 6, 4)
	Props.sphere(_body, 0.045, Vector3(0.08, 1.2, -0.18), Color("#2b2f36"), 6, 4)
	_arm = Props.pivot(_body, Vector3(0.22, 0.75, -0.1), "Arm")
	rod_mount = Props.pivot(_arm, Vector3.ZERO, "RodMount")


func animate(delta: float, speed: float, pose: String, tension: float) -> void:
	_pose = pose
	_tension = tension
	if speed > 0.1:
		_step += delta * 9.0
		_body.position.y = absf(sin(_step)) * 0.05
	else:
		_body.position.y = move_toward(_body.position.y, 0.0, delta)
	var angle := deg_to_rad(18.0)
	if pose == "hold":
		angle = deg_to_rad(28.0)
	elif pose == "reel":
		angle = lerpf(deg_to_rad(30.0), deg_to_rad(58.0), clampf(tension, 0.0, 1.0))
	if _cast_t >= 0.0:
		_cast_t += delta
		if _cast_t < 0.16:
			angle = lerpf(angle, deg_to_rad(95.0), _cast_t / 0.16)
		elif _cast_t < 0.32:
			angle = lerpf(deg_to_rad(95.0), deg_to_rad(5.0), (_cast_t - 0.16) / 0.16)
		else:
			_cast_t = -1.0
	_angle = lerpf(_angle, angle, minf(1.0, delta * (30.0 if _cast_t >= 0.0 else 8.0)))
	_arm.rotation.x = _angle
	if _cheer_t >= 0.0:
		_cheer_t += delta
		_body.position.y = absf(sin(_cheer_t * 9.0)) * 0.22 * maxf(0.0, 1.0 - _cheer_t / 1.2)
		if _cheer_t > 1.2:
			_cheer_t = -1.0


func play_cast() -> void:
	_cast_t = 0.0


func show_fish() -> void:
	_cheer_t = 0.0


func cheer() -> void:
	_cheer_t = 0.0


func hand_point() -> Vector3:
	return _arm.global_position
