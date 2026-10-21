class_name GuidePages
extends RefCounted
## "Nasıl oynanır?" rehberinin içeriği (GuidePanel çizer, test_guide denetler). Rehber 10 sayfa;
## her sayfada bir giriş cümlesi ve karolar var. Bir karo şunlardan oluşur:
## - görsel ve başlık;
## - metin: biçimli; sayıları veriden gelir;
## - altta küçük ikonlar ya da yıldızlar, sağda kilit hapı ya da yer hapı.
##
## Sayılar veriden gelir (rütbeler, tuzağın süresi, kovalar, şans garantisi, yıldızlar, tür sayısı);
## oyun değişince rehber eskimez. Henüz açılmamış teknik, bölge ve takım da gösterilir; kilidinde
## açıldığı rütbe, derin ortada sandal yazar. Anahtarlar büyük harfle ve düz yazılır, çünkü
## test_content_db koddaki "UI_..." dizgilerini tarar; birleştirilen anahtarları test_guide denetler.

## Karo düzenleri: [sütun, satır, görsel üstte mi]. Dikey karoda görsel üstte, yatayda solda.
const LAYOUTS := {
	"row5": [5, 1, true], "row4": [4, 1, true], "row3": [3, 1, true],
	"grid6": [3, 2, false], "grid4": [2, 2, false],
}
## Ölçüler (tasarım birimi). Panel bunlarla kurulur, test_guide bunlarla ölçer.
## - AREA: sayfanın karo alanı; GAP: karolar arası.
## - PAD: karonun iç payı (UiKit.card_style).
## - VISUAL: görselin boyu; TITLE_H: başlık satırı; FOOT_H: alttaki satır; SEP: aralar.
const AREA := Vector2(1600, 495)
const GAP := 16.0
const PAD := 18.0
const VISUAL := 110.0
const TITLE_H := 40.0
const FOOT_H := 52.0
const SEP := 8.0
## Yazı boyları: karonun başlığı (Luckiest Guy; sığmazsa en çok TITLE_MIN'e küçülür), metni (Baloo 2),
## giriş cümlesi (tek satır, LEAD_W genişliğinde) ve haplar.
const TITLE_SIZE := 32
const TITLE_MIN := 22
const TEXT_SIZE := 30
const LEAD_SIZE := 32
const LEAD_W := 1600.0
const PILL_SIZE := 26
## Metnin satır aralığı (temanın Label'ınki; panel karonun metnine de bunu verir).
const LINE_SPACING := -6
## Alttaki satır: küçük ikonların boyu ve arası, yıldızların boyu, hapın ikonu ve yatay payları.
const FOOT_ICON := 50.0
const FOOT_SEP := 6.0
const STAR := 30.0
const PILL_ICON := 36.0
const PILL_MARGIN := Vector2(12, 16)

