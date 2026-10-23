extends SceneTree
## Balık kataloğunu (docs/balik-katalogu.md) veriden üretir: nadirlikler, boy ve yıldız şansları,
## şans garantisi, tekniklerin yatkınlık tablosu, vakit, hava ve göl sevgisi (Dalga 4: türlerin
## sevdiği vakit ve hava, bölgelerde vakte ve havaya göre oranlar), oyunun gölündeki türler ve her
## bölgede her teknikle (şamandıra ve dipte yeme, spinde yapay yeme, sinekte sineğe göre) gelme
## şansları, nadirlik oranı ve ortalama değer; kerevit tuzağının tablosu. Oranlar oyunun gölge doğururken kullandığı işlevlerden
## (CatchOdds) okunur (gelir kuralı 10). Bölge tabloları koşulsuz (vakit, hava ve göl sevgisi yok sayılır, belli vakitte
## gelen türler yok); vakit ve hava bölümü koşullu oranları verir. Balık Defteri gölün o anki koşuluyla gösterir.
##   godot --headless --path . -s res://tools/fish_catalog.gd
## Balık, nadirlik, yem, teknik ya da atış noktası değişince yeniden çalıştırılır.

const OUTPUT := "res://docs/balik-katalogu.md"
const PPM := Dice.PPM
## Ortalama değer ve puan için boy zarının eşit aralıklı örnekleri.
const SAMPLES := 4000
## Nadirlik simgeleri (rarities.json "shape"; oyunda GameIcon çizer).
const SYMBOLS := { "circle": "●", "triangle": "▲", "diamond": "◆", "star": "★", "sparkle": "✦", "medallion": "✪" }
## Tekniğin tablosundaki takım sütunları: yuva -> [başlık, cümledeki adı].
const ATTRACT_SLOTS := { "bait": ["Yem", "yeme"], "lure": ["Yapay yem", "yapay yeme"], "fly": ["Sinek", "sineğe"] }
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
	lines.append("> işlevlerden (`CatchOdds`) okunur. Bölge tabloları koşulsuzdur (vakit, hava ve göl sevgisi yok sayılır; belli")
	lines.append("> vakitte gelen türler yok); Balık Defteri gölün o anki koşuluyla gösterir (Vakit ve hava bölümündeki gibi).")
	lines.append("")
	lines.append("- **Değer** = türün değeri × boy çarpanı (türün en küçük boyu 0,6, en büyüğü 1,6; tamsayı para). Değeri")
	lines.append("  0 olan balık satılmaz: koruma altındaki mersin, gece efsaneleri (Ay Turnası, Kocabaş) ve Masalsı Gölün")
	lines.append("  Bekçisi. Kovaya girmezler: tutulur, göle bırakılır; rütbe puanı ve göl sevgisi verirler.")
	lines.append("- **Rütbe puanı** = nadirliğin puanı × (1 + yıldız başına 0,25). Bırakılan balık da puan verir.")
	lines.append("- Bir gölgenin türü ve boyu doğduğu anda belirlenir (gizli ama değişmez); gölgenin boyu balığın")
	lines.append("  boyunu ele verir, nadirlik ipucu (pırıltı, ışıltı, dalga izi) kademesini.")
	lines.append("")
	_rarities(db, lines)
	_sizes(lines)
	_big_fish(db, lines)
	_pity(db, lines)
	_techniques(db, db.main_spot, lines)
	_world(db, db.main_spot, lines)
	_love(db, lines)
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
	lines.append("- Aşağıdaki tablolar vakitten ve havadan bağımsızdır (koşulsuz). Yalnızca belli vakitte gelen tür")
	lines.append("  (Ay Turnası, Kocabaş) kendi vaktindeki oranıyla yazılır (ör. \"gece %2\"). Vakte ve havaya göre")
	lines.append("  oranlar: \"Vakit ve hava\" bölümü.")
	lines.append("")
	for z in zones:
		var opens := "başta açık" if int(z["rank"]) <= 1 else "rütbe %d" % int(z["rank"])
		if bool(z["boat"]):
			opens += ", yalnızca sandalla"
		lines.append("### %s (`%s`; %s)" % [_name("ZONE_" + str(z["id"])), z["id"], opens])
		lines.append("")
		var suggest := str(z["suggest"])
		if not suggest.is_empty():
			lines.append("Dede'nin önerisi: %s (\"%s\")." % [_name("UI_TECH_" + suggest).to_lower(),
					_name("UI_DEDE_SUGGEST_" + str(z["id"]))])
			lines.append("")
		for t: String in ContentDB.TECHNIQUES:
			if not db.has_technique(t) or not CatchOdds.allows(z, t):
				continue
			var at := db.technique_rank(t)
			lines.append("#### %s%s" % [_name("UI_TECH_" + t), "" if at <= 1 else " (rütbe %d)" % at])
			lines.append("")
			_tables(db, z, lines, t)
		_trap_table(db, z, lines)


