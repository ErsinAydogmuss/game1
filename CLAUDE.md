# CLAUDE.md: Olta: Gölün Sırrı (game1)

Ersin'in Kazı'dan sonraki yeni oyun projesi: her yaşa hitap eden, rahat bir 3D mobil balıkçılık oyunu. Kodu tamamen Claude yazıyor. Açıklamaları **Türkçe ve sade** yaz; terimleri ilk geçtiğinde kısaca açıkla.

**Durum:**

- Saha araştırması bitti: `docs/saha-arastirmasi.md`.
- Fikir seçildi: **Olta: Gölün Sırrı** (`docs/fikirler.md`, Karar bölümü). Görünüm eğik üstten, suda balık gölgeleri. Kahraman kendi balıkçın + köyde Dede.
- Şu an: 1. hafta prototipi (`docs/yol-haritasi.md`). Tasarım: `docs/gdd.md`. Sürüm: v0.1.

## Ersin ve çalışma şartları

- **Deneyim:** İlk oyunu Kazı (`ErsinAydogmuss/game`). Kod bilmiyor, kodu Claude yazıyor. Samimi konuşur ("kanka").
- **Zaman:** Akşamları ve sabahları, iş arasında çalışıyor; test seansları kısa.
- **Cihazlar:** Mac ve iPhone 14 (kabloyla bağlı). Android cihazı yok.
- **Telefona yükleme:** Bulut oturumu kodu yazar, Mac'teki Claude Code oyunu telefona yükler. Bunun için adım adım bir md görev dosyası ister; örneği Kazı'nın `docs/iphone-kurulum.md`'si. Kurulum ücretsiz Apple hesabı varsayımıyla yazılır; uygulama 7 günde bir yeniden yüklenir.
- **Görseller:** Ersin ChatGPT ile kendisi üretir (stil sayfası + 3×2 sayfa, macenta arka plan) ve GitHub'a web'den yükler.
- **3D ve ses:** 3D modeller KayKit CC0 paketlerinden gelir; bulutta GitHub depoları açık, kenney.nl ve quaternius.com kapalı. Sesler kodla üretilir (numpy).
- **Geri bildirim:** Telefonda oynar, numaralı sorun listesi gönderir; "araştır", "beyin fırtınası yapalım" der.

## Süreç

- **Kararlar:** Seçenek listesi sun, birini "(Önerilen)" diye işaretle. Ersin şimdiye kadar hep önerileni seçti. Bu yüzden öneri dürüst ve gerekçeli olmalı, bedeli seçeneğin açıklamasında yazmalı.
- **Plan:** Seçtikleri sıralı bir plana dökülür. Her adım ayrı commit ve push olur; adım bitince kısa bir "telefonda dene" listesi ver.
- **"Sen karar ver" derse:** karar ver ve nedenini yaz.
- **Gece planı:** "Kendin planla ve onayla, bana sorma" derse sormadan çalış; sabah kısa bir rapor ver, gerekirse video ekle.
- **İnceleme:** Büyük bir işten sonra ayrı bir inceleme ajanı kodu baştan okusun.
- **Commit:** Commit'ten önce test çıktısını oku. Her adımda commit ve push yap; oturum yeniden başlarsa iş kaybolmasın.
- **Dil:** Belgeler ve yorumlar Türkçe, kod isimleri İngilizce, commit mesajları Türkçe.

## Gelir ve "her yaş" kuralları

Ayrıntı ve kaynaklar: `docs/saha-arastirmasi.md` §8.

1. **Konum:** "aile dostu, herkes için". Hedef Apple 4+/9+ ve PEGI 7; çocuk kategorisine girilmez.
2. **Karma kitle kurulumu:**
   - ilk açılışta tarafsız bir doğum yılı sorusu;
   - 13 yaş altı ya da yaşı bilinmeyen oyuncuya yalnızca sertifikalı SDK'dan kişiselleştirilmemiş ödüllü reklam; reklam kimliği yok;
   - yalnızca kendi analitiğimiz;
   - satın alma ve dış bağlantı önünde ebeveyn kapısı.
