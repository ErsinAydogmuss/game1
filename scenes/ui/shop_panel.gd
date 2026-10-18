class_name ShopPanel
extends Dialog
## Nine'nin dükkânı (docs/gdd.md §10.4). Nine'ye ya da dükkânına dokununca açılır.
## - Üstte Nine'nin yüzü ve sözü (selam, "güle güle kullan", "biraz daha balık getir"...), para.
## - Sekmeler: Kova (balıkları sat), Kamış, Makara, Misina, tekniğe özel sekme (şamandırada iğne ve
##   şamandıra, spinde yapay yem, dipte kurşun, sinekte sinek), Yem, Ekstra (kepçe, sandal, sıradaki
##   kova: kovalar tek kartta). Her sekmede en çok 6 kart (3×2): kaydırma yok, parmakla aranmaz.
## - Başlıkta teknik düğmeleri: Kamış ve tekniğe özel sekme bakılan tekniğin takımını gösterir
##   (açılışta elindeki teknik). Kilitli teknik de görünür, düğmesinde rütbesi yazar. Makara ve
##   misina her teknikte ortak. Bir tekniğin ilk kamışı alınınca o teknik ele geçer.
## - Kart: ikon, ad, kısa açıklama, en çok iki değer çubuğu (kuşanılanla karşılaştırma: işaret
##   kuşanılanın yeri; yeşil daha iyi, turuncu daha zayıf; kamışta ve misinada "İri balık": kaç
##   yıldızlı iri balığı taşıdığı, 5 yıldızdan dolu olanlar) ve tek düğme: fiyat (al ve tak), TAK,
##   TAKILI, SENDE ya da rütbe kilidi. Yem kartında hangi balığı çektiği ve elindeki sayı; takılı
##   yem yeniden alınabilir (düğme fiyat olur, kart yeşil kenarlı).
## - Kova: tür başına bir satır (sayı, değer), altta toplam ve HEPSİNİ SAT.
## Para yalnızca oynayarak kazanılır; satın alma oyun parasıyla (gelir kuralları, CLAUDE.md).
## Düğmeler normal Button (TouchButton değil): paneller tek parmakla kullanılır.

## Takım değişti (satın alma, kuşanma; tekniğin ilk kamışı alınınca elindeki teknik de): main
## oturumun takımını yeniler.
signal gear_changed
## Kova satıldı: kazanılan para (main: HUD, Nine'nin sevinci).
signal sold(coins: int)

## [kimlik, ikon, başlık anahtarı, kategoriler]
const TABS: Array[Array] = [
	["sell", "bucket", "UI_SHOP_TAB_SELL", []],
	["rod", "rod", "UI_SHOP_TAB_ROD", ["rod"]],
	["reel", "reel", "UI_SHOP_TAB_REEL", ["reel"]],
	["line", "line", "UI_SHOP_TAB_LINE", ["line"]],
	["tackle", "hook", "UI_SHOP_TAB_TACKLE", ["hook", "bobber"]],
	["bait", "bait", "UI_SHOP_TAB_BAIT", ["bait"]],
	["extra", "net", "UI_SHOP_TAB_EXTRA", ["extra", "boat", "bucket"]],
]
## Kategori başına gösterilen değerler: [gear.json alanı, çeviri anahtarı, birim ("" = sayı yok,
## "★" = çubuk yerine 5 yıldızdan dolu olanlar)]. Kamışta ve misinada "İri balık": kaç yıldızlı iri
## balığı taşır (ikisinin küçüğü işler; güç ve kopma süresi kuralda kalır, satır olarak görünmez).
## Tekniğe özel sekme ("tackle"): teknik -> [kategoriler, başlık anahtarı, ikon].
const TECHNIQUE_TACKLE := {
	"float": [["hook", "bobber"], "UI_SHOP_TAB_TACKLE", "hook"],
	"spin": [["lure"], "UI_SHOP_TAB_LURE", "lure"],
	"bottom": [["rig"], "UI_SHOP_TAB_RIG", "rig"],
	"fly": [["fly"], "UI_SHOP_TAB_FLY", "fly"],
}
## Teknik düğmesinin boyu (başlık satırında, kapat düğmesi kadar: panel uzamaz).
const TECH_BUTTON := Vector2(122, 122)
const STATS := {
	"rod": [["range_m", "UI_STAT_RANGE", "m"], ["carry", "UI_STAT_CARRY", "★"]],
	"reel": [["reel_speed", "UI_STAT_SPEED", ""], ["drag", "UI_STAT_DRAG", ""]],
	"line": [["carry", "UI_STAT_CARRY", "★"], ["stealth", "UI_STAT_STEALTH", ""]],
	"hook": [["escape_extra", "UI_STAT_HOLD", ""]],
	"bobber": [["window_add", "UI_STAT_SENSITIVE", ""]],
	"extra": [["catch_m", "UI_STAT_REACH", ""]],
	"bucket": [["capacity", "UI_STAT_CAPACITY", "#"]],
}
## Panelin genişliği: 3 kart ve aralarındaki boşluklar, panel görselinin kenar paylarıyla.
const WIDTH := 1880.0
const COLUMNS := 3
## Sekme başına en çok kart (3×2; kaydırma yok).
const CARDS := 6
## Kartın boyu: kart görselinin kenar payları içeriğin çevresinde (bot her sekmede denetler; aşan
## kart paneli sekmeden sekmeye büyütürdü).
const CARD := Vector2(572, 312)
## Kart sıraları arası; başlık, sekmeler ve kartlar arası (panelin boyu, telefonda sığsın).
const ROW_GAP := 12
const GAP := 6
## Satış satırının boyu (iki sütun).
const SELL_ROW := Vector2(820, 96)
const TAB := Vector2(232, 122)
## Sekme görselinin köşe boyu (kemerli tabela).
const TAB_CORNER := 30.0
const ACTION := Vector2(236, 122)
## Yem kartında oran satırının yazısına kalan genişlik (kartın iç payı, düğme ve balık simgesi
## düşülünce): uzun adlı satır ("Gümüş Balığı %14 → %20") kartı büyütmesin diye küçük yazılır.
const ODDS_TEXT := 204.0
## Satış satırları: iki sütun, en çok bu kadar tür (daha fazlası "+N tür").
const SELL_ROWS := 8
## Kamış ve misina kartında "İri balık" yıldızlarının boyu (5 yıldız, kartı CARD'dan genişletmesin).
const STAR_SIDE := 27.0
const BETTER := Color("#2f9e52")
const WORSE := Color("#e07a24")
const SAME := Color("#a88a64")

