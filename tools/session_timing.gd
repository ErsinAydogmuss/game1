extends SceneTree
## Gerçek oturum süreleri: FishingSession'ı oyuncu gibi oynayan bir botla oynar, süreleri ölçer ve
## data/sim.json için önerilen değerleri yazar. Denge botu (SessionSim) zamanı bu dosyadan alır;
## kurallar (gölge, fark etme, dürtme) değişince bu araç yeniden çalıştırılır.
##   godot --headless --path . -s res://tools/session_timing.gd [-- --casts=600 --seeds=3 --gear=top --zone=reeds
##       --technique=spin] (sinek: -- --technique=fly --zone=stream_mouth)
## --zone: balıkçı o bölgenin atış noktasında (sandal bölgesinde ilk şamandıranın yanında, sandalda)
## durur; gölgeler yalnızca o bölgede doğar (denge botu bölge başına süre kullanır: sim.json "zones").
## --technique: o teknikle (tekniğin ilk kamışı; --gear=top en iyi takımı) oynar; öneri sim.json
## "techniques" altına (tekniğin bölgeleri de: --zone ile).
## Bot (şamandıra):
## - Nişan (AIM_S) alır; menzildeki en yakın gölgenin önüne (LEAD_M) atar, insan gibi şaşarak
##   (AIM_NOISE_M yarıçaplı daire içinde); gölge yoksa rastgele suya.
## - Bekler; gelen balık yokken sabrı (PATIENCE_S) biterse geri sarar ve yeniden atar.
## - Dürtmede dokunmaz; ısırmadan REACTION_S sonra VUR; çekişmede ReelBot REACT (aynı tepki).
## - Kartsız yakalamada oyunun beklediği kadar (main QUICK_CATCH_TIME) bekler.
## Spin: gölgenin ötesine (SPIN_PAST_M) atar, basılı tutup yemi getirir (yem gölgenin önünden geçer);
## balık peşine düşünce dur-kalk yapar (evreler RHYTHM_S aralığında); saldırı bırakılmışken olduysa
## REACTION_S sonra VUR. Yem gelince (ya da takılınca) atış kendiliğinden biter. Burada "geliş"
## balığın peşine düşmesi, "dürtme" izlemesi, "ısırma" saldırısıdır.
## Dip: en yakın gölgenin yönüne atar (takım menzilin sonuna düşer), BOTTOM_PATIENCE_S bekler;
## koklamada (zil tek tük) dokunmaz, koşuda (zil durmadan) REACTION_S sonra VUR.
## Balıkçı başlangıç yerinde (iskelenin ucu) durur. Bot ısırmayı hiç kaçırmaz; insan hatası
## sim.json'da ayrıca (miss_ppm).

const AIM_S := 1.2
const LEAD_M := 1.2
const AIM_NOISE_M := 1.0
const PATIENCE_S := 15.0
const REACTION_S := 0.45
const SHOW_S := 1.3
## Spin: gölgenin ne kadar ötesine atılır (m) ve dur-kalk evrelerinin süresi (sn).
const SPIN_PAST_M := 2.5
const RHYTHM_S := Vector2(0.35, 0.8)
## Dip: gelen balık yokken bu kadar sn sonra geri sarar (dip sabır ister).
const BOTTOM_PATIENCE_S := 30.0
## Sinek: gölgenin akıntı yukarısına (FLY_UP_M) atar, sinek ona doğru sürüklensin; sinek kendiliğinden
## döndüğü için geri sarmaz (sabır en uzun sürüklenmeden uzun); halkada REACTION_S sonra VUR.
const FLY_UP_M := 2.5
const FLY_PATIENCE_S := 20.0

