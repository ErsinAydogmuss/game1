# Yol Haritası

Yarı zamanlı çalışma (iş arasında) ve kodun Claude tarafından yazılması varsayıldı. Süreler tahmin; önemli olan sıra. Her adım ayrı commit; adım bitince kısa bir "telefonda dene" listesi gelir.

## Faz 0: Kurulum

- [x] Saha araştırması ve fikir seçimi (Olta: Gölün Sırrı).
- [x] Godot projesi, testler ve iPhone dışa aktarma ayarı (1. hafta, adım 2).
- [ ] Mac'teki Claude Code ile telefona ilk yükleme: [`iphone-kurulum.md`](iphone-kurulum.md).
  - **Not:** ücretsiz Apple hesabıyla aynı anda en fazla 3 uygulama yüklenebilir; Kazı da bunlardan biri.
- [ ] **Apple Developer** (99 $/yıl) ve **Google Play Console** (25 $): dış testçilerden önce.

## Faz 1: Prototip

### H1: Çekirdek his ve stil

Plan: suya dokun ve at → gölge yaklaşır, dürter, ısırır → VUR → gerilimli çekme → balık elde ve kartta.

- [x] Karar kaydı.
- [x] Kısa tasarım belgesi ([`gdd.md`](gdd.md)), bu yol haritası, görsel istekleri ([`gorsel-istekleri.md`](gorsel-istekleri.md)).
- [x] Proje iskeleti: Kazı'nın test koşucusu, kayıt, arayüz parçaları ve ses motoru; yer tutucu göl; iPhone ayarı. (Bot altyapısı 4. adımda.)
- [x] Çekirdek mantık ve testler: `ContentDB`, `LakeShape`, `ShadowSim`, `BiteRules`, `ReelModel`, `FishTable`, `FishingSession`, `Records`, `SaveData`. Denge raporu: `tools/reel_report.gd`.
- [x] Gri kutu oynanış.
  - [x] Göl şeklinden su ve kumsal, yer tutucu balıkçı ve şamandıra, misina ve gölgeler.
  - [x] Dokunma kontrolleri, HUD, gerilim çubuğu, Dede'nin ipucu çubuğu, balık kartı.
  - [x] Sesler (`tools/make_sounds.py`) ve titreşim; `controls` ve `first` bot senaryoları.
  - [ ] **1. telefon denemesi** (Ersin).
- [x] Göl görselleri:
  - arazi ve kumsal;
  - su (derinlik rengi, dalga, parıltı, köpük);
  - gölge ve halkalar;
  - iskele, sallanan sazlık, KayKit ağaçları, kayalar, tepeler ve küçük bir kamp.
- [x] Balıkçı (kız; KayKit Rogue), olta, misina, şamandıra; 5 balığın 3D modeli; elde balık ve kart.
- [x] Ek işler (vakit kalırsa):
  - [x] iskelede oturan Dede (bakar, konuşur, sevinir; dokununca öğüt verir);
  - [x] `hero` ve `fish` senaryoları;
  - [x] kısa video (35 sn, `video` senaryosu).
- [x] README, CREDITS, kod incelemesi (3 ayrı inceleme: çekirdek, akış ve arayüz, 3B; bulgular düzeltildi), "telefonda dene" listesi.

### Ersin'in ilk geri bildirimi

"Oyun mantığını beğendim, temel olarak güzel." İstekler: daha büyük göl, dükkân ve ekipman, balıklarda nadirlik, çeşitli teknikler, daha profesyonel görseller, Claude'un önerileri. Araştırma ve iki tur sorudan sonra H2 "Büyük Göl" planı çıktı. Tasarım: [`gdd.md`](gdd.md) §10.

### H2: "Büyük Göl" ← şu an buradayız

- **Her adım:** ayrı commit.
- **Her dalganın sonunda:** inceleme, video, "telefonda dene" listesi, sürüm artışı.
- **Görseller ve 3D paketler:** gelene kadar kodla çizilen yedekler kullanılır; iş beklemez.

