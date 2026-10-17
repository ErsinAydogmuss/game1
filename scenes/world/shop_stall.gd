class_name ShopStall
extends Node3D
## Nine'nin dükkânı: iskelenin kara ucunun yanında, kodla kurulan ahşap bir tezgâh. Alçak bir
## döşeme, arkada raflı duvar (yem kavanozları, kutular), önde tezgâh (solucan kovası, kavanozlar,
## mısır kasası, pirinç zil), yanda olta sehpası, üstte turkuaz-krem çizgili tente ve tabela.
## Nine tezgâhın arkasında durur (keeper_spot). Yanında KayKit fıçı ve kasa (tek ağ).
## Parçalar köşe renkli tek ağda birleşir (MeshBatch): ~120 parça tek çizim (gölgesiyle iki).
## Yerel eksen: +z dükkânın önü (müşteri tarafı); kök döşemenin ön kenarının ortası, zemin hizası.
## Yerleşim noktaları (keeper_spot, blockers) üst düğümün uzayındadır (main: dünya); ağaçta olmadan
## da hesaplanır (testler).
## Kamera yukarıdan baktığı için tente yüksek ve kısa tutulur: tezgâhın arkasındaki Nine'nin
## başı tentenin altından görünür.

const WIDTH := 2.6
const DEPTH := 1.9
const FLOOR := 0.14
## Döşemenin altında, eğimli zemine kadar inen etek (m).
const SKIRT := 0.3
const COUNTER_W := 2.0
const COUNTER_H := 0.56
const COUNTER_D := 0.42
const COUNTER_Z := -0.32
## Nine'nin ayakları (tezgâhın arkası).
const KEEPER_Z := -0.98
const WALL_Z := -1.8
const WALL_H := 2.3
## Tente: duvarın tepesinden öne doğru alçalır.
const AWNING_BACK := 2.62
const AWNING_FRONT := 2.32
const AWNING_FRONT_Z := -0.46
const STRIPES := 7
const WOOD := Color("#9b6a3c")
const WOOD_LIGHT := Color("#b98352")
const WOOD_DARK := Color("#6e4526")
const STRIPE_A := Color("#2a9d96")
const STRIPE_B := Color("#f4ead2")
const BRASS := Color("#d9a83a")
const SIGN_TEXT := Color("#ffe6a3")
const SIGN_INK := Color("#3a2414")
## Dokunma: ekranda dükkânın çevresine eklenen pay (viewport yüksekliği 1080'e göre piksel).
const TOUCH_PX := 24.0

var _sign: Label3D
## Dokunma için dükkânın köşe noktaları (yerel).
var _outline: Array[Vector3] = []


## Dükkânı kurar: front_center ön kenarın ortası (dünya; döşemenin altı), facing önün yönü (xz),
## ground_at: zemin yüksekliği (Vector2 -> float; yanındaki eşyalar zemine otursun).
func build(front_center: Vector3, facing: Vector2, ground_at: Callable = Callable()) -> void:
	var f := facing.normalized()
	rotation = Vector3(0.0, atan2(f.x, f.y), 0.0)
	position = front_center
	var batch := MeshBatch.new()
	_build_floor(batch)
	_build_wall(batch)
	_build_counter(batch)
	_build_rod_rack(batch)
	_build_awning(batch)
	_build_sign(batch)
	batch.build(self, "Stall").cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	_add_props(ground_at)
	var half := WIDTH * 0.5
	for p: Vector3 in [Vector3(-half, 0, 0.1), Vector3(half, 0, 0.1), Vector3(half, 0, WALL_Z),
			Vector3(-half, 0, WALL_Z), Vector3(-half, AWNING_BACK, WALL_Z), Vector3(half, AWNING_BACK, WALL_Z),
			Vector3(half, AWNING_FRONT, AWNING_FRONT_Z), Vector3(-half, AWNING_FRONT, AWNING_FRONT_Z)]:
		_outline.append(p)
	refresh()


## Dil değişince tabela yeniden yazılır.
func refresh() -> void:
	if _sign != null:
		_sign.text = UiKit.upper(tr("UI_SHOP_SIGN"))


## Nine'nin duracağı yer (döşemenin üstü) ve yüzünün yönü.
func keeper_spot() -> Vector3:
	return transform * Vector3(0.0, FLOOR, KEEPER_Z)


func facing() -> Vector2:
	var forward := basis.z
	return Vector2(forward.x, forward.z).normalized()


