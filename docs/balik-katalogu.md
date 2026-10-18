# Balık Kataloğu

> Bu dosya `tools/fish_catalog.gd` ile veriden üretilir; elle düzenleme. Veri: `data/fish.json`,
> `data/rarities.json`, `data/spots.json`, `data/gear.json`. Oranlar oyunun gölge doğururken kullandığı
> işlevlerden (`CatchOdds`) okunur; Balık Defteri'nde yazan oranlar bunlardır.

- **Değer** = türün değeri × boy çarpanı (türün en küçük boyu 0,6, en büyüğü 1,6; tamsayı para). Değeri
  0 olan balık satılmaz: Masalsı hikâye balığı (sonraki dalgalarda) ve koruma altındaki tür (mersin). Mersin
  kovaya girmez: tutulur, göle bırakılır; rütbe puanı ve göl sevgisi verir.
- **Rütbe puanı** = nadirliğin puanı × (1 + yıldız başına 0,25). Bırakılan balık da puan verir.
- Bir gölgenin türü ve boyu doğduğu anda belirlenir (gizli ama değişmez); gölgenin boyu balığın
  boyunu ele verir, nadirlik ipucu (pırıltı, ışıltı, dalga izi) kademesini.

## Nadirlikler

| Kademe | Simge | Renk | Tutmadan önce gölgede | Rütbe puanı (1★–5★) | Bırakınca göl sevgisi | Şans garantisi |
|---|---|---|---|---|---|---|
| Sıradan | ● | `b8c2cc` | — | 5–10 | 1 | — |
| Güzel | ▲ | `5fd86a` | — | 10–20 | 2 | — |
| Nadir | ◆ | `3f8fff` | arada bir baştan kuyruğa pırıltı | 25–50 | 5 | 40 av |
| Destansı | ★ | `b764ff` | kenarında nabız gibi ışıltı, kabarcık | 60–120 | 12 | 150 av |
| Efsanevi | ✦ | `ffc426` | parlayan kenar ve göbek, dalga izi; Dede uyarır | 150–300 | 40 | 400 av |
| Masalsı | ✪ | `2fe0d0` | Gölün Bekçisi (hikâye) | 500–1000 | 100 | — |

## Boy ve yıldız

Boy yüzdeliği = u^1,6 (u tekdüze zar): balıkların çoğu küçük, büyükler seyrek. Yıldız boy yüzdeliğinden
gelir; 5★ türün en iri %10'u.

| Yıldız | Boy yüzdeliği | Şans |
|---|---|---|
| ★ | 0–20 | %36,5 |
| ★★ | 20–45 | %24,1 |
| ★★★ | 45–70 | %19,3 |
| ★★★★ | 70–90 | %13,6 |
| ★★★★★ | 90–100 | %6,4 |

Ortalama boy çarpanı 0,99: ortalama bir balık türünün değerinin yaklaşık bu katına satılır.

## İri balık ve takım

İri türlerin (sazan, turna, yayın, kadife, sudak, altın sazan, mersin balığı, aynalı sazan, dere alabalığı) boyu çekişini artırır. Bir iri balığı ancak yıldızını taşıyan kamış ve
misina rahat tutar; ikisinin küçüğü işler. Takım taşımıyorsa balık fazla iridir: takılınca "Çok iri!"
çıkar, sakinken de gerilim kırmızıya çeker, bırakınca balık hızla uzaklaşır. Misina koparsa ya da balık
kaçarsa Dede eksik takımı söyler. Kolay modda kopma yok; fazla iri balık yalnızca yavaş gelir. Öteki
türler her boyda bambu oltayla tutulur.

| Takım | Fiyat | Rütbe | Taşır |
|---|---|---|---|
| Bambu kamış | başlangıç | 1 | ★★★ |
| Cam elyafı kamış | 300 | 2 | ★★★★ |
| Karbon kamış | 2000 | 5 | ★★★★★ |
| Hafif spin kamışı | 150 | 2 | ★★★ |
| Orta spin kamışı | 1100 | 4 | ★★★★ |
| Ağır spin kamışı | 3000 | 8 | ★★★★★ |
| Dip kamışı | 500 | 4 | ★★★★ |
| Uzun dip kamışı | 1800 | 6 | ★★★★★ |
| Usta dip kamışı | 4500 | 10 | ★★★★★ |
| Sinek kamışı | 1500 | 7 | ★★★ |
| Uzun sinek kamışı | 4000 | 9 | ★★★★ |
| Usta sinek kamışı | 9000 | 12 | ★★★★★ |
| İnce misina | başlangıç | 1 | ★★★ |
| Naylon misina | 120 | 1 | ★★★★ |
| Florokarbon misina | 500 | 3 | ★★★★ |
| Örgü misina | 1800 | 6 | ★★★★★ |
| Usta florokarbon | 2500 | 7 | ★★★★★ |
| Altın örgü | 9000 | 12 | ★★★★★ |

## Şans garantisi

- **Nadir ve üstü:** 40 av boyunca gelmezse yakında doğan sıradaki gölge en az Nadir olur.
- **Destansı ve üstü:** 150 av boyunca gelmezse yakında doğan sıradaki gölge en az Destansı olur.
- **Efsanevi ve üstü:** 400 av boyunca gelmezse yakında doğan sıradaki gölge en az Efsanevi olur.
- Garanti balığı değil gölgeyi verir: tutmak yine oyuncunun becerisi. Sayaç ancak o kademe ya da
  üstü tutulunca sıfırlanır; aynı anda yalnızca bir garanti gölgesi olur. Türü, takımın çekebileceği
  türler arasından kendi oranlarıyla seçilir; boyu ve yolu ayrı zarlardan geldiği için kaymaz.
- Gölde türü olmayan kademe garanti edilmez ve sayacı alttaki garantileri kilitlemez.
- Sayaçlar Balık Defteri'nde görünür. Hiçbir şans ya da oran gerçek parayla satılmaz; yemler
  yalnızca oynayarak kazanılan parayla alınır.

## Teknikler

Bir gölgenin türü bölgenin doğma ağırlığı × yemin (yapay yemin, sineğin) çekimi × türün teknik
yatkınlığıyla seçilir. Yatkınlığı olmayan tür o teknikle hiç gelmez; şamandırada Dalga 3 öncesi
türlerin hepsi 1 (şamandıranın oranları değişmedi). Teknik bölgede avlanılmıyorsa (sinek yalnızca
akıntılı bölgede) orada o teknikle gölge doğmaz. Balık takıldıktan sonraki çekişme her teknikte aynı.

| Teknik | Açıldığı rütbe | İlk kamış | Avlanıldığı bölgeler |
|---|---|---|---|
| Şamandıra | 1 | Bambu kamış (başlangıç) | hepsi |
| Spin | 2 | Hafif spin kamışı (150 para) | hepsi |
| Dip | 4 | Dip kamışı (500 para) | hepsi |
| Sinek | 7 | Sinek kamışı (1500 para) | Dere Ağzı |
| Kerevit tuzağı | 3 | Kerevit tuzağı (250 para) | Sazlık, Kayalık Burun |