3. **Parayla şans yok.** Gerçek para ya da gerçek parayla alınan oyun parası, oranı değiştiren ya da zar attıran hiçbir şeyi alamaz. Örnekler: nadir yem, şans eşyası, ek deneme ya da enerji, satın alınan hava olayı, zaman atlama, altın yuva.
4. **Gizli içerik baştan belli.** Yumurta, sandık, çamurlu eşya gibi şeylerin içi oluştuğu anda belirlenir. İçini açtıran hızlandırma parayla satılmaz.
5. **Doğrudan satış:** kostümler ve görünüş süsleri. Fiyat her zaman gerçek parayla da yazar. Bir süs bir türü çağırıyorsa tarif o türü garanti eder.
6. **Sezon kartının süresi dolmaz.** Eski kartlar alınabilir kalır; satın alma ekranında geri sayım olmaz.
7. **Oyuncu yokken ceza yok.** Aç kalan, ölen, kirlenen, solan, kaçan bir şey olmaz; seri sıfırlanmaz. Boşta biriken gelir bir üst sınırda durur.
8. **Sık yarışma yok.** Etkinlikler seyrek ya da ortak hedefli olur.
9. **Açık sohbet yok.**
10. **Oranlar ve şans garantisi (pity) açıkça gösterilir.**

## Komutlar

