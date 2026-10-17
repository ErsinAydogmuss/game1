extends SceneTree
## Gölün kuşbakışı önizlemesi (geometriyi ayarlarken): derinlik, bölgeler, iskele, başlangıç,
## atış noktaları, şamandıralar ve çitler bir PNG'ye çizilir; bölgelerin alanı ve merkezi yazılır.
##
##   godot --headless --path . -s res://tools/lake_map.gd -- --spot=big_lake --out=/mutlak/yol/gol.png
##
## Renkler: kara yeşil (yürünmeyen orman koyu), su derinliğe göre açık → koyu mavi, bölgeler kendi renginde ince sınırla;
## iskele kahverengi, başlangıç beyaz, atış noktaları siyah, şamandıralar kırmızı, çitler turuncu.
## Kuzey (−z) yukarıda, kamera (+x +z) sağ altta.

const ZONE_COLORS: Array[Color] = [
	Color("#ffd23f"), Color("#7ad151"), Color("#f48fb6"), Color("#9aa5b1"), Color("#4fd1c5"), Color("#5a4fcf"),
	Color("#ff8c42"), Color("#c084fc"),
]
## Hücre başına piksel.
const SCALE := 3


func _initialize() -> void:
	var spot_id := ""
	var out := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--spot="):
			spot_id = arg.trim_prefix("--spot=")
		elif arg.begins_with("--out="):
			out = arg.trim_prefix("--out=")
	var db := ContentDB.load_default()
	for e in db.errors:
		print("HATA: " + e)
	if spot_id.is_empty():
		spot_id = db.main_spot
	if out.is_empty():
		out = OS.get_user_data_dir().path_join("lake_%s.png" % spot_id)
	var started := Time.get_ticks_msec()
	var lake := LakeShape.from_spot(db.spot(spot_id), false)
	print("%s: %dx%d hücre, su kutusu %.0fx%.0f m, kurulum %d ms (önbelleksiz)" % [spot_id, lake.width, lake.height,
			lake.water_bounds.size.x, lake.water_bounds.size.y, Time.get_ticks_msec() - started])
	var zones := db.zones_of(spot_id)
	var area := PackedFloat32Array()
	area.resize(zones.size())
	var total := 0.0
	var img := Image.create_empty(lake.width * SCALE, lake.height * SCALE, false, Image.FORMAT_RGBA8)
	for y in lake.height:
		for x in lake.width:
			var i := y * lake.width + x
			var color := Color("#8fbf6a")
			var z := lake.zone_grid[i]
			if lake.shore[i] > 0.0:
				var d := lake.depth_at(lake.cell_center(x, y))
				color = Color("#9fe0f0").lerp(Color("#103a66"), clampf(d / 8.0, 0.0, 1.0))
				if z != LakeShape.NO_ZONE:
					color = color.lerp(ZONE_COLORS[z % ZONE_COLORS.size()], 0.28)
					area[z] += LakeShape.CELL * LakeShape.CELL
				else:
					color = Color.RED
				total += LakeShape.CELL * LakeShape.CELL
			elif not lake.in_world(lake.cell_center(x, y)):
				color = Color("#4f7a3a")
			elif z != LakeShape.NO_ZONE:
				color = color.lerp(ZONE_COLORS[z % ZONE_COLORS.size()], 0.12)
			# Bölge sınırı: komşu hücrenin bölgesi farklıysa koyu.
			if x > 0 and y > 0 and lake.shore[i] > 0.0:
				if lake.zone_grid[i - 1] != z or lake.zone_grid[i - lake.width] != z:
					color = color.darkened(0.45)
			img.fill_rect(Rect2i(x * SCALE, y * SCALE, SCALE, SCALE), color)
	var s := db.spot(spot_id)
	_rect(img, lake, s["dock"], Color("#8b5a2b"))
	_dot(img, lake, s["start"], 5, Color.WHITE)
	for k in zones.size():
		var z := zones[k]
		for p: Vector2 in z["stands"]:
			_dot(img, lake, p, 5, Color.BLACK)
		for p: Vector2 in z["buoys"]:
			_dot(img, lake, p, 5, Color("#e53935"))
		for g: PackedVector2Array in z["gates"]:
			if g.size() == 2:
				_line(img, lake, g[0], g[1], Color("#ff8c00"))
		_dot(img, lake, lake.zone_centers[k], 3, ZONE_COLORS[k % ZONE_COLORS.size()].darkened(0.5))
		print("  %-14s rütbe %d%s  su %5.0f m²  merkez (%.1f, %.1f)  kutu %s" % [z["id"], z["rank"],
				" sandal" if bool(z["boat"]) else "", area[k], lake.zone_centers[k].x, lake.zone_centers[k].y,
				lake.zone_bounds[k]])
	print("toplam su %.0f m²" % total)
	img.save_png(out)
	print("önizleme: " + out)
	quit()


func _px(lake: LakeShape, p: Vector2) -> Vector2i:
	return Vector2i(roundi((p.x - lake.origin.x) / LakeShape.CELL * SCALE), roundi((p.y - lake.origin.y) / LakeShape.CELL * SCALE))


func _dot(img: Image, lake: LakeShape, p: Vector2, radius: int, color: Color) -> void:
	var c := _px(lake, p)
	for y in range(-radius, radius + 1):
		for x in range(-radius, radius + 1):
			if x * x + y * y <= radius * radius and c.x + x >= 0 and c.y + y >= 0 and c.x + x < img.get_width() and c.y + y < img.get_height():
				img.set_pixel(c.x + x, c.y + y, color)


func _rect(img: Image, lake: LakeShape, r: Rect2, color: Color) -> void:
	var a := _px(lake, r.position)
	var b := _px(lake, r.end)
	img.fill_rect(Rect2i(a, b - a).intersection(Rect2i(Vector2i.ZERO, img.get_size())), color)


func _line(img: Image, lake: LakeShape, a: Vector2, b: Vector2, color: Color) -> void:
	var steps := maxi(1, ceili(a.distance_to(b) / LakeShape.CELL * SCALE))
	for i in steps + 1:
		_dot(img, lake, a.lerp(b, float(i) / steps), 1, color)
