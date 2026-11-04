# Reklamlar: Ersin'in yapacakları (AdMob, mağazalar)

Olta'nın reklamları Kazı'daki gibi Google AdMob'dan gelir. Kod hazır: ödüllü reklamın dört yeri, seyrek geçiş reklamı,
"Reklamlar hakkında" kartı, Ayarlar'da Gizlilik ve Lisanslar (`docs/gdd.md` §11). Oyunun telefonda gerçek reklam
göstermesi için senden şunlar lazım. Kazı'yı kurduğun AdMob hesabını kullanırsın (yayıncı `pub-8552904073566888`);
yeni hesap açma.

**Sıra:**

1. AdMob'da iki uygulama ve dört reklam birimi (aşağıda §1). Altı kimliği bana gönder, ben oyuna koyarım.
2. GitHub'da `olta-gizlilik` deposu ve sayfası (§3). Gizlilik adresi AdMob'da ve iki mağazada istenir.
3. AdMob → Gizlilik ve mesajlaşma (§2).
4. Mac'te derleme: Android paketi ve iPhone arşivi ([`reklam-mac.md`](reklam-mac.md)). Kimlikler oyuna girdikten sonra
   yap, yoksa sürümde reklam çıkmaz.
5. Play Console ve App Store Connect: beyanlar, metinler, ekran görüntüleri, inceleme notu ([`magaza/yayin.md`](magaza/yayin.md)).
6. Apple için kısa ekran kaydı. Play'de kapalı test: 12 test kullanıcısı, 14 gün (§4).

## 1. Şimdi: AdMob'da iki uygulama ve dört reklam birimi

1. [admob.google.com](https://admob.google.com) → **Uygulamalar → Uygulama ekle**.
   - Platform **Android**. "Uygulama mağazada yayında mı?" sorusuna **Hayır**. Ad: **Olta**. **Ekle**.
   - Aynısını **iOS** için yap (ad yine **Olta**).
   - Her uygulamanın bir **uygulama kimliği** olur: `ca-app-pub-8552904073566888~0123456789` biçiminde (ortada `~`).
2. Her iki uygulamada **Reklam birimleri → Reklam birimi ekle**:
   - **Ödüllü** (Rewarded): ad `olta_rewarded`. Ödül ayarlarını olduğu gibi bırak (oyun ödülü kendisi verir).
   - **Geçiş** (Interstitial): ad `olta_interstitial`.
   - Her birimin bir **birim kimliği** olur: `ca-app-pub-8552904073566888/0123456789` biçiminde (ortada `/`).
3. Bana şu altı kimliği gönder (sohbete yapıştırman yeter; gizli değiller, uygulamanın içinde de yazar):

   | | Android | iOS |
   |---|---|---|
   | Uygulama kimliği (`~`) | | |
   | Ödüllü birim (`/`) | | |
   | Geçiş birimi (`/`) | | |

   Ben `project.godot`'a ve `data/ads.json`'a koyarım; testler biçimlerini ve hepsinin aynı yayıncının olduğunu denetler.
   Kimlikler gelene kadar sürüm derlemesinde reklam yok; telefona kurduğun deneme derlemesi (debug) Google'ın deneme
   reklamlarını gösterir.

## 2. AdMob → Gizlilik ve mesajlaşma

Kazı için yaptıklarının aynısı, Olta'nın iki uygulamasını da seçerek:

1. **Avrupa düzenlemeleri** (GDPR) mesajı: Olta'nın Android ve iOS uygulamalarını ekle, gizlilik politikası adresi
   `https://ersinaydogmuss.github.io/olta-gizlilik/`, **Yayınla**. AB'deki oyuncu ilk açılışta Google'ın onay
   penceresini görür (oyun "Reklamlar hakkında" kartından sonra açar).
2. **IDFA açıklama mesajı** (iOS, izleme izninden önceki ekran): oluştur ve **Yayınla**. iPhone'daki izleme izni
   penceresi bundan sonra gelir; açıklama yazısı oyunun içinde de var.
3. Kazı'daki mesajı düzenliyorsan Olta'yı ona eklemek de olur.

## 3. app-ads.txt ve gizlilik sayfası

- **app-ads.txt:** `https://ersinaydogmuss.github.io/app-ads.txt` Kazı için zaten var ve aynı yayıncı satırı Olta'yı da
  kapsar. Tek şart: mağaza sayfalarında **geliştirici web sitesi** olarak `https://ersinaydogmuss.github.io` yazmak.
  AdMob onu birkaç gün içinde bulur ve "Doğrulandı" der.
- **Gizlilik sayfası:** Olta'nın gizlilik politikası (Türkçe ve İngilizce) hazır: `docs/gizlilik-sayfasi/index.html`.
  Senden: GitHub'da `olta-gizlilik` adında herkese açık bir depo aç, bu dosyayı oraya `index.html` olarak yükle,
  **Settings → Pages**'te `main` dalını yayınla (Kazı'nın `kazi-gizlilik` deposu gibi). Adımlar:
  [`magaza/yayin.md`](magaza/yayin.md), "Gizlilik sayfası".

