class_name HatModel
extends RefCounted
## Balıkçının şapkaları (Dalga 5, kıyafetler; data/outfits.json, OutfitRules.HAT_SHAPES): kodla, tek ağ
## (MeshBatch, köşe rengi): bir çizim, bir dış çizgi, bir gölge (eski kova şapkayla aynı bütçe).
## Baş kemiğinin yuvasında, modelin biriminde (KayKit modeli ~2,2 birim; AnglerBody ölçeği 0,66). Kökü şapkanın
## oturduğu yer (AnglerBody: görünüşün hat_y'si, biçimin DROP'u kadar aşağı); +z yüzün yönü, y yukarı.
## Biçimler: bucket (kova şapka), straw (hasır: geniş kenar, kurdele), beanie (bere: kıvrık kenar, ponpon),
## cap (kasket: yassı tepe, siper), fly (sinekçi: kova şapka, bantta yapay sinekler), crown (çiçek tacı: başın
## çevresinde çiçekler ve yapraklar), keeper (Bekçi'nin şapkası: turkuaz kova şapka, tepede yüzgeç, benekler).

## Biçimin oturduğu yerin baş kemiğinden yüksekliğe göre aşağı payı (bere ve taç başı sarar).
const DROP := { "beanie": 0.16, "crown": 0.2, "cap": 0.06, "straw": 0.02 }


## Şapkanın ağı (biçim bilinmiyorsa kova şapka).
static func build(shape: String, color: Color, band: Color) -> MeshBatch:
	var b := MeshBatch.new()
	match shape:
		"straw":
			_straw(b, color, band)
		"beanie":
			_beanie(b, color, band)
		"cap":
			_cap(b, color, band)
		"crown":
			_crown(b, color, band)
		"fly":
			_bucket(b, color, band)
			_flies(b)
		"keeper":
			_bucket(b, color, band)
			_fin(b, color, band)
		_:
			_bucket(b, color, band)
	return b


static func drop(shape: String) -> float:
	return float(DROP.get(shape, 0.0))


## Kova şapka (v0.1'den beri balıkçının şapkası): tepe, aşağı eğik geniş kenar, bant.
static func _bucket(b: MeshBatch, color: Color, band: Color) -> void:
	b.cylinder(0.42, 0.52, 0.34, Vector3(0, 0.13, 0), color, 14)
	b.cylinder(0.53, 0.76, 0.09, Vector3(0, -0.07, 0), color.darkened(0.12), 18)
	b.cylinder(0.515, 0.515, 0.08, Vector3(0, 0.0, 0), band, 14)


## Hasır şapka: yassı geniş kenar (iki tonlu örgü), alçak tepe, kurdele.
static func _straw(b: MeshBatch, color: Color, band: Color) -> void:
	b.cylinder(0.93, 0.96, 0.045, Vector3(0, -0.06, 0), color.darkened(0.08), 22)
	b.cylinder(0.72, 0.72, 0.05, Vector3(0, -0.052, 0), color.lightened(0.06), 20)
	b.cylinder(0.4, 0.46, 0.31, Vector3(0, 0.12, 0), color, 16)
	b.cylinder(0.465, 0.465, 0.075, Vector3(0, -0.005, 0), band, 16)


## Bere: başı saran kubbe, kıvrık kenar, ponpon.
static func _beanie(b: MeshBatch, color: Color, band: Color) -> void:
	b.sphere(0.5, Vector3(0, 0.02, 0), color, Vector3(1.0, 0.92, 1.0), 16, 8)
	b.cylinder(0.535, 0.535, 0.17, Vector3(0, -0.06, 0), band, 18)
	b.sphere(0.15, Vector3(0, 0.5, 0), band, Vector3.ONE, 10, 5)


## Kasket (Dede'ninkine benzer): yassı dolgun tepe, bant, önde aşağı eğik siper.
static func _cap(b: MeshBatch, color: Color, band: Color) -> void:
	b.sphere(0.5, Vector3(0, 0.03, -0.02), color, Vector3(1.04, 0.42, 1.06), 16, 8)
	b.cylinder(0.5, 0.53, 0.13, Vector3(0, -0.05, -0.02), band, 18)
	b.box(Vector3(0.58, 0.05, 0.26), Vector3(0, -0.09, 0.55), band.darkened(0.15), Vector3(-0.22, 0, 0))


## Sinekçi şapkasının bandında üç yapay sinek: gövde, tüy ve kuyruk (renkli: suda seçilsin).
static func _flies(b: MeshBatch) -> void:
	var looks := [[Color("#d9452f"), Color("#ffd23f")], [Color("#2fb5a8"), Color("#f4ecdc")],
			[Color("#f07d24"), Color("#5a3a24")]]
	for i in looks.size():
		var a := 0.55 + 0.75 * i
		var out := Vector3(sin(a), 0.0, cos(a))
		var at := out * 0.54
		var colors: Array = looks[i]
		b.sphere(0.05, at, colors[0], Vector3(1.0, 0.8, 1.0), 8, 4)
		b.sphere(0.045, at + Vector3(0, 0.045, 0) + out * 0.015, colors[1], Vector3(1.2, 0.7, 1.2), 8, 4)
		b.box(Vector3(0.025, 0.025, 0.09), at + Vector3(0, -0.03, 0) + out * 0.01, colors[1], Vector3(0, a, 0))


## Çiçek tacı: başın çevresinde dönüşümlü renkli çiçekler (göbekli) ve aralarında yapraklar.
static func _crown(b: MeshBatch, color: Color, band: Color) -> void:
	var petals: Array[Color] = [band, Color("#ffffff"), Color("#c9a6e8"), Color("#ffd84a")]
	var count := 10
	for i in count:
		var a := TAU * i / count
		var out := Vector3(sin(a), 0.0, cos(a))
		var at := out * 0.48
		b.sphere(0.1, at, petals[i % petals.size()], Vector3(1.0, 0.75, 1.0), 10, 5)
		b.sphere(0.045, at + out * 0.07 + Vector3(0, 0.035, 0), Color("#f4c430"), Vector3.ONE, 8, 4)
		var leaf_a := a + TAU / count * 0.5
		var leaf := Vector3(sin(leaf_a), 0.0, cos(leaf_a))
		b.sphere(0.075, leaf * 0.5 + Vector3(0, -0.03, 0), color, Vector3(1.4, 0.45, 0.8), 8, 4)


## Bekçi'nin şapkası: turkuaz kova şapkanın tepesinde boyuna yüzgeç ve yanlarda açık benekler.
static func _fin(b: MeshBatch, color: Color, band: Color) -> void:
	b.box(Vector3(0.06, 0.26, 0.5), Vector3(0, 0.38, -0.04), color.darkened(0.3), Vector3(-0.18, 0, 0))
	for side: float in [-1.0, 1.0]:
		for k in 2:
			var a := side * (0.9 + 0.55 * k)
			b.sphere(0.05, Vector3(sin(a) * 0.47, 0.14 + 0.06 * k, cos(a) * 0.47), band, Vector3(1.0, 0.7, 1.0), 8, 4)
