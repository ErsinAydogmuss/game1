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
| 1. Arayüz | şimdi | 12 | paneller, düğmeler, nadirlik kartları, ikonlar, Dede ve Nine'nin yüzü, uygulama ikonu |
| 2. Ekipman | Dalga 1 ortasına kadar | 7 | Nine'nin dükkânındaki 42 eşya |
| 3. Göl | Dalga 2'den önce | ~5 | bölge rozetleri, zemin dokuları, nilüfer ve çiçekler |
| 4. Teknikler | Dalga 3'ten önce | ~5 | yapay yemler, sinekler, sehpa ve zil, çöp ve kerevit |
| 5. Hikâye ve yuva | Dalga 4'ten önce | ~8 | mektuplar, Gölün Bekçisi, hava ikonları, kedi, kıyafetler, tanıtım görseli |

3, 4 ve 5. partilerin promptlarını o dalgadan önce bu sayfaya eklerim.

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
  - Pembe ya da mor bir nesne varsa o sayfada düz **yeşil (#00FF00)** iste.
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

## Teknik not (Claude için)

Görseller `assets/incoming/` altına gelince:

```bash
godot --headless --path . -s res://tools/process_images.gd
godot --headless --path . --import
```

Sayfa adları, kesim şekli (`fit`) ve kesilen adlar `data/art_sheets.json`'da. Oyuna bağlama:

| Görsel | Çıktı | Bağlantı |
|---|---|---|
| `ui_frames`, `ui_buttons`, `rarity_frames` | `assets/ui/frames/` (`fit: trim`, oran korunur) | `UiKit.framed` (kenar payları `UiKit.FRAME_SLICES`). Şu an bağlı olanlar: diyalog paneli, ipucu hapı, balık kartı (`frame_<nadirlik>`), paletin düğme renkleri (`UiKit.BUTTON_ART`). Görsel gelince paylar ekran görüntüsüne bakılarak ayarlanır. |
| `rarity_badges` | `assets/icons/ui/rarity_<id>.png` | Dalga 1'de `UiKit.rarity_badge`. |
| `ui_1`, `ui_2` | `assets/icons/ui/` | `GameIcon.ART_NAMES`; `hand` ve `coin`, `book` Kazı'nınkilerin yerini alır. |
| `portraits`, `portraits_nine` | `assets/ui/portraits/` | `dede_smile` ipucu çubuğunda hemen görünür (`Hud.set_portrait`); varsa 3D yüz çekilmez. Öteki duygular ve Nine Dalga 1'de bağlanır. |
| `gear_*` | `assets/icons/gear/<takım kimliği>.png` | Dalga 1'de `ItemArt.gear`; kimlikler `data/gear.json` ile aynı. |
| `app_icon` | `assets/ui/art/app_icon.png` | `project.godot`'ta `config/icon="res://assets/ui/art/app_icon.png"` (Kazı'daki gibi). iOS ikonları bundan üretilir; opak ve 1024×1024 olmalı. |
| `logo` | `assets/ui/art/logo.png` | açılış ekranı (Kazı'da `boot_splash/image`). |
| `style_sheet`, `concept_screen` | `docs/img/` | Yalnızca referans. |
