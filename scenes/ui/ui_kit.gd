class_name UiKit
extends RefCounted
## Arayüz stili (yatay ekran, 1920×1080 taban): tek Theme + küçük fabrika yardımcıları.
## İki font: başlık ve büyük sayılar için Luckiest Guy (hep BÜYÜK harf), metinler için
## Baloo 2. Butonlar koddan üretilen parlak (gradyanlı) dokularla, diyaloglar krem renkli.
## HUD üstündeki yazılar koyu yarı saydam haplar üstünde açık renktedir.

const TEXT := Color("#fff8ec")
const MUTED := Color("#c3bfd6")
const DARK_TEXT := Color("#2b1a08")
const ACCENT := Color("#ffc93c")
const GOOD := Color("#4fdc7b")
const BAD := Color("#ff6b6b")
const MYSTERY := Color("#c3a6ff")
const PANEL := Color("#1c2133")
const PANEL_SOFT := Color("#283049")
const PILL := Color(0.07, 0.08, 0.13, 0.62)
const PRIMARY := Color("#ff9f1c")
const SECONDARY := Color("#3d8bff")
const SUCCESS := Color("#25b864")
const NEUTRAL := Color("#59617f")
const DANGER := Color("#e5484d")
const MYSTERY_BUTTON := Color("#9a7bff")
## Krem diyaloglar: zemin, kart, kenar ve üstündeki koyu kahve yazı.
const CREAM := Color("#fff3d9")
const CREAM_CARD := Color("#fffaf0")
const CREAM_EDGE := Color("#e7c98f")
const INK := Color("#4a2a12")
const INK_SOFT := Color("#8f6b47")
## Başlık yazılarının koyu dış çizgisi.
const OUTLINE := Color("#2a160a")

const SIZE_SMALL := 30
const SIZE_BODY := 38
const SIZE_TITLE := 54
const SIZE_HERO := 76

const DISPLAY_FONT := "res://assets/fonts/LuckiestGuy-Regular.ttf"
const BODY_FONT := "res://assets/fonts/Baloo2-Variable.ttf"

static var _theme: Theme
static var _body: Font
static var _display: Font
static var _glossy_cache: Dictionary = {}


## Metin fontu: Baloo 2 kalın (Türkçe harflerin tamamı var). Dosya yoksa varsayılan font.
static func body_font() -> Font:
	if _body == null:
		var v := FontVariation.new()
		if ResourceLoader.exists(BODY_FONT):
			v.base_font = load(BODY_FONT)
			# Eksen anahtarı adla değil etiketle (int) verilmeli; "wght" yazısı yok sayılıyor.
			v.variation_opentype = { TextServerManager.get_primary_interface().name_to_tag("wght"): 700 }
		else:
			v.base_font = ThemeDB.fallback_font
			v.variation_embolden = 0.75
		_body = v
	return _body


## Başlık fontu: Luckiest Guy. Yalnızca büyük harfle kullanılır (bkz. title()).
static func display_font() -> Font:
	if _display == null:
		_display = load(DISPLAY_FONT) if ResourceLoader.exists(DISPLAY_FONT) else body_font()
	return _display


## Eski adı (geriye uyum): metin fontu.
static func bold_font() -> Font:
	return body_font()


static func theme() -> Theme:
	if _theme != null:
		return _theme
	var t := Theme.new()
	t.default_font = body_font()
	t.default_font_size = SIZE_BODY
	t.set_color("font_color", "Label", TEXT)
	t.set_color("font_shadow_color", "Label", Color(0, 0, 0, 0.45))
	t.set_constant("shadow_offset_x", "Label", 0)
	t.set_constant("shadow_offset_y", "Label", 3)
	t.set_constant("line_spacing", "Label", -6)
	t.set_stylebox("normal", "Button", glossy(PRIMARY, false))
	t.set_stylebox("hover", "Button", glossy(PRIMARY.lightened(0.06), false))
	t.set_stylebox("pressed", "Button", glossy(PRIMARY, true))
	t.set_stylebox("hover_pressed", "Button", glossy(PRIMARY, true))
	t.set_stylebox("disabled", "Button", glossy(Color("#8c8f9e"), false))
	t.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	t.set_font("font", "Button", display_font())
	for state: String in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		t.set_color(state, "Button", TEXT)
	t.set_color("font_disabled_color", "Button", Color(TEXT, 0.75))
	t.set_color("font_outline_color", "Button", OUTLINE)
	t.set_constant("outline_size", "Button", 10)
	t.set_stylebox("panel", "PanelContainer", panel_style())
	t.set_stylebox("background", "ProgressBar", flat(Color(0, 0, 0, 0.45), 10))
	t.set_stylebox("fill", "ProgressBar", flat(ACCENT, 10))
	t.set_constant("separation", "VBoxContainer", 16)
	t.set_constant("separation", "HBoxContainer", 16)
	t.set_stylebox("panel", "ScrollContainer", StyleBoxEmpty.new())
	_theme = t
	return t


