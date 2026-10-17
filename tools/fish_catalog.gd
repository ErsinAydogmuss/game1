extends SceneTree
## Balık kataloğunu (docs/balik-katalogu.md) veriden üretir: nadirlikler, boy ve yıldız şansları,
## şans garantisi, oyunun gölündeki türler ve her yemle gelme şansları, yem başına nadirlik oranı
## ve ortalama değer. Oranlar oyunun gölge doğururken kullandığı işlevlerden (CatchOdds) okunur:
## Balık Defteri'nde yazan oranlarla hep aynıdır (gelir kuralı 10).
##   godot --headless --path . -s res://tools/fish_catalog.gd
## Balık, nadirlik, yem ya da atış noktası değişince yeniden çalıştırılır.

const OUTPUT := "res://docs/balik-katalogu.md"
const PPM := Dice.PPM
## Ortalama değer ve puan için boy zarının eşit aralıklı örnekleri.
const SAMPLES := 4000
## Nadirlik simgeleri (rarities.json "shape"; oyunda GameIcon çizer).
const SYMBOLS := { "circle": "●", "triangle": "▲", "diamond": "◆", "star": "★", "sparkle": "✦", "medallion": "✪" }
const SHADOW_FX := {
	"none": "—",
	"glint": "arada bir baştan kuyruğa pırıltı",
	"shimmer": "kenarında nabız gibi ışıltı, kabarcık",
	"trail": "parlayan kenar ve göbek, dalga izi; Dede uyarır",
	"guardian": "Gölün Bekçisi (hikâye)",
}


func _initialize() -> void:
	var db := ContentDB.load_default()
	if not db.errors.is_empty():
		push_error("İçerik hatalı: %s" % ", ".join(db.errors))
		quit(1)
		return
	var lines: PackedStringArray = []
	lines.append("# Balık Kataloğu")
	lines.append("")
	lines.append("> Bu dosya `tools/fish_catalog.gd` ile veriden üretilir; elle düzenleme. Veri: `data/fish.json`,")
	lines.append("> `data/rarities.json`, `data/spots.json`, `data/gear.json`. Oranlar oyunun gölge doğururken kullandığı")
	lines.append("> işlevlerden (`CatchOdds`) okunur; Balık Defteri'nde yazan oranlar bunlardır.")
	lines.append("")
	lines.append("- **Değer** = türün değeri × boy çarpanı (türün en küçük boyu 0,6, en büyüğü 1,6; tamsayı para). Değeri")
	lines.append("  0 olan balık satılmaz: Masalsı hikâye balığı (sonraki dalgalarda) ve koruma altındaki tür (mersin). Mersin")
	lines.append("  kovaya girmez: tutulur, göle bırakılır; rütbe puanı ve göl sevgisi verir.")
	lines.append("- **Rütbe puanı** = nadirliğin puanı × (1 + yıldız başına 0,25). Bırakılan balık da puan verir.")
	lines.append("- Bir gölgenin türü ve boyu doğduğu anda belirlenir (gizli ama değişmez); gölgenin boyu balığın")
	lines.append("  boyunu ele verir, nadirlik ipucu (pırıltı, ışıltı, dalga izi) kademesini.")
	lines.append("")
	_rarities(db, lines)
	_sizes(lines)
	_pity(db, lines)
	_spot(db, db.main_spot, lines)
	var file := FileAccess.open(OUTPUT, FileAccess.WRITE)
	if file == null:
		push_error("Yazılamadı: " + OUTPUT)
		quit(1)
		return
	file.store_string("\n".join(lines) + "\n")
	file.close()
	print("Yazıldı: ", OUTPUT, " (", db.fish.size(), " tür)")
	quit(0)


func _rarities(db: ContentDB, lines: PackedStringArray) -> void:
	lines.append("## Nadirlikler")
	lines.append("")
	lines.append("| Kademe | Simge | Renk | Tutmadan önce gölgede | Rütbe puanı (1★–5★) | Bırakınca göl sevgisi | Şans garantisi |")
	lines.append("|---|---|---|---|---|---|---|")
	for i in db.rarities.size():
		var r := db.rarities[i]
		var pity := int(r["pity"])
		lines.append("| %s | %s | `%s` | %s | %d–%d | %d | %s |" % [_name("RARITY_" + str(r["id"])),
				SYMBOLS.get(str(r["shape"]), "?"), (r["color"] as Color).to_html(false),
				SHADOW_FX.get(str(r["shadow_fx"]), str(r["shadow_fx"])), Rank.catch_xp(db, i, 1), Rank.catch_xp(db, i, 5),
				int(r["love"]), "%d av" % pity if pity > 0 else "—"])
	lines.append("")