var _tab: String = "rod"
var _last_gear_tab: String = "rod"
var _tab_buttons: Dictionary = {}
var _tab_icons: Dictionary = {}
var _tech_buttons: Dictionary = {}
var _content: VBoxContainer
var _face: TextureRect
## Ersin'in portresi yokken Nine'nin modelden çekilen yedek yüzü (main verir).
var _fallback_face: Texture2D
var _line: Label
var _coins: HBoxContainer
var _line_key: String = "UI_NINE_SHOP_HELLO"
var _line_args: Array = []
## Yem kartındaki oranların atış noktası (main verir; boşsa oyunun gölü).
var spot_id: String = ""
## Balıkçının bölgesi: yem kartındaki oranlar o bölgenin (Balık Defteri'yle aynı).
var zone_id: String = ""
## Bakılan teknik (Kamış ve tekniğe özel sekme; açılışta elindeki teknik).
var technique: String = "float"


func _build() -> void:
	set_header(tr("UI_SHOP_TITLE"), "shop", WIDTH)
	# Başlık yerine Nine'nin yüzü ve sözü (tabelada dükkânın adı yazıyor).
	var header := _icon.get_parent() as HBoxContainer
	_title.visible = false
	_face = TextureRect.new()
	_face.custom_minimum_size = Vector2(104, 104)
	_face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_face.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_face.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	_face.visible = false
	header.add_child(_face)
	header.move_child(_face, 0)
	_line = UiKit.ink("", UiKit.SIZE_BODY)
	_line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_line.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_line.size_flags_stretch_ratio = 6.0
	_line.custom_minimum_size = Vector2(600, 0)
	header.add_child(_line)
	header.move_child(_line, _title.get_index() + 1)
	var techs := HBoxContainer.new()
	techs.add_theme_constant_override("separation", 8)
	header_extra.add_child(techs)
	for id: String in ContentDB.TECHNIQUES:
		if GameState.db.has_technique(id):
			var b := _tech_button(id)
			techs.add_child(b)
			_tech_buttons[id] = b
	_coins = HBoxContainer.new()
	header_extra.add_child(_coins)
	# Telefonda (çentik ve ev çubuğu payıyla ~997 birim) küçülmeden sığsın, düğmeler 122 birim
	# kalsın: başlık, sekmeler ve kartlar arası dar (panel 993 birim).
	(_panel.get_child(0) as VBoxContainer).add_theme_constant_override("separation", GAP)
	body.add_theme_constant_override("separation", GAP)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 12)
	tabs.alignment = BoxContainer.ALIGNMENT_CENTER
	body.add_child(tabs)
	for t: Array in TABS:
		var b := _tab_button(str(t[0]), str(t[1]))
		tabs.add_child(b)
		_tab_buttons[str(t[0])] = b
	_content = VBoxContainer.new()
	_content.add_theme_constant_override("separation", 16)
	_content.custom_minimum_size = Vector2(0, CARD.y * 2 + ROW_GAP)
	body.add_child(_content)


