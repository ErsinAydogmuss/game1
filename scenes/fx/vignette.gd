class_name Vignette
extends ColorRect
## Tam ekran vinyet: kenarlar yüzeyde hafif, yer altında belirgin koyulaşır. Arayüzün
## altında çizilir ve dokunuşları engellemez.

const SURFACE_STRENGTH := 0.22
const UNDERGROUND_STRENGTH := 0.62

var _material: ShaderMaterial


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_material = ShaderMaterial.new()
	_material.shader = preload("res://scenes/fx/vignette.gdshader")
	material = _material
	color = Color.WHITE
	set_depth(0.0)


## underground: oyuncunun yerin kaç metre altında olduğu.
func set_depth(underground: float) -> void:
	var t := clampf(underground / 6.0, 0.0, 1.0)
	_material.set_shader_parameter("strength", lerpf(SURFACE_STRENGTH, UNDERGROUND_STRENGTH, t))
	if size.y > 0.0:
		_material.set_shader_parameter("aspect", size.x / size.y)
