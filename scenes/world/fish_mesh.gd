class_name FishMesh
extends MeshInstance3D
## Kodla kurulan balık (docs/gdd.md §8): gövde (elips kesitler), kuyruk, sırt, yan ve karın
## yüzgeçleri, iri gözler. Oranlar: boy / yükseklik 2,2 (turnada 3), en yüksek nokta boyun
## %35'inde, küt burun; genişlik yüksekliğin 0,6'sı; kuyruk sapı yüksekliğin 0,22'si; kuyruk
## açıklığı 0,9 × yükseklik; göz yarıçapı boyun 0,075'i, burundan %16'da. Renk: koyu sırt, açık
## karın, türün vurgusu yüzgeçlerde (data/fish.json: back, color, accent).
## Model yerel +X'e bakar, toplam boyu 1 birimdir (ölçekle büyütülür). Yüzme kıvrılması ve dış
## çizgi fish.gdshader / fish_outline.gdshader'da.

const RINGS := 14
const SIDES := 12
## Burundan kuyruk sapına gövde; gerisi kuyruk yüzgeci.
const BODY := 0.78
const NOSE_X := 0.5
## Türe göre biçim: ratio (boy / yükseklik), nose (burnun sivriliği: büyük = küt, 1'in altı sivri
## burun), eye (göz yarıçapı / boy), iris (gözün rengi; yoksa beyaz), stripes (dikey çizgi sayısı) ve
## stripe_strength (koyuluğu), whiskers (bıyık), barbels (burnun altından sarkan dört kısa bıyık),
## flat (baş basıklığı), thin (genişlik / yükseklik), stem (kuyruk sapının yüksekliği), lateral (yan
## şeridin rengi), patches (lekelerin rengi), scutes (sırt ve yan plakaların rengi), spots (sırt ve
## yanlardaki küçük beneklerin rengi: alabalıklar), mirror (aynalı sazanın iri, yassı pullarının
## rengi), dorsals (sırt yüzgeci sayısı), dorsal ([baş, son, tepe, yükseklik]: sırt yüzgecinin yeri),
## anal (uzun anal yüzgeç), low_fins (alt yüzgeçlerin rengi), fork (kuyruğun çatal derinliği),
## tail_tilt (üst lobu uzun kuyruk).
const SHAPES := {
	"rudd": { "ratio": 2.4, "nose": 2.4, "eye": 0.075 },
	"carp": { "ratio": 2.2, "nose": 2.6, "eye": 0.065, "whiskers": 0.12 },
	"perch": { "ratio": 2.5, "nose": 2.2, "eye": 0.075, "stripes": 5 },
	"pike": { "ratio": 3.4, "nose": 1.5, "eye": 0.06, "flat": 0.15 },
	"wels": { "ratio": 3.2, "nose": 2.8, "eye": 0.042, "whiskers": 0.45, "flat": 0.3 },
	"silverside": { "ratio": 4.4, "nose": 2.0, "eye": 0.095, "lateral": "#f6fcff", "dorsals": 2, "thin": 0.68 },
	"bream": { "ratio": 1.95, "nose": 1.9, "eye": 0.07, "thin": 0.42, "anal": true },
	"chub": { "ratio": 3.0, "nose": 1.9, "eye": 0.065, "flat": 0.12, "low_fins": "#e5632f" },
	"tench": { "ratio": 2.6, "nose": 2.5, "eye": 0.05, "iris": "#d4472b", "whiskers": 0.05, "stem": 0.36, "fork": 0.0 },
	"zander": { "ratio": 3.6, "nose": 1.8, "eye": 0.075, "iris": "#e9dfae", "stripes": 7, "stripe_strength": 0.4,
		"dorsals": 2 },
	"golden_carp": { "ratio": 2.25, "nose": 2.6, "eye": 0.065, "whiskers": 0.12, "patches": "#f7f1e6" },
	"sturgeon": { "ratio": 4.4, "nose": 0.85, "eye": 0.034, "flat": 0.4, "scutes": "#ece7d8", "barbels": 0.08,
		"dorsal": [0.72, 0.9, 0.78, 0.6], "tail_tilt": 0.55, "fork": 0.12 },
	"mirror_carp": { "ratio": 2.0, "nose": 2.6, "eye": 0.06, "whiskers": 0.12, "thin": 0.68, "mirror": "#f3d58a" },
	"trout": { "ratio": 3.3, "nose": 2.0, "eye": 0.07, "lateral": "#ef8fa6", "spots": "#2e2a1e", "fork": 0.04 },
	"brook_trout": { "ratio": 3.1, "nose": 2.1, "eye": 0.068, "flat": 0.08, "spots": "#e04a2f", "low_fins": "#e8743a",
		"fork": 0.03 },
}
const DEFAULT_SHAPE := { "ratio": 2.2, "nose": 2.4, "eye": 0.075 }
## Dış çizginin dünyadaki kalınlığı (m).
const OUTLINE_M := 0.012

