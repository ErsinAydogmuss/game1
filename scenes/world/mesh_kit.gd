class_name MeshKit
extends RefCounted
## Kodla kurulan yuvarlak ve eğri parçalar (aletler, birinci şahıs kolu ve eldiven):
## - rounded_box: köşeleri yuvarlatılmış kutu (süperelipsoit).
## - loft: bir yol boyunca kesiti değişen gövde (sap, kazma başı, parmak, kürek ağzı,
##   burgulu matkap ucu). Kesit elips ya da yuvarlak kare; yarıçapı 0 olan uç sivri olur.
## Normaller hesaplanır (yumuşak gölgelendirme). UV: u çevre (0..1), v yol boyunca metre.
## Üçgenler saat yönünde (Godot'nun ön yüzü); ters kabuk dış çizgi buna dayanır.


## Yuvarlatılmış kutu. size: tam boyut; roundness: 0'a yakın keskin kutu, 1 elipsoit.
static func rounded_box(size: Vector3, roundness: float = 0.3, segments: int = 16, rings: int = 10) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var half := size * 0.5
	var e := clampf(roundness, 0.05, 1.0)
	for r in rings + 1:
		var theta := lerpf(-PI * 0.5, PI * 0.5, float(r) / rings)
		var ct := cos(theta)
		var sn := sin(theta)
		for k in segments + 1:
			var phi := TAU * float(k) / segments
			var cp := cos(phi)
			var sp := sin(phi)
			var p := Vector3(half.x * _spow(ct, e) * _spow(cp, e), half.y * _spow(sn, e),
					half.z * _spow(ct, e) * _spow(sp, e))
			var n := Vector3(_spow(ct, 2.0 - e) * _spow(cp, 2.0 - e) / half.x, _spow(sn, 2.0 - e) / half.y,
					_spow(ct, 2.0 - e) * _spow(sp, 2.0 - e) / half.z)
			st.set_normal(n.normalized() if n.length_squared() > 1e-12 else Vector3(0, signf(sn), 0))
			st.set_uv(Vector2(float(k) / segments, float(r) / rings))
			st.add_vertex(p)
	for r in rings:
		for k in segments:
			var a := r * (segments + 1) + k
			var b := a + segments + 1
			st.add_index(a)
			st.add_index(b + 1)
			st.add_index(b)
			st.add_index(a)
			st.add_index(a + 1)
			st.add_index(b + 1)
	return st.commit()


## Yol boyunca gövde. path: yolun noktaları; radii[i]: o noktadaki kesitin yarıçapları
## (x: yan, y: üst). up: kesitin "üst" yönü için ipucu (yola dik izdüşümü yol boyunca taşınır).
## shape: kesitin biçimi (1 elips, 0,5 yuvarlak kare). twist: yol boyunca kesitin dönüşü (tur;
## burgulu uç). caps: uçlar düz kapatılsın mı. closed: yol kapalı halka (D tutamak).
## colors: isteğe bağlı köşe rengi, func(t: yol boyunca 0..1, u: çevre 0..1, side: kesitte
## yan (-1..1), top: üst (-1..1)) -> Color.
static func loft(path: PackedVector3Array, radii: PackedVector2Array, segments: int = 12,
		up: Vector3 = Vector3.UP, shape: float = 1.0, twist: float = 0.0, caps: bool = true,
		closed: bool = false, colors: Callable = Callable()) -> ArrayMesh:
	var n := path.size()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Yol boyunca uzunluk, teğetler ve taşınan kesit eksenleri.
	var lengths := PackedFloat32Array()
	lengths.resize(n)
	for i in range(1, n):
		lengths[i] = lengths[i - 1] + path[i].distance_to(path[i - 1])
	var total := maxf(lengths[n - 1], 1e-6)
	var tangents: Array[Vector3] = []
	var ups: Array[Vector3] = []
	var sides: Array[Vector3] = []
	for i in n:
		var prev := path[(i - 1 + n) % n] if closed or i > 0 else path[i]
		var next := path[(i + 1) % n] if closed or i < n - 1 else path[i]
		var t := (next - prev).normalized()
		tangents.append(t)
		var u := up if i == 0 else ups[i - 1]
		u = u - t * u.dot(t)
		if u.length_squared() < 1e-8:
			u = t.cross(Vector3.RIGHT if absf(t.x) < 0.9 else Vector3.FORWARD)
		u = u.normalized()
		ups.append(u)
		sides.append(u.cross(t).normalized())
	var ring := segments + 1
	for i in n:
		var r := radii[i]
		# Kesitin yol boyunca büyüme hızı: sivrilen uçta normal ileri eğilir.
		var a_i := maxi(i - 1, 0)
		var b_i := mini(i + 1, n - 1)
		var slope := 0.0
		if lengths[b_i] > lengths[a_i]:
			var ra := (radii[a_i].x + radii[a_i].y) * 0.5
			var rb := (radii[b_i].x + radii[b_i].y) * 0.5
			slope = (rb - ra) / (lengths[b_i] - lengths[a_i])
		var turn := twist * TAU * lengths[i] / total
		for j in ring:
			var angle := TAU * float(j) / segments
			var c := cos(angle)
			var s := sin(angle)
			var local := Vector2(r.x * _spow(c, shape), r.y * _spow(s, shape))
			var normal_2d := Vector2(_spow(c, 2.0 - shape) / maxf(r.x, 1e-4), _spow(s, 2.0 - shape) / maxf(r.y, 1e-4))
			local = local.rotated(turn)
			normal_2d = normal_2d.normalized().rotated(turn)
			var radial := (sides[i] * normal_2d.x + ups[i] * normal_2d.y).normalized()
			st.set_normal((radial - tangents[i] * slope).normalized())
			st.set_uv(Vector2(float(j) / segments, lengths[i]))
			if colors.is_valid():
				st.set_color(colors.call(lengths[i] / total, float(j) / segments, c, s))
			st.add_vertex(path[i] + sides[i] * local.x + ups[i] * local.y)
	var spans := n if closed else n - 1
	for i in spans:
		var i0 := i * ring
		var i1 := ((i + 1) % n) * ring
		for j in segments:
			st.add_index(i0 + j)
			st.add_index(i1 + j)
			st.add_index(i1 + j + 1)
			st.add_index(i0 + j)
			st.add_index(i1 + j + 1)
			st.add_index(i0 + j + 1)
	if caps and not closed:
		_cap(st, path, radii, sides, ups, tangents, segments, shape, twist, 0, n * ring, colors)
		_cap(st, path, radii, sides, ups, tangents, segments, shape, twist, n - 1, n * ring + ring + 1, colors)
	return st.commit()