**Dalga 0 — Hazırlık**

- [x] Tasarım belgeleri (gdd §10, bu yol haritası).
- [x] Görsel istekleri Parti 1–2 ([`gorsel-istekleri.md`](gorsel-istekleri.md)); 9 dilimli çerçeve desteği (`UiKit.framed`).
- [x] Mac'te CC0 3D paket indirme görevi ([`mac-indirme.md`](mac-indirme.md)).

**Dalga 1 — Dükkân, takım, para, nadirlik, defter → v0.2**

- [x] İçerik v2: 6 nadirlik kademesi ve simgeleri, takım verisi (`data/gear.json`), rütbe (`data/progression.json`), oyunun gölü `big_lake` (testlerin gölü `home_lake` sabit).
- [x] Takımın çekişmeye etkisi (`GearStats`): menzil, güç, sarma, fren, misina, iğne, şamandıra, kepçe; en iyi takım korkulukları.
- [x] Para, kova, rütbe, oranlar ve şans garantisi (`Economy`, `Bucket`, `Rank`, `CatchOdds`); kayıt v2 ve göç testi.
- [x] HUD'da para, kova ve rütbe.
- [x] Nine ve dükkân binası: KayKit Mage'den Nine (yazma, önlük, gözlük), kodla ahşap dükkân; dokununca selam.
- [x] Dükkân paneli (sekmeler, kartlar, al ve tak, rütbe kilidi), kova ve satış; `shop` bot senaryosu. Takım çantası teknik düğmesiyle Dalga 3'te.
- [x] Nadirliğin gölgede ve kartta görünmesi: simgeli rozetler, gölgede pırıltı / ışıltı / iz, efsanevi gölgede Dede'nin uyarısı ve ezgi, yakalamada 2B etiket, kartta Dede'nin sözü; gri tonlama denetimi (`rarity` senaryosu).
- [x] Balık Defteri: sayfalı 6×2 ızgara (siluet ve nadirlik simgesi), rekor ve sayılar, ipuçları (sevdiği yem, görülme sıklığı), takımla gerçek oranlar ve şans garantisi sayaçları; HUD'da defter düğmesi. (Kaydırmalı metin mektuplarla Dalga 4'te.)
- [x] Denge botu (`SessionSim`; süreler gerçek oturumdan `tools/session_timing.gd` ile) ve korkuluk testleri (`test_session_sim.gd`); ekonomi raporu (gdd §10.4); oran kataloğu ([`balik-katalogu.md`](balik-katalogu.md)); yemler kendi türünü belirgin çağırır, kartta gerçek şans; `shop` senaryosu.
- [x] Kapanış: inceleme (10 bulgu düzeltildi), tanıtım videosu (Nine, dükkân, defter, nadir ve destansı balık), telefonda dene listesi. **v0.2.**

**Ara sürüm v0.2.1 — Ersin'in görselleri ve 3D paketler**

Ersin Parti 1–2 görsellerini (19 sayfa) ve Mac'te indirdiği CC0 3D paketleri yükledi; hepsi Dalga 2'den önce bağlandı.

