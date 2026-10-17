extends SceneTree
## Gerçek oturum süreleri: FishingSession'ı oyuncu gibi oynayan bir botla oynar, süreleri ölçer ve
## data/sim.json için önerilen değerleri yazar. Denge botu (SessionSim) zamanı bu dosyadan alır;
## kurallar (gölge, fark etme, dürtme) değişince bu araç yeniden çalıştırılır.
##   godot --headless --path . -s res://tools/session_timing.gd [-- --casts=600 --seeds=3 --gear=top --zone=reeds]
## --zone: balıkçı o bölgenin atış noktasında (sandal bölgesinde ilk şamandıranın yanında, sandalda)
## durur; gölgeler yalnızca o bölgede doğar (denge botu bölge başına süre kullanır: sim.json "zones").
## Bot:
## - Nişan (AIM_S) alır; menzildeki en yakın gölgenin önüne (LEAD_M) atar, insan gibi şaşarak
##   (AIM_NOISE_M yarıçaplı daire içinde); gölge yoksa rastgele suya.
## - Bekler; gelen balık yokken sabrı (PATIENCE_S) biterse geri sarar ve yeniden atar.
## - Dürtmede dokunmaz; ısırmadan REACTION_S sonra VUR; çekişmede ReelBot REACT (aynı tepki).
## - Kartsız yakalamada oyunun beklediği kadar (main QUICK_CATCH_TIME) bekler.
## Balıkçı başlangıç yerinde (iskelenin ucu) durur. Bot ısırmayı hiç kaçırmaz; insan hatası
## sim.json'da ayrıca (miss_ppm).

const AIM_S := 1.2
const LEAD_M := 1.2
const AIM_NOISE_M := 1.0
const PATIENCE_S := 15.0
const REACTION_S := 0.45
const SHOW_S := 1.3

var _casts: int = 600
var _seeds: int = 3
var _top: bool = false
var _zone: String = ""

# Ölçümler (sn): uçuş, şamandıra suya düştükten balık gelene kadar, dürtmeler, hazır olmaktan
# ısırmaya (nişan, atış, geri sarıp yeniden atış dahil), çekişme; takılan balığın uzaklığı (m).
var _flight: Array[float] = []
var _wait: Array[float] = []
var _nibble: Array[float] = []
var _to_bite: Array[float] = []
var _fight: Array[float] = []
var _hook_m: Array[float] = []
var _counts := {}
var _total_s: float = 0.0


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--casts="):
			_casts = int(arg.substr(8))
		elif arg.begins_with("--seeds="):
			_seeds = int(arg.substr(8))
		elif arg == "--gear=top":
			_top = true
		elif arg.begins_with("--zone="):
			_zone = arg.substr(7)
	var db := ContentDB.load_default()
	for e in db.errors:
		printerr("İçerik hatası: " + e)
	var gear := GearStats.best(db) if _top else GearStats.starter(db)
	var started := Time.get_ticks_msec()
	for s in _seeds:
		_play(db, gear, 5000 + s * 31)
	print("Oturum süreleri: %s%s, %d seed × %d atış, takım: %s (hesap %.1f sn)" % [db.main_spot,
			"" if _zone.is_empty() else " / " + _zone, _seeds, _casts, "en iyi" if _top else "başlangıç",
			(Time.get_ticks_msec() - started) / 1000.0])
	print("  %-34s %6s %6s %6s %6s %6s" % ["", "adet", "ort", "p10", "p50", "p90"])
	_row("atış uçuşu", _flight)
	_row("suya düşüşten balığın gelişine", _wait)
	_row("dürtmeler (gelişten ısırmaya)", _nibble)
	_row("hazırdan ısırmaya (her şey dahil)", _to_bite)
	_row("çekişme", _fight)
	_row("takılan balığın uzaklığı (m)", _hook_m)
	var hours := _total_s / 3600.0
	print("")
	print("  atış %d, geri sarma %d, korkan gölge %d, ısırma %d" % [_count("cast"), _count("retrieve"),
			_count("scare"), _count("bite")])
	print("  tutulan %d, koptu %d, kaçtı %d, kaçırılan %d, erken %d" % [_count("catch"), _count("snapped"),
			_count("escaped"), _count("missed"), _count("early")])
	print("  saatte %.0f av (satış ve kart hariç, kartsız gösteri dahil)" % (_count("catch") / hours))
	# Önerilen sim.json: atış = nişan + ortalama uçuş; dürtme ve yaklaşma tekdüze aralık
	# [p10, 2·ort − p10] (ortalaması ölçülen ortalamaya eşit).
	var cast_s := AIM_S + _mean(_flight)
	var approach: Array[float] = []
	for i in _to_bite.size():
		approach.append(_to_bite[i] - _nibble[i] - cast_s)
	print("")
	print("  önerilen data/sim.json:")
	print("    \"cast_s\": %.1f," % cast_s)
	print("    \"approach_s\": %s," % _uniform(approach))
	print("    \"nibble_s\": %s," % _uniform(_nibble))
	print("    \"show_s\": %.1f," % SHOW_S)
	print("    \"start_m\": %s," % _uniform(_hook_m))
	print("    \"reaction_s\": %.2f" % REACTION_S)
	quit()