## Sayfalar, okuma sırasıyla. Bir karonun alanları:
## - kimlik ve görsel: action (eylem düğmesi; let_go gerilim çubuğu), icon (GameIcon), category
##   (takımın resmi), portrait (konuşanın yüzü);
## - başlık ve metin anahtarı;
## - kilit: lock "bag" (Takım Çantası, ilk teknikle açılır), "requests" (Dede'nin istekleri) ya da "secret"
##   (Gölün Sırrı: ilk şişenin rütbesi);
##   takım kategorisinin kilidi kategorisinden gelir;
## - stars: kategorinin başlangıç taşıması yıldızla gösterilir.
## "from" alanı karoları veriden kurar: rarities, techniques ya da zones. "steps": karolar sıralı
## adımlar (alttaki satırda numarası).
const PAGES: Array[Dictionary] = [
	{ "id": "basics", "icon": "hand", "title": "UI_GUIDE_BASICS", "lead": "UI_GUIDE_BASICS_LEAD", "layout": "row5",
		"steps": true, "tiles": [
			{ "id": "cast", "action": "cast", "text": "UI_GUIDE_DO_CAST" },
			{ "id": "wait", "action": "wait", "text": "UI_GUIDE_DO_WAIT" },
			{ "id": "hook", "action": "hook", "text": "UI_GUIDE_DO_STRIKE" },
			{ "id": "reel", "action": "reel", "text": "UI_GUIDE_DO_REEL" },
			{ "id": "let_go", "action": "let_go", "text": "UI_GUIDE_DO_LET_GO" },
		] },
	{ "id": "loop", "icon": "bucket", "title": "UI_GUIDE_LOOP", "lead": "UI_GUIDE_LOOP_LEAD", "layout": "row5",
		"steps": true, "tiles": [
			{ "id": "bucket", "icon": "bucket", "title": "UI_SHOP_TAB_SELL", "text": "UI_GUIDE_LOOP_BUCKET" },
			{ "id": "shop", "icon": "shop", "title": "UI_SHOP_TITLE", "text": "UI_GUIDE_LOOP_SHOP" },
			{ "id": "rank", "icon": "star", "title": "UI_GUIDE_RANK", "text": "UI_GUIDE_LOOP_RANK" },
			{ "id": "map", "icon": "map", "title": "UI_MAP", "text": "UI_GUIDE_LOOP_MAP" },
			{ "id": "bag", "icon": "tackle_bag", "title": "UI_BAG_TITLE", "text": "UI_GUIDE_LOOP_BAG", "lock": "bag" },
		] },
	{ "id": "rarity", "icon": "rarity:diamond", "title": "UI_GUIDE_RARITY", "lead": "UI_GUIDE_RARITY_LEAD",
		"layout": "row5", "from": "rarities" },
	{ "id": "techniques", "icon": "tech_spin", "title": "UI_GUIDE_TECHNIQUES", "lead": "UI_GUIDE_TECHNIQUES_LEAD",
		"layout": "row5", "from": "techniques" },
	{ "id": "rods", "icon": "rod", "title": "UI_GUIDE_RODS", "lead": "UI_GUIDE_RODS_LEAD", "layout": "row3",
		"tiles": [
			{ "id": "rod", "category": "rod", "title": "UI_SHOP_TAB_ROD", "text": "UI_GUIDE_GEAR_ROD", "stars": true },
			{ "id": "reel", "category": "reel", "title": "UI_SHOP_TAB_REEL", "text": "UI_GUIDE_GEAR_REEL" },
			{ "id": "line", "category": "line", "art": "line_fluoro", "title": "UI_SHOP_TAB_LINE", "text": "UI_GUIDE_GEAR_LINE",
				"stars": true },
		] },
	{ "id": "tackle", "icon": "hook", "title": "UI_GUIDE_TACKLE", "lead": "UI_GUIDE_TACKLE_LEAD", "layout": "grid6",
		"tiles": [
			{ "id": "hook", "category": "hook", "art": "hook_medium", "title": "UI_GUIDE_T_HOOK", "text": "UI_GUIDE_GEAR_HOOK" },
			{ "id": "bobber", "category": "bobber", "art": "bobber_sensitive", "title": "UI_GUIDE_T_BOBBER",
				"text": "UI_GUIDE_GEAR_BOBBER" },
			{ "id": "bait", "category": "bait", "art": "bait_corn", "title": "UI_SHOP_TAB_BAIT", "text": "UI_GUIDE_GEAR_BAIT" },
			{ "id": "lure", "category": "lure", "art": "lure_spinner", "title": "UI_SHOP_TAB_LURE", "text": "UI_GUIDE_GEAR_LURE" },
			{ "id": "rig", "category": "rig", "art": "feeder", "title": "UI_GUIDE_T_RIG", "text": "UI_GUIDE_GEAR_RIG" },
			{ "id": "fly", "category": "fly", "art": "fly_nymph", "title": "UI_SHOP_TAB_FLY", "text": "UI_GUIDE_GEAR_FLY" },
		] },
	{ "id": "extras", "icon": "net", "title": "UI_GUIDE_EXTRAS", "lead": "UI_GUIDE_EXTRAS_LEAD", "layout": "grid4",
		"tiles": [
			{ "id": "net", "category": "extra", "title": "GEAR_net", "text": "UI_GUIDE_GEAR_NET" },
			{ "id": "bucket", "category": "bucket", "art": "keepnet", "title": "UI_GUIDE_T_BUCKET", "text": "UI_GUIDE_GEAR_BUCKET" },
			{ "id": "boat", "category": "boat", "title": "GEAR_boat", "text": "UI_GUIDE_GEAR_BOAT" },
			{ "id": "trap", "category": "trap", "title": "UI_BAG_TRAP", "text": "UI_GUIDE_GEAR_TRAP" },
		] },
	{ "id": "zones", "icon": "map", "title": "UI_GUIDE_ZONES", "lead": "UI_GUIDE_ZONES_LEAD", "layout": "grid6",
		"from": "zones" },
	{ "id": "living", "icon": "phase_noon", "title": "UI_GUIDE_LIVING", "lead": "UI_GUIDE_LIVING_LEAD", "layout": "row5",
		"tiles": [
			{ "id": "time", "icon": "phase_night", "title": "UI_GUIDE_TIME", "text": "UI_GUIDE_TIME_TEXT" },
			{ "id": "weather", "icon": "weather_rain", "title": "UI_GUIDE_WEATHER", "text": "UI_GUIDE_WEATHER_TEXT" },
			{ "id": "tea", "icon": "tea", "title": "UI_TEA_TITLE", "text": "UI_GUIDE_TEA_TEXT" },
			{ "id": "love", "icon": "love", "title": "UI_GUIDE_LOVE", "text": "UI_GUIDE_LOVE_TEXT" },
			{ "id": "requests", "icon": "requests", "title": "UI_REQ_TITLE", "text": "UI_GUIDE_REQUESTS_TEXT",
				"lock": "requests" },
		] },
	{ "id": "people", "icon": "book", "title": "UI_GUIDE_PEOPLE", "lead": "UI_GUIDE_PEOPLE_LEAD", "layout": "row5",
		"tiles": [
			{ "id": "dede", "portrait": "dede_smile", "title": "UI_GUIDE_DEDE", "text": "UI_GUIDE_DEDE_TEXT" },
			{ "id": "nine", "portrait": "nine_smile", "title": "UI_GUIDE_NINE", "text": "UI_GUIDE_NINE_TEXT" },
			{ "id": "book", "icon": "book", "title": "UI_BOOK", "text": "UI_GUIDE_BOOK_TEXT" },
			{ "id": "goal", "icon": "trophy", "title": "UI_GUIDE_GOAL", "text": "UI_GUIDE_GOAL_TEXT" },
			{ "id": "secret", "icon": "bottle", "title": "UI_SECRET_TITLE", "text": "UI_GUIDE_SECRET_TEXT",
				"lock": "secret" },
		] },
]

