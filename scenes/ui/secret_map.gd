class_name SecretMap
extends Control
## Gölün Sırrı'nın haritası (Dalga 4, 5. adım; docs/gdd.md §10.5): genç Dede'nin dörde yırttığı harita, 2×2
## yapboz (Balık Defteri'nin "Gölün Sırrı" sekmesi). Bulunan parça yerinde: Ersin'in secret_map görselinin çeyreği
## ya da (görsel yoksa) kodla parşömen: gölün havzaları gerçek göl şeklinden, iskele, derin orta koyu. Eksik
## parçanın yeri kesik çizgili ve soru işaretli. Dört parça tamamsa kodla çizilen haritada derin ortanın ilk
## şamandırasında kırmızı X (Ersin'in görselinde X zaten çizili). Parçalar sırayla: sol üst, sağ üst, sol alt, sağ
## alt.

## Parçaların arası (yırtık çizgi) ve haritanın göl çevresindeki payı (m).
const GAP := 8.0
const MARGIN_M := 3.0
const PAPER := Color("#eed9a6")
const PAPER_EDGE := Color("#b98a4e")
const WATER := Color("#86c9d4")
const WATER_DEEP := Color("#4d93b0")
const DOCK := Color("#8f6b47")
const INK := Color("#5a3a1e")
const RED := Color("#d8423a")
const EMPTY := Color(0.36, 0.25, 0.14, 0.12)
const EMPTY_EDGE := Color(0.36, 0.25, 0.14, 0.55)

## Bulunan parça sayısı (0..4).
var pieces: int = 0:
	set(value):
		pieces = clampi(value, 0, 4)
		queue_redraw()
var _lake: LakeShape
var _deep_zone: int = -1
var _x_point := Dice.NO_POINT


## Haritanın gölü (havzalar, iskele) ve X'in yeri (derin ortanın ilk şamandırası).
func setup(lake: LakeShape, deep_zone: int, x_point: Vector2) -> void:
	_lake = lake
	_deep_zone = deep_zone
	_x_point = x_point
	queue_redraw()


func _draw() -> void:
	var half := (size - Vector2(GAP, GAP)) * 0.5
	var art := ItemArt.art("secret_map.png")
	for i in 4:
		var cell := _cell(i, half)
		if i >= pieces:
			_draw_empty(cell)
		elif art != null:
			var region_size := art.get_size() * 0.5
			draw_texture_rect_region(art, cell, Rect2(Vector2(i % 2, i >> 1) * region_size, region_size))
		else:
			_draw_piece(i, cell, half)


## Parçanın ekrandaki yeri (aralarında GAP).
func _cell(i: int, half: Vector2) -> Rect2:
	return Rect2(Vector2(i % 2, i >> 1) * (half + Vector2(GAP, GAP)), half)


## Kodla çizilen parça: haritanın o çeyreği (havzalar çeyreğe kırpılır), parşömen kenarı; harita tamamsa X.
func _draw_piece(i: int, cell: Rect2, half: Vector2) -> void:
	draw_rect(cell, PAPER)
	if _lake != null:
		# Harita bütün olarak (aralıksız) kurulur; çeyreğin parçası kırpılıp hücreye kaydırılır.
		var whole := Rect2(Vector2.ZERO, half * 2.0)
		var piece := Rect2(Vector2(i % 2, i >> 1) * half, half)
		var shift := cell.position - piece.position
		var clip := _rect_polygon(piece)
		for b in _lake.basins.size():
			var basin: Dictionary = _lake.basins[b]
			var color := WATER_DEEP if int(basin["zone"]) == _deep_zone and _deep_zone >= 0 else WATER
			for poly: PackedVector2Array in Geometry2D.intersect_polygons(_ellipse(basin, whole), clip):
				draw_colored_polygon(_moved(poly, shift), color)
		if _lake.dock.size.x > 0.0:
			var dock := _rect_polygon(Rect2(_to_map(_lake.dock.position, whole), _lake.dock.size * _scale(whole)))
			for poly: PackedVector2Array in Geometry2D.intersect_polygons(dock, clip):
				draw_colored_polygon(_moved(poly, shift), DOCK)
		if pieces >= 4 and Dice.is_point(_x_point):
			var x := _to_map(_x_point, whole)
			if piece.grow(-2.0).has_point(x):
				var p := x + shift
				var r := minf(half.x, half.y) * 0.12
				for d: Vector2 in [Vector2(r, r), Vector2(r, -r)]:
					draw_line(p - d, p + d, INK, 11.0, true)
					draw_line(p - d, p + d, RED, 7.0, true)
	draw_rect(cell, PAPER_EDGE, false, 3.0)


## Eksik parçanın yeri: soluk zemin, kesik çizgili kenar, ortada soru işareti.
func _draw_empty(cell: Rect2) -> void:
	draw_rect(cell, EMPTY)
	var corners := [cell.position, Vector2(cell.end.x, cell.position.y), cell.end, Vector2(cell.position.x, cell.end.y)]
	for k in 4:
		draw_dashed_line(corners[k], corners[(k + 1) % 4], EMPTY_EDGE, 3.0, 12.0)
	var font := UiKit.display_font()
	var side := int(minf(cell.size.x, cell.size.y) * 0.4)
	var text_size := font.get_string_size("?", HORIZONTAL_ALIGNMENT_LEFT, -1, side)
	draw_string(font, cell.get_center() + Vector2(-text_size.x * 0.5, text_size.y * 0.3), "?",
			HORIZONTAL_ALIGNMENT_LEFT, -1, side, EMPTY_EDGE)


## Dünyadan (xz) haritaya: gölün suyunun kutusu (payıyla) haritanın içine, oranı korunarak ve ortalanarak.
func _to_map(p: Vector2, whole: Rect2) -> Vector2:
	var box := _lake.water_bounds.grow(MARGIN_M)
	var k := _scale(whole)
	var offset := whole.position + (whole.size - box.size * k) * 0.5
	return offset + (p - box.position) * k


func _scale(whole: Rect2) -> float:
	var box := _lake.water_bounds.grow(MARGIN_M)
	return minf(whole.size.x / maxf(1.0, box.size.x), whole.size.y / maxf(1.0, box.size.y))


## Havzanın elipsi haritada (döndürülmüş; LakeShape'in havza verisi).
func _ellipse(basin: Dictionary, whole: Rect2) -> PackedVector2Array:
	var center: Vector2 = basin["center"]
	var radius: Vector2 = basin["radius"]
	var c := float(basin["cos"])
	var s := float(basin["sin"])
	var out := PackedVector2Array()
	for k in 32:
		var t := TAU * k / 32.0
		var local := Vector2(cos(t) * radius.x, sin(t) * radius.y)
		out.append(_to_map(center + Vector2(local.x * c - local.y * s, local.x * s + local.y * c), whole))
	return out


static func _rect_polygon(r: Rect2) -> PackedVector2Array:
	return PackedVector2Array([r.position, Vector2(r.end.x, r.position.y), r.end, Vector2(r.position.x, r.end.y)])


static func _moved(poly: PackedVector2Array, shift: Vector2) -> PackedVector2Array:
	var out := PackedVector2Array()
	for p in poly:
		out.append(p + shift)
	return out
