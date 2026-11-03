class_name MapView
extends Control
## Haritanın kendisi (MapPanel'in içinde): gölün harita dokusu (build_image) map.gdshader ile
## çizilir; üstünde iskele, kapalı çitler ve tabelaları, şamandıralar (_draw_overlay), Ersin'in
## çıkartmaları (bölgelerin süsü, ormanda ağaçlar, sandal, pusula; rozetlere binmeyecek yere
## kayar), bölge rozetleri, Nine'nin dükkânı, Dede ve "Buradasın" iğnesi (çocuk düğümler). Dünya →
## harita: gölün ve dünyanın kapladığı yer (region) haritanın alanına oranı korunarak sığdırılır ve
## ortalanır. Harita kâğıdı (MapPanel'in çerçevesi) varsa haritanın kenarı kâğıda karışır.
## Görseller docs/gorsel-istekleri.md Parti 3; yoksa harita süssüz, ikonlar kodla.

signal zone_pressed(zone_id: String)

## Harita dokusunun aralığı (m) ve haritanın suyun ve iskelenin çevresinde bıraktığı pay (m): atış
## noktaları, dükkân ve biraz orman içinde kalır.
const STEP := 0.5
const PAD := 4.0
const BADGE_ICON := 58.0
## Rozet en az bu boyda (dokunma hedefi: panel ekrana sığmak için biraz küçülse de 122 birimin
## altına düşmesin).
const BADGE_MIN := Vector2(150, 132)
const PIN := 66.0
const MARK := 58.0
## Kerevit tuzağının işareti (küçük: atış noktasının iğnesini örtmesin).
const TRAP_MARK := 44.0
## Çıkartmaların boyu: bölge süsü ve ağaç öbeği, dükkân, sandal, pusula; şamandıra ve çit tabelası.
const STICKER := 92.0
const SHOP_STICKER := 84.0
const BOAT_STICKER := 76.0
const COMPASS := 80.0
const BUOY_ICON := 44.0
const SIGN_ICON := 46.0
## Bölge -> [çıkartması, bölgenin suyunun ortasına göre yeri (m)]: kıyısının dışa bakan yanında.
const ZONE_STICKERS := {
	"reeds": ["map_reeds", Vector2(-6.8, 0.5)],
	"lily_cove": ["map_lilies", Vector2(6.5, 4.5)],
	"rocky_point": ["map_rocks", Vector2(7.5, 1.5)],
}
## Ormana konan ağaç öbeği (yer yoksa daha az): kıyıdan en az FOREST_SHORE metre, birbirinden en az
## TREE_GAP metre uzakta.
const TREES := 5
const FOREST_SHORE := 2.0
const TREE_GAP := 7.0
## Çıkartma yerinden en çok bu kadar halka uzağa kayar (halka arası boyunun 0,35'i).
const RINGS := 6
## Kâğıtlı haritada kenarın kâğıda karıştığı bant (m; map.gdshader fade_m).
const PAPER_FADE := 1.8
const WOOD := Color("#b07a3b")
const WOOD_DARK := Color("#6e4520")
const BUOY := Color("#e63946")
## Kilitli rozetin soluk hâli.
const LOCKED_TINT := Color(1, 1, 1, 0.55)

## Gölün harita dokuları (spot id -> [göl, veri dokusu, bölge dokusu, Rect2]): bir kez kurulur.
## Aynı görüntüden iki doku: veri yumuşak (doğrusal), bölge keskin (en yakın) okunur; GLES3'te bir
## dokunun tek süzgeci olur.
static var _built: Dictionary = {}
## Gölün ağaç çıkartması yerleri (spot id -> [göl, noktalar]).
static var _forest: Dictionary = {}