## Nine'nin yedek yüzü (Ersin'in portresi yokken modelden çekilen; main verir).
func set_face(texture: Texture2D) -> void:
	_fallback_face = texture
	_show_line()


## Nine'nin sözü ve sözün ifadesiyle yüzü (Moods: satın almada paketi uzatır, satışta sevinir).
func _show_line() -> void:
	_line.text = tr(_line_key) % _line_args if not _line_args.is_empty() else tr(_line_key)
	var texture := Moods.face("nine", _line_key)
	if texture == null:
		texture = _fallback_face
	_face.texture = texture
	_face.visible = texture != null
	_icon.visible = texture == null


## Açar: kovada balık varsa Kova sekmesi, yoksa en son bakılan takım sekmesi (ilk açılışta Kamış).
## look: bakılacak teknik (boşsa elindeki).
func open_shop(tab: String = "", look: String = "") -> void:
	technique = look if not look.is_empty() else GameState.save.technique
	if not tab.is_empty():
		_tab = tab
	elif not GameState.save.bucket.is_empty():
		_tab = "sell"
	elif _tab == "sell":
		_tab = _last_gear_tab
	_say("UI_NINE_SHOP_HELLO")
	open()


func refresh() -> void:
	set_header(tr("UI_SHOP_TITLE"), "shop", WIDTH)
	_title.visible = false
	_show_line()
	Dialog.clear(_coins)
	_coins.add_child(Dialog.coin_pill(GameState.save.coins))
	for id: String in _tab_buttons:
		var b: Button = _tab_buttons[id]
		b.text = UiKit.upper(tr(_tab_title(id, technique)))
		b.add_theme_font_size_override("font_size", UiKit.fit_size(b.text, b.get_theme_font("font"), 26, TAB.x - 104.0, 18))
		(_tab_icons[id] as GameIcon).kind = _tab_icon(id, technique)
		_style_tab(b, id == _tab)
	for id: String in _tech_buttons:
		_style_tech(_tech_buttons[id], id)
	Dialog.clear(_content)
	if _tab == "sell":
		_build_sell()
	else:
		_build_gear()


## Bir sekmenin kartları (gear.json'daki sıra) bakılan teknikte: Kamış sekmesinde o tekniğin
## kamışları, tekniğe özel sekmede o tekniğin takımı. Kovalardan yalnızca sıradaki
## (Bucket.next_bucket; kayıt verilmezse yeni oyuncununki). Sekme başına en çok CARDS (test denetler).
static func items_for(db: ContentDB, tab: String, save: SaveData = null, look: String = "float") -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for category: String in tab_categories(tab, look):
		if category == "bucket":
			out.append(Bucket.next_bucket(db, save if save != null else SaveData.create_new(0)))
			continue
		for g in db.gear_in(category):
			if category == "rod" and str(g["technique"]) != look:
				continue
			out.append(g)
	return out


## Sekmenin kategorileri bakılan teknikte.
static func tab_categories(tab: String, look: String) -> Array:
	if tab == "tackle":
		return (TECHNIQUE_TACKLE.get(look, TECHNIQUE_TACKLE["float"]) as Array)[0]
	for t: Array in TABS:
		if str(t[0]) == tab:
			return t[3]
	return []


## Başka bir tekniğin takımına bak (başlıktaki teknik düğmeleri, bot).
func select_technique(look: String) -> void:
	technique = look
	refresh()


## Sekmeyi değiştirir (sekme düğmeleri, bot).
func select_tab(tab: String) -> void:
	_tab = tab
	if tab != "sell":
		_last_gear_tab = tab
	refresh()


func current_tab() -> String:
	return _tab


# --- Takım kartları ---------------------------------------------------------------

func _build_gear() -> void:
	var grid := GridContainer.new()
	grid.columns = COLUMNS
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", ROW_GAP)
	_content.add_child(grid)
	for item in items_for(GameState.db, _tab, GameState.save):
		grid.add_child(_gear_card(item))