## İri türler ve takımın taşıması (fish.json fight.heavy, gear.json carry; docs/gdd.md §5).
func _big_fish(db: ContentDB, lines: PackedStringArray) -> void:
	var names := PackedStringArray()
	for f in db.fish:
		if bool((f["fight"] as Dictionary)["heavy"]):
			names.append(_name("FISH_" + str(f["id"])).to_lower())
	lines.append("## İri balık ve takım")
	lines.append("")
	lines.append("İri türlerin (%s) boyu çekişini artırır. Bir iri balığı ancak yıldızını taşıyan kamış ve" % ", ".join(names))
	lines.append("misina rahat tutar; ikisinin küçüğü işler. Takım taşımıyorsa balık fazla iridir: takılınca \"Çok iri!\"")
	lines.append("çıkar, sakinken de gerilim kırmızıya çeker, bırakınca balık hızla uzaklaşır. Misina koparsa ya da balık")
	lines.append("kaçarsa Dede eksik takımı söyler. Kolay modda kopma yok; fazla iri balık yalnızca yavaş gelir. Öteki")
	lines.append("türler her boyda bambu oltayla tutulur.")
	lines.append("")
	lines.append("| Takım | Fiyat | Rütbe | Taşır |")
	lines.append("|---|---|---|---|")
	for g in db.gear_in("rod") + db.gear_in("line"):
		var price := "başlangıç" if int(g["price"]) == 0 else _number(float(g["price"]))
		lines.append("| %s | %s | %d | %s |" % [_name("GEAR_" + str(g["id"])), price, int(g["rank"]), "★".repeat(int(g["carry"]))])
	lines.append("")


