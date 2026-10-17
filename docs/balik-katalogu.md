# Balık Kataloğu

> Bu dosya `tools/fish_catalog.gd` ile veriden üretilir; elle düzenleme. Veri: `data/fish.json`,
> `data/rarities.json`, `data/spots.json`, `data/gear.json`. Oranlar oyunun gölge doğururken kullandığı
> işlevlerden (`CatchOdds`) okunur; Balık Defteri'nde yazan oranlar bunlardır.

- **Değer** = türün değeri × boy çarpanı (türün en küçük boyu 0,6, en büyüğü 1,6; tamsayı para). Değeri
  0 olan (Masalsı) balık satılmaz.
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

## Köy Gölü (oyunun gölü, `big_lake`)

- Aynı anda en çok 4 gölge; tutulan ya da kaçanın yerine birkaç saniyede yenisi doğar.
- Hiç balık tutmamış oyuncunun ilk balığı senaryoludur: Kızılkanat, dürtmesiz, kaçmaz.
- Göl bölgelere ayrılır: gölge balıkçının çevresinde doğar, türü doğduğu yerin bölgesinden gelir.
  Oranlar bölgenindir (Balık Defteri ve dükkân bulunulan bölgeninkini gösterir). Şans garantisi
  balıkçının bölgesinde doğar; sayaç yalnızca o bölgede gelebilen kademeler için ilerler.

### İskele Koyu (`dock_cove`; başta açık)

Bir gölgenin o tür olma şansı, kuşanılan yeme göre:

| Tür | English | Nadirlik | Boy (cm) | Değer (para) | Gölge (m) | Solucan | Kurtçuk | Ekmek hamuru | Mısır | Boili | Karides |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Kızılkanat | Rudd | Sıradan | 15–30 | 3–8 | 0,5 | %40 | %30,1 | %29,1 | %26,7 | %25,6 | %32,9 |
| Sazan | Carp | Güzel | 30–80 | 7–19 | 0,75 | %25 | %18,8 | %32,7 | %50 | %48,1 | %20,6 |
| Levrek | Perch | Güzel | 20–45 | 7–19 | 0,75 | %22 | %41,4 | %28,8 | %14,7 | %14,1 | %18,1 |
| Turna | Pike | Nadir | 50–120 | 21–56 | 1,05 | %9 | %6,8 | %6,5 | %6 | %5,8 | %18,5 |
| Yayın | Wels Catfish | Destansı | 100–250 | 72–192 | 1,5 | %4 | %3 | %2,9 | %2,7 | %6,4 | %9,9 |

Yeme göre nadirlik oranları ve balık başına ortalama değer ile rütbe puanı (yem bedeli düşülmeden):

| Yem | Fiyat (para / paket) | Sıradan | Güzel | Nadir | Destansı | Ortalama değer | Ortalama puan |
|---|---|---|---|---|---|---|---|
| Solucan | bedava, sınırsız | %40 | %47 | %9 | %4 | 15,33 | 14,8 |
| Kurtçuk | 30 / 20 | %30,1 | %60,2 | %6,8 | %3 | 14,46 | 14,36 |
| Ekmek hamuru | 30 / 20 | %29,1 | %61,5 | %6,5 | %2,9 | 14,37 | 14,32 |
| Mısır | 40 / 20 | %26,7 | %64,7 | %6 | %2,7 | 14,15 | 14,21 |
| Boili | 60 / 10 | %25,6 | %62,2 | %5,8 | %6,4 | 18,16 | 16,72 |
| Karides | 100 / 10 | %32,9 | %38,7 | %18,5 | %9,9 | 24,21 | 21,05 |

### Sazlık (`reeds`; başta açık)

Bir gölgenin o tür olma şansı, kuşanılan yeme göre:

| Tür | English | Nadirlik | Boy (cm) | Değer (para) | Gölge (m) | Solucan | Kurtçuk | Ekmek hamuru | Mısır | Boili | Karides |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Kızılkanat | Rudd | Sıradan | 15–30 | 3–8 | 0,5 | %42,1 | %34 | %29,6 | %24,2 | %24,2 | %39 |
| Sazan | Carp | Güzel | 30–80 | 7–19 | 0,75 | %36,8 | %29,8 | %46,7 | %63,6 | %63,6 | %34,1 |
| Levrek | Perch | Güzel | 20–45 | 7–19 | 0,75 | %15,8 | %31,9 | %20 | %9,1 | %9,1 | %14,6 |
| Turna | Pike | Nadir | 50–120 | 21–56 | 1,05 | %5,3 | %4,3 | %3,7 | %3 | %3 | %12,2 |