func _gear_card(item: Dictionary) -> Control:
	var db := GameState.db
	var save := GameState.save
	var id := str(item["id"])
	var category := str(item["category"])
	var equipped := _is_equipped(item)
	var panel := PanelContainer.new()
	panel.name = "Card_" + id
	panel.custom_minimum_size = CARD
	var style := UiKit.framed("card", UiKit.card_style(BETTER if equipped else UiKit.CREAM_EDGE, 28,
			UiKit.CREAM_CARD, 6 if equipped else 4), UiKit.CARD_CORNER)
	panel.add_theme_stylebox_override("panel", style)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 8)
	panel.add_child(column)
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 14)
	column.add_child(top)
	top.add_child(_gear_icon(item, 104))
	var info := VBoxContainer.new()
	info.add_theme_constant_override("separation", 0)
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(info)
	# Uzun adlar küçük yazılır; yine sığmazsa sonu "…" olur (clip_text değil: büyük harflerin
	# üstündeki nokta ve şapkalar kırpılırdı).
	var title := UiKit.upper(tr("GEAR_" + id))
	var name_label := UiKit.ink(title, UiKit.SIZE_BODY if title.length() <= 16 else 32)
	name_label.add_theme_font_override("font", UiKit.display_font())
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	info.add_child(name_label)
	var desc := UiKit.ink(tr("GEAR_" + id + "_DESC"), 26, UiKit.INK_SOFT)
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.max_lines_visible = 2
	desc.custom_minimum_size = Vector2(378, 0)
	info.add_child(desc)
	var bottom := HBoxContainer.new()
	bottom.add_theme_constant_override("separation", 10)
	bottom.size_flags_vertical = Control.SIZE_EXPAND_FILL
	bottom.alignment = BoxContainer.ALIGNMENT_END
	column.add_child(bottom)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 4)
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.alignment = BoxContainer.ALIGNMENT_END
	bottom.add_child(left)
	if category in ["bait", "lure", "fly"]:
		_bait_info(left, item)
	else:
		for stat: Array in STATS.get(category, []):
			left.add_child(_stat_row(item, stat))
	var action := _action(item)
	action.size_flags_vertical = Control.SIZE_SHRINK_END
	bottom.add_child(action)
	if not equipped and Economy.buy_block(db, save, id) == "rank":
		panel.modulate = Color(1, 1, 1, 0.82)
	if equipped and style is StyleBoxTexture:
		# Resimli kartın kenarı ahşap: kuşanılanı çevresindeki yeşil halka gösterir.
		var ring := PanelContainer.new()
		ring.add_theme_stylebox_override("panel", UiKit.ring_style(BETTER))
		ring.add_child(panel)
		return ring
	return panel


## Kartın tek düğmesi:
## - tükenen yem: elinde var ama takılı değilse TAK; yoksa ya da takılıysa fiyat (yeniden al);
## - sahip olunan takım: TAKILI ya da TAK; kepçe ve kova: SENDE;
## - alınmamış: rütbe yetmiyorsa kilit (Nine söyler), yoksa fiyat (para yetmezse gri; Nine söyler).
func _action(item: Dictionary) -> Button:
	var db := GameState.db
	var save := GameState.save
	var id := str(item["id"])
	var category := str(item["category"])
	var consumable := category == "bait" and int(item["pack"]) > 0
	if consumable:
		if int(save.baits.get(id, 0)) > 0 and not _is_equipped(item):
			return _button(tr("UI_SHOP_EQUIP"), UiKit.SECONDARY, func() -> void: _equip(id), ACTION)
	elif Economy.owns(db, save, id):
		if not category in ContentDB.GEAR_SLOTS:
			return _button(tr("UI_SHOP_OWNED"), UiKit.SUCCESS, func() -> void: Sounds.play("ui_tap"), ACTION)
		if _is_equipped(item):
			return _button(tr("UI_SHOP_EQUIPPED"), UiKit.SUCCESS, func() -> void: Sounds.play("ui_tap"), ACTION)
		return _button(tr("UI_SHOP_EQUIP"), UiKit.SECONDARY, func() -> void: _equip(id), ACTION)
	var block := Economy.buy_block(db, save, id)
	if block == "owned":
		# Daha büyük bir kova sende: bu bir şey katmaz.
		return _button(tr("UI_SHOP_OWNED"), UiKit.SUCCESS, func() -> void: Sounds.play("ui_tap"), ACTION)
	if block == "rank":
		var lock := _button(tr("UI_SHOP_RANK") % int(item["rank"]), UiKit.NEUTRAL,
				func() -> void: _refuse("UI_NINE_RANK", [int(item["rank"])]), ACTION)
		lock.icon = ItemArt.ui("lock")
		return lock
	var price := _button(UiKit.format_int(int(item["price"])), UiKit.PRIMARY if block.is_empty() else UiKit.NEUTRAL,
			func() -> void: _buy(id), ACTION)
	price.icon = ItemArt.ui("coin")
	return price


