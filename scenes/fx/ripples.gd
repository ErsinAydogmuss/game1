class_name Ripples
extends Node3D
## Suda büyüyüp solan halkalar (şamandıra düşünce, dürtmede, ısırmada, balık çırpınınca).
## Süreler _process(delta) toplamıyla ölçülür (video kaydında da doğru akar).

const Y := 0.025

var _shader: Shader
var _mesh: PlaneMesh
## Her biri: { node, age, duration }.
var _live: Array[Dictionary] = []


func _ready() -> void:
	_shader = load("res://scenes/fx/ripple.gdshader")
	_mesh = PlaneMesh.new()
	_mesh.size = Vector2.ONE


## p noktasında radius (m) yarıçapa büyüyen, duration sn süren bir halka.
func spawn(p: Vector2, radius: float, duration: float, color: Color = Color(1, 1, 1, 0.85), thickness: float = 0.1) -> void:
	var node := MeshInstance3D.new()
	node.mesh = _mesh
	node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var material := ShaderMaterial.new()
	material.shader = _shader
	material.render_priority = 2
	material.set_shader_parameter("color", color)
	material.set_shader_parameter("thickness", thickness)
	node.material_override = material
	node.position = Vector3(p.x, Y, p.y)
	node.scale = Vector3(radius * 2.0, 1.0, radius * 2.0)
	add_child(node)
	_live.append({ "node": node, "age": 0.0, "duration": maxf(duration, 0.05) })


func _process(delta: float) -> void:
	for i in range(_live.size() - 1, -1, -1):
		var r := _live[i]
		r["age"] = float(r["age"]) + delta
		var t := float(r["age"]) / float(r["duration"])
		var node: MeshInstance3D = r["node"]
		if t >= 1.0:
			node.queue_free()
			_live.remove_at(i)
			continue
		(node.material_override as ShaderMaterial).set_shader_parameter("progress", t)
