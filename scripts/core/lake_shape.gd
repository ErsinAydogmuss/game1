class_name LakeShape
extends RefCounted
## Gölün şekli: elipslerin birleşimi ve suyun üstündeki iskele. Kıyıya uzaklık (işaretli:
## suda +, karada −) bir ızgarada bir kez hesaplanır (CELL metre aralıkla); derinlik ondan
## türetilir. Arazi ve su shader'ı aynı ızgaradan üretilen dokuyu kullanır (5. adım):
## R = derinlik, G = kıyıya uzaklık.
## Koordinatlar dünya x/z metredir (Vector2(x, z)); su yüzeyi y = 0.

const CELL := 0.25
## Izgara suyun çevresinde bu kadar kara payı bırakır.
const MARGIN := 4.0

## Elipsler: { center: Vector2, radius: Vector2, cos: float, sin: float }.
var ellipses: Array[Dictionary] = []
var dock := Rect2()
var max_depth: float = 3.5
## Derinlik kıyıdan bu kadar metrede en derine iner.
var shelf: float = 4.0
## Elipslerin kapladığı alan.
var water_bounds := Rect2()
## Izgaranın sol üst köşesi ve boyutu (hücre).
var origin := Vector2.ZERO
var width: int = 0
var height: int = 0
## Hücre merkezlerinde işaretli kıyı uzaklığı (m).
var shore: PackedFloat32Array = PackedFloat32Array()


## spot: ContentDB'deki atış noktası (ellipses, dock, max_depth, shelf_m).
static func from_spot(spot: Dictionary) -> LakeShape:
	var lake := LakeShape.new()
	for e: Dictionary in spot.get("ellipses", []):
		var angle: float = e.get("angle", 0.0)
		lake.ellipses.append({
			"center": e["center"], "radius": e["radius"], "cos": cos(angle), "sin": sin(angle),
		})
	lake.dock = spot.get("dock", Rect2())
	lake.max_depth = float(spot.get("max_depth", 3.5))
	lake.shelf = maxf(0.5, float(spot.get("shelf_m", 4.0)))
	lake._build()
	return lake


## Nokta suyun içinde mi (elipslerden birinde)? İskelenin altı da sudur.
func is_water(p: Vector2) -> bool:
	for e in ellipses:
		var q: Vector2 = p - (e["center"] as Vector2)
		var c: float = e["cos"]
		var s: float = e["sin"]
		var r: Vector2 = e["radius"]
		var lx := (q.x * c + q.y * s) / r.x
		var ly := (-q.x * s + q.y * c) / r.y
		if lx * lx + ly * ly <= 1.0:
			return true
	return false


## İskelenin üstünde mi (margin kadar genişletilmiş)?
func on_dock(p: Vector2, margin: float = 0.0) -> bool:
	return dock.size.x > 0.0 and dock.grow(margin).has_point(p)


## Balıkçı burada durabilir mi (kara ya da iskele)?
func is_walkable(p: Vector2) -> bool:
	return on_dock(p) or not is_water(p)


## İşaretli kıyı uzaklığı (m): suda +, karada −. Izgaradan çift doğrusal örnekleme.
func shore_distance(p: Vector2) -> float:
	var gx := (p.x - origin.x) / CELL - 0.5
	var gy := (p.y - origin.y) / CELL - 0.5
	if gx < -1.0 or gy < -1.0 or gx > width or gy > height:
		return -MARGIN
	var x0 := clampi(floori(gx), 0, width - 1)
	var y0 := clampi(floori(gy), 0, height - 1)
	var x1 := mini(x0 + 1, width - 1)
	var y1 := mini(y0 + 1, height - 1)
	var fx := clampf(gx - x0, 0.0, 1.0)
	var fy := clampf(gy - y0, 0.0, 1.0)
	var top := lerpf(shore[y0 * width + x0], shore[y0 * width + x1], fx)
	var bottom := lerpf(shore[y1 * width + x0], shore[y1 * width + x1], fx)
	return lerpf(top, bottom, fy)


## Derinlik (m): karada 0; kıyıdan uzaklaştıkça yumuşakça max_depth'e iner.
func depth_at(p: Vector2) -> float:
	return depth_for(shore_distance(p))


func depth_for(shore_dist: float) -> float:
	if shore_dist <= 0.0:
		return 0.0
	return max_depth * smoothstep(0.0, shelf, shore_dist)


## Gölgelerin dolaşabileceği yer: en az min_depth derin ve iskeleden uzak.
func is_deep(p: Vector2, min_depth: float) -> bool:
	return depth_at(p) >= min_depth and not on_dock(p, 0.6)


## a'dan b'ye düz yol baştan sona derin suda mı (0,4 m aralıkla bakılır)?
func segment_is_deep(a: Vector2, b: Vector2, min_depth: float) -> bool:
	var count := maxi(1, ceili(a.distance_to(b) / 0.4))
	for i in count + 1:
		if not is_deep(a.lerp(b, float(i) / count), min_depth):
			return false
	return true


## Şamandıranın düşeceği yer: from'dan target'a giden çizgide, menzilin içinde kalan en uzak su
## noktası (kıyıya en az min_shore, iskeleye değmez). Hedef karadaysa ya da menzil dışındaysa
## şamandıra yine suya düşer. Çizgide hiç su yoksa Dice.NO_POINT.
func landing_point(from: Vector2, target: Vector2, max_range: float, min_shore: float) -> Vector2:
	var offset := target - from
	var length := offset.length()
	if length < 0.001:
		return Dice.NO_POINT
	var dir := offset / length
	var d := minf(length, max_range)
	while d >= 0.5:
		var p := from + dir * d
		if is_water(p) and not on_dock(p, 0.2) and shore_distance(p) >= min_shore:
			return p
		d -= 0.1
	return Dice.NO_POINT