Türlerin teknik yatkınlığı (çarpan; boş: o teknikle gelmez) ve tuzağa girdiği bölgeler:

| Tür | Nadirlik | Şamandıra | Spin | Dip | Sinek | Tuzak |
|---|---|---|---|---|---|---|
| Kızılkanat | Sıradan | ×1 |  | ×0,3 | ×0,3 |  |
| Sazan | Güzel | ×1 |  | ×1 |  |  |
| Levrek | Güzel | ×1 | ×1 | ×0,2 |  |  |
| Turna | Nadir | ×1 | ×0,8 | ×0,2 |  |  |
| Yayın | Destansı | ×1 | ×0,25 | ×1 |  |  |
| Gümüş Balığı | Sıradan | ×1 |  |  | ×0,2 |  |
| Çapak | Sıradan | ×1 |  | ×1 |  |  |
| Tatlısu Kefali | Sıradan | ×1 | ×0,7 | ×0,5 | ×0,5 |  |
| Kadife | Güzel | ×1 |  | ×1 |  |  |
| Sudak | Nadir | ×1 | ×0,9 | ×0,3 |  |  |
| Altın Sazan | Destansı | ×1 |  | ×0,8 |  |  |
| Mersin Balığı | Efsanevi | ×1 |  | ×1,5 |  |  |
| Aynalı Sazan | Nadir |  |  | ×1 |  |  |
| Alabalık | Nadir |  | ×0,6 |  | ×1 |  |
| Dere Alabalığı | Destansı |  | ×0,4 |  | ×1 |  |
| Kerevit | Sıradan |  |  | ×0,5 |  | Sazlık, Kayalık Burun |

## Köy Gölü (oyunun gölü, `big_lake`)

- Aynı anda en çok 4 gölge; tutulan ya da kaçanın yerine birkaç saniyede yenisi doğar.
- Hiç balık tutmamış oyuncunun ilk balığı senaryoludur: Kızılkanat, dürtmesiz, kaçmaz.
- Göl bölgelere ayrılır: gölge balıkçının çevresinde doğar, türü doğduğu yerin bölgesinden gelir.
  Oranlar bölgenindir (Balık Defteri ve dükkân bulunulan bölgeninkini gösterir). Şans garantisi
  balıkçının bölgesinde doğar; sayaç yalnızca o bölgede gelebilen kademeler için ilerler.

### İskele Koyu (`dock_cove`; başta açık)

#### Şamandıra

Bir gölgenin o tür olma şansı, kuşanılan yeme göre:

| Tür | English | Nadirlik | Boy (cm) | Değer (para) | Gölge (m) | İri | Solucan | Kurtçuk | Ekmek hamuru | Mısır | Boili | Karides |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Kızılkanat | Rudd | Sıradan | 15–30 | 3–8 | 0,5 |  | %26 | %18,4 | %18,5 | %18,6 | %16,9 | %21,7 |
| Gümüş Balığı | Silverside | Sıradan | 8–18 | 2–6 | 0,4 |  | %14 | %19,9 | %10 | %10 | %9,1 | %11,7 |
| Çapak | Bream | Sıradan | 25–60 | 4–10 | 0,7 |  | %10 | %7,1 | %14,2 | %7,1 | %11,7 | %8,3 |
| Sazan | Carp | Güzel | 30–80 | 7–19 | 0,75 | ✓ | %20 | %14,2 | %25,6 | %42,9 | %39 | %16,7 |
| Levrek | Perch | Güzel | 20–45 | 7–19 | 0,75 |  | %18 | %31,9 | %23,1 | %12,9 | %11,7 | %15 |
| Turna | Pike | Nadir | 50–120 | 21–56 | 1,05 | ✓ | %8 | %5,7 | %5,7 | %5,7 | %5,2 | %16,7 |
| Yayın | Wels Catfish | Destansı | 100–250 | 72–192 | 1,5 | ✓ | %4 | %2,8 | %2,8 | %2,9 | %6,5 | %10 |

Yeme göre nadirlik oranları ve balık başına ortalama değer ile rütbe puanı (yem bedeli düşülmeden):

| Yem | Fiyat (para / paket) | Sıradan | Güzel | Nadir | Destansı | Ortalama değer | Ortalama puan |
|---|---|---|---|---|---|---|---|
| Solucan | bedava, sınırsız | %50 | %38 | %8 | %4 | 14,38 | 13,93 |
| Kurtçuk | 30 / 20 | %45,4 | %46,1 | %5,7 | %2,8 | 12,85 | 13,01 |
| Ekmek hamuru | 30 / 20 | %42,7 | %48,7 | %5,7 | %2,8 | 13,22 | 13,2 |
| Mısır | 40 / 20 | %35,7 | %55,7 | %5,7 | %2,9 | 13,64 | 13,68 |
| Boili | 60 / 10 | %37,7 | %50,6 | %5,2 | %6,5 | 17,32 | 15,86 |
| Karides | 100 / 10 | %41,7 | %31,7 | %16,7 | %10 | 23,29 | 20,18 |

#### Spin (rütbe 2)

Bir gölgenin o tür olma şansı, kuşanılan yapay yeme göre:

| Tür | English | Nadirlik | Boy (cm) | Değer (para) | Gölge (m) | İri | Kaşık | Döner kaşık | Silikon yem | Maket balık | Su üstü yemi | Altın kaşık |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Levrek | Perch | Güzel | 20–45 | 7–19 | 0,75 |  | %76 | %82,9 | %77,3 | %54,4 | %59 | %50,6 |
| Turna | Pike | Nadir | 50–120 | 21–56 | 1,05 | ✓ | %20,8 | %14,7 | %19,6 | %42,6 | %37,7 | %44,9 |
| Yayın | Wels Catfish | Destansı | 100–250 | 72–192 | 1,5 | ✓ | %3,2 | %2,3 | %3,1 | %3 | %3,3 | %4,5 |

Yapay yeme göre nadirlik oranları ve balık başına ortalama değer ile rütbe puanı:

| Yapay yem | Fiyat (para) | Sıradan | Güzel | Nadir | Destansı | Ortalama değer | Ortalama puan |
|---|---|---|---|---|---|---|---|
| Kaşık | başlangıç | %0 | %76 | %20,8 | %3,2 | 19,96 | 19,3 |
| Döner kaşık | 120 (rütbe 2) | %0 | %82,9 | %14,7 | %2,3 | 17,6 | 17,48 |
| Silikon yem | 300 (rütbe 3) | %0 | %77,3 | %19,6 | %3,1 | 19,51 | 18,96 |
| Maket balık | 700 (rütbe 5) | %0 | %54,4 | %42,6 | %3 | 24,61 | 23,46 |
| Su üstü yemi | 1000 (rütbe 6) | %0 | %59 | %37,7 | %3,3 | 23,8 | 22,68 |
| Altın kaşık | 2500 (rütbe 10) | %0 | %50,6 | %44,9 | %4,5 | 26,71 | 24,91 |

