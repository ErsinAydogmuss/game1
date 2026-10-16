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

const GRID := Vector2i(8, 4)
const JOBS: Array[Dictionary] = [
	{
		# Kazım Usta (Barbarian): Vector2i(sütun, satır) → yeni renk.
		"source": "res://assets/models/characters/source/barbarian_texture.png",
		"output": "res://assets/models/characters/kazim_texture.png",
		"swatches": {
			Vector2i(0, 1): "#d9503a", # gömlek
			Vector2i(1, 1): "#d9503a", # kollar
			Vector2i(7, 1): "#3c6fc0", # pantolon → tulum
			Vector2i(2, 1): "#2c5596", # kürk süsler → koyu kot kenarlar
			Vector2i(1, 0): "#5a3520", # sakal ve kaşlar
			Vector2i(7, 0): "#4a2c1a", # saç örgüleri, yaka
			Vector2i(7, 2): "#b5793f", # eller → iş eldiveni
			Vector2i(3, 2): "#5b3a25", # botlar
			Vector2i(6, 0): "#7b4a27", # kemer ve kayış
			Vector2i(3, 0): "#f2c443", # tokalar → pirinç
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
	var cell := Vector2i(image.get_width() / GRID.x, image.get_height() / GRID.y)
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
