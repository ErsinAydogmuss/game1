class_name Bucket
extends RefCounted
## Kova (docs/gdd.md §10.4): tutulan balık kovaya girer, Nine'ye toptan satılır ya da göle bırakılır
## (take, take_last; göl sevgisi WorldState.release). Kapasite sahip olunan en büyük kovadan gelir. Kova doluyken oyunda olta atılmaz (main: eylem düğmesi SAT); yine
## de dolu kovaya gelen balık göle bırakılır (çağıran bırakma ödülünü verir). Koruma altındaki tür
## (mersin, fish.json release_only) kovaya hiç girmez.


## Sahip olunan en büyük kova (ya da file) kaç balık alır.
static func capacity(db: ContentDB, save: SaveData) -> int:
	var best := 0
	for g in db.gear_in("bucket"):
		if Economy.owns(db, save, str(g["id"])):
			best = maxi(best, int(g["capacity"]))
	return maxi(1, best)


## Dükkânda gösterilen kova: kapasiteyi büyüten en ucuz kova; hepsi alındıysa en büyüğü (kovalar
## tek kartta: sahip olunanın bir üstü).
static func next_bucket(db: ContentDB, save: SaveData) -> Dictionary:
	var have := capacity(db, save)
	var next: Dictionary = {}
	var biggest: Dictionary = {}
	for g in db.gear_in("bucket"):
		if biggest.is_empty() or int(g["capacity"]) > int(biggest["capacity"]):
			biggest = g
		if int(g["capacity"]) > have and (next.is_empty() or int(g["price"]) < int(next["price"])):
			next = g
	return next if not next.is_empty() else biggest


## Koruma altındaki tür mü (tutulur, kovaya girmez, göle bırakılır)?
static func release_only(db: ContentDB, fish_id: String) -> bool:
	return bool(db.fish_by_id(fish_id).get("release_only", false))


static func is_full(db: ContentDB, save: SaveData) -> bool:
	return save.bucket.size() >= capacity(db, save)


## Balığı kovaya koyar; kova doluysa ya da tür koruma altındaysa false (çağıran balığı bırakır).
static func add(db: ContentDB, save: SaveData, fish_id: String, size_cm: int, stars: int) -> bool:
	if is_full(db, save) or release_only(db, fish_id):
		return false
	save.bucket.append({ "fish": fish_id, "size_cm": size_cm, "stars": stars })
	return true


## Kovadan o türün en küçük balığını çıkarır (göle bırakmak için; iri olan satılsın). Döner: çıkan kayıt
## ({fish, size_cm, stars}) ya da yoksa boş sözlük.
static func take(save: SaveData, fish_id: String) -> Dictionary:
	var pick := -1
	for i in save.bucket.size():
		var entry := save.bucket[i]
		if str(entry["fish"]) == fish_id and (pick < 0 or int(entry["size_cm"]) < int(save.bucket[pick]["size_cm"])):
			pick = i
	return _remove(save, pick)


## Kovadan o türün en son giren balığını çıkarır (yeni tür kartındaki "Göle bırak": az önce tutulan).
static func take_last(save: SaveData, fish_id: String) -> Dictionary:
	for i in range(save.bucket.size() - 1, -1, -1):
		if str(save.bucket[i]["fish"]) == fish_id:
			return _remove(save, i)
	return {}


static func _remove(save: SaveData, index: int) -> Dictionary:
	if index < 0:
		return {}
	var entry := save.bucket[index]
	save.bucket.remove_at(index)
	return entry


## Kovadaki tür sayımı (dükkânda tür başına bir satır): balık kimliği -> adet, ilk girişe göre sıralı.
static func counts(save: SaveData) -> Dictionary:
	var out := {}
	for entry in save.bucket:
		var id := str(entry["fish"])
		out[id] = int(out.get(id, 0)) + 1
	return out