#### Dip (rütbe 4)

Bir gölgenin o tür olma şansı, kuşanılan yeme göre:

| Tür | English | Nadirlik | Boy (cm) | Değer (para) | Gölge (m) | İri | Solucan | Kurtçuk | Ekmek hamuru | Mısır | Boili | Karides |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Kızılkanat | Rudd | Sıradan | 15–30 | 3–8 | 0,5 |  | %16,6 | %14,9 | %10,3 | %9 | %7,7 | %13,6 |
| Çapak | Bream | Sıradan | 25–60 | 4–10 | 0,7 |  | %21,3 | %19,1 | %26,4 | %11,5 | %17,8 | %17,4 |
| Sazan | Carp | Güzel | 30–80 | 7–19 | 0,75 | ✓ | %42,6 | %38,2 | %47,4 | %69 | %59,4 | %34,8 |
| Levrek | Perch | Güzel | 20–45 | 7–19 | 0,75 |  | %7,7 | %17,2 | %8,5 | %4,1 | %3,6 | %6,3 |
| Turna | Pike | Nadir | 50–120 | 21–56 | 1,05 | ✓ | %3,4 | %3,1 | %2,1 | %1,8 | %1,6 | %7 |
| Yayın | Wels Catfish | Destansı | 100–250 | 72–192 | 1,5 | ✓ | %8,5 | %7,6 | %5,3 | %4,6 | %9,9 | %20,9 |

Yeme göre nadirlik oranları ve balık başına ortalama değer ile rütbe puanı (yem bedeli düşülmeden):

| Yem | Fiyat (para / paket) | Sıradan | Güzel | Nadir | Destansı | Ortalama değer | Ortalama puan |
|---|---|---|---|---|---|---|---|
| Solucan | bedava, sınırsız | %37,9 | %50,2 | %3,4 | %8,5 | 19,23 | 16,83 |
| Kurtçuk | 30 / 20 | %34 | %55,3 | %3,1 | %7,6 | 18,47 | 16,44 |
| Ekmek hamuru | 30 / 20 | %36,6 | %56 | %2,1 | %5,3 | 15,63 | 14,51 |
| Mısır | 40 / 20 | %20,5 | %73,1 | %1,8 | %4,6 | 15,82 | 15,09 |
| Boili | 60 / 10 | %25,5 | %63 | %1,6 | %9,9 | 21,12 | 18,21 |
| Karides | 100 / 10 | %31 | %41,1 | %7 | %20,9 | 33,66 | 26,21 |

### Sazlık (`reeds`; başta açık)

Dede'nin önerisi: dip ("Sazlıkta kadife ile sazan dipte beslenir evlat. Dip dene!").

#### Şamandıra

Bir gölgenin o tür olma şansı, kuşanılan yeme göre:

| Tür | English | Nadirlik | Boy (cm) | Değer (para) | Gölge (m) | İri | Solucan | Kurtçuk | Ekmek hamuru | Mısır | Boili | Karides |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Kızılkanat | Rudd | Sıradan | 15–30 | 3–8 | 0,5 |  | %28 | %22,5 | %22,4 | %15,5 | %18,9 | %26 |
| Gümüş Balığı | Silverside | Sıradan | 8–18 | 2–6 | 0,4 |  | %14 | %22,5 | %11,2 | %7,7 | %9,5 | %13 |
| Sazan | Carp | Güzel | 30–80 | 7–19 | 0,75 | ✓ | %24 | %19,3 | %34,6 | %39,8 | %48,6 | %22,3 |
| Kadife | Tench | Güzel | 25–55 | 8–22 | 0,7 | ✓ | %22 | %17,7 | %17,6 | %30,4 | %14,9 | %20,5 |
| Levrek | Perch | Güzel | 20–45 | 7–19 | 0,75 |  | %7 | %14,1 | %10,1 | %3,9 | %4,7 | %6,5 |
| Turna | Pike | Nadir | 50–120 | 21–56 | 1,05 | ✓ | %5 | %4 | %4 | %2,8 | %3,4 | %11,6 |

Yeme göre nadirlik oranları ve balık başına ortalama değer ile rütbe puanı (yem bedeli düşülmeden):

| Yem | Fiyat (para / paket) | Sıradan | Güzel | Nadir | Ortalama değer | Ortalama puan |
|---|---|---|---|---|---|---|
| Solucan | bedava, sınırsız | %42 | %53 | %5 | 10,32 | 11,22 |
| Kurtçuk | 30 / 20 | %45 | %51 | %4 | 9,73 | 10,83 |
| Ekmek hamuru | 30 / 20 | %33,7 | %62,3 | %4 | 10,62 | 11,58 |
| Mısır | 40 / 20 | %23,2 | %74 | %2,8 | 11,34 | 12,04 |
| Boili | 60 / 10 | %28,4 | %68,2 | %3,4 | 10,8 | 11,81 |
| Karides | 100 / 10 | %39,1 | %49,3 | %11,6 | 12 | 12,73 |

#### Spin (rütbe 2)

Bir gölgenin o tür olma şansı, kuşanılan yapay yeme göre:

| Tür | English | Nadirlik | Boy (cm) | Değer (para) | Gölge (m) | İri | Kaşık | Döner kaşık | Silikon yem | Maket balık | Su üstü yemi | Altın kaşık |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Levrek | Perch | Güzel | 20–45 | 7–19 | 0,75 |  | %69,5 | %77,8 | %71 | %44,3 | %49,3 | %41,2 |
| Turna | Pike | Nadir | 50–120 | 21–56 | 1,05 | ✓ | %30,5 | %22,2 | %29 | %55,7 | %50,7 | %58,8 |

Yapay yeme göre nadirlik oranları ve balık başına ortalama değer ile rütbe puanı:

| Yapay yem | Fiyat (para) | Sıradan | Güzel | Nadir | Ortalama değer | Ortalama puan |
|---|---|---|---|---|---|---|
| Kaşık | başlangıç | %0 | %69,5 | %30,5 | 18,69 | 19,08 |
| Döner kaşık | 120 (rütbe 2) | %0 | %77,8 | %22,2 | 16,83 | 17,43 |
| Silikon yem | 300 (rütbe 3) | %0 | %71 | %29 | 18,35 | 18,77 |
| Maket balık | 700 (rütbe 5) | %0 | %44,3 | %55,7 | 24,35 | 24,05 |
| Su üstü yemi | 1000 (rütbe 6) | %0 | %49,3 | %50,7 | 23,22 | 23,07 |
| Altın kaşık | 2500 (rütbe 10) | %0 | %41,2 | %58,8 | 25,05 | 24,67 |

#### Dip (rütbe 4)

