class_name MapPanel
extends Dialog
## Göl haritası (docs/gdd.md §10.1): HUD'daki harita düğmesiyle açılır (ilk balıktan sonra; olta
## sudayken gizli). Göl gerçek verisinden çizilir (MapView): bölgelerin rozeti ve adı, kilitli
## bölgede kilit ve neden, "Buradasın", Nine'nin dükkânı, kapalı çitler ve şamandıralar, Ersin'in
## çıkartmaları; çerçevesi Ersin'in harita kâğıdı (yoksa kodla çizilen çerçeve). Açık bir
## bölgenin rozetine dokununca oraya hızlı geçilir: panel kapanır, travel_requested (main ekranı
## karartıp balıkçıyı bölgenin atış noktasına geçirir). Kilitli bölgede neden yazılır, rozet sallanır.

signal travel_requested(zone_id: String)

## Haritanın en büyük boyu (gölün oranıyla küçülür) ve panelin en dar genişliği. Yükseklik telefonda
## (iPhone 14, alt güvenli payla) panel küçülmeden sığacak kadar: kapatma düğmesi 122 birim kalır.
const MAP := Vector2(1500, 660)
const MIN_WIDTH := 1000.0
## Panelin iç payları ve haritanın çerçevesi (genişliğe eklenir).
const FRAME_PAD := 110.0
## Kodla çizilen çerçevenin iç payı (MAP ve FRAME_PAD bununla ölçüldü) ve harita kâğıdının köşe
## payının ekrandaki boyu. Kâğıdın payı daha kalın: harita o kadar küçülür, panelin boyu aynı kalır.
const FRAME_MARGIN := 6.0
const PAPER_CORNER := 70.0

## Haritanın gölü (main verir), balıkçının yeri ve bölgesi, işaretler (dükkân, Dede).
var spot_id: String = ""
var zone_id: String = ""
var here := Vector2.ZERO
var marks: Array[Dictionary] = []

var view: MapView
var _note: Label
var _frame_style: StyleBox


func _build() -> void:
	set_header(tr("UI_MAP"), "map", MIN_WIDTH)
	var frame := PanelContainer.new()
	var sb := UiKit.card_style(Color("#8a6136"), 20, Color("#e9dcb8"), 6)
	sb.set_content_margin_all(FRAME_MARGIN)
	_frame_style = UiKit.framed("map_paper", sb, PAPER_CORNER)
	frame.add_theme_stylebox_override("panel", _frame_style)
	frame.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	body.add_child(frame)
	view = MapView.new()
	view.custom_minimum_size = MAP
	view.zone_pressed.connect(_on_zone)
	frame.add_child(view)
	_note = UiKit.ink("", 28, UiKit.INK_SOFT, HORIZONTAL_ALIGNMENT_CENTER)
	body.add_child(_note)


## Açar: balıkçının yeri ve bölgesi, işaretler ([{ "kind": "shop" | "dede", "pos": Vector2 }]).
func open_map(position: Vector2, current: String, map_marks: Array[Dictionary]) -> void:
	here = position
	zone_id = current
	marks = map_marks
	open()


func refresh() -> void:
	_note.text = tr("UI_MAP_HINT")
	_note.add_theme_color_override("font_color", UiKit.INK_SOFT)
	view.show_lake(GameState.db, GameState.save, spot_id, here, zone_id, marks)
	# Harita gölün oranında: boş kâğıt payı kalmasın.
	var extra := _frame_extra()
	view.custom_minimum_size = view.fitted_size(MAP - extra)
	set_header(tr("UI_MAP"), "map", maxf(MIN_WIDTH, view.custom_minimum_size.x + FRAME_PAD + extra.x))


## Çerçevenin (kâğıdın) payının kodla çizilen çerçevenin payından fazlası (iki yan toplam).
func _frame_extra() -> Vector2:
	var pad := Vector2(_frame_style.get_margin(SIDE_LEFT) + _frame_style.get_margin(SIDE_RIGHT),
			_frame_style.get_margin(SIDE_TOP) + _frame_style.get_margin(SIDE_BOTTOM))
	return (pad - Vector2.ONE * FRAME_MARGIN * 2.0).max(Vector2.ZERO)


func _on_zone(id: String) -> void:
	var db := GameState.db
	var z := db.zone(spot_id, id)
	if z.is_empty():
		return
	var reason := Zones.lock_reason(db, GameState.save, z)
	if not reason.is_empty():
		Sounds.play("error")
		Sounds.haptic(20)
		var key := str(reason["key"])
		var why := tr(key) % int(reason["rank"]) if key == "UI_ZONE_LOCKED_RANK" else tr(key)
		_note.text = "%s: %s" % [tr("ZONE_" + id), why]
		_note.add_theme_color_override("font_color", Color("#a2471d"))
		view.shake(id)
		return
	# Gidilecek yer: bölgenin atış noktası ya da (sandal bölgesinde) şamandırası.
	if (z["stands"] as Array).is_empty() and (z["buoys"] as Array).is_empty():
		return
	Sounds.play("ui_tap")
	close_panel()
	travel_requested.emit(id)
