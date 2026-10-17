extends SceneTree
## Çekişme denge raporu: her balık, boy (yıldız kümesi), bot tarzı ve mod için yakalama, kopma, kaçma
## oranları ve süreler. Sayılar data/fish.json, data/rules.json ve data/gear.json'dan gelir.
##   godot --headless --path . -s res://tools/reel_report.gd
##   godot --headless --path . -s res://tools/reel_report.gd -- --gear=mid   (cam elyafı kamış + naylon misina)
##   godot --headless --path . -s res://tools/reel_report.gd -- --gear=top   (en iyi şamandıra takımı)
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
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--gear="):
			mode = arg.get_slice("=", 1)
	var gear := gear_for(db, mode)
	var max_distance: float = gear.range_m + db.rules.escape_extra + gear.escape_extra
	var bots := [
		["kusursuz", ReelBot.Style.PERFECT, 0.0],
		["tepki 0,4", ReelBot.Style.REACT, 0.4],
		["tepki 0,7", ReelBot.Style.REACT, 0.7],
		["hep basılı", ReelBot.Style.ALWAYS, 0.0],
		["pompa", ReelBot.Style.PUMP, 0.0],
	]
	print("Çekişme raporu (%d deneme, başlangıç 4–9 m, boy kümenin içinde eşit aralıklı; takım: %s, taşıma %d★)" % [RUNS,
			{"start": "başlangıç", "mid": "cam elyafı kamış + naylon misina", "top": "en iyi"}.get(mode, mode), gear.carry])
	for easy: bool in [false, true]:
		print("")
		print("== %s ==" % ("KOLAY" if easy else "NORMAL"))
		print("%-12s %-5s %-11s %7s %7s %7s %7s %8s %8s %8s" % ["balık", "boy", "bot", "tutar", "koparır", "kaçar",
				"bitmedi", "ort sn", "en çok", "kırmızı"])
		for f in db.fish:
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
						var start: float = DISTANCES[i % DISTANCES.size()]
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
	print("Süreler (6 m, kusursuz, Normal, 1–3★): ")
	for f in db.fish:
		var times: Array[float] = []
		for i in RUNS:
			var model := ReelModel.new(db.rules, f["fight"], gear.reel_speed, 6.0, max_distance,
					false, Dice.derive(777, i), gear, percentile_in(GROUPS[0], i, RUNS))
			var result := ReelBot.play(model, ReelBot.make(ReelBot.Style.PERFECT))
			times.append(float(result["seconds"]))
		times.sort()
		print("  %-12s en az %.1f  ortanca %.1f  en çok %.1f sn" % [f["id"], times[0], times[times.size() >> 1], times[-1]])
	quit()


## Rapor ve testlerin takımları: start (bambu olta), mid (başlangıç + cam elyafı kamış ve naylon
## misina: 4★ taşır), top (en iyi şamandıra takımı).
static func gear_for(db: ContentDB, mode: String) -> GearStats:
	match mode:
		"top":
			return GearStats.best(db)
		"mid":
			var items := db.gear_start.duplicate()
			items["rod"] = "rod_float_glass"
			items["line"] = "line_mono"
			var none: Array[String] = []
			return GearStats.from_items(db, items, none)
	return GearStats.starter(db)


## Kümenin i. denemesinin boy yüzdeliği: kümenin içinde eşit aralıklı.
static func percentile_in(group: Array, i: int, runs: int) -> int:
	var low := int(group[1])
	var high := int(group[2])
	return low + int(float(high - low) * (float(i) + 0.5) / runs)
