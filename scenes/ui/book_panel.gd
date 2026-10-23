class_name BookPanel
extends Dialog
## Balık Defteri (docs/gdd.md §10.2): gölün bütün türleri, nadirlik sırasıyla 6×2'lik sayfalarda
## (kaydırma yok; 12'den çok tür olunca sayfa düğmeleri). Tutulanlar kendi resmi ve nadirlik
## renginde çerçeveyle, tutulmayanlar koyu siluet ve "???" ile. Sağda seçili türün bilgisi:
## nadirlik, rekor boy ve yıldız, sayılar ya da tutulmadıysa ipucu (sevdiği yem, ne sıklıkla
## görüldüğü); bu göldeki gerçek oranı (CatchOdds: gölgeyi doğuran işlevin aynısı, kuşanılan yemle),
## gölün nadirlik oranları ve şans garantisi sayaçları (gelir kuralı 10: oranlar ve garanti açık).
## İlk mektuptan sonra ikinci görünüş "Gölün Sırrı" (Dalga 4, 5. adım; düğmesi sayfa düğmelerinin sağında, iki
## görünüşte aynı yerde): 3×2 mektup kartı (okunan: bölgesi ve adı, dokununca yeniden okunur: letter_requested;
## sıradaki: bölgesi ve ne zaman; ötekiler soru işareti), sağda dörde yırtılmış harita (SecretMap), parçalar,
## altın istek ya da X'in yeri, altın hamur. Panelin boyu iki görünüşte aynı.

## Okunan bir mektuba dokunuldu (main mektubu yeniden açar; Dede konuşmaz).
signal letter_requested(n: int)

## Bir sayfadaki tür (6 sütun × 2 satır).
const PAGE_SIZE := 12
const COLUMNS := 6
const WIDTH := 1760.0
const CARD := Vector2(168, 232)
## Görülme sıklığı ipucu: tür oranı bu kadar ppm ve üstündeyse "sık", "ara sıra".
const OFTEN_PPM := 200_000
const SOMETIMES_PPM := 80_000
## "Sevdiği yem" ipucu: yuva (kategori) -> söz. Türün tekniklerinin kullandığı yuvalara bakılır.
const FAVOURITE_KEYS := { "bait": "UI_BOOK_BAIT_HINT", "lure": "UI_BOOK_LURE_HINT", "fly": "UI_BOOK_FLY_HINT" }
## Türün sevdiği vakit ya da hava ipucuna yazılır, çarpanı en az bu kadarsa (fish.json when, weather).
const LIKES_AT := 1.3
const UNKNOWN_BORDER := Color("#cdb48a")
const SILHOUETTE := Color(0.16, 0.1, 0.06, 0.6)
## Tutulmamış türün görselli nadirlik simgesi: şekli belli, rengi soluk.
const UNFOUND_MARK := Color(0.42, 0.33, 0.24, 0.7)
## Ayrıntıdaki balık resmi ve onu saran nadirlik çerçevesinin köşe boyu (balık kartı gibi).
const DETAIL_ART := 110.0
const DETAIL_FRAME_CORNER := 50.0
## Gölün Sırrı: mektup kartları (3×2; balık ızgarasının yerini kaplar), haritanın boyu, görünüş düğmesi.
const LETTER_COLUMNS := 3
const LETTER_CARD := Vector2(348, 232)
const SECRET_MAP := Vector2(500, 330)
const VIEW_BUTTON := Vector2(330, 122)
const LETTER_EDGE := Color("#c79f62")
const LETTER_FILL := Color("#f7ecd0")

## Defterin gölü (main verir; spots.json kimliği) ve balıkçının bölgesi (oranlar o bölgenin).
var spot_id: String = ""
var zone_id: String = ""

var _grid: GridContainer
var _pager: HBoxContainer
var _detail: VBoxContainer
var _page: int = 0
var _selected: String = ""
## Görünüşler: balıklar ya da Gölün Sırrı ("fish", "secret"); sırrın mektup kartları, alttaki satırı ve haritası.
var _view: String = "fish"
var _fish_view: HBoxContainer
var _fish_foot: HBoxContainer
var _secret_view: HBoxContainer
var _letters: GridContainer
var _secret_foot: HBoxContainer
var _secret_info: VBoxContainer
var _secret_lines: VBoxContainer
var _map: SecretMap