## Balıkçının giremeyeceği daireler: Vector3(x, z, yarıçap) (Angler.blockers).
func blockers() -> Array[Vector3]:
	var out: Array[Vector3] = []
	for local: Vector3 in [Vector3(-0.62, 0, -0.95), Vector3(0.62, 0, -0.95), Vector3(-1.45, 0, 0.0)]:
		var p := transform * local
		out.append(Vector3(p.x, p.z, 1.02 if local.x > -1.0 else 0.32))
	return out


## Ekrandaki bir nokta dükkânın üstünde mi (köşelerinin ekrandaki dış zarfı, biraz paylı)?
func hit(view: Camera3D, screen: Vector2) -> bool:
	if not is_visible_in_tree() or view == null or _outline.is_empty():
		return false
	var points := PackedVector2Array()
	for local in _outline:
		var p := to_global(local)
		if view.is_position_behind(p):
			return false
		points.append(view.unproject_position(p))
	var hull := Geometry2D.convex_hull(points)
	if Geometry2D.is_point_in_polygon(screen, hull):
		return true
	var pad := TOUCH_PX * view.get_viewport().get_visible_rect().size.y / 1080.0
	for i in hull.size() - 1:
		if Geometry2D.get_closest_point_to_segment(screen, hull[i], hull[i + 1]).distance_to(screen) <= pad:
			return true
	return false


# --- Kurulum ---------------------------------------------------------------------

## Döşeme: enine tahtalar, altında kiriş ve zemine inen etek (eğimli kıyıda boşluk kalmasın).
func _build_floor(batch: MeshBatch) -> void:
	var planks := 6
	var plank := DEPTH / planks
	for i in planks:
		var shade := WOOD if i % 2 == 0 else WOOD.darkened(0.08)
		batch.box(Vector3(WIDTH, 0.06, plank - 0.02), Vector3(0, FLOOR - 0.03, -plank * (i + 0.5)), shade)
	batch.box(Vector3(WIDTH - 0.06, SKIRT, DEPTH - 0.06), Vector3(0, FLOOR - 0.06 - SKIRT * 0.5, -DEPTH * 0.5), WOOD_DARK)
	# Önde bir basamak.
	batch.box(Vector3(0.9, 0.07, 0.26), Vector3(0.55, 0.035, 0.12), WOOD_DARK)


## Arka duvar: dikey tahtalar, üst kiriş, iki raf ve raflardaki yem kavanozları, kutular.
func _build_wall(batch: MeshBatch) -> void:
	var boards := 8
	var board := WIDTH / boards
	for i in boards:
		var shade := WOOD_DARK if i % 2 == 0 else WOOD_DARK.lightened(0.07)
		batch.box(Vector3(board - 0.015, WALL_H, 0.08), Vector3(-WIDTH * 0.5 + board * (i + 0.5), FLOOR + WALL_H * 0.5, WALL_Z), shade)
	batch.box(Vector3(WIDTH + 0.08, 0.12, 0.14), Vector3(0, FLOOR + WALL_H + 0.02, WALL_Z), WOOD)
	# Köşe direkleri (tenteyi taşır).
	for side: float in [-1.0, 1.0]:
		var x := side * (WIDTH * 0.5 - 0.06)
		batch.cylinder(0.055, 0.06, AWNING_FRONT - 0.04, Vector3(x, (AWNING_FRONT - 0.04) * 0.5, AWNING_FRONT_Z), WOOD, 6)
		batch.cylinder(0.06, 0.06, AWNING_BACK, Vector3(x, AWNING_BACK * 0.5, WALL_Z + 0.06), WOOD, 6)
	var jars: Array[Color] = [Color("#8b5a3c"), Color("#f0e2b8"), Color("#f2c33d"), Color("#e8d6a8"), Color("#d96b4a"), Color("#6aa84f")]
	for row in 2:
		var y := FLOOR + 0.8 + row * 0.5
		batch.box(Vector3(WIDTH - 0.3, 0.04, 0.3), Vector3(0, y, WALL_Z + 0.19), WOOD_LIGHT)
		for i in 6:
			var x := -0.95 + i * 0.38
			var color := jars[(i + row * 3) % jars.size()]
			if (i + row) % 3 == 2:
				# Kutu (iğne, kurşun).
				batch.box(Vector3(0.22, 0.13, 0.16), Vector3(x, y + 0.085, WALL_Z + 0.2), color.darkened(0.1))
				continue
			# Kavanoz: içi yemin rengi, kapağı tahta.
			batch.cylinder(0.075, 0.075, 0.17, Vector3(x, y + 0.105, WALL_Z + 0.2), color, 10)
			batch.cylinder(0.08, 0.08, 0.035, Vector3(x, y + 0.205, WALL_Z + 0.2), WOOD_DARK, 10)


