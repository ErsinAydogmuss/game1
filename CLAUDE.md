# CLAUDE.md: Olta: Gölün Sırrı (game1)

Ersin'in Kazı'dan sonraki yeni oyun projesi: her yaşa hitap eden, rahat bir 3D mobil balıkçılık oyunu. Kodu tamamen Claude yazıyor. Açıklamaları **Türkçe ve sade** yaz; terimleri ilk geçtiğinde kısaca açıkla.

**Durum:**

- Saha araştırması bitti: `docs/saha-arastirmasi.md`.
- Fikir seçildi: **Olta: Gölün Sırrı** (`docs/fikirler.md`, Karar bölümü). Görünüm eğik üstten, suda balık gölgeleri. Kahraman kendi balıkçın + köyde Dede.
- 1. hafta prototipi (v0.1) bitti. Ersin'in geri bildirimiyle H2 "Büyük Göl" planı onaylandı: 5 dalga (`docs/yol-haritasi.md`), tasarım `docs/gdd.md` §10. Dalga 1 (dükkân, takım, para, nadirlik, defter) bitti: v0.2. Ara sürüm v0.2.1: Ersin'in görselleri (Parti 1–2) ve Mac'te indirdiği 3D paketler oyuna bağlandı. Dalga 2 (büyük göl: 6 bölge, harita, sandal, 7 yeni tür, kıyı yolu, su ve zemin, telefonda hız ölçümü) bitti: v0.3. Sırada Dalga 3 (teknikler). Telefona kurulum: `docs/iphone-kurulum.md`. Sürüm: v0.3.
- Görseller Ersin'de: `docs/gorsel-istekleri.md` (partiler, öncelik, oyuna bağlama). Parti 1–3 oyunda; Parti 4 (teknikler) kesildi, Dalga 3'te bağlanır; Parti 5'in promptları Dalga 4'ten önce. CC0 3D paketleri Mac'te indirilir (`docs/mac-indirme.md`; bulut bu sitelere erişemiyor), `assets/incoming/models/`'e gelir. Uygulama ikonu ve açılış logosu Ersin'in (`assets/ui/art/app_icon.png`, `logo.png`).

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
godot --headless --path . -s res://tools/economy_report.gd -- --hours=12   # fiyat, değer, rütbe puanı değiştiyse
godot --headless --path . -s res://tools/session_timing.gd  # gölge, fark etme, dürtme kuralı değiştiyse → data/sim.json (bölge başına: -- --zone=reeds → "zones")
godot --headless --path . -s res://tools/fish_catalog.gd    # balık, nadirlik, yem ya da oran değiştiyse (docs/balik-katalogu.md)
godot --headless --path . -s res://tools/lake_map.gd -- --spot=big_lake --out=/mutlak/yol/gol.png   # göl şekli değiştiyse: kuşbakışı önizleme
```

Bot senaryoları (`scripts/dev/autoplay.gd`; gerçek dokunma olayları gönderir). `--fixed-fps 30` oyun zamanını sabit akıtır (bu ortamda kare hızı düşük):

```bash
xvfb-run -a -s "-screen 0 1920x1080x24" godot --path . --rendering-driver opengl3 --audio-driver Dummy \
  --resolution 1280x720 --fixed-fps 30 -- --autoplay --scenario=controls --locale=tr --safe-inset=130 --shots=/mutlak/yol
# senaryolar: controls (KONTROL satırlarının hepsi TAMAM olmalı), first (ilk açılış, senaryolu ilk balık),
#   hero (balıkçı, Dede ve Nine yakın çekim), fish (12 balık elde ve kartlarıyla), video (tanıtım; aşağıda),
#   shop (Nine'nin dükkânı; telefon oranında çalıştır: --resolution 1560x720),
#   rarity (nadirlik ipuçları ve rozetleri; gri tonlamalı kopyasıyla renk körü denetimi),
#   map (harita ve hızlı geçiş: yeni bölge açılır, her açık bölgeye geçilir, kilitliye geçilmez; telefon oranında ve --safe-inset=130 ile),
#   boat (sandal: Nine'den al, bin, at, yayını tut, sıradaki şamandıra, kıyıya dön; aynı ayarlarla),
#   tour (gezi: her bölgenin atış noktası ve sandal; ÇİZİM satırları ve ekran görüntüsü; KONTROL: her yerde ≤150 çizim)
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

Araçlar (`tools/`, sürüm paketine girmez): `make_sounds.py` (bütün sesler), `reel_report.gd` (çekişme denge raporu: her balık, bot tarzı ve mod için tutma, kopma, kaçma oranı ve süre), `economy_report.gd` (denge botu saatlerce oynar: saatte para ve av, rütbelerin, takım alımlarının, türlerin ve bölgelerin ilk görüldüğü dakika, bölgelerde geçen zaman; `--seeds=6`), `session_timing.gd` (gerçek `FishingSession`'ı insan gibi oynayan botla süreleri ölçer, `data/sim.json` için öneri yazar; `--zone=` o bölgenin atış noktasında ya da sandalda), `fish_catalog.gd` (`docs/balik-katalogu.md`: nadirlikler, yıldız şansı, şans garantisi, yem başına tür ve nadirlik oranı, ortalama değer), `lake_map.gd` (gölün kuşbakışı PNG önizlemesi: derinlik, bölgeler, atış noktaları, şamandıralar, çitler, yürünmeyen orman; bölgelerin alanı), `process_images.gd` (Ersin'in görsel sayfalarını keser, `data/art_sheets.json`: `fit` square / box / trim / tile (zemin dokusu: kare örneğin içinden dikişsiz karo), `despill` all / edge (mor nesneli sayfalar: yalnızca kenar bandı) / none, `key: false` arka planı silinmez ve saydamlıksız kaydedilir (uygulama ikonu); `--keep`, `--only=`, `--preview=`), `art_sheet.gd` (kesme ve arka plan silme), `recolor_texture.gd` (KayKit ve Kenney dokularını boyar: orman ve ortaçağ paketi, Rogue, Barbarian, Mage, Kenney paletleri (`grid` 16×4); hangi modelin hangi renk kutusunu kullandığı UV'lerden çıkarılır; orijinaller `source/` altında, `.gdignore`'lu), `character_sheet.gd` (karakterin duruşları tek resimde; xvfb ve `--fixed-fps 30` ile; `--angler` balıkçının, `--elder` Dede'nin, `--nine` Nine'nin oyundaki duruşları, `--model=` başka model (kendi kıyafetiyle), `--raw` boyasız).

