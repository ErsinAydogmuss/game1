extends SceneTree
## Ekonomi ve ilerleme raporu: denge botu (SessionSim) birkaç seed'le oynar; rütbelerin, takım
## alımlarının ve türlerin ilk görüldüğü dakikaları (belli vakitte gelen efsaneler dahil), saatlik
## para ve av sayısını, bölgelerde, tekniklerde, vakitlerde ve havalarda geçen zamanı yazar.
##   godot --headless --path . -s res://tools/economy_report.gd [-- --hours=8 --seeds=3]
## Hedefler docs/gdd.md §8 ve §10.4'te; korkuluklar tests/test_session_sim.gd'de.

var _hours: float = 8.0
var _seeds: int = 3


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--hours="):
			_hours = float(arg.substr(8))
		elif arg.begins_with("--seeds="):
			_seeds = int(arg.substr(8))
	var db := ContentDB.load_default()
	for e in db.errors:
		printerr("İçerik hatası: " + e)
	var sims: Array[SessionSim] = []
	var started := Time.get_ticks_msec()
	for s in _seeds:
		var sim := SessionSim.new(db, db.main_spot, 1000 + s * 77)
		sim.run(_hours * 60.0)
		sims.append(sim)
	print("Ekonomi raporu: %s, %d seed, %.0f saat oyun (hesap %.1f sn)" % [db.main_spot, _seeds, _hours,
			(Time.get_ticks_msec() - started) / 1000.0])
	for sim in sims:
		var hours := sim.elapsed / 3600.0
		print("  seed %d: %d atış, %d av, %d kaçan, %d satış, %d para kazanıldı (saatte %.0f para, %.0f av), rütbe %d, tuzaktan %d kerevit (%d tuzak)" % [
				sim.rng.seed, sim.casts, sim.catches, sim.lost, sim.sells, sim.earned, sim.earned / hours,
				sim.catches / hours, Rank.rank(db, sim.save), sim.trapped, sim.save.traps.size()])
	print("")
	print("%-28s %s" % ["olay (ilk kez, dakika)", "  ".join(range(_seeds).map(func(i: int) -> String: return "seed%d" % (i + 1)))])
	var keys: Array[String] = []
	for r in range(2, db.max_rank() + 1):
		keys.append("rank_%d" % r)
	for z in db.zones_of(db.main_spot):
		keys.append("zone:" + str(z["id"]))
	for t: String in ContentDB.TECHNIQUES:
		if t != "float" and db.has_technique(t):
			keys.append("tech:" + t)
	keys.append("buy")
	for g in db.gear:
		if int(g["price"]) > 0 and str(g["category"]) != "bait":
			keys.append("buy:" + str(g["id"]))
	keys.append("sell")
	keys.append("trap_set")
	keys.append("trap")
	for n in range(1, db.fish.size() + 1):
		keys.append("species_%d" % n)
	for r in db.rarities:
		keys.append("rarity_" + str(r["id"]))
	# Yalnızca belli vakitte gelen türlerin ilk tutulduğu dakika (Dalga 4: Ay Turnası, Kocabaş).
	for f in db.fish:
		if not (f["only"] as Dictionary).is_empty():
			keys.append("fish:" + str(f["id"]))
	for key in keys:
		var cells := PackedStringArray()
		for sim in sims:
			cells.append("%5.1f" % float(sim.milestones[key]) if sim.milestones.has(key) else "    -")
		print("%-28s %s" % [key, "  ".join(cells)])
	# Bölgeli göl: zamanın bölgelere dağılımı (atış ve çekişme; satış ve yol hariç).
	if db.zones_of(db.main_spot).size() > 1:
		print("")
		print("bölgelerde geçen zaman (%):")
		for z in db.zones_of(db.main_spot):
			var id := str(z["id"])
			var cells := PackedStringArray()
			for sim in sims:
				var total := 0.0
				for k: String in sim.zone_time:
					total += float(sim.zone_time[k])
				cells.append("%5.1f" % (100.0 * float(sim.zone_time.get(id, 0.0)) / maxf(total, 1.0)))
			print("  %-26s %s" % [id, "  ".join(cells)])
	# Tekniklerde geçen zaman (atış ve çekişme).
	print("")
	print("tekniklerde geçen zaman (%):")
	for t: String in ContentDB.TECHNIQUES:
		if not db.has_technique(t):
			continue
		var cells := PackedStringArray()
		for sim in sims:
			var total := 0.0
			for k: String in sim.technique_time:
				total += float(sim.technique_time[k])
			cells.append("%5.1f" % (100.0 * float(sim.technique_time.get(t, 0.0)) / maxf(total, 1.0)))
		print("  %-26s %s" % [t, "  ".join(cells)])
	# Vakitlerde ve havalarda geçen zaman (atış ve çekişme; Dalga 4): saat dükkânda ve takım çantasında
	# durur, günün havası zarla.
	for part: Array in [["vakitlerde", DayClock.PHASES, "phase_time"], ["havalarda", Weather.KINDS, "weather_time"]]:
		print("")
		print("%s geçen zaman (%%):" % part[0])
		for name: String in part[1]:
			var cells := PackedStringArray()
			for sim in sims:
				var spent: Dictionary = sim.get(str(part[2]))
				var total := 0.0
				for k: String in spent:
					total += float(spent[k])
				cells.append("%5.1f" % (100.0 * float(spent.get(name, 0.0)) / maxf(total, 1.0)))
			print("  %-26s %s" % [name, "  ".join(cells)])
	quit()