var lake: LakeShape
## Haritanın dünyadaki yeri (m).
var region := Rect2(0, 0, 1, 1)
var _map: ColorRect
var _material: ShaderMaterial
var _overlay: Control
## Bölge kimliği -> rozet, rozetin köşesindeki "Yeni!" etiketi; rozetlerin dünyadaki yeri.
var _badges: Dictionary = {}
var _tags: Dictionary = {}
var _anchors: Dictionary = {}
var _pin: Control
var _here := Vector2.ZERO
## İşaretler: [düğüm, dünya noktası].
var _marks: Array[Array] = []
## Çıkartmalar: [düğüm, dünya noktası]; yerleşirken rozetlere, iğneye, işaretlere ve birbirine
## binmeyen en yakın yere kayar (_place_stickers).
var _stickers: Array[Array] = []
## Kapalı çitler ve şamandıralar (dünya).
var _gates: Array[PackedVector2Array] = []
var _buoys: PackedVector2Array = PackedVector2Array()
## Sallanan rozet ve kalan süresi (kilitliye dokunulunca).
var _shake_id: String = ""
var _shake: float = 0.0
var _clock: float = 0.0


func _init() -> void:
	clip_contents = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_map = ColorRect.new()
	_map.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_material = ShaderMaterial.new()
	_material.shader = load("res://scenes/ui/map.gdshader")
	_map.material = _material
	add_child(_map)
	_overlay = Control.new()
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_overlay.draw.connect(_draw_overlay)
	add_child(_overlay)
	resized.connect(_layout)


## Haritayı kurar: göl ve bölgeleri, kilitler (kayda göre), balıkçının yeri (here), bulunulan
## bölge ve işaretler ([{ "kind": "shop" | "dede" | "boat" | "trap" | "bottle" | "secret_x", "pos": Vector2 }]; sandal çıkartmadır,
## görseli yoksa çizilmez).
func show_lake(db: ContentDB, save: SaveData, spot_id: String, here: Vector2, current: String,
		marks: Array[Dictionary]) -> void:
	lake = db.lake(spot_id)
	var built := map_texture(spot_id, lake)
	region = built[3]
	var texture: ImageTexture = built[1]
	_material.set_shader_parameter("map_data", texture)
	_material.set_shader_parameter("map_zone", built[2])
	_material.set_shader_parameter("region_origin", region.position)
	_material.set_shader_parameter("region_size", region.size)
	_material.set_shader_parameter("texel", Vector2(1.0 / texture.get_width(), 1.0 / texture.get_height()))
	var zones := db.zones_of(spot_id)
	var locked := PackedFloat32Array()
	locked.resize(8)
	_gates.clear()
	_buoys = PackedVector2Array()
	for child in get_children():
		if child != _map and child != _overlay:
			remove_child(child)
			child.queue_free()
	_badges.clear()
	_tags.clear()
	_anchors.clear()
	_marks.clear()
	_stickers.clear()
	_material.set_shader_parameter("fade_m", PAPER_FADE if ItemArt.frame("map_paper") != null else 0.0)
	# Çıkartmalar önce eklenir: rozetlerin, işaretlerin ve iğnenin altında kalır.
	_add_stickers(spot_id, zones, marks)
	for k in zones.size():
		var z := zones[k]
		var id := str(z["id"])
		var open := Zones.unlocked(db, save, z)
		if k < locked.size():
			locked[k] = 0.0 if open else 1.0
		if not open:
			for g: PackedVector2Array in z["gates"]:
				_gates.append(g)
		_buoys.append_array(PackedVector2Array(z["buoys"]))
		if zones.size() <= 1:
			continue
		var note := ""
		var reason := Zones.lock_reason(db, save, z)
		if not reason.is_empty():
			var key := str(reason["key"])
			note = tr("UI_MAP_RANK") % int(reason["rank"]) if key == "UI_ZONE_LOCKED_RANK" else tr("UI_MAP_BOAT")
		var badge := _badge(id, open, note, id == current)
		add_child(badge)
		_badges[id] = badge
		_anchors[id] = badge_anchor(lake, k, z)
		if open and not save.flags.has("visited_" + id):
			var tag := _new_tag()
			add_child(tag)
			_tags[id] = tag
	_material.set_shader_parameter("locked", locked)
	for m in marks:
		var node := _mark(str(m["kind"]))
		if node != null:
			add_child(node)
			_marks.append([node, m["pos"]])
	_here = here
	_pin = _here_pin()
	add_child(_pin)
	_layout()


