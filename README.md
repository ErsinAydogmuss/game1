# Olta: Gölün Sırrı (EN: Lure Lake)

**"Kıyını süsle, havayı bekle: bu gece oltana ne takılacak?"** Her yaşa hitap eden, rahat bir 3D mobil balıkçılık oyunu (iOS + Android, yatay ekran). Kendi balıkçınla yazı Dede'nin göl köyünde geçiriyorsun. Suda balık gölgeleri dolaşıyor; gölgenin önüne atıyorsun, gölge yaklaşıp dürtüyor, ısırınca VUR ve çek. Ersin'in Kazı'dan sonraki oyunu; kodu Claude yazıyor.

> **Durum (Ekim 2026): v0.3 (H2 "Büyük Göl", Dalga 2 bitti).** Göl büyüdü: altı bölge (iskele koyu, sazlık, nilüferli koy, kayalık burun, dere ağzı, derin orta), her birinin kendi balıkları ve süsleri. Bölgeler rütbeyle açılır; haritadan hızlı geçilir, koyların çevresinden kıyı yolu dolaşır. Nine'den alınan sandalla derin ortaya açılınır. 7 yeni tür (toplam 12): gümüş balığı, çapak, tatlısu kefali, kadife, sudak, altın sazan ve koruma altındaki mersin (kartıyla göle bırakılır). Su ve zemin yenilendi; zemin, bölge rozetleri ve parşömen harita Ersin'in görselleriyle (Parti 3). Telefonda hız ölçümü ayarlarda. Sırada Dalga 3: teknikler ([yol haritası](docs/yol-haritasi.md)).