static var _meshes: Dictionary = {}
static var _material: ShaderMaterial


## Türün (ContentDB fish tanımı) balığı; toplam boyu length metre.
static func make(def: Dictionary, length: float) -> FishMesh:
	var node := FishMesh.new()
	node.mesh = mesh_for(def)
	node.material_override = _shared_material()
	node.scale = Vector3.ONE * length
	node.set_instance_shader_parameters_safe(length)
	return node


## Elde gösterilen boy (m): logaritmik büyür (küçük balık da seçilsin); 15 cm'lik balık 0,3 m,
## 250 cm'lik yayın en fazla 1,1 m.
static func display_length(size_cm: int) -> float:
	return minf(1.1, 0.3 * pow(maxf(float(size_cm), 5.0) / 15.0, 0.55))


func set_instance_shader_parameters_safe(length: float) -> void:
	# Kıvrılmanın genliği modelin kendi biriminde (boy 1); ölçek düğümde.
	var material := (material_override as ShaderMaterial).duplicate() as ShaderMaterial
	material.next_pass = (material.next_pass as ShaderMaterial).duplicate()
	material.set_shader_parameter("fish_length", 1.0)
	(material.next_pass as ShaderMaterial).set_shader_parameter("fish_length", 1.0)
	# Dış çizgi dünyada ~12 mm (modelin biriminde, ölçeğe bölünür): telefonda ve portrede seçilsin.
	(material.next_pass as ShaderMaterial).set_shader_parameter("outline_width", OUTLINE_M / maxf(length, 0.2))
	material_override = material


## Çırpınma: genlik (boyun oranı) ve hız.
func set_wiggle(amount: float, speed: float) -> void:
	var material := material_override as ShaderMaterial
	for m: ShaderMaterial in [material, material.next_pass as ShaderMaterial]:
		m.set_shader_parameter("wiggle", amount)
		m.set_shader_parameter("wiggle_speed", speed)


static func _shared_material() -> ShaderMaterial:
	if _material == null:
		_material = ShaderMaterial.new()
		_material.shader = load("res://scenes/world/fish.gdshader")
		var outline := ShaderMaterial.new()
		outline.shader = load("res://scenes/world/fish_outline.gdshader")
		_material.next_pass = outline
	return _material


static func mesh_for(def: Dictionary) -> ArrayMesh:
	var id := str(def.get("id", ""))
	if _meshes.has(id):
		return _meshes[id]
	var shape: Dictionary = SHAPES.get(id, DEFAULT_SHAPE)
	var builder := _Builder.new(def, shape)
	var mesh := builder.build()
	_meshes[id] = mesh
	return mesh


