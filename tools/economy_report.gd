extends SceneTree
## Ekonomi ve ilerleme raporu: denge botu (SessionSim) birkaç seed'le oynar; rütbelerin, takım
## alımlarının ve türlerin ilk görüldüğü dakikaları (belli vakitte gelen efsaneler dahil), saatlik
## para ve av sayısını, Dede'nin isteklerini (biten, para, değiştirme), Gölün Sırrı'nı (mektuplar, altın
## istekler, harita parçaları, altın hamur, final hazır, Gölün Bekçisi), akvaryumun bağış kutusunu (Dalga 5: toplanan
## para, kazançtaki payı, sondaki saatlik bağış ve tür sayısı), Tekir'in yediği balıkları, kıyafetlerin açıldığı
## dakikaları (outfit:<kimlik>), bölgelerde, tekniklerde, vakitlerde ve havalarda geçen zamanı yazar.
##   godot --headless --path . -s res://tools/economy_report.gd [-- --hours=8 --seeds=3] [--ads]
## --ads: her seed reklamsız ve reklam izleyen oyuncuyla (SessionSim.ads; A3) iki kez oynanır; rapor reklamlı
## oyuncunun saatlik parasını, reklamla gelen payı, saatte izlenen reklamları ve önemli olayların dakikalarını
## reklamsızla karşılaştırır.
## Hedefler docs/gdd.md §8, §10.4 ve §11'de; korkuluklar tests/test_session_sim.gd'de.

var _hours: float = 8.0
var _seeds: int = 3
var _ads: bool = false
## Reklamlı karşılaştırmada dakikası yazılan olaylar (ilerlemenin hızı: reklam izleyen ne kadar erken varır).
const AD_KEYS: Array[String] = ["buy:boat", "rank_5", "rank_9", "rank_13", "tech:bottom", "tech:fly", "final_ready",
		"keeper"]


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--hours="):
			_hours = float(arg.substr(8))
		elif arg.begins_with("--seeds="):
			_seeds = int(arg.substr(8))
		elif arg == "--ads":
			_ads = true
	var db := ContentDB.load_default()
	for e in db.errors:
		printerr("İçerik hatası: " + e)
	var sims: Array[SessionSim] = []
	var started := Time.get_ticks_msec()
	for s in _seeds:
		var sim := SessionSim.new(db, db.main_spot, 1000 + s * 77)
		sim.run(_hours * 60.0)
		sims.append(sim)
	if _ads:
		_report_ads(db, sims)
		quit()
		return
	print("Ekonomi raporu: %s, %d seed, %.0f saat oyun (hesap %.1f sn)" % [db.main_spot, _seeds, _hours,
			(Time.get_ticks_msec() - started) / 1000.0])
	for sim in sims:
		var hours := sim.elapsed / 3600.0
		print("  seed %d: %d atış, %d av, %d kaçan, %d satış, %d para kazanıldı (saatte %.0f para, %.0f av), rütbe %d, tuzaktan %d kerevit (%d tuzak), %d bırakılan, %d çöp, göl sevgisi %d (seviye %d), %d istek (saatte %.1f; %d para, kazançta payı %%%.1f; %d değiştirme), %d mektup, %d parça, altın hamur %s, Bekçi %d, akvaryum %d para (kazançta payı %%%.1f; sonunda saatte %d, %d/%d tür), Tekir %d balık" % [
				sim.rng.seed, sim.casts, sim.catches, sim.lost, sim.sells, sim.earned, sim.earned / hours,
				sim.catches / hours, Rank.rank(db, sim.save), sim.trapped, sim.save.traps.size(), sim.released, sim.trash,
				sim.save.love, LakeLove.level(db.rules, sim.save.love), sim.requests_done, sim.requests_done / hours,
				sim.request_coins, 100.0 * sim.request_coins / maxf(1.0, sim.earned), sim.rerolls, sim.save.letters,
				sim.save.map_pieces, "var" if Secret.has_dough(sim.save) else "yok", sim.save.keeper, sim.aquarium_coins,
				100.0 * sim.aquarium_coins / maxf(1.0, sim.earned), Aquarium.rate_ph(db, sim.save),
				Aquarium.fish(db, sim.save).size(), Aquarium.capacity(db), sim.cat_meals])
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
	keys.append("aquarium")
	keys.append("cat")
	keys.append("trap_set")
	keys.append("trap")
	keys.append("release")
	keys.append("trash")
	for level in range(2, LakeLove.max_level(db.rules) + 1):
		keys.append("love_%d" % level)
	keys.append("requests")
	keys.append("request_1")
	keys.append("requests_10")
	# Gölün Sırrı (5. adım): mektuplar, altın istekler (geldi, parça), altın hamur, final hazır; final (6. adım):
	# Gölün Bekçisi göle döndü.
	for n in range(1, Secret.LETTERS.size() + 1):
		keys.append("letter_%d" % n)
	for piece in range(1, SaveData.MAX_MAP_PIECES + 1):
		keys.append("golden_%d" % piece)
		keys.append("piece_%d" % piece)
	keys.append("dough")
	keys.append("final_ready")
	keys.append("keeper")
	# Kıyafetler (Dalga 5): açıldığı dakika (satışta bakılır).
	for e in db.outfits.items:
		if str(e["unlock"]) != "start":
			keys.append("outfit:" + str(e["id"]))
	for n in range(1, db.fish.size() + 1):
		keys.append("species_%d" % n)
	for r in db.rarities:
		keys.append("rarity_" + str(r["id"]))
	# Yalnızca belli vakitte gelen türlerin ilk tutulduğu dakika (Dalga 4: Ay Turnası, Kocabaş; Bekçi yukarıda).
	for f in db.fish:
		if not (f["only"] as Dictionary).is_empty() and not bool(f.get("story", false)):
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