## Tezgâh: tahta gövde, açık renk üst tahta; üstünde solucan kovası, kavanozlar, mısır kasası, zil.
func _build_counter(batch: MeshBatch) -> void:
	var y0 := FLOOR
	batch.box(Vector3(COUNTER_W, COUNTER_H, COUNTER_D), Vector3(0, y0 + COUNTER_H * 0.5, COUNTER_Z), WOOD)
	# Önde dikey çıtalar (tahta görünsün).
	var slats := 7
	for i in slats:
		var x := -COUNTER_W * 0.5 + COUNTER_W * (i + 0.5) / slats
		batch.box(Vector3(0.05, COUNTER_H - 0.08, 0.02), Vector3(x, y0 + COUNTER_H * 0.5, COUNTER_Z + COUNTER_D * 0.5 + 0.01), WOOD_DARK)
	var top := y0 + COUNTER_H + 0.025
	batch.box(Vector3(COUNTER_W + 0.12, 0.05, COUNTER_D + 0.1), Vector3(0, top, COUNTER_Z), WOOD_LIGHT)
	var on := top + 0.025
	# Solucan kovası (kahverengi toprak).
	batch.cylinder(0.12, 0.1, 0.18, Vector3(-0.72, on + 0.09, COUNTER_Z), Color("#5f7f9a"), 12)
	batch.cylinder(0.11, 0.11, 0.02, Vector3(-0.72, on + 0.17, COUNTER_Z), Color("#5a3a24"), 12)
	# Üç küçük yem kavanozu.
	var colors: Array[Color] = [Color("#f0e2b8"), Color("#f2c33d"), Color("#e8a0a8")]
	for i in 3:
		var x := -0.38 + i * 0.17
		batch.cylinder(0.06, 0.06, 0.14, Vector3(x, on + 0.07, COUNTER_Z + 0.04), colors[i], 10)
		batch.cylinder(0.065, 0.065, 0.03, Vector3(x, on + 0.155, COUNTER_Z + 0.04), Color("#c0392b") if i == 1 else WOOD_DARK, 10)
	# Mısır kasası.
	batch.box(Vector3(0.34, 0.12, 0.24), Vector3(0.28, on + 0.06, COUNTER_Z), WOOD_DARK)
	for i in 6:
		batch.sphere(0.045, Vector3(0.16 + (i % 3) * 0.12, on + 0.13, COUNTER_Z - 0.05 + floorf(i / 3.0) * 0.1), Color("#f2c33d"))
	# Pirinç zil.
	batch.cylinder(0.05, 0.05, 0.015, Vector3(0.74, on + 0.008, COUNTER_Z + 0.06), WOOD_DARK, 10)
	batch.sphere(0.055, Vector3(0.74, on + 0.04, COUNTER_Z + 0.06), BRASS, Vector3(1.0, 0.85, 1.0))
	batch.sphere(0.015, Vector3(0.74, on + 0.095, COUNTER_Z + 0.06), BRASS)


## Olta sehpası: dükkânın sağ önünde, eğik duran üç olta (renkli makaralar) ve bir kepçe.
func _build_rod_rack(batch: MeshBatch) -> void:
	var base := Vector3(-WIDTH * 0.5 - 0.22, 0.0, -0.05)
	batch.box(Vector3(0.22, 0.06, 0.62), base + Vector3(0, 0.03, -0.25), WOOD_DARK)
	batch.box(Vector3(0.06, 0.95, 0.06), base + Vector3(0.02, 0.475, -0.52), WOOD_DARK)
	batch.box(Vector3(0.1, 0.05, 0.62), base + Vector3(0.02, 0.9, -0.25), WOOD)
	var reels: Array[Color] = [Color("#e5484d"), Color("#3d8bff"), Color("#f0b637")]
	for i in 3:
		var z := -0.08 - i * 0.17
		var foot := base + Vector3(0.0, 0.06, z)
		var tilt := Vector3(0.0, 0.0, -0.14)
		var length := 1.9
		var dir := Basis.from_euler(tilt) * Vector3.UP
		batch.cylinder(0.008, 0.02, length, foot + dir * length * 0.5, Color("#3a2a1e"), 6, tilt)
		batch.cylinder(0.028, 0.028, 0.22, foot + dir * 0.2, Color("#c8a06a"), 6, tilt)
		batch.cylinder(0.05, 0.05, 0.04, foot + dir * 0.36 + Vector3(0.05, 0, 0), reels[i], 10,
				Vector3(0.0, 0.0, PI * 0.5 - 0.14))
	# Kepçe: sap ve çember.
	var net_foot := base + Vector3(0.12, 0.06, 0.18)
	var net_tilt := Vector3(0.18, 0.0, -0.22)
	var net_dir := Basis.from_euler(net_tilt) * Vector3.UP
	batch.cylinder(0.015, 0.015, 1.2, net_foot + net_dir * 0.6, Color("#c8a06a"), 6, net_tilt)
	var ring := TorusMesh.new()
	ring.inner_radius = 0.17
	ring.outer_radius = 0.2
	ring.rings = 14
	ring.ring_segments = 4
	batch.add(ring, Transform3D(Basis.from_euler(net_tilt + Vector3(PI * 0.5, 0, 0)), net_foot + net_dir * 1.38), Color("#3a2a1e"))