Bir gölgenin o tür olma şansı, kuşanılan yeme göre:

| Tür | English | Nadirlik | Boy (cm) | Değer (para) | Gölge (m) | İri | Solucan | Kurtçuk | Ekmek hamuru | Mısır | Boili | Karides |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Kızılkanat | Rudd | Sıradan | 15–30 | 3–8 | 0,5 |  | %12,6 | %12,2 | %9,6 | %5,7 | %7,3 | %12,3 |
| Sazan | Carp | Güzel | 30–80 | 7–19 | 0,75 | ✓ | %35,9 | %34,8 | %49,6 | %48,7 | %62,7 | %35,1 |
| Kadife | Tench | Güzel | 25–55 | 8–22 | 0,7 | ✓ | %32,9 | %31,9 | %25,3 | %37,2 | %19,2 | %32,2 |
| Levrek | Perch | Güzel | 20–45 | 7–19 | 0,75 |  | %2,1 | %5,1 | %2,9 | %0,95 | %1,2 | %2 |
| Turna | Pike | Nadir | 50–120 | 21–56 | 1,05 | ✓ | %1,5 | %1,5 | %1,1 | %0,68 | %0,87 | %3,7 |
| Aynalı Sazan | Mirror Carp | Nadir | 40–95 | 20–54 | 0,85 | ✓ | %9 | %8,7 | %6,9 | %4,1 | %5,2 | %8,8 |
| Kerevit | Crayfish | Sıradan | 6–14 | 4–10 | 0,3 |  | %6 | %5,8 | %4,6 | %2,7 | %3,5 | %5,9 |

Yeme göre nadirlik oranları ve balık başına ortalama değer ile rütbe puanı (yem bedeli düşülmeden):

| Yem | Fiyat (para / paket) | Sıradan | Güzel | Nadir | Ortalama değer | Ortalama puan |
|---|---|---|---|---|---|---|
| Solucan | bedava, sınırsız | %18,6 | %71 | %10,5 | 13,51 | 13,87 |
| Kurtçuk | 30 / 20 | %18 | %71,8 | %10,2 | 13,46 | 13,85 |
| Ekmek hamuru | 30 / 20 | %14,2 | %77,7 | %8 | 13,11 | 13,68 |
| Mısır | 40 / 20 | %8,4 | %86,9 | %4,7 | 13,01 | 13,42 |
| Boili | 60 / 10 | %10,8 | %83,1 | %6,1 | 12,8 | 13,52 |
| Karides | 100 / 10 | %18,2 | %69,4 | %12,4 | 13,97 | 14,29 |

#### Kerevit tuzağı (rütbe 3)

Gerçek saatle 20 dakikada bir tuzağa bir tür girer, en çok 4 birikir; içindekiler tuzak kurulunca
belli olur. Tuzaktan gelen balık şans garantisi sayaçlarını ilerletmez.

| Tür | Nadirlik | Şans | Değer (para) | Ortalama değer |
|---|---|---|---|---|
| Kerevit | Sıradan | %100 | 4–10 | 5,94 |

### Nilüferli Koy (`lily_cove`; rütbe 3)

Dede'nin önerisi: spin ("Nilüferlerde turna pusuda evlat. Spin dene!").

#### Şamandıra

Bir gölgenin o tür olma şansı, kuşanılan yeme göre:

| Tür | English | Nadirlik | Boy (cm) | Değer (para) | Gölge (m) | İri | Solucan | Kurtçuk | Ekmek hamuru | Mısır | Boili | Karides |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Turna | Pike | Nadir | 50–120 | 21–56 | 1,05 | ✓ | %22 | %15,8 | %15,7 | %14,6 | %14 | %41,4 |
| Levrek | Perch | Güzel | 20–45 | 7–19 | 0,75 |  | %26 | %46,8 | %33,4 | %17,2 | %16,6 | %19,5 |
| Sazan | Carp | Güzel | 30–80 | 7–19 | 0,75 | ✓ | %24 | %17,3 | %30,9 | %47,7 | %45,9 | %18 |
| Kızılkanat | Rudd | Sıradan | 15–30 | 3–8 | 0,5 |  | %22 | %15,8 | %15,7 | %14,6 | %14 | %16,5 |
| Altın Sazan | Golden Carp | Destansı | 40–85 | 66–176 | 0,9 | ✓ | %6 | %4,3 | %4,3 | %6 | %9,6 | %4,5 |

Yeme göre nadirlik oranları ve balık başına ortalama değer ile rütbe puanı (yem bedeli düşülmeden):

| Yem | Fiyat (para / paket) | Sıradan | Güzel | Nadir | Destansı | Ortalama değer | Ortalama puan |
|---|---|---|---|---|---|---|---|
| Solucan | bedava, sınırsız | %22 | %50 | %22 | %6 | 21,03 | 19,9 |
| Kurtçuk | 30 / 20 | %15,8 | %64 | %15,8 | %4,3 | 18,45 | 17,98 |
| Ekmek hamuru | 30 / 20 | %15,7 | %64,3 | %15,7 | %4,3 | 18,4 | 17,94 |
| Mısır | 40 / 20 | %14,6 | %64,9 | %14,6 | %6 | 19,83 | 18,9 |
| Boili | 60 / 10 | %14 | %62,4 | %14 | %9,6 | 23,21 | 21,21 |
| Karides | 100 / 10 | %16,5 | %37,6 | %41,4 | %4,5 | 24,32 | 23,1 |

#### Spin (rütbe 2)

Bir gölgenin o tür olma şansı, kuşanılan yapay yeme göre:

| Tür | English | Nadirlik | Boy (cm) | Değer (para) | Gölge (m) | İri | Kaşık | Döner kaşık | Silikon yem | Maket balık | Su üstü yemi | Altın kaşık |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Turna | Pike | Nadir | 50–120 | 21–56 | 1,05 | ✓ | %34,2 | %25,3 | %32,6 | %59,8 | %54,9 | %62,9 |
| Levrek | Perch | Güzel | 20–45 | 7–19 | 0,75 |  | %65,8 | %74,7 | %67,4 | %40,2 | %45,1 | %37,1 |

Yapay yeme göre nadirlik oranları ve balık başına ortalama değer ile rütbe puanı:

| Yapay yem | Fiyat (para) | Sıradan | Güzel | Nadir | Ortalama değer | Ortalama puan |
|---|---|---|---|---|---|---|
| Kaşık | başlangıç | %0 | %65,8 | %34,2 | 19,53 | 19,81 |
| Döner kaşık | 120 (rütbe 2) | %0 | %74,7 | %25,3 | 17,51 | 18,04 |
| Silikon yem | 300 (rütbe 3) | %0 | %67,4 | %32,6 | 19,16 | 19,49 |
| Maket balık | 700 (rütbe 5) | %0 | %40,2 | %59,8 | 25,27 | 24,87 |
| Su üstü yemi | 1000 (rütbe 6) | %0 | %45,1 | %54,9 | 24,17 | 23,9 |
| Altın kaşık | 2500 (rütbe 10) | %0 | %37,1 | %62,9 | 25,95 | 25,47 |

