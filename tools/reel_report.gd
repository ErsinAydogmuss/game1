extends SceneTree
## Çekişme denge raporu: her balık, boy (yıldız kümesi), bot tarzı ve mod için yakalama, kopma, kaçma
## oranları ve süreler. Sayılar data/fish.json, data/rules.json ve data/gear.json'dan gelir.
##   godot --headless --path . -s res://tools/reel_report.gd
##   godot --headless --path . -s res://tools/reel_report.gd -- --gear=mid   (cam elyafı kamış + naylon misina)
##   godot --headless --path . -s res://tools/reel_report.gd -- --gear=top   (en iyi şamandıra takımı)
##   godot --headless --path . -s res://tools/reel_report.gd -- --technique=bottom [--gear=mid|top]
## --technique= (spin, bottom, fly): o teknikle gelen türler (fish.json affinity; şamandırada bütün
## türler, karşılaştırma için), tekniğin kamışı
## (start: ilk kamışı, mid: ikincisi + naylon misina, top: tekniğin en iyi takımı) ve balığın
## takıldığı uzaklık oyundan ölçülen aralıkta (data/sim.json techniques.<teknik>.start_m; dipte
## uzakta takılır, çekişme uzun sürer). Çekişme her teknikte aynı kurallarla (alabalığın ilk çırpınması
## fight.first_burst, sıçrayışı yalnızca görünüş).
## Hedefler (docs/gdd.md §5): iyi oyuncu (kusursuz, 0,4 sn) takımın taşıdığı her balığı tutar;
## Kızılkanat 4–7 sn, Yayın 14–20 sn; hep basılı tutan Normal'de koparır, Kolay'da tutar. İri türün
## taşımayı aşan (fazla iri) 4–5★'ını iyi oyuncu tutamaz, kusursuz pompalayan da çoğunlukla kaçırır.

const RUNS := 200
## Başlangıç uzaklıkları (m): atışların çoğu bu aralıkta.
const DISTANCES := [4.0, 5.0, 6.0, 7.0, 8.0, 9.0]
## Boy kümeleri: [ad, en az yüzdelik, en çok yüzdelik (ppm, hariç)]. 1–3★ her türde; 4★ ve 5★
## yalnızca iri türde ayrı satır (öteki türde boy çekişmeyi değiştirmez).
const GROUPS := [["1-3★", 0, 700000], ["4★", 700000, 900000], ["5★", 900000, 1000000]]


