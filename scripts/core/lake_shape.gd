class_name LakeShape
extends RefCounted
## Gölün şekli: havzaların (elips) birleşimi ve suyun üstündeki iskele. Kıyıya uzaklık (işaretli:
## suda +, karada −), derinlik ve bölge bir ızgarada bir kez hesaplanır (CELL metre aralıkla) ve
## user://cache'e yazılır; gölün tanımı ya da kurulum (BUILD_VERSION) değişince yeniden hesaplanır.
##
## Havza: elips + kendi derinliği (max_depth) ve kıyı eğimi (shelf: kıyıdan bu kadar metrede en
## derine iner) + bölgesi. Havzaların birleştiği yerde derinlik ±BLEND metrelik bantta yumuşakça
## geçer. Bölge: su hücresinin en çok içinde kaldığı havzanın bölgesi; sandal bölgesi (boat_from)
## yalnızca kıyıdan boat_from metre içerideki hücreleri alır (kıyıya değmez). Kara hücresinin
## bölgesi en yakın suyunki (kıyıda duran balıkçının bölgesi).
##
## Arazi ve su shader'ı aynı ızgaradan üretilen dokuyu kullanır (LakeTexture).
## Koordinatlar dünya x/z metredir (Vector2(x, z)); su yüzeyi y = 0.

const CELL := 0.25
## Izgara suyun çevresinde bu kadar kara payı bırakır.
const MARGIN := 4.0
## Havza derinliklerinin karıştığı bant (m): havzanın kenarının iki yanında.
const BLEND := 1.5
## Kıyıya bu kadar yakın hücrelerde uzaklık elips formülünden (pürüzsüz kıyı), uzakta ızgaradan.
const EXACT_BAND := 1.25
## Izgara kurulumunun sürümü: kurulum (kıyı, derinlik, bölge) değişince artır, önbellek yenilensin.
const BUILD_VERSION := 1
const CACHE_DIR := "user://cache"
## Bölgesi olmayan hücre (ızgarada; zone_at -1 döner).
const NO_ZONE := 255
## Akıntının, akıntılı havzanın kenarından dışarıda söndüğü uzaklık (m) ve tam güçte aktığı
## havza genişliği (en kısa yarıçap, m): geniş havzada akıntı yavaşlar (aynı su geniş yerde yayılır).
const FLOW_FADE := 2.0
const FLOW_NARROW := 1.6

## Havzalar: { center, radius, cos, sin, max_depth, shelf, zone (sıra), boat_from (sandal
## bölgesi değilse -1) }.
var basins: Array[Dictionary] = []
## Havza başına akıntı (bölgesinin "current"i: yön ve güç; akıntısız havzada sıfır). Izgaraya
## girmez (önbelleğin özetinde yok).
var flows: PackedVector2Array = PackedVector2Array()
var dock := Rect2()
## Yürünebilen dünya: bu kutunun içi ve suya en çok world_band metre uzaklık (ormanın kenarı).
## Tanımsızsa (eski şema) sınırsız.
var world_rect := Rect2(-1e6, -1e6, 2e6, 2e6)
var world_band: float = INF
## Gölün en derin havzasının derinliği (veri dokusu bununla ölçeklenir).
var max_depth: float = 3.5
## Bütün havzaların derinlik profili aynıysa (eski şema, tek profil) derinlik bugünkü gibi kıyı
## uzaklığından hesaplanır; değilse derinlik ızgarasından.
var uniform: bool = true
## Tek profilli gölde derinliğin kıyıdan indiği mesafe.
var shelf: float = 4.0
## Elipslerin kapladığı alan.
var water_bounds := Rect2()
## Izgaranın sol üst köşesi ve boyutu (hücre).
var origin := Vector2.ZERO
var width: int = 0
var height: int = 0
## Hücre merkezlerinde işaretli kıyı uzaklığı (m), derinlik (m) ve bölge sırası.
var shore: PackedFloat32Array = PackedFloat32Array()
var depth: PackedFloat32Array = PackedFloat32Array()
var zone_grid: PackedByteArray = PackedByteArray()
## Bölge kimlikleri (sıra = zone_grid'deki değer), su hücrelerinin kutusu ve ağırlık merkezi.
var zone_ids: PackedStringArray = PackedStringArray()
var zone_bounds: Array[Rect2] = []
var zone_centers: PackedVector2Array = PackedVector2Array()
## Izgara önbellekten mi geldi (test ve ölçüm)?
var from_cache: bool = false