func _build() -> void:
	set_header(tr("UI_BOOK"), "book", WIDTH)
	_fish_view = HBoxContainer.new()
	_fish_view.add_theme_constant_override("separation", 22)
	body.add_child(_fish_view)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 12)
	_fish_view.add_child(left)
	_grid = GridContainer.new()
	_grid.columns = COLUMNS
	_grid.add_theme_constant_override("h_separation", 12)
	_grid.add_theme_constant_override("v_separation", 12)
	_grid.custom_minimum_size = Vector2(COLUMNS * CARD.x + (COLUMNS - 1) * 12, CARD.y * 2 + 12)
	left.add_child(_grid)
	# Alttaki satır: sayfa düğmeleri ve sağda Gölün Sırrı düğmesi (sırrın görünüşünde aynı yerde Balıklar).
	_fish_foot = HBoxContainer.new()
	_fish_foot.add_theme_constant_override("separation", 14)
	_fish_foot.custom_minimum_size.y = VIEW_BUTTON.y
	left.add_child(_fish_foot)
	_pager = HBoxContainer.new()
	_pager.add_theme_constant_override("separation", 14)
	_pager.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_fish_foot.add_child(_pager)
	var detail_panel := PanelContainer.new()
	detail_panel.add_theme_stylebox_override("panel", UiKit.framed("card", UiKit.card_style(), UiKit.CARD_CORNER))
	detail_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_fish_view.add_child(detail_panel)
	_detail = VBoxContainer.new()
	_detail.add_theme_constant_override("separation", 8)
	detail_panel.add_child(_detail)
	_build_secret_view()


## Açar; fish_id verilirse onu seçer (sayfası açılır). Her açılış balıklarla başlar.
func open_book(fish_id: String = "") -> void:
	if not fish_id.is_empty():
		_selected = fish_id
	_page = -1
	_view = "fish"
	open()


## Gölün Sırrı görünüşünde açar (bot ve testler; oyuncu düğmeyle geçer).
func open_secret() -> void:
	_page = -1
	_view = "secret"
	open()


## Gösterilen görünüş ("fish" ya da "secret").
func view() -> String:
	return _view


func refresh() -> void:
	var db := GameState.db
	var save := GameState.save
	if save.letters <= 0:
		_view = "fish"
	_fish_view.visible = _view == "fish"
	_secret_view.visible = _view == "secret"
	clear(header_extra)
	if _view == "secret":
		set_header(tr("UI_SECRET_TITLE"), "item:map_piece", WIDTH)
		_build_secret(db, save)
		return
	set_header(tr("UI_BOOK"), "book", WIDTH)
	var count := PanelContainer.new()
	count.add_theme_stylebox_override("panel", UiKit.pill_style(Color(0.18, 0.1, 0.04, 0.85)))
	var fish := species(db, spot_id)
	var found := 0
	for f in fish:
		if save.records.has(str(f["id"])):
			found += 1
	count.add_child(UiKit.title("%d / %d" % [found, fish.size()], 46, UiKit.ACCENT, HORIZONTAL_ALIGNMENT_CENTER, 10))
	header_extra.add_child(_conditions_pill(db, save))
	header_extra.add_child(count)
	_build_grid(db, save, fish)
	_build_detail(db, save)


## Başlıkta gölün şimdiki koşulu (oranlar ona göre): vaktin ve havanın ikonu, "Gece · Fırtınalı" (yağmurlu
## gece fırtına) ve sevgi seviyesi 2 ve üstündeyse sevginin en çok Nadir+ payı.
func _conditions_pill(db: ContentDB, save: SaveData) -> PanelContainer:
	var cond := WorldState.conditions(db, save)
	var phase := str(cond["phase"])
	var weather := "storm" if Weather.stormy(str(cond["weather"]), phase) else str(cond["weather"])
	var pill := PanelContainer.new()
	pill.add_theme_stylebox_override("panel", UiKit.pill_style(Color(0.18, 0.1, 0.04, 0.85)))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	pill.add_child(row)
	row.add_child(GameIcon.make("phase_" + phase, 48))
	if weather != "clear":
		row.add_child(GameIcon.make("weather_" + weather, 48))
	var text := tr("UI_BOOK_NOW") % [tr("PHASE_" + phase), tr("WEATHER_" + weather)]
	var love := int(cond["love"])
	if love > 1:
		text += " · " + tr("UI_BOOK_LOVE") % [love, UiKit.format_percent((LakeLove.rare_bonus_pm(db.rules, love) - 1000) * 1000)]
	var label := UiKit.label(text, 26, UiKit.TEXT)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)
	return pill