## Mimari

Kazı'nın yapısı. ✅ = var, 🔜 = sıradaki adımlarda.

- `scripts/core/`: **saf oyun mantığı**. `class_name` + `extends RefCounted`; Node, sahne ve `GameState`'e bağlı değil; headless test edilir.
  - ✅ `ContentDB`: `data/*.json`'u yükler ve doğrular: nadirlikler (simge, gölge ipucu, rütbe puanı, göl sevgisi), balıklar (12 tür; `release_only`: koruma altındaki mersin satılmaz, değeri 0), oltalar, takım (`gear.json`: kategori, fiyat, rütbe, değerler), rütbe (`progression.json`), atış noktaları ve bölgeleri (`zones_of`, `zone`: rütbe, sandal, balık ağırlıkları, `min_depth`, atış noktaları `stands`, çitler `gates`, şamandıralar `buoys`), kurallar. Oyunun gölü `spots.json` `"main"` (`big_lake`); `home_lake` testlerin sabit gölüdür, değiştirilmez. Büyük gölün (Dalga 2) altı bölgesi: iskele koyu (bugünkü iki elips), sazlık, nilüferli koy (rütbe 3), kayalık burun (5), dere ağzı (7), derin orta (9 + sandal); U biçimi: kuzey kıyısı orman, atış noktaları suya ekranın yukarısına bakar. Oyun açılışta yalnızca ana gölü kurar (`load_default(false)`); testler hepsini. `FishingRules`: `rules.json`'daki sayılar (süreler adım olarak da).
  - ✅ `Dice`: seed türetme, ppm şans, ağırlıklı seçim. Oynanıştaki her zar buradan ya da ondan türeyen RNG'den.
  - ✅ `LakeShape`: göl şekli: havzalar (elips + kendi derinliği ve kıyı eğimi + bölge) ve iskele; işaretli kıyı uzaklığı, derinlik ve bölge ızgarası (`zone_at`: suda havzanın, karada en yakın suyun bölgesi; sandal bölgesi kıyıdan `boat_from` m içeride başlar; sandal havzasının kıyı şeridi en yakın öteki havzaya `RIM_REACH` 3 m'den uzaksa bölgesiz: gölge doğmaz, dolaşmaz); yürünebilen dünya (`in_world`: kutu ve ormanın kenarı); şamandıranın düşeceği yer. Izgara `user://cache`'e yazılır (gölün tanımı ya da `BUILD_VERSION` değişince yenilenir). Eski şemadaki göl (`home_lake`) tek bölgeli ve bit bit eskisi gibi. Akıntı (`flow_at`: bölgenin `current`i; dar havzada tam, geniş havzada zayıf, havzanın dışında `FLOW_FADE` metrede söner; şimdilik görsel, Dalga 3'te sinek).
  - ✅ `FishShadow` + `ShadowSim`: gölgeler (doğma, dolaşma, fark etme, yaklaşma, kaçma, yeniden doğma; ilk av senaryolu). Bölgeli gölde gölgeler balıkçının çevresinde (menzil + `reach_extra`) ve yalnızca avlandığı bölgede (`player_zone`: durduğu yerin bölgesi, ızgaranın dışında en yakın hücreninki; kilitliyse yakındaki açık bölge) doğar: defter ve dükkânın gösterdiği oran gerçek oran (gelir kuralı 10); dolaşırken bölgesinde kalır; çok uzakta kalan ya da balıkçı başka bölgeye geçince eski bölgede kalan çekilir, yenisi yakında doğar (`leash_extra`, `recycle`); `relocate` hızlı geçiş; şans garantisi balıkçının bölgesinde; balıkçı sandaldaysa dolaşan gölge sandaldan `BOAT_CLEAR` uzak kalır. Tek bölgeli göl eskisi gibi (altın test).
  - ✅ `GearStats`: kuşanılmış takımın etkisi (menzil, güç, sarma, fren, kopma süresi, görünmezlik, kaçma payı, VUR süresi, kepçe, yem çekimi). `starter` = bambu olta, `best` = en iyi takım (rapor ve testler). `FishingSession` ve `ReelModel` takımı yalnızca buradan okur.
  - ✅ `BiteRules` (fark etme konisi, korkutma, dürtme, VUR penceresi, erken dokunuş), `FishTable` (tür, boy yüzdeliği, yıldız, gölge uzunluğu), `ReelModel` (gerilim, patlama, kopma, kaçma, Kolay mod), `ReelBot` (oyuncu tarzı botları), `Records` (kayıt defteri, kart kuralı).
  - ✅ `FishingSession`: durum makinesi (BOŞ → ATIŞ → BEKLEME → DÜRTME → ISIRMA → ÇEKİŞME → TUTULDU / KAÇTI). Sabit 1/60 sn adım; girdiler `cast` / `press` / `release` / `acknowledge`; olaylar `poll_events()`.
  - ✅ `Economy` (balığın değeri: tür değeri × boy çarpanı 0,6–1,6, binde birle; satış, satın alma, kuşanma, yem harcama; `gear_for` oturumun takımını kurar), `Bucket` (kapasite = sahip olunan en büyük kova; doluysa ya da tür koruma altındaysa (`release_only`) çağıran balığı bırakır), `Rank` (rütbe puanı, seviye, ilerleme).
  - ✅ `ShorePath`: kıyı yolu. Yürünebilen dünyada 0,5 m'lik ızgarada Godot'nun `AStarGrid2D`'si; su, dünyanın dışı, kapalı çitler (kilitli bölgenin `gates`'i) ve engeller (Dede, dükkân, kamp, büyük süsler) geçilmez; kıyı bandı ucuz. Düz çizgi açıksa düz; değilse yol gerilir. `route`, `nearest_open`, `clear_line`, `set_gate` (değişmeyen çit ızgarayı yeniden kurmaz; çok çitte `refresh_now = false` + `refresh()`), `crosses_closed_gate` (düz yürüyüş ve klavye adımı çitten geçmesin: `Angler.can_step`), `set_obstacles`.
  - ✅ `Zones`: bölge erişimi (rütbe, sandal: `unlocked`, `open_ids`, `lock_reason`, `unlocked_between`), `place` (oranların geldiği yer: bölge ya da göl), `at` (ızgaranın dışındaki karada en yakın hücrenin bölgesi: `LakeShape.zone_of`; bölge yoksa `lock_reason` boş).
  - ✅ `CatchOdds`: hangi balığın geleceği. Tür ağırlıkları × yem çekimi → ppm (toplamı tam 1e6; doğma, defter ve katalog aynı işlevi kullanır). Şans garantisi: `rarities.json` "pity" avdan sonra yakında doğan sıradaki gölge o nadirlikten (aynı anda tek garanti gölgesi; sayaç ancak o nadirlik tutulunca sıfırlanır). `pity_floor(db, save, spot)` gölde tutulamayan kademeyi saymaz (`top_rarity`).
  - ✅ `SessionSim`: denge botu (Kazı'nın `TripSimulator`'ı gibi). Oyunun kurallarını aynen kullanır (oranlar, şans garantisi, boy, çekişme `ReelModel` + `ReelBot`, kova, rütbe, satış, alışveriş: rütbesi yeten en ucuz takım); zamanı ve el becerisini `data/sim.json`'dan taklit eder (bölge başına süreler `zones`). Bölgeli gölde kıyı bölgesini oyuncu gibi seçer (önce gidilmemiş açık bölge, sonra tutulmamış türü en çok olan, sonra balık başına en çok kazandıran); sandalı rütbesi yetince öncelikle alır (parası yetene kadar biriktirir), sonra kovaların `boat_share` kadarını derin ortada doldurur; bölge değiştirmek ve satmak `travel_s`. `milestones`: olayların ilk olduğu dakika (`zone:<bölge>` dahil), `zone_time`. Aynı seed aynı sonuç.
  - ✅ `SaveData` (sürüm 3: kova, takım kimlikle, kuşanma, yem, rütbe puanı, göl sevgisi, şans garantisi, sayaçlar; v3 göçü rütbe puanını Dalga 2'nin uzun eğrisine taşır: `remap_xp`, rütbe ve ilerleme korunur) / `SaveStore` (atomik yazma), `TimeProvider` (zaman soyutlaması).
- `scripts/autoload/`:
  - `game_state.gd` (`GameState`): içerik + kayıt, ayarlar, dil, ipucu adımı, bayraklar, klavye kontrolleri. Sinyaller: `changed`, `focus_lost`, `focus_gained`. Odak kaybında kaydeder.
  - `sounds.gd` (`Sounds`): efektler (`BANK`), döngüler (makara, gerilim), ortam sesi, müzik, titreşim. Dosya yoksa sessiz geçer.
- `scenes/`: sunum (3D sahne ve arayüz kodla kurulur).
  - ✅ `main.gd`: her şeyi bağlar. Oturumun olaylarını ses + titreşim + görsele çevirir; kamera (olta sudayken eğilir, çekişmede yakınlaşır); Dede'nin ipuçları ve öğütleri (ipucu değişince Dede konuşur); yakalayışta kayıt; odak kaybında ve ayarlar açıkken oyun donar.
  - ✅ Rütbe dışarıdan değişince (geliştirme düğmesi, kayıt sıfırlama) oturumun erişimi ve çitler yenilenir (`_access_rank`).
  - ✅ Hızlı geçiş (`_travel`): haritada açık bir bölgeye dokununca ekran kararır (`Fade`), balıkçı bölgenin atış noktasına suya dönük geçer (`Angler.face_now`), `FishingSession.relocate` gölgeleri yeni yerin çevresinde doğurur, kamera hemen gelir. Rütbe atlayınca açılan bölge: bildirim (bölgenin rozetiyle), Dede'nin sözü (`UI_DEDE_ZONE_OPEN`), harita düğmesinin nabzı (`Hud.pulse_map`). Gidilen bölge `flags["visited_<bölge>"]` (haritada "Yeni!" söner).
  - ✅ Sandal (`in_boat`, `_go_boat`, `_leave_boat`): sandala ya da haritada sandal bölgesine dokununca kararmayla şamandıranın yanına (`LakeScene.moor_boat`); sandalda yürünmez, dokunuş atış; oturumun erişimi sandal bölgeleri (`Zones.open_ids(..., true)`); "Kıyıya dön" (`Hud.shore_button`) ya da kıyı bölgesine geçiş sandalı iskeleye döndürür (`LakeScene.dock_boat`). Sandal yokken Dede söyler (rütbe yetiyorsa Nine'yi).
  - ✅ Yürüme: karaya dokununca kıyı yolundan (`Angler.walk_path`); menzil dışındaki suya dokununca düz yürüyüş menzile sokuyorsa düz, sokmuyorsa kıyı yolundan hedefe en yakın kıyıya; hedef kilitli bölgedeyse balıkçı çitin önünde durur, Dede söyler (`UI_DEDE_GATE`). AT düğmesi önü karaysa suyun olduğu en yakın yöne atar.
  - ✅ `input_router.gd` (`InputRouter`): dokunma / fare / klavye. Olta boştayken (`targets_active`) dünyadaki bir hedefe dokun (`hit_targets`: Dede → konuşur, Nine ya da dükkânı → selam ve dükkân, sandal → alındıysa binilir, yoksa Dede söyler) → `target_tapped(kimlik)`; olta dönerken hedefler dokunuşu yutmaz (atış saklanır), karaya dokun → yürü, suya dokun → at (menzil dışıysa main önce yaklaştırır); olta sudayken ekranın her yeri eylem (parmak değdiği an `press`, kalkınca `release`).
  - ✅ `camera/follow_camera.gd`: sabit eğik açı, yumuşak takip, sarsıntı; `pitch` ve `zoom` main'den.
  - ✅ `world/`: `LakeScene` (süsler bölge bölge kurulur: her bölgenin takımı `ZONE_KITS`, kendi seed'i; kilitli bölgelerin çiti (Kenney `fence`, tabela; bölge açılınca gizlenir `set_gate_open`), derin ortanın şamandıraları; kamera tarafı kuralı: ağaç, balıkçının durabileceği yerle kamera arasına düşmez; ortam ve ışık, kıyıya doğru hafif yükselen arazi ağı, su, iskele, sallanan sazlar; KayKit orman paketinden yuvarlak ağaçlar, korular, çalılar, çimen öbekleri ve yosunlu kayalar (`moss.gdshader`); kodla nilüfer ve çiçekler; Kenney kampı ve iskeleye bağlı, suyla sallanan sandal (dokunma `boat_hit`: alındıysa binilir, yoksa Dede konuşur); uzakta tepeler; süsler `keep_clear` dairelerine (dükkân, kamp) ve iskeleye düşmez; model yoksa Props), `LakeTexture` (göl veri dokusu: R derinlik, G kıyı uzaklığı, A akıntı; zemin dokusu `build_ground`: R yürünebilen dünya, G taşlık), `water` (derinlik rengi metreye göre: `depth_scale`; 4–9 m'de koyu; iki katlı dalgacık, parıltı, köpük, kıyıya gelen dalga çizgileri, derede akıntı çizgileri `flow_dir`) / `ground` (çimen öbekleri, orman zemini, kıyı yolu, kum ve ıslak kenar, taşlık; Ersin'in zemin karoları dördü birden varsa onlarla: `LakeScene.GROUND_TILES`) / `shadow` / `reeds` / `moss` shader'ları (ortak gürültü `noise.gdshaderinc`), kıyı yolu (`PATH_AT`, kıvrımı `path_wobble` shader'la aynı formül; `on_path`: çalı, çimen öbeği, çiçek ve yakın ağaç yola düşmez), `ShadowLayer` (gölgeler; nadirlik ipucu: pırıltı, ışıltı, kabarcık, dalga izi), `Bobber` (şamandıra), `FishingLine` (misina; `frame_pre_draw`'da kurulur), `Props`, `ModelLibrary` (aynı modelin kopyaları `scatter` ile tek MultiMesh; aynı dokulu bir paketin farklı modelleri `merge` ile bölge parçalarında tek ağ; `bounds`), `ShopStall` (Nine'nin dükkânı: kodla ahşap tezgâh, raflar, çizgili tente, tabela, olta sehpası; `keeper_spot`, `blockers`, dokunma `hit`), `MeshBatch` (durağan parçaları ve kodla hesaplanan üçgenleri (`triangles`) köşe renkli tek ağda birleştirir). Çizim sayısı az tutulur: iskele ve dükkân renk başına tek ağ, orman parçaları bölge başına tek ağ (gölün ortasına göre 30 m'lik ızgara), nilüfer ve çiçekler tek ağ, opak suyun altındaki arazi kurulmaz.
  - ✅ `player/`: `Angler` (yürür, kıyıda durur, engellerin çevresinden kayar (`avoid`), kapalı çitten geçmez (`can_step`: main verir); her kare `pose` = free / hold / reel ve `tension` verir; atış, gösterme, sevinç tek seferlik). Görünüm `AnglerBody` (KayKit Rogue: boyanmış doku, gizlenen parçalar, kodla şapka, AnimationTree, `AimModifier` ile geriye yaslanma) ya da yedek `ToyAngler` (aynı arayüz). `RodModel`: üç eklemli, gerilimle bükülen olta; el yuvasındaki `rod_mount`'a takılır, serbestken dik taşınır.
  - ✅ `player/villager.gd` (`Villager`): köylülerin ortak davranışı (konuşma balonu, oyuncuya bakış, baş sallama, sevinç, izleme `focus`, boşta bakınma, dokunma denetimi `hit`).
  - ✅ `player/elder.gd` (`Elder` < `Villager`, Dede): iskele kenarında oturur (`seat`), balıkçıya engel (`blocker`), şamandırayı izler. Görünüm `ElderBody` (KayKit Barbarian: Sit_Chair_Idle, üst gövdeden Cheer, kodla kasket, `LookModifier` ile baş çevirme ve sallama, `portrait()` ipucu çubuğu yüzü) ya da yedek `ToyElder`.
  - ✅ `player/nine.gd` (`Nine` < `Villager`, Dede'nin eşi): dükkânın tezgâhının arkasında ayakta (`stand`), yaklaşan balıkçıya bakar (`watch`), dokununca selam verir (`greet`). Görünüm `NineBody` (KayKit Mage: boyanmış doku, kodla mavi çiçekli yazma, puantiyeli önlük, gözlük; Idle, üst gövdeden Interact ve Cheer; `portrait()`) ya da yedek `ToyNine`. `CharacterKit`: karakterlerin ortak yardımcıları (giydirme, dış çizgi, döngü, üst gövde süzgeçli tek seferlik animasyon, kemik yuvası).
  - ✅ `world/fish_mesh.gd` (`FishMesh`): kodla balık (halkalı gövde, çatal kuyruk, yüzgeçler, gözler, bıyık; köşe renkleri). Türün biçimi `SHAPES`'te: oran, burun, göz ve rengi, çizgi, yan şerit, koi lekeleri, kemik plakalar, sırt yüzgeci sayısı, uzun anal yüzgeç, kuyruk çatalı ve eğimi. `fish.gdshader` + `fish_outline.gdshader` kuyruk kıvrılmasını `fish_bend.gdshaderinc`'ten paylaşır. `display_length()`: elde gösterilen boy.
  - ✅ `fx/`: `Ripples` (su halkaları), `CatchFx` (tutulan balık balıkçının önünde, nadirde ışık sütunu), `CatchTag` (balığın üstünde 2B etiket: nadirlik simgesi, adı, boyu), `PortraitStudio` (bir 3B nesneyi saydam SubViewport'ta çizip resim yapar), `FishPortrait` (açılışta her balığın resmi → `ItemArt`).
  - ✅ `ui/`: `UiKit` (stil, fontlar, `upper()`, `safe_insets()`, `fit_size` (uzun yazı tek satıra sığsın diye küçülür), simgeli `rarity_badge`, `rarity_icon`; Ersin'in çerçeveleri `framed(ad, yedek, köşe)`: 9 dilim payları `FRAME_SLICES`, içerik payları `FRAME_CONTENT`; düğme görselleri `BUTTON_ART` (renk → görsel; basılı koyu, pasif gri), `ring_style` (anlam taşıyan renk çerçevenin dışında halka)), `Dialog` (panellerin tabanı; ekrana sığmazsa küçülür `fit_scale`), `Hud` (eylem düğmesi, harita (ilk balıktan sonra: `map_allowed`), defter ve ayarlar düğmeleri, sol üstte geliştirme sürümünde FPS, ölçüm açıkken (`perf`) her sürümde FPS, çizim ve üçgen sayısı, gerilim çubuğu `TensionBar`, ikonlu bildirim `toast(metin, renk, ikon)` ve sırası `toast_later` / `hold_toasts`, ipucu çubuğu ve konuşanın yüzü: `show_hint(anahtar, konuşan)`; yüz sözün ifadesiyle portreden, portre yoksa `set_portrait` ile verilen yedek), `Moods` (söz → ifade: smile, story, wow; ipucu çubuğu, karttaki Dede ve dükkân başlığı), `FishCard` (balık kartı; nadirliğin çerçevesinde resim, adın arkasında kurdele, simgeli rozet, Dede'nin sözü `dede_line`; koruma altındaki türde koruma sözü ve "Göle bırak"), `SettingsPanel` (başlıkta logo; sürüm yazısına arka arkaya 5 dokunuş ölçümü açar ya da kapatır: `settings["perf"]`; ölçüm açıkken geliştirme sürümünde "Bütün bölgeleri aç" (rütbe en yüksek bölgeninki, sandal; telefonda ölçüm ve deneme için) ve kaydı sıfırla; normalde panel telefonda küçülmeden sığar), `MapPanel` (harita: `MapView`, gölün oranında, en çok `MAP` boyunda: telefonda panel küçülmeden sığar; çerçevesi Ersin'in harita kâğıdı (9 dilimli `map_paper`; kâğıdın payı kalın olduğu için harita o kadar küçülür, panelin boyu aynı kalır); açık bölgeye dokun → `travel_requested`, kilitlide neden), `MapView` (harita verisi `build_image`: kıyı uzaklığı, derinlik, bölge, yürünebilen yer; `map.gdshader` ile çizilir, kâğıt varsa kenarı kâğıda karışır (`fade_m`); rozetler bölgenin suyunun ortasında, "Yeni!" köşede, iskele, çitler (ortasında tabela) ve şamandıralar üstte; Ersin'in çıkartmaları: bölgenin süsü `ZONE_STICKERS`, ormanda ağaç öbekleri `forest_points`, iskelede sandal, dükkân, pusula; çıkartma rozetlere, iğneye, işaretlere ve birbirine binmeyen en yakın yere kayar (`free_spot`), yer yoksa gizlenir), `Fade` (ekran kararıp açılır; sürerken dokunuş geçmez), `ShopPanel` (Nine'nin dükkânı: sekmeler (Ekstra: kepçe, sandal, sıradaki kova `Bucket.next_bucket`), 3×2 kart, değer çubukları, al ve tak, rütbe kilidi, kova ve satış; `gear_changed`, `sold`), `BookPanel` (Balık Defteri: 6×2 sayfa, siluet, rekor, ipucu, takımla oranlar, şans garantisi; tutulan türün resmi nadirlik çerçevesinde), `TouchButton`, `GameIcon` (görseller: `ART_NAMES`, nadirlik rozetleri `RARITY_ART`, sekmelerde takım resmi `GEAR_ART`, bölge rozetleri `zone:<bölge>` (Parti 3 görseli yoksa kodla: iskele, kamış, nilüfer, kaya, dere, şamandıra), harita iğnesi `pin`, yalnızca görselle çizilenler `anchor` ("Kıyıya dön"), `compass`, `buoy`, `signpost`: görseli yoksa çağıran başka ikon seçer ya da çizmez; görsel yoksa kodla çizer: `DRAWN` listesi, bilinmeyen ad soru işareti), `ItemArt` (görsellere tek giriş; takım resimleri `gear()`, bölge rozetleri `zone()`, harita çıkartmaları `map_art()`), `SpeechBubble` (köylülerin 2B konuşma balonu; balon görseli varsa onunla).
- `data/*.json`: içerik. `localization/strings.csv`: `keys,en,tr`.
- `assets/`: `fonts/`, `icons/ui/` (Kazı'nın genel ikonları; Ersin'in görselleri gelince değişir), `audio/` (`tools/make_sounds.py` üretir), `incoming/` (Ersin'in ham görselleri; `.gdignore`'lu).
- `tests/`: `run_tests.gd` (koşucu), `base_test.gd`, `test_*.gd`. Test metotları `test_` ile başlar. `test_golden.gd`: testlerin gölünde gölgeler ve oturum olayları birebir aynı kalır (`fixtures/golden_home_lake.json`; davranış bilerek değişirse `tests/make_golden.gd` ile yeniden üret).
- `scripts/dev/`: yalnızca debug: `autoplay.gd` (bot senaryoları, KONTROL satırları, ekran görüntüsü: geliştirme sürümünün FPS yazısı görüntüye girmez, ölçüm açıkken girer), `video_overlay.gd` (parmak izleri).

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
- **Hazır modeller:** `assets/incoming/models/<paket>/`'ten yalnızca kullanılan dosyalar `assets/models/<paket>/`'e taşınır (dışa aktarma her içe aktarılanı paketler) + `ModelLibrary.MODELS` satırı + `assets/CREDITS.md`. Dokunun orijinali `source/` altına, boyanmışı modelin beklediği yola (`tools/recolor_texture.gd`); yeni doku `.import`'u `compress/mode=0`, `detect_3d/compress_to=0` (paletli doku sıkıştırılmasın). GLB içe aktarmada gömülü dokular atılır; karakterin dokusu kodla verilir.
- **Kayıt biçimi** değişirse: `SaveData.VERSION`'ı artır, `migrate()`'e adım ekle, `test_save_data.gd`'ye test yaz. Her sürümün gerçek bir örneği `tests/fixtures/save_vN.json`'da durur ve değiştirilmez (göç zinciri ondan sınanır). Takım kimlikle saklanır, kademe numarasıyla değil.
- **Çekişme, balık ya da takım ayarı** değişirse: `tools/reel_report.gd`'yi (ve `-- --gear=top`) çalıştır, `docs/gdd.md` §5'teki tabloları güncelle; `test_reel_model.gd` korkulukları (en iyi takımla da beceri gereksin) yeşil kalsın. Balığın `pull` değeri sınırın en az 0,05 altında olmalı; en güçlü frende patlama sınırın en az 0,1 üstünde kalmalı (ContentDB denetler).
- **Koordinatlar:** dünya x/z metre; çekirdek mantık `Vector2(x, z)` kullanır, su yüzeyi y = 0. Kamera +x +z tarafında; iskele kıyıdan −z yönüne uzanır.
- **Her sesin** bir görsel ve titreşim karşılığı olur (iPhone'un sessiz anahtarı sesi kapatır).
- **Ekonomi** (fiyat, balık değeri, rütbe puanı, kova, yem) değişirse: `tools/economy_report.gd`'yi çalıştır, `docs/gdd.md` §10.4'teki tabloyu güncelle; `test_session_sim.gd` korkulukları yeşil kalsın. Oran değiştiyse `tools/fish_catalog.gd` ile kataloğu yeniden üret; yeni bölge öncekilerden az kazandırmamalı (`test_economy.gd`). Gölge ya da ısırma kuralı değiştiyse önce `tools/session_timing.gd` ile `data/sim.json`'u güncelle (bölgelerin süreleri `--zone=` ile).
- **Rütbe eğrisi** (`progression.json` `xp`) değişirse eski kayıtlarda rütbe düşer: `SaveData`'ya yeni sürüm, o sürümün eğri sabiti (`XP_CURVE_Vn`) ve `remap_xp` ile göç adımı ekle (`test_save_data.gd` eğriyi son sabitle karşılaştırır).
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
- Çizim sayısı: her MeshInstance3D bir çizim; dış çizgisi ve gölgesi birer çizim daha. Kodla kurulan durağan parçalar `MeshBatch` ile tek ağda birleşir (köşe rengi; `vertex_color_is_srgb` açık olmalı, yoksa renkler Props'unkinden açık görünür). Gölgesi görünmeyen parçaların (tente altındaki Nine, çay bardağı, karakterlerin kolları ve şapkanın örttüğü baş: `SHADOWLESS`) gölgesi kapatılır. Ölçüm (Dalga 2, 1560×720, `tour` botu; karenin bütün çizimleri, arayüz dahil): iskelede 140 çizim (hedef ≤150), öteki atış noktalarında 88–114, sandalda 98; göl sahnesinin bir bakışta görünen ağları `test_models.gd` `START_DRAWS` / `VIEW_DRAWS` sınırında (görüş alanı elle hesaplanır: `Projection.get_projection_planes` GDScript'e açık değil).
- `-s` ile çalışan testlerde root'a eklenen düğüm ağaçta sayılmaz (`is_inside_tree` false): `to_global` ve `global_transform` hata verir. Yerleşim hesaplayan sınıflar (`ShopStall`) üst düğümün uzayında (`transform * nokta`) hesaplar.
- `pgrep -f` / `pkill -f` deseni kendi komut satırında da geçer: bekleme döngüsü kendini bulur, `pkill` kendi kabuğunu öldürür. Arka plan işini bildirimiyle bekle.
- KayKit animasyonları döngüsüz gelir; döngü çalışırken açılır. Kemik pozuna animasyondan sonra dokunmak için `SkeletonModifier3D`.
- KayKit Rogue'da baş yuvası yok (yalnızca `handslot_r` / `handslot_l`): şapka, `head` kemiğine bağlanan bir `BoneAttachment3D`'ye takılır. El yuvasında nişan duruşlarında +X ileri, +Y yukarı bakar; olta bu yüzden +X'e göre kurulur (`AnglerBody.ROD_TILT`).
- `-s` ile çalışan araçlarda eklenen düğümlerin `_ready()`'si ilk karede çalışır: `_ready`'de kurulan parçalara (ör. `rod_mount`) `_initialize`'da değil, ilk `_process` karesinde dokun. Animasyonu `seek` ile ölçmek de ancak kareler ilerledikten sonra doğru sonuç verir.
- Headless çalışmada (testler, `--headless`) `SubViewport` çizilmez: `PortraitStudio` null döner, kartta yer tutucu madalyon, ipucu çubuğunda yer tutucu ikon kalır.
- Sahne ton eşlemesi (Filmic, `tonemap_white` 6) 3B'deki ışıksız beyazı da griye çeker: arayüz gibi görünmesi gereken parçalar (konuşma balonu) 2B çizilir ve her kare `unproject_position` ile 3B noktaya taşınır.
- Üstel sis doğrusal renk uzayında karışır. Kameranın 12 m'sinde %7'lik sis bile koyuları açar ve bütün görüntüyü puslu yapar (Ersin telefonda "sisli" dedi).
  - Göl sahnesinde derinlik sisi (`FOG_MODE_DEPTH`; Compatibility'de çalışır) oyun alanının dışında başlar (`LakeScene.FOG_BEGIN`).
  - Doygunluk ayarı yok.
  - Işıkla oynarken telefon boyutundaki ekran görüntülerini karşılaştır: doygunluğu ve en koyu %5'in parlaklığını ölç.
- Kamera +x +z tarafında ve yukarıdan bakar: bir karakterin yüzü yalnızca kameraya dönükken görünür. Dede bu yüzden kameraya üçte bir dönük oturur ve konuşurken başını kameraya kaldırır (`LookModifier` yukarı bakış).
- Balıkçı düz çizgide yürür: yoldaki engeller (Dede) `Angler.avoid` ile çevreden kayılarak geçilir; durdurmak yerine kaydırmak, "karaya dokun" yürüyüşünün takılmamasını sağlar.
- Video kaydında (Movie Maker) oyun zamanı gerçek saatten yavaş akar; bot döngülerinde kare sayısı kullan. Kayıtta `OS.has_feature("movie")` true: hata ayıklama FPS etiketi gizlenir.
- `Image.blend_rect` iki görüntünün aynı biçimde olmasını ister (RGBA8).
- Kodla kurulan ağlarda üçgenler dışarıdan bakınca **saat yönünde** sıralanmalı (Godot'nun ön yüzü). Ters olursa `generate_normals()` normalleri içe çevirir; `cull_disabled` ışığı düzgün gösterdiği için fark edilmez ama dış çizgi kabuğu (`NORMAL` yönünde büyür) gövdenin içinde kalır (`FishMesh._tri`).
- Göl veri dokusu yarım float (`FORMAT_RGBAH`): 8 bitlik kanal 12 m'lik kıyı uzaklığını 4,7 cm'lik basamaklara böler, kıyı köpüğü testere dişi olur.
- Parlak düğme dokuları (`UiKit.glossy`) GDScript'te piksel piksel çizilir (her biri ~40 ms): oyunda sonradan görünen renkler açılışta çizilir (`Hud.warm_styles`), yoksa ilk dürtme, VUR ve kart anında takılır.
- Kartlı yakalamada (kart açıkken ya da açılacakken) gelen dokunuş saklanmaz: kartı kapatan dokunuş olta da atmasın. Olta dönerken (kaçtı, geri sarma, kartsız kısa yakalama) gelen atış dokunuşu saklanır, dönünce atılır.
- Konuşma balonu dokunma hedefi değildir: sık çıkar ve iskelenin üstünde durur; yürüme ve atma dokunuşlarını yutmasın. Dede'ye dokunmak için Dede'nin kendisi.
- İpucu çubuğu tek satır ve iki yandaki eylem düğmesi payının arasında: taşan yazı eylem düğmesinin altında kalır. Yeni bir ipucu ya da Dede / Nine sözü eklenince `test_hud.gd` iki dilde ölçer (16:9'da yazıya ~1038 birim; İngilizcesi daha uzun).
- Göl ızgarasının kurulumu (kıyı, derinlik, bölge) değişirse `LakeShape.BUILD_VERSION`'ı artır: yoksa telefonda ve testlerde eski önbellek okunur. Eski göllerin ızgarası bit bit aynı kalmalı: elips hesabı `Vector2` farkı ve float bölmeyle, uzaklık 32 bitlik diziden geçer (altın test denetler).
- `LakeShape.shore_distance` ızgaranın dışında (kıyıdan 4 m öte) hep −MARGIN verir: kıyıdan uzak bantlar (ağaç, koru) `land_distance` ile ölçülür.
- `LakeShape.zone_at` ızgaranın dışında −1 verir; yürünebilen dünya ızgaradan büyük (dükkânın arkasındaki çayır): balıkçının ve dokunulan yerin bölgesi `zone_of` (en yakın hücre) ya da `Zones.at` ile alınır. Bölgesiz su da var (derin ortanın uzak kıyı şeridi).
- Oran gösteren her ekran (defter, dükkânın yem kartı) `session.zone_id()`'yi (avlanılan bölge, `ShadowSim.player_zone`) kullanır: gölgeler yalnızca orada doğar. Durduğu yerin bölgesi (`zone_at`) kilitli olabilir (çitin önü).
- Autowrap'lı Label'ın en küçük yüksekliği genişliği belli olunca (ilk yerleşimden sonra) doğru çıkar: açılışta ölçülen boy büyüktür. Boyuna göre ölçeklenen ya da ortalanan bir düğüm bunu her kare (ya da `resized`'da) yeniden hesaplamalı (`FishCard._fit_card`, `Dialog`).
- Çerçeve görselinin içerik payları kartı `CARD`'dan büyütebilir: dükkân botu her sekmede kartların `ShopPanel.CARD`'ı aşmadığını ve panelin boyunun sabit kaldığını denetler; balık kartının düğmesi ekrana sığdırılınca da 122 birimden küçük olmamalı (`controls` botu).
- Bu bulut ortamında `kenney.nl`, `quaternius.com`, `godotengine.org` erişime kapalı; KayKit'in GitHub depoları açık (seyrek klonla).
- Export: `data/*.json` pakete girmeli (`include_filter`); `tests/*`, `tools/*`, `scripts/dev/*` hariç.
- Dokunuştan üretilen taklit fare olayı dokunuşun kendisinden **önce** işlenir. Basışta kapanan bir panel, aynı dokunuşu arkasındaki oyuna da geçirir (kart kapanır, olta atılır). Paneller parmak kalkınca kapanır (`FishCard`).
- Botun `Input.parse_input_event` ile gönderdiği dokunuş bir sonraki karede işlenir: sonucu ölçmeden önce 1–2 kare bekle.
- Compatibility renderer'da `blend_mul` (çarpma karışımı) dörtgenin tamamını karartıyor: gölgeler koyu renkli `blend_mix` ile çizilir.
- GLES3'te bir dokunun tek süzgeci olur: aynı dokuyu iki uniform'a (biri `filter_linear`, biri `filter_nearest`) vermek ikisini de aynı süzgeçle okutur (harita basamaklı çıkar). İki farklı süzgeç gerekiyorsa aynı görüntüden iki doku yap (`MapView.map_texture`).
- Göl suyu y = 0'da: suyun üstüne düşen büyük bir düzlem (ör. dış zemin) gölü örter. Dış zemin, arazi ağının çevresinde dört şerittir.
- Kıyı çizgisinde arazi suyun biraz altındadır (`SHORE_DIP`): görünen kıyı, ağın üçgenleri değil, suyun pürüzsüz kenarıdır.
- Bot çıkmadan önce `Sounds.stop_all()` çağırıp birkaç kare bekler; yoksa çalan ogg için çıkışta "resources still in use" hatası çıkar.
- `FishingSession.advance` bir karede en fazla 0,5 sn işler: testlerde uzun süreyi parça parça ilerlet.
- Luckiest Guy'da büyük harflerin üstündeki nokta ve şapkalar (İ, Ü, Ğ, Â) satır kutusunun dışına taşar: Label'da `clip_text` onları keser ("KUCUK IGNE"). Uzun adlarda `text_overrun_behavior` (…) ya da küçük yazı kullan.
- Luckiest Guy ve Baloo 2 Türkçe karakterleri destekler. Yeni font seçilirse ğ, ş, ı, İ kontrol edilmeli. Varsayılan fontta ★ ve ok işaretleri yok. Baloo 2'de → ve × var, ★ yok; Luckiest Guy'da → da yok (» ve × var). Emin değilsen `FontFile.has_char` ile denetle; simgeler `GameIcon` ile çizilir.