## Ağ kurucusu: gövde halkaları, yüzgeçler, gözler ve bıyıklar.
class _Builder:
	var st := SurfaceTool.new()
	var back: Color
	var body: Color
	var belly: Color
	var accent: Color
	var ratio: float
	var nose: float
	var eye: float
	var stripes: int
	var stripe_strength: float
	var whiskers: float
	var barbels: float
	var flat: float
	var thin: float
	var stem: float
	var half_h: float
	var iris: Color
	var low_fins: Color
	## Yan şerit, leke ve plaka renkleri (alfa 0 = yok).
	var lateral := Color(0, 0, 0, 0)
	var patches := Color(0, 0, 0, 0)
	var scutes := Color(0, 0, 0, 0)
	var mirror := Color(0, 0, 0, 0)
	var spots := Color(0, 0, 0, 0)
	var dorsals: int
	var dorsal: Array
	var anal: bool
	var fork: float
	var tail_tilt: float

	func _init(def: Dictionary, shape: Dictionary) -> void:
		body = def.get("color", Color("#9fb3c8"))
		back = def.get("back", body.darkened(0.45))
		accent = def.get("accent", body)
		belly = body.lightened(0.5)
		ratio = float(shape.get("ratio", 2.2))
		nose = float(shape.get("nose", 2.4))
		eye = float(shape.get("eye", 0.075))
		iris = Color(str(shape.get("iris", "#fbfbf6")))
		stripes = int(shape.get("stripes", 0))
		stripe_strength = float(shape.get("stripe_strength", 0.7))
		whiskers = float(shape.get("whiskers", 0.0))
		barbels = float(shape.get("barbels", 0.0))
		flat = float(shape.get("flat", 0.0))
		thin = float(shape.get("thin", 0.6))
		stem = float(shape.get("stem", 0.22))
		low_fins = Color(str(shape["low_fins"])) if shape.has("low_fins") else accent
		if shape.has("lateral"):
			lateral = Color(str(shape["lateral"]))
		if shape.has("patches"):
			patches = Color(str(shape["patches"]))
		if shape.has("scutes"):
			scutes = Color(str(shape["scutes"]))
		if shape.has("mirror"):
			mirror = Color(str(shape["mirror"]))
		if shape.has("spots"):
			spots = Color(str(shape["spots"]))
		dorsals = int(shape.get("dorsals", 1))
		dorsal = shape.get("dorsal", [0.32, 0.62, 0.4, 0.45])
		anal = bool(shape.get("anal", false))
		fork = float(shape.get("fork", 0.07))
		tail_tilt = float(shape.get("tail_tilt", 0.0))
		half_h = 0.5 / ratio

	func build() -> ArrayMesh:
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		_body()
		_tail()
		_fins()
		for side: float in [-1.0, 1.0]:
			_eye(side)
		if whiskers > 0.0:
			for side: float in [-1.0, 1.0]:
				_whisker(side)
		if barbels > 0.0:
			_barbels()
		if scutes.a > 0.0:
			_scutes()
		if mirror.a > 0.0:
			_mirror_scales()
		if spots.a > 0.0:
			_spots()
		st.generate_normals()
		return st.commit()

	## t: 0 burun, 1 kuyruk sapı. Yarım yükseklik.
	func height_at(t: float) -> float:
		if t <= 0.35:
			var u := clampf((0.35 - t) / 0.35, 0.0, 1.0)
			return half_h * pow(maxf(1.0 - pow(u, nose), 0.0), 1.0 / nose)
		var v := (t - 0.35) / 0.65
		return half_h * (1.0 - (1.0 - stem) * smoothstep(0.0, 1.0, v))

	## Yarım genişlik: yüksekliğin 0,6'sı (thin); basık başlı türlerde önde daha geniş, daha alçak.
	func width_at(t: float) -> float:
		var head := 1.0 - smoothstep(0.1, 0.45, t)
		return height_at(t) * thin * (1.0 + flat * 0.8 * head)

	func height_scaled(t: float) -> float:
		var head := 1.0 - smoothstep(0.1, 0.45, t)
		return height_at(t) * (1.0 - flat * 0.35 * head)

	func x_at(t: float) -> float:
		return NOSE_X - t * BODY

	func ring_point(t: float, a: float) -> Vector3:
		return Vector3(x_at(t), cos(a) * height_scaled(t), sin(a) * width_at(t))

	func ring_color(t: float, a: float) -> Color:
		var up := cos(a)
		var c := belly.lerp(body, smoothstep(-0.9, 0.05, up))
		c = c.lerp(back, smoothstep(0.35, 0.95, up))
		if stripes > 0 and t > 0.25 and t < 0.9 and up > -0.3:
			var band := sin((t - 0.25) / 0.65 * PI * stripes)
			if band > 0.55:
				c = c.lerp(back.darkened(0.25), stripe_strength)
		# Yan şerit: gövdenin ortasında, burundan kuyruğa parlak bant.
		if lateral.a > 0.0 and t > 0.12 and t < 0.97:
			c = c.lerp(lateral, 0.85 * (1.0 - smoothstep(0.0, 0.45, absf(up))))
		# Koi lekeleri: sırtta ve yanlarda düzensiz beyaz adalar (köşe renkleriyle yumuşak kenarlı).
		if patches.a > 0.0 and up > -0.6:
			var n := sin(t * 9.0 + 0.7) * sin(a * 2.0 + t * 5.0 + 1.1) + 0.45 * sin(a * 3.0 - t * 13.0)
			if n > 0.3:
				c = c.lerp(patches, 0.9)
		return c

	func _body() -> void:
		var tip := Vector3(NOSE_X + 0.01, 0.0, 0.0)
		for i in RINGS:
			var t0 := float(i) / RINGS
			var t1 := float(i + 1) / RINGS
			for k in SIDES:
				var a0 := TAU * k / SIDES
				var a1 := TAU * (k + 1) / SIDES
				var p00 := tip if i == 0 else ring_point(t0, a0)
				var p01 := tip if i == 0 else ring_point(t0, a1)
				var p10 := ring_point(t1, a0)
				var p11 := ring_point(t1, a1)
				var c0 := ring_color(t0, a0)
				var c1 := ring_color(t1, a1)
				_tri(p00, p10, p11, c0, ring_color(t1, a0), c1)
				if i > 0:
					_tri(p00, p11, p01, c0, c1, ring_color(t0, a1))
		# Kuyruk sapını kapat.
		var end := Vector3(x_at(1.0), 0.0, 0.0)
		for k in SIDES:
			var a0 := TAU * k / SIDES
			var a1 := TAU * (k + 1) / SIDES
			_tri(end, ring_point(1.0, a1), ring_point(1.0, a0), body, body, body)

	## Çatallı kuyruk yüzgeci: kuyruk sapından açılan iki dilim; açıklık 0,9 × yükseklik. fork 0
	## düz kuyruk (kadife); tail_tilt üst lobu uzun, alt lobu kısa kuyruk (mersin).
	func _tail() -> void:
		var base_x := x_at(1.0) + 0.02
		var stem_h := height_at(1.0)
		var spread := half_h * 0.9 * 2.0 * 0.5
		var end_x := NOSE_X - 1.0
		var notch := Vector3(end_x + fork, 0.0, 0.0)
		var top := Vector3(end_x, spread * (1.0 + tail_tilt), 0.0)
		var bottom := Vector3(end_x + tail_tilt * 0.12, -spread * (1.0 - tail_tilt * 0.55), 0.0)
		var b_top := Vector3(base_x, stem_h, 0.0)
		var b_bottom := Vector3(base_x, -stem_h, 0.0)
		var tint := accent.darkened(0.1)
		_quad(b_top, top, notch, Vector3(base_x, 0.0, 0.0), tint)
		_quad(Vector3(base_x, 0.0, 0.0), notch, bottom, b_bottom, tint)

	func _fins() -> void:
		var tint := accent
		# Sırt yüzgeci (iki sırt yüzgeçli türde önde sivri, arkada alçak ikincisi).
		if dorsals >= 2:
			_dorsal(0.26, 0.46, 0.31, 0.55, tint)
			_dorsal(0.5, 0.72, 0.56, 0.36, tint)
		else:
			_dorsal(float(dorsal[0]), float(dorsal[1]), float(dorsal[2]), float(dorsal[3]), tint)
		# Karın (anal) yüzgeci; çapakta uzun.
		var a0 := 0.48 if anal else 0.62
		var a_apex := 0.58 if anal else 0.74
		var b0 := Vector3(x_at(a0), -height_scaled(a0) * 0.92, 0.0)
		var b1 := Vector3(x_at(0.8), -height_scaled(0.8) * 0.92, 0.0)
		var low := Vector3(x_at(a_apex), -height_scaled(a_apex) - half_h * (0.22 if anal else 0.3), 0.0)
		_tri(b0, low, b1, low_fins, low_fins, low_fins)
		# Yan yüzgeçler: gözün gerisinde, geriye ve aşağıya.
		for side: float in [-1.0, 1.0]:
			var root := Vector3(x_at(0.3), -height_scaled(0.3) * 0.25, side * width_at(0.3) * 0.95)
			var a := root + Vector3(-0.14, -half_h * 0.35, side * 0.05)
			var b := root + Vector3(-0.05, -half_h * 0.45, side * 0.09)
			_tri(root, a, b, low_fins, low_fins, low_fins)

	## Sırt yüzgeci: t0..t1 arasında, tepesi apex_t'de, yüksekliği yarım boyun height katı.
	func _dorsal(t0: float, t1: float, apex_t: float, height: float, tint: Color) -> void:
		var p0 := Vector3(x_at(t0), height_scaled(t0) * 0.92, 0.0)
		var p1 := Vector3(x_at(t1), height_scaled(t1) * 0.92, 0.0)
		var apex := Vector3(x_at(apex_t), height_scaled(apex_t) + half_h * height, 0.0)
		_tri(p0, apex, p1, tint, tint, tint)

	func _eye(side: float) -> void:
		var t := 0.16
		var r := eye
		var center := Vector3(x_at(t), height_scaled(t) * 0.22, side * width_at(t) * 0.78)
		_sphere(center, r, iris, 8, 6)
		var out := Vector3(0.12, 0.05, side).normalized()
		_sphere(center + out * r * 0.55, r * 0.55, Color("#1d1f24"), 8, 6)
		_sphere(center + out * r * 0.95 + Vector3(0.0, r * 0.35, 0.0), r * 0.18, Color.WHITE, 6, 4)

	## Bıyık: ağzın yanından geriye ve aşağıya incelen ince boru.
	func _whisker(side: float) -> void:
		var start := Vector3(NOSE_X - 0.02, -height_scaled(0.05) * 0.4, side * width_at(0.05) * 0.8)
		var finish := start + Vector3(-whiskers, -whiskers * 0.35, side * whiskers * 0.35)
		_tube(start, finish, 0.012, back.darkened(0.2))

	## Mersinin bıyıkları: sivri burnun altından aşağı sarkan dört kısa ve açık renkli bıyık.
	func _barbels() -> void:
		var t := 0.09
		for side: float in [-1.0, -0.35, 0.35, 1.0]:
			var start := Vector3(x_at(t), -height_scaled(t) * 0.8, side * width_at(t) * 0.7)
			var finish := start + Vector3(-barbels * 0.25, -barbels, side * barbels * 0.15)
			_tube(start, finish, 0.006, belly.darkened(0.15))

	## Mersinin plakaları: sırtta (sırt yüzgecine kadar) ve iki yanda sıra sıra küçük kemik kabarcıkları.
	func _scutes() -> void:
		var count := 12
		for row: Array in [[0.0, 0.66], [PI * 0.5, 0.92], [PI * 1.5, 0.92]]:
			var a: float = row[0]
			for i in count:
				var t := lerpf(0.2, float(row[1]), float(i) / (count - 1))
				var r := height_scaled(t) * 0.2
				var out := Vector3(0.0, cos(a), sin(a))
				_sphere(ring_point(t, a) + out * r * 0.25, r, scutes, 5, 3)

	## Aynalı sazanın pulları: iki yanda yan çizgi boyunca ve sırtın iki yanında birkaç iri, parlak,
	## yassı pul (yüzeye yatık).
	func _mirror_scales() -> void:
		var rows: Array = [[PI * 0.5, [0.3, 0.46, 0.62, 0.78]], [PI * 1.5, [0.34, 0.5, 0.68]],
				[PI * 0.2, [0.4, 0.58]], [TAU - PI * 0.2, [0.36, 0.54]]]
		for row: Array in rows:
			var a: float = row[0]
			for t: float in row[1]:
				_disc(ring_point(t, a), Vector3(0.0, cos(a), sin(a)), height_scaled(t) * 0.24, mirror)

	## Alabalığın benekleri: sırtta ve yanların üst yarısında, burundan kuyruk sapına seyrek, sabit bir
	## düzende (her balıkta aynı; zar yok) küçük yassı lekeler.
	func _spots() -> void:
		var rows: Array = [[PI * 0.14, [0.34, 0.5, 0.66]], [PI * 0.3, [0.26, 0.41, 0.56, 0.71]],
				[PI * 0.46, [0.22, 0.36, 0.5, 0.64, 0.78]], [PI * 0.62, [0.3, 0.46, 0.62]]]
		for row: Array in rows:
			for a: float in [float(row[0]), TAU - float(row[0])]:
				for t: float in row[1]:
					_disc(ring_point(t, a), Vector3(0.0, cos(a), sin(a)), height_scaled(t) * 0.075, spots)

	## Yassı pul: n yönünde basık küre (dışı saat yönünde: küre noktalarıyla aynı el).
	func _disc(center: Vector3, n: Vector3, r: float, color: Color) -> void:
		var t1 := n.cross(Vector3.RIGHT)
		if t1.length() < 0.1:
			t1 = n.cross(Vector3.UP)
		t1 = t1.normalized()
		var t2 := t1.cross(n).normalized()
		var rings := 3
		var segments := 6
		for j in rings:
			var v0 := PI * j / rings
			var v1 := PI * (j + 1) / rings
			for k in segments:
				var u0 := TAU * k / segments
				var u1 := TAU * (k + 1) / segments
				var p00 := center + _squash(_spherical(u0, v0), t1, n, t2) * r
				var p01 := center + _squash(_spherical(u1, v0), t1, n, t2) * r
				var p10 := center + _squash(_spherical(u0, v1), t1, n, t2) * r
				var p11 := center + _squash(_spherical(u1, v1), t1, n, t2) * r
				_tri_as_is(p00, p10, p11, color, color, color)
				_tri_as_is(p00, p11, p01, color, color, color)

	static func _squash(p: Vector3, t1: Vector3, n: Vector3, t2: Vector3) -> Vector3:
		return t1 * p.x + n * (p.y * 0.3) + t2 * p.z

	## İncelen boru (bıyık): start'tan finish'e, kalınlığı r'den neredeyse sıfıra. Kesitin halkası
	## borunun çevresinde, gövde noktaları gibi dışarıdan bakınca saat yönünün tersine döner.
	func _tube(start: Vector3, finish: Vector3, r: float, color: Color) -> void:
		var dir := (finish - start).normalized()
		var u := dir.cross(Vector3.UP)
		if u.length() < 0.1:
			u = dir.cross(Vector3.RIGHT)
		u = u.normalized()
		var v := u.cross(dir).normalized()
		var steps := 4
		for i in steps:
			var a := start.lerp(finish, float(i) / steps)
			var b := start.lerp(finish, float(i + 1) / steps)
			var ra := r * (1.0 - float(i) / steps)
			var rb := r * (1.0 - float(i + 1) / steps) + r / 6.0
			for k in 5:
				var a0 := TAU * k / 5.0
				var a1 := TAU * (k + 1) / 5.0
				var o0 := u * cos(a0) + v * sin(a0)
				var o1 := u * cos(a1) + v * sin(a1)
				_quad(a + o0 * ra, b + o0 * rb, b + o1 * rb, a + o1 * ra, color)

	func _sphere(center: Vector3, r: float, color: Color, segments: int, rings: int) -> void:
		for j in rings:
			var v0 := PI * j / rings
			var v1 := PI * (j + 1) / rings
			for k in segments:
				var u0 := TAU * k / segments
				var u1 := TAU * (k + 1) / segments
				var p00 := center + _spherical(u0, v0) * r
				var p01 := center + _spherical(u1, v0) * r
				var p10 := center + _spherical(u0, v1) * r
				var p11 := center + _spherical(u1, v1) * r
				_tri_as_is(p00, p10, p11, color, color, color)
				_tri_as_is(p00, p11, p01, color, color, color)

	static func _spherical(u: float, v: float) -> Vector3:
		return Vector3(sin(v) * cos(u), cos(v), sin(v) * sin(u))

	## Üçgen. Gövde, kuyruk, yüzgeç ve bıyık noktaları dışarıdan bakınca saat yönünün tersine
	## sıralı; Godot'da ön yüz saat yönündedir: sıra burada çevrilir. Böylece normaller dışa
	## bakar ve dış çizgi kabuğu (NORMAL yönünde büyür) gövdenin dışına çıkar.
	func _tri(a: Vector3, b: Vector3, c: Vector3, ca: Color, cb: Color, cc: Color) -> void:
		_tri_as_is(a, c, b, ca, cc, cb)

	## Verilen sırayla (küre noktaları zaten saat yönünde).
	func _tri_as_is(a: Vector3, b: Vector3, c: Vector3, ca: Color, cb: Color, cc: Color) -> void:
		st.set_color(ca)
		st.add_vertex(a)
		st.set_color(cb)
		st.add_vertex(b)
		st.set_color(cc)
		st.add_vertex(c)

	func _quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, color: Color) -> void:
		_tri(a, b, c, color, color, color)
		_tri(a, c, d, color, color, color)
