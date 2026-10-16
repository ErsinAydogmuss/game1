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
## Türe göre biçim: ratio (boy / yükseklik), nose (burnun sivriliği: küçük = küt), eye (göz
## yarıçapı / boy), stripes (dikey çizgi sayısı), whiskers (bıyık), flat (baş basıklığı).
const SHAPES := {
	"rudd": { "ratio": 2.4, "nose": 2.4, "eye": 0.075 },
	"carp": { "ratio": 2.2, "nose": 2.6, "eye": 0.065, "whiskers": 0.12 },
	"perch": { "ratio": 2.5, "nose": 2.2, "eye": 0.075, "stripes": 5 },
	"pike": { "ratio": 3.4, "nose": 1.5, "eye": 0.06, "flat": 0.15 },
	"wels": { "ratio": 3.2, "nose": 2.8, "eye": 0.042, "whiskers": 0.45, "flat": 0.3 },
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
	var whiskers: float
	var flat: float
	var half_h: float

	func _init(def: Dictionary, shape: Dictionary) -> void:
		body = def.get("color", Color("#9fb3c8"))
		back = def.get("back", body.darkened(0.45))
		accent = def.get("accent", body)
		belly = body.lightened(0.5)
		ratio = float(shape.get("ratio", 2.2))
		nose = float(shape.get("nose", 2.4))
		eye = float(shape.get("eye", 0.075))
		stripes = int(shape.get("stripes", 0))
		whiskers = float(shape.get("whiskers", 0.0))
		flat = float(shape.get("flat", 0.0))
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
		st.generate_normals()
		return st.commit()

	## t: 0 burun, 1 kuyruk sapı. Yarım yükseklik.
	func height_at(t: float) -> float:
		if t <= 0.35:
			var u := clampf((0.35 - t) / 0.35, 0.0, 1.0)
			return half_h * pow(maxf(1.0 - pow(u, nose), 0.0), 1.0 / nose)
		var v := (t - 0.35) / 0.65
		return half_h * (1.0 - 0.78 * smoothstep(0.0, 1.0, v))

	## Yarım genişlik: yüksekliğin 0,6'sı; basık başlı türlerde önde daha geniş, daha alçak.
	func width_at(t: float) -> float:
		var head := 1.0 - smoothstep(0.1, 0.45, t)
		return height_at(t) * 0.6 * (1.0 + flat * 0.8 * head)

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
				c = c.lerp(back.darkened(0.25), 0.7)
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

	## Çatallı kuyruk yüzgeci: kuyruk sapından açılan iki dilim; açıklık 0,9 × yükseklik.
	func _tail() -> void:
		var base_x := x_at(1.0) + 0.02
		var stem := height_at(1.0)
		var spread := half_h * 0.9 * 2.0 * 0.5
		var end_x := NOSE_X - 1.0
		var notch := Vector3(end_x + 0.07, 0.0, 0.0)
		var top := Vector3(end_x, spread, 0.0)
		var bottom := Vector3(end_x, -spread, 0.0)
		var b_top := Vector3(base_x, stem, 0.0)
		var b_bottom := Vector3(base_x, -stem, 0.0)
		var tint := accent.darkened(0.1)
		_quad(b_top, top, notch, Vector3(base_x, 0.0, 0.0), tint)
		_quad(Vector3(base_x, 0.0, 0.0), notch, bottom, b_bottom, tint)

	func _fins() -> void:
		var tint := accent
		# Sırt yüzgeci.
		var d0 := 0.32
		var d1 := 0.62
		var p0 := Vector3(x_at(d0), height_scaled(d0) * 0.92, 0.0)
		var p1 := Vector3(x_at(d1), height_scaled(d1) * 0.92, 0.0)
		var apex := Vector3(x_at(0.4), height_scaled(0.4) + half_h * 0.45, 0.0)
		_tri(p0, apex, p1, tint, tint, tint)
		# Karın yüzgeci.
		var b0 := Vector3(x_at(0.62), -height_scaled(0.62) * 0.92, 0.0)
		var b1 := Vector3(x_at(0.8), -height_scaled(0.8) * 0.92, 0.0)
		var low := Vector3(x_at(0.74), -height_scaled(0.74) - half_h * 0.3, 0.0)
		_tri(b0, low, b1, tint, tint, tint)
		# Yan yüzgeçler: gözün gerisinde, geriye ve aşağıya.
		for side: float in [-1.0, 1.0]:
			var root := Vector3(x_at(0.3), -height_scaled(0.3) * 0.25, side * width_at(0.3) * 0.95)
			var a := root + Vector3(-0.14, -half_h * 0.35, side * 0.05)
			var b := root + Vector3(-0.05, -half_h * 0.45, side * 0.09)
			_tri(root, a, b, tint, tint, tint)

	func _eye(side: float) -> void:
		var t := 0.16
		var r := eye
		var center := Vector3(x_at(t), height_scaled(t) * 0.22, side * width_at(t) * 0.78)
		_sphere(center, r, Color("#fbfbf6"), 8, 6)
		var out := Vector3(0.12, 0.05, side).normalized()
		_sphere(center + out * r * 0.55, r * 0.55, Color("#1d1f24"), 8, 6)
		_sphere(center + out * r * 0.95 + Vector3(0.0, r * 0.35, 0.0), r * 0.18, Color.WHITE, 6, 4)

	## Bıyık: ağzın yanından geriye ve aşağıya incelen ince boru.
	func _whisker(side: float) -> void:
		var start := Vector3(NOSE_X - 0.02, -height_scaled(0.05) * 0.4, side * width_at(0.05) * 0.8)
		var finish := start + Vector3(-whiskers, -whiskers * 0.35, side * whiskers * 0.35)
		var dark := back.darkened(0.2)
		var steps := 4
		for i in steps:
			var a := start.lerp(finish, float(i) / steps)
			var b := start.lerp(finish, float(i + 1) / steps)
			var ra := 0.012 * (1.0 - float(i) / steps)
			var rb := 0.012 * (1.0 - float(i + 1) / steps) + 0.002
			for k in 5:
				var a0 := TAU * k / 5.0
				var a1 := TAU * (k + 1) / 5.0
				var o0 := Vector3(0, cos(a0), sin(a0))
				var o1 := Vector3(0, cos(a1), sin(a1))
				_quad(a + o0 * ra, b + o0 * rb, b + o1 * rb, a + o1 * ra, dark)

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