#### Dip (rütbe 4)

Bir gölgenin o tür olma şansı, kuşanılan yeme göre:

| Tür | English | Nadirlik | Boy (cm) | Değer (para) | Gölge (m) | İri | Solucan | Kurtçuk | Ekmek hamuru | Mısır | Boili | Karides |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Turna | Pike | Nadir | 50–120 | 21–56 | 1,05 | ✓ | %9,8 | %8,3 | %6,4 | %4,6 | %4,4 | %21,3 |
| Levrek | Perch | Güzel | 20–45 | 7–19 | 0,75 |  | %11,6 | %24,6 | %13,7 | %5,5 | %5,2 | %10,1 |
| Sazan | Carp | Güzel | 30–80 | 7–19 | 0,75 | ✓ | %53,3 | %45,5 | %63,2 | %75,5 | %71,9 | %46,5 |
| Kızılkanat | Rudd | Sıradan | 15–30 | 3–8 | 0,5 |  | %14,7 | %12,5 | %9,7 | %6,9 | %6,6 | %12,8 |
| Altın Sazan | Golden Carp | Destansı | 40–85 | 66–176 | 0,9 | ✓ | %10,7 | %9,1 | %7 | %7,5 | %12 | %9,3 |

Yeme göre nadirlik oranları ve balık başına ortalama değer ile rütbe puanı (yem bedeli düşülmeden):

| Yem | Fiyat (para / paket) | Sıradan | Güzel | Nadir | Destansı | Ortalama değer | Ortalama puan |
|---|---|---|---|---|---|---|---|
| Solucan | bedava, sınırsız | %14,7 | %64,9 | %9,8 | %10,7 | 23,28 | 21,07 |
| Kurtçuk | 30 / 20 | %12,5 | %70,1 | %8,3 | %9,1 | 21,59 | 19,88 |
| Ekmek hamuru | 30 / 20 | %9,7 | %76,9 | %6,4 | %7 | 19,36 | 18,33 |
| Mısır | 40 / 20 | %6,9 | %80,9 | %4,6 | %7,5 | 19,64 | 18,5 |
| Boili | 60 / 10 | %6,6 | %77 | %4,4 | %12 | 23,88 | 21,41 |
| Karides | 100 / 10 | %12,8 | %56,6 | %21,3 | %9,3 | 24,69 | 22,57 |

### Kayalık Burun (`rocky_point`; rütbe 5)

Dede'nin önerisi: spin ("Kayalıkta sudak avlanır evlat. Spin dene, dur-kalk yap!").

#### Şamandıra

Bir gölgenin o tür olma şansı, kuşanılan yeme göre:

| Tür | English | Nadirlik | Boy (cm) | Değer (para) | Gölge (m) | İri | Solucan | Kurtçuk | Ekmek hamuru | Mısır | Boili | Karides |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Tatlısu Kefali | Chub | Sıradan | 20–50 | 4–11 | 0,65 |  | %30 | %21,1 | %24,5 | %30 | %27,5 | %30,9 |
| Levrek | Perch | Güzel | 20–45 | 7–19 | 0,75 |  | %28 | %49,3 | %41,2 | %28 | %25,7 | %16 |
| Sudak | Zander | Nadir | 40–90 | 24–64 | 0,95 | ✓ | %16 | %11,3 | %13,1 | %16 | %14,7 | %22,9 |
| Kızılkanat | Rudd | Sıradan | 15–30 | 3–8 | 0,5 |  | %10 | %7 | %8,2 | %10 | %9,2 | %5,7 |
| Turna | Pike | Nadir | 50–120 | 21–56 | 1,05 | ✓ | %10 | %7 | %8,2 | %10 | %9,2 | %14,3 |
| Yayın | Wels Catfish | Destansı | 100–250 | 72–192 | 1,5 | ✓ | %6 | %4,2 | %4,9 | %6 | %13,8 | %10,3 |

Yeme göre nadirlik oranları ve balık başına ortalama değer ile rütbe puanı (yem bedeli düşülmeden):

| Yem | Fiyat (para / paket) | Sıradan | Güzel | Nadir | Destansı | Ortalama değer | Ortalama puan |
|---|---|---|---|---|---|---|---|
| Solucan | bedava, sınırsız | %40 | %28 | %26 | %6 | 22,7 | 19,49 |
| Kurtçuk | 30 / 20 | %28,2 | %49,3 | %18,3 | %4,2 | 19,48 | 17,58 |
| Ekmek hamuru | 30 / 20 | %32,7 | %41,2 | %21,2 | %4,9 | 20,71 | 18,31 |
| Mısır | 40 / 20 | %40 | %28 | %26 | %6 | 22,7 | 19,49 |
| Boili | 60 / 10 | %36,7 | %25,7 | %23,9 | %13,8 | 30,58 | 24,43 |
| Karides | 100 / 10 | %36,6 | %16 | %37,1 | %10,3 | 30,36 | 24,76 |

#### Spin (rütbe 2)

Bir gölgenin o tür olma şansı, kuşanılan yapay yeme göre:

| Tür | English | Nadirlik | Boy (cm) | Değer (para) | Gölge (m) | İri | Kaşık | Döner kaşık | Silikon yem | Maket balık | Su üstü yemi | Altın kaşık |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Tatlısu Kefali | Chub | Sıradan | 20–50 | 4–11 | 0,65 |  | %25,8 | %29,6 | %20,7 | %23,4 | %44,2 | %21 |
| Levrek | Perch | Güzel | 20–45 | 7–19 | 0,75 |  | %44,8 | %49,3 | %38,7 | %31,2 | %26,8 | %27,9 |
| Sudak | Zander | Nadir | 40–90 | 24–64 | 0,95 | ✓ | %17,7 | %12,7 | %31,2 | %24,1 | %13,8 | %28,7 |
| Turna | Pike | Nadir | 50–120 | 21–56 | 1,05 | ✓ | %9,8 | %7 | %7,9 | %19,6 | %13,8 | %20 |
| Yayın | Wels Catfish | Destansı | 100–250 | 72–192 | 1,5 | ✓ | %1,8 | %1,3 | %1,5 | %1,7 | %1,4 | %2,4 |

Yapay yeme göre nadirlik oranları ve balık başına ortalama değer ile rütbe puanı:

