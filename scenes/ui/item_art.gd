class_name ItemArt
extends RefCounted
## Görsellere tek giriş noktası: arayüz ikonları, portreler, logo ve balık portreleri.
## Önce kullanıcının işlenmiş görselleri (assets/icons/..., assets/ui/...) kullanılır; dosya yoksa
## null döner ve çağıran yer tutucu çizer (GameIcon kodla çizer). Balık portreleri oyunun kendi
## 3D modelinden çekilir (FishPortrait, register_fish ile verilir); o gelene kadar balığın renginde
## bir madalyon üretilir. (Kazı'dan uyarlandı.)
## Görseller tools/process_images.gd ile üretilir (docs/gorsel-istekleri.md).

const UI := "res://assets/icons/ui/%s.png"
const PORTRAITS := "res://assets/ui/portraits/%s.png"
const ART := "res://assets/ui/art/%s"
## Arayüz kitinin 9 dilimli çerçeveleri ve düğmeleri (ör. "panel", "button_green", "frame_rare").
const FRAMES := "res://assets/ui/frames/%s.png"
## Nine'nin dükkânındaki takımın resimleri (gear.json "icon" ya da kimlik; docs/gorsel-istekleri.md
## Parti 2).
const GEAR := "res://assets/icons/gear/%s.png"

## Yer tutucunun boyu (piksel).
const PLACEHOLDER_SIZE := 128

static var _cache: Dictionary = {}
## Balık id -> renk (yer tutucu için) ve id -> portre dokusu (modelden çekilen).
static var _fish_colors: Dictionary = {}
static var _fish_portraits: Dictionary = {}


## Balıkların yer tutucu renkleri (fish.json "color").
static func register_fish_colors(colors: Dictionary) -> void:
	for id: Variant in colors:
		_fish_colors[str(id)] = colors[id]


## Modelden çekilen balık portresi (FishPortrait verir).
static func register_fish_portrait(id: String, texture: Texture2D) -> void:
	_fish_portraits[id] = texture


## Balığın portresi; yoksa balığın renginde yer tutucu madalyon.
static func fish(id: String) -> Texture2D:
	if _fish_portraits.has(id):
		return _fish_portraits[id]
	return _placeholder(id)


static func ui(icon_name: String) -> Texture2D:
	return _load(UI % icon_name)


## Takımın resmi (yoksa null; dükkân kodla çizilen ikonu kullanır).
static func gear(icon_name: String) -> Texture2D:
	return _load(GEAR % icon_name)


## Arayüz kitinden 9 dilimli bir çerçeve ya da düğme görseli (yoksa null; UiKit.framed kullanır).
static func frame(frame_name: String) -> Texture2D:
	return _load(FRAMES % frame_name)


## Çerçeve görselini dışarıdan verir (testler; dosya yokken UiKit.framed'i denemek için).
static func register_frame(frame_name: String, texture: Texture2D) -> void:
	_cache[FRAMES % frame_name] = texture


## register_frame'i geri alır: sonraki istekte dosyadan yüklenir (testler).
static func forget_frame(frame_name: String) -> void:
	_cache.erase(FRAMES % frame_name)


static func portrait(mood: String) -> Texture2D:
	return _load(PORTRAITS % mood)


## file: uzantısıyla (ör. "logo.png").
static func art(file: String) -> Texture2D:
	return _load(ART % file)


## Altın çerçeveli, balığın renginde yumuşak kenarlı bir disk ve parıltı (önbellekli).
static func _placeholder(id: String) -> Texture2D:
	var key := "placeholder:" + id
	if _cache.has(key):
		return _cache[key]
	var color: Color = _fish_colors.get(id, Color("#7fb8c8"))
	var side := PLACEHOLDER_SIZE
	var center := Vector2(side, side) * 0.5
	var k := side / 128.0
	# Dıştan içe: koyu altın kenar, altın çerçeve, balığın koyu rengi, balığın rengi, parıltı.
	var rings: Array[Array] = [
		[Vector2.ZERO, 58.0 * k, Color("#a8700c")], [Vector2.ZERO, 54.0 * k, Color("#ffd23f")],
		[Vector2.ZERO, 45.0 * k, color.darkened(0.35)], [Vector2.ZERO, 39.0 * k, color],
		[Vector2(-14, -14) * k, 9.0 * k, Color(1, 1, 1, 0.55)],
	]
	var image := Image.create_empty(side, side, false, Image.FORMAT_RGBA8)
	for y in side:
		for x in side:
			var p := Vector2(x + 0.5, y + 0.5)
			var out := Color(0, 0, 0, 0)
			for ring in rings:
				var r: float = ring[1]
				var cover := clampf(r - p.distance_to(center + (ring[0] as Vector2)) + 0.5, 0.0, 1.0)
				if cover > 0.0:
					var c: Color = ring[2]
					out = out.blend(Color(c, c.a * cover))
			image.set_pixel(x, y, out)
	image.generate_mipmaps()
	var texture := ImageTexture.create_from_image(image)
	_cache[key] = texture
	return texture


static func _load(path: String) -> Texture2D:
	if _cache.has(path):
		return _cache[path]
	var texture: Texture2D = load(path) if ResourceLoader.exists(path) else null
	_cache[path] = texture
	return texture
