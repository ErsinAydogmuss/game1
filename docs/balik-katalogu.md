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
| Kerevit tuzağı | 3 | Kerevit tuzağı (150 para) | Sazlık, Kayalık Burun |

Türlerin teknik yatkınlığı (çarpan; boş: o teknikle gelmez) ve tuzağa girdiği bölgeler:

| Tür | Nadirlik | Şamandıra | Spin | Dip | Sinek | Tuzak |
|---|---|---|---|---|---|---|
| Kızılkanat | Sıradan | ×1 |  | ×0,3 | ×0,3 |  |
| Sazan | Güzel | ×1 |  | ×1 |  |  |
| Levrek | Güzel | ×1 | ×1 | ×0,2 |  |  |
| Turna | Nadir | ×1 | ×1,4 | ×0,2 |  |  |
| Yayın | Destansı | ×1 | ×0,1 | ×1,5 |  |  |
| Gümüş Balığı | Sıradan | ×1 |  |  | ×0,2 |  |
| Çapak | Sıradan | ×1 |  | ×0,5 |  |  |
| Tatlısu Kefali | Sıradan | ×1 | ×0,7 | ×0,5 | ×0,5 |  |
| Kadife | Güzel | ×1 |  | ×1 |  |  |
| Sudak | Nadir | ×1 | ×2 | ×0,3 |  |  |
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
| Levrek | Perch | Güzel | 20–45 | 7–19 | 0,75 |  | %66,9 | %75,6 | %68,5 | %41,8 | %46,7 | %38,6 |
| Turna | Pike | Nadir | 50–120 | 21–56 | 1,05 | ✓ | %32 | %23,5 | %30,4 | %57,2 | %52,3 | %60 |
| Yayın | Wels Catfish | Destansı | 100–250 | 72–192 | 1,5 | ✓ | %1,1 | %0,84 | %1,1 | %0,93 | %1 | %1,4 |

Yapay yeme göre nadirlik oranları ve balık başına ortalama değer ile rütbe puanı:

| Yapay yem | Fiyat (para) | Sıradan | Güzel | Nadir | Destansı | Ortalama değer | Ortalama puan |
|---|---|---|---|---|---|---|---|
| Kaşık | başlangıç | %0 | %66,9 | %32 | %1,1 | 20,24 | 20,13 |
| Döner kaşık | 120 (rütbe 2) | %0 | %75,6 | %23,5 | %0,84 | 18,01 | 18,25 |
| Silikon yem | 300 (rütbe 3) | %0 | %68,5 | %30,4 | %1,1 | 19,83 | 19,78 |
| Maket balık | 700 (rütbe 5) | %0 | %41,8 | %57,2 | %0,93 | 25,68 | 24,98 |
| Su üstü yemi | 1000 (rütbe 6) | %0 | %46,7 | %52,3 | %1 | 24,68 | 24,07 |
| Altın kaşık | 2500 (rütbe 10) | %0 | %38,6 | %60 | %1,4 | 26,78 | 25,82 |

#### Dip (rütbe 4)

Bir gölgenin o tür olma şansı, kuşanılan yeme göre:

| Tür | English | Nadirlik | Boy (cm) | Değer (para) | Gölge (m) | İri | Solucan | Kurtçuk | Ekmek hamuru | Mısır | Boili | Karides |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Kızılkanat | Rudd | Sıradan | 15–30 | 3–8 | 0,5 |  | %17,7 | %15,8 | %11,5 | %9,3 | %8 | %13,4 |
| Çapak | Bream | Sıradan | 25–60 | 4–10 | 0,7 |  | %11,4 | %10,1 | %14,7 | %6 | %9,3 | %8,6 |
| Sazan | Carp | Güzel | 30–80 | 7–19 | 0,75 | ✓ | %45,5 | %40,5 | %53 | %71,4 | %61,9 | %34,2 |
| Levrek | Perch | Güzel | 20–45 | 7–19 | 0,75 |  | %8,2 | %18,2 | %9,5 | %4,3 | %3,7 | %6,2 |
| Turna | Pike | Nadir | 50–120 | 21–56 | 1,05 | ✓ | %3,6 | %3,2 | %2,4 | %1,9 | %1,6 | %6,8 |
| Yayın | Wels Catfish | Destansı | 100–250 | 72–192 | 1,5 | ✓ | %13,6 | %12,1 | %8,8 | %7,1 | %15,5 | %30,8 |

