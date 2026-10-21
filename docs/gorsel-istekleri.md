# Görsel İstekleri (ChatGPT için prompt paketi)

Bu sayfadaki görselleri ChatGPT ile üretip game1'e yüklersen gerisini ben hallederim:

- arka planı silerim;
- sayfaları parçalara keserim;
- adlandırıp oyuna bağlarım.

Görsel gelene kadar oyun kodla çizilen yer tutucuları kullanır, yani oyun görselsiz de çalışıyor. Senin görsellerin onu bitmiş bir oyun gibi gösterecek.

**Balık görseli istemiyoruz:** balıkların resimleri oyunun kendi 3D modelinden çekiliyor.

## Kısaca

Görseller partiler hâlinde geliyor; her parti bir dalgadan önce. **Hepsini birden beklemene gerek yok:** hazır olanı yükle, ben bağlayayım.

| Parti | Ne zaman | Sayfa | Oyunda nerede |
|---|---|---|---|
| 1. Arayüz | ✅ geldi, oyunda (v0.2.1) | 12 | paneller, düğmeler, nadirlik kartları, ikonlar, Dede ve Nine'nin yüzü, uygulama ikonu |
| 2. Ekipman | ✅ geldi, oyunda (v0.2.1) | 7 | Nine'nin dükkânındaki 42 eşya (bugün satılan 33'ü görünüyor; kalanı Dalga 2–4'te) |
| 3. Göl | ✅ geldi, oyunda | 5 | bölge rozetleri, harita kâğıdı, harita çıkartmaları ve ikonları, zemin dokuları |
| 4. Teknikler | ✅ geldi, oyunda (v0.4) | 4 | yapay yemler, sinekler ve dip takımı, teknik ikonları, takım çantası, kerevit (çöp ve hikâye eşyaları Dalga 4'te) |
| 5a. Hikâye ve canlı dünya | Dalga 4 (promptlar aşağıda) | 6 + 2 isteğe bağlı | vakit ve hava ikonları, çay, göl sevgisi, istekler, altın hamur, mektup kâğıdı, sırrın haritası, Gölün Bekçisi |
| 5b. Yuva | Dalga 5'ten önce | ~4 | kedi, kıyafetler, akvaryum, karakter seçimi, tanıtım görseli |

5a'nın promptları aşağıda; 5b'ninkileri (kedi, kıyafetler) Dalga 5'ten önce eklerim: kedinin modeli ve kıyafetlerin tasarımı o zaman belli olacak.

## Nasıl teslim edersin?

1. GitHub'da repoyu aç: **ErsinAydogmuss/game1**.
2. Sol üstteki dal (branch) menüsünden **`claude/festive-shannon-yycmwu`** dalını seç.
3. **Add file → Upload files** ekranında dosya adının başına `assets/incoming/` yaz. Klasör yoksa böyle oluşur.
4. Görselleri sürükle → **Commit changes**.
5. Bana "görselleri yükledim" yaz. Kesip oyuna bağlarım ve sana ekran görüntüsü gönderirim.

**Dosya adları önemli:** Her görseli aşağıdaki adla kaydet (ör. `ui_frames.png`). PNG, JPG ya da WEBP olabilir.

## Genel kurallar (Kazı'dakiyle aynı)

- **Boyut:** yatay **1536×1024** (logo ve uygulama ikonu 1024×1024).
- **Arka plan:** düz, saf **macenta (#FF00FF)**.
  - "Şeffaf arka plan" isteme; ChatGPT sahte dama deseni çiziyor.
  - Pembe ya da mor nesneli sayfalarda da macenta kalabilir: kesim aracı o sayfalarda yalnızca kenar bandını temizler (`"despill": "edge"`; nadirlik çerçeveleri, nilüferli sayfalar). Nesnenin rengi yine soluyorsa o sayfayı düz **yeşil (#00FF00)** arka planla iste.
- **6'lı sayfa (3×2 ızgara):** nesneler birbirine değmesin, aralarında boşluk olsun.
- **Yazı yok:** yazı, gölge ve zemin olmasın (logo hariç).
- **Stil sabit kalsın:** ilk ürettiğin **stil sayfasını** sonraki her isteğe referans görsel olarak ekle. Prompttaki stil cümlelerini değiştirme, yalnızca nesne listesini değiştir.
- **Beğenmezsen:** aynı promptla yeniden üret ya da tek nesneyi düzelt: "Keep everything the same, only redraw the bucket".
- **Çerçeveler ve düğmeler için ek kural:** içleri düz, tek renk olmalı (desen yok). Oyun onları her boyuta gerdirir; süsler yalnızca kenarda ve köşelerde durur. İçi desenli çıkarsa: "Make the inside a plain flat cream color".

---

## Parti 1 — Arayüz (önce bunlar, bu sırayla)

### 1. Stil sayfası: `style_sheet.png`

Önce bunu üret ve beğenene kadar tekrarla. Bütün oyunun görünümünü bu belirliyor.

```
Style reference sheet for a cozy lakeside fishing mobile game, stylized low-poly 3D look:
chunky simple shapes, soft gradient colors, gentle bevels, subtle ambient occlusion,
warm morning light from the top-left, slightly toy-like proportions, clean readable silhouettes,
calm teal-and-wood color mood. Show 6 sample objects evenly spaced: a bamboo fishing rod with a
cork handle, a red-and-white round bobber, a small wooden bucket, a paper lantern on a post,
a green lily pad with a pink flower, a cute plump carp with big eyes.
Plus a small color palette strip. Solid flat pure magenta background (#FF00FF).
No text, no labels, no shadows.
```

### 2. Hedef ekran: `concept_screen.png`

Oyunda görünmez. Oyunun nasıl görünmesini istediğimizi gösteren bir "hayal ekran görüntüsü": 3D sahneyi buna benzetmeye çalışacağım.

```
Concept art of an in-game screenshot for a cozy lakeside fishing mobile game, landscape,
exactly matching the attached style reference, stylized low-poly 3D look, oblique top-down
camera at about 50 degrees. A calm teal lake with a few dark fish shadows visible under the
water, one of them softly sparkling. A wooden dock: an old grandfather in a brown flat cap,
white beard and a brick-red knitted sweater sits on its edge with a small tulip-shaped tea glass.
A young angler girl in a teal bucket hat with a yellow band and a yellow fishing vest casts a
line with a red-and-white bobber. At the land end of the dock, a small wooden fishing shop hut
with a striped awning and a grandmother in a white floral headscarf. Reeds, lily pads with
pink flowers, chunky low-poly trees and rocks around the shore, warm morning light.
No user interface, no text.
```

### 3. Uygulama ikonu: `app_icon.png` (1024×1024)

Telefonun ana ekranında görünecek.

```
Mobile app icon, square, stylized low-poly 3D: a cute plump fish jumping out of teal water
toward a red-and-white bobber, wooden dock edge at the bottom, soft warm light, bold simple
shapes readable at small size, matching the attached style reference. No text.
Fill the whole square edge to edge with the scene: no magenta background, no border,
no transparency, sharp square corners (the phone rounds the corners itself).
```

- Köşeleri yuvarlatma; iPhone kendisi yuvarlar.
- İkon telefonda küçük görünecek: görsele uzaktan bir bak, balık ve şamandıra seçiliyor mu?

### 4. Arayüz çerçeveleri: `ui_frames.png`

Bütün panellerin, kartların ve konuşma balonlarının çerçevesi.

```
Sheet of 6 cozy wooden-and-cream mobile game UI frames in a 3x2 grid, exactly matching the
attached style reference: chunky shapes, soft gradients, thick dark brown outline, warm top-left
light, flat front view (not tilted). Each element centered in its own cell with generous empty
space around it. The INSIDE of every frame is a plain, flat, single cream color (#FFF3D9) with
no pattern, no texture and no shading, so it can be stretched; all decoration stays on the
border and the corners. No text, no icons, no shadows.
Solid flat pure magenta background (#FF00FF) everywhere, no gradient, no checkerboard.
Elements, left to right, top row then bottom row: a large square panel with a thick carved
wooden border and small rope-tied corners; a smaller square item card with a thin wooden border
and rounded corners; a tab shape with rounded top corners and a flat bottom; a wide horizontal
ribbon banner with folded ends; a wide pill shape with fully rounded ends and a thin wooden
border; a speech bubble with a small tail at the bottom center.
```

Kesilen adlar: `panel`, `card`, `tab`, `ribbon`, `pill`, `bubble`.

### 5. Düğmeler: `ui_buttons.png`

```
Sheet of 6 glossy cartoon mobile game buttons in a 3x2 grid, exactly matching the attached
style reference: chunky rounded rectangles with a thick dark outline, a soft highlight band on
top and a darker 3D lip along the bottom edge, flat front view. The face of each button is a
plain smooth color with no text, no icons and no pattern, so it can be stretched. Each button
centered in its own cell with empty space around it.
Solid flat pure magenta background (#FF00FF) everywhere, no gradient, no checkerboard.
Buttons, left to right, top row then bottom row: grass green, warm orange, sky blue, slate gray
and tomato red wide rounded rectangles, and one round circular button in warm orange.
```

Kesilen adlar: `button_green`, `button_orange`, `button_blue`, `button_gray`, `button_red`, `button_round`.

### 6. Nadirlik çerçeveleri: `rarity_frames.png`

Balık kartının çerçevesi; nadir balık daha süslü bir kartta çıkar.

```
Sheet of 6 collectible card frames for a cozy fishing game in a 3x2 grid, exactly matching the
attached style reference, flat front view, all the same size and shape: a portrait rectangle
with rounded corners. The INSIDE of every frame is a plain flat cream color (#FFF3D9) with no
pattern, so it can be stretched; all decoration stays on the border. No text, no icons, no
shadows. Solid flat pure magenta background (#FF00FF) everywhere.
The frames get fancier from left to right, top row then bottom row: a simple light gray stone
border; a green border with small leaves; a blue border with small water droplets and pearls;
a purple border with tiny shells and sparkles; a thick ornate gold border with a fish-scale
pattern and small gems; a shimmering teal-and-silver border with wave swirls and tiny stars.
```

Kesilen adlar: `frame_common`, `frame_fine`, `frame_rare`, `frame_epic`, `frame_legendary`, `frame_mythic` (Sıradan, Güzel, Nadir, Destansı, Efsanevi, Masalsı).

### 7. Nadirlik rozetleri: `rarity_badges.png`

Her kademenin bir şekli var. Renkleri ayırt edemeyen oyuncu da şekilden anlasın diye.

```
Sheet of 6 small glossy badge icons for fish rarity in a 3x2 grid, exactly matching the attached
style reference: each a simple bold shape readable at a small size, front view, thick dark
outline. No text, no shadows. Solid flat pure magenta background (#FF00FF).
Left to right, top row then bottom row: a gray round pebble; a green triangle-shaped gem;
a blue diamond-shaped gem; a purple five-point star; a golden four-point sparkle star;
a teal round medallion with a white star in the middle.
```

Kesilen adlar: `rarity_common`, `rarity_fine`, `rarity_rare`, `rarity_epic`, `rarity_legendary`, `rarity_mythic`.

### 8. Dede portreleri: `portraits.png` (3×1)

Dede ipucu çubuğunda konuşuyor; portresi orada görünecek. Oyundaki 3D Dede'ye benzemeli: kahverengi kasket, beyaz sakal, tuğla kırmızısı kazak.

```
Sheet of 3 portrait busts of the same character in a 3x1 grid, exactly matching the attached
style reference, stylized low-poly 3D look: a kind Turkish grandfather fisherman, round friendly
face, short white beard and mustache, bushy white eyebrows, sun-tanned skin, a brown flat cap
with a short brim, a brick-red chunky knitted sweater with a cream wool collar.
Head and shoulders, facing slightly toward the viewer. Moods, left to right: warm smile;
surprised and excited (eyebrows up, mouth open); telling a mysterious story (one finger raised,
eyes narrowed playfully). Same size and framing in each cell.
Solid flat pure magenta background (#FF00FF). No text, no shadows.
```

Kesilen adlar: `dede_smile`, `dede_wow`, `dede_story`.

### 9. Nine portreleri: `portraits_nine.png` (3×1)

Nine, Dede'nin eşi ve dükkânı işletiyor. 3D modelini bu portreye göre boyayacağım.

```
Sheet of 3 portrait busts of the same character in a 3x1 grid, exactly matching the attached
style reference, stylized low-poly 3D look: a kind Turkish grandmother, round friendly face with
rosy cheeks and small round glasses, silver-gray hair under a white headscarf with small blue
flowers tied under the chin, a mustard-yellow knitted cardigan and a teal apron with white polka
dots. Head and shoulders, facing slightly toward the viewer. Moods, left to right: warm smile;
surprised and delighted (eyebrows up, hands on her cheeks); proudly offering a small paper bag
(one eyebrow raised playfully). Same size and framing in each cell.
Solid flat pure magenta background (#FF00FF). No text, no shadows.
```

Kesilen adlar: `nine_smile`, `nine_wow`, `nine_story`.

### 10. Eylem ikonları: `ui_1.png`

İlk dördü büyük eylem düğmesinde görünür; son ikisi kova ve akvaryum için.

```
Sheet of 6 glossy cartoon mobile game UI icons in a 3x2 grid, exactly matching the attached
style reference: chunky shapes, soft gradients, thick dark outline, warm top-left light,
3/4 view. Each icon centered in its own cell with generous empty space around it, all at a
similar size. No text, no labels, no shadows, no floor.
Solid flat pure magenta background (#FF00FF) everywhere, no gradient, no checkerboard.
Icons, left to right, top row then bottom row: a fishing rod with a reel and a red-and-white
bobber hanging from the tip, a fishing reel close-up with a crank handle, a big shiny steel
fishing hook, an open hand with the palm facing the viewer (a calm "wait" gesture),
a wooden bucket with a fish tail sticking out, a round fish tank aquarium with a small fish.
```

| Kesilen ad | Nerede |
|---|---|
| `rod` | AT |
| `reel` | SAR ve GERİ SAR |
| `hook` | VUR |
| `hand` | BEKLE. Şimdiki el Kazı'nın "dokun" parmağı; beklerken dokunma demeli, o yüzden açık el. |
| `bucket` | kova |
| `aquarium` | akvaryum |

### 11. Genel ikonlar: `ui_2.png`

```
(ui_1 ile aynı stil cümleleri.) Icons, left to right, top row then bottom row: a shiny gold coin
with a small fish emblem; a leather-bound notebook with a fish drawn on the cover; a folded paper
map with a small lake drawn on it; a small wooden market stall with a striped awning; a small
sack full of gold coins; a happy fish jumping back into the water with a small heart above it.
```

| Kesilen ad | Nerede |
|---|---|
| `coin` | para |
| `book` | Balık Defteri |
| `map` | harita |
| `shop` | dükkân |
| `sell` | "hepsini sat" |
| `release` | balığı göle bırak |

### 12. Logo: `logo.png` (1024×1024)

```
Game logo for a cozy fishing game titled "OLTA" with a small subtitle "Gölün Sırrı",
chunky rounded 3D letters in warm wood and teal colors, a fishing line with a red-and-white
bobber hooking the letter O, a few water droplets, stylized low-poly game art matching the
attached style reference. Turkish characters must be correct: Ö, ü, ı (dotless i).
Solid flat pure magenta background (#FF00FF).
```

Türkçe harfleri kontrol et: "Gölün Sırrı"daki **ö, ü ve ı** doğru çizilmiş olmalı. Yanlışsa "Fix the Turkish letters: Ö, ü and dotless ı" diye düzelttir.

---

## Parti 2 — Ekipman (Nine'nin dükkânı)

Yedi sayfanın hepsinde aynı stil cümleleri kullanılır, yalnızca eşya listesi değişir. Her sayfada eşyalar soldan sağa giderek daha iyi ve süslü olur:

```
Sheet of 6 fishing gear icons for a cozy mobile game shop in a 3x2 grid, exactly matching the
attached style reference: chunky shapes, soft gradients, thick dark outline, warm top-left light,
3/4 view. Each item centered in its own cell with generous empty space, all at a similar size.
Long items such as rods are drawn diagonally from bottom-left to top-right. No text, no labels,
no shadows, no floor.
Solid flat pure magenta background (#FF00FF) everywhere, no gradient, no checkerboard.
Items, left to right, top row then bottom row: <EŞYA LİSTESİ>
```

**1. `gear_rods_1.png`: şamandıra ve spin kamışları**

```
a simple bamboo float rod with a cork handle; a light-blue fiberglass float rod with a small
reel; a sleek dark-gray carbon float rod with gold rings; a short light spinning rod, green;
a medium spinning rod, orange; a heavy spinning rod, red, with a big reel
```

Adlar: `rod_bamboo`, `rod_float_glass`, `rod_float_carbon`, `rod_spin_light`, `rod_spin_medium`, `rod_spin_heavy`.

**2. `gear_rods_2.png`: dip ve sinek kamışları**

```
a sturdy olive-green carp rod with a big reel; a stronger dark-green carp rod with brass
fittings; a premium black-and-gold carp rod; a slim light-wood fly rod with a fly reel;
a deep-blue fly rod; a premium bamboo fly rod with silver fittings
```

Adlar: `rod_carp_1`, `rod_carp_2`, `rod_carp_3`, `rod_fly_1`, `rod_fly_2`, `rod_fly_3`.

**3. `gear_reels.png`: makaralar**

```
a simple gray plastic reel; a smooth blue reel; a fast green reel with a big handle; a strong
orange reel with a thick drag knob; a pro black-and-silver reel; a master gold reel with a small
fish emblem
```

Adlar: `reel_basic`, `reel_smooth`, `reel_quick`, `reel_strong`, `reel_pro`, `reel_master`.

**4. `gear_lines.png`: misinalar**

```
a spool of thin clear fishing line; a spool of thicker clear line; a spool of pale-blue
fluorocarbon line; a spool of premium light-aqua fluorocarbon line; a spool of bright-yellow
braided line; a spool of premium bright-orange braided line
```

Adlar: `line_mono_thin`, `line_mono`, `line_fluoro`, `line_fluoro_pro`, `line_braid`, `line_braid_pro`.

**5. `gear_hooks_bobbers.png`: iğneler ve şamandıralar**

```
a small silver fishing hook; a medium silver hook; a large strong bronze hook; a classic round
red-and-white bobber; a slim sensitive pencil float with an orange tip and a green body; a big
bright yellow-and-red bobber with a little flag
```

Adlar: `hook_small`, `hook_medium`, `hook_large`, `bobber_basic`, `bobber_sensitive`, `bobber_bright`.

**6. `gear_baits.png`: yemler**

Çocuklar da oynayacak: tatlı ve temiz görünsün.

```
a little tin of cute wriggly earthworms; a small pile of sweet corn kernels; a ball of white
bread dough; a small box of tiny pale grubs; a few round red-and-yellow boilie bait balls;
a few orange cooked shrimp
```

Adlar: `bait_worm`, `bait_corn`, `bait_dough`, `bait_maggot`, `bait_boilie`, `bait_shrimp`.

**7. `gear_extras.png`: ekstralar**

```
a landing net with a wooden handle; a rod stand with an electronic bite alarm with a small red
light; a small wooden rowing boat with two oars; a crayfish trap (a small cylinder net trap with
a float); an old brass lantern; a long mesh fish keepnet with a metal ring
```

Adlar: `net` (kepçe), `rod_stand` (sehpa ve zil), `boat` (sandal), `trap` (kerevit tuzağı), `lantern` (fener), `keepnet` (balık filesi, büyük kova).

---

## Parti 3 — Göl (bölgeler ve harita)

✅ Beş sayfa da geldi ve oyunda. Büyük gölde altı bölge var: İskele koyu, Sazlık, Nilüferli koy, Kayalık burun, Dere ağzı ve Derin orta. Harita gölün gerçek şeklinden kodla çizilir; bu sayfalar onu süsler.

**1. `zone_badges.png`: bölge rozetleri**

Haritada ve "yeni bölge açıldı" bildiriminde görünür.

```
Sheet of 6 round cozy mobile game badges in a 3x2 grid, exactly matching the attached style
reference: chunky shapes, soft gradients, thick dark outline, warm top-left light, flat front
view. Each badge is a round wooden medallion with a small scene inside, centered in its own cell
with generous empty space, all the same size. No text, no labels, no shadows.
Solid flat pure magenta background (#FF00FF) everywhere, no gradient, no checkerboard.
Badges, left to right, top row then bottom row: a small wooden fishing dock over teal water;
tall green reeds and cattails; a green lily pad with a pink lotus flower; mossy gray rocks with
a splash of water; a little stream flowing over stones between two grassy banks; a
red-and-white buoy floating on deep dark-blue water.
```

| Kesilen ad | Bölge |
|---|---|
| `zone_dock_cove` | İskele koyu |
| `zone_reeds` | Sazlık |
| `zone_lily_cove` | Nilüferli koy |
| `zone_rocky_point` | Kayalık burun |
| `zone_stream_mouth` | Dere ağzı |
| `zone_deep_water` | Derin orta |

**2. `map_paper.png`: harita kâğıdı**

Tek parça. Gölü oyun bunun üstüne çizer; ortası boş kalmalı.

```
A single blank old parchment map paper for a cozy mobile game, flat front view, exactly
matching the attached style reference: warm cream paper with soft darker edges, slightly curled
corners and a thin hand-drawn brown border line. The middle is plain, empty and evenly lit, with
nothing drawn on it, so the game can draw the lake on top. Wide landscape shape filling most of
the image. No text, no drawings, no shadows.
Solid flat pure magenta background (#FF00FF) everywhere around the paper.
```

Ortasına bir şey çizilmişse: "Keep the paper exactly the same but make the middle completely empty".

**3. `map_stickers.png`: harita çıkartmaları**

Haritada bölgelerin ve yerlerin üstüne konur (masa oyunu haritası gibi).

```
Sheet of 6 small cute map stickers for a cozy fishing game map in a 3x2 grid, exactly matching
the attached style reference: chunky shapes, soft gradients, thick dark outline, warm top-left
light, seen from above at a slight 3/4 angle like a board game map. Each sticker centered in its
own cell with generous empty space, all at a similar size. No text, no labels, no shadows,
no floor.
Solid flat pure magenta background (#FF00FF) everywhere, no gradient, no checkerboard.
Stickers, left to right, top row then bottom row: a cluster of three round green trees; a patch
of reeds and cattails; three lily pads with one pink flower; a pile of mossy gray rocks; a small
wooden fishing shop with a striped awning; a small wooden rowing boat.
```

Kesilen adlar: `map_trees`, `map_reeds`, `map_lilies`, `map_rocks`, `map_shop`, `map_boat`.

**4. `map_icons.png`: harita ikonları**

```
(ui_1 ile aynı stil cümleleri.) Icons, left to right, top row then bottom row: a round red map
pin with a white dot; a small golden padlock; a wooden compass rose; a red-and-white buoy with a
small flag; a dark iron anchor with a rope; a wooden signpost with an arrow.
```

| Kesilen ad | Nerede |
|---|---|
| `pin` | haritada "buradasın" |
| `lock` | kilitli bölge (dükkândaki rütbe kilidi de bunu kullanır) |
| `compass` | harita süsü (sol alt köşe) |
| `buoy` | haritada sandalla gidilen şamandıralar |
| `anchor` | sandaldayken "Kıyıya dön" düğmesi |
| `signpost` | haritada kilitli bölgenin çitindeki tabela |

**5. `ground_tiles.png`: zemin dokuları**

Bu sayfa ötekilerden farklı: nesne değil, **kare doku örnekleri** (2×2). Oyun her karenin içinden keser ve kenarlarını kendisi dikişsiz yapar.

```
Four square seamless tileable ground textures for a cozy stylized low-poly lakeside game, in a
2x2 grid, seen straight from above, matching the colors of the attached style reference: soft
painterly shapes, gentle color variation, no strong highlights or shadows, no objects, no
perspective. Each texture is a perfect square swatch filling most of its cell, with a gap of
solid flat pure magenta (#FF00FF) between the swatches and around them.
Textures, left to right, top row then bottom row: short soft green grass; light sand with a few
small pebbles; a brown dirt footpath of packed earth; mossy gray stone.
```

Kesilen adlar: `grass` (çimen), `sand` (kıyı kumu), `path` (kıyı yolu), `moss_stone` (kayalık burun).

- Dokular yakından değil uzaktan görünür: ayrıntı az, renk geçişi yumuşak olsun.
- Çok parlak ya da çok desenli çıkarsa: "Make it softer and less detailed, gentle color variation only".

---

## Parti 4 — Teknikler

✅ Dört sayfa da geldi ve oyunda (v0.4); çöp ve hikâye eşyaları (çizme, şişeler, anahtar) Dalga 4'te göl sevgisiyle bağlanır. Dalga 3'te dört yeni teknik geliyor: spin (yapay yemle), dip (sehpa ve zille), sinek (dere ağzında) ve kerevit tuzağı. Kamışların, sehpanın ve tuzağın resimleri Parti 2'den hazır; bu dört sayfa gerisini tamamlar.

**1. `gear_lures.png`: yapay yemler (spin)**

Parti 2'deki takım sayfalarıyla aynı stil cümleleri, yalnızca eşya listesi değişir. Yemler küçük ama hücreyi doldursun.

```
Sheet of 6 fishing gear icons for a cozy mobile game shop in a 3x2 grid, exactly matching the
attached style reference: chunky shapes, soft gradients, thick dark outline, warm top-left light,
3/4 view. Each item centered in its own cell with generous empty space, all at a similar size.
Long items such as rods are drawn diagonally from bottom-left to top-right. No text, no labels,
no shadows, no floor.
Solid flat pure magenta background (#FF00FF) everywhere, no gradient, no checkerboard.
Items, left to right, top row then bottom row: a simple silver spoon lure with a small hook;
a spinner lure with a shiny spinning blade and a red bead; a soft green rubber worm lure on a
round jig head; a small crankbait lure shaped like a little striped fish with a clear diving
lip; a yellow topwater popper lure with a cupped face and a feather tail; a premium golden
spoon lure with a small blue gem
```

| Kesilen ad | Yem |
|---|---|
| `lure_spoon` | kaşık |
| `lure_spinner` | döner kaşık |
| `lure_soft` | silikon yem |
| `lure_crank` | maket balık |
| `lure_popper` | su üstü yemi |
| `lure_gold` | altın kaşık (en üst kademe) |

**2. `gear_flies.png`: sinekler ve dip takımı**

```
(gear_lures ile aynı stil cümleleri.) Items, left to right, top row then bottom row: a small
brown dry fly with upright wings and a fluffy collar; a dark nymph fly with a shiny gold bead
head; a long white-and-olive streamer fly with flowing feathers; a teardrop-shaped lead fishing
sinker with a small swivel; a small wire cage feeder filled with brown groundbait; a small brass
fishing bell with a clip, the kind that rings on a rod tip
```

| Kesilen ad | Ne |
|---|---|
| `fly_dry` | kuru sinek |
| `fly_nymph` | nimf |
| `fly_streamer` | streamer (uzun tüylü sinek) |
| `sinker` | kurşun (dip) |
| `feeder` | yem sepeti (dip) |
| `bell` | dip zili (zil çalınca ipucu ve bildirim) |

**3. `technique_icons.png`: teknik ikonları**

Sol alttaki teknik düğmesinde ve takım çantasında görünür. Arayüz ikonu oldukları için `ui_1` ile aynı stil cümleleri.

```
(ui_1 ile aynı stil cümleleri.) Icons, left to right, top row then bottom row: a red-and-white
bobber floating on a small splash of teal water; a spinning reel with a silver spoon lure
hanging from its line; a fishing rod resting on a small rod stand with a little brass bell;
a feathered fly with a curly fly line looping around it; a small cylinder crayfish trap net
with a little orange float; a green canvas tackle bag with a fishing rod sticking out
```

| Kesilen ad | Nerede |
|---|---|
| `tech_float` | teknik düğmesi: şamandıra |
| `tech_spin` | teknik düğmesi: spin |
| `tech_bottom` | teknik düğmesi: dip |
| `tech_fly` | teknik düğmesi: sinek |
| `tech_trap` | teknik düğmesi: tuzak |
| `tackle_bag` | takım çantası (her tekniğin kuşanılmış takımı) |

**4. `catch_items.png`: kerevit ve çöp**

Tuzaktan ve dip avından çıkanlar. Çocuklar da oynayacak: çöpler de sevimli ve temiz görünsün.

```
Sheet of 6 cute cartoon items for a cozy fishing game in a 3x2 grid, exactly matching the
attached style reference: chunky shapes, soft gradients, thick dark outline, warm top-left
light, 3/4 view. Each item centered in its own cell with generous empty space, all at a similar
size. No text, no labels, no shadows, no floor.
Solid flat pure magenta background (#FF00FF) everywhere, no gradient, no checkerboard.
Items, left to right, top row then bottom row: a small cute red-brown crayfish with big claws;
an old green rubber boot with a few water drops; a dented rusty tin can; an empty plastic
bottle; a corked glass bottle with a rolled paper message inside; an old rusty iron key with an
ornate handle
```

| Kesilen ad | Ne |
|---|---|
| `crayfish` | kerevit (tuzak ve dip) |
| `boot` | eski çizme |
| `tin_can` | teneke |
| `plastic_bottle` | plastik şişe |
| `message_bottle` | mesajlı şişe (hikâye, Dalga 4) |
| `rusty_key` | paslı anahtar (hikâye, Dalga 4) |

Kerevit kırmızımsı: macentaya yakın görünüp soluyorsa bu sayfayı düz **yeşil (#00FF00)** arka planla iste.

---

## Parti 5a — Hikâye ve canlı dünya

Dalga 4'te göl yaşıyor:

- **Vakit ve hava:** sabah, öğle, akşam ve gece; açık, bulutlu, yağmurlu ve sisli günler. Hangi balığın geleceğini değiştirirler.
- **Göl sevgisi:** balığı göle bırakınca ve çöp toplayınca artar; göl güzelleşir.
- **Dede'nin istekleri:** her oyun günü küçük istekler.
- **Gölün Sırrı:** şişelerdeki mektuplar, dört harita parçası, altın hamur ve finalde Gölün Bekçisi.

Bu sayfalar onları süsler. Görseller gelene kadar oyun kodla çizilen yedekleri kullanır; iş beklemez. Önce 1 ve 2 (üstteki saat çipinde hemen görünürler), sonra sırayla.

**1. `time_icons.png`: vakit ikonları, çay ve göl sevgisi**

Üst ortadaki saat çipinde ve "Bugün" panelinde görünürler.

```
(ui_1 ile aynı stil cümleleri.) Icons, left to right, top row then bottom row: a sun rising over
a small calm lake with a soft pink-orange sky; a bright round midday sun in a small circle of
blue sky; a big orange sun setting behind green reeds with two tiny birds; a yellow crescent moon
with two small stars on a round patch of dark-blue night sky; a small tulip-shaped Turkish tea
glass with red tea on a little white saucer with a curl of steam; a teal heart made of water
with a small pink lotus flower on it.
```

| Kesilen ad | Nerede |
|---|---|
| `phase_morning` | sabah (saat çipi, "Bugün" paneli, "Sabah oldu" bildirimi) |
| `phase_noon` | öğle |
| `phase_evening` | akşam |
| `phase_night` | gece |
| `tea` | "Dede'yle çay" düğmesi (sonraki vakte geçer) |
| `love` | göl sevgisi (Kova paneli, defter, "Göl sevgisi arttı" bildirimi) |

**2. `weather_icons.png`: hava ikonları ve istekler**

```
(ui_1 ile aynı stil cümleleri.) Icons, left to right, top row then bottom row: a cheerful round
sun with tiny sparkles; a fluffy white cloud partly covering a small sun; a soft gray cloud with
blue rain drops; three soft wavy bands of white mist in front of a pale sun; a dark storm cloud
with a yellow lightning bolt and rain drops; a rolled paper note tied with a red ribbon and a
small fish stamp.
```

| Kesilen ad | Nerede |
|---|---|
| `weather_clear` | açık hava (bugünün ve yarının havası) |
| `weather_cloudy` | bulutlu |
| `weather_rain` | yağmur |
| `weather_fog` | sis |
| `weather_storm` | fırtına (yağmurlu gece) |
| `requests` | Dede'nin istekleri ("Bugün" paneli, saat çipinin rozeti) |

**3. `story_items.png`: hikâye eşyaları**

Parti 4'teki `catch_items` ile aynı stil cümleleri.

```
Sheet of 6 cute cartoon items for a cozy fishing game in a 3x2 grid, exactly matching the
attached style reference: chunky shapes, soft gradients, thick dark outline, warm top-left
light, 3/4 view. Each item centered in its own cell with generous empty space, all at a similar
size. No text, no labels, no shadows, no floor.
Solid flat pure magenta background (#FF00FF) everywhere, no gradient, no checkerboard.
Items, left to right, top row then bottom row: a round golden dough ball glowing softly with
small sparkles, on a little checkered cloth; a single torn piece of old parchment map with a
dotted line and half of a red X; a wooden fish measuring ruler with a small fish outline; an
open old letter on cream paper with a red wax seal; a brass lantern glowing with warm yellow
light; a big shiny turquoise fish scale with a soft glow.
```

| Kesilen ad | Nerede |
|---|---|
| `golden_dough` | altın hamur (göl sevgisi 6 olunca Nine verir; finalin yemi) |
| `map_piece` | harita parçası (Dede'nin altın istekleri) |
| `ruler` | boy isteği ("Kadife · 30 cm üstü") |
| `letter` | mektup (defterin Gölün Sırrı sekmesi, "Yeni mektup" bildirimi) |
| `lantern_lit` | yanan fener (ilk gece Nine'nin hediyesi) |
| `keeper_scale` | Bekçi'nin pulu (finalden sonra defterde) |

**4. `letter_paper.png`: mektup kâğıdı**

Tek parça. Mektubun yazısını oyun bunun üstüne yazar; ortası boş kalmalı. Kâğıt mektubun boyuna göre gerilir, bu yüzden süsler yalnızca kenarda ve köşelerde olsun.

```
A single old letter paper for a cozy mobile game, flat front view, exactly matching the attached
style reference: warm cream paper with slightly torn and curled edges, a faint brown water stain
in one corner, a thin hand-drawn brown border line and a tiny fish doodle in the bottom-right
corner. The middle is plain, empty and evenly lit, with nothing written or drawn on it, so the
game can write the letter on top. Wide landscape shape filling most of the image. No text, no
shadows.
Solid flat pure magenta background (#FF00FF) everywhere around the paper.
```

Ortasına bir şey yazılmışsa: "Keep the paper exactly the same but make the middle completely empty".

**5. `secret_map.png`: sırrın haritası**

Tek parça. Oyun bu haritayı kodla dörde yırtar: Dede'nin altın isteklerinden gelen her parça defterde yerine oturur. Tamamlanınca Bekçi'nin yeri belli olur.

```
An old hand-drawn treasure map of a small U-shaped lake for a cozy fishing game, flat front view,
exactly matching the attached style reference: brown ink and soft watercolor on warm parchment.
The lake outline with tiny reeds, lily pads, mossy rocks, a little stream flowing in, a small
wooden dock and a rowing boat; a dotted path from the dock across the water to a big red X in the
deep middle of the lake; next to the X a tiny drawing of a big friendly fish. Wide landscape
shape filling most of the image. No text, no letters, no numbers.
Solid flat pure magenta background (#FF00FF) everywhere around the map.
```

Haritada yazı çıkarsa: "Keep the map exactly the same but remove all text and letters".

**6. `keeper.png` (3×1): Gölün Bekçisi**

"Balık görseli istemiyoruz" kuralının tek istisnası: Bekçi bir hikâye yaratığı, kartı ve bitiş sahnesi özel olsun. Görsel yoksa oyun onu da kendi 3D modelinden çizer.

```
Sheet of 3 images of the same creature in a 3x1 grid, exactly matching the attached style
reference, stylized low-poly 3D look: the Lake Keeper, a huge ancient and gentle lake fish, a mix
of a sturgeon and a carp, long and powerful, turquoise-and-silver scales with soft glowing wave
patterns, long white whiskers, a kind wise eye, a few small water plants and a tiny pink lotus
flower growing on its back, a faint turquoise glow. Left to right: the whole fish from the side,
calm and friendly; the fish seen from straight above as a big glowing turquoise silhouette inside
a round patch of dark-blue water with soft ripples; the fish leaping out of misty night water
under a crescent moon with a turquoise splash, inside a round night scene. Same size and framing
in each cell.
Solid flat pure magenta background (#FF00FF). No text, no shadows.
```

| Kesilen ad | Nerede |
|---|---|
| `keeper` | Bekçi'nin kartı (Masalsı çerçeve) ve defterdeki resmi |
| `keeper_top` | haritadaki X'in yanında, tamamlanan harita |
| `keeper_leap` | bitiş sahnesi ve jenerik |

**7. İsteğe bağlı: `portraits_young.png` (3×1): genç Nine ve Dede**

Mektupları gençken yazdılar; imzanın yanında ve jenerikte görünürler. Parti 1'deki portrelerin stil cümleleri.

```
Sheet of 3 portrait busts in a 3x1 grid, exactly matching the attached style reference,
stylized low-poly 3D look, the same two characters as the attached grandparent portraits but as
teenagers, many years ago. Left to right: a cheerful teenage girl with two braids, rosy cheeks
and freckles, a white headscarf with small blue flowers pushed back on her hair, a mustard-yellow
knitted cardigan; a friendly teenage boy with a brown flat cap, short dark hair and freckles, a
brick-red chunky knitted sweater; the two of them together on a muddy lake shore, smiling, she
holds a bundle of green reeds and he holds a small sack of collected trash. Head and shoulders
in the first two cells, waist up in the third. Same size and framing in each cell.
Solid flat pure magenta background (#FF00FF). No text, no shadows.
```

Kesilen adlar: `young_nine`, `young_dede`, `young_both`.

**8. İsteğe bağlı: `ending.png`: bitiş resmi**

Tam resim, arka planı silinmez (uygulama ikonu gibi). Jeneriğin arkasında durur.

```
A wide landscape illustration for the ending of a cozy fishing game, exactly matching the
attached style reference, stylized low-poly 3D look: a small U-shaped lake at sunrise in full
bloom, pink and white lotus flowers and lily pads everywhere, butterflies and small birds,
crystal-clear teal water. A grandfather in a brown flat cap and a grandmother in a white
flowered headscarf wave happily from a small wooden dock. A young angler in a hat, seen from
behind, sits in a small rowing boat on the water and waves back. Under the water a faint
turquoise shimmer of a huge friendly fish. Warm golden morning light. No text.
```

---

## Teknik not (Claude için)

Görseller `assets/incoming/` altına gelince:

```bash
godot --headless --path . -s res://tools/process_images.gd
godot --headless --path . --import
```

Sayfa adları, kesim şekli (`fit`) ve kesilen adlar `data/art_sheets.json`'da. Oyuna bağlama:

Mor ve pembe nesneli sayfalarda (`rarity_frames`, `rarity_badges`, `zone_badges`, `map_stickers`, `time_icons`, `keeper`) `"despill": "edge"`: macenta temizliği yalnızca kenar bandında yapılır, Destansı moru ve nilüferin pembesi solmaz. Zemin dokuları `"fit": "tile"`: kare örneğin içinden kesilir ve dikişsiz yapılır (`ArtSheet.make_tile`). Harita ve mektup kâğıdı `"fit": "trim"`: saydam payı kırpılır, 9 dilimli çerçeve olarak `assets/ui/frames/`'e gider.

Oyuna bağlama (v0.4'teki durum):

| Görsel | Çıktı | Bağlantı |
|---|---|---|
| `ui_frames` | `assets/ui/frames/` (`fit: trim`, oran korunur) | `UiKit.framed` (9 dilim payları `FRAME_SLICES`, yazının süse binmemesi için içerik payları `FRAME_CONTENT`): panel (bütün paneller), kart (dükkân kartları, satış satırları, defter ayrıntısı, balık kartının içi), kemerli sekme (dükkân sekmeleri), kurdele (balık kartında adın arkası), hap (HUD hapları, ipucu çubuğu, karttaki Dede satırı), balon (köylülerin konuşma balonu). |
| `ui_buttons` | `assets/ui/frames/button_*` | `UiKit.BUTTON_ART`: yeşil, turuncu, mavi, gri, kırmızı; basılı hâl aynı resmin koyusu, pasif hâl gri; palet dışı renkler en yakın resme bağlı. Yuvarlak turuncu ileride. |
| `rarity_frames` | `assets/ui/frames/frame_<nadirlik>.png` | Balık kartında ve defter ayrıntısında balık resminin çerçevesi (≈1:1; süsler kenarların ortasında olduğu için 9 dilim değil). |
| `rarity_badges` | `assets/icons/ui/rarity_<nadirlik>.png` | `GameIcon.RARITY_ART`: rozetler, defter, yakalama etiketi, oranlar. |
| `ui_1`, `ui_2` | `assets/icons/ui/` | `GameIcon.ART_NAMES`: HUD (para, kova, rütbe), dükkân sekmeleri (kamış, makara, iğne), defter, dükkân; `sell` HEPSİNİ SAT düğmesinde, `release` "kova dolu, balık göle döndü" bildiriminde. `map` Dalga 2'de (harita), `aquarium` Dalga 5'te (yuva). |
| `portraits`, `portraits_nine` | `assets/ui/portraits/` | `Moods`: yüz sözün ifadesinden (smile, story, wow); ipucu çubuğu, karttaki Dede satırı, dükkânın başlığı. Portre yoksa 3D modelden çekilen yüz. |
| `gear_*` | `assets/icons/gear/<takım kimliği>.png` | `ItemArt.gear`: dükkân kartları; Misina, Yem ve Ekstra sekmelerinin ikonu `GameIcon.GEAR_ART`. Spin, dip ve sinek kamışları, sehpa, sandal, tuzak ve fener Dalga 2–4'te. |
| `app_icon` | `assets/ui/art/app_icon.png` | `project.godot` `config/icon`; iOS ikonları bundan üretilir (Godot 4.7: iOS ikon alanları boşsa proje ikonu). Saydamlık kanalsız kaydedilir (`"key": false`). |
| `logo` | `assets/ui/art/logo.png` | Açılış ekranı (`boot_splash/image`; iOS açılış ekranı da bundan) ve ayarlar panelinin başlığı. |
| `style_sheet`, `concept_screen` | `docs/img/` | Yalnızca referans. |
| `zone_badges` | `assets/icons/zones/zone_<bölge>.png` | ✅ `ItemArt.zone`: haritada bölgelerin rozeti, "yeni bölge açıldı" ve bölgeye girince adının bildirimi. Yoksa kodla çizilen rozet. |
| `map_paper` | `assets/ui/frames/map_paper.png` (`fit: trim`) | ✅ Harita panelinin çerçevesi (`UiKit.framed`, 9 dilim payları `FRAME_SLICES`); haritanın kenarı kâğıda karışır (`map.gdshader` `fade_m`). Yoksa kodla çizilen çerçeve. |
| `map_stickers` | `assets/ui/map/` | ✅ `MapView` çıkartmaları (`ItemArt.map_art`): sazlık, nilüfer ve kayalar kendi bölgesinin yanında, ağaç öbekleri ormanda, sandal iskelede (sandaldayken yok), dükkân Nine'nin yerinde; rozetlere, iğneye ve birbirine binmeyecek yere kayar, yer yoksa gizlenir. |
| `map_icons` | `assets/icons/ui/` | ✅ `GameIcon.ART_NAMES`: `pin` "Buradasın", `lock` kilitli bölge ve dükkânın rütbe kilidi, `compass` haritanın sol alt köşesi, `buoy` haritada derin ortanın şamandıraları, `anchor` "Kıyıya dön" düğmesi, `signpost` haritada kapalı çitin tabelası. |
| `ground_tiles` | `assets/textures/ground/` | ✅ Zemin shader'ı (çimen, kum, kıyı yolu, kayalık): dördü birden olunca zemin onlarla çizilir (`LakeScene.GROUND_TILES`, bir karo 3 m); yoksa kodla. |
| `gear_lures`, `gear_flies` | `assets/icons/gear/` | ✅ `ItemArt.gear`: dükkânın yapay yem, sinek ve kurşun kartları, yem sepeti, takım çantasının karoları; `bell` dipte koşuda sehpanın üstündeki 2B zil (`BellMark`). Yoksa kodla çizilen ikon. |
| `technique_icons` | `assets/icons/ui/` | ✅ `GameIcon.ART_NAMES` (`tech_float`, `tech_spin`, `tech_bottom`, `tech_fly`, `tech_trap`, `tackle_bag`): sol alttaki teknik düğmesi, Takım Çantası'nın başlığı ve karoları, dükkânın başlığındaki teknik düğmeleri, "Yeni teknik" ve tuzak bildirimleri. Yoksa kodla çizilen ikon. |
| `catch_items` | `assets/icons/items/` | ✅ `ItemArt.item`: kerevit (defter, kart, tuzak rozeti). Çöp (çizme, şişe) ve hikâye eşyaları (mesajlı şişe, anahtar) Dalga 4'te. |
| `time_icons` | `assets/icons/ui/` (`despill: edge`: pembe gök ve nilüfer solmasın) | 🔜 `GameIcon.ART_NAMES`: saat çipi ve "Bugün" paneli (vakitler), çay düğmesi, göl sevgisi. Yoksa kodla çizilen ikon. |
| `weather_icons` | `assets/icons/ui/` | 🔜 `GameIcon.ART_NAMES`: saat çipinin hava ikonu, bugünün ve yarının havası, isteklerin ikonu ve çipin rozeti. |
| `story_items` | `assets/icons/items/` | 🔜 `ItemArt.item`: altın hamur, harita parçası, boy isteğinin cetveli, mektup, yanan fener, Bekçi'nin pulu. |
| `letter_paper` | `assets/ui/frames/letter_paper.png` (`fit: trim`) | 🔜 Mektup panelinin çerçevesi (`UiKit.framed`, 9 dilim payları `FRAME_SLICES`). Yoksa kodla çizilen kâğıt. |
| `secret_map` | `assets/ui/art/secret_map.png` (`fit: box`) | 🔜 Defterin Gölün Sırrı sekmesindeki harita yapbozu: kodla dörde yırtılır, gelen parça yerine oturur. Yoksa kodla çizilen parşömen. |
| `keeper` | `assets/icons/items/` (`despill: edge`) | 🔜 `ItemArt.item` (`ItemArt.fish` önce ona bakar): Bekçi'nin kartı ve defteri, haritada X'in yanı, bitiş ve jenerik. |
| `portraits_young` | `assets/ui/portraits/` | 🔜 İsteğe bağlı: mektupların imzası, jenerik. |
| `ending` | `assets/ui/art/ending.png` (`fit: box`, `key: false`) | 🔜 İsteğe bağlı: jeneriğin arka planı. |
