class_name Technique
extends RefCounted
## Balık tutma tekniğinin ısırmaya kadarki kuralları (strateji): takımın nereye düştüğü, suda
## ne yaptığı, gölgelerin onu nasıl fark ettiği (rig: TechniqueRules), girdilerin anlamı ve
## eylem düğmesi. Çekişme (ReelModel) her teknikte ortaktır: balık takıldıktan sonrası
## FishingSession'da. Teknik oturumu saklamaz, her işlev onu parametre olarak alır (RefCounted
## döngüsü olmasın). Teknikler: şamandıra (FloatTechnique); spin, dip ve sinek Dalga 3'te
## (docs/gdd.md §10.3).

var id: String = "float"
var rules: FishingRules
## Gölgelerin okuduğu takım profili (fark etme, yaklaşma, toplanma) ve dürtme sayıları.
var rig: TechniqueRules


func _init(fishing_rules: FishingRules, technique_id: String) -> void:
	rules = fishing_rules
	id = technique_id
	rig = fishing_rules.technique(technique_id)


## Takımın düşeceği yer (çizgide su yoksa Dice.NO_POINT).
func landing_point(s: FishingSession, target: Vector2) -> Vector2:
	return s.lake.landing_point(s.angler, target, s.gear.range_m, s.rules.min_shore)


## Bundan kısa atış yapılmaz (m).
func min_cast(s: FishingSession) -> float:
	return s.rules.min_cast


## Uçuş bitti: takım suda (CASTING → WAITING).
func land(s: FishingSession) -> void:
	s.land_rig()


## Takım sudayken her adım (WAITING, NIBBLING, BITING ve tekniğin kendi durumları).
func step(_s: FishingSession) -> void:
	pass


## Gölgeler takımı fark edebilir mi (yalnızca bir balık yaklaşır)?
func listening(_s: FishingSession) -> bool:
	return false


## Yaklaşan balık takıma vardı (sim'in "arrive" olayı).
func on_arrive(s: FishingSession, fish: FishShadow, _e: Dictionary) -> void:
	s.sim.lose_interest(fish)


## Parmak değdi (çekişme dışındaki durumlarda).
func press(_s: FishingSession) -> void:
	pass


## Parmak kalktı (çekişme dışındaki durumlarda).
func release(_s: FishingSession) -> void:
	pass


## Eylem düğmesinin işi (çekişme ve boş durum dışında): retrieve, wait, hook ya da "".
func action_kind(_s: FishingSession) -> String:
	return ""


## Isırmadan önce kaç dürtme (koklama)?
func roll_nibbles(rng: RandomNumberGenerator) -> int:
	return maxi(0, Dice.pick_weighted(rng, rig.nibble_weights))


## İki dürtme arası (adım).
func roll_gap(rng: RandomNumberGenerator) -> int:
	return Dice.between(rng, rig.gap_steps)


## Vuruş penceresi (adım).
func window(s: FishingSession, fish: FishShadow) -> int:
	return rig.window_easy_steps if s.easy or fish.scripted else rig.window_steps


## Dürtme ve ısırma olaylarının adı (dipte koklama ve koşu, sinekte halka).
func nibble_event() -> String:
	return "nibble"


func bite_event() -> String:
	return "bite"


## Yem kullanır mı (yakalayınca yem eksilir)?
func uses_bait() -> bool:
	return true