func _initialize() -> void:
	var db := ContentDB.load_default()
	for e in db.errors:
		printerr("İçerik hatası: " + e)
	var mode := "start"
	var technique := "float"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--gear="):
			mode = arg.get_slice("=", 1)
		elif arg.begins_with("--technique="):
			technique = arg.get_slice("=", 1)
	if not db.has_technique(technique):
		printerr("Bilinmeyen teknik: " + technique)
		quit(1)
		return
	var gear := gear_for(db, mode, technique)
	var distances := distances_for(technique)
	var max_distance: float = gear.range_m + db.rules.escape_extra + gear.escape_extra
	var bots := [
		["kusursuz", ReelBot.Style.PERFECT, 0.0],
		["tepki 0,4", ReelBot.Style.REACT, 0.4],
		["tepki 0,7", ReelBot.Style.REACT, 0.7],
		["hep basılı", ReelBot.Style.ALWAYS, 0.0],
		["pompa", ReelBot.Style.PUMP, 0.0],
	]
	var rod_name := str(gear.items.get("rod", ""))
	print("Çekişme raporu: %s (%d deneme, başlangıç %.1f–%.1f m, boy kümenin içinde eşit aralıklı; takım: %s, %s, taşıma %d★, kaçma %.1f m)" % [
			technique, RUNS, distances[0], distances[-1], {"start": "başlangıç", "mid": "ikinci kamış + naylon misina",
			"top": "en iyi"}.get(mode, mode), rod_name, gear.carry, max_distance])
	for easy: bool in [false, true]:
		print("")
		print("== %s ==" % ("KOLAY" if easy else "NORMAL"))
		print("%-12s %-5s %-11s %7s %7s %7s %7s %8s %8s %8s" % ["balık", "boy", "bot", "tutar", "koparır", "kaçar",
				"bitmedi", "ort sn", "en çok", "kırmızı"])
		for f in db.fish:
			if not _reported(db, str(f["id"]), technique):
				continue
			var fight: Dictionary = f["fight"]
			for g: Array in GROUPS:
				if int(g[1]) > 0 and not bool(fight["heavy"]):
					continue
				var heavy_mark := "*" if ReelModel.excess_for(fight, int(g[1]), gear.carry) > 0 else ""
				for b: Array in bots:
					# Pompalamak Kolay'da anlamsız: gerilim sınırda durur, misina kopmaz.
					if easy and int(b[1]) == ReelBot.Style.PUMP:
						continue
					var caught := 0
					var snapped := 0
					var escaped := 0
					var total_s := 0.0
					var max_s := 0.0
					var red := 0.0
					for i in RUNS:
						var start: float = distances[i % distances.size()]
						var model := ReelModel.new(db.rules, fight, gear.reel_speed, start, max_distance, easy,
								Dice.derive(4242, i), gear, percentile_in(g, i, RUNS))
						var result := ReelBot.play(model, ReelBot.make(b[1], b[2]))
						match int(result["outcome"]):
							ReelModel.Outcome.CAUGHT:
								caught += 1
								total_s += float(result["seconds"])
								max_s = maxf(max_s, float(result["seconds"]))
							ReelModel.Outcome.SNAPPED:
								snapped += 1
							ReelModel.Outcome.ESCAPED:
								escaped += 1
						red += float(result["red"])
					var unfinished := RUNS - caught - snapped - escaped
					print("%-12s %-5s %-11s %6.0f%% %6.0f%% %6.0f%% %6.0f%% %8.1f %8.1f %8.2f" % [f["id"], str(g[0]) + heavy_mark,
							b[0], 100.0 * caught / RUNS, 100.0 * snapped / RUNS, 100.0 * escaped / RUNS,
							100.0 * unfinished / RUNS, total_s / maxi(1, caught), max_s, red / RUNS])
	print("")
	print("* fazla iri: iri türün yıldızı takımın taşımasını aşıyor. bitmedi: %d sn'de sonuçlanmadı (pompalayan" % roundi(float(ReelBot.LIMIT_STEPS) / FishingRules.HZ))
	print("  fazla iri balığı yerinde tutabilir ama getiremez; bırakınca kaçar).")
	print("")
	# Süreler orta uzaklıkta (şamandırada eskisi gibi 6 m).
	var middle: float = 6.0 if technique == "float" else (distances[0] + distances[-1]) * 0.5
	print("Süreler (%.1f m, kusursuz, Normal, 1–3★): " % middle)
	for f in db.fish:
		if not _reported(db, str(f["id"]), technique):
			continue
		var times: Array[float] = []
		for i in RUNS:
			var model := ReelModel.new(db.rules, f["fight"], gear.reel_speed, middle, max_distance,
					false, Dice.derive(777, i), gear, percentile_in(GROUPS[0], i, RUNS))
			var result := ReelBot.play(model, ReelBot.make(ReelBot.Style.PERFECT))
			times.append(float(result["seconds"]))
		times.sort()
		print("  %-12s en az %.1f  ortanca %.1f  en çok %.1f sn" % [f["id"], times[0], times[times.size() >> 1], times[-1]])
	quit()


## Raporda yer alan tür: şamandırada hepsi (çekişme modelinin karşılaştırması; docs/gdd.md §5
## tabloları), öteki teknikte yalnızca o teknikle gelenler.
static func _reported(db: ContentDB, fish_id: String, technique: String) -> bool:
	return technique == "float" or db.affinity(fish_id, technique) > 0.0


## Rapor ve testlerin takımları: start (tekniğin ilk kamışı; şamandırada bambu olta), mid (başlangıç +
## tekniğin ikinci kamışı (şamandırada cam elyafı) ve naylon misina: 4★ taşır), top (tekniğin en iyi
## takımı).
static func gear_for(db: ContentDB, mode: String, technique: String = "float") -> GearStats:
	var rods := db.rods_of(technique)
	var none: Array[String] = []
	var items := db.gear_start.duplicate()
	match mode:
		"top":
			return GearStats.best(db, technique)
		"mid":
			items["rod"] = str(rods[mini(1, rods.size() - 1)]["id"])
			items["line"] = "line_mono"
			return GearStats.from_items(db, items, none)
	if technique == "float":
		return GearStats.starter(db)
	items["rod"] = str(rods[0]["id"])
	return GearStats.from_items(db, items, none)


## Balığın takıldığı uzaklıklar (m): şamandırada DISTANCES; öteki teknikte oyundan ölçülen aralıkta
## (data/sim.json techniques.<teknik>.start_m) DISTANCES kadar eşit aralıklı.
static func distances_for(technique: String) -> Array[float]:
	var out: Array[float] = []
	if technique == "float":
		for d: float in DISTANCES:
			out.append(d)
		return out
	var timing := SessionSim.load_timing()
	var own: Dictionary = (timing.get("techniques", {}) as Dictionary).get(technique, {})
	var span: Variant = own.get("start_m", timing.get("start_m", [4.0, 9.0]))
	var lo := float((span as Array)[0])
	var hi := float((span as Array)[1])
	for i in DISTANCES.size():
		out.append(lerpf(lo, hi, float(i) / (DISTANCES.size() - 1)))
	return out


## Kümenin i. denemesinin boy yüzdeliği: kümenin içinde eşit aralıklı.
static func percentile_in(group: Array, i: int, runs: int) -> int:
	var low := int(group[1])
	var high := int(group[2])
	return low + int(float(high - low) * (float(i) + 0.5) / runs)