static func label(text: String, size: int = SIZE_BODY, color: Color = TEXT,
		align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := Label.new()
	l.text = text
	l.horizontal_alignment = align
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## Krem zemin üstündeki koyu yazı (gölgesiz).
static func ink(text: String, size: int = SIZE_BODY, color: Color = INK,
		align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT) -> Label:
	var l := label(text, size, color, align)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
	return l


## Başlık: Luckiest Guy, büyük harf, kalın koyu dış çizgi.
static func title(text: String, size: int = SIZE_TITLE, color: Color = TEXT,
		align: HorizontalAlignment = HORIZONTAL_ALIGNMENT_LEFT, outline: int = 12) -> Label:
	var l := label(upper(text), size, color, align)
	l.add_theme_font_override("font", display_font())
	l.add_theme_constant_override("outline_size", outline)
	l.add_theme_color_override("font_outline_color", OUTLINE)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.35))
	l.add_theme_constant_override("shadow_offset_y", 5)
	return l


## Parlak buton (Luckiest Guy yazı, koyu dış çizgi).
static func button(text: String, color: Color = PRIMARY, size: int = SIZE_BODY,
		min_size: Vector2 = Vector2(0, 100)) -> Button:
	var b := Button.new()
	b.text = upper(text)
	b.custom_minimum_size = min_size
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", size)
	style_button(b, color)
	return b


static func style_button(b: Button, color: Color) -> void:
	b.add_theme_stylebox_override("normal", glossy(color, false))
	b.add_theme_stylebox_override("hover", glossy(color.lightened(0.06), false))
	b.add_theme_stylebox_override("pressed", glossy(color, true))
	b.add_theme_stylebox_override("hover_pressed", glossy(color, true))
	b.add_theme_stylebox_override("disabled", glossy(color.lerp(Color("#8c8f9e"), 0.7), false))


## Düz renkli buton stili (eski, kodla çizilen yerler için).
static func button_style(color: Color, pressed: bool, radius: int = 28) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.border_color = color.darkened(0.35)
	sb.border_width_bottom = 4 if pressed else 11
	sb.set_corner_radius_all(radius)
	sb.content_margin_left = 30
	sb.content_margin_right = 30
	sb.content_margin_top = 18 + (7 if pressed else 0)
	sb.content_margin_bottom = 14
	sb.shadow_color = Color(0, 0, 0, 0.28)
	sb.shadow_size = 2 if pressed else 8
	sb.shadow_offset = Vector2(0, 4)
	sb.anti_aliasing = true
	return sb


