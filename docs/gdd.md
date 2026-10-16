# Olta: Gölün Sırrı — Oyun Tasarım Belgesi (H2: Büyük Göl)

> Prototipin (v0.1) kuralları ✅ ile, H2 "Büyük Göl" güncellemesinin tasarımı 🔜 ile işaretli (§10). Sıra ve adımlar: [`yol-haritasi.md`](yol-haritasi.md). H2'nin sayıları taslaktır; denge botuyla ayarlanır. Fikrin neden seçildiği: [`fikirler.md`](fikirler.md).

## 1. Vizyon

**"Gölü keşfet, takımını kur: bu gece oltana ne takılacak?"**

Yazı Dede ile Nine'nin göl köyünde geçiren bir çocuk ya da genç balıkçısın. Gölde balık gölgeleri dolaşıyor. Gölgenin önüne oltanı atıyorsun; gölge fark edip yaklaşıyor, şamandırayı dürtüyor ve sonunda ısırıyor: VUR! Sonra gerilim çubuğunu kırmızıya kaçırmadan çekiyorsun.

Göl büyük ve bölgelere ayrılmış: sazlık, nilüferli koy, kayalık burun, dere ağzı, derin orta 🔜. Her bölgenin kendi balıkları var; her balığın sevdiği bir teknik, yem, saat ve hava var. Nine'nin dükkânından aldığın takımla yeni tekniklere (spin, dip, sinek, tuzak) ve yeni sulara açılırsın. Tuttuğun balıkların kopyalarını Nine'ye satarsın; her türün en iyisi akvaryumda yaşar. İstersen balığı göle geri bırakırsın; bıraktıkça göl güzelleşir. Dede'nin anlattıkları ve şişelerden çıkan mektuplar seni gölün sırrına, Gölün Bekçisi'ne götürür.

- **Platform:** iOS + Android, yatay ekran, low-poly 3D.
- **Model:** ücretsiz oyun; gelir kuralları [`CLAUDE.md`](../CLAUDE.md)'de.
- **Kitle:** aile dostu, her yaş. Hedef Apple 4+/9+, PEGI 7. Çocuk kategorisine girilmez.
- **Dil:** baştan Türkçe + İngilizce.

## 2. Tasarım sütunları

1. **Her gölge bir soru.** Gölgenin boyu balığın boyunu ele verir, türünü vermez. Nadir gölgeler arada pırıldar, ama yine türünü söylemez 🔜. "Bu kocaman gölge ne?" merakı oyunun motorudur.
2. **Tek parmak, her yaş.** Dokun-yürü, dokun-at, değdiği an VUR, basılı tut-çek. Yeni teknikler de tek parmakla oynanır: bas-bırak, dokun 🔜. Okumadan oynanır.
3. **Keşfet, kur, sergile** 🔜. Bölge, teknik, yem, saat ve hava hangi balığın geleceğini belirler; takımını sen kurarsın. Balık Defteri her türün nerede ve ne zaman çıktığını, oranlarıyla birlikte gösterir. En iyileri akvaryumda yaşar.
4. **Sakin ve adil.** Oyuncu yokken ceza yok; parayla şans satılmaz; kötü şansa karşı garanti var.
5. **Kısa oturum.** Bir atış 15–40 saniye; bir oturum 5–10 dakika.

## 3. Döngüler

| Döngü | Süre | İçerik | Durum |
|---|---|---|---|
| Çekirdek | 15–40 sn | Dokun → at → gölge yaklaşır, dürter → ısırır → VUR → çek → balık elde, kart | ✅ |
| Oturum | 5–10 dk | Kova dolar → Nine'ye sat (her türün en iyisi akvaryuma) → takım al → yeni teknik ya da bölge → Dede'nin isteğini bitir | 🔜 (H2) |
| Haftalar | günler | Balık Defteri (siluetler, ipuçları, oranlar), rütbe, gece ve hava balıkları, göl sevgisi, "Gölün Sırrı" hikâyesi ve Gölün Bekçisi; sonra yeni sular, sezonluk türler | 🔜 |

## 4. Kontroller ✅

**Telefon (yatay):**

