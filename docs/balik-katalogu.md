# Balık Kataloğu

> Bu dosya `tools/fish_catalog.gd` ile veriden üretilir; elle düzenleme. Veri: `data/fish.json`,
> `data/rarities.json`, `data/spots.json`, `data/gear.json`. Oranlar oyunun gölge doğururken kullandığı
> işlevlerden (`CatchOdds`) okunur; Balık Defteri'nde yazan oranlar bunlardır.

- **Değer** = türün değeri × boy çarpanı (türün en küçük boyu 0,6, en büyüğü 1,6; tamsayı para). Değeri
  0 olan (Masalsı) balık satılmaz. Koruma altındaki tür (mersin) kovaya girmez: tutulur, göle bırakılır;
  rütbe puanı ve göl sevgisi verir.
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
| Kızılkanat | Rudd | Sıradan | 15–30 | 3–8 | 0,5 | %26 | %18,4 | %18,5 | %18,6 | %16,9 | %21,7 |
| Gümüş Balığı | Silverside | Sıradan | 8–18 | 2–6 | 0,4 | %14 | %19,9 | %10 | %10 | %9,1 | %11,7 |
| Çapak | Bream | Sıradan | 25–60 | 4–10 | 0,7 | %10 | %7,1 | %14,2 | %7,1 | %11,7 | %8,3 |
| Sazan | Carp | Güzel | 30–80 | 7–19 | 0,75 | %20 | %14,2 | %25,6 | %42,9 | %39 | %16,7 |
| Levrek | Perch | Güzel | 20–45 | 7–19 | 0,75 | %18 | %31,9 | %23,1 | %12,9 | %11,7 | %15 |
| Turna | Pike | Nadir | 50–120 | 21–56 | 1,05 | %8 | %5,7 | %5,7 | %5,7 | %5,2 | %16,7 |
| Yayın | Wels Catfish | Destansı | 100–250 | 72–192 | 1,5 | %4 | %2,8 | %2,8 | %2,9 | %6,5 | %10 |

Yeme göre nadirlik oranları ve balık başına ortalama değer ile rütbe puanı (yem bedeli düşülmeden):

| Yem | Fiyat (para / paket) | Sıradan | Güzel | Nadir | Destansı | Ortalama değer | Ortalama puan |
|---|---|---|---|---|---|---|---|
| Solucan | bedava, sınırsız | %50 | %38 | %8 | %4 | 14,38 | 13,93 |
| Kurtçuk | 30 / 20 | %45,4 | %46,1 | %5,7 | %2,8 | 12,85 | 13,01 |
| Ekmek hamuru | 30 / 20 | %42,7 | %48,7 | %5,7 | %2,8 | 13,22 | 13,2 |
| Mısır | 40 / 20 | %35,7 | %55,7 | %5,7 | %2,9 | 13,64 | 13,68 |
| Boili | 60 / 10 | %37,7 | %50,6 | %5,2 | %6,5 | 17,32 | 15,86 |
| Karides | 100 / 10 | %41,7 | %31,7 | %16,7 | %10 | 23,29 | 20,18 |

### Sazlık (`reeds`; başta açık)

Bir gölgenin o tür olma şansı, kuşanılan yeme göre:

| Tür | English | Nadirlik | Boy (cm) | Değer (para) | Gölge (m) | Solucan | Kurtçuk | Ekmek hamuru | Mısır | Boili | Karides |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Kızılkanat | Rudd | Sıradan | 15–30 | 3–8 | 0,5 | %28 | %22,5 | %22,4 | %15,5 | %18,9 | %26 |
| Gümüş Balığı | Silverside | Sıradan | 8–18 | 2–6 | 0,4 | %14 | %22,5 | %11,2 | %7,7 | %9,5 | %13 |
| Sazan | Carp | Güzel | 30–80 | 7–19 | 0,75 | %24 | %19,3 | %34,6 | %39,8 | %48,6 | %22,3 |
| Kadife | Tench | Güzel | 25–55 | 8–22 | 0,7 | %22 | %17,7 | %17,6 | %30,4 | %14,9 | %20,5 |
| Levrek | Perch | Güzel | 20–45 | 7–19 | 0,75 | %7 | %14,1 | %10,1 | %3,9 | %4,7 | %6,5 |
| Turna | Pike | Nadir | 50–120 | 21–56 | 1,05 | %5 | %4 | %4 | %2,8 | %3,4 | %11,6 |

Yeme göre nadirlik oranları ve balık başına ortalama değer ile rütbe puanı (yem bedeli düşülmeden):

| Yem | Fiyat (para / paket) | Sıradan | Güzel | Nadir | Ortalama değer | Ortalama puan |
|---|---|---|---|---|---|---|
| Solucan | bedava, sınırsız | %42 | %53 | %5 | 10,32 | 11,22 |
| Kurtçuk | 30 / 20 | %45 | %51 | %4 | 9,73 | 10,83 |
| Ekmek hamuru | 30 / 20 | %33,7 | %62,3 | %4 | 10,62 | 11,58 |
| Mısır | 40 / 20 | %23,2 | %74 | %2,8 | 11,34 | 12,04 |
| Boili | 60 / 10 | %28,4 | %68,2 | %3,4 | 10,8 | 11,81 |
| Karides | 100 / 10 | %39,1 | %49,3 | %11,6 | 12 | 12,73 |

