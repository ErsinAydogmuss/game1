class_name Moods
extends RefCounted
## Konuşanların ifadeleri: bir sözün (çeviri anahtarı) yüzü. Ersin'in portreleri
## assets/ui/portraits/<konuşan>_<ifade>.png; ifadeler: smile (gülümser), story (Dede parmağını
## kaldırıp anlatır, Nine paketi uzatır), wow (şaşırır, sevinir). İpucu çubuğu, balık kartındaki
## Dede satırı ve dükkânın başlığı aynı eşlemeyi kullanır. (Kazı'daki eğitimin MOODS düzeni.)

const SMILE := "smile"
const STORY := "story"
const WOW := "wow"
## Bütün ifadeler (her konuşanın her ifadesi için bir portre; test_moods denetler).
const ALL: Array[String] = [SMILE, STORY, WOW]
## Söz -> ifade. Listede olmayan söz gülümser.
const BY_KEY := {
	# İlk balıklarda Dede yol gösterir: talimatı anlatır, heyecanlı anda şaşırır.
	"UI_HINT_FIRST_SHADOW": STORY, "UI_HINT_CAST": STORY, "UI_HINT_NIBBLE": STORY, "UI_HINT_REEL": STORY,
	"UI_HINT_COMING": WOW, "UI_HINT_BITE": WOW, "UI_HINT_TOO_BIG": WOW,
	"UI_DEDE_BUCKET": STORY, "UI_DEDE_BAIT_OUT": STORY, "UI_DEDE_BOAT": STORY, "UI_DEDE_GATE": STORY, "UI_DEDE_LEGEND_NEAR": WOW,
	"UI_DEDE_ZONE_OPEN": WOW,
	# Spin: talimat anlatılır, peşindeki balık ve saldırı heyecanlı.
	"UI_HINT_SPIN_REEL": STORY, "UI_HINT_SPIN_FOLLOW": WOW, "UI_HINT_SPIN_STRIKE": WOW, "UI_DEDE_SNAG": STORY,
	# Dip: bekleyiş ve koklama anlatılır, koşu heyecanlı.
	"UI_HINT_BOTTOM_WAIT": STORY, "UI_HINT_BOTTOM_SNIFF": STORY, "UI_HINT_BOTTOM_RUN": WOW,
	"UI_DEDE_CARD_NEW": SMILE, "UI_DEDE_CARD_RECORD": WOW, "UI_DEDE_CARD_RELEASE": STORY,
	# Nine satın almada paketi uzatır, satışta sevinir.
	"UI_NINE_BOUGHT": STORY, "UI_NINE_SOLD": WOW,
}
## Ön ekle eşlenen sözler: Dede'nin öğütleri (UI_DEDE_TIP_1...), fazla iri balıkta takım öğüdü
## (UI_DEDE_TOO_BIG_...), kartta nadirliğe göre sözleri (UI_DEDE_CARD_<nadirlik>, Nadir ve üstü), yeni
## teknik açılınca (UI_DEDE_TECH_OPEN_<teknik>) ve ilk kez ele alınınca (UI_DEDE_TECH_FIRST_<teknik>).
## Önce BY_KEY bakılır.
const BY_PREFIX := {"UI_DEDE_TIP_": STORY, "UI_DEDE_TOO_BIG_": STORY, "UI_DEDE_CARD_": WOW,
		"UI_DEDE_TECH_OPEN_": WOW, "UI_DEDE_TECH_FIRST_": STORY}


## Sözün ifadesi.
static func of(key: String) -> String:
	if BY_KEY.has(key):
		return str(BY_KEY[key])
	for prefix: String in BY_PREFIX:
		if key.begins_with(prefix):
			return str(BY_PREFIX[prefix])
	return SMILE


## Konuşanın ("dede", "nine") bu sözdeki yüzü: Ersin'in portresi; o ifade yoksa gülümseyeni, o da
## yoksa null (çağıran modelden çekilen yedek yüzü kullanır).
static func face(speaker: String, key: String) -> Texture2D:
	var texture := ItemArt.portrait("%s_%s" % [speaker, of(key)])
	return texture if texture != null else ItemArt.portrait("%s_%s" % [speaker, SMILE])
