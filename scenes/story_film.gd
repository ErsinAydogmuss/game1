class_name StoryFilm
extends RefCounted
## Açılış filminin çekimleri (docs/gdd.md §10.5; sözler StoryPanel'de, sırası Story.LINES): her söz
## bir çekim. Kamera bir çekimden ötekine yumuşakça kayar (hedef, yakınlık ve eğim; MOVE_TIME),
## konuşan köylü konuşur. Derin ortada Gölün Bekçisi'nin dev gölgesi geçer: yalnızca görünüş
## (ShadowLayer.make_ghost), ShadowSim'e ve oturuma dokunmaz. Logo göründüğü sırada kamera iskele
## koyunun üstünde, yüksekten bakar. Son sözde balıkçı Dede'ye döner, elinde Dede'nin ilk oltası
## belirir, Dede sevinir. main kurar (setup), her kare update() çağırır, bitince end(). Süreler
## _process(delta) toplamıyla.
##
## Bitiş filmi (Story.ENDING; begin(true)): Bekçi'nin dev gölgesi X'te sandalın çevresinde bir tur döner ve dalar
## (turkuaz halkalar), şafak söker (filmin ışığı look: gece sisinden açık sabaha; main oyunun saatini ilk
## seferde sonraki sabaha alır ve balıkçıyı iskeleye geçirir: moment "dawn"), göl çiçek açar (moment "bloom":
## main gölü sevginin en üst görünüşüne alır), iskelede Dede, Nine ve balıkçı sevinir, en son göl yüksekten.

## Çekimler arası kayma ve dev gölgenin geçişi (sn); gölgenin boyu (m) ve iz halkalarının arası.
const MOVE_TIME := 1.8
const GHOST_TIME := 7.5
const GHOST_LENGTH := 5.0
const WAKE_EVERY := 0.4
## Bitiş filminde Bekçi'nin turu (sn) ve dalışının halkaları: (gecikme sn, yarıçap m, ömür sn).
const CIRCLE_TIME := 7.5
const DIVE_RINGS: Array[Vector3] = [Vector3(0.0, 2.0, 1.4), Vector3(0.3, 3.2, 1.8), Vector3(0.7, 4.4, 2.2)]
const TURQUOISE := Color(0.7, 1.0, 0.96, 0.8)
## Yakın çekimde hedef başın bu kadar altında (m): yüz ekranın üst yarısında, alttaki söz kutusunun üstünde.
const FACE_DROP := 0.55
## Hediye çekiminde hedef iki başın ortasının bu kadar altında (m); balıkçının başının yerden yüksekliği.
const GIFT_DROP := 0.7
const ANGLER_HEAD := 1.2

## Filmin önemli anı (bitiş filmi: "dawn" şafak, "bloom" göl çiçek açar): main oyunun durumunu değiştirir.
signal moment(kind: String)

## Filmin sözleri (Story.LINES ya da Story.ENDING) ve ışığı (boşsa oyunun kendi görünüşü; bitiş filminde
## gece sisi, şafaktan sonra açık sabah: DayLook.of).
var lines: Array[Array] = Story.LINES
var look: Dictionary = {}
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
var _ghost_time: float = GHOST_TIME
## Bitiş filminde gölge yolunun sonunda dalar (halkalar, ses).
var _ghost_dives: bool = false
var _wake: float = 0.0
## Bekleyen halkalar: [kalan sn, nokta (Vector2), yarıçap, ömür].
var _rings: Array = []


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


## Film başlıyor: açılışta balıkçının oltası hediyeye kadar elinde değil, kamera logonun çekiminde; bitiş
## filminde (ending) kamera Bekçi'nin turunda, ışık gece sisi.
func begin(ending: bool = false) -> void:
	if ending:
		lines = Story.ENDING
		look = DayLook.of("night", "fog")
		_to = _shot_of("circle")
	else:
		angler.rod_hidden = true
		_to = _shot_of("opening")
	_from = _to
	_move = 1.0
	_apply(_to)
	camera.snap(camera.target)