## Elipsler, hızlı erişim için (sözlükten okumak yavaş): merkez, yarıçap, havza başına cos ve sin.
## Hesap eski kurulumla aynı sırada ve aynı duyarlıkta yapılır (Vector2 farkı, float bölme):
## eski göllerin ızgarası bit bit aynı kalır, gölgelerin yolu kaymaz.
var _centers: PackedVector2Array = PackedVector2Array()
var _radii: PackedVector2Array = PackedVector2Array()
var _cs: PackedFloat64Array = PackedFloat64Array()


## spot: ContentDB'deki atış noktası (basins, zones, dock). use_cache: ızgara user://cache'ten
## okunsun ve yazılsın (kimliksiz gölde kullanılmaz).
static func from_spot(spot: Dictionary, use_cache: bool = true) -> LakeShape:
	var lake := LakeShape.new()
	var zones: Array = spot.get("zones", [])
	var order := {}
	for z: Variant in zones:
		var zd: Dictionary = z
		order[str(zd["id"])] = lake.zone_ids.size()
		lake.zone_ids.append(str(zd["id"]))
	var first := true
	for b: Variant in spot.get("basins", []):
		var bd: Dictionary = b
		var angle: float = bd.get("angle", 0.0)
		var zi := int(order.get(str(bd.get("zone", "")), NO_ZONE))
		var zd: Dictionary = zones[zi] if zi < zones.size() else {}
		var basin := {
			"center": bd["center"], "radius": bd["radius"], "cos": cos(angle), "sin": sin(angle),
			"max_depth": float(bd.get("max_depth", 3.5)), "shelf": maxf(0.5, float(bd.get("shelf_m", 4.0))),
			"zone": zi, "boat_from": float(zd.get("boat_from", 5.0)) if bool(zd.get("boat", false)) else -1.0,
		}
		if first:
			lake.max_depth = basin["max_depth"]
			lake.shelf = basin["shelf"]
		elif float(basin["max_depth"]) != lake.max_depth or float(basin["shelf"]) != lake.shelf:
			lake.uniform = false
		lake.max_depth = maxf(lake.max_depth, basin["max_depth"])
		lake.basins.append(basin)
		var current: Variant = zd.get("current", Vector2.ZERO)
		lake.flows.append(current if current is Vector2 else Vector2.ZERO)
		first = false
	lake.dock = spot.get("dock", Rect2())
	var world: Rect2 = spot.get("world_rect", Rect2())
	if world.size.x > 0.0 and world.size.y > 0.0:
		lake.world_rect = world
	lake.world_band = float(spot.get("world_band", INF))
	lake._prepare()
	var id := str(spot.get("id", ""))
	var path := lake._cache_path(id) if use_cache and not id.is_empty() else ""
	if path.is_empty() or not lake._load_cache(path):
		lake._build()
		if not path.is_empty():
			lake._save_cache(path, id)
	return lake


## Nokta suyun içinde mi (havzalardan birinde)? İskelenin altı da sudur.
func is_water(p: Vector2) -> bool:
	for b in basins.size():
		if _inside(b, p):
			return true
	return false


## İskelenin üstünde mi (margin kadar genişletilmiş)?
func on_dock(p: Vector2, margin: float = 0.0) -> bool:
	return dock.size.x > 0.0 and dock.grow(margin).has_point(p)


## İskeleye uzaklık (m); iskelenin üstünde 0, iskele yoksa INF.
func dock_distance(p: Vector2) -> float:
	if dock.size.x <= 0.0:
		return INF
	var half := dock.size * 0.5
	var q := (p - dock.get_center()).abs() - half
	return Vector2(maxf(q.x, 0.0), maxf(q.y, 0.0)).length()


## Balıkçı burada durabilir mi (dünyanın içinde kara ya da iskele)?
func is_walkable(p: Vector2) -> bool:
	return on_dock(p) or (not is_water(p) and in_world(p))