![İskele koyu: balıkçı, Dede, Nine'nin dükkânı ve bağlı sandal; kıyı yolu gölü dolaşıyor](docs/ekran/01_iskele.jpg)

| | |
|---|---|
| ![Harita: parşömen kâğıt ve çıkartmalar, bölge rozetleri, kilitler ve çit tabelaları, Buradasın](docs/ekran/02_harita.jpg) | ![Rütbe 3: nilüferli koy açıldı, Dede haritayı gösteriyor](docs/ekran/03_bolge_acildi.jpg) |
| ![Sazlık: sık kamışlar](docs/ekran/04_sazlik.jpg) | ![Nilüferli koy: Destansı altın sazanın mor ışıltılı gölgesi](docs/ekran/05_nilufer.jpg) |
| ![Kayalık burun: iri kayalar ve yosunlu taş](docs/ekran/06_kayalik.jpg) | ![Dere ağzı: akıntı çizgileri](docs/ekran/07_dere.jpg) |
| ![Sandalla derin orta: Efsanevi mersinin gölgesi](docs/ekran/08_sandal.jpg) | ![Mersin koruma altında: kartında Göle bırak](docs/ekran/09_mersin.jpg) |
| ![Destansı altın sazan kartı](docs/ekran/10_altin_sazan.jpg) | ![Nadir turna kartı ve Dede'nin sözü](docs/ekran/11_turna.jpg) |

## Nasıl oynanır

1. **At:** suya dokun. En iyisi bir gölgenin **önüne** atmak; üstüne atarsan balık korkup kaçar.
2. **Bekle:** gölge şamandırayı fark edip gelir, birkaç kez dürter (şamandıra hafifçe batar). Bu sırada dokunma.
3. **VUR:** şamandıra suya dalınca ekranın **her yerine** dokun.
4. **Çek:** parmağını basılı tut, balık gelsin. Balık çırpınınca ("!", titreşim, gıcırtı) **bırak**; gerilim kırmızıda kalırsa misina kopar.
5. Tutulan balık elde gösterilir; yeni tür, rekor ya da Nadir ve üstünde kart açılır.
6. **Kova ve dükkân:** tutulan balık kovaya girer. Nine'ye (iskelenin başındaki dükkân) dokun: kovayı sat, parayla yeni takım al. Bazı takımlar rütbe ister; rütbe balık tuttukça artar.
7. **Nadirlik:** Sıradan ●, Güzel ▲, Nadir ◆, Destansı ★, Efsanevi ✦ (oyunda Ersin'in rozetleri; şekilleri renk körü oyuncu için de ayrılır). Nadir balığın gölgesi arada pırıldar, Destansınınki mor ışıldar, Efsanevinin kenarı altın parlar. Uzun süre gelmezse şans garantisi devreye girer.
8. **Balık Defteri** (sağ üst): tuttuğun türler ve rekorlar; tutmadıklarının ipuçları; bulunduğun bölgede takımınla gerçek oranlar ve şans garantisi sayaçları. Bütün oranlar: [balık kataloğu](docs/balik-katalogu.md).
9. **Bölgeler ve harita:** göl altı bölgeye ayrılmış (iskele koyu, sazlık, nilüferli koy, kayalık burun, dere ağzı, derin orta); her birinin kendi balıkları ve süsleri var. Yeni bölge rütbeyle açılır (3, 5, 7; derin orta 9 ve sandal). İlk balıktan sonra sağ üstte harita düğmesi çıkar: bir bölgenin rozetine dokun, ekran kararır ve oradasın. Gölgeler bulunduğun bölgede doğar, defterdeki oran o bölgenin.
10. **Sandal:** rütbe 9'da Nine'den alınır (Ekstra sekmesi). İskeledeki sandala ya da haritada Derin Orta'ya dokun: derin ortada şamandıranın yanındasın; iri yayın ve mersin orada. Sol alttaki "Kıyıya dön" iskeleye getirir.
11. **Mersin** koruma altında: kovaya girmez, kartında Dede'nin sözüyle göle bırakılır (rütbe puanı ve göl sevgisi verir).

- **Yürü:** karaya ya da iskeleye dokun. Önü su ise balıkçı kıyı yolundan dolaşır; kilitli bölgenin çitinde durur, Dede ne zaman geçileceğini söyler.
- **Dede:** ilk 3 balığa kadar ipucu verir. Ona dokununca her zaman bir öğüt söyler.
- **Ayarlar** (sağ üst): ses, titreşim, dil, **Kolay çekme** (misina kopmaz, balık kaçmaz). Sürüm yazısına 5 kez dokununca sol üstte FPS ve çizim sayısı çıkar (telefonda hız ölçümü).
- **Mac:** tıkla (yürü, at), WASD ya da oklar (yürü), Space (eylem; basılı tutunca sar).

Kısa tanıtım videosu bot ile çekilir (`video` senaryosu, bkz. [CLAUDE.md](CLAUDE.md)): turna, yeni bölge, Nine, harita, altın sazan, sandal ve mersin.

## Çalıştırma

- **Mac'te:** Godot 4.7.2'yi kur, bu klasörü aç, F5. Ya da Terminal'de: `/Applications/Godot.app/Contents/MacOS/Godot --path .`
- **iPhone'da:** Mac'teki Claude Code'a [`docs/iphone-kurulum.md`](docs/iphone-kurulum.md) dosyasını uygulat. Ücretsiz Apple hesabı yeter; uygulama 7 günde bir yeniden yüklenir, en fazla 3 uygulama yüklenebilir (Kazı da biri).
- **Testler ve botlar:** komutlar [CLAUDE.md](CLAUDE.md)'de (testler, `controls` / `first` / `hero` / `fish` / `shop` / `rarity` / `map` / `boat` / `tour` / `video` senaryoları, çekişme ve ekonomi raporları, balık kataloğu, gölün kuşbakışı önizlemesi).

## Belgeler

- [Kısa tasarım belgesi (GDD)](docs/gdd.md): kurallar, sayılar, balıklar, bölgeler, Dede, görünüm, ses, gelir.
- [Yol haritası](docs/yol-haritasi.md): H1 (prototip), H2 "Büyük Göl" (5 dalga: dükkân ve nadirlik, büyük göl, teknikler, canlı dünya, yuva), H3 ve sonrası.
- [Balık kataloğu](docs/balik-katalogu.md): bütün türler, nadirlikler, bölge ve yem başına oranlar, şans garantisi (veriden üretilir).
- [Görsel istekleri](docs/gorsel-istekleri.md): Ersin'in ChatGPT ile üreteceği görseller.
- [iPhone kurulumu](docs/iphone-kurulum.md): Mac'teki Claude Code için adım adım görev (telefonda hız ölçümü dahil).
- [Saha araştırması](docs/saha-arastirmasi.md) ve [fikirler ve karar](docs/fikirler.md).
- [Kaynaklar ve lisanslar](assets/CREDITS.md): KayKit ve Kenney modelleri (CC0), yazı tipleri, Ersin'in görselleri; sesler kodla üretildi.
- [CLAUDE.md](CLAUDE.md): Claude'un bu projede nasıl çalıştığı (komutlar, mimari, kurallar, tuzaklar).

## Nasıl çalışıyoruz

- Claude seçenekler hazırlar ve birini önerir; Ersin seçer.
- Seçilenler sıralı bir plana dökülür. Her adım ayrı commit olur; adım bitince Ersin iPhone'da dener ve geri bildirim verir.
- Görselleri Ersin ChatGPT ile üretir. 3D modeller hazır ücretsiz (CC0) paketlerden (KayKit, Kenney) gelir; sesler kodla üretilir.

Kardeş proje: [Kazı](https://github.com/ErsinAydogmuss/game).
