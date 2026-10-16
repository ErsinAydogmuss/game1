# Görsel İstekleri (ChatGPT için prompt paketi)

Bu sayfadaki görselleri ChatGPT ile üretip game1'e yüklersen gerisini ben hallederim:

- arka planı silerim;
- sayfaları ikonlara keserim;
- adlandırıp oyuna bağlarım.

Görsel gelene kadar oyun kodla çizilen yer tutucuları kullanır.

**Balık görseli istemiyoruz:** balıkların ikonları oyunun kendi 3D modelinden çekiliyor. Böylece senin işin Kazı'dakinden çok daha az.

Toplam **6 görsel** var. En önemlisi ilk ikisi (stil sayfası + arayüz ikonları).

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

## 2. Arayüz ikonları: `ui_1.png`

```
Sheet of 6 glossy cartoon mobile game UI icons in a 3x2 grid, exactly matching the attached
style reference: chunky shapes, soft gradients, thick dark outline, warm top-left light,
3/4 view. Each icon centered in its own cell with generous empty space around it, all at a
similar size. No text, no labels, no shadows, no floor.
Solid flat pure magenta background (#FF00FF) everywhere, no gradient, no checkerboard.
Icons, left to right, top row then bottom row: a fishing rod with a reel, a fishing reel
close-up, a glass jar of worms (bait), a wooden bucket with a fish tail sticking out,
a round fish tank aquarium with a small fish, an open book with a fish drawing.
```

Kesilen adlar sırasıyla: `rod`, `reel`, `bait`, `bucket`, `aquarium`, `book`.

## 3. Dede portreleri: `portraits.png` (3×1)

Dede, 1. haftada ipucu çubuğunda konuşuyor; portresi orada görünecek.

```
Sheet of 3 portrait busts of the same character in a 3x1 grid, exactly matching the attached
style reference, stylized low-poly 3D look: a kind Turkish grandfather fisherman, round friendly
face, short white beard and mustache, bushy white eyebrows, sun-tanned skin, a faded green
bucket hat with a small fishing fly pinned on it, a beige fishing vest over a checkered shirt.
Head and shoulders, facing slightly toward the viewer. Moods, left to right: warm smile;
surprised and excited (eyebrows up, mouth open); telling a mysterious story (one finger raised,
eyes narrowed playfully). Same size and framing in each cell.
Solid flat pure magenta background (#FF00FF). No text, no shadows.
```

Kesilen adlar: `dede_smile`, `dede_wow`, `dede_story`.

## 4. Logo: `logo.png` (1024×1024)

```
Game logo for a cozy fishing game titled "OLTA" with a small subtitle "Gölün Sırrı",
chunky rounded 3D letters in warm wood and teal colors, a fishing line with a red-and-white
bobber hooking the letter O, a few water droplets, stylized low-poly game art matching the
attached style reference. Turkish characters must be correct: Ö, ü, ı (dotless i).
Solid flat pure magenta background (#FF00FF).
```

Türkçe harfleri kontrol et: "Gölün Sırrı"daki **ö, ü ve ı** doğru çizilmiş olmalı. Yanlışsa "Fix the Turkish letters: Ö, ü and dotless ı" diye düzelttir.

## 5. Uygulama ikonu: `app_icon.png` (1024×1024)

```
Mobile app icon, square, stylized low-poly 3D: a cute plump fish jumping out of teal water
toward a red-and-white bobber, wooden dock edge at the bottom, soft warm light, bold simple
shapes readable at small size, matching the attached style reference. No text.
Fill the whole square (no magenta background for this one).
```

## 6. (Sonra) Tanıtım görseli: `key_art.png`

H2'de istenecek.

## Öncelik

1. `style_sheet.png`
2. `ui_1.png`
3. `portraits.png`
4. `logo.png`, `app_icon.png`

## Teknik not (Claude için)

Görseller `assets/incoming/` altına gelince:

```bash
godot --headless --path . -s res://tools/process_images.gd
godot --headless --path . --import
```

Sayfa adları ve kesilen adlar `data/art_sheets.json`'da.