## Nokta yürünebilen dünyanın içinde mi (kutunun içi ve ormanın kenarına kadar)?
func in_world(p: Vector2) -> bool:
	return world_rect.has_point(p) and (world_band == INF or land_distance(p) >= -world_band)


## İşaretli kıyı uzaklığı (m): suda +, karada −. Izgaradan çift doğrusal örnekleme.
func shore_distance(p: Vector2) -> float:
	return _sample(shore, p, -MARGIN)


## İşaretli kıyı uzaklığı, ızgaranın dışında da (karada −): dışarıdaki noktaya ızgaranın en yakın
## noktasının uzaklığı ile ızgaraya olan uzaklığı birlikte verilir. shore_distance ızgaranın dışında
## (kıyıdan MARGIN metre öte) hep −MARGIN verir; kıyıdan uzaklık bantları (ağaçlar, korular) gerçek
## uzaklık ister.
func land_distance(p: Vector2) -> float:
	var low := origin + Vector2(CELL, CELL) * 0.5
	var high := origin + Vector2(width - 0.5, height - 0.5) * CELL
	var q := p.clamp(low, high)
	return shore_distance(q) - p.distance_to(q)


## Derinlik (m): karada 0; kıyıdan uzaklaştıkça yumuşakça havzanın derinliğine iner.
func depth_at(p: Vector2) -> float:
	if uniform:
		return depth_for(shore_distance(p))
	return maxf(0.0, _sample(depth, p, 0.0))


## Tek profilli gölde kıyı uzaklığına göre derinlik.
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


## Noktanın bölgesi (sıra; ızgaranın dışında -1). Suda o suyun bölgesi, karada en yakın suyunki.
func zone_at(p: Vector2) -> int:
	var x := floori((p.x - origin.x) / CELL)
	var y := floori((p.y - origin.y) / CELL)
	if x < 0 or y < 0 or x >= width or y >= height:
		return -1
	var z := zone_grid[y * width + x]
	return -1 if z == NO_ZONE else z


## Noktanın bölgesi, ızgaranın dışında da (en yakın ızgara hücresininki; uzak orman ve tepeler).
func zone_of(p: Vector2) -> int:
	var low := origin + Vector2(CELL, CELL) * 0.5
	var high := origin + Vector2(width - 0.5, height - 0.5) * CELL
	return zone_at(p.clamp(low, high))


## Bölge kimliğinin sırası (yoksa -1).
func zone_index(id: String) -> int:
	return zone_ids.find(id)


## Akıntı (yön ve güç): akıntılı bölgenin havzasında bölgenin akıntısı; dar havzada tam güç,
## geniş havzada (en kısa yarıçapı FLOW_NARROW'dan büyük) zayıf; havzanın dışında FLOW_FADE
## metrede söner. Akıntısız yerde sıfır. Şimdilik görsel (suyun akışı); Dalga 3'te sinek
## akıntıyla sürüklenir.
func flow_at(p: Vector2) -> Vector2:
	var best := Vector2.ZERO
	for b in flows.size():
		var flow := flows[b]
		if flow == Vector2.ZERO:
			continue
		var narrow := minf(1.0, FLOW_NARROW / minf(_radii[b].x, _radii[b].y))
		var k := smoothstep(-FLOW_FADE, 0.5, _basin_distance(b, p)) * narrow * narrow * narrow
		if k * flow.length() > best.length():
			best = flow * k
	return best


## Göldeki en güçlü akıntı (yoksa sıfır).
func strongest_flow() -> Vector2:
	var best := Vector2.ZERO
	for flow in flows:
		if flow.length() > best.length():
			best = flow
	return best


## Akıntılı havzaların kutusu, sönme payıyla (akıntının olabileceği yer; akıntı yoksa boş).
func flow_bounds() -> Rect2:
	var out := Rect2()
	for b in flows.size():
		if flows[b] == Vector2.ZERO:
			continue
		var box := _basin_box(b).grow(FLOW_FADE)
		out = box if out.size == Vector2.ZERO else out.merge(box)
	return out


