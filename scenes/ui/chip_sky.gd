class_name ChipSky
extends Control
## Saat çipinin ikonları (Dalga 5): vaktin ve (açık değilse) havanın ikonu yan yana, saatin solunda. İkisi tek
## çizimde: Ersin'in görselleri (Parti 5a: time_icons, weather_icons) tek bir atlasta birleşir, iki ikon aynı
## dokudan çizilir (iki ayrı doku iki çizim olurdu); görsel yoksa ikisi de kodla (SkyIcons) tek üçgen dizisi.
## İskelede yağmurda Dede konuşurken 150 çizim sınırında: CLAUDE.md "Çizim sayısı".

const SIDE := 58.0
const GAP := 6.0
## Atlasın hücresi (ikonların kesildiği boy) ve hücreler arası saydam pay (küçük mipmap'te komşu sızmasın).
const CELL := 160
const PAD := 6

var phase: String = "phase_morning"
## Havanın ikonu (açık havada boş: gösterilmez).
var weather: String = ""

## Vaktin ve havanın görselleri tek dokuda (ilk çizimde kurulur; görsel yoksa null) ve her ikonun yeri.
var _atlas: Texture2D = null
var _cells: Dictionary = {}
var _atlas_built: bool = false


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


## İkonlar atlastan mı çiziliyor (bot ve testler: tek çizim)?
func uses_atlas() -> bool:
	if not _atlas_built:
		_build_atlas()
	return _atlas != null


func _draw() -> void:
	if not _atlas_built:
		_build_atlas()
	var sky_kinds: Array[String] = []
	var sky_origins: Array[Vector2] = []
	var list := kinds()
	for i in list.size():
		var origin := Vector2(i * (SIDE + GAP), (size.y - SIDE) * 0.5)
		if _cells.has(list[i]):
			draw_texture_rect_region(_atlas, Rect2(origin, Vector2(SIDE, SIDE)), _cells[list[i]])
			continue
		var texture := GameIcon.texture_for(list[i])
		if texture != null:
			draw_texture_rect(texture, Rect2(origin, Vector2(SIDE, SIDE)), false)
		elif list[i] in SkyIcons.KINDS:
			sky_kinds.append(list[i])
			sky_origins.append(origin)
	SkyIcons.draw_many(self, sky_kinds, sky_origins, SIDE / 100.0)


## Vaktin ve havanın görsellerini tek dokuda birleştirir (yalnızca hepsi varsa: biri eksikse ikonlar karışık çizilir,
## kodla çizilen de tek dizi).
func _build_atlas() -> void:
	_atlas_built = true
	var kinds_all: Array[String] = []
	for kind in SkyIcons.KINDS:
		if kind.begins_with("phase_") or kind.begins_with("weather_"):
			kinds_all.append(kind)
	var images: Array[Image] = []
	for kind in kinds_all:
		var texture := GameIcon.texture_for(kind)
		if texture == null:
			return
		var img := texture.get_image()
		if img == null or img.is_empty():
			return
		if img.is_compressed():
			img.decompress()
		img.clear_mipmaps()
		img.convert(Image.FORMAT_RGBA8)
		if img.get_size() != Vector2i(CELL, CELL):
			img.resize(CELL, CELL, Image.INTERPOLATE_LANCZOS)
		images.append(img)
	var cols := 3
	var step := CELL + PAD * 2
	var rows := ceili(images.size() / float(cols))
	var atlas := Image.create_empty(cols * step, rows * step, false, Image.FORMAT_RGBA8)
	for i in images.size():
		var at := Vector2i((i % cols) * step + PAD, (i / cols) * step + PAD)
		atlas.blit_rect(images[i], Rect2i(Vector2i.ZERO, Vector2i(CELL, CELL)), at)
		_cells[kinds_all[i]] = Rect2(Vector2(at), Vector2(CELL, CELL))
	atlas.generate_mipmaps()
	_atlas = ImageTexture.create_from_image(atlas)