## Gölün türleri, defterin sırasıyla: nadirlik, sonra fish.json sırası. Hikâyenin balıkları da (Gölün
## Bekçisi: bölgelerin tablosunda yok, spots.json story_fish).
static func species(db: ContentDB, spot: String) -> Array[Dictionary]:
	var def := db.spot(spot)
	var ids: PackedStringArray = def.get("fish_ids", PackedStringArray())
	var story: PackedStringArray = def.get("story_fish", PackedStringArray())
	var out: Array[Dictionary] = []
	for f in db.fish:
		if str(f["id"]) in ids or str(f["id"]) in story:
			out.append(f)
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a["rarity"]) < int(b["rarity"]) if int(a["rarity"]) != int(b["rarity"]) \
				else db.fish_index(str(a["id"])) < db.fish_index(str(b["id"])))
	return out


## Bu göldeki tür oranları elindeki teknik, kuşanılan takım ve gölün o anki koşuluyla (vakit, hava,
## göl sevgisi: WorldState; doğan gölgeler de bunu kullanır).
static func odds(db: ContentDB, save: SaveData, spot: String, zone: String = "") -> Dictionary:
	var gear := Economy.gear_for(db, save, save.technique)
	return CatchOdds.species_ppm(db, Zones.place(db, spot, zone),
			CatchOdds.context(gear, gear.technique, WorldState.conditions(db, save)))



## Bot ve testler: seçili tür.
func selected() -> String:
	return _selected


# --- Izgara ----------------------------------------------------------------------

func _build_grid(db: ContentDB, save: SaveData, fish: Array[Dictionary]) -> void:
	clear(_grid)
	if fish.is_empty():
		return
	if _selected.is_empty() or fish.all(func(f: Dictionary) -> bool: return str(f["id"]) != _selected):
		_selected = str(fish[0]["id"])
	var pages := maxi(1, ceili(float(fish.size()) / PAGE_SIZE))
	if _page < 0:
		_page = 0
		for i in fish.size():
			if str(fish[i]["id"]) == _selected:
				_page = floori(float(i) / PAGE_SIZE)
	_page = clampi(_page, 0, pages - 1)
	for i in range(_page * PAGE_SIZE, mini(fish.size(), (_page + 1) * PAGE_SIZE)):
		_grid.add_child(_fish_card(db, save, fish[i]))
	_build_pager(pages, fish)


func _build_pager(pages: int, fish: Array[Dictionary]) -> void:
	clear(_pager)
	_set_view_button(_fish_foot, "secret")
	if pages <= 1:
		return
	for page in pages:
		var b := UiKit.button(str(page + 1), UiKit.PRIMARY if page == _page else UiKit.NEUTRAL, UiKit.SIZE_BODY,
				Vector2(122, 122))
		var target := page
		b.pressed.connect(func() -> void:
			if _page != target:
				Sounds.play("ui_tap")
			_page = target
			_build_grid(GameState.db, GameState.save, fish))
		_pager.add_child(b)


func _fish_card(db: ContentDB, save: SaveData, f: Dictionary) -> Button:
	var id := str(f["id"])
	var entry: Dictionary = save.records.get(id, {})
	var found := not entry.is_empty()
	var rarity := int(f["rarity"])
	var border := UiKit.rarity_color(db, rarity) if found else UNKNOWN_BORDER
	var b := Button.new()
	b.name = "Fish_" + id
	b.custom_minimum_size = CARD
	b.focus_mode = Control.FOCUS_NONE
	var fill := Color(border, 0.14) if found else Color("#efe2c6")
	var sb := UiKit.card_style(border, 24, fill, 8 if id == _selected else 4)
	for state: String in ["normal", "hover", "pressed", "hover_pressed"]:
		b.add_theme_stylebox_override(state, sb)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 2)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.offset_left = 8
	column.offset_right = -8
	column.offset_top = 8
	column.offset_bottom = -8
	b.add_child(column)
	var art := _art(id, 118, found)
	art.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(art)
	var name_text := tr("FISH_" + id) if found else "???"
	var label := UiKit.ink(name_text, UiKit.fit_size(name_text, UiKit.body_font(), 26, CARD.x - 20.0, 20), UiKit.INK,
			HORIZONTAL_ALIGNMENT_CENTER)
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	column.add_child(label)
	var foot := HBoxContainer.new()
	foot.alignment = BoxContainer.ALIGNMENT_CENTER
	foot.add_theme_constant_override("separation", 6)
	foot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(foot)
	# Nadirlik simgesi tutulmadan da görünür (ipucu); rengi tutulunca gelir (görselli simge
	# tutulmadıysa koyu gölge).
	var mark := GameIcon.make(UiKit.rarity_icon(db, rarity), 30, border if found else Color("#b9a27c"))
	if not found:
		mark.modulate_art = UNFOUND_MARK
	foot.add_child(mark)
	if found:
		foot.add_child(UiKit.ink(tr("UI_SIZE_CM") % int(entry["best_cm"]), 24, UiKit.INK_SOFT))
	b.pressed.connect(func() -> void:
		if _selected != id:
			Sounds.play("ui_tap")
		_selected = id
		_build_grid(GameState.db, GameState.save, species(GameState.db, spot_id))
		_build_detail(GameState.db, GameState.save))
	return b


