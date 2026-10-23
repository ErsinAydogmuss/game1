class_name KeeperPresenter
extends Node
## Gölün Bekçisi'nin karşılaşması (Dalga 4, final; docs/gdd.md §10.5). Sisli gecede sandal haritanın X'indeyken
## (derin ortanın Secret.KEEPER_BUOY şamandırası), elde dip ve altın hamur varken kurşun suya düşüp RISE_DELAY
## beklenince Bekçi çağrılır (Secret.keeper_due, keeper_point; FishingSession.summon): turkuaz halkalar, "sting",
## titreşim, bildirim, Dede'nin sözü ve Bekçi'nin müziği (presence_changed: main müziği değiştirir). O gece X'te
## takım Bekçi'nin (FishingSession.reserve): o belirmeden ya da kaçıp dönmeden öteki balıklar yemi kapmaz. Dalışın
## uyarısında ve dalışta turkuaz halka, sarsıntı, ses ve titreşim (ipucu main'de: UI_HINT_KEEPER_DIVE). Kaçarsa
## RETURN_TIME sn sonra yine gelir (Dede söyler; o arada sabah olursa gelmez, Dede söyler); sabah olunca gider
## (Dede söyler). Gece X'ten ayrılınca (kıyıya, başka şamandıraya, başka tekniğe) dolaşan Bekçi sessizce çekilir,
## dönünce yine belirir. Aynı gece kaçtıktan sonra yeniden belirince Dede "geri geldi" der. X'te dip kamışı elde
## değilse ya da final
## gecesi henüz gelmediyse Dede ne yapılacağını söyler (oturum başına bir kez). main kurar (setup), her oyun
## karesinde update eder (filmde, kararmada, panel açıkken ve odak kaybında etmez), oturumun olaylarını on_event
## ile iletir.
## Süreler update'in delta'sıyla (oyun saati gibi).

## Dede'nin sözü (main ipucu çubuğunda söyler).
signal speak(key: String)
## Bekçi gölde ya da oltada mı (main müziği Bekçi'ninkine geçirir).
signal presence_changed(present: bool)

## Kurşun suya düştükten (takım bekliyor) bu kadar sn sonra Bekçi belirir.
const RISE_DELAY := 1.6
## Kaçarsa (misina koptu, kaçtı) bu kadar sn sonra yine gelir (denge botu da bekler).
const RETURN_TIME := Secret.KEEPER_RETURN_S
## Belirişin halkaları: (gecikme sn, yarıçap m, ömür sn); dalışınkiler.
const RISE_RINGS: Array[Vector3] = [Vector3(0.0, 2.4, 1.8), Vector3(0.35, 3.4, 2.0), Vector3(0.8, 4.4, 2.3)]
const DIVE_RINGS: Array[Vector3] = [Vector3(0.0, 1.8, 1.2), Vector3(0.25, 2.8, 1.5), Vector3(0.55, 3.8, 1.8)]
const TURQUOISE := Color(0.62, 1.0, 0.95, 0.85)

var db: ContentDB
var spot_id: String
var ripples: Ripples
var camera: FollowCamera
var hud: Hud

var _present: bool = false
## Takım kaç sn'dir bekliyor (Bekçi belirmeden önce).
var _waiting: float = 0.0
## Bekçi kaçtı: yeniden gelmesine kalan süre (sn).
var _return_wait: float = 0.0
## Oltadaki balık Bekçi mi?
var _fighting: bool = false
## Bu gece Bekçi oltadan kaçtı: yeniden belirince Dede "geri geldi" der (X'ten ayrılıp dönünce değil).
var _lost_tonight: bool = false
## Son karede Bekçi'nin vakti miydi (Secret.keeper_due): kaçan Bekçi ancak öyleyse geri gelir.
var _due: bool = false
## Bu oturumda söylendi: X'te dip kamışı elde değil; final gecesi ama gece değil.
var _told_bottom: bool = false
var _told_wait: bool = false
## Bekleyen halkalar: [kalan sn, nokta (Vector2), yarıçap, ömür].
var _rings: Array = []


func setup(content: ContentDB, spot: String, rings: Ripples, view: FollowCamera, overlay: Hud) -> void:
	db = content
	spot_id = spot
	ripples = rings
	camera = view
	hud = overlay


## Yeni oturum (oyunun açılışı, kayıt değişti): sayaçlar ve sözler baştan.
func reset() -> void:
	_waiting = 0.0
	_return_wait = 0.0
	_fighting = false
	_lost_tonight = false
	_due = false
	_told_bottom = false
	_told_wait = false
	_rings.clear()
	_set_present(false)


## Bekçi gölde ya da oltada mı (müzik)?
func present() -> bool:
	return _present


## Oltadaki balık Bekçi mi (ipucu, kamera)?
func fighting() -> bool:
	return _fighting


