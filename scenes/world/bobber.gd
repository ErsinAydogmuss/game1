class_name Bobber
extends Node3D
## Suyun üstündeki takım: şamandıra, yapay yem (spin), kurşun (dip) ya da sinek (set_kind).
## - Şamandıra: kırmızı-beyaz top (0,3 m; telefonda okunsun diye iri). Atışta yay çizerek uçar,
##   suda hafifçe sallanır, dürtmede boyunun %40'ı kadar dalıp çıkar, ısırmada suya gömülür,
##   çekişmede balığın peşinden sürüklenir, geri sarılınca oltanın ucuna döner.
## - Yapay yem: gümüş kaşık. Su opak olduğu için yüzeyde parlak bir kıymık gibi görünür; çekilirken
##   (drag_to) titreşir ve parlar, durunca (sink) batar: yalnızca soluk izi kalır.
## - Kurşun (dip): uçarken ve geri sarılırken küçük koyu bir ağırlık; suda dipte durur, görünmez:
##   misina suya girdiği yerde biter (line_point).
## - Sinek: kahve gövdeli, sarı kanatlı küçük kuru sinek (telefonda seçilsin diye iri); suyun yüzünde
##   hafifçe sallanarak akıntıyla sürüklenir (drag_to), halkada suya çekilir (go_under).
## Kare başı konum _process'te hesaplanır (Tween yok).

enum Look { HIDDEN, FLYING, FLOATING, UNDER, FIGHT, RETURNING }

const RADIUS := 0.15
## Dürtmede dalış derinliği: boyun %40'ı.
const DIP := 0.4 * RADIUS * 2.0
## Yemin boyu (m): gerçeğinden iri, telefonda görünsün.
const LURE_LENGTH := 0.24
## Yem batınca inme (m; su opak: üstü suyun hemen altında kalır).
const LURE_SINK := 0.045
## Sineğin boyu (m; gerçeğinden çok iri).
const FLY_LENGTH := 0.12

var look: Look = Look.HIDDEN
## Çekişmede balığın yeri (FIGHT).
var fight_point := Vector3.ZERO
## "float" (şamandıra) ya da "lure" (yapay yem).
var kind: String = "float"
## Yapay yemin batışı (0 = yüzeyde oynuyor, 1 = durdu, battı; main verir).
var sink: float = 0.0

var _from := Vector3.ZERO
var _to := Vector3.ZERO
var _arc: float = 1.0
var _t: float = 0.0
var _duration: float = 0.5
var _dip: float = 0.0
var _clock: float = 0.0
var _rest := Vector3.ZERO
var _float_part: Node3D
var _lure_part: Node3D
var _sinker_part: Node3D
var _fly_part: Node3D
var _glint: MeshInstance3D
var _heading: float = 0.0


