class_name ArtSheet
extends RefCounted
## Görsel boru hattının çekirdeği (tools/process_images.gd kullanır; testlerle denetlenir).
## ChatGPT'nin düz renkli (macenta / yeşil) arka planlı görsellerini oyuna hazırlar:
## arka planı siler, kenar sızıntısını temizler, sayfayı nesnelere böler, kareye sığdırır.
## Piksel indeksleriyle çalışır; tamsayı bölme bilinçli.
@warning_ignore_start("integer_division")

## Arka plan rengine RGB uzaklığı (0-441): BG_NEAR altı kesin arka plan, BG_FAR üstü kesin nesne.
const BG_NEAR := 60.0
const BG_FAR := 140.0
## Nesnenin içinde kalan arka plan boşlukları (ör. yüzüğün ortası): tohum bu kadar yakın,
## alan en az HOLE_MIN piksel olmalı.
const HOLE_SEED := 36.0
const HOLE_MIN := 24
## Toz sayılan parça: sayfa alanına oranı bundan küçükse atılır.
const SPECK := 0.0002
## Yumuşak kenar bandının genişliği (piksel) ve iç renk arama yarıçapı.
const EDGE := 3
const INNER_RADIUS := 4
## Renk sızıntısı: arka plan kanalları bu kadar fazlaya kadar dokunulmaz; kanallar arası fark
## SPILL_HUE'dan büyükse (ör. gerçek mor, pembe) piksel sızıntı sayılmaz.
const SPILL_FREE := 24
const SPILL_HUE := 60
## Kenardaki piksellerin en az bu oranı aynı renkte olmalı (düz arka plan denetimi).
const FLAT_BORDER := 0.7
## 8 komşu (parçaları bulurken çapraz değen pikseller de aynı parçadır).
const NEIGHBORS_X: Array[int] = [-1, 0, 1, -1, 1, -1, 0, 1]
const NEIGHBORS_Y: Array[int] = [-1, -1, -1, 0, 0, 1, 1, 1]

var errors: PackedStringArray = []
var warnings: PackedStringArray = []
## Kenarlardan bulunan arka plan rengi.
var background := Color.MAGENTA


## Arka planı siler. Dönen görüntü RGBA8; arka plan saydam, kenarlar yumuşak.
## Görsel zaten saydamsa olduğu gibi döner. Arka plan düz değilse errors'a yazar.
func remove_background(source: Image) -> Image:
	var img: Image = source.duplicate()
	img.convert(Image.FORMAT_RGBA8)
	var w := img.get_width()
	var h := img.get_height()
	var n := w * h
	var data := img.get_data()
	if _border_is_transparent(data, w, h):
		return img
	background = _border_color(data, w, h)
	var br := background.r8
	var bgg := background.g8
	var bb := background.b8
	var dist := PackedFloat32Array()
	dist.resize(n)
	for i in n:
		var o := i << 2
		var dr := data[o] - br
		var dg := data[o + 1] - bgg
		var db := data[o + 2] - bb
		dist[i] = sqrt(float(dr * dr + dg * dg + db * db))
	if _flat_share(dist, w, h) < FLAT_BORDER:
		errors.append("Arka plan düz değil (dama deseni ya da sahne olabilir). Düz macenta arka planla yeniden üret.")
		return img
	# 0 = bilinmiyor, 1 = arka plan, 2 = incelendi (nesne ya da küçük boşluk).
	var state := PackedByteArray()
	state.resize(n)
	state.fill(0)
	var queue := PackedInt32Array()
	for x in w:
		_seed(x, dist, state, queue)
		_seed((h - 1) * w + x, dist, state, queue)
	for y in h:
		_seed(y * w, dist, state, queue)
		_seed(y * w + w - 1, dist, state, queue)
	_flood(queue, w, h, dist, state, 1)
	# Nesnenin içinde kalan arka plan renkli boşluklar.
	for i in n:
		if state[i] != 0 or dist[i] >= HOLE_SEED:
			continue
		var region := PackedInt32Array([i])
		state[i] = 2
		_flood(region, w, h, dist, state, 2)
		if region.size() >= HOLE_MIN:
			for j in region:
				state[j] = 1
	# Arka plana EDGE piksel yakın kenar bandı: yumuşak alfa + renk sızıntısı temizliği.
	# Kenar pikseli = t x nesne rengi + (1 - t) x arka plan. Nesne rengi yakındaki iç pikselden
	# alınır, t izdüşümle bulunur; sonra arka plan payı geri çıkarılır.
	var near := _mask(state, 1)
	for k in EDGE:
		near = _dilate(near, w, h)
	var bgv := Vector3(br, bgg, bb)
	var fixed := data.duplicate()
	for i in n:
		var o := i << 2
		if state[i] == 1:
			for ch in 4:
				fixed[o + ch] = 0
			continue
		if near[i] == 0:
			continue
		var c := Vector3(data[o], data[o + 1], data[o + 2])
		var t := clampf((dist[i] - BG_NEAR) / (BG_FAR - BG_NEAR), 0.0, 1.0)
		var inner := _interior_color(i, w, h, data, state, near)
		if inner.x >= 0.0:
			var axis := inner - bgv
			var len2 := axis.dot(axis)
			if len2 > 400.0:
				t = clampf((c - bgv).dot(axis) / len2, 0.0, 1.0)
		if t >= 0.98:
			continue
		if t < 0.06:
			for ch in 4:
				fixed[o + ch] = 0
			continue
		var fg := (c - bgv * (1.0 - t)) / t
		fixed[o] = clampi(roundi(fg.x), 0, 255)
		fixed[o + 1] = clampi(roundi(fg.y), 0, 255)
		fixed[o + 2] = clampi(roundi(fg.z), 0, 255)
		fixed[o + 3] = roundi(t * data[o + 3])
	data = fixed
	_despill(data, n)
	img.set_data(w, h, false, Image.FORMAT_RGBA8, data)
	return img