## Ayrıntıdaki balık: tutulduysa nadirliğin çerçevesinde (arayüz kiti), yoksa koyu siluet.
func _framed_art(db: ContentDB, id: String, rarity: int, found: bool) -> Control:
	var frame := UiKit.framed("frame_" + db.rarity_id(rarity), StyleBoxEmpty.new(), DETAIL_FRAME_CORNER)
	if not found or not frame is StyleBoxTexture:
		return _art(id, 140, found)
	var box := PanelContainer.new()
	box.add_theme_stylebox_override("panel", frame)
	box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(_art(id, DETAIL_ART, true))
	return box


## Balığın resmi; tutulmadıysa koyu siluet.
static func _art(id: String, side: float, found: bool) -> TextureRect:
	var art := TextureRect.new()
	art.texture = ItemArt.fish(id)
	art.custom_minimum_size = Vector2(side, side)
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	if not found:
		art.modulate = SILHOUETTE
	return art


# --- Ayrıntı ---------------------------------------------------------------------

func _build_detail(db: ContentDB, save: SaveData) -> void:
	clear(_detail)
	var f := db.fish_by_id(_selected)
	if f.is_empty():
		return
	var id := _selected
	var entry: Dictionary = save.records.get(id, {})
	var found := not entry.is_empty()
	var rarity := int(f["rarity"])
	var head := HBoxContainer.new()
	head.add_theme_constant_override("separation", 14)
	_detail.add_child(head)
	head.add_child(_framed_art(db, id, rarity, found))
	var text := VBoxContainer.new()
	text.add_theme_constant_override("separation", 4)
	text.alignment = BoxContainer.ALIGNMENT_CENTER
	text.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(text)
	var title_color := UiKit.rarity_color(db, rarity).darkened(0.25) if found else UiKit.INK
	text.add_child(UiKit.title(tr("FISH_" + id) if found else "???", 44, title_color, HORIZONTAL_ALIGNMENT_LEFT, 0))
	text.add_child(UiKit.rarity_badge(db, rarity, 26))
	# Koruma altındaki tür (mersin) satılmaz: tutulur, göle bırakılır. Belli vakitte gelen efsaneler (Ay
	# Turnası, Kocabaş) de bırakılır: koruma değil, efsane sözüyle.
	if Bucket.release_only(db, id):
		var legend := not (f.get("only", {}) as Dictionary).is_empty()
		var protected := UiKit.ink(tr("UI_BOOK_LEGEND" if legend else "UI_BOOK_PROTECTED"), 26, UiKit.INK)
		protected.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		protected.custom_minimum_size = Vector2(420, 0)
		_detail.add_child(protected)
	if found:
		var best := HBoxContainer.new()
		best.add_theme_constant_override("separation", 10)
		text.add_child(best)
		best.add_child(UiKit.ink(tr("UI_BOOK_BEST") % int(entry["best_cm"]), 28, UiKit.INK))
		best.add_child(UiKit.stars(int(entry["best_stars"]), 30.0))
		_detail.add_child(UiKit.ink(tr("UI_BOOK_COUNT") % [int(entry["count"]), int(entry.get("released", 0))], 28, UiKit.INK))
		var desc := UiKit.ink(tr("FISH_%s_DESC" % id), 26, UiKit.INK_SOFT)
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc.custom_minimum_size = Vector2(420, 0)
		_detail.add_child(desc)
	else:
		_detail.add_child(UiKit.ink(tr("UI_BOOK_NOT_CAUGHT"), 28, UiKit.INK))
		for hint in hints(db, save, spot_id, id, zone_id):
			var line := UiKit.ink(hint, 26, UiKit.INK_SOFT)
			line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			line.custom_minimum_size = Vector2(420, 0)
			_detail.add_child(line)
	var species_odds := odds(db, save, spot_id, zone_id)
	_detail.add_child(UiKit.ink(tr("UI_BOOK_CHANCE") % UiKit.format_percent(int(species_odds.get(id, 0))), 28, UiKit.INK))
	_detail.add_child(UiKit.spacer(true))
	_add_lake_odds(db, save, species_odds)


