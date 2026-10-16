class_name RodModel
extends Node3D
## Olta: tutamak, makara ve üç eklemli kamış (Props). Kökü bu düğümün yerinde; kamış -Z'ye uzanır.
## Ucundaki işaretçiden (tip) misina çıkar. bend (0..1): gerilimle uca doğru artan bükülme;
## bekleyişte hafifçe esner. Kare başı hareket _process'te.

const LENGTH := 2.3
## Eklemlerin bükülme payı (kökten uca).
const BEND := [0.1, 0.22, 0.38]
const WOOD := Color("#7a4f2b")
const GRIP := Color("#3a2a20")
const METAL := Color("#c9d2dc")

## Gerilim (0 = gevşek, 1 = çok gergin).
var bend: float = 0.0
var tip: Node3D

var _joints: Array[Node3D] = []
var _clock: float = 0.0


func _ready() -> void:
	# Tutamak (elin arkasında biraz kalır) ve makara.
	Props.cylinder(self, 0.028, 0.032, 0.42, Vector3(0, 0, 0.12), GRIP, 6, Vector3(deg_to_rad(90.0), 0, 0))
	var reel := Props.cylinder(self, 0.06, 0.06, 0.05, Vector3(0, -0.07, 0.05), METAL, 10, Vector3(0, 0, deg_to_rad(90.0)))
	reel.name = "Reel"
	Props.cylinder(self, 0.012, 0.012, 0.09, Vector3(0.05, -0.07, 0.05), METAL, 5, Vector3(0, 0, deg_to_rad(90.0)))
	var parent: Node3D = self
	var segment := LENGTH / 3.0
	for i in 3:
		var joint := Props.pivot(parent, Vector3(0, 0, -segment if i > 0 else -0.08), "Joint%d" % i)
		var r0 := 0.022 - 0.006 * i
		var r1 := r0 - 0.006
		Props.cylinder(joint, maxf(r1, 0.006), r0, segment, Vector3(0, 0, -segment * 0.5), WOOD, 5,
				Vector3(deg_to_rad(-90.0), 0, 0))
		if i < 2:
			Props.cylinder(joint, r1 + 0.005, r1 + 0.005, 0.025, Vector3(0, 0, -segment), METAL, 6,
					Vector3(deg_to_rad(-90.0), 0, 0))
		_joints.append(joint)
		parent = joint
	tip = Props.pivot(parent, Vector3(0, 0, -segment), "Tip")
	# Olta gölge haritasının bir pikselinden ince: gölgesi görünmez, gölge çizimi boşa gider.
	for node in find_children("*", "GeometryInstance3D", true, false):
		(node as GeometryInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func _process(delta: float) -> void:
	_clock += delta
	# Bekleyişte hafif esneme; gerilimde aşağı (balığa doğru) bükülme ve titreme.
	var sway := sin(_clock * 1.7) * 0.015 * (1.0 - clampf(bend, 0.0, 1.0))
	var shiver := sin(_clock * 37.0) * 0.012 * clampf(bend - 0.6, 0.0, 1.0)
	for i in _joints.size():
		var amount: float = BEND[i]
		_joints[i].rotation.x = -(bend * amount) + sway * (i + 1) + shiver
