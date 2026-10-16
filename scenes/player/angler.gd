class_name Angler
extends Node3D
## Balıkçı (gri kutu yer tutucusu; 6. adımda KayKit Rogue gelir). Göl düzleminde 2B yürür:
## karada ve iskelede durabilir, suya giremez (kıyıda durur). Oltayı tutar; atar, sarar, sevinir.
## Kare başı hareket _process'te (Tween yok).

## Yürüme bitti (hedefe vardı ya da kıyıda durdu).
signal arrived

const SPEED := 2.4
const TURN := 10.0
## Kıyıda bu kadar geride durur (gövde suya taşmasın).
const BODY := 0.22
const ROD_LENGTH := 2.4

var lake: LakeShape
## Durulan yerin yüksekliği (LakeScene.stand_height).
var height_at: Callable
var facing := Vector2(0.0, -1.0)
## Oltanın kalkma oranı (0 = önde alçak, 1 = dik): çekişmede gerilimle yükselir.
var rod_raise: float = 0.0

var _target := Vector2.ZERO
var _walking: bool = false
var _body: Node3D
var _rod_pivot: Node3D
var _tip: Node3D
var _cast_t: float = -1.0
var _cheer_t: float = -1.0
var _step_clock: float = 0.0
var _y: float = 0.0
var _rod_angle: float = 0.0


func _ready() -> void:
	_body = Props.pivot(self, Vector3.ZERO, "Body")
	Props.capsule(_body, 0.24, 0.95, Vector3(0, 0.48, 0), Color("#3d8bff"))
	Props.sphere(_body, 0.21, Vector3(0, 1.16, 0), Color("#f2c7a5"))
	Props.cylinder(_body, 0.17, 0.32, 0.14, Vector3(0, 1.34, 0), Color("#f4d35e"), 12)
	Props.sphere(_body, 0.045, Vector3(-0.08, 1.2, -0.18), Color("#2b2f36"), 6, 4)
	Props.sphere(_body, 0.045, Vector3(0.08, 1.2, -0.18), Color("#2b2f36"), 6, 4)
	# Olta: sağ elde, kökü 0,75 m yükseklikte; -Z'ye (ileri) doğru uzanır.
	_rod_pivot = Props.pivot(_body, Vector3(0.22, 0.75, -0.1), "Rod")
	Props.cylinder(_rod_pivot, 0.012, 0.03, ROD_LENGTH, Vector3(0, 0, -ROD_LENGTH * 0.5), Color("#6e4526"), 5,
			Vector3(deg_to_rad(-90.0), 0, 0))
	Props.sphere(_rod_pivot, 0.05, Vector3(0, 0, -0.2), Color("#c9d2dc"), 8, 4)
	_tip = Props.pivot(_rod_pivot, Vector3(0, 0, -ROD_LENGTH), "Tip")


func pos2() -> Vector2:
	return Vector2(position.x, position.z)


## Anında yerleştirir (sahne açılışı).
func place(p: Vector2) -> void:
	_y = _height(p)
	position = Vector3(p.x, _y, p.y)
	_walking = false


## Düz bir çizgide yürür; önü su olursa kıyıda durur.
func walk_to(p: Vector2) -> void:
	_target = p
	_walking = true


func stop() -> void:
	if _walking:
		_walking = false
		arrived.emit()


func is_walking() -> bool:
	return _walking


## Klavyeyle bir adım (dir: dünya xz yönü, uzunluğu 0..1).
func step_dir(dir: Vector2, delta: float) -> void:
	if dir.length_squared() < 0.0001:
		return
	_walking = false
	_move(dir.normalized() * minf(dir.length(), 1.0), SPEED * delta)


func face(dir: Vector2) -> void:
	if dir.length_squared() > 0.0001:
		facing = dir.normalized()


func rod_tip() -> Vector3:
	return _tip.global_position


## Atış hareketi (geri al, ileri savur).
func play_cast() -> void:
	_cast_t = 0.0


func cheer() -> void:
	_cheer_t = 0.0


func _process(delta: float) -> void:
	if _walking:
		var to := _target - pos2()
		var d := to.length()
		if d < 0.05:
			stop()
		elif not _move(to / d, minf(SPEED * delta, d)):
			stop()
	var p := pos2()
	_y = move_toward(_y, _height(p), delta * 2.5)
	position = Vector3(p.x, _y, p.y)
	# Yüzünü dönme: facing yönüne yumuşakça.
	var want := atan2(-facing.x, -facing.y)
	rotation.y = lerp_angle(rotation.y, want, minf(1.0, delta * TURN))
	# Yürürken hafif zıplama.
	if _walking:
		_step_clock += delta * 9.0
		_body.position.y = absf(sin(_step_clock)) * 0.05
	else:
		_body.position.y = move_toward(_body.position.y, 0.0, delta)
	# Olta açısı: bekleyişte önde alçak; atışta geri-ileri; çekişmede gerilimle yukarı.
	var angle := lerpf(deg_to_rad(18.0), deg_to_rad(52.0), rod_raise)
	if _cast_t >= 0.0:
		_cast_t += delta
		if _cast_t < 0.16:
			angle = lerpf(angle, deg_to_rad(95.0), _cast_t / 0.16)
		elif _cast_t < 0.32:
			angle = lerpf(deg_to_rad(95.0), deg_to_rad(5.0), (_cast_t - 0.16) / 0.16)
		else:
			_cast_t = -1.0
	_rod_angle = lerpf(_rod_angle, angle, minf(1.0, delta * (30.0 if _cast_t >= 0.0 else 8.0)))
	_rod_pivot.rotation.x = _rod_angle
	if _cheer_t >= 0.0:
		_cheer_t += delta
		_body.position.y = absf(sin(_cheer_t * 9.0)) * 0.22 * maxf(0.0, 1.0 - _cheer_t / 1.2)
		if _cheer_t > 1.2:
			_cheer_t = -1.0


## Bir adım; yer yürünebilir değilse false.
func _move(dir: Vector2, length: float) -> bool:
	face(dir)
	var next := pos2() + dir * length
	var ahead := next + dir * BODY
	if not lake.is_walkable(next) or not lake.is_walkable(ahead):
		return false
	position.x = next.x
	position.z = next.y
	return true


func _height(p: Vector2) -> float:
	return float(height_at.call(p)) if height_at.is_valid() else 0.0
