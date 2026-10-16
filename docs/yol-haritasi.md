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
- [ ] Takımın çekişmeye etkisi (`Loadout`, `GearStats`).
- [ ] Para, kova, rütbe, oranlar ve şans garantisi; kayıt v2 ve göç testi.
- [ ] Kaydırmalı liste; HUD'da para, kova ve rütbe.
- [ ] Nine ve dükkân binası.
- [ ] Dükkân paneli, takım çantası, kova ve satış.
- [ ] Nadirliğin gölgede ve kartta görünmesi.
- [ ] Balık Defteri.
- [ ] Denge botu ve korkuluk testleri; oran kataloğu; `shop` senaryosu.

**Dalga 2 — Büyük göl → v0.3**

- [ ] Göl verisi v2: havzalar ve bölgeler; testler için sabit küçük göl; kıyı alanı önbelleği.
- [ ] Gölgeler bölgelere göre doğar.
- [ ] Kıyı yolu ve dünya sınırı.
- [ ] Göl sahnesi ve bölge süsleri.
- [ ] Harita ve hızlı geçiş.
- [ ] Sandal.
- [ ] Bölge balıkları (7 yeni tür).
- [ ] 3D görsel geçişi: su, zemin dokuları, doğa modelleri; telefonda hız ölçümü.

**Dalga 3 — Teknikler → v0.4**

- [ ] Teknik soyutlaması (önce bugünkü şamandıra için altın test).
- [ ] Spin.
- [ ] Dip: sehpa ve zil.
- [ ] Sinek (dere ağzı).
- [ ] Kerevit tuzağı.
- [ ] Teknik balıkları.
- [ ] Dede'nin teknik ipuçları.
- [ ] **5 kişiye oynat** (aşağıdaki sorular). Devam ya da vazgeç burada verilir; Dalga 4–5 beklemez.

**Dalga 4 — Canlı dünya → v0.5**

- [ ] Oyun saati ve hava (çekirdek).
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