func _ready() -> void:
	_float_part = Node3D.new()
	_float_part.name = "Float"
	add_child(_float_part)
	Props.sphere(_float_part, RADIUS, Vector3.ZERO, Color("#e63946"), 14, 7)
	Props.sphere(_float_part, RADIUS * 0.8, Vector3(0, RADIUS * 0.55, 0), Color("#fbfbf6"), 14, 7)
	Props.cylinder(_float_part, 0.018, 0.018, 0.16, Vector3(0, RADIUS * 1.35 + 0.06, 0), Color("#e63946"), 6)
	# Üç parça tek ağ (tek çizim).
	MeshBatch.merge(_float_part)
	_lure_part = Node3D.new()
	_lure_part.name = "Lure"
	add_child(_lure_part)
	# Kaşık: basık gümüş damla, ucunda kırmızı boncuk ve iğne (tek ağ).
	Props.sphere(_lure_part, LURE_LENGTH * 0.5, Vector3.ZERO, Color("#dfe6ee"), 12, 6, Vector3(0.42, 0.22, 1.0))
	Props.sphere(_lure_part, 0.024, Vector3(0, 0.01, -LURE_LENGTH * 0.52), Color("#e63946"), 8, 4)
	Props.cylinder(_lure_part, 0.008, 0.008, 0.07, Vector3(0, 0.0, LURE_LENGTH * 0.55), Color("#8a939e"), 5,
			Vector3(deg_to_rad(90.0), 0, 0))
	MeshBatch.merge(_lure_part)
	# Kurşun: koyu gri damla ve bağlandığı halka (tek ağ).
	_sinker_part = Node3D.new()
	_sinker_part.name = "Sinker"
	add_child(_sinker_part)
	Props.sphere(_sinker_part, 0.05, Vector3.ZERO, Color("#5d646c"), 10, 5, Vector3(0.8, 1.15, 0.8))
	Props.cylinder(_sinker_part, 0.012, 0.012, 0.03, Vector3(0, 0.07, 0), Color("#9aa3ad"), 5)
	MeshBatch.merge(_sinker_part)
	# Sinek: koyu gövde, açık sarı kanat (dik tüy), kırmızı kuyruk teli (tek ağ).
	_fly_part = Node3D.new()
	_fly_part.name = "Fly"
	add_child(_fly_part)
	Props.sphere(_fly_part, FLY_LENGTH * 0.5, Vector3.ZERO, Color("#6b4423"), 10, 5, Vector3(0.32, 0.3, 1.0))
	Props.sphere(_fly_part, FLY_LENGTH * 0.34, Vector3(0, FLY_LENGTH * 0.28, -FLY_LENGTH * 0.12), Color("#ffe066"), 10,
			5, Vector3(0.9, 0.9, 0.35))
	Props.cylinder(_fly_part, 0.006, 0.004, FLY_LENGTH * 0.7, Vector3(0, 0.0, FLY_LENGTH * 0.75), Color("#e63946"), 4,
			Vector3(deg_to_rad(90.0), 0, 0))
	MeshBatch.merge(_fly_part)
	_glint = Props.sphere(self, 0.05, Vector3(0, 0.05, 0), Color("#ffffff"), 8, 4)
	_glint.material_override = Props.material(Color("#ffffff"), 0.2, 2.5)
	_glint.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	for part: Node3D in [_lure_part, _sinker_part, _fly_part]:
		for mesh in part.find_children("*", "GeometryInstance3D", true, false):
			(mesh as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	set_kind("float")
	visible = false


## Tekniğin suya attığı takımın görünüşü (spin: yapay yem, dip: kurşun; ötekiler şamandıra).
static func kind_for(technique: String) -> String:
	match technique:
		"spin":
			return "lure"
		"bottom":
			return "sinker"
		"fly":
			return "fly"
	return "float"


## Misinanın bağlandığı yer: şamandıranın tepesi, yemin ve sineğin burnu ya da (dipte) suya girdiği yer.
func line_point() -> Vector3:
	if kind == "lure" or kind == "sinker" or kind == "fly":
		return global_position + Vector3(0, 0.01, 0)
	return global_position + Vector3(0, RADIUS * 1.4, 0)


## Takımın görünüşü: "float" (şamandıra), "lure" (yapay yem), "sinker" (dipte kurşun: yalnızca
## havadayken görünür) ya da "fly" (sinek).
func set_kind(value: String) -> void:
	kind = value
	_float_part.visible = kind == "float"
	_lure_part.visible = kind == "lure"
	_fly_part.visible = kind == "fly"
	_sinker_part.visible = false
	_glint.visible = false
	sink = 0.0
	rotation = Vector3.ZERO


## Oltanın ucundan hedefe yay çizerek uçar (seconds sn; arc_height m).
func fly(from: Vector3, to: Vector3, seconds: float, arc_height: float) -> void:
	_from = from
	_to = to
	_arc = arc_height
	_t = 0.0
	_duration = maxf(seconds, 0.05)
	look = Look.FLYING
	position = from
	visible = true
	_heading = atan2(to.x - from.x, to.z - from.z)


## Suya düştü (oturumun land olayıyla): uçuş nerede olursa olsun hedefe oturur.
func land(at: Vector3) -> void:
	_rest = at
	look = Look.FLOATING
	position = at
	visible = true
	sink = 0.0


## Yapay yem çekiliyor: yüzeydeki yeri (oturumun takımı; her kare).
func drag_to(at: Vector3) -> void:
	var move := at - _rest
	if move.length_squared() > 0.000001:
		_heading = atan2(move.x, move.z)
	_rest = at


## Dürtme: kısa bir dalış.
func nibble() -> void:
	_dip = 1.0


## Isırma: suya gömülür.
func go_under() -> void:
	look = Look.UNDER


func start_fight(at: Vector3) -> void:
	fight_point = at
	look = Look.FIGHT


## Oltanın ucuna geri döner, sonra gizlenir.
func fly_back(to: Vector3, seconds: float) -> void:
	_from = position
	_to = to
	_arc = 0.6
	_t = 0.0
	_duration = maxf(seconds, 0.05)
	look = Look.RETURNING


func hide_bobber() -> void:
	look = Look.HIDDEN
	visible = false


func _process(delta: float) -> void:
	_clock += delta
	_glint.visible = false
	_sinker_part.visible = kind == "sinker" and (look == Look.FLYING or look == Look.RETURNING)
	match look:
		Look.FLYING, Look.RETURNING:
			_t = minf(1.0, _t + delta / _duration)
			position = _from.lerp(_to, _t) + Vector3.UP * _arc * 4.0 * _t * (1.0 - _t)
			if _t >= 1.0:
				if look == Look.FLYING:
					land(_to)
				else:
					hide_bobber()
		Look.FLOATING:
			if kind == "lure":
				_lure_float()
				return
			if kind == "sinker":
				position = _rest
				return
			if kind == "fly":
				_fly_float()
				return
			_dip = move_toward(_dip, 0.0, delta * 3.5)
			var bob := sin(_clock * 2.3) * 0.015
			position = _rest + Vector3(0, bob - DIP * sin(_dip * PI * 0.5), 0)
		Look.UNDER:
			var shake := Vector3(sin(_clock * 31.0), 0, cos(_clock * 27.0)) * 0.025
			position = position.lerp(_rest + Vector3(0, -RADIUS * 1.6, 0) + shake, minf(1.0, delta * 18.0))
		Look.FIGHT:
			var target := fight_point + Vector3(0, -RADIUS * 0.8 + sin(_clock * 9.0) * 0.03, 0)
			position = position.lerp(target, minf(1.0, delta * 12.0))


## Yapay yem suda: oynarken yüzeyde titreşir ve parlar; durunca batar.
func _lure_float() -> void:
	var live := 1.0 - clampf(sink, 0.0, 1.0)
	var wobble := sin(_clock * 18.0) * 0.35 * live
	rotation = Vector3(0.0, _heading, wobble)
	position = _rest + Vector3(0, 0.012 - LURE_SINK * clampf(sink, 0.0, 1.0), 0)
	# Parıltı: oynarken arada bir çakar (balık ışıltıya gelir).
	var flash := maxf(0.0, sin(_clock * 7.0)) * live
	_glint.visible = flash > 0.55
	_glint.scale = Vector3.ONE * (0.6 + flash)


## Sinek suyun yüzünde: akıntının yönüne dönük, hafifçe sallanır.
func _fly_float() -> void:
	rotation = Vector3(0.0, _heading, sin(_clock * 5.0) * 0.12)
	position = _rest + Vector3(0, 0.012 + sin(_clock * 3.1) * 0.006, 0)