## Tekniklerin karo metni (nasıl oynanır, kısaca).
const TECH_KEYS := {
	"float": "UI_GUIDE_TECH_FLOAT", "spin": "UI_GUIDE_TECH_SPIN", "bottom": "UI_GUIDE_TECH_BOTTOM",
	"fly": "UI_GUIDE_TECH_FLY",
}
## Her bölgede avlanılmayan tekniğin yeri (kilidi açılınca karoda yazar; sinek yalnızca dere ağzında).
const WHERE_KEYS := { "fly": "UI_TECH_fly_WHERE" }
## Gölgenin nadirlik ipucu (rarities.json shadow_fx).
const SHADOW_KEYS := {
	"none": "UI_GUIDE_FX_NONE", "glint": "UI_GUIDE_FX_GLINT", "shimmer": "UI_GUIDE_FX_SHIMMER",
	"trail": "UI_GUIDE_FX_TRAIL", "guardian": "UI_GUIDE_FX_GUARDIAN",
}
## Bölgelerin kısa tarifi.
const ZONE_KEYS := {
	"dock_cove": "UI_GUIDE_ZONE_DOCK_COVE", "reeds": "UI_GUIDE_ZONE_REEDS", "lily_cove": "UI_GUIDE_ZONE_LILY_COVE",
	"rocky_point": "UI_GUIDE_ZONE_ROCKY_POINT", "stream_mouth": "UI_GUIDE_ZONE_STREAM_MOUTH",
	"deep_water": "UI_GUIDE_ZONE_DEEP_WATER",
}
## Bölge karosunda Dede'nin önerisinin önündeki yüz (karonun ikonlarından biri: "portrait:" + yüz).
const DEDE_FACE := "portrait:dede_smile"
## Dükkânın sekmesi → rehberin sayfası (dükkândaki "?").
const SHOP_TAB_PAGES := {
	"sell": "loop", "rod": "rods", "reel": "rods", "line": "rods", "tackle": "tackle", "bait": "tackle",
	"extra": "extras",
}