func _button(text: String, color: Color, action: Callable, min_size: Vector2) -> Button:
	var b := UiKit.button(text, color, UiKit.SIZE_SMALL + 4, min_size)
	b.expand_icon = true
	b.add_theme_constant_override("icon_max_width", 52)
	b.pressed.connect(action)
	return b


## Bir değer satırı: ad, çubuk (bu takımın değeri; işaret kuşanılanın) ve gerekirse sayı.
func _stat_row(item: Dictionary, stat: Array) -> Control:
	var key := str(stat[0])
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 10)
	var label := UiKit.ink(tr(str(stat[1])), 24, UiKit.INK_SOFT)
	label.custom_minimum_size = Vector2(112, 0)
	row.add_child(label)
	if str(stat[2]) == "★":
		var stars := UiKit.stars(int(item.get(key, 0)), STAR_SIDE)
		stars.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(stars)
		return row
	var value := float(item.get(key, 0.0))
	var current := _current_value(str(item["category"]), key)
	# Aralık şimdikini de kapsar: tek eşyalı kategoride (kepçe) işaret "kepçesiz" yerinde dursun.
	var span := _span(str(item["category"]), key)
	span = Vector2(minf(span.x, current), maxf(span.y, current))
	var bar := StatBar.new()
	bar.custom_minimum_size = Vector2(70, 22)
	bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	bar.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	bar.value = _fraction(value, span)
	bar.marker = _fraction(current, span)
	bar.color = BETTER if value > current + 0.0001 else (WORSE if value < current - 0.0001 else SAME)
	row.add_child(bar)
	match str(stat[2]):
		"m":
			row.add_child(UiKit.ink(UiKit.format_float(value) + " m", 24))
		"#":
			row.add_child(UiKit.ink(str(int(value)), 24))
	return row


## Yemin (yapay yemin, sineğin) çektiği balıklar (en çok iki): bir gölgenin o balık olma şansı
## çekimsiz ve bu yemle, yemin tekniğinde ("Levrek %22 → %41"; Balık Defteri'yle aynı işlev,
## CatchOdds). Altında elindeki sayı (yapay yem ve sinek tükenmez: yalnızca takılıysa).
func _bait_info(parent: VBoxContainer, item: Dictionary) -> void:
	var db := GameState.db
	var spot := Zones.place(db, spot_id if not spot_id.is_empty() else db.main_spot, zone_id)
	var attract: Dictionary = item["attract"]
	var tech := _item_technique(item)
	var plain := CatchOdds.species_ppm(db, spot, { "technique": tech })
	var baited := CatchOdds.species_ppm(db, spot, { "attract": attract, "technique": tech })
	var keys := attract.keys().filter(func(k: Variant) -> bool: return plain.has(k))
	keys.sort_custom(func(a: Variant, b: Variant) -> bool: return float(attract[a]) > float(attract[b]))
	for i in mini(2, keys.size()):
		var fish_id := str(keys[i])
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)
		row.add_child(GameIcon.make("fish:" + fish_id, 40))
		var odds := "%s %s → %s" % [tr("FISH_" + fish_id), UiKit.format_percent(int(plain[fish_id])),
				UiKit.format_percent(int(baited[fish_id]))]
		row.add_child(UiKit.ink(odds, UiKit.fit_size(odds, UiKit.body_font(), 24, ODDS_TEXT, 18)))
		parent.add_child(row)
	if str(item["category"]) != "bait":
		if _is_equipped(item):
			parent.add_child(UiKit.ink(tr("UI_SHOP_EQUIPPED"), 24, BETTER))
		return
	var pack := int(item["pack"])
	var count := int(GameState.save.baits.get(str(item["id"]), 0))
	var text := tr("UI_SHOP_UNLIMITED") if pack == 0 else tr("UI_SHOP_HAVE") % count
	var equipped := _is_equipped(item)
	if equipped:
		text += " · " + tr("UI_SHOP_EQUIPPED")
	elif pack > 0:
		text += " · " + tr("UI_SHOP_PACK") % pack
	parent.add_child(UiKit.ink(text, 24, BETTER if equipped else UiKit.INK_SOFT))


static func _fraction(value: float, span: Vector2) -> float:
	if span.y - span.x < 0.0001:
		return 1.0
	return lerpf(0.12, 1.0, clampf((value - span.x) / (span.y - span.x), 0.0, 1.0))


## Bu değerin kategorideki en küçük ve en büyük hâli (çubuklar buna göre dolar).
func _span(category: String, key: String) -> Vector2:
	var lo := INF
	var hi := -INF
	for g in GameState.db.gear_in(category):
		var v := float(g.get(key, 0.0))
		lo = minf(lo, v)
		hi = maxf(hi, v)
	return Vector2(lo, hi)


