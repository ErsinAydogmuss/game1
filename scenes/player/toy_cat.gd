class_name ToyCat
extends Node3D
## Tekir'in yedek gövdesi (Quaternius kedisi yoksa): kodla kurulan oyuncak kedi, tek ağ (MeshBatch), gölgesiz.
## CatBody'nin arayüzü: head_point, set_motion (yürürken hafifçe sallanır), hop. +X'e bakar, ayakları y = 0'da.

const FUR := Color("#aaa69e")
const STRIPE := Color("#45413c")
const CREAM := Color("#f4ecdc")
const PINK := Color("#e99aa0")
const HEAD := Vector3(0.24, 0.3, 0.0)
const HOP_TIME := 0.35
const HOP_HEIGHT := 0.08

var _root: Node3D
var _walk: float = 0.0
var _speed: float = 0.0
var _hop: float = -1.0


func _ready() -> void:
	_root = Node3D.new()
	add_child(_root)
	var batch := MeshBatch.new()
	batch.sphere(0.1, Vector3(0.0, 0.17, 0.0), FUR, Vector3(1.9, 0.9, 0.95))
	for x: float in [-0.08, 0.0, 0.08]:
		batch.box(Vector3(0.025, 0.07, 0.17), Vector3(x, 0.24, 0.0), STRIPE)
	batch.sphere(0.075, Vector3(0.21, 0.26, 0.0), FUR)
	batch.sphere(0.03, Vector3(0.27, 0.24, 0.0), CREAM, Vector3(1.0, 0.8, 1.2))
	for side: float in [-1.0, 1.0]:
		batch.cylinder(0.0, 0.03, 0.06, Vector3(0.2, 0.33, side * 0.04), FUR, 6)
		batch.sphere(0.012, Vector3(0.275, 0.27, side * 0.025), Color("#1c1410"))
		for x: float in [-0.1, 0.11]:
			batch.cylinder(0.018, 0.018, 0.13, Vector3(x, 0.065, side * 0.05), FUR, 6)
			batch.sphere(0.02, Vector3(x, 0.01, side * 0.05), CREAM)
	batch.sphere(0.011, Vector3(0.285, 0.255, 0.0), PINK)
	batch.cylinder(0.015, 0.02, 0.22, Vector3(-0.2, 0.28, 0.0), FUR, 6, Vector3(0.0, 0.0, 0.5))
	var node := batch.build(_root, "ToyCatMesh")
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF


func head_point() -> Vector3:
	return to_global(HEAD)


func set_motion(speed: float) -> void:
	_speed = speed


func hop() -> void:
	_hop = 0.0


func _process(delta: float) -> void:
	if _root == null:
		return
	var y := 0.0
	if _speed > 0.05:
		_walk += delta * (6.0 + _speed * 4.0)
		y = absf(sin(_walk)) * 0.02
	if _hop >= 0.0:
		_hop += delta
		var t := _hop / HOP_TIME
		if t >= 1.0:
			_hop = -1.0
		else:
			y += sin(t * PI) * HOP_HEIGHT
	_root.position.y = y