## Düzenin karo boyu.
static func tile_size(layout: String) -> Vector2:
	var def: Array = LAYOUTS[layout]
	var columns := int(def[0])
	var rows := int(def[1])
	return Vector2(floorf((AREA.x - GAP * (columns - 1)) / columns), floorf((AREA.y - GAP * (rows - 1)) / rows))


## Karo dikey mi (görsel üstte)?
static func vertical(layout: String) -> bool:
	return bool((LAYOUTS[layout] as Array)[2])


## Başlığın, metnin ve alttaki satırın genişliği: dikey karoda içi, yatayda görselin yanı.
static func column_width(layout: String) -> float:
	var inner := tile_size(layout).x - 2.0 * PAD
	return inner if vertical(layout) else inner - VISUAL - GAP


## Karonun metin kutusu: görselin, başlığın (titled) ve alttaki satırın dışında kalan yer.
static func text_box(layout: String, titled: bool = true) -> Vector2:
	var inner := tile_size(layout).y - 2.0 * PAD
	var title := TITLE_H + SEP if titled else 0.0
	if vertical(layout):
		return Vector2(column_width(layout), inner - VISUAL - title - FOOT_H - 2.0 * SEP)
	return Vector2(column_width(layout), inner - title - FOOT_H - SEP)


## Metnin karodaki boyu: kelimeden kırılan satırlar (Label'ın AUTOWRAP_WORD_SMART'ı gibi), satır
## aralığı LINE_SPACING (Label: satır sayısı × font yüksekliği + aralar).
static func text_size(font: Font, text: String, width: float) -> Vector2:
	var flags := TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND | TextServer.BREAK_ADAPTIVE
	var size := font.get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, width, TEXT_SIZE, -1, flags)
	var lines := roundi(size.y / font.get_height(TEXT_SIZE))
	return Vector2(size.x, size.y + maxi(0, lines - 1) * LINE_SPACING)


## Karonun metni: satırlar alt alta, sayıları yerinde. translate anahtarı yazıya çevirir (panelde
## tr; testte CSV'nin bir sütunu).
static func text_of(tile: Dictionary, translate: Callable) -> String:
	var lines := PackedStringArray()
	for line: Array in tile["text"]:
		var text := str(translate.call(str(line[0])))
		var args: Array = line[1]
		lines.append(text % args if not args.is_empty() else text)
	return "\n".join(lines)


## Sayfanın sırası (bilinmeyen sayfada -1).
static func page_index(id: String) -> int:
	for i in PAGES.size():
		if str(PAGES[i]["id"]) == id:
			return i
	return -1


## Sayfanın tanımı (bilinmeyen sayfada ilk sayfa).
static func page(id: String) -> Dictionary:
	return PAGES[maxi(0, page_index(id))]