## Bir yerin (göl ya da bölge: fish_ids, fish_weights) bir teknikle tür ve nadirlik tabloları, o
## tekniğin yemine (şamandıra ve dip: yem, spin: yapay yem, sinek: sinek) göre. O teknikle gelmeyen tür
## yazılmaz.
func _tables(db: ContentDB, spot: Dictionary, lines: PackedStringArray, technique: String = "float") -> void:
	var slot := _attract_slot(db, technique)
	var baits: Array[Dictionary] = db.gear_in(slot)
	var odds: Array[Dictionary] = []
	for bait in baits:
		odds.append(CatchOdds.species_ppm(db, spot, {"attract": bait["attract"], "technique": technique}))
	lines.append("Bir gölgenin o tür olma şansı, kuşanılan %s göre:" % str(ATTRACT_SLOTS[slot][1]))
	lines.append("")
	var header := "| Tür | English | Nadirlik | Boy (cm) | Değer (para) | Gölge (m) | İri |"
	var rule := "|---|---|---|---|---|---|---|"
	for bait in baits:
		header += " %s |" % _name("GEAR_" + str(bait["id"]))
		rule += "---|"
	lines.append(header)
	lines.append(rule)
	var ids: PackedStringArray = spot["fish_ids"]
	for id in ids:
		# O teknikle gelmeyen tür (şamandırada aynalı sazan: yalnızca dip) yazılmaz.
		if db.affinity(id, technique) <= 0.0:
			continue
		var f := db.fish_by_id(id)
		var span: Vector2i = f["size_cm"]
		var value := "%d–%d" % [Economy.fish_value(db, id, span.x), Economy.fish_value(db, id, span.y)]
		if Bucket.release_only(db, id):
			value = "satılmaz (bırakılır)"
		var row := "| %s | %s | %s | %d–%d | %s | %s | %s |" % [_name("FISH_" + id), _name("FISH_" + id, "en"),
				_name("RARITY_" + db.rarity_id(int(f["rarity"]))), span.x, span.y, value, _number(float(f["shadow_m"])),
				"✓" if bool((f["fight"] as Dictionary)["heavy"]) else ""]
		var own := CatchOdds.own_conditions(db, id)
		for b in baits.size():
			if own.is_empty():
				row += " %s |" % _percent(int(odds[b].get(id, 0)))
				continue
			# Yalnızca belli vakitte gelen tür: kendi vaktindeki oranı.
			var ctx := own.duplicate()
			ctx["attract"] = baits[b]["attract"]
			ctx["technique"] = technique
			row += " %s %s |" % [_when_label(own), _percent(int(CatchOdds.species_ppm(db, spot, ctx).get(id, 0)))]
		lines.append(row)
	lines.append("")
	var top := CatchOdds.top_rarity(db, spot, technique)
	if slot == "bait":
		lines.append("Yeme göre nadirlik oranları ve balık başına ortalama değer ile rütbe puanı (yem bedeli düşülmeden):")
		header = "| Yem | Fiyat (para / paket) |"
	else:
		var by := str(ATTRACT_SLOTS[slot][1])
		lines.append("%s göre nadirlik oranları ve balık başına ortalama değer ile rütbe puanı:" % (by.left(1).to_upper() + by.substr(1)))
		header = "| %s | Fiyat (para) |" % str(ATTRACT_SLOTS[slot][0])
	lines.append("")
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
		var price := ""
		if slot == "bait":
			price = "bedava, sınırsız" if int(bait["price"]) <= 0 else "%d / %d" % [int(bait["price"]), int(bait["pack"])]
		else:
			price = "başlangıç" if int(bait["price"]) <= 0 else "%d (rütbe %d)" % [int(bait["price"]), int(bait["rank"])]
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