| Yapay yem | Fiyat (para) | Sıradan | Güzel | Nadir | Destansı | Ortalama değer | Ortalama puan |
|---|---|---|---|---|---|---|---|
| Kaşık | başlangıç | %25,8 | %44,8 | %27,6 | %1,8 | 19,61 | 17,99 |
| Döner kaşık | 120 (rütbe 2) | %29,6 | %49,3 | %19,7 | %1,3 | 16,86 | 15,84 |
| Silikon yem | 300 (rütbe 3) | %20,7 | %38,7 | %39,1 | %1,5 | 22,77 | 20,38 |
| Maket balık | 700 (rütbe 5) | %23,4 | %31,2 | %43,7 | %1,7 | 23,5 | 21,23 |
| Su üstü yemi | 1000 (rütbe 6) | %44,2 | %26,8 | %27,6 | %1,4 | 18,07 | 16,49 |
| Altın kaşık | 2500 (rütbe 10) | %21 | %27,9 | %48,7 | %2,4 | 25,75 | 22,86 |

#### Dip (rütbe 4)

Bir gölgenin o tür olma şansı, kuşanılan yeme göre:

| Tür | English | Nadirlik | Boy (cm) | Değer (para) | Gölge (m) | İri | Solucan | Kurtçuk | Ekmek hamuru | Mısır | Boili | Karides |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Tatlısu Kefali | Chub | Sıradan | 20–50 | 4–11 | 0,65 |  | %37,1 | %30,7 | %33,4 | %37,1 | %30,4 | %36,2 |
| Levrek | Perch | Güzel | 20–45 | 7–19 | 0,75 |  | %13,9 | %28,7 | %22,5 | %13,9 | %11,3 | %7,5 |
| Sudak | Zander | Nadir | 40–90 | 24–64 | 0,95 | ✓ | %11,9 | %9,8 | %10,7 | %11,9 | %9,7 | %16,1 |
| Kızılkanat | Rudd | Sıradan | 15–30 | 3–8 | 0,5 |  | %7,4 | %6,1 | %6,7 | %7,4 | %6,1 | %4 |
| Turna | Pike | Nadir | 50–120 | 21–56 | 1,05 | ✓ | %5 | %4,1 | %4,5 | %5 | %4 | %6,7 |
| Yayın | Wels Catfish | Destansı | 100–250 | 72–192 | 1,5 | ✓ | %14,9 | %12,3 | %13,4 | %14,9 | %30,4 | %24,1 |
| Kerevit | Crayfish | Sıradan | 6–14 | 4–10 | 0,3 |  | %9,9 | %8,2 | %8,9 | %9,9 | %8,1 | %5,4 |

Yeme göre nadirlik oranları ve balık başına ortalama değer ile rütbe puanı (yem bedeli düşülmeden):

| Yem | Fiyat (para / paket) | Sıradan | Güzel | Nadir | Destansı | Ortalama değer | Ortalama puan |
|---|---|---|---|---|---|---|---|
| Solucan | bedava, sınırsız | %54,5 | %13,9 | %16,8 | %14,9 | 29,09 | 22,58 |
| Kurtçuk | 30 / 20 | %45,1 | %28,7 | %13,9 | %12,3 | 26,12 | 20,94 |
| Ekmek hamuru | 30 / 20 | %49 | %22,5 | %15,2 | %13,4 | 27,36 | 21,63 |
| Mısır | 40 / 20 | %54,5 | %13,9 | %16,8 | %14,9 | 29,09 | 22,58 |
| Boili | 60 / 10 | %44,5 | %11,3 | %13,8 | %30,4 | 45,32 | 32,93 |
| Karides | 100 / 10 | %45,6 | %7,5 | %22,8 | %24,1 | 41,06 | 30,51 |

#### Kerevit tuzağı (rütbe 3)

Gerçek saatle 20 dakikada bir tuzağa bir tür girer, en çok 4 birikir; içindekiler tuzak kurulunca
belli olur. Tuzaktan gelen balık şans garantisi sayaçlarını ilerletmez.

| Tür | Nadirlik | Şans | Değer (para) | Ortalama değer |
|---|---|---|---|---|
| Kerevit | Sıradan | %100 | 4–10 | 5,94 |

### Dere Ağzı (`stream_mouth`; rütbe 7)

Dede'nin önerisi: sinek ("Burada sinek dene evlat. Alabalık akıntıda çıkar.").

#### Şamandıra

Bir gölgenin o tür olma şansı, kuşanılan yeme göre:

| Tür | English | Nadirlik | Boy (cm) | Değer (para) | Gölge (m) | İri | Solucan | Kurtçuk | Ekmek hamuru | Mısır | Boili | Karides |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Tatlısu Kefali | Chub | Sıradan | 20–50 | 4–11 | 0,65 |  | %36 | %27,7 | %31 | %36 | %32,1 | %35,3 |
| Turna | Pike | Nadir | 50–120 | 21–56 | 1,05 | ✓ | %26 | %20 | %22,4 | %26 | %23,2 | %35,4 |
| Levrek | Perch | Güzel | 20–45 | 7–19 | 0,75 |  | %20 | %38,5 | %31 | %20 | %17,9 | %10,9 |
| Kızılkanat | Rudd | Sıradan | 15–30 | 3–8 | 0,5 |  | %10 | %7,7 | %8,6 | %10 | %8,9 | %5,4 |
| Yayın | Wels Catfish | Destansı | 100–250 | 72–192 | 1,5 | ✓ | %8 | %6,2 | %6,9 | %8 | %17,9 | %13,1 |

Yeme göre nadirlik oranları ve balık başına ortalama değer ile rütbe puanı (yem bedeli düşülmeden):

| Yem | Fiyat (para / paket) | Sıradan | Güzel | Nadir | Destansı | Ortalama değer | Ortalama puan |
|---|---|---|---|---|---|---|---|
| Solucan | bedava, sınırsız | %46 | %20 | %26 | %8 | 23,71 | 20,41 |
| Kurtçuk | 30 / 20 | %35,4 | %38,5 | %20 | %6,2 | 20,97 | 18,71 |
| Ekmek hamuru | 30 / 20 | %39,7 | %31 | %22,4 | %6,9 | 22,07 | 19,4 |
| Mısır | 40 / 20 | %46 | %20 | %26 | %8 | 23,71 | 20,41 |
| Boili | 60 / 10 | %41,1 | %17,9 | %23,2 | %17,9 | 33,84 | 26,73 |
| Karides | 100 / 10 | %40,7 | %10,9 | %35,4 | %13,1 | 31,55 | 25,97 |

#### Spin (rütbe 2)

Bir gölgenin o tür olma şansı, kuşanılan yapay yeme göre:

