class_name ShorePath
extends RefCounted
## Kıyı yolu (docs/gdd.md §10.1 "Yürüme"): balıkçı dokunulan yere sudan geçmeden varır. Yürünebilen
## dünyada (LakeShape.is_walkable) 0,5 m'lik ızgarada Godot'nun hazır A*'ı (AStarGrid2D) yol bulur:
## su, dünyanın dışı, kapalı çitler (kilitli bölgeler) ve engeller (dükkân, kamp, Dede, büyük ağaç
## ve kayalar) geçilmez. Kıyıya yakın kara ucuz: yol kıyıyı izler. Düz çizgi açıksa düz yürünür;
## değilse A* yolu gerilir (görülebilen en uzak noktaya düz parçalar).

## Izgara aralığı (m).
const CELL := 0.5
## Hücre merkezi kıyıya en az bu kadar uzak olmalı (balıkçının gövdesi suya taşmasın).
const SHORE_CLEAR := 0.3
## Bu banttaki kara (kıyıdan metre) ucuz; daha içerisi INLAND kat pahalı.
const SHORE_BAND := Vector2(0.3, 2.6)
const INLAND := 1.6
## Balıkçının gövde payı (Angler.BODY ile aynı).
const BODY := 0.22
## Çitin kalınlığı (m; iki yanına).
const GATE_HALF := 0.4
## Dokunulan yer yürünemiyorsa en yakın yürünebilir hücre bu kadar hücre içinde aranır.
const SEARCH := 24

var lake: LakeShape
## Izgaranın kapladığı alan (dünya).
var area := Rect2()
var _grid := AStarGrid2D.new()
var _cols: int = 0
var _rows: int = 0
## Hücre başına: gölün izin verdiği (1) ve engeller ile çitlerden sonra yürünebilen (1).
var _base := PackedByteArray()
var _open := PackedByteArray()
var _circles: Array[Vector3] = []
## Çit kimliği -> [a, b, kapalı mı].
var _gates: Dictionary = {}


## area: yolun arandığı dünya kutusu (yoksa gölün çevresi).
func _init(shape: LakeShape, bounds: Rect2 = Rect2()) -> void:
	lake = shape
	area = bounds
	if area.size.x <= 0.0 or area.size.y <= 0.0:
		area = shape.water_bounds.grow(12.0)
	_cols = maxi(1, ceili(area.size.x / CELL))
	_rows = maxi(1, ceili(area.size.y / CELL))
	_grid.region = Rect2i(0, 0, _cols, _rows)
	_grid.cell_size = Vector2(CELL, CELL)
	_grid.offset = area.position + Vector2(CELL, CELL) * 0.5
	_grid.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
	_grid.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	_grid.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
	_grid.update()
	_base.resize(_cols * _rows)
	for y in _rows:
		for x in _cols:
			var p := _center(x, y)
			var walk := lake.on_dock(p) or (lake.is_walkable(p) and lake.shore_distance(p) <= -SHORE_CLEAR)
			_base[y * _cols + x] = 1 if walk else 0
			if walk and not lake.on_dock(p):
				var shore := -lake.shore_distance(p)
				if shore < SHORE_BAND.x or shore > SHORE_BAND.y:
					_grid.set_point_weight_scale(Vector2i(x, y), INLAND)
	_apply()


## Kalıcı engeller (daireler: x, z, yarıçap); öncekilerin yerine.
func set_obstacles(circles: Array[Vector3]) -> void:
	_circles = circles.duplicate()
	_apply()


## Çit: a'dan b'ye; kapalıyken geçilmez.
func set_gate(id: String, a: Vector2, b: Vector2, closed: bool) -> void:
	_gates[id] = [a, b, closed]
	_apply()


func gate_closed(id: String) -> bool:
	return _gates.has(id) and bool((_gates[id] as Array)[2])


## from'dan to'ya yürüme yolu (from hariç, sıralı noktalar). to yürünemiyorsa (su, orman, engel)
## en yakın yürünebilir noktaya; varılamıyorsa (kapalı çit) varılabilen en yakın yere kadar.
## Yol yoksa boş.
func route(from: Vector2, to: Vector2) -> PackedVector2Array:
	var goal := nearest_open(to)
	if not Dice.is_point(goal):
		return PackedVector2Array()
	if clear_line(from, goal):
		return PackedVector2Array([goal])
	var start := _nearest_cell(from)
	var end := _nearest_cell(goal)
	if start.x < 0 or end.x < 0:
		return PackedVector2Array()
	var raw := _grid.get_point_path(start, end, true)
	if raw.is_empty():
		return PackedVector2Array()
	var reached := raw[raw.size() - 1].distance_to(_center(end.x, end.y)) < 0.01
	if reached:
		raw[raw.size() - 1] = goal
	return _pull(from, raw)


