class_name ShadowSim
extends RefCounted
## Göldeki balık gölgeleri: doğma, dolaşma, duraklama, fark etme, yaklaşma, kaçma ve yeniden
## doğma. Aynı anda en fazla max_shadows gölge; eksilenin yerine respawn aralığında yenisi
## gelir. Aynı anda yalnızca bir balık yaklaşır (approacher). Her adım 1/60 sn.
## Gölgeler yalnızca derin suda (min_depth) dolaşır ve iskelenin altına girmez. Yaklaşırken sığa
## ya da iskelenin dibine sokulan balık (oyuncu geri sarınca) yeniden derine yüzer.
##
## Bölgeli göl (Dalga 2, birden çok bölge): gölgeler balıkçının yakınında (menzil + reach_extra)
## ve yalnızca balıkçının avlandığı bölgede (player_zone) doğar: defter ve dükkânın gösterdiği oran
## gelen balığın gerçek oranıdır (gelir kuralı 10). Zarlar aynı: tür ve boy ayrı tuzlu zarlardan.
## Kapalı bölgede (rütbe, sandal) gölge doğmaz; gölge dolaşırken kendi bölgesinde kalır,
## şamandıraya yaklaşırken sınırı geçebilir. Balıkçıdan çok uzakta kalan ya da balıkçı başka
## bölgeye geçince öteki bölgede kalan gölge çekilir, yenisi yakında doğar. Şans garantisi de
## avlanılan bölgede doğar. Balıkçı sandaldaysa (suyun üstünde) gölgeler sandaldan BOAT_CLEAR
## uzakta dolaşır: sandalın altına girmez (şamandıraya yaklaşan ve kaçan gölge girebilir). Tek
## bölgeli göl (eski şema) bugünkü gibi çalışır (altın test).
##
## Hikâye balığı (Gölün Bekçisi; summon): sunumun çağırdığı tek gölge. Göldeyken takımı yalnızca o fark eder
## (senaryolu ilk av gibi; öteki gölgeler süs olarak dolaşır), korkmaz, vazgeçmez, evinin çevresinde dolaşır;
## bölgesinden, balıkçıdan uzaklığından ve gölün koşulundan çekilmez. Gölgelerin sayısına girmez, gidince
## yerine yenisi doğmaz; kimliği ve zarı ayrı (SUMMON_ID, SUMMON_SALT): öteki gölgelerin zarı kaymaz.

const STEP := 1.0 / FishingRules.HZ
## Önü kapalıysa denenecek sapma açıları (radyan): kıyı boyunca kayar.
const DETOURS := [0.5, -0.5, 1.0, -1.0, 1.5, -1.5]
## Sığda kalan balığın derine dönüş yolu iskeleden bu kadar uzak olmalı (m).
const STRANDED_DOCK := 0.3
## Sandaldaki balıkçıdan dolaşan gölgenin uzak kaldığı mesafe (m).
const BOAT_CLEAR := 2.0
## Balıkçının durduğu yerin bölgesi kapalıysa (kilitli bölgenin çitinin önü) açık bölge bu
## yarıçaplarda (m) halka halka aranır.
const FISHING_SEARCH: Array[float] = [1.0, 2.0, 3.0, 4.5, 6.0, 8.0]
## Çağrılan gölgelerin kimlikleri buradan başlar (dolaşan gölgelerin sırası kaymaz) ve zarının tuzu.
const SUMMON_ID := 1 << 30
const SUMMON_SALT := 9091
## Çağrılan gölge evinin bu yarıçapında (m) dolaşır.
const SUMMON_ROAM := 3.0

var shadows: Array[FishShadow] = []
## Şamandıraya yaklaşan (ya da dürten) gölge.
var approacher: FishShadow = null
## Şans garantisi: yakında doğan sıradaki gölge en az bu nadirlikte (-1 = garanti yok). Aynı
## anda yalnızca bir garanti gölgesi olur.
var pity_floor: int = -1
## Takım hikâye balığına ayrıldı (Gölün Bekçisi'nin gecesi, X'te dip; sunum verir: FishingSession.reserve):
## dolaşan gölgeler takımı fark etmez ve ona toplanmaz; çağrılan gölge belirince yalnızca o gelir. Bekçi
## belirmeden önce (KeeperPresenter.RISE_DELAY) ya da kaçtıktan sonra dönene kadar yakındaki bir balık yemi
## kapmasın. Varsayılanı kapalı (altın test).
var reserved: bool = false
## Takım profili (tekniğin fark etme, yaklaşma, vazgeçme ve toplanma sayıları; FishingSession
## verir). Varsayılanı şamandıranınki.
var rig: TechniqueRules