| Tür | English | Nadirlik | Boy (cm) | Değer (para) | Gölge (m) | İri | Kaşık | Döner kaşık | Silikon yem | Maket balık | Su üstü yemi | Altın kaşık |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Tatlısu Kefali | Chub | Sıradan | 20–50 | 4–11 | 0,65 |  | %26,9 | %32,9 | %26,4 | %22,4 | %41,2 | %21 |
| Turna | Pike | Nadir | 50–120 | 21–56 | 1,05 | ✓ | %22,2 | %16,9 | %21,8 | %40,7 | %27,8 | %43,3 |
| Levrek | Perch | Güzel | 20–45 | 7–19 | 0,75 |  | %27,8 | %32,6 | %29,3 | %17,8 | %14,9 | %16,7 |
| Yayın | Wels Catfish | Destansı | 100–250 | 72–192 | 1,5 | ✓ | %2,1 | %1,6 | %2,1 | %1,8 | %1,5 | %2,7 |
| Alabalık | Trout | Nadir | 25–60 | 18–48 | 0,65 |  | %19,2 | %14,7 | %18,8 | %16 | %13,4 | %15 |
| Dere Alabalığı | Brook Trout | Destansı | 35–80 | 42–112 | 0,8 | ✓ | %1,7 | %1,3 | %1,7 | %1,4 | %1,2 | %1,3 |

Yapay yeme göre nadirlik oranları ve balık başına ortalama değer ile rütbe puanı:

| Yapay yem | Fiyat (para) | Sıradan | Güzel | Nadir | Destansı | Ortalama değer | Ortalama puan |
|---|---|---|---|---|---|---|---|
| Kaşık | başlangıç | %26,9 | %27,8 | %41,5 | %3,8 | 22,15 | 21,99 |
| Döner kaşık | 120 (rütbe 2) | %32,9 | %32,6 | %31,6 | %2,9 | 19,09 | 19,04 |
| Silikon yem | 300 (rütbe 3) | %26,4 | %29,3 | %40,6 | %3,8 | 21,94 | 21,8 |
| Maket balık | 700 (rütbe 5) | %22,4 | %17,8 | %56,6 | %3,2 | 25,4 | 24,87 |
| Su üstü yemi | 1000 (rütbe 6) | %41,2 | %14,9 | %41,2 | %2,7 | 20,68 | 20,21 |
| Altın kaşık | 2500 (rütbe 10) | %21 | %16,7 | %58,3 | %4 | 26,79 | 25,82 |

#### Dip (rütbe 4)

Bir gölgenin o tür olma şansı, kuşanılan yeme göre:

| Tür | English | Nadirlik | Boy (cm) | Değer (para) | Gölge (m) | İri | Solucan | Kurtçuk | Ekmek hamuru | Mısır | Boili | Karides |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Tatlısu Kefali | Chub | Sıradan | 20–50 | 4–11 | 0,65 |  | %47,1 | %40,7 | %43,5 | %47,1 | %35,9 | %42,4 |
| Turna | Pike | Nadir | 50–120 | 21–56 | 1,05 | ✓ | %13,6 | %11,8 | %12,6 | %13,6 | %10,4 | %17 |
| Levrek | Perch | Güzel | 20–45 | 7–19 | 0,75 |  | %10,5 | %22,6 | %17,4 | %10,5 | %8 | %5,2 |
| Kızılkanat | Rudd | Sıradan | 15–30 | 3–8 | 0,5 |  | %7,9 | %6,8 | %7,2 | %7,9 | %6 | %3,9 |
| Yayın | Wels Catfish | Destansı | 100–250 | 72–192 | 1,5 | ✓ | %20,9 | %18,1 | %19,3 | %20,9 | %39,8 | %31,4 |

Yeme göre nadirlik oranları ve balık başına ortalama değer ile rütbe puanı (yem bedeli düşülmeden):

| Yem | Fiyat (para / paket) | Sıradan | Güzel | Nadir | Destansı | Ortalama değer | Ortalama puan |
|---|---|---|---|---|---|---|---|
| Solucan | bedava, sınırsız | %55 | %10,5 | %13,6 | %20,9 | 34,29 | 25,95 |
| Kurtçuk | 30 / 20 | %47,5 | %22,6 | %11,8 | %18,1 | 31,25 | 24,2 |
| Ekmek hamuru | 30 / 20 | %50,7 | %17,4 | %12,6 | %19,3 | 32,56 | 24,95 |
| Mısır | 40 / 20 | %55 | %10,5 | %13,6 | %20,9 | 34,29 | 25,95 |
| Boili | 60 / 10 | %41,8 | %8 | %10,4 | %39,8 | 54,36 | 38,72 |
| Karides | 100 / 10 | %46,3 | %5,2 | %17 | %31,4 | 46,7 | 34,15 |

#### Sinek (rütbe 7)

Bir gölgenin o tür olma şansı, kuşanılan sineğe göre:

| Tür | English | Nadirlik | Boy (cm) | Değer (para) | Gölge (m) | İri | Kuru sinek | Nimf | Streamer |
|---|---|---|---|---|---|---|---|---|---|
| Tatlısu Kefali | Chub | Sıradan | 20–50 | 4–11 | 0,65 |  | %29,5 | %32,9 | %27,4 |
| Kızılkanat | Rudd | Sıradan | 15–30 | 3–8 | 0,5 |  | %4,9 | %3,7 | %4,6 |
| Alabalık | Trout | Nadir | 25–60 | 18–48 | 0,65 |  | %59 | %58,5 | %54,7 |
| Dere Alabalığı | Brook Trout | Destansı | 35–80 | 42–112 | 0,8 | ✓ | %6,6 | %4,9 | %13,4 |

Sineğe göre nadirlik oranları ve balık başına ortalama değer ile rütbe puanı:

| Sinek | Fiyat (para) | Sıradan | Güzel | Nadir | Destansı | Ortalama değer | Ortalama puan |
|---|---|---|---|---|---|---|---|
| Kuru sinek | başlangıç | %34,4 | %0 | %59 | %6,6 | 24,24 | 26,76 |
| Nimf | 300 (rütbe 7) | %36,6 | %0 | %58,5 | %4,9 | 23,11 | 25,41 |
| Streamer | 900 (rütbe 8) | %31,9 | %0 | %54,7 | %13,4 | 27,5 | 30,6 |

### Derin Orta (`deep_water`; rütbe 9, yalnızca sandalla)

Dede'nin önerisi: dip ("Yayın ile mersin derinin dibinde gezer evlat. Dip dene!").

#### Şamandıra

Bir gölgenin o tür olma şansı, kuşanılan yeme göre:

| Tür | English | Nadirlik | Boy (cm) | Değer (para) | Gölge (m) | İri | Solucan | Kurtçuk | Ekmek hamuru | Mısır | Boili | Karides |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Yayın | Wels Catfish | Destansı | 100–250 | 72–192 | 1,5 | ✓ | %22 | %18,8 | %15,3 | %15,7 | %29,2 | %36,1 |
| Sazan | Carp | Güzel | 30–80 | 7–19 | 0,75 | ✓ | %20 | %17,1 | %25 | %42,9 | %31,9 | %10,9 |
| Çapak | Bream | Sıradan | 25–60 | 4–10 | 0,7 |  | %19 | %16,2 | %26,4 | %13,6 | %18,2 | %10,4 |
| Sudak | Zander | Nadir | 40–90 | 24–64 | 0,95 | ✓ | %14 | %11,9 | %9,7 | %10 | %7,4 | %19,1 |
| Turna | Pike | Nadir | 50–120 | 21–56 | 1,05 | ✓ | %12 | %10,2 | %8,3 | %8,6 | %6,4 | %16,4 |
| Levrek | Perch | Güzel | 20–45 | 7–19 | 0,75 |  | %11,5 | %24,5 | %14,4 | %8,2 | %6,1 | %6,3 |
| Mersin Balığı | Sturgeon | Efsanevi | 100–220 | satılmaz (bırakılır) | 1,75 | ✓ | %1,5 | %1,3 | %1 | %1,1 | %0,80 | %0,82 |

