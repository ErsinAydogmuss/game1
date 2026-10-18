class_name BottomTechnique
extends Technique
## Dip (Dalga 3, rütbe 4; docs/gdd.md §10.3): dokunulan yöne, menzilin sonuna atılır (avlanılan
## bölgenin suyunda kalır: gölgeler yalnızca orada dolaşır); olta balıkçının yanındaki sehpaya
## konur, ucunda zil var. Yem dipte durur: balık her yönden sezer, takımın çevresine toplanır (yem
## sepeti toplanmayı hızlandırır: rig_for). Varan balık zili tek tük çaldırır (koklama, "sniff":
## 1–3 kez; bu sırada dokunmak balığı kaçırır), sonra zil durmadan çalar ve misina akar (koşu,
## "run"): vuruş penceresinde ekranın her yerine dokun. Beklerken dokunmak oltayı geri sarar (uzun
## misina: daha uzun sürer). Sayılar rules.json techniques.bottom; zarlar balığın kendi zarından.

var min_cast_m: float = 4.0
## Geri sarma süresi (adım).
var retrieve_steps: int = 60


func _init(fishing_rules: FishingRules) -> void:
	super(fishing_rules, "bottom")
	min_cast_m = rig.num("min_cast_m", min_cast_m)
	retrieve_steps = rig.steps("retrieve", 1.0)


## Dokunulan yönde menzilin sonundan geriye ilk uygun su (balıkçının avlandığı bölgede).
func landing_point(s: FishingSession, target: Vector2) -> Vector2:
	var offset := target - s.angler
	if offset.length_squared() < 0.000001:
		return Dice.NO_POINT
	var dir := offset.normalized()
	var zoned := s.lake.zone_ids.size() > 1
	var zone := s.zone()
	var d := s.gear.range_m
	while d >= min_cast_m:
		var p := s.angler + dir * d
		if s.lake.is_water(p) and not s.lake.on_dock(p, 0.2) and s.lake.shore_distance(p) >= s.rules.min_shore \
				and (not zoned or s.lake.zone_at(p) == zone):
			return p
		d -= 0.1
	return Dice.NO_POINT


func min_cast(_s: FishingSession) -> float:
	return min_cast_m


## Kurşun suya düşer: yakındaki gölgeler ürker (şamandıra gibi).
func land(s: FishingSession) -> void:
	s.land_rig()
	for e in s.sim.scare(s.bobber, s.gear.stealth):
		s.push_event(e)


func step(s: FishingSession) -> void:
	match s.state:
		FishingSession.State.WAITING:
			s.waiting_steps += 1
			# Yemin kokusu yayıldı: dolaşan gölgeler takıma yönelebilir (yem sepetiyle daha erken).
			if s.waiting_steps == s.sim.rig.gather_after_steps:
				s.sim.call_to_rig(s.bobber, s.waiting_steps)
		FishingSession.State.NIBBLING:
			s.timer -= 1
			if s.timer <= 0:
				s.next_nibble()
		FishingSession.State.BITING:
			s.bite_steps += 1
			if s.bite_steps >= s.window:
				s.missed()


func listening(s: FishingSession) -> bool:
	return s.state == FishingSession.State.WAITING


func on_arrive(s: FishingSession, fish: FishShadow, e: Dictionary) -> void:
	if s.state == FishingSession.State.WAITING and fish == s.sim.approacher:
		s.push_event(e)
		s.start_nibbling()
	else:
		s.sim.lose_interest(fish)


func press(s: FishingSession) -> void:
	match s.state:
		FishingSession.State.WAITING:
			s.retrieve(retrieve_steps)
		FishingSession.State.NIBBLING:
			s.early()
		FishingSession.State.BITING:
			s.hook_fish()


func action_kind(s: FishingSession) -> String:
	match s.state:
		FishingSession.State.WAITING:
			return "retrieve"
		FishingSession.State.NIBBLING:
			return "wait"
		FishingSession.State.BITING:
			return "hook"
	return ""


## Yem sepeti (kurşun yuvasının pull'u): gölgeler takıma daha erken ve daha sık toplanır.
func rig_for(gear: GearStats) -> TechniqueRules:
	return rig if gear.rig_pull <= 0.0 else rig.with_pull(gear.rig_pull)


func nibble_event() -> String:
	return "sniff"


func bite_event() -> String:
	return "run"
