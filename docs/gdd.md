# Olta: Gölün Sırrı — Oyun Tasarım Belgesi (H2: Büyük Göl)

> Prototipin (v0.1) kuralları ✅ ile, H2 "Büyük Göl" güncellemesinin tasarımı 🔜 ile işaretli (§10). Sıra ve adımlar: [`yol-haritasi.md`](yol-haritasi.md). H2'nin sayıları taslaktır; denge botuyla ayarlanır. Fikrin neden seçildiği: [`fikirler.md`](fikirler.md).

## 1. Vizyon

**"Gölü keşfet, takımını kur: bu gece oltana ne takılacak?"**

Yazı Dede ile Nine'nin göl köyünde geçiren bir çocuk ya da genç balıkçısın. Gölde balık gölgeleri dolaşıyor. Gölgenin önüne oltanı atıyorsun; gölge fark edip yaklaşıyor, şamandırayı dürtüyor ve sonunda ısırıyor: VUR! Sonra gerilim çubuğunu kırmızıya kaçırmadan çekiyorsun.

Göl büyük ve bölgelere ayrılmış: iskele koyu, sazlık, nilüferli koy, kayalık burun, dere ağzı ve sandalla açılınan derin orta. Her bölgenin kendi balıkları var; her balığın sevdiği bir teknik, yem, saat ve hava var. Nine'nin dükkânından aldığın takımla yeni tekniklere (spin, dip, sinek, tuzak) ve yeni sulara açılırsın. Tuttuğun balıkların kopyalarını Nine'ye satarsın; her türün en iyisi akvaryumda yaşar. İstersen balığı göle geri bırakırsın; bıraktıkça göl güzelleşir. Oyun kısa bir açılış filmiyle başlar: Nine ve Dede, gençken ölmek üzere olan gölü nasıl kurtardıklarını ve derinlerde yaşayan Gölün Bekçisi'ni anlatır, Dede ilk oltasını sana verir (§10.5). Dede'nin anlattıkları ve şişelerden çıkan mektuplar seni gölün sırrına, Gölün Bekçisi'ne götürür.

- **Platform:** iOS + Android, yatay ekran, low-poly 3D.
- **Model:** ücretsiz oyun; gelir kuralları [`CLAUDE.md`](../CLAUDE.md)'de.
- **Kitle:** aile dostu, her yaş. Hedef Apple 4+/9+, PEGI 7. Çocuk kategorisine girilmez.
- **Dil:** baştan Türkçe + İngilizce.

## 2. Tasarım sütunları

1. **Her gölge bir soru.** Gölgenin boyu balığın boyunu ele verir, türünü vermez. Nadir gölgeler arada pırıldar, ama yine türünü söylemez. "Bu kocaman gölge ne?" merakı oyunun motorudur.
2. **Tek parmak, her yaş.** Dokun-yürü, dokun-at, değdiği an VUR, basılı tut-çek. Yeni teknikler de tek parmakla oynanır: bas-bırak, dokun. Okumadan oynanır.
3. **Keşfet, kur, sergile.** Bölge, teknik, yem, saat ve hava hangi balığın geleceğini belirler; takımını sen kurarsın. Balık Defteri her türün nerede ve ne zaman çıktığını, oranlarıyla birlikte gösterir. En iyileri akvaryumda yaşar 🔜 (Dalga 5).
4. **Sakin ve adil.** Oyuncu yokken ceza yok; parayla şans satılmaz; kötü şansa karşı garanti var.
5. **Kısa oturum.** Bir atış 15–40 saniye; bir oturum 5–10 dakika.

## 3. Döngüler

| Döngü | Süre | İçerik | Durum |
|---|---|---|---|
| Çekirdek | 15–40 sn | Dokun → at → gölge yaklaşır, dürter → ısırır → VUR → çek → balık elde, kart | ✅ |
| Oturum | 5–10 dk | Kova dolar → Nine'ye sat (her türün en iyisi akvaryuma) → takım al → yeni teknik ya da bölge → Dede'nin isteğini bitir | ✅ (akvaryum 🔜) |
| Haftalar | günler | Balık Defteri (siluetler, ipuçları, oranlar), rütbe, gece ve hava balıkları, göl sevgisi, "Gölün Sırrı" hikâyesi ve Gölün Bekçisi; sonra yeni sular, sezonluk türler | ✅ (yeni sular ve sezonlar 🔜) |

## 4. Kontroller ✅

**Telefon (yatay):**

- **Karaya ya da iskeleye dokun:** balıkçı oraya yürür. Önü su ise kıyı yolundan dolaşır (kısa yandan); kilitli bölgenin çitinde durur, Dede ne zaman geçileceğini söyler. Yürünebilen dünyanın dışına (orman) dokunulursa en yakın yere gider.
- **Suya dokun:** balıkçı oraya atar. Menzil dışındaysa önce yaklaşır. Hedef karaya denk geliyorsa şamandıra yine suya düşer.
- **Olta suyadayken ekranın her yeri bir düğmedir:**
  - **değdiği an:** ısırmada VUR; ısırmadan önce oltayı geri sarar;
  - **çekişmede basılı tutunca:** sarar.
  Sağ altta büyük bir eylem düğmesi de aynı işi yapar ve ne olacağını yazar: GERİ SAR / VUR! / SAR.
