extends SceneTree
## Görsel boru hattı: assets/incoming/ içindeki ChatGPT görsellerini oyun ikonlarına çevirir.
##   godot --headless --path . -s res://tools/process_images.gd
##   godot --headless --path . -s res://tools/process_images.gd -- --keep --only=items_modern_1 --preview=/tmp/onizleme
## Hangi görselin nasıl kesileceği data/art_sheets.json'da, promptlar docs/gorsel-istekleri.md'de.
## fit: "square" (varsayılan; ikon kareye ortalanır), "box" (tek görsel, oran korunur),
## "trim" (ızgaradaki her parça kırpılır, oran korunur: 9 dilimli çerçeveler ve düğmeler).
## despill: "all" (varsayılan), "edge" (mor nesneli sayfalar: içi solmasın), "none" (ArtSheet).
## key: false: arka plan silinmez, görsel saydamlık kanalsız kaydedilir (uygulama ikonu).
## --keep: işlenen orijinali silme (varsayılan: silinir, depo şişmesin).
## --preview=KLASÖR: kesilen ikonları dama desenli bir önizleme sayfasına da çizer.
## Sonra yeni PNG'ler için: godot --headless --path . --import

const INCOMING := "res://assets/incoming"
const SHEETS := "res://data/art_sheets.json"
const EXTENSIONS: Array[String] = ["png", "jpg", "jpeg", "webp"]


func _initialize() -> void:
	var keep := false
	var only := ""
	var preview := ""
	for arg in OS.get_cmdline_user_args():
		if arg == "--keep":
			keep = true
		elif arg.begins_with("--only="):
			only = arg.get_slice("=", 1)
		elif arg.begins_with("--preview="):
			preview = arg.get_slice("=", 1)
	var config := _read_config()
	if config.is_empty():
		quit(1)
		return
	var sheets := {}
	for raw: Variant in config.get("sheets", []):
		var def: Dictionary = raw
		sheets[str(def["file"])] = def
	var margin := float(config.get("margin", 0.08))
	var done := 0
	var failed := 0
	for path in _incoming_files():
		var base := path.get_file().get_basename()
		if not only.is_empty() and base != only:
			continue
		if not sheets.has(base):
			print("?  %s: tanınmayan dosya adı (docs/gorsel-istekleri.md'deki adları kullan)" % path.get_file())
			failed += 1
			continue
		var started := Time.get_ticks_msec()
		var outputs: Array[String] = []
		var errors := _process_file(path, sheets[base], margin, outputs)
		if errors.is_empty():
			done += 1
			print("✓  %s → %d dosya (%.1f sn)" % [path.get_file(), outputs.size(), (Time.get_ticks_msec() - started) / 1000.0])
			if not preview.is_empty() and outputs[0].ends_with(".png"):
				_write_preview(outputs, preview.path_join(base + ".png"))
			if not keep:
				DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
		else:
			failed += 1
			print("✗  %s" % path.get_file())
			for e in errors:
				print("     " + e)
	_report_missing(config)
	print("%d görsel işlendi, %d sorunlu." % [done, failed])
	quit(1 if failed > 0 else 0)


