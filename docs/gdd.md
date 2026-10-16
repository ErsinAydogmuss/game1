# Olta: Gölün Sırrı — Oyun Tasarım Belgesi (kısa sürüm v0.1)

> Kısa sürüm. Tam tasarım belgesi, 3. haftadaki devam/vazgeç testinden sonra yazılacak ([`yol-haritasi.md`](yol-haritasi.md)). ✅ = prototipte var, 🔜 = planlı. Fikrin neden seçildiği: [`fikirler.md`](fikirler.md).

## 1. Vizyon

**"Kıyını süsle, havayı bekle: bu gece oltana ne takılacak?"**

Yazı Dede'nin göl köyünde geçiren bir çocuk ya da genç balıkçısın. Gölde balık gölgeleri dolaşıyor. Gölgenin önüne oltanı atıyorsun; gölge fark edip yaklaşıyor, şamandırayı dürtüyor ve sonunda ısırıyor: VUR! Sonra gerilim çubuğunu kırmızıya kaçırmadan çekiyorsun.

İleride kıyıyı süsleyerek hangi balığın geleceğini sen belirleyeceksin. Tuttuğun balıklar satılmayacak, canlı akvaryumunda yaşayacak.

- **Platform:** iOS + Android, yatay ekran, low-poly 3D.
- **Model:** ücretsiz oyun; gelir kuralları [`CLAUDE.md`](../CLAUDE.md)'de.
- **Kitle:** aile dostu, her yaş. Hedef Apple 4+/9+, PEGI 7. Çocuk kategorisine girilmez.
- **Dil:** baştan Türkçe + İngilizce.

## 2. Tasarım sütunları

1. **Her gölge bir soru.** Gölgenin boyu balığın boyunu ele verir, türünü vermez. "Bu kocaman gölge ne?" merakı oyunun motorudur.
2. **Tek parmak, her yaş.** Dokun-yürü, dokun-at, değdiği an VUR, basılı tut-çek. Okumadan oynanır.
3. **Çağır, sakla, sergile** 🔜. Kıyı süsleri hangi balığın geleceğini belirler; balıklar akvaryumda yaşar.
4. **Sakin ve adil.** Oyuncu yokken ceza yok; parayla şans satılmaz; kötü şansa karşı garanti var.
5. **Kısa oturum.** Bir atış 15–40 saniye; bir oturum 5–10 dakika.

## 3. Döngüler

| Döngü | Süre | İçerik | Durum |
|---|---|---|---|
| Çekirdek | 15–40 sn | Dokun → at → gölge yaklaşır, dürter → ısırır → VUR → çek → balık elde, kart | ✅ |
| Oturum | 5–10 dk | Kova dolar → kopyaları sat, yenileri akvaryuma koy → olta, yem ya da süs al → kıyı süsünü değiştir, yeni türü çağır | 🔜 (H2) |
| Haftalar | günler | Ansiklopedi (silüetler ve ipuçları), yeni sular, gece ve hava balıkları, köy, sezonluk türler, "Gölün Sırrı" hikâyesi | 🔜 |

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
  - Balık zaman zaman çırpınır.
  - Her patlamadan **0,5 sn önce** uyarı gelir: balık çırpınır, misina titrer, gıcırtı duyulur, telefon titrer, "!" çıkar.
  - Patlamada basılı tutarsan gerilim kırmızıya çıkar.