- [x] Görseller kesildi: arayüz, takım, portreler, uygulama ikonu ve logo (`process_images.gd`; mor nesneli sayfalarda yalnızca kenar temizliği).
- [x] Çerçeveler ve düğmeler: panel, kart, sekme, kurdele, hap, balon; basılı ve pasif düğmeler; yazı süse binmez.
- [x] Nadirlik rozetleri (görselden) ve çerçeveleri (balık kartı, defter ayrıntısı); gri tonlamada şekliyle ayrılır.
- [x] İkonlar ve takım resimleri: dükkân sekmeleri, HEPSİNİ SAT kesesi, "kova dolu" bildirimi göle dönen balıkla.
- [x] Dede ve Nine'nin yüzleri sözle değişir (gülümser, anlatır, şaşırır).
- [x] Uygulama ikonu (zıplayan koi), açılış ekranında logo, ayarlarda logo.
- [x] Göl kenarı hedef ekrana yaklaştı: KayKit orman paketinden ağaçlar, korular, çalılar, çimen ve yosunlu kayalar; kodla nilüfer ve çiçekler; Kenney kampı ve iskeleye bağlı sandal (dokununca Dede konuşur). Çizim 180 → 160.
- [x] Kapanış: inceleme (5 bulgu ve küçük öneriler düzeltildi: ipucu çubuğuna sığmayan söz, uzak koruların yerleşmemesi, dükkân panelinin sekmeden sekmeye büyümesi, sandala yutulan atış dokunuşu, balık kartının fazla küçülmesi), tanıtım videosu, telefonda dene listesi. **v0.2.1.**

**Dalga 2 — Büyük göl → v0.3**

