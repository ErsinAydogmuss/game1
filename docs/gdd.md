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
| Gümüş balığı | hafif, çevik | 4,6 sn | 4,8 sn | tutar |
| Çapak | ağır ama tembel | 7,1 sn | 7,4 sn | %72 tutar |
| Tatlısu kefali | sert kaçışlı | 7,4 sn | 7,7 sn | %94 tutar |
| Kadife | inatçı, ağır | 10,4 sn | 11,4 sn | koparır |
| Sudak | başını sallar (sık patlama) | 13,9 sn | 15,6 sn | koparır |
| Altın sazan | ağır, güçlü | 14,0 sn | 15,3 sn | koparır |
| Mersin | çok güçlü, uzun koşular | 17,4 sn | 18,7 sn | koparır |

  İyi ve yavaş oyuncu her balığı tutar. Kolay modda hep basılı tutan da tutar.
- **Takımla** (H2, `GearStats`): başlangıç takımı yukarıdaki bambu oltayla aynıdır. En iyi şamandıra takımıyla (`tools/reel_report.gd -- --gear=top`):

| Balık | İyi oyuncu (0,4 sn): başlangıç → en iyi takım | Hep basılı, en iyi takım (Normal) |
|---|---|---|
| Kızılkanat | 5,8 → 3,9 sn | tutar |
| Sazan | 10,7 → 6,9 sn | %36 tutar |
| Levrek | 9,5 → 5,7 sn | tutar |
| Turna | 13,7 → 8,0 sn | %38 tutar |
| Yayın | 16,1 → 9,7 sn | koparır |
| Gümüş balığı | 4,6 → 3,2 sn | tutar |
| Çapak | 7,1 → 4,9 sn | tutar |
| Tatlısu kefali | 7,4 → 4,8 sn | tutar |
| Kadife | 10,4 → 6,7 sn | %18 tutar |
| Sudak | 13,9 → 7,7 sn | %40 tutar |
| Altın sazan | 14,0 → 8,5 sn | %2 tutar |
| Mersin | 17,4 → 10,4 sn | koparır |

  Korkuluklar (`test_reel_model`): en iyi takımla yavaş oyuncu her balığı tutar; hep basılı tutan Nadir balığı en çok yarı yarıya, Destansı ve üstünü en çok %30 tutar; çekişme en çok %40 kısalır. Misinanın kopma süresi bu yüzden en çok 0,95 sn.

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

İlk beşi prototipten, öbür yedisi Dalga 2'de (bölge balıkları). Kimlikler değişmez; görünüş kodla
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
| `zander` | Sudak | Zander | 0,95 m | Nadir | 40–90 cm | 40 | başını sallar (sık patlama) | kayalık burun, derin orta | uzun, gri-yeşil, soluk çizgiler, cam gibi parlak göz, iki sırt yüzgeci |
| `wels` | Yayın | Wels Catfish | 1,5 m | Destansı | 100–250 cm | 120 | düzensiz, güçlü | iskele koyu (az), kayalık burun, dere ağzı, derin orta | koyu gri-kahve, bıyıklı, yassı baş |
| `golden_carp` | Altın Sazan | Golden Carp | 0,9 m | Destansı | 40–85 cm | 110 | ağır, güçlü | nilüferli koy | koi gibi altın-turuncu, beyaz lekeli, bıyıklı |
| `sturgeon` | Mersin Balığı | Sturgeon | 1,75 m | Efsanevi | 100–220 cm | satılmaz | çok güçlü, uzun koşular | derin orta (sandalla) | sivri burun, sırtta ve yanlarda kemik plakalar, burnun altında dört bıyık, üst lobu uzun kuyruk |

