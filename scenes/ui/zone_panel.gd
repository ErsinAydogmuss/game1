class_name ZonePanel
extends Dialog
## Bölge kartı (testçi: "hangi bölgede hangi balık hangi oranda çıkıyor?"): haritada bir bölgenin rozetine
## dokununca haritanın üstünde açılır (kapanınca harita açık kalır). O bölgede elindeki teknikle (orada
## avlanılmıyorsa oyunun da geçeceği teknikle: technique_for) ve gölün şimdiki koşuluyla (vakit, hava, göl
## sevgisi: WorldState) gelen türler, en sık gelenden başlayarak: resmi, adı, nadirliği ve oranı. Oran, oyunda
## doğan gölgelerinkiyle aynı işlevden (CatchOdds.species_ppm; defter de bunu kullanır: gelir kuralı 10).
## Tutulmamış tür siluet ve "???" (keşfetme sürprizi kalsın), nadirliği ve oranı yine yazar. Şimdi gelmeyen ama
## başka vakitte (Ay Turnası gece, Kocabaş fırtınada) ya da başka teknikle (alabalık sinekle, kerevit dipte) gelen
## tür sonda, oran yerine ne zaman ya da hangi teknikle. Altta kerevit tuzağı kurulur mu; sağda GİT
## (travel_requested: main haritayı kapatıp oraya geçirir), kilitliyse nedeni; balıkçının bölgesindeyse
## "Buradasın" (GİT yalnızca atış noktasında değilse: haritanın eski davranışı; sandalda derin ortada: sıradaki
## şamandıra).

signal travel_requested(zone_id: String)

const WIDTH := 1420.0
## Türlerin kartı: beş sütun (bir bölgede en çok 9 tür: derin orta), iki sıra.
const COLUMNS := 5
const CARD := Vector2(246, 210)
const ART := 96.0
const GO_BUTTON := Vector2(340, 122)
## Balıkçı atış noktasında sayılır (main._travel'ın eşiği).
const AT_STAND := 0.5
## Kilidin yazısı (haritadaki eski notun rengi).
const LOCK_COLOR := Color("#a2471d")

## Haritanın gölü (main verir), gösterilen bölge, balıkçı o bölgede mi, sandalda mı, nerede.
var spot_id: String = ""
var zone: String = ""
var current: bool = false
var in_boat: bool = false
var angler_pos := Vector2.ZERO

var _info: HBoxContainer
var _grid: GridContainer
var _foot: HBoxContainer


func _build() -> void:
	set_header("", "map", WIDTH)
	_info = HBoxContainer.new()
	_info.name = "Info"
	_info.add_theme_constant_override("separation", 14)
	body.add_child(_info)
	_grid = GridContainer.new()
	_grid.name = "Species"
	_grid.columns = COLUMNS
	_grid.add_theme_constant_override("h_separation", 14)
	_grid.add_theme_constant_override("v_separation", 14)
	_grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	body.add_child(_grid)
	_foot = HBoxContainer.new()
	_foot.name = "Foot"
	_foot.add_theme_constant_override("separation", 18)
	body.add_child(_foot)


## Açar: bölge, balıkçı o bölgede mi, sandalda mı (sandal bölgesinde GİT sıradaki şamandıraya götürür), nerede
## (kendi bölgesinde atış noktasındaysa GİT yok).
func open_zone(id: String, here: bool, boat: bool, pos: Vector2) -> void:
	zone = id
	current = here
	in_boat = boat
	angler_pos = pos
	open()