func _sizes(lines: PackedStringArray) -> void:
	lines.append("## Boy ve yıldız")
	lines.append("")
	lines.append("Boy yüzdeliği = u^1,6 (u tekdüze zar): balıkların çoğu küçük, büyükler seyrek. Yıldız boy yüzdeliğinden")
	lines.append("gelir; 5★ türün en iri %10'u.")
	lines.append("")
	lines.append("| Yıldız | Boy yüzdeliği | Şans |")
	lines.append("|---|---|---|")
	var limits: Array[int] = [0]
	for limit: int in FishTable.STAR_LIMITS:
		limits.append(limit)
	limits.append(PPM)
	for star in range(1, limits.size()):
		var low := _first_u(limits[star - 1])
		var high := _first_u(limits[star]) if star < limits.size() - 1 else PPM
		lines.append("| %s | %d–%d | %s |" % ["★".repeat(star), limits[star - 1] / 10000, limits[star] / 10000,
				_percent(high - low)])
	lines.append("")
	var factor := 0.0
	for i in SAMPLES:
		factor += 0.6 + float(FishTable.percentile_for(_sample_u(i))) / PPM
	lines.append("Ortalama boy çarpanı %s: ortalama bir balık türünün değerinin yaklaşık bu katına satılır." % _number(factor / SAMPLES))
	lines.append("")


func _pity(db: ContentDB, lines: PackedStringArray) -> void:
	lines.append("## Şans garantisi")
	lines.append("")
	for i in db.rarities.size():
		var every := int(db.rarities[i]["pity"])
		if every > 0:
			lines.append("- **%s ve üstü:** %d av boyunca gelmezse yakında doğan sıradaki gölge en az %s olur." % [
					_name("RARITY_" + db.rarity_id(i)), every, _name("RARITY_" + db.rarity_id(i))])
	lines.append("- Garanti balığı değil gölgeyi verir: tutmak yine oyuncunun becerisi. Sayaç ancak o kademe ya da")
	lines.append("  üstü tutulunca sıfırlanır; aynı anda yalnızca bir garanti gölgesi olur. Türü, takımın çekebileceği")
	lines.append("  türler arasından kendi oranlarıyla seçilir; boyu ve yolu ayrı zarlardan geldiği için kaymaz.")
	lines.append("- Gölde türü olmayan kademe garanti edilmez ve sayacı alttaki garantileri kilitlemez.")
	lines.append("- Sayaçlar Balık Defteri'nde görünür. Hiçbir şans ya da oran gerçek parayla satılmaz; yemler")
	lines.append("  yalnızca oynayarak kazanılan parayla alınır.")
	lines.append("")


func _spot(db: ContentDB, spot_id: String, lines: PackedStringArray) -> void:
	var spot := db.spot(spot_id)
	lines.append("## %s (oyunun gölü, `%s`)" % [_name("SPOT_" + spot_id), spot_id])
	lines.append("")
	lines.append("- Aynı anda en çok %d gölge; tutulan ya da kaçanın yerine birkaç saniyede yenisi doğar." % int(spot.get("max_shadows", 4)))
	lines.append("- Hiç balık tutmamış oyuncunun ilk balığı senaryoludur: %s, dürtmesiz, kaçmaz." % _name("FISH_" + str(spot.get("first_fish", ""))))
	var zones := db.zones_of(spot_id)
	if zones.size() <= 1:
		lines.append("")
		_tables(db, spot, lines)
		return
	lines.append("- Göl bölgelere ayrılır: gölge balıkçının çevresinde doğar, türü doğduğu yerin bölgesinden gelir.")
	lines.append("  Oranlar bölgenindir (Balık Defteri ve dükkân bulunulan bölgeninkini gösterir). Şans garantisi")
	lines.append("  balıkçının bölgesinde doğar; sayaç yalnızca o bölgede gelebilen kademeler için ilerler.")
	lines.append("")
	for z in zones:
		var opens := "başta açık" if int(z["rank"]) <= 1 else "rütbe %d" % int(z["rank"])
		if bool(z["boat"]):
			opens += ", yalnızca sandalla"
		lines.append("### %s (`%s`; %s)" % [_name("ZONE_" + str(z["id"])), z["id"], opens])
		lines.append("")
		_tables(db, z, lines)


