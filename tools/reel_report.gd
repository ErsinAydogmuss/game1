extends SceneTree
## Çekişme denge raporu: her balık, her bot tarzı ve mod için yakalama, kopma, kaçma oranları ve
## süreler. Sayılar data/fish.json ve data/rules.json'dan gelir.
##   godot --headless --path . -s res://tools/reel_report.gd
##   godot --headless --path . -s res://tools/reel_report.gd -- --gear=top   (en iyi şamandıra takımı)
## Hedefler (docs/gdd.md §5): iyi oyuncu (kusursuz, 0,4 sn) her balığı tutar; Kızılkanat 4–7 sn,
## Yayın 14–20 sn; hep basılı tutan Normal'de koparır, Kolay'da tutar.

const RUNS := 200
## Başlangıç uzaklıkları (m): atışların çoğu bu aralıkta.
const DISTANCES := [4.0, 5.0, 6.0, 7.0, 8.0, 9.0]


func _initialize() -> void:
	var db := ContentDB.load_default()
	for e in db.errors:
		printerr("İçerik hatası: " + e)
	var top := "--gear=top" in OS.get_cmdline_user_args()
	var gear := GearStats.best(db) if top else GearStats.starter(db)
	var max_distance: float = gear.range_m + db.rules.escape_extra + gear.escape_extra
	var bots := [
		["kusursuz", ReelBot.Style.PERFECT, 0.0],
		["tepki 0,4", ReelBot.Style.REACT, 0.4],
		["tepki 0,7", ReelBot.Style.REACT, 0.7],
		["hep basılı", ReelBot.Style.ALWAYS, 0.0],
	]
	print("Çekişme raporu (%d deneme, başlangıç 4–9 m; süre: 6 m'den kusursuz oyuncu; takım: %s)" % [RUNS,
			"en iyi" if top else "başlangıç"])
	for easy: bool in [false, true]:
		print("")
		print("== %s ==" % ("KOLAY" if easy else "NORMAL"))
		print("%-8s %-11s %7s %7s %7s %8s %8s %8s" % ["balık", "bot", "tutar", "koparır", "kaçar", "ort sn", "en çok", "kırmızı"])
		for f in db.fish:
			for b: Array in bots:
				var caught := 0
				var snapped := 0
				var escaped := 0
				var total_s := 0.0
				var max_s := 0.0
				var red := 0.0
				for i in RUNS:
					var start: float = DISTANCES[i % DISTANCES.size()]
					var model := ReelModel.new(db.rules, f["fight"], gear.reel_speed, start,
							max_distance, easy, Dice.derive(4242, i), gear)
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
				print("%-8s %-11s %6.0f%% %6.0f%% %6.0f%% %8.1f %8.1f %8.2f" % [f["id"], b[0],
						100.0 * caught / RUNS, 100.0 * snapped / RUNS, 100.0 * escaped / RUNS,
						total_s / maxi(1, caught), max_s, red / RUNS])
	print("")
	print("Süreler (6 m, kusursuz, Normal): ")
	for f in db.fish:
		var times: Array[float] = []
		for i in RUNS:
			var model := ReelModel.new(db.rules, f["fight"], gear.reel_speed, 6.0, max_distance,
					false, Dice.derive(777, i), gear)
			var result := ReelBot.play(model, ReelBot.make(ReelBot.Style.PERFECT))
			times.append(float(result["seconds"]))
		times.sort()
		print("  %-8s en az %.1f  ortanca %.1f  en çok %.1f sn" % [f["id"], times[0], times[times.size() >> 1], times[-1]])
	quit()