- **Kopma:** gerilim sınırın üstünde toplam 0,8 sn kalırsa misina kopar ("Misina koptu!"). Sayaç sınırın altında yavaşça geri iner.
- **Kaçma:** balık menzil + 2 m'den uzağa kaçarsa gider.
- **Yakalama:** balık 0,6 m'ye gelince tutulur.
- **Kolay çekme (Ayarlar):** gerilim tavanlıdır, misina kopmak yerine kayar, balık kaçmaz; beceri yalnızca hızı belirler.
- **Süre:** iyi bir oyuncuyla çekişme Kızılkanat'ta 4–7 sn, Yayın'da 14–20 sn sürer.
- **Kolay modda** patlamada basılı tutunca misina kayar: balık, kaçış hızının 2 katıyla uzaklaşır. Hep basılı tutan yine tutar; bırakmayı bilen daha hızlı tutar.
- **Denge raporu** (`tools/reel_report.gd`; 4–9 m'den 200 deneme, ortalama süre):

| Balık | Çekiş | İyi oyuncu (0,4 sn tepki) | Yavaş oyuncu (0,7 sn) | Hep basılı (Normal) |
|---|---|---|---|---|
| Kızılkanat | sakin | 5,4 sn | 5,6 sn | tutar |
| Sazan | ağır | 10,1 sn | 10,7 sn | koparır |
| Levrek | ani | 8,6 sn | 9,4 sn | %62 tutar |
| Turna | ani, güçlü | 12,6 sn | 13,9 sn | koparır |
| Yayın | düzensiz, güçlü | 15,1 sn | 16,5 sn | koparır |

  İyi ve yavaş oyuncu her balığı tutar. Kolay modda hep basılı tutan da tutar.

**Sonuç**

- Tutulan balık elde gösterilir; boy ve yıldızıyla yazı çıkar.
- **Tam kart** yalnızca yeni tür, yeni rekor ya da Nadir ve üstü için açılır; tekrarlarda kısa bildirim.
- **Yıldız** boy yüzdeliğinden gelir:

| Yüzdelik | <0,2 | <0,45 | <0,7 | <0,9 | gerisi |
|---|---|---|---|---|---|
| Yıldız | ★ | ★★ | ★★★ | ★★★★ | ★★★★★ |

- Boylar çoğunlukla küçük, büyükler seyrek: yüzdelik = u^1,6. Beş yıldız ~%6.

**İlk açılış**

- Oyun doğrudan iskelede başlar; Dede ipucu çubuğundan konuşur.
- İlk gölge iskelenin önüne gelir ve ilk av senaryoludur: hep Kızılkanat, dürtmesiz. İlk balık 45 sn içinde gelir.
  - İlk av göldeyken şamandıraya yalnızca o gelir. Nereye atılırsa atılsın fark eder ve korkmaz.
  - Erken dokunuş onu kaçırmaz, yalnızca irkiltir. Pencere kaçarsa biraz sonra yeniden ısırır. Çekişmesi Kolay kurallarıyla.
  - İlk atışa kadar ilk av gölgesinin çevresinde arada bir halka çıkar ("bu gölge!").
- Dede'nin ipuçları ilk 3 balığa kadar ipucu çubuğunda görünür; oyunun durumuna göre değişir.

**Kayıt**

- Her yakalayışta ve uygulama arka plana geçince kayıt alınır.
- Uygulama odağı kaybedince (arama, Denetim Merkezi) ya da Ayarlar açıkken çekişme donar.
- Her oturum yeni gölgelerle başlar (seed + oturum sayacı).

## 6. Balıklar (prototip) ✅

| Kimlik | TR | EN | Taban gölge | Nadirlik | Boy | Çekiş | Doğma | Görünüş |
|---|---|---|---|---|---|---|---|---|
| `rudd` | Kızılkanat | Rudd | 0,5 m | Sıradan | 15–30 cm | sakin | 35 | gümüş gövde, kırmızı yüzgeçler |
| `carp` | Sazan | Carp | 0,75 m | Sıradan | 30–80 cm | ağır | 25 | bronz-altın, koyu sırt, iri pullar |
| `perch` | Levrek | Perch | 0,75 m | Güzel | 20–45 cm | ani | 17 | yeşil-sarı, koyu dikey çizgiler, turuncu yüzgeçler |
| `pike` | Turna | Pike | 1,05 m | Nadir | 50–120 cm | ani, güçlü | 15 | uzun, zeytin yeşili, açık benekler |
| `wels` | Yayın | Wels Catfish | 1,5 m | Destansı | 100–250 cm | düzensiz, güçlü | 8 | koyu gri-kahve, bıyıklı, yassı baş |

**Nadirlikler:** Sıradan (beyaz), Güzel (yeşil), Nadir (mavi), Destansı (mor), Efsanevi (altın). Efsanevi henüz yok; "Gölün Sırrı" ona ayrıldı. Nadirlikler yalnızca sona eklenir.

**Sonraki türler 🔜:** 15 tür ve gece, yağmur, sabah türleri; çöp eşyalar (eski çizme, şişede not); renk varyantları.

## 7. Kahraman ve Dede

- **Kendi balıkçın:**
  - 1. hafta kız balıkçıyla çıkar (KayKit Rogue, yeniden boyanmış; kodla balıkçı şapkası).
  - Erkek balıkçı ve seçim ekranı H2'de 🔜. KayKit'teki erkek modeller ya zırhlı (Knight) ya sakallı (Barbarian); karakter sayfasıyla bakılacak.
  - Kostümler (şapka, yelek, olta kaplaması) sonra gelir 🔜.
- **Dede:**
  - Köyün yaşlı balıkçısı.
  - 1. hafta yalnızca ipucu çubuğunda konuşur (yer tutucu portre).
  - Sonra iskelede oturur (KayKit Barbarian, beyaz sakal), eğitimi verir, istekte bulunur ("bana bir turna getir") ve "Gölün Sırrı"nı parça parça anlatır 🔜.

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
  - Elde gösterilen boy logaritmik: 250 cm'lik yayın en fazla 1,1 m görünür.
- **Çevre:** iskele (tahta), sazlık, KayKit ağaç, kaya, çadır, fıçı ve fenerleri; Kazı'nın çimeni, ışığı ve ortamı.
- **Dış çizgi** yalnızca karakterlerde ve balıklarda.
- **Erişilebilirlik:** gerilim çubuğu renk + ikon + sarsıntı + "BIRAK!" yazısı. Her sesin bir görsel ve titreşim karşılığı var.

## 9. Ses

- ✅ Kodla üretilir (`tools/make_sounds.py`, Kazı'nın sentez yardımcıları):
  - atış vınlaması, şamandıra "plop", dürtme tıkı;
  - ısırma sıçraması + zil;
  - makara tıkırtısı (döngü), gerilim gıcırtısı (döngü), misina kopması;
  - nadirliğe göre buluntu;
  - arayüz sesleri;
  - göl ortam sesi (su, kuş, rüzgâr).
- 🔜 Müzik: sakin kalimba ve ud (H3).
- iPhone'un sessiz anahtarı açıkken oyunun sesi çıkmaz (Kazı deneyimi).

## 10. Sonraki sistemler 🔜

- **Kova ve satış (H2):** kova 6 balık alır. Kopyalar köye satılır; yeni türler ve rekorlar akvaryuma gider.
- **Dükkân (H2):** 2 olta, 2 yem. Olta menzil, isabet ve çekme hızı verir.
  - Şansı değiştiren her şey yalnızca oyun parasıyla alınır.
- **Akvaryum (H2):** tuttuğun türler yüzer. Köylüler ziyaret eder ve bilet parası bırakır; bu boşta gelir üst sınırlıdır.
- **Kıyı süsleri ve tarifler (H2):**
  - Kıyının 4–6 süs yuvası var (sazlık, fener, nilüfer, yemlik...).
  - Süs + hava + saat bir türü çağırır; bulunan tarif o türü **garanti** eder.
- **Ansiklopedi (H2):** "?" silüetler ve ipuçları ("seviyor: fener, yağmur, gece").
- **Gece ve hava (H3):** gün döngüsü, yağmur; gece balıkları.
- **Sular (sonra):** göl → nehir → deniz → buzlu göl → mağara gölü.
- **Gölün Sırrı (sonra):** şişelerden çıkan notlar ve efsanevi göl canavarı.
- **Online (sonra):**
  - arkadaşın akvaryumunu gezme, hediye;
  - köyün ortak hedefi;
  - açık sohbet ve sık yarışma yok.

## 11. Gelir

Ayrıntı: [`saha-arastirmasi.md`](saha-arastirmasi.md) §7–8 ve [`CLAUDE.md`](../CLAUDE.md).

- **Satılacaklar:** kostümler ve görünüş süsleri (doğrudan satış, gerçek fiyat görünür), reklamsız / destekçi paketi, süresi dolmayan sezon kartı.
- **Ödüllü reklam** (isteğe bağlı): çift ödül, kopan misinayı kurtarma.
- **Parayla satılmayacaklar:** şans (nadir yem, ek atış, hava olayı).

## 12. Teknik özet

- **Motor:** Godot 4.7, statik tipli GDScript, Compatibility renderer.
- **Oyun mantığı** `scripts/core/` altında, saf ve testli: `FishingSession`, `ShadowSim`, `BiteRules`, `ReelModel`, `FishTable`, `LakeShape`, `Records`.
  - Çekişme sayıları `tools/reel_report.gd` ile denetlenir; `tests/test_reel_model.gd` sınırları korur.
  - İç adım sabit 1/60 sn; sonuç fps'e ve video kaydına bağlı değil.
- **Sunum** yalnızca olayları dinler.
- **Kazı'nın genel altyapısı** kullanılır: test koşucusu, kayıt, arayüz parçaları, ses, bot.
- Ayrıntılar ve kurallar: [`CLAUDE.md`](../CLAUDE.md).

## 13. Açık sorular

- Gölgeler ve şamandıranın dürtmesi telefonda okunuyor mu?
- VUR penceresi ve çekişme her yaşa adil mi? Kolay çekme varsayılan mı olmalı?
- Kazı'ya benzerlik hissediliyor mu?
- Erkek balıkçı için hangi model?
- Uzun vadede tarif sistemi tek başına yeterli merakı veriyor mu (H2 testinde)?