func _process_file(path: String, def: Dictionary, margin: float, outputs: Array[String]) -> PackedStringArray:
	var img := Image.load_from_file(ProjectSettings.globalize_path(path))
	if img == null or img.is_empty():
		return PackedStringArray(["Görsel okunamadı"])
	var out := str(def.get("out", ""))
	if bool(def.get("reference", false)):
		var copy := ArtSheet.fit_box(img, 1024, false, 0.0)
		copy.convert(Image.FORMAT_RGB8)
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out.get_base_dir()))
		copy.save_jpg(ProjectSettings.globalize_path(out), 0.85)
		outputs.append(out)
		return PackedStringArray()
	var sheet := ArtSheet.new()
	var keyed := img
	if bool(def.get("key", true)):
		keyed = sheet.remove_background(img, str(def.get("despill", "all")))
	else:
		keyed.convert(Image.FORMAT_RGBA8)
	if not sheet.errors.is_empty():
		return sheet.errors
	var names: Array = def.get("names", [])
	var size := int(def.get("size", 256))
	var pieces: Array[Image] = []
	var fit := str(def.get("fit", "square"))
	if fit == "box":
		pieces.append(ArtSheet.fit_box(keyed, size, bool(def.get("key", true)), margin))
	else:
		var grid: Array = def.get("grid", [1, 1])
		for piece in sheet.split(keyed, int(grid[0]), int(grid[1])):
			if piece == null:
				continue
			# "trim": 9 dilimli çerçeveler ve düğmeler; en boy oranı korunur, kenar payı eklenmez.
			# "tile": zemin dokuları; içinden kare kesilir, dikişsiz yapılır.
			if fit == "trim":
				pieces.append(ArtSheet.fit_box(piece, size, true, 0.0))
			elif fit == "tile":
				pieces.append(ArtSheet.make_tile(piece, size))
			else:
				pieces.append(ArtSheet.fit_square(piece, size, margin))
		if not sheet.errors.is_empty():
			return sheet.errors
	if pieces.size() != names.size():
		return PackedStringArray(["%d nesne bekleniyordu, %d bulundu" % [names.size(), pieces.size()]])
	# Arka planı silinmeyen görsel (uygulama ikonu) saydamlık kanalsız kaydedilir: Apple uygulama
	# ikonunda saydam kanal istemez.
	if not bool(def.get("key", true)):
		for piece in pieces:
			piece.convert(Image.FORMAT_RGB8)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out))
	var errors := PackedStringArray()
	var jpg := str(def.get("format", "png")) == "jpg"
	for k in pieces.size():
		var target := out.path_join(str(names[k]) + (".jpg" if jpg else ".png"))
		var err := OK
		if jpg:
			pieces[k].convert(Image.FORMAT_RGB8)
			err = pieces[k].save_jpg(ProjectSettings.globalize_path(target), 0.9)
		else:
			err = pieces[k].save_png(ProjectSettings.globalize_path(target))
		if err != OK:
			errors.append("Yazılamadı: " + target)
		else:
			outputs.append(target)
			_write_import_defaults(target)
	return errors


## İlk içe aktarmada mipmap üretilsin diye .import dosyası yoksa ayarlarıyla yazar
## (ikonlar küçük gösterilince pürüzsüz görünsün). Godot eksik alanları kendisi doldurur.
func _write_import_defaults(target: String) -> void:
	var path := ProjectSettings.globalize_path(target + ".import")
	if FileAccess.file_exists(path):
		return
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string("[remap]\n\nimporter=\"texture\"\ntype=\"CompressedTexture2D\"\n\n[params]\n\nmipmaps/generate=true\n")
	f.close()


## Kesilen ikonları dama deseni üstünde yan yana çizer (gözle kontrol için).
func _write_preview(paths: Array[String], target: String) -> void:
	var cell := 160
	var sheet := Image.create_empty(cell * paths.size(), cell, false, Image.FORMAT_RGBA8)
	for y in cell:
		for x in cell * paths.size():
			var dark := ((x >> 4) + (y >> 4)) % 2 == 0
			sheet.set_pixel(x, y, Color(0.75, 0.75, 0.78) if dark else Color(0.95, 0.95, 0.97))
	for k in paths.size():
		var icon := Image.load_from_file(ProjectSettings.globalize_path(paths[k]))
		icon.convert(Image.FORMAT_RGBA8)
		icon.resize(cell, cell, Image.INTERPOLATE_LANCZOS)
		sheet.blend_rect(icon, Rect2i(0, 0, cell, cell), Vector2i(k * cell, 0))
	DirAccess.make_dir_recursive_absolute(target.get_base_dir())
	sheet.save_png(target)


func _report_missing(config: Dictionary) -> void:
	var waiting: Array[String] = []
	for raw: Variant in config.get("sheets", []):
		var def: Dictionary = raw
		if bool(def.get("reference", false)):
			if not FileAccess.file_exists(str(def["out"])):
				waiting.append(str(def["file"]))
			continue
		var extension := "." + str(def.get("format", "png"))
		for name: Variant in def.get("names", []):
			if not FileAccess.file_exists(str(def["out"]).path_join(str(name) + extension)):
				waiting.append(str(def["file"]))
				break
	if waiting.is_empty():
		print("Bütün görseller hazır.")
	else:
		print("Bekleyen görseller (%d): %s" % [waiting.size(), ", ".join(waiting)])


func _read_config() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(SHEETS))
	if typeof(parsed) != TYPE_DICTIONARY:
		printerr("Okunamadı: " + SHEETS)
		return {}
	return parsed


func _incoming_files() -> Array[String]:
	var out: Array[String] = []
	if not DirAccess.dir_exists_absolute(ProjectSettings.globalize_path(INCOMING)):
		return out
	for file in DirAccess.get_files_at(INCOMING):
		if file.get_extension().to_lower() in EXTENSIONS:
			out.append(INCOMING.path_join(file))
	out.sort()
	return out
