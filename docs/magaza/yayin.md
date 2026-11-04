# Yayın: Google Play ve App Store beyanları, inceleme notu

Olta: Gölün Sırrı'nın mağaza sürümü (1.0.0) için Ersin'in iki konsolda dolduracakları. Kazı'da işe yarayanlar örnek
alındı (Kazı'nın reposunda `docs/android-yayin.md` §9, App Store'un "Information Needed" (2.1) cevabı). Metinler:
[`magaza-metinleri.md`](magaza-metinleri.md). AdMob ve gizlilik sayfası: [`../reklam-kurulum.md`](../reklam-kurulum.md).
Derleme: [`../reklam-mac.md`](../reklam-mac.md).

## Künye

| | |
|---|---|
| Ad | Olta: Gölün Sırrı (İngilizcesi: Olta: Secret of the Lake) |
| Paket kimliği | `com.juiloot.olta` (iki mağazada da) |
| Sürüm | 1.0.0, Android sürüm kodu 1, iOS yapı numarası 1 |
| Kategori | Oyun → Simülasyon (Play: Simülasyon; App Store: Games → Simulation, ikinci: Casual) |
| Hedef kitle | 13 yaş ve üstü (Kazı gibi; çocuk kategorisi değil) |
| Gizlilik politikası | `https://ersinaydogmuss.github.io/olta-gizlilik/` (kaynağı `docs/gizlilik-sayfasi/index.html`) |
| Web sitesi | `https://ersinaydogmuss.github.io` (app-ads.txt orada) |
| İletişim e-postası | `ersincodes@gmail.com` (Kazı'nınki) |
| Geliştirici adı | Play'de **Juiloot** yazılabilir (Play Console → Ayarlar → Geliştirici hesabı). App Store'da kişisel hesapta kimlikteki ad soyad görünür; "Juiloot" için hesabın şirkete (Organization: Ltd. ya da A.Ş., D-U-N-S numarası) çevrilmesi gerekir. |

## Gizlilik sayfası (ilk iş)

1. GitHub'da herkese açık `olta-gizlilik` deposunu aç (Kazı'nın `kazi-gizlilik`'i gibi).
2. Bu repodaki `docs/gizlilik-sayfasi/index.html` dosyasını o deponun köküne `index.html` olarak yükle (GitHub'da
   **Add file → Upload files**). İstersen bana depoyu açtığını söyle; ben yüklerim.
3. **Settings → Pages → Branch: main** → Save. Birkaç dakika sonra `https://ersinaydogmuss.github.io/olta-gizlilik/`
   açılır. Oyunun içindeki "Gizlilik politikası" düğmesi bu adresi açar.

## Google Play Console

### Uygulama içeriği beyanları

- **Gizlilik politikası:** yukarıdaki adres.
- **Reklamlar:** "Evet, uygulamam reklam içeriyor". Mağaza sayfasında "Reklam içerir" etiketi çıkar.
- **Uygulama erişimi:** "Tüm işlevler özel erişim gerekmeden kullanılabilir" (hesap ya da giriş yok).
- **Reklam kimliği:** "Evet"; amaç **Reklam veya pazarlama** (ve Analiz). `AD_ID` iznini reklam SDK'sı ekler.
- **İçerik derecelendirmesi** (IARC anketi): şiddet yok, korku yok (Gölün Bekçisi dost bir efsane), kumar yok (parayla
  şans satılmaz; oranlar ve şans garantisi görünür), kullanıcılar arası iletişim yok, konum paylaşımı yok, dijital satın
  alma yok (1.0'da). Sonuç büyük olasılıkla PEGI 3 / USK 0 / ESRB Everyone.
- **Hedef kitle ve içerik:** yaş grupları **13–15, 16–17, 18 ve üstü** (13 yaş altı seçilmez: Aileler politikası ve
  çocuğa yönelik reklam gelirdi; o zaman `Ads.CHILD_DIRECTED = true` gerekir). "Uygulama çocukların ilgisini çekebilir mi"
  sorusuna dürüst cevap: oyun her yaşa hitap eden rahat bir oyun; Play "çocuklara hitap ediyor" derse karma kitleye
  dönülür (`CLAUDE.md`, Gelir kuralları 2).
- **Veri güvenliği** (Google'ın AdMob tablosuna göre; oyunun kendisi bir şey toplamaz):

  | Veri türü | Toplanıyor | Paylaşılıyor | Amaç |
  |---|---|---|---|
  | Konum → Yaklaşık konum (IP adresinden) | Evet | Evet (Google) | Reklam, Analiz, Dolandırıcılığı önleme |
  | Uygulama etkinliği → Uygulama etkileşimleri | Evet | Evet | Reklam, Analiz, Dolandırıcılığı önleme |
  | Uygulama bilgileri ve performansı → Teşhis | Evet | Evet | Analiz, Dolandırıcılığı önleme |
  | Cihaz veya diğer kimlikler → Reklam kimliği, uygulama grubu kimliği | Evet | Evet | Reklam, Analiz, Dolandırıcılığı önleme |

  - Veriler aktarılırken şifreleniyor: **Evet**.
  - Kullanıcı verinin silinmesini isteyebilir mi: **Hayır** (sunucu ve hesap yok; reklam kimliği telefonun ayarlarından).
  - Toplama isteğe bağlı mı: **Hayır** (reklamlar için gerekli); AB'de onay penceresi ve Ayarlar → Gizlilik → Reklam
    seçimleri ayrıca var.
  - Fotoğraflar: oyun fotoğraf çeker ama cihazdan çıkmaz (toplanmaz, paylaşılmaz): beyan edilmez.
- **Haber uygulaması, sağlık, finans, devlet:** hayır.

### Mağaza girişi

- Metinler `magaza-metinleri.md`; İngilizcesi çeviri olarak.
- Görseller (`docs/magaza/gorsel/`): 512×512 ikon `play_ikon_512.png` (uygulama ikonun), 1024×500 öne çıkan görsel
  `play_one_cikan_1024x500.png` (tanıtım görselin ve logon). Ekran görüntüleri: `docs/magaza/ekran/tr/play/` (sekiz
  tane, 1920×1080; aşağıda, "Ekran görüntüleri").
- **Kategori:** Oyun → Simülasyon; etiketler: Balıkçılık, Rahat, Tek oyunculu.

### Sürümler

1. **Dahili test** → AAB (`reklam-mac.md`) → test kullanıcıları.
2. **Kapalı test:** kişisel hesap 13 Kasım 2023'ten sonra açıldıysa üretimden önce en az 12 test kullanıcısı 14 gün
   kapalı testte olmalı. Kazı'da nasıl geçildiyse aynısı.
3. **Üretim:** Play Console'un ana sayfası eksikleri listeler.

## App Store Connect

### Uygulamayı aç

**Uygulamalar → + → Yeni Uygulama:** platform iOS, ad **Olta: Gölün Sırrı**, birincil dil Türkçe, paket kimliği
`com.juiloot.olta` (listede yoksa önce developer.apple.com → Identifiers'ta kaydet), SKU `olta`, kullanıcı erişimi tam.

### App Privacy (Uygulama Gizliliği)

**Veri topluyor musunuz: Evet** (AdMob). Seçilecekler:

| Veri türü | Bağlantılı mı (kimliğe) | İzleme için mi | Amaç |
|---|---|---|---|
| Konum → Yaklaşık konum | Hayır | Evet | Üçüncü taraf reklamı, Analiz |
| Tanımlayıcılar → Cihaz kimliği (IDFA) | Hayır | Evet | Üçüncü taraf reklamı, Analiz |
| Kullanım verileri → Ürün etkileşimi | Hayır | Evet | Üçüncü taraf reklamı, Analiz |
| Kullanım verileri → Reklam verileri | Hayır | Evet | Üçüncü taraf reklamı |
| Teşhis → Çökme verileri, Performans verileri | Hayır | Hayır | Analiz |

"İzleme" (tracking): kullanıcı izin verirse reklam kimliği (IDFA) başka şirketlerin uygulamalarıyla ilişkilendirilir:
**Evet**. Oyun izni Google'ın UMP'si üzerinden Apple'ın ATT penceresiyle ister (`NSUserTrackingUsageDescription`).

### Yaş derecelendirmesi

Anket: çizgi film şiddeti yok, korku yok, kumar ve şans oyunu yok (ödüllü reklam ve şans garantisi kumar değil; parayla
şans satılmaz), sınırsız web erişimi yok, kullanıcı içeriği yok. Sonuç büyük olasılıkla **4+**; hedef kitle 13+
olduğundan **Kids kategorisi seçilmez**.

### Fiyat ve bulunabilirlik

Ücretsiz; bütün ülkeler (ya da Kazı'daki gibi).

### İnceleme notu (App Review Information → Notes)

Kazı'nın ilk gönderiminde Apple 2.1 "Information Needed" demişti; not ve kısa bir ekran kaydıyla geçti. Olta için
şunu yapıştır (İngilizce; inceleyiciler İngilizce okur):

```
Olta: Secret of the Lake is a single-player, offline-friendly fishing game. There is no account, login, chat or
in-app purchase in this version.

How to play: tap the water in front of a fish shadow to cast, wait while the float bobs, tap STRIKE when it sinks,
then hold to reel (release when the line turns red). The first fish is scripted, so the reviewer can learn it in
under a minute. Settings (gear icon, top right) has a "How to play" guide.

Ads: the game shows Google AdMob ads. After the player catches 3 fish, an "About ads" card explains the ads once;
after the player taps "Got it", Google's UMP consent flow runs (in the EEA a consent form; on iOS the App Tracking
Transparency prompt, using NSUserTrackingUsageDescription). Rewarded ads are always optional: "Watch an ad: double
it" after selling fish at Nana's shop, in the aquarium panel and after Dede's request is done, and "Watch an ad:
bring it back" when a rare fish escapes. A short interstitial ad may appear at most once every 8 minutes, never in
the first 20 minutes, only during a screen fade when the player travels with the map or drinks tea. Ad content is
limited to PG. Privacy: Settings → Privacy (privacy policy, ad choices, licenses).

The game does not collect personal data itself; game progress and photos taken in photo mode stay on the device
(photos are visible in the Files app).

A screen recording showing the first catch, the ads card, the ATT prompt and the rewarded ad offers is attached.
```

### Ekran kaydı (Ersin çeker)

iPhone'da **Denetim Merkezi → Ekran Kaydı** (yoksa Ayarlar → Denetim Merkezi'nden ekle). TestFlight'taki sürümle,
**Kaydı sıfırla**dan sonra 2–3 dakika:

1. Açılış: "Balıkçını seç", film (ATLA), ilk balık.
2. 3 balık tut: "Reklamlar hakkında" kartı → ANLADIM → izleme izni penceresi.
3. Nine'de sat → **Reklam izle: 2 katı** → reklam (deneme reklamı ya da gerçek, dokunmadan) → para.
4. Ayarlar → GİZLİLİK → kart, Lisanslar.

Kaydı App Review Information'daki **Attachment** alanına yükle (ya da inceleyici isterse Resolution Center'dan gönder).

### Ekran görüntüleri

Hazır: [`ekran/`](ekran/). Görüntüleri bulut oturumunun `store` botu çekti: oyunun kendi ekranı ve arayüzü, üstüne yazı
eklenmedi. Her klasörde sekiz görüntü var, mağazaya numara sırasıyla yükle:

1. İskele: yayının iri gölgesi, Dede "Büyük gölge, büyük balık demek."
2. Yayınla çekişme: gerilim çubuğu.
3. Nilüferli koyda tutulan Destansı altın sazanın kartı.
4. Harita: altı bölge.
5. Fenerli gece: ateşböcekleri.
6. Gölün Bekçisi: sisli gece, sandalla X'te.
7. Akvaryum.
8. Nine'nin dükkânı.

| Klasör | Boyut (yatay) | Nereye |
|---|---|---|
| `ekran/tr/iphone/`, `ekran/en/iphone/` | 2868×1320 | App Store → iPhone 6,9 inç (Apple öteki iPhone boyutlarını bundan küçültür) |
| `ekran/tr/ipad/`, `ekran/en/ipad/` | 2752×2064 | App Store → iPad 13 inç. Oyun iPad'de de çalıştığı için bu set gerekli |
| `ekran/tr/play/`, `ekran/en/play/` | 1920×1080 | Google Play → Telefon. İstersen aynılarını 7 ve 10 inç tablete de yükle |

- `tr/` Türkçe görüntüler, `en/` İngilizce görüntüler.
  - App Store'da sağ üstteki dil menüsünden **English (U.S.)** seçince ona İngilizce seti yükle.
  - Play'de **Çevirileri yönet → English (United States)** altına İngilizce görüntüleri koy.
- iPhone setini Play'e yükleme. Play'de uzun kenar kısa kenarın en çok iki katı olabilir, 2868×1320 bunu aşıyor. Play'e
  `play/` setini yükle.
- Yeniden çekmek için: `CLAUDE.md` → `store` senaryosu.

## AdMob'u mağazaya bağla (yayından sonra)

Uygulama mağazada herkese açık olunca (Play'de üretim sürümü, App Store'da onaylı sürüm) AdMob → Uygulamalar → Olta →
Uygulama ayarları → **Uygulama mağazası ekle**. AdMob uygulamayı inceler; inceleme bitene kadar "Sınırlı reklam sunumu":
gerçek reklam az gelir.
