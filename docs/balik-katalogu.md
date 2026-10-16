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

