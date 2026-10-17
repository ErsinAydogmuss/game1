extends SceneTree
## KayKit dokularını oyunun renklerine boyar.
##
## KayKit dokuları 8×4 ızgarada renk şeritlerinden (dikey renk geçişli kutular) oluşur; her
## model parçası bir kutunun içine düşen UV'lerle boyanır. Bir kutuyu yeniden boyamak, o kutuyu
## kullanan her parçayı boyar. Renk geçişi korunur: her piksel, kutunun ortalama parlaklığına
## göre oranlanıp yeni renkle çarpılır. Hangi kutuyu hangi parçanın kullandığı, model
## dosyalarındaki UV'lerden çıkarıldı.
##
## Çalıştırma: godot --headless --path . -s res://tools/recolor_texture.gd
## Girdiler paketlerdeki orijinal dokular (source/ klasörleri, Godot içe aktarmaz).
## Kenney dokuları 16×4 ızgaralı renk paletidir (işte "grid"); hangi modelin hangi kutuyu
## kullandığı yine UV'lerden çıkarıldı.

const GRID := Vector2i(8, 4)
const JOBS: Array[Dictionary] = [
	{
		# Balıkçı kız (Rogue): Vector2i(sütun, satır) → yeni renk. Yeşil tunik çimende ve sazlıkta
		# kaybolmasın diye sarı; yaka ve kol uçları koyu turkuaz; pantolon kot mavisi.
		"source": "res://assets/models/characters/source/rogue_texture.png",
		"output": "res://assets/models/characters/angler_texture.png",
		"swatches": {
			Vector2i(0, 1): "#f0b637", # tunik ve kollar → sarı balıkçı yeleği
			Vector2i(1, 1): "#2c7d96", # yaka ve kol uçları (pelerin de bunu kullanır, gizli)
			Vector2i(3, 2): "#3f69a6", # pantolon → kot
			Vector2i(5, 2): "#8a5a36", # eldiven ve bileklik
		},
	},
	{
		# Dede (Barbarian): beyaz sakal ve saç; mavi suda ve yeşil çimende seçilsin diye tuğla
		# kırmızısı örgü kazak, krem yün yaka; kahverengi pantolon. Kutular Kazı'daki eşlemeden.
		"source": "res://assets/models/characters/source/barbarian_texture.png",
		"output": "res://assets/models/characters/dede_texture.png",
		"swatches": {
			Vector2i(1, 0): "#f4f1ea", # sakal ve kaşlar → beyaz
			Vector2i(7, 0): "#dcd7ce", # saç örgüleri, yaka → kır
			Vector2i(0, 1): "#a8443a", # gömlek → örgü kazak
			Vector2i(1, 1): "#a8443a", # kollar → kazak kolları
			Vector2i(2, 1): "#eadfc6", # kürk süsler → krem yün
			Vector2i(7, 1): "#5c5242", # pantolon
			Vector2i(7, 2): "#e8ae8c", # eller → ten
			Vector2i(3, 2): "#4a3426", # botlar
			Vector2i(6, 0): "#6b4428", # kemer ve kayış
			Vector2i(3, 0): "#c9a24a", # tokalar → pirinç
		},
	},
	{
		# Nine (Mage): Ersin'in portre tarifi (docs/gorsel-istekleri.md §9): gümüş saç, hardal
		# sarısı örgü hırka (cüppe), krem yün kenarlar, tahta düğmeler. Kemer ve keseler önlüğün
		# turkuazı: kodla takılan önlüğün bağı ve cepleri gibi görünür. Şapka ve pelerin gizli.
		"source": "res://assets/models/characters/source/mage_texture.png",
		"output": "res://assets/models/characters/nine_texture.png",
		"swatches": {
			Vector2i(1, 0): "#c4bfba", # saç ve kaşlar → gümüş
			Vector2i(1, 1): "#3f6fb5", # saç bağı (şapka da bunu kullanır, gizli)
			Vector2i(0, 1): "#d39b2f", # cüppe ve kollar → hardal hırka
			Vector2i(4, 0): "#efe3c8", # etek ucu, yaka ve kol uçları → krem yün
			Vector2i(3, 0): "#7a4a2a", # düğmeler ve toka → tahta
			Vector2i(5, 0): "#1f7f7c", # kemer → önlük bağı
			Vector2i(2, 2): "#2a9d96", # keseler → önlük cepleri
			Vector2i(7, 1): "#5b4a5e", # çorap
			Vector2i(3, 2): "#5b3a28", # ayakkabı
		},
	},
	{
		# Ortaçağ paketi: ahşap pembemsi görünmesin, ağaçlar çimenle uyuşsun.
		"source": "res://assets/models/medieval/source/hexagons_medieval.png",
		"output": "res://assets/models/medieval/hexagons_medieval.png",
		"swatches": {
			Vector2i(6, 0): "#9a653d", # ahşap (fıçı, kasa, tezgâh, ağaç gövdesi)
			Vector2i(5, 0): "#bf8a57", # açık ahşap
			Vector2i(1, 2): "#3f944a", # ağaç yaprağı
			Vector2i(0, 2): "#86b84e", # dağlardaki çimen
		},
	},
	{
		# KayKit orman paketi (ağaç, çalı, çimen, kaya; sütun 0): yapraklar biraz koyu (yukarıdan
		# bakınca açık uçları soluk görünüyordu), turuncu kabuk iskelenin ahşabına yakın kahverengi,
		# mavimsi kaya sıcak gri (üstüne yosunu moss.gdshader çizer).
		"source": "res://assets/models/kaykit_forest/source/forest_texture.png",
		"output": "res://assets/models/kaykit_forest/forest_texture.png",
		"swatches": {
			Vector2i(0, 0): "#33782b", # yaprak, çalı, çimen
			Vector2i(0, 1): "#8f5d34", # ağaç kabuğu
			Vector2i(0, 2): "#a09b90", # kaya
		},
	},
	{
		# Kenney hayatta kalma paketi (kamp ateşi, kütük, tabela): somon tahta → iskele ahşabı.
		"source": "res://assets/models/kenney_survival/Textures/source/colormap.png",
		"output": "res://assets/models/kenney_survival/Textures/colormap.png",
		"grid": Vector2i(16, 4),
		"swatches": {
			Vector2i(9, 3): "#9a653d", # tahta
			Vector2i(13, 3): "#c4a27a", # açık tahta (kütük ucu), ocak taşları
		},
	},
	{
		# Kenney deniz taşıtları (sandal): somon gövde → koyu ahşap, beyaz iç → açık ahşap.
		"source": "res://assets/models/kenney_watercraft/Textures/source/colormap.png",
		"output": "res://assets/models/kenney_watercraft/Textures/colormap.png",
		"grid": Vector2i(16, 4),
		"swatches": {
			Vector2i(13, 3): "#7d4f2c", # gövde ve kürekler
			Vector2i(11, 3): "#c9a36e", # iç ve oturaklar
		},
	},
]


