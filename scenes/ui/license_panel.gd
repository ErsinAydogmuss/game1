class_name LicensePanel
extends Dialog
## Lisanslar (Kazı'nın v0.14 paneli; Ayarlar → GİZLİLİK → LİSANSLAR, kartların üstünde açılır): oyunun içindeki açık
## kaynaklı parçaların telif satırları ve lisansları. Godot'nun MIT lisansı ve içindeki bileşenler (FreeType, ENet,
## mbed TLS...: Engine.get_copyright_info), yazı tipleri (Luckiest Guy: Apache 2.0, Baloo 2: SIL OFL 1.1), kitaplıklar
## (Poing Studios'un AdMob eklentisi, MIT; Google'ın reklam ve onay SDK'ları kendi şartlarıyla) ve lisansların tam
## metinleri (Engine.get_license_info; adına dokununca açılır). Bu lisanslar metinlerin oyunla birlikte verilmesini
## ister; jenerikte yalnızca emek verenler yazar. 3D modeller (KayKit, Kenney, Quaternius) CC0: ad yazmak gerekmez.

## Yazı tipleri: ad, telif satırı (yazı tipi dosyasının kendi satırı), lisans (get_license_info anahtarı).
const FONTS: Array[Array] = [
	["Luckiest Guy", "Copyright (c) 2010 by Brian J. Bonislawsky DBA Astigmatic (AOETI). All rights reserved.",
			"Apache-2.0"],
	["Baloo 2", "Copyright 2019 The Baloo 2 Project Authors (https://github.com/EkType/Baloo2)", "OFL-1.1"],
]
## Kitaplıklar: ad, telif satırı, lisans (get_license_info anahtarı: MIT'nin metni "Expat" adıyla).
const LIBRARIES: Array[Array] = [
	["Poing Studios AdMob Plugin", "Copyright (c) 2020-present Poing Studios", "Expat (MIT)"],
]
## FreeType lisansının (FTL) istediği cümle; yıl bileşenin telif satırından gelir.
const FREETYPE_CREDIT := "Portions of this software are copyright © %s The FreeType Project (www.freetype.org). All rights reserved."
const WIDTH := 1500.0
const TEXT_SIZE := 24
const TEXT_W := 1300.0
const LIST_H := 700.0

var _list: VBoxContainer
var _scroll: ScrollContainer
## Lisans adı → tam metnin Label'ı (ilk dokunuşta kurulur; uzun metinler açılışı yavaşlatmasın).
var _texts: Dictionary = {}


func _build() -> void:
	set_header(tr("UI_LICENSES"), "book", WIDTH)
	_scroll = ScrollContainer.new()
	_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_scroll.custom_minimum_size = Vector2(0, LIST_H)
	body.add_child(_scroll)
	_list = VBoxContainer.new()
	_list.add_theme_constant_override("separation", 10)
	_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_scroll.add_child(_list)


func refresh() -> void:
	set_header(tr("UI_LICENSES"), "book", WIDTH)
	clear(_list)
	_texts.clear()
	_scroll.scroll_vertical = 0
	_list.add_child(_text(tr("UI_LICENSES_INTRO"), UiKit.SIZE_SMALL, UiKit.INK_SOFT))
	_heading("Godot Engine")
	_list.add_child(_text(_unwrap(Engine.get_license_text())))
	_heading(tr("UI_LICENSES_FONTS"))
	for font: Array in FONTS:
		_entry(str(font[0]), "%s\n%s" % [font[1], tr("UI_LICENSES_LICENSE") % font[2]])
	_heading(tr("UI_LICENSES_LIBS"))
	for library: Array in LIBRARIES:
		_entry(str(library[0]), "%s\n%s" % [library[1], tr("UI_LICENSES_LICENSE") % library[2]])
	_list.add_child(_text(tr("UI_LICENSES_GOOGLE")))
	_heading(tr("UI_LICENSES_PARTS"))
	for part: Dictionary in Engine.get_copyright_info():
		var name := str(part["name"])
		if name == "Godot Engine":
			continue
		_entry(name, _part_lines(part))
	_heading(tr("UI_LICENSES_TEXTS"))
	_list.add_child(_text(tr("UI_LICENSES_TAP"), UiKit.SIZE_SMALL, UiKit.INK_SOFT))
	var info := Engine.get_license_info()
	var names: Array = info.keys()
	names.sort()
	for license: String in names:
		_license_row(license, str(info[license]))