## Saydam arka planlı sayfayı cols x rows ızgarasına göre nesnelere böler (soldan sağa,
## yukarıdan aşağı). Bir nesne birden çok parçadan oluşabilir (ör. bilyeler): parçalar ağırlık
## merkezlerine göre hücreye atanır. Nesnesi bulunamayan hücre için null döner.
func split(img: Image, cols: int, rows: int) -> Array[Image]:
	var w := img.get_width()
	var h := img.get_height()
	var n := w * h
	var data := img.get_data()
	var labels := PackedInt32Array()
	labels.resize(n)
	labels.fill(-1)
	var parts: Array[Dictionary] = []
	var queue := PackedInt32Array()
	for start in n:
		if labels[start] != -1 or data[(start << 2) + 3] < 128:
			continue
		var label := parts.size()
		var count := 0
		var sum_x := 0
		var sum_y := 0
		var x0 := w
		var y0 := h
		var x1 := 0
		var y1 := 0
		labels[start] = label
		queue.clear()
		queue.append(start)
		var head := 0
		while head < queue.size():
			var i := queue[head]
			head += 1
			var x := i % w
			var y := i / w
			count += 1
			sum_x += x
			sum_y += y
			x0 = mini(x0, x)
			y0 = mini(y0, y)
			x1 = maxi(x1, x)
			y1 = maxi(y1, y)
			for k in 8:
				var nx := x + NEIGHBORS_X[k]
				var ny := y + NEIGHBORS_Y[k]
				if nx < 0 or ny < 0 or nx >= w or ny >= h:
					continue
				var j := ny * w + nx
				if labels[j] == -1 and data[(j << 2) + 3] >= 128:
					labels[j] = label
					queue.append(j)
		parts.append({ "count": count, "sx": sum_x, "sy": sum_y, "rect": Rect2i(x0, y0, x1 - x0 + 1, y1 - y0 + 1) })
	var cells: Array[PackedInt32Array] = []
	for k in cols * rows:
		cells.append(PackedInt32Array())
	var owner := PackedInt32Array()
	owner.resize(parts.size())
	owner.fill(-1)
	var min_count := maxi(4, int(SPECK * n))
	for p in parts.size():
		var count := int(parts[p]["count"])
		if count < min_count:
			continue
		var cx := float(parts[p]["sx"]) / count
		var cy := float(parts[p]["sy"]) / count
		var col := clampi(int(cx * cols / w), 0, cols - 1)
		var row := clampi(int(cy * rows / h), 0, rows - 1)
		owner[p] = row * cols + col
		cells[owner[p]].append(p)
	var out: Array[Image] = []
	for k in cells.size():
		if cells[k].is_empty():
			errors.append("%d. nesne bulunamadı (ızgara %dx%d bozuk olabilir)" % [k + 1, cols, rows])
			out.append(null)
			continue
		var rect: Rect2i = parts[cells[k][0]]["rect"]
		for p in cells[k]:
			rect = rect.merge(parts[p]["rect"])
		rect = rect.grow(3).intersection(Rect2i(0, 0, w, h))
		var piece := PackedByteArray()
		piece.resize(rect.size.x * rect.size.y * 4)
		piece.fill(0)
		for y in rect.size.y:
			for x in rect.size.x:
				var i := (rect.position.y + y) * w + rect.position.x + x
				var label := labels[i]
				var mine := owner[label] == k if label >= 0 else data[(i << 2) + 3] > 0
				if not mine:
					continue
				var o := (y * rect.size.x + x) << 2
				for c in 4:
					piece[o + c] = data[(i << 2) + c]
		out.append(Image.create_from_data(rect.size.x, rect.size.y, false, Image.FORMAT_RGBA8, piece))
	return out