## Kilitli bir rozeti kısa süre sallar.
func shake(zone_id: String) -> void:
	_shake_id = zone_id
	_shake = 0.4


## Bölgenin rozeti (bot ve testler).
func badge(zone_id: String) -> Control:
	return _badges.get(zone_id) as Control


## Dünya noktasının haritadaki yeri (bu düğümün içinde).
func to_view(p: Vector2) -> Vector2:
	var area := map_area()
	return area.position + (p - region.position) / region.size * area.size


## Haritanın çizildiği alan: bölge oranı korunarak sığdırılır, ortalanır.
func map_area() -> Rect2:
	var s := minf(size.x / region.size.x, size.y / region.size.y)
	var area := region.size * s
	return Rect2((size - area) * 0.5, area)


## Haritanın dünyadaki yeri: su ve iskele, PAD payıyla.
static func map_region(shape: LakeShape) -> Rect2:
	var r := shape.water_bounds
	if shape.dock.size.x > 0.0:
		r = r.merge(shape.dock)
	return r.grow(PAD)


## Haritanın oranını koruyarak en çok max_size'a sığan boyu (panel haritayı buna göre kurar).
func fitted_size(max_size: Vector2) -> Vector2:
	var s := minf(max_size.x / region.size.x, max_size.y / region.size.y)
	return (region.size * s).round()


## Rozetin dünyadaki yeri: bölgenin verisindeki "map" noktası (verilmişse), yoksa bölgenin suyunun
## ortası (su hücrelerinin ağırlık merkezi). "Buradasın" iğnesine binen rozet yerleşirken kayar.
static func badge_anchor(shape: LakeShape, zone_index: int, zone: Dictionary = {}) -> Vector2:
	var at: Vector2 = zone.get("map", Dice.NO_POINT)
	if Dice.is_point(at):
		return at
	if zone_index >= 0 and zone_index < shape.zone_centers.size():
		return shape.zone_centers[zone_index]
	return shape.water_bounds.get_center()


## Gölün harita dokuları: [göl, veri dokusu, bölge dokusu, bölge]; göl değişmedikçe yeniden
## kurulmaz.
static func map_texture(spot_id: String, shape: LakeShape) -> Array:
	var cached: Array = _built.get(spot_id, [])
	if not cached.is_empty() and cached[0] == shape:
		return cached
	var r := map_region(shape)
	var image := build_image(shape, r)
	var built := [shape, ImageTexture.create_from_image(image), ImageTexture.create_from_image(image), r]
	_built[spot_id] = built
	return built


## Harita verisi (STEP metre aralıkla, yarım float): R kıyıya işaretli uzaklık (m; suda +),
## G derinlik (m), B bölge sırası + 1 (0 = yok), A yürünebilir (dünyanın içi ya da iskele).
static func build_image(shape: LakeShape, r: Rect2) -> Image:
	var w := maxi(1, ceili(r.size.x / STEP))
	var h := maxi(1, ceili(r.size.y / STEP))
	var image := Image.create_empty(w, h, false, Image.FORMAT_RGBAH)
	for y in h:
		for x in w:
			var p := r.position + Vector2((x + 0.5) * STEP, (y + 0.5) * STEP)
			var gx := floori((p.x - shape.origin.x) / LakeShape.CELL)
			var gy := floori((p.y - shape.origin.y) / LakeShape.CELL)
			var sd := 0.0
			var depth := 0.0
			var zone := 0
			if gx >= 0 and gy >= 0 and gx < shape.width and gy < shape.height:
				var i := gy * shape.width + gx
				sd = shape.shore[i]
				depth = shape.depth_for(sd) if shape.uniform else shape.depth[i]
				var z := shape.zone_grid[i]
				zone = 0 if z == LakeShape.NO_ZONE else z + 1
			else:
				sd = shape.land_distance(p)
			var walk := shape.on_dock(p) or (sd <= 0.0 and shape.world_rect.has_point(p) \
					and (shape.world_band == INF or sd >= -shape.world_band))
			image.set_pixel(x, y, Color(sd, depth, float(zone), 1.0 if walk else 0.0))
	return image


