# Kaynaklar ve lisanslar

Oyundaki hazır içerik ve lisansları. Hepsi ticari kullanıma açıktır.

## 3D modeller: KayKit (Kay Lousberg) — CC0 1.0

Lisans: Creative Commons Zero (kamu malı). Atıf zorunlu değil; teşekkür olarak burada anıyoruz.
Kaynak: https://kaylousberg.com · https://github.com/KayKit-Game-Assets

| Klasör | Paket | Kullanılanlar |
|---|---|---|
| `assets/models/kaykit_forest/` | KayKit Forest Nature Pack 1.0 | yuvarlak ağaçlar ve çamlar (Tree_1, Tree_3, Tree_4), çalılar, çimen öbekleri, yuvarlak kayalar (Rock_3) |
| `assets/models/medieval/` | KayKit Medieval Hexagon Pack 1.0 | uzaktaki dağlar ve tepeler, fıçı, kasa, çuval, kova |
| `assets/models/halloween/` | KayKit Halloween Bits 1.0 | fenerli direk |
| `assets/models/characters/` | KayKit Character Pack: Adventures 1.0 | Rogue (balıkçı kız), Knight (balıkçı oğlan), Barbarian (Dede) ve Mage (Nine); iskeletleri ve animasyonlarıyla |

Orman paketi Ersin'in Mac'inde indirildi (lisansı `assets/models/kaykit_forest/License.txt`); kullanılmayan
modelleri `assets/incoming/models/` altında sonraki dalgaları bekler. Ortaçağ ve cadılar bayramı modelleri
ile Barbarian Kazı projesinden değiştirilmeden kopyalandı. Rogue, Knight ve Mage,
https://github.com/KayKit-Game-Assets/KayKit-Character-Pack-Adventures-1.0 deposundan alındı.
Dokular `tools/recolor_texture.gd` ile yeniden boyandı (orman: daha koyu yaprak, kahverengi kabuk, sıcak
gri kaya; ortaçağ: ahşap ve ağaç yeşili; Rogue: balıkçı renkleri; Knight: sarı yağmurluk, turkuaz yaka, kahverengi saç; Barbarian: Dede'nin beyaz sakalı ve
kazağı; Mage: Nine'nin gümüş saçı ve hardal hırkası); orijinaller `assets/models/kaykit_forest/source/`,
`assets/models/medieval/source/` ve `assets/models/characters/source/` altında. Kayaların yosunu
`scenes/world/moss.gdshader` ile çizilir.
Karakterlerin pelerinleri, silahları ve kalkanları, Knight'ın ve Barbarian'ın miğferi, Barbarian'ın kupası ve Mage'in şapkası oyunda gizlenir;
balıkçı şapkası, Dede'nin kasketi ve çay bardağı, Nine'nin yazması, önlüğü ve gözlüğü, olta ve Nine'nin
dükkânı kodla kurulur.
Hangi modelin oyunda hangi ölçekle kullanıldığı `scenes/world/model_library.gd` içinde.

## 3D model: Quaternius — CC0 1.0

Lisans: Creative Commons Zero (kamu malı). Atıf zorunlu değil; teşekkür olarak burada anıyoruz.
Kaynak: https://opengameart.org/content/animated-animales-low-poly (Animated Animales Low Poly, Animal Pack Vol. 2;
paket Ersin'in Mac'inde indirildi, lisansı `assets/models/cat/License.txt`).

| Klasör | Paket | Kullanılanlar |
|---|---|---|
| `assets/models/cat/` | Animated Animales Low Poly | kedi (Cat.fbx: iskeleti, Idle ve Walking animasyonlarıyla): Tekir |

Modelin dokusu yok: üç yüzeyi oyunda tek yüzeyde birleştirilir, gri tekir deseni (çizgiler, beyaz patiler, pembe
kulak içi) `scenes/player/cat.gdshader` ile kodla çizilir (`scenes/player/cat_body.gd`).

## 3D modeller: Kenney — CC0 1.0

Lisans: Creative Commons Zero (kamu malı). Atıf zorunlu değil; teşekkür olarak burada anıyoruz.
Kaynak: https://kenney.nl (paketler Ersin'in Mac'inde indirildi; lisansları klasörlerdeki `License.txt`).

| Klasör | Paket | Kullanılanlar |
|---|---|---|
| `assets/models/kenney_survival/` | Kenney Survival Kit 2.0 | kamp ateşi ocağı, kütük oturak, tabela, kilitli bölgelerin çiti ve küçük tabelası |
| `assets/models/kenney_watercraft/` | Kenney Watercraft Kit 2.1 | kürekli sandal (iskeleye bağlı), derin ortanın bayraklı şamandıraları |

Renk paletleri (`Textures/colormap.png`) `tools/recolor_texture.gd` ile iskelenin ahşap tonuna boyandı
(şamandıra kırmızı-beyaz); orijinaller `Textures/source/` altında. Kullanılmayan modeller `assets/incoming/models/` altında bekler.

## Yazı tipleri — SIL Open Font License 1.1 / Apache 2.0

| Dosya | Yazı tipi | Lisans |
|---|---|---|
| `assets/fonts/LuckiestGuy-Regular.ttf` | Luckiest Guy (Astigmatic) | Apache 2.0 (`luckiestguy_LICENSE.txt`) |
| `assets/fonts/Baloo2-Variable.ttf` | Baloo 2 (Ek Type) | SIL OFL 1.1 (`baloo2_OFL.txt`) |

## Görseller

Arayüz görselleri (`assets/ui/frames/`, `assets/ui/portraits/`, `assets/ui/art/`, `assets/icons/ui/`,
`assets/icons/gear/`): proje sahibi Ersin yapay zekâ araçlarıyla üretti (`docs/gorsel-istekleri.md`;
genel ikonların bir kısmı Kazı projesinden),
`tools/process_images.gd` ile kesildi. Su, gölge, misina, balıklar, nilüferler, çiçekler ve efektler kodla
çizilir (`scenes/world/`, `scenes/fx/`); kartlardaki balık resimleri açılışta balık modellerinden çekilir.

## Sesler

`assets/audio/`: bütün efektler ve ortam sesi bu proje için kodla sentezlendi
(`tools/make_sounds.py`, numpy); dışarıdan alınmış ses yok.

## Yazılım: motor ve reklam eklentisi

| Klasör | Yazılım | Lisans |
|---|---|---|
| (oyunun kendisi) | Godot Engine 4.7.2 (godotengine.org) ve içindeki bileşenler | MIT; oyunda Ayarlar → Lisanslar |
| `addons/admob/` | Poing Studios AdMob Plugin v5.1.0 (Godot'nun AdMob eklentisi; Kazı'dakiyle aynı: yalnızca reklam çekirdeği `android/bin/ads`, `ios/bin/ads`) | MIT (`addons/admob/LICENSE`); oyunda Ayarlar → Lisanslar |
| (paket derlenirken) | Google Mobile Ads SDK, Google User Messaging Platform SDK (Android'de Gradle, iOS'ta Swift Package Manager indirir) | Google'ın şartları (AdMob) |
