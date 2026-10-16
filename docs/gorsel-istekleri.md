# Görsel İstekleri (ChatGPT için prompt paketi)

Bu sayfadaki görselleri ChatGPT ile üretip game1'e yüklersen gerisini ben hallederim:

- arka planı silerim;
- sayfaları ikonlara keserim;
- adlandırıp oyuna bağlarım.

Görsel gelene kadar oyun kodla çizilen yer tutucuları kullanır, yani oyun görselsiz de çalışıyor. Senin görsellerin onu bitmiş bir oyun gibi gösterecek.

**Balık görseli istemiyoruz:** balıkların resimleri oyunun kendi 3D modelinden çekiliyor. Böylece senin işin Kazı'dakinden çok daha az.

## Kısaca

| Görsel | Oyunda nerede görünecek? | Şu an yerinde ne var? |
|---|---|---|
| 1. `style_sheet.png` | Oyunda görünmez; ötekilerin stil referansı | — |
| 2. `app_icon.png` | Telefonun ana ekranı | Kodla çizdiğim basit bir balık |
| 3. `portraits.png` | İpucu çubuğu: Dede konuşurken yüzü | 3D Dede'den çekilen küçük yüz |
| 4. `ui_1.png` | Büyük eylem düğmesi (AT, SAR, VUR, BEKLE); sonra kova ve akvaryum | Kodla çizilen ikonlar ve Kazı'nın eli |
| 5. `logo.png` | Açılış ekranı (H2'de gelecek) | Yok |
| 6. `key_art.png` | Tanıtım görseli | Sonra istenecek |

Sıra, önem sırası:

1. **Stil sayfası:** ötekilerin hepsine referans olur, o yüzden önce bu.
2. **Uygulama ikonu:** oyunu açmadan önce ilk gördüğün şey.
3. **Dede portreleri:** Dede oyun boyunca konuşuyor. Çizilmiş bir yüz, 3D'den çekilen küçük yüzden çok daha canlı durur.
4. **Arayüz ikonları:** eylem düğmesi ekranda hep duruyor.
5. **Logo:** açılış ekranı gelince lazım olacak.

Hepsini birden beklemene gerek yok: hazır olanı yükle, ben bağlayayım.

## Nasıl teslim edersin?

1. GitHub'da repoyu aç: **ErsinAydogmuss/game1**.
2. Sol üstteki dal (branch) menüsünden **`claude/festive-shannon-yycmwu`** dalını seç.
3. **Add file → Upload files** ekranında dosya adının başına `assets/incoming/` yaz. Klasör yoksa böyle oluşur.
4. Görselleri sürükle → **Commit changes**.
5. Bana "görselleri yükledim" yaz. Kesip oyuna bağlarım ve sana ekran görüntüsü gönderirim.

**Dosya adları önemli:** Her görseli aşağıdaki adla kaydet (ör. `ui_1.png`). PNG, JPG ya da WEBP olabilir.

## Genel kurallar (Kazı'dakiyle aynı)

- **Boyut:** yatay **1536×1024** (logo ve uygulama ikonu 1024×1024).
- **Arka plan:** düz, saf **macenta (#FF00FF)**.
  - "Şeffaf arka plan" isteme; ChatGPT sahte dama deseni çiziyor.
  - Pembe ya da mor bir nesne varsa o sayfada düz **yeşil (#00FF00)** iste.
- **6'lı sayfa (3×2 ızgara):** nesneler birbirine değmesin, aralarında boşluk olsun.
- **Yazı yok:** yazı, logo, gölge ve zemin olmasın (logo görseli hariç).
- **Stil sabit kalsın:** ilk ürettiğin **stil sayfasını** sonraki her isteğe referans görsel olarak ekle. Prompttaki stil cümlelerini değiştirme, yalnızca nesne listesini değiştir.
- **Beğenmezsen:** aynı promptla yeniden üret ya da tek nesneyi düzelt: "Keep everything the same, only redraw the bucket".

## 1. Stil sayfası: `style_sheet.png`

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

## 2. Uygulama ikonu: `app_icon.png` (1024×1024)

```
Mobile app icon, square, stylized low-poly 3D: a cute plump fish jumping out of teal water
toward a red-and-white bobber, wooden dock edge at the bottom, soft warm light, bold simple
shapes readable at small size, matching the attached style reference. No text.
Fill the whole square edge to edge with the scene: no magenta background, no border,
no transparency, sharp square corners (the phone rounds the corners itself).
```

- Köşeleri yuvarlatma; iPhone kendisi yuvarlar.
- İkon telefonda küçük görünecek: görsele uzaktan bir bak, balık ve şamandıra seçiliyor mu?

## 3. Dede portreleri: `portraits.png` (3×1)

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

## 4. Arayüz ikonları: `ui_1.png`

İlk dördü büyük eylem düğmesinde görünür; son ikisi sonraki hafta (H2) gelecek kova ve akvaryum için.

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
| `bucket` | kova (H2) |
| `aquarium` | akvaryum (H2) |

## 5. Logo: `logo.png` (1024×1024)

```
Game logo for a cozy fishing game titled "OLTA" with a small subtitle "Gölün Sırrı",
chunky rounded 3D letters in warm wood and teal colors, a fishing line with a red-and-white
bobber hooking the letter O, a few water droplets, stylized low-poly game art matching the
attached style reference. Turkish characters must be correct: Ö, ü, ı (dotless i).
Solid flat pure magenta background (#FF00FF).
```

Türkçe harfleri kontrol et: "Gölün Sırrı"daki **ö, ü ve ı** doğru çizilmiş olmalı. Yanlışsa "Fix the Turkish letters: Ö, ü and dotless ı" diye düzelttir.

## 6. (Sonra) Tanıtım görseli: `key_art.png`

H2'de istenecek.

## Teknik not (Claude için)

Görseller `assets/incoming/` altına gelince:

```bash
godot --headless --path . -s res://tools/process_images.gd
godot --headless --path . --import
```

Sayfa adları ve kesilen adlar `data/art_sheets.json`'da. Oyuna bağlama:

| Görsel | Çıktı | Bağlantı |
|---|---|---|
| `ui_1` | `assets/icons/ui/<ad>.png` | `GameIcon.ART_NAMES` ile kendiliğinden; eylem düğmesi (`Hud.ACTIONS`) bunları kullanır. `hand`, Kazı'nın elinin yerini alır. |
| `portraits` | `assets/ui/portraits/` | `dede_smile` ipucu çubuğunda hemen görünür (`Hud.set_portrait`); varsa 3B yüz çekilmez (`main._load_dede_face`). `dede_wow` (nadir ve üstü balık) ve `dede_story` (Dede'ye dokununca öğüt) gelince `main.gd`'de bağlanır. |
| `app_icon` | `assets/ui/art/app_icon.png` | `project.godot`'ta `config/icon="res://assets/ui/art/app_icon.png"` (Kazı'daki gibi). iOS ikonları bundan üretilir; opak ve 1024×1024 olmalı. |
| `logo` | `assets/ui/art/logo.png` | H2'deki açılış ekranı (Kazı'da `boot_splash/image`). |
| `style_sheet` | `docs/img/stil_sayfasi.jpg` | Yalnızca referans. |
