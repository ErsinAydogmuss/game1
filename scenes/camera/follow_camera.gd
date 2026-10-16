class_name FollowCamera
extends Camera3D
## Hedefi sabit bir eğik açıdan ("diorama") yumuşakça izleyen kamera (Kazı'dan).
## Açı dönmez; yürüme yönleri bu açıya göre hesaplanır. Atışta eğim değiştirilebilir (pitch).

const YAW := deg_to_rad(32.0)
const PITCH := deg_to_rad(50.0)
const SURFACE_DISTANCE := 12.0

var target := Vector3.ZERO
var distance: float = SURFACE_DISTANCE
## Uzaklık çarpanı (1 = normal). Geliştirici aracı yakın çekim için küçültür.
var zoom: float = 1.0
## Bakış eğimi (radyan); oyunda sabit, yakın çekimde değiştirilebilir.
var pitch: float = PITCH

var _focus := Vector3.ZERO
var _shake: float = 0.0


func _init() -> void:
	fov = 40.0
	near = 0.3
	far = 220.0


## Hedefe anında geç (sahne açılışında).
func snap(point: Vector3) -> void:
	target = point
	_focus = point
	_place(Vector3.ZERO)


## Sarsıntı ekle (metre cinsinden genlik, kendiliğinden söner).
func shake(amount: float) -> void:
	_shake = minf(_shake + amount, 0.35)


func _process(delta: float) -> void:
	var horizontal := 1.0 - exp(-7.0 * delta)
	var vertical := 1.0 - exp(-9.0 * delta)
	_focus.x = lerpf(_focus.x, target.x, horizontal)
	_focus.z = lerpf(_focus.z, target.z, horizontal)
	_focus.y = lerpf(_focus.y, target.y, vertical)
	# Hedef çok uzağa sıçrarsa kamera geride kalmasın.
	if absf(_focus.y - target.y) > 6.0:
		_focus.y = target.y + signf(_focus.y - target.y) * 6.0
	var offset := Vector3.ZERO
	if _shake > 0.001:
		offset = Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)) * _shake
		_shake = move_toward(_shake, 0.0, delta * 1.6)
	_place(offset)


func _place(offset: Vector3) -> void:
	var back := Vector3(sin(YAW) * cos(pitch), sin(pitch), cos(YAW) * cos(pitch))
	position = _focus + back * distance * zoom + offset
	rotation = Vector3(-pitch, YAW, 0.0)