## Tutulmamış bir balığın ipuçları: sevdiği yem (tekniklerinin yemi, yapay yemi ya da sineği; en
## çok çeken), yalnızca belli vakitte geliyorsa ne zaman (Ay Turnası gece, Kocabaş fırtınalı gece),
## yoksa en çok sevdiği vakit ve hava (çarpanı en az LIKES_AT), tuzağa giriyorsa nerede, şamandırayla
## gelmiyorsa hangi teknikle tutulduğu, bölgeli gölde yaşadığı yerler ve ne sıklıkla görüldüğü
## (oyundaki tekniklerin her biriyle, en sık görüldüğü bölgede; vakitten bağımsız, belli vakitte gelen
## tür kendi vaktinde). Tuzak türünde sıklık yazılmaz (tuzağa hep o girer); yaşadığı yerler tuzağınkilerle
## aynıysa yinelenmez.
static func hints(db: ContentDB, save: SaveData, spot: String, fish_id: String, zone: String = "") -> PackedStringArray:
	var out := PackedStringArray()
	var techniques := PackedStringArray()
	for t: String in ContentDB.TECHNIQUES:
		if db.has_technique(t) and db.affinity(fish_id, t) > 0.0:
			techniques.append(t)
	var favourite := _favourite(db, spot, fish_id, techniques)
	if not favourite.is_empty():
		out.append(UiKit.translate(FAVOURITE_KEYS[str(db.gear_item(favourite)["category"])]) \
				% UiKit.translate("GEAR_" + favourite))
	# Vakit ve hava tek satırda ("En çok sabah gelir. Yağmuru sever."): defter ekrana sığsın.
	var time := PackedStringArray()
	for key in _time_hints(db, fish_id):
		time.append(UiKit.translate(key))
	if not time.is_empty():
		out.append(" ".join(time))
	var trap_zones := PackedStringArray()
	for z in db.zones_of(spot):
		if fish_id in (z["trap_ids"] as PackedStringArray):
			trap_zones.append(UiKit.translate("ZONE_" + str(z["id"])))
	if not trap_zones.is_empty():
		out.append(UiKit.translate("UI_BOOK_HINT_TRAP") % ", ".join(trap_zones))
	if not "float" in techniques and not techniques.is_empty():
		var names := PackedStringArray()
		for t in techniques:
			names.append(UiKit.translate("UI_TECH_" + t))
		var key := "UI_BOOK_HINT_TECH_ALSO" if not trap_zones.is_empty() else "UI_BOOK_HINT_TECH"
		out.append(UiKit.translate(key) % ", ".join(names))
	var ppm := _best_ppm(db, Zones.place(db, spot, zone), fish_id, techniques)
	var zones := db.zones_of(spot)
	if zones.size() > 1:
		var names := PackedStringArray()
		for z in zones:
			var here := _best_ppm(db, z, fish_id, techniques)
			if here > 0:
				names.append(UiKit.translate("ZONE_" + str(z["id"])))
			ppm = maxi(ppm, here)
		if not names.is_empty() and names != trap_zones:
			out.append(UiKit.translate("UI_BOOK_HINT_ZONE") % ", ".join(names))
	if not trap_zones.is_empty():
		return out
	if ppm >= OFTEN_PPM:
		out.append(UiKit.translate("UI_BOOK_HINT_OFTEN"))
	elif ppm >= SOMETIMES_PPM:
		out.append(UiKit.translate("UI_BOOK_HINT_SOMETIMES"))
	else:
		out.append(UiKit.translate("UI_BOOK_HINT_RARELY"))
	return out


## Türün en sevdiği yem, yapay yem ya da sinek: türün tekniklerinin kullandığı yuvalardan, türü en sık
## getiren (gölün bölgelerinde, o teknikle, CatchOdds ile: başka türleri de çeken yem türün payını
## düşürebilir). Yemsiz en iyi orandan yüksek değilse "" (eşitlikte teknik ve gear.json sırasıyla ilki).
static func _favourite(db: ContentDB, spot: String, fish_id: String, techniques: PackedStringArray) -> String:
	var places := db.zones_of(spot)
	if places.size() <= 1:
		places = [db.spot(spot)]
	var best_id := ""
	var best := 0
	for t in techniques:
		for place in places:
			best = maxi(best, _ppm_in(db, place, fish_id, t))
	for t in techniques:
		for slot in db.slots_for(t):
			if not FAVOURITE_KEYS.has(slot):
				continue
			for g in db.gear_in(slot):
				for place in places:
					var ctx := CatchOdds.own_conditions(db, fish_id)
					ctx["attract"] = g["attract"]
					ctx["technique"] = t
					var ppm := int(CatchOdds.species_ppm(db, place, ctx).get(fish_id, 0))
					if ppm > best:
						best = ppm
						best_id = str(g["id"])
	return best_id


## Türün bu yerdeki en yüksek oranı (ppm; tekniklerden hangisiyle en sık geliyorsa, yemsiz).
static func _best_ppm(db: ContentDB, place: Dictionary, fish_id: String, techniques: PackedStringArray) -> int:
	var top := 0
	for t in techniques:
		top = maxi(top, _ppm_in(db, place, fish_id, t))
	return top


