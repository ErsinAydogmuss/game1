class_name BossPresenter
extends Node
## Bölge canavarlarının karşılaşması (yapı 5; Bosses, docs/gdd.md §10.9). Balıkçı bir bölgede o bölgenin etkili
## tekniğiyle ve canavarın istediği takımın hepsiyle (ya da daha iyisiyle) atınca (Bosses.ready) her atışta zar atılır
## (Bosses.roll: kaydın atış sayısıyla); tutarsa takım canavara ayrılır (FishingSession.reserve: öteki balıklar yemi
## kapmaz), takım RISE_DELAY sn bekleyince canavar takımın çevresinde belirir (Bosses.rise_point; FishingSession.summon):
## altın halkalar, "sting", titreşim, bildirim ve Dede'nin sözü. Dalışın uyarısında ve dalışta altın halka, ses,
## titreşim, sarsıntı (ipucu main'de: UI_HINT_BOSS_DIVE). Kaçarsa RETURN_TIME sn sonra sıradaki atışta zarsız yine gelir
## (Dede söyler). Balıkçı bölgeden ayrılır ya da tekniği değiştirirse dolaşan canavar sessizce çekilir. Gölün
## Bekçisi'nin gecesinde (Secret.keeper_due) canavar çıkmaz. main kurar (setup), her oyun karesinde KeeperPresenter'dan
## sonra update eder, oturumun olaylarını on_event ile iletir. Süreler update'in delta'sıyla.

## Dede'nin sözü (main ipucu çubuğunda söyler; değerler: canavarın adı).
signal speak(key: String, args: Array)

## Takım suya düştükten (takım bekliyor) bu kadar sn sonra canavar belirir.
const RISE_DELAY := 1.4
## Kaçan canavar bu kadar sn sonra (sıradaki atışta zarsız) yine gelir.
const RETURN_TIME := Bosses.RETURN_S
## Belirişin ve dalışın halkaları: (gecikme sn, yarıçap m, ömür sn).
const RISE_RINGS: Array[Vector3] = [Vector3(0.0, 1.8, 1.5), Vector3(0.3, 2.6, 1.8), Vector3(0.7, 3.4, 2.0)]
const DIVE_RINGS: Array[Vector3] = [Vector3(0.0, 1.4, 1.1), Vector3(0.25, 2.2, 1.4)]
const GOLD := Color(1.0, 0.86, 0.42, 0.85)

var db: ContentDB
var spot_id: String
var ripples: Ripples
var camera: FollowCamera
var hud: Hud

## Bu atışın zarı atıldı mı (atış sayısı; -1: henüz yok) ve tuttu mu.
var _rolled_cast: int = -1
var _rising: bool = false
## Takım kaç sn'dir bekliyor (canavar belirmeden önce).
var _waiting: float = 0.0
## Kaçan canavar: yeniden gelmesine kalan süre (sn) ve kimliği (süre bitince sıradaki atışta zarsız).
var _return_wait: float = 0.0
var _back: String = ""
## Oltadaki balık canavar mı (kimliği; değilse "").
var _fighting: String = ""
## Göldeki canavarın kimliği ve bölgesi (çekilme denetimi).
var _present: String = ""
## Bekleyen halkalar: [kalan sn, nokta (Vector2), yarıçap, ömür].
var _rings: Array = []
## Botlar (scripts/dev/autoplay.gd) canavarı yalnızca boss senaryosunda açar: eski senaryoların atışları kaymasın.
var enabled: bool = true


func setup(content: ContentDB, spot: String, rings: Ripples, view: FollowCamera, overlay: Hud) -> void:
	db = content
	spot_id = spot
	ripples = rings
	camera = view
	hud = overlay


## Yeni oturum (oyunun açılışı, kayıt değişti).
func reset() -> void:
	_rolled_cast = -1
	_rising = false
	_waiting = 0.0
	_return_wait = 0.0
	_back = ""
	_fighting = ""
	_present = ""
	_rings.clear()


## Göldeki ya da oltadaki canavar (kimliği; yoksa "").
func present() -> String:
	return _fighting if not _fighting.is_empty() else _present


## Oltadaki balık canavar mı (ipucu)?
func fighting() -> bool:
	return not _fighting.is_empty()