## Şu an kullanılanın değeri: kuşanılan takım; kepçe yoksa kuraldaki uzaklık, kova en büyüğü.
func _current_value(category: String, key: String) -> float:
	var db := GameState.db
	var save := GameState.save
	if category in ContentDB.GEAR_SLOTS:
		return float(db.gear_item(Economy.equipped(db, save, category, _slot_technique(category))).get(key, 0.0))
	var best := 0.0
	var any := false
	for g in db.gear_in(category):
		if Economy.owns(db, save, str(g["id"])):
			best = maxf(best, float(g.get(key, 0.0)))
			any = true
	if not any and key == "catch_m":
		return db.rules.catch_m
	return best


func _is_equipped(item: Dictionary) -> bool:
	var category := str(item["category"])
	if not category in ContentDB.GEAR_SLOTS:
		return false
	return Economy.equipped(GameState.db, GameState.save, category, _item_technique(item)) == str(item["id"])


## Takımın kuşanıldığı teknik: kamış kendi tekniği; yem bakılan teknik (yem kullanmıyorsa
## şamandıra); yapay yem, kurşun, sinek ve iğne kendi tekniği; ortak yuvada bakılan teknik.
func _item_technique(item: Dictionary) -> String:
	if str(item["category"]) == "rod":
		return str(item["technique"])
	return _slot_technique(str(item["category"]))


func _slot_technique(slot: String) -> String:
	var db := GameState.db
	if db.is_shared(slot):
		return technique
	var owner := db.slot_technique(slot)
	if not owner.is_empty():
		return owner
	return technique if db.uses_slot(technique, slot) else "float"


func _gear_icon(item: Dictionary, side: float) -> Control:
	var art := ItemArt.gear(str(item.get("icon", item["id"])))
	if art != null:
		var rect := TextureRect.new()
		rect.texture = art
		rect.custom_minimum_size = Vector2(side, side)
		rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		rect.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		return rect
	return GameIcon.make(str(item["kind"]), side)


# --- Kova ve satış ---------------------------------------------------------------

func _build_sell() -> void:
	var db := GameState.db
	var save := GameState.save
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 14)
	_content.add_child(head)
	head.add_child(GameIcon.make("bucket", 72))
	head.add_child(UiKit.ink(tr("UI_SHOP_BUCKET") % [save.bucket.size(), Bucket.capacity(db, save)], UiKit.SIZE_BODY))
	if save.bucket.is_empty():
		var empty := UiKit.ink(tr("UI_SHOP_BUCKET_EMPTY"), UiKit.SIZE_BODY, UiKit.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER)
		empty.size_flags_vertical = Control.SIZE_EXPAND_FILL
		_content.add_child(empty)
		return
	var grid := GridContainer.new()
	grid.columns = 2
	grid.add_theme_constant_override("h_separation", 16)
	grid.add_theme_constant_override("v_separation", 10)
	_content.add_child(grid)
	var rows := _bucket_rows()
	for i in mini(rows.size(), SELL_ROWS):
		grid.add_child(_sell_row(rows[i]))
	if rows.size() > SELL_ROWS:
		grid.add_child(UiKit.ink(tr("UI_SHOP_MORE_KINDS") % (rows.size() - SELL_ROWS), 26, UiKit.INK_SOFT))
	_content.add_child(UiKit.spacer(true))
	var foot := HBoxContainer.new()
	foot.add_theme_constant_override("separation", 18)
	foot.alignment = BoxContainer.ALIGNMENT_END
	_content.add_child(foot)
	foot.add_child(UiKit.ink(tr("UI_SHOP_TOTAL"), UiKit.SIZE_BODY))
	foot.add_child(GameIcon.make("coin", 64))
	foot.add_child(UiKit.title(UiKit.format_int(Economy.bucket_value(db, save)), UiKit.SIZE_TITLE, UiKit.ACCENT))
	var sell := _button(tr("UI_SHOP_SELL_ALL"), UiKit.SUCCESS, _sell, Vector2(380, ACTION.y))
	sell.name = "SellAll"
	sell.icon = ItemArt.ui("sell")
	sell.add_theme_constant_override("icon_max_width", 64)
	foot.add_child(sell)