## Türün bu yerde bu teknikle (yemsiz) oranı: koşulsuz; belli vakitte gelen tür kendi vaktinde.
static func _ppm_in(db: ContentDB, place: Dictionary, fish_id: String, technique: String) -> int:
	var ctx := CatchOdds.own_conditions(db, fish_id)
	ctx["technique"] = technique
	return int(CatchOdds.species_ppm(db, place, ctx).get(fish_id, 0))



## Vaktin ve havanın ipuçları (çeviri anahtarları): yalnızca belli vakitte gelen türde ne zaman
## (UI_BOOK_HINT_ONLY_storm: yağmurlu gece, UI_BOOK_HINT_ONLY_<vakit>); yoksa en sevdiği vakit
## (UI_BOOK_HINT_WHEN_<vakit>) ve hava (UI_BOOK_HINT_LIKES_<hava>), çarpanı en az LIKES_AT ise.
static func _time_hints(db: ContentDB, fish_id: String) -> PackedStringArray:
	var out := PackedStringArray()
	var def := db.fish_by_id(fish_id)
	var only: Dictionary = def.get("only", {})
	if not only.is_empty():
		var phases: PackedStringArray = only.get("phase", PackedStringArray())
		var kinds: PackedStringArray = only.get("weather", PackedStringArray())
		if "rain" in kinds and "night" in phases:
			out.append("UI_BOOK_HINT_ONLY_storm")
		elif not phases.is_empty():
			out.append("UI_BOOK_HINT_ONLY_" + phases[0])
		return out
	var best_phase := ""
	var best := LIKES_AT
	for phase in DayClock.PHASES:
		if db.when_mult(fish_id, phase) >= best:
			best = db.when_mult(fish_id, phase)
			best_phase = phase
	if not best_phase.is_empty():
		out.append("UI_BOOK_HINT_WHEN_" + best_phase)
	var best_kind := ""
	best = LIKES_AT
	for kind in Weather.KINDS:
		if db.weather_mult(fish_id, kind) >= best:
			best = db.weather_mult(fish_id, kind)
			best_kind = kind
	if not best_kind.is_empty():
		out.append("UI_BOOK_HINT_LIKES_" + best_kind)
	return out


## Gölün nadirlik oranları (elindeki teknik ve kuşanılan yemle; başlıkta tekniğin adı) ve şans
## garantisi sayaçları (o teknikle bu bölgede gelebilen kademeler).
func _add_lake_odds(db: ContentDB, save: SaveData, species_odds: Dictionary) -> void:
	var zoned := not zone_id.is_empty() and db.zones_of(spot_id).size() > 1
	var technique := tr("UI_TECH_" + save.technique)
	var title := tr("UI_BOOK_ZONE_ODDS") % [tr("ZONE_" + zone_id), technique] if zoned \
			else tr("UI_BOOK_ODDS") % technique
	var heading := UiKit.ink(title, 26, UiKit.INK_SOFT)
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	heading.custom_minimum_size = Vector2(420, 0)
	_detail.add_child(heading)
	# Oranlar gölün şimdiki koşuluyla (vakit, hava, göl sevgisi; başlıkta yazar): ekranda yazan gerçek oran.
	var by_rarity := CatchOdds.rarity_ppm(db, species_odds)
	var grid := GridContainer.new()
	grid.columns = 4
	grid.add_theme_constant_override("h_separation", 10)
	grid.add_theme_constant_override("v_separation", 6)
	_detail.add_child(grid)
	for r in by_rarity.size():
		if by_rarity[r] <= 0:
			continue
		grid.add_child(UiKit.rarity_badge(db, r, 22))
		grid.add_child(UiKit.ink(UiKit.format_percent(by_rarity[r]), 26))
	_detail.add_child(UiKit.ink(tr("UI_BOOK_PITY_TITLE"), 26, UiKit.INK_SOFT))
	for r in db.rarities.size():
		var left := CatchOdds.pity_left(db, save, r)
		# Bu gölde o nadirlikte (ya da üstünde) tür yoksa garanti yazılmaz: boş söz verilmez.
		var reachable := 0
		for k in range(r, by_rarity.size()):
			reachable += by_rarity[k]
		if left < 0 or reachable <= 0:
			continue
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 10)
		_detail.add_child(row)
		row.add_child(UiKit.rarity_badge(db, r, 22))
		row.add_child(UiKit.ink(tr("UI_BOOK_PITY_NOW") if left == 0 else tr("UI_BOOK_PITY") % left, 26, UiKit.INK))


