class_name TrapBadge
extends Control
## Tuzağın dolma rozeti (TrapMarkers): şamandıranın üstünde küçük bir hap: kerevit resmi ve "2/4".
## Boşken soluk; içinde kerevit varken altın, dolunca yeşil ve hafifçe nabız gibi atar. Sahnenin ton
## eşlemesi soldurmasın diye arayüz gibi 2B çizilir; TrapMarkers her kare 3B noktayı ekrana taşır
## (anchor: hapın altındaki ucun ekrandaki yeri). Süreler _process(delta) toplamıyla.

## Hapın boyu ve altındaki ucun yüksekliği (viewport birimi).
const SIZE := Vector2(150, 66)
const TAIL := 14.0
const FONT_SIZE := 38

## Ucun ekrandaki yeri.
var anchor := Vector2.ZERO
var count: int = 0
var most: int = 4

var _art: Texture2D
var _box := StyleBoxFlat.new()
var _clock: float = 0.0


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = SIZE + Vector2(0.0, TAIL)
	pivot_offset = Vector2(SIZE.x * 0.5, SIZE.y + TAIL)
	_art = ItemArt.item("crayfish")
	_box.set_corner_radius_all(int(SIZE.y * 0.5))
	_box.set_border_width_all(4)
	_box.bg_color = Color(0.12, 0.08, 0.04, 0.86)


func set_count(n: int, cap: int) -> void:
	if n == count and cap == most:
		return
	count = n
	most = cap
	queue_redraw()


func is_full() -> bool:
	return count >= most


func _process(delta: float) -> void:
	if not visible:
		return
	_clock += delta
	scale = Vector2.ONE * (1.0 + (0.07 * sin(_clock * 5.0) if is_full() else 0.0))
	position = anchor - pivot_offset


func _draw() -> void:
	var full := is_full()
	var edge := UiKit.SUCCESS if full else (UiKit.ACCENT if count > 0 else Color(1, 1, 1, 0.55))
	_box.border_color = edge
	draw_colored_polygon(PackedVector2Array([Vector2(SIZE.x * 0.5 - TAIL, SIZE.y - 4.0),
			Vector2(SIZE.x * 0.5 + TAIL, SIZE.y - 4.0), Vector2(SIZE.x * 0.5, SIZE.y + TAIL)]), edge)
	draw_style_box(_box, Rect2(Vector2.ZERO, SIZE))
	var icon := Rect2(Vector2(8.0, 5.0), Vector2(56.0, 56.0))
	if _art != null:
		draw_texture_rect(_art, icon, false, Color(1, 1, 1, 1.0 if count > 0 else 0.6))
	else:
		draw_circle(icon.get_center(), 22.0, Color("#c8553d"))
	var font := UiKit.display_font()
	var baseline := (SIZE.y + font.get_ascent(FONT_SIZE) - font.get_descent(FONT_SIZE)) * 0.5
	var color := UiKit.SUCCESS.lightened(0.3) if full else (UiKit.ACCENT if count > 0 else Color(1, 1, 1, 0.8))
	draw_string(font, Vector2(70.0, baseline), "%d/%d" % [count, most], HORIZONTAL_ALIGNMENT_LEFT, SIZE.x - 76.0,
			FONT_SIZE, color)