func refresh() -> void:
	var db := GameState.db
	var save := GameState.save
	set_header(tr("ZONE_" + zone), "zone:" + zone, WIDTH)
	clear(_info)
	clear(_grid)
	clear(_foot)
	var z := db.zone(spot_id, zone)
	if z.is_empty():
		return
	var technique := technique_for(db, save, spot_id, zone)
	_info.add_child(_pill("tech_" + technique, tr("UI_TECH_" + technique)))
	_info.add_child(BookPanel.conditions_pill(db, save))
	_info.add_child(UiKit.spacer())
	if current:
		_info.add_child(_pill("pin", tr("UI_MAP_HERE")))
	for row in rows(db, save, spot_id, zone):
		_grid.add_child(_card(db, save, row))
	var notes := VBoxContainer.new()
	notes.add_theme_constant_override("separation", 6)
	notes.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	notes.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_foot.add_child(notes)
	var note := UiKit.ink(tr("UI_ZONE_NOTE"), 24, UiKit.INK_SOFT)
	note.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	notes.add_child(note)
	if not (z["trap_ids"] as PackedStringArray).is_empty():
		var trap := UiKit.icon_text("trap", tr("UI_ZONE_TRAP"), 44, 26)
		trap.name = "Trap"
		notes.add_child(trap)
	var reason := Zones.lock_reason(db, save, z)
	if not reason.is_empty():
		var key := str(reason["key"])
		var lock := HBoxContainer.new()
		lock.name = "Locked"
		lock.add_theme_constant_override("separation", 10)
		lock.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		lock.add_child(GameIcon.make("lock", 56))
		lock.add_child(UiKit.ink(tr(key) % int(reason["rank"]) if key == "UI_ZONE_LOCKED_RANK" else tr(key), 30,
				LOCK_COLOR))
		_foot.add_child(lock)
		return
	# Gidilecek yer: bölgenin atış noktası ya da (sandal bölgesinde) şamandırası. Balıkçı kendi bölgesinin atış
	# noktasındaysa düğme yok (main._travel orada bir şey yapmaz); sandalla derin ortadaysa sıradaki şamandıraya
	# (haritanın eski davranışı).
	var stands: Array = z["stands"]
	if stands.is_empty() and (z["buoys"] as Array).is_empty():
		return
	var boat_here := current and bool(z["boat"]) and in_boat
	if current and not boat_here and not in_boat and not stands.is_empty() \
			and angler_pos.distance_to(stands[0]) < AT_STAND:
		return
	var go := UiKit.button(tr("UI_ZONE_NEXT_BUOY") if boat_here else tr("UI_ZONE_GO"), UiKit.SUCCESS,
			UiKit.SIZE_BODY, GO_BUTTON)
	go.name = "Go"
	go.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	go.pressed.connect(func() -> void:
		Sounds.play("ui_tap")
		close_panel()
		travel_requested.emit(zone))
	_foot.add_child(go)


## Bölgede oranların tekniği: oyun oraya varınca neyle avlanacaksa o (main._fit_technique): elindeki teknik
## orada avlanılıyorsa o; şamandıraya dönülmüş ve bırakılan teknik (sinek) orada avlanılıyorsa o; yoksa şamandıra.
static func technique_for(db: ContentDB, save: SaveData, spot: String, zone_id: String) -> String:
	var held := str(save.flags.get(Economy.HELD_FLAG, ""))
	if save.technique == "float" and not held.is_empty() and Economy.technique_allowed(db, spot, zone_id, held) \
			and Economy.technique_ready(db, save, held):
		return held
	if Economy.technique_allowed(db, spot, zone_id, save.technique) and Economy.technique_ready(db, save, save.technique):
		return save.technique
	return "float"


## Bölgenin türleri: { id, ppm (şimdi, elindeki takımla), when ("": şimdi geliyor; yoksa ne zaman ya da hangi
## teknikle: UI_ZONE_NIGHT, UI_ZONE_STORM, UI_ZONE_WITH), technique (UI_ZONE_WITH'in tekniği) }. Önce şimdi
## gelenler, en sık gelenden (eşitse fish.json sırası); sonra şimdi gelmeyenler bölgenin tablosundaki sırayla.
## Hiçbir koşulda ve teknikte gelmeyen tür yazılmaz.
static func rows(db: ContentDB, save: SaveData, spot: String, zone_id: String) -> Array[Dictionary]:
	var place := Zones.place(db, spot, zone_id)
	var technique := technique_for(db, save, spot, zone_id)
	var cond := WorldState.conditions(db, save)
	var gear := Economy.gear_for(db, save, technique)
	var now := CatchOdds.species_ppm(db, place, CatchOdds.context(gear, technique, cond))
	var out: Array[Dictionary] = []
	var later: Array[Dictionary] = []
	for id: String in (place.get("fish_ids", PackedStringArray()) as PackedStringArray):
		var ppm := int(now.get(id, 0))
		if ppm > 0:
			out.append({ "id": id, "ppm": ppm, "when": "", "technique": "" })
			continue
		var other := _other_way(db, place, technique, cond, id)
		if not other.is_empty():
			later.append(other)
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(a["ppm"]) > int(b["ppm"]) if int(a["ppm"]) != int(b["ppm"]) \
				else db.fish_index(str(a["id"])) < db.fish_index(str(b["id"])))
	return out + later