Yeme göre nadirlik oranları ve balık başına ortalama değer ile rütbe puanı (yem bedeli düşülmeden):

| Yem | Fiyat (para / paket) | Sıradan | Güzel | Nadir | Destansı | Ortalama değer | Ortalama puan |
|---|---|---|---|---|---|---|---|
| Solucan | bedava, sınırsız | %29,1 | %53,6 | %3,6 | %13,6 | 25,24 | 20,86 |
| Kurtçuk | 30 / 20 | %25,9 | %58,7 | %3,2 | %12,1 | 23,78 | 20,01 |
| Ekmek hamuru | 30 / 20 | %26,2 | %62,6 | %2,4 | %8,8 | 20,08 | 17,62 |
| Mısır | 40 / 20 | %15,2 | %75,7 | %1,9 | %7,1 | 18,84 | 17,14 |
| Boili | 60 / 10 | %17,3 | %65,6 | %1,6 | %15,5 | 27,53 | 22,47 |
| Karides | 100 / 10 | %21,9 | %40,4 | %6,8 | %30,8 | 44,72 | 33,38 |

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
| Levrek | Perch | Güzel | 20–45 | 7–19 | 0,75 |  | %56,5 | %66,7 | %58,3 | %31,2 | %35,7 | %28,6 |
| Turna | Pike | Nadir | 50–120 | 21–56 | 1,05 | ✓ | %43,5 | %33,3 | %41,7 | %68,8 | %64,3 | %71,4 |

Yapay yeme göre nadirlik oranları ve balık başına ortalama değer ile rütbe puanı:

| Yapay yem | Fiyat (para) | Sıradan | Güzel | Nadir | Ortalama değer | Ortalama puan |
|---|---|---|---|---|---|---|
| Kaşık | başlangıç | %0 | %56,5 | %43,5 | 21,6 | 21,64 |
| Döner kaşık | 120 (rütbe 2) | %0 | %66,7 | %33,3 | 19,32 | 19,63 |
| Silikon yem | 300 (rütbe 3) | %0 | %58,3 | %41,7 | 21,19 | 21,28 |
| Maket balık | 700 (rütbe 5) | %0 | %31,2 | %68,8 | 27,28 | 26,63 |
| Su üstü yemi | 1000 (rütbe 6) | %0 | %35,7 | %64,3 | 26,28 | 25,75 |
| Altın kaşık | 2500 (rütbe 10) | %0 | %28,6 | %71,4 | 27,88 | 27,16 |

#### Dip (rütbe 4)

Bir gölgenin o tür olma şansı, kuşanılan yeme göre:

| Tür | English | Nadirlik | Boy (cm) | Değer (para) | Gölge (m) | İri | Solucan | Kurtçuk | Ekmek hamuru | Mısır | Boili | Karides |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Kızılkanat | Rudd | Sıradan | 15–30 | 3–8 | 0,5 |  | %11,5 | %11,2 | %9 | %5,5 | %7 | %11,3 |
| Sazan | Carp | Güzel | 30–80 | 7–19 | 0,75 | ✓ | %33 | %32 | %46,4 | %46,8 | %59,6 | %32,3 |
| Kadife | Tench | Güzel | 25–55 | 8–22 | 0,7 | ✓ | %30,2 | %29,4 | %23,6 | %35,8 | %18,2 | %29,6 |
| Levrek | Perch | Güzel | 20–45 | 7–19 | 0,75 |  | %1,9 | %4,7 | %2,7 | %0,91 | %1,2 | %1,9 |
| Turna | Pike | Nadir | 50–120 | 21–56 | 1,05 | ✓ | %1,4 | %1,3 | %1,1 | %0,65 | %0,83 | %3,4 |
| Aynalı Sazan | Mirror Carp | Nadir | 40–95 | 20–54 | 0,85 | ✓ | %16,5 | %16 | %12,9 | %7,8 | %9,9 | %16,2 |
| Kerevit | Crayfish | Sıradan | 6–14 | 6–16 | 0,3 |  | %5,5 | %5,3 | %4,3 | %2,6 | %3,3 | %5,4 |

