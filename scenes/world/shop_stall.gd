class_name ShopStall
extends Node3D
## Nine'nin dükkânı: iskelenin kara ucunun yanında, kodla kurulan ahşap bir tezgâh. Alçak bir
## döşeme, arkada raflı duvar (yem kavanozları, kutular), önde tezgâh (solucan kovası, kavanozlar,
## defter, pirinç zil), yanda olta sehpası, üstte turkuaz-krem çizgili tente ve tabela.
## Akvaryum (Dalga 5; yapı 4'te büyüdü, testçi: "60-80 cm'lik balıklar küçücük tankta"): dükkânın solunda (yerel −x),
## kıyı yolunun öte yanında, dolabın üstünde ~3 m'lik tank; önü dükkânınki gibi kameraya bakar. Arka ve sağ duvarı
## su (opak, açıktan koyuya), dibi kum; ön ve sol yüzü cam (yalnızca çerçeve ve parıltı): balıklar içeride gerçek
## boylarında (FishMesh'in ağı, suyun rengine biraz karışmış), aynı tek ağda: çizim eklemez. Bağış kutusu dolabın
## önünde. Tanktaki türler ya da boylar değişince ağ yeniden kurulur (set_tank).
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
## Akvaryum: dükkânın solunda, kıyı yolunun öte yanında (yerel; tankın ortası x, z; boy, derinlik, camın yüksekliği,
## dolabın yüksekliği m). Yol dükkânın sol yanından geçer (x ≈ −1): tank onun ötesinde, çimende.
const TANK_X := -3.5
const TANK_Z := -0.42
const TANK_W := 2.8
const TANK_D := 0.8
const TANK_H := 1.1
const TANK_STAND := 0.5
## Dolabın önündeki raf (bağış kutusu orada) ve kumun kalınlığı.
const TANK_LEDGE := 0.2
const TANK_SAND := 0.07
## Tankta en çok bu kadar balık görünür (en değerliler; paneldeki tankta hepsi).
const TANK_SHOWN := 6
## Balığın tanktaki boyu: gerçek boyu (cm / 100) ama tanka sığacak kadar (uçlarda pay).
const TANK_FISH_PAD := 0.14
## Balığın rengi suyun rengine bu kadar karışır (camın ardında).
const TANK_TINT := 0.1
const WATER := Color("#3f9fc4")
const WATER_DEEP := Color("#24709a")
const WATER_TOP := Color("#86d2e6")
const SAND := Color("#e6cc93")
const TANK_FRAME := Color("#2f2a26")
const GLASS := Color("#d9f3fa")
const PLANT := Color("#4c9a46")
const PLANT_LIGHT := Color("#78c060")
## Bağış kutusu: dolabın önündeki rafta, sağ uçta (dükkâna yakın).
const BOX_SIZE := Vector3(0.2, 0.18, 0.16)
const BOX_COLOR := Color("#b5452f")
## Akvaryumun dokunma payı (viewport yüksekliği 1080'e göre piksel).
const TANK_TOUCH_PX := 14.0
const SIGN_INK := Color("#3a2414")
## Dokunma: ekranda dükkânın çevresine eklenen pay (viewport yüksekliği 1080'e göre piksel).
const TOUCH_PX := 24.0
## Gölde yeri: iskelenin kara ucunun solunda (-x); ön kenarın ortası kara ucuna göre (m), önü
## iskeleye ve biraz kameraya (+z) döner; çevresinde göl süslerinin konmadığı dairenin yarıçapı (m).
const OFFSET := Vector2(-1.85, 0.4)
const TURN := deg_to_rad(30.0)
const CLEAR := 2.4

var _sign: Label3D
## Dokunma için dükkânın ve akvaryumun köşe noktaları (yerel).
var _outline: Array[Vector3] = []
var _tank_outline: Array[Vector3] = []
## Dükkânın tek ağı (akvaryumun balıkları değişince yeniden kurulur) ve tankta görünen balıklar ({def, size_cm}).
var _mesh: MeshInstance3D
var _tank_fish: Array[Dictionary] = []
var _tank_key := ""
## Dükkânın balıksız parçaları (bir kez kurulur; balıklar değişince yalnızca onlar eklenir).
var _base: MeshBatch
## Tankın dolabının altındaki zemin (yerel y): en alçağı (etek) ve en yükseği (dolap ona oturur).
var _tank_ground := Vector2.ZERO


