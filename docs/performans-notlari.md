# Mobil performans ve çökme notları (Kazı'dan öğrenilenler)

Kazı'da (Godot 4.7, Compatibility / OpenGL ES 3 çizicisi, Android + iPhone) Ekim-Kasım 2026'da kasma, takılma, ısınma,
bellek ve Android çökmeleri için yapılanların özeti. Başka bir oyunda aynı işleri yaptırmak için yazıldı: bu dosyayı o
oyunun Claude'una ver, "bunu bizim oyuna uygula, önce ölç" de (en altta hazır bir istek var).

Sürümler: 0.9.0-0.9.4 (21 Ekim: kasma, grafik ayarları, ısındırma), 0.14.3 (15 Kasım: kazarken kapanma, ekran kartı
belleği). Kod ve ölçüm araçları Kazı deposunda (`ErsinAydogmuss/game`); dosya adları aşağıda.

---

## 0. Kısa kontrol listesi

Yeni bir mobil oyunda sırayla:

1. **Ölçmeden düzeltme.** Önce botla ölç (kare süresi, derleme, bellek, ekran kartı nesneleri), sonra değiştir, sonra
   aynı ölçümü tekrarla (§5).
2. **Grafik ayarı:** Düşük / Orta / Yüksek. Android'de varsayılan Orta: 3D'yi en fazla 1,7 milyon pikselde çiz, arayüz
   keskin kalsın (§1).
3. **Kare sınırı:** Android'de 90/120 Hz ekranda 60 FPS. 60 Hz ekranda sınır koyma (§1).
4. **Gölgelendirici ısındırma:** açılış perdesinin arkasında her malzemeyi her ışık düzeninde bir kez çiz (§2.1).
   Telefondaki "anlık takılma"nın asıl sebebi buydu.
5. **Oyun karesinde diske dokunma:** sesler, görseller arka planda yüklensin; kayıt iş parçacığında yazılsın (§2.2).
6. **Her karede ağır GDScript yok:** dünyayı tek tek değil toplu oku; resim çizerken piksel piksel değil satır satır;
   ağ (mesh) kurmayı arka plana al (§2.3).
7. **Her karede ekran kartı nesnesi kurma:** 3D yazının (Label3D) rengini canlandırma, parçacığı havuzdan kullan, ağın
   boyunu her karede değiştirme (§3.3). Android'deki çökmenin en büyük şüphelisi buydu.
8. **Büyük görselleri ekran kartının sıkıştırmasıyla tut** (telefonda ASTC): bellek 4'te 1 (§3.4).
9. **Play Console çökmelerini sembollerle oku** (§4.1); telefonda `adb logcat` al (§4.3).
10. **Android Geri tuşu** oyunu kapatmasın (§6).

---

## 1. Grafik ayarları (Düşük / Orta / Yüksek)

Telefonlar 3D'yi ekranın tam çözünürlüğünde (FHD+ ekranda 2,6 milyon piksel; kenar yumuşatma, parlama, sis, gölgeyle)
çizerken kasıyordu. Çözüm: Ayarlar'da üç seviye, kayıtta yoksa Android'de Orta, iPhone ve bilgisayarda Yüksek.

