class_name FishingSession
extends RefCounted
## Bir balık tutma oturumu: BOŞ → ATIŞ → BEKLEME → DÜRTME → ISIRMA → ÇEKİŞME → TUTULDU / KAÇTI.
## Saf mantık (Node yok). Sunum her karede advance(delta) çağırır, olayları poll_events() ile
## alır, gölgeleri `sim.shadows`'tan okur. İç adım sabit 1/60 sn: aynı girdilerle her fps'te ve
## video kaydında aynı sonuç çıkar.
##
## Isırmaya kadarki kısım tekniğin (technique: Technique; şamandıra FloatTechnique): takımın
## nereye düştüğü, suda ne yaptığı, girdilerin anlamı, eylem düğmesi. Teknikler dürtme, ısırma,
## erken dokunuş, kaçırma ve takılma için buradaki ortak işlevleri çağırır (start_nibbling …
## hook_fish). Çekişme (ReelModel) ve sonrası her teknikte ortak.
##
## Girdiler:
## - angler: balıkçının yeri (sunum her karede yazar).
## - cast(hedef): yalnızca BOŞ durumda. Hedef karadaysa ya da menzil dışındaysa şamandıra yine
##   suya düşer; çizgide hiç su yoksa false (sunum o zaman yürür).
## - press() / release(): eylem; parmak değdiği an işler. Şamandırada beklerken oltayı geri sarar,
##   dürtmede erken sayılır, ısırmada VUR; çekişmede basılı tutunca sarar.
## - acknowledge(): yakalanan balığın kartı kapandı; yeni atış serbest.
##
## Olaylar (sözlük; "type" ve "step" alanlı):
## cast {from, to, steps} · land {pos} · scare {shadow} · notice {shadow} · arrive {shadow} ·
## nibble {shadow, index} · bite {shadow} · early {shadow, startle} · retry {shadow} (ilk av
## kaçırılınca yeniden ısıracak) · hook {shadow, fish, distance, too_big} · warn · burst · burst_end ·
## strain · strain_end · lost {reason: early | missed | snapped | escaped, too_big} ·
## catch {fish, fish_index, size_cm, stars, rarity, percentile, shadow, zone} · retrieve · idle ·
## spawn {shadow} · despawn {shadow}
##
## Bölgeli gölde gölgeler balıkçının çevresinde doğar (ShadowSim); balıkçının bölgesi zone().
## access: gölge doğabilen bölgeler (Zones.open_ids; boşsa sandalsız bütün bölgeler).

enum State { IDLE, CASTING, WAITING, NIBBLING, BITING, FIGHTING, RETRIEVING, CAUGHT, LOST }

const STEP := 1.0 / FishingRules.HZ
## Bir karede en fazla bu kadar adım (uzun bir takılmadan sonra oyun "koşmasın").
const MAX_STEPS_PER_FRAME := 30
## Çekişmede balık kıyıya bu kadar yaklaşabilir (m): şamandıra ve gölge karaya çizilmez.
const FIGHT_SHORE := 0.3

var state: State = State.IDLE
## Toplam adım (oturum saati).
var steps: int = 0
var angler := Vector2.ZERO
## Takımın (şamandıra, yem, kurşun, sinek) suyundaki yeri.
var bobber := Vector2.ZERO
var cast_from := Vector2.ZERO
var easy: bool = false
## Parmak (ya da eylem tuşu) basılı mı?
var holding: bool = false
var sim: ShadowSim
## Çekişme sürerken dolu.
var reel: ReelModel
var hooked: FishShadow
## Oltaya takılan balığın yönü (balıkçıdan şamandıraya).
var hook_dir := Vector2(0.0, -1.0)
## Çekişmede balığın hook_dir yönünde gidebileceği en uzak su (balıkçıdan uzaklık, m).
var fight_reach: float = 0.0
## Son yakalanan balık (catch olayının içeriği) ve son kaçırma nedeni.
var last_catch: Dictionary = {}
var last_loss: String = ""
## Takılan balık fazla iriyse yıldızı (takımı taşımıyor: ReelModel.excess), değilse 0. hook ve
## çekişmede kaybedilince lost olayında too_big olarak gelir (Dede eksik takımı söyler).
var too_big: int = 0
var lake: LakeShape
var rules: FishingRules
## Kuşanılmış takım (menzil, sarma, fren, misina, iğne, şamandıra, yem, kepçe).
var gear: GearStats
## Elindeki teknik (gear.technique; teknik yalnızca boştayken değişir).
var technique: Technique