Yeme göre nadirlik oranları ve balık başına ortalama değer ile rütbe puanı (yem bedeli düşülmeden):

| Yem | Fiyat (para / paket) | Sıradan | Güzel | Nadir | Ortalama değer | Ortalama puan |
|---|---|---|---|---|---|---|
| Solucan | bedava, sınırsız | %17 | %65,1 | %17,9 | 15,38 | 15,43 |
| Kurtçuk | 30 / 20 | %16,6 | %66,1 | %17,4 | 15,28 | 15,37 |
| Ekmek hamuru | 30 / 20 | %13,3 | %72,7 | %14 | 14,6 | 14,91 |
| Mısır | 40 / 20 | %8,1 | %83,5 | %8,5 | 13,92 | 14,17 |
| Boili | 60 / 10 | %10,3 | %79 | %10,8 | 13,96 | 14,48 |
| Karides | 100 / 10 | %16,7 | %63,8 | %19,5 | 15,76 | 15,78 |

#### Kerevit tuzağı (rütbe 3)

Gerçek saatle 20 dakikada bir tuzağa bir tür girer, en çok 4 birikir; içindekiler tuzak kurulunca
belli olur. Tuzaktan gelen balık şans garantisi sayaçlarını ilerletmez.

| Tür | Nadirlik | Şans | Değer (para) | Ortalama değer |
|---|---|---|---|---|
| Kerevit | Sıradan | %100 | 6–16 | 9,93 |

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
| Turna | Pike | Nadir | 50–120 | 21–56 | 1,05 | ✓ | %47,7 | %37,2 | %45,8 | %72,3 | %68,1 | %74,8 |
| Levrek | Perch | Güzel | 20–45 | 7–19 | 0,75 |  | %52,3 | %62,8 | %54,2 | %27,7 | %31,9 | %25,2 |

Yapay yeme göre nadirlik oranları ve balık başına ortalama değer ile rütbe puanı:

| Yapay yem | Fiyat (para) | Sıradan | Güzel | Nadir | Ortalama değer | Ortalama puan |
|---|---|---|---|---|---|---|
| Kaşık | başlangıç | %0 | %52,3 | %47,7 | 22,54 | 22,47 |
| Döner kaşık | 120 (rütbe 2) | %0 | %62,8 | %37,2 | 20,19 | 20,4 |
| Silikon yem | 300 (rütbe 3) | %0 | %54,2 | %45,8 | 22,13 | 22,1 |
| Maket balık | 700 (rütbe 5) | %0 | %27,7 | %72,3 | 28,07 | 27,33 |
| Su üstü yemi | 1000 (rütbe 6) | %0 | %31,9 | %68,1 | 27,13 | 26,5 |
| Altın kaşık | 2500 (rütbe 10) | %0 | %25,2 | %74,8 | 28,63 | 27,82 |

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
| Tatlısu Kefali | Chub | Sıradan | 20–50 | 4–11 | 0,65 |  | %20,2 | %24,7 | %14,5 | %16,4 | %35 | %14,1 |
| Levrek | Perch | Güzel | 20–45 | 7–19 | 0,75 |  | %35 | %41,1 | %27 | %21,8 | %21,2 | %18,8 |
| Sudak | Zander | Nadir | 40–90 | 24–64 | 0,95 | ✓ | %30,8 | %23,5 | %48,5 | %37,4 | %24,2 | %43 |
| Turna | Pike | Nadir | 50–120 | 21–56 | 1,05 | ✓ | %13,5 | %10,3 | %9,6 | %24 | %19,1 | %23,5 |
| Yayın | Wels Catfish | Destansı | 100–250 | 72–192 | 1,5 | ✓ | %0,58 | %0,44 | %0,41 | %0,47 | %0,45 | %0,64 |

