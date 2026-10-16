class_name LakeTexture
extends RefCounted
## LakeShape ızgarasından su ve zemin shader'larının okuduğu veri dokusu:
## R = derinlik / max_depth, G = işaretli kıyı uzaklığı ((m + 4) / 12; −4..8 m), B = 0, A = 1.
## Doku pikselleri ızgara hücrelerinin merkezleridir: uv = (dünya xz − origin) / (hücre × boyut).

## G kanalının kapsadığı aralık (m): SHORE_MIN altı 0, SHORE_MIN + SHORE_SPAN üstü 1.
const SHORE_MIN := -4.0
const SHORE_SPAN := 12.0


static func build(lake: LakeShape) -> ImageTexture:
	var image := Image.create_empty(lake.width, lake.height, false, Image.FORMAT_RGBAH)
	for y in lake.height:
		for x in lake.width:
			var shore: float = lake.shore[y * lake.width + x]
			var depth := lake.depth_for(shore) / maxf(lake.max_depth, 0.01)
			image.set_pixel(x, y, Color(depth, clampf((shore - SHORE_MIN) / SHORE_SPAN, 0.0, 1.0), 0.0, 1.0))
	return ImageTexture.create_from_image(image)


## Dokuyu ve dönüşümü bir shader malzemesine verir (lake_data, lake_origin, lake_size).
static func apply(material: ShaderMaterial, lake: LakeShape, texture: Texture2D) -> void:
	material.set_shader_parameter("lake_data", texture)
	material.set_shader_parameter("lake_origin", lake.origin)
	material.set_shader_parameter("lake_size", Vector2(lake.width, lake.height) * LakeShape.CELL)