# --- Gölün Sırrı ------------------------------------------------------------------

## Sırrın görünüşü: solda mektup kartları (balık ızgarasının boyunda) ve alttaki satır, sağda haritanın kartı.
func _build_secret_view() -> void:
	_secret_view = HBoxContainer.new()
	_secret_view.name = "Secret"
	_secret_view.add_theme_constant_override("separation", 22)
	_secret_view.visible = false
	body.add_child(_secret_view)
	var left := VBoxContainer.new()
	left.add_theme_constant_override("separation", 12)
	_secret_view.add_child(left)
	_letters = GridContainer.new()
	_letters.name = "Letters"
	_letters.columns = LETTER_COLUMNS
	_letters.add_theme_constant_override("h_separation", 12)
	_letters.add_theme_constant_override("v_separation", 12)
	_letters.custom_minimum_size = _grid.custom_minimum_size
	left.add_child(_letters)
	_secret_foot = HBoxContainer.new()
	_secret_foot.add_theme_constant_override("separation", 14)
	_secret_foot.custom_minimum_size.y = VIEW_BUTTON.y
	left.add_child(_secret_foot)
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", UiKit.framed("card", UiKit.card_style(), UiKit.CARD_CORNER))
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_secret_view.add_child(card)
	_secret_info = VBoxContainer.new()
	_secret_info.add_theme_constant_override("separation", 10)
	card.add_child(_secret_info)
	_map = SecretMap.new()
	_map.name = "Map"
	_map.custom_minimum_size = SECRET_MAP
	_map.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	_map.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_secret_info.add_child(_map)
	_secret_lines = VBoxContainer.new()
	_secret_lines.add_theme_constant_override("separation", 10)
	_secret_info.add_child(_secret_lines)


## Sırrın görünüşünü kayda göre kurar: başlıkta mektup sayısı, kartlar, harita, parçalar, altın istek ya da X,
## altın hamur.
func _build_secret(db: ContentDB, save: SaveData) -> void:
	var pill := PanelContainer.new()
	pill.add_theme_stylebox_override("panel", UiKit.pill_style(Color(0.18, 0.1, 0.04, 0.85)))
	pill.add_child(UiKit.title(tr("UI_SECRET_LETTERS") % [save.letters, Secret.LETTERS.size()], 40, UiKit.ACCENT,
			HORIZONTAL_ALIGNMENT_CENTER, 10))
	header_extra.add_child(pill)
	clear(_letters)
	for i in Secret.LETTERS.size():
		_letters.add_child(_letter_card(db, save, i + 1))
	clear(_secret_foot)
	_secret_foot.add_child(UiKit.spacer())
	_set_view_button(_secret_foot, "fish")
	# Harita kartı: harita, parçalar, sıradaki parça ya da X, altın hamur.
	clear(_secret_lines)
	var deep := _boat_zone(db)
	var buoys: Array[Vector2] = deep.get("buoys", [] as Array[Vector2])
	var lake := db.lake(spot_id)
	_map.setup(lake, lake.zone_index(str(deep.get("id", ""))), buoys[0] if not buoys.is_empty() else Dice.NO_POINT)
	_map.pieces = save.map_pieces
	var pieces := DayPanel._display(tr("UI_SECRET_PIECES") % [save.map_pieces, SaveData.MAX_MAP_PIECES], 34, UiKit.INK)
	pieces.name = "Pieces"
	_secret_lines.add_child(pieces)
	var note := ""
	var golden := Requests.golden(db, save)
	if save.map_pieces >= SaveData.MAX_MAP_PIECES:
		note = tr("UI_SECRET_X")
	elif not golden.is_empty():
		note = tr("UI_SECRET_GOLDEN") % DayPanel.text_of(db, golden)
	else:
		note = tr("UI_SECRET_PIECES_HINT")
	_secret_lines.add_child(_wrapped(note, 26, UiKit.INK_SOFT))
	var dough := HBoxContainer.new()
	dough.add_theme_constant_override("separation", 10)
	_secret_lines.add_child(dough)
	var has := Secret.has_dough(save)
	var icon := GameIcon.make("item:golden_dough", 52)
	icon.modulate = Color.WHITE if has else Color(1, 1, 1, 0.45)
	dough.add_child(icon)
	var text := tr("UI_SECRET_DOUGH_HAVE") if has else tr("UI_SECRET_DOUGH_WAIT") % Secret.DOUGH_LOVE
	var label := _wrapped(text, 26, UiKit.INK if has else UiKit.INK_SOFT)
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	dough.add_child(label)