## Nesneyi saydam kenarlarından kırpar, margin payı bırakıp kareye ortalar, size x size yapar.
static func fit_square(img: Image, size: int, margin: float) -> Image:
	var used := img.get_used_rect()
	if used.size.x <= 0 or used.size.y <= 0:
		return Image.create_empty(size, size, false, Image.FORMAT_RGBA8)
	var side := ceili(maxf(used.size.x, used.size.y) * (1.0 + 2.0 * margin))
	var canvas := Image.create_empty(side, side, false, Image.FORMAT_RGBA8)
	canvas.blit_rect(img, used, Vector2i((side - used.size.x) >> 1, (side - used.size.y) >> 1))
	canvas.fix_alpha_edges()
	canvas.resize(size, size, Image.INTERPOLATE_LANCZOS)
	return canvas


## En boy oranını koruyarak uzun kenarı max_size yapar. trim: saydam kenarları kırpıp margin ekler.
static func fit_box(img: Image, max_size: int, trim: bool, margin: float) -> Image:
	var src := img
	if trim:
		var used := img.get_used_rect()
		if used.size.x > 0 and used.size.y > 0:
			var pad := Vector2i(ceili(used.size.x * margin), ceili(used.size.y * margin))
			src = Image.create_empty(used.size.x + pad.x * 2, used.size.y + pad.y * 2, false, Image.FORMAT_RGBA8)
			src.blit_rect(img, used, pad)
			src.fix_alpha_edges()
	var scale := float(max_size) / maxf(src.get_width(), src.get_height())
	var out: Image = src.duplicate()
	if scale < 1.0:
		out.resize(maxi(1, roundi(src.get_width() * scale)), maxi(1, roundi(src.get_height() * scale)), Image.INTERPOLATE_LANCZOS)
	return out


## Nesnenin saydam yerlerinden (cam, zincir arası) görünen arka plan rengini nötrleştirir.
## Macenta arka planda R ve B birlikte G'den çok yüksekse (ve birbirine yakınsa) fazlası
## kırpılır; yeşil arka planda G'nin fazlası. Gerçek mor/pembe renkler (R ile B farklı) korunur.
func _despill(data: PackedByteArray, n: int) -> void:
	var magenta := background.r > 0.7 and background.b > 0.7 and background.g < 0.3
	var green := background.g > 0.7 and background.r < 0.3 and background.b < 0.3
	if not (magenta or green):
		return
	for i in n:
		var o := i << 2
		if data[o + 3] == 0:
			continue
		var r := data[o]
		var g := data[o + 1]
		var b := data[o + 2]
		if magenta:
			var spill := mini(r, b) - g - SPILL_FREE
			if spill > 0 and absi(r - b) < SPILL_HUE:
				var cut := roundi(spill * 0.9)
				data[o] = r - cut
				data[o + 2] = b - cut
		else:
			var spill := g - maxi(r, b) - SPILL_FREE
			if spill > 0 and absi(r - b) < SPILL_HUE:
				data[o + 1] = g - roundi(spill * 0.9)


