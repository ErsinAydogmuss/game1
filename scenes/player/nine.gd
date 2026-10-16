class_name Nine
extends Villager
## Nine: Dede'nin eşi, iskelenin başındaki dükkânı (ShopStall) işletir. Tezgâhın arkasında ayakta
## durur, yüzü dükkânın önüne (iskeleye ve kameraya) dönük. Balıkçı yaklaşınca ona bakar
## (watch); dokununca selam verir (balon, baş sallama, tezgâha uzanma) ve dükkân açılır (main).
## Konuşma, bakış, balon ve dokunma Villager'da.
## Görünüm NineBody (KayKit Mage) ya da yedek ToyNine; ikisi aynı arayüzü taşır.

## Dokununca sırayla söylediği selamlar: çeviri anahtarı ve sayısı (strings.csv).
const HELLO_KEY := "UI_NINE_HELLO_%d"
const HELLO_COUNT := 4
## Balıkçı bu kadar yakındayken (m) ona bakar.
const WATCH_RANGE := 4.5

## true ise KayKit modeli olsa bile kodla kurulan model kullanılır (testler).
static var force_toy: bool = false

## Bu Nine için yedek model (karakter sayfası karşılaştırması); _ready'den önce verilir.
var use_toy: bool = false

var _feet := Vector3.ZERO


func _make_body() -> Node3D:
	if NineBody.available() and not force_toy and not use_toy:
		return NineBody.new()
	return ToyNine.new()


func _low_point() -> Vector3:
	return _feet + Vector3(0.0, 0.3, 0.0)


## KayKit modeli mi kullanılıyor?
func is_rigged() -> bool:
	return _body is NineBody


## Yerine koyar: spot ayakların yeri (dünya), facing yüzün baktığı yön (xz).
func stand(spot: Vector3, facing: Vector2) -> void:
	_facing = facing.normalized()
	rotation = Vector3(0.0, atan2(_facing.x, _facing.y), 0.0)
	_feet = spot
	position = spot


## Selam: balon, baş sallama, oyuncuya bakış ve tezgâha uzanma.
func greet() -> void:
	say()
	_body.call("give")


## Balıkçıyı izler: yakındaysa ona bakar (main her kare verir).
func watch(point: Vector3) -> void:
	focus = point
	has_focus = Vector2(point.x - _feet.x, point.z - _feet.z).length() <= WATCH_RANGE