## Izgaradaki bir hücrenin merkezi (dünya).
func cell_center(x: int, y: int) -> Vector2:
	return origin + Vector2((x + 0.5) * CELL, (y + 0.5) * CELL)


# --- Kurulum ------------------------------------------------------------------------

## Elipsleri paketler, su kutusunu ve ızgaranın boyutunu bulur.
func _prepare() -> void:
	_centers.resize(basins.size())
	_radii.resize(basins.size())
	_cs.resize(basins.size() * 2)
	water_bounds = Rect2()
	for b in basins.size():
		var basin := basins[b]
		_centers[b] = basin["center"]
		_radii[b] = basin["radius"]
		_cs[b * 2] = basin["cos"]
		_cs[b * 2 + 1] = basin["sin"]
		var box := _basin_box(b)
		water_bounds = box if b == 0 else water_bounds.merge(box)
	origin = water_bounds.position - Vector2(MARGIN, MARGIN)
	width = maxi(1, ceili((water_bounds.size.x + MARGIN * 2.0) / CELL))
	height = maxi(1, ceili((water_bounds.size.y + MARGIN * 2.0) / CELL))


func _build() -> void:
	var n := width * height
	# Su maskesi: her elips yalnızca kendi kutusundaki hücrelere bakar.
	var inside := PackedByteArray()
	inside.resize(n)
	for b in basins.size():
		var cells := _cell_range(_basin_box(b))
		for y in range(cells.position.y, cells.end.y):
			for x in range(cells.position.x, cells.end.x):
				var i := y * width + x
				if inside[i] == 0 and _inside(b, cell_center(x, y)):
					inside[i] = 1
	# Su hücreleri için en yakın kara hücresine, kara hücreleri için en yakın su hücresine
	# uzaklık; sınır iki hücre merkezinin ortasındadır (yarım hücre düşülür).
	var land_x := PackedInt32Array()
	var land_y := PackedInt32Array()
	var water_x := PackedInt32Array()
	var water_y := PackedInt32Array()
	_distance_field(inside, 0, land_x, land_y)
	_distance_field(inside, 1, water_x, water_y)
	# Uzaklık (hücre) 32 bitlik dizide: eski kurulumla aynı yuvarlama (ızgara bit bit aynı kalsın).
	var to_edge := PackedFloat32Array()
	to_edge.resize(n)
	for i in n:
		to_edge[i] = sqrt(float(land_x[i] * land_x[i] + land_y[i] * land_y[i])) if inside[i] == 1 \
				else sqrt(float(water_x[i] * water_x[i] + water_y[i] * water_y[i]))
	shore.resize(n)
	for y in height:
		for x in width:
			var i := y * width + x
			var grid: float
			if inside[i] == 1:
				grid = maxf(0.0, to_edge[i] * CELL - CELL * 0.5)
			else:
				grid = -maxf(0.0, to_edge[i] * CELL - CELL * 0.5)
			# Kıyıya yakın yerde elips formülü (pürüzsüz kıyı çizgisi), uzakta ızgara uzaklığı.
			if absf(grid) < EXACT_BAND:
				var exact := _union_distance(cell_center(x, y))
				shore[i] = lerpf(exact, grid, smoothstep(0.5, 1.0, absf(exact)))
			else:
				shore[i] = grid
	_build_depth_and_zones(inside, water_x, water_y)
	_zone_stats()