- ✅ **Yürüme halkası** (v0.4.1, Ersin: "solda yürüme mekanizması daha mantıklı olmaz mı"): sol alt köşede sabit bir joystick. Halkaya basıp sürükle: o yöne yürürsün, az itersen yavaş; bırakınca durursun. Yalnızca halkanın içinde başlayan dokunuşu alır: halkanın dışında dokunarak yürüme, atış ve köylüye dokunma aynen sürer (Kazı'daki joystick parmağın altında beliriyordu ve soldaki dokunuşları yutuyordu; bu yüzden ilk sürümde joystick yoktu). Olta sudayken ve sandalda gizli (sandalda yerinde "Kıyıya dön"); kart açılırken, yakalamada ve geri sararken soluk (soluk halkaya basmak yürütmez, oyuna da geçmez; halka açılınca aynı parmakla yürünür). Bir parmak halkadayken öbürüyle suya dokununca atılır.

- ✅ **Harita** (sağ üst, ilk balıktan sonra): açık bir bölgenin rozetine dokun → ekran kararır, o bölgenin atış noktasındasın. Kilitli bölgede nedeni yazar.
- ✅ **Sandal:** sandalı aldıysan iskeledeki sandala (ya da haritada Derin Orta'ya) dokun → ilk şamandıranın yanında sandaldasın; haritada Derin Orta'ya yeniden dokununca sıradaki şamandıraya geçilir. Sandalda suya dokunmak atıştır; sol alttaki "Kıyıya dön" iskeleye getirir.

- ✅ **Teknik düğmesi** (sol alt; spin rütbe 2'de açılınca görünür, sandalda "Kıyıya dön"ün üstünde, olta sudayken gizli): elindeki tekniğin ikonu; dokununca Takım Çantası açılır (§10.3).
- ✅ **Spin:** atınca yapay yem düşer. Basılı tut = yem sana gelir (makara tıkırdar, arkasında iz), bırak = durur ve batar. Yırtıcı peşine düşünce dur-kalk yap. Saldırı anında basılıysa balık kendiliğinden takılır, değilse VUR! (0,6 sn; Kolay modda 1 sn). Eylem düğmesi beklerken SAR yazar.
- ✅ **Dip:** dokunduğun yöne uzağa at, olta sehpaya konur. Zil tek tük çalarsa balık kokluyor: dokunma (kaçar; düğme BEKLE). Zil durmadan çalıp misina akınca ekranın her yerine dokun: VUR! (2,5 sn; Kolay modda 3,5 sn). Beklerken dokunmak oltayı geri sarar (düğme GERİ SAR).
- ✅ **Sinek** (yalnızca dere ağzında): akıntıya at, sinek akıntıyla sürüklenir (düğme GERİ SAR). Alabalık sineğin altına gelince bekle (dokunursan kaçar; düğme BEKLE). Halka çıkınca hemen dokun: VUR! (0,5 sn; Kolay modda 0,9 sn). Durgun suya düşen sinek kımıldamaz, kendiliğinden döner.
- ✅ **Kerevit tuzağı** (sazlıkta ve kayalık burunda): Takım Çantası'nın altındaki satırda TUZAK BIRAK → tuzak yakındaki sığ suya atılır. Turuncu şamandırasına dokun → içindekiler toplanır (uzaktaysan balıkçı önce yürür); boşsa küçük bir panel: BEKLE ya da KALDIR.

**Mac:** tıkla (yürü, at), WASD (yürü), Space (VUR; basılı tutunca sar).

**H2'de gelenler** (ayrıntı §10.3):

- **Dünyada dokunulanlar** ✅: Nine → dükkân; Dede → öğüt (istekler üstteki saat çipinin "Bugün" panelinde); sandal, kerevit tuzağı, suda şişe; sol üstte kova → Kova paneli. Kedi → sev 🔜 (Dalga 5).

## 5. Kurallar ve başlangıç sayıları ✅

Bütün sayılar `data/*.json`'da ve testlerde. Telefonda denendikçe ayarlanır.

**Atış**

- İlk olta: bambu olta, menzil 9 m.
- Şamandıra uçuş süresi 0,45 sn + mesafe × 0,05 sn; yay yüksekliği mesafenin dörtte biri.

**Gölgeler**

- Gölde aynı anda 4 gölge var.
- Hız 0,3–0,5 m/sn; aralarda 1–3 sn duraklar. Yalnızca derin yerlerde dolaşırlar: bölgenin en sığ sınırı 0,5 m (sazlık, dere ağzı) ya da 0,8 m (öteki bölgeler).
- Büyük gölde gölgeler balıkçının çevresinde ve yalnızca avlandığı bölgede doğar (durduğu yerin bölgesi; kilitliyse yakındaki açık bölge). Defterin ve dükkânın gösterdiği oran, gelen balığın gerçek oranıdır. Başka bölgeye yürüyünce eski bölgenin gölgeleri çekilir, yenileri doğar.
- Gölgenin balığı ve boyu doğduğu anda belli (Kazı'daki çamurlu eşya gibi): gizli ama değişmez.
- Gölge uzunluğu türün taban gölgesi × (0,85 + 0,30 × boy yüzdeliği).
- Şamandıra 6 sn'den uzun süredir suda bekliyorsa gölgeler yarı yarıya onun çevresine yönelir (bekleme uzamasın).

**Korkutma ve fark etme**

- **Korkutma:** şamandıra bir gölgenin merkezine "gölge boyunun yarısı + 0,3 m"den yakın düşerse o gölge kaçar.
- **Fark etme:** şamandıra gölgenin önündeki ±70°'lik konide 3 m'den, başka yönde 1,8 m'den yakınsa fark eder. Bu, şamandıra suda olduğu sürece sürekli denetlenir.
- Aynı anda yalnızca bir balık yaklaşır.

**Dürtme ve ısırma**

- Yaklaşan balık 0/1/2/3 kez dürter (olasılıklar %15/30/35/20). Dürtmeler arası 0,8–1,4 sn.
- Sonra ısırır: şamandıra suya dalar, ses ve titreşim gelir.
- **Vuruş penceresi:** 1,0 sn (Kolay modda 1,6 sn).
- **Erken dokunuş:** balık kaçar ("Erken davrandın!"). Kolay modda ilk erken dokunuşta yalnızca irkilir.
- **Pencere kaçarsa:** balık gider ("Kaçtı!"). Eksilen gölgenin yerine 8 sn içinde yenisi gelir.

**Çekişme**

- **Gerilim (0–1):**
  - Basılı tutunca gerilim, balığın çekişine göre bir hedefe doğru yükselir.
  - **Balık sakinken basılı tutmak hiç kırmızıya çıkmaz.**
  - Bırakınca gerilim düşer, balık biraz uzaklaşır.
- **Patlama:**
  - Balık zaman zaman çırpınır. İlk patlama çekişmenin 1,6–2,4. saniyesinde gelir (oyuncu hemen öğrensin; sudakta 1,2–1,6, alabalıklarda 0,8–1,1: `fight.first_burst`).
  - Her patlamadan **0,5 sn önce** uyarı gelir: balık çırpınır, misina titrer, gıcırtı duyulur, telefon titrer, "!" çıkar.
  - Patlamada basılı tutarsan gerilim kırmızıya çıkar.
- **Kopma:** gerilim sınırın üstünde toplam 0,8 sn kalırsa misina kopar ("Misina koptu!"). Sayaç sınırın altında yavaşça geri iner.
- **Kaçma:** balık menzil + 2 m'den uzağa kaçarsa gider. Kıyıya doğru kaçarsa kıyıda gider (karaya çıkmaz); ama kaçış payı hep şamandıranın en az 2 m ötesidir, kıyıya yakın atışta da bırakan oyuncu hemen kaybetmez (balık kıyıda çırpınır).
- **Yakalama:** balık 0,6 m'ye gelince tutulur.
- **Kolay çekme (Ayarlar):** gerilim tavanlıdır, misina kopmak yerine kayar, balık kaçmaz; beceri yalnızca hızı belirler.
- **Süre:** iyi bir oyuncuyla çekişme Kızılkanat'ta 4–7 sn, Yayın'da 14–20 sn sürer.
- **Kolay modda** patlamada basılı tutunca misina kayar: balık, kaçış hızının 2 katıyla uzaklaşır. Hep basılı tutan yine tutar; bırakmayı bilen daha hızlı tutar.
- **İri balık takım ister** (v0.3.1; Ersin: "iskelede takım almadan bütün balıkları tutabiliyorum"):
  - **İri türler:** sazan, turna, yayın, kadife, sudak, altın sazan, mersin, aynalı sazan, dere alabalığı (`fish.json` `fight.heavy`). Ötekiler (kızılkanat, gümüş balığı, levrek, çapak, tatlısu kefali, alabalık, kerevit) her boyda bambu oltayla tutulur.
  - **Boy çekişi artırır:** iri türde sakin çekiş en irisinde 0,08 artar (`size_pull`). Yine sınırın altında kalır.
  - **Taşıma:** kamışın ve misinanın bir taşıması var (yıldız). Kuşanılan takımın taşıması ikisinin küçüğüdür.
    - Bambu kamış ve ince misina 3★ taşır.
    - Cam elyafı kamış (300 para, rütbe 2) ve naylon ya da florokarbon misina 4★ taşır.
    - Karbon kamış (2.000, rütbe 5) ve örgü (1.800, rütbe 6), usta florokarbon ya da altın örgü misina 5★ taşır.
  - **Fazla iri:** iri türün yıldızı taşımayı aşarsa:
    - takılınca "Çok iri!" bildirimi çıkar, telefon titrer;
    - sakinken de basılı tutmak kırmızıya çıkar (sakin çekiş sınırın 0,12 üstü, fazla yıldız başına);
    - patlama sertleşir (+0,1);
    - bırakınca balık 4 kat hızlı uzaklaşır (fazla yıldız başına +3 kat).
    - Sonuç: basılı tutan ~1,2 sn'de koparır, bırakan balığı kaçırır. Kusursuz pompalayan bot bile tutamıyor.
  - **Dede'nin öğüdü:** fazla iri balık kopunca ya da kaçınca Dede eksik takımı adıyla söyler (`Economy.gear_for_stars`: önce sendeki, sonra rütbesi yeten en ucuz, sonra en erken açılan):
    - "Nine'den cam elyafı kamış ve naylon misina al.";
    - sende varsa "Dükkânda tak: …";
    - biri sende, biri Nine'deyse "Nine'den cam elyafı kamış al; naylon misina sende, tak.";
    - rütbe yetmiyorsa "Onu taşıyan takımı Nine rütbe 6 olunca satar."
    - Öğüt 6 sn kalır; hemen yeniden atınca silinmez. Takım adları dil değişince de doğru dilde.
  - **İlk 3 balıkta** (Dede'nin ipuçları) fazla iri balığın çekişmesinde "Basılı tut, sar" yerine "Çok iri! Bu takım onu taşımaz." yazar.
  - **Dükkân:** kamış ve misina kartında "İri balık" satırı, 5 yıldızdan taşıdığı kadarı dolu.
  - **Kolay modda** kopma ve kaçma yine yok; fazla iri balık yalnızca yavaş gelir (sarma ×0,9; çekişi ve bırakınca uzaklaşması artmaz). Kolay çekme çekişme sürerken ayarlardan açılırsa balık o andan Kolay kurallarıyla gelir.
  - **Senaryolu ilk balık** hiç fazla iri sayılmaz.
  - **Kaç balık:** boyların %20'si 4★ ve üstü, %6'sı 5★. İskele koyunda ısırmaların ~%6'sı bambu oltayla fazla iri (sazan, turna, yayın). Cam elyafı kamış ve naylon misinadan sonra ~%2'si (yalnızca 5★).
- **Denge raporu** (`tools/reel_report.gd`; 4–9 m'den 200 deneme, ortalama süre; boy 1–3★ aralığında, takımın taşıdığı balık):

| Balık | Çekiş | İyi oyuncu (0,4 sn tepki) | Yavaş oyuncu (0,7 sn) | Hep basılı (Normal) |
|---|---|---|---|---|
| Kızılkanat | sakin | 5,8 sn | 6,0 sn | tutar |
| Sazan | ağır | 10,7 sn | 11,4 sn | koparır |
| Levrek | ani | 9,5 sn | 10,5 sn | %55 tutar |
| Turna | ani, güçlü | 13,7 sn | 15,2 sn | koparır |
| Yayın | düzensiz, güçlü | 16,1 sn | 17,7 sn | koparır |
| Gümüş balığı | hafif, çevik | 4,6 sn | 4,8 sn | tutar |
| Çapak | ağır ama tembel | 7,1 sn | 7,4 sn | %72 tutar |
| Tatlısu kefali | sert kaçışlı | 7,4 sn | 7,7 sn | %94 tutar |
| Kadife | inatçı, ağır | 10,4 sn | 11,4 sn | koparır |
| Sudak | başını sallar (sık patlama, erken çırpınır) | 15,3 sn | 17,6 sn | koparır |
| Altın sazan | ağır, güçlü | 14,0 sn | 15,3 sn | koparır |
| Mersin | çok güçlü, uzun koşular | 17,4 sn | 18,7 sn | koparır |
| Aynalı sazan | ağır, güçlü | 13,4 sn | 14,6 sn | koparır |
| Alabalık | çevik, sıçrar; takılır takılmaz çırpınır | 11,3 sn | 12,4 sn | koparır |
| Dere alabalığı | güçlü, sıçrar; takılır takılmaz çırpınır | 15,2 sn | 16,7 sn | koparır |

  İyi ve yavaş oyuncu her balığı tutar. Kolay modda hep basılı tutan da tutar.
- **Sinek takımıyla** (balık 3–5,5 m'de takılır; `test_reel_model` sinek korkuluğu): iyi oyuncu alabalığı ilk sinek kamışıyla ~6 sn'de, dere alabalığını ~8 sn'de tutar. Balık yakında takıldığı için hep basılı tutmak kolay olurdu; bu yüzden alabalıklar takılır takılmaz çırpınır (`fight.first_burst` 0,8–1,1 sn; sudakta 1,2–1,6, öteki balıklarda 1,6–2,4). Hep basılı tutan en iyi sinek takımıyla alabalığı en çok ~%19 tutar, dere alabalığını tutamaz (ilk ayarda %62 ve %52'ydi).
- **Tekniklere göre** (v0.4; `tools/reel_report.gd -- --technique=spin|bottom|fly`): öteki tekniklerde balık oyunda ölçülen uzaklıkta takılır (`sim.json` `start_m`; `session_timing.gd` ölçer): spinde 3,3–8 m, dipte 9,6–14 m (balık menzilin ötesinde takılmaz: ilk dip kamışı 14 m; sazlıkta ve derin ortada daha yakın), sinekte 3,2–5,6 m. Şamandıra sütunu yukarıdaki tablonun (raporun Dalga 1'den beri sabit 4–9 m'si; oyunda ölçülen 2,7–7,5 m). Tekniğin ilk kamışı, başlangıç makarası ve misinası; iyi oyuncu (0,4 sn tepki), 1–3★, ortalama süre:

| Balık | Şamandıra | Spin | Dip | Sinek |
|---|---|---|---|---|
| Kızılkanat | 5,8 sn | — | 8,6 sn | 3,4 sn |
| Gümüş balığı | 4,6 sn | — | — | — |
| Çapak | 7,1 sn | — | 10,5 sn | — |
| Tatlısu kefali | 7,4 sn | 6,1 sn | 10,7 sn | 4,0 sn |
| Kerevit | — | — | 7,2 sn | — |
| Sazan | 10,7 sn | — | 15,0 sn | — |
| Levrek | 9,5 sn | 7,8 sn | 13,6 sn | — |
| Kadife | 10,4 sn | — | 14,8 sn | — |
| Turna | 13,7 sn | 11,4 sn | 18,3 sn | — |
| Sudak | 15,3 sn | 12,8 sn | 19,2 sn | — |
| Aynalı sazan | — | — | 18,2 sn | — |
| Alabalık | — | 9,8 sn | — | 6,5 sn |
| Yayın | 16,1 sn | 13,4 sn | 21,0 sn | — |
| Altın sazan | 14,0 sn | — | 18,8 sn | — |
| Dere alabalığı | — | 13,1 sn | — | 8,9 sn |
| Mersin | 17,4 sn | — | 22,3 sn | — |

  - İyi ve yavaş oyuncu takımın taşıdığı her balığı her teknikte tutar. En iyi takımla iyi oyuncunun süreleri %25–44 kısalır (dipte en az, spinde en çok; spinde turna 6,4, yayın 8,0 sn; dipte sazan 10,9, yayın 14,8, mersin 15,7 sn; sinekte alabalık 4,4, dere alabalığı 5,8 sn).
  - Hep basılı tutan ilk kamışla iri türleri tutamaz; spinde levrek %66, tatlısu kefali %94; dipte uzak takılma yüzünden levrek %32, çapak %55, tatlısu kefali %86.
  - **Değerlendirme:** spin ve sinek şamandıra sütunundan biraz kısa; bunun bir kısmı uzaklık farkından (şamandıra sütunu 4–9 m'den, oyunda şamandırada balık 2,7–7,5 m'de takılır). Dipte balık uzakta takılır, çekişme şamandıradakinin ~1,3–1,5 katı: yayın 21 sn, mersin 22 sn (kapanışta takılma uzaklığı menzilde kesildi: 9,6–15,7 m → 9,6–14 m). 8. adımda dip kamışlarının gücü arttı (0,15 / 0,2 / 0,25 → 0,25 / 0,3 / 0,3; ilk ölçümde yayın 26, mersin 28 sn); derin ortada ve sazlıkta su yakın, balık daha yakında takılır (ortalama çekişme 10,6 ve 9,1 sn; §10.4).
- **Takımla** (H2, `GearStats`): başlangıç takımı yukarıdaki bambu oltayla aynıdır. En iyi şamandıra takımıyla (`tools/reel_report.gd -- --gear=top`):

| Balık | İyi oyuncu (0,4 sn): başlangıç → en iyi takım | Hep basılı, en iyi takım (Normal) |
|---|---|---|
| Kızılkanat | 5,8 → 3,9 sn | tutar |
| Sazan | 10,7 → 6,9 sn | %32 tutar |
| Levrek | 9,5 → 5,7 sn | tutar |
| Turna | 13,7 → 8,0 sn | %36 tutar |
| Yayın | 16,1 → 9,7 sn | koparır |
| Gümüş balığı | 4,6 → 3,2 sn | tutar |
| Çapak | 7,1 → 4,9 sn | tutar |
| Tatlısu kefali | 7,4 → 4,8 sn | tutar |
| Kadife | 10,4 → 6,7 sn | %14 tutar |
| Sudak | 15,3 → 8,8 sn | %24 tutar |
| Altın sazan | 14,0 → 8,5 sn | %2 tutar |
| Mersin | 17,4 → 10,4 sn | koparır |
| Aynalı sazan | 13,4 → 8,3 sn | %6 tutar |
| Alabalık | 11,3 → 7,2 sn | %12 tutar |
| Dere alabalığı | 15,2 → 9,5 sn | koparır |

  Korkuluklar (`test_reel_model`; her teknik kendi uzaklığında): en iyi takımla yavaş oyuncu her balığı tutar; hep basılı tutan Nadir balığı en çok yarı yarıya, Destansı ve üstünü en çok %30 tutar; kusursuz oyuncunun çekişmesi en çok %40 kısalır. Misinanın kopma süresi bu yüzden en çok 0,95 sn. Spinde balık yakında takılır: en iyi spin takımıyla hep basılı tutan sudağı %60 tutuyordu (kapanış incelemesi); sudak takılınca erken çırpınır (`first_burst` 1,2–1,6 sn): spinde %33, şamandırada %24 (önce %37).
- **İri balık raporu** (`tools/reel_report.gd`, `-- --gear=mid` cam elyafı kamış + naylon misina, `-- --gear=top`; iyi oyuncu 0,4 sn tepki; pompa: gerilimi sınırın hemen altında tutan kusursuz bot):

| İri tür | Bambu olta, 4–5★ (fazla iri): iyi oyuncu / pompa | Cam elyafı + naylon: 4★ / 5★ | En iyi takım, 5★ | Kolay, hep basılı: 3★ → 5★ (bambu) |
|---|---|---|---|---|
| Sazan | %0 / %0 | 9,8 sn / %0 | 6,9 sn | 9,8 → 11,7 sn |
| Turna | %0 / %0 | 12,3 sn / %0 | 8,0 sn | 12,3 → 15,6 sn |
| Yayın | %0 / %0 | 14,6 sn / %0 | 9,7 sn | 16,1 → 20,7 sn |
| Kadife | %0 / %0 | 9,6 sn / %0 | 6,7 sn | 9,5 → 11,4 sn |
| Sudak | %0 / %0 | 13,7 sn / %0 | 8,8 sn | 13,0 → 16,8 sn |
| Altın sazan | %0 / %0 | 12,7 sn / %0 | 8,5 sn | 13,3 → 16,7 sn |
| Mersin | %0 / %0 | 15,7 sn / %0 | 10,4 sn | 19,7 → 27,1 sn |
| Aynalı sazan | %0 / %0 | 12,2 sn / %0 | 8,3 sn | 12,7 → 16,0 sn |
| Dere alabalığı | %0 / %0 | 13,9 sn / %0 | 9,5 sn | 14,9 → 18,8 sn |

  Takımın taşıdığı balığı iyi oyuncu %100 tutar (süreler bu oranla). Kusursuz pompalayan fazla iri balığı bazen 2 dakika yerinde tutar ama getiremez (raporda "bitmedi"; cam elyafı + naylonla 5★ kadife %99, sazan %48); bırakınca kaçar. Kolay modda yavaş oyuncu (0,7 sn) için de fark en çok ~1,4 kat (sudak 21,7 → 30,5 sn). Korkuluklar (`test_reel_model`):
  - bambu olta 3★ iri balığı rahat tutar;
  - fazla iriyi iyi oyuncu en çok %5, kusursuz pompalayan en çok %25 tutar (ölçüm: %0);
  - o yıldızı taşıyan takımla iyi oyuncu en az %90 tutar;
  - Kolay modda fazla iri balık hep tutulur (hep basılı tutan da 0,7 sn tepkili oyuncu da), en çok 75 sn ve 3★'ın en çok 1,75 katı sürer; Kolay çekişme sırasında açılsa da.
- **Gölün Bekçisi** (Dalga 4, final; `fight.stages`, §10.5): iri tür değil (takımın taşıması aranmaz), iki dalışı var.
  - Balık takıldığı uzaklığın %60'ına ve %30'una gelince, sakinse, 1,2 sn uyarır: turkuaz halka, gıcırtı, titreşim,
    ipucu "BIRAK! Bekçi dalıyor!".
  - Sonra 2–2,6 sn dalar: bırakınca 1,8 m/sn uzaklaşır (en çok kaçış sınırının 0,5 m içine, kaçmaz); basılı tutunca
    gerilim sınırın üstüne çıkar, misina kopar. Kolay modda dalış 0,6 kat hızlı, kopma yok.
  - Dalışın zarı yalnızca dalışlı balıkta çekilir: öteki balıkların çekişmesi ve altın test aynı kalır.
  - Dipte 12–14 m'de takılır (`tools/reel_report.gd -- --fish=keeper`, `--gear=mid`, `--gear=top`; her çekişmede iki dalış):

| Dip takımı | Kusursuz | İyi oyuncu (0,4 sn) | Yavaş (0,7 sn) | Hep basılı | Kolay: iyi oyuncu / hep basılı |
|---|---|---|---|---|---|
| İlk dip kamışı | 35,2 sn | 47,2 sn | 50,6 sn | koparır | 40,4 / 32,5 sn |
| İkinci dip kamışı + naylon | 36,4 sn | 48,9 sn | 52,0 sn | koparır | 42,2 / 33,9 sn |
| En iyi dip takımı | 30,5 sn | 40,3 sn | 42,5 sn | koparır | 35,4 / 28,1 sn |

  Hedef Normal'de ~35–55 sn, Kolay'da ~25–45 sn'ydi; ilk ayarla tuttu. Korkuluklar (`test_reel_model`): her dalıştan
  önce uyarı gelir, dalış kaçış sınırını aşmaz; kusursuz usta ve tepkili oyuncu Normal'de ve Kolay'da tutar; dalışta
  basılı tutan Normal'de koparır.

**Sonuç**

- Tutulan balık balıkçının önünde kıvrılarak gösterilir, kamera yakınlaşır; üstünde adı ve boyu yükselir. Nadir ve üstünde ışık sütunu çıkar. Yeni tür, rekor ya da nadirde balıkçı sevinir.
- **Tam kart** yalnızca yeni tür, yeni rekor ya da Nadir ve üstü için açılır; tekrarlarda kısa bildirim.
- **Yıldız** boy yüzdeliğinden gelir:

| Yüzdelik | <0,2 | <0,45 | <0,7 | <0,9 | gerisi |
|---|---|---|---|---|---|
| Yıldız | ★ | ★★ | ★★★ | ★★★★ | ★★★★★ |

- Boylar çoğunlukla küçük, büyükler seyrek: yüzdelik = u^1,6. Beş yıldız ~%6.

**İlk açılış**

- Oyun doğrudan iskelede başlar; Dede iskelenin kenarında oturur ve ipucu çubuğundan konuşur.
- İlk gölge iskelenin önüne gelir ve ilk av senaryoludur: hep Kızılkanat, dürtmesiz. İlk balık 45 sn içinde gelir.
  - İlk av göldeyken şamandıraya yalnızca o gelir. Nereye atılırsa atılsın fark eder ve korkmaz.
  - Erken dokunuş onu kaçırmaz, yalnızca irkiltir. Pencere kaçarsa biraz sonra yeniden ısırır. Çekişmesi Kolay kurallarıyla.
  - İlk atışa kadar ilk av gölgesinin çevresinde arada bir halka çıkar ("bu gölge!").
- Dede'nin ipuçları ilk 3 balığa kadar ipucu çubuğunda görünür; oyunun durumuna göre değişir.
- Dede'ye dokununca (olta suda değilken) sıradaki öğüdünü söyler; 3 balıktan sonra da. Öğütlerden biri gölün sırrına göz kırpar ("Bu gölün bir sırrı var... Bir gün anlatırım.").

**Kayıt**

- Her yakalayışta ve uygulama arka plana geçince kayıt alınır.
- Uygulama odağı kaybedince (arama, Denetim Merkezi) ya da Ayarlar açıkken çekişme donar.
- Her oturum yeni gölgelerle başlar (seed + oturum sayacı).

## 6. Balıklar ✅

İlk beşi prototipten, yedisi Dalga 2'de (bölge balıkları), aynalı sazan, alabalıklar ve kerevit Dalga 3'te (teknik balıkları), Ay Turnası ve Kocabaş Dalga 4'te (vakit ve hava), Gölün Bekçisi Dalga 4'ün finalinde (hikâyenin balığı). Kimlikler değişmez; görünüş kodla
(`scenes/world/fish_mesh.gd`), oranlar bölgeden (§10.1; tam tablo [`balik-katalogu.md`](balik-katalogu.md)).

| Kimlik | TR | EN | Taban gölge | Nadirlik | Boy | Değer | Çekiş | Bölgeler | Görünüş |
|---|---|---|---|---|---|---|---|---|---|
| `rudd` | Kızılkanat | Rudd | 0,5 m | Sıradan | 15–30 cm | 5 | sakin | iskele koyu, sazlık, nilüferli koy, kayalık burun, dere ağzı | gümüş gövde, kırmızı yüzgeçler |
| `silverside` | Gümüş Balığı | Silverside | 0,4 m | Sıradan | 8–18 cm | 4 | hafif, çevik | iskele koyu, sazlık | ince uzun, parlak gümüş yan şerit, iri göz, iki sırt yüzgeci |
| `bream` | Çapak | Bream | 0,7 m | Sıradan | 25–60 cm | 6 | ağır ama tembel | iskele koyu, derin orta | yassı ve derin gövde, bronz, uzun anal yüzgeç |
| `chub` | Tatlısu Kefali | Chub | 0,65 m | Sıradan | 20–50 cm | 7 | sert kaçışlı | kayalık burun, dere ağzı | iri başlı, gri-gümüş, turuncu alt yüzgeçler |
| `carp` | Sazan | Carp | 0,75 m | Güzel (H2'de Sıradan'dan çıktı) | 30–80 cm | 12 | ağır | iskele koyu, sazlık, nilüferli koy, derin orta | bronz-altın, koyu sırt, iri pullar |
| `perch` | Levrek | Perch | 0,75 m | Güzel | 20–45 cm | 12 | ani | her bölge | yeşil-sarı, koyu dikey çizgiler, turuncu yüzgeçler |
| `tench` | Kadife | Tench | 0,7 m | Güzel | 25–55 cm | 14 | inatçı, ağır | sazlık | zeytin yeşili, kırmızı göz, kalın kuyruk sapı, düz kuyruk |
| `pike` | Turna | Pike | 1,05 m | Nadir | 50–120 cm | 35 | ani, güçlü | her bölge | uzun, zeytin yeşili, açık benekler |
| `zander` | Sudak | Zander | 0,95 m | Nadir | 40–90 cm | 40 | başını sallar (sık patlama, erken çırpınır) | kayalık burun, derin orta | uzun, gri-yeşil, soluk çizgiler, cam gibi parlak göz, iki sırt yüzgeci |
| `wels` | Yayın | Wels Catfish | 1,5 m | Destansı | 100–250 cm | 120 | düzensiz, güçlü | iskele koyu (az), kayalık burun, dere ağzı, derin orta | koyu gri-kahve, bıyıklı, yassı baş |
| `golden_carp` | Altın Sazan | Golden Carp | 0,9 m | Destansı | 40–85 cm | 110 | ağır, güçlü | nilüferli koy | koi gibi altın-turuncu, beyaz lekeli, bıyıklı |
| `sturgeon` | Mersin Balığı | Sturgeon | 1,75 m | Efsanevi | 100–220 cm | satılmaz | çok güçlü, uzun koşular | derin orta (sandalla) | sivri burun, sırtta ve yanlarda kemik plakalar, burnun altında dört bıyık, üst lobu uzun kuyruk |
| `mirror_carp` | Aynalı Sazan | Mirror Carp | 0,85 m | Nadir | 40–95 cm | 34 | ağır, güçlü | sazlık, derin orta (yalnızca dip) | kalın gövde, yan çizgide ve sırtta birkaç iri, ayna gibi parlak pul, bıyıklı |
| `trout` | Alabalık | Trout | 0,65 m | Nadir | 25–60 cm | 30 | çevik, sıçrar | dere ağzı (sinek; az da spin) | ince uzun, zeytin sırt, pembe yan şerit, koyu benekler |
| `brook_trout` | Dere Alabalığı | Brook Trout | 0,8 m | Destansı | 35–80 cm | 70 | güçlü, sıçrar (iri tür) | dere ağzı (sinek; az da spin) | kahverengi, kırmızı benekli, turuncu alt yüzgeçler |
| `crayfish` | Kerevit | Crayfish | 0,3 m | Sıradan | 6–14 cm | 10 | hafif | sazlık, kayalık burun (tuzak; az da dip) | kızıl kahve kabuk, halkalı kuyruk, iki iri kıskaç, duyargalar, saplı gözler |
| `moon_pike` | Ay Turnası | Moon Pike | 1,25 m | Efsanevi | 90–140 cm | satılmaz | ani, güçlü, sıçrar (iri tür) | nilüferli koy, yalnızca gece (şamandıra ×1, spin ×1,4, dip ×0,2) | gümüş-mavi turna, soluk ay benekleri, sarı göz |
| `kocabas` | Kocabaş | Old Bighead | 2,1 m | Efsanevi | 240–320 cm | satılmaz | çok ağır, uzun koşular (iri tür) | derin orta, yalnızca yağmurlu gece (dip ×1,5, şamandıra ×0,5) | dev yayın: yosunlu sırt, uzun bıyıklar |
| `keeper` | Gölün Bekçisi | Keeper of the Lake | 4,4 m | Masalsı | 480–520 cm (hep ~517 cm, 5★) | satılmaz | iki dalış: BIRAK! (§5) | derin ortada haritanın X'i (ilk şamandıra), sisli gece, dip ve altın hamurla; bölgelerin tablosunda yok, oyun çağırır (§10.5) | uzun turkuaz gövde, açık plakalar ve benekler, bıyık, dört sırt yüzgeci |

**Nadirlikler:** Sıradan (gri), Güzel (yeşil), Nadir (mavi), Destansı (mor), Efsanevi (altın), Masalsı (turkuaz; H2'de eklendi, yalnızca Gölün Bekçisi). Efsaneviler mersin, Ay Turnası (gece) ve Kocabaş (yağmurlu gece); tek Masalsı balık Gölün Bekçisi (Dalga 4'ün finali, §10.5). Nadirlikler yalnızca sona eklenir; her kademenin bir simgesi, rütbe puanı ve göl sevgisi değeri var (§10.2, `data/rarities.json`).

**Değerler (para, orta boy):** yukarıdaki tabloda; boy çarpanı 0,6–1,6.

**Mersin koruma altında** (`release_only`): tutulur, kovaya girmez, satılmaz; kartta Dede "Mersin koruma altında evlat. Bir güzel bakalım, sonra bırakalım." der, düğme "Göle bırak" olur, bildirim "Mersin Balığı göle döndü". Rütbe puanı ve göl sevgisi verir; defterde "Koruma altında" yazar. Ay Turnası ve Kocabaş da böyle (Dalga 4; Ersin: "göle bırakılır"): Dede'nin kendi sözüyle ("Ay Turnası! Nine buna inanmayacak...", "Kocabaş'ın ta kendisi! Benden yaşlıdır..."); "belli vakitte gelen" (`only`) her tür göle bırakılır (`ContentDB` denetler).

**Doğma ağırlıkları** bölgenin (`data/spots.json`). İskele koyu: kızılkanat 26, gümüş balığı 14, çapak 10, sazan 20, levrek 18, turna 8, yayın 4 (Ersin'in seçimi: turna ve yayın kalsın ama az çıksın). Bölgelerin yıldız balıkları (sudak, altın sazan, mersin) başlangıç koylarında çıkmaz. Testlerin gölünde 35/25/17/15/8.

**Sevdiği yem:** kurtçuk levrek ve gümüş balığı, ekmek hamuru sazan, levrek ve çapak, mısır sazan, kadife ve altın sazan, boili sazan, yayın, altın sazan ve çapak, karides yayın, turna, sudak ve tatlısu kefali. Mersin hiçbir yeme gelmez, ama dipte 1,5 kat sık gelir. **Yapay yemlerin çektiği** (spin): kaşık levrek ×1,3; döner kaşık levrek ×2, tatlısu kefali ×1,6; silikon yem sudak ×2,2, levrek ×1,4; maket balık turna ×2,2, sudak ×1,5; su üstü yemi tatlısu kefali ×2,2, turna ×1,8; altın kaşık turna ×2,5, sudak ×2, yayın ×1,6. **Sineklerin çektiği:** kuru sinek alabalık ×1,2; nimf alabalık ×2, tatlısu kefali ×1,5; streamer dere alabalığı ×2,2, alabalık ×1,2. Defter tutulmamış türün en sevdiğini ipucu olarak söyler: türün tekniklerinin yemlerinden, yapay yemlerinden ve sineklerinden türü gölde en sık getireni (başka türleri de çeken yem türün payını düşürebilir: en büyük çarpan her zaman en iyisi değil).

**Dalga 3 türleri** sona eklenir ve şamandırayla gelmez: şamandıranın oranları, kataloğu ve altın testi değişmez. ✅ Aynalı sazan yalnızca dipte (sazlıkta 12, derin ortada 60 ağırlık). ✅ Alabalık ve dere alabalığı dere ağzında (30 ve 4 ağırlık): sinekle (yatkınlık 1), az da spinle (0,6 ve 0,4). Çekişmede çırpınınca sudan sıçrarlar (`fight.jumps`; yalnızca görünüş). ✅ Kerevit tuzakta (sazlık ve kayalık burun) ve az da dipte (yatkınlık 0,5; 8 ağırlık).

**H2 türleri** (19 tür; ilk 5 kimlik korunur, sazan Güzel'e çıkar). Dalga 3'le 16'sı oyunda; Dalga 4'te Ay Turnası ve Kocabaş (18, ✅) ve hikâyenin sonunda Gölün Bekçisi (19, ✅). Bölge, teknik ve vakit ayrıntısı §10.1 ve §10.3'te.

| Kademe | Türler |
|---|---|
| Sıradan | kızılkanat ✅, gümüş balığı ✅, çapak ✅, tatlısu kefali ✅, kerevit ✅ (tuzak) |
| Güzel | sazan ✅, levrek ✅, kadife ✅ |
| Nadir | turna ✅, sudak ✅, alabalık ✅, aynalı sazan ✅ |
| Destansı | yayın ✅, altın sazan ✅, dere alabalığı ✅ |
| Efsanevi | mersin ✅ (yalnızca bırakılır; koruma mesajı), Ay Turnası ✅ (yalnızca gece, bırakılır), Kocabaş ✅ (dev yayın, yalnızca yağmurlu gece, bırakılır) |
| Masalsı | Gölün Bekçisi (hikâyenin sonu) |

- ✅ **Kerevit:** tuzakla ve dip avıyla çıkar (§10.3).
- ✅ **Vakit ve hava** (Dalga 4, §10.5): her türün vakit (`when`) ve hava (`weather`) çarpanı var (yazılmayan 1). Vakit
  çarpanlarının ortalaması her türde 1: vakit balığın ne zaman geldiğini değiştirir, kazancı değil (`test_economy`:
  vakit ve hava ortalamasında bölgenin balık başına değeri koşulsuz değerin ±%5'inde). Belli vakitte gelen türler
  (`only`) o koşulun dışında hiç gelmez. Oranlar iki aşamada hesaplanır (§10.2): önce bugünkü ağırlıklar, sonra
  çıkan oran × koşul çarpanı (koşulsuz sayılar bit bit aynı).

  | Tür | Sabah / öğle / akşam / gece | Hava |
  |---|---|---|
  | Kızılkanat | 1,0 / 1,3 / 1,0 / 0,7 | yağmur 0,8 |
  | Gümüş Balığı | 1,3 / 1,0 / 1,1 / 0,6 | – |
  | Çapak | 0,9 / 0,7 / 1,2 / 1,2 | bulutlu 1,2 |
  | Tatlısu Kefali | 1,2 / 0,8 / 1,2 / 0,8 | yağmur 1,4 |
  | Sazan | 1,3 / 0,7 / 0,9 / 1,1 | bulutlu 1,2 |
  | Levrek | 1,2 / 1,0 / 1,2 / 0,6 | bulutlu 1,2 |
  | Kadife | 1,5 / 0,7 / 1,1 / 0,7 | bulutlu 1,2, yağmur 1,3 |
  | Turna | 1,2 / 0,8 / 1,3 / 0,7 | bulutlu 1,3, yağmur 1,2 |
  | Sudak | 0,9 / 0,6 / 1,1 / 1,4 | bulutlu 1,3, yağmur 1,2, sis 1,5 |
  | Yayın | 0,8 / 0,6 / 1,0 / 1,6 | yağmur 1,4 |
  | Altın Sazan | 0,9 / 1,5 / 0,9 / 0,7 | bulutlu 0,8, yağmur 0,7 |
  | Mersin Balığı | 1,1 / 0,8 / 0,9 / 1,2 | sis 1,3 |
  | Aynalı Sazan | 1,2 / 0,8 / 0,9 / 1,1 | – |
  | Alabalık | 1,3 / 0,7 / 1,3 / 0,7 | bulutlu 1,2, yağmur 1,4 |
  | Dere Alabalığı | 1,4 / 0,7 / 1,2 / 0,7 | yağmur 1,5 |
  | Kerevit (dipte; tuzak etkilenmez) | 0,8 / 0,6 / 1,0 / 1,6 | – |
  | Ay Turnası | yalnızca gece | bulutlu 0,8, yağmur 0,6 |
  | Kocabaş | yalnızca gece | yalnızca yağmur |

  Koşulu gelince payı: Ay Turnası nilüferli koyda şamandırayla ~%2,5, spinle ~%7; Kocabaş derin ortada dipte ~%6.
  Denge botunda (16 saat, 6 seed; vakit değişince bölgesini yeniden seçer) Ay Turnası ilk kez 26–119. dakikada,
  Kocabaş 146–596. dakikada (bir seed'de 16 saatte hiç): fırtınalı gece derin ortada dipte olmak şansa bağlı.
- **Eşyalar:** eski çizme, teneke, mesajlı şişe (hikâye), paslı anahtar. Çöp toplamak göl sevgisi verir.
  - ✅ **Çöp** (Dalga 4; `rules.json` `trash`): dipte tutulan balığın yanında %5 (kurşun dibi tarar; şamandıra,
    spin ve sinek yüzeyde: çöp yok), tuzakta kerevit başına %5 (içerik yenilenirken yeni kerevit sayısıyla: boş
    tuzak dolunca %20; sık toplayan çok çöp bulmaz; ilk kerevitle birlikte çıkar). Hangisi:
    çizme 35, teneke kutu 35, plastik şişe 25, paslı anahtar 5. Ne çıkacağı önceden belli (gelir kuralı 4):
    balıkta gölgenin zarı, tuzakta içerik kurulurken (kerevitler aynı kalır). Toplanınca göl sevgisi verir (3,
    paslı anahtar 5); kovaya girmez, satılmaz, para vermez. Eşyanın resmiyle bildirim ("Eski çizme çıktı! Göl
    sevgisi +3"), ses ve titreşim; Dede her eşyanın ilk gelişinde konuşur ("Eski bir çizme! Göl temizlendikçe
    balık çoğalır.", "Teneke kutu! Topladığın her çöp göle iyi gelir.", "Plastik şişe! Balıklar bunlarla
    yaşayamaz evlat.", "Paslı bir anahtar! Benim gençliğimden kalma olabilir.").
- **Katalog:** bütün oranlar araçla üretilen `docs/balik-katalogu.md`'de yazar.

## 7. Kahraman, Dede ve Nine

- **Kendi balıkçın:**
  - ✅ 1. hafta kız balıkçıyla çıkar (KayKit Rogue, yeniden boyanmış; pelerin ve silahlar gizli; kodla kova biçimli balıkçı şapkası).
  - ✅ Duruşlar: bekleme, yürüme, atış (Throw), olta suda (tek el nişan), çekme (iki el nişan, gerilimle geriye yaslanır), gösterme ve sevinç (Cheer).
  - Model dosyası yoksa kodla kurulan basit bir balıkçı çıkar (aynı duruşlar).
  - Erkek balıkçı ve seçim ekranı 🔜 (H2, Dalga 5). İlk açılışta kız ya da erkek seçilir, ayarlardan değişir. Model KayKit Adventurers ve Mac'te indirilen paketlerden karakter sayfasıyla seçilir.
  - Kıyafetler 🔜: şapka, yelek rengi, olta kaplaması. H2'de rütbe, defter ve isteklerle kazanılır; gerçek parayla satış Faz 3'te.
- **Dede:**
  - Köyün yaşlı balıkçısı.
  - ✅ İskelenin kenarında oturur, bacakları suya sarkar; yanında ince belli çay bardağı. KayKit Barbarian, yeniden boyanmış: beyaz sakal ve kaşlar, tuğla kırmızısı örgü kazak, kodla kasket. Miğfer, silahlar ve kupa gizli (kupa bira bardağına benziyor; oyun her yaşa).
  - ✅ Yüzü görünsün diye kameraya üçte bir dönük oturur. Konuşurken başını kaldırıp oyuncuya (kameraya) bakar, başını sallar; başının üstünde konuşma balonu (üç nokta) çıkar. Olta sudayken şamandırayı izler. Balık tutulunca oturduğu yerde kollarını kaldırıp sevinir (yeni tür, rekor, nadir); sıradan balıkta ünlemle onaylar.
  - ✅ İpucu çubuğundaki yüzü kendi modelinden çekilir (Ersin'in Dede portreleri gelince onlar).
  - Balıkçı onun içinden geçmez, yanından kayarak geçer.
  - ✅ Her tekniği açılınca haber verir, ilk kullanımda nasıl oynandığını söyler (§10.3).
  - ✅ Açılış filminde Nine'yle birlikte gölün öyküsünü anlatır, Gölün Bekçisi'ni gösterir ve ilk oltasını
    balıkçıya verir (§10.5).
  - ✅ Her gün 3 küçük istekte bulunur ("3 Kadife tut", "Kadife · en az 35 cm"; §10.5); "Gölün Sırrı"nı parça parça
    anlatır: şişeden çıkan her mektuptan sonra bir söz, eski haritasının dört parçası için dört altın istek (§10.5).
  - ✅ Dede'yle çay içmek oyun saatini bir sonraki vakte geçirir (§10.5). Vakte ve havaya ilk sözleri bir kez
    (olta boşa dönünce; çekişmede ipucunu ezmez):
    öğle ("Altın Sazan öğle güneşini sever"), akşam (turna ile levrek), yeni günün sabahı, bulut, yağmur, sis
    (sudak), fırtına ("Kocabaş böyle gecelerde derinde gezer"); ilk gecenin sözü Nine'nin feneri. Öğütlerine çay
    da katıldı ("Saate dokun evlat, benimle bir çay iç").
- **Nine** (Dede'nin eşi):
  - ✅ İskelenin kara ucunun solundaki küçük ahşap dükkânı işletir: tezgâhın arkasında ayakta durur, yüzü iskeleye ve kameraya dönük. Balıkçı yaklaşınca ona bakar. Ona ya da dükkâna dokununca selam verir (balon, baş sallama, tezgâha uzanır); sözü ipucu çubuğunda kendi yüzüyle çıkar. Dükkân paneli 🔜 (Dalga 1, 6. adım).
  - ✅ KayKit Mage, yeniden boyanmış: gümüş saç, hardal sarısı hırka. Kodla beyaz, mavi çiçekli yazma (çenenin altında bağlı), turkuaz puantiyeli önlük, yuvarlak gözlük ve pembe yanaklar (Ersin'in portre tarifi). Büyücü şapkası, asa ve kitap gizli. Model yoksa kodla kurulan yedek çıkar.
  - ✅ Dükkân kodla kurulur: alçak döşeme, raflı arka duvar (yem kavanozları, kutular), tezgâh (solucan kovası, kavanozlar, mısır kasası, zil), olta sehpası ve kepçe, turkuaz-krem çizgili tente, "Nine'nin Dükkânı" tabelası; yanında fıçı, kasa, çuval. Kamera yukarıdan baktığı için tente yüksek ve kısa: Nine'nin başı altından görünür. Balıkçı dükkânın içinden geçmez.
  - ✅ Hikâyede gençliğini anlatır (şişelerdeki tek numaralı mektuplar onun); göl sevgisi 6 olunca dükkâna ilk
    uğrayışta "altın hamur"u verir (§10.5).
- **Kedi (Tekir)** 🔜:
  - İskelede bekler, peşinden biraz gelir. Dokununca mırlar (titreşim).
  - Küçük balık isteyebilir; her 5 beslemede sıradaki hediyeyi getirir (sabit sırayla, zar yok).

## 8. Görünüm

- **Kamera:**
  - Eğik üstten: yatay açı 32°, eğim 50°, 12 m uzaklık (Kazı'nın yüzey kamerası).
  - Olta suyadayken eğim ~60°'ye çıkar, odak balıkçı ile şamandıranın ortasına kayar. Çekişmede hafif yakınlaşır.
- **Su:**
  - Opak, düz.
  - Renk, göl şeklinden üretilen bir dokudan gelir: derinlikte koyu, kıyıda açık turkuaz.
  - Kayan dalgalar; gerçek kıyı çizgisinde köpük.
- **Gölgeler:** suyun 2 cm üstünde yumuşak, koyu, balık biçimli lekeler; yön ve boy belli. Telefonda okunsun diye balığın boyunun 1,25 katı çizilir (kurallar gerçek boyu kullanır). Halkalar aynı yöntemle.
- **Şamandıra:** en az 0,3 m, kırmızı-beyaz. Dürtmede boyunun %40'ı kadar dalar, halka çıkar.
- **Misina:** kameraya dönük ince şerit (~1,3 pt). Beklerken sarkar, çekişmede gerilir ve titrer.
- **Balıklar** kodla kurulur:
  - Oranlar:
    - boy/yükseklik 2,2 (turnada 3);
    - en yüksek nokta boyun %35'inde, küt burun;
    - genişlik yüksekliğin 0,6'sı.
  - Gözler iri (boyun 0,075'i), göz bebeği ve parlama ile.
  - Renk: koyu sırt, açık karın, türe özgü bir vurgu.
  - Kuyruk kıvrılır; dış çizgi kıvrılmaya uyar.
  - Elde gösterilen boy gerçeğe göre küçültülür (boyun 0,55. kuvveti): 15 cm'lik kızılkanat 0,3 m, 250 cm'lik yayın en fazla 1,1 m görünür.
  - Kartın balık resmi aynı modelden açılışta çizilir (Ersin'in balık görselleri gelince onlar kullanılır).
- **Olta:** 2,3 m, üç eklemli; çekişmede gerilimle bükülür, gerilim yüksekken titrer. Serbestken dik taşınır.
- **Çevre:** iskele (tahta), sazlık, KayKit ağaç, kaya, çadır, fıçı ve fenerleri; Kazı'nın çimeni, ışığı ve ortamı.
- **Işık ve pus:**
  - Sıcak güneş, serin dolgu ışığı, Filmic ton eşleme ve hafif kontrast.
  - Sis yalnızca uzakta. Kamera oyun alanını ~20 m'ye kadar görür; derinlik sisi 35 m'de başlar, 140 m'de en çok %45 örter (yakın çekimde uzak kıyı ve tepeler). Parlama yalnızca gerçekten parlak yerlerde (ışık sütunu, su parıltısı).
  - v0.3.1'den önce üstel sis bütün görüntüyü puslu yapıyordu (Ersin telefonda "sisli" dedi). Telefon boyutunda ölçüm: doygunluk %22–24, kontrast %26–29 düşüktü; en koyu tonlar açılmıştı.
- **Dış çizgi** yalnızca karakterlerde ve balıklarda.
- **Erişilebilirlik:** gerilim çubuğu renk + ikon + sarsıntı + "BIRAK!" yazısı. Her sesin bir görsel ve titreşim karşılığı var.
- **H2 görsel hedefleri 🔜:**
  - **Su:** normal haritası, gök rengine göre fresnel, sığda kostik, derede akış, yağmur halkaları.
    - ✅ Dalga 2'deki hâli: renk derinliğin metresine göre; iki katlı dalgacık ve güneş parıltısı; kıyıda kıpırdayan köpük ve kıyıya doğru gelip sönen, parça parça ince dalga çizgileri; dere ağzında akıntı yönünde kayan kısa, kıvrımlı akıntı çizgileri (dar derede güçlü, derenin açıldığı havuzda zayıf; dalgalar da akıntıyla kayar). Fresnel ve kostik sonraki dalgalarda; yağmur halkaları Dalga 4'te ✅ (Işık maddesi).
  - **Zemin:** dokulu (çimen, kum, çamur, patika; Ersin'in dikişsiz dokuları ya da kodla).
    - ✅ Dalga 2'deki hâli (kodla; Ersin'in zemin karoları gelince onlarla): açık ve koyu çimen öbekleri; yürünmeyen yerde (orman, dünyanın kenarı) koyu orman zemini; kıyıdan ~2,6 m'de gölü dolaşan, kıvrılan toprak kıyı yolu (çalı, çimen öbeği ve çiçek yola düşmez); kenarı dalgalı kumsal, suya değen yeri ıslak; kayalık burnun karasında öbek öbek yosunlu taş.
  - **Doğa:** Forest Nature ve Quaternius doğa modelleri, nilüferler.
  - **Işık:** vakte göre ışık, gök ve sis; gece ay, fenerler ve ateş böcekleri.
    - ✅ Dalga 4'teki hâli (2. adım; `DayLook`, `LakeScene.set_look`): vakit × hava tablosu. Sabah ve açık hava
      v0.4.1'in ışığı. Öğle beyaz ve biraz tepeden; akşam alçak, turuncu güneş, uzun gölgeler, pembe ortam
      ışığı; gece mavi ay ışığı, koyu (3B görüntünün parlaklığı %72), suyun kendi ışığı (gölge koyu suda
      seçilsin), gölgeler biraz koyu, ateşböcekleri. Bulutta güneş ve gölgesi zayıf, gök soluk, kayan bulut
      gölgeleri; yağmurda koyu, ıslak (parlak) zemin, düşen damlalar ve suda damla halkaları; sisli sabahta
      sis 11 m'de başlar (balıkçı ~12 m'de berrak, ekranın üstü ~18 m'de puslu), gün ışığında beyaz pus.
      Yağmurlu gece fırtına: en az 12 sn arayla yumuşak şimşek (yanıp sönmez; ses 2. adımın sonunda).
      Vaktin son 60 sn'sinde sonrakine (gün dönerken yarının havasına) kayar; hava düğmesi ve hızlı geçiş
      yumuşakça. Çizim eklemeyenler global shader uniform'larıyla (`world_light.gdshaderinc`); yağmur ya da
      ateşböceği tek parçacık düğümü (`AmbientParticles`, 1 çizim). Konumlu ışık yok (Compatibility'de her
      nesneye ek çizim): lambaların ışığı shader'da ışık havuzu (en çok 4): Nine'nin feneri (ilk gece
      hediye: balıkçının çevresinde 6 m), kamp ateşi, iskelenin başındaki fener direği, dükkân; akşam az,
      gece tam.
    - Ölçüm (`world` botu, iskele, 1560×720; ÖLÇÜ satırları): doygunluk sabah 0,61, akşam 0,71, gece 0,70,
      sisli sabah 0,43; en koyu %5 sabah 0,35, akşam 0,18, gece 0,05; gölgenin suya karşıtlığı her görünüşte
      0,61–0,96 (sınır 0,25); çizim en çok 143 (yağmurda).
  - **Nadirlik efektleri:** gölgede pırıltı, ışıltı, iz.
  - **Arayüz:** Ersin'in arayüz kiti (çerçeveler, düğmeler, nadirlik çerçeveleri).
  - **Ölçüt:** iPhone 14'te 60 fps.
    - ✅ Ölçüm: ayarlarda sürüm yazısına 5 dokunuş sol üstte FPS, çizim ve üçgen sayısını açar (her sürümde); adımlar `iphone-kurulum.md` 12. adımda. Bulutta (`tour` botu; arayüz dahil) bir bakışta en çok 140 çizim.

## 9. Ses

- ✅ Kodla üretilir (`tools/make_sounds.py`, Kazı'nın sentez yardımcıları):
  - atış vınlaması, şamandıra "plop", dürtme tıkı;
  - ısırma sıçraması + zil;
  - makara tıkırtısı (döngü), gerilim gıcırtısı (döngü), misina kopması;
  - nadirliğe göre buluntu;
  - arayüz sesleri;
  - göl ortam sesi (su, kuş, rüzgâr).
- ✅ Müzik (Dalga 4): her vaktin kodla üretilen sakin, dikişsiz döngüsü (40–46 sn; sabah kalimba ve marimba,
  öğle marimba ve ud, akşam ud ve çelesta, gece çelesta, uzak çan ve kalimba; altında pad ve bas) ve Nine'nin
  dükkânının neşeli valsi (dükkân açıkken). Vakit değişince 2 sn'de geçer. Ezgiler elle yazıldı; çalgılar
  Reels müziğiyle ortak (`tools/make_sounds.py`).
- ✅ Ortam sesi görünüşle değişir: gündüz göl (su, kuş, rüzgâr), gece cırcır böcekleri ve kurbağa, yağmurda
  yağmur. Fırtınada her şimşekten 0,6–1,8 sn sonra uzak, yumuşak gök gürültüsü (titreşimiyle).
- ✅ Dalga 4 efektleri: vakit değişimi (üç notalı çan, bildirimle), Dede'yle çay (bardağa akan çay, kaşık),
  Nine'nin feneri (fitil ve sıcak akor), Masalsı buluntu (Gölün Bekçisi için). Her birinin görseli (bildirim,
  kararma, şimşek, kart) ve titreşimi var.
- ✅ Spin: yem düşüşü (iki çeşit), saldırı şapırtısı, takılma (otlara sürtünme); yem çekilirken makara döngüsü kısık ve pes. Her birinin görseli (halka, sıçrama, iz) ve titreşimi var.
- ✅ Dip: zil (iki tınlama; koklamada tek tük), koşuda durmadan çalan zil döngüsü, kurşunun pes şapırtısı. Zilin görseli sehpada sallanan zil ve koşuda 2B zil işareti; her birinin titreşimi var.
- ✅ Sinek: halka (yüzeyde küçük şapırtı ve emiş kabarcığı; iki çeşit), sineğin konuşu kısık tıkırtı, sıçrayan alabalığın çıkış ve dalış şapırtısı. Görseli halka, suya çekilen sinek ve sıçrayan balık; her birinin titreşimi var.
- ✅ Tuzak: bırakma ve toplama (§10.3); her birinin görseli ve titreşimi var.
- 🔜 Yeni sesler: kedi mırlaması.
- iPhone'un sessiz anahtarı açıkken oyunun sesi çıkmaz (Kazı deneyimi).

## 10. H2 sistemleri 🔜

Sıra ve adımlar [`yol-haritasi.md`](yol-haritasi.md)'de (Dalga 1–5). Sayılar taslaktır, denge botuyla ayarlanır.

### 10.1 Göl ve bölgeler

- **Boyut:** su alanı eski gölün (testlerin gölü, ≈227 m²) yaklaşık 3,7 katı: ≈846 m²; suyun kutusu yaklaşık 46×30 m (`tools/lake_map.gd`).
- **İskele koyu bugünkü gibi kalır:** iskele, başlangıç noktası ve Dede aynı yerde.
- **Derinlik:** her havzanın kendi derinliği ve kıyı eğimi var.

| Bölge | Derinlik | Öne çıkan teknik | Balıklar | Açılış |
|---|---|---|---|---|
| İskele koyu | 1–3,5 m | şamandıra, spin | kızılkanat, gümüş, çapak, levrek, sazan | başta |
| Sazlık | 0,5–1,5 m | şamandıra, dip, tuzak | kadife, sazan, kızılkanat, aynalı sazan (dip), kerevit | başta |
| Nilüferli koy | 1–2,5 m | spin | turna, levrek, altın sazan, ay turnası | rütbe 3 |
| Kayalık burun | 2–6 m (dik) | spin, dip | sudak, tatlısu kefali, levrek, kerevit | rütbe 5 |
| Dere ağzı (akıntılı) | 0,5–1,5 m | sinek, spin | alabalık, dere alabalığı, tatlısu kefali | rütbe 7 |
| Derin orta | 4–10 m | dip (sandaldan) | yayın, aynalı sazan, mersin, Kocabaş, Gölün Bekçisi | rütbe 9 + sandal |

- ✅ **Dalga 2'deki balıklar** (solucanla bir gölgenin o tür olma şansı; tam tablo [`balik-katalogu.md`](balik-katalogu.md)):
  - iskele koyu: kızılkanat %26, sazan %20, levrek %18, gümüş balığı %14, çapak %10, turna %8, yayın %4;
  - sazlık: kızılkanat %28, sazan %24, kadife %22, gümüş balığı %14, levrek %7, turna %5;
  - nilüferli koy: levrek %26, sazan %24, turna %22, kızılkanat %22, altın sazan %6;
  - kayalık burun: tatlısu kefali %30, levrek %28, sudak %16, turna %10, kızılkanat %10, yayın %6;
  - dere ağzı: tatlısu kefali %36, turna %26, levrek %20, kızılkanat %10, yayın %8 (dereden inen yemi bekleyen yırtıcılar; alabalıklar sinekle Dalga 3'te). Her yeni bölge öncekilerden az kazandırmaz: solucanla balık başına ortalama değer iskele koyu 14, sazlık 10, nilüferli koy 21, kayalık burun 23, dere ağzı 24, derin orta 40 para (`test_economy.gd` denetler);
  - derin orta: yayın %22, sazan %20, çapak %19, sudak %14, turna %12, levrek %11,5, mersin %1,5.

- **Yürüme:** koyların çevresinden dolaşılır. Dokunulan yere sudan geçmeden varılamıyorsa balıkçı kıyı yolundan kısa yönü seçer.
- **Harita:** bölgelerin atış noktalarına hızlı geçiş (ekran kararıp açılır). Kilitli noktalar rütbeyle açılır.
  - ✅ Dalga 2'deki hâli: sağ üstte, defterin solunda harita düğmesi (ilk balıktan sonra; olta sudayken gizli). Göl gerçek verisinden kodla çizilir: masa oyunu haritası gibi çayır, kum, kıyıda mürekkep çizgisi, derinliğe göre su, ağaç tepeleriyle orman (dünyanın kenarı). Üstünde her bölgenin rozeti ve adı; açılmış ama gidilmemiş bölgede köşede "Yeni!"; kilitli bölgenin suyu gri ve taralı, rozetinde kilit ve "Rütbe 5" ya da "Sandalla"; kapalı çitler, şamandıralar, iskele, Nine'nin dükkânı, Dede ve "Buradasın" iğnesi. Açık bir bölgeye dokununca ekran 0,25 sn'de kararır, balıkçı o bölgenin atış noktasına suya dönük geçer, gölgeler çevresinde doğar, ekran açılır ve bölgenin adı çıkar (hışırtı ve çan sesi, kısa titreşim). Kilitli bölgeye dokununca rozet sallanır, nedeni yazar.
  - ✅ Yeni bölge açılınca (rütbe atlayınca): "Nilüferli Koy açıldı!" bildirimi bölgenin rozetiyle, Dede "Yeni bir yer açıldı evlat! Haritaya bir bak." der, harita düğmesi 4 sn nabız gibi atar.
  - Ersin'in Parti 3 görselleri (harita kâğıdı, çıkartmalar, bölge rozetleri) gelince harita onlarla süslenir; rozetlerin yedeği kodla çizilir.
- **Sandal:** dükkândan alınır. İskeleye bağlı sandala binilir; derin ortadaki 3 şamandıradan birine gidilir. Sandaldayken suya dokunmak yine atıştır.
  - ✅ Dalga 2'deki hâli: Nine'nin dükkânında Ekstra sekmesinde (rütbe 9, 3.500 para). Sandal yokken iskeledeki sandala dokununca Dede "Sandalla derin sulara açılınır. Zamanı gelecek evlat!", rütbe yetiyorsa "Derin sulara hazırsın evlat! Nine sandal satıyor." der. Sandal alındıysa sandala ya da haritada Derin Orta'ya dokununca ekran kararır; sandal ilk şamandıranın yanına gider, balıkçı içinde ayakta, şamandıra önünde (sandal suyla iner kalkar). Sandaldayken yürünmez, dokunulan yöne atılır; gölgeler yalnızca derin ortada doğar ve sandalın altına girmez. İlk açılışta Dede "Derin sular! Burada iri balıklar yaşar evlat. Sıkı tut!" der. Haritada Derin Orta'ya yeniden dokununca sıradaki şamandıraya geçilir; sol alttaki "Kıyıya dön" ya da haritada bir kıyı bölgesi balıkçıyı karaya, sandalı iskeleye götürür. Oturum hep iskelede başlar.

### 10.2 Nadirlik ve şans garantisi

Kademeler yalnızca sona eklenir; Masalsı yeni eklenir. Renk tek başına yetmez: her kademenin bir simgesi, adı ve sesi var. Ekran gri tonlamada da denetlenir.

| Kademe | Simge | Renk | Tutmadan önce ipucu |
|---|---|---|---|
| Sıradan | ● | gri (bugünkü krem beyaz yazıya benziyor) | — |
| Güzel | ▲ | yeşil | — |
| Nadir | ◆ | mavi | gölgede arada pırıltı |
| Destansı | ★ | mor | mor ışıltı ve kabarcık |
| Efsanevi | ✦ | altın | iz bırakan dalga, Dede'nin uyarısı, kısa müzik |
| Masalsı | ✪ | turkuaz | yalnızca Gölün Bekçisi |

- **Tuttuktan sonra:** kademe çerçeveli kart ve rozet, kademe renginde ışık sütunu, kademe sesi, Dede'nin sözü.
- ✅ **Dalga 1'deki hâli:**
  - Simgeler kodla çizilir (daire, üçgen, karo, yıldız, dört köşeli parıltı, madalyon); her rozette (kart, dükkânın kovası, defter) adın önünde. Gri tonlamalı ekran görüntüsünde rozetler şekilleriyle ayrılıyor.
  - Gölgede ipucu: Nadir 2,5 sn'de bir baştan kuyruğa kayan açık bir pırıltı; Destansı kenarında hiç sönmeyen, nabız gibi atan mor ışıltı ve arada kabarcık halkaları; Efsanevi altın parlayan kenar ve göbek, arkasında dalga izi (Efsanevi balık Dalga 2'de gelir).
  - Efsanevi bir gölge balıkçıya 9 m yaklaşınca Dede bir kez uyarır ("Şşş! Şu parlayan gölgeyi gördün mü?"), kısa gizemli bir ezgi çalar, telefon titrer, Dede o gölgeye bakar.
  - Tutunca balığın üstünde 2B etiket: simge ve ad kademe renginde, altında boy (kartsız yakalamadaki eski bildirim kalktı; rütbe ve kova bildirimleri etiket sönünce gelir).
  - Kartta Dede'nin yüzü ve sözü: Nadir ve üstünde kademeye göre ("Vay be, nadir bir balık!", "Bunu ben bile az gördüm!", "Efsane! Bunu bütün köy duyacak!"), yoksa yeni tür ya da rekor için.
- **Değer:** her türün bir taban değeri var (Sıradan ≈5, Güzel ≈12, Nadir ≈35, Destansı ≈120 para) × boy çarpanı (0,6–1,6). Dalga 2'nin tek Efsanevi türü mersin koruma altında: satılmaz, göle bırakılır (rütbe puanı ve göl sevgisi verir). Masalsı da satılmaz.
- **Şans garantisi:**
  - Nadir+ balık gelmeden geçen 40 avdan sonra, bulunduğun bölgede Nadir+ bir gölge doğar. Destansı+ için 150, Efsanevi için 400 av.
  - Sayaçlar defterde görünür.
  - Garanti öteki zarları kaydırmaz (Kazı'daki `LootTable` düzeni: sabit sıralı zar).
- **Balık Defteri:**
  - Kademeye göre ızgara; bulunmamış türler siluet ve ipucuyla (bölge, teknik, vakit, hava).
  - Rekorlar; o yerdeki, teknikteki ve vakitteki tam oranlar; şans garantisi sayaçları; göl sevgisi.
  - ✅ Dalga 1'deki hâli: sağ üstteki defter düğmesiyle açılır (olta sudayken gizli). Nadirlik sırasıyla 6×2'lik sayfalar (12'den çok tür olunca sayfa düğmeleri). Tutulan tür kendi resmi, adı, en büyük boyu ve nadirlik renginde çerçeveyle; tutulmayan koyu siluet, "???" ve nadirlik simgesiyle (renksiz). Sağda seçili türün nadirliği, rekor boyu ve yıldızı, tutulan ve bırakılan sayısı, tanımı; tutulmadıysa ipuçları (sevdiği yem, gölde ne sıklıkla görüldüğü). Altında takımınla bir gölgenin bu balık olma şansı, gölün nadirlik oranları ve şans garantisi sayaçları ("9 av içinde garanti"). Oranlar gölgeyi doğuran işlevin aynısından gelir.
  - ✅ Garanti yalnızca gölde tutulabilen kademeler için yazılır ve işler: Köy Gölü'nde Efsanevi tür yokken dolan Efsanevi sayacı Nadir ve Destansı garantisini kilitlemez (`CatchOdds.pity_floor(db, save, spot)`).
  - ✅ Dalga 3'teki hâli (v0.4): 16 tür, iki sayfa (12 + 4). Oranlar elindeki teknik ve takımla; başlıkta tekniğin adı ("Sazlık oranları (Spin, takımınla)"). Şans garantisi yalnızca elindeki teknikle bu bölgede gelebilen kademeler için yazılır. Tutulmamış türün ipuçları:
    - en sevdiği yem, yapay yem ya da sinek (türün tekniklerinin kullandığı; "Sevdiği sinek: Nimf");
    - tuzağa giriyorsa nerede ("Tuzağa girer: Sazlık, Kayalık Burun"; tuzak hep o türü verdiği için sıklık yazılmaz);
    - şamandırayla gelmiyorsa hangi teknikle ("Şununla tutulur: Spin, Sinek"; tuzak türünde "Şununla da tutulur: Dip");
    - yaşadığı bölgeler (tuzağınkilerle aynıysa yinelenmez) ve ne sıklıkla görüldüğü.
  - ✅ Dalga 4'teki hâli (1. adım): 18 tür, iki sayfa (12 + 6). Oranlar gölün şimdiki koşuluyla (vakit, hava, göl
    sevgisi); başlıkta koşulun hapı: vaktin ve havanın ikonu, "Akşam · Yağmurlu" (yağmurlu gecede "Fırtınalı"; sevgi
    seviyesi 2'den büyükse "· Göl sevgisi 2 (Nadir+ +%4)"). Tutulmamış türün vakit ipucu tek satırda: belli vakitte
    geliyorsa "Yalnızca gece çıkar." / "Yalnızca fırtınalı gecelerde yemlenir.", yoksa en sevdiği vakit ("En çok
    sabah gelir.") ve hava ("Yağmuru sever.") çarpanı en az 1,3 ise. Ay Turnası ve Kocabaş'ta "Gölün efsanesi:
    tutulur, göle bırakılır." (mersinde koruma sözü). Dükkânın yem kartı da şimdiki koşulla. Defter, telefonda
    güvenli alanın içinde (inceleme: koşul satırları eklenince alttan taşıyordu; paneller artık güvenli alanın
    ortasında, `Dialog`).
- ✅ **Oranlar ve koşul** (Dalga 4): oran iki aşamada hesaplanır. Önce bugünkü hesap (ağırlık × yem × teknik
  yatkınlığı; o koşulda gelmeyen tür 0), sonra çıkan oran × türün koşul çarpanı (vakit × hava × sevginin Nadir+ payı,
  binde) yeniden toplamı 1.000.000'a. Bütün çarpanlar 1 ise ikinci aşama atlanır: koşulsuz her sayı eskisi gibi
  (altın test). Şans garantisi o koşulda gelebilen kademeleri sayar (gündüz nilüferli koyda Efsanevi garanti yok);
  koşul değişince yenilenir, o koşulda gelmeyen türün dolaşan gölgesi çekilir.

### 10.3 Teknikler ✅

Çekişme her teknikte ortaktır (bugünkü `ReelModel`); teknik yalnızca ısırmaya kadarki kısmı değiştirir. Her türün bir teknik yatkınlığı var.

| Teknik | Nasıl oynanır | Takım | Açılış |
|---|---|---|---|
| Şamandıra | bugünkü gibi | şamandıra kamışı, şamandıra, iğne, yem | başta |
| Spin | Basılı tut = yem gelir, bırak = durur ve batar. Yırtıcı yemi kovalar; "dur-kalk" ritmiyle saldırır. Saldırı anında basılıysa balık kendiliğinden takılır, değilse kısa VUR anı. Otlu ve kayalık yerde uzun bekleyen yem takılır (yalnızca zaman kaybı). | spin kamışı, makara, yapay yem | rütbe 2 |
| Dip | Uzağa at, olta sehpaya konur. Zil: tek tük bip = balık kokluyor; sürekli bip ve misina akıyor = koşu → dokun. İri balık, uzun çekişme. | dip kamışı (sehpası ve zili onunla), kurşun ya da yem sepeti, yem | rütbe 4 |
| Sinek | Yalnızca dere ağzında. Akıntıya at, sinek sürüklenir; halka çıkınca 0,5 sn içinde dokun. Alabalık çevik ve sıçrar; dere alabalığı iri tür. | sinek kamışı, sinek | rütbe 7 |
| Kerevit tuzağı ✅ | Sığ kıyıya bırak. Oyunda değilken de dolar: 20 dk'da bir, en çok 4. İçi bırakılırken belirlenir. | tuzak (en çok 3) | rütbe 3 |

- ✅ **Teknik altyapısı (Dalga 3):** tekniğin ısırmaya kadarki kuralları bir strateji sınıfında (`Technique`: şamandıra `FloatTechnique`, spin `SpinTechnique`, dip `BottomTechnique`, sinek `FlyTechnique`); sayıları `rules.json` `techniques` (şamandıranınki üst bölümlerden). Teknik yalnızca olta boştayken değişir; değişince gölgeler yeni tekniğin oranıyla yeniden doğar. Şamandıra bit bit eskisi gibi (altın test).
- ✅ **Tür yatkınlığı** (`fish.json` `affinity`): şamandırada bütün türler 1. Spin yalnızca yırtıcıları çağırır: sudak 2, turna 1,4, levrek 1, tatlısu kefali 0,7, alabalık 0,6, dere alabalığı 0,4, yayın 0,1 (8. adımda; önce sudak 0,9, turna 0,8, yayın 0,25). Defter ve dükkân oranı elindeki tekniğe göre gösterir.
- ✅ **Spin (v0.4):**
  - **Fark etme:** yırtıcı yalnızca oynayan yemi (bırakınca 0,5 sn daha) fark eder: önde 4 m, yanda 2,2 m, 60°'lik koni. 2 m/sn kovalar (yem uzaklaşırken de yetişsin), 1,5 m/sn izler. Yem basılıyken 0,8 m/sn gelir (makaradan bağımsız: balık yetişebilsin).
  - **Saldırı:** balık 0,6 sn izledikten sonra her ritim değişiminde zar: duruşta %40, kalkışta %30; bir evre en az 0,25 sn. 4. değişimde kesin. Hep basılı tutana saniyede %12.
  - **VUR:** saldırı anında basılıysa balık kendiliğinden takılır; değilse 0,6 sn (Kolay 1 sn) VUR anı.
  - **Vazgeçme ve takılma:** 3 sn bekletilen yemden ya da 10 sn izledikten sonra balık vazgeçer ("Vazgeçti..."). Otlu ve kayalık yerde bekleyen yem takılır: sazlık 4 sn, nilüferli koy 5 sn, kayalık burun 3,5 sn; geri sarma 2,5 sn sürer, kayıp yok. İlk takılmada Dede nedenini söyler.
  - Yem balıkçıya 1,2 m kalınca atış biter.
  - **Görünüm:** su opak; yem yüzeyde parlayan gümüş bir kıymık. Çekilirken titrer, parlar ve arkasında halkalar (V biçimli iz) bırakır; durunca batar. Saldırıda su sıçrar, telefon titrer. Elde kısa, koyu spin kamışı (`RodModel.STYLES`).
  - **Takım:** 3 spin kamışı (hafif 150 para / rütbe 2 / 10 m / 3★; orta 1.100 / 4 / 12 m / 4★; ağır 3.000 / 8 / 13 m / 5★). 6 yapay yem (tükenmez): kaşık (bedava; levrek ×1,3), döner kaşık (120, r2; levrek ×2, kefal ×1,6), silikon yem (300, r3; sudak ×2,2), maket balık (700, r5; turna ×2,2), su üstü yemi (1.000, r6; kefal ×2,2, turna ×1,8), altın kaşık (2.500, r10; turna ×2,5, sudak ×2, yayın ×1,6).
  - **Açılış:** rütbe 2'de bildirim (spinin ikonuyla), Dede "Yırtıcılar oynayan yeme gelir evlat. Nine spin kamışı satıyor!" der, teknik düğmesi nabız gibi atar. İlk spin kamışı alınınca spin ele geçer; Dede "Gölgenin ötesine at, yemi tam önünden geçir!" der. İlk 3 spin atışında ipuçları: "Basılı tut, yem gelsin; bırak, batsın.", "Peşinde biri var! Dur-kalk yap!", "Saldırdı! Hemen VUR!" (`TechniqueHints`).
- ✅ **Dip (v0.4):**
  - **Atış:** dokunulan yöne, menzilin sonuna (14 / 16 / 18 m; kamışa göre) ama avlanılan bölgenin suyunda: gölgeler yalnızca orada dolaşır. En kısa atış 4 m. Kurşun suya düşünce yakındaki gölgeler ürker.
  - **Bekleyiş:** olta balıkçının yanındaki sehpaya konur, ucunda zil var. Balık yemi her yönden 4,5 m'den sezer. 1 sn sonra yemin kokusu yayılır: dolaşan gölgeler hemen yeni hedef seçer, %85 olasılıkla takımın 2 m çevresine yönelir ve oraya 3,5 kat hızlı yüzer. Yaklaşma 0,8 m/sn (8. adımda hızlandı: önce 2 sn, 2,5 kat, 0,5 m/sn).
  - **Zil:** varan balık 1–3 kez koklar (zil tek tük çalar; ağırlıklar 50/35/15; aralık 0,6–1,3 sn). Bu sırada dokunmak balığı kaçırır. Sonra zil durmadan çalar ve misina akar (koşu): 2,5 sn içinde (Kolay modda 3,5 sn) ekranın her yerine dokun.
  - Beklerken dokunmak oltayı geri sarar (uzun misina: 1 sn).
  - **Takım:** 3 dip kamışı (dip kamışı 500 para / rütbe 4 / 14 m / 4★; uzun 1.800 / 6 / 16 m / 5★; usta 4.500 / 10 / 18 m / 5★). Kamışların gücü yüksek (0,25 / 0,3 / 0,3): balık uzaktan gelir. Kurşun bedava; yem sepeti (400, r4): yemin kokusu 1 sn yerine 0,5 sn sonra yayılır ve dolaşan gölgelerin hepsi takıma yönelir (%85 yerine %100), menzil −1 m. Yem şamandırayla ortak stok.
  - **Yatkınlık:** dip sazangillerini ve iri dip balıklarını çağırır: sazan, kadife 1, yayın 1,5, altın sazan 0,8, çapak ve tatlısu kefali 0,5, mersin 1,5; az da kızılkanat 0,3, sudak 0,3, levrek ve turna 0,2. Aynalı sazan yalnızca dipte.
  - **Görünüm:** kurşun uçarken küçük koyu bir ağırlık; suya düşünce büyük halka ve pes şapırtı. Olta balıkçının yanındaki ahşap sehpaya konur (yanında yer yoksa öteki yanına, o da yoksa arkasına; `RodStand`, tek ağ, gölgesiz), misina kamışın ucundan kurşuna gerili. Koklamada zil çınlar, uç seğirir, kurşunun üstünde küçük halka. Koşuda zil durmadan çalar, uç eğilir, misina titrer, kamışın üstünde 2B zil sallanır. VUR'da balıkçı oltayı sehpadan alır.
  - **Kamera:** kurşun uzağa düştüğü için kamera biraz yatar (45°; şamandırada olta sudayken 60°) ve balıkçıyla takımı birlikte gösterecek kadar uzaklaşır (en çok 1,3 kat). Sınırlar ekran payıyla: balıkçının ayağı ipucu çubuğunun üstünde, kurşun üstteki göstergelerin altında kalır (bu iki çizgi arasına en çok 12,4 m sığar). Sığmazsa öncelik balıkçı ve sehpada: ekranın tam yukarısına atışta kurşun 14 m'de üst kenara yakın, 16 m'de üst kenarda, 18 m'de ekranın dışında kalır; çapraz atışta daha çoğu sığar. Çekişmede balık yaklaştıkça kamera çekişmenin yakınlığına döner (`FollowCamera.fit`).
  - **Açılış:** rütbe 4'te bildirim, Dede "İri sazanlar dipte beslenir evlat. Nine dip kamışı satıyor!" der, teknik düğmesi nabız gibi atar. İlk dip kamışı alınınca Dede "Uzağa at, sabret. Zil durmadan çalınca VUR!" der. İlk 3 dip atışında ipuçları: "Bekle... balıklar yemin çevresine toplanır.", "Zil tek tük çalıyor: kokluyor. Dokunma!", "Zil durmadan çalıyor! Hemen VUR!".
- ✅ **Sinek (v0.4):**
  - **Yer:** yalnızca akıntılı suda (dere ağzı; bölgenin `techniques`'i). Başka bölgede Takım Çantası'nda sineğin düğmesi "Dere ağzında" yazar, seçilmez. İlk sinek kamışı dere ağzı dışında alınırsa ele geçmez; Nine "Dere ağzında kullan evladım, alabalık orada." der. Dere ağzından çıkınca el oltası kendiliğinden şamandıraya döner (bölgenin adından sonra "Sinek yalnızca dere ağzında" bildirimi); dere ağzına dönünce sinek yine ele geçer (bildirim "Sinek"; arada başka teknik seçilmediyse). Dere ağzının kıyı şeridi dar: sınırda gidip gelen balıkçı sineği yitirmez. Bölge denetimi her karede ve atıştan hemen önce yapılır (sinek dere ağzı dışına atılmaz).
  - **Sürüklenme:** sinek düştüğü yerden akıntıyla sürüklenir (akıntının %85'i; dar derede ~0,85 m/sn). Kıyıya ya da iskeleye varınca, menzilin sonuna ya da balıkçıya 1,2 m'den yakına gelince (balık hep menzilin içinde, çekişme payıyla takılır; dibinde çıkan balık çekişmesiz tutulmaz), durgun suda 1,5 sn kalınca ya da 15 sn sonra kendiliğinden döner (0,8 sn). Hiç akmayan suya düşen sinek kımıldamaz ve döner: "Durgun su" bildirimi, ilk kez Dede "Durgun suda sinek kımıldamaz evlat. Akıntıya at!" der. Beklerken dokunmak geri sarar.
  - **Halka:** alabalık sineği önde 3 m, yanda 2 m'den (önünden iki yana 110°'ye kadar) fark eder, 1,2 m/sn yaklaşır, altına gelir ve sinekle birlikte sürüklenir. 0,3–1 sn sonra halka çıkar: 0,5 sn içinde dokun (Kolay modda 0,9 sn). Halkadan önce dokunmak balığı kaçırır.
  - **Çekişme:** ortak çekişme; alabalıklar takılır takılmaz çırpınır (§5). Çırpınınca sudan sıçrarlar: balığın kendisi (elde gösterilen boyunun 1,5 katı) yay çizerek 0,8 m'den yükseğe sıçrar, havada kıvrılır, halka ve şapırtıyla geri dalar (`FishJump`). Dar derede yay suyun olduğu yöne çizilir, yer yoksa balık yerinde sıçrar. Dere ağzında fark etme ve yaklaşma hızlı olduğu için balık çabuk gelir.
  - **Görünüm:** koyu gövdeli, beyaz dik tüylü (paraşüt sineği: yukarıdan suyun üstünde beyaz bir nokta), kırmızı kuyruklu kuru sinek; telefonda seçilsin diye 0,22 m (şamandıra 0,3, yem 0,24). Suyun yüzünde akıntıya dönük sallanır, sürüklenirken arkasında seyrek küçük halkalar. Halkada sinek suya çekilir; halka, ses, titreşim ve hafif sarsıntı. Elde uzun, ince, kızıl kahve sinek kamışı; misina az sarkar.
  - **Kamera:** dipteki gibi çerçeveler: balıkçı ipucu çubuğunun üstünde kalır, sinek uzaktaysa kamera en çok 1,15 kat uzaklaşır (sinek küçük; eğim şamandıradaki gibi 60°).
  - **Takım:** 3 sinek kamışı (sinek kamışı 1.500 para / rütbe 7 / 10 m / 3★; uzun 4.000 / 9 / 11 m / 4★; usta 9.000 / 12 / 12 m / 5★). 3 sinek (tükenmez): kuru sinek (bedava; alabalık ×1,2), nimf (300, r7; alabalık ×2, tatlısu kefali ×1,5), streamer (900, r8; dere alabalığı ×2,2, alabalık ×1,2). Dükkânda sinekte tekniğe özel sekme "Sinek".
  - **Yatkınlık:** alabalık ve dere alabalığı 1; tatlısu kefali 0,5, kızılkanat 0,3, gümüş balığı 0,2. Dere ağzında kuru sinekle alabalık %59, tatlısu kefali %30, dere alabalığı %7, kızılkanat %5.
  - **Açılış:** rütbe 7'de (dere ağzıyla birlikte) bildirim, Dede "Alabalık sineğe çıkar evlat. Nine sinek kamışı satıyor!" der, teknik düğmesi nabız gibi atar. Dere ağzında sinek ilk seçilince Dede "Akıntıya at, sinek süzülsün. Halka çıkınca VUR!" der; ilk 3 atışta ipuçları: "Sinek akıntıyla süzülüyor... halkayı bekle.", "Altında bir balık var! Halkayı bekle.", "Halka! Hemen VUR!". Dere ağzında başka teknikle balık tutan oyuncuya Dede bir kez "Burada sinek dene evlat. Alabalık akıntıda çıkar." der (bölgenin önerisi, aşağıda).
- ✅ **Kerevit tuzağı (v0.4):**
  - **Kurma:** Takım Çantası'nın altında tuzak satırı (bir teknik değil, bir eylem): ikonu, "Sığ suya bırak: 20 dakikada bir kerevit girer.", kaç tuzağın kurulu olduğu ("1/2 kurulu") ve tek düğme: TUZAK BIRAK, NİNE'DE (tuzağı yok: dükkân Ekstra sekmesinde açılır), HEPSİ KURULU, "Sazlık, kayalık" (bu bölgeye kurulmaz) ya da rütbe kilidi. TUZAK BIRAK'ta balıkçı baktığı yöne en yakın uygun yere atar: sazlık ya da kayalık burun, derinlik en çok 1,2 m, balıkçıya 1,2–3,5 m, öteki tuzaklara en az 2 m. Yer yoksa nedeni bildirilir (tuzağın yok, hepsi kurulu, tuzak sazlıkta ya da kayalıkta kurulur, öteki tuzağa çok yakın, tuzak için çok derin, yakında sığ su yok). Tuzak yay çizerek uçar, suya düşünce halka, ses ve titreşim; "Tuzak kuruldu: 20 dakikada bir kerevit"; ilk tuzakta Dede "Sen yokken de dolar. Turuncu şamandıraya dokun, topla!" der.
  - **Dolma** (`TrapSim`): gerçek saatle, oyun kapalıyken de; 20 dakikada bir kerevit girer, en çok 4 (boşta biriken gelir üst sınırda durur; gelir kuralı 7). İçindekiler tuzak kurulunca zarlanır ve bekler (gelir kuralı 4; tuzağın zarı `trap_serial`'dan); parayla hızlandırma yok. Saat geri alınırsa bir şey kaybolmaz ya da kazanılmaz (yalnızca dayanak yenilenir); ileri alınırsa en çok 4. Oyun her saniye ve öne gelince dolmayı yeniler.
  - **Görünüm:** suda turuncu bir şamandıra (beyaz bant, sırık, küçük kırmızı bayrak; tek ağ, gölgesiz; suyla iner kalkar) ve üstünde 2B rozet: kerevit resmi ve "2/4"; boşken soluk, kerevit varken altın, dolunca yeşil ve nabız gibi atar. Haritada tuzakların küçük işareti.
  - **Toplama:** şamandıraya ya da rozete dokun (yakındaysa hemen; 5 m'den uzaksa balıkçı kıyı yolundan yürür, varınca toplar). Kerevitler kovaya, deftere ve rütbe puanına girer (şans garantisi sayaçları ilerlemez); tuzak yeniden kurulur (içeriği yeniden zarlanır), artan süre sonraki kereviti bekler. En irisi elde gösterilir (kodla kurulan kerevit: kabuk, halkalı kuyruk, kıskaçlar, bacaklar, duyargalar; sırtı kameraya dönük), adının üstünde kaç tane olduğu ("Kerevit ×3"); ilk kerevitte yeni tür kartı (Ersin'in kerevit resmiyle). Kova doluysa toplanmaz ("Kova dolu: kerevitler tuzakta bekliyor", Dede Nine'yi söyler); kova toplarken dolarsa kalanı tuzakta bekler (kayıp yok).
  - **Boş tuzak:** dokununca küçük panel: sıradaki kerevitin kaç dakika sonra gireceği, BEKLE ya da KALDIR (tuzak çantaya döner; henüz girmemiş kerevitler silinir, yeniden kurulan tuzağın içi yeniden zarlanır). Panel açıkken kerevit girerse "Tuzağa bir kerevit girdi!" yazar ve KALDIR TOPLA olur (kerevit girmiş tuzak kaldırılmaz, toplanır). Tuzaktan ilk kerevitin kartı açılana kadar (0,9 sn) dokunuşlar atış ya da yürüyüş olmaz.
  - **Takım:** 3 tuzak, Ekstra sekmesinde tek kart (sıradaki): kerevit tuzağı 150 para / rütbe 3, ikinci tuzak 400 / 3, üçüncü tuzak 1.000 / 5 (8. adımda; önce 250 / 600 / 1.500). Nine alınca "Takım çantandan sığ suya bırak evladım." der.
  - **Kerevit:** Sıradan, 10 para (8. adımda; önce 6), 6–14 cm. Tuzak tablosu sazlıkta ve kayalık burunda; dipte de arada gelir (yeme göre sazlıkta %2,6–5,5, kayalık burunda %4,8–9,2), şamandırayla gelmez.
  - **Açılış:** rütbe 3'te bildirim ("Yeni: kerevit tuzağı!", tuzağın ikonuyla), Dede "Kerevit tuzağa kendi girer evlat. Nine tuzak satıyor!" der, teknik düğmesi nabız gibi atar. Aynı anda bir bölge (rütbe 3'te nilüferli koy) ya da teknik açılırsa Dede önce onu söyler; tuzağın sözü sonraki balıkta (tuzak o zamana dek alınmadıysa).
  - **Sesler:** bırakma (iri plop, tel kafes tıkırtısı, batan kabarcıklar) ve toplama (şıpırtı, damlalar, kerevitlerin tıkırtısı); her birinin titreşimi var.
- ✅ **Dede'nin bölge önerileri** (v0.4; `spots.json` `suggest`): her bölgenin öne çıkan tekniği. Orada başka bir teknikle balık tutana Dede bir kez söyler (tekniğin rütbesi gelmişse; kamışı henüz alınmadıysa oyuncu Nine'den alır). Oyuncu orada önerilen teknikle balık tuttuysa öneri söylenmez:

| Bölge | Öneri | Dede |
|---|---|---|
| Sazlık | dip | "Sazlıkta kadife ile sazan dipte beslenir evlat. Dip dene!" |
| Nilüferli koy | spin | "Nilüferlerde turna pusuda evlat. Spin dene!" |
| Kayalık burun | spin | "Kayalıkta sudak avlanır evlat. Spin dene, dur-kalk yap!" |
| Dere ağzı | sinek | "Burada sinek dene evlat. Alabalık akıntıda çıkar." |
| Derin orta | dip | "Yayın ile mersin derinin dibinde gezer evlat. Dip dene!" |

  İskele koyunun önerisi yok (her şeyden biraz). Öneri, yakalayıştan sonraki sözlerin sırasında kova ve yeni bölge haberinden sonra gelir.
- ✅ **Dede'nin teknik öğütleri** (v0.4): Dede'ye dokununca söylediği 6 öğüdün arasına, rütbesi gelmiş tekniklerin öğütleri açıldıkları sırayla girer (`Elder.tips`): spin "Dur-kalk yap evlat: yırtıcı en çok duran yeme saldırır.", tuzak "Tuzak sen yokken de dolar, ama 4 kereviti geçmez." (sayı kurallardan), dip "Yem sepeti balığı yemin çevresine daha çabuk toplar.", sinek "Alabalık çırpınınca sudan sıçrar. O an bırak, misina kopmasın." Rütbe 1'de öğütler eskisi gibi.
- ✅ **Takım Çantası** (teknik düğmesi): her teknik bir karo: ikonu, adı, nasıl oynandığı, kuşanılmış kamışı ve küçük takımı (makara ve misina her teknikte ortak). Karonun düğmesi: ELİNDE, SEÇ, NİNE'DE (dükkân o tekniğin Kamış sekmesinde açılır), rütbe kilidi ya da (kamışı var ama bu bölgede avlanılmıyorsa) "Dere ağzında". Teknik seçilince bildirim çıkar; gölgeler panel açıkken yeniden doğar.

### 10.4 Dükkân, takım ve para

- **Nine'nin dükkânı:** sekmeler: kamış, makara, misina, iğne, yem, yapay yem ve sinek, şamandıra, ekstra.
  - Her eşyada en çok 2 değer, çubukla gösterilir; şimdiki takımla karşılaştırılır.
  - Rütbe kilidi var.
  - Sade tutulur: araştırmada en çok "seçenek kalabalığı" eleştirildi.
  - ✅ Dalga 1'deki hâli: Nine'ye ya da dükkâna dokununca açılır (kovada balık varsa Kova sekmesi, yoksa en son bakılan sekme). Üstte Nine'nin yüzü ve sözü ("Hoş geldin evladım!", "Güle güle kullan!", "Paran biraz eksik...", "Rütbe 4 olunca gel!", "Eline sağlık!") ve para. Sekmeler: Kova, Kamış, Makara, Misina, İğne (iğne ve şamandıra), Yem, Ekstra (kepçe, sandal ve sıradaki kova: kovalar tek kartta, sahip olunanın bir üstü; Dalga 2; Dalga 3'te sıradaki tuzak da tek kartta). Her sekmede en çok 6 kart (3×2), kaydırma yok.
  - ✅ Kart: ikon (Ersin'in ekipman görseli gelene kadar kodla çizilir), ad, kısa açıklama, değer çubukları (koyu çizgi kuşanılanın yeri; yeşil daha iyi, turuncu daha zayıf; menzil ve kova kapasitesinin sayısı da yazar; kamışta ve misinada çubuk yerine "İri balık" yıldızları: kaç yıldızlı iri balığı taşıdığı, v0.3.1) ve tek düğme: fiyat (al ve tak), TAK, TAKILI, SENDE ya da kilitli rütbe. Para yetmeyen ya da rütbesi tutmayan düğme gri kalır ama basılınca Nine nedenini söyler (kilit sessiz kalmaz). Kuşanılan kartın kenarı yeşil.
  - ✅ Yem kartında çektiği balıklar ve bir gölgenin o balık olma şansı solucanla ve bu yemle ("Levrek %22 → %41"; defterdeki oranın aynısı), elindeki sayı ve paket boyu. Takılı yem yeniden alınabilir.
  - ✅ Sesler: satın almada tezgâh zili, kuşanmada tıkırtı, satışta para şıkırtısı; her birinin titreşimi ve Nine'nin sözü var.
  - ✅ **Dalga 3:** başlıkta, Nine'nin sözüyle para arasında teknik düğmeleri (şamandıra, spin, dip, sinek). Kamış sekmesi ve tekniğe özel sekme bakılan tekniği gösterir: şamandırada "İğne" (iğne ve şamandıra), spinde "Yapay yem", dipte "Kurşun" (kurşun ve yem sepeti), sinekte "Sinek". Makara ve misina her teknikte ortak. Kilitli teknik de görünür, düğmesinde rütbesi yazar; dokununca Nine ne zaman satacağını söyler. Bir tekniğin ilk kamışı alınınca teknik ele geçer. Uzun sekme adı (Yapay yem) küçülerek sığar. Panelin boyu değişmez (telefonda 993 birim).

| Kategori | Ne yapar | Kademe |
|---|---|---|
| Kamış (teknik başına) | menzil, iri balık taşıma (yıldız), güç (sarma) | 3 |
| Makara | sarma hızı, fren (gerilim tepesini kırpar) | 4 |
| Misina | iri balık taşıma (yıldız), dayanım (kopma süresi), görünmezlik (ürkek balık) | 4 |
| İğne | tutma (kaçışı azaltır) | 3 |
| Yem | tür çekimi; tükenir, solucan bedava ve sınırsız | 6 |
| Yapay yem, sinek | yırtıcı ve alabalık çekimi; kalıcı | 6 + 3 |
| Şamandıra | hassasiyet (VUR süresi +), görünürlük | 3 |
| Ekstra | kepçe (son anda bir kaçışı kurtarır), sandal, tuzak, kova kapasitesi (fener satılmaz: ilk gece Nine'nin hediyesi ✅) | — |

- ✅ **Takım çantası:** her teknik için kuşanılmış bir set (kamış ve küçük takım); makara ve misina ortak (kayıt v4: `loadouts.shared`). Teknik düğmesiyle geçilir (§10.3).
- **Kova ve satış:**
  - Tutulan balık kovaya girer; dükkânda "hepsini sat" yapılır (Kazı'nın sırt çantası düzeni). ✅ Kova sekmesinde tür başına bir satır (sayı, değer), altta toplam ve HEPSİNİ SAT.
  - Kova dolunca Dede uyarır ✅ (kova her dolduğunda: "Kovan doldu evlat! SAT'a bas ya da kovaya dokun, göle bırak.") ve olta atılmaz: eylem düğmesi yeşil SAT olur, basınca Nine'ye gidilir (v0.4.1); kova kapasitesi dükkândan büyür.
  - Her türün en iyisi akvaryuma konabilir (§10.6).
- ✅ **Bırakma** (Dalga 4): bırakılan balık para vermez, yalnızca göl sevgisi verir (rütbe puanı balık tutulunca gelmiştir).
  - **Kova paneli:** sol üstteki kovaya dokununca açılır (olta boştayken ve balık eldeyken de; dokunma kutusu 122,
    olta sudayken dokunuş almaz). Tür başına bir satır: resmi, adı, altında "×3", nadirliği ve bir balığın sevgisi
    ("♥ +5"), değeri, BIRAK (türün en küçüğü göle döner). Bir sayfada 6 satır, fazlası sonraki sayfada ("Sayfa 1/2 »"
    düğmesi; panelin boyu aynı). Altta HEPSİNİ BIRAK (çocuk yanlışlıkla basmasın: ilk dokunuş "Emin misin?", 3 sn
    içinde ikincisi bırakır; hızlı çift dokunuş saymaz), toplam değer ve SAT (Nine'nin tezgâhı, Kova sekmesi).
    Başlıkta göl sevgisinin seviyesi ve çubuğu: bıraktıkça dolar. Telefonda küçülmeden sığar. Kova boşalınca Dede'nin
    "kovan doldu" sözü biter.
  - **Kartta "Göle bırak":** yeni tür, rekor ya da nadir balık kartında ikinci düğme (≥122): az önce kovaya giren
    balık göle döner, "Çapak göle döndü". Koruma altındaki türlerde tek düğme zaten "Göle bırak"; dolu kovaya gelen
    balık da göle döner (sevgi verir).
- **Para:** yalnızca oynayarak kazanılır, gerçek parayla asla satılmaz. Bu yüzden oranı değiştiren yem ve yapay yem satılabilir (§11).
- **Rütbe 1–20:** rütbe puanı av ve isteklerden gelir; bölge ve takım kilitlerini açar.
- **Denge hedefleri** (denge botunun korkulukları):

| Hedef | Süre |
|---|---|
| nilüferli koy (rütbe 3) | 8–12 dk |
| kayalık burun (rütbe 5) | 20–30 dk |
| dere ağzı (rütbe 7) | 45–60 dk |
| rütbe 9 (sandal Nine'de) | 80–110 dk |
| sandal | 90–180 dk |
| spin takımı ✅ | 4–10 dk |
| tuzak ✅ | 10–20 dk |
| dip takımı ✅ | 15–35 dk |
| sinek ✅ | 60–120 dk |
| bütün kademeler ✅ | 8–15 saat |

- ✅ **Denge botu** (`SessionSim`): oyunun kurallarını aynen kullanır (oranlar ve şans garantisi `CatchOdds`, boy `FishTable`, çekişme `ReelModel` + tepkili oyuncu botu, kova, rütbe, satış), yalnızca zamanı ve el becerisini taklit eder. Süreler `data/sim.json`'dan; atış, balığın gelişi, dürtmeler ve çekişme uzaklığı `tools/session_timing.gd` ile gerçek `FishingSession`'dan ölçülür (insan gibi şaşarak nişan alan bot). Dalga 1'deki ölçüm (eski göl, başlangıç takımı): ısırmaya ortalama 9 sn (atış ve geri sarma dahil), dürtmeler 2,8 sn, çekişme 5,2 sn, takılma uzaklığı 4,5 m; saatte 225 av (satışsız). Büyük gölde bölge başına: saatte 204–251 av (sazlık ve dere ağzında en çok, derin ortada en az). İnsan hatası tahmin: ısırmaların %15'i kaçırılır.
- ✅ **Dalga 1 ölçümü** (iskele koyu, 3 seed): saatte yaklaşık 3.100 para ve 200 av; rütbe 20'ye 5 saatte varılıyordu.
- ✅ **Bölgeli denge botu** (Dalga 2): kıyı bölgesini oyuncu gibi seçer. Önce gidilmemiş açık bölgeye gider (yeni bölge açılınca hemen), sonra defterde tutulmamış türü en çok olana, sonra balık başına en çok kazandırana. Sandalı rütbesi yetince öncelikle alır, parası yetene kadar başka şey almaz; sonra kovaların yarısını derin ortada doldurur (`boat_share`, tahmin). Bölge değiştirmek ve satmak için iskeleye dönmek 6 sn sürer (`travel_s`: harita, dokunuş, kararma). Bölge başına süreler `session_timing.gd --zone=` ile ölçülür (`sim.json` "zones").
- ✅ **Rütbe eğrisi uzadı:** bölgeler rütbe 3–9'da açıldığı için eşikler 0, 60, 300, 600, 950, 1.400, 2.050, 2.900, 4.000, 5.000 … 26.000 (rütbe 20). Eski kayıtta rütbe ve rütbedeki ilerleme korunur: kayıt sürümü 3, puan yeni eğriye taşınır (`SaveData.remap_xp`). Sandal 3.500 para.
- ✅ **Dalga 2 ölçümü** (`tools/economy_report.gd -- --hours=12 --seeds=6`; gölgeler yalnızca avlanılan bölgede doğar, derin ortanın uzak kıyı şeridi bölgesiz): saatte yaklaşık 6.000 para ve 190 av. Zamanın ~%47'si dere ağzında, ~%47'si derin ortada geçiyor (en çok kazandıran iki yer); öteki kıyı bölgelerine yeni türleri tutmak için gidiliyor. Rütbe 9 hedefin (80–110 dk) biraz önünde: dere ağzında balık çabuk geliyor; Dalga 3'te eğri aynı kaldı (teknikler bugünkü rütbelerde açılır). Korkuluklar `tests/test_session_sim.gd`'de (200 dk, 3 seed); "yeni bölge öncekilerden az kazandırmaz" `test_economy.gd`'de.
- ✅ **v0.3.1 ölçümü (iri balık takım ister):**
  - Saatte ~5.850 para (−%3) ve 190 av.
  - Rütbe 9: 76–92 dk (önce 69–81). Sandal: 111–150 dk (önce 104–132).
  - Bot Dede'nin öğüdüne uymaz, takımı yine en ucuzdan alır. Cam elyafı kamış ~22–35. dakikada, karbon kamış ve örgü misina ~3. saatte geliyor. O zamana dek iri türlerin 5★'ları (~%6) kaçıyor; öğüde uyan oyuncu daha erken alır.
  - Mersinin ilk tutuluşu şansa çok bağlı (20 seed: 125–276 dk; eski kodda da bir seed 288). Korkuluk 100–300 dk, 310 dakikada ölçülür.

v0.3.1 ölçümü (Dalga 2 dengesi) ve v0.4 ölçümü (Dalga 3 dengesi, 8. adım ve kapanış düzeltmeleri: `economy_report.gd -- --hours=16 --seeds=6`); korkuluklar bugünkü (`tests/test_session_sim.gd`).

| Olay (ilk kez) | v0.3.1 (dk) | v0.4 (dk) | Korkuluk |
|---|---|---|---|
| ilk satış | 2–3 | 2–3 | ≤ 5 |
| ilk alışveriş | 3–8 (misina) | 4–10 (spin kamışı) | ≤ 10 |
| rütbe 2 / 3 / 5 / 7 / 9 | 1–3 / 10–14 / 21–31 / 45–56 / 76–92 | 1–3 / 9–11 / 22–28 / 49–58 / 79–94 | ≤ 5 / 5–15 / 15–35 / 38–65 / 60–120 |
| rütbe 10 / 15 / 20 | 90–112 / 193–225 / 334–375 | 92–105 / 187–202 / 317–331 | — |
| ilk gidiş: sazlık / nilüferli koy / kayalık burun / dere ağzı | 2–3 / 10–14 / 22–31 / 45–56 | 2–3 / 9–11 / 22–28 / 49–58 | — / 5–15 / 15–35 / — |
| gölün 5 türü / 11. tür / mersin (ilk Efsanevi, 16. tür) | 2–4 / 25–37 / 135–276 | 2–4 / 21–33 / 135–241 | ≤ 30 / — / 100–300 |
| spin kamışı ve ilk spin atışı | — | 4–10 | 4–10 / 4–12 |
| ilk tuzak / tuzaktan ilk kerevit | — | 10–17 / 31–37 | 8–20 / 28–55 |
| dip kamışı ve ilk dip atışı | — | 19–33 | 15–35 / 15–40 |
| sinek kamışı ve ilk sinek atışı | — | 64–89 | 60–120 / 60–125 |
| naylon misina, döner kaşık | 3–8 | 9–22 / 17–34 | — |
| makara, iğne, şamandıra (ilk kademe) | 10–26 | 29–67 | — |
| büyük kova | 30–42 | 43–54 | 25–70 |
| cam kamış | 22–35 | 52–87 | 10–100 |
| ikinci tuzak / üçüncü tuzak | — | 140–152 / 201–212 | — |
| yem sepeti, nimf, floro misina | — | 134–161 | — |
| hızlı makara, kepçe, büyük iğne | 40–85 | 151–187 | kepçe 120–220 |
| sandal (3.500) | 111–150 | 131–144 | 90–180 |
| derin ortada ilk av | 111–150 | 134–147 | — |
| orta spin kamışı, güçlü makara, parlak şamandıra, balık filesi | 126–185 | 190–264 | — |
| örgü misina, uzun dip kamışı, karbon kamış, usta florokarbon | 171–250 | 270–341 | — |
| ağır spin kamışı, altın kaşık, usta makarası, uzun sinek kamışı | — | 340–509 | — |
| büyük file, usta dip kamışı | 261–428 | 455–542 | — |
| altın örgü, usta sinek kamışı | 261–428 (altın örgü) | 584–755 | — |
| dev file (10.000; önce 15.000) / altın makara (10.000; önce 15.000) | 665–703 / 528–559 | 613–752 / 810–834 | — |

- **Değerlendirme:** ilk saat dolu: yeni bölge yaklaşık 12, 26 ve 50. dakikada, araya alışverişler giriyor. Sandal rütbe 9'dan sonra 35–50 dakikalık bir birikim hedefi; alınınca balık başına kazanç ~1,7 katına çıkıyor (derin ortada ~40 para, dere ağzında ~24). Rütbe 20'ye ~5,9 saatte varılıyor (Dalga 1'de 5). Şamandıra takımının hepsi 12 saatte alınıyordu (dev file ~11. saatte). (v0.3.1 değerlendirmesi; Dalga 3 dengesi aşağıda.)
- ✅ **Dalga 3, spin ölçümü:**
  - **Oturum süreleri** (`tools/session_timing.gd -- --technique=spin`; bot gölgenin ötesine atar, basılı tutup yemi getirir, peşine düşünce 0,35–0,8 sn'lik dur-kalk yapar):
    - ısırmaya 5,4 sn (şamandırada 9,4): yemin balığa gelişi 1,5 sn, izleme 1,7 sn;
    - atışların %98'i saldırıyla biter, saldırıların %44'ünde balık kendiliğinden takılır;
    - çekişme 8,1 sn (şamandırada 5,3: yırtıcılar daha uzaktan ve sert çeker), takılma uzaklığı 5,7 m;
    - satışsız saatte 227 av (şamandırada 208).
  - **Denge botu:** yeni tekniğin ilk kamışını öncelikle alır, sonra tekniği dener. Bölge seçiminden sonra elindeki tekniği seçer: önce defterde olmayan, o bölgede gelen türü en çabuk getiren teknik, sonra dakikada en çok kazandıran. Teknik değiştirmek 3 sn (`switch_s`). Süreler `sim.json` `techniques`.
  - **Sonuç** (`economy_report.gd -- --hours=12 --seeds=6`):
    - spin kamışı ve ilk spin atışı 4–10. dakikada;
    - saatte ~5.900 para ve 192 av (v0.3.1'deki gibi); rütbe 20'ye 6,0–6,5 saatte;
    - mersin 134–184. dakikada (bot derin ortada mersini şamandırayla arar).
  - **Değerlendirme:** defter dolunca bot zamanının %70–80'ini spinde geçiriyor: yırtıcılar dakikada şamandıradan çok kazandırıyor. Dip ve sinek gelince 8. adımda (Denge) teknikler birbirine göre yeniden ayarlandı (aşağıda).
- ✅ **Dalga 3, dip ölçümü:**
  - **Oturum süreleri** (`tools/session_timing.gd -- --technique=bottom`; bot dokunduğu yöne atar, koklamada dokunmaz, koşuda VUR'a basar, başlangıç takımıyla):
    - ısırmaya 15,8 sn (şamandırada 9,4, spinde 5,4): balığın gelişi 9,3 sn, koklama 3,5 sn;
    - atışların %97'si ısırmayla biter; takılan balığın %11'i kopar (iri sazanlar ve yayın, başlangıç misinası);
    - çekişme 14,3 sn (şamandırada 5,3), takılma uzaklığı 12,5 m;
    - satışsız saatte 100 av (şamandırada 208): az ama iri balık.
  - **Sonuç** (`economy_report.gd -- --hours=12 --seeds=6`):
    - dip kamışı ve ilk dip atışı 22–31. dakikada (hedef 15–35); yem sepeti 65–88. dakikada;
    - saatte ~5.600 para ve 187 av; rütbe 20'ye 6,3–6,8 saatte (spinle 6,0–6,5: bot dip takımına da para ayırıyor);
    - cam kamış 48–62. dakikada (dip kamışından sonra), kepçe 138–172. dakikada.
  - **Değerlendirme:** bot dipte zamanının yalnızca %1–3'ünü geçiriyor: aynalı sazanı tutunca dakikada daha çok kazandıran spine dönüyor. Dipin balık başına değeri yüksek ama saatte avı yarı yarıya; 8. adımda (Denge) dipin süreleri ve yatkınlıkları tekniklerle birlikte ayarlandı (aşağıda).
- ✅ **Dalga 3, sinek ölçümü:**
  - **Oturum süreleri** (`tools/session_timing.gd -- --technique=fly --zone=stream_mouth`; bot menzildeki en yakın gölgenin 2,5 m akıntı yukarısına atar, sinek balığa doğru sürüklenir; halkadan 0,45 sn sonra VUR):
    - ısırmaya 4,9 sn (şamandırada 9,4, spinde 5,4): balığın gelişi 1,9 sn, halkaya 0,7 sn;
    - çekişme 5,6 sn, takılma uzaklığı 4,4 m;
    - satışsız saatte 287 av (şamandırada 208): bot halkayı hiç kaçırmıyor. Fark etmeyi daraltmak (140° / 3,5 m → 110° / 3 m) ölçümü değiştirmedi: sinek balığa doğru sürüklendiği için balık onu hep görüyor.
    - İnsanın kaçırma payı sinekte %25 (öteki tekniklerde %15; tahmin: VUR anı 0,5 sn, halkadan önce dokunmak kaçırır; `sim.json` `techniques.fly.miss_ppm`). Bot tekniği seçerken bu payı da hesaba katar.
  - **Sonuç** (`economy_report.gd -- --hours=12 --seeds=6`):
    - sinek kamışı ve ilk sinek atışı 83–99. dakikada (rütbe 7: 56–71; hedef 60–120);
    - saatte ~5.700–5.950 para ve ~187 av (önce ~5.600–5.900 ve 187); rütbe 20'ye 5,8–5,9 saatte (önce 6,3–6,8: alabalıklar Nadir, balık başına rütbe puanı çok);
    - kepçe 170–187. dakikada (sinek kamışına da para ayrılıyor); bütün türler 153–276. dakikada.
  - **Değerlendirme:** bot zamanının ~%44'ünü sinekte, ~%44'ünü spinde, %7–16'sını şamandırada, %1–3'ünü dipte geçiriyor. Dere ağzında sinekle balık başına değer şamandırayla aynı (~25 para), ama balık daha çabuk geliyor. 8. adımda (Denge) teknikler birbirine göre ayarlandı (aşağıda).
- ✅ **Dalga 3, tuzak ölçümü:**
  - **Denge botu:** ilk tuzağı öncelikle alır (Dede haber verir, düğme atar); sonraki tuzaklar sıradan takım gibi. Her satıştan sonra (kova boşken) kerevit girmiş tuzakları toplar, boştaki tuzağı sazlığın atış noktasının yakınına bırakır (yer kalmazsa kayalık buruna); tuzağın bölgesine gitmek `travel_s`, tuzak başına 4 sn (`trap_s`, tahmin). Tuzaklar botun oyun süresiyle dolar.
  - **Sonuç** (`economy_report.gd -- --hours=12 --seeds=6`):
    - ilk tuzak 13–17. dakikada (hedef 10–20), tuzaktan ilk kerevit 35–41. dakikada; ikinci tuzak ~3. saatte, üçüncüsü ~5. saatte;
    - 12 saatte 79–81 kerevit (saatte ~7);
    - saatte ~5.400–5.750 para ve 180 av (önce ~5.700–5.950 ve 187); rütbe 20'ye 6,0–6,2 saatte.
  - **Değerlendirme (ilk ölçüm; 8. adımda kerevit 10 para, ilk tuzak 150):** tuzak kendini çok geç öder (kerevit 6 para, ilk tuzak 250) ve ucuz kerevit kovada yer kaplıyor: saatteki para %3–5 düştü. 250 paralık tuzak ~13. dakikada alınınca alışveriş birkaç dakika kaydı, büyük kova rütbe 7'ye kaldı ve sinek kamışına biriktirirken 95–103. dakikaya düştü (korkuluk 15–110). 8. adımda (Denge) kerevitin değeri, tuzağın fiyatı ve büyük kovanın sırası ayarlandı (aşağıda).
- ✅ **Dalga 3 dengesi (v0.4, 8. adım):** önce yatkınlıklar, sonra süreler, en son fiyatlar ayarlandı (rütbe eğrisi aynı).
  - **İlk ölçüm** (Dalga 3'ün 5 tekniğiyle, 16 saat, 6 seed): bot zamanının %41–49'unu spinde, %44–46'sını sinekte, %0,5–2'sini dipte geçiriyordu (spin derin ortada da en çok kazandırıyordu). Büyük kova 95–103, dev file 16 saatte hiç alınmadı; bütün takım ~100.500 para.
  - **Yatkınlık:** dipte yayın 1 → 1,5 (dip yayının tekniği), çapak 1 → 0,5. Spinde turna 0,8 → 1,4 ve sudak 0,9 → 2 (nilüferli koyun ve kayalığın yırtıcıları), yayın 0,25 → 0,1. Sazlıkta aynalı sazan 6 → 12 (yalnızca dipte gelir; şamandıranın oranları ve kataloğu değişmedi). Nimf alabalığı ×1,6 → ×2 çeker (tatlısu kefalini de çektiği için alabalığın payını düşürüyordu).
  - **Dipin süreleri:** yemin kokusu 1 sn sonra yayılır (önce 2), gölgeler takıma 3,5 kat hızlı yüzer (2,5), 0,8 m/sn yaklaşır (0,5); koklama arası 0,6–1,3 sn (0,8–1,8). Dip kamışlarının gücü 0,25 / 0,3 / 0,3 (önce 0,15 / 0,2 / 0,25; üst sınır 0,3). Ölçüm (`session_timing.gd -- --technique=bottom`): ısırmaya 12,2 sn (15,8), çekişme 13,2 sn (14,3), satışsız saatte 117 av (100). Sazlıkta ve derin ortada su yakın, balık daha yakında takılır (8,3–10,6 m ve 5,2–12,7 m): saatte 147 ve 145 av, çekişme 9,1 ve 10,6 sn (`sim.json` `techniques.bottom.zones`). Spinde takılma ölçülmedi: bot yemi hiç bekletmiyor (sazlıkta, nilüferli koyda ve kayalıkta `session_timing.gd -- --zone=` ile 0 takılma).
  - **Fiyat:** kerevit 6 → 10 para; tuzaklar 250 / 600 / 1.500 → 150 / 400 / 1.000; altın makara ve dev file 15.000 → 10.000 (bütün takım ~89.750).
  - **Denge botu:** sıradaki kova öncelikli ama onun için biriktirilmez: parası yetiyorsa öteki takımdan önce alınır (oyuncu sık dolan kovayı büyütür).
  - **Kural** (`test_economy.gd`): Dede'nin bölgede önerdiği teknik orada şamandıradan az kazandırmaz. Dakikada ortalama para (`SessionSim.rate`: oran × takılan balığın ortalama değeri; boy zarının örnekleriyle, takımın taşıyamadığı iri balık kaçar; `sim.json`'daki bölge süreleriyle), iki teknikte aynı kademe takımla: öneri ilk söylendiğinde (tekniğin ilk kamışı, şamandırada bambu; naylon misina: dip kamışından önce alınır, `test_session_sim`), sonra iki teknikte de 4★ ve 5★ taşıyan en ucuz kamışla. İlk kademe:

| Bölge | Öneri | Önerilen teknik | Şamandıra | Spin | Dip | Sinek |
|---|---|---|---|---|---|---|
| İskele koyu | — | — | 36,5 | 57,7 | 44,1 | — |
| Sazlık | dip | 34,9 | 28,2 | 59,8 | 34,9 | — |
| Nilüferli koy | spin | 61,6 | 56,3 | 61,6 | 40,6 | — |
| Kayalık burun | spin | 61,9 | 59,6 | 61,9 | 62,5 | — |
| Dere ağzı | sinek | 87,2 | 62,1 | 65,5 | 73,9 | 87,2 |
| Derin orta | dip | 131,7 | 92,0 | 86,6 | 131,7 | — |

  4★ kademede (cam elyafı, orta spin, dip ve uzun sinek kamışı) önerilen teknik / şamandıra: sazlık 34,9 / 33,6, nilüferli koy 72,9 / 68,1, kayalık burun 74,0 / 70,8, dere ağzı 90,6 / 74,5, derin orta 131,7 / 115,8; 5★ kademede de önde. 8. adımdaki ilk hesap orta boyun değerini kullanıyor, iri balık kaybını saymıyordu (kapanış incelemesi): kayıp sayılınca naylon misinasız (3★) sazlıkta dip şamandıranın %99'unda kalıyor; bot naylon misinayı 9–22. dakikada, dip kamışını 19–33. dakikada alıyor (6 seed'in birinde misina 3 dk sonra).
  - **Sonuç** (`economy_report.gd -- --hours=16 --seeds=6`): saatte ~6.550–6.850 para ve ~167 av (önce ~5.900–6.200 ve 187: dip az ama iri balık getirir); rütbe 20'ye 5,3–5,5 saatte (önce 6,0–6,2); bütün takım 13,5–13,9 saatte (hedef 8–15). Bot zamanının ~%57'sini dipte (derin ortada), ~%36'sını sinekte (dere ağzında), ~%3–5'ini spinde, ~%1–3'ünü şamandırada geçiriyor; spin rütbe 2–7 arasında kıyı bölgelerinde, şamandıra yeni türleri tutmak için. Tuzaklar 16 saatte ~123 kerevit.
  - **Değerlendirme:** her tekniğin öne çıktığı bir yer var; spin sazlıkta ve iskele koyunda da güçlü (yırtıcılar), oyunun sonunda kıyının en iyisi dere ağzında sinek, derin ortada dip. Bot spinde yemi hiç bekletmediği için takılmayı ölçmüyor; insan için sazlık ve kayalık spinde biraz daha yavaş.
- ✅ **Dalga 4, vakit ve hava ölçümü** (1. adım; `economy_report.gd -- --hours=16 --seeds=6`): denge botu oyun saatini
  sürer (satış, teknik değiştirme ve haritadan geçiş saati ilerletmez: oyunda panel ve kararma saati durdurur), her
  atış o anki vakit, hava ve sevgiyle; vakit değişince bot bölgesini ve tekniğini yeniden seçer (oyuncu gibi: gece
  Ay Turnası için nilüferli koya); yağmurda balık 0,84 kat sürede gelir (`session_timing.gd -- --weather=rain` aynı
  seed'lerle açık havada da ölçer: geliş 4,62 → 3,88 sn, satışsız saatte 216 → 219 av; `sim.json`
  `weather.rain_approach`). Sonuç: saatte 6.717–7.333 para (önce 6.557–6.836: ~+%4) ve 165–167 av (önce 166–168).
  Vakitlere zamanın ~%25'i. Ay Turnası ilk kez 26–119. dakikada. Rütbe 9'a cam kamıştan önce varan bot önce sandala
  biriktirir: cam kamış 54–150. dakikada (korkuluk 160'a genişledi; Dalga 3'te 52–87). Korkuluklar yeşil.
- ✅ **Dalga 4, tut-bırak ve çöp ölçümü** (3. adım; `economy_report.gd -- --hours=16 --seeds=6`): denge botu rütbe 9'dan
  sonra satıştan önce değeri 5 parayı geçmeyen balıkları göle bırakır (`sim.json` `release_value_max`,
  `release_from_rank`), dipte ve tuzakta çıkan çöpü toplar. Baştan bırakan bot erken alışverişleri geciktiriyordu
  (ilk satışların çoğu ucuz balık: bir seed'de büyük kova 103. dakikada, korkuluk 25–70); oyuncu da önce takım için
  her şeyi satar. Sonuç: saatte 6.835–7.214 para (önce 6.717–7.333) ve 164–167 av; erken alışverişler ve rütbeler
  aynı; 16 saatte 210–257 balık bırakıldı, 56–75 çöp toplandı (tuzakta çöpün payı yeni kerevit sayısıyla: önce sık
  toplayan bot 73–95 buluyordu). Göl sevgisi 2'si 26–119. dakikada (ilk Ay Turnası ya da rütbe 9), 6'sı (altın
  hamur) 145–226. dakikada (rütbe 13–16; korkuluk 120–240), 10'u 312–434. dakikada. Dede'nin isteklerinin sevgisi
  (4. adım) 6'yı finalin rütbesine (12–14) çekmeli: 4. adımda ölçülür.
- ✅ **Dalga 4, isteklerin ölçümü** (4. adım; `economy_report.gd -- --hours=16 --seeds=6`): denge botu yeni günde boş
  yuvaları doldurur (Bugün paneline bakmak `sim.json` `request_s` 5 sn, saat durur), istekleri kovalamaz (bölge ve
  teknik seçimi aynı), günde bir dünden kalan bir isteği değiştirir (önce hiç ilerlemeyeni, sonra en eskisini;
  yağmurlu günde yağmur isteğini değil; yalnızca hiç ilerlemeyeni değiştiren bot bir seed'de yarım kalan isteklerle
  tıkanıyordu: 16 saatte 22 istek); ucuz balık bıraktığı rütbeden (9) sonra bırakma isteğini kovadaki en ucuz
  balıklarla bitirir (her rütbede bırakan bot erken alışverişleri geciktiriyordu: büyük kova bir seed'de 83.
  dakikada, ilk çöp 133. dakikada). Sonuç: saatte 4,0–4,5 istek (16 saatte 64–72, 23–26 değiştirme); ilki 6,6–17,5.
  dakikada, onuncusu 156–216. dakikada. İsteklerin parası kazancın %6,9–8,0'i: saatte 7.331–7.661 para (önce
  6.835–7.214), 310. dakikada 4.948–5.394 (korkuluk 6.500); 163–166 av. Erken rütbeler ve alışverişler aynı, rütbe
  20 4,9–5,3 saatte. Göl sevgisi 6'sı 137–227. dakikada (önce 145–226): istekler onu az öne çeker; finalin öteki
  şartları (mektuplar, harita parçaları, altın isteklerin sevgisi) 5. adımda.
- ✅ **Dalga 4, Gölün Sırrı'nın ölçümü** (5. adım; `economy_report.gd -- --hours=16 --seeds=6`): denge botu şişe çıkınca
  bölgesine gider, alır (`sim.json` `bottle_s` 4 sn) ve mektubu okur (`letter_s` 30 sn, saat durur), sonra avlandığı
  bölgeye döner; altın istek gelince Bugün paneline bakar; altın av isteğini vakti gelince kovalar (akşam nilüferli
  koyda turnayı en çok getiren teknikle, gece derin ortada diple), altın bırakma isteğini günlük bırakma isteği gibi
  satıştan önce en ucuz balıklarla bitirir; göl sevgisi 6'da sıradaki satışta Nine'den altın hamuru alır. Sonuç:
  mektuplar 9,0–12,2 / 16,9–21,2 / 35,5–43,0 / 62,6–72,7 / 92,4–99,5 / 126–135. dakikada; parçalar 48,5–51,6 (ilk altın
  istek üçüncü mektupla gelir, akşamı bekler) / 63,8–90,7 / 94,1–101,8 / 127–151; altın hamur 140–188; final hazır
  151–188. dakikada (rütbe 13–14; hedef bot ~3 sa, insan 5–6 sa). Altın isteklerin parası (dördü ~900) kazancı az
  artırır: 310. dakikada saatte 5.141–5.777 para (önce 4.948–5.394; korkuluk 6.500), 16 saatte 7.332–7.807. Günlük
  istekler saatte 3,7–4,4 (altın istekler bu sayaca girmez); botun seyri değiştiği için onuncu günlük istek 97–248.
  dakikada (ortalama aynı, ~180; korkuluk 80–300).
- ✅ **Dalga 4, finalin ölçümü** (6. adım; `economy_report.gd -- --hours=16 --seeds=6`): denge botu final gecesinde gece
  olunca sandalla X'e gider, dibe atar; Bekçi gelir (`sim.json` `keeper_s` 8–14 sn), tepkili botla dalışlarıyla
  çekişir, göle döner; bitiş filmi ve jenerik `ending_s` 65 sn (saat durur), gece bitmediyse saat sonraki sabaha.
  Final hazır 151–188. dakikada (değişmedi): dördüncü parça gece derin ortada geldiği için bot çoğunlukla aynı gece
  X'e geçer, Bekçi 1–1,5 dakika sonra göle döner; final gündüz hazır olursa geceyi bekler (bir seed'de 188 → 209). Bekçi
  152–209. dakikada (korkuluk 120–270; insan için ~5–6 saat). Kazanç aynı: 16 saatte saatte 7.436–7.826 para, 163–167 av.
- ✅ **Kova dolunca SAT** (v0.4.1; Ersin: "kova doluyken balık tutmaya izin vermeyelim, oyun dükkâna yönlendirsin"): kova doluyken atılmaz; eylem düğmesi yeşil SAT olur, basınca Nine'nin tezgâhına geçilir (yakındaysa dükkân hemen açılır), dükkân Kova sekmesinde açılır. Önceden dolu kovaya gelen balık göle dönüyordu. Denge botu da atıştan önce satar (satıştan sonra toplanan tuzak kovayı doldurabiliyordu): 16 saat × 6 seed'de saatte 6.557–6.836 para ve 166–168 av, rütbe 20'ye 5,3–5,5 saatte, bütün takım 13,5–13,9 saatte; sayılar değişmedi. Korunmayan her türün değeri 0'dan büyük (`test_session_sim`): değersiz bir tür kovaya girseydi kova satışla boşalmaz, oyuncu atamazdı.
- ✅ **Yemler** para kazandırmak için değil, istenen türü (defter, rekor, ileride istekler) aramak içindir. Her yem kendi türünün şansını belirgin artırır (iskele koyunda kurtçuk levrek %18 → %32 ve gümüş balığı %14 → %20, mısır sazan %20 → %43, karides yayın %4 → %10 ve turna %8 → %17; sazlıkta mısır kadife %22 → %30; nilüferli koyda boili altın sazan %6 → %9,6). Ucuz yemler balık başına ~1,5–2 para; karides balık başına 10 para ve ortalama değeri solucandan yüksek olduğu için aşağı yukarı başa baş. Bütün oranlar ve balık başına ortalama değer [`balik-katalogu.md`](balik-katalogu.md)'de (`tools/fish_catalog.gd` üretir).

### 10.5 Canlı dünya

- **Oyun saati** ✅ (Dalga 4, 1. adım; `DayClock`, `WorldClock`):
  - 24 dk = 1 gün: sabah, öğle, akşam ve gece 6'şar dk. 1 gerçek sn = 1 oyun dakikası; yeni oyun sabah 06:00'da.
  - Saat yalnızca oynarken akar (kayıtta oynanan saniye `clock_s`); uygulama kapalıyken, bir panel açıkken, filmde ve
    ekran kararırken durur, ceza yok. Kart açıkken akar.
  - Vakit değişince kısa bildirim ("Akşam oldu", vaktin ikonuyla) ve kayıt.
  - ✅ **Dede'yle çay** (2. adım; "Bugün" panelinde ÇAY İÇ): ekran kararır, saat sonraki vaktin başına geçer
    (oranlar ve garanti yeni vakitle), ekran açılınca vaktin bildirimi. Dede balıkçının 8 m yakınındaysa kamera
    2 sn ona yaklaşır; Dede çayın sözünü, ardından (ilk kezse) yeni vaktin sözünü söyler. Ücretsiz (zaman atlama parayla satılmaz,
    gelir kuralı 3). İki çay arasında en az bir balık (ilk çaydan önce de): yoksa düğme pasif, "Önce bir balık
    tut, sonra çay içeriz." Böylece vakit atlamak bir ritüel kalır; günler art arda atlanıp hava ve istekler
    çevrilemez (`WorldState.can_tea`, kayıtta `tea_at`).
  - Gerçek saat kullanılmaz: hep aynı saatlerde oynayan da her vakti görür, çocuk gece balığı için uyanık kalmaz.
- **Hava** ✅ (`Weather`): her oyun günü için tohumlu (seed'li): açık %55, bulutlu %20, yağmur %15, sis %10.
  - İlk oyun günü hep açık. Sisli günde sis yalnızca sabah ve gece, öğle ve akşam bulutlu.
  - Yağmurlu gece fırtınadır (ayrı bir hava değil): en az 12 sn arayla yumuşak şimşek ✅ (yanıp sönmez), biraz
    sonra uzak gök gürültüsü ✅ (§9). Vaktin ve havanın görünüşü §8.
  - ✅ İlk gece Nine fener hediye eder ("Nine sana bir fener verdi!", Dede: "Nine fener yolladı evlat! Gece
    balığı bir başkadır."): geceleri balıkçının çevresinde 6 m sıcak ışık. Dükkân ve denge değişmez.
  - Yağmur ısırmayı artırır: gölgeler takımı 1,3 kat uzaktan fark eder ve 1,25 kat hızlı yaklaşır (her teknikte;
    şamandıranın dürtme zamanlaması değişmez). Ölçüm: balık 0,83 kat sürede gelir.
  - Hava önceden belli (gelir kuralı 4): "Bugün" panelinde bugünün ve yarının havası (yağmurlu günde "Gece
    fırtına", sisli günde "Sabah ve gece").
  - Vakit ve hava türlerin oranını değiştirir (§6); gece Ay Turnası'nın, yağmurlu gece Kocabaş'ın tek zamanı.
- **Göl sevgisi:**
  - **Kaynaklar:** bırakılan balık (kademeye göre 1/2/5/12/40/100) ✅, toplanan çöp (3; paslı anahtar 5; §6) ✅,
    istekler.
  - ✅ Seviye atlayınca kalp ikonuyla "Göl sevgisi 2!", ses ve titreşim (panel ya da kart açıksa kapanınca; birkaç
    seviye birden atlanırsa yalnızca sonuncusu). Dede 2. ve 10. seviyede bir kez konuşur (olta boşa dönünce): "Göl seni
    tanıdı evlat! Nadir balık artacak.", "Gölün en sevdiği balıkçı sensin evlat!". 6. seviyenin sözü ("Göl seni çok
    sevdi! Nine'ye uğra, sevinir.") altın hamuru haber verir: Nine onu dükkâna ilk uğrayışta verir (§10.5).
  - ✅ Görüldüğü yerler: Kova panelinin başlığı, "Bugün" panelindeki sevgi kartı (çayın yanında: seviye, çubuk;
    seviye 1'de "Balık bırak, çöp topla: göl güzelleşir.", sonra "Nadir+ balık en çok %4 daha sık"), defterin başlığı.
  - **Etki** ✅: 10 seviye (eşikler 0, 12, 30, 60, 110, 180, 270, 380, 520, 700); Nadir+ ağırlıkları seviye başına %4
    artar, en çok %36 ("en çok": ağırlığın payı; oranlar yeniden normalleşince Nadir+'nın payı biraz daha az artar).
    Defterdeki oranlara yansır (defterin başlığı: "Şimdi: Akşam · Yağmurlu · Göl sevgisi 2 (Nadir+ en çok +%4)").
  - ✅ Göl seviyeyle güzelleşir (bitkiler yine tek ağ; kelebekler yağmurun ve ateşböceğinin parçacık düğümünde: gündüz
    +1 çizim, bütçede): seviye başına kıyıda %20 daha çok çiçek öbeği ve %3 daha çok
    nilüfer (yenilerin çoğu çiçekli; nilüfer az artar, gölgelerin üstünde çizilir), su biraz daha berrak (açık
    turkuaz derine iner, en yüksek seviyede %30); 3. seviyeden sonra gündüzleri (açık ve bulutlu havada) renkli
    kelebekler (yatay uçar, uçtuğu yöne bakar, kanat çırpar). Kuşlar sonraya.
  - Hiç azalmaz.
- **Dede'nin istekleri** ✅ (4. adım; `Requests`, `data/requests.json`):
  - Rütbe 2'de açılır: o rütbeyi getiren balıktan sonra 3 yuva dolar; saat çipinin köşesinde kırmızı rozet, çip nabız
    gibi atar, Dede: "Her gün sana küçük işlerim olacak evlat! Saate dokun."
  - Her yeni oyun gününde yalnızca boş yuvalar dolar ("Yeni gün! Dede'nin yeni istekleri var", "Sabah oldu"dan sonra;
    rozet). Süre sınırı yok (gelir kuralı 7): biten isteğin yuvası ertesi güne kadar boş ("Yarın yeni istek"), bitmeyen
    istek kalır. Günde bir isteği ücretsiz değiştirebilirsin (eskisi ve ekrandakiler gelmez).
  - İstek oluştuğu anda belli (gelir kuralı 4): zarı kaydın seed'i ve isteğin sıra numarası.
  - Türler:

    | İstek | Örnek | Ağırlık | Rütbe | Sayı | Sevgi | Çarpan |
    |---|---|---|---|---|---|---|
    | tür | "3 Kadife tut" | 6 | 2 | Sıradan 3–5, Güzel 2–3, Nadir 1–2 | 3 | 1,0 |
    | boy | "Kadife · en az 35 cm" (türün %35–60 yüzdeliği, 5'e yuvarlı, 3★ içinde) | 4 | 3 | 1 | 4 | 1,2 |
    | teknik | "Spin ile 4 balık" (kamışı alınmış teknik) | 3 | 2 | 3–5 | 3 | 1,0 |
    | bölge | "Sazlık: 5 balık" (açık bölge) | 3 | 3 | 4–6 | 3 | 1,0 |
    | vakit | "Akşam vakti 2 balık" | 3 | 2 | 2–4 | 4 | 1,1 |
    | nadir | "1 Nadir+ balık" | 2 | 4 | 1–2 | 5 | 1,4 |
    | yağmur | "Yağmurda 2 balık" (yalnızca bugünün ya da yarının tahmini yağmursa) | 2 | 3 | 2–3 | 4 | 1,1 |
    | bırakma | "3 balık bırak" | 3 | 2 | 3–5 | 5 | 0,8 |
    | çöp | "1 çöp topla" (dip kamışı ya da tuzak varken) | 2 | 4 | 1–2 | 6 | 1,0 |
    | tuzak | "Tuzaktan 4 kerevit" (tuzak alınmışken) | 2 | 3 | 3–6 | 3 | 0,9 |

    Tür ve boy isteği bir açık bölgede elindeki bir teknikle en az %2 gelen türden (koruma altındaki tür yok).
  - Ödül: para round5((15 + 6·rütbe) × çarpan × 0,75–1,25), rütbe puanı (10 + 4·rütbe) × çarpan, göl sevgisi. Biten
    istek kendiliğinden öder: "İstek tamam! +45 para" (istek ikonuyla, para sesi), Dede: "Aferin evlat! Tam istediğim
    gibi."
  - Sayılanlar: av (tür, boy, nadirlik, teknik, bölge, vakit, hava), göle bırakılan balık (kovadan, karttan, koruma
    altındaki tür), toplanan çöp, tuzaktan gelen her kerevit (tuzak isteğine, kerevitin tür ve boy isteğine).
  - Denge §10.4. Altın istekler (harita parçaları): ayrı yuvada, değiştirilmez, yarın yenisi gelmez (Gölün Sırrı).
- **Açılış filmi** ✅ (v0.4.1; Ersin: "oyunun başlangıcında bir hikâyesi yok, ilgi çekici bir hikâye ekle"):
  - Yeni oyunda bir kez, oyunun içinde oynar (~45–55 sn): göl arkada yaşar, kamera çekimden çekime kayar.
    Sinema şeritleri, başta logo, altta konuşanın yüzü, adı ve en çok iki satır söz.
  - Dokununca sonraki söz; söz kendiliğinden de ilerler (en az 5 sn). Sağ üstte ATLA. Film görülünce bir daha
    oynamaz (kayıtta bayrak); bitince "Gölgeyi gördün mü?" ipucuyla ilk balık başlar.
  - Sözler:

    | # | Konuşan · çekim | Söz |
    |---|---|---|
    | 1 | Nine · Nine yakın, selam verir | Hoş geldin evladım! Bu yaz bizimle, göl köyünde kalacaksın. |
    | 2 | Dede · göl | Şu göle bak evlat. Pırıl pırıl, değil mi? |
    | 3 | Dede · Dede yakın | Biz gençken bu göl ölüyordu. Su bulanıktı, balıklar kaçmıştı. |
    | 4 | Nine · sazlık | Dedenle yıllarca çöp topladık, sazlar diktik. Göl yeniden canlandı. |
    | 5 | Dede · derin orta | Bir de derinlerde biri yaşar evlat: Gölün Bekçisi. |
    | 6 | Dede (şaşkın) · dev gölge geçer | İşte orada! Gölü o korur. Ben onu yalnızca bir kez gördüm. |
    | 7 | Nine · iskele | Bekçi, göle iyi bakanlara görünürmüş evladım. |
    | 8 | Dede · hediye | Al, bu benim ilk oltam. Artık senin evlat! Haydi, ilk balığına! |

  - Bekçi'nin dev gölgesi (5 m, masalsı turkuaz) derin ortada 10 m'lik bir yay çizip geçer; yalnızca görünüş,
    gölgelerin kuralına ve oranlara dokunmaz. Son sözde balıkçı Dede'ye döner, Dede'nin bambu oltası eline gelir.
  - ✅ Ayarlar'da HİKÂYE: film iskelede baştan oynar (sandaldaysan iner); olta suda değilken. Kayıt değişmez.
- **Hikâyenin devamı** ✅ (v0.4.1): unvanın değiştiği rütbelerde (3, 6, 10, 15, 20) Dede hikâyeyi bir adım
  sürdürür: o rütbeye gelince sonraki balıktan sonra (başka haber yoksa) ya da Dede'ye dokununca, her biri bir kez.
  Dalga 4'teki finale (sisli gece, derin orta, Bekçi) hazırlar.

  | Rütbe | Dede'nin sözü |
  |---|---|
  | 3 | Göl temizlenince Bekçi'nin gölgesini ilk kez gördük. |
  | 6 | Bekçi her yaz derin ortadan geçer, iz bırakırmış. |
  | 10 | Bıraktığın her balık Bekçi'ye selam götürür evlat. |
  | 15 | Nine der ki Bekçi sisli gecelerde yüzeye çıkar. |
  | 20 | Artık gölün efsanesisin. Bekçi seni bekliyor evlat. |

- **Gölün Sırrı** (Dalga 4, 5. adım ✅; `Secret`, `Requests.offer_golden`):
  1. Dede efsaneyi anlatır (açılış filmi ve rütbe bölümleri bunu başlatır); ilk şişe sazlıkta çıkar.
  2. ✅ **Şişeler ve mektuplar.** Her bölgeden bir şişe, sırayla: sıradaki mektubun rütbesi gelmiş, son mektuptan beri
     en az 15 balık tutulmuş ve bölge açık olmalı. Mektuplar genç Nine ile Dede'nin gölün iki yakasından şişelerle
     yazışması (tek numaralar Nine'nin, çiftler Dede'nin; Türkçesi 51–60, İngilizcesi 81–94 kelime: kâğıda kaydırmadan
     sığar): göl ölürken onu nasıl temizlediklerini anlatır.

     | # | Bölge | Rütbe | Mektup |
     |---|---|---|---|
     | 1 | Sazlık | 3 | Kuruyan sazlar |
     | 2 | İskele koyu | 4 | İskelenin altından (çizmeler, paslı anahtar) |
     | 3 | Nilüferli koy | 6 | İlk nilüfer |
     | 4 | Kayalık burun | 8 | Turkuaz gölge (Bekçi'yi gördüğü gece) |
     | 5 | Dere ağzı | 10 | Altın hamur (ninenin tarifi) |
     | 6 | Derin orta (sandal) | 12 | Dört parça ("Gördüğüm yeri çizdim, haritayı dörde yırttım") |

     - Şişe bölgenin atış noktasından 2–4 m açıkta (derin ortada ilk şamandıranın yanında) suda yan yatar, sallanır,
       parlar, arada çevresinde halka. Çıkınca "Suda bir şişe var: Sazlık" bildirimi, haritada işareti, Dede'nin sözü
       ("Sazlıkta suda bir şey parlıyor evlat! Git bir bak.").
     - Şişeye dokun: yakındaysan hemen, uzaktaysan kıyı yolundan yürüyüp alırsın; şişe başka sudaysa ekran kararıp
       oraya geçilir (derin ortanınkine sandalla ilk şamandıraya, sandaldan kıyıdakine sandaldan inilerek). Şişe
       kalkar, mektup açılır: mektup kâğıdında başlık ("Mektup 3/6"), mektubun adı, yazı, imza; kaydırmadan sığar.
       Kapanınca Dede yazanı tanır ("Bu yazıyı tanıdım evlat... Nine'nin!"). Şişe alınana kadar suda bekler; süre
       yok (gelir kuralı 7).
     - Okunan mektuplar Balık Defteri'nin "Gölün Sırrı" sekmesinde (ilk mektuptan sonra görünür): altı mektup kartı
       (okunanlar yeniden açılır; sıradakinde bölgesi ve ne beklediği: rütbe, sandal ya da kaç balık), harita yapbozu,
       altın hamur.
  3. ✅ **Harita parçaları: Dede'nin altın istekleri.** Altın yuvada (günlük üç isteğin üstünde, altın şeritte), sırayla,
     mektubu ve rütbesi gelince; değiştirilmez, yarın yenisi gelmez, süresi dolmaz. Ödül: parça, para round5(150 + 10 ·
     rütbe), 100 rütbe puanı, 8 göl sevgisi. Gelince "Dede'nin altın isteği! Saate dokun." ve Dede'nin sözü ("Eski
     haritamı dörde yırtmıştım. Saate dokun evlat!"); bitince "Harita parçası 2/4! +230 para".

     | Parça | Şart | İstek |
     |---|---|---|
     | 1 | 3 mektup, rütbe 6 | Akşam Nilüferli Koy'da 1 Turna tut |
     | 2 | 4 mektup, rütbe 8 | Gece vakti 3 balık tut |
     | 3 | 5 mektup, rütbe 10 | Göle 5 balık bırak |
     | 4 | 6 mektup, rütbe 12 | Gece Derin Orta'da diple 1 Yayın tut |

     - Defterde 2×2 yapboz: bulunan parça yerinde (Ersin'in hazine haritası görseli gelince onun çeyreği; yoksa kodla
       parşömen: gölün gerçek şekli, iskele, koyu derin orta), eksiğin yeri kesik çizgili ve soru işaretli. Dört parça
       tamamsa haritanın ve oyunun haritasında derin ortanın ilk şamandırasında kırmızı X ("X: derin ortanın ilk
       şamandırası. Sisli geceyi bekle!"); Dede: "Harita tamam! X, ilk şamandıranın orada."
  4. ✅ **Altın hamur.** Göl sevgisi 6 olunca Dede "Nine'ye uğra" der; dükkâna ilk uğrayışta Nine verir ("Al evladım,
     ninemin altın hamuru! Dipte kullan."), bildirim. Anahtar eşya: dükkânda kartı yok, satılmaz; Takım Çantası'nın dip
     karosunda rozeti, defterde "Altın hamur sende".
  5. Final hazır: altı mektup, dört parça, altın hamur (denge botu 151–188. dakikada, rütbe 13–14; Bekçi 152–209. dakikada; §10.4).
  6. ✅ **Final: Gölün Bekçisi** (6. adım; `Secret.keeper_due`, `KeeperPresenter`, `Story.ENDING`, `CreditsPanel`):
     - Final hazır olunca Dede söyler: "Hepsi tamam! Bu gece sis basacak, sandalla X'e git." Bekçi bırakılana kadar
       her gece sisli, fırtınasız (sisli gece kendiliğinden ~10 günde bir gelir; beklemek ceza gibi olmasın; Kocabaş
       finalden sonra döner). "Bugün" panelinde "Gece sis: Bekçi'nin gecesi".
     - Gece, sandal haritanın X'inde (derin ortanın ilk şamandırası), elde dip ve altın hamur varken kurşun suya düşüp
       1,6 sn geçince Bekçi belirir: sandaldan 6–9 m ötede, takımdan en az 3 m uzakta turkuaz halkalar, "sting",
       titreşim, "Gölün Bekçisi geldi!", Dede'nin sözü ("İşte o, Gölün Bekçisi! Zil çalınca vur evlat!") ve Bekçi'nin
       müziği. Gündüz X'te Dede "Bekçi gece gelir evlat. Çay içip geceyi bekleyelim." der; elde dip yoksa "Altın hamur
       dipte işe yarar evlat: dip kamışını al!".
     - Takıma yalnızca o gelir: o gece X'te öteki balıklar dibe atılan yemi kapmaz (Bekçi belirmeden, kaçıp dönmeden
       de; ilk denemede belirmeden önceki 1,6 sn'de yakındaki bir balık yemi kapıyordu); korkmaz, vazgeçmez, boyu hep
       aynı (~5,2 m, 5★). Koklarken
       dokunmak ve kaçan koşu onu kaçırmaz (ilk av gibi irkilir, yeniden koklar); koşuda VUR. Çekişme gerçek (Kolay
       modda Kolay): iki dalış (§5); dalışın uyarısında ipucu "BIRAK! Bekçi dalıyor!", turkuaz halka, ses, sarsıntı,
       titreşim.
     - Kaçarsa (misina koptu): Dede "Kaçırdık! Bekle, geri gelecek."; 25 sn sonra yeniden atınca gelir ("Geri geldi!
       Bu sefer dalınca bırak evlat."; oyun sonrasında da). Sabah olunca derinlere döner ("Sabah oldu, Bekçi derinlere
       döndü."; çekişirken ya da beklerken sabah olursa o gece gelmez). Ceza yok.
     - Tutulunca elde gösterilmez (5 m): sudan çıktığı yerde turkuaz halkalar, herkes sevinir; Masalsı kart (koruma
       sözü), tek düğme "Göle bırak". Şans garantisine sayılmaz, yanında çöp çıkmaz. Bırakmak finali bitirir
       (`save.keeper`), Masalsı kademenin göl sevgisi 100. O gece sabaha kadar sisli kalır (sis şafakta kalkar).
     - **Bitiş filmi** (kart kapanınca, bir kez; kart açıkken uygulama kapandıysa açılışta; ~32 sn; açılış filmi gibi
       göl arkada yaşar; dokununca sonraki söz, ATLA; kendi müziği). Şafak ve çiçek açma ATLA'da da olur: film bitince
       balıkçı iskelede, saat sabah, göl çiçekli. Göl kart açıkken değil, filmde çiçek açar:

       | # | Konuşan · çekim | Söz |
       |---|---|---|
       | 1 | Dede · Bekçi sandalın çevresinde döner ve dalar | Bak evlat... Bekçi sandalın çevresinde dönüyor. Sana teşekkür ediyor! |
       | 2 | Nine · şafak (ekran kararır, iskeleye dönülür, gece bitmediyse sonraki sabah) | Sabah oldu. Bakın, sis kalkıyor! |
       | 3 | Nine · göl çiçek açar (göl sevgisinin en üst görünüşü, kalıcı) | Göl hiç bu kadar güzel olmamıştı. Senin sayende evladım. |
       | 4 | Dede · Dede ve Nine sevinir | Aferin evlat! Gölün sırrı artık senin de sırrın. |
       | 5 | Nine · göl, geniş | Bu göl artık senin de evin. Ne zaman istersen gel evladım! |

     - **Jenerik** (filmden sonra; kendiliğinden yukarı kayar, ATLA; filmin ATLA'sına çift dokunuş jeneriği atlamaz): logo; Fikir ve görseller: Ersin; Kod: Claude;
       3B modeller: KayKit · Kay Lousberg, Kenney; Yazı tipleri: Luckiest Guy · Astigmatic, Baloo 2 · Ek Type; Sesler ve
       müzik: kodla üretildi; Teşekkürler: oynayan herkese; son söz "Gölün Bekçisi'ni göle bıraktın. Göl seni bekliyor!".
     - **Oyun sonrası:** geceler normal havaya döner; rütbe 20'nin sözü Bekçi'den sonra "Artık gölün efsanesisin. Bekçi
       bile sana selam verdi!"; Ayarlar'da BİTİŞ filmi ve jeneriği yeniden oynatır (sandalla X'ten başlar, şafakta
       iskele; saat ve kayıt değişmez);
       kendiliğinden gelen sisli gecelerde X'te Bekçi yine çıkar, filmsiz ("Bekçi yine sana göründü evlat!"; bırakıldığı
       gün değil). Defterde 19. tür (ipucu "Haritanın X'inde, sisli bir gecede, altın hamurla."), Gölün Sırrı
       görünüşünde "Gölün Bekçisi'ni göle bıraktın. Göl seni seviyor!".
     - Denge botu finali oynar (`SessionSim`; §10.4).

### 10.6 Yuva ve kişilik

- **Akvaryum (Nine'nin dükkânında):**
  - Bulunan her türden biri konabilir; tanktaki balıklar 3D yüzer.
  - Ziyaretçi kutusu tanktaki türlere göre para biriktirir; en çok 2 saatlik birikimde durur.
- **Kedi, erkek balıkçı ve kıyafetler:** §7.
- **Fotoğraf modu:**
  - Arayüz gizlenir, kamera biraz döndürülür, çerçeve seçilir.
  - PNG `user://photos`'a kaydedilir ve iPhone'un Dosyalar uygulamasında görünür.
  - Doğrudan Fotoğraflar'a kaydetmek yerel bir eklenti ister; sonraya kalır.

### 10.7 Ekran düzeni

Ekran kalabalık olmasın diye her şeyin bir yeri var:

- **Sol üst:** para, kova (5/12), rütbe rozeti. Başlık ve sürüm yazısı ayarlara taşınır. ✅ Kovaya dokununca Kova
  paneli (§10.4; dokunma kutusu 122, olta sudayken dokunuş almaz).
- ✅ **Üst orta:** saat çipi (Dalga 4): vaktin ikonu, saat ("18:24") ve açık değilse havanın ikonu (yağmurlu gece
  fırtına). Çekişmede yerini gerilim çubuğu alır. Dokununca "Bugün" paneli (dokunma kutusu 122; olta sudayken
  görünür ama dokunuş almaz, ekranın her yeri eylem):
  - **Şimdi:** vaktin ikonu ve adı, saat, sonraki vakte kalan ("Geceye 3 dk");
  - **Hava:** bugün ve yarın;
  - **Dede'yle çay** (ÇAY İÇ);
  - **Göl sevgisi** ✅ (çayın yanında; §10.5);
  - başlıkta günün sırası ("3. gün");
  - ✅ en altta Dede'nin istekleri (rütbe 2'den sonra; §10.5): yuva başına kart (ikon, ne istendiği, ilerleme "1/3",
    ödül, değiştir düğmesi; boş yuvada "Yarın yeni istek"). Yeni istek varsa çipte kırmızı rozet; panel açılınca söner.
  Panel açıkken saat durur; telefonda küçülmeden sığar.
- **Sağ üst:** harita, defter, ayarlar (her biri ≥122).
- ✅ **Sol alt:** yürüme halkası (252; sağ kenarı ipucu çubuğunun payının solunda; olta sudayken yok, sandalda yerinde "Kıyıya dön") ve üstünde teknik düğmesi (132).
- **Sağ alt:** eylem düğmesi (300).
- **Alt orta:** Dede'nin ipucu çubuğu.
- **Fotoğraf:** balık kartındaki ve ayarlardaki kamera düğmesi.
- ✅ **"Nasıl oynanır?" rehberi:** oyunun baştan sona anlatımı, 10 sayfa.
  - **Sayfalar:**
    1. balık tutmak (AT, BEKLE, VUR!, SAR, BIRAK!);
    2. oyunun döngüsü;
    3. nadirlik;
    4. teknikler ve tuzak;
    5. kamış, makara, misina (iri balık yıldızları);
    6. küçük takım;
    7. ekstralar;
    8. bölgeler;
    9. göl yaşıyor (Dalga 4): vakit, hava, Dede'yle çay, göl sevgisi, Dede'nin istekleri (rütbe 2'ye kadar kilitli);
    10. Dede, Nine, defter ve hedef.
  - **Girişler:** Ayarlar'ın başlığındaki "Nasıl oynanır?" (yanında HİKÂYE: açılış filmi yeniden, §10.5). Takım Çantası'ndaki "?" Teknikler'i, dükkândaki "?" açık sekmenin sayfasını açar.
  - **Kilitler:** henüz açılmamış teknik, bölge ve takım da görünür; kilidinde açıldığı rütbe, derin ortada sandal yazar.
  - **Sayılar veriden gelir:** rütbeler, tuzağın süresi, kovalar, şans garantisi, yıldızlar. Oyun değişince rehber eskimez.
  - **Dede:** son genel öğüdü rehberi söyler.

### 10.8 Sonraya kalanlar

- **Kıyı süsleri ve tarifler:** kıyının 4–6 süs yuvası; süs + hava + saat bir türü çağırır, bulunan tarif o türü garanti eder.
- **Gerçek parayla satış (Faz 3):** kostümler, reklam, sezon kartı.
- **Yeni sular:** göl → nehir → deniz → buzlu göl → mağara gölü.
- **Sonar.**
- **Fotoğraflar uygulamasına doğrudan kayıt** (yerel eklenti).
- **Çevrimiçi:** arkadaşın akvaryumunu gezme, hediye, köyün ortak hedefi. Açık sohbet ve sık yarışma yok.

## 11. Gelir

Ayrıntı: [`saha-arastirmasi.md`](saha-arastirmasi.md) §7–8 ve [`CLAUDE.md`](../CLAUDE.md).

- **Satılacaklar:** kostümler ve görünüş süsleri (doğrudan satış, gerçek fiyat görünür), reklamsız / destekçi paketi, süresi dolmayan sezon kartı.
- **Ödüllü reklam** (isteğe bağlı): çift ödül, kopan misinayı kurtarma.
- **Parayla satılmayacaklar:** şans (nadir yem, ek atış, hava olayı).
- **Oyun parası:** yalnızca oynayarak kazanılır, gerçek parayla asla satılmaz. Bu yüzden oranı değiştiren yem ve yapay yem oyun parasıyla satılabilir.
- **Boşta gelir üst sınırlı:** tuzak en çok 4 şey toplar, akvaryum kutusu en çok 2 saatlik birikimde durur.
- **Kıyafetler:** H2'de oynayarak kazanılır; gerçek parayla satış Faz 3'te başlar ve fiyatı her zaman gerçek parayla yazar.

## 12. Teknik özet

- **Motor:** Godot 4.7, statik tipli GDScript, Compatibility renderer.
- **Oyun mantığı** `scripts/core/` altında, saf ve testli: `FishingSession`, `ShadowSim`, `BiteRules`, `ReelModel`, `FishTable`, `LakeShape`, `Records`.
  - ✅ H2'de gelenler: takım ve para (`GearStats`, `Economy`, `Bucket`, `Rank`, `CatchOdds`: oranlar ve şans garantisi); göl (`LakeShape` havzaları ve bölgeleri, `Zones`, `ShorePath`); teknikler (`Technique` stratejileri `FloatTechnique`, `SpinTechnique`, `BottomTechnique`, `FlyTechnique`; `TechniqueRules`, teknik başına takım seti, kerevit tuzağı `TrapSim`).
  - ✅ Dalga 4'te gelenler: canlı dünya (`DayClock`, `Weather`, `LakeLove`, `WorldState`, `Trash`, `Requests`, `Secret`, `Story`).
  - ✅ Denge botu (`SessionSim`, `tools/economy_report.gd`, süreler `tools/session_timing.gd`) ile korkuluk testleri; oran kataloğu (`tools/fish_catalog.gd` → `balik-katalogu.md`).
  - Çekişme sayıları `tools/reel_report.gd` ile denetlenir; `tests/test_reel_model.gd` sınırları korur.
  - İç adım sabit 1/60 sn; sonuç fps'e ve video kaydına bağlı değil.
- **Sunum** yalnızca olayları dinler.
- **Kazı'nın genel altyapısı** kullanılır: test koşucusu, kayıt, arayüz parçaları, ses, bot.
- Ayrıntılar ve kurallar: [`CLAUDE.md`](../CLAUDE.md).

## 13. Açık sorular

- Gölgeler ve şamandıranın dürtmesi telefonda okunuyor mu?
- VUR penceresi ve çekişme her yaşa adil mi? Kolay çekme varsayılan mı olmalı?
- Büyük göl iPhone 14'te 60 fps'te akıyor mu? Yürüme ve harita yeterince hızlı mı?
- Spin ve sinek dokunmatik ekranda anlaşılıyor mu?
- Dükkânda seçenek kalabalığı var mı?
- 24 dakikalık oyun günü doğru hızda mı?
- Erkek balıkçı ve kedi için hangi modeller? (Nine: KayKit Mage.)
- Kazı'ya benzerlik hissediliyor mu?