func _initialize() -> void:
	var failed := false
	for job in JOBS:
		failed = not _run(job) or failed
	quit(1 if failed else 0)


static func _run(job: Dictionary) -> bool:
	var source := str(job["source"])
	var output := str(job["output"])
	var image := Image.load_from_file(ProjectSettings.globalize_path(source))
	if image == null:
		push_error("Kaynak doku okunamadı: " + source)
		return false
	image.convert(Image.FORMAT_RGBA8)
	var grid: Vector2i = job.get("grid", GRID)
	var cell := Vector2i(image.get_width() / grid.x, image.get_height() / grid.y)
	var swatches: Dictionary = job["swatches"]
	for key: Vector2i in swatches:
		_recolor(image, Rect2i(key * cell, cell), Color(str(swatches[key])))
	if image.save_png(ProjectSettings.globalize_path(output)) != OK:
		push_error("Yazılamadı: " + output)
		return false
	print("Yazıldı: ", output)
	return true


static func _recolor(image: Image, rect: Rect2i, target: Color) -> void:
	var total := 0.0
	var count := 0
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			total += image.get_pixel(x, y).get_luminance()
			count += 1
	var mean := maxf(total / maxi(count, 1), 0.001)
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			var c := image.get_pixel(x, y)
			var k := c.get_luminance() / mean
			image.set_pixel(x, y, Color(clampf(target.r * k, 0.0, 1.0), clampf(target.g * k, 0.0, 1.0),
					clampf(target.b * k, 0.0, 1.0), c.a))