var _db: ContentDB
var _rules: FishingRules
var _lake: LakeShape
var _spot: Dictionary
var _seed: int = 0
var _serial: int = 0
## Çağrılan gölgelerin sırası (summon).
var _summons: int = 0
var _max: int = 4
## Bekleyen doğumlar: her biri için kalan adım.
var _pending := PackedInt32Array()
## Sıradaki gölge ilk av mı (senaryolu)?
var _first_pending: bool = false
## Türlerin oranları (CatchOdds.species_ppm).
var _species: Dictionary = {}
## Balıkçının avlandığı bölge (sıra): durduğu yerin bölgesi (ızgaranın dışında en yakın hücreninki;
## sandalda altındaki suyunki); o bölge kapalıysa en yakın açık bölge (_fishing_zone). Bölgeli
## gölde gölgeler ve şans garantisi yalnızca burada doğar; yoksa -1 (bütün açık bölgeler).
var player_zone: int = -1
## Bölgeli göl mü (birden çok bölge)?
var _zoned: bool = false
var _zones: Array[Dictionary] = []
## Bölge başına tür oranları ve gölge doğup doğamayacağı.
var _zone_species: Array[Dictionary] = []
var _open := PackedByteArray()
## Gölgelerin doğduğu yarıçap (menzil + reach_extra) ve balıkçının son yeri.
var _reach: float = 10.0
var _angler := Vector2.ZERO
## Balıkçı suyun üstünde mi (sandalda)?
var _afloat: bool = false
var _check: int = 0


## odds: { "attract": yemin tür çekimi, "pity_floor": şans garantisi } (CatchOdds); bölgeli gölde
## ayrıca "reach": menzil (m) ve "open": gölge doğabilen bölgeler (verilmezse sandalsız bütün
## bölgeler).
func _init(db: ContentDB, spot: Dictionary, lake: LakeShape, seed: int, first_catch: bool,
		angler: Vector2, odds: Dictionary = {}) -> void:
	_db = db
	_rules = db.rules
	rig = _rules.technique("float")
	_lake = lake
	_spot = spot
	_seed = seed
	_max = int(spot.get("max_shadows", 4))
	_first_pending = first_catch
	var zones: Variant = spot.get("zones")
	if zones is Array:
		_zones.assign(zones)
	_zoned = _zones.size() > 1
	_angler = angler
	_afloat = _zoned and _in_boat(angler)
	set_reach(float(odds.get("reach", 8.0)))
	if odds.has("open"):
		set_access(odds["open"])
	else:
		var open := PackedStringArray()
		for z in _zones:
			if not bool(z["boat"]):
				open.append(str(z["id"]))
		set_access(open)
	player_zone = _fishing_zone(angler) if _zoned else lake.zone_at(angler)
	set_odds(odds)
	for i in _max:
		# Yer bulunamazsa bir sn sonra yeniden denenir (küçük göllerde).
		if _spawn(angler, Vector2.ZERO, false) == null:
			_pending.append(FishingRules.HZ)