## İskelenin yanındaki dükkânın ön kenarının ortası (dünya xz; main yerleştirir).
static func front_for(dock: Rect2) -> Vector2:
	return Vector2(dock.get_center().x, dock.end.y) + OFFSET


## Dükkânın önünün yönü (xz).
static func facing_dir() -> Vector2:
	return Vector2(1.0, 0.0).rotated(TURN)


## Dükkânın kapladığı yer (x, z, yarıçap): göl süsleri oraya konmaz (LakeScene.keep_clear).
static func clear_zone(dock: Rect2) -> Vector3:
	var center := front_for(dock) - facing_dir() * DEPTH * 0.5
	return Vector3(center.x, center.y, CLEAR)


## Dükkânın ve akvaryumun kapladığı yerler (LakeScene.keep_clear).
static func clear_zones(dock: Rect2) -> Array[Vector3]:
	var tank := _local_to_world(dock, Vector2(TANK_X, TANK_Z))
	return [clear_zone(dock), Vector3(tank.x, tank.y, TANK_W * 0.5 + 0.5)]


## Dükkânın yerel noktası (x, z) dünyada (xz; ağaç kurulmadan: main ve testler).
static func _local_to_world(dock: Rect2, local: Vector2) -> Vector2:
	var f := facing_dir()
	var side := Vector2(f.y, -f.x)
	return front_for(dock) + side * local.x + f * local.y


## Dükkânı kurar: front_center ön kenarın ortası (dünya; döşemenin altı), facing önün yönü (xz),
## ground_at: zemin yüksekliği (Vector2 -> float; yanındaki eşyalar zemine otursun).
func build(front_center: Vector3, facing: Vector2, ground_at: Callable = Callable()) -> void:
	var f := facing.normalized()
	rotation = Vector3(0.0, atan2(f.x, f.y), 0.0)
	position = front_center
	_tank_ground = _ground_under_tank(ground_at)
	_build_mesh()
	_add_props(ground_at)
	var half := WIDTH * 0.5
	for p: Vector3 in [Vector3(-half, 0, 0.1), Vector3(half, 0, 0.1), Vector3(half, 0, WALL_Z),
			Vector3(-half, 0, WALL_Z), Vector3(-half, AWNING_BACK, WALL_Z), Vector3(half, AWNING_BACK, WALL_Z),
			Vector3(half, AWNING_FRONT, AWNING_FRONT_Z), Vector3(-half, AWNING_FRONT, AWNING_FRONT_Z)]:
		_outline.append(p)
	# Akvaryumun dokunma zarfı: dolap (raf ve bağış kutusu dahil) ve tank.
	var x0 := TANK_X - TANK_W * 0.5 - 0.05
	var x1 := TANK_X + TANK_W * 0.5 + 0.05
	var back := TANK_Z - TANK_D * 0.5 - 0.05
	var front := TANK_Z + TANK_D * 0.5 + TANK_LEDGE + 0.05
	var low := _tank_ground.x
	var high := _tank_top() + TANK_H
	for p: Vector3 in [Vector3(x0, low, front), Vector3(x1, low, front), Vector3(x1, low, back), Vector3(x0, low, back),
			Vector3(x0, high, front), Vector3(x1, high, front), Vector3(x1, high, back), Vector3(x0, high, back)]:
		_tank_outline.append(p)
	refresh()


## Tankta görünen balıklar: Aquarium.fish'in sırasıyla (en değerliler önce) [{def, size_cm}], en çok TANK_SHOWN.
## Türler ya da boylar değişince dükkânın ağı yeniden kurulur (yeni tür ya da daha iri balık tanka girince).
func set_tank(fish: Array[Dictionary]) -> void:
	var shown := fish.slice(0, TANK_SHOWN)
	var key := ""
	for f: Dictionary in shown:
		key += "%s:%d," % [str((f["def"] as Dictionary).get("id", "")), int(f["size_cm"])]
	if key == _tank_key:
		return
	_tank_key = key
	_tank_fish.assign(shown)
	if _mesh != null:
		_build_mesh()


## Tankta görünen balık sayısı (testler ve bot).
func tank_fish_count() -> int:
	return _tank_fish.size()


## Tankta görünen balıkların dükkândaki yeri ve boyu (yerel; testler: tanka sığar mı): [{id, center, length}].
func tank_fish_layout() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for place: Dictionary in _layout():
		out.append({ "id": str((place["def"] as Dictionary).get("id", "")), "center": place["center"],
				"length": float(place["length"]) })
	return out