## Vakit ve hava (docs/gdd.md §10.5): kurallar, türlerin sevdiği vakit ve hava, her bölgede şamandırayla
## (solucan) ve bölgenin önerdiği teknikle vakte ve havaya göre oranlar (göl sevgisi: _love).
func _world(db: ContentDB, spot_id: String, lines: PackedStringArray) -> void:
	var rules := db.rules
	lines.append("## Vakit ve hava")
	lines.append("")
	lines.append("- Bir oyun günü %d dakika: sabah, öğle, akşam, gece %d'şar dakika. Saat yalnızca oynarken akar (oyuncu" % [
			roundi(DayClock.day_s(rules) / 60.0), roundi(rules.phase_s / 60.0)])
	lines.append("  yokken, panel açıkken durur); Dede'yle çay sonraki vakte geçirir.")
	var total := 0
	for w in rules.weather_weights:
		total += w
	var weather := PackedStringArray()
	for k in Weather.KINDS.size():
		weather.append("%s %s" % [_name("WEATHER_" + Weather.KINDS[k]).to_lower(),
				_percent(roundi(rules.weather_weights[k] * float(PPM) / total))])
	lines.append("- Her oyun günün havası önceden belli (bugün ve yarın gösterilir): %s. İlk gün açık. Sisli günde sis" % ", ".join(weather))
	lines.append("  yalnızca sabah ve gece, öğle ve akşam bulutlu. Yağmurlu gece fırtınadır.")
	lines.append("- Yağmurda gölgeler takımı %s kat uzaktan fark eder, %s kat hızlı yaklaşır." % [_number(rules.rain_notice),
			_number(rules.rain_approach)])
	lines.append("- Türün oranı vaktin ve havanın çarpanıyla değişir (aşağıda; yazılmayan 1). Vakit çarpanlarının ortalaması")
	lines.append("  her türde 1 (`test_content_db` denetler): vakit balığın ne zaman geldiğini değiştirir, kazancı değil.")
	lines.append("")
	lines.append("| Tür | Sabah | Öğle | Akşam | Gece | Hava |")
	lines.append("|---|---|---|---|---|---|")
	for f in db.fish:
		var id := str(f["id"])
		var row := "| %s |" % _name("FISH_" + id)
		var own := CatchOdds.own_conditions(db, id)
		for phase in DayClock.PHASES:
			if own.is_empty():
				row += " %s |" % _number(db.when_mult(id, phase))
			else:
				row += " %s |" % ("✓" if db.fish_available(id, phase, str(own["weather"])) else "—")
		var likes := PackedStringArray()
		var only_weather: PackedStringArray = (f["only"] as Dictionary).get("weather", PackedStringArray())
		for kind in only_weather:
			likes.append("yalnızca " + _name("WEATHER_" + kind).to_lower())
		for kind: String in (f["weather"] as Dictionary):
			likes.append("%s %s" % [_name("WEATHER_" + kind).to_lower(), _number(float(f["weather"][kind]))])
		row += " %s |" % ", ".join(likes)
		lines.append(row)
	lines.append("")
	for z in db.zones_of(spot_id):
		var techniques: Array[String] = ["float"]
		if not str(z["suggest"]).is_empty():
			techniques.append(str(z["suggest"]))
		for t in techniques:
			lines.append("### %s, %s: vakte göre (açık hava) ve havaya göre (öğle)" % [_name("ZONE_" + str(z["id"])),
					_name("UI_TECH_" + t).to_lower()])
			lines.append("")
			lines.append("| Tür | Sabah | Öğle | Akşam | Gece | Bulutlu | Yağmurlu | Sisli (sabah) |")
			lines.append("|---|---|---|---|---|---|---|---|")
			var columns: Array[Dictionary] = []
			for phase in DayClock.PHASES:
				columns.append({ "phase": phase, "weather": "clear" })
			columns.append({ "phase": "noon", "weather": "cloudy" })
			columns.append({ "phase": "noon", "weather": "rain" })
			columns.append({ "phase": "morning", "weather": "fog" })
			var tables: Array[Dictionary] = []
			for c in columns:
				var ctx := c.duplicate()
				ctx["technique"] = t
				tables.append(CatchOdds.species_ppm(db, z, ctx))
			for id: String in (z["fish_ids"] as PackedStringArray):
				if db.affinity(id, t) <= 0.0:
					continue
				var row := "| %s |" % _name("FISH_" + id)
				for odds in tables:
					row += " %s |" % (_percent(int(odds[id])) if odds.has(id) else "—")
				lines.append(row)
			# Yağmurlu gece (fırtına): yalnızca o gece gelen tür varsa.
			var storm := CatchOdds.species_ppm(db, z, { "technique": t, "phase": "night", "weather": "rain" })
			for id: String in storm:
				if (db.fish_by_id(id)["only"] as Dictionary).has("weather"):
					lines.append("")
					lines.append("Fırtınalı gecede (yağmurlu gece) %s: %s." % [_name("FISH_" + id), _percent(int(storm[id]))])
			lines.append("")