func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	_clock += delta
	if _shake > 0.0:
		_shake = maxf(0.0, _shake - delta)
		_layout()
	# "Buradasın" iğnesi hafifçe zıplar.
	if _pin != null:
		_pin.position = _pin_position() + Vector2(0.0, -6.0 * absf(sin(_clock * 3.0)))


func _layout() -> void:
	var area := map_area()
	_map.position = area.position
	_map.size = area.size
	_overlay.position = Vector2.ZERO
	_overlay.size = size
	_overlay.queue_redraw()
	var pin_rect := Rect2()
	# Çıkartmaların binmeyeceği yerler: iğne, rozetler (sallanmadan), "Yeni!" etiketleri, işaretler.
	var blocked: Array[Rect2] = []
	if _pin != null:
		_pin.reset_size()
		_pin.position = _pin_position()
		pin_rect = pin_box()
		blocked.append(pin_rect)
	for id: String in _badges:
		var b: Control = _badges[id]
		b.reset_size()
		var rest := _badge_spot(id, b.size, pin_rect)
		b.position = rest
		if id == _shake_id and _shake > 0.0:
			b.position.x += sin(_shake * 60.0) * 10.0 * (_shake / 0.4)
		blocked.append(Rect2(rest, b.size))
		if _tags.has(id):
			var tag: Control = _tags[id]
			tag.reset_size()
			var offset := Vector2(b.size.x - tag.size.x * 0.75, -tag.size.y * 0.4)
			tag.position = b.position + offset
			blocked.append(Rect2(rest + offset, tag.size))
	for m in _marks:
		var node: Control = m[0]
		node.reset_size()
		node.position = to_view(m[1]) - node.size * 0.5
		blocked.append(Rect2(node.position, node.size))
	_place_stickers(blocked)


## Rozetin yeri (sallanmadan): bölgenin noktasında, haritanın içinde. "Buradasın" iğnesinin
## üstüne binen rozet (sandaldayken derin orta) iğnenin üstüne, yer yoksa altına kayar.
func _badge_spot(id: String, badge_size: Vector2, pin_rect: Rect2) -> Vector2:
	var at := (to_view(_anchors[id]) - badge_size * 0.5).clamp(Vector2.ZERO, (size - badge_size).max(Vector2.ZERO))
	if pin_rect.size.x > 0.0 and Rect2(at, badge_size).intersects(pin_rect):
		var up := pin_rect.position.y - badge_size.y
		at.y = up if up >= 0.0 else minf(pin_rect.end.y, size.y - badge_size.y)
	return at


## "Buradasın" iğnesinin kapladığı yer (zıplaması ve biraz payla; rozetler buna binmez).
func pin_box() -> Rect2:
	if _pin == null:
		return Rect2()
	return Rect2(_pin_position(), _pin.size).grow(8.0)


## İğnenin ucu balıkçının yerinde; yazısı iğnenin altında (atış noktaları suya ekranın yukarısına
## bakar: aşağısı kara, rozetlerin üstüne binmez).
func _pin_position() -> Vector2:
	return to_view(_here) - Vector2(_pin.size.x * 0.5, PIN)