## Akvaryumun ön camının ortası (dünya; bot dokunur).
func tank_point() -> Vector3:
	var local := Vector3(TANK_X, _tank_top() + TANK_H * 0.5, TANK_Z + TANK_D * 0.5)
	return to_global(local) if is_inside_tree() else transform * local


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
	# Akvaryum: boyunca dört daire (dolabın derinliğini örter; uçlar köşeleri).
	var depth := TANK_D + TANK_LEDGE
	var z := TANK_Z + TANK_LEDGE * 0.5
	for i in 4:
		var x := TANK_X - TANK_W * 0.5 + depth * 0.5 + (TANK_W - depth) * i / 3.0
		var p := transform * Vector3(x, 0, z)
		out.append(Vector3(p.x, p.z, depth * 0.62))
	return out


## Ekrandaki bir nokta dükkânın üstünde mi (köşelerinin ekrandaki dış zarfı, biraz paylı)?
func hit(view: Camera3D, screen: Vector2) -> bool:
	return _hull_hit(view, screen, _outline, TOUCH_PX)


## Ekrandaki bir nokta akvaryumun (tank ve bağış kutusu) üstünde mi? Dükkânınkinden önce bakılır
## (dükkânın zarfı tankı da kapsar).
func tank_hit(view: Camera3D, screen: Vector2) -> bool:
	return _hull_hit(view, screen, _tank_outline, TANK_TOUCH_PX)


## Akvaryumun ekrandaki kutusu (köşelerinin sınırları; bot dokunma alanının boyunu ölçer).
func tank_screen_rect(view: Camera3D) -> Rect2:
	var rect := Rect2()
	for i in _tank_outline.size():
		var p := view.unproject_position(to_global(_tank_outline[i]))
		rect = Rect2(p, Vector2.ZERO) if i == 0 else rect.expand(p)
	return rect


func _hull_hit(view: Camera3D, screen: Vector2, outline: Array[Vector3], touch_px: float) -> bool:
	if not is_visible_in_tree() or view == null or outline.is_empty():
		return false
	var points := PackedVector2Array()
	for local in outline:
		var p := to_global(local)
		if view.is_position_behind(p):
			return false
		points.append(view.unproject_position(p))
	var hull := Geometry2D.convex_hull(points)
	if Geometry2D.is_point_in_polygon(screen, hull):
		return true
	var pad := touch_px * view.get_viewport().get_visible_rect().size.y / 1080.0
	for i in hull.size() - 1:
		if Geometry2D.get_closest_point_to_segment(screen, hull[i], hull[i + 1]).distance_to(screen) <= pad:
			return true
	return false


# --- Kurulum ---------------------------------------------------------------------

## Dükkânın tek ağı: eskisi varsa yerine yenisi (aynı ad; eskisi hemen ağaçtan çıkar). Balıksız parçalar bir kez
## kurulur (_base); balıklar her seferinde eklenir (MeshBatch.add_mesh: toplu dönüşüm).
func _build_mesh() -> void:
	if _mesh != null:
		remove_child(_mesh)
		_mesh.queue_free()
	if _base == null:
		_base = MeshBatch.new()
		_build_floor(_base)
		_build_wall(_base)
		_build_counter(_base)
		_build_aquarium(_base)
		_build_rod_rack(_base)
		_build_awning(_base)
		_build_sign(_base)
	var batch := MeshBatch.new()
	batch.append(_base)
	_add_tank_fish(batch)
	_mesh = batch.build(self, "Stall")
	_mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON


## Tezgâhın üst tahtasının üstü (eşyalar buna oturur).
static func _counter_top() -> float:
	return FLOOR + COUNTER_H + 0.05

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
	# Nine'nin defteri (açık, iki sayfa) ve kalem: tezgâhın sağında.
	batch.box(Vector3(0.34, 0.025, 0.24), Vector3(0.42, on + 0.0125, COUNTER_Z + 0.02), WOOD_DARK, Vector3(0, 0.18, 0))
	batch.box(Vector3(0.15, 0.012, 0.21), Vector3(0.35, on + 0.031, COUNTER_Z + 0.03), Color("#f3ead2"), Vector3(0, 0.18, 0.03))
	batch.box(Vector3(0.15, 0.012, 0.21), Vector3(0.5, on + 0.031, COUNTER_Z + 0.0), Color("#f3ead2"), Vector3(0, 0.18, -0.03))
	batch.cylinder(0.006, 0.006, 0.16, Vector3(0.62, on + 0.035, COUNTER_Z + 0.12), Color("#c0392b"), 6, Vector3(PI * 0.5, 0.9, 0))
	# Pirinç zil.
	batch.cylinder(0.05, 0.05, 0.015, Vector3(0.88, on + 0.008, COUNTER_Z + 0.06), WOOD_DARK, 10)
	batch.sphere(0.055, Vector3(0.88, on + 0.04, COUNTER_Z + 0.06), BRASS, Vector3(1.0, 0.85, 1.0))
	batch.sphere(0.015, Vector3(0.88, on + 0.095, COUNTER_Z + 0.06), BRASS)


