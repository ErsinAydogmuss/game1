class_name WorldState
extends RefCounted
## Gölün o anki koşulları (docs/gdd.md §10.5): vakit (DayClock), hava (Weather) ve göl sevgisinin
## seviyesi (LakeLove). Saf: hepsi kayıttan türer (saat, seed, sevgi, bayraklar). Oturum, defter,
## dükkân ve denge botu oranları aynı koşullarla hesaplar (CatchOdds.context): ekranda yazan oran
## gerçek orandır (gelir kuralı 10).


## { phase, weather, love } (love: seviye 1..10).
static func conditions(db: ContentDB, save: SaveData) -> Dictionary:
	var rules := db.rules
	return {
		"phase": DayClock.phase(rules, save.clock_s),
		"weather": Weather.at(rules, save),
		"love": LakeLove.level(rules, save.love),
	}