### Nilüferli Koy (`lily_cove`; rütbe 3)

Bir gölgenin o tür olma şansı, kuşanılan yeme göre:

| Tür | English | Nadirlik | Boy (cm) | Değer (para) | Gölge (m) | Solucan | Kurtçuk | Ekmek hamuru | Mısır | Boili | Karides |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Turna | Pike | Nadir | 50–120 | 21–56 | 1,05 | %22 | %15,8 | %15,7 | %14,6 | %14 | %41,4 |
| Levrek | Perch | Güzel | 20–45 | 7–19 | 0,75 | %26 | %46,8 | %33,4 | %17,2 | %16,6 | %19,5 |
| Sazan | Carp | Güzel | 30–80 | 7–19 | 0,75 | %24 | %17,3 | %30,9 | %47,7 | %45,9 | %18 |
| Kızılkanat | Rudd | Sıradan | 15–30 | 3–8 | 0,5 | %22 | %15,8 | %15,7 | %14,6 | %14 | %16,5 |
| Altın Sazan | Golden Carp | Destansı | 40–85 | 66–176 | 0,9 | %6 | %4,3 | %4,3 | %6 | %9,6 | %4,5 |

Yeme göre nadirlik oranları ve balık başına ortalama değer ile rütbe puanı (yem bedeli düşülmeden):

| Yem | Fiyat (para / paket) | Sıradan | Güzel | Nadir | Destansı | Ortalama değer | Ortalama puan |
|---|---|---|---|---|---|---|---|
| Solucan | bedava, sınırsız | %22 | %50 | %22 | %6 | 21,03 | 19,9 |
| Kurtçuk | 30 / 20 | %15,8 | %64 | %15,8 | %4,3 | 18,45 | 17,98 |
| Ekmek hamuru | 30 / 20 | %15,7 | %64,3 | %15,7 | %4,3 | 18,4 | 17,94 |
| Mısır | 40 / 20 | %14,6 | %64,9 | %14,6 | %6 | 19,83 | 18,9 |
| Boili | 60 / 10 | %14 | %62,4 | %14 | %9,6 | 23,21 | 21,21 |
| Karides | 100 / 10 | %16,5 | %37,6 | %41,4 | %4,5 | 24,32 | 23,1 |

### Kayalık Burun (`rocky_point`; rütbe 5)

Bir gölgenin o tür olma şansı, kuşanılan yeme göre:

| Tür | English | Nadirlik | Boy (cm) | Değer (para) | Gölge (m) | Solucan | Kurtçuk | Ekmek hamuru | Mısır | Boili | Karides |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Tatlısu Kefali | Chub | Sıradan | 20–50 | 4–11 | 0,65 | %30 | %21,1 | %24,5 | %30 | %27,5 | %30,9 |
| Levrek | Perch | Güzel | 20–45 | 7–19 | 0,75 | %28 | %49,3 | %41,2 | %28 | %25,7 | %16 |
| Sudak | Zander | Nadir | 40–90 | 24–64 | 0,95 | %16 | %11,3 | %13,1 | %16 | %14,7 | %22,9 |
| Kızılkanat | Rudd | Sıradan | 15–30 | 3–8 | 0,5 | %10 | %7 | %8,2 | %10 | %9,2 | %5,7 |
| Turna | Pike | Nadir | 50–120 | 21–56 | 1,05 | %10 | %7 | %8,2 | %10 | %9,2 | %14,3 |
| Yayın | Wels Catfish | Destansı | 100–250 | 72–192 | 1,5 | %6 | %4,2 | %4,9 | %6 | %13,8 | %10,3 |

Yeme göre nadirlik oranları ve balık başına ortalama değer ile rütbe puanı (yem bedeli düşülmeden):

| Yem | Fiyat (para / paket) | Sıradan | Güzel | Nadir | Destansı | Ortalama değer | Ortalama puan |
|---|---|---|---|---|---|---|---|
| Solucan | bedava, sınırsız | %40 | %28 | %26 | %6 | 22,7 | 19,49 |
| Kurtçuk | 30 / 20 | %28,2 | %49,3 | %18,3 | %4,2 | 19,48 | 17,58 |
| Ekmek hamuru | 30 / 20 | %32,7 | %41,2 | %21,2 | %4,9 | 20,71 | 18,31 |
| Mısır | 40 / 20 | %40 | %28 | %26 | %6 | 22,7 | 19,49 |
| Boili | 60 / 10 | %36,7 | %25,7 | %23,9 | %13,8 | 30,58 | 24,43 |
| Karides | 100 / 10 | %36,6 | %16 | %37,1 | %10,3 | 30,36 | 24,76 |