## Izgaradaki bir hücrenin merkezi (dünya).
func cell_center(x: int, y: int) -> Vector2:
	return origin + Vector2((x + 0.5) * CELL, (y + 0.5) * CELL)


# --- Kurulum ------------------------------------------------------------------------

func _build() -> void:
	water_bounds = Rect2()
	var first := true
	for e in ellipses:
		var r: Vector2 = e["radius"]
		var c: float = e["cos"]
		var s: float = e["sin"]
		# Döndürülmüş elipsin sınır kutusu.
		var half := Vector2(sqrt(pow(r.x * c, 2) + pow(r.y * s, 2)), sqrt(pow(r.x * s, 2) + pow(r.y * c, 2)))
		var box := Rect2((e["center"] as Vector2) - half, half * 2.0)
		water_bounds = box if first else water_bounds.merge(box)
		first = false
	origin = water_bounds.position - Vector2(MARGIN, MARGIN)
	width = maxi(1, ceili((water_bounds.size.x + MARGIN * 2.0) / CELL))
	height = maxi(1, ceili((water_bounds.size.y + MARGIN * 2.0) / CELL))
	var inside := PackedByteArray()
	inside.resize(width * height)
	for y in height:
		for x in width:
			inside[y * width + x] = 1 if is_water(cell_center(x, y)) else 0
	# Su hücreleri için en yakın kara hücresine, kara hücreleri için en yakın su hücresine
	# uzaklık; sınır iki hücre merkezinin ortasındadır (yarım hücre düşülür).
	var to_land := _distance_field(inside, 0)
	var to_water := _distance_field(inside, 1)
	shore.resize(width * height)
	for y in height:
		for x in width:
			var i := y * width + x
			var grid := maxf(0.0, to_land[i] * CELL - CELL * 0.5) if inside[i] == 1 \
					else -maxf(0.0, to_water[i] * CELL - CELL * 0.5)
			# Kıyıya yakın yerde elips formülü (pürüzsüz kıyı çizgisi), uzakta ızgara uzaklığı.
			var exact := _ellipse_distance(cell_center(x, y))
			shore[i] = lerpf(exact, grid, smoothstep(0.5, 1.0, absf(exact)))


## Elipslerin birleşimine işaretli uzaklık tahmini; kıyının yakınında doğru, uzakta kaba.
## Her elips için g / |∇g| (g = 1 − (lx² + ly²), lx ve ly elipsin kendi ekseninde
## yarıçapa bölünmüş konum); birleşim için en büyüğü.
func _ellipse_distance(p: Vector2) -> float:
	var best := -INF
	for e in ellipses:
		var q: Vector2 = p - (e["center"] as Vector2)
		var c: float = e["cos"]
		var s: float = e["sin"]
		var r: Vector2 = e["radius"]
		var lx := (q.x * c + q.y * s) / r.x
		var ly := (-q.x * s + q.y * c) / r.y
		var g := 1.0 - (lx * lx + ly * ly)
		var grad := 2.0 * sqrt((lx / r.x) * (lx / r.x) + (ly / r.y) * (ly / r.y))
		best = maxf(best, g / maxf(grad, 0.0001))
	return best


## Her hücreden mask değeri `seed_value` olan en yakın hücreye uzaklık (hücre biriminde).
## 8SSEDT: iki geçişte en yakın tohumun ofseti komşulardan aktarılır.
func _distance_field(mask: PackedByteArray, seed_value: int) -> PackedFloat32Array:
	var n := width * height
	var ox := PackedInt32Array()
	var oy := PackedInt32Array()
	ox.resize(n)
	oy.resize(n)
	var far := 1 << 20
	for i in n:
		var is_seed := mask[i] == seed_value
		ox[i] = 0 if is_seed else far
		oy[i] = 0 if is_seed else far
	for y in height:
		for x in width:
			_relax(ox, oy, x, y, -1, 0)
			_relax(ox, oy, x, y, 0, -1)
			_relax(ox, oy, x, y, -1, -1)
			_relax(ox, oy, x, y, 1, -1)
		for x in range(width - 1, -1, -1):
			_relax(ox, oy, x, y, 1, 0)
	for y in range(height - 1, -1, -1):
		for x in range(width - 1, -1, -1):
			_relax(ox, oy, x, y, 1, 0)
			_relax(ox, oy, x, y, 0, 1)
			_relax(ox, oy, x, y, -1, 1)
			_relax(ox, oy, x, y, 1, 1)
		for x in width:
			_relax(ox, oy, x, y, -1, 0)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		out[i] = sqrt(float(ox[i] * ox[i] + oy[i] * oy[i]))
	return out


## (x, y) hücresinin en yakın tohumunu, (x+dx, y+dy) komşusunun tohumuyla karşılaştırır.
func _relax(ox: PackedInt32Array, oy: PackedInt32Array, x: int, y: int, dx: int, dy: int) -> void:
	var nx := x + dx
	var ny := y + dy
	if nx < 0 or ny < 0 or nx >= width or ny >= height:
		return
	var j := ny * width + nx
	var cx := ox[j] + dx
	var cy := oy[j] + dy
	var i := y * width + x
	if cx * cx + cy * cy < ox[i] * ox[i] + oy[i] * oy[i]:
		ox[i] = cx
		oy[i] = cy