## Düz bir halka kapağı (yarıçap 0 ise atlanır). base: kapağın ilk köşesinin sırası.
static func _cap(st: SurfaceTool, path: PackedVector3Array, radii: PackedVector2Array, sides: Array[Vector3],
		ups: Array[Vector3], tangents: Array[Vector3], segments: int, shape: float, twist: float, i: int,
		base: int, colors: Callable) -> void:
	var r := radii[i]
	var start := i == 0
	var normal := -tangents[i] if start else tangents[i]
	var turn := 0.0 if start else twist * TAU
	var t := 0.0 if start else 1.0
	# Merkez + çevre (kapakta düz normalle ayrı köşeler).
	st.set_normal(normal)
	st.set_uv(Vector2(0.5, 0.5))
	if colors.is_valid():
		st.set_color(colors.call(t, 0.0, 0.0, 0.0))
	st.add_vertex(path[i])
	for j in segments + 1:
		var angle := TAU * float(j) / segments
		var local := Vector2(r.x * _spow(cos(angle), shape), r.y * _spow(sin(angle), shape)).rotated(turn)
		st.set_normal(normal)
		st.set_uv(Vector2(0.5 + 0.5 * cos(angle), 0.5 + 0.5 * sin(angle)))
		if colors.is_valid():
			st.set_color(colors.call(t, float(j) / segments, cos(angle), sin(angle)))
		st.add_vertex(path[i] + sides[i] * local.x + ups[i] * local.y)
	if r.x <= 0.0 or r.y <= 0.0:
		return
	for j in segments:
		st.add_index(base)
		if start:
			st.add_index(base + 1 + j)
			st.add_index(base + 2 + j)
		else:
			st.add_index(base + 2 + j)
			st.add_index(base + 1 + j)


## Düz bir doğru boyunca gövde (sap, silindir): from'dan to'ya, yarıçaplar uçtan uca.
static func rod(from: Vector3, to: Vector3, radius_from: float, radius_to: float, segments: int = 12,
		up: Vector3 = Vector3.UP, steps: int = 1) -> ArrayMesh:
	var path := PackedVector3Array()
	var radii := PackedVector2Array()
	for i in steps + 1:
		var t := float(i) / steps
		path.append(from.lerp(to, t))
		var r := lerpf(radius_from, radius_to, t)
		radii.append(Vector2(r, r))
	return loft(path, radii, segments, up)


## Bir yay üzerinde noktalar: center merkezli, axis_a ve axis_b düzleminde, from..to açıları.
static func arc(center: Vector3, axis_a: Vector3, axis_b: Vector3, radius: float, from: float, to: float,
		steps: int) -> PackedVector3Array:
	var out := PackedVector3Array()
	for i in steps + 1:
		var angle := lerpf(from, to, float(i) / steps)
		out.append(center + (axis_a * cos(angle) + axis_b * sin(angle)) * radius)
	return out


## İşaretli üs: işaret korunur, büyüklüğün üssü alınır.
static func _spow(v: float, p: float) -> float:
	return signf(v) * pow(absf(v), p)
