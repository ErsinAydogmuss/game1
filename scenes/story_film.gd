class_name StoryFilm
extends RefCounted
## Açılış filminin çekimleri (docs/gdd.md §10.5; sözler StoryPanel'de, sırası Story.LINES): her söz
## bir çekim. Kamera bir çekimden ötekine yumuşakça kayar (hedef, yakınlık ve eğim; MOVE_TIME),
## konuşan köylü konuşur. Derin ortada Gölün Bekçisi'nin dev gölgesi geçer: yalnızca görünüş
## (ShadowLayer.make_ghost), ShadowSim'e ve oturuma dokunmaz. Logo göründüğü sırada kamera iskele
## koyunun üstünde, yüksekten bakar. Son sözde balıkçı Dede'ye döner, elinde Dede'nin ilk oltası
## belirir, Dede sevinir. main kurar (setup), her kare update() çağırır, bitince end(). Süreler
## _process(delta) toplamıyla.

## Çekimler arası kayma ve dev gölgenin geçişi (sn); gölgenin boyu (m) ve iz halkalarının arası.
const MOVE_TIME := 1.8
const GHOST_TIME := 7.5
const GHOST_LENGTH := 5.0
const WAKE_EVERY := 0.4
## Yakın çekimde hedef başın bu kadar altında (m): yüz ekranın üst yarısında, alttaki söz kutusunun üstünde.
const FACE_DROP := 0.55
## Hediye çekiminde hedef iki başın ortasının bu kadar altında (m); balıkçının başının yerden yüksekliği.
const GIFT_DROP := 0.7
const ANGLER_HEAD := 1.2

var camera: FollowCamera
var angler: Angler
var elder: Elder
var nine: Nine
var shadows: ShadowLayer
var ripples: Ripples
var db: ContentDB
var spot_id: String

## Kameranın çıkış ve varış değerleri: [hedef, yakınlık, eğim]; kaymanın ilerlemesi (0..1).
var _from: Array = []
var _to: Array = []
var _move: float = 1.0
var _ghost: MeshInstance3D
var _ghost_path := PackedVector2Array()
var _ghost_age: float = -1.0
var _wake: float = 0.0


func setup(view: FollowCamera, fisher: Angler, dede: Elder, nana: Nine, layer: ShadowLayer, rings: Ripples,
		content: ContentDB, spot: String) -> void:
	camera = view
	angler = fisher
	elder = dede
	nine = nana
	shadows = layer
	ripples = rings
	db = content
	spot_id = spot


## Film başlıyor: balıkçının oltası hediyeye kadar elinde değil; kamera logonun çekiminde.
func begin() -> void:
	angler.rod_hidden = true
	_to = _shot_of("opening")
	_from = _to
	_move = 1.0
	_apply(_to)
	camera.snap(camera.target)


## Sıradaki sözün çekimi (Story.LINES): kamera oraya kayar, konuşan konuşur.
func shot(index: int) -> void:
	if index < 0 or index >= Story.LINES.size():
		return
	var line: Array = Story.LINES[index]
	var kind := str(line[2])
	_from = [camera.target, camera.zoom, camera.pitch]
	_to = _shot_of(kind)
	_move = 0.0
	match kind:
		"nine":
			nine.greet()
		"keeper":
			_start_ghost()
			elder.approve()
			Sounds.play("sting")
			Sounds.haptic(40)
		"gift":
			angler.rod_hidden = false
			angler.face(Vector2(elder.global_position.x, elder.global_position.z) - angler.pos2())
			elder.cheer()
			Sounds.play("equip")
			Sounds.haptic(30)
		_:
			if str(line[1]) == "nine":
				nine.say()
			else:
				elder.say()


func update(delta: float) -> void:
	if _move < 1.0:
		_move = minf(1.0, _move + delta / MOVE_TIME)
		var t := smoothstep(0.0, 1.0, _move)
		_apply([(_from[0] as Vector3).lerp(_to[0], t), lerpf(_from[1], _to[1], t), lerp_angle(_from[2], _to[2], t)])
	_step_ghost(delta)


## Film bitti (ya da yarıda kesildi): olta elde, balıkçı suya döner, dev gölge silinir. Kamerayı
## main geri alır.
func end() -> void:
	angler.rod_hidden = false
	angler.face(Vector2(0.0, -1.0))
	if _ghost != null:
		_ghost.queue_free()
		_ghost = null
	_ghost_age = -1.0


## Dev gölge şu an görünüyor mu (bot denetler)?
func ghost_point() -> Vector3:
	return _ghost.global_position if _ghost != null and _ghost.is_inside_tree() else Vector3.INF


func _apply(values: Array) -> void:
	camera.target = values[0]
	camera.zoom = values[1]
	camera.pitch = values[2]