## Dükkânın sekmesinin sayfası (bilinmeyen sekmede ilk sayfa).
static func page_for_shop_tab(tab: String) -> String:
	return str(SHOP_TAB_PAGES.get(tab, PAGES[0]["id"]))


## Sayfanın karoları, çizilmeye hazır. Her karo bir sözlük:
## - id;
## - visual (action, let_go, icon, gear, portrait) ve art (ikonun, resmin ya da yüzün adı);
## - title: başlığın anahtarı, eylem karosunda boş;
## - text: satırlar, her biri [anahtar, sayılar];
## - icons: alttaki küçük ikonlar;
## - stars: [dolu, toplam] ya da boş;
## - where: yer hapının anahtarı ya da boş;
## - step: sıralı sayfada adımın numarası (yoksa 0);
## - rank (kilit; 1 ve altı kilitsiz) ve boat (sandal ister);
## - kapsam için: category, technique, zone, rarity.
static func tiles_of(db: ContentDB, page_id: String) -> Array[Dictionary]:
	var def := page(page_id)
	match str(def.get("from", "")):
		"rarities":
			return _rarity_tiles(db)
		"techniques":
			return _technique_tiles(db)
		"zones":
			return _zone_tiles(db)
	var out: Array[Dictionary] = []
	for raw: Dictionary in def["tiles"]:
		var tile := _tile(db, raw)
		if bool(def.get("steps", false)):
			tile["step"] = out.size() + 1
		out.append(tile)
	return out


## Karonun kilidi: "rank" (rütbe yetmiyor), "boat" (sandal yok) ya da "" (açık).
static func lock_state(db: ContentDB, save: SaveData, tile: Dictionary) -> String:
	if Rank.rank(db, save) < int(tile.get("rank", 0)):
		return "rank"
	if bool(tile.get("boat", false)) and not Economy.owns(db, save, Zones.BOAT):
		return "boat"
	return ""


## Takım kategorisinin açıldığı rütbe. Yalnızca bir tekniğin kullandığı yuvada (yapay yem, kurşun,
## sinek) o tekniğin rütbesi; ötekilerde kategorinin en erken açılan eşyasınınki (kepçe 3, sandal 9).
static func category_rank(db: ContentDB, category: String) -> int:
	var technique := db.slot_technique(category) if category in ContentDB.GEAR_SLOTS else ""
	if not technique.is_empty():
		return db.technique_rank(technique)
	var low := 0
	for g in db.gear_in(category):
		low = int(g["rank"]) if low == 0 else mini(low, int(g["rank"]))
	return low


## Takım Çantası'nın açıldığı rütbe: şamandıradan sonraki ilk tekniğinki (çantanın düğmesi o zaman
## görünür: main._other_technique_open; tuzak düğmeyi açmaz).
static func bag_rank(db: ContentDB) -> int:
	var low := 0
	for t: String in ContentDB.TECHNIQUES:
		if t != "float" and db.has_technique(t):
			low = db.technique_rank(t) if low == 0 else mini(low, db.technique_rank(t))
	return low


## Eylem karosunun düğmesindeki yazının anahtarı: oyundaki eylem düğmesininki (Hud.ACTIONS);
## gerilim çubuğunda "BIRAK!". Eylem karosu değilse "".
static func action_label(tile: Dictionary) -> String:
	match str(tile["visual"]):
		"action":
			return str((Hud.ACTIONS[str(tile["art"])] as Array)[0])
		"let_go":
			return "UI_LET_GO"
	return ""


## Sayfadaki her anahtar: başlık, giriş ve karoların başlıkları ve satırları (test_guide çeviriyi
## denetler).
static func keys_of(db: ContentDB, page_id: String) -> PackedStringArray:
	var def := page(page_id)
	var out := PackedStringArray([str(def["title"]), str(def["lead"])])
	for tile in tiles_of(db, page_id):
		if not str(tile["title"]).is_empty():
			out.append(str(tile["title"]))
		var label := action_label(tile)
		if not label.is_empty():
			out.append(label)
		for line: Array in tile["text"]:
			out.append(str(line[0]))
		if not str(tile["where"]).is_empty():
			out.append(str(tile["where"]))
	return out