Yeme göre nadirlik oranları ve balık başına ortalama değer ile rütbe puanı (yem bedeli düşülmeden):

| Yem | Fiyat (para / paket) | Sıradan | Güzel | Nadir | Destansı | Efsanevi | Ortalama değer | Ortalama puan |
|---|---|---|---|---|---|---|---|---|
| Solucan | bedava, sınırsız | %19 | %31,5 | %26 | %22 | %1,5 | 40,49 | 34,28 |
| Kurtçuk | 30 / 20 | %16,2 | %41,6 | %22,2 | %18,8 | %1,3 | 36,27 | 31,16 |
| Ekmek hamuru | 30 / 20 | %26,4 | %39,3 | %18 | %15,3 | %1 | 30,92 | 26,89 |
| Mısır | 40 / 20 | %13,6 | %51,1 | %18,6 | %15,7 | %1,1 | 32,29 | 28,21 |
| Boili | 60 / 10 | %18,2 | %38 | %13,8 | %29,2 | %0,80 | 45,23 | 35,42 |
| Karides | 100 / 10 | %10,4 | %17,2 | %35,5 | %36,1 | %0,82 | 58,45 | 44,81 |

#### Spin (rütbe 2)

Bir gölgenin o tür olma şansı, kuşanılan yapay yeme göre:

| Tür | English | Nadirlik | Boy (cm) | Değer (para) | Gölge (m) | İri | Kaşık | Döner kaşık | Silikon yem | Maket balık | Su üstü yemi | Altın kaşık |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Yayın | Wels Catfish | Destansı | 100–250 | 72–192 | 1,5 | ✓ | %12,9 | %10,8 | %9,3 | %9,6 | %11,7 | %12,7 |
| Sudak | Zander | Nadir | 40–90 | 24–64 | 0,95 | ✓ | %29,5 | %24,9 | %47 | %33,1 | %26,9 | %36,3 |
| Turna | Pike | Nadir | 50–120 | 21–56 | 1,05 | ✓ | %22,5 | %18,9 | %16,3 | %37 | %36,9 | %34,5 |
| Levrek | Perch | Güzel | 20–45 | 7–19 | 0,75 |  | %35,1 | %45,4 | %27,3 | %20,2 | %24,5 | %16,5 |

Yapay yeme göre nadirlik oranları ve balık başına ortalama değer ile rütbe puanı:

| Yapay yem | Fiyat (para) | Sıradan | Güzel | Nadir | Destansı | Ortalama değer | Ortalama puan |
|---|---|---|---|---|---|---|---|
| Kaşık | başlangıç | %0 | %35,1 | %52,1 | %12,9 | 38,76 | 31,89 |
| Döner kaşık | 120 (rütbe 2) | %0 | %45,4 | %43,8 | %10,8 | 34,48 | 28,9 |
| Silikon yem | 300 (rütbe 3) | %0 | %27,3 | %63,3 | %9,3 | 38,4 | 31,76 |
| Maket balık | 700 (rütbe 5) | %0 | %20,2 | %70,2 | %9,6 | 39,56 | 33,32 |
| Su üstü yemi | 1000 (rütbe 6) | %0 | %24,5 | %63,7 | %11,7 | 40,01 | 33,43 |
| Altın kaşık | 2500 (rütbe 10) | %0 | %16,5 | %70,8 | %12,7 | 43,06 | 35,44 |

#### Dip (rütbe 4)

Bir gölgenin o tür olma şansı, kuşanılan yeme göre:

| Tür | English | Nadirlik | Boy (cm) | Değer (para) | Gölge (m) | İri | Solucan | Kurtçuk | Ekmek hamuru | Mısır | Boili | Karides |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Yayın | Wels Catfish | Destansı | 100–250 | 72–192 | 1,5 | ✓ | %28,2 | %27 | %19,1 | %18,6 | %33,1 | %50 |
| Sazan | Carp | Güzel | 30–80 | 7–19 | 0,75 | ✓ | %25,6 | %24,5 | %31,3 | %50,8 | %36,1 | %15,1 |
| Çapak | Bream | Sıradan | 25–60 | 4–10 | 0,7 |  | %24,3 | %23,3 | %33 | %16,1 | %20,6 | %14,4 |
| Sudak | Zander | Nadir | 40–90 | 24–64 | 0,95 | ✓ | %5,4 | %5,1 | %3,7 | %3,6 | %2,5 | %8 |
| Turna | Pike | Nadir | 50–120 | 21–56 | 1,05 | ✓ | %3,1 | %2,9 | %2,1 | %2 | %1,4 | %4,5 |
| Levrek | Perch | Güzel | 20–45 | 7–19 | 0,75 |  | %2,9 | %7 | %3,6 | %1,9 | %1,4 | %1,7 |
| Mersin Balığı | Sturgeon | Efsanevi | 100–220 | satılmaz (bırakılır) | 1,75 | ✓ | %2,9 | %2,8 | %2 | %1,9 | %1,4 | %1,7 |
| Aynalı Sazan | Mirror Carp | Nadir | 40–95 | 20–54 | 0,85 | ✓ | %7,7 | %7,4 | %5,2 | %5,1 | %3,6 | %4,5 |

Yeme göre nadirlik oranları ve balık başına ortalama değer ile rütbe puanı (yem bedeli düşülmeden):

| Yem | Fiyat (para / paket) | Sıradan | Güzel | Nadir | Destansı | Efsanevi | Ortalama değer | Ortalama puan |
|---|---|---|---|---|---|---|---|---|
| Solucan | bedava, sınırsız | %24,3 | %28,5 | %16,1 | %28,2 | %2,9 | 43,83 | 38,61 |
| Kurtçuk | 30 / 20 | %23,3 | %31,6 | %15,4 | %27 | %2,8 | 42,48 | 37,53 |
| Ekmek hamuru | 30 / 20 | %33 | %34,9 | %11 | %19,1 | %2 | 32,6 | 29,31 |
| Mısır | 40 / 20 | %16,1 | %52,7 | %10,7 | %18,6 | %1,9 | 32,99 | 29,95 |
| Boili | 60 / 10 | %20,6 | %37,5 | %7,6 | %33,1 | %1,4 | 47,42 | 37,6 |
| Karides | 100 / 10 | %14,4 | %16,9 | %17 | %50 | %1,7 | 68,15 | 51,76 |