Yeme göre nadirlik oranları ve balık başına ortalama değer ile rütbe puanı (yem bedeli düşülmeden):

| Yem | Fiyat (para / paket) | Sıradan | Güzel | Nadir | Ortalama değer | Ortalama puan |
|---|---|---|---|---|---|---|
| Solucan | bedava, sınırsız | %42,1 | %52,6 | %5,3 | 10,09 | 11,27 |
| Kurtçuk | 30 / 20 | %34 | %61,7 | %4,3 | 10,42 | 11,61 |
| Ekmek hamuru | 30 / 20 | %29,6 | %66,7 | %3,7 | 10,6 | 11,79 |
| Mısır | 40 / 20 | %24,2 | %72,7 | %3 | 10,81 | 12,02 |
| Boili | 60 / 10 | %24,2 | %72,7 | %3 | 10,81 | 12,02 |
| Karides | 100 / 10 | %39 | %48,8 | %12,2 | 11,86 | 12,84 |

### Nilüferli Koy (`lily_cove`; rütbe 3)

Bir gölgenin o tür olma şansı, kuşanılan yeme göre:

| Tür | English | Nadirlik | Boy (cm) | Değer (para) | Gölge (m) | Solucan | Kurtçuk | Ekmek hamuru | Mısır | Boili | Karides |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Turna | Pike | Nadir | 50–120 | 21–56 | 1,05 | %25 | %17,2 | %17,4 | %16,7 | %16,7 | %45,5 |
| Levrek | Perch | Güzel | 20–45 | 7–19 | 0,75 | %30 | %51,7 | %37,5 | %20 | %20 | %21,8 |
| Sazan | Carp | Güzel | 30–80 | 7–19 | 0,75 | %25 | %17,2 | %31,2 | %50 | %50 | %18,2 |
| Kızılkanat | Rudd | Sıradan | 15–30 | 3–8 | 0,5 | %20 | %13,8 | %13,9 | %13,3 | %13,3 | %14,5 |

Yeme göre nadirlik oranları ve balık başına ortalama değer ile rütbe puanı (yem bedeli düşülmeden):

| Yem | Fiyat (para / paket) | Sıradan | Güzel | Nadir | Ortalama değer | Ortalama puan |
|---|---|---|---|---|---|---|
| Solucan | bedava, sınırsız | %20 | %55 | %25 | 16,06 | 16,65 |
| Kurtçuk | 30 / 20 | %13,8 | %69 | %17,2 | 14,75 | 15,53 |
| Ekmek hamuru | 30 / 20 | %13,9 | %68,8 | %17,4 | 14,76 | 15,54 |
| Mısır | 40 / 20 | %13,3 | %70 | %16,7 | 14,64 | 15,44 |
| Boili | 60 / 10 | %13,3 | %70 | %16,7 | 14,64 | 15,44 |
| Karides | 100 / 10 | %14,5 | %40 | %45,5 | 21,03 | 21,06 |

### Kayalık Burun (`rocky_point`; rütbe 5)

Bir gölgenin o tür olma şansı, kuşanılan yeme göre:

| Tür | English | Nadirlik | Boy (cm) | Değer (para) | Gölge (m) | Solucan | Kurtçuk | Ekmek hamuru | Mısır | Boili | Karides |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Levrek | Perch | Güzel | 20–45 | 7–19 | 0,75 | %44,4 | %66,7 | %59 | %44,4 | %41 | %30,8 |
| Turna | Pike | Nadir | 50–120 | 21–56 | 1,05 | %22,2 | %13,3 | %16,4 | %22,2 | %20,5 | %38,5 |
| Kızılkanat | Rudd | Sıradan | 15–30 | 3–8 | 0,5 | %27,8 | %16,7 | %20,5 | %27,8 | %25,6 | %19,2 |
| Yayın | Wels Catfish | Destansı | 100–250 | 72–192 | 1,5 | %5,6 | %3,3 | %4,1 | %5,6 | %12,8 | %11,5 |

Yeme göre nadirlik oranları ve balık başına ortalama değer ile rütbe puanı (yem bedeli düşülmeden):

