class_name GraphicsRules
extends RefCounted
## Grafik kalitesi (Ayarlar: Düşük / Orta / Yüksek; ayar "graphics"). Kazı'dan (docs/performans-notlari.md §1):
## telefonlar 3D'yi ekranın tam çözünürlüğünde (FHD+ ekranda 2,6 milyon piksel; kenar yumuşatma, parlama,
## gölgeyle) çizerken kasıyordu. Kayıtta ayar yoksa Android'de Orta, iPhone'da ve bilgisayarda Yüksek (eskisi gibi).
## - Yüksek: 3D ekranın tam çözünürlüğünde, gölge haritası 2048, kenar yumuşatma 2x, parlama.
## - Orta: 3D en fazla 1,7 milyon pikselde (Viewport.scaling_3d_scale; arayüz keskin kalır), gölge haritası 1024;
##   gerisi Yüksek gibi.
## - Düşük: 3D en fazla 1 milyon pikselde; güneşin gölgesi, kenar yumuşatma ve parlama kapalı (balığın,
##   balıkçının ve köylülerin yuvarlak gölgesi kalır: o bir düzlem).
## Telefonda 90/120 Hz ekranda kare sınırı 60: oyun boşuna iki kat çizip telefonu ısıtır, ısınan telefon da
## yavaşlar. 60 Hz ekranda sınır yok (V-Sync zaten 60; ikisi birlikte ara ara kare kaçırtıyordu). Main uygular
## (akvaryumun ve dolabın önizlemesi de seviyeye bakar).

const LOW := "low"
const MEDIUM := "medium"
const HIGH := "high"
## Ayarlar'daki sıra.
const LEVELS: Array[String] = [LOW, MEDIUM, HIGH]
## 3D'nin en fazla piksel sayısı (0: sınır yok). FHD+ telefonda ölçek Orta'da ~0,81, Düşük'te ~0,62.
const PIXEL_BUDGET := { LOW: 1_000_000, MEDIUM: 1_700_000, HIGH: 0 }
## Ölçeğin alt sınırı: çok yüksek çözünürlüklü tablette de bundan bulanık olmaz.
const MIN_SCALE := 0.5
## Güneşin gölge haritasının kenarı (piksel; Düşük'te gölge yok).
const SHADOW_SHARP := 2048
const SHADOW_SMOOTH := 1024
## Telefonda kare sınırı (Engine.max_fps); ekran bundan hızlı tazeleniyorsa uygulanır.
const MOBILE_FPS := 60
## Kare sınırının uygulandığı işletim sistemleri (OS.get_name()).
const MOBILE := ["Android", "iOS"]


## Kayıtta ayar yoksa: Android'de Orta, öbürlerinde Yüksek.
static func default_level(os_name: String) -> String:
	return MEDIUM if os_name == "Android" else HIGH


## Kayıttaki değer (bilinmeyen ya da eksikse varsayılan).
static func level_of(value: Variant, os_name: String) -> String:
	var level := str(value) if value != null else ""
	return level if LEVELS.has(level) else default_level(os_name)


## 3D'nin çözünürlük ölçeği: pencere (piksel) seviyenin bütçesinden büyükse bütçeye iner, MIN_SCALE'in altına
## inmez.
static func render_scale(window: Vector2i, level: String) -> float:
	var budget := float(int(PIXEL_BUDGET.get(level, 0)))
	var pixels := float(window.x) * float(window.y)
	if budget <= 0.0 or pixels <= budget:
		return 1.0
	return maxf(MIN_SCALE, sqrt(budget / pixels))


## Güneş gölge düşürür mü.
static func shadows(level: String) -> bool:
	return level != LOW


static func shadow_size(level: String) -> int:
	return SHADOW_SHARP if level == HIGH else SHADOW_SMOOTH


## Gölün kenar yumuşatması (Viewport.MSAA_*). Android'de hiçbir seviyede yok (Kazı 0.14.4, docs/performans-notlari.md
## §3.6): Kazı'nın Play Console'daki kendiliğinden kapanmalarının hepsi Mali sürücüsündeydi, çizim tamponu bağlanırken
## ya da temizlenirken (glBindFramebuffer, glClear) bellek alınamıyordu ("Scudo ERROR: internal map failure").
## Compatibility çizicisi MSAA'yı telefonda EXT_multisampled_render_to_texture ile yapar; o tamponun belleğini sürücü
## bağlama anında kendisi ayırır. Kazı'da Android'de MSAA kapanınca çökme bitti. os_name: OS.get_name() (testler
## başkasını verir).
static func msaa(level: String, os_name: String = OS.get_name()) -> int:
	if os_name == "Android":
		return Viewport.MSAA_DISABLED
	return Viewport.MSAA_DISABLED if level == LOW else Viewport.MSAA_2X


## Panellerdeki küçük 3D önizlemelerin (akvaryum, dolap) kenar yumuşatması. Android'de yok (msaa'daki neden).
static func preview_msaa(level: String, os_name: String = OS.get_name()) -> int:
	if os_name == "Android":
		return Viewport.MSAA_DISABLED
	return Viewport.MSAA_DISABLED if level == LOW else Viewport.MSAA_2X


## Parlama (glow): ışık sütunu, suyun parıltısı.
static func glow(level: String) -> bool:
	return level != LOW


## Kare sınırı (0: sınır yok, ekranın tazelenme hızı). refresh_rate: ekranın tazelenme hızı (Hz; bilinmiyorsa 0 ya
## da eksi: sınır konur). Bilgisayarda sınır yok (V-Sync).
static func max_fps(os_name: String, refresh_rate: float) -> int:
	if not MOBILE.has(os_name):
		return 0
	return MOBILE_FPS if refresh_rate <= 0.0 or refresh_rate > MOBILE_FPS + 1.0 else 0