## Bir mektubun kartı: okunduysa bölgesi, adı ve numarası (dokununca yeniden okunur); sıradakiyse bölgesi ve ne
## zaman (şişe suda, kaç balık sonra, hangi rütbede, sandalla); ötekiler soru işareti.
func _letter_card(db: ContentDB, save: SaveData, n: int) -> Button:
	var letter := Secret.LETTERS[n - 1]
	var zone := str(letter["zone"])
	var read := n <= save.letters
	var next := n == save.letters + 1
	var b := Button.new()
	b.name = "Letter%d" % n
	b.custom_minimum_size = LETTER_CARD
	b.focus_mode = Control.FOCUS_NONE
	var sb := UiKit.card_style(LETTER_EDGE if read else UNKNOWN_BORDER, 24, LETTER_FILL if read else Color("#efe2c6"),
			5 if read else 3)
	for state: String in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		b.add_theme_stylebox_override(state, sb)
	b.disabled = not read
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	column.offset_left = 12
	column.offset_right = -12
	column.offset_top = 10
	column.offset_bottom = -10
	b.add_child(column)
	var top := HBoxContainer.new()
	top.alignment = BoxContainer.ALIGNMENT_CENTER
	top.add_theme_constant_override("separation", 10)
	top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(top)
	var badge := GameIcon.make("zone:" + zone, 76)
	if not read:
		badge.modulate = Color(1, 1, 1, 0.6 if next else 0.3)
	top.add_child(badge)
	if read:
		top.add_child(GameIcon.make("item:letter", 60))
		var title := DayPanel._display(tr(Secret.letter_title_key(n)), 28, UiKit.INK)
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		title.max_lines_visible = 2
		column.add_child(title)
		var number := UiKit.ink(tr("UI_SECRET_LETTER_N") % n, 24, UiKit.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER)
		column.add_child(number)
		b.pressed.connect(func() -> void:
			Sounds.play("ui_tap")
			letter_requested.emit(n))
		return b
	top.add_child(DayPanel._display("?", 64, Color(UiKit.INK_SOFT, 0.7 if next else 0.4)))
	if next:
		var when := _wrapped(_next_text(db, save, n), 24, UiKit.INK_SOFT, LETTER_CARD.x - 24.0)
		when.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		when.max_lines_visible = 2
		column.add_child(when)
	return b


## Sıradaki mektubun ne zaman geleceği: şişe suda, kaç balık sonra, hangi rütbede ya da sandalla (bölgesinin adıyla).
func _next_text(db: ContentDB, save: SaveData, n: int) -> String:
	var letter := Secret.LETTERS[n - 1]
	var zone_name := tr("ZONE_" + str(letter["zone"]))
	if Secret.bottle_due(db, save, spot_id):
		return tr("UI_SECRET_BOTTLE_NOW") % zone_name
	if Rank.rank(db, save) < int(letter["rank"]):
		return tr("UI_SECRET_NEXT_RANK") % [zone_name, int(letter["rank"])]
	var zone := db.zone(spot_id, str(letter["zone"]))
	if not zone.is_empty() and not Zones.unlocked(db, save, zone):
		return tr("UI_SECRET_NEXT_BOAT") % zone_name
	return tr("UI_SECRET_NEXT_FISH") % [zone_name, maxi(1, Secret.LETTER_GAP - (save.catches - save.letter_at))]


## Görünüş düğmesi alttaki satırın sağında: "Gölün Sırrı" (ilk mektuptan sonra) ya da "Balıklar".
func _set_view_button(foot: HBoxContainer, to: String) -> void:
	var old := foot.get_node_or_null("ViewButton")
	if old != null:
		foot.remove_child(old)
		old.queue_free()
	if GameState.save.letters <= 0:
		return
	var b := UiKit.button(UiKit.upper(tr("UI_BOOK_TAB_SECRET" if to == "secret" else "UI_BOOK_TAB_FISH")),
			UiKit.MYSTERY_BUTTON if to == "secret" else UiKit.SECONDARY, UiKit.SIZE_SMALL, VIEW_BUTTON)
	b.name = "ViewButton"
	b.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	b.pressed.connect(func() -> void:
		Sounds.play("ui_tap")
		_view = to
		refresh())
	foot.add_child(b)


## Gölün sandal bölgesi (derin orta; X'in şamandırası).
func _boat_zone(db: ContentDB) -> Dictionary:
	for z in db.zones_of(spot_id):
		if bool(z["boat"]):
			return z
	return {}


## Satıra bölünen yazı (genişliği verilmezse haritanın kartının sütunu).
static func _wrapped(text: String, size: int, color: Color, width: float = SECRET_MAP.x - 20.0) -> Label:
	var label := UiKit.ink(text, size, color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(width, 0)
	return label