## Noktadan gidilebilen en yakın yürünebilir yer (kendisi yürünebilirse kendisi).
func nearest_open(p: Vector2) -> Vector2:
	if _is_open_point(p):
		return p
	var cell := _nearest_cell(p)
	return _center(cell.x, cell.y) if cell.x >= 0 else Dice.NO_POINT


## a'dan b'ye düz çizgi açık mı (ızgarada; yarım hücre aralıkla)?
func clear_line(a: Vector2, b: Vector2) -> bool:
	var count := maxi(1, ceili(a.distance_to(b) / (CELL * 0.5)))
	for i in range(1, count + 1):
		if not _is_open_point(a.lerp(b, float(i) / count)):
			return false
	return true


## Yolun uzunluğu (from'dan başlayarak).
static func length_of(from: Vector2, points: PackedVector2Array) -> float:
	var total := 0.0
	var prev := from
	for p in points:
		total += prev.distance_to(p)
		prev = p
	return total


# --- İç işler ----------------------------------------------------------------------

func _center(x: int, y: int) -> Vector2:
	return area.position + Vector2((x + 0.5) * CELL, (y + 0.5) * CELL)


func _cell_of(p: Vector2) -> Vector2i:
	return Vector2i(floori((p.x - area.position.x) / CELL), floori((p.y - area.position.y) / CELL))


func _is_open_point(p: Vector2) -> bool:
	var c := _cell_of(p)
	if c.x < 0 or c.y < 0 or c.x >= _cols or c.y >= _rows:
		return false
	return _open[c.y * _cols + c.x] == 1


## Noktanın hücresi açıksa o, değilse en yakın açık hücre (halka halka aranır; yoksa (-1, -1)).
func _nearest_cell(p: Vector2) -> Vector2i:
	var c := _cell_of(p)
	var best := Vector2i(-1, -1)
	var best_d := INF
	for r in SEARCH + 1:
		for y in range(c.y - r, c.y + r + 1):
			for x in range(c.x - r, c.x + r + 1):
				if maxi(absi(x - c.x), absi(y - c.y)) != r:
					continue
				if x < 0 or y < 0 or x >= _cols or y >= _rows or _open[y * _cols + x] == 0:
					continue
				var d := _center(x, y).distance_squared_to(p)
				if d < best_d:
					best_d = d
					best = Vector2i(x, y)
		# Bu halkada bulunduysa bir sonrakinde daha yakını olamaz (yarım hücre payıyla bir halka daha).
		if best.x >= 0 and r > 0 and float(r - 1) * CELL > sqrt(best_d):
			break
	return best


## Engeller ve kapalı çitlerle yürünebilen hücreleri yeniden kurar.
func _apply() -> void:
	_open = _base.duplicate()
	for c in _circles:
		_mark_circle(Vector2(c.x, c.y), c.z + BODY)
	for id: String in _gates:
		var g: Array = _gates[id]
		if bool(g[2]):
			_mark_segment(g[0], g[1], GATE_HALF)
	for y in _rows:
		for x in _cols:
			_grid.set_point_solid(Vector2i(x, y), _open[y * _cols + x] == 0)


func _mark_circle(center: Vector2, radius: float) -> void:
	var cells := Rect2i(_cell_of(center - Vector2(radius, radius)), Vector2i.ZERO).expand(_cell_of(center + Vector2(radius, radius)) + Vector2i.ONE)
	for y in range(maxi(0, cells.position.y), mini(_rows, cells.end.y + 1)):
		for x in range(maxi(0, cells.position.x), mini(_cols, cells.end.x + 1)):
			if _center(x, y).distance_to(center) <= radius:
				_open[y * _cols + x] = 0


func _mark_segment(a: Vector2, b: Vector2, half: float) -> void:
	var low := Vector2(minf(a.x, b.x), minf(a.y, b.y)) - Vector2(half, half)
	var high := Vector2(maxf(a.x, b.x), maxf(a.y, b.y)) + Vector2(half, half)
	var c0 := _cell_of(low)
	var c1 := _cell_of(high)
	for y in range(maxi(0, c0.y), mini(_rows, c1.y + 1)):
		for x in range(maxi(0, c0.x), mini(_cols, c1.x + 1)):
			var p := _center(x, y)
			if Geometry2D.get_closest_point_to_segment(p, a, b).distance_to(p) <= half + CELL * 0.5:
				_open[y * _cols + x] = 0


## Yolu gerer: bulunulan yerden görülebilen en uzak yol noktasına düz parça, oradan devam.
func _pull(from: Vector2, raw: PackedVector2Array) -> PackedVector2Array:
	var out := PackedVector2Array()
	var current := from
	var i := 0
	while i < raw.size():
		var far := i
		for j in range(i + 1, raw.size()):
			if clear_line(current, raw[j]):
				far = j
			elif j > far + 6:
				break
		current = raw[far]
		out.append(current)
		i = far + 1
	return out