## Akvaryumun dolabının üstü (tankın tabanı; yerel y): zeminin en yüksek yerinden TANK_STAND yukarıda.
func _tank_top() -> float:
	return _tank_ground.y + TANK_STAND


## Tankın altındaki zemin (yerel y): dolabın köşelerinde ve ortasında; en alçağı ve en yükseği. Zemin verilmezse
## döşemenin hizası (testler).
func _ground_under_tank(ground_at: Callable) -> Vector2:
	if not ground_at.is_valid():
		return Vector2.ZERO
	var low := INF
	var high := -INF
	for u: float in [-0.5, 0.0, 0.5]:
		for v: float in [-0.5, 0.0, 0.5]:
			var local := Vector3(TANK_X + u * TANK_W, 0.0, TANK_Z + TANK_LEDGE * 0.5 + v * (TANK_D + TANK_LEDGE))
			var world := transform * local
			var y := float(ground_at.call(Vector2(world.x, world.z))) - position.y
			low = minf(low, y)
			high = maxf(high, y)
	return Vector2(low, high)


## Akvaryum: ahşap dolap (önünde raf ve bağış kutusu), üstünde koyu çerçeveli tank. Arka ve sağ duvar su (opak,
## yukarıdan aşağı koyulaşan), dibi kum, taşlar ve bitkiler; ön ve sol yüz cam: çerçeve, köşe parıltıları ve suyun
## yüzeyinin çizgisi. Balıklar içeride gerçek boylarında (_layout).
func _build_aquarium(batch: MeshBatch) -> void:
	var half := TANK_W * 0.5
	var x0 := TANK_X - half
	var x1 := TANK_X + half
	var back := TANK_Z - TANK_D * 0.5
	var front := TANK_Z + TANK_D * 0.5
	var top := _tank_top()
	# Dolap: gövde, zemine inen etek, öndeki kapak çıtaları, raf.
	var cabinet_h := top - _tank_ground.x + 0.08
	batch.box(Vector3(TANK_W + 0.1, cabinet_h, TANK_D + 0.08), Vector3(TANK_X, top - cabinet_h * 0.5, TANK_Z), WOOD)
	for i in 4:
		var x := x0 + TANK_W * (i + 0.5) / 4.0
		batch.box(Vector3(TANK_W / 4.0 - 0.08, TANK_STAND - 0.14, 0.02), Vector3(x, top - TANK_STAND * 0.5, front + 0.05),
				WOOD_LIGHT)
		batch.sphere(0.022, Vector3(x + TANK_W / 8.0 - 0.1, top - TANK_STAND * 0.5, front + 0.07), BRASS)
	batch.box(Vector3(TANK_W + 0.16, 0.05, TANK_D + 0.14), Vector3(TANK_X, top - 0.025, TANK_Z), WOOD_DARK)
	var ledge_y := top - TANK_STAND * 0.42
	batch.box(Vector3(TANK_W + 0.1, 0.05, TANK_LEDGE + 0.04), Vector3(TANK_X, ledge_y, front + TANK_LEDGE * 0.5 + 0.04),
			WOOD_DARK)
	# Bağış kutusu: raf ağzında, sağ uçta (dükkâna yakın); para yuvası ve önünde pirinç para.
	var box_x := x1 - 0.22
	var box_z := front + 0.04 + TANK_LEDGE * 0.5
	var box_y := ledge_y + 0.025
	batch.box(BOX_SIZE, Vector3(box_x, box_y + BOX_SIZE.y * 0.5, box_z), BOX_COLOR)
	batch.box(Vector3(BOX_SIZE.x + 0.02, 0.025, BOX_SIZE.z + 0.02), Vector3(box_x, box_y + BOX_SIZE.y + 0.012, box_z), WOOD_DARK)
	batch.box(Vector3(0.09, 0.006, 0.016), Vector3(box_x, box_y + BOX_SIZE.y + 0.026, box_z), Color("#1c1410"))
	batch.cylinder(0.045, 0.045, 0.01, Vector3(box_x, box_y + BOX_SIZE.y * 0.5, box_z + BOX_SIZE.z * 0.5 + 0.004), BRASS, 12,
			Vector3(PI * 0.5, 0.0, 0.0))
	# Kum, arka ve sağ duvar (su): yukarıdan aşağı üç şerit, açıktan koyuya.
	var sand_top := top + TANK_SAND
	batch.box(Vector3(TANK_W - 0.02, TANK_SAND, TANK_D - 0.02), Vector3(TANK_X, top + TANK_SAND * 0.5, TANK_Z), SAND)
	var water_h := TANK_H - 0.12
	var bands: Array[Color] = [WATER_DEEP, WATER, WATER_TOP]
	for i in bands.size():
		var h := water_h / bands.size()
		var y := top + h * (i + 0.5)
		batch.box(Vector3(TANK_W - 0.02, h, 0.03), Vector3(TANK_X, y, back + 0.025), bands[i])
		batch.box(Vector3(0.03, h, TANK_D - 0.04), Vector3(x1 - 0.025, y, TANK_Z), bands[i])
	var water_top := top + water_h
	# Suyun yüzeyinin çizgisi (camın içinde, ön ve sol kenar) ve köşe parıltıları.
	batch.box(Vector3(TANK_W - 0.04, 0.025, 0.02), Vector3(TANK_X, water_top, front - 0.02), WATER_TOP)
	batch.box(Vector3(0.02, 0.025, TANK_D - 0.04), Vector3(x0 + 0.02, water_top, TANK_Z), WATER_TOP)
	for spec: Vector3 in [Vector3(x0 + 0.16, 0.5, 0.14), Vector3(x0 + 0.24, 0.36, 0.14), Vector3(x1 - 0.3, 0.55, 0.14)]:
		batch.box(Vector3(0.025, TANK_H * spec.y, 0.008), Vector3(spec.x, top + TANK_H * 0.48, front + 0.004), GLASS,
				Vector3(0.0, 0.0, spec.z))
	# Çerçeve: dört köşe dikmesi, üst ve alt kenarlar.
	var frame := 0.045
	for sx: float in [-1.0, 1.0]:
		for sz: float in [-1.0, 1.0]:
			batch.box(Vector3(frame, TANK_H, frame), Vector3(TANK_X + sx * half, top + TANK_H * 0.5, TANK_Z + sz * TANK_D * 0.5),
					TANK_FRAME)
	for y: float in [top + 0.02, top + TANK_H]:
		for sz: float in [-1.0, 1.0]:
			batch.box(Vector3(TANK_W + frame, frame, frame), Vector3(TANK_X, y, TANK_Z + sz * TANK_D * 0.5), TANK_FRAME)
		for sx: float in [-1.0, 1.0]:
			batch.box(Vector3(frame, frame, TANK_D), Vector3(TANK_X + sx * half, y, TANK_Z), TANK_FRAME)
	# Taşlar ve bitkiler (arkada ve uçlarda: balıkların önünü kapatmasın).
	for spec: Array in [[x0 + 0.35, back + 0.2, 0.16], [x1 - 0.45, back + 0.18, 0.2], [TANK_X + 0.3, back + 0.14, 0.11]]:
		batch.sphere(float(spec[2]), Vector3(float(spec[0]), sand_top + float(spec[2]) * 0.3, float(spec[1])), Color("#8a8f94"),
				Vector3(1.5, 0.8, 1.0), 10, 5)
	var plants: Array[Array] = [[x0 + 0.12, back + 0.12, 0.85, 0.1], [x0 + 0.22, back + 0.2, 0.6, -0.2],
			[x1 - 0.14, back + 0.1, 0.8, -0.12], [x1 - 0.22, back + 0.24, 0.55, 0.22], [TANK_X - 0.5, back + 0.1, 0.5, 0.15],
			[TANK_X + 0.62, back + 0.1, 0.65, -0.1]]
	for i in plants.size():
		var spec: Array = plants[i]
		var h := float(spec[2]) * (water_h - TANK_SAND)
		batch.box(Vector3(0.05, h, 0.02), Vector3(float(spec[0]), sand_top + h * 0.5, float(spec[1])),
				PLANT if i % 2 == 0 else PLANT_LIGHT, Vector3(0.0, 0.3 * i, float(spec[3])))
	# Kabarcıklar (sol uçta, yüzeye doğru).
	for i in 5:
		batch.sphere(0.018 + 0.004 * (i % 2), Vector3(x0 + 0.3 + 0.03 * sin(i * 1.7), sand_top + 0.15 + i * 0.17, front - 0.18),
				Color("#e8f7fb"), Vector3.ONE, 6, 3)


