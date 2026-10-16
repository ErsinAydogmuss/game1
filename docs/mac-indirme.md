# Ücretsiz 3D paketleri indirme: Mac'teki Claude Code için görev

> **Ersin için:** Mac'te Terminal'i aç, `claude` yaz, sonra şunu söyle:
> "github.com/ErsinAydogmuss/game1 reposunun `claude/festive-shannon-yycmwu` dalındaki `docs/mac-indirme.md` dosyasını oku ve uygula."
> Dosyayı indirdiysen: "İndirilenler klasöründeki `mac-indirme.md` dosyasını oku ve uygula."
>
> Senin işin yalnızca tarayıcıda açılan sayfalarda **indirme düğmelerine basmak**. Gerisini Claude yapar. Yaklaşık 15–20 dakika sürer.

---

## Bağlam

- **Proje:** Olta: Gölün Sırrı, Godot 4.7 ile yapılan, rahat bir 3D mobil balıkçılık oyunu.
  - Repo: `https://github.com/ErsinAydogmuss/game1`, dal: `claude/festive-shannon-yycmwu`.
  - Kodu bulut oturumundaki Claude yazıyor.
- **Neden Mac:** bulut oturumu `kenney.nl`, `quaternius.com` ve itch.io indirmelerine erişemiyor. Bu yüzden paketleri Mac indirir, repoya koyar; bulut oturumu da modelleri seçip boyar ve oyuna bağlar.
- **Lisans:** paketlerin hepsi ücretsiz ve **CC0** (kamu malı): ad anmak gerekmiyor, ticari oyunda kullanılabilir. Yine de her paketin lisans dosyası da kopyalanır.
- **Kullanıcı:** Ersin. Kod bilmiyor. Türkçe ve sade konuş; teknik terimleri ilk geçtiğinde kısaca açıkla.

## Kurallar

- **Yalnızca `assets/incoming/models/` klasörüne yaz.** Başka hiçbir dosyayı değiştirme, commit etme.
  - `export_presets.cfg`'de iPhone kurulumundan kalan yerel bir Team ID değişikliği olabilir; ona dokunma, commit'e de katma.
- `assets/incoming/` klasöründe `.gdignore` var: Godot oradaki dosyaları içe aktarmaz. Böylece paketler oyunu bozmaz; bulut oturumu gerekenleri sonra `assets/models/` altına taşır.
- Büyük dosya koyma:
  - Her paketten yalnızca **glTF/GLB biçimini** ve dokularını kopyala. FBX, OBJ, Blend ve önizleme kopyalarını kopyalama.
  - Bir paketin kopyalanacak kısmı 40 MB'ı geçerse yalnızca listedeki türleri kopyala.
- Bir paket indirilemezse ya da sayfa değişmişse o paketi atla, raporda yaz. Oyunda her şeyin kodla yapılmış bir yedeği var.

## Adımlar

### 1. Repo

```bash
# Repo yoksa:
git clone https://github.com/ErsinAydogmuss/game1.git ~/game1 && cd ~/game1
# Varsa repo klasöründe:
git fetch origin && git checkout claude/festive-shannon-yycmwu && git pull --autostash
mkdir -p assets/incoming/models
```

Klasörü `mdfind -name project.godot` ile bulabilirsin; Kazı'nın klasörü (`~/game`) değil, Olta'nınki (`~/game1`).

### 2. Paketleri indir

Her paket için:

1. Sayfayı `open "<adres>"` ile aç.
2. Ersin'e hangi düğmeye basacağını söyle:
   - itch.io'da: **Download Now** → **No thanks, just take me to the downloads** → dosyanın yanındaki **Download**;
   - kenney.nl'de: **Download** (bağış istemeye gerek yok, "Continue without donating" gibi bir seçenek çıkabilir).
3. Zip `~/Downloads`'a inince geçici bir klasöre aç, içindekilere bak (`find <klasör> -maxdepth 3`).
4. Lisans dosyasını (`License.txt` ya da benzeri) ve aşağıda istenen modelleri `assets/incoming/models/<klasör adı>/` altına kopyala.

| Paket | Adres | Klasör adı | Ne kopyalanır |
|---|---|---|---|
| Kenney **Watercraft Kit** | https://kenney.nl/assets/watercraft-kit | `kenney_watercraft` | GLB klasörünün tamamı (sandal, kayık, kürek, iskele parçaları) |
| KayKit **Forest Nature Pack** | https://kaylousberg.itch.io/kaykit-forest | `kaykit_forest` | glTF klasörü (`.gltf`, `.bin` ve doku `.png`): ağaç, çalı, çiçek, mantar, kaya, çimen. Ücretsiz sürüm yeter. |
| Quaternius **Stylized Nature MegaKit** | https://quaternius.itch.io/stylized-nature-megakit | `quaternius_nature` | glTF klasörü: saz, nilüfer, çiçek, çalı, taş. Ücretsiz "Standard" zip yeter (yaklaşık 99 MB; yalnızca glTF kısmı kopyalanır). |
| Kenney **Survival Kit** | https://kenney.nl/assets/survival-kit | `kenney_survival` | GLB klasörünün tamamı (çadır, kamp ateşi, sandık, fıçı, araç gereç) |
| Quaternius **Animated Animales** | https://opengameart.org/content/animated-animales-low-poly | `cat` | yalnızca animasyonlu kedi (aşağıda) |

**Kedi:**

- Quaternius'un **Animated Animales Low Poly** paketi ("Animal Pack Vol.2", CC0, yaklaşık 2 MB) animasyonlu bir kedi içeriyor: https://opengameart.org/content/animated-animales-low-poly
- Yalnızca kedinin dosyasını (glTF/GLB yoksa FBX de olur; Godot 4.7 FBX'i doğrudan alır) ve dokusunu kopyala.
- Bulamazsan ya da lisansı CC0 değilse atla: oyunda kodla yapılmış bir kedi kullanılır. CC-BY ya da ücretli bir kedi koyma; önce Ersin'e sor.

### 3. Denetle

```bash
du -sh assets/incoming/models/*
find assets/incoming/models -maxdepth 2 | head -50
```

- Her klasörde bir lisans dosyası olmalı.
- Toplam boyut 150 MB'ı geçmemeli; geçerse en büyük klasörde yalnızca gereken türleri bırak.

### 4. Repoya gönder

```bash
git add assets/incoming/models
git status --short            # yalnızca assets/incoming/models/ satırları "A" olmalı
git commit -m "3D paketleri: Mac'ten indirilen CC0 modeller (assets/incoming/models)"
git pull --rebase --autostash
git push origin claude/festive-shannon-yycmwu
```

- `git status`'ta başka dosya da hazırlanmışsa (`export_presets.cfg` gibi) onu `git restore --staged <dosya>` ile çıkar; commit'e girmesin.
- Push reddedilirse (bulut oturumu o arada bir şey göndermiştir) `git pull --rebase --autostash` ve tekrar push yap. Çakışma çıkarsa dur, Ersin'e haber ver.

## Bitince Ersin'e rapor ver

- Hangi paketler indi, hangileri atlandı (neden)?
- Her klasörün boyutu.
- Push oldu mu (son commit'in kısa kimliği)?
- Ersin bulut oturumundaki Claude'a "3D paketleri yükledim" yazsın; modeller oyuna bağlansın.