- **Karaya ya da iskeleye dokun:** balıkçı oraya düz yürür; kıyıya gelince durur.
- **Suya dokun:** balıkçı oraya atar. Menzil dışındaysa önce yaklaşır. Hedef karaya denk geliyorsa şamandıra yine suya düşer.
- **Olta suyadayken ekranın her yeri bir düğmedir:**
  - **değdiği an:** ısırmada VUR; ısırmadan önce oltayı geri sarar;
  - **çekişmede basılı tutunca:** sarar.
  Sağ altta büyük bir eylem düğmesi de aynı işi yapar ve ne olacağını yazar: GERİ SAR / VUR! / SAR.
- **Joystick yok,** çünkü soldaki dokunuşları yutuyordu (Kazı deneyimi).

**Mac:** tıkla (yürü, at), WASD (yürü), Space (VUR; basılı tutunca sar).

**H2'de eklenecekler 🔜** (ayrıntı §10.3):

- **Teknik düğmesi** (sol alt): geçerli tekniğin ikonu; dokununca şamandıra, spin, dip ya da sinek seçilir.
- **Spin:** basılı tut = yem gelir, bırak = durur ve batar. Saldırı anında basılıysa balık kendiliğinden takılır, değilse kısa bir VUR anı açılır.
- **Dip:** at, olta sehpaya konur; zil sürekli öterken ekranın her yerine dokun.
- **Sinek:** halka çıkınca dokun.
- **Tuzak:** kıyıdaki tuzak şamandırasına dokun → bırak ya da topla.
- **Harita** (sağ üst): bir atış noktasına dokun → oraya geçilir. **Sandal:** iskeledeki sandala dokun → derin ortadaki şamandıralardan birini seç.
- **Dünyada dokunulanlar:** Nine → dükkân; Dede → öğüt ve istekler; kedi → sev.

## 5. Kurallar ve başlangıç sayıları ✅

Bütün sayılar `data/*.json`'da ve testlerde. Telefonda denendikçe ayarlanır.

**Atış**

- İlk olta: bambu olta, menzil 9 m.
- Şamandıra uçuş süresi 0,45 sn + mesafe × 0,05 sn; yay yüksekliği mesafenin dörtte biri.

**Gölgeler**

- Gölde aynı anda 4 gölge var.
- Hız 0,3–0,5 m/sn; aralarda 1–3 sn duraklar. Yalnızca 0,8 m'den derin yerlerde dolaşırlar.
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
  - Balık zaman zaman çırpınır. İlk patlama çekişmenin 1,6–2,4. saniyesinde gelir (oyuncu hemen öğrensin).
  - Her patlamadan **0,5 sn önce** uyarı gelir: balık çırpınır, misina titrer, gıcırtı duyulur, telefon titrer, "!" çıkar.
  - Patlamada basılı tutarsan gerilim kırmızıya çıkar.
