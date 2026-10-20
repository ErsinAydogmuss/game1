extends BaseTest
## Kamış ve makara görünüşü (RodModel): dükkândaki her kamışın ve makaranın görünüşü var, kamışın
## tekniği tutuyor, aynı teknikte kamışlar birbirinden farklı; kurulan olta 4 ağ (4 çizim) ve uçlu.


func test_every_rod_and_reel_has_a_look() -> void:
	var db := content()
	for g in db.gear_in("rod"):
		var id := str(g["id"])
		assert_true(RodModel.LOOKS.has(id), "kamışın görünüşü yok: " + id)
		if RodModel.LOOKS.has(id):
			assert_eq(str((RodModel.LOOKS[id] as Dictionary)["technique"]), str(g["technique"]), "%s: tekniği" % id)
	for g in db.gear_in("reel"):
		assert_true(RodModel.REEL_LOOKS.has(str(g["id"])), "makaranın görünüşü yok: " + str(g["id"]))
	for technique: String in RodModel.STYLES:
		assert_true(RodModel.LOOKS.has(str(RodModel.STYLES[technique])), "%s: varsayılan görünüş" % technique)
	assert_eq(RodModel.look_of("yok", "spin"), RodModel.LOOKS["rod_spin_light"], "bilinmeyen kamış: tekniğin ilki")


## Aynı teknikte kamışlar ayırt edilir: kamışın rengi ya da sargısı farklı; makaraların gövdesi farklı.
func test_looks_differ_within_a_technique() -> void:
	var seen := {}
	for id: String in RodModel.LOOKS:
		var look: Dictionary = RodModel.LOOKS[id]
		var key := "%s|%s|%s" % [look["technique"], look["blank"], look.get("butt", "")]
		assert_true(not seen.has(key), "%s ile %s aynı görünüyor" % [id, seen.get(key, "")])
		seen[key] = id
	var bodies := {}
	for id: String in RodModel.REEL_LOOKS:
		var body := str((RodModel.REEL_LOOKS[id] as Dictionary)["body"])
		assert_true(not bodies.has(body), "%s ile %s aynı renk" % [id, bodies.get(body, "")])
		bodies[body] = id


## Kurulan olta: sabit kısım ve üç eklem birer ağ (4 çizim), ucu kamışın boyunda; sinek kamışında
## yuvarlak makara (yanı kameraya dönük: gövdesinin ekseni x'te), ötekilerde çıkrık.
func test_built_rod_is_four_meshes_with_a_tip() -> void:
	for id: String in RodModel.LOOKS:
		var look: Dictionary = RodModel.LOOKS[id]
		var rod := RodModel.new()
		rod.style = str(look["technique"])
		rod.gear_id = id
		rod.reel_id = "reel_master"
		rod.build()
		var meshes := rod.find_children("*", "MeshInstance3D", true, false)
		assert_eq(meshes.size(), 4, "%s: 4 ağ" % id)
		assert_true(rod.tip != null, "%s: uç" % id)
		if rod.tip != null:
			# Uç, eklemler düzken kökten JOINT0_Z + boy uzakta (-Z): ağaçta olmayan düğümün yeri elle toplanır.
			var z := 0.0
			var node: Node3D = rod.tip
			while node != rod:
				z += node.position.z
				node = node.get_parent() as Node3D
			var want := RodModel.JOINT0_Z - float(look["length"])
			assert_between(z, want - 0.01, want + 0.01, "%s: kamışın boyu" % id)
		rod.free()
