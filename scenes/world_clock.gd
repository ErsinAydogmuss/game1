class_name WorldClock
extends Node
## Oyun saatinin sürücüsü (docs/gdd.md §10.5): main her oyun karesinde (oyun akarken) tick'i çağırır;
## geçen süre tam saniyelere çevrilip kayıttaki saate eklenir (DayClock.advance). Vakit, gün ya da
## gölün koşulu (vakit, hava, sevgi seviyesi: WorldState) değişince sinyal verir. Saat oyuncu yokken,
## bir panel açıkken, filmde ve kararmada durur: main o zaman tick'i çağırmaz. Süre _process(delta)
## toplamıyla ölçülür (Movie Maker'da oyun saati gerçek saatten yavaş akar).

## Vakit değişti (yeni vakit) ya da gün döndü (yeni günün sırası).
signal phase_changed(phase: String)
signal day_changed(day: int)
## Gölün koşulu değişti: { phase, weather, love } (oranlar, garanti, defter yenilenir).
signal conditions_changed(conditions: Dictionary)

## true iken saat ilerlemez (yalnızca debug: botlar saati dondurur; eski senaryolar sabah ışığında).
var frozen: bool = false

var _db: ContentDB
var _acc: float = 0.0
var _last: Dictionary = {}


func setup(db: ContentDB, save: SaveData) -> void:
	_db = db
	reset(save)


## Kayıt değişti (yeni oyun, kayıt sıfırlama): koşul baştan okunur, sinyal verilmez.
func reset(save: SaveData) -> void:
	_acc = 0.0
	_last = WorldState.conditions(_db, save)


## Gölün şimdiki koşulu.
func conditions() -> Dictionary:
	return _last


## Oyun karesi (main çağırır: oyun akarken).
func tick(delta: float, save: SaveData) -> void:
	if frozen or _db == null:
		return
	_acc += maxf(0.0, delta)
	if _acc < 1.0:
		return
	var whole := int(_acc)
	_acc -= whole
	_apply(save, DayClock.advance(_db.rules, save, whole))


## Sonraki vaktin başına geçer (Dede'yle çay, geliştirme sürümünün VAKİT + düğmesi).
func skip(save: SaveData) -> void:
	_acc = 0.0
	_apply(save, DayClock.skip_phase(_db.rules, save))


## Koşul saatten başka bir yoldan değişti (sevgi arttı, deneme düğmesiyle hava): yeniden bakılır.
func refresh(save: SaveData) -> void:
	_apply(save, {})


func _apply(save: SaveData, change: Dictionary) -> void:
	if bool(change.get("day_changed", false)):
		day_changed.emit(int(change["new_day"]))
	if bool(change.get("phase_changed", false)):
		phase_changed.emit(str(change["new_phase"]))
	var now := WorldState.conditions(_db, save)
	if now != _last:
		_last = now
		conditions_changed.emit(now)