- **Kopma:** gerilim sınırın üstünde toplam 0,8 sn kalırsa misina kopar ("Misina koptu!"). Sayaç sınırın altında yavaşça geri iner.
- **Kaçma:** balık menzil + 2 m'den uzağa kaçarsa gider. Kıyıya doğru kaçarsa kıyıda gider (karaya çıkmaz); ama kaçış payı hep şamandıranın en az 2 m ötesidir, kıyıya yakın atışta da bırakan oyuncu hemen kaybetmez (balık kıyıda çırpınır).
- **Yakalama:** balık 0,6 m'ye gelince tutulur.
- **Kolay çekme (Ayarlar):** gerilim tavanlıdır, misina kopmak yerine kayar, balık kaçmaz; beceri yalnızca hızı belirler.
- **Süre:** iyi bir oyuncuyla çekişme Kızılkanat'ta 4–7 sn, Yayın'da 14–20 sn sürer.
- **Kolay modda** patlamada basılı tutunca misina kayar: balık, kaçış hızının 2 katıyla uzaklaşır. Hep basılı tutan yine tutar; bırakmayı bilen daha hızlı tutar.
- **Denge raporu** (`tools/reel_report.gd`; 4–9 m'den 200 deneme, ortalama süre):

| Balık | Çekiş | İyi oyuncu (0,4 sn tepki) | Yavaş oyuncu (0,7 sn) | Hep basılı (Normal) |
|---|---|---|---|---|
| Kızılkanat | sakin | 5,8 sn | 6,0 sn | tutar |
| Sazan | ağır | 10,7 sn | 11,4 sn | koparır |
| Levrek | ani | 9,5 sn | 10,5 sn | %55 tutar |
| Turna | ani, güçlü | 13,7 sn | 15,2 sn | koparır |
| Yayın | düzensiz, güçlü | 16,1 sn | 17,7 sn | koparır |

  İyi ve yavaş oyuncu her balığı tutar. Kolay modda hep basılı tutan da tutar.

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

## 6. Balıklar (prototip) ✅

| Kimlik | TR | EN | Taban gölge | Nadirlik | Boy | Çekiş | Doğma | Görünüş |
|---|---|---|---|---|---|---|---|---|
| `rudd` | Kızılkanat | Rudd | 0,5 m | Sıradan | 15–30 cm | sakin | 35 | gümüş gövde, kırmızı yüzgeçler |
| `carp` | Sazan | Carp | 0,75 m | Güzel (H2'de Sıradan'dan çıktı) | 30–80 cm | ağır | 25 | bronz-altın, koyu sırt, iri pullar |
| `perch` | Levrek | Perch | 0,75 m | Güzel | 20–45 cm | ani | 17 | yeşil-sarı, koyu dikey çizgiler, turuncu yüzgeçler |
| `pike` | Turna | Pike | 1,05 m | Nadir | 50–120 cm | ani, güçlü | 15 | uzun, zeytin yeşili, açık benekler |
| `wels` | Yayın | Wels Catfish | 1,5 m | Destansı | 100–250 cm | düzensiz, güçlü | 8 | koyu gri-kahve, bıyıklı, yassı baş |

**Nadirlikler:** Sıradan (gri), Güzel (yeşil), Nadir (mavi), Destansı (mor), Efsanevi (altın), Masalsı (turkuaz; H2'de eklendi, yalnızca Gölün Bekçisi). Efsanevi ve Masalsı balık henüz yok. Nadirlikler yalnızca sona eklenir; her kademenin bir simgesi, rütbe puanı ve göl sevgisi değeri var (§10.2, `data/rarities.json`).

**Değerler (para, orta boy):** Kızılkanat 5, Sazan 12, Levrek 12, Turna 35, Yayın 120. Doğma ağırlıkları Köy Gölü'nde 40/25/22/9/4 (testlerin gölünde 35/25/17/15/8).

**H2 türleri 🔜** (18 tür; bugünkü 5 kimlik korunur, sazan Güzel'e çıkar). Bölge, teknik ve vakit ayrıntısı §10.1 ve §10.3'te.

| Kademe | Türler |
|---|---|
| Sıradan | kızılkanat, gümüş balığı, çapak, tatlısu kefali |
| Güzel | sazan, levrek, kadife |
| Nadir | turna, sudak, alabalık, aynalı sazan |
| Destansı | yayın, altın sazan, dere alabalığı |
| Efsanevi | mersin (yalnızca bırakılır; koruma mesajı), ay turnası (gece), Kocabaş (dev yayın, fırtınalı gece) |
| Masalsı | Gölün Bekçisi (hikâyenin sonu) |

- **Kerevit:** tuzakla ve dip avıyla çıkar.
- **Eşyalar:** eski çizme, teneke, mesajlı şişe (hikâye), paslı anahtar. Çöp toplamak göl sevgisi verir.
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
  - Sonra her tekniği ilk kullanımda gösterir, her gün 3 küçük istekte bulunur ("bana 30 cm'lik bir kadife getir") ve "Gölün Sırrı"nı parça parça anlatır 🔜.
  - Dede'yle çay içmek oyun saatini bir sonraki vakte geçirir 🔜.
- **Nine** 🔜 (Dede'nin eşi):
  - İskelenin kara ucundaki küçük ahşap dükkânı işletir; ona dokununca dükkân açılır.
  - Model KayKit'ten seçilir ve boyanır; yazmayı ve önlüğü kod kurar. Yoksa kodla kurulan yedek çıkar.
  - Hikâyede gençliğini anlatır; göl sevgisi yükselince "altın hamur"u verir.
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
- **Dış çizgi** yalnızca karakterlerde ve balıklarda.
- **Erişilebilirlik:** gerilim çubuğu renk + ikon + sarsıntı + "BIRAK!" yazısı. Her sesin bir görsel ve titreşim karşılığı var.
- **H2 görsel hedefleri 🔜:**
  - **Su:** normal haritası, gök rengine göre fresnel, sığda kostik, derede akış, yağmur halkaları.
  - **Zemin:** dokulu (çimen, kum, çamur, patika; Ersin'in dikişsiz dokuları ya da kodla).
  - **Doğa:** Forest Nature ve Quaternius doğa modelleri, nilüferler.
  - **Işık:** vakte göre ışık, gök ve sis; gece ay, fenerler ve ateş böcekleri.
  - **Nadirlik efektleri:** gölgede pırıltı, ışıltı, iz.
  - **Arayüz:** Ersin'in arayüz kiti (çerçeveler, düğmeler, nadirlik çerçeveleri).
  - **Ölçüt:** iPhone 14'te 60 fps.

## 9. Ses

- ✅ Kodla üretilir (`tools/make_sounds.py`, Kazı'nın sentez yardımcıları):
  - atış vınlaması, şamandıra "plop", dürtme tıkı;
  - ısırma sıçraması + zil;
  - makara tıkırtısı (döngü), gerilim gıcırtısı (döngü), misina kopması;
  - nadirliğe göre buluntu;
  - arayüz sesleri;
  - göl ortam sesi (su, kuş, rüzgâr).
- 🔜 Müzik: her vakit için kodla üretilen sakin döngüler (kalimba, ud) ve dükkân ezgisi.
- 🔜 Yeni sesler: spin makarası ve yem şapırtısı, dip zili (bip ve sürekli bip), sinek halkası, tuzak, kedi mırlaması, yağmur, gece böcekleri.
- iPhone'un sessiz anahtarı açıkken oyunun sesi çıkmaz (Kazı deneyimi).

## 10. H2 sistemleri 🔜

Sıra ve adımlar [`yol-haritasi.md`](yol-haritasi.md)'de (Dalga 1–5). Sayılar taslaktır, denge botuyla ayarlanır.

### 10.1 Göl ve bölgeler

- **Boyut:** su alanı bugünün yaklaşık 3 katı (≈700 m²; sınırları yaklaşık 60×36 m).
- **İskele koyu bugünkü gibi kalır:** iskele, başlangıç noktası ve Dede aynı yerde.
- **Derinlik:** her havzanın kendi derinliği ve kıyı eğimi var.

| Bölge | Derinlik | Öne çıkan teknik | Balıklar | Açılış |
|---|---|---|---|---|
| İskele koyu | 1–3,5 m | şamandıra, spin | kızılkanat, gümüş, çapak, levrek, sazan | başta |
| Sazlık | 0,5–1,5 m | şamandıra, dip, tuzak | kadife, sazan, kızılkanat, kerevit | başta |
| Nilüferli koy | 1–2,5 m | spin | turna, levrek, altın sazan, ay turnası | rütbe 3 |
| Kayalık burun | 2–6 m (dik) | spin, dip | sudak, tatlısu kefali, levrek, kerevit | rütbe 5 |
| Dere ağzı (akıntılı) | 0,5–1,5 m | sinek, spin | alabalık, dere alabalığı, tatlısu kefali | rütbe 7 |
| Derin orta | 4–10 m | dip (sandaldan) | yayın, aynalı sazan, mersin, Kocabaş, Gölün Bekçisi | rütbe 9 + sandal |

- **Yürüme:** koyların çevresinden dolaşılır. Dokunulan yere sudan geçmeden varılamıyorsa balıkçı kıyı yolundan kısa yönü seçer.
- **Harita:** bölgelerin atış noktalarına hızlı geçiş (ekran kararıp açılır). Kilitli noktalar rütbeyle açılır.
- **Sandal:** dükkândan alınır. İskeleye bağlı sandala binilir; derin ortadaki 3 şamandıradan birine gidilir. Sandaldayken suya dokunmak yine atıştır.

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
- **Değer:** her türün bir taban değeri var (Sıradan ≈5, Güzel ≈12, Nadir ≈35, Destansı ≈120, Efsanevi ≈500 para) × boy çarpanı (0,6–1,6). Masalsı satılmaz.
- **Şans garantisi:**
  - Nadir+ balık gelmeden geçen 40 avdan sonra, bulunduğun bölgede Nadir+ bir gölge doğar. Destansı+ için 150, Efsanevi için 400 av.
  - Sayaçlar defterde görünür.
  - Garanti öteki zarları kaydırmaz (Kazı'daki `LootTable` düzeni: sabit sıralı zar).
- **Balık Defteri:**
  - Kademeye göre ızgara; bulunmamış türler siluet ve ipucuyla (bölge, teknik, vakit, hava).
  - Rekorlar; o yerdeki, teknikteki ve vakitteki tam oranlar; şans garantisi sayaçları; göl sevgisi.

### 10.3 Teknikler

Çekişme her teknikte ortaktır (bugünkü `ReelModel`); teknik yalnızca ısırmaya kadarki kısmı değiştirir. Her türün bir teknik yatkınlığı var.

| Teknik | Nasıl oynanır | Takım | Açılış |
|---|---|---|---|
| Şamandıra | bugünkü gibi | şamandıra kamışı, şamandıra, iğne, yem | başta |
| Spin | Basılı tut = yem gelir, bırak = durur ve batar. Yırtıcı yemi kovalar; "dur-kalk" ritmiyle saldırır. Saldırı anında basılıysa balık kendiliğinden takılır, değilse kısa VUR anı. Otlu ve kayalık yerde uzun bekleyen yem takılır (yalnızca zaman kaybı). | spin kamışı, makara, yapay yem | rütbe 2 |
| Dip | Uzağa at, olta sehpaya konur. Zil: tek tük bip = balık kokluyor; sürekli bip ve misina akıyor = koşu → dokun. İri balık, uzun çekişme. | dip kamışı, kurşun, yem, sehpa + zil | rütbe 4 |
| Sinek | Yalnızca dere ağzında. Akıntıya at, sinek sürüklenir; halka çıkınca 0,5 sn içinde dokun. Hafif, zıplayan çekişme. | sinek kamışı, sinek | rütbe 7 |
| Kerevit tuzağı | Sığ kıyıya bırak. Oyunda değilken de dolar: 20 dk'da bir, en çok 4. İçi bırakılırken belirlenir. | tuzak (en çok 3) | rütbe 3 |

### 10.4 Dükkân, takım ve para

- **Nine'nin dükkânı:** sekmeler: kamış, makara, misina, iğne, yem, yapay yem ve sinek, şamandıra, ekstra.
  - Her eşyada en çok 2 değer, çubukla gösterilir; şimdiki takımla karşılaştırılır.
  - Rütbe kilidi var.
  - Sade tutulur: araştırmada en çok "seçenek kalabalığı" eleştirildi.

| Kategori | Ne yapar | Kademe |
|---|---|---|
| Kamış (teknik başına) | menzil, güç (balığın çekişini azaltır) | 3–4 |
| Makara | sarma hızı, fren (gerilim tepesini kırpar) | 4 |
| Misina | dayanım (kopma eşiği), görünmezlik (ürkek balık) | 4 |
| İğne | tutma (kaçışı azaltır) | 3 |
| Yem | tür çekimi; tükenir, solucan bedava ve sınırsız | 6 |
| Yapay yem, sinek | yırtıcı ve alabalık çekimi; kalıcı | 5 + 3 |
| Şamandıra | hassasiyet (VUR süresi +), görünürlük | 3 |
| Ekstra | kepçe (son anda bir kaçışı kurtarır), sehpa + zil, sandal, tuzak, fener (gece), kova kapasitesi | — |

- **Takım çantası:** her teknik için kuşanılmış bir set; teknik düğmesiyle geçilir.
- **Kova ve satış:**
  - Tutulan balık kovaya girer; dükkânda "hepsini sat" yapılır (Kazı'nın sırt çantası düzeni).
  - Kova dolunca Dede uyarır; kova kapasitesi dükkândan büyür.
  - Her türün en iyisi akvaryuma konabilir (§10.6).
- **Bırakma:** bırakılan balık para vermez; göl sevgisi ve rütbe puanı verir.
- **Para:** yalnızca oynayarak kazanılır, gerçek parayla asla satılmaz. Bu yüzden oranı değiştiren yem ve yapay yem satılabilir (§11).
- **Rütbe 1–20:** rütbe puanı av ve isteklerden gelir; bölge ve takım kilitlerini açar.
- **Denge hedefleri** (denge botunun korkulukları):

| Hedef | Süre |
|---|---|
| spin takımı | 4–10 dk |
| tuzak | 10–20 dk |
| dip takımı | 15–35 dk |
| sinek | 60–120 dk |
| sandal | 90–180 dk |
| bütün kademeler | 8–15 saat |

### 10.5 Canlı dünya

- **Oyun saati:**
  - 24 dk = 1 gün: sabah, öğle, akşam ve gece 6'şar dk.
  - Saat yalnızca oynarken akar; yokken durur, ceza yok.
  - Dede'yle çay = sonraki vakte geç (ücretsiz).
  - Gerçek saat kullanılmaz: hep aynı saatlerde oynayan da her vakti görür, çocuk gece balığı için uyanık kalmaz.
- **Hava:** her oyun günü için tohumlu (seed'li): açık %55, bulutlu %20, yağmur %15, sis %10 (yalnızca sabah ve gece).
  - Yağmur ısırmayı artırır.
  - Sis ve gece bazı türlerin tek zamanı.
- **Göl sevgisi:**
  - **Kaynaklar:** bırakılan balık (kademeye göre 1–40), toplanan çöp (3), istekler.
  - **Etki:** 10 seviye; Nadir+ ağırlıkları seviye başına %4 artar, en çok %36. Defterdeki oranlara yansır.
  - Göl seviyeyle güzelleşir: çiçek, kuş, kelebek, daha berrak su.
  - Hiç azalmaz.
- **Dede'nin istekleri:**
  - Her oyun günü boş yuvalar dolar (3 yuva); süre sınırı yok, günde bir kez ücretsiz değiştirme hakkı var.
  - Örnekler: "30 cm üstü kadife", "spinle 2 levrek", "gece bir balık", "3 balık bırak", "2 çöp topla".
  - Ödül: para, rütbe puanı, göl sevgisi; bazıları harita parçası verir.
  - Kazı'daki `quests.gd` uyarlanır.
- **Gölün Sırrı:**
  1. Dede efsaneyi anlatır; ilk şişe sazlıkta çıkar.
  2. Her bölgeden bir mektup çıkar (6 mektup). Mektuplar Dede ile Nine'nin gençliğini anlatır: göl ölürken onu temizlemişler.
  3. Dede'nin özel isteklerinden 4 harita parçası gelir. Göl sevgisi 6 olunca Nine "altın hamur" verir.
  4. Final: gece ve sisli bir havada, derin ortada, dip tekniği ve altın hamurla Bekçi'nin gölgesi çıkar. Çok evreli bir çekişme olur; Bekçi tutulur ve yalnızca bırakılır. Bitiş sahnesi oynar, jenerik akar, göl çiçek açar.

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

- **Sol üst:** para, kova (5/12), rütbe rozeti. Başlık ve sürüm yazısı ayarlara taşınır.
- **Üst orta:** saat ve hava çipi. Çekişmede yerini gerilim çubuğu alır.
- **Sağ üst:** harita, defter, ayarlar (her biri ≥122).
- **Sol alt:** teknik düğmesi.
- **Sağ alt:** eylem düğmesi (300).
- **Alt orta:** Dede'nin ipucu çubuğu.
- **Fotoğraf:** balık kartındaki ve ayarlardaki kamera düğmesi.

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
  - H2'de eklenecekler 🔜:
    - takım ve para: `Loadout`, `GearStats`, `Economy`, `Bucket`, `Rank`, `CatchOdds` (oranlar ve şans garantisi);
    - teknikler: `Technique` stratejileri (`FloatTechnique`, `LureTechnique`, `BottomTechnique`, `FlyTechnique`), `TrapSim`;
    - göl: `ShorePath`;
    - canlı dünya: `DayClock`, `Weather`, `LakeLove`, `Requests`, `Story`.
  - Denge botu (`SessionSim`, `tools/economy_report.gd`) ile korkuluk testleri; oran kataloğu (`tools/fish_catalog.gd`).
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
- Nine, erkek balıkçı ve kedi için hangi modeller?
- Kazı'ya benzerlik hissediliyor mu?
