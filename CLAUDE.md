# CLAUDE.md: Olta: Gölün Sırrı (game1)

Ersin'in Kazı'dan sonraki yeni oyun projesi: her yaşa hitap eden, rahat bir 3D mobil balıkçılık oyunu. Kodu tamamen Claude yazıyor. Açıklamaları **Türkçe ve sade** yaz; terimleri ilk geçtiğinde kısaca açıkla.

**Durum:**

- Saha araştırması bitti: `docs/saha-arastirmasi.md`.
- Fikir seçildi: **Olta: Gölün Sırrı** (`docs/fikirler.md`, Karar bölümü). Görünüm eğik üstten, suda balık gölgeleri. Kahraman kendi balıkçın + köyde Dede.
- 1. hafta prototipi (v0.1) bitti. Ersin'in geri bildirimiyle H2 "Büyük Göl" planı onaylandı: 5 dalga (`docs/yol-haritasi.md`), tasarım `docs/gdd.md` §10. Şu an Dalga 1 (dükkân, takım, para, nadirlik, defter). Telefona kurulum: `docs/iphone-kurulum.md`. Sürüm: v0.1.
- Görseller Ersin'de: `docs/gorsel-istekleri.md` (partiler, öncelik, oyuna bağlama). CC0 3D paketleri Mac'te indirilir (`docs/mac-indirme.md`; bulut bu sitelere erişemiyor), `assets/incoming/models/`'e gelir. Geçici uygulama ikonu `icon.svg`.

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
godot --headless --path . -s res://tools/reel_report.gd  # balık ya da çekişme ayarı değiştiyse
```

Bot senaryoları (`scripts/dev/autoplay.gd`; gerçek dokunma olayları gönderir). `--fixed-fps 30` oyun zamanını sabit akıtır (bu ortamda kare hızı düşük):

```bash
xvfb-run -a -s "-screen 0 1920x1080x24" godot --path . --rendering-driver opengl3 --audio-driver Dummy \
  --resolution 1280x720 --fixed-fps 30 -- --autoplay --scenario=controls --locale=tr --safe-inset=130 --shots=/mutlak/yol
# senaryolar: controls (KONTROL satırlarının hepsi TAMAM olmalı), first (ilk açılış, senaryolu ilk balık),
#   hero (balıkçı, Dede ve Nine yakın çekim), fish (5 balık elde ve kartlarıyla), video (tanıtım; aşağıda),
#   shop (Nine'nin dükkânı; telefon oranında çalıştır: --resolution 1560x720),
#   rarity (nadirlik ipuçları ve rozetleri; gri tonlamalı kopyasıyla renk körü denetimi)
# --safe-inset: çentiği taklit eder (sol, sağ ve alt pay); düğmelerin güvenli alanda olduğu denetlenir
```

Görsel değişikliklerde ekran görüntüsüne bak (Linux'ta `xvfb-run`; yalnızca OpenGL var). Telefon boyutu için `--resolution 2532x1170` (iPhone 14). Movie Maker (`--write-movie`) pencere boyutunu `project.godot`'taki override'dan alır: telefon boyutunda kayıt için geçici bir `override.cfg` (`[display]` altında `window/size/window_width_override=2532`, `window_height_override=1170`) koy, sonra sil.

Tanıtım videosu (`video` senaryosu; bot gerçek dokunma olayları gönderir, Movie Maker sabit 30 fps ve sesli kaydeder). Telefon oranında (iPhone 14 ≈ 2,16:1) kayıt için geçici `override.cfg`, kayıttan sonra silinir:

```bash
printf '[display]\n\nwindow/size/window_width_override=1560\nwindow/size/window_height_override=720\n\n[editor]\n\nmovie_writer/video_quality=0.95\n' > override.cfg
xvfb-run -a -s "-screen 0 1920x1080x24" godot --path . --rendering-driver opengl3 --audio-driver Dummy \
  --resolution 1560x720 --write-movie /mutlak/yol/olta.avi --fixed-fps 30 -- --autoplay --scenario=video --locale=tr