## Her oyun karesi (KeeperPresenter.update'ten sonra). keeper_due: Gölün Bekçisi'nin vakti (o gece X'te canavar
## çıkmaz).
func update(delta: float, session: FishingSession, save: SaveData, keeper_due: bool) -> void:
	_step_rings(delta)
	if not enabled:
		return
	if _return_wait > 0.0:
		_return_wait = maxf(0.0, _return_wait - delta)
	var zone_id := session.zone_id()
	var technique := session.technique.id
	var boss := db.boss_of(zone_id)
	var ready := not keeper_due and Bosses.ready(db, save, spot_id, zone_id, technique, session.gear)
	# Dolaşan canavar: balıkçı bölgeden ayrıldı, tekniği ya da takımı değişti, Bekçi'nin vakti: sessizce çekilir.
	var summoned := session.summoned()
	if not _present.is_empty() and summoned != null and summoned.fish_id == _present and _fighting.is_empty() \
			and (not ready or _present != boss):
		session.dismiss_summoned()
	summoned = session.summoned()
	# Kaçan (uzaklaşan) canavar gölde sayılmaz: geri dönüşü yeni çağrıyla (eskisini kaldırır).
	_present = "" if summoned == null or summoned.mode == FishShadow.Mode.FLEE or not summoned.fish_id in Bosses.IDS \
			else summoned.fish_id
	if session.state != FishingSession.State.WAITING:
		_waiting = 0.0
		if session.state == FishingSession.State.IDLE:
			_rising = false
		return
	if not ready or not _present.is_empty():
		_rising = false
		return
	# Takım suda: bu atışın zarı bir kez; kaçan canavar süresi dolunca zarsız döner (atış sürerken de).
	if _back == boss:
		_rising = _return_wait <= 0.0
	elif _rolled_cast != save.casts:
		_rolled_cast = save.casts
		_rising = Bosses.roll(save, save.casts)
		_waiting = 0.0
	if not _rising:
		return
	# Takım canavara ayrılır: belirmeden önce yakındaki bir balık yemi kapmasın.
	session.reserve(true)
	_waiting += delta
	if _waiting >= RISE_DELAY and _rise(session, save, boss):
		_rising = false
		_waiting = 0.0


## Oturumun olayı (main _on_event'ten).
func on_event(e: Dictionary, session: FishingSession) -> void:
	match str(e["type"]):
		"hook":
			var hooked := session.hooked
			_fighting = hooked.fish_id if hooked != null and hooked.summoned and hooked.fish_id in Bosses.IDS else ""
		"dive_warn":
			if not _fighting.is_empty():
				ripples.spawn(session.fight_point(), 1.2, 0.9, GOLD, 0.12)
				Sounds.play("warn", 0.0, 0.8)
				Sounds.haptic(40)
				camera.shake(0.04)
		"dive":
			if not _fighting.is_empty():
				_queue_rings(session.fight_point(), DIVE_RINGS)
				Sounds.play("dive")
				Sounds.haptic(100)
				camera.shake(0.12)
		"dive_end":
			if not _fighting.is_empty():
				ripples.spawn(session.fight_point(), 0.9, 0.7, Color(GOLD, 0.6), 0.1)
				Sounds.haptic(15)
		"lost":
			if not _fighting.is_empty():
				_back = _fighting
				_return_wait = RETURN_TIME
				_fighting = ""
				_present = ""
				speak.emit("UI_DEDE_BOSS_LOST", [])
		"catch":
			if not _fighting.is_empty():
				_back = ""
				_return_wait = 0.0
			_fighting = ""
			_present = ""


## Canavar belirir: takımın çevresinde, bölgenin derin suyunda. Belirdiyse true (yer yoksa false: sonraki karede).
func _rise(session: FishingSession, save: SaveData, boss: String) -> bool:
	var point := Bosses.rise_point(db, spot_id, session.angler, session.bobber)
	if not Dice.is_point(point) or session.summon(boss, point, Bosses.PERCENTILE) < 0:
		return false
	_present = boss
	var again := _back == boss
	_back = ""
	_queue_rings(point, RISE_RINGS)
	Sounds.play("sting")
	Sounds.haptic(60)
	camera.shake(0.05)
	var name := tr("FISH_" + boss)
	hud.toast(tr("UI_BOSS_RISE") % name, UiKit.rarity_color(db, db.rarity_index("legendary")),
			UiKit.rarity_icon(db, db.rarity_index("legendary")))
	var seen_flag := "boss_seen_" + boss
	if again:
		speak.emit("UI_DEDE_BOSS_BACK", [name])
	elif not save.flags.has(seen_flag):
		save.flags[seen_flag] = true
		speak.emit("UI_DEDE_BOSS_RISE", [name])
	else:
		speak.emit("UI_DEDE_BOSS_AGAIN", [name])
	return true


func _queue_rings(at: Vector2, rings: Array[Vector3]) -> void:
	for r in rings:
		_rings.append([r.x, at, r.y, r.z])


func _step_rings(delta: float) -> void:
	for i in range(_rings.size() - 1, -1, -1):
		var ring: Array = _rings[i]
		ring[0] = float(ring[0]) - delta
		if float(ring[0]) <= 0.0:
			ripples.spawn(ring[1], float(ring[2]), float(ring[3]), GOLD, 0.14)
			_rings.remove_at(i)