**Nadirlikler:** Sıradan (gri), Güzel (yeşil), Nadir (mavi), Destansı (mor), Efsanevi (altın), Masalsı (turkuaz; H2'de eklendi, yalnızca Gölün Bekçisi). İlk Efsanevi balık mersin; Masalsı balık henüz yok. Nadirlikler yalnızca sona eklenir; her kademenin bir simgesi, rütbe puanı ve göl sevgisi değeri var (§10.2, `data/rarities.json`).

**Değerler (para, orta boy):** yukarıdaki tabloda; boy çarpanı 0,6–1,6.

**Mersin koruma altında** (`release_only`): tutulur, kovaya girmez, satılmaz; kartta Dede "Mersin koruma altında evlat. Bir güzel bakalım, sonra bırakalım." der, düğme "Göle bırak" olur, bildirim "Mersin Balığı göle döndü". Rütbe puanı ve göl sevgisi verir; defterde "Koruma altında" yazar.

**Doğma ağırlıkları** bölgenin (`data/spots.json`). İskele koyu: kızılkanat 26, gümüş balığı 14, çapak 10, sazan 20, levrek 18, turna 8, yayın 4 (Ersin'in seçimi: turna ve yayın kalsın ama az çıksın). Bölgelerin yıldız balıkları (sudak, altın sazan, mersin) başlangıç koylarında çıkmaz. Testlerin gölünde 35/25/17/15/8.

**Sevdiği yem:** kurtçuk levrek ve gümüş balığı, ekmek hamuru sazan, levrek ve çapak, mısır sazan, kadife ve altın sazan, boili sazan, yayın, altın sazan ve çapak, karides yayın, turna, sudak ve tatlısu kefali. Mersin hiçbir yeme gelmez (dip tekniği Dalga 3'te).

**H2 türleri** (18 tür; bugünkü 5 kimlik korunur, sazan Güzel'e çıkar). Dalga 2'de 12'si oyunda (✅); alabalıklar, aynalı sazan, gece ve fırtına balıkları teknik ve vakitle gelir. Bölge, teknik ve vakit ayrıntısı §10.1 ve §10.3'te.

| Kademe | Türler |
|---|---|
| Sıradan | kızılkanat ✅, gümüş balığı ✅, çapak ✅, tatlısu kefali ✅ |
| Güzel | sazan ✅, levrek ✅, kadife ✅ |
| Nadir | turna ✅, sudak ✅, alabalık, aynalı sazan |
| Destansı | yayın ✅, altın sazan ✅, dere alabalığı |
| Efsanevi | mersin ✅ (yalnızca bırakılır; koruma mesajı), ay turnası (gece), Kocabaş (dev yayın, fırtınalı gece) |
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
- **Nine** (Dede'nin eşi):
  - ✅ İskelenin kara ucunun solundaki küçük ahşap dükkânı işletir: tezgâhın arkasında ayakta durur, yüzü iskeleye ve kameraya dönük. Balıkçı yaklaşınca ona bakar. Ona ya da dükkâna dokununca selam verir (balon, baş sallama, tezgâha uzanır); sözü ipucu çubuğunda kendi yüzüyle çıkar. Dükkân paneli 🔜 (Dalga 1, 6. adım).
  - ✅ KayKit Mage, yeniden boyanmış: gümüş saç, hardal sarısı hırka. Kodla beyaz, mavi çiçekli yazma (çenenin altında bağlı), turkuaz puantiyeli önlük, yuvarlak gözlük ve pembe yanaklar (Ersin'in portre tarifi). Büyücü şapkası, asa ve kitap gizli. Model yoksa kodla kurulan yedek çıkar.
  - ✅ Dükkân kodla kurulur: alçak döşeme, raflı arka duvar (yem kavanozları, kutular), tezgâh (solucan kovası, kavanozlar, mısır kasası, zil), olta sehpası ve kepçe, turkuaz-krem çizgili tente, "Nine'nin Dükkânı" tabelası; yanında fıçı, kasa, çuval. Kamera yukarıdan baktığı için tente yüksek ve kısa: Nine'nin başı altından görünür. Balıkçı dükkânın içinden geçmez.
  - Hikâyede gençliğini anlatır; göl sevgisi yükselince "altın hamur"u verir 🔜.
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
- **Değer:** her türün bir taban değeri var (Sıradan ≈5, Güzel ≈12, Nadir ≈35, Destansı ≈120, Efsanevi ≈500 para) × boy çarpanı (0,6–1,6). Masalsı satılmaz.
- **Şans garantisi:**
  - Nadir+ balık gelmeden geçen 40 avdan sonra, bulunduğun bölgede Nadir+ bir gölge doğar. Destansı+ için 150, Efsanevi için 400 av.
  - Sayaçlar defterde görünür.
  - Garanti öteki zarları kaydırmaz (Kazı'daki `LootTable` düzeni: sabit sıralı zar).
- **Balık Defteri:**
  - Kademeye göre ızgara; bulunmamış türler siluet ve ipucuyla (bölge, teknik, vakit, hava).
  - Rekorlar; o yerdeki, teknikteki ve vakitteki tam oranlar; şans garantisi sayaçları; göl sevgisi.
  - ✅ Dalga 1'deki hâli: sağ üstteki defter düğmesiyle açılır (olta sudayken gizli). Nadirlik sırasıyla 6×2'lik sayfalar (12'den çok tür olunca sayfa düğmeleri). Tutulan tür kendi resmi, adı, en büyük boyu ve nadirlik renginde çerçeveyle; tutulmayan koyu siluet, "???" ve nadirlik simgesiyle (renksiz). Sağda seçili türün nadirliği, rekor boyu ve yıldızı, tutulan ve bırakılan sayısı, tanımı; tutulmadıysa ipuçları (sevdiği yem, gölde ne sıklıkla görüldüğü). Altında takımınla bir gölgenin bu balık olma şansı, gölün nadirlik oranları ve şans garantisi sayaçları ("9 av içinde garanti"). Oranlar gölgeyi doğuran işlevin aynısından gelir.
  - ✅ Garanti yalnızca gölde tutulabilen kademeler için yazılır ve işler: Köy Gölü'nde Efsanevi tür yokken dolan Efsanevi sayacı Nadir ve Destansı garantisini kilitlemez (`CatchOdds.pity_floor(db, save, spot)`).

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
  - ✅ Dalga 1'deki hâli: Nine'ye ya da dükkâna dokununca açılır (kovada balık varsa Kova sekmesi, yoksa en son bakılan sekme). Üstte Nine'nin yüzü ve sözü ("Hoş geldin evladım!", "Güle güle kullan!", "Paran biraz eksik...", "Rütbe 4 olunca gel!", "Eline sağlık!") ve para. Sekmeler: Kova, Kamış, Makara, Misina, İğne (iğne ve şamandıra), Yem, Ekstra (kepçe, sandal ve sıradaki kova: kovalar tek kartta, sahip olunanın bir üstü; Dalga 2). Her sekmede en çok 6 kart (3×2), kaydırma yok.
  - ✅ Kart: ikon (Ersin'in ekipman görseli gelene kadar kodla çizilir), ad, kısa açıklama, değer çubukları (koyu çizgi kuşanılanın yeri; yeşil daha iyi, turuncu daha zayıf; menzil ve kova kapasitesinin sayısı da yazar) ve tek düğme: fiyat (al ve tak), TAK, TAKILI, SENDE ya da kilitli rütbe. Para yetmeyen ya da rütbesi tutmayan düğme gri kalır ama basılınca Nine nedenini söyler (kilit sessiz kalmaz). Kuşanılan kartın kenarı yeşil.
  - ✅ Yem kartında çektiği balıklar ve bir gölgenin o balık olma şansı solucanla ve bu yemle ("Levrek %22 → %41"; defterdeki oranın aynısı), elindeki sayı ve paket boyu. Takılı yem yeniden alınabilir.
  - ✅ Sesler: satın almada tezgâh zili, kuşanmada tıkırtı, satışta para şıkırtısı; her birinin titreşimi ve Nine'nin sözü var.

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

- **Takım çantası:** her teknik için kuşanılmış bir set; teknik düğmesiyle geçilir. Dalga 1'de tek teknik (şamandıra) olduğundan kuşanma dükkânda yapılır; çanta teknik düğmesiyle Dalga 3'te gelir.
- **Kova ve satış:**
  - Tutulan balık kovaya girer; dükkânda "hepsini sat" yapılır (Kazı'nın sırt çantası düzeni). ✅ Kova sekmesinde tür başına bir satır (sayı, değer), altta toplam ve HEPSİNİ SAT.
  - Kova dolunca Dede uyarır ✅ (kova her dolduğunda; dolu kovaya gelen balık göle döner ve bildirim çıkar); kova kapasitesi dükkândan büyür.
  - Her türün en iyisi akvaryuma konabilir (§10.6).
- **Bırakma:** bırakılan balık para vermez; göl sevgisi ve rütbe puanı verir.
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
| spin takımı | 4–10 dk |
| tuzak | 10–20 dk |
| dip takımı | 15–35 dk |
| sinek | 60–120 dk |
| bütün kademeler | 8–15 saat |

- ✅ **Denge botu** (`SessionSim`): oyunun kurallarını aynen kullanır (oranlar ve şans garantisi `CatchOdds`, boy `FishTable`, çekişme `ReelModel` + tepkili oyuncu botu, kova, rütbe, satış), yalnızca zamanı ve el becerisini taklit eder. Süreler `data/sim.json`'dan; atış, balığın gelişi, dürtmeler ve çekişme uzaklığı `tools/session_timing.gd` ile gerçek `FishingSession`'dan ölçülür (insan gibi şaşarak nişan alan bot). Ölçüm (başlangıç takımı): ısırmaya ortalama 9 sn (atış ve geri sarma dahil), dürtmeler 2,8 sn, çekişme 5,2 sn, takılma uzaklığı 4,5 m; saatte 225 av (satışsız). İnsan hatası tahmin: ısırmaların %15'i kaçırılır.
- ✅ **Dalga 1 ölçümü** (iskele koyu, 3 seed): saatte yaklaşık 3.100 para ve 200 av; rütbe 20'ye 5 saatte varılıyordu.
- ✅ **Bölgeli denge botu** (Dalga 2): kıyı bölgesini oyuncu gibi seçer. Önce gidilmemiş açık bölgeye gider (yeni bölge açılınca hemen), sonra defterde tutulmamış türü en çok olana, sonra balık başına en çok kazandırana. Sandalı rütbesi yetince öncelikle alır, parası yetene kadar başka şey almaz; sonra kovaların yarısını derin ortada doldurur (`boat_share`, tahmin). Bölge değiştirmek ve satmak için iskeleye dönmek 6 sn sürer (`travel_s`: harita, dokunuş, kararma). Bölge başına süreler `session_timing.gd --zone=` ile ölçülür (`sim.json` "zones").
- ✅ **Rütbe eğrisi uzadı:** bölgeler rütbe 3–9'da açıldığı için eşikler 0, 60, 300, 600, 950, 1.400, 2.050, 2.900, 4.000, 5.000 … 26.000 (rütbe 20). Eski kayıtta rütbe ve rütbedeki ilerleme korunur: kayıt sürümü 3, puan yeni eğriye taşınır (`SaveData.remap_xp`). Sandal 3.500 para.
- ✅ **Dalga 2 ölçümü** (`tools/economy_report.gd -- --hours=12 --seeds=6`): saatte yaklaşık 5.400 para ve 176 av. Zamanın ~%52'si dere ağzında, ~%42'si derin ortada geçiyor (en çok kazandıran iki yer); öteki kıyı bölgelerine yeni türleri tutmak için gidiliyor. Korkuluklar `tests/test_session_sim.gd`'de (200 dk, 3 seed); "yeni bölge öncekilerden az kazandırmaz" `test_economy.gd`'de.

| Olay (ilk kez) | Dakika | Korkuluk |
|---|---|---|
| ilk satış | 2–3 | ≤ 5 |
| ilk alışveriş (misina) | 3–7 | ≤ 10 |
| rütbe 2 / 3 / 5 / 7 / 9 | 1–3 / 6–13 / 19–28 / 44–51 / 75–89 | ≤ 5 / 5–15 / 15–35 / 38–65 / 70–120 |
| rütbe 10 / 15 / 20 | 92–110 / 200–237 / 360–390 | — |
| ilk gidiş: sazlık / nilüferli koy / kayalık burun / dere ağzı | 2–3 / 6–13 / 19–28 / 44–51 | — / 5–15 / 15–35 / — |
| gölün 5 türü / 11 kıyı türü / mersin (12.) | 2–4 / 21–34 / 132–176 | ≤ 30 / — / 100–200 |
| makara, iğne, şamandıra (ilk kademe) | 3–25 | — |
| cam kamış | 20–30 | 10–45 |
| büyük kova | 23–37 | 15–60 |
| floro misina, hızlı makara, kepçe, büyük iğne | 38–82 | kepçe 40–100 |
| sandal (3.500) ve derin orta | 115–147 | 90–180 |
| güçlü makara, parlak şamandıra, balık filesi | 126–195 | — |
| örgü misina, karbon kamış, usta florokarbon | 185–263 | — |
| usta makarası, büyük file, altın örgü | 269–444 | — |
| altın makara (15.000) / dev file (15.000) | 546–590 / 2 seed'de ~690 | — |

- **Değerlendirme:** ilk saat dolu: yeni bölge yaklaşık 10, 25 ve 48. dakikada, araya alışverişler giriyor. Sandal rütbe 9'dan sonra 30–60 dakikalık bir birikim hedefi; alınınca balık başına kazanç ~1,7 katına çıkıyor (derin ortada ~40 para, dere ağzında ~24). Rütbe 20'ye ~6 saatte varılıyor (Dalga 1'de 5). Şamandıra takımının neredeyse hepsi 12 saatte alınıyor (dev file 6 seed'in 2'sinde); Dalga 3'te tekniklerin takımı gelince fiyatlar "bütün kademeler 8–15 saat" hedefine göre yeniden ayarlanır.
- ✅ **Yemler** para kazandırmak için değil, istenen türü (defter, rekor, ileride istekler) aramak içindir. Her yem kendi türünün şansını belirgin artırır (iskele koyunda kurtçuk levrek %18 → %32 ve gümüş balığı %14 → %20, mısır sazan %20 → %43, karides yayın %4 → %10 ve turna %8 → %17; sazlıkta mısır kadife %22 → %30; nilüferli koyda boili altın sazan %6 → %9,6). Ucuz yemler balık başına ~1,5–2 para; karides balık başına 10 para ve ortalama değeri solucandan yüksek olduğu için aşağı yukarı başa baş. Bütün oranlar ve balık başına ortalama değer [`balik-katalogu.md`](balik-katalogu.md)'de (`tools/fish_catalog.gd` üretir).

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