var _casts: int = 600
var _seeds: int = 3
var _top: bool = false
var _zone: String = ""
var _technique: String = "float"

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
		elif arg.begins_with("--gear="):
			printerr("Bilinmeyen takım: %s (yalnızca --gear=top; verilmezse başlangıç takımı)" % arg.substr(7))
			quit(1)
			return
		elif arg.begins_with("--zone="):
			_zone = arg.substr(7)
		elif arg.begins_with("--technique="):
			_technique = arg.substr(12)
	var db := ContentDB.load_default()
	for e in db.errors:
		printerr("İçerik hatası: " + e)
	var problem := _check_args(db)
	if not problem.is_empty():
		printerr(problem)
		quit(1)
		return
	var gear := _gear(db)
	var started := Time.get_ticks_msec()
	for s in _seeds:
		_play(db, gear, 5000 + s * 31)
	print("Oturum süreleri: %s%s, %s, %d seed × %d atış, takım: %s (hesap %.1f sn)" % [db.main_spot,
			"" if _zone.is_empty() else " / " + _zone, _technique, _seeds, _casts, "en iyi" if _top else "başlangıç",
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
	if _technique == "spin":
		print("  yem geldi %d, takıldı %d, vazgeçen %d, kendiliğinden takılan %d" % [_count("home"), _count("snag"),
				_count("turn_away"), _count("auto")])
	print("  saatte %.0f av (satış ve kart hariç, kartsız gösteri dahil)" % (_count("catch") / hours))
	if _to_bite.is_empty() or _fight.is_empty():
		printerr("Isırma ya da çekişme ölçülmedi: öneri yok (atış sayısını artır).")
		quit(1)
		return
	# Önerilen sim.json: atış = nişan + ortalama uçuş; dürtme ve yaklaşma tekdüze aralık
	# [p10, 2·ort − p10] (ortalaması ölçülen ortalamaya eşit). Balığın uzaklığı menzili aşamaz (dipte
	# takım menzilin sonuna düşer: çoğu ölçüm tam menzilde, aralık menzilde kesilir).
	var cast_s := AIM_S + _mean(_flight)
	var approach: Array[float] = []
	for i in _to_bite.size():
		approach.append(_to_bite[i] - _nibble[i] - cast_s)
	var where := ""
	if _technique != "float":
		where = "techniques.%s" % _technique + ("" if _zone.is_empty() else ".zones.%s" % _zone)
	elif not _zone.is_empty():
		where = "zones.%s" % _zone
	print("")
	print("  önerilen data/sim.json%s:" % ("" if where.is_empty() else " (%s)" % where))
	print("    \"cast_s\": %.1f," % cast_s)
	print("    \"approach_s\": %s," % _uniform(approach))
	print("    \"nibble_s\": %s," % _uniform(_nibble))
	print("    \"show_s\": %.1f," % SHOW_S)
	print("    \"start_m\": %s," % _uniform(_hook_m, gear.range_m))
	print("    \"fight_s\": %.1f," % _mean(_fight))
	print("    \"reaction_s\": %.2f" % REACTION_S)
	quit()


## Seçenekler oyunun içeriğiyle uyumlu mu: bilinen teknik ve bölge, teknik o bölgede (bölge yoksa
## başlangıç bölgesinde) avlanılır. Sorun yoksa boş.
func _check_args(db: ContentDB) -> String:
	if not _technique in ContentDB.TECHNIQUES or not db.has_technique(_technique):
		return "Bilinmeyen teknik: %s" % _technique
	var z: Dictionary = Zones.at(db, db.main_spot, db.spot(db.main_spot)["start"])
	if not _zone.is_empty():
		z = db.zone(db.main_spot, _zone)
		if z.is_empty():
			return "Bilinmeyen bölge: %s" % _zone
	if not z.is_empty() and not CatchOdds.allows(z, _technique):
		return "%s bölgesinde %s ile avlanılmaz (sinek: --zone=stream_mouth)" % [z["id"], _technique]
	return ""


## Ölçülen tekniğin takımı: tekniğin ilk (en ucuz) kamışı ve başlangıç takımı; --gear=top en iyisi.
func _gear(db: ContentDB) -> GearStats:
	if _top:
		return GearStats.best(db, _technique)
	if _technique == "float":
		return GearStats.starter(db)
	var rod: Dictionary = {}
	for g in db.rods_of(_technique):
		if rod.is_empty() or int(g["price"]) < int(rod["price"]):
			rod = g
	var none: Array[String] = []
	return GearStats.from_items(db, { "rod": str(rod["id"]) }, none)


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
	var spin := _technique == "spin"
	var bottom := _technique == "bottom"
	var fly := _technique == "fly"
	if bottom:
		patience = FishingRules.to_steps(BOTTOM_PATIENCE_S)
	if fly:
		patience = FishingRules.to_steps(FLY_PATIENCE_S)
	var phase_end := 0
	while casts < _casts:
		match session.state:
			FishingSession.State.IDLE:
				cooldown -= 1
				if cooldown <= 0:
					var target := _spin_point(session, rng) if spin else (_fly_point(session, rng) if fly else _aim_point(session, rng))
					if session.cast(target):
						casts += 1
					cooldown = aim
			FishingSession.State.WAITING:
				if spin:
					# Yem hep oynar (basılı): yırtıcı fark etsin, otlu yerde takılmasın.
					if not session.holding:
						session.press()
				elif session.sim.approacher == null and session.steps - landed_at >= patience:
					session.press()
					session.release()
					_add("retrieve")
			FishingSession.State.FOLLOWING:
				# Dur-kalk: evre bitince bırak ya da bas.
				if session.steps >= phase_end:
					if session.holding:
						session.release()
					else:
						session.press()
					phase_end = session.steps + FishingRules.to_steps(rng.randf_range(RHYTHM_S.x, RHYTHM_S.y))
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
				"arrive", "follow":
					# Spinde "arrive" peşine düşmeden önceki varıştır; geliş "follow".
					if kind == "follow" or not spin:
						arrive_at = session.steps
						_wait.append(_sec(arrive_at - landed_at))
						phase_end = session.steps + FishingRules.to_steps(rng.randf_range(RHYTHM_S.x, RHYTHM_S.y))
				"bite", "strike", "run", "rise":
					bite_at = session.steps
					_add("bite")
					if bool(e.get("auto", false)):
						_add("auto")
					_nibble.append(_sec(bite_at - arrive_at))
					_to_bite.append(_sec(bite_at - cycle_start))
					cycle_open = false
				"turn_away":
					_add("turn_away")
				"retrieve":
					if e.has("reason"):
						_add(str(e["reason"]))
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


## Spin: menzildeki en yakın dolaşan gölgenin ötesi (yem gelirken gölgenin önünden geçer); yoksa
## rastgele bir yön.
func _spin_point(session: FishingSession, rng: RandomNumberGenerator) -> Vector2:
	var best: FishShadow = null
	var best_d := INF
	for s in session.sim.shadows:
		if s.mode != FishShadow.Mode.WANDER and s.mode != FishShadow.Mode.PAUSE:
			continue
		var d := session.angler.distance_to(s.pos)
		if d < session.technique.min_cast(session) or d > session.range_m():
			continue
		if d < best_d:
			best = s
			best_d = d
	if best != null:
		var away := (best.pos - session.angler).normalized()
		return best.pos + away * SPIN_PAST_M + Dice.in_disc(rng, AIM_NOISE_M)
	return session.angler + Dice.direction(rng) * rng.randf_range(4.0, session.range_m())


## Sinek: menzildeki en yakın dolaşan gölgenin akıntı yukarısı (sinek ona doğru sürüklenir); yoksa
## rastgele, akıntılı bir yer.
func _fly_point(session: FishingSession, rng: RandomNumberGenerator) -> Vector2:
	var best: FishShadow = null
	var best_d := INF
	for s in session.sim.shadows:
		if s.mode != FishShadow.Mode.WANDER and s.mode != FishShadow.Mode.PAUSE:
			continue
		var d := session.angler.distance_to(s.pos)
		if d < session.technique.min_cast(session) or d > session.range_m():
			continue
		if d < best_d:
			best = s
			best_d = d
	if best != null:
		var down := session.lake.flow_at(best.pos).normalized()
		return best.pos - down * FLY_UP_M + Dice.in_disc(rng, AIM_NOISE_M)
	for i in 12:
		var p := session.angler + Dice.direction(rng) * rng.randf_range(3.0, session.range_m())
		if session.lake.flow_at(p).length() > 0.3:
			return p
	return session.angler + Dice.direction(rng) * rng.randf_range(3.0, session.range_m())


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
	if values.is_empty():
		return 0.0
	var sorted := values.duplicate()
	sorted.sort()
	return float(sorted[clampi(int(q * (sorted.size() - 1)), 0, sorted.size() - 1)])


## Tekdüze aralık [p10, 2·ort − p10], en çok cap.
func _uniform(values: Array[float], cap: float = INF) -> String:
	var lo := minf(maxf(0.0, _pct(values, 0.1)), cap)
	var hi := minf(maxf(lo, 2.0 * _mean(values) - lo), cap)
	return "[%.1f, %.1f]" % [lo, hi]