## Bir yerin (göl ya da bölge: fish_ids, fish_weights) tür ve nadirlik tabloları, yeme göre.
func _tables(db: ContentDB, spot: Dictionary, lines: PackedStringArray) -> void:
	var baits: Array[Dictionary] = db.gear_in("bait")
	var odds: Array[Dictionary] = []
	for bait in baits:
		odds.append(CatchOdds.species_ppm(db, spot, {"attract": bait["attract"]}))
	lines.append("Bir gölgenin o tür olma şansı, kuşanılan yeme göre:")
	lines.append("")
	var header := "| Tür | English | Nadirlik | Boy (cm) | Değer (para) | Gölge (m) |"
	var rule := "|---|---|---|---|---|---|"
	for bait in baits:
		header += " %s |" % _name("GEAR_" + str(bait["id"]))
		rule += "---|"
	lines.append(header)
	lines.append(rule)
	var ids: PackedStringArray = spot["fish_ids"]
	for id in ids:
		var f := db.fish_by_id(id)
		var span: Vector2i = f["size_cm"]
		var value := "%d–%d" % [Economy.fish_value(db, id, span.x), Economy.fish_value(db, id, span.y)]
		if Bucket.release_only(db, id):
			value = "satılmaz (bırakılır)"
		var row := "| %s | %s | %s | %d–%d | %s | %s |" % [_name("FISH_" + id), _name("FISH_" + id, "en"),
				_name("RARITY_" + db.rarity_id(int(f["rarity"]))), span.x, span.y, value, _number(float(f["shadow_m"]))]
		for o in odds:
			row += " %s |" % _percent(int(o.get(id, 0)))
		lines.append(row)
	lines.append("")
	var top := CatchOdds.top_rarity(db, spot)
	lines.append("Yeme göre nadirlik oranları ve balık başına ortalama değer ile rütbe puanı (yem bedeli düşülmeden):")
	lines.append("")
	header = "| Yem | Fiyat (para / paket) |"
	rule = "|---|---|"
	for i in top + 1:
		header += " %s |" % _name("RARITY_" + db.rarity_id(i))
		rule += "---|"
	header += " Ortalama değer | Ortalama puan |"
	rule += "---|---|"
	lines.append(header)
	lines.append(rule)
	for b in baits.size():
		var bait := baits[b]
		var price := "bedava, sınırsız" if int(bait["price"]) <= 0 else "%d / %d" % [int(bait["price"]), int(bait["pack"])]
		var row := "| %s | %s |" % [_name("GEAR_" + str(bait["id"])), price]
		var by_rarity := CatchOdds.rarity_ppm(db, odds[b])
		for i in top + 1:
			row += " %s |" % _percent(by_rarity[i])
		var value := 0.0
		var xp := 0.0
		for id: String in odds[b]:
			var share := float(odds[b][id]) / PPM
			value += share * _mean_value(db, id)
			xp += share * _mean_xp(db, int(db.fish_by_id(id)["rarity"]))
		row += " %s | %s |" % [_number(value), _number(xp)]
		lines.append(row)
	lines.append("")


## Balığın ortalama değeri (boy zarının dağılımıyla).
func _mean_value(db: ContentDB, fish_id: String) -> float:
	var def := db.fish_by_id(fish_id)
	var total := 0
	for i in SAMPLES:
		total += Economy.fish_value(db, fish_id, FishTable.size_cm(def, FishTable.percentile_for(_sample_u(i))))
	return float(total) / SAMPLES


func _mean_xp(db: ContentDB, rarity: int) -> float:
	var total := 0
	for i in SAMPLES:
		total += Rank.catch_xp(db, rarity, FishTable.stars(FishTable.percentile_for(_sample_u(i))))
	return float(total) / SAMPLES


## Zarın i. eşit aralıklı örneği (ppm).
func _sample_u(i: int) -> int:
	return int((float(i) + 0.5) / SAMPLES * PPM)


## Boy yüzdeliği en az limit olan en küçük zar (ppm).
func _first_u(limit: int) -> int:
	var lo := 0
	var hi := PPM
	while lo < hi:
		var mid := (lo + hi) >> 1
		if FishTable.percentile_for(mid) >= limit:
			hi = mid
		else:
			lo = mid + 1
	return lo


## Çeviri anahtarının metni (varsayılan Türkçe).
static func _name(key: String, locale: String = "tr") -> String:
	var translation := TranslationServer.get_translation_object(locale)
	if translation == null:
		return key
	var text := str(translation.get_message(key))
	return key if text.is_empty() else text


static func _percent(ppm: int) -> String:
	var value := float(ppm) / PPM * 100.0
	var text := "%.2f" % value if value < 1.0 and value > 0.0 else "%.1f" % value
	if text.ends_with(".0"):
		text = text.substr(0, text.length() - 2)
	return "%" + text.replace(".", ",")


static func _number(value: float) -> String:
	var text := "%.2f" % value
	while text.ends_with("0"):
		text = text.substr(0, text.length() - 1)
	if text.ends_with("."):
		text = text.substr(0, text.length() - 1)
	return text.replace(".", ",")