## Sıradaki sözün çekimi (lines): kamera oraya kayar, konuşan konuşur.
func shot(index: int) -> void:
	if index < 0 or index >= lines.size():
		return
	var line: Array = lines[index]
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
		"circle":
			_start_circle()
			elder.say()
			Sounds.play("sting")
			Sounds.haptic(40)
		"dawn":
			look = DayLook.of("morning", "clear")
			nine.say()
			moment.emit("dawn")
		"bloom":
			nine.say()
			moment.emit("bloom")
			Sounds.play("love_up")
			Sounds.haptic(30)
		"cheer":
			elder.cheer()
			nine.cheer()
			angler.cheer()
			Sounds.play("record")
			Sounds.haptic(40)
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
	_step_rings(delta)


## Film bitti (ya da yarıda kesildi): olta elde, balıkçı suya döner, dev gölge silinir. Kamerayı
## main geri alır.
func end() -> void:
	angler.rod_hidden = false
	angler.face(Vector2(0.0, -1.0))
	if _ghost != null:
		_ghost.queue_free()
		_ghost = null
	_ghost_age = -1.0


## Bitiş filmi atlandı (jenerik başlıyor): kamera son çekime kayar, ışık sabahın, dev gölge kalkar.
func skip_ending() -> void:
	look = DayLook.of("morning", "clear")
	_from = [camera.target, camera.zoom, camera.pitch]
	_to = _shot_of(str(lines[lines.size() - 1][2]))
	_move = 0.0
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
		"circle":
			return [_ground(_x_point()), 1.35, deg_to_rad(54.0)]
		"dawn":
			# Şafak: göl yüksekten ve yatık (gökyüzü de görünsün), derin ortanın üstünde.
			return [_ground(_deep_center()), 2.1, deg_to_rad(34.0)]
		"bloom":
			# Göl çiçek açar: iskele koyunun nilüfer ve çiçekleri.
			return [_ground(_lake_point() + Vector2(2.0, 1.0)), 1.15, deg_to_rad(46.0)]
		"cheer":
			# İskelede Dede ve Nine (balıkçı da yanlarında): iki başın ortası, söz kutusunun üstünde.
			var both := (elder.head_point() + nine.head_point()) * 0.5
			return [both + Vector3(0.0, -GIFT_DROP, 0.0), 0.75, deg_to_rad(30.0)]
		"wide":
			return [_ground(_lake_point() + Vector2(0.0, -7.0)), 2.4, deg_to_rad(50.0)]
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


## Haritanın X'i: sandalın derin ortanın ilk şamandırasına bağlandığı yer (LakeScene.moor_boat gibi).
func _x_point() -> Vector2:
	var x := Secret.keeper_x(db, spot_id)
	return x + LakeScene.BUOY_MOOR if Dice.is_point(x) else _deep_center()


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
	_begin_ghost(Story.keeper_path(db, spot_id, _across()), GHOST_TIME, false)


## Bitiş filmi: Bekçi X'te sandalın çevresinde bir tur döner, sonunda dalar.
func _start_circle() -> void:
	_begin_ghost(Story.keeper_circle(db, spot_id, _x_point()), CIRCLE_TIME, true)


func _begin_ghost(path: PackedVector2Array, seconds: float, dives: bool) -> void:
	_ghost_path = path
	if _ghost_path.size() < 2 or shadows == null:
		return
	if _ghost == null:
		_ghost = shadows.make_ghost(GHOST_LENGTH)
	_ghost_age = 0.0
	_ghost_time = seconds
	_ghost_dives = dives
	_wake = 0.0


## Dev gölge yolunda yüzer: belirip söner, arkasında turkuaz iz halkaları.
func _step_ghost(delta: float) -> void:
	if _ghost == null or _ghost_age < 0.0:
		return
	_ghost_age += delta
	var t := _ghost_age / _ghost_time
	if t >= 1.0:
		if _ghost_dives:
			# Bekçi dalar: sondaki yerinde turkuaz halkalar, dalış sesi, titreşim.
			var at := _ghost_path[_ghost_path.size() - 1]
			for r in DIVE_RINGS:
				_rings.append([r.x, at, r.y, r.z])
			Sounds.play("dive")
			Sounds.haptic(80)
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


func _step_rings(delta: float) -> void:
	for i in range(_rings.size() - 1, -1, -1):
		var ring: Array = _rings[i]
		ring[0] = float(ring[0]) - delta
		if float(ring[0]) <= 0.0:
			if ripples != null:
				ripples.spawn(ring[1], float(ring[2]), float(ring[3]), TURQUOISE, 0.14)
			_rings.remove_at(i)