## Bir çekimin kamerası: [hedef, yakınlık, eğim].
func _shot_of(kind: String) -> Array:
	match kind:
		"opening":
			return [_ground(_lake_point() + Vector2(0.0, -2.0)), 1.9, deg_to_rad(58.0)]
		"nine":
			return [nine.head_point() + Vector3(0.0, -FACE_DROP, 0.0), 0.38, deg_to_rad(28.0)]
		"dede":
			return [elder.head_point() + Vector3(0.0, -FACE_DROP, 0.0), 0.34, deg_to_rad(26.0)]
		"lake":
			return [_ground(_lake_point()), 1.7, deg_to_rad(36.0)]
		"reeds":
			return [_ground(_zone_point("reeds", Vector2(0.0, -3.0))), 1.25, deg_to_rad(44.0)]
		"deep", "keeper":
			return [_ground(_deep_center()), 1.45 if kind == "keeper" else 1.7, deg_to_rad(52.0)]
		"gift":
			# Dede kameraya balıkçıdan yakın (ekranda onun altında): iki başın ortası biraz yukarıda,
			# ikisinin yüzü de söz kutusunun üstünde kalsın; hediye rozeti sağda (StoryPanel).
			var mid := (angler.global_position + Vector3(0.0, ANGLER_HEAD, 0.0) + elder.head_point()) * 0.5
			return [mid + Vector3(0.0, -GIFT_DROP, 0.0), 0.52, deg_to_rad(30.0)]
	return [angler.global_position + Vector3(0.0, 0.6, 0.0), 0.95, FollowCamera.PITCH]


func _ground(p: Vector2) -> Vector3:
	return Vector3(p.x, 0.0, p.y)


## Göl çekimi: başlangıç yerinin önündeki su (iskele koyunun ortası).
func _lake_point() -> Vector2:
	var start: Vector2 = db.spot(spot_id).get("start", Vector2.ZERO)
	return start + Vector2(0.0, -5.0)


## Bir bölgenin atış noktasından offset kadar ötesi (bölge yoksa göl çekimi).
func _zone_point(zone_id: String, offset: Vector2) -> Vector2:
	var z := db.zone(spot_id, zone_id)
	if z.is_empty() or (z["stands"] as Array).is_empty():
		return _lake_point()
	return (z["stands"] as Array)[0] + offset


## Derin ortanın ortası: dev gölgenin yolunun ortası (Story.keeper_path).
func _deep_center() -> Vector2:
	var path := Story.keeper_path(db, spot_id, _across())
	if path.is_empty():
		return _lake_point()
	return path[path.size() >> 1]


## Ekranın sağı (dünya xz): dev gölge ekranı soldan sağa geçer.
func _across() -> Vector2:
	return Vector2(cos(FollowCamera.YAW), -sin(FollowCamera.YAW))


func _start_ghost() -> void:
	_ghost_path = Story.keeper_path(db, spot_id, _across())
	if _ghost_path.size() < 2 or shadows == null:
		return
	if _ghost == null:
		_ghost = shadows.make_ghost(GHOST_LENGTH)
	_ghost_age = 0.0
	_wake = 0.0


## Dev gölge yolunda yüzer: belirip söner, arkasında turkuaz iz halkaları.
func _step_ghost(delta: float) -> void:
	if _ghost == null or _ghost_age < 0.0:
		return
	_ghost_age += delta
	var t := _ghost_age / GHOST_TIME
	if t >= 1.0:
		_ghost.queue_free()
		_ghost = null
		_ghost_age = -1.0
		return
	var f := t * float(_ghost_path.size() - 1)
	var i := mini(int(f), _ghost_path.size() - 2)
	var p := _ghost_path[i].lerp(_ghost_path[i + 1], f - float(i))
	var heading := (_ghost_path[i + 1] - _ghost_path[i]).normalized()
	var wiggle := sin(_ghost_age * 2.2) * 0.06
	_ghost.position = Vector3(p.x, ShadowLayer.Y, p.y)
	_ghost.rotation = Vector3(0.0, atan2(-heading.x, -heading.y) + wiggle, 0.0)
	var fade := smoothstep(0.0, 0.18, t) * (1.0 - smoothstep(0.8, 1.0, t))
	(_ghost.material_override as ShaderMaterial).set_shader_parameter("fade", fade)
	_wake -= delta
	if ripples != null and fade > 0.5 and _wake <= 0.0:
		_wake = WAKE_EVERY
		ripples.spawn(p - heading * GHOST_LENGTH * 0.5, GHOST_LENGTH * 0.4, 1.5, Color(0.7, 1.0, 0.96, 0.6), 0.1)