## Koddan üretilen parlak buton dokusu (9-patch): üstten alta gradyan, üstte parlama bandı,
## koyu dış çizgi ve altta "kalınlık". Basılıyken kalınlık kaybolur, buton içine çöker.
static func glossy(color: Color, pressed: bool, radius: int = 30) -> StyleBoxTexture:
	var key := "%s|%s|%d" % [color.to_html(), pressed, radius]
	if _glossy_cache.has(key):
		return _glossy_cache[key]
	var w := radius * 2 + 32
	var lip := 3 if pressed else 12
	var h := radius * 2 + 32 + lip
	var face_h := h - lip
	var img := Image.create_empty(w, h, false, Image.FORMAT_RGBA8)
	var outline := color.darkened(0.55)
	var top := color.lightened(0.28)
	var bottom := color.darkened(0.08)
	var side := color.darkened(0.32)
	for y in h:
		for x in w:
			var in_face := _in_round_rect(x, y, w, face_h, radius, 0)
			if not in_face and not _in_round_rect(x, y, w, h, radius, 0):
				continue
			var c := side
			if in_face:
				var t := float(y) / face_h
				c = top.lerp(bottom, t)
				# Üstteki parlama bandı (yüzün üst %42'si, kenarlardan içeride).
				if t < 0.42 and _in_round_rect(x, y, w, face_h, radius, 9):
					c = c.lerp(Color.WHITE, 0.22 * (1.0 - t / 0.42))
			if not _in_round_rect(x, y, w, face_h if in_face else h, radius, 3):
				c = outline
			img.set_pixel(x, y, c)
	var sb := StyleBoxTexture.new()
	sb.texture = ImageTexture.create_from_image(img)
	sb.texture_margin_left = radius + 4
	sb.texture_margin_right = radius + 4
	sb.texture_margin_top = radius + 4
	sb.texture_margin_bottom = radius + 4 + lip
	sb.content_margin_left = 34
	sb.content_margin_right = 34
	sb.content_margin_top = 14 + (9 if pressed else 0)
	sb.content_margin_bottom = 12 + lip
	_glossy_cache[key] = sb
	return sb


## (x, y) pikseli w×h boyutlu, r yarıçaplı yuvarlak dikdörtgenin inset kadar içinde mi.
static func _in_round_rect(x: int, y: int, w: int, h: int, r: int, inset: int) -> bool:
	var px := float(x) + 0.5
	var py := float(y) + 0.5
	var left := float(inset)
	var right := float(w - inset)
	var up := float(inset)
	var down := float(h - inset)
	if px < left or px > right or py < up or py > down:
		return false
	var rr := float(maxi(1, r - inset))
	var cx := clampf(px, left + rr, right - rr)
	var cy := clampf(py, up + rr, down - rr)
	return Vector2(px - cx, py - cy).length() <= rr


## Koyu panel (HUD kartları ve eski ekranlar).
static func panel_style(color: Color = PANEL, radius: int = 40) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(color, 0.96)
	sb.border_color = Color(1, 1, 1, 0.09)
	sb.set_border_width_all(3)
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(34)
	sb.shadow_color = Color(0, 0, 0, 0.45)
	sb.shadow_size = 26
	sb.shadow_offset = Vector2(0, 10)
	return sb


## Krem diyalog zemini: kalın açık kahve kenar, yumuşak gölge.
static func dialog_style(radius: int = 46) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = CREAM
	sb.border_color = CREAM_EDGE
	sb.set_border_width_all(8)
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(36)
	sb.shadow_color = Color(0, 0, 0, 0.5)
	sb.shadow_size = 30
	sb.shadow_offset = Vector2(0, 14)
	sb.anti_aliasing = true
	return sb


## Krem diyalog içindeki kart (beyaza yakın, ince kenarlı). border: kenar rengi (ör. nadirlik).
static func card_style(border: Color = CREAM_EDGE, radius: int = 28, fill: Color = CREAM_CARD,
		border_width: int = 4) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = fill
	sb.border_color = border
	sb.set_border_width_all(border_width)
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(18)
	sb.shadow_color = Color(0.35, 0.2, 0.05, 0.18)
	sb.shadow_size = 8
	sb.shadow_offset = Vector2(0, 5)
	sb.anti_aliasing = true
	return sb


## HUD üzerindeki yarı saydam hap (pill) kutular.
static func pill_style(color: Color = PILL) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(48)
	sb.content_margin_left = 22
	sb.content_margin_right = 30
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	sb.border_color = Color(1, 1, 1, 0.08)
	sb.set_border_width_all(2)
	return sb