# --- Karolar ----------------------------------------------------------------------

static func _blank(id: String) -> Dictionary:
	return { "id": id, "visual": "icon", "art": "question", "title": "", "text": [], "icons": PackedStringArray(),
		"stars": [], "where": "", "step": 0, "rank": 0, "boat": false, "category": "", "technique": "", "zone": "", "rarity": -1 }


## Sayfa listesindeki karo: görseli, kilidi ve metnin sayıları.
static func _tile(db: ContentDB, raw: Dictionary) -> Dictionary:
	var tile := _blank(str(raw["id"]))
	tile["title"] = str(raw.get("title", ""))
	tile["text"] = [[str(raw["text"]), _text_args(db, str(raw["text"]))]]
	if raw.has("action"):
		var action := str(raw["action"])
		tile["visual"] = "let_go" if action == "let_go" else "action"
		tile["art"] = action
	elif raw.has("portrait"):
		tile["visual"] = "portrait"
		tile["art"] = str(raw["portrait"])
	elif raw.has("category"):
		var category := str(raw["category"])
		tile["visual"] = "gear"
		tile["art"] = str(raw.get("art", _category_art(db, category)))
		tile["category"] = category
		tile["rank"] = category_rank(db, category)
		tile["icons"] = _category_techniques(db, category)
		if bool(raw.get("stars", false)):
			tile["stars"] = _carry_stars(db, category)
	else:
		tile["art"] = str(raw.get("icon", "question"))
	match str(raw.get("lock", "")):
		"bag":
			tile["rank"] = bag_rank(db)
		"requests":
			tile["rank"] = db.requests.unlock_rank
		"secret":
			tile["rank"] = int(Secret.LETTERS[0]["rank"])
	return tile


## Metnin veriden gelen sayıları (anahtarın yer tutucularıyla aynı sırada).
static func _text_args(db: ContentDB, key: String) -> Array:
	match key:
		"UI_GUIDE_GEAR_BUCKET":
			var low := 0
			var high := 0
			for g in db.gear_in("bucket"):
				low = int(g["capacity"]) if low == 0 else mini(low, int(g["capacity"]))
				high = maxi(high, int(g["capacity"]))
			return [low, high]
		"UI_GUIDE_BOOK_TEXT":
			return [BookPanel.species(db, db.main_spot).size()]
		"UI_GUIDE_TECH_TRAP":
			return [roundi(db.rules.trap_fill_s / 60.0), db.rules.trap_max]
		"UI_GUIDE_TIME_TEXT":
			return [roundi(DayClock.day_s(db.rules) / 60.0)]
		"UI_GUIDE_REQUESTS_TEXT":
			return [db.requests.slots]
	return []


## Kategorinin resmi: ilk eşyasının (gear.json icon ya da kimlik).
static func _category_art(db: ContentDB, category: String) -> String:
	var items := db.gear_in(category)
	if items.is_empty():
		return category
	return str(items[0].get("icon", items[0]["id"]))


## Kategoriyi kullanan tekniklerin ikonları (ortak yuvada, kamışta ve tekniksiz kategoride boş).
static func _category_techniques(db: ContentDB, category: String) -> PackedStringArray:
	var out := PackedStringArray()
	if not category in ContentDB.GEAR_SLOTS or db.is_shared(category) or category == "rod":
		return out
	for t: String in ContentDB.TECHNIQUES:
		if db.has_technique(t) and db.uses_slot(t, category):
			out.append("tech_" + t)
	return out


