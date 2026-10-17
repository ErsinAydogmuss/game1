class_name LakeTexture
extends RefCounted
## LakeShape ızgarasından su ve zemin shader'larının okuduğu veri dokuları.
## Göl dokusu (build): R = derinlik / max_depth (shader'da depth_scale ile metreye döner),
## G = işaretli kıyı uzaklığı ((m + 4) / 12; −4..8 m), B = 0, A = akıntının gücü (0..1; yönü
## flow_dir: gölün en güçlü akıntısı). Doku pikselleri ızgara hücrelerinin merkezleridir:
## uv = (dünya xz − origin) / (hücre × boyut).
## Zemin dokusu (build_ground): R = yürünebilen dünya (1) ya da orman (0), G = taşlık.

## G kanalının kapsadığı aralık (m): SHORE_MIN altı 0, SHORE_MIN + SHORE_SPAN üstü 1.
const SHORE_MIN := -4.0
const SHORE_SPAN := 12.0
## Zemin dokusunun aralığı (m) ve taşlığın kıyıdan uzandığı yer.
const GROUND_STEP := 0.5
const STONE_BAND := 6.0


static func build(lake: LakeShape) -> ImageTexture:
	return ImageTexture.create_from_image(build_image(lake))


## Göl dokusunun görüntüsü (testler bundan okur).
static func build_image(lake: LakeShape) -> Image:
	var image := Image.create_empty(lake.width, lake.height, false, Image.FORMAT_RGBAH)
	for y in lake.height:
		for x in lake.width:
			var i := y * lake.width + x
			var shore: float = lake.shore[i]
			var depth := (lake.depth_for(shore) if lake.uniform else lake.depth[i]) / maxf(lake.max_depth, 0.01)
			image.set_pixel(x, y, Color(depth, clampf((shore - SHORE_MIN) / SHORE_SPAN, 0.0, 1.0), 0.0, 0.0))
	# Akıntı yalnızca akıntılı havzaların çevresinde hesaplanır.
	var strongest := lake.strongest_flow().length()
	var bounds := lake.flow_bounds()
	if strongest > 0.0 and bounds.size != Vector2.ZERO:
		var low := ((bounds.position - lake.origin) / LakeShape.CELL).floor()
		var high := ((bounds.end - lake.origin) / LakeShape.CELL).ceil()
		for y in range(maxi(0, int(low.y)), mini(lake.height, int(high.y))):
			for x in range(maxi(0, int(low.x)), mini(lake.width, int(high.x))):
				if lake.shore[y * lake.width + x] <= 0.0:
					continue
				var strength := lake.flow_at(lake.cell_center(x, y)).length() / strongest
				if strength > 0.0:
					var c := image.get_pixel(x, y)
					c.a = strength
					image.set_pixel(x, y, c)
	return image


## Dokuyu ve dönüşümü bir shader malzemesine verir (lake_data, lake_origin, lake_size,
## depth_scale, flow_dir).
static func apply(material: ShaderMaterial, lake: LakeShape, texture: Texture2D) -> void:
	material.set_shader_parameter("lake_data", texture)
	material.set_shader_parameter("lake_origin", lake.origin)
	material.set_shader_parameter("lake_size", Vector2(lake.width, lake.height) * LakeShape.CELL)
	material.set_shader_parameter("depth_scale", lake.max_depth)
	material.set_shader_parameter("flow_dir", lake.strongest_flow().normalized())


## Zemin dokusu: area'yı GROUND_STEP aralıkla örter. stony: karası taşlık olan bölgelerin sırası
## (kıyıdan STONE_BAND metreye kadar).
static func build_ground(lake: LakeShape, area: Rect2, stony: PackedInt32Array) -> ImageTexture:
	return ImageTexture.create_from_image(ground_image(lake, area, stony))


## Zemin dokusunun görüntüsü (testler bundan okur).
static func ground_image(lake: LakeShape, area: Rect2, stony: PackedInt32Array) -> Image:
	var w := maxi(1, ceili(area.size.x / GROUND_STEP))
	var h := maxi(1, ceili(area.size.y / GROUND_STEP))
	var image := Image.create_empty(w, h, false, Image.FORMAT_RG8)
	for y in h:
		for x in w:
			var p := area.position + (Vector2(x, y) + Vector2(0.5, 0.5)) * GROUND_STEP
			var stone := 0.0
			if not stony.is_empty():
				var land := lake.land_distance(p)
				if land < 0.0 and land > -STONE_BAND and lake.zone_of(p) in stony:
					stone = 1.0
			image.set_pixel(x, y, Color(1.0 if lake.in_world(p) else 0.0, stone, 0.0))
	return image


static func apply_ground(material: ShaderMaterial, area: Rect2, texture: Texture2D) -> void:
	material.set_shader_parameter("ground_data", texture)
	material.set_shader_parameter("ground_origin", area.position)
	material.set_shader_parameter("ground_size", Vector2(texture.get_width(), texture.get_height()) * GROUND_STEP)