## Haritanın üstündekiler: iskele, kapalı çitler (kazık ve çapraz; ortasında tabela), şamandıralar.
## Tabela ve şamandıra Ersin'in ikonlarıyla; yoksa çitte tabela yok, şamandıra kodla.
func _draw_overlay() -> void:
	if lake == null:
		return
	var px := map_area().size.x / region.size.x
	if lake.dock.size.x > 0.0:
		var a := to_view(lake.dock.position)
		var b := to_view(lake.dock.end)
		var rect := Rect2(a, b - a)
		_overlay.draw_rect(rect.grow(px * 0.12), WOOD_DARK)
		_overlay.draw_rect(rect, WOOD)
		var planks := maxi(1, int(lake.dock.size.y / 0.5))
		for i in range(1, planks):
			var y := lerpf(rect.position.y, rect.end.y, float(i) / planks)
			_overlay.draw_line(Vector2(rect.position.x, y), Vector2(rect.end.x, y), WOOD_DARK, maxf(1.0, px * 0.05))
	var signpost := GameIcon.texture_for("signpost")
	for g in _gates:
		var from := to_view(g[0])
		var to := to_view(g[1])
		var length := from.distance_to(to)
		var posts := maxi(2, int(length / (px * 1.1)))
		_overlay.draw_line(from, to, WOOD_DARK, maxf(3.0, px * 0.22))
		_overlay.draw_line(from, to, WOOD, maxf(1.5, px * 0.12))
		for i in posts + 1:
			var p := from.lerp(to, float(i) / posts)
			_overlay.draw_circle(p, maxf(3.0, px * 0.2), WOOD_DARK)
		if signpost != null:
			var mid := from.lerp(to, 0.5)
			_overlay.draw_texture_rect(signpost, Rect2(mid - Vector2(SIGN_ICON * 0.5, SIGN_ICON * 0.9),
					Vector2(SIGN_ICON, SIGN_ICON)), false)
	var buoy := GameIcon.texture_for("buoy")
	for p in _buoys:
		var c := to_view(p)
		if buoy != null:
			# Şamandıranın alt ucu suyun üstündeki noktada.
			_overlay.draw_texture_rect(buoy, Rect2(c - Vector2(BUOY_ICON * 0.5, BUOY_ICON * 0.8),
					Vector2(BUOY_ICON, BUOY_ICON)), false)
			continue
		var r := maxf(6.0, px * 0.45)
		_overlay.draw_circle(c, r + 2.0, Color("#2b1a10"))
		_overlay.draw_circle(c, r, Color.WHITE)
		_overlay.draw_circle(c + Vector2(0, -r * 0.35), r * 0.62, BUOY)


## Bölge rozeti: simge, ad, kilitliyse nedeni ("Rütbe 5", "Sandalla"). Dokununca zone_pressed.
func _badge(id: String, open: bool, note: String, here: bool) -> Control:
	var b := _Badge.new()
	b.name = "Zone_" + id
	b.custom_minimum_size = BADGE_MIN
	var border := UiKit.SUCCESS if here else (UiKit.CREAM_EDGE if open else Color("#8d939b"))
	var fill := UiKit.CREAM_CARD if open else Color("#dfe3e7")
	var sb := UiKit.card_style(border, 26, Color(fill, 0.95), 6 if here else 4)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 4
	sb.content_margin_bottom = 6
	b.add_theme_stylebox_override("panel", sb)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 0)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(column)
	var top := HBoxContainer.new()
	top.alignment = BoxContainer.ALIGNMENT_CENTER
	top.add_theme_constant_override("separation", 4)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(top)
	var icon := GameIcon.make("zone:" + id, BADGE_ICON)
	if not open:
		icon.modulate = LOCKED_TINT
	top.add_child(icon)
	if not open:
		top.add_child(GameIcon.make("lock", 46))
	var title := tr("ZONE_" + id)
	top.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(UiKit.ink(title, UiKit.fit_size(title, UiKit.body_font(), 26, 230.0, 20), UiKit.INK,
			HORIZONTAL_ALIGNMENT_CENTER))
	if not note.is_empty():
		column.add_child(UiKit.ink(note, 22, Color("#a2471d"), HORIZONTAL_ALIGNMENT_CENTER))
	b.tapped.connect(func() -> void: zone_pressed.emit(id))
	return b