## Göl sevgisi (Dalga 4): seviyeler ve Nadir+ payı; çöp eşyaları (pay ve sevgi).
func _love(db: ContentDB, lines: PackedStringArray) -> void:
	var rules := db.rules
	lines.append("## Göl sevgisi ve çöp")
	lines.append("")
	lines.append("Göl sevgisi hiç azalmaz. Kaynakları: göle bırakılan balık (kademenin sevgisi: Nadirlikler tablosu), toplanan")
	lines.append("çöp ve Dede'nin istekleri. Her seviye %s ve üstü kademelerin ağırlığını artırır (sonra oranlar yeniden" % \
			_name("RARITY_" + rules.love_from))
	lines.append("normalleştirilir; defterdeki oranlar bu payla). Göl de güzelleşir: daha çok çiçek ve nilüfer, daha berrak su,")
	lines.append("3. seviyeden sonra gündüz kelebekler.")
	lines.append("")
	lines.append("| Seviye | Toplam sevgi | %s+ ağırlığı |" % _name("RARITY_" + rules.love_from))
	lines.append("|---|---|---|")
	for i in rules.love_levels.size():
		lines.append("| %d | %d | ×%s |" % [i + 1, rules.love_levels[i], _number(LakeLove.rare_bonus_pm(rules, i + 1) / 1000.0)])
	lines.append("")
	lines.append("**Çöp:** dipte tutulan balığın yanında %s, tuzakta kerevit başına %s (içerik yenilenirken yeni kerevit" % [
			_percent(rules.trash_bottom_ppm), _percent(roundi(rules.trash_trap_ppm / float(rules.trap_max)))])
	lines.append("sayısıyla: boş tuzak dolunca %s). Ne çıkacağı önceden belli: balıkta gölgenin zarı, tuzakta içerik kurulurken." % \
			_percent(rules.trash_trap_ppm))
	lines.append("Kovaya girmez, satılmaz; toplanınca göl sevgisi verir.")
	lines.append("")
	lines.append("| Eşya | Pay | Göl sevgisi |")
	lines.append("|---|---|---|")
	var total := 0
	for w in rules.trash_weights:
		total += w
	for i in rules.trash_ids.size():
		lines.append("| %s | %s | %d |" % [_name("ITEM_" + rules.trash_ids[i]),
				_percent(roundi(rules.trash_weights[i] * float(PPM) / total)), rules.trash_love[i]])
	lines.append("")


## Yalnızca belli vakitte gelen türün vakti (katalog: "gece", "fırtınalı gece").
static func _when_label(own: Dictionary) -> String:
	if str(own["weather"]) == "rain" and str(own["phase"]) == "night":
		return "fırtınalı gece"
	return _name("PHASE_" + str(own["phase"])).to_lower()


## Tekniğin tür çeken yuvası (şamandıra ve dip: yem, spin: yapay yem, sinek: sinek).
static func _attract_slot(db: ContentDB, technique: String) -> String:
	for slot in db.slots_for(technique):
		if ATTRACT_SLOTS.has(slot):
			return slot
	return "bait"