| | Düşük | Orta (Android varsayılanı) | Yüksek |
|---|---|---|---|
| 3D çözünürlüğü | en fazla 1 milyon piksel (FHD+'da ölçek ~0,62) | en fazla 1,7 milyon piksel (~0,81) | ekranın tamamı |
| Güneşin gölgesi | kapalı | açık, gölge haritası 1024 | açık, 2048 |
| Kenar yumuşatma (MSAA) | kapalı | 2x | 2x |
| Parlama (glow) | kapalı | açık | açık |

- **Çözünürlük ölçeği:** `Viewport.scaling_3d_scale = sqrt(bütçe / piksel)`, en az 0,5. Compatibility'de çalışıyor
  (yalnızca bilinear); arayüz (2D) etkilenmez, keskin kalır.
- **Kare sınırı:** `Engine.max_fps = 60` yalnızca Android'de ve ekran 60 Hz'den hızlıysa. 0.9.0'da oyun 120 Hz ekranda
  saniyede 120 kareyi tam çözünürlükte çiziyor, telefon ısınıyor, ısınan telefon yavaşlıyordu ("10 dakikada
  kapanıyor" şikâyeti büyük olasılıkla buydu). 60 Hz ekranda sınır koyma: V-Sync zaten 60, ikisi birlikte ara ara kare
  kaçırtıyordu (0.9.1).
- **Ne zaman uygulanır:** ayar değişince ve pencere boyu değişince. Her setter'ı yalnızca değer değişince çağır:
  Kazı'da grafik ayarı her kazıda yeniden veriliyordu, `Light3D.shadow_enabled` aynı değerle bile ışığın bağlı olduğu her
  şeyi yeniden eşletir (0.14.3'te düzeltildi).
- **Ayrı dünyası olan görünümler** (dükkânın 3D vitrini gibi `SubViewport`'lar) de seviyeye baksın: vitrin Yüksek'te
  MSAA 4x, Orta'da 2x, Düşük'te kapalı.
- Kurallar saf bir sınıfta, test edilir: `scripts/core/graphics_rules.gd`, `tests/test_graphics_rules.gd`. Uygulayan:
  `scenes/main.gd` `_apply_graphics`.

```gdscript
# Özü (GraphicsRules + Main._apply_graphics):
const PIXEL_BUDGET := { "low": 1_000_000, "medium": 1_700_000, "high": 0 }
static func render_scale(window: Vector2i, level: String) -> float:
	var budget := float(int(PIXEL_BUDGET.get(level, 0)))
	var pixels := float(window.x) * float(window.y)
	if budget <= 0.0 or pixels <= budget:
		return 1.0
	return maxf(0.5, sqrt(budget / pixels))

static func max_fps(os_name: String, refresh_rate: float) -> int:
	if os_name != "Android":
		return 0
	return 60 if refresh_rate <= 0.0 or refresh_rate > 61.0 else 0

func _apply_graphics() -> void:            # ayar ve pencere boyu değişince
	var level := GameState.graphics_level()
	var scale := GraphicsRules.render_scale(DisplayServer.window_get_size(), level)
	if not is_equal_approx(scale, _render_scale):
		_render_scale = scale
		get_viewport().scaling_3d_scale = scale
	# MSAA, gölge haritası, gölge, parlama, kare sınırı: hepsi yalnızca değişince
	...
```

---

## 2. Takılmalar (stutter)

### 2.1 Gölgelendirici derlemesi: en büyük sebep

Telefonda "blok kırılırken anlık takılma"nın asıl sebebi buydu. Compatibility çizicisi her malzemeyi **ilk çizildiği
karede** derler (telefonda onlarca-yüzlerce ms) ve derleme anahtarı malzemeyle birlikte **ışık ve sis düzenidir**:

- sis türü (yüzeyde derinlik sisi, yer altında üstel),
- gölgeli güneş var mı,
- nesneye spot ya da yakın ışık (omni) vuruyor mu (Godot ışığı nesneyle kutularından eşler),
- MultiMesh mi.

Yeni oyunda ilk 10 dakikada 57 derleme ölçüldü: yüzeyden ilk inişte 27, güneş sönünce 11, ilk kırıntıda, ilk "+1 maden"
yazısında birkaç tane.

**Çözüm: ısındırma (`scenes/shader_warmup.gd`, 0.9.4).**
- Açılış görseliyle aynı perde (ilerleme çubuklu) ekranı örterken arkada oyunun bütün ışık düzenleri kurulur: yüzey,
  çukurun ağzı, fenerli sığ, güneşsiz derin, gece kampı.
- Her düzende birinci şahıs, arkadan ve üstten bakışla birkaç kare çizilir: kazı ve buluntu efektleri, bütün aletler,
  çantalar, taşıtlar, şapkalar, süsler. Bunlar bir "raf"ta göze yakın (fenerli), ortada (yalnızca spot) ve uzakta
  (ışıksız) durur.
- Kartların yazı boyları bütün harfleriyle perdenin altında bir kez çizilir.
- Derlenen gölgelendiriciler `user://shader_cache`'e yazılır; ikinci açılışta oradan yüklenir (kısa sürer).
- Takılırsa `MAX_FRAMES`'te perde yine kalkar (oyun asla perdede kalmaz).

**Isındırmayla ilgili tuzaklar:**
- Koddan kurulan `Shader` (`Shader.new()` + `code`) her nesnede ayrı derlenir. Aynı gölgelendiriciyi kullananlar tek
  `static var` paylaşsın. Kampta 17 bayrak kendi Shader'ını kuruyordu: aynı kod 17 kez derleniyordu.
- **Ortama `Sky` bağlama.** Sky'ın yansıma dokusu varken her malzeme yansıma haritalı ayrı bir düzende derlenir (yansıma
  kapalı olsa bile). Gece göğüne geçişte ~150 derleme bir anda oluyordu. Gece göğü, kameranın çevresinde ters yüzlü bir
  küre oldu.
- **Kendi ışığı ya da dünyası olan sahneler** ısındırmanın düzenlerinde yoktur. Halatla çıkış sahnesi (~17 derleme),
  dükkânın vitrini (~14) ve son sahneler için ikisinden biri yapılır:
  - sahne ilk kez ekran karanlıkken birer kare önceden çizilir (`Main._ascent_preroll`),
  - ya da ısındırmada geçici bir kopyası kurulur (`_warm_showcase`).
- Isındırmaya ışık kaynağı koyma: çevresini "ışıklı" derletip ışıksız hâllerini eksik bırakır.
- Ölçüm aracı: `tools/shader_compiles.py` oyunu boş bir veri klasörüyle çalıştırır, önbelleğe her yazışı bir derleme
  sayar, malzemeyi ve ışık düzenini kazılarla yan yana yazar. Hedef: "basla"dan sonra satır olmaması (§5).

### 2.2 Oyun karesinde diske dokunma

- İlk çalınan ses ve ilk bulunan eşyanın görseli `load()` ile o karede okunuyordu: telefonda 10 ms'yi aşan takılma.
  Çözüm: açılışta `ResourceLoader.load_threaded_request`, biten yükler her kare `load_threaded_get` ile alınır.
  Alınmayan yükler çıkışta "ObjectDB instances leaked" uyarısı verir.
- Otomatik kayıt iş parçacığında: sözlük o karede kurulur (derin kopya), JSON'a çevirme ve dosyaya yazma
  `WorkerThreadPool`'da. Biri yazılırken gelen bekler; çıkışta önce o beklenir. Dosya atomik yazılır (geçici dosya +
  yeniden adlandırma), bozuk kayıt `.corrupt` diye kenara alınır.
- Ağır arayüz (eşya kartı) istendiği karede değil bir sonrakinde kurulur.

### 2.3 Her karede ağır GDScript

- **Toplu okuma:** çevreyi saniyede birkaç kez tarayan kod hücre hücre `get_cell` çağırıyordu (binlerce GDScript çağrısı).
  Satır satır kopyalanan, çevresinde 1 hücre payı olan diziyle okunur, komşuya `±1`, `±PAD`, `±PAD²` ile bakılır
  (`MineWorld.read_padded`). Kandil taraması 2,8 ms'den 0,33 ms'ye indi.
- **Ağ (mesh) kurmak arka planda:** kazıda chunk'ın ağı `WorkerThreadPool`'da kurulur. Hücreler önce ana iş parçacığında
  okunur, arka plandaki iş dünyaya dokunmaz. Ağ sonraki karede takılır. Aynı chunk'a yeni iş gelirse eskisi atılır. Ağ
  kurucu iki kat hızlandı: altı yanı dolu hücre atlanır, yüz başına dizi açılmaz.
- **Koddan doku çizerken** piksel piksel `set_pixel` döngüsü kurma; satır satır `fill_rect` kullan. Düğmelerin parlak
  dokusu her yeni renkte ~50 ms'den ~1,6 ms'ye indi.
- **İşi karelere yay:** odaların süs ağları açılışta her kare bir tane kurulur, yeni odalar her kare bir tane döşenir.
- Arayüzde metin değişmedikçe satır yeniden kurulmaz (görev listesi yalnızca ilerleme yazısını günceller).

### 2.4 Ölçerken dikkat

- Kare süresini `delta`'dan değil gerçek saatten ölç (`Time.get_ticks_usec` farkı). Godot `delta`'yı yumuşatır,
  tek karelik takılmaları gizler.
- Ekransızda (headless) Godot kareyi 6,9 ms'ye tamamlar; `OS.low_processor_usage_mode_sleep_usec = 0` ile kalkar, o
  zaman kare süresi kodun süresidir (telefonda 2-5 kat uzun).
- Süre ölçen oyun kodunda `Time.get_ticks_*` değil `_process(delta)` toplamı kullan (video kaydında oyun zamanı yavaş
  akar).

---

## 3. Bellek ve Android çökmeleri

### 3.1 Play Console'da ne vardı (0.14.0, Kasım 2026)

- **Çökmeler:** SIGABRT. Telefonun ekran kartı sürücüsü (`libGLES_mali.so`; Helio G99 ve Dimensity 9300) çizim
  sırasında bellek ayıramıyor, Android'in bellek yöneticisi (`scudo`) eşleme alamayınca süreci durduruyor:
  `abort ← scudo::reportMapError ← MapAllocator::allocate ← malloc ← libGLES_mali.so`.
- **Sembollerle çözülen Godot işlevleri** (§4.1):
  - son kareyi ekrana kopyalama (`CopyEffects::draw_screen_quad` → `glDrawArrays`),
  - 3D tamponlarının kurulması (`RenderSceneBuffersGLES3::_check_render_buffers` → `glBindFramebuffer`),
  - sahneyi temizleme (`glClear`).
  Yani çökme tek bir yerde değil: bellek bitince sürücünün o anki ayırması patlıyor.
- **ANR "Input dispatching timed out":** ana iş parçacığı boştayken yakalanmış; büyük olasılıkla aynı bellek baskısı.
- 12-16 GB RAM'li telefonda bile oluyorsa sebep tek başına "bellek az" olamaz: sürücüye her karede çok sayıda yeni
  nesne kurdurmak (§3.3) ya da bellek eşlemesinin tükenmesi.

### 3.2 Sızıntı var mı: nasıl bakıldı

Masaüstünde (xvfb, llvmpipe) üç uzun deneme yapıldı. Llvmpipe ekran kartı nesnelerini RAM'de tuttuğu için oradaki bir
sızıntı da süreç belleğinde görünür. Hiçbirinde artış yoktu:

| Deneme | Ne yapıldı | Sonuç |
|---|---|---|
| `perf --part=soak` | 12 dk oyun (kazı, dedektör, halatla çıkış, satış) | RSS ~1,25 GB, eşlem ~2270: sabit |
| `perf --part=digsoak` | 15 dk durmadan kazı, 1475 blok, çağdan çağa | statik bellek, doku, tampon, düğüm, GL nesneleri: sabit |
| `perf --part=resize` | pencere boyu 120 kez değişti (reklamdan, başka uygulamadan dönüş gibi) | sabit |

Sızıntı yoktu, ama ekran kartı nesnelerini sayan araç (`tools/gl_count.c`, §5) **kurulup silinen** nesnelerde büyük bir
çalkantı gösterdi.

### 3.3 Her karede ekran kartı nesnesi kurma (0.14.3'teki asıl düzeltme)

- **Label3D'nin rengini canlandırma.** `modulate` ya da `outline_modulate` her değişince Godot yazının ağını baştan kurar:
  her karede yeni tamponlar. 60 karelik bir solma ~480 yeni tampon demek. Her "+1 maden" yazısı solarken telefonda yazı
  başına ~200 tampon kurulup siliniyordu; kazarken saniyede onlarca.
  - Çözüm: yazı solmuyor, sonunda küçülerek kayboluyor (`scale` tween; hafif büyüyüp küçülme, `TRANS_BACK`).
  - `GeometryInstance3D.transparency` Compatibility'de Label3D'yi soldurmuyor (denendi).
  - 2D `Label`'ın `modulate`'i ucuz: yalnızca 3D yazıda sorun.
- **Aynı yük:** her karede `PrimitiveMesh` boyu (`BoxMesh.size`, `CylinderMesh.height`) değiştirmek, Label3D metnini
  değiştirmek. Yeni ağ kurulur. Hareket için `position`, `scale`, `rotation` kullan.
- **Parçacıklar havuzdan:** her vuruşta yeni `CPUParticles3D` düğümü kuruluyor, 1,2 sn sonra siliniyordu. Her biri kendi
  tamponunu kurar. Tane sayısı başına 8 düğümlük havuz, `restart()` ile yeniden kullanılıyor (`DigFx._pooled_particles`).
  Havuzdaki düğüm başka kod tarafından silinmiş olabilir (ısındırma kendi eklediklerini siler): `is_instance_valid` ile
  bak, yerine yenisini kur.
- **Ölçülen fark** (masaüstünde, aynı 550 blokluk kazı):

  | | Önce | Sonra |
  |---|---|---|
  | Blok başına kurulan tampon | 20,6 | 15,9 |
  | Doku belleği | 149 MB | 96 MB |

  Masaüstünde (xvfb) kare hızı düşük olduğu için yazının payı küçük görünüyor. Telefonda 60 karede çok daha
  büyük. Kalan tamponlar chunk'ın her kazıda yeni ağı (oyunun özü, kaçınılmaz).

### 3.4 Büyük görseller ekran kartının sıkıştırmasıyla

- "Lossless" (`compress/mode=0`) görsel diskte PNG / WebP ama ekran kartında sıkıştırmasız RGBA8: piksel başına 4 bayt,
  mipmap'le 5,3 bayt. 192 eşya ikonu (256x256) 64 MB tutuyordu.
- **ASTC'ye çevirmek** (`compress/mode=2` VRAM Compressed + `compress/high_quality=true`; masaüstünde BPTC) piksel başına
  1 bayt: 4'te 1. Ekran görüntülerinde kalite farkı görülmedi.
  - Proje ayarı `rendering/textures/vram_compression/import_etc2_astc=true` olmalı.
  - ASTC'yi desteklemeyen ekran kartında Godot görseli açarken çözer (şablonda `astcenc` var).
- **Sıkıştırılmayacaklar:**
  - Kodun `get_image()` ile piksellerini okuduğu görseller: sıkıştırılmış doku telefonda geri okunamaz. Kazı'da freskler
    böyle.
  - Açılış görseli (boot splash): PNG kalmalı.
- **Kazı'da sıkıştırılanlar:** eşya ve arayüz ikonları, çağ rozetleri, portreler, model dokuları. 550 blokluk kazıda
  doku belleği 149 → 96 MB; bütün çağlar açıkken ~80 MB az.
- Bir test kuralı korur (`tests/test_texture_memory.gd`): klasördeki her `.import` `compress/mode=2` mi. Görsel kesme aracı
  yeni ikonun `.import`'unu böyle yazar.
- `.import` dosyalarını toplu değiştirmek: Python'la `compress/mode=0` → `2`, `compress/high_quality=false` → `true`, sonra
  `godot --headless --path . --import` (Kazı'da 324 görsel ~1 dakika).

### 3.5 Hâlâ açık: PowerVR GE8320'de açılışta kapanma (16 Kasım)

General Mobile GM Era 30 (Helio G36, ekran kartı **PowerVR GE8320**, 4 GB RAM): yükleme çubuğu dolunca oyun kapanıyor.
Çubuğun son parçası dükkân vitrininin ısındırılması; hemen ardından giriş ekranı ve eşya ikonlarının arka planda
yüklenmesi geliyor. Bu ekran kartının sürücüsü başka motorlarda da çökmeleriyle biliniyor (`glClear`,
`glBlitFramebuffer`). Telefonun `adb logcat` kaydı bekleniyor (§4.3). Helio G35 / G36 / G37 / P35 ucuz telefonlarda çok
yaygın: başka oyunda da açılışı bu tür bir telefonda dene.

---

## 4. Çökmeyi okumak

### 4.1 Play Console yığınını sembollerle çözmek

Play Console'daki Godot çökmesi sembolsüz gelir (yalnızca `Java_org_godotengine_godot_GodotLib_step`). Godot'nun sürüm
sayfasında hata ayıklama sembolleri var; BuildId aynıysa adresler işlev adına çevrilir:

```bash
# Sürüm sayfasındaki dosya (4.7.2 için):
curl -sSLO https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_native_debug_symbols.4.7.2.stable.template_release.android.zip
unzip Godot_native_debug_symbols.4.7.2.stable.template_release.android.zip arm64-v8a/libgodot_android.so
readelf -n arm64-v8a/libgodot_android.so | grep "Build ID"     # çökmedeki BuildId ile aynı olmalı
# Yığındaki libgodot_android.so satırlarının "pc 0x..." adresleri:
llvm-symbolizer --obj=arm64-v8a/libgodot_android.so --relative-address -f -C 0x226f914 0x2193cd4 0x1212ae0
```

Gradle'lı dışa aktarmada (AdMob eklentisi yüzünden) da `libgodot_android.so` şablondan gelir, BuildId aynıdır.

### 4.2 Yığında ne aranır

- `scudo` + `MapAllocator` / `reportMapError` + sürücü (`libGLES_mali.so`, `libGLESv2_adreno.so`, PowerVR'da
  `libGLESv2_mtk.so` / `libsrv_um.so`): bellek ya da eşleme bitti. Her karede kurulan nesnelere ve büyük dokulara bak
  (§3.3, §3.4).
- Godot işlevi `_check_render_buffers`: 3D tamponları yeniden kuruluyor. Pencere boyu, ölçek ya da MSAA değişmiş;
  setter'ları aynı değerle çağırmayın (§1).
- "Abort message" satırı ("Scudo ERROR: internal map failure ... requesting ...KB") istenecek boyutu söyler; Play
  Console'da çökmenin ayrıntısında görünür.

### 4.3 Telefondan kayıt almak (Mac'te, USB'yle)

```bash
# Telefonda: Ayarlar → Telefon hakkında → Yapı numarasına 7 kez dokun → Geliştirici seçenekleri → USB hata ayıklama
adb devices
adb shell dumpsys package <paket.adı> | grep -E "versionName|versionCode"
adb shell getprop ro.product.model; adb shell getprop ro.board.platform
adb shell dumpsys SurfaceFlinger | grep -i -m3 GLES          # ekran kartı ve sürücü
adb shell cat /proc/meminfo | head -3
adb logcat -c
adb shell monkey -p <paket.adı> -c android.intent.category.LAUNCHER 1
# çöktükten sonra:
adb logcat -d -v threadtime > ~/Desktop/logcat.txt
adb logcat -b crash -d > ~/Desktop/crash.txt                 # yerel yığın burada
```

Oyunun `print` satırları da logcat'e düşer. Kazı ısındırma bitince "Gölgelendiriciler ısındı: N kare, M ms" yazar: çökme
öncesinde mi sonrasında mı, bu satırdan anlaşılır.

---

## 5. Ölçüm araçları (Kazı'da hazır olanlar)

Hepsi geliştirme içindir, oyunun paketine girmez (`tools/*`, `scripts/dev/*` dışa aktarma süzgecinde hariç).

- **Bot senaryosu `perf`** (`scripts/dev/autoplay.gd`; xvfb'de, `--autoplay --scenario=perf`):
  - varsayılan: kampta, yer altında, şehirde kare süreleri, çizim çağrıları, üçgenler; lazerle 28 blok kazarken en uzun
    kareler,
  - `--part=cold`: yeni açılmış oyunun ilk kazıları, her kazının çevresindeki en uzun kare,
  - `--part=idle`: 100 sn boşta (arada gelen işler kare kaçırtıyor mu),
  - `--part=soak`: 12 dk oyun, her 30 sn "PERF_BELLEK" (statik bellek, nesne, düğüm, sahipsiz düğüm, kaynak, doku ve
    tampon belleği),
  - `--part=digsoak` (`--seconds=`): durmadan kazı,
  - `--part=resize`: pencere boyu 120 kez değişir,
  - `--graphics=low|medium|high`; ölçek ancak büyük pencerede görünür (`--resolution 2400x1080`).

  Bellek satırı `Performance.get_monitor(MEMORY_STATIC, OBJECT_COUNT, OBJECT_NODE_COUNT, OBJECT_ORPHAN_NODE_COUNT,
  OBJECT_RESOURCE_COUNT, RENDER_TEXTURE_MEM_USED, RENDER_BUFFER_MEM_USED)`. Sızıntı varsa sayılar tur tur artar.
- **Süreç belleği ve eşlem sayısı** (dışarıdan; Godot `/proc`'u `FileAccess` ile okuyamıyor, boyutu 0 görünüyor):

  ```bash
  # 15 sn'de bir Godot sürecinin RSS'i ve bellek eşlemesi sayısı (exe'ye bakılır: xvfb-run sarmalayıcısı değil)
  while true; do for pid in $(pgrep -f Godot_v4); do
    case "$(readlink /proc/$pid/exe)" in *Godot_v4*)
      echo "$(date +%s) rss_kb=$(awk '/VmRSS/{print $2}' /proc/$pid/status) maps=$(wc -l < /proc/$pid/maps)" >> sample.txt;;
    esac; done; sleep 15; done
  ```
- **Ekran kartı nesneleri sayacı** `tools/gl_count.c` (Linux, `LD_PRELOAD`). Godot GL işlevlerini `dlsym` /
  `glXGetProcAddressARB` ile bulur; bu kitaplık ikisini de sarar. Tampon, doku, çerçeve, VAO, program, fence ve
  `glBufferData` çağrılarını sayar, 15 sn'de bir ve çıkışta yazar: `buffers=<canlı>(+<kurulan>)`. Canlı sayı sabit
  kalmalı, kurulan az artmalı. Küçük bir sahnede (`-s` betiğiyle) tek bir şeyi (yazı solması, parçacık) ayrı ayrı ölçmek
  çok öğretici.

  ```bash
  gcc -O2 -shared -fPIC -o gl_count.so tools/gl_count.c -ldl -lpthread
  LD_PRELOAD=$PWD/gl_count.so xvfb-run -a godot --path . --rendering-driver opengl3 ... 2> gl.log
  ```
- **Gölgelendirici derlemeleri** `tools/shader_compiles.py run --godot <godot> --out <klasör>`: ısındırmadan sonra derleme
  kalmamalı. `scenario --scenario shop` herhangi bir senaryoda ısındırmadan sonraki derlemeleri yazar.

---

## 6. Oyunu "kapatan" öbür Android tuzakları

- **Geri tuşu:** Godot'da varsayılan olarak oyunu hemen kapatır, son kayıttan sonrası kaybolur. Bunun için
  `application/config/quit_on_go_back=false` ve en üstteki paneli kapatan bir `go_back`.
- **Kare sınırı ve ısınma:** §1.
- **Reklam (AdMob) açıkken ağaç durur** (`SceneTree.paused`): reklamın üstünde çalışması gereken düğüm
  `PROCESS_MODE_ALWAYS` olmalı. Reklam belirli sürede açılmazsa oyun beklemesin.
- **iPhone'da ses yok şikâyeti:** iOS ses oturumu varsayılanı Ambient; sessiz anahtar açıkken oyun sessizdir. Hata
  değildir.

---

## 7. Başka oyunda uygulatmak için hazır istek

Bu dosyayı o oyunun deposuna kopyala (ya da yapıştır) ve Claude'a şunu yaz:

```
docs/performans-notlari.md'deki notları bu oyuna uygula. Önce ölç, sonra düzelt, sonra aynı ölçümü tekrarla;
her adımın sayısını bana yaz.
1. Bir bot / ölçüm senaryosu kur: kare süreleri (gerçek saatle), çizim çağrıları, her 30 sn bellek (statik, nesne,
   düğüm, sahipsiz düğüm, doku, tampon). 15 dakikalık normal oyun denemesi; süreç belleğini dışarıdan da örnekle.
2. Grafik ayarı Düşük / Orta / Yüksek (Android'de Orta: 3D en fazla 1,7 milyon piksel), Android'de 60 Hz'den hızlı
   ekranda 60 FPS sınırı. Setter'lar yalnızca değer değişince.
3. Oyun sırasında derlenen gölgelendiricileri say. Varsa açılış perdesinin arkasında ısındır (her malzeme her ışık /
   sis düzeninde bir kez). Koddan kurulan Shader'lar paylaşılsın, ortama Sky bağlama.
4. Oyun karesinde diske dokunan load()'ları arka plana al (load_threaded_request), kaydı iş parçacığında yaz.
5. Her karede ekran kartı nesnesi kuran şeyleri bul ve düzelt: Label3D modulate / outline_modulate canlandırması,
   her karede PrimitiveMesh boyu, her olayda yeni CPUParticles / GPUParticles düğümü (havuz). Mümkünse OpenGL nesne
   sayacıyla (LD_PRELOAD, glGen* / glDelete*) önce / sonra ölç.
6. Büyük görselleri VRAM sıkıştırmasına çevir (compress/mode=2, high_quality; import_etc2_astc açık). get_image() ile
   okunan görseller ve açılış görseli hariç. Bunu koruyan bir test yaz.
7. Android Geri tuşu oyunu kapatmasın.
Play Console'da çökme varsa yığını Godot'nun native debug sembolleriyle çöz (llvm-symbolizer), hangi işlevde
koptuğunu yaz.
```

---

## 8. Olta'da yapılanlar (Kasım 2026)

Yukarıdaki notlar Kazı'nın. Olta'da aynı istek uygulandı: önce ölçüldü, sonra düzeltildi, sonra aynı ölçüm
tekrarlandı. Ölçümler bu bulut ortamında (xvfb, Mesa llvmpipe, yazılımla çizim, 1280x720): kare süreleri telefonun
2-10 katı. Önemli olan sayılar oran ve sayımdır: kare başına kurulan ekran kartı nesnesi, derleme sayısı, bellek
eğrisi. Araçlar: `perf` botu (`scripts/dev/autoplay.gd`), `tools/gl_count.c` + `tools/gl_windows.py`,
`tools/shader_compiles.py` (komutlar CLAUDE.md'de).

### 8.1 Olta'da zaten iyi olanlar

- Gök yok (`BG_COLOR`), sis tek tür (derinlik sisi), lambalar gölgelendiricide (ışık havuzu): Kazı'daki derlemelerin
  büyük kaynakları (gece göğü, spot ve omni ışıkları, yer altı sisi) Olta'da yok.
- Label3D yalnızca dükkânın tabelasında, bir kez yazılır.
- Reklam açıkken ağaç durur, `Ads` `PROCESS_MODE_ALWAYS`, gösterme süre aşımlı (A1-A2'de Kazı'dan).
- Işığın gölgesi ve parlama her karede verilmiyordu (görünüş geçişinde yalnızca renk ve güç).

### 8.2 Bulunanlar ve düzeltmeler

| Bulgu | Önce | Düzeltme | Sonra |
|---|---|---|---|
| Android Geri tuşu oyunu kapatıyordu (`quit_on_go_back` varsayılanı) | son kayıttan sonrası kaybolurdu | `quit_on_go_back=false`, main `go_back`: en öndeki kapatılabilir panel, kart, fotoğraf modu | controls botu: defter kapanır, panel yokken bir şey olmaz |
| Misina `ImmediateMesh`'le her kare yeniden kuruluyordu | olta sudayken kare başına 1 tampon + 1 VAO (küçük denemede 660 karede 660) | sabit köşeli `ArrayMesh`, köşeler `mesh_surface_update_vertex_region` | 660 karede 1 |
| Gerilim çubuğunun yuvarlak `StyleBoxFlat`'leri her kare çiziliyordu (2B çokgen her çizimde tampon kurar) | çekişmede kare başına **22** tampon, 5 VAO | `UiKit.soft_box` (dokulu 9 dilim) | çekişmede **0** |
| Konuşma balonu her kare yeniden çiziliyordu (noktalar `draw_circle`, kalp çokgen) | Dede konuşurken 2,6 tampon/kare | işaret parçaları bir kez çizilir, zıplama ve atma konum ve ölçekle | 0,1 |
| Akvaryumun kabarcıkları her kare üçgen dizisi | panel açıkken 2,2 tampon/kare | `UiKit.disc` (doku) | 0 |
| Yürüme halkası her dokunuş olayında 3 çokgen | yürürken saniyede ~180 tampon | topuz ayrı düğüm, yalnızca yeri değişir | durum değişince |
| Su halkası ve balık gölgesi her seferinde yeni düğüm + malzeme; gölgenin solması her kare | Efsanevi gölgenin izi saniyede 3 halka | havuz; solma yalnızca değişince | - |
| Kartın konfetisi her kartta yeni `CPUParticles2D` | - | tane sayısı başına havuz | - |
| Efektler ilk çalındığında, müzik her vakit değişiminde o karede diskten | - | açılışta `load_threaded_request` (önce müzik ve ortam) | - |
| Kayıt her balıkta oyunun karesinde (JSON + dosya) | - | `WorkerThreadPool`; arka plana geçerken ve çıkışta beklenir | - |
| Grafik ayarı yoktu; proje 60 FPS sınırı her cihazda | 60 Hz ekranda V-Sync'le kare kaçırtır | `GraphicsRules` (Kazı'dan): Düşük / Orta / Yüksek, Android'de Orta; sınır yalnızca telefonda >60 Hz ekranda | Ayarlar'da Grafik satırı |
| Oyun sırasında gölgelendirici derlemesi | ilk balıkta 800 ms, dolabı ilk açışta 890 ms, ilk gece, yağmur, kelebek ~500 ms'lik kareler; 24 derleme | `ShaderWarmup`: açılış perdesinin arkasında 4 kare | bkz. 8.3 |
| 193 görselin hepsi sıkıştırmasız | doku belleği 173 MB | 146 arayüz görseli ASTC; büyük çerçevenin özgünü tutulmaz | 142 MB (aynı gezi) |

Tampon/kare: `tools/gl_windows.py`, `perf` botunun her ölçüm anında (90 kare). Düzeltmeden sonra gezinti,
bölgeler, paneller ve gece-yağmur 0-0,1; boşta iskele 0,3. Çekişmenin ilk 30 karesinde 18 kalıyor: balık
takılınca bildirimler, Dede'nin sözü ve gerilim çubuğunun ilk kurulumu (bir kezlik). Çekişmenin içi 0
(`perf --part=fight`: parçalar tek tek gizlenerek ölçüldü).

### 8.3 Gölgelendirici ısındırma

`tools/shader_compiles.py run` (perf --part=cold, önbellek boş, Mesa önbelleği kapalı):

| | Oyun sırasında derleme | En uzun karesi |
|---|---|---|
| Önce | 24 (ilk balık 6, dolap 3, harita, derin orta, gece, yağmur, kelebek) | ilk balık 797 ms, dolap 894 ms, gece 513, bulutlu → yağmur 533, sevgi 518 |
| Isındırmayla (raf) | 7 (ışık sütunu, derin ortada bir model malzemesi, harita, kartın bir 2B düzeni) | ilk balık 500 ms, dolap 191 ms |
| Raf + sahnedeki bütün malzemeler (son hâl) | 1 (kartın bir 2B düzeni) | ilk balık, dolap, derin orta, gece: derleme yok; kalan uzun kareler (akvaryum 412 ms, göl sevgisinin bitkileri 386, ilk gece 365, ilk yağmur 363) panelin ve sahnenin ilk kurulumu |

Isındırma 90 derleme (37 malzeme, 5 MultiMesh malzemesi, harita). Bu ortamda Mesa'nın önbelleği kapalıyken 15,7 sn,
açıkken ~2 sn; telefonda ilk açılışta birkaç saniye (açılış perdesi biraz uzun kalır), sonraki açılışlarda Godot'nun
önbelleğinden (`user://shader_cache`) kısa.

### 8.4 Uzun oyun ve pencere boyu (sızıntı yok)

- `perf --part=soak --seconds=900`: 30 tur, 62/62 balık; bölge değiştir, sat, vakit ve hava döner, paneller.
  İlk turlardan sonra bellek sabit: statik 138,9 MB, ~1165 düğüm, sahipsiz düğüm 0, doku 146,3 MB, tampon 19,6 MB.
  Süreç belleği (dışarıdan, 15 sn'de bir): ilk 3 dakikada paneller ilk kez açılırken 740 → 823 MB, sonra 15.
  dakikaya kadar 823-828 MB.
- `perf --part=resize`: pencere boyu 120 kez değişti; bellek ve nesne sayıları sabit.

### 8.5 Olta'ya özgü tuzaklar

- Compatibility'de 2B çokgen (yuvarlak köşeli `StyleBoxFlat`, `draw_circle`, `draw_colored_polygon`,
  `canvas_item_add_triangle_array`) her çizimde yeni tampon ve VAO kurar; dikdörtgen, çizgi, doku ve yazı kurmaz.
  Kazı'daki Label3D'nin 2B karşılığı: her kare yeniden çizilen arayüz öğesi (gerilim çubuğu) Olta'da en büyük kaynaktı.
- Bilgisayarda (botlar, Mac'te editör) sıkıştırılmış görsel BPTC; llvmpipe'te BPTC örneklemek çok yavaş. Zemin karosu
  sıkıştırılınca bütün botlar ~5 kat yavaşladı: ekranın çoğunu kaplayan 3B doku sıkıştırılmaz (telefonda ASTC'nin
  bir bedeli yok; zemin 4 MB).
- Kodun piksellerini okuduğu görseller (çerçeveler, saat çipinin ikonları) sıkıştırılmaz (`tests/test_texture_memory.gd`).

### 8.6 Açık kalanlar

- Telefonda ölçüm: iPhone 14'te deneme listesi 50-53 (`docs/iphone-kurulum.md`). Android cihaz yok: Orta ayarın ve
  60 FPS sınırının etkisi ancak Play'deki kullanıcılarda görülür (Play Console'da "ANR ve çökme").
- Play Console'da çökme gelirse §4.1'deki gibi sembollerle çöz (Gradle'lı dışa aktarmada da şablonun
  `libgodot_android.so`'su).
- Modellerin dokuları (KayKit karakterleri ve paletler, Kenney; mipmap'le ~42 MB) bilerek sıkıştırılmadı: renk kutularının sınırında renk
  karışmasın. İleride ölçülüp ekran görüntüsüyle denenebilir.
- Her kartta ve her panel açılışında arayüz baştan kurulur (o an birkaç yüz tampon; kare başına değil). Kart
  sık; gerekirse kart yeniden kullanılabilir.