## Açılmış ama henüz gidilmemiş bölgenin rozetinin köşesinde "Yeni!" etiketi.
func _new_tag() -> Control:
	var pill := PanelContainer.new()
	var ps := UiKit.flat(UiKit.SUCCESS, 18)
	ps.content_margin_left = 12
	ps.content_margin_right = 12
	ps.border_color = Color("#14592f")
	ps.set_border_width_all(3)
	pill.add_theme_stylebox_override("panel", ps)
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill.rotation = deg_to_rad(8.0)
	pill.add_child(UiKit.title(tr("UI_MAP_NEW"), 22, UiKit.TEXT, HORIZONTAL_ALIGNMENT_CENTER, 5))
	return pill


## Dükkân, Dede, tuzak ya da şişe işareti: dükkân Ersin'in çıkartması (yoksa dükkân ikonu), Dede portresi
## (yoksa yok), kerevit tuzağı küçük tuzak resmi, Gölün Sırrı'nın şişesi. Sandal çıkartmadır (_add_stickers).
func _mark(kind: String) -> Control:
	match kind:
		"shop":
			var stall := ItemArt.map_art("map_shop")
			return _art_rect(stall, SHOP_STICKER) if stall != null else GameIcon.make("shop", MARK)
		"dede":
			var face := ItemArt.portrait("dede_smile")
			return _art_rect(face, MARK) if face != null else null
		"trap":
			return GameIcon.make("trap", TRAP_MARK)
		"bottle":
			return GameIcon.make("bottle", MARK)
		"secret_x":
			# Gölün Sırrı: dört parça tamam, Bekçi'nin yeri (derin ortanın ilk şamandırası).
			return GameIcon.make("x_mark", MARK)
	return null


## Görseli side boyunda, oranı korunarak çizen düğüm.
static func _art_rect(texture: Texture2D, side: float) -> TextureRect:
	var t := TextureRect.new()
	t.texture = texture
	t.custom_minimum_size = Vector2(side, side)
	t.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	t.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	t.mouse_filter = Control.MOUSE_FILTER_IGNORE
	t.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	return t


## Çıkartmalar (yerleşme sırasıyla): iskeledeki sandal, bölgelerin süsü, ormanda ağaç öbekleri, sol
## alt köşede pusula. Görseli olmayan çıkartma eklenmez.
func _add_stickers(spot_id: String, zones: Array[Dictionary], marks: Array[Dictionary]) -> void:
	for m in marks:
		if str(m["kind"]) == "boat":
			_add_sticker(ItemArt.map_art("map_boat"), BOAT_STICKER, m["pos"])
	for k in zones.size():
		var entry: Array = ZONE_STICKERS.get(str(zones[k]["id"]), [])
		if not entry.is_empty():
			var offset: Vector2 = entry[1]
			_add_sticker(ItemArt.map_art(str(entry[0])), STICKER, badge_anchor(lake, k, zones[k]) + offset)
	var trees := ItemArt.map_art("map_trees")
	if trees != null:
		for p in forest_points(spot_id, lake, region):
			_add_sticker(trees, STICKER, p)
	_add_sticker(GameIcon.texture_for("compass"), COMPASS, Vector2(region.position.x + 3.0, region.end.y - 3.0))


func _add_sticker(texture: Texture2D, side: float, at: Vector2) -> void:
	if texture == null:
		return
	var node := _art_rect(texture, side)
	add_child(node)
	_stickers.append([node, at])


