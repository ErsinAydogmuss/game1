# Kaynaklar ve lisanslar

Oyundaki hazır içerik ve lisansları. Hepsi ticari kullanıma açıktır.

## 3D modeller: KayKit (Kay Lousberg) — CC0 1.0

Lisans: Creative Commons Zero (kamu malı). Atıf zorunlu değil; teşekkür olarak burada anıyoruz.
Kaynak: https://kaylousberg.com · https://github.com/KayKit-Game-Assets

| Klasör | Paket | Kullanılanlar |
|---|---|---|
| `assets/models/medieval/` | KayKit Medieval Hexagon Pack 1.0 | ağaç kümeleri, tek ağaçlar, kayalar, dağlar ve tepeler, çadır, fıçı, kasa, çuval, kova, kereste, bayrak |
| `assets/models/halloween/` | KayKit Halloween Bits 1.0 | ahşap bank, fenerli direk, ayaklı fener |
| `assets/models/characters/` | KayKit Character Pack: Adventures 1.0 | Rogue (balıkçı kız), Barbarian (Dede) ve Mage (Nine); iskeletleri ve animasyonlarıyla |

Ortaçağ ve cadılar bayramı modelleri ile Barbarian Kazı projesinden değiştirilmeden kopyalandı. Rogue ve
Mage, https://github.com/KayKit-Game-Assets/KayKit-Character-Pack-Adventures-1.0 deposundan alındı.
Dokular `tools/recolor_texture.gd` ile yeniden boyandı (ortaçağ: ahşap ve ağaç yeşili; Rogue: balıkçı
renkleri; Barbarian: Dede'nin beyaz sakalı ve kazağı; Mage: Nine'nin gümüş saçı ve hardal hırkası);
orijinaller `assets/models/medieval/source/` ve `assets/models/characters/source/` altında.
Karakterlerin pelerinleri, silahları, Barbarian'ın miğferi ile kupası ve Mage'in şapkası oyunda gizlenir;
balıkçı şapkası, Dede'nin kasketi ve çay bardağı, Nine'nin yazması, önlüğü ve gözlüğü, olta ve Nine'nin
dükkânı kodla kurulur.
Hangi modelin oyunda hangi ölçekle kullanıldığı `scenes/world/model_library.gd` içinde.

## Yazı tipleri — SIL Open Font License 1.1 / Apache 2.0

| Dosya | Yazı tipi | Lisans |
|---|---|---|
| `assets/fonts/LuckiestGuy-Regular.ttf` | Luckiest Guy (Astigmatic) | Apache 2.0 (`luckiestguy_LICENSE.txt`) |
| `assets/fonts/Baloo2-Variable.ttf` | Baloo 2 (Ek Type) | SIL OFL 1.1 (`baloo2_OFL.txt`) |

## Görseller

`assets/icons/ui/`: Kazı projesinin genel arayüz ikonları (proje sahibi yapay zekâ araçlarıyla
üretti, `tools/process_images.gd` ile kesildi). Olta'nın kendi görselleri `docs/gorsel-istekleri.md`'ye
göre gelecek. Su, gölge, misina, balıklar ve efektler kodla çizilir (`scenes/world/`, `scenes/fx/`);
kartlardaki balık resimleri açılışta balık modellerinden çekilir.

## Sesler

`assets/audio/`: bütün efektler ve ortam sesi bu proje için kodla sentezlendi
(`tools/make_sounds.py`, numpy); dışarıdan alınmış ses yok.