Bulut oturumunda (Linux) Godot yoksa indir ve doğrula (Mac'te: `godot=/Applications/Godot.app/Contents/MacOS/Godot`):

```bash
mkdir -p "$SCRATCH/godot" && cd "$SCRATCH/godot"
curl -sSLO https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_linux.x86_64.zip
curl -sSLO https://github.com/godotengine/godot/releases/download/4.7.2-stable/SHA512-SUMS.txt
grep linux.x86_64.zip SHA512-SUMS.txt | sha512sum -c - && unzip -q Godot_v4.7.2-stable_linux.x86_64.zip
```

Her değişiklikten sonra:

```bash
godot --headless --path . --import                       # yeni dosya/sınıf eklenince şart (class_name önbelleği)
godot --headless --path . -s res://tests/run_tests.gd    # tüm testler; çıkış kodu 0 olmalı, çıktıyı oku
godot --headless --path . --quit-after 600               # ana sahne hatasız açılmalı (çıktıda SCRIPT ERROR yok)
godot --headless --path . --export-pack "iPhone" /mutlak/yol/olta.zip   # paket: data/*.json var; tests, tools, scripts/dev yok
```

Görsel değişikliklerde ekran görüntüsü al ve incele (Linux'ta `xvfb-run` ile; yalnızca OpenGL var). Bot senaryoları 4. adımda gelir (`scripts/dev/autoplay.gd`):

```bash
xvfb-run -a -s "-screen 0 2560x1440x24" godot --path . --rendering-driver opengl3 --audio-driver Dummy \
  --resolution 2532x1170 -- --autoplay --locale=tr --shots=/mutlak/yol --scenario=controls
```

Araçlar (`tools/`, sürüm paketine girmez): `process_images.gd` (Ersin'in görsel sayfalarını keser, `data/art_sheets.json`), `art_sheet.gd` (kesme ve arka plan silme), `recolor_texture.gd` (KayKit dokularını boyar; iş listesi model gelince uyarlanacak).

## Mimari

Kazı'nın yapısı. ✅ = var, 🔜 = sıradaki adımlarda.

- `scripts/core/`: **saf oyun mantığı**. `class_name` + `extends RefCounted`; Node, sahne ve `GameState`'e bağlı değil; headless test edilir.
  - ✅ `ContentDB`: `data/*.json`'u yükler ve doğrular (şimdilik nadirlikler). 🔜 balıklar, oltalar, atış noktaları.
  - ✅ `SaveData` (sürüm 1) / `SaveStore` (atomik yazma), `TimeProvider` (zaman soyutlaması).
  - 🔜 `LakeShape` (göl şekli, derinlik, kıyı uzaklığı), `ShadowSim` (gölgeler), `BiteRules` (dürtme, ısırma, VUR penceresi), `ReelModel` (gerilim), `FishTable` (tür, boy, yıldız), `FishingSession` (durum makinesi; sabit 1/60 sn adım; olay yayar), `Records`.
- `scripts/autoload/`:
  - `game_state.gd` (`GameState`): içerik + kayıt, ayarlar, dil, ipucu adımı, bayraklar, klavye kontrolleri. Sinyaller: `changed`, `focus_lost`, `focus_gained`. Odak kaybında kaydeder.
  - `sounds.gd` (`Sounds`): efektler (`BANK`), döngüler (makara, gerilim), ortam sesi, müzik, titreşim. Dosya yoksa sessiz geçer.
- `scenes/`: sunum (3D sahne ve arayüz kodla kurulur).
  - ✅ `main.gd`: her şeyi bağlar; şimdilik yer tutucu göl ve iskele. 🔜 `InputRouter` (dokunuş → yürü / at / VUR / sar).
  - ✅ `camera/follow_camera.gd`: sabit eğik açı, yumuşak takip, sarsıntı.
  - ✅ `world/`: `Props` (kodla basit parçalar), `MeshKit` (kodla mesh), `ModelLibrary` (hazır modeller: ad → dosya, ölçek), `grass.gdshader`.
  - ✅ `ui/`: `UiKit` (stil, fontlar, `upper()`, `safe_insets()`), `Dialog` (panellerin tabanı), `Hud`, `SettingsPanel`, `TouchButton`, `GameIcon` (kodla çizilen ikonlar), `ItemArt` (görsellere tek giriş).
  - ✅ `player/aim_modifier.gd`, `fx/vignette`. 🔜 `AnglerBody`, `RodModel`, `FishingLine`, `Bobber`, `FishMesh`, kart.
- `data/*.json`: içerik. `localization/strings.csv`: `keys,en,tr`.
- `assets/`: `fonts/`, `icons/ui/` (Kazı'nın genel ikonları; Ersin'in görselleri gelince değişir), `incoming/` (Ersin'in ham görselleri; `.gdignore`'lu).
- `tests/`: `run_tests.gd` (koşucu), `base_test.gd`, `test_*.gd`. Test metotları `test_` ile başlar.
- `scripts/dev/`: yalnızca debug (bot, video katmanı).

## Kurallar

- **Yalnızca Godot 4.7 API.** Godot 3 sözdizimi yasak. Karşılıkları:

  | Godot 3 (yasak) | Godot 4.7 |
  |---|---|
  | `yield` | `await` |
  | `export var` | `@export var` |
  | `onready var` | `@onready var` |
  | `connect("sinyal", self, "metot")` | `sinyal.connect(metot)` |
  | `Image.create` | `Image.create_empty` |

  Emin değilsen API'yi `godot --headless --doctool <klasör>` çıktısında doğrula. 4.7'de yerleşik `VirtualJoystick` sınıfı var; aynı adda `class_name` kullanma.
- **Statik tip her yerde.** Değer Variant ise (sözlükten okuma) `:=` kullanma, tipi yaz: `var x: int = d["k"]`.
  - JSON sayıları **float** gelir; `int()` ile çevir.
  - Tamsayı bölmede uyarı çıkar; `float` ya da `>> 1` kullan.
- **Determinizm:** Oynanışı etkileyen rastgelelik (gölge, dürtme sayısı, balık boyu) yalnızca seed'li `RandomNumberGenerator` + tamsayı karşılaştırma (ppm = milyonda bir) ile yapılır. `scripts/core/` içinde global `randf`/`randi` kullanılmaz. Görsel efektlerde ve shader'larda rastgelelik serbest.
- **Zaman:** Çekirdek mantık sabit 1/60 sn adımla ilerler; her fps'te aynı sonuç çıkar. Sunumda süre `_process(delta)` toplamıyla ölçülür, `Time.get_ticks_*` ile değil.
- **Nadirlikler yalnızca sona eklenir:** kayıtlar sıra numarasını tutar. Balık kimlikleri değişmez.
- **Yeni içerik** = `data/*.json` + `strings.csv`'de TR/EN anahtar (`FISH_x`, `ROD_x`, `RARITY_x`...) + görsel. Testler eksik çeviriyi yakalar.
- **İsteğe bağlı dosyalar** (model, ikon, portre, ses) `ResourceLoader.exists` ile denetlenir; yoksa kodla kurulan yedek kullanılır (`ItemArt`, `GameIcon`, `Sounds`).
- **Arayüz metni** her zaman `tr("UI_...")` ile; anahtar CSV'de olmalı (test denetler). Biçimli metin: `tr("UI_VERSION") % [a]`. Büyük harf için `UiKit.upper()` (Türkçe i → İ; `to_upper()` kullanma).
- **Arayüz kurulumu:** Tam ekran Control için `set_anchors_and_offsets_preset(PRESET_FULL_RECT)` kullan. HUD öğeleri `MOUSE_FILTER_IGNORE`; basılı tutulan ve aynı anda basılacak butonlar `TouchButton`. Paneller `Dialog`'dan türer ve `"modal"` grubuna girer; açıkken oyun girdisi engellenir. Düğmeler güvenli alanın içinde (`UiKit.safe_insets`), en az 122 birim; eylem düğmesi en az 280 birim.
- **Fontlar:** başlık Luckiest Guy (`UiKit.display_font()`), metin Baloo 2 (`UiKit.body_font()`).
- **Hazır modeller:** `assets/models/<paket>/` + `ModelLibrary.MODELS` satırı + `assets/CREDITS.md`. GLB içe aktarmada gömülü dokular atılır; karakterin dokusu kodla verilir.
- **Kayıt biçimi** değişirse: `SaveData.VERSION`'ı artır, `migrate()`'e adım ekle, `test_save_data.gd`'ye test yaz.
- **Her sesin** bir görsel ve titreşim karşılığı olur (iPhone'un sessiz anahtarı sesi kapatır).
- **Gelir:** yukarıdaki 10 kural. Parayla şans yok; oran ve pity gösterilir.
- **Dil:** Dokümanlar ve yorumlar Türkçe, kod isimleri İngilizce. Commit mesajları Türkçe.
- Commit'ten önce: import + testler + headless ana sahne. Görsel değiştiyse ekran görüntüsüne bak; kontroller değiştiyse `controls` senaryosu.

## Bilinen tuzaklar

- `.godot/` ve CSV'den üretilen `*.translation` dosyaları git'e girmez. `*.uid` ve `*.import` dosyaları **girer**.
- `docs/` ve `assets/incoming/` `.gdignore`'lu: Godot onları içe aktarmaz, pakete de girmez.
- Packed array'ler (`PackedInt32Array` vb.) referansla geçer.
- `-s` ile çalışan scriptlerde (testler) autoload'lara güvenme; core sınıfları `GameState` kullanmaz.
- Renderer `gl_compatibility` (mobil + bu ortamdaki llvmpipe). SSAO, SDFGI, hacimsel sis, Decal ve derinlik dokusu yok: suyun rengi ve gölgeler aynı veri dokusundan çizilir; dış çizgi ters kabuk malzeme (`next_pass`, `grow`).
- Kare başı hareket eden 3D parçaları Tween geri çağrısından değil `_process`'ten sür.
- KayKit animasyonları döngüsüz gelir; döngü çalışırken açılır. Kemik pozuna animasyondan sonra dokunmak için `SkeletonModifier3D`.
- Video kaydında (Movie Maker) oyun zamanı gerçek saatten yavaş akar; bot döngülerinde kare sayısı kullan.
- `Image.blend_rect` iki görüntünün aynı biçimde olmasını ister (RGBA8).
- Bu bulut ortamında `kenney.nl`, `quaternius.com`, `godotengine.org` erişime kapalı; KayKit'in GitHub depoları açık (seyrek klonla).
- Export: `data/*.json` pakete girmeli (`include_filter`); `tests/*`, `tools/*`, `scripts/dev/*` hariç.
- Luckiest Guy ve Baloo 2 Türkçe karakterleri destekler. Yeni font seçilirse ğ, ş, ı, İ kontrol edilmeli. Varsayılan fontta ★ ve ok işaretleri yok.