## Tanktaki balıklar: gerçek boylarında, derin suyun rengine biraz karışmış; iki yüzlü (yüzgeçler tek yüzlü üçgen).
## Renkler sRGB okunur (balığın gölgelendiricisi onları doğrusal okur, elde daha açık görünür): camın ardında biraz
## koyu ve doygun.
func _add_tank_fish(batch: MeshBatch) -> void:
	for place: Dictionary in _layout():
		var def: Dictionary = place["def"]
		var length := float(place["length"])
		var heading := float(place["heading"])
		var basis := Basis(Vector3.UP, heading) * Basis(Vector3.FORWARD, float(place["pitch"])) * Basis.from_scale(Vector3.ONE * length)
		batch.add_mesh(FishMesh.mesh_for(def), Transform3D(basis, place["center"]), false, WATER_DEEP, TANK_TINT, true)


## Tanktaki balıkların yeri: en irisi önce; yükseklikleri sırayla dağılır (iri olan ortaya), derinlikleri öne ve
## arkaya, yatay yerleri ve yönleri türün tohumuyla (her açılışta aynı). Boy gerçek (cm / 100), tanka sığacak kadar
## (TANK_FISH_PAD); kerevit kumda, önde. Döner: [{def, center (yerel), length, heading, pitch}].
func _layout() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if _tank_fish.is_empty():
		return out
	var half := TANK_W * 0.5
	var inner := TANK_W - TANK_FISH_PAD * 2.0
	var top := _tank_top()
	var floor_y := top + TANK_SAND
	var water_top := top + TANK_H - 0.12
	var order: Array[Dictionary] = []
	order.assign(_tank_fish)
	order.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return int(a["size_cm"]) > int(b["size_cm"]))
	var swimmers := 0
	for f in order:
		if not FishMesh.is_crayfish(f["def"]):
			swimmers += 1
	var lanes: Array[float] = []
	# Yükseklik sırası: ilk (en iri) ortada, sonrakiler üste ve alta dönüşümlü.
	for i in swimmers:
		var step := ceili(i / 2.0) * (1.0 if i % 2 == 1 else -1.0)
		lanes.append(0.5 + step / float(maxi(2, swimmers)))
	var lane := 0
	for f in order:
		var def: Dictionary = f["def"]
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(str(def.get("id", ""))) ^ 4411
		var length := minf(float(f["size_cm"]) / 100.0, inner)
		var dir := -1.0 if rng.randf() < 0.5 else 1.0
		var heading := (0.0 if dir > 0.0 else PI) + rng.randf_range(-0.35, 0.35)
		if FishMesh.is_crayfish(def):
			var cx := TANK_X - half + 0.35 + rng.randf_range(0.0, 0.5)
			out.append({ "def": def, "length": length, "heading": heading, "pitch": 0.0,
					"center": Vector3(cx, floor_y + length * 0.12, TANK_Z + TANK_D * 0.5 - 0.16) })
			continue
		var body_h := length * 0.24
		var low := floor_y + body_h * 0.5 + 0.04
		var high := water_top - body_h * 0.5 - 0.04
		var y := lerpf(low, high, clampf(lanes[lane], 0.0, 1.0)) if high > low else (low + high) * 0.5
		var depth := TANK_D * 0.5 - 0.12 - length * 0.12
		var z := TANK_Z + (depth if lane % 2 == 0 else -depth * 0.6)
		var reach := maxf(0.0, inner * 0.5 - length * 0.5)
		var x := TANK_X + rng.randf_range(-reach, reach)
		lane += 1
		out.append({ "def": def, "length": length, "heading": heading, "pitch": rng.randf_range(-0.08, 0.08),
				"center": Vector3(x, y, z) })
	return out


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
	# Yazı bir kez kurulur (ağ yeniden kurulunca yazı yerinde kalır).
	if _sign != null:
		return
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