# Durum sayaçları (teknikler de okur ve yazar).
## Atışta, dürtmede, geri sarmada ve kaçırmadan sonra kalan adım.
var timer: int = 0
## Takım kaç adımdır suda (gölgelerin toplanması).
var waiting_steps: int = 0
## Isırmadan beri geçen adım ve vuruş penceresi.
var bite_steps: int = 0
var window: int = 60

var _db: ContentDB
var _acc: float = 0.0
var _nibbles_left: int = 0
var _nibble_index: int = 0
var _events: Array[Dictionary] = []


## gear: kuşanılmış takım (GearStats.starter = bambu olta). seed: oturum tohumu
## (Dice.derive(kayıt seed'i, oturum sayısı)). first_catch: ilk av senaryolu olsun (oyuncu
## henüz balık tutmadı). pity_floor: şans garantisi (CatchOdds.pity_floor; -1 = yok).
func _init(db: ContentDB, spot_id: String, gear_stats: GearStats, seed: int, easy_mode: bool,
		first_catch: bool, pity_floor: int = -1, access: PackedStringArray = PackedStringArray()) -> void:
	_db = db
	rules = db.rules
	gear = gear_stats if gear_stats != null else GearStats.starter(db)
	var spot := db.spot(spot_id)
	lake = db.lake(spot_id)
	angler = spot.get("start", Vector2.ZERO)
	easy = easy_mode
	var odds := { "attract": gear.attract, "pity_floor": pity_floor, "reach": gear.range_m }
	if not access.is_empty():
		odds["open"] = access
	sim = ShadowSim.new(db, spot, lake, seed, first_catch, angler, odds)
	technique = Techniques.make(gear.technique, rules)
	sim.set_rig(technique.rig)


## Gerçek zamanı sabit adımlara çevirir.
func advance(delta: float) -> void:
	_acc = minf(_acc + maxf(delta, 0.0), STEP * MAX_STEPS_PER_FRAME)
	while _acc >= STEP - 0.000001:
		_acc -= STEP
		step()


## Tek bir sabit adım (1/60 sn). Testler doğrudan çağırabilir.
func step() -> void:
	steps += 1
	match state:
		State.CASTING:
			timer -= 1
			if timer <= 0:
				technique.land(self)
		State.WAITING, State.NIBBLING, State.BITING:
			technique.step(self)
		State.FIGHTING:
			_step_fight()
		State.RETRIEVING, State.LOST:
			timer -= 1
			if timer <= 0:
				_to_idle()
	var listening := technique.listening(self)
	for e in sim.step(angler, bobber, listening, waiting_steps):
		if str(e["type"]) != "arrive":
			push_event(e)
			continue
		var s := sim.find(int(e["shadow"]))
		if s == null:
			continue
		technique.on_arrive(self, s, e)


func poll_events() -> Array[Dictionary]:
	var out := _events
	_events = []
	return out


# --- Girdiler --------------------------------------------------------------------------

func cast(target: Vector2) -> bool:
	if state != State.IDLE:
		return false
	var point := technique.landing_point(self, target)
	if not Dice.is_point(point) or angler.distance_to(point) < technique.min_cast(self):
		return false
	cast_from = angler
	bobber = point
	var dist := angler.distance_to(point)
	timer = maxi(1, FishingRules.to_steps(rules.flight_base + rules.flight_per_m * dist))
	state = State.CASTING
	push_event({ "type": "cast", "from": angler, "to": point, "steps": timer })
	return true


func press() -> void:
	holding = true
	if state == State.FIGHTING:
		reel.holding = true
	else:
		technique.press(self)


func release() -> void:
	holding = false
	if state == State.FIGHTING:
		reel.holding = false
	else:
		technique.release(self)


func acknowledge() -> void:
	if state == State.CAUGHT:
		_to_idle()


# --- Sunum için sorgular ---------------------------------------------------------------

## Olta suda mı (ekranın her yeri eylem düğmesi)?
func line_out() -> bool:
	return state in [State.CASTING, State.WAITING, State.NIBBLING, State.BITING, State.FIGHTING]


## Eylem düğmesinin şu anki işi: cast, retrieve, wait (dürtme: dokunma!), hook, reel ya da "".
func action_kind() -> String:
	match state:
		State.IDLE:
			return "cast"
		State.FIGHTING:
			return "reel"
	return technique.action_kind(self)


## Çekişmede balığın yeri (balıkçıdan hook_dir yönünde, reel.distance uzakta; suyun bittiği
## yerin ötesine çizilmez).
func fight_point() -> Vector2:
	if reel == null:
		return bobber
	return angler + hook_dir * minf(reel.distance, fight_reach)