## Teknikler: açıldığı rütbe, ilk kamışı, nerede avlanıldığı; türlerin yatkınlığı ve tuzağa girenler.
func _techniques(db: ContentDB, spot_id: String, lines: PackedStringArray) -> void:
	var zones := db.zones_of(spot_id)
	lines.append("## Teknikler")
	lines.append("")
	lines.append("Bir gölgenin türü bölgenin doğma ağırlığı × yemin (yapay yemin, sineğin) çekimi × türün teknik")
	lines.append("yatkınlığıyla seçilir. Yatkınlığı olmayan tür o teknikle hiç gelmez; şamandırada Dalga 3 öncesi")
	lines.append("türlerin hepsi 1 (şamandıranın oranları değişmedi). Teknik bölgede avlanılmıyorsa (sinek yalnızca")
	lines.append("akıntılı bölgede) orada o teknikle gölge doğmaz. Balık takıldıktan sonraki çekişme her teknikte aynı.")
	lines.append("")
	lines.append("| Teknik | Açıldığı rütbe | İlk kamış | Avlanıldığı bölgeler |")
	lines.append("|---|---|---|---|")
	for t: String in ContentDB.TECHNIQUES:
		if not db.has_technique(t):
			continue
		var rod := db.rods_of(t)[0]
		var rod_text := "%s (%s)" % [_name("GEAR_" + str(rod["id"])), "başlangıç" if int(rod["price"]) <= 0 \
				else "%s para" % _number(float(rod["price"]))]
		var where := PackedStringArray()
		for z in zones:
			if CatchOdds.allows(z, t):
				where.append(_name("ZONE_" + str(z["id"])))
		lines.append("| %s | %d | %s | %s |" % [_name("UI_TECH_" + t), maxi(1, db.technique_rank(t)), rod_text,
				"hepsi" if where.size() == zones.size() else ", ".join(where)])
	var trap_rank := TrapSim.rank(db)
	if trap_rank > 0:
		var where := PackedStringArray()
		for z in zones:
			if not (z["trap_ids"] as PackedStringArray).is_empty():
				where.append(_name("ZONE_" + str(z["id"])))
		var first := db.gear_in("trap")[0]
		lines.append("| %s | %d | %s (%s para) | %s |" % [_name("UI_BAG_TRAP"), trap_rank, _name("GEAR_" + str(first["id"])),
				_number(float(first["price"])), ", ".join(where)])
	lines.append("")
	lines.append("Türlerin teknik yatkınlığı (çarpan; boş: o teknikle gelmez) ve tuzağa girdiği bölgeler:")
	lines.append("")
	var header := "| Tür | Nadirlik |"
	var rule := "|---|---|"
	for t: String in ContentDB.TECHNIQUES:
		if db.has_technique(t):
			header += " %s |" % _name("UI_TECH_" + t)
			rule += "---|"
	lines.append(header + " Tuzak |")
	lines.append(rule + "---|")
	for f in db.fish:
		var id := str(f["id"])
		var row := "| %s | %s |" % [_name("FISH_" + id), _name("RARITY_" + db.rarity_id(int(f["rarity"])))]
		for t: String in ContentDB.TECHNIQUES:
			if db.has_technique(t):
				var aff := db.affinity(id, t)
				row += " %s |" % ("×" + _number(aff) if aff > 0.0 else "")
		var traps := PackedStringArray()
		for z in zones:
			if id in (z["trap_ids"] as PackedStringArray):
				traps.append(_name("ZONE_" + str(z["id"])))
		lines.append(row + " %s |" % ", ".join(traps))
	lines.append("")


## Bölgenin kerevit tuzağı tablosu (spots.json trap; yoksa yazılmaz): tuzağa giren tür, şansı, değeri.
func _trap_table(db: ContentDB, zone: Dictionary, lines: PackedStringArray) -> void:
	var ids: PackedStringArray = zone["trap_ids"]
	if ids.is_empty():
		return
	var weights: PackedInt32Array = zone["trap_weights"]
	var total := 0
	for w in weights:
		total += maxi(0, w)
	var rules := db.rules
	lines.append("#### %s (rütbe %d)" % [_name("UI_BAG_TRAP"), TrapSim.rank(db)])
	lines.append("")
	lines.append("Gerçek saatle %d dakikada bir tuzağa bir tür girer, en çok %d birikir; içindekiler tuzak kurulunca" % [
			roundi(rules.trap_fill_s / 60.0), rules.trap_max])
	lines.append("belli olur. Tuzaktan gelen balık şans garantisi sayaçlarını ilerletmez.")
	lines.append("")
	lines.append("| Tür | Nadirlik | Şans | Değer (para) | Ortalama değer |")
	lines.append("|---|---|---|---|---|")
	for i in ids.size():
		var id := ids[i]
		var f := db.fish_by_id(id)
		var span: Vector2i = f["size_cm"]
		lines.append("| %s | %s | %s | %d–%d | %s |" % [_name("FISH_" + id), _name("RARITY_" + db.rarity_id(int(f["rarity"]))),
				_percent(roundi(float(Dice.PPM) * maxi(0, weights[i]) / maxi(1, total))), Economy.fish_value(db, id, span.x),
				Economy.fish_value(db, id, span.y), _number(_mean_value(db, id))])
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