### Dere Ağzı (`stream_mouth`; rütbe 7)

Bir gölgenin o tür olma şansı, kuşanılan yeme göre:

| Tür | English | Nadirlik | Boy (cm) | Değer (para) | Gölge (m) | Solucan | Kurtçuk | Ekmek hamuru | Mısır | Boili | Karides |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Tatlısu Kefali | Chub | Sıradan | 20–50 | 4–11 | 0,65 | %40 | %29,1 | %33,3 | %40 | %36,7 | %43,6 |
| Levrek | Perch | Güzel | 20–45 | 7–19 | 0,75 | %25 | %45,5 | %37,5 | %25 | %22,9 | %15,2 |
| Kızılkanat | Rudd | Sıradan | 15–30 | 3–8 | 0,5 | %15 | %10,9 | %12,5 | %15 | %13,8 | %9,1 |
| Turna | Pike | Nadir | 50–120 | 21–56 | 1,05 | %14 | %10,2 | %11,7 | %14 | %12,8 | %21,2 |
| Yayın | Wels Catfish | Destansı | 100–250 | 72–192 | 1,5 | %6 | %4,4 | %5 | %6 | %13,8 | %10,9 |

Yeme göre nadirlik oranları ve balık başına ortalama değer ile rütbe puanı (yem bedeli düşülmeden):

| Yem | Fiyat (para / paket) | Sıradan | Güzel | Nadir | Destansı | Ortalama değer | Ortalama puan |
|---|---|---|---|---|---|---|---|
| Solucan | bedava, sınırsız | %55 | %25 | %14 | %6 | 18,34 | 16,11 |
| Kurtçuk | 30 / 20 | %40 | %45,5 | %10,2 | %4,4 | 16,57 | 15,27 |
| Ekmek hamuru | 30 / 20 | %45,8 | %37,5 | %11,7 | %5 | 17,26 | 15,6 |
| Mısır | 40 / 20 | %55 | %25 | %14 | %6 | 18,34 | 16,11 |
| Boili | 60 / 10 | %50,5 | %22,9 | %12,8 | %13,8 | 26,59 | 21,34 |
| Karides | 100 / 10 | %52,7 | %15,2 | %21,2 | %10,9 | 25,41 | 20,95 |

### Derin Orta (`deep_water`; rütbe 9, yalnızca sandalla)

Bir gölgenin o tür olma şansı, kuşanılan yeme göre:

| Tür | English | Nadirlik | Boy (cm) | Değer (para) | Gölge (m) | Solucan | Kurtçuk | Ekmek hamuru | Mısır | Boili | Karides |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Yayın | Wels Catfish | Destansı | 100–250 | 72–192 | 1,5 | %22 | %18,8 | %15,3 | %15,7 | %29,2 | %36,1 |
| Sazan | Carp | Güzel | 30–80 | 7–19 | 0,75 | %20 | %17,1 | %25 | %42,9 | %31,9 | %10,9 |
| Çapak | Bream | Sıradan | 25–60 | 4–10 | 0,7 | %19 | %16,2 | %26,4 | %13,6 | %18,2 | %10,4 |
| Sudak | Zander | Nadir | 40–90 | 24–64 | 0,95 | %14 | %11,9 | %9,7 | %10 | %7,4 | %19,1 |
| Turna | Pike | Nadir | 50–120 | 21–56 | 1,05 | %12 | %10,2 | %8,3 | %8,6 | %6,4 | %16,4 |
| Levrek | Perch | Güzel | 20–45 | 7–19 | 0,75 | %11,5 | %24,5 | %14,4 | %8,2 | %6,1 | %6,3 |
| Mersin Balığı | Sturgeon | Efsanevi | 100–220 | satılmaz (bırakılır) | 1,75 | %1,5 | %1,3 | %1 | %1,1 | %0,80 | %0,82 |

Yeme göre nadirlik oranları ve balık başına ortalama değer ile rütbe puanı (yem bedeli düşülmeden):

| Yem | Fiyat (para / paket) | Sıradan | Güzel | Nadir | Destansı | Efsanevi | Ortalama değer | Ortalama puan |
|---|---|---|---|---|---|---|---|---|
| Solucan | bedava, sınırsız | %19 | %31,5 | %26 | %22 | %1,5 | 40,49 | 34,28 |
| Kurtçuk | 30 / 20 | %16,2 | %41,6 | %22,2 | %18,8 | %1,3 | 36,27 | 31,16 |
| Ekmek hamuru | 30 / 20 | %26,4 | %39,3 | %18 | %15,3 | %1 | 30,92 | 26,89 |
| Mısır | 40 / 20 | %13,6 | %51,1 | %18,6 | %15,7 | %1,1 | 32,29 | 28,21 |
| Boili | 60 / 10 | %18,2 | %38 | %13,8 | %29,2 | %0,80 | 45,23 | 35,42 |
| Karides | 100 / 10 | %10,4 | %17,2 | %35,5 | %36,1 | %0,82 | 58,45 | 44,81 |

