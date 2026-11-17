extends BaseTest
## Görsellerin ekran kartı belleği (Kazı'dan, docs/performans-notlari.md §3.4). "Lossless" görsel (compress/mode=0)
## ekran kartında sıkıştırmasız: piksel başına 4 bayt, mipmap'le 5,3. Arayüzün ikonları, büyük resimleri, portreler,
## haritanın çıkartmaları ve zemin karoları ekran kartının sıkıştırmasıyla (compress/mode=2, high_quality: telefonda
## ASTC, bilgisayarda BPTC): bellek 4'te 1. Sıkıştırılmayanlar:
## - kodun get_image() ile piksellerini okuduğu görseller (sıkıştırılmış doku telefonda geri okunamaz): çerçeveler
##   (UiKit.framed onları küçültüp kopyalar), saat çipinin vakit ve hava ikonları (ChipSky tek atlasta birleştirir);
## - açılış görseli (logo) ve uygulama ikonları;
## - modellerin palet dokuları (renk kutuları: sıkıştırma kutuların sınırında renkleri karıştırır);
## - 3B zemin karoları (her karede ekranın çoğunda örneklenir: bilgisayarda Godot sıkıştırmayı BPTC'ye çevirir, bu
##   ortamın yazılım çizicisinde (llvmpipe) BPTC örneklemek bütün botları ~5 kat yavaşlatıyordu; 4 MB).
## Yeni görsel ekleyen araç (tools/process_images.gd) .import'u bu kurala göre yazar.

## Sıkıştırılan görseller: bu klasörlerin hepsi (RAW'dakiler hariç) ve bu dosyalar.
const COMPRESSED_DIRS: Array[String] = ["res://assets/icons/", "res://assets/ui/map/", "res://assets/ui/portraits/"]
const COMPRESSED_FILES: Array[String] = ["res://assets/ui/art/aquarium_bg.png", "res://assets/ui/art/ending.png",
		"res://assets/ui/art/secret_map.png"]
## Sıkıştırılmayanlar (yolun başı).
const RAW: Array[String] = ["res://assets/ui/frames/", "res://assets/icons/ui/phase_", "res://assets/icons/ui/weather_",
		"res://assets/ui/art/logo.png", "res://assets/ui/art/app_icon.png", "res://assets/ui/art/android/",
		"res://assets/models/", "res://assets/textures/"]


static func compressed(path: String) -> bool:
	for prefix in RAW:
		if path.begins_with(prefix):
			return false
	if COMPRESSED_FILES.has(path):
		return true
	for dir in COMPRESSED_DIRS:
		if path.begins_with(dir):
			return true
	return false


func test_ui_textures_are_vram_compressed() -> void:
	var wrong := PackedStringArray()
	var count := 0
	for path in _textures("res://assets/"):
		var params := _params(path)
		var mode := int(params.get("compress/mode", -1))
		if compressed(path):
			count += 1
			if mode != 2 or not bool(params.get("compress/high_quality", false)):
				wrong.append("%s (mode %d)" % [path, mode])
		elif mode == 2:
			wrong.append("%s sıkıştırılmamalı" % path)
	assert_true(wrong.is_empty(), "görsellerin sıkıştırması kurala uyuyor: " + ", ".join(wrong))
	assert_true(count > 100, "sıkıştırılan görsel sayısı (%d)" % count)
	assert_true(bool(ProjectSettings.get_setting("rendering/textures/vram_compression/import_etc2_astc", false)),
			"telefonun sıkıştırması (ETC2/ASTC) içe aktarılıyor")


## Saat çipi vakit ve hava ikonlarının piksellerini okur (ChipSky._build_atlas): sıkıştırılmamış olmalılar.
func test_pixels_read_by_code_stay_raw() -> void:
	for kind: String in SkyIcons.KINDS:
		if not (kind.begins_with("phase_") or kind.begins_with("weather_")):
			continue
		var art := str(GameIcon.ART_NAMES.get(kind, ""))
		if art.is_empty():
			continue
		var path := "res://assets/icons/ui/%s.png" % art
		if FileAccess.file_exists(path + ".import"):
			assert_true(not compressed(path) and int(_params(path).get("compress/mode", -1)) == 0,
					"saat çipinin ikonu sıkıştırılmamış: " + path)
	for frame: String in UiKit.FRAME_SLICES:
		var path := "res://assets/ui/frames/%s.png" % frame
		if FileAccess.file_exists(path + ".import"):
			assert_true(not compressed(path), "çerçeve sıkıştırılmamış (UiKit.framed okur): " + path)


func _textures(root: String) -> PackedStringArray:
	var out := PackedStringArray()
	var dirs: Array[String] = [root]
	while not dirs.is_empty():
		var dir: String = dirs.pop_back()
		for sub in DirAccess.get_directories_at(dir):
			if sub != "source" and not FileAccess.file_exists(dir.path_join(sub).path_join(".gdignore")):
				dirs.append(dir.path_join(sub) + "/")
		for file in DirAccess.get_files_at(dir):
			if file.ends_with(".import") and (file.ends_with(".png.import") or file.ends_with(".jpg.import")):
				var params := _params(dir.path_join(file.trim_suffix(".import")))
				if params.has("compress/mode"):
					out.append(dir.path_join(file.trim_suffix(".import")))
	return out


func _params(path: String) -> Dictionary:
	var config := ConfigFile.new()
	if config.load(path + ".import") != OK:
		return {}
	if str(config.get_value("remap", "importer", "")) != "texture":
		return {}
	var out := {}
	for key in config.get_section_keys("params"):
		out[key] = config.get_value("params", key)
	return out