| Yem | Fiyat (para / paket) | Sıradan | Güzel | Nadir | Destansı | Ortalama değer | Ortalama puan |
|---|---|---|---|---|---|---|---|
| Solucan | bedava, sınırsız | %27,8 | %44,4 | %22,2 | %5,6 | 20,81 | 19,26 |
| Kurtçuk | 30 / 20 | %16,7 | %66,7 | %13,3 | %3,3 | 17,22 | 16,77 |
| Ekmek hamuru | 30 / 20 | %20,5 | %59 | %16,4 | %4,1 | 18,46 | 17,63 |
| Mısır | 40 / 20 | %27,8 | %44,4 | %22,2 | %5,6 | 20,81 | 19,26 |
| Boili | 60 / 10 | %25,6 | %41 | %20,5 | %12,8 | 28,31 | 23,89 |
| Karides | 100 / 10 | %19,2 | %30,8 | %38,5 | %11,5 | 31,42 | 27,01 |

### Dere Ağzı (`stream_mouth`; rütbe 7)

Bir gölgenin o tür olma şansı, kuşanılan yeme göre:

| Tür | English | Nadirlik | Boy (cm) | Değer (para) | Gölge (m) | Solucan | Kurtçuk | Ekmek hamuru | Mısır | Boili | Karides |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Levrek | Perch | Güzel | 20–45 | 7–19 | 0,75 | %38,9 | %61,4 | %53,4 | %38,9 | %38,9 | %33,3 |
| Kızılkanat | Rudd | Sıradan | 15–30 | 3–8 | 0,5 | %50 | %31,6 | %38,1 | %50 | %50 | %42,9 |
| Turna | Pike | Nadir | 50–120 | 21–56 | 1,05 | %11,1 | %7 | %8,5 | %11,1 | %11,1 | %23,8 |

Yeme göre nadirlik oranları ve balık başına ortalama değer ile rütbe puanı (yem bedeli düşülmeden):

| Yem | Fiyat (para / paket) | Sıradan | Güzel | Nadir | Ortalama değer | Ortalama puan |
|---|---|---|---|---|---|---|
| Solucan | bedava, sınırsız | %50 | %38,9 | %11,1 | 10,87 | 11,9 |
| Kurtçuk | 30 / 20 | %31,6 | %61,4 | %7 | 11,22 | 12,32 |
| Ekmek hamuru | 30 / 20 | %38,1 | %53,4 | %8,5 | 11,1 | 12,17 |
| Mısır | 40 / 20 | %50 | %38,9 | %11,1 | 10,87 | 11,9 |
| Boili | 60 / 10 | %50 | %38,9 | %11,1 | 10,87 | 11,9 |
| Karides | 100 / 10 | %42,9 | %33,3 | %23,8 | 14,21 | 14,88 |

### Derin Orta (`deep_water`; rütbe 9, yalnızca sandalla)

Bir gölgenin o tür olma şansı, kuşanılan yeme göre:

| Tür | English | Nadirlik | Boy (cm) | Değer (para) | Gölge (m) | Solucan | Kurtçuk | Ekmek hamuru | Mısır | Boili | Karides |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Yayın | Wels Catfish | Destansı | 100–250 | 72–192 | 1,5 | %30 | %23,1 | %21,4 | %18,8 | %36,6 | %47,4 |
| Sazan | Carp | Güzel | 30–80 | 7–19 | 0,75 | %30 | %23,1 | %38,6 | %56,2 | %43,9 | %15,8 |
| Turna | Pike | Nadir | 50–120 | 21–56 | 1,05 | %20 | %15,4 | %14,3 | %12,5 | %9,8 | %26,3 |
| Levrek | Perch | Güzel | 20–45 | 7–19 | 0,75 | %20 | %38,5 | %25,7 | %12,5 | %9,8 | %10,5 |

Yeme göre nadirlik oranları ve balık başına ortalama değer ile rütbe puanı (yem bedeli düşülmeden):

| Yem | Fiyat (para / paket) | Sıradan | Güzel | Nadir | Destansı | Ortalama değer | Ortalama puan |
|---|---|---|---|---|---|---|---|
| Solucan | bedava, sınırsız | %0 | %50 | %20 | %30 | 48,23 | 36,9 |
| Kurtçuk | 30 / 20 | %0 | %61,5 | %15,4 | %23,1 | 39,83 | 31,39 |
| Ekmek hamuru | 30 / 20 | %0 | %64,3 | %14,3 | %21,4 | 37,83 | 30,08 |
| Mısır | 40 / 20 | %0 | %68,8 | %12,5 | %18,8 | 34,57 | 27,95 |
| Boili | 60 / 10 | %0 | %53,7 | %9,8 | %36,6 | 52,93 | 39,24 |
| Karides | 100 / 10 | %0 | %26,3 | %26,3 | %47,4 | 68,13 | 49,67 |