## Kenar pikseline en yakın iç (bant dışı, nesne) pikselin rengi; yoksa x = -1.
static func _interior_color(i: int, w: int, h: int, data: PackedByteArray, state: PackedByteArray, near: PackedByteArray) -> Vector3:
	var x := i % w
	var y := i / w
	var best := -1
	var best_d := 1 << 30
	for dy in range(-INNER_RADIUS, INNER_RADIUS + 1):
		var ny := y + dy
		if ny < 0 or ny >= h:
			continue
		for dx in range(-INNER_RADIUS, INNER_RADIUS + 1):
			var nx := x + dx
			if nx < 0 or nx >= w:
				continue
			var j := ny * w + nx
			if near[j] != 0 or state[j] == 1:
				continue
			var d := dx * dx + dy * dy
			if d < best_d:
				best_d = d
				best = j
	if best < 0:
		return Vector3(-1, -1, -1)
	return Vector3(data[best << 2], data[(best << 2) + 1], data[(best << 2) + 2])


func _seed(i: int, dist: PackedFloat32Array, state: PackedByteArray, queue: PackedInt32Array) -> void:
	if state[i] == 0 and dist[i] < BG_NEAR:
		state[i] = 1
		queue.append(i)


## queue'daki piksellerden başlayıp arka plana yakın komşulara yayılır, onları mark ile işaretler.
## queue sonunda bölgenin tüm piksellerini içerir.
func _flood(queue: PackedInt32Array, w: int, h: int, dist: PackedFloat32Array, state: PackedByteArray, mark: int) -> void:
	var head := 0
	while head < queue.size():
		var i := queue[head]
		head += 1
		var x := i % w
		if x > 0 and state[i - 1] == 0 and dist[i - 1] < BG_NEAR:
			state[i - 1] = mark
			queue.append(i - 1)
		if x < w - 1 and state[i + 1] == 0 and dist[i + 1] < BG_NEAR:
			state[i + 1] = mark
			queue.append(i + 1)
		if i >= w and state[i - w] == 0 and dist[i - w] < BG_NEAR:
			state[i - w] = mark
			queue.append(i - w)
		if i < (h - 1) * w and state[i + w] == 0 and dist[i + w] < BG_NEAR:
			state[i + w] = mark
			queue.append(i + w)


static func _mask(state: PackedByteArray, value: int) -> PackedByteArray:
	var out := PackedByteArray()
	out.resize(state.size())
	for i in state.size():
		out[i] = 1 if state[i] == value else 0
	return out


## 4 komşulu genişletme: maskeye değen pikseller de maskeye girer.
static func _dilate(mask: PackedByteArray, w: int, h: int) -> PackedByteArray:
	var out := mask.duplicate()
	for i in mask.size():
		if mask[i] != 0:
			continue
		var x := i % w
		if (x > 0 and mask[i - 1] != 0) or (x < w - 1 and mask[i + 1] != 0) \
				or (i >= w and mask[i - w] != 0) or (i < (h - 1) * w and mask[i + w] != 0):
			out[i] = 1
	return out


static func _border_indices(w: int, h: int) -> PackedInt32Array:
	var out := PackedInt32Array()
	var inset := mini(2, mini(w, h) >> 2)
	for x in range(inset, w - inset):
		out.append(inset * w + x)
		out.append((h - 1 - inset) * w + x)
	for y in range(inset, h - inset):
		out.append(y * w + inset)
		out.append(y * w + w - 1 - inset)
	return out


static func _border_is_transparent(data: PackedByteArray, w: int, h: int) -> bool:
	var border := _border_indices(w, h)
	var clear := 0
	for i in border:
		if data[(i << 2) + 3] < 16:
			clear += 1
	return clear > border.size() * 0.9


## Kenar piksellerinin kanal kanal ortancası (yapay zekâ arka planı tam #FF00FF olmayabilir).
static func _border_color(data: PackedByteArray, w: int, h: int) -> Color:
	var channels: Array[PackedInt32Array] = [PackedInt32Array(), PackedInt32Array(), PackedInt32Array()]
	for i in _border_indices(w, h):
		for c in 3:
			channels[c].append(data[(i << 2) + c])
	var median := PackedInt32Array()
	for c in 3:
		channels[c].sort()
		median.append(channels[c][channels[c].size() >> 1] if channels[c].size() > 0 else 0)
	return Color8(median[0], median[1], median[2])


static func _flat_share(dist: PackedFloat32Array, w: int, h: int) -> float:
	var border := _border_indices(w, h)
	var flat := 0
	for i in border:
		if dist[i] < BG_NEAR:
			flat += 1
	return float(flat) / maxf(1.0, border.size())