## Tente: duvarın tepesinden öne alçalan çizgili bez; önünde dalgalı saçak.
func _build_awning(batch: MeshBatch) -> void:
	var run := WALL_Z - AWNING_FRONT_Z
	var rise := AWNING_BACK - AWNING_FRONT
	var length := Vector2(run, rise).length() + 0.12
	var angle := atan2(rise, -run)
	var center := Vector3(0, (AWNING_BACK + AWNING_FRONT) * 0.5 + 0.03, (WALL_Z + AWNING_FRONT_Z) * 0.5)
	var width := WIDTH + 0.24
	var stripe := width / STRIPES
	for i in STRIPES:
		var x := -width * 0.5 + stripe * (i + 0.5)
		batch.box(Vector3(stripe, 0.04, length), center + Vector3(x, 0, 0), STRIPE_A if i % 2 == 0 else STRIPE_B,
				Vector3(-angle, 0, 0))
	# Saçak: ön kenardan sarkan bir şerit, altı dalgalı (her çizginin altında iki yarım daire;
	# dairelerin üst yarısı şeridin içinde kalır).
	var drop := 0.1
	var front_y := AWNING_FRONT - 0.02
	for i in STRIPES:
		var x := -width * 0.5 + stripe * (i + 0.5)
		var color := STRIPE_A if i % 2 == 0 else STRIPE_B
		batch.box(Vector3(stripe, drop, 0.04), Vector3(x, front_y - drop * 0.5, AWNING_FRONT_Z + 0.04), color)
		for half: float in [-0.25, 0.25]:
			batch.cylinder(stripe * 0.25, stripe * 0.25, 0.036, Vector3(x + half * stripe, front_y - drop,
					AWNING_FRONT_Z + 0.04), color, 12, Vector3(PI * 0.5, 0, 0))


## Tabela: tentenin üstünde, kameraya doğru yatık bir tahta; yazısı Label3D.
func _build_sign(batch: MeshBatch) -> void:
	var pivot := Vector3(0, AWNING_FRONT + 0.36, AWNING_FRONT_Z - 0.22)
	var tilt := Vector3(-0.42, 0, 0)
	var basis := Basis.from_euler(tilt)
	batch.box(Vector3(1.86, 0.42, 0.06), pivot, WOOD_DARK, tilt)
	batch.box(Vector3(1.96, 0.05, 0.08), pivot + basis * Vector3(0, 0.235, 0), WOOD, tilt)
	batch.box(Vector3(1.96, 0.05, 0.08), pivot + basis * Vector3(0, -0.235, 0), WOOD, tilt)
	for side: float in [-1.0, 1.0]:
		batch.box(Vector3(0.06, 0.5, 0.06), pivot + Vector3(side * 0.8, -0.32, -0.12), WOOD_DARK)
	_sign = Label3D.new()
	_sign.font = UiKit.display_font()
	_sign.font_size = 64
	_sign.pixel_size = 0.0034
	_sign.outline_size = 14
	_sign.modulate = SIGN_TEXT
	_sign.outline_modulate = SIGN_INK
	_sign.position = pivot + basis * Vector3(0, -0.01, 0.035)
	_sign.rotation = tilt
	_sign.double_sided = false
	add_child(_sign)


## Yanında KayKit fıçı ve kasa (göl tarafında; kameraya bakan yan açık kalır). Aynı paketten:
## ikisi tek ağ (ModelLibrary.merge), bir çizim ve bir gölge.
func _add_props(ground_at: Callable) -> void:
	var half := WIDTH * 0.5
	var placements: Array[Array] = []
	for spec: Array in [["barrel", Vector3(half + 0.35, 0, -0.35), 0.4], ["crate", Vector3(half + 0.3, 0, -1.25), 1.2]]:
		var local: Vector3 = spec[1]
		if ground_at.is_valid():
			var world := transform * local
			local.y = float(ground_at.call(Vector2(world.x, world.z))) - position.y
		placements.append([str(spec[0]), Transform3D(Basis(Vector3.UP, float(spec[2])), local)])
	for node in ModelLibrary.merge(self, "Props", placements):
		node.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
