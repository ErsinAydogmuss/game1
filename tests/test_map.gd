extends BaseTest
## Harita (MapView, MapPanel) ve harita düğmesi: haritanın kapladığı yer, harita verisi (su, bölge,
## yürünebilen kara, orman), rozetlerin birbirine binmemesi, düğmenin görünürlüğü.

const SPOT := "big_lake"


## Harita suyu, iskeleyi, atış noktalarını ve şamandıraları içine alır.
func test_region_covers_the_lake() -> void:
	var db := content()
	var lake := db.lake(SPOT)
	var region := MapView.map_region(lake)
	assert_true(region.encloses(lake.water_bounds), "su haritada")
	assert_true(region.encloses(lake.dock), "iskele haritada")
	for z in db.zones_of(SPOT):
		for p: Vector2 in z["stands"]:
			assert_true(region.has_point(p), "%s atış noktası haritada" % z["id"])
		for p: Vector2 in z["buoys"]:
			assert_true(region.has_point(p), "%s şamandırası haritada" % z["id"])
	var front := ShopStall.front_for(lake.dock)
	assert_true(region.has_point(front - ShopStall.facing_dir() * ShopStall.DEPTH), "Nine'nin dükkânı haritada")


## Harita verisi: bölgenin suyunda kıyı uzaklığı +, bölgesi doğru; atış noktası yürünebilir (kara ya
## da iskele); kuzey kıyısının ötesi orman (yürünmez).
func test_map_data() -> void:
	var db := content()
	var lake := db.lake(SPOT)
	var region := MapView.map_region(lake)
	var image := MapView.build_image(lake, region)
	assert_eq(image.get_width(), ceili(region.size.x / MapView.STEP), "genişlik")
	var zones := db.zones_of(SPOT)
	for k in zones.size():
		var c := MapView.badge_anchor(lake, k, zones[k])
		var px := _pixel(image, region, c)
		assert_true(px.r > 0.0, "%s rozeti suyun üstünde (kıyı %.2f m)" % [zones[k]["id"], px.r])
		assert_eq(int(px.b), k + 1, "%s bölgesi" % zones[k]["id"])
		# Atış noktası yürünebilir: kara ya da iskele (iskelenin altı sudur).
		for p: Vector2 in zones[k]["stands"]:
			var stand := _pixel(image, region, p)
			assert_true((stand.r <= 0.0 or lake.on_dock(p)) and stand.a > 0.5, "%s atış noktası yürünebilir" % zones[k]["id"])
	var north := Vector2(-3.5, lake.water_bounds.position.y - 2.0)
	var forest := _pixel(image, region, north)
	assert_true(forest.r < 0.0 and forest.a < 0.5, "kuzey kıyısının ötesi orman (yürünmez)")
	var dock := _pixel(image, region, lake.dock.get_center())
	assert_true(dock.a > 0.5, "iskele yürünebilir")


## Rozetler birbirinden uzak: haritada üst üste binmez.
func test_badges_do_not_overlap() -> void:
	var db := content()
	var lake := db.lake(SPOT)
	var zones := db.zones_of(SPOT)
	for a in zones.size():
		for b in range(a + 1, zones.size()):
			var d := MapView.badge_anchor(lake, a, zones[a]).distance_to(MapView.badge_anchor(lake, b, zones[b]))
			assert_true(d >= 9.0, "%s ile %s rozeti arası %.1f m" % [zones[a]["id"], zones[b]["id"], d])



## Rozetler "Buradasın" iğnesine binmez: balıkçı her atış noktasında ve her şamandıradaki sandalda.
func test_badges_avoid_the_pin() -> void:
	var db := content()
	var save := SaveData.create_new(0)
	save.xp = db.rank_xp[8]
	save.owned.append(Zones.BOAT)
	var places: Array[Vector2] = []
	for z in db.zones_of(SPOT):
		for p: Vector2 in z["stands"]:
			places.append(p)
		for p: Vector2 in z["buoys"]:
			places.append(p + LakeScene.BUOY_MOOR)
	var marks: Array[Dictionary] = []
	for here in places:
		var view := MapView.new()
		view.size = MapPanel.MAP
		view.show_lake(db, save, SPOT, here, Zones.at(db, SPOT, here).get("id", ""), marks)
		var pin := view.pin_box()
		for z in db.zones_of(SPOT):
			var badge := view.badge(str(z["id"]))
			var r := Rect2(badge.position, badge.size)
			assert_true(not r.intersects(pin), "%s rozeti %s'teki iğneye binmez" % [z["id"], here])
		view.free()


