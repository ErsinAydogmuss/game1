class_name Elder
extends Villager
## Dede: iskelenin kenarında oturur, bacakları suya sarkar; yanında çay bardağı. Kameraya dönük
## oturur ki yüzü görünsün. Konuşma, bakış, balon ve dokunma Villager'da: konuşurken (ipucu
## değişince, ona dokununca) oyuncuya bakar; balık tutulunca oturduğu yerde sevinir; olta sudayken
## şamandırayı izler (focus); boşta gölde arada bir sağa sola bakınır.
## Görünüm ElderBody (KayKit Barbarian) ya da yedek ToyElder; ikisi aynı arayüzü taşır.

## Dede'ye dokununca sırayla söylediği öğütler: çeviri anahtarı ve sayısı (strings.csv).
const TIP_KEY := "UI_DEDE_TIP_%d"
const TIP_COUNT := 6
## Yürüme engeli: oturma noktasından içeri doğru gövdenin ortası ve yarıçapı (m).
const BODY_INSET := 0.15
const BODY_RADIUS := 0.25
const TEA := Color("#b5481c")
const GLASS := Color("#f3e7d0")
const SAUCER := Color("#f6f3ec")

## true ise KayKit modeli olsa bile kodla kurulan model kullanılır (testler).
static var force_toy: bool = false

## Bu Dede için yedek model (karakter sayfası karşılaştırması); _ready'den önce verilir.
var use_toy: bool = false

var _seat := Vector3.ZERO


func _make_body() -> Node3D:
	if ElderBody.available() and not force_toy and not use_toy:
		return ElderBody.new()
	return ToyElder.new()


func _low_point() -> Vector3:
	return _seat + Vector3(0.0, 0.1, 0.0)


## KayKit modeli mi kullanılıyor?
func is_rigged() -> bool:
	return _body is ElderBody


## Oturtur: edge iskelenin kenarındaki nokta (dünya xz), facing dışa doğru (suya), deck_y güverte.
## Oturma noktası (diz arkası) kenara gelir; bacaklar dışarı sarkar. Yanına çay bardağı konur.
func seat(edge: Vector2, facing: Vector2, deck_y: float) -> void:
	_facing = facing.normalized()
	rotation = Vector3(0.0, atan2(_facing.x, _facing.y), 0.0)
	var offset: Vector3 = _body.call("seat_offset")
	_seat = Vector3(edge.x, deck_y, edge.y)
	position = _seat - basis * offset
	_add_tea()


## Balıkçının giremeyeceği daire: Vector3(x, z, yarıçap) (Angler.blockers).
func blocker() -> Vector3:
	var c := Vector2(_seat.x, _seat.z) - _facing * BODY_INSET
	return Vector3(c.x, c.y, BODY_RADIUS)


## Yanında, güvertede ince belli çay bardağı ve tabağı (sağ yanında, kenardan içeride). Oyun
## ölçeğinde okunsun diye gerçeğinden iri.
func _add_tea() -> void:
	var tea := Props.pivot(self, Vector3.ZERO, "Tea")
	tea.global_position = _seat + global_basis * Vector3(-0.3, 0.0, -0.25)
	tea.scale = Vector3.ONE * 1.5
	Props.cylinder(tea, 0.075, 0.07, 0.014, Vector3(0, 0.007, 0), SAUCER, 14)
	Props.cylinder(tea, 0.03, 0.038, 0.05, Vector3(0, 0.039, 0), TEA, 10)
	Props.cylinder(tea, 0.044, 0.03, 0.06, Vector3(0, 0.094, 0), TEA, 10)
	Props.cylinder(tea, 0.046, 0.046, 0.012, Vector3(0, 0.127, 0), GLASS, 10)
	# Tek ağ (bir çizim). Gölge haritasının bir pikselinden ince: gölgesi görünmez, çizimi boşa gider.
	MeshBatch.merge(tea).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