## Ağaç çıkartmalarının yeri: haritanın ormanında (yürünmeyen kara, kıyıdan en az FOREST_SHORE
## metre) birbirine en uzak en çok TREES nokta, aralarında en az TREE_GAP metre. İlki haritanın sol
## üst köşesine en yakın aday. Göl değişmedikçe aynı.
static func forest_points(spot_id: String, shape: LakeShape, r: Rect2) -> PackedVector2Array:
	var cached: Array = _forest.get(spot_id, [])
	if not cached.is_empty() and cached[0] == shape:
		return cached[1]
	var candidates := PackedVector2Array()
	var step := 2.0
	for y in range(1, floori(r.size.y / step)):
		for x in range(1, floori(r.size.x / step)):
			var p := r.position + Vector2(x, y) * step
			if not shape.on_dock(p) and shape.land_distance(p) < -FOREST_SHORE and not shape.in_world(p):
				candidates.append(p)
	var picked := PackedVector2Array()
	if not candidates.is_empty():
		var first := 0
		for i in candidates.size():
			if candidates[i].distance_squared_to(r.position) < candidates[first].distance_squared_to(r.position):
				first = i
		picked.append(candidates[first])
		while picked.size() < TREES:
			var best := -1
			var best_d := TREE_GAP * TREE_GAP
			for i in candidates.size():
				var d := INF
				for q in picked:
					d = minf(d, candidates[i].distance_squared_to(q))
				if d >= best_d:
					best_d = d
					best = i
			if best < 0:
				break
			picked.append(candidates[best])
	_forest[spot_id] = [shape, picked]
	return picked


## Çıkartmalar rozetlere, "Yeni!" etiketlerine, iğneye, işaretlere ve birbirine binmez: yerinden
## başlayıp çevresindeki halkalarda harita alanının içindeki ilk boş yere kayar; yer yoksa gizlenir.
func _place_stickers(blocked: Array[Rect2]) -> void:
	var area := map_area()
	for s in _stickers:
		var node: Control = s[0]
		node.reset_size()
		var home := Rect2(to_view(s[1]) - node.size * 0.5, node.size)
		var spot := free_spot(home, blocked, area)
		node.visible = Dice.is_point(spot)
		if node.visible:
			node.position = spot
			blocked.append(Rect2(spot, node.size))


## r'nin yerine ya da çevresindeki halkalarda (halka arası r'nin 0,35'i, en çok RINGS halka) area'nın
## içinde blocked'a binmeyen ilk yer; yoksa Dice.NO_POINT. Görselin saydam payı (%8) binmeye sayılmaz.
static func free_spot(r: Rect2, blocked: Array[Rect2], area: Rect2) -> Vector2:
	var step := r.size.x * 0.35
	for ring in RINGS + 1:
		var count := 1 if ring == 0 else 8 + ring * 4
		for k in count:
			var c := Rect2(r.position + Vector2.from_angle(TAU * k / count) * step * ring, r.size)
			if not area.encloses(c):
				continue
			var core := c.grow(-c.size.x * 0.08)
			var fits := true
			for b in blocked:
				if core.intersects(b):
					fits = false
					break
			if fits:
				return c.position
	return Dice.NO_POINT


## "Buradasın": iğne ve altında yazısı; iğnenin ucu balıkçının yerinde.
func _here_pin() -> Control:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 2)
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var pin := GameIcon.make("pin", PIN)
	pin.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(pin)
	var pill := PanelContainer.new()
	var sb := UiKit.flat(Color(0.16, 0.09, 0.04, 0.85), 16)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	pill.add_theme_stylebox_override("panel", sb)
	pill.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill.add_child(UiKit.title(tr("UI_MAP_HERE"), 22, UiKit.ACCENT, HORIZONTAL_ALIGNMENT_CENTER, 5))
	column.add_child(pill)
	return column


## Dokunulabilen rozet: parmak kalkınca (rozetin üstündeyse) tapped; basılıyken biraz küçülür.
class _Badge extends PanelContainer:
	signal tapped

	var _down: bool = false

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _gui_input(event: InputEvent) -> void:
		var button := event as InputEventMouseButton
		if button == null or button.button_index != MOUSE_BUTTON_LEFT:
			return
		accept_event()
		if button.pressed:
			_down = true
			pivot_offset = size * 0.5
			scale = Vector2.ONE * 0.94
			return
		scale = Vector2.ONE
		if _down and Rect2(Vector2.ZERO, size).has_point(button.position):
			tapped.emit()
		_down = false