## Şimdi gelmeyen tür başka nasıl gelir: kendi vaktinde (Ay Turnası gece, Kocabaş fırtınada) bu teknikle, yoksa
## bölgede avlanılan başka bir teknikle: onu en sık getiren (alabalık sinekle; şimdiki ya da kendi koşulunda).
## Hiç gelmiyorsa {}.
static func _other_way(db: ContentDB, place: Dictionary, technique: String, cond: Dictionary, id: String) -> Dictionary:
	var own := CatchOdds.own_conditions(db, id)
	var own_cond := cond.duplicate()
	own_cond.merge(own, true)
	if not own.is_empty() and _ppm(db, place, technique, own_cond, id) > 0:
		var storm := str(own["weather"]) == "rain" and str(own["phase"]) == "night"
		return { "id": id, "ppm": 0, "when": "UI_ZONE_STORM" if storm else "UI_ZONE_NIGHT", "technique": "" }
	var best := ""
	var best_ppm := 0
	for t: String in ContentDB.TECHNIQUES:
		if t == technique or not db.has_technique(t) or not CatchOdds.allows(place, t):
			continue
		var ppm := maxi(_ppm(db, place, t, cond, id), _ppm(db, place, t, own_cond, id) if not own.is_empty() else 0)
		if ppm > best_ppm:
			best = t
			best_ppm = ppm
	if best.is_empty():
		return {}
	return { "id": id, "ppm": 0, "when": "UI_ZONE_WITH", "technique": best }


## Türün o teknikle ve koşulda oranı (takımsız: yemin çekimi yok; yalnızca gelir mi, hangisiyle sık gelir).
static func _ppm(db: ContentDB, place: Dictionary, technique: String, cond: Dictionary, id: String) -> int:
	return int(CatchOdds.species_ppm(db, place, CatchOdds.context(null, technique, cond)).get(id, 0))


## Bir türün kartı: resmi (tutulmadıysa siluet), adı (ya da "???"), nadirlik simgesi ve oranı (şimdi gelmiyorsa
## ne zaman ya da hangi teknikle; kart soluk).
func _card(db: ContentDB, save: SaveData, row: Dictionary) -> Control:
	var id := str(row["id"])
	var found := save.records.has(id)
	var rarity := int(db.fish_by_id(id).get("rarity", 0))
	var border := UiKit.rarity_color(db, rarity) if found else BookPanel.UNKNOWN_BORDER
	var panel := PanelContainer.new()
	panel.name = "Fish_" + id
	panel.custom_minimum_size = CARD
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sb := UiKit.card_style(border, 24, Color(border, 0.14) if found else Color("#efe2c6"), 4)
	sb.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", sb)
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 2)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	column.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(column)
	var art := BookPanel.fish_art(id, ART, found)
	art.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	column.add_child(art)
	var name_text := tr("FISH_" + id) if found else "???"
	var name_label := UiKit.ink(name_text, UiKit.fit_size(name_text, UiKit.body_font(), 26, CARD.x - 30.0, 18), UiKit.INK,
			HORIZONTAL_ALIGNMENT_CENTER)
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	column.add_child(name_label)
	var foot := HBoxContainer.new()
	foot.alignment = BoxContainer.ALIGNMENT_CENTER
	foot.add_theme_constant_override("separation", 8)
	foot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	column.add_child(foot)
	var mark := GameIcon.make(UiKit.rarity_icon(db, rarity), 32, border if found else Color("#b9a27c"))
	if not found:
		mark.modulate_art = BookPanel.UNFOUND_MARK
	foot.add_child(mark)
	var when := str(row["when"])
	var odds: Label
	if when.is_empty():
		odds = UiKit.ink(UiKit.format_percent(int(row["ppm"])), 30, UiKit.INK)
		odds.add_theme_font_override("font", UiKit.display_font())
	else:
		var text := tr(when) % tr("UI_TECH_" + str(row["technique"])) if when == "UI_ZONE_WITH" else tr(when)
		odds = UiKit.ink(text, UiKit.fit_size(text, UiKit.body_font(), 24, CARD.x - 70.0, 18), UiKit.INK_SOFT)
		panel.modulate = Color(1, 1, 1, 0.72)
	odds.name = "Odds"
	foot.add_child(odds)
	return panel


## Bilgi hapı: ikon ve kısa yazı (tekniğin adı, "Buradasın").
func _pill(icon_kind: String, text: String) -> PanelContainer:
	var pill := PanelContainer.new()
	pill.add_theme_stylebox_override("panel", UiKit.pill_style(Color(0.18, 0.1, 0.04, 0.85)))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	pill.add_child(row)
	row.add_child(GameIcon.make(icon_kind, 48))
	var label := UiKit.label(text, 26, UiKit.TEXT)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)
	return pill
