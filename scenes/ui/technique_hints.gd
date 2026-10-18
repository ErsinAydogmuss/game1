class_name TechniqueHints
extends RefCounted
## Yeni bir teknikte Dede'nin ilk atışlardaki ipuçları (docs/gdd.md §10.3): şamandıradan başka bir
## teknikle yapılan ilk CASTS atış boyunca ipucu çubuğu o anki duruma göre ne yapılacağını söyler.
## Atışlar kayıtta sayılır (flags["tech_casts_<teknik>"]); şamandıranın ipuçları main'de (ilk 3 balık).

const CASTS := 3
const FLAG := "tech_casts_%s"


## Bu teknikle yapılan atış sayısı.
static func casts(save: SaveData, technique: String) -> int:
	return int(save.flags.get(FLAG % technique, 0))


## Bir atış yapıldı (şamandıra sayılmaz).
static func note_cast(save: SaveData, technique: String) -> void:
	if technique != "float":
		save.flags[FLAG % technique] = casts(save, technique) + 1


## İpuçları bu teknikte hâlâ gösterilsin mi (atış sırasında da: ilk atış 1 sayılır)?
static func active(save: SaveData, technique: String) -> bool:
	return technique != "float" and casts(save, technique) <= CASTS


## Durumun ipucu ("" = bu durumda yeni söz yok, önceki kalır). Boştayken Dede'nin o tekniği
## anlatan sözü (nereye atılacağı).
static func key(technique: String, state: FishingSession.State) -> String:
	match technique:
		"spin":
			match state:
				FishingSession.State.IDLE:
					return "UI_DEDE_TECH_FIRST_spin"
				FishingSession.State.CASTING, FishingSession.State.WAITING:
					return "UI_HINT_SPIN_REEL"
				FishingSession.State.FOLLOWING:
					return "UI_HINT_SPIN_FOLLOW"
				FishingSession.State.BITING:
					return "UI_HINT_SPIN_STRIKE"
				FishingSession.State.FIGHTING:
					return "UI_HINT_REEL"
		"bottom":
			match state:
				FishingSession.State.IDLE:
					return "UI_DEDE_TECH_FIRST_bottom"
				FishingSession.State.CASTING, FishingSession.State.WAITING:
					return "UI_HINT_BOTTOM_WAIT"
				FishingSession.State.NIBBLING:
					return "UI_HINT_BOTTOM_SNIFF"
				FishingSession.State.BITING:
					return "UI_HINT_BOTTOM_RUN"
				FishingSession.State.FIGHTING:
					return "UI_HINT_REEL"
	return ""
