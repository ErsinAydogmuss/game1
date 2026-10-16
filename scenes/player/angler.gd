class_name Angler
extends Node3D
## Balıkçı: göl düzleminde 2B yürür; karada ve iskelede durabilir, suya giremez (kıyıda durur).
## Görünüm AnglerBody (KayKit Rogue) ya da yedek ToyAngler; olta (RodModel) elin yuvasında.
## Sunum her kare pose / tension verir (free, hold, reel); atış, gösterme ve sevinç tek seferlik.
## Kare başı hareket _process'te (Tween yok).

## Yürüme bitti (hedefe vardı ya da kıyıda durdu).
signal arrived

const SPEED := 2.4
const TURN := 10.0
## Kıyıda bu kadar geride durur (gövde suya taşmasın).
const BODY := 0.22
## Serbestken olta gövdeye göre dik taşınır (elin sarkan açısı oltayı suya batırmasın):
## oltanın ucu gövdenin önüne ve yukarısına.
const CARRY_DIR := Vector3(0.12, 0.9, -0.42)
## Balığı gösterirken olta gizlenir (sn).
const SHOW_TIME := 1.6

## true ise KayKit modeli olsa bile kodla kurulan model kullanılır (testler, karşılaştırma).
static var force_toy: bool = false

var lake: LakeShape
## Durulan yerin yüksekliği (LakeScene.stand_height).
var height_at: Callable
## Girilemeyen daireler (iskelede oturan Dede): Vector3(x, z, yarıçap). Balıkçı çevresinden kayar.
var blockers: Array[Vector3] = []
var facing := Vector2(0.0, -1.0)
## Duruş: free (serbest), hold (olta suda), reel (çekişme).
var pose: String = "free"
## Çekişmede gerilim (0..1+): olta bükülür, balıkçı geriye yaslanır.
var tension: float = 0.0
var rod: RodModel

var _body: Node3D
var _target := Vector2.ZERO
var _walking: bool = false
## 1 = olta dik taşınıyor, 0 = elde (atış, bekleme, çekme).
var _carry: float = 1.0
var _cast_time: float = -1.0
var _show_time: float = -1.0
var _speed: float = 0.0
var _y: float = 0.0


func _ready() -> void:
	if AnglerBody.available() and not force_toy:
		_body = AnglerBody.new()
	else:
		_body = ToyAngler.new()
	_body.name = "Body"
	add_child(_body)
	rod = RodModel.new()
	rod.name = "Rod"
	(_body.get("rod_mount") as Node3D).add_child(rod)


func pos2() -> Vector2:
	return Vector2(position.x, position.z)


## KayKit modeli mi kullanılıyor?
func is_rigged() -> bool:
	return _body is AnglerBody


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
	if _move(dir.normalized() * minf(dir.length(), 1.0), SPEED * delta):
		_speed = SPEED


func face(dir: Vector2) -> void:
	if dir.length_squared() > 0.0001:
		facing = dir.normalized()


func rod_tip() -> Vector3:
	return rod.tip.global_position


## Elin dünyadaki yeri (yakalanan balık burada tutulur).
func hand_point() -> Vector3:
	return _body.call("hand_point")


func play_cast() -> void:
	_cast_time = 0.0
	_carry = 0.0
	_body.call("play_cast")


## Balığı havaya kaldırıp gösterir (olta kısa süre gizlenir).
func show_fish() -> void:
	_show_time = 0.0
	_body.call("show_fish")


func cheer() -> void:
	_show_time = 0.0
	_body.call("cheer")


func _process(delta: float) -> void:
	var moved := false
	if _walking:
		var to := _target - pos2()
		var d := to.length()
		if d < 0.05:
			stop()
		elif _move(to / d, minf(SPEED * delta, d)):
			moved = true
		else:
			stop()
	_speed = move_toward(_speed, SPEED if moved else 0.0, delta * (30.0 if moved else 8.0))
	var p := pos2()
	_y = move_toward(_y, _height(p), delta * 2.5)
	position = Vector3(p.x, _y, p.y)
	var want := atan2(-facing.x, -facing.y)
	rotation.y = lerp_angle(rotation.y, want, minf(1.0, delta * TURN))
	rod.bend = clampf(tension, 0.0, 1.2) if pose == "reel" else 0.0
	_body.call("animate", delta, _speed, pose, tension)
	_update_rod(delta)


## Oltanın duruşu: serbestken gövdeye göre dik (yumuşak geçişle), atışta ve olta sudayken elde.
func _update_rod(delta: float) -> void:
	if _cast_time >= 0.0:
		_cast_time += delta
		if _cast_time > 0.6:
			_cast_time = -1.0
	if _show_time >= 0.0:
		_show_time += delta
		if _show_time > SHOW_TIME:
			_show_time = -1.0
	rod.visible = _show_time < 0.0
	var free := pose == "free" and _cast_time < 0.0
	_carry = move_toward(_carry, 1.0 if free else 0.0, delta * 4.0)
	if _carry <= 0.0:
		rod.transform = Transform3D.IDENTITY
		return
	var mount := (rod.get_parent() as Node3D).global_basis.orthonormalized()
	var carry := (global_basis * Basis.looking_at(CARRY_DIR.normalized(), Vector3.UP)).orthonormalized()
	var t := smoothstep(0.0, 1.0, _carry)
	rod.global_basis = Basis(mount.get_rotation_quaternion().slerp(carry.get_rotation_quaternion(), t))


## Bir adım; yer yürünebilir değilse ya da engel tam karşıdaysa false.
func _move(dir: Vector2, length: float) -> bool:
	face(dir)
	var step := avoid(blockers, pos2(), dir * length)
	if step == Vector2.ZERO:
		return false
	face(step)
	var next := pos2() + step
	var ahead := next + step.normalized() * BODY
	if not lake.is_walkable(next) or not lake.is_walkable(ahead):
		return false
	position.x = next.x
	position.z = next.y
	return true


## Engelden kaçınma: from'dan step kadarlık adım bir engelin içine (gövde payıyla) giriyorsa
## adımın engele doğru bileşeni atılır; balıkçı engelin çevresinden kayar (Dede'nin yanından
## geçip karaya yürür). Neredeyse tam karşıdan geliyorsa Vector2.ZERO (durur). Engelden
## uzaklaşan adım hep serbest: balıkçı bir engelin içinde kalırsa takılmaz.
static func avoid(list: Array[Vector3], from: Vector2, step: Vector2) -> Vector2:
	var out := step
	for b in list:
		var center := Vector2(b.x, b.y)
		var d := (from + out).distance_to(center)
		if d >= b.z + BODY or d >= from.distance_to(center):
			continue
		var normal := (from - center).normalized()
		out -= normal * out.dot(normal)
		if out.length() < step.length() * 0.2:
			return Vector2.ZERO
	return out


func _height(p: Vector2) -> float:
	return float(height_at.call(p)) if height_at.is_valid() else 0.0