static func flat(color: Color, radius: int, margin: int = 0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(radius)
	sb.set_content_margin_all(margin)
	return sb


static func spacer(vertical: bool = false) -> Control:
	var c := Control.new()
	if vertical:
		c.size_flags_vertical = Control.SIZE_EXPAND_FILL
	else:
		c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return c


## Durum yıldızları: dolu ve boş yıldız ikonları (yıldız görseli yoksa kodla).
static func stars(count: int, side: float = 34.0, total: int = 5) -> HBoxContainer:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", int(side * -0.12))
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for i in total:
		var star := GameIcon.make("star" if i < count else "star_empty", side, ACCENT)
		if i >= count and GameIcon.texture_for("star_empty") == null:
			star.tint = Color(1, 1, 1, 0.25)
		row.add_child(star)
	return row


## Nadirlik rozeti: nadirlik renginde hap, içinde büyük harfli adı.
static func rarity_badge(db: ContentDB, rarity: int, size: int = SIZE_SMALL) -> PanelContainer:
	var color := rarity_color(db, rarity)
	var pill := PanelContainer.new()
	var sb := flat(color, 40)
	sb.content_margin_left = 22
	sb.content_margin_right = 22
	sb.content_margin_top = 4
	sb.content_margin_bottom = 2
	sb.border_color = color.darkened(0.45)
	sb.set_border_width_all(3)
	pill.add_theme_stylebox_override("panel", sb)
	pill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pill.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	var text := title(translate("RARITY_" + db.rarity_id(rarity)), size,
			DARK_TEXT if color.get_luminance() > 0.6 else TEXT, HORIZONTAL_ALIGNMENT_CENTER, 0)
	text.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0))
	pill.add_child(text)
	return pill


## Statik yerlerde çeviri (Node.tr() olmayan sınıflar için).
static func translate(key: String) -> String:
	return str(TranslationServer.translate(key))


## Binlik ayırıcılı sayı: TR "12.345", EN "12,345".
static func format_int(n: int) -> String:
	var sep := "." if TranslationServer.get_locale().begins_with("tr") else ","
	var digits := str(absi(n))
	var out := ""
	while digits.length() > 3:
		out = sep + digits.substr(digits.length() - 3) + out
		digits = digits.substr(0, digits.length() - 3)
	return ("-" if n < 0 else "") + digits + out


## Büyük harf; Türkçede i → İ, ı → I (String.to_upper() i'yi I yapar).
static func upper(text: String) -> String:
	if TranslationServer.get_locale().begins_with("tr"):
		text = text.replace("i", "İ")
	return text.to_upper()


## Nadirliğin rengi (data/rarities.json).
static func rarity_color(db: ContentDB, rarity: int) -> Color:
	return db.rarity_def(rarity).get("color", TEXT)


## Durum yıldızları metni ("★★★"): 3D yazılar için (fontta yoksa sistem fontundan gelir).
static func stars_text(stars: int) -> String:
	return "★".repeat(clampi(stars, 0, 5))


## Ondalıklı küçük sayı: TR "1,5", EN "1.5".
static func format_float(x: float) -> String:
	var text := ("%.1f" % x).trim_suffix(".0")
	return text.replace(".", ",") if TranslationServer.get_locale().begins_with("tr") else text


## Yüzde (ppm'den): TR "%2,5", EN "2.5%".
static func format_percent(ppm: int) -> String:
	var value := float(ppm) / 10_000.0
	var text := ("%.1f" % value).trim_suffix(".0") if value < 10.0 else str(roundi(value))
	if TranslationServer.get_locale().begins_with("tr"):
		return "%" + text.replace(".", ",")
	return text + "%"


## Çentik / yuvarlak köşe için güvenli alan payları (viewport birimiyle):
## x = sol, y = üst, z = sağ, w = alt.
static func safe_insets(node: CanvasItem) -> Vector4:
	if not OS.has_feature("mobile"):
		return Vector4.ZERO
	var window := Vector2(DisplayServer.window_get_size())
	if window.x <= 0.0:
		return Vector4.ZERO
	var safe := Rect2(DisplayServer.get_display_safe_area())
	var scale := node.get_viewport_rect().size.x / window.x
	return Vector4(safe.position.x, safe.position.y, maxf(0.0, window.x - safe.end.x),
			maxf(0.0, window.y - safe.end.y)) * scale