## Su hücrelerinde havzaların derinliği (ağırlıklı ortalama) ve bölge; kara hücrelerinde en yakın
## suyun bölgesi.
func _build_depth_and_zones(inside: PackedByteArray, water_x: PackedInt32Array, water_y: PackedInt32Array) -> void:
	var n := width * height
	depth.resize(n)
	depth.fill(0.0)
	zone_grid.resize(n)
	zone_grid.fill(NO_ZONE)
	var best := PackedFloat32Array()
	best.resize(n)
	best.fill(-INF)
	var weight := PackedFloat32Array()
	weight.resize(n)
	for b in basins.size():
		var basin := basins[b]
		var deepest: float = basin["max_depth"]
		var shelf_m: float = basin["shelf"]
		var zone: int = basin["zone"]
		var boat_from: float = basin["boat_from"]
		var cells := _cell_range(_basin_box(b).grow(BLEND + CELL))
		for y in range(cells.position.y, cells.end.y):
			for x in range(cells.position.x, cells.end.x):
				var i := y * width + x
				if inside[i] == 0:
					continue
				var sd := _basin_distance(b, cell_center(x, y))
				var w := smoothstep(-BLEND, BLEND, sd)
				if w > 0.0:
					weight[i] += w
					depth[i] += w * deepest * smoothstep(0.0, shelf_m, shore[i])
				# Sandal bölgesi kıyıya değmez: kıyıya yakın hücreyi en yakın öteki havza alır.
				# Burada yalnızca havzanın içi ve kenar bandı (kutu bunu tam kapsar).
				if (boat_from < 0.0 or shore[i] >= boat_from) and sd >= -BLEND and sd > best[i] and zone != NO_ZONE:
					best[i] = sd
					zone_grid[i] = zone
	for y in height:
		for x in width:
			var i := y * width + x
			if inside[i] == 0:
				continue
			if weight[i] > 0.0:
				depth[i] /= weight[i]
			# Hiçbir havzanın bandına düşmeyen su (sandal havzasının kıyıya yakın yeri): sandalsız
			# havzalardan kenarı en yakın olanın bölgesi.
			if zone_grid[i] == NO_ZONE:
				var p := cell_center(x, y)
				var near := -INF
				for b in basins.size():
					var zone: int = basins[b]["zone"]
					if float(basins[b]["boat_from"]) >= 0.0 or zone == NO_ZONE:
						continue
					var sd := _basin_distance(b, p)
					if sd > near:
						near = sd
						zone_grid[i] = zone
	# Kara hücresi: en yakın su hücresinin bölgesi (uzaklık alanının bulduğu tohum).
	for y in height:
		for x in width:
			var i := y * width + x
			if inside[i] == 1:
				continue
			var sx := x + water_x[i]
			var sy := y + water_y[i]
			if sx >= 0 and sy >= 0 and sx < width and sy < height:
				zone_grid[i] = zone_grid[sy * width + sx]


## Bölgelerin su hücrelerinin kutusu ve ağırlık merkezi.
func _zone_stats() -> void:
	var count := zone_ids.size()
	zone_bounds.clear()
	zone_centers.resize(count)
	var sums := PackedVector2Array()
	sums.resize(count)
	var cells := PackedInt32Array()
	cells.resize(count)
	for k in count:
		zone_bounds.append(Rect2())
	for y in height:
		for x in width:
			var i := y * width + x
			var z := zone_grid[i]
			if z == NO_ZONE or z >= count or shore[i] <= 0.0:
				continue
			var p := cell_center(x, y)
			var cell := Rect2(p - Vector2(CELL, CELL) * 0.5, Vector2(CELL, CELL))
			zone_bounds[z] = cell if cells[z] == 0 else zone_bounds[z].merge(cell)
			sums[z] += p
			cells[z] += 1
	for k in count:
		zone_centers[k] = sums[k] / cells[k] if cells[k] > 0 else Vector2.ZERO