## Bir adım. listening: şamandıra suda ve balık bekliyor (fark etme açık).
## waiting_steps: şamandıra kaç adımdır suda. Olayları döndürür (spawn, despawn, notice, arrive).
func step(angler: Vector2, bobber: Vector2, listening: bool, waiting_steps: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	if _zoned:
		_follow(angler)
	for i in range(_pending.size() - 1, -1, -1):
		_pending[i] -= 1
		if _pending[i] <= 0:
			_pending.remove_at(i)
			var born := _spawn(angler, bobber, listening)
			if born != null:
				out.append({ "type": "spawn", "shadow": born.id })
			else:
				_pending.append(FishingRules.HZ)
	for s: FishShadow in shadows.duplicate():
		match s.mode:
			FishShadow.Mode.WANDER:
				_wander(s)
			FishShadow.Mode.PAUSE:
				s.timer -= 1
				if s.timer <= 0:
					_pick_target(s, bobber, listening, waiting_steps)
			FishShadow.Mode.APPROACH:
				s.timer += 1
				if _approach(s, bobber):
					s.mode = FishShadow.Mode.NIBBLE
					out.append({ "type": "arrive", "shadow": s.id })
				elif not (s.scripted or s.summoned) and s.timer > rig.give_up_steps:
					lose_interest(s)
					# Aynı adımda yeniden fark edip aynı kapalı yola girmesin.
					s.bored = true
			FishShadow.Mode.NIBBLE:
				# Şamandırada takım durur, balık da (izleme hızı 0); spinde yemin peşinden gelir.
				if rig.follow_speed > 0.0:
					_follow_rig(s, bobber)
			FishShadow.Mode.FLEE:
				_flee_step(s)
				s.timer -= 1
				if s.timer <= 0:
					remove(s)
					out.append({ "type": "despawn", "shadow": s.id })
	if listening and approacher == null:
		# İlk av (ya da çağrılan hikâye balığı) gölde oldukça şamandıraya yalnızca o gelir; takım hikâye balığına
		# ayrıldıysa da (reserved) öteki gölgeler gelmez.
		var only_scripted := reserved or _has_scripted()
		var best: FishShadow = null
		var best_d := INF
		for s in shadows:
			if s.mode != FishShadow.Mode.WANDER and s.mode != FishShadow.Mode.PAUSE:
				continue
			if only_scripted and not (s.scripted or s.summoned):
				continue
			if s.bored:
				continue
			if not (s.scripted or s.summoned or BiteRules.notices_in(s, bobber, rig.notice_front, rig.notice_side,
					rig.notice_cos)):
				continue
			var d := s.pos.distance_squared_to(bobber)
			if d < best_d:
				best = s
				best_d = d
		if best != null:
			approacher = best
			best.mode = FishShadow.Mode.APPROACH
			best.timer = 0
			out.append({ "type": "notice", "shadow": best.id })
	return out


## Şamandıra point'e düştü: yakındaki gölgeler korkup kaçar (ilk av ve hikâye balığı korkmaz). Vazgeçmiş
## balıklar yeni şamandırayı yeniden fark edebilir. stealth: misinanın görünmezliği.
func scare(point: Vector2, stealth: float = 0.0) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for s in shadows:
		s.bored = false
		if s.scripted or s.summoned or s.mode == FishShadow.Mode.FLEE or s.mode == FishShadow.Mode.HOOKED:
			continue
		if BiteRules.scares(s, point, _rules, stealth):
			flee(s, point)
			out.append({ "type": "scare", "shadow": s.id })
	return out


## Gölge from'dan uzağa kaçar, sonra kaybolur.
func flee(s: FishShadow, from: Vector2) -> void:
	var away := s.pos - from
	s.heading = away.normalized() if away.length_squared() > 0.0001 else -s.heading
	s.mode = FishShadow.Mode.FLEE
	s.timer = _rules.flee_steps
	if approacher == s:
		approacher = null


## Takımın kokusu yayıldı (dip): dolaşan ve duraklayan gölgeler yolculuğunu bitirmeden hemen yeni
## hedef seçer (toplanma zarıyla, kendi zarından). Şamandırada çağrılmaz; takım hikâye balığına ayrıldıysa
## kimse toplanmaz (reserved).
func call_to_rig(bobber: Vector2, waiting_steps: int) -> void:
	if reserved:
		return
	for s in shadows:
		if s.scripted or s.summoned or s == approacher or s.bored:
			continue
		if s.mode == FishShadow.Mode.WANDER or s.mode == FishShadow.Mode.PAUSE:
			_pick_target(s, bobber, true, waiting_steps)


## Takım sudan çıktı (geri sarma, kaçma) ya da balık takıldı: takıma toplanan gölgeler yine olağan
## hızla dolaşır (gidecekleri yer değişmez; zar atılmaz; şamandırada kimse toplanmaz).
func end_gather() -> void:
	for s in shadows:
		s.gathering = false


## Yaklaşan balık ilgisini kaybeder (oyuncu oltayı geri sardı).
func lose_interest(s: FishShadow) -> void:
	s.mode = FishShadow.Mode.PAUSE
	s.timer = Dice.between(s.rng, _rules.pause_steps)
	if approacher == s:
		approacher = null


## Balık oltaya takıldı: çekişme bitene kadar sim onu yönetmez.
func hook(s: FishShadow) -> void:
	s.mode = FishShadow.Mode.HOOKED
	if approacher == s:
		approacher = null


## Gölgeyi gölden çıkarır (tutuldu ya da kaçtı) ve yerine yenisinin doğmasını planlar (çağrılan gölgenin
## yerine doğmaz: sayıya girmiyordu).
func remove(s: FishShadow) -> void:
	shadows.erase(s)
	if approacher == s:
		approacher = null
	if not s.summoned:
		_pending.append(Dice.between(s.rng, _rules.recycle_steps if s.recycled else _rules.respawn_steps))


## Balıkçı başka yere geçti (harita, sandal): oltadaki ve senaryolu dışındaki gölgeler (çağrılan hikâye
## balığı da) sessizce kalkar, yenileri hemen yeni yerin çevresinde doğar. Olayları döndürür (despawn, spawn).
func relocate(angler: Vector2) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	_angler = angler
	_afloat = _zoned and _in_boat(angler)
	player_zone = _fishing_zone(angler) if _zoned else _lake.zone_at(angler)
	for s: FishShadow in shadows.duplicate():
		if s.scripted or s.mode == FishShadow.Mode.HOOKED:
			continue
		shadows.erase(s)
		if approacher == s:
			approacher = null
		out.append({ "type": "despawn", "shadow": s.id })
	_pending.clear()
	while _wild_count() < _max:
		var born := _spawn(angler, Vector2.ZERO, false)
		if born == null:
			_pending.append(FishingRules.HZ)
			if _wild_count() + _pending.size() >= _max:
				break
			continue
		out.append({ "type": "spawn", "shadow": born.id })
	return out


## Teknik değişti: gölgeler takımı bu profille fark eder, ona bu hızla yaklaşır.
func set_rig(profile: TechniqueRules) -> void:
	rig = profile


## Gölgelerin doğduğu yarıçap: menzil + reach_extra (takım değişince).
func set_reach(range_m: float) -> void:
	_reach = range_m + _rules.reach_extra


## Gölge doğabilen bölgeler (rütbe ve sandal; main hesaplar). Avlanılan bölge de yenilenir.
func set_access(open: PackedStringArray) -> void:
	_open.resize(_zones.size())
	for k in _zones.size():
		_open[k] = 1 if str(_zones[k]["id"]) in open else 0
	if _zoned:
		player_zone = _fishing_zone(_angler)


## Bölgede gölge doğabilir mi?
func is_open(zone: int) -> bool:
	return zone >= 0 and zone < _open.size() and _open[zone] == 1


func find(id: int) -> FishShadow:
	for s in shadows:
		if s.id == id:
			return s
	return null


## Hikâye balığını çağırır (Gölün Bekçisi): point'te (suda) doğar, türü ve boy yüzdeliği verilir (zar yok);
## hareketi kendi zarından (SUMMON_SALT). Takıma yaklaşmakta olan öteki balık ilgisini kaybeder: yolu
## bundan sonra yalnızca onun. Gölde zaten çağrılan bir gölge varsa o kalkar. Doğamazsa (kara, bilinmeyen
## tür) null.
func summon(fish_id: String, point: Vector2, percentile: int) -> FishShadow:
	var index := _db.fish_index(fish_id)
	if index < 0 or not _lake.is_water(point):
		return null
	for old: FishShadow in shadows.duplicate():
		if old.summoned and old.mode != FishShadow.Mode.HOOKED:
			shadows.erase(old)
			if approacher == old:
				approacher = null
	var s := FishShadow.new()
	s.id = SUMMON_ID + _summons
	s.seed = Dice.derive(_seed, SUMMON_SALT, _summons)
	_summons += 1
	s.rng.seed = s.seed
	s.summoned = true
	var def := _db.fish_def(index)
	s.fish_index = index
	s.fish_id = fish_id
	s.rarity = int(def["rarity"])
	s.percentile = clampi(percentile, 0, Dice.PPM - 1)
	s.size_cm = FishTable.size_cm(def, s.percentile)
	s.stars = FishTable.stars(s.percentile)
	s.length = FishTable.shadow_length(def, s.percentile)
	s.speed = s.rng.randf_range(_rules.shadow_speed.x, _rules.shadow_speed.y)
	s.pos = point
	s.home = point
	s.zone = _lake.zone_at(point)
	s.heading = Dice.direction(s.rng)
	s.mode = FishShadow.Mode.PAUSE
	s.timer = FishingRules.HZ
	if approacher != null and approacher.mode == FishShadow.Mode.APPROACH:
		lose_interest(approacher)
	shadows.append(s)
	return s


## Göldeki çağrılan gölge (yoksa null).
func summoned_shadow() -> FishShadow:
	for s in shadows:
		if s.summoned:
			return s
	return null


## Çağrılan gölge gider (sabah oldu, sis kalktı): balıkçıdan uzağa kaçar ve kaybolur. Takıma yaklaşan,
## dürten ya da oltadaki gölgeye dokunulmaz (o iş kendi sonucuyla biter). Gittiyse true.
func dismiss_summoned() -> bool:
	var s := summoned_shadow()
	if s == null or s == approacher or s.mode == FishShadow.Mode.HOOKED or s.mode == FishShadow.Mode.FLEE:
		return false
	flee(s, _angler)
	return true


## Dolaşan gölgelerin sayısı (çağrılan gölge girmez: max_shadows yalnızca onları sınırlar).
func _wild_count() -> int:
	var n := 0
	for s in shadows:
		if not s.summoned:
			n += 1
	return n


## Bekleyen doğumlar (test ve hata ayıklama için).
func pending_spawns() -> int:
	return _pending.size()


## Yemin çekimi ya da şans garantisi değişti: bundan sonra doğan gölgeler yeni oranlarla.
func set_odds(odds: Dictionary) -> void:
	_species = CatchOdds.species_ppm(_db, _spot, odds)
	_zone_species.clear()
	for z in _zones:
		_zone_species.append(CatchOdds.species_ppm(_db, z, odds))
	pity_floor = int(odds.get("pity_floor", -1))


## Gölün koşulu değişti (set_odds'tan sonra; vakit, hava): o koşulda gelmeyen türün (oranı yok)
## dolaşan ya da duraklayan gölgesi çekilir (kaçar, yerine yakında yenisi doğar). Yaklaşan, oltadaki,
## senaryolu ve çağrılan gölgeye dokunulmaz. Zar atılmaz.
func recycle_unfit() -> void:
	for s in shadows:
		if s.scripted or s.summoned or s == approacher or (s.mode != FishShadow.Mode.WANDER and s.mode != FishShadow.Mode.PAUSE):
			continue
		var species: Dictionary = _zone_species[s.zone] if _zoned and s.zone >= 0 and s.zone < _zone_species.size() \
				else _species
		if not species.has(s.fish_id):
			s.recycled = true
			flee(s, _angler)


## Bundan sonra doğacak gölgelerin tür oranları (Balık Defteri ve testler): bölgeli gölde
## balıkçının bölgesininki.
func species_odds() -> Dictionary:
	if _zoned and player_zone >= 0 and player_zone < _zone_species.size():
		return _zone_species[player_zone]
	return _species


# --- İç işler ----------------------------------------------------------------------

## Senaryolu ilk av ya da çağrılan hikâye balığı yakında mı? (Bölgeli gölde balıkçı uzaklaşınca öteki
## balıklar da gelir.)
func _has_scripted() -> bool:
	for s in shadows:
		if (s.scripted or s.summoned) and (not _zoned or s.pos.distance_to(_angler) <= _reach + _rules.leash_extra):
			return true
	return false


## Balıkçının yeri ve avlandığı bölge, adımı beklemeden (atıştan önce: takım avlanılan bölgenin
## suyuna düşer, teknik bölgeye uyar). Bölgesiz gölde bir şey yapmaz.
func locate(angler: Vector2) -> void:
	if not _zoned or angler == _angler:
		return
	_afloat = _in_boat(angler)
	_angler = angler
	player_zone = _fishing_zone(angler)


## Bölgeli göl: balıkçının yeri ve avlandığı bölge; çok uzakta kalan ya da avlanılan bölgeden
## olmayan (balıkçı başka bölgeye yürüdü) dolaşan gölge çekilir (kaçar ve kaybolur, yerine yakında
## yenisi doğar).
func _follow(angler: Vector2) -> void:
	locate(angler)
	_check -= 1
	if _check > 0:
		return
	_check = _rules.recycle_check_steps
	var far := _reach + _rules.leash_extra
	for s in shadows:
		if s.scripted or s.summoned or s == approacher or (s.mode != FishShadow.Mode.WANDER and s.mode != FishShadow.Mode.PAUSE):
			continue
		if s.pos.distance_to(angler) > far or (player_zone >= 0 and s.zone != player_zone):
			s.recycled = true
			flee(s, angler)


## Avlanılan bölge: noktanın bölgesi açıksa o (ızgaranın dışında en yakın hücreninki); değilse
## (kapalı bölgenin çitinin önü, bölgesiz şerit) çevrede halka halka aranan en yakın açık bölge;
## yoksa -1.
func _fishing_zone(p: Vector2) -> int:
	var here := _lake.zone_of(p)
	if is_open(here):
		return here
	for r in FISHING_SEARCH:
		for k in 16:
			var zone := _lake.zone_at(p + Vector2.from_angle(TAU * k / 16.0) * r)
			if is_open(zone):
				return zone
	return -1


## Balıkçı sandalda mı (suyun üstünde, iskelede değil)?
func _in_boat(p: Vector2) -> bool:
	return _lake.is_water(p) and not _lake.on_dock(p)


## Sandaldaki balıkçının çevresi: dolaşan gölgenin hedefi ve yolu buraya girmez. Sandala zaten
## yakın olan gölge (kaçarken ya da ilgisini kaybedince) sandala yaklaşmayan bir yol seçebilir:
## orada takılı kalmaz.
func _clear_of_boat(from: Vector2, to: Vector2) -> bool:
	if not _afloat:
		return true
	var side := minf(BOAT_CLEAR * 0.7, from.distance_to(_angler) - 0.001)
	return to.distance_to(_angler) >= BOAT_CLEAR \
			and Geometry2D.get_closest_point_to_segment(_angler, from, to).distance_to(_angler) >= side


## Gölgenin dolaşabileceği en sığ su: bölgesinin min_depth'i (eski şemada kuraldaki).
func _min_depth(s: FishShadow) -> float:
	return _zone_depth(s.zone) if _zoned else _rules.min_depth


func _zone_depth(zone: int) -> float:
	return float(_zones[zone]["min_depth"]) if zone >= 0 and zone < _zones.size() else _rules.min_depth


## Şimdiki garantiyi karşılayan bir garanti gölgesi gölde mi? Eski (daha düşük) bir garantiyle
## doğmuş gölge sayılmaz: Nadir garantisinin turnası göldeyken dolan Destansı garantisi beklemesin.
func _has_pity() -> bool:
	for s in shadows:
		if s.pity and s.rarity >= pity_floor:
			return true
	return false


func _spawn(angler: Vector2, bobber: Vector2, bobber_active: bool) -> FishShadow:
	if _wild_count() >= _max:
		return null
	var s := FishShadow.new()
	s.id = _serial
	_serial += 1
	s.seed = Dice.derive(_seed, s.id)
	s.rng.seed = s.seed
	# Tür ve boy ayrı tuzlu zarlardan: şans garantisi türü değiştirse de boy ve hareket kaymaz.
	var species_rng := RandomNumberGenerator.new()
	species_rng.seed = Dice.derive(s.seed, 2)
	var size_rng := RandomNumberGenerator.new()
	size_rng.seed = Dice.derive(s.seed, 3)
	var ids: PackedStringArray = _spot["fish_ids"]
	var scripted := _first_pending
	# Gölgenin kendi zarının sırası: hız, yer, yön, duraklama (tür ve boy ayrı zarlardan).
	s.speed = s.rng.randf_range(_rules.shadow_speed.x, _rules.shadow_speed.y)
	var point: Vector2 = (_spot["first_shadow"] as Dictionary)["pos"] if scripted \
			else _spawn_point(s.rng, angler, bobber, bobber_active)
	if not Dice.is_point(point):
		return null
	s.zone = _lake.zone_at(point)
	var species: Dictionary = _zone_species[s.zone] if _zoned and s.zone >= 0 else _species
	var forced := not scripted and pity_floor >= 0 and not _has_pity() and (not _zoned or s.zone == player_zone)
	var fish_id := str(_spot.get("first_fish", ids[0])) if scripted \
			else CatchOdds.roll(_db, species_rng, species, pity_floor if forced else -1)
	if fish_id.is_empty():
		# Bu teknikle bu bölgede gelen tür yok (zarlar atıldıktan sonra; şamandırada hiç olmaz).
		return null
	s.fish_index = _db.fish_index(fish_id)
	var def := _db.fish_def(s.fish_index)
	s.fish_id = fish_id
	s.rarity = int(def["rarity"])
	s.pity = forced and s.rarity >= pity_floor
	s.percentile = FishTable.roll_percentile(size_rng)
	s.size_cm = FishTable.size_cm(def, s.percentile)
	s.stars = FishTable.stars(s.percentile)
	s.length = FishTable.shadow_length(def, s.percentile)
	s.pos = point
	s.home = point
	if scripted:
		var first: Dictionary = _spot["first_shadow"]
		s.scripted = true
		s.heading = first["heading"]
		s.mode = FishShadow.Mode.PAUSE
		s.timer = FishingRules.HZ
		_first_pending = false
	else:
		s.heading = Dice.direction(s.rng)
		s.mode = FishShadow.Mode.PAUSE
		s.timer = Dice.between(s.rng, _rules.pause_steps)
	shadows.append(s)
	return s


func _spawn_point(rng: RandomNumberGenerator, angler: Vector2, bobber: Vector2, bobber_active: bool) -> Vector2:
	var bounds := _lake.water_bounds
	if _zoned:
		# Balıkçının çevresi, avlanılan bölgenin kutusunda (gölün dışı kırpılır).
		bounds = Rect2(angler - Vector2(_reach, _reach), Vector2(_reach, _reach) * 2.0).intersection(_lake.water_bounds)
		if player_zone >= 0 and player_zone < _lake.zone_bounds.size():
			bounds = bounds.intersection(_lake.zone_bounds[player_zone])
		if bounds.size.x <= 0.0 or bounds.size.y <= 0.0:
			return Dice.NO_POINT
	for strict: bool in [true, false]:
		for attempt in 40:
			var p := Vector2(rng.randf_range(bounds.position.x, bounds.end.x),
					rng.randf_range(bounds.position.y, bounds.end.y))
			if _zoned:
				var zone := _lake.zone_at(p)
				if not is_open(zone) or (player_zone >= 0 and zone != player_zone) or p.distance_to(angler) > _reach \
						or not _lake.is_deep(p, _zone_depth(zone)):
					continue
			elif not _lake.is_deep(p, _rules.min_depth):
				continue
			if strict:
				if p.distance_to(angler) < _rules.spawn_from_angler:
					continue
				if bobber_active and p.distance_to(bobber) < 2.5:
					continue
				var crowded := false
				for o in shadows:
					# Çağrılan gölge sayılmaz: öteki gölgelerin zarı onun varlığıyla kaymaz.
					if not o.summoned and o.pos.distance_to(p) < _rules.spacing:
						crowded = true
						break
				if crowded:
					continue
			return p
	return Dice.NO_POINT


## Yeni bir dolaşma hedefi seçer. Takım uzun süredir sudaysa gölgeler (profile göre, şamandırada
## yarı yarıya) onun çevresine yönelir; ilk av ve hikâye balığı evinin yakınında dolaşır.
func _pick_target(s: FishShadow, bobber: Vector2, listening: bool, waiting_steps: int) -> void:
	# Kısa devre sırası şamandırada v0.3'teki gibi: zar yalnızca toplanma açıkken atılır (takım hikâye
	# balığına ayrıldıysa toplanılmaz: reserved).
	var gather := listening and not reserved and rig.gather_ppm > 0 and waiting_steps >= rig.gather_after_steps \
			and Dice.chance(s.rng, rig.gather_ppm)
	var bounds := _lake.water_bounds
	var depth := _min_depth(s)
	var own := _zoned and s.zone >= 0 and s.zone < _lake.zone_bounds.size()
	if own:
		# Kendi bölgesinde, balıkçının çevresinde dolaşır (uzaklaşan zaten çekilir).
		var near_size := Vector2.ONE * (_reach + _rules.leash_extra)
		var near := Rect2(_angler - near_size, near_size * 2.0).intersection(_lake.zone_bounds[s.zone])
		bounds = near if near.size.x > 0.5 and near.size.y > 0.5 else _lake.zone_bounds[s.zone]
	var stranded := _stranded(s)
	for attempt in 12:
		var p: Vector2
		if gather:
			p = bobber + Dice.in_disc(s.rng, rig.gather_radius)
		elif s.scripted:
			p = s.home + Dice.in_disc(s.rng, 1.5)
		elif s.summoned:
			p = s.home + Dice.in_disc(s.rng, SUMMON_ROAM)
		else:
			p = Vector2(s.rng.randf_range(bounds.position.x, bounds.end.x),
					s.rng.randf_range(bounds.position.y, bounds.end.y))
		# Sığda kalmış balığın yolunu adım adım _wander denetler (başlangıç zaten sınır dışında).
		var path_ok := stranded or _lake.segment_is_deep(s.pos, p, depth * 0.75)
		var home_zone := not own or gather or s.scripted or s.summoned or _lake.zone_at(p) == s.zone
		if _lake.is_deep(p, depth) and path_ok and home_zone and _clear_of_boat(s.pos, p):
			s.target = p
			s.mode = FishShadow.Mode.WANDER
			s.gathering = gather
			return
	s.mode = FishShadow.Mode.PAUSE
	s.timer = FishingRules.HZ


func _wander(s: FishShadow) -> void:
	var to := s.target - s.pos
	var d := to.length()
	if d < 0.15:
		s.mode = FishShadow.Mode.PAUSE
		s.timer = Dice.between(s.rng, _rules.pause_steps)
		return
	if _stranded(s) or (_afloat and s.pos.distance_to(_angler) < BOAT_CLEAR * 0.7):
		# Sığda kalmış ya da sandalın dibindeki balık yerinde hedefe döner: eski yönündeki adım
		# reddedilip hep duraklamasın (hedefin yolu sandala yaklaşmaz: _clear_of_boat).
		s.heading = to / d
	else:
		_turn(s, to / d, _rules.turn)
	# Takıma toplanan gölge (dipte yemin kokusu) daha hızlı yüzer; şamandırada çarpan 1.
	var next := s.pos + s.heading * (s.speed * (rig.gather_speed if s.gathering else 1.0)) * STEP
	var boat_ok := not _afloat or next.distance_to(_angler) >= BOAT_CLEAR * 0.6 \
			or next.distance_to(_angler) >= s.pos.distance_to(_angler) - 0.0005
	if boat_ok and (_lake.is_deep(next, _min_depth(s) * 0.75) or _escapes_shallows(s, next)):
		s.pos = next
	else:
		s.mode = FishShadow.Mode.PAUSE
		s.timer = FishingRules.HZ >> 1


## Balık sığda ya da iskelenin dibinde mi (dolaşma sınırının dışında)?
func _stranded(s: FishShadow) -> bool:
	return not _lake.is_deep(s.pos, _min_depth(s) * 0.75)


## Sığda kalmış balığın adımı: suda, derinliği azaltmıyor ve iskeleye yaklaşmıyorsa serbest
## (iskeleye STRANDED_DOCK'tan yakınsa uzaklaşmalı, uzaksa o kadar uzakta kalmalı). Böylece balık
## dolaşma sınırının içine döner.
func _escapes_shallows(s: FishShadow, next: Vector2) -> bool:
	if not _stranded(s) or not _lake.is_water(next) or _lake.on_dock(next):
		return false
	return _lake.depth_at(next) >= _lake.depth_at(s.pos) - 0.001 \
			and _lake.dock_distance(next) >= minf(_lake.dock_distance(s.pos), STRANDED_DOCK) - 0.001


## Şamandıraya doğru yüzer; ağzı şamandıraya değince true. Önü kıyıysa kenarından kayar.
func _approach(s: FishShadow, bobber: Vector2) -> bool:
	var to := bobber - s.pos
	var d := to.length()
	var stop := s.length * 0.5
	if d <= stop + 0.05:
		return true
	_turn(s, to / d, _rules.turn * 2.0)
	var step_len := minf(rig.approach_speed * STEP, d - stop)
	var next := s.pos + s.heading * step_len
	if _lake.is_water(next):
		s.pos = next
		return false
	for angle: float in DETOURS:
		var dir := s.heading.rotated(angle)
		next = s.pos + dir * step_len
		if _lake.is_water(next):
			s.pos = next
			s.heading = dir
			return false
	return false


## Takımı izleyen balık (spinde yemin peşindeki): takıma doğru izleme hızıyla yüzer, ağzı takımın
## dibinde durur.
func _follow_rig(s: FishShadow, rig_pos: Vector2) -> void:
	var to := rig_pos - s.pos
	var d := to.length()
	var stop := s.length * 0.5
	if d <= stop + 0.02:
		return
	var dir := to / d
	var next := s.pos + dir * minf(rig.follow_speed * STEP, d - stop)
	if _lake.is_water(next):
		s.pos = next
		s.heading = dir


func _flee_step(s: FishShadow) -> void:
	var next := s.pos + s.heading * _rules.flee_speed * STEP
	if _lake.is_water(next) and not _lake.on_dock(next, 0.3):
		s.pos = next


## Yönü istenen yöne doğru yumuşakça çevirir (trigonometri yok: normalize edilmiş karışım).
func _turn(s: FishShadow, desired: Vector2, rate: float) -> void:
	var h := s.heading.lerp(desired, minf(1.0, rate * STEP))
	if h.length_squared() < 0.000001:
		h = Vector2(-s.heading.y, s.heading.x)
	s.heading = h.normalized()