## 4. Sonra: mağazalar

Ayrıntılar: [`magaza/yayin.md`](magaza/yayin.md) (Play ve App Store beyanları, inceleme notu, ekran kaydı),
[`magaza/magaza-metinleri.md`](magaza/magaza-metinleri.md) (mağaza yazıları), [`reklam-mac.md`](reklam-mac.md) (Mac'te
derleme: Android paketi ve iPhone arşivi). Kısaca:

- **Paket adı** iki mağazada da `com.juiloot.olta`; Apple takımı Kazı'nınki (`3D9ZPVPY5L`).
- **Google Play Console:** yeni uygulama **Olta: Gölün Sırrı**, varsayılan dil Türkçe, **Oyun**, **Ücretsiz**.
  - Beyanlar: **Reklam içerir: Evet**; reklam kimliği (Advertising ID) **kullanılıyor** (reklamlar için);
    **Hedef kitle 13 yaş ve üstü** (çocuklar seçilmez; Kazı gibi); veri güvenliği tablosu Kazı'nınkiyle aynı
    (yaklaşık konum, uygulama etkileşimleri, tanılama, cihaz kimlikleri: AdMob için).
  - **Kapalı test şartı:** kişisel geliştirici hesabı 13 Kasım 2023'ten sonra açıldıysa her yeni uygulama, üretime
    çıkmadan önce **en az 12 test kullanıcısıyla 14 gün** kapalı testten geçer. Kazı'da nasıl geçtiysen Olta'da da
    aynısı gerekecek; bu sürede iPhone sürümü ilerleyebilir.
- **App Store Connect:** yeni uygulama **Olta: Gölün Sırrı**, paket kimliği `com.juiloot.olta`, SKU `olta`.
  - **App Privacy:** Kazı'nınkiyle aynı veri türleri, **izleme (tracking): Evet** (AdMob).
  - **Yaş derecelendirmesi** anketi; Kazı gibi 13+ hedef.
  - **İnceleme notu** hazır (`magaza/yayin.md`); kısa ekran kaydını sen çekersin (2–3 dakika, adımları orada). Apple
    Kazı'nın ilk gönderiminde "Information Needed" (2.1) demişti, not ve kayıtla geçmişti.
  - **Ekran görüntüleri** hazır: `magaza/ekran/` (iPhone 6,9", iPad 13", Play; Türkçe ve İngilizce).

## Kurallar

- **Kendi reklamına asla dokunma, kimseye dokundurma**: AdMob hesabı kalıcı kapanır. Telefonunu AdMob'da **test
  cihazı** olarak ekle (AdMob → Ayarlar → Test cihazları): sürüm derlemesinde de reklamlar "Test Ad" etiketli çıkar.
- AdMob'da uygulama mağazaya bağlanıp incelenene kadar "sınırlı reklam sunumu" olabilir: gerçek reklam az gelir ya da
  hiç gelmez, o zaman teklif düğmeleri görünmez. Bu normal.