func _play(db: ContentDB, gear: GearStats, seed_value: int) -> void:
	var session := FishingSession.new(db, db.main_spot, gear, seed_value, false, false)
	if not _zone.is_empty():
		var z := db.zone(db.main_spot, _zone)
		var stands: Array[Vector2] = z["stands"]
		var buoys: Array[Vector2] = z["buoys"]
		var at: Vector2 = stands[0] if not stands.is_empty() else buoys[0] + LakeScene.BUOY_MOOR
		session.set_access(PackedStringArray([_zone]))
		session.relocate(at)
		session.poll_events()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var aim := FishingRules.to_steps(AIM_S)
	var patience := FishingRules.to_steps(PATIENCE_S)
	var reaction := FishingRules.to_steps(REACTION_S)
	var show := FishingRules.to_steps(SHOW_S)
	var cooldown := aim
	var cast_at := 0
	var landed_at := 0
	var arrive_at := 0
	var bite_at := -1
	var hook_at := 0
	var caught_at := 0
	var cycle_start := 0
	var cycle_open := true
	var bot: ReelBot = null
	var reel_events := PackedStringArray()
	var casts := 0
	while casts < _casts:
		match session.state:
			FishingSession.State.IDLE:
				cooldown -= 1
				if cooldown <= 0:
					if session.cast(_aim_point(session, rng)):
						casts += 1
					cooldown = aim
			FishingSession.State.WAITING:
				if session.sim.approacher == null and session.steps - landed_at >= patience:
					session.press()
					session.release()
					_add("retrieve")
			FishingSession.State.BITING:
				if bite_at >= 0 and session.steps - bite_at >= reaction:
					session.press()
			FishingSession.State.FIGHTING:
				var hold := bot.decide(session.reel, reel_events)
				if hold and not session.holding:
					session.press()
				elif not hold and session.holding:
					session.release()
			FishingSession.State.CAUGHT:
				if session.steps - caught_at >= show:
					session.acknowledge()
		session.step()
		reel_events = PackedStringArray()
		for e in session.poll_events():
			var kind := str(e["type"])
			match kind:
				"cast":
					cast_at = session.steps
					_add("cast")
				"land":
					landed_at = session.steps
					_flight.append(_sec(landed_at - cast_at))
				"scare":
					_add("scare")
				"arrive":
					arrive_at = session.steps
					_wait.append(_sec(arrive_at - landed_at))
				"bite":
					bite_at = session.steps
					_add("bite")
					_nibble.append(_sec(bite_at - arrive_at))
					_to_bite.append(_sec(bite_at - cycle_start))
					cycle_open = false
				"hook":
					hook_at = session.steps
					bite_at = -1
					_hook_m.append(float(e["distance"]))
					bot = ReelBot.make(ReelBot.Style.REACT, REACTION_S)
				"catch":
					caught_at = session.steps
					_add("catch")
					_fight.append(_sec(caught_at - hook_at))
				"lost":
					var reason := str(e["reason"])
					_add(reason)
					bite_at = -1
					if reason == "snapped" or reason == "escaped":
						_fight.append(_sec(session.steps - hook_at))
				"idle":
					cooldown = aim
					if not cycle_open:
						cycle_start = session.steps
						cycle_open = true
				_:
					reel_events.append(kind)
	_total_s += session.seconds()


## Menzildeki (en az min_cast uzaktaki) en yakın dolaşan gölgenin önü; yoksa rastgele bir yön.
func _aim_point(session: FishingSession, rng: RandomNumberGenerator) -> Vector2:
	var best: FishShadow = null
	var best_d := INF
	for s in session.sim.shadows:
		if s.mode != FishShadow.Mode.WANDER and s.mode != FishShadow.Mode.PAUSE:
			continue
		var d := session.angler.distance_to(s.pos)
		if d < session.rules.min_cast or d > session.range_m():
			continue
		if d < best_d:
			best = s
			best_d = d
	if best != null:
		return best.pos + best.heading * LEAD_M + Dice.in_disc(rng, AIM_NOISE_M)
	return session.angler + Dice.direction(rng) * rng.randf_range(3.0, session.range_m())


func _add(key: String) -> void:
	_counts[key] = int(_counts.get(key, 0)) + 1


func _count(key: String) -> int:
	return int(_counts.get(key, 0))


func _sec(steps: int) -> float:
	return float(steps) / FishingRules.HZ


func _row(label: String, values: Array[float]) -> void:
	if values.is_empty():
		print("  %-34s %6d" % [label, 0])
		return
	print("  %-34s %6d %6.1f %6.1f %6.1f %6.1f" % [label, values.size(), _mean(values), _pct(values, 0.1),
			_pct(values, 0.5), _pct(values, 0.9)])


func _mean(values: Array[float]) -> float:
	if values.is_empty():
		return 0.0
	var total := 0.0
	for v in values:
		total += v
	return total / values.size()


func _pct(values: Array[float], q: float) -> float:
	var sorted := values.duplicate()
	sorted.sort()
	return float(sorted[clampi(int(q * (sorted.size() - 1)), 0, sorted.size() - 1)])


func _uniform(values: Array[float]) -> String:
	var lo := maxf(0.0, _pct(values, 0.1))
	var hi := maxf(lo, 2.0 * _mean(values) - lo)
	return "[%.1f, %.1f]" % [lo, hi]
