class_name FollowCamera
extends Camera3D
## Hedefi sabit bir eğik açıdan ("diorama") yumuşakça izleyen kamera (Kazı'dan).
## Açı dönmez; yürüme yönleri bu açıya göre hesaplanır. Atışta eğim değiştirilebilir (pitch).

const YAW := deg_to_rad(32.0)
const PITCH := deg_to_rad(50.0)
const SURFACE_DISTANCE := 12.0
## Görüş açısı (dikey, derece) ve kesme uzaklıkları (çizim sayısı testi de bunları kullanır).
const FOV := 40.0
const NEAR := 0.3
const FAR := 220.0

var target := Vector3.ZERO
var distance: float = SURFACE_DISTANCE
## Uzaklık çarpanı (1 = normal). Geliştirici aracı yakın çekim için küçültür.
var zoom: float = 1.0
## Bakış eğimi (radyan); oyunda sabit, yakın çekimde değiştirilebilir.
var pitch: float = PITCH

var _focus := Vector3.ZERO
var _shake: float = 0.0


func _init() -> void:
	fov = FOV
	near = NEAR
	far = FAR


## Zeminde odaktan ekranın iki yatay çizgisine uzaklık (m; zoom 1'de, verilen eğimle; ekranın dikey
## ekseni boyunca, screen_up): x odaktan aşağıdaki low çizgisine, y yukarıdaki high çizgisine.
## Çizgiler ekran payıyla: -1 alt kenar, 0 orta, 1 üst kenar (perspektife uygun). Uzaklık zoom'la
## doğru orantılı büyür.
static func ground_extents(view_pitch: float, low: float = -1.0, high: float = 1.0) -> Vector2:
	var spread := tan(deg_to_rad(FOV * 0.5))
	var near_ray := view_pitch - atan(low * spread)
	var far_ray := view_pitch - atan(high * spread)
	var down := SURFACE_DISTANCE * (cos(view_pitch) - sin(view_pitch) / tan(near_ray))
	var up := SURFACE_DISTANCE * (sin(view_pitch) / tan(far_ray) - cos(view_pitch))
	return Vector2(down, up)


## Ekranın yukarısı zeminde (xz): kameradan uzağa.
static func screen_up() -> Vector2:
	return Vector2(-sin(YAW), -cos(YAW))


## Uzaktaki bir hedefi (balıkçının ahead m önünde, ekranın dikey ekseninde) balıkçıyla birlikte
## gösteren çerçeve: odağın balıkçıdan uzaklığı (x, m) ve zoom (y). Odak yolun share'inde; hedef
## sığmıyorsa kamera max_zoom'a kadar uzaklaşır. Balıkçının ayağı ekranın low çizgisinin, hedef
## high çizgisinin içinde kalır (ground_extents); ikisi birden sığmazsa balıkçı görünür kalır.
static func fit(ahead: float, view_pitch: float, share: float, base_zoom: float, max_zoom: float,
		low: float, high: float) -> Vector2:
	var ext := ground_extents(view_pitch, low, high)
	var zoom := clampf(ahead / (ext.x + ext.y), base_zoom, max_zoom)
	var offset := maxf(ahead * share, ahead - ext.y * zoom)
	return Vector2(clampf(offset, 0.0, ext.x * zoom), zoom)


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