- [x] Göl verisi v2: havzalar (her birinin derinliği ve kıyı eğimi) ve bölgeler, yürünebilen dünya; testler için sabit küçük göl (bit bit eskisi gibi, altın test); kıyı ızgarası 3,5 kat hızlı ve önbellekli; kuşbakışı önizleme aracı.
- [x] Gölgeler bölgelere göre doğar: balıkçının çevresinde ve yalnızca avlandığı bölgede (inceleme düzeltmesi: defterin ve dükkânın gösterdiği oran gerçek oran); türü bölgeden; yürüyünce peşinden gelir; şans garantisi bulunulan bölgede.
- [x] Kıyı yolu ve dünya sınırı: dokunulan yere sudan geçmeden, kısa yönden; kilitli bölgenin çitinde durur, Dede söyler; ormanın kenarı yürünmez (büyük gölde U biçimi).
- [x] Göl sahnesi ve bölge süsleri: büyük göl oyunun gölü; her bölgenin kendi süsleri (sık kamış, nilüfer tarlası, iri kayalar, dere), çitler ve tabelalar, şamandıralar; bölgeye girince adı; su rengi metreye göre; çizim iskelede 164 → 142.
- [x] Harita ve hızlı geçiş: gölün verisinden kodla çizilen harita (bölge rozetleri, kilitler, "Yeni!", Buradasın, çitler, şamandıralar); açık bölgeye dokun → ekran kararır, oraya geçilir; yeni bölge açılınca bildirim, Dede ve nabız; `map` bot senaryosu.
- [x] Sandal: dükkânın Ekstra sekmesinde (kovalar tek kartta); iskeledeki sandala ya da haritada derin ortaya dokun → ekran kararır, şamandıranın yanında sandaldasın; yürüme yok, dokunuş atış; gölgeler yalnızca derin ortada, sandalın altına girmez; sıradaki şamandıra; "Kıyıya dön"; `boat` bot senaryosu.
- [x] Bölge balıkları: 7 yeni tür (gümüş balığı, çapak, tatlısu kefali, kadife, sudak, altın sazan, mersin), her biri kendi bölgesinde ve kodla kendi görünüşünde (mersinde sivri burun, plakalar, bıyık; altın sazanda koi lekeleri; kadifede kırmızı göz); kendi çekişi ve sevdiği yem; mersin koruma altında: kovaya girmez, kartta Dede'nin sözüyle göle bırakılır. Defter 12 tür, tek sayfa.
- [x] Denge: denge botu bölge bölge oynar (yeni bölgeyi merak eder, sonra tutmadığı türü, sonra kazancı arar; sandala biriktirir); rütbe eğrisi uzadı (rütbe 3 / 5 / 7 / 9 ≈ 10 / 24 / 46 / 75. dakika; eski kayıtta rütbe korunur, kayıt v3), sandal 3.500 para (≈ 2 saatte); dere ağzı kayalık burundan az kazandırmasın diye turna ve yayın arttı.
- [x] Su ve zemin: kıyıya gelen dalga çizgileri, derede akıntı; çimen öbekleri, orman zemini, gölü dolaşan toprak yol, ıslak kum, kayalık burunda yosunlu taş (kodla; Ersin'in zemin karoları gelince onlarla).
- [x] Telefonda hız ölçümü: ayarlarda sürüm yazısına 5 dokunuş (sol üstte FPS, çizim, üçgen), geliştirme sürümünde "Bütün bölgeleri aç", `tour` bot senaryosu, kurulum belgesinde ölçüm adımları (`iphone-kurulum.md` 12. adım). Telefondaki sayılar Ersin'den gelecek.
- [x] Kapanış: üç inceleme ajanı (çekirdek, sunum, araçlar ve belgeler). Düzeltilen bulgular: gölgeler gösterilen oranın bölgesinde doğmuyordu, kapalı çitten düz yürüyüşle geçilebiliyordu, dükkânın arkasındaki çayırın bölgesi yoktu, derin ortanın uzak kıyı şeridi başka bölgelere sayılıyordu, sandalın dibindeki gölge takılıyordu, harita ve ayarlar telefonda küçülüyordu; küçük öneriler de yapıldı. Tanıtım videosu (turna, yeni bölge, Nine, harita, altın sazan, sandal, mersin), telefonda dene listesi. **v0.3.**

**Ara sürüm v0.3.1 — Parti 3–4 görselleri ve telefondaki geri bildirim**

- [x] Parti 3 görselleri oyunda: zemin dokuları (çimen, kum, toprak yol, yosunlu taş), bölge rozetleri (harita ve bildirimler), harita kâğıdı ve çıkartmaları (sazlık, nilüfer, kayalar, ağaçlar, sandal, dükkân), harita ikonları (iğne, kilit, pusula, şamandıra, çit tabelası) ve "Kıyıya dön" düğmesinde çapa.
- [x] Parti 4 görselleri (teknikler) kesildi; Dalga 3'te oyuna girdi.
- [x] Sis: oyun alanı berrak. Üstel sis yerine 35 m'de başlayan derinlik sisi, bloom yok, doygunluk ayarı kalktı (Ersin: "telefonda sisli").
- [x] İri balık takım ister (Ersin: "iskelede takım almadan bütün balıkları tutabiliyorum"):
  - İri türlerin boyu çekişini artırır.
  - Kamış ve misinanın taşıması var: bambu 3★, cam elyafı ve naylon 4★, karbon ve örgü 5★.
  - Taşımayı aşan balıkta "Çok iri!" bildirimi çıkar; sakinken de kırmızıya çeker, koparır. Ardından Dede eksik takımı adıyla söyler.
  - Dükkân kartında "İri balık" yıldızları var.
  - Kolay modda iri balık yalnızca yavaş gelir.
  - Bkz. `docs/gdd.md` §5.
- [ ] Telefonda deneme ve hız ölçümü: Ersin'in sorun listesi.

**Dalga 3 — Teknikler → v0.4 ✅** (5 kişilik test kaldı)

- [x] Teknik soyutlaması: ısırmaya kadarki kısım tekniğin (`Technique`, şamandıra `FloatTechnique`); gölgeler tekniğin profilini okur (`TechniqueRules`). Şamandıra bit bit aynı (altın test).
- [x] Takım çantasının temeli: makara ve misina her teknikte ortak, her tekniğin kendi yuvaları; türlerin teknik yatkınlığı (şamandırada oranlar ve katalog aynı); kayıt v4 (elindeki teknik, kerevit tuzakları).
- [x] Spin (rütbe 2): basılı tut, yem gelir; bırak, batar. Yırtıcı oynayan yemin peşine düşer, dur-kalk ritmiyle saldırır (basılıysa kendiliğinden takılır, değilse VUR). Otlu yerde bekleyen yem takılır. 3 spin kamışı, 6 yapay yem. Takım Çantası (sol alttaki teknik düğmesi), dükkânın başlığında teknik düğmeleri, Dede'nin spin sözleri ve ilk atış ipuçları; `technique` bot senaryosu; denge botu spini kullanır (spin takımı 4–10. dakikada).
- [x] Dip (rütbe 4): dokunduğun yöne uzağa atar, olta balıkçının yanındaki sehpada; balık yemin çevresine toplanır (yem sepetiyle daha çabuk). Zil tek tük = kokluyor, dokunma; zil durmadan = VUR. Kamera kurşunu da gösterecek kadar uzaklaşır. 3 dip kamışı, kurşun ve yem sepeti, aynalı sazan (sazlık ve derin orta, yalnızca dip). Dede'nin dip sözleri ve ilk atış ipuçları; `technique` senaryosunda dip bölümü; dip takımı 19–33. dakikada.
- [x] Sinek (rütbe 7, yalnızca dere ağzında): sinek akıntıyla sürüklenir; alabalık altına gelir, halka çıkınca VUR (0,5 sn); halkadan önce dokunmak kaçırır; durgun suya düşen sinek döner, Dede akıntıyı söyler. Alabalık (Nadir) ve dere alabalığı (Destansı, iri) çekişirken sudan sıçrar. 3 sinek kamışı, 3 sinek. Dere ağzından çıkınca şamandıraya dönülür; Dede'nin sinek sözleri ve ilk atış ipuçları; `technique` senaryosunda sinek bölümü; sinek kamışı 64–88. dakikada.
- [x] Kerevit tuzağı (rütbe 3): Takım Çantası'nın altındaki satırdan sazlığa ya da kayalık buruna bırakılır; gerçek saatle, oyun kapalıyken de 20 dakikada bir kerevit, en çok 4; içi kurulunca belli, saat geri alınınca kayıp ya da kazanç yok. Suda turuncu şamandıra ve "2/4" rozeti; dokununca toplanır (uzaktaysa balıkçı yürür), boşsa bekle ya da kaldır. Kerevit (Sıradan; kodla 3B modeli, defterde Ersin'in resmi), 3 tuzak (Ekstra sekmesi), haritada tuzaklar, sesler, Dede'nin ve Nine'nin sözleri; `trap` bot senaryosu ve `technique` senaryosunda tuzak bölümü; denge botu tuzak kurar ve toplar (ilk tuzak 10–17. dakikada); gerçek v4 kayıt örneği.
- [x] Teknik balıkları: aynalı sazan (dip), alabalık ve dere alabalığı (sinek, az da spin), kerevit (tuzak, az da dip); şamandırayla gelmezler (şamandıranın oranları değişmedi).
- [x] Defter ve katalog: 16 tür iki sayfada; oranlar elindeki teknikle (başlıkta tekniğin adı); tutulmamış türün ipucu en sevdiği yemi, yapay yemi ya da sineği, tuzağını ("Tuzağa girer: Sazlık, Kayalık Burun") ve tekniğini söyler. Katalogda tekniklerin yatkınlık tablosu, her bölgede her teknikle oranlar ve tuzak tablosu; çekişme raporu tekniklere açıldı (`--technique=`).
- [x] Dede'nin teknik ipuçları: bölgenin önerisi (sazlıkta ve derin ortada dip, nilüferli koyda ve kayalıkta spin, dere ağzında sinek; orada başka teknikle tutana bir kez) ve Dede'ye dokununca açılmış tekniklerin öğütleri.
- [x] Denge: Dede'nin önerdiği teknik o bölgede şamandıradan az kazandırmaz (test); dip yayının tekniği ve daha çabuk (balık yeme çabuk toplanır, kamışlar güçlü), spin nilüferli koyda ve kayalıkta öne çıkar; kerevit 10 para, tuzaklar ucuzladı; bot büyük kovayı erken alır (43–54. dk); bütün takım 13,5–13,9 saatte (hedef 8–15).
- [x] Kapanış: üç inceleme ajanı (çekirdek, sunum, araçlar ve belgeler) ve düzeltmeleri; tanıtım videosu; telefon boyutunda README görüntüleri; iskelede en çok 150 çizim (`tour`); sürüm 0.4.
- [ ] **5 kişiye oynat** (aşağıdaki sorular). Devam ya da vazgeç burada verilir; Dalga 4–5 beklemez.

