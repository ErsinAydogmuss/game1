# Yol Haritası

Yarı zamanlı çalışma (iş arasında) ve kodun Claude tarafından yazılması varsayıldı. Süreler tahmin; önemli olan sıra. Her adım ayrı commit; adım bitince kısa bir "telefonda dene" listesi gelir.

## Faz 0: Kurulum

- [x] Saha araştırması ve fikir seçimi (Olta: Gölün Sırrı).
- [x] Godot projesi, testler ve iPhone dışa aktarma ayarı (1. hafta, adım 2).
- [ ] Mac'teki Claude Code ile telefona ilk yükleme: [`iphone-kurulum.md`](iphone-kurulum.md).
  - **Not:** ücretsiz Apple hesabıyla aynı anda en fazla 3 uygulama yüklenebilir; Kazı da bunlardan biri.
- [ ] **Apple Developer** (99 $/yıl) ve **Google Play Console** (25 $): dış testçilerden önce.

## Faz 1: Prototip (3 hafta) ← şu an buradayız

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
- [ ] Ek işler (vakit kalırsa):
  - iskelede oturan Dede;
  - `hero` ve `fish` senaryoları;
  - kısa video.
- [ ] README, CREDITS, kod incelemesi, "telefonda dene" listesi.

### H2: Döngü

- [ ] Kova (6 balık), satış (kopyalar), akvaryum (yeni türler yüzer).
- [ ] Dükkân: 2 olta, 2 yem. Şansı değiştirenler yalnızca oyun parasıyla.
- [ ] Kıyı süsleri: 4–6 yuva, 3 tarif. Bulunan tarif türü garanti eder.
- [ ] Balık ansiklopedisi: silüetler ve ipuçları.
- [ ] Erkek balıkçı ve karakter seçim ekranı. Önce karakter sayfasıyla model seçilir.
- [ ] Denge botu: kaç dakikada ilk olta, ilk nadir, ilk tarif?
- [ ] Kayıt v2 ve göç testi.

### H3: Çeşit ve test

- [ ] Gün döngüsü ve yağmur; gece balıkları.
- [ ] 15 balık; çöp eşyalar (eski çizme, şişede not).
- [ ] Dede: tam eğitim ve istekler ("bana bir turna getir").
- [ ] Müzik (kalimba, ud).
- [ ] **5 kişiye oynat** (Kazı'nın 5 kişilik testiyle birlikte yapılabilir). Sorular:
  - İlk 30 saniyede ne yapacaklarını anladılar mı?
  - Gölgeleri gördüler mi? Gölgenin önüne atmayı kendiliğinden buldular mı?
  - VUR anı adil mi? Erken dokunup kaçırdılar mı?
  - Çekişme zevkli mi, zor mu? Kolay çekmeye ihtiyaç duydular mı?
  - "Bir atış daha" dediler mi? Ertesi gün oyunu kendiliğinden açtılar mı?
  - Kazı'ya benziyor mu, farklı mı geldi?
- [ ] **Devam ya da vazgeç:** 5 kişiden en az 3'ü "bir atış daha" diyor ve ertesi gün açıyorsa tam tasarım belgesi ve Faz 2. Değilse sorun bulunur; düzeltilir ya da ikinci fikre (Pofuduk Adası) geçilir.

## Faz 2: Dikey dilim

- [ ] Görsel stili kilitle: ChatGPT stil sayfası, arayüz ikonları, Dede portreleri, logo.
- [ ] Köy ve akvaryum binası; köylüler.
- [ ] İkinci su (nehir) ve tekne.
- [ ] Sonar (Kazı'daki dedektör gibi).
- [ ] "Gölün Sırrı" hikâyesinin ilk bölümü: şişelerden çıkan notlar.
- [ ] Kostümler: şapka, yelek, olta kaplaması.

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
