class_name ChipSky
extends Control
## Saat çipinin ikonları (Dalga 5): vaktin ve (açık değilse) havanın ikonu yan yana, saatin solunda. İkisi de
## kodla (SkyIcons) çizilirken tek üçgen dizisi, tek çizim: iskelede yağmurda bir çizim kazandırır (Tekir'e
## yer açar; CLAUDE.md "Çizim sayısı"). Ersin'in görselleri gelince her biri kendi dokusuyla çizilir.

const SIDE := 58.0
const GAP := 6.0

var phase: String = "phase_morning"
## Havanın ikonu (açık havada boş: gösterilmez).
var weather: String = ""


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	custom_minimum_size = Vector2(SIDE, SIDE)


func set_icons(phase_kind: String, weather_kind: String) -> void:
	phase = phase_kind
	weather = weather_kind
	custom_minimum_size = Vector2(SIDE if weather.is_empty() else SIDE * 2.0 + GAP, SIDE)
	queue_redraw()


## Görünen ikonlar (bot).
func kinds() -> PackedStringArray:
	var out := PackedStringArray([phase])
	if not weather.is_empty():
		out.append(weather)
	return out


func _draw() -> void:
	var sky_kinds: Array[String] = []
	var sky_origins: Array[Vector2] = []
	var list := kinds()
	for i in list.size():
		var origin := Vector2(i * (SIDE + GAP), (size.y - SIDE) * 0.5)
		var texture := GameIcon.texture_for(list[i])
		if texture != null:
			draw_texture_rect(texture, Rect2(origin, Vector2(SIDE, SIDE)), false)
		elif list[i] in SkyIcons.KINDS:
			sky_kinds.append(list[i])
			sky_origins.append(origin)
	SkyIcons.draw_many(self, sky_kinds, sky_origins, SIDE / 100.0)