rm override.cfg
ffmpeg -i /mutlak/yol/olta.avi -c:v libx264 -preset slow -crf 20 -pix_fmt yuv420p -c:a aac -b:a 128k -movflags +faststart olta.mp4
```

Sesler kodla üretilir: `python3 -I tools/make_sounds.py` (numpy; .ogg için ffmpeg). Ses adları `Sounds.BANK` ve `LOOPS` ile aynı olmalı (`test_sounds.gd`).

Araçlar (`tools/`, sürüm paketine girmez): `make_sounds.py` (bütün sesler), `reel_report.gd` (çekişme denge raporu: her balık, bot tarzı ve mod için tutma, kopma, kaçma oranı ve süre), `process_images.gd` (Ersin'in görsel sayfalarını keser, `data/art_sheets.json`), `art_sheet.gd` (kesme ve arka plan silme), `recolor_texture.gd` (KayKit dokularını boyar: ortaçağ paketi, Rogue, Barbarian ve Mage; orijinaller `source/` altında, `.gdignore`'lu), `character_sheet.gd` (karakterin duruşları tek resimde; xvfb ve `--fixed-fps 30` ile; `--angler` balıkçının, `--elder` Dede'nin, `--nine` Nine'nin oyundaki duruşları, `--model=` başka model (kendi kıyafetiyle), `--raw` boyasız).

## Mimari

Kazı'nın yapısı. ✅ = var, 🔜 = sıradaki adımlarda.

- `scripts/core/`: **saf oyun mantığı**. `class_name` + `extends RefCounted`; Node, sahne ve `GameState`'e bağlı değil; headless test edilir.
  - ✅ `ContentDB`: `data/*.json`'u yükler ve doğrular: nadirlikler (simge, gölge ipucu, rütbe puanı, göl sevgisi), balıklar, oltalar, takım (`gear.json`: kategori, fiyat, rütbe, değerler), rütbe (`progression.json`), atış noktaları, kurallar. Oyunun gölü `spots.json` `"main"` (`big_lake`); `home_lake` testlerin sabit gölüdür, değiştirilmez. `FishingRules`: `rules.json`'daki sayılar (süreler adım olarak da).
  - ✅ `Dice`: seed türetme, ppm şans, ağırlıklı seçim. Oynanıştaki her zar buradan ya da ondan türeyen RNG'den.
  - ✅ `LakeShape`: göl şekli (elipsler + iskele), işaretli kıyı uzaklığı ızgarası, derinlik, şamandıranın düşeceği yer.
  - ✅ `FishShadow` + `ShadowSim`: gölgeler (doğma, dolaşma, fark etme, yaklaşma, kaçma, yeniden doğma; ilk av senaryolu).
  - ✅ `GearStats`: kuşanılmış takımın etkisi (menzil, güç, sarma, fren, kopma süresi, görünmezlik, kaçma payı, VUR süresi, kepçe, yem çekimi). `starter` = bambu olta, `best` = en iyi takım (rapor ve testler). `FishingSession` ve `ReelModel` takımı yalnızca buradan okur.
  - ✅ `BiteRules` (fark etme konisi, korkutma, dürtme, VUR penceresi, erken dokunuş), `FishTable` (tür, boy yüzdeliği, yıldız, gölge uzunluğu), `ReelModel` (gerilim, patlama, kopma, kaçma, Kolay mod), `ReelBot` (oyuncu tarzı botları), `Records` (kayıt defteri, kart kuralı).
  - ✅ `FishingSession`: durum makinesi (BOŞ → ATIŞ → BEKLEME → DÜRTME → ISIRMA → ÇEKİŞME → TUTULDU / KAÇTI). Sabit 1/60 sn adım; girdiler `cast` / `press` / `release` / `acknowledge`; olaylar `poll_events()`.
  - ✅ `Economy` (balığın değeri: tür değeri × boy çarpanı 0,6–1,6, binde birle; satış, satın alma, kuşanma, yem harcama; `gear_for` oturumun takımını kurar), `Bucket` (kapasite = sahip olunan en büyük kova; doluysa çağıran balığı bırakır), `Rank` (rütbe puanı, seviye, ilerleme).
  - ✅ `CatchOdds`: hangi balığın geleceği. Tür ağırlıkları × yem çekimi → ppm (toplamı tam 1e6; doğma, defter ve katalog aynı işlevi kullanır). Şans garantisi: `rarities.json` "pity" avdan sonra yakında doğan sıradaki gölge o nadirlikten (aynı anda tek garanti gölgesi; sayaç ancak o nadirlik tutulunca sıfırlanır). `pity_floor(db, save, spot)` gölde tutulamayan kademeyi saymaz (`top_rarity`).
  - ✅ `SaveData` (sürüm 2: kova, takım kimlikle, kuşanma, yem, rütbe puanı, göl sevgisi, şans garantisi, sayaçlar) / `SaveStore` (atomik yazma), `TimeProvider` (zaman soyutlaması).
- `scripts/autoload/`:
  - `game_state.gd` (`GameState`): içerik + kayıt, ayarlar, dil, ipucu adımı, bayraklar, klavye kontrolleri. Sinyaller: `changed`, `focus_lost`, `focus_gained`. Odak kaybında kaydeder.
  - `sounds.gd` (`Sounds`): efektler (`BANK`), döngüler (makara, gerilim), ortam sesi, müzik, titreşim. Dosya yoksa sessiz geçer.
- `scenes/`: sunum (3D sahne ve arayüz kodla kurulur).
  - ✅ `main.gd`: her şeyi bağlar. Oturumun olaylarını ses + titreşim + görsele çevirir; kamera (olta sudayken eğilir, çekişmede yakınlaşır); Dede'nin ipuçları ve öğütleri (ipucu değişince Dede konuşur); yakalayışta kayıt; odak kaybında ve ayarlar açıkken oyun donar.
  - ✅ `input_router.gd` (`InputRouter`): dokunma / fare / klavye. Olta suda değilken dünyadaki bir hedefe dokun (`hit_targets`: Dede → konuşur, Nine ya da dükkânı → selam ve dükkân) → `target_tapped(kimlik)`, karaya dokun → yürü, suya dokun → at (menzil dışıysa main önce yaklaştırır); olta sudayken ekranın her yeri eylem (parmak değdiği an `press`, kalkınca `release`).
  - ✅ `camera/follow_camera.gd`: sabit eğik açı, yumuşak takip, sarsıntı; `pitch` ve `zoom` main'den.
  - ✅ `world/`: `LakeScene` (ortam ve ışık, kıyıya doğru hafif yükselen arazi ağı, su, iskele, sallanan sazlar, KayKit ağaçları / kayaları / tepeleri ve kamp; model yoksa Props), `LakeTexture` (göl veri dokusu), `water` (derinlik rengi, dalga, parıltı, köpük) / `ground` / `shadow` / `reeds` shader'ları, `ShadowLayer` (gölgeler; nadirlik ipucu: pırıltı, ışıltı, kabarcık, dalga izi), `Bobber` (şamandıra), `FishingLine` (misina; `frame_pre_draw`'da kurulur), `Props`, `ModelLibrary` (aynı modelin kopyaları `scatter` ile tek MultiMesh), `ShopStall` (Nine'nin dükkânı: kodla ahşap tezgâh, raflar, çizgili tente, tabela, olta sehpası; `keeper_spot`, `blockers`, dokunma `hit`), `MeshBatch` (durağan parçaları renk başına tek ağda birleştirir). Çizim sayısı az tutulur: iskele ve dükkân renk başına tek ağ, opak suyun altındaki arazi kurulmaz.
  - ✅ `player/`: `Angler` (yürür, kıyıda durur, engellerin çevresinden kayar (`avoid`); her kare `pose` = free / hold / reel ve `tension` verir; atış, gösterme, sevinç tek seferlik). Görünüm `AnglerBody` (KayKit Rogue: boyanmış doku, gizlenen parçalar, kodla şapka, AnimationTree, `AimModifier` ile geriye yaslanma) ya da yedek `ToyAngler` (aynı arayüz). `RodModel`: üç eklemli, gerilimle bükülen olta; el yuvasındaki `rod_mount`'a takılır, serbestken dik taşınır.
  - ✅ `player/villager.gd` (`Villager`): köylülerin ortak davranışı (konuşma balonu, oyuncuya bakış, baş sallama, sevinç, izleme `focus`, boşta bakınma, dokunma denetimi `hit`).
  - ✅ `player/elder.gd` (`Elder` < `Villager`, Dede): iskele kenarında oturur (`seat`), balıkçıya engel (`blocker`), şamandırayı izler. Görünüm `ElderBody` (KayKit Barbarian: Sit_Chair_Idle, üst gövdeden Cheer, kodla kasket, `LookModifier` ile baş çevirme ve sallama, `portrait()` ipucu çubuğu yüzü) ya da yedek `ToyElder`.
  - ✅ `player/nine.gd` (`Nine` < `Villager`, Dede'nin eşi): dükkânın tezgâhının arkasında ayakta (`stand`), yaklaşan balıkçıya bakar (`watch`), dokununca selam verir (`greet`). Görünüm `NineBody` (KayKit Mage: boyanmış doku, kodla mavi çiçekli yazma, puantiyeli önlük, gözlük; Idle, üst gövdeden Interact ve Cheer; `portrait()`) ya da yedek `ToyNine`. `CharacterKit`: karakterlerin ortak yardımcıları (giydirme, dış çizgi, döngü, üst gövde süzgeçli tek seferlik animasyon, kemik yuvası).
  - ✅ `world/fish_mesh.gd` (`FishMesh`): kodla balık (halkalı gövde, çatal kuyruk, yüzgeçler, gözler, bıyık; köşe renkleri). `fish.gdshader` + `fish_outline.gdshader` kuyruk kıvrılmasını `fish_bend.gdshaderinc`'ten paylaşır. `display_length()`: elde gösterilen boy.
  - ✅ `fx/`: `Ripples` (su halkaları), `CatchFx` (tutulan balık balıkçının önünde, nadirde ışık sütunu), `CatchTag` (balığın üstünde 2B etiket: nadirlik simgesi, adı, boyu), `PortraitStudio` (bir 3B nesneyi saydam SubViewport'ta çizip resim yapar), `FishPortrait` (açılışta her balığın resmi → `ItemArt`).
  - ✅ `ui/`: `UiKit` (stil, fontlar, `upper()`, `safe_insets()`, simgeli `rarity_badge`, `rarity_icon`), `Dialog` (panellerin tabanı; ekrana sığmazsa küçülür `fit_scale`), `Hud` (eylem düğmesi, defter ve ayarlar düğmeleri, gerilim çubuğu `TensionBar`, bildirim (`hold_toasts`), ipucu çubuğu ve konuşanın yüzü: `set_portrait(resim, "dede" | "nine")`, `show_hint(anahtar, konuşan)`), `FishCard` (balık kartı; simgeli rozet, Dede'nin sözü `dede_line`), `SettingsPanel`, `ShopPanel` (Nine'nin dükkânı: sekmeler, 3×2 kart, değer çubukları, al ve tak, rütbe kilidi, kova ve satış; `gear_changed`, `sold`), `BookPanel` (Balık Defteri: 6×2 sayfa, siluet, rekor, ipucu, takımla oranlar, şans garantisi), `TouchButton`, `GameIcon` (kodla çizilen ikonlar; `DRAWN` listesi, bilinmeyen ad soru işareti), `ItemArt` (görsellere tek giriş; takım resimleri `gear()`), `SpeechBubble` (köylülerin 2B konuşma balonu).
- `data/*.json`: içerik. `localization/strings.csv`: `keys,en,tr`.
- `assets/`: `fonts/`, `icons/ui/` (Kazı'nın genel ikonları; Ersin'in görselleri gelince değişir), `audio/` (`tools/make_sounds.py` üretir), `incoming/` (Ersin'in ham görselleri; `.gdignore`'lu).
- `tests/`: `run_tests.gd` (koşucu), `base_test.gd`, `test_*.gd`. Test metotları `test_` ile başlar.
- `scripts/dev/`: yalnızca debug: `autoplay.gd` (bot senaryoları, KONTROL satırları, ekran görüntüsü), `video_overlay.gd` (parmak izleri).

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
- **Determinizm:** Oynanışı etkileyen rastgelelik (gölge, dürtme sayısı, balık boyu) yalnızca seed'li `RandomNumberGenerator` + tamsayı karşılaştırma (ppm = milyonda bir) ile yapılır. `scripts/core/` içinde global `randf`/`randi` kullanılmaz. Görsel efektlerde ve shader'larda rastgelelik serbest. Gölgenin türü `Dice.derive(seed, 2)`, boyu `Dice.derive(seed, 3)` tuzlu zarından, hareketi kendi `rng`'sinden: bir kural (şans garantisi, yem) türü değiştirse de boy ve yol kaymaz.
- **Zaman:** Çekirdek mantık sabit 1/60 sn adımla ilerler; her fps'te aynı sonuç çıkar. Sunumda süre `_process(delta)` toplamıyla ölçülür, `Time.get_ticks_*` ile değil.
- **Nadirlikler yalnızca sona eklenir:** kayıtlar sıra numarasını tutar. Balık kimlikleri değişmez.
- **Yeni içerik** = `data/*.json` + `strings.csv`'de TR/EN anahtar (`FISH_x`, `ROD_x`, `RARITY_x`...) + görsel. Testler eksik çeviriyi yakalar.
- **İsteğe bağlı dosyalar** (model, ikon, portre, ses) `ResourceLoader.exists` ile denetlenir; yoksa kodla kurulan yedek kullanılır (`ItemArt`, `GameIcon`, `Sounds`).
- **Arayüz metni** her zaman `tr("UI_...")` ile; anahtar CSV'de olmalı (test denetler). Biçimli metin: `tr("UI_VERSION") % [a]`. Büyük harf için `UiKit.upper()` (Türkçe i → İ; `to_upper()` kullanma).
- **Arayüz kurulumu:** Tam ekran Control için `set_anchors_and_offsets_preset(PRESET_FULL_RECT)` kullan. HUD öğeleri `MOUSE_FILTER_IGNORE`; basılı tutulan ve aynı anda basılacak butonlar `TouchButton`. Paneller `Dialog`'dan türer ve `"modal"` grubuna girer; açıkken oyun girdisi engellenir. Düğmeler güvenli alanın içinde (`UiKit.safe_insets`), en az 122 birim; eylem düğmesi en az 280 birim.
- **Fontlar:** başlık Luckiest Guy (`UiKit.display_font()`), metin Baloo 2 (`UiKit.body_font()`).
- **Hazır modeller:** `assets/models/<paket>/` + `ModelLibrary.MODELS` satırı + `assets/CREDITS.md`. GLB içe aktarmada gömülü dokular atılır; karakterin dokusu kodla verilir.
- **Kayıt biçimi** değişirse: `SaveData.VERSION`'ı artır, `migrate()`'e adım ekle, `test_save_data.gd`'ye test yaz. Her sürümün gerçek bir örneği `tests/fixtures/save_vN.json`'da durur ve değiştirilmez (göç zinciri ondan sınanır). Takım kimlikle saklanır, kademe numarasıyla değil.
- **Çekişme, balık ya da takım ayarı** değişirse: `tools/reel_report.gd`'yi (ve `-- --gear=top`) çalıştır, `docs/gdd.md` §5'teki tabloları güncelle; `test_reel_model.gd` korkulukları (en iyi takımla da beceri gereksin) yeşil kalsın. Balığın `pull` değeri sınırın en az 0,05 altında olmalı; en güçlü frende patlama sınırın en az 0,1 üstünde kalmalı (ContentDB denetler).
- **Koordinatlar:** dünya x/z metre; çekirdek mantık `Vector2(x, z)` kullanır, su yüzeyi y = 0. Kamera +x +z tarafında; iskele kıyıdan −z yönüne uzanır.
- **Her sesin** bir görsel ve titreşim karşılığı olur (iPhone'un sessiz anahtarı sesi kapatır).
- **Gelir:** yukarıdaki 10 kural. Parayla şans yok; oran ve pity gösterilir. **Oyun parası (`coins`) gerçek parayla asla satılmaz:** oranı değiştiren yem ve yapay yem ancak bu sayede oyun parasıyla satılabiliyor.
- **Dil:** Dokümanlar ve yorumlar Türkçe, kod isimleri İngilizce. Commit mesajları Türkçe.
- Commit'ten önce: import + testler + headless ana sahne. Görsel değiştiyse ekran görüntüsüne bak; kontroller değiştiyse `controls` senaryosu.

## Bilinen tuzaklar

- `.godot/` ve CSV'den üretilen `*.translation` dosyaları git'e girmez. `*.uid` ve `*.import` dosyaları **girer**.
- `docs/` ve `assets/incoming/` `.gdignore`'lu: Godot onları içe aktarmaz, pakete de girmez.
- Packed array'ler (`PackedInt32Array` vb.) referansla geçer.
- `-s` ile çalışan scriptlerde (testler) autoload'lara güvenme; core sınıfları `GameState` kullanmaz.
- Renderer `gl_compatibility` (mobil + bu ortamdaki llvmpipe). SSAO, SDFGI, hacimsel sis, Decal ve derinlik dokusu yok: suyun rengi ve gölgeler aynı veri dokusundan çizilir; dış çizgi ters kabuk malzeme (`next_pass`, `grow`).
- Kare başı hareket eden 3D parçaları Tween geri çağrısından değil `_process`'ten sür.
- Çizim sayısı: her MeshInstance3D bir çizim; dış çizgisi ve gölgesi birer çizim daha. Kodla kurulan durağan parçalar `MeshBatch` ile tek ağda birleşir (köşe rengi; `vertex_color_is_srgb` açık olmalı, yoksa renkler Props'unkinden açık görünür). Gölgesi görünmeyen parçaların (tente altındaki Nine, çay bardağı) gölgesi kapatılır. Ölçüm: sahne ~190 çizim (hedef ≤150, Dalga 2'de).
- `-s` ile çalışan testlerde root'a eklenen düğüm ağaçta sayılmaz (`is_inside_tree` false): `to_global` ve `global_transform` hata verir. Yerleşim hesaplayan sınıflar (`ShopStall`) üst düğümün uzayında (`transform * nokta`) hesaplar.
- `pgrep -f` / `pkill -f` deseni kendi komut satırında da geçer: bekleme döngüsü kendini bulur, `pkill` kendi kabuğunu öldürür. Arka plan işini bildirimiyle bekle.
- KayKit animasyonları döngüsüz gelir; döngü çalışırken açılır. Kemik pozuna animasyondan sonra dokunmak için `SkeletonModifier3D`.
- KayKit Rogue'da baş yuvası yok (yalnızca `handslot_r` / `handslot_l`): şapka, `head` kemiğine bağlanan bir `BoneAttachment3D`'ye takılır. El yuvasında nişan duruşlarında +X ileri, +Y yukarı bakar; olta bu yüzden +X'e göre kurulur (`AnglerBody.ROD_TILT`).
- `-s` ile çalışan araçlarda eklenen düğümlerin `_ready()`'si ilk karede çalışır: `_ready`'de kurulan parçalara (ör. `rod_mount`) `_initialize`'da değil, ilk `_process` karesinde dokun. Animasyonu `seek` ile ölçmek de ancak kareler ilerledikten sonra doğru sonuç verir.
- Headless çalışmada (testler, `--headless`) `SubViewport` çizilmez: `PortraitStudio` null döner, kartta yer tutucu madalyon, ipucu çubuğunda yer tutucu ikon kalır.
- Sahne ton eşlemesi (Filmic, `tonemap_white` 6) ve sis 3B'deki ışıksız beyazı da griye çeker: arayüz gibi görünmesi gereken parçalar (konuşma balonu) 2B çizilir ve her kare `unproject_position` ile 3B noktaya taşınır.
- Kamera +x +z tarafında ve yukarıdan bakar: bir karakterin yüzü yalnızca kameraya dönükken görünür. Dede bu yüzden kameraya üçte bir dönük oturur ve konuşurken başını kameraya kaldırır (`LookModifier` yukarı bakış).
- Balıkçı düz çizgide yürür: yoldaki engeller (Dede) `Angler.avoid` ile çevreden kayılarak geçilir; durdurmak yerine kaydırmak, "karaya dokun" yürüyüşünün takılmamasını sağlar.
- Video kaydında (Movie Maker) oyun zamanı gerçek saatten yavaş akar; bot döngülerinde kare sayısı kullan. Kayıtta `OS.has_feature("movie")` true: hata ayıklama FPS etiketi gizlenir.
- `Image.blend_rect` iki görüntünün aynı biçimde olmasını ister (RGBA8).
- Kodla kurulan ağlarda üçgenler dışarıdan bakınca **saat yönünde** sıralanmalı (Godot'nun ön yüzü). Ters olursa `generate_normals()` normalleri içe çevirir; `cull_disabled` ışığı düzgün gösterdiği için fark edilmez ama dış çizgi kabuğu (`NORMAL` yönünde büyür) gövdenin içinde kalır (`FishMesh._tri`).
- Göl veri dokusu yarım float (`FORMAT_RGBAH`): 8 bitlik kanal 12 m'lik kıyı uzaklığını 4,7 cm'lik basamaklara böler, kıyı köpüğü testere dişi olur.
- Parlak düğme dokuları (`UiKit.glossy`) GDScript'te piksel piksel çizilir (her biri ~40 ms): oyunda sonradan görünen renkler açılışta çizilir (`Hud.warm_styles`), yoksa ilk dürtme, VUR ve kart anında takılır.
- Kartlı yakalamada (kart açıkken ya da açılacakken) gelen dokunuş saklanmaz: kartı kapatan dokunuş olta da atmasın. Olta dönerken (kaçtı, geri sarma, kartsız kısa yakalama) gelen atış dokunuşu saklanır, dönünce atılır.
- Konuşma balonu dokunma hedefi değildir: sık çıkar ve iskelenin üstünde durur; yürüme ve atma dokunuşlarını yutmasın. Dede'ye dokunmak için Dede'nin kendisi.
- Bu bulut ortamında `kenney.nl`, `quaternius.com`, `godotengine.org` erişime kapalı; KayKit'in GitHub depoları açık (seyrek klonla).
- Export: `data/*.json` pakete girmeli (`include_filter`); `tests/*`, `tools/*`, `scripts/dev/*` hariç.
- Dokunuştan üretilen taklit fare olayı dokunuşun kendisinden **önce** işlenir. Basışta kapanan bir panel, aynı dokunuşu arkasındaki oyuna da geçirir (kart kapanır, olta atılır). Paneller parmak kalkınca kapanır (`FishCard`).
- Botun `Input.parse_input_event` ile gönderdiği dokunuş bir sonraki karede işlenir: sonucu ölçmeden önce 1–2 kare bekle.
- Compatibility renderer'da `blend_mul` (çarpma karışımı) dörtgenin tamamını karartıyor: gölgeler koyu renkli `blend_mix` ile çizilir.
- Göl suyu y = 0'da: suyun üstüne düşen büyük bir düzlem (ör. dış zemin) gölü örter. Dış zemin, arazi ağının çevresinde dört şerittir.
- Kıyı çizgisinde arazi suyun biraz altındadır (`SHORE_DIP`): görünen kıyı, ağın üçgenleri değil, suyun pürüzsüz kenarıdır.
- Bot çıkmadan önce `Sounds.stop_all()` çağırıp birkaç kare bekler; yoksa çalan ogg için çıkışta "resources still in use" hatası çıkar.
- `FishingSession.advance` bir karede en fazla 0,5 sn işler: testlerde uzun süreyi parça parça ilerlet.
- Luckiest Guy'da büyük harflerin üstündeki nokta ve şapkalar (İ, Ü, Ğ, Â) satır kutusunun dışına taşar: Label'da `clip_text` onları keser ("KUCUK IGNE"). Uzun adlarda `text_overrun_behavior` (…) ya da küçük yazı kullan.
- Luckiest Guy ve Baloo 2 Türkçe karakterleri destekler. Yeni font seçilirse ğ, ş, ı, İ kontrol edilmeli. Varsayılan fontta ★ ve ok işaretleri yok.