## İri balık taşıması: [başlangıç eşyasınınki, kategorinin en iyisi] (yıldız).
static func _carry_stars(db: ContentDB, category: String) -> Array:
	var start := db.gear_item(str(db.gear_start.get(category, "")))
	var best := 0
	for g in db.gear_in(category):
		best = maxi(best, int(g.get("carry", 0)))
	return [int(start.get("carry", 0)), best]


## Gölün nadirlikleri (gölde türü olanlar): rozet, gölge ipucu, rütbe puanı ve şans garantisi.
static func _rarity_tiles(db: ContentDB) -> Array[Dictionary]:
	var seen := {}
	for f in BookPanel.species(db, db.main_spot):
		seen[int(f["rarity"])] = true
	var out: Array[Dictionary] = []
	for r in db.rarities.size():
		if not seen.has(r):
			continue
		var def := db.rarity_def(r)
		var tile := _blank(db.rarity_id(r))
		tile["art"] = UiKit.rarity_icon(db, r)
		tile["title"] = "RARITY_" + db.rarity_id(r)
		var lines: Array = [[str(SHADOW_KEYS.get(str(def.get("shadow_fx", "none")), SHADOW_KEYS["none"])), []],
				["UI_GUIDE_XP", [int(def.get("xp", 0))]]]
		if int(def.get("pity", 0)) > 0:
			lines.append(["UI_BOOK_PITY", [int(def["pity"])]])
		tile["text"] = lines
		tile["rarity"] = r
		out.append(tile)
	return out


## Teknikler (kamışı oyunda olanlar) ve kerevit tuzağı: ikon, nasıl oynandığı, kilit ve yer.
static func _technique_tiles(db: ContentDB) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for t: String in ContentDB.TECHNIQUES:
		if not db.has_technique(t):
			continue
		var tile := _blank(t)
		tile["art"] = "tech_" + t
		tile["title"] = "UI_TECH_" + t
		tile["text"] = [[str(TECH_KEYS.get(t, "")), []]]
		tile["rank"] = db.technique_rank(t)
		tile["technique"] = t
		if not _everywhere(db, t):
			tile["where"] = str(WHERE_KEYS.get(t, ""))
		out.append(tile)
	if TrapSim.rank(db) > 0:
		var trap := _blank("trap")
		trap["art"] = "tech_trap"
		trap["title"] = "UI_BAG_TRAP"
		trap["text"] = [["UI_GUIDE_TECH_TRAP", _text_args(db, "UI_GUIDE_TECH_TRAP")]]
		trap["rank"] = TrapSim.rank(db)
		trap["where"] = "UI_BAG_TRAP_WHERE"
		trap["technique"] = "trap"
		out.append(trap)
	return out


## Teknik ana gölün her bölgesinde avlanılıyor mu?
static func _everywhere(db: ContentDB, technique: String) -> bool:
	for z in db.zones_of(db.main_spot):
		if not technique in (z["techniques"] as PackedStringArray):
			return false
	return true


## Ana gölün bölgeleri: rozet, tarif, Dede'nin önerdiği teknik, tuzak ve sandal ikonları, kilit.
static func _zone_tiles(db: ContentDB) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for z in db.zones_of(db.main_spot):
		var id := str(z["id"])
		var tile := _blank(id)
		tile["art"] = "zone:" + id
		tile["title"] = "ZONE_" + id
		tile["text"] = [[str(ZONE_KEYS.get(id, "")), []]]
		var icons := PackedStringArray()
		# Dede'nin yüzü ve yanında önerdiği teknik (giriş cümlesi anlatır).
		if not str(z["suggest"]).is_empty():
			icons.append(DEDE_FACE)
			icons.append("tech_" + str(z["suggest"]))
		if not (z["trap_ids"] as PackedStringArray).is_empty():
			icons.append("tech_trap")
		if bool(z["boat"]):
			icons.append("boat")
		tile["icons"] = icons
		tile["rank"] = int(z["rank"])
		tile["boat"] = bool(z["boat"])
		tile["zone"] = id
		out.append(tile)
	return out