Yapay yeme göre nadirlik oranları ve balık başına ortalama değer ile rütbe puanı:

| Yapay yem | Fiyat (para) | Sıradan | Güzel | Nadir | Destansı | Ortalama değer | Ortalama puan |
|---|---|---|---|---|---|---|---|
| Kaşık | başlangıç | %20,2 | %35 | %44,2 | %0,58 | 22,96 | 20,82 |
| Döner kaşık | 120 (rütbe 2) | %24,7 | %41,1 | %33,8 | %0,44 | 19,87 | 18,36 |
| Silikon yem | 300 (rütbe 3) | %14,5 | %27 | %58,1 | %0,41 | 27,09 | 23,84 |
| Maket balık | 700 (rütbe 5) | %16,4 | %21,8 | %61,4 | %0,47 | 27,22 | 24,39 |
| Su üstü yemi | 1000 (rütbe 6) | %35 | %21,2 | %43,3 | %0,45 | 21,56 | 19,57 |
| Altın kaşık | 2500 (rütbe 10) | %14,1 | %18,8 | %66,5 | %0,64 | 28,95 | 25,67 |

#### Dip (rütbe 4)

Bir gölgenin o tür olma şansı, kuşanılan yeme göre:

| Tür | English | Nadirlik | Boy (cm) | Değer (para) | Gölge (m) | İri | Solucan | Kurtçuk | Ekmek hamuru | Mısır | Boili | Karides |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Tatlısu Kefali | Chub | Sıradan | 20–50 | 4–11 | 0,65 |  | %34,6 | %29 | %31,3 | %34,6 | %26,4 | %32,3 |
| Levrek | Perch | Güzel | 20–45 | 7–19 | 0,75 |  | %12,9 | %27 | %21,1 | %12,9 | %9,8 | %6,7 |
| Sudak | Zander | Nadir | 40–90 | 24–64 | 0,95 | ✓ | %11,1 | %9,3 | %10 | %11,1 | %8,4 | %14,4 |
| Kızılkanat | Rudd | Sıradan | 15–30 | 3–8 | 0,5 |  | %6,9 | %5,8 | %6,3 | %6,9 | %5,3 | %3,6 |
| Turna | Pike | Nadir | 50–120 | 21–56 | 1,05 | ✓ | %4,6 | %3,9 | %4,2 | %4,6 | %3,5 | %6 |
| Yayın | Wels Catfish | Destansı | 100–250 | 72–192 | 1,5 | ✓ | %20,7 | %17,4 | %18,8 | %20,7 | %39,5 | %32,3 |
| Kerevit | Crayfish | Sıradan | 6–14 | 6–16 | 0,3 |  | %9,2 | %7,7 | %8,4 | %9,2 | %7 | %4,8 |

Yeme göre nadirlik oranları ve balık başına ortalama değer ile rütbe puanı (yem bedeli düşülmeden):

| Yem | Fiyat (para / paket) | Sıradan | Güzel | Nadir | Destansı | Ortalama değer | Ortalama puan |
|---|---|---|---|---|---|---|---|
| Solucan | bedava, sınırsız | %50,7 | %12,9 | %15,7 | %20,7 | 35,61 | 26,51 |
| Kurtçuk | 30 / 20 | %42,5 | %27 | %13,1 | %17,4 | 31,76 | 24,32 |
| Ekmek hamuru | 30 / 20 | %45,9 | %21,1 | %14,2 | %18,8 | 33,39 | 25,25 |
| Mısır | 40 / 20 | %50,7 | %12,9 | %15,7 | %20,7 | 35,61 | 26,51 |
| Boili | 60 / 10 | %38,7 | %9,8 | %12 | %39,5 | 55,21 | 39,05 |
| Karides | 100 / 10 | %40,7 | %6,7 | %20,3 | %32,3 | 49,56 | 35,77 |

