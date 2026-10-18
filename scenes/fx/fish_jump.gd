class_name FishJump
extends Node3D
## Çekişmede sudan sıçrayan balık (Dalga 3; fish.json fight.jumps: alabalıklar): balığın modeli
## (FishMesh, gösterideki boyunda) çırpınma başlayınca çekişme noktasından yay çizerek sudan çıkar,
## havada kıvrılır ve suya geri dalar. Çıkışta ve dalışta halka ve şapırtı main'den (left / landed
## sinyalleri). Bir anda tek sıçrayış. Kare başı hareket _process'te, süre delta toplamıyla.

signal left(at: Vector2)
signal landed(at: Vector2)

## Sıçrayışın süresi (sn) ve yüksekliği (m; balığın boyunun yarısı da eklenir). Balık elde
## gösterilen boyunun SCALE katı: yukarıdan bakan kamerada seçilsin (gölgeler de iri çizilir).
const TIME := 0.62
const HEIGHT := 0.8
const SCALE := 1.5

var _fish: FishMesh
var _from := Vector3.ZERO
var _to := Vector3.ZERO
var _height: float = HEIGHT
var _age: float = -1.0


## Sıçrayışta balığın yatayda aldığı yol (m; boyunun 1,4 katı): main dalışın suya düştüğünü denetler.
static func reach_for(size_cm: int) -> float:
	return FishMesh.display_length(size_cm) * SCALE * 1.4


## Balık at noktasından (xz) heading yönüne doğru sıçrar; heading sıfırsa yerinde (aynı yere dalar).
## def: türün tanımı; size_cm: boyu. Sıçrayış başladıysa true (bir anda tek sıçrayış).
func jump(def: Dictionary, size_cm: int, at: Vector2, heading: Vector2) -> bool:
	if _age >= 0.0:
		return false
	clear()
	var length := FishMesh.display_length(size_cm) * SCALE
	_fish = FishMesh.make(def, length)
	_fish.set_wiggle(0.3, 16.0)
	_fish.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(_fish)
	var still := heading.length_squared() <= 0.0001
	var dir := Vector2(0, -1) if still else heading.normalized()
	var reach := 0.0 if still else reach_for(size_cm)
	_from = Vector3(at.x, -0.1, at.y)
	_to = Vector3(at.x + dir.x * reach, -0.1, at.y + dir.y * reach)
	_height = HEIGHT + length * 0.5
	# Model yerel +X'e bakar: yön dönüşü Y'de, burnun açısı Z'de (_place).
	_fish.rotation = Vector3(0.0, atan2(-dir.y, dir.x), 0.0)
	_age = 0.0
	_place()
	left.emit(at)
	return true


func is_jumping() -> bool:
	return _age >= 0.0


func clear() -> void:
	if _fish != null:
		_fish.queue_free()
		_fish = null
	_age = -1.0


func _process(delta: float) -> void:
	if _age < 0.0:
		return
	_age += delta
	if _age >= TIME:
		var end := Vector2(_to.x, _to.z)
		clear()
		landed.emit(end)
		return
	_place()


func _place() -> void:
	var t := clampf(_age / TIME, 0.0, 1.0)
	_fish.position = _from.lerp(_to, t) + Vector3.UP * _height * 4.0 * t * (1.0 - t)
	# Burnu önce yukarı, tepede yatay, sonra aşağı (yayın teğeti).
	var climb := _height * 4.0 * (1.0 - 2.0 * t)
	var run := maxf(0.05, _from.distance_to(_to))
	_fish.rotation.z = atan2(climb, run)