## Her oyun karesi. cond: gölün koşulu (WorldState.conditions); at_x: sandal X'te.
func update(delta: float, session: FishingSession, save: SaveData, cond: Dictionary, at_x: bool) -> void:
	_step_rings(delta)
	_return_wait = maxf(0.0, _return_wait - delta)
	var phase := str(cond.get("phase", ""))
	var weather := str(cond.get("weather", ""))
	var day := DayClock.day(db.rules, save.clock_s)
	var technique := session.technique.id
	var due := Secret.keeper_due(save, phase, weather, at_x, technique, day)
	_due = due
	# Bekçi'nin gecesinde X'te takım onun: belirmeden önce yakındaki bir balık yemi kapmasın.
	session.reserve(due)
	var keeper := session.summoned()
	if phase != "night":
		_lost_tonight = false
	if not due:
		# Sabah oldu (sis kalktı): dolaşan Bekçi derinlere döner; yaklaşan ya da oltadaki kendi sonucuyla biter.
		if keeper != null and keeper.mode != FishShadow.Mode.FLEE and session.dismiss_summoned() and phase != "night":
			speak.emit("UI_DEDE_KEEPER_GONE")
		elif keeper == null and _return_wait > 0.0 and phase != "night":
			# Kaçan Bekçi'yi beklerken sabah oldu: bu gece dönmez.
			_return_wait = 0.0
			speak.emit("UI_DEDE_KEEPER_GONE")
	# Takım RISE_DELAY sn kesintisiz bekleyince Bekçi belirir (yer yoksa sonraki karede yeniden denenir).
	if due and keeper == null and _return_wait <= 0.0 and session.state == FishingSession.State.WAITING:
		_waiting += delta
		if _waiting >= RISE_DELAY and _rise(session, save):
			_waiting = 0.0
	else:
		_waiting = 0.0
	# X'te Dede yol gösterir: altın hamur dipte işe yarar; Bekçi gece gelir (çay içip beklenebilir).
	if at_x and session.state == FishingSession.State.IDLE:
		if not _told_bottom and technique != "bottom" and Secret.keeper_due(save, phase, weather, true, "bottom", day):
			_told_bottom = true
			speak.emit("UI_DEDE_KEEPER_BOTTOM")
		elif not _told_wait and Secret.keeper_night(save) and phase != "night":
			_told_wait = true
			speak.emit("UI_DEDE_KEEPER_WAIT")
	keeper = session.summoned()
	_set_present(_fighting or (keeper != null and keeper.mode != FishShadow.Mode.FLEE))


## Oturumun olayı (main _on_event'ten).
func on_event(e: Dictionary, session: FishingSession) -> void:
	match str(e["type"]):
		"hook":
			_fighting = session.hooked != null and session.hooked.summoned
		"dive_warn":
			# Uyarı: Bekçi'nin çevresinde turkuaz halka, pes gıcırtı, titreşim (ipucu: BIRAK).
			ripples.spawn(session.fight_point(), 1.4, 1.0, TURQUOISE, 0.12)
			Sounds.play("warn", 0.0, 0.7)
			Sounds.haptic(45)
			camera.shake(0.05)
		"dive":
			_queue_rings(session.fight_point(), DIVE_RINGS)
			Sounds.play("dive")
			Sounds.haptic(120)
			camera.shake(0.16)
		"dive_end":
			ripples.spawn(session.fight_point(), 1.0, 0.8, Color(TURQUOISE, 0.6), 0.1)
			Sounds.haptic(15)
		"lost":
			if _fighting:
				_fighting = false
				if _due:
					_return_wait = RETURN_TIME
					_lost_tonight = true
					speak.emit("UI_DEDE_KEEPER_LOST")
				else:
					# Çekişirken sabah oldu: bu gece dönmez.
					speak.emit("UI_DEDE_KEEPER_GONE")
		"catch":
			_fighting = false


## Bekçi belirir: takıma karşı, sandaldan 6–9 m ötede. Belirdiyse true (yer yoksa false: sonraki karede yeniden).
func _rise(session: FishingSession, save: SaveData) -> bool:
	var point := Secret.keeper_point(db, spot_id, session.angler, session.bobber)
	if not Dice.is_point(point) or session.summon(Secret.KEEPER_ID, point, Secret.KEEPER_PERCENTILE) < 0:
		return false
	_queue_rings(point, RISE_RINGS)
	Sounds.play("sting")
	Sounds.haptic(60)
	camera.shake(0.06)
	hud.toast(tr("UI_KEEPER_RISE"), UiKit.rarity_color(db, db.rarity_index("mythic")), "rarity:medallion")
	if _lost_tonight:
		speak.emit("UI_DEDE_KEEPER_BACK")
	elif save.keeper > 0:
		speak.emit("UI_DEDE_KEEPER_AGAIN")
	else:
		speak.emit("UI_DEDE_KEEPER_RISE")
	return true


func _queue_rings(at: Vector2, rings: Array[Vector3]) -> void:
	for r in rings:
		_rings.append([r.x, at, r.y, r.z])


func _step_rings(delta: float) -> void:
	for i in range(_rings.size() - 1, -1, -1):
		var ring: Array = _rings[i]
		ring[0] = float(ring[0]) - delta
		if float(ring[0]) <= 0.0:
			ripples.spawn(ring[1], float(ring[2]), float(ring[3]), TURQUOISE, 0.14)
			_rings.remove_at(i)


func _set_present(on: bool) -> void:
	if on == _present:
		return
	_present = on
	presence_changed.emit(on)