## Bileşenin telif satırları ve lisansı (aynı lisanslı parçalar tek satırda).
func _part_lines(part: Dictionary) -> String:
	var lines := PackedStringArray()
	var licenses := PackedStringArray()
	for piece: Dictionary in part["parts"]:
		for line: String in piece["copyright"]:
			var text := "© " + line
			if not lines.has(text):
				lines.append(text)
		var license := str(piece["license"])
		if not licenses.has(license):
			licenses.append(license)
	if str(part["name"]) == "FreeType":
		var year := lines[0].trim_prefix("© ").get_slice(",", 0) if not lines.is_empty() else ""
		lines.append(FREETYPE_CREDIT % year)
	lines.append(tr("UI_LICENSES_LICENSE") % ", ".join(licenses))
	return "\n".join(lines)


## Lisans metinleri ~70 harfte satır kırar: düz paragrafların satırları birleşir (ekranın genişliğine göre kırılsın);
## girintili, maddeli ya da kısa satırlı paragraflar olduğu gibi kalır.
static func _unwrap(text: String) -> String:
	var out := PackedStringArray()
	for paragraph in text.strip_edges().replace("\r", "").split("\n\n"):
		var lines := paragraph.split("\n")
		var prose := lines.size() > 1
		var joined := ""
		for line in lines:
			var bare := line.strip_edges()
			if line.begins_with(" ") or line.begins_with("\t") or bare.begins_with("-") or bare.begins_with("*") \
					or bare.begins_with("Copyright") or (bare.length() > 1 and bare[0].is_valid_int() and bare[1] in [".", ")"]):
				prose = false
			# Büyük harfli kısa satır (PREAMBLE, DEFINITIONS) başlıktır: kendi satırında kalır.
			var heading := joined != "" and joined.length() < 40 and joined == joined.to_upper() and not "\n" in joined
			joined += ("\n" if heading else " ") + bare if joined != "" else bare
		out.append(joined if prose else paragraph)
	return "\n\n".join(out)


func _heading(text: String) -> void:
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 14)
	_list.add_child(gap)
	_list.add_child(UiKit.title(text, 44, UiKit.PRIMARY, HORIZONTAL_ALIGNMENT_LEFT, 8))


func _entry(name: String, text: String) -> void:
	_list.add_child(_text(name, 30, UiKit.INK))
	_list.add_child(_text(text))


## Lisansın adı bir düğme: dokununca tam metni açılır ya da kapanır.
func _license_row(license: String, full_text: String) -> void:
	var button := UiKit.button(license, UiKit.NEUTRAL, UiKit.SIZE_SMALL, Vector2(0, 122))
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_list.add_child(button)
	button.pressed.connect(func() -> void:
		Sounds.play("ui_tap")
		var shown: Label = _texts.get(license)
		if shown == null:
			shown = _text(_unwrap(full_text))
			_list.add_child(shown)
			_list.move_child(shown, button.get_index() + 1)
			_texts[license] = shown
		else:
			shown.visible = not shown.visible)


func _text(text: String, size: int = TEXT_SIZE, color: Color = UiKit.INK) -> Label:
	var label := UiKit.ink(text, size, color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(TEXT_W, 0)
	label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	return label


## Bot ve testler için: açık listedeki bütün yazılar tek metinde.
func all_text() -> String:
	var parts := PackedStringArray()
	for child in _list.get_children():
		if child is Label:
			parts.append((child as Label).text)
		elif child is Button:
			parts.append((child as Button).text)
	return "\n".join(parts)


## Bot için: adı verilen lisansın düğmesi (yoksa null).
func license_button(license: String) -> Button:
	for child in _list.get_children():
		if child is Button and (child as Button).text == UiKit.upper(license):
			return child
	return null
