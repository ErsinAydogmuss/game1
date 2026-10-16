class_name Bobber
extends Node3D
## Şamandıra: kırmızı-beyaz top (0,3 m; telefonda okunsun diye iri). Atışta yay çizerek uçar,
## suda hafifçe sallanır, dürtmede boyunun %40'ı kadar dalıp çıkar, ısırmada suya gömülür,
## çekişmede balığın peşinden sürüklenir, geri sarılınca oltanın ucuna döner.
## Kare başı konum _process'te hesaplanır (Tween yok).

enum Look { HIDDEN, FLYING, FLOATING, UNDER, FIGHT, RETURNING }

const RADIUS := 0.15
## Dürtmede dalış derinliği: boyun %40'ı.
const DIP := 0.4 * RADIUS * 2.0

var look: Look = Look.HIDDEN
## Çekişmede balığın yeri (FIGHT).
var fight_point := Vector3.ZERO

var _from := Vector3.ZERO
var _to := Vector3.ZERO
var _arc: float = 1.0
var _t: float = 0.0
var _duration: float = 0.5
var _dip: float = 0.0
var _clock: float = 0.0
var _rest := Vector3.ZERO


func _ready() -> void:
	Props.sphere(self, RADIUS, Vector3.ZERO, Color("#e63946"), 14, 7)
	Props.sphere(self, RADIUS * 0.8, Vector3(0, RADIUS * 0.55, 0), Color("#fbfbf6"), 14, 7)
	Props.cylinder(self, 0.018, 0.018, 0.16, Vector3(0, RADIUS * 1.35 + 0.06, 0), Color("#e63946"), 6)
	visible = false


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


## Suya düştü (oturumun land olayıyla): uçuş nerede olursa olsun hedefe oturur.
func land(at: Vector3) -> void:
	_rest = at
	look = Look.FLOATING
	position = at
	visible = true


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
			_dip = move_toward(_dip, 0.0, delta * 3.5)
			var bob := sin(_clock * 2.3) * 0.015
			position = _rest + Vector3(0, bob - DIP * sin(_dip * PI * 0.5), 0)
		Look.UNDER:
			var shake := Vector3(sin(_clock * 31.0), 0, cos(_clock * 27.0)) * 0.025
			position = position.lerp(_rest + Vector3(0, -RADIUS * 1.6, 0) + shake, minf(1.0, delta * 18.0))
		Look.FIGHT:
			var target := fight_point + Vector3(0, -RADIUS * 0.8 + sin(_clock * 9.0) * 0.03, 0)
			position = position.lerp(target, minf(1.0, delta * 12.0))