func range_m() -> float:
	return gear.range_m


## Takım değişti (dükkân, takım çantası): menzil ve sarma sonraki atıştan, yemin çekimi sonraki
## gölgeden geçerli. Teknik değiştiyse (yalnızca boştayken; değilse boşa dönünce) gölgeler yeni
## tekniğin oranıyla yeniden doğar: defterin gösterdiği oran gerçek oran kalır.
func set_gear(gear_stats: GearStats) -> void:
	gear = gear_stats
	sim.set_reach(gear.range_m)
	sim.set_odds({ "attract": gear.attract, "pity_floor": sim.pity_floor })
	if state == State.IDLE:
		_apply_technique()


## Gölge doğabilen bölgeler değişti (rütbe atladı, sandala binildi ya da inildi).
func set_access(open: PackedStringArray) -> void:
	sim.set_access(open)


## Balıkçı başka yere geçti (harita, sandal): yalnızca boştayken; gölgeler yeni yerin çevresinde.
func relocate(p: Vector2) -> void:
	angler = p
	for e in sim.relocate(p):
		push_event(e)


## Balıkçının avlandığı bölge (sıra): bölgeli gölde gölgelerin doğduğu bölge (ShadowSim.player_zone:
## durduğu yerin bölgesi, kapalıysa yakındaki açık bölge); tek bölgeli gölde durduğu yerinki.
func zone() -> int:
	return sim.player_zone if lake.zone_ids.size() > 1 else lake.zone_at(angler)


## Balıkçının bölgesinin kimliği (bölgesiz yerde boş).
func zone_id() -> String:
	var k := zone()
	return lake.zone_ids[k] if k >= 0 and k < lake.zone_ids.size() else ""


## Şans garantisi değişti (bir balık tutuldu).
func set_pity_floor(floor: int) -> void:
	sim.pity_floor = floor


func state_name() -> String:
	return str(State.find_key(state)).to_lower()


func seconds() -> float:
	return float(steps) / FishingRules.HZ


# --- Tekniklerin ortak işlevleri -------------------------------------------------------

func push_event(e: Dictionary) -> void:
	e["step"] = steps
	_events.append(e)


## Takım suya değdi: bekleme başlar.
func land_rig() -> void:
	state = State.WAITING
	waiting_steps = 0
	push_event({ "type": "land", "pos": bobber })


## Olta geri sarılır (yaklaşan balık ilgisini kaybeder).
func retrieve() -> void:
	if sim.approacher != null:
		sim.lose_interest(sim.approacher)
	state = State.RETRIEVING
	timer = maxi(1, rules.retrieve_steps)
	push_event({ "type": "retrieve" })


## Yaklaşan balık takıma vardı: dürtmeler (tekniğin sayısıyla) başlar.
func start_nibbling() -> void:
	var s := sim.approacher
	state = State.NIBBLING
	_nibbles_left = 0 if s.scripted else technique.roll_nibbles(s.rng)
	_nibble_index = 0
	timer = technique.roll_gap(s.rng)


## Sıradaki dürtme; dürtme kalmadıysa ısırma (vuruş penceresi açılır).
func next_nibble() -> void:
	var s := sim.approacher
	if _nibbles_left > 0:
		_nibbles_left -= 1
		_nibble_index += 1
		push_event({ "type": technique.nibble_event(), "shadow": s.id, "index": _nibble_index })
		timer = technique.roll_gap(s.rng)
	else:
		state = State.BITING
		bite_steps = 0
		window = technique.window(self, s)
		push_event({ "type": technique.bite_event(), "shadow": s.id })


## Dürtmede (ısırmadan önce) dokunuş: balık irkilir ya da kaçar.
func early() -> void:
	var s := sim.approacher
	if BiteRules.early_outcome(easy, s.scripted, s.startles) == "startle":
		s.startles += 1
		# İlk av sözünü tutar: sık sık dokunan çocuk da ısırmayı görsün (sayaç baştan başlamaz).
		if not s.scripted:
			timer = technique.roll_gap(s.rng)
		push_event({ "type": "early", "shadow": s.id, "startle": true })
		return
	push_event({ "type": "early", "shadow": s.id, "startle": false })
	sim.flee(s, bobber)
	lose("early")


## Vuruş penceresi kaçtı: balık gider (ilk av gitmez, yeniden ısırır).
func missed() -> void:
	var s := sim.approacher
	if s.scripted:
		# İlk av: balık gitmez, biraz sonra yeniden ısırır.
		state = State.NIBBLING
		_nibbles_left = 0
		timer = technique.roll_gap(s.rng)
		push_event({ "type": "retry", "shadow": s.id })
		return
	sim.flee(s, bobber)
	lose("missed")