## Ersin'in çıkartmaları (Parti 3) haritanın içinde; rozetlere, "Yeni!" etiketlerine, iğneye,
## işaretlere ve birbirine binmez (görselin saydam payı sayılmaz). Bölgelerin süsü ve ağaçlar
## görünür. Balıkçı her atış noktasında ve sandalda.
func test_stickers_stay_clear() -> void:
	if ItemArt.map_art("map_trees") == null:
		return
	var db := content()
	var lake := db.lake(SPOT)
	var save := SaveData.create_new(0)
	save.xp = db.rank_xp[8]
	save.owned.append(Zones.BOAT)
	var front := ShopStall.front_for(lake.dock)
	var boat := Vector2(lake.dock.position.x - LakeScene.BOAT_SIDE, lake.dock.position.y + LakeScene.BOAT_ALONG)
	var places: Array[Vector2] = []
	for z in db.zones_of(SPOT):
		for p: Vector2 in z["stands"]:
			places.append(p)
	var buoys: Array = db.zone(SPOT, "deep_water")["buoys"]
	var afloat: Vector2 = buoys[0] + LakeScene.BUOY_MOOR
	places.append(afloat)
	var art := [GameIcon.texture_for("compass")]
	for n: String in ["map_trees", "map_reeds", "map_lilies", "map_rocks", "map_boat"]:
		art.append(ItemArt.map_art(n))
	for here in places:
		var marks: Array[Dictionary] = [
			{ "kind": "shop", "pos": front - ShopStall.facing_dir() * ShopStall.DEPTH * 0.5 },
			{ "kind": "dede", "pos": lake.dock.get_center() },
		]
		# Sandaldayken sandal iğnenin yerinde: işareti yok (main._map_marks).
		if here != afloat:
			marks.append({ "kind": "boat", "pos": boat })
		var view := MapView.new()
		view.size = MapPanel.MAP
		view.show_lake(db, save, SPOT, here, Zones.at(db, SPOT, here).get("id", ""), marks)
		var taken: Array[Rect2] = [view.pin_box()]
		var stickers: Array[Rect2] = []
		for child in view.get_children():
			var r := Rect2(child.position, child.size)
			if child is TextureRect and (child as TextureRect).texture in art:
				if child.visible:
					stickers.append(r)
			elif child is TextureRect or child is PanelContainer:
				# Dükkân ve Dede işaretleri, rozetler ve "Yeni!" etiketleri.
				taken.append(r)
		assert_true(stickers.size() >= 5, "%s: en az beş çıkartma görünür (%d)" % [here, stickers.size()])
		for i in stickers.size():
			var s := stickers[i]
			assert_true(Rect2(Vector2.ZERO, view.size).encloses(s), "%s: çıkartma haritanın içinde %s" % [here, s])
			var core := s.grow(-s.size.x * 0.08)
			for t in taken:
				assert_true(not core.intersects(t), "%s: çıkartma %s rozete ya da iğneye binmez %s" % [here, s, t])
			for j in range(i + 1, stickers.size()):
				assert_true(not core.intersects(stickers[j]), "%s: çıkartmalar birbirine binmez" % here)
		view.free()


## Ağaç çıkartmaları ormanda (yürünmeyen kara, kıyıdan uzak) ve birbirinden uzak.
func test_forest_points_are_in_the_forest() -> void:
	var db := content()
	var lake := db.lake(SPOT)
	var points := MapView.forest_points(SPOT, lake, MapView.map_region(lake))
	assert_true(points.size() >= 3, "en az üç ağaç öbeği (%d)" % points.size())
	for i in points.size():
		var p := points[i]
		assert_true(not lake.in_world(p) and lake.land_distance(p) < -MapView.FOREST_SHORE, "%s ormanda" % p)
		for j in range(i + 1, points.size()):
			assert_true(p.distance_to(points[j]) >= MapView.TREE_GAP - 0.01, "ağaçlar arası %.1f m" % p.distance_to(points[j]))


## Harita düğmesi: izin yokken (ilk balıktan önce) ve olta sudayken gizli.
func test_map_button_visibility() -> void:
	var hud := Hud.new()
	hud.call("_build_top")
	assert_true(not hud.map_button.visible, "başta gizli")
	hud.map_allowed = true
	assert_true(hud.map_button.visible, "izin verilince görünür")
	hud.set_line_out(true)
	assert_true(not hud.map_button.visible and not hud.book_button.visible, "olta sudayken gizli")
	hud.set_line_out(false)
	assert_true(hud.map_button.visible, "olta dönünce görünür")
	hud.map_allowed = false
	hud.set_line_out(false)
	assert_true(not hud.map_button.visible and hud.book_button.visible, "izin yokken olta dönse de gizli")
	hud.free()


static func _pixel(image: Image, region: Rect2, p: Vector2) -> Color:
	var x := clampi(floori((p.x - region.position.x) / MapView.STEP), 0, image.get_width() - 1)
	var y := clampi(floori((p.y - region.position.y) / MapView.STEP), 0, image.get_height() - 1)
	return image.get_pixel(x, y)