## Kovadaki balıklar tür başına: [tür, sayı, değer, en iyi nadirlik]; nadirden sıradana.
func _bucket_rows() -> Array[Array]:
	var db := GameState.db
	var by_fish := {}
	for entry in GameState.save.bucket:
		var id := str(entry["fish"])
		if not by_fish.has(id):
			by_fish[id] = [id, 0, 0, int(db.fish_by_id(id).get("rarity", 0))]
		var row: Array = by_fish[id]
		row[1] = int(row[1]) + 1
		row[2] = int(row[2]) + Economy.fish_value(db, id, int(entry["size_cm"]))
	var rows: Array[Array] = []
	for id: String in by_fish:
		rows.append(by_fish[id])
	rows.sort_custom(func(a: Array, b: Array) -> bool:
		return int(a[3]) > int(b[3]) if int(a[3]) != int(b[3]) else int(a[2]) > int(b[2]))
	return rows


func _sell_row(row: Array) -> Control:
	var db := GameState.db
	var fish_id := str(row[0])
	var panel := PanelContainer.new()
	panel.custom_minimum_size = SELL_ROW
	panel.add_theme_stylebox_override("panel", UiKit.framed("card", UiKit.card_style(UiKit.rarity_color(db, int(row[3])), 22),
			UiKit.CARD_CORNER * 0.8))
	var line := HBoxContainer.new()
	line.add_theme_constant_override("separation", 14)
	panel.add_child(line)
	line.add_child(GameIcon.make("fish:" + fish_id, 72))
	var name_box := VBoxContainer.new()
	name_box.add_theme_constant_override("separation", 0)
	name_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	line.add_child(name_box)
	name_box.add_child(UiKit.ink(tr("FISH_" + fish_id), UiKit.SIZE_BODY))
	name_box.add_child(UiKit.rarity_badge(db, int(row[3]), 22))
	line.add_child(UiKit.ink("×%d" % int(row[1]), UiKit.SIZE_BODY))
	line.add_child(GameIcon.make("coin", 48))
	line.add_child(UiKit.ink(UiKit.format_int(int(row[2])), UiKit.SIZE_BODY))
	return panel


# --- İşlemler --------------------------------------------------------------------

func _buy(id: String) -> void:
	var db := GameState.db
	var save := GameState.save
	match Economy.buy_block(db, save, id):
		"":
			var item := db.gear_item(id)
			var first_rod := str(item["category"]) == "rod" and not Economy.technique_ready(db, save, str(item["technique"]))
			Economy.buy(db, save, id, technique)
			# Tekniğin ilk kamışı: teknik ele geçer (takım çantasında da seçili).
			if first_rod:
				save.technique = str(item["technique"])
			GameState.save_game()
			Sounds.play("buy")
			Sounds.haptic(18)
			_say("UI_NINE_BOUGHT")
			gear_changed.emit()
			refresh()
		"coins":
			_refuse("UI_NINE_NO_COINS")
		"rank":
			_refuse("UI_NINE_RANK", [int(db.gear_item(id)["rank"])])


func _equip(id: String) -> void:
	if not Economy.equip(GameState.db, GameState.save, id, technique):
		Sounds.play("error")
		return
	GameState.save_game()
	Sounds.play("equip")
	Sounds.haptic(10)
	_say("UI_NINE_EQUIP")
	gear_changed.emit()
	refresh()


func _sell() -> void:
	var earned := Economy.sell_all(GameState.db, GameState.save)
	if earned <= 0:
		return
	GameState.save_game()
	Sounds.play("coins")
	Sounds.haptic(24)
	_say("UI_NINE_SOLD", [UiKit.format_int(earned)])
	sold.emit(earned)
	refresh()


## Olmayan bir şey istendi: hata sesi ve Nine'nin açıklaması (düğme kilitli görünmez; ne
## yapılacağı söylenir).
func _refuse(key: String, args: Array = []) -> void:
	Sounds.play("error")
	_say(key, args)
	_show_line()


func _say(key: String, args: Array = []) -> void:
	_line_key = key
	_line_args = args


# --- Sekmeler --------------------------------------------------------------------

func _tab_button(id: String, icon_kind: String) -> Button:
	var b := Button.new()
	b.name = "Tab_" + id
	b.custom_minimum_size = TAB
	b.focus_mode = Control.FOCUS_NONE
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.add_theme_font_size_override("font_size", 26)
	b.clip_text = true
	var icon := GameIcon.make(icon_kind, 64)
	icon.position = Vector2(14, (TAB.y - 64.0) * 0.5)
	b.add_child(icon)
	_tab_icons[id] = icon
	b.pressed.connect(func() -> void:
		if _tab != id:
			Sounds.play("ui_tap")
			select_tab(id))
	return b


