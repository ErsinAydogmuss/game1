class_name Story
extends RefCounted
## Oyunun hikâyesi (docs/gdd.md §10.5): yeni oyunda bir kez oynayan açılış filmi (StoryFilm) ve
## rütbe atladıkça Dede'nin anlattığı devamı (bölümler). Saf kurallar ve veri; sunum main'de.
## Göl köyü: Dede ile Nine gençken ölen gölü temizlemiş, sazlar dikmiş; göl canlanmış. Derinlerde
## gölü koruyan Gölün Bekçisi yaşar, göle iyi bakanlara görünür (Dalga 4'ün finali: sisli gece,
## derin orta, Bekçi).

## Film görüldü mü (kayıtta bayrak; kayıt sürümü değişmez).
const SEEN_FLAG := "seen_intro"
## Filmin sözleri sırasıyla: [anahtar, konuşan, çekim] ya da [..., en kısa süresi (sn)]: Bekçi'nin
## geçişi ve hediye biraz uzun kalır. Çekimleri StoryFilm kurar.
const LINES: Array[Array] = [
	["UI_INTRO_1", "nine", "nine"],
	["UI_INTRO_2", "dede", "lake"],
	["UI_INTRO_3", "dede", "dede"],
	["UI_INTRO_4", "nine", "reeds"],
	["UI_INTRO_5", "dede", "deep"],
	["UI_INTRO_6", "dede", "keeper", 6.5],
	["UI_INTRO_7", "nine", "dock"],
	["UI_INTRO_8", "dede", "gift", 5.5],
]


## Bir sözün ekranda kalacağı süre (sn): en az LINE_MIN (ya da sözün kendi süresi), uzun yazıda harf
## başına PER_CHAR. Dokunuş daha önce geçirir.
const LINE_MIN := 5.0
const PER_CHAR := 0.085


static func line_time(index: int, text: String) -> float:
	var line: Array = LINES[index]
	var least := float(line[3]) if line.size() > 3 else LINE_MIN
	return maxf(least, text.length() * PER_CHAR)
## Hikâyenin devamı: rütbe → Dede'nin sözü. Unvanın değiştiği rütbeler; her biri bir kez
## (flags["told_story_<rütbe>"]).
const CHAPTERS := { 3: "UI_DEDE_STORY_3", 6: "UI_DEDE_STORY_6", 10: "UI_DEDE_STORY_10", 15: "UI_DEDE_STORY_15",
		20: "UI_DEDE_STORY_20" }
const TOLD_FLAG := "told_story_%d"


## Film oynasın mı: yeni oyun (film görülmedi ve hiç balık tutulmadı).
static func wants_intro(save: SaveData) -> bool:
	return not save.flags.has(SEEN_FLAG) and save.catches == 0


static func mark_seen(save: SaveData) -> void:
	save.flags[SEEN_FLAG] = true


## Rütbesi gelmiş ama anlatılmamış ilk bölümün rütbesi (yoksa 0). Rütbeler atlandıysa en eskisi
## önce: hikâye sırayla anlatılır.
static func next_chapter(rank: int, save: SaveData) -> int:
	var ranks: Array = CHAPTERS.keys()
	ranks.sort()
	for r: int in ranks:
		if r <= rank and not save.flags.has(TOLD_FLAG % r):
			return r
	return 0


## Bölüm anlatıldı: sözü döner (bayrak kayda).
static func tell(rank: int, save: SaveData) -> String:
	save.flags[TOLD_FLAG % rank] = true
	return str(CHAPTERS[rank])


## Gölün Bekçisi'nin filmdeki yolu: derin ortanın ortasından (şamandıraların ortalaması) geçen
## KEEPER_SPAN m'lik, hafif yay çizen (yan sapma KEEPER_BEND m) bir yol. Yönü ekranın sağına (across)
## en yakın, bütün noktaları en az KEEPER_DEPTH derin olan yön (across'tan en çok 60° döner; derin
## orta doğu-batı uzanır, ekranın sağı ise kuzeydoğuya). Hiçbiri olmazsa across. Yalnızca görünüş.
const KEEPER_SPAN := 10.0
const KEEPER_BEND := 1.5
const KEEPER_DEPTH := 4.5
const KEEPER_TURNS: Array[float] = [0.0, 10.0, -10.0, 20.0, -20.0, 30.0, -30.0, 40.0, -40.0, 50.0, -50.0, 60.0, -60.0]


static func keeper_path(db: ContentDB, spot_id: String, across: Vector2, count: int = 24) -> PackedVector2Array:
	var center := Vector2.ZERO
	var buoys: Array = []
	for z in db.zones_of(spot_id):
		if bool(z["boat"]):
			buoys = z["buoys"]
	if buoys.is_empty():
		return PackedVector2Array()
	for b: Vector2 in buoys:
		center += b
	center /= float(buoys.size())
	var lake := db.lake(spot_id)
	for turn in KEEPER_TURNS:
		var path := _keeper_line(center, across.normalized().rotated(deg_to_rad(turn)), count)
		if _deep(lake, path):
			return path
	return _keeper_line(center, across.normalized(), count)


static func _keeper_line(center: Vector2, dir: Vector2, count: int) -> PackedVector2Array:
	var out := PackedVector2Array()
	var side := Vector2(-dir.y, dir.x)
	for i in count:
		var s := float(i) / float(maxi(1, count - 1))
		out.append(center + dir * (s - 0.5) * KEEPER_SPAN + side * sin(PI * s) * KEEPER_BEND)
	return out


static func _deep(lake: LakeShape, path: PackedVector2Array) -> bool:
	for p in path:
		if not lake.is_water(p) or lake.depth_at(p) < KEEPER_DEPTH:
			return false
	return true
