class_name LookModifier
extends SkeletonModifier3D
## Animasyonun üstüne baş hareketi ekler: başı (biraz da göğsü) hedefe çevirir (yatayda, başı da
## yukarı ya da aşağı eğerek) ve konuşurken başı sallar. Açılar sınırlı, dönüş yumuşak.
## Yukarıdan bakan kamerada yüz, başı kameraya kaldırınca görünür. Skeleton3D'nin çocuğu olmalı;
## AnimationTree'den sonra çalışır. Model iskelet uzayında +Z'ye bakar.

## Bakılan nokta (dünya). has_target false ise baş öne döner.
var target := Vector3.ZERO
var has_target: bool = false
## En çok dönüş (radyan); göğüs bunun CHEST_SHARE kadarını üstlenir.
var limit: float = deg_to_rad(80.0)
## Baş sallama açısı (radyan, + öne eğilir). Çağıran her kare verir.
var nod: float = 0.0

const CHEST_SHARE := 0.35
## En çok yukarı ve aşağı bakış (radyan).
const PITCH_UP := 0.5
const PITCH_DOWN := 0.3
## Dönüşün yumuşaklığı (büyüdükçe hızlı).
const SMOOTH := 5.0

var _yaw: float = 0.0
var _pitch: float = 0.0
var _head: int = -2
var _chest: int = -1


func _process_modification_with_delta(delta: float) -> void:
	var skeleton := get_skeleton()
	if skeleton == null:
		return
	if _head == -2:
		_head = skeleton.find_bone("head")
		_chest = skeleton.find_bone("chest")
	if _head < 0:
		return
	var want := 0.0
	var want_pitch := 0.0
	if has_target:
		var local := skeleton.global_transform.affine_inverse() * target
		var to := local - skeleton.get_bone_global_pose(_head).origin
		var flat := Vector2(to.x, to.z).length()
		if flat > 0.05:
			want = clampf(atan2(to.x, to.z), -limit, limit)
			# + öne eğilir: yukarıdaki hedefe bakarken baş geriye kalkar.
			want_pitch = clampf(-atan2(to.y, flat), -PITCH_UP, PITCH_DOWN)
	var k := 1.0 - exp(-SMOOTH * delta)
	_yaw = lerpf(_yaw, want, k)
	_pitch = lerpf(_pitch, want_pitch, k)
	if absf(_yaw) < 0.0005 and absf(_pitch) < 0.0005 and absf(nod) < 0.0005:
		return
	if _chest >= 0:
		_turn(skeleton, _chest, _yaw * CHEST_SHARE, 0.0, 0.0)
	_turn(skeleton, _head, _yaw * (1.0 - CHEST_SHARE if _chest >= 0 else 1.0), nod + _pitch, _yaw)


## Kemiği önce iskeletin dikey ekseni çevresinde yaw kadar, sonra dönmüş başın yan ekseni
## çevresinde pitch kadar döndürür (facing_yaw: kemiğin toplam dönüşü). Eksenler üst kemiğin
## uzayına çevrilir: animasyonun duruşu ne olursa olsun doğru yöne.
static func _turn(skeleton: Skeleton3D, bone: int, yaw: float, pitch: float, facing_yaw: float) -> void:
	var parent := skeleton.get_bone_parent(bone)
	var basis := skeleton.get_bone_global_pose(parent).basis.orthonormalized() if parent >= 0 else Basis.IDENTITY
	var up := (basis.inverse() * Vector3.UP).normalized()
	var side := (basis.inverse() * Vector3.RIGHT.rotated(Vector3.UP, facing_yaw)).normalized()
	var rotation := skeleton.get_bone_pose_rotation(bone)
	skeleton.set_bone_pose_rotation(bone, Quaternion(side, pitch) * Quaternion(up, yaw) * rotation)