func _style_tab(b: Button, selected: bool) -> void:
	var fill := UiKit.CREAM_CARD if selected else Color("#ead8b5")
	var edge := UiKit.PRIMARY if selected else UiKit.CREAM_EDGE
	for state: String in ["normal", "hover", "pressed", "hover_pressed"]:
		var flat := UiKit.card_style(edge, 24, fill, 6 if selected else 3)
		flat.content_margin_left = 88
		flat.content_margin_right = 12
		# Arayüz kitinin kemerli sekmesi: seçili olan parlak, ötekiler biraz koyu.
		var sb := UiKit.framed("tab", flat, TAB_CORNER)
		if sb is StyleBoxTexture and not selected:
			sb = sb.duplicate() as StyleBox
			(sb as StyleBoxTexture).modulate_color = Color(0.86, 0.82, 0.76)
		b.add_theme_stylebox_override(state, sb)
	for state: String in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(state, UiKit.INK if selected else UiKit.INK_SOFT)
	b.add_theme_constant_override("outline_size", 0)


static func _tab_title(id: String, look: String = "float") -> String:
	if id == "tackle":
		return str((TECHNIQUE_TACKLE.get(look, TECHNIQUE_TACKLE["float"]) as Array)[1])
	for t: Array in TABS:
		if str(t[0]) == id:
			return str(t[2])
	return ""


static func _tab_icon(id: String, look: String) -> String:
	if id == "tackle":
		return str((TECHNIQUE_TACKLE.get(look, TECHNIQUE_TACKLE["float"]) as Array)[2])
	for t: Array in TABS:
		if str(t[0]) == id:
			return str(t[1])
	return "question"


# --- Teknik düğmeleri ---------------------------------------------------------------

func _tech_button(id: String) -> Button:
	var b := Button.new()
	b.name = "Tech_" + id
	b.custom_minimum_size = TECH_BUTTON
	b.focus_mode = Control.FOCUS_NONE
	var icon := GameIcon.make("tech_" + id, 92)
	icon.name = "Icon"
	icon.position = (TECH_BUTTON - Vector2(92, 92)) * 0.5
	b.add_child(icon)
	var lock := HBoxContainer.new()
	lock.name = "Lock"
	lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lock.add_theme_constant_override("separation", 0)
	lock.position = Vector2(6, TECH_BUTTON.y - 50.0)
	lock.add_child(GameIcon.make("lock", 44))
	var rank := UiKit.title(str(GameState.db.technique_rank(id)), 34, UiKit.TEXT, HORIZONTAL_ALIGNMENT_LEFT, 8)
	rank.mouse_filter = Control.MOUSE_FILTER_IGNORE
	lock.add_child(rank)
	b.add_child(lock)
	b.pressed.connect(func() -> void:
		if technique != id:
			Sounds.play("ui_tap")
			select_technique(id)
		if Rank.rank(GameState.db, GameState.save) < GameState.db.technique_rank(id):
			_refuse("UI_NINE_RANK", [GameState.db.technique_rank(id)]))
	return b


## Teknik düğmesi: bakılan teknik yeşil halkalı; rütbesi yetmeyen kilitli (rütbesi yazar).
func _style_tech(b: Button, id: String) -> void:
	var selected := id == technique
	var locked := Rank.rank(GameState.db, GameState.save) < GameState.db.technique_rank(id)
	var sb := UiKit.card_style(BETTER if selected else UiKit.CREAM_EDGE, 24,
			UiKit.CREAM_CARD if selected else Color("#ead8b5"), 6 if selected else 3)
	for state: String in ["normal", "hover", "pressed", "hover_pressed"]:
		b.add_theme_stylebox_override(state, sb)
	(b.get_node("Lock") as Control).visible = locked
	(b.get_node("Icon") as GameIcon).modulate_art = Color(1, 1, 1, 0.55) if locked else Color.WHITE


## Değer çubuğu: yuvarlak zemin, dolgu (bu takım) ve kuşanılanın yerinde koyu bir çizgi.
class StatBar:
	extends Control

	var value: float = 0.5
	var marker: float = -1.0
	var color: Color = Color("#a88a64")

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var r := size.y * 0.5
		var back := StyleBoxFlat.new()
		back.bg_color = Color("#e6d5b8")
		back.set_corner_radius_all(int(r))
		draw_style_box(back, Rect2(Vector2.ZERO, size))
		var fill := StyleBoxFlat.new()
		fill.bg_color = color
		fill.set_corner_radius_all(int(r))
		draw_style_box(fill, Rect2(Vector2.ZERO, Vector2(maxf(size.y, size.x * value), size.y)))
		if marker >= 0.0:
			var x := clampf(size.x * marker, 3.0, size.x - 3.0)
			draw_line(Vector2(x, -4.0), Vector2(x, size.y + 4.0), UiKit.INK, 4.0)