**Ara sürüm v0.4.1 — Ersin'in telefon geri bildirimi**

Ersin oyunu telefonda oynadı, altı şey istedi; her birinde önerilen seçeneği seçti. Her madde ayrı commit.

- [x] Deneme düğmeleri (Ayarlar'da sürüm yazısına 5 dokunuş, geliştirme sürümünde): HEPSİNİ AÇ, +1.000 ve
  +10.000 para, RÜTBE +1 (gerçek rütbe atlama akışıyla; bildirimler panel kapanınca çıkar).
- [x] Kumdaki gölge (Ersin: "kuma kadar gölgelik çıkıyor"): çekişmede balık suyun kenarında durur; gölge ve
  halkalar kıyıda söner.
- [x] Kova dolunca SAT (Ersin: "kova doluyken balık tutmaya izin vermeyelim"): dolu kovada atılmaz; eylem düğmesi
  yeşil SAT olur, basınca Nine'nin tezgâhına gidilir (sandaldaysan önce kıyıya), dükkân Kova sekmesinde açılır.
- [x] Kamış ve makara görünüşü (Ersin: "oltaları geliştirsek bile görünümü hep aynı"): her kamış dükkândaki
  resmi gibi (bambu boğumlu, karbon siyah ve altın, sinekte uzun mantar sap), makara kuşanılan makaranın renginde;
  dipteki sehpada da kuşanılan kamış. Olta 8 çizimden 4'e indi.
- [x] Yürüme halkası (Ersin: "solda yürüme mekanizması"): sol altta sabit joystick, yalnızca halkada başlayan
  dokunuşu alır; dokunarak yürüme de kaldı.
- [x] Hikâye (Ersin: "oyunun başlangıcında bir hikâyesi yok"): yeni oyunda ~50 sn'lik açılış filmi (Nine ve Dede
  gölün öyküsünü anlatır, Gölün Bekçisi'nin dev gölgesi geçer, Dede ilk oltasını verir); Ayarlar'da HİKÂYE ile
  yeniden izlenir; rütbe 3, 6, 10, 15 ve 20'de Dede hikâyeyi sürdürür.
- [x] Kapanış: inceleme ajanı (düzeltilenler: soluk yürüme halkasına basmak oyuna geçip geri sarılırken arkaya
  atış kuyruklayabiliyordu; filmde Dede'nin efsane uyarısı ve bildirimler gizli arayüzde kayboluyordu; film
  botu en geniş çekimi ölçmüyordu; denge botu satıştan sonra dolan kovada atabiliyordu; eski belge satırları),
  bütün KONTROL botları telefon oranında ve çentik payıyla (controls, first, story, shop, map, boat, technique,
  trap, fly, rods, guide, tour: iskele 141 çizim), belgeler, sürüm 0.4.1.
- [ ] Ersin telefonda dener ([`iphone-kurulum.md`](iphone-kurulum.md) 20–26).

**Dalga 4 — Canlı dünya → v0.5**

Ersin'in seçimleri (hepsi önerilen): balık kovadan ve yeni tür kartından göle bırakılır; istekler ve Dede'yle çay üstteki saat çipinin "Bugün" panelinde; final rütbe 12–14 civarında; Ay Turnası ve Kocabaş mersin gibi göle bırakılır.

- [x] Parti 5a görsel promptları ([`gorsel-istekleri.md`](gorsel-istekleri.md)): Ersin görselleri üretirken kod yazılır.
- [x] Oyun saati ve hava: 24 dakikalık gün (4 vakit), her günün tohumlu havası, vakit ve havaya göre oranlar (defter ve dükkânda da), yağmurda balık çabuk gelir, Ay Turnası (gece) ve Kocabaş (yağmurlu gece), üst ortada saat çipi, kayıt v5 (dalganın bütün alanları), geliştirme düğmeleri VAKİT +, HAVA, SEVGİ +50, `world` botu.
- [ ] Vakit ışığı, gece, yağmur, sis; Dede'yle çay; vakit müziği.
- [ ] Tut-bırak, göl sevgisi, çöp toplama.
- [ ] Dede'nin istekleri.
- [ ] Gölün Sırrı: mektuplar ve harita parçaları.
- [ ] Gölün Sırrı: final, Gölün Bekçisi, bitiş sahnesi.

**Dalga 5 — Yuva ve kişilik → v0.6**

- [ ] Kedi.
- [ ] Akvaryum.
- [ ] Karakter seçimi ve erkek balıkçı.
- [ ] Kıyafetler.
- [ ] Fotoğraf modu.
- [ ] Son geçiş: telefonda hız ölçümü, tam inceleme.

**5 kişilik test** (Kazı'nın 5 kişilik testiyle birlikte yapılabilir). Sorular:

- İlk 30 saniyede ne yapacaklarını anladılar mı?
- Gölgeleri gördüler mi? Gölgenin önüne atmayı kendiliğinden buldular mı?
- VUR anı adil mi? Erken dokunup kaçırdılar mı?
- Çekişme zevkli mi, zor mu? Kolay çekmeye ihtiyaç duydular mı?
- Dükkânda ne alacaklarını anladılar mı? Yeni teknikleri denediler mi?
- "Bir atış daha" dediler mi? Ertesi gün oyunu kendiliğinden açtılar mı?
- Kazı'ya benziyor mu, farklı mı geldi?

**Devam ya da vazgeç:** 5 kişiden en az 3'ü "bir atış daha" diyor ve ertesi gün açıyorsa devam. Değilse sorun bulunur; düzeltilir ya da ikinci fikre (Pofuduk Adası) geçilir.

## Faz 2: Dikey dilim

Tekne, Gölün Sırrı, kostümler ve akvaryum H2'ye taşındı.

- [ ] Köy ve köylüler.
- [ ] İkinci su (nehir).
- [ ] Sonar (Kazı'daki dedektör gibi).
- [ ] Kıyı süsleri ve tarifler: bulunan tarif türü garanti eder.

## Faz 3: Ücretsiz oyun katmanı

- [ ] Doğrudan satış: kostüm ve görünüş süsleri; gerçek para fiyatı her zaman görünür.
- [ ] Ödüllü reklam (isteğe bağlı): çift ödül, kopan misinayı kurtarma. Sertifikalı SDK (AdMob).
- [ ] Reklamsız / destekçi paketi; süresi dolmayan sezon kartı.
- [ ] Karma kitle kurulumu: tarafsız yaş sorusu, 13 yaş altına kişiselleştirilmemiş reklam, ebeveyn kapısı.
- [ ] Analitik (kendi analitiğimiz); Google kapalı testi (12 kişi × 14 gün) + TestFlight.

## Faz 4: Soft launch

- [ ] Birkaç ülkede yayın.
- [ ] Ölçütler: 1. gün dönüş ≥ %35, 7. gün ≥ %10, çökmesiz oturum ≥ %99,5.
- [ ] Ölç → düzelt → tekrar ölç.

## Faz 5: Online ve LiveOps

- [ ] Hesap ve bulut kayıt.
- [ ] Arkadaşın akvaryumunu gezme, hediye, köyün ortak hedefi.
- [ ] Sezonlar: yeni türler ve süsler (sezon bitince kaybolmaz, sonra geri gelir).