## Her hücreden mask değeri seed_value olan en yakın hücreye ofset (hücre biriminde; ox, oy
## çağıranın dizilerine yazılır). 8SSEDT: iki geçişte en yakın tohumun ofseti komşulardan
## aktarılır. Komşu karşılaştırmaları hız için açık yazılmıştır (işlev çağrısı GDScript'te pahalı).
func _distance_field(mask: PackedByteArray, seed_value: int, ox: PackedInt32Array, oy: PackedInt32Array) -> void:
	var n := width * height
	ox.resize(n)
	oy.resize(n)
	var far := 1 << 20
	for i in n:
		var is_seed := mask[i] == seed_value
		ox[i] = 0 if is_seed else far
		oy[i] = 0 if is_seed else far
	var w := width
	for y in height:
		var row := y * w
		for x in w:
			var i := row + x
			var bx := ox[i]
			var by := oy[i]
			if bx == 0 and by == 0:
				continue
			var best := bx * bx + by * by
			if x > 0:
				var cx := ox[i - 1] - 1
				var cy := oy[i - 1]
				var d := cx * cx + cy * cy
				if d < best:
					best = d
					bx = cx
					by = cy
			if y > 0:
				var j := i - w
				var cx := ox[j]
				var cy := oy[j] - 1
				var d := cx * cx + cy * cy
				if d < best:
					best = d
					bx = cx
					by = cy
				if x > 0:
					cx = ox[j - 1] - 1
					cy = oy[j - 1] - 1
					d = cx * cx + cy * cy
					if d < best:
						best = d
						bx = cx
						by = cy
				if x < w - 1:
					cx = ox[j + 1] + 1
					cy = oy[j + 1] - 1
					d = cx * cx + cy * cy
					if d < best:
						best = d
						bx = cx
						by = cy
			ox[i] = bx
			oy[i] = by
		for x in range(w - 2, -1, -1):
			var i := row + x
			var cx := ox[i + 1] + 1
			var cy := oy[i + 1]
			if cx * cx + cy * cy < ox[i] * ox[i] + oy[i] * oy[i]:
				ox[i] = cx
				oy[i] = cy
	for y in range(height - 1, -1, -1):
		var row := y * w
		for x in range(w - 1, -1, -1):
			var i := row + x
			var bx := ox[i]
			var by := oy[i]
			if bx == 0 and by == 0:
				continue
			var best := bx * bx + by * by
			if x < w - 1:
				var cx := ox[i + 1] + 1
				var cy := oy[i + 1]
				var d := cx * cx + cy * cy
				if d < best:
					best = d
					bx = cx
					by = cy
			if y < height - 1:
				var j := i + w
				var cx := ox[j]
				var cy := oy[j] + 1
				var d := cx * cx + cy * cy
				if d < best:
					best = d
					bx = cx
					by = cy
				if x > 0:
					cx = ox[j - 1] - 1
					cy = oy[j - 1] + 1
					d = cx * cx + cy * cy
					if d < best:
						best = d
						bx = cx
						by = cy
				if x < w - 1:
					cx = ox[j + 1] + 1
					cy = oy[j + 1] + 1
					d = cx * cx + cy * cy
					if d < best:
						best = d
						bx = cx
						by = cy
			ox[i] = bx
			oy[i] = by
		for x in range(1, w):
			var i := row + x
			var cx := ox[i - 1] - 1
			var cy := oy[i - 1]
			if cx * cx + cy * cy < ox[i] * ox[i] + oy[i] * oy[i]:
				ox[i] = cx
				oy[i] = cy


## Elipslerin birleşimine işaretli uzaklık tahmini; kıyının yakınında doğru, uzakta kaba.
## Her elips için g / |∇g|; birleşim için en büyüğü.
func _union_distance(p: Vector2) -> float:
	var best := -INF
	for b in basins.size():
		best = maxf(best, _basin_distance(b, p))
	return best


## Havzanın içinde kalma payı (m; içeride +): g / |∇g| (g = 1 − (lx² + ly²), lx ve ly elipsin
## kendi ekseninde yarıçapa bölünmüş konum).
func _basin_distance(b: int, p: Vector2) -> float:
	var q := p - _centers[b]
	var c := _cs[b * 2]
	var s := _cs[b * 2 + 1]
	var r := _radii[b]
	var lx := (q.x * c + q.y * s) / r.x
	var ly := (-q.x * s + q.y * c) / r.y
	var g := 1.0 - (lx * lx + ly * ly)
	var grad := 2.0 * sqrt((lx / r.x) * (lx / r.x) + (ly / r.y) * (ly / r.y))
	return g / maxf(grad, 0.0001)


func _inside(b: int, p: Vector2) -> bool:
	var q := p - _centers[b]
	var c := _cs[b * 2]
	var s := _cs[b * 2 + 1]
	var r := _radii[b]
	var lx := (q.x * c + q.y * s) / r.x
	var ly := (-q.x * s + q.y * c) / r.y
	return lx * lx + ly * ly <= 1.0


## Döndürülmüş elipsin sınır kutusu.
func _basin_box(b: int) -> Rect2:
	var basin := basins[b]
	var r: Vector2 = basin["radius"]
	var c: float = basin["cos"]
	var s: float = basin["sin"]
	var half := Vector2(sqrt(pow(r.x * c, 2) + pow(r.y * s, 2)), sqrt(pow(r.x * s, 2) + pow(r.y * c, 2)))
	return Rect2((basin["center"] as Vector2) - half, half * 2.0)


