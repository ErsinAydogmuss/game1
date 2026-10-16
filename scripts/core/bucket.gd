class_name Bucket
extends RefCounted
## Kova (docs/gdd.md §10.4): tutulan balık kovaya girer, Nine'ye toptan satılır. Kapasite sahip
## olunan en büyük kovadan gelir. Kova dolunca oyun durmaz: yeni balık göle bırakılır (çağıran
## bırakma ödülünü verir).


## Sahip olunan en büyük kova (ya da file) kaç balık alır.
static func capacity(db: ContentDB, save: SaveData) -> int:
	var best := 0
	for g in db.gear_in("bucket"):
		if Economy.owns(db, save, str(g["id"])):
			best = maxi(best, int(g["capacity"]))
	return maxi(1, best)


static func is_full(db: ContentDB, save: SaveData) -> bool:
	return save.bucket.size() >= capacity(db, save)


## Balığı kovaya koyar; kova doluysa false (çağıran balığı bırakır).
static func add(db: ContentDB, save: SaveData, fish_id: String, size_cm: int, stars: int) -> bool:
	if is_full(db, save):
		return false
	save.bucket.append({ "fish": fish_id, "size_cm": size_cm, "stars": stars })
	return true


## Kovadaki tür sayımı (dükkânda tür başına bir satır): balık kimliği -> adet, ilk girişe göre sıralı.
static func counts(save: SaveData) -> Dictionary:
	var out := {}
	for entry in save.bucket:
		var id := str(entry["fish"])
		out[id] = int(out.get(id, 0)) + 1
	return out
