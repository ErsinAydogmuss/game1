class_name FishShadow
extends RefCounted
## Gölde dolaşan bir balık gölgesi. Türü ve boyu doğduğu anda kendi seed'li zarıyla belirlenir
## (gizli ama değişmez); hareketi de aynı zardan gelir: aynı girdilerle hep aynı yol.
## Gölgenin boyu balığın boyunu ele verir, türünü vermez.

enum Mode { WANDER, PAUSE, APPROACH, NIBBLE, FLEE, HOOKED }

var id: int = 0
var seed: int = 0
var rng := RandomNumberGenerator.new()
var fish_index: int = 0
var fish_id: String = ""
var rarity: int = 0
## Boy yüzdeliği (ppm).
var percentile: int = 0
var size_cm: int = 0
var stars: int = 1
## Gölge uzunluğu (m).
var length: float = 0.5
var pos := Vector2.ZERO
## Baktığı yön (birim vektör).
var heading := Vector2(0.0, -1.0)
## Dolaşma hızı (m/sn).
var speed: float = 0.4
var mode: Mode = Mode.PAUSE
var target := Vector2.ZERO
## Duraklama ya da kaçış için kalan adım.
var timer: int = 0
## İlk av (senaryolu): hep fark eder, korkmaz, dürtmez, kaçmaz.
var scripted: bool = false
## Çağrılan hikâye balığı (Gölün Bekçisi; ShadowSim.summon): göldeyken takımı yalnızca o fark eder;
## korkmaz, vazgeçmez, erken dokunuşu ve kaçan vuruşu bağışlar (ilk av gibi) ama dürter ve gerçekten
## çekişir. Gölgelerin sayısına girmez, gidince yerine yenisi doğmaz.
var summoned: bool = false
## Senaryolu ve çağrılan gölgenin dolaştığı yer.
var home := Vector2.ZERO
## Kolay modda erken dokunuşla kaç kez irkildi.
var startles: int = 0
## Yolu kapalı olduğu için vazgeçti: şamandıra yeniden düşene kadar onu fark etmez.
var bored: bool = false
## Hedefi takımın çevresi mi (toplanma; dipte yemin kokusuna daha hızlı yüzer: rig.gather_speed)?
var gathering: bool = false
## Şans garantisiyle doğdu (aynı anda yalnızca bir tane).
var pity: bool = false
## Doğduğu bölge (LakeShape.zone_grid sırası; -1 bilinmiyor). Türü bu bölgenin oranından gelir.
var zone: int = -1
## Balıkçıdan çok uzakta kaldığı için gölden çekildi: yerine kısa sürede yenisi doğar.
var recycled: bool = false


func mode_name() -> String:
	return str(Mode.find_key(mode)).to_lower()
