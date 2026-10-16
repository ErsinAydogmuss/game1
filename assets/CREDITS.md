# Kaynaklar ve lisanslar

Oyundaki hazır içerik ve lisansları. Hepsi ticari kullanıma açıktır.

## 3D modeller: KayKit (Kay Lousberg) — CC0 1.0

Lisans: Creative Commons Zero (kamu malı). Atıf zorunlu değil; teşekkür olarak burada anıyoruz.
Kaynak: https://kaylousberg.com · https://github.com/KayKit-Game-Assets

| Klasör | Paket | Kullanılanlar |
|---|---|---|
| `assets/models/medieval/` | KayKit Medieval Hexagon Pack 1.0 | ağaç kümeleri, tek ağaçlar, kayalar, dağlar ve tepeler, çadır, fıçı, kasa, çuval, kova, kereste, bayrak |
| `assets/models/halloween/` | KayKit Halloween Bits 1.0 | ahşap bank, fenerli direk, ayaklı fener |

Modeller Kazı projesinden değiştirilmeden kopyalandı. Ortaçağ paketinin dokusu `tools/recolor_texture.gd`
ile yeniden boyandı (ahşap ve ağaç yeşili); orijinali `assets/models/medieval/source/` altında.
Hangi modelin oyunda hangi ölçekle kullanıldığı `scenes/world/model_library.gd` içinde.

## Yazı tipleri — SIL Open Font License 1.1 / Apache 2.0

| Dosya | Yazı tipi | Lisans |
|---|---|---|
| `assets/fonts/LuckiestGuy-Regular.ttf` | Luckiest Guy (Astigmatic) | Apache 2.0 (`luckiestguy_LICENSE.txt`) |
| `assets/fonts/Baloo2-Variable.ttf` | Baloo 2 (Ek Type) | SIL OFL 1.1 (`baloo2_OFL.txt`) |

## Görseller

`assets/icons/ui/`: Kazı projesinin genel arayüz ikonları (proje sahibi yapay zekâ araçlarıyla
üretti, `tools/process_images.gd` ile kesildi). Olta'nın kendi görselleri `docs/gorsel-istekleri.md`'ye
göre gelecek. Su, gölge, misina ve efektler kodla çizilir (`scenes/world/`, `scenes/fx/`).

## Sesler

`assets/audio/`: bütün efektler ve ortam sesi bu proje için kodla sentezlendi
(`tools/make_sounds.py`, numpy); dışarıdan alınmış ses yok.
