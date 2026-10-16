class_name Rank
extends RefCounted
## Rütbe (docs/gdd.md §10.4): rütbe puanı tutulan ve bırakılan balıktan ve isteklerden gelir;
## rütbe bölge ve takım kilitlerini açar. Eşikler data/progression.json'da.

## Yıldız başına ek puan (binde bir): 5 yıldızlı balık 2 katı puan verir.
const STAR_BONUS := 250


static func rank(db: ContentDB, save: SaveData) -> int:
	return db.rank_for_xp(save.xp)


## Bir yakalayışın rütbe puanı: nadirliğin puanı × (1 + yıldız başına 0,25).
static func catch_xp(db: ContentDB, rarity: int, stars: int) -> int:
	var base := int(db.rarity_def(rarity).get("xp", 0))
	return base * (1000 + STAR_BONUS * clampi(stars - 1, 0, 4)) / 1000


## Puan ekler. Döner: { old_rank, new_rank } (rütbe atlandıysa new_rank > old_rank).
static func add_xp(db: ContentDB, save: SaveData, amount: int) -> Dictionary:
	var before := rank(db, save)
	save.xp += maxi(0, amount)
	return { "old_rank": before, "new_rank": rank(db, save) }


## Bu rütbe içinde ne kadar ilerlendi (0..1; en yüksek rütbede 1).
static func progress(db: ContentDB, save: SaveData) -> float:
	var r := rank(db, save)
	if r >= db.max_rank():
		return 1.0
	var low := db.rank_xp[r - 1]
	var high := db.rank_xp[r]
	return clampf(float(save.xp - low) / float(maxi(1, high - low)), 0.0, 1.0)