## Yaklaşan balık oltaya takıldı: çekişme başlar.
func hook_fish() -> void:
	var s := sim.approacher
	hooked = s
	sim.hook(s)
	var offset := bobber - angler
	hook_dir = offset.normalized() if offset.length_squared() > 0.0001 else Vector2(0.0, -1.0)
	var dist := offset.length()
	var fight: Dictionary = _db.fish_def(s.fish_index)["fight"]
	# Balık kıyıya kadar kaçabilir; ama şamandıranın en az kaçma payı ötesine (kıyı yakınsa
	# çizimi kıyıda durur), en çok menzil + kaçma payına. İğne kaçma payını büyütür.
	var extra := rules.escape_extra + gear.escape_extra
	var cap := range_m() + extra
	fight_reach = _water_reach(dist, cap)
	# Senaryolu ilk balık hiçbir zaman fazla iri sayılmaz (boyu çekişmeye girmez).
	reel = ReelModel.new(rules, fight, gear.reel_speed, dist,
			clampf(fight_reach, minf(dist + extra, cap), cap), easy or s.scripted, Dice.derive(s.seed, 1), gear,
			0 if s.scripted else s.percentile)
	reel.holding = holding
	too_big = s.stars if reel.excess > 0 else 0
	state = State.FIGHTING
	push_event({ "type": "hook", "shadow": s.id, "fish": s.fish_id, "distance": dist, "too_big": too_big })


## Balık kaçtı ya da misina koptu: kısa bir beklemeden sonra boşa döner.
func lose(reason: String) -> void:
	state = State.LOST
	timer = maxi(1, rules.lost_steps)
	last_loss = reason
	reel = null
	push_event({ "type": "lost", "reason": reason, "too_big": too_big })
	too_big = 0


# --- İç işler ----------------------------------------------------------------------

## Balıkçıdan hook_dir yönünde, from_dist'ten dışarı doğru suyun sürdüğü en uzak uzaklık
## (kıyıdan FIGHT_SHORE payıyla, en çok cap).
func _water_reach(from_dist: float, cap: float) -> float:
	var d := from_dist
	while d + 0.1 <= cap:
		var p := angler + hook_dir * (d + 0.1)
		if not lake.is_water(p) or lake.on_dock(p) or lake.shore_distance(p) < FIGHT_SHORE:
			break
		d += 0.1
	return d


func _step_fight() -> void:
	for what in reel.step():
		match what:
			"caught":
				_caught()
				return
			"snap":
				_fight_lost("snapped")
				return
			"escaped":
				_fight_lost("escaped")
				return
			_:
				push_event({ "type": what })
	hooked.pos = fight_point()


func _caught() -> void:
	var s := hooked
	last_catch = {
		"fish": s.fish_id, "fish_index": s.fish_index, "size_cm": s.size_cm, "stars": s.stars,
		"rarity": s.rarity, "percentile": s.percentile, "shadow": s.id,
		"zone": lake.zone_ids[s.zone] if s.zone >= 0 and s.zone < lake.zone_ids.size() else "",
	}
	sim.remove(s)
	hooked = null
	reel = null
	too_big = 0
	state = State.CAUGHT
	var e := last_catch.duplicate()
	e["type"] = "catch"
	push_event(e)


func _fight_lost(reason: String) -> void:
	hooked.pos = _water_near(fight_point())
	sim.flee(hooked, angler)
	hooked = null
	lose(reason)


## p karadaysa (balıkçı kıyıdan geriye, balık kıyının ötesine kaçtı) şamandıraya doğru ilk su noktası.
func _water_near(p: Vector2) -> Vector2:
	var count := maxi(1, ceili(p.distance_to(bobber) / 0.1))
	for i in count + 1:
		var q := p.lerp(bobber, float(i) / count)
		if lake.is_water(q):
			return q
	return bobber


func _to_idle() -> void:
	state = State.IDLE
	push_event({ "type": "idle" })
	_apply_technique()


## Takımın tekniği elindekinden farklıysa (boştayken) değiştirir: gölgeler yeni tekniğin
## profiliyle fark eder ve yeni oranla, balıkçının çevresinde yeniden doğar.
func _apply_technique() -> void:
	if Techniques.resolve(gear.technique) == technique.id:
		return
	technique = Techniques.make(gear.technique, rules)
	sim.set_rig(technique.rig)
	relocate(angler)
