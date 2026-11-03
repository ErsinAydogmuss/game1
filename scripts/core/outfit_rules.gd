class_name OutfitRules
extends RefCounted
## Kıyafetlerin verisi (data/outfits.json; Dalga 5, docs/gdd.md §7). Yükleyen ContentDB denetler (validate).
## Her kıyafetin yuvası (SaveData.OUTFIT_SLOTS: hat, vest, rod), açılma şartı ve görünüşü:
## - unlock: start (başta açık; her yuvada tam bir tane: varsayılan), rank (rütbe), species (defterdeki tür),
##   requests (biten istek: stats.requests), love (göl sevgisinin seviyesi), keeper (Gölün Bekçisi göle bırakıldı),
##   cat (Tekir'in n. hediyesi: değerler 1'den sırayla, boşluksuz; hediye sırası buradan türer);
## - value: şartın sayısı (start ve keeper'da yok);
## - shape (şapka: HAT_SHAPES), color, band (şapkanın rengi ve bandı; yelekte color; kamışta kaplamanın rengi ve
##   sargısı: varsayılan kamışta yok, kamışın kendi rengi).
## Kimlikler değişmez (kayıt kimliği tutar); yeni kıyafet sona eklenir.

const KINDS: Array[String] = ["start", "rank", "species", "requests", "love", "keeper", "cat"]
## Şapkaların biçimleri (HatModel kurar).
const HAT_SHAPES: Array[String] = ["bucket", "straw", "beanie", "cap", "fly", "crown", "keeper"]

## Dosyadaki sırayla: { id, slot, unlock, value, shape, color, band } (renkler "#rrggbb" ya da boş).
var items: Array[Dictionary] = []
var _index: Dictionary = {}


static func from_dict(d: Dictionary, errors: PackedStringArray) -> OutfitRules:
	var r := OutfitRules.new()
	if d.is_empty():
		errors.append("outfits.json: boş ya da okunamadı")
		return r
	for raw: Variant in d.get("items", []):
		if typeof(raw) != TYPE_DICTIONARY:
			errors.append("outfits.json: kıyafet bir nesne olmalı")
			continue
		var e: Dictionary = raw
		var item := {
			"id": str(e.get("id", "")),
			"slot": str(e.get("slot", "")),
			"unlock": str(e.get("unlock", "")),
			"value": int(e.get("value", 0)),
			"shape": str(e.get("shape", "")),
			"color": str(e.get("color", "")),
			"band": str(e.get("band", "")),
		}
		r._index[item["id"]] = r.items.size()
		r.items.append(item)
	return r


## Kıyafet (kimliğiyle; yoksa boş).
func item(id: String) -> Dictionary:
	var i: int = _index.get(id, -1)
	return items[i] if i >= 0 else {}


## Yuvanın kıyafetleri, dosyadaki sırayla.
func of_slot(slot: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for e in items:
		if str(e["slot"]) == slot:
			out.append(e)
	return out


## Yuvanın varsayılanı (start; yoksa boş).
func default_of(slot: String) -> String:
	for e in items:
		if str(e["slot"]) == slot and str(e["unlock"]) == "start":
			return str(e["id"])
	return ""


## Tekir'in n. hediyesi (1'den; yoksa boş).
func cat_gift(n: int) -> String:
	for e in items:
		if str(e["unlock"]) == "cat" and int(e["value"]) == n:
			return str(e["id"])
	return ""


## Tekir'in hediyelerinin sayısı.
func cat_gift_count() -> int:
	var n := 0
	for e in items:
		if str(e["unlock"]) == "cat":
			n += 1
	return n


## Denetim (ContentDB): kimlikler tekrarsız ve dolu, bilinen yuva ve şart, her yuvada tam bir başlangıç kıyafeti,
## şartların sayısı geçerli (rütbe, tür, sevgi seviyesi aralıkta; Tekir'in hediyeleri 1..n boşluksuz), şapkanın
## biçimi ve renkleri, yeleğin rengi, kamış kaplamasının renkleri (varsayılan kamış renksiz).
func validate(db: ContentDB, errors: PackedStringArray) -> void:
	var seen := {}
	var starts := {}
	var gifts: Array[int] = []
	for e in items:
		var id := str(e["id"])
		var slot := str(e["slot"])
		var kind := str(e["unlock"])
		var value := int(e["value"])
		if id.is_empty() or seen.has(id):
			errors.append("outfits.json: kimlik boş ya da tekrar: %s" % id)
		seen[id] = true
		if not slot in SaveData.OUTFIT_SLOTS:
			errors.append("outfits.json: %s: yuva bilinmiyor: %s" % [id, slot])
		if not kind in KINDS:
			errors.append("outfits.json: %s: şart bilinmiyor: %s" % [id, kind])
			continue
		match kind:
			"start":
				starts[slot] = int(starts.get(slot, 0)) + 1
			"rank":
				if value < 2 or value > db.max_rank():
					errors.append("outfits.json: %s: rütbe 2..%d olmalı" % [id, db.max_rank()])
			"species":
				if value < 1 or value > db.fish.size():
					errors.append("outfits.json: %s: tür sayısı 1..%d olmalı" % [id, db.fish.size()])
			"requests":
				if value < 1:
					errors.append("outfits.json: %s: istek sayısı pozitif olmalı" % id)
			"love":
				if value < 2 or value > db.rules.love_levels.size():
					errors.append("outfits.json: %s: sevgi seviyesi 2..%d olmalı" % [id, db.rules.love_levels.size()])
			"cat":
				gifts.append(value)
		var colors: Array[String] = []
		match slot:
			"hat":
				if not str(e["shape"]) in HAT_SHAPES:
					errors.append("outfits.json: %s: şapkanın biçimi bilinmiyor: %s" % [id, e["shape"]])
				colors = ["color", "band"]
			"vest":
				colors = ["color"]
			"rod":
				if kind != "start":
					colors = ["color", "band"]
		for key in colors:
			if not Color.html_is_valid(str(e[key])):
				errors.append("outfits.json: %s: %s geçerli bir renk olmalı" % [id, key])
	for slot: String in SaveData.OUTFIT_SLOTS:
		if int(starts.get(slot, 0)) != 1:
			errors.append("outfits.json: %s yuvasında tam bir başlangıç kıyafeti olmalı" % slot)
	gifts.sort()
	for i in gifts.size():
		if gifts[i] != i + 1:
			errors.append("outfits.json: Tekir'in hediyeleri 1'den sırayla, boşluksuz olmalı")
			break