## Reklam izleyen oyuncu (A3): aynı seed'ler reklamlı; saatlik para, reklamın payı, saatte reklamlar, kurtarılan
## balıklar ve önemli olayların dakikaları reklamsızla yan yana.
func _report_ads(db: ContentDB, plain: Array[SessionSim]) -> void:
	var ad_sims: Array[SessionSim] = []
	for s in _seeds:
		var sim := SessionSim.new(db, db.main_spot, 1000 + s * 77)
		sim.ads = true
		sim.run(_hours * 60.0)
		ad_sims.append(sim)
	print("Reklam raporu: %s, %d seed, %.0f saat oyun (ödüllü reklam %.0f sn, geçiş %.0f sn, günlük sınır her %.0f dakikada)"
			% [db.main_spot, _seeds, _hours, SessionSim.AD_REWARDED_S, SessionSim.AD_INTERSTITIAL_S,
			SessionSim.AD_DAY_S / 60.0])
	var gain_sum := 0.0
	for i in ad_sims.size():
		var a := ad_sims[i]
		var p := plain[i]
		var ah := a.elapsed / 3600.0
		var ph := p.elapsed / 3600.0
		var gain := (a.earned / ah) / maxf(1.0, p.earned / ph) - 1.0
		gain_sum += gain
		print("  seed %d: reklamsız saatte %.0f para, reklamlı %.0f (%+.1f%%); reklamla %d para (kazançta payı %%%.1f), saatte %.1f ödüllü reklam (%d), %.1f geçiş (%d), %d kurtarılan balık; rütbe %d / %d" % [
				a.rng.seed, p.earned / ph, a.earned / ah, 100.0 * gain, a.ad_coins,
				100.0 * a.ad_coins / maxf(1.0, a.earned), a.ad_rewarded / ah, a.ad_rewarded,
				a.ad_interstitials / ah, a.ad_interstitials, a.ad_rescued, Rank.rank(db, p.save), Rank.rank(db, a.save)])
	print("  ortalama: reklamlı oyuncu saatte %+.1f%% para" % (100.0 * gain_sum / maxf(1.0, ad_sims.size())))
	print("")
	print("%-28s %s" % ["olay (dakika: reklamsız/reklamlı)", "  ".join(range(_seeds).map(func(i: int) -> String:
			return "     seed%d" % (i + 1)))])
	for key in AD_KEYS:
		var cells := PackedStringArray()
		for i in ad_sims.size():
			var p_at := "%5.0f" % float(plain[i].milestones[key]) if plain[i].milestones.has(key) else "    -"
			var a_at := "%5.0f" % float(ad_sims[i].milestones[key]) if ad_sims[i].milestones.has(key) else "    -"
			cells.append("%s/%s" % [p_at, a_at])
		print("%-28s %s" % [key, "  ".join(cells)])
	# Yer başına: ilk reklamın dakikası, saatte reklam ve reklamın parasının kazançtaki payı.
	print("")
	print("yer başına (ilk dakika · saatte reklam · kazançtaki payı %):")
	for place: String in AdRules.PLACES:
		var cells := PackedStringArray()
		for a in ad_sims:
			var first := "%5.1f" % float(a.milestones["ad:" + place]) if a.milestones.has("ad:" + place) else "    -"
			cells.append("%s · %4.1f · %4.1f" % [first, int(a.ad_count.get(place, 0)) / (a.elapsed / 3600.0),
					100.0 * int(a.ad_place_coins.get(place, 0)) / maxf(1.0, a.earned)])
		print("  %-26s %s" % [place, "  ".join(cells)])