#### Kerevit tuzağı (rütbe 3)

Gerçek saatle 20 dakikada bir tuzağa bir tür girer, en çok 4 birikir; içindekiler tuzak kurulunca
belli olur. Tuzaktan gelen balık şans garantisi sayaçlarını ilerletmez.

| Tür | Nadirlik | Şans | Değer (para) | Ortalama değer |
|---|---|---|---|---|
| Kerevit | Sıradan | %100 | 6–16 | 9,93 |

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
| Tatlısu Kefali | Chub | Sıradan | 20–50 | 4–11 | 0,65 |  | %23,3 | %29,4 | %22,9 | %17,3 | %34,4 | %16 |
| Turna | Pike | Nadir | 50–120 | 21–56 | 1,05 | ✓ | %33,7 | %26,5 | %33,1 | %55 | %40,6 | %57,9 |
| Levrek | Perch | Güzel | 20–45 | 7–19 | 0,75 |  | %24,1 | %29,2 | %25,5 | %13,7 | %12,4 | %12,7 |
| Yayın | Wels Catfish | Destansı | 100–250 | 72–192 | 1,5 | ✓ | %0,74 | %0,58 | %0,73 | %0,55 | %0,50 | %0,81 |
| Alabalık | Trout | Nadir | 25–60 | 18–48 | 0,65 |  | %16,7 | %13,1 | %16,4 | %12,4 | %11,2 | %11,5 |
| Dere Alabalığı | Brook Trout | Destansı | 35–80 | 42–112 | 0,8 | ✓ | %1,5 | %1,2 | %1,5 | %1,1 | %0,99 | %1 |

Yapay yeme göre nadirlik oranları ve balık başına ortalama değer ile rütbe puanı:

| Yapay yem | Fiyat (para) | Sıradan | Güzel | Nadir | Destansı | Ortalama değer | Ortalama puan |
|---|---|---|---|---|---|---|---|
| Kaşık | başlangıç | %23,3 | %24,1 | %50,4 | %2,2 | 22,84 | 22,91 |
| Döner kaşık | 120 (rütbe 2) | %29,4 | %29,2 | %39,7 | %1,8 | 19,96 | 20,08 |
| Silikon yem | 300 (rütbe 3) | %22,9 | %25,5 | %49,5 | %2,2 | 22,64 | 22,74 |
| Maket balık | 700 (rütbe 5) | %17,3 | %13,7 | %67,3 | %1,6 | 26,73 | 26,29 |
| Su üstü yemi | 1000 (rütbe 6) | %34,4 | %12,4 | %51,8 | %1,5 | 22,33 | 21,97 |
| Altın kaşık | 2500 (rütbe 10) | %16 | %12,7 | %69,4 | %1,8 | 27,53 | 26,91 |

#### Dip (rütbe 4)

Bir gölgenin o tür olma şansı, kuşanılan yeme göre:

| Tür | English | Nadirlik | Boy (cm) | Değer (para) | Gölge (m) | İri | Solucan | Kurtçuk | Ekmek hamuru | Mısır | Boili | Karides |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Tatlısu Kefali | Chub | Sıradan | 20–50 | 4–11 | 0,65 |  | %42,7 | %37,3 | %39,6 | %42,7 | %29,9 | %36,7 |
| Turna | Pike | Nadir | 50–120 | 21–56 | 1,05 | ✓ | %12,3 | %10,8 | %11,5 | %12,3 | %8,6 | %14,7 |
| Levrek | Perch | Güzel | 20–45 | 7–19 | 0,75 |  | %9,5 | %20,7 | %15,9 | %9,5 | %6,6 | %4,5 |
| Kızılkanat | Rudd | Sıradan | 15–30 | 3–8 | 0,5 |  | %7,1 | %6,2 | %6,6 | %7,1 | %5 | %3,4 |
| Yayın | Wels Catfish | Destansı | 100–250 | 72–192 | 1,5 | ✓ | %28,4 | %24,9 | %26,4 | %28,4 | %49,8 | %40,7 |