## Dünya kutusunun kapladığı hücreler (ızgaraya kırpılmış; end hariç).
func _cell_range(box: Rect2) -> Rect2i:
	var x0 := clampi(floori((box.position.x - origin.x) / CELL), 0, width)
	var y0 := clampi(floori((box.position.y - origin.y) / CELL), 0, height)
	var x1 := clampi(ceili((box.end.x - origin.x) / CELL) + 1, 0, width)
	var y1 := clampi(ceili((box.end.y - origin.y) / CELL) + 1, 0, height)
	return Rect2i(x0, y0, maxi(0, x1 - x0), maxi(0, y1 - y0))


## Izgaradan çift doğrusal örnekleme; ızgaranın dışında outside.
func _sample(grid: PackedFloat32Array, p: Vector2, outside: float) -> float:
	var gx := (p.x - origin.x) / CELL - 0.5
	var gy := (p.y - origin.y) / CELL - 0.5
	if gx < -1.0 or gy < -1.0 or gx > width or gy > height:
		return outside
	var x0 := clampi(floori(gx), 0, width - 1)
	var y0 := clampi(floori(gy), 0, height - 1)
	var x1 := mini(x0 + 1, width - 1)
	var y1 := mini(y0 + 1, height - 1)
	var fx := clampf(gx - x0, 0.0, 1.0)
	var fy := clampf(gy - y0, 0.0, 1.0)
	var top := lerpf(grid[y0 * width + x0], grid[y0 * width + x1], fx)
	var bottom := lerpf(grid[y1 * width + x0], grid[y1 * width + x1], fx)
	return lerpf(top, bottom, fy)


# --- Önbellek ------------------------------------------------------------------------

## Önbellek dosyası: gölün tanımının (havzalar, bölgeler, iskele) ve kurulum sürümünün özeti adda.
func _cache_path(id: String) -> String:
	var key := var_to_str([BUILD_VERSION, CELL, MARGIN, BLEND, EXACT_BAND, basins, zone_ids]).md5_text().left(12)
	return CACHE_DIR.path_join("lake_%s_%s.bin" % [id, key])


func _load_cache(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return false
	var f := FileAccess.open(path, FileAccess.READ)
	if f == null:
		return false
	var data: Variant = f.get_var()
	f.close()
	if typeof(data) != TYPE_DICTIONARY:
		return false
	var d: Dictionary = data
	var n := width * height
	if int(d.get("width", 0)) != width or int(d.get("height", 0)) != height:
		return false
	var cached_shore: Variant = d.get("shore")
	var cached_depth: Variant = d.get("depth")
	var cached_zone: Variant = d.get("zone")
	if typeof(cached_shore) != TYPE_PACKED_FLOAT32_ARRAY or typeof(cached_depth) != TYPE_PACKED_FLOAT32_ARRAY \
			or typeof(cached_zone) != TYPE_PACKED_BYTE_ARRAY:
		return false
	if (cached_shore as PackedFloat32Array).size() != n or (cached_depth as PackedFloat32Array).size() != n \
			or (cached_zone as PackedByteArray).size() != n:
		return false
	shore = cached_shore
	depth = cached_depth
	zone_grid = cached_zone
	_zone_stats()
	from_cache = true
	return true


## Önbelleği yazar (önce geçici dosyaya, sonra yerine: yarım dosya kalmasın) ve aynı gölün eski
## önbelleklerini siler.
func _save_cache(path: String, id: String) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(CACHE_DIR))
	var temp := path + ".tmp"
	var f := FileAccess.open(temp, FileAccess.WRITE)
	if f == null:
		return
	f.store_var({ "width": width, "height": height, "shore": shore, "depth": depth, "zone": zone_grid })
	f.close()
	var dir := DirAccess.open(CACHE_DIR)
	if dir == null:
		return
	for file in dir.get_files():
		if file.begins_with("lake_%s_" % id) and file != temp.get_file():
			dir.remove(file)
	dir.rename(temp.get_file(), path.get_file())