Yeme göre nadirlik oranları ve balık başına ortalama değer ile rütbe puanı (yem bedeli düşülmeden):

| Yem | Fiyat (para / paket) | Sıradan | Güzel | Nadir | Destansı | Ortalama değer | Ortalama puan |
|---|---|---|---|---|---|---|---|
| Solucan | bedava, sınırsız | %49,8 | %9,5 | %12,3 | %28,4 | 42,25 | 31,01 |
| Kurtçuk | 30 / 20 | %43,6 | %20,7 | %10,8 | %24,9 | 38,46 | 28,78 |
| Ekmek hamuru | 30 / 20 | %46,3 | %15,9 | %11,5 | %26,4 | 40,11 | 29,75 |
| Mısır | 40 / 20 | %49,8 | %9,5 | %12,3 | %28,4 | 42,25 | 31,01 |
| Boili | 60 / 10 | %34,9 | %6,6 | %8,6 | %49,8 | 64,97 | 45,47 |
| Karides | 100 / 10 | %40 | %4,5 | %14,7 | %40,7 | 56,41 | 40,29 |

#### Sinek (rütbe 7)

Bir gölgenin o tür olma şansı, kuşanılan sineğe göre:

| Tür | English | Nadirlik | Boy (cm) | Değer (para) | Gölge (m) | İri | Kuru sinek | Nimf | Streamer |
|---|---|---|---|---|---|---|---|---|---|
| Tatlısu Kefali | Chub | Sıradan | 20–50 | 4–11 | 0,65 |  | %29,5 | %28,7 | %27,4 |
| Kızılkanat | Rudd | Sıradan | 15–30 | 3–8 | 0,5 |  | %4,9 | %3,2 | %4,6 |
| Alabalık | Trout | Nadir | 25–60 | 18–48 | 0,65 |  | %59 | %63,8 | %54,7 |
| Dere Alabalığı | Brook Trout | Destansı | 35–80 | 42–112 | 0,8 | ✓ | %6,6 | %4,3 | %13,4 |

Sineğe göre nadirlik oranları ve balık başına ortalama değer ile rütbe puanı:

| Sinek | Fiyat (para) | Sıradan | Güzel | Nadir | Destansı | Ortalama değer | Ortalama puan |
|---|---|---|---|---|---|---|---|
| Kuru sinek | başlangıç | %34,4 | %0 | %59 | %6,6 | 24,24 | 26,76 |
| Nimf | 300 (rütbe 7) | %31,9 | %0 | %63,8 | %4,3 | 23,94 | 26,35 |
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
| Yayın | Wels Catfish | Destansı | 100–250 | 72–192 | 1,5 | ✓ | %3,6 | %3,1 | %2,3 | %2,4 | %3,1 | %3,1 |
| Sudak | Zander | Nadir | 40–90 | 24–64 | 0,95 | ✓ | %45,2 | %40 | %63,7 | %45,3 | %38,9 | %49,5 |
| Turna | Pike | Nadir | 50–120 | 21–56 | 1,05 | ✓ | %27,1 | %24 | %17,4 | %39,9 | %42 | %37,2 |
| Levrek | Perch | Güzel | 20–45 | 7–19 | 0,75 |  | %24,1 | %32,9 | %16,6 | %12,4 | %16 | %10,2 |

Yapay yeme göre nadirlik oranları ve balık başına ortalama değer ile rütbe puanı:

| Yapay yem | Fiyat (para) | Sıradan | Güzel | Nadir | Destansı | Ortalama değer | Ortalama puan |
|---|---|---|---|---|---|---|---|
| Kaşık | başlangıç | %0 | %24,1 | %72,3 | %3,6 | 34,17 | 29,7 |
| Döner kaşık | 120 (rütbe 2) | %0 | %32,9 | %64 | %3,1 | 31,6 | 27,78 |
| Silikon yem | 300 (rütbe 3) | %0 | %16,6 | %81,1 | %2,3 | 35,72 | 30,58 |
| Maket balık | 700 (rütbe 5) | %0 | %12,4 | %85,2 | %2,4 | 35,82 | 31,47 |
| Su üstü yemi | 1000 (rütbe 6) | %0 | %16 | %81 | %3,1 | 35,26 | 31,08 |
| Altın kaşık | 2500 (rütbe 10) | %0 | %10,2 | %86,7 | %3,1 | 37,16 | 32,25 |

#### Dip (rütbe 4)

Bir gölgenin o tür olma şansı, kuşanılan yeme göre:

| Tür | English | Nadirlik | Boy (cm) | Değer (para) | Gölge (m) | İri | Solucan | Kurtçuk | Ekmek hamuru | Mısır | Boili | Karides |
|---|---|---|---|---|---|---|---|---|---|---|---|---|
| Yayın | Wels Catfish | Destansı | 100–250 | 72–192 | 1,5 | ✓ | %41,4 | %39,7 | %30,8 | %27,6 | %46,7 | %63,6 |
| Sazan | Carp | Güzel | 30–80 | 7–19 | 0,75 | ✓ | %25,1 | %24,1 | %33,6 | %50,1 | %33,9 | %12,9 |
| Çapak | Bream | Sıradan | 25–60 | 4–10 | 0,7 |  | %11,9 | %11,4 | %17,8 | %7,9 | %9,7 | %6,1 |
| Sudak | Zander | Nadir | 40–90 | 24–64 | 0,95 | ✓ | %5,3 | %5,1 | %3,9 | %3,5 | %2,4 | %6,8 |
| Turna | Pike | Nadir | 50–120 | 21–56 | 1,05 | ✓ | %3 | %2,9 | %2,2 | %2 | %1,4 | %3,9 |
| Levrek | Perch | Güzel | 20–45 | 7–19 | 0,75 |  | %2,9 | %6,9 | %3,9 | %1,9 | %1,3 | %1,5 |
| Mersin Balığı | Sturgeon | Efsanevi | 100–220 | satılmaz (bırakılır) | 1,75 | ✓ | %2,8 | %2,7 | %2,1 | %1,9 | %1,3 | %1,4 |
| Aynalı Sazan | Mirror Carp | Nadir | 40–95 | 20–54 | 0,85 | ✓ | %7,5 | %7,2 | %5,6 | %5 | %3,4 | %3,9 |

Yeme göre nadirlik oranları ve balık başına ortalama değer ile rütbe puanı (yem bedeli düşülmeden):

| Yem | Fiyat (para / paket) | Sıradan | Güzel | Nadir | Destansı | Efsanevi | Ortalama değer | Ortalama puan |
|---|---|---|---|---|---|---|---|---|
| Solucan | bedava, sınırsız | %11,9 | %28 | %15,8 | %41,4 | %2,8 | 58,63 | 48,09 |
| Kurtçuk | 30 / 20 | %11,4 | %31 | %15,2 | %39,7 | %2,7 | 56,68 | 46,63 |
| Ekmek hamuru | 30 / 20 | %17,8 | %37,5 | %11,8 | %30,8 | %2,1 | 46,14 | 38,54 |
| Mısır | 40 / 20 | %7,9 | %52,1 | %10,5 | %27,6 | %1,9 | 42,97 | 36,37 |
| Boili | 60 / 10 | %9,7 | %35,2 | %7,1 | %46,7 | %1,3 | 62,45 | 47,12 |
| Karides | 100 / 10 | %6,1 | %14,3 | %14,5 | %63,6 | %1,4 | 82,57 | 60,39 |

