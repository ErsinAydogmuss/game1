# iPhone'da çalıştırma: Mac'teki Claude Code için görev

> **Ersin için:** iPhone'u Mac'e kabloyla bağla. Mac'te Terminal'i aç, `claude` yaz, sonra şu üç yoldan birini seç:
>
> 1. **En kolayı, indirmeden.** Şunu söyle: "github.com/ErsinAydogmuss/game1 reposunun `claude/festive-shannon-yycmwu` dalındaki `docs/iphone-kurulum.md` dosyasını oku ve uygula. iPhone'um kabloyla bağlı."
> 2. **Dosyayı Mac'e indirdiysen.** Şunu söyle: "İndirilenler klasöründeki `iphone-kurulum.md` dosyasını oku ve uygula. iPhone'um kabloyla bağlı." Dosyayı Terminal penceresine sürüklersen yolu kendiliğinden yazılır. Telefona indirdiysen 1. yol daha kolay.
> 3. **Ya da** bu dosyanın tamamını kopyalayıp Claude'a yapıştır.
>
> Claude gerisini kendisi yapar. Senden yalnızca telefonda dokunmaları, gerekirse Xcode'da Apple ID girişini ve Mac şifresini ister. Kazı bu Mac'e kurulduysa adımların çoğu hızlı geçer.

---

## Bağlam

- **Proje:** Olta: Gölün Sırrı, Godot 4.7.2 ile yapılan 3D, yatay ekranlı, rahat bir mobil balıkçılık oyunu.
  Repo: `https://github.com/ErsinAydogmuss/game1`, dal: `claude/festive-shannon-yycmwu`.
- **Kullanıcı:** Ersin. Kazı'dan sonraki oyununu yapıyor ve kodu Claude'a yazdırıyor. Türkçe ve sade konuş; teknik terimleri ilk geçtiğinde kısaca açıkla.
- **Cihaz:** iPhone 14, Mac'e kabloyla bağlı. Ücretsiz Apple ID (Personal Team) varsayılıyor.
- **Hazır olanlar:** Repoda `iPhone` adlı bir dışa aktarma ayarı var (`export_presets.cfg`):
  - Paket kimliği (bundle id) `com.ersinaydogmuss.olta`.
  - Godot yalnızca Xcode projesi üretir: `export/olta.xcodeproj`.
  - `export/` klasörü git dışında ve `.gdignore`'lu, yani Godot onu taramaz.
  - Team ID boş. Onu sen yazacaksın: Kazı'dan kopyalayarak (aşağıdaki kısa yol) ya da 6. adımda.
- Repodaki `CLAUDE.md` proje kurallarını anlatır; repo klasörüne geçince oku. Bu görevde kod yazmıyorsun: kodu bulut oturumundaki Claude yazıyor. Senin işin kurulum ve oyunu telefona yüklemek.

## Görev

Oyunu kullanıcının iPhone'unda aç. Yapabildiğin her şeyi komut satırından yap. Kullanıcıdan yalnızca senin yapamayacağın şeyleri iste: Xcode'da Apple ID ile giriş, telefonda dokunmalar, `sudo` şifresi. Bir adım başarısız olursa hatayı oku, sondaki **Sorun giderme** tablosuna bak, düzelt ve devam et.

## Kurallar

- Oyun kodunu değiştirme.
- `git commit` ve `git push` yapma. `export_presets.cfg`'ye yazacağın Team ID yerel kalsın.
- `sudo` gereken komutları kullanıcıya **ayrı bir Terminal penceresinde** çalıştırt; şifreyi sen giremezsin.
- Büyük indirmelerden önce kullanıcıya haber ver: Xcode birkaç GB, Godot şablonları 1,3 GB.
- Her adımdan sonra kullanıcıya bir iki cümleyle ne olduğunu söyle.

## Kazı bu Mac'e kurulduysa (kısa yol)

Kullanıcı ilk oyunu Kazı'yı (`ErsinAydogmuss/game`) büyük olasılıkla bu Mac'ten telefonuna yükledi. O zaman o sırada kurulanlar duruyordur:

- **1, 3, 4 ve 7. adımlar:** yalnızca baştaki denetim komutlarını çalıştır. Hazır çıkarsa adımı atla.
- **Team ID:** Kazı'nın yerel ayarında yazılı. Kazı klasörüne yalnızca bak, hiçbir şeyi değiştirme:

  ```bash
  grep app_store_team_id ~/game/export_presets.cfg   # klasör orada değilse: mdfind -name project.godot
  ```

  Tırnakların içinde 10 karakterlik bir değer varsa onu Olta'nın `export_presets.cfg`'sindeki aynı satıra yaz ve 6. adımı atla. Boşsa 6. adımı yap.
- **Betik:** `~/kazi-iphone.sh` varsa Olta için `~/olta-iphone.sh`'ı ona bakarak yaz (bkz. "Sonraki güncellemeler"). Repo yolu ve paket kimliği farklı.
- **Kazı telefonda kalabilir:** ücretsiz Apple hesabıyla en fazla 3 uygulama yüklenebilir; Kazı ile Olta 2 eder.

## Adımlar

### 1. Ön koşullar

```bash
sw_vers                  # macOS sürümü
xcodebuild -version      # Xcode kurulu mu?
xcode-select -p          # /Applications/Xcode.app/Contents/Developer olmalı
xcodebuild -license check
```

- **Xcode yoksa** kullanıcı App Store'dan kursun. "Bu Mac'te kurulamaz" derse önce macOS güncellemesi gerekir; kullanıcıya söyle.
- **`xcode-select -p` CommandLineTools gösteriyorsa** kullanıcı şunu çalıştırsın:
  `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer`
- **Lisans onaylı değilse** kullanıcı şunları çalıştırsın:
  `sudo xcodebuild -license accept` ve `sudo xcodebuild -runFirstLaunch`
- Kullanıcı Xcode'u bir kez açsın. Ek bileşen kurmayı önerirse kursun.

### 2. Repo

Repo Mac'te var mı bak (`mdfind -name project.godot`) ya da kullanıcıya sor. Klonlarken GitHub girişi istenirse kullanıcı GitHub Desktop'tan ya da `gh auth login` ile giriş yapsın.

```bash
# Yoksa:
git clone https://github.com/ErsinAydogmuss/game1.git ~/game1 && cd ~/game1
# Varsa repo klasöründe:
git status               # yerel değişiklik varsa üzerine yazma, kullanıcıya sor
git fetch origin
git checkout claude/festive-shannon-yycmwu
git pull
```

### 3. Godot 4.7.2

```bash
GODOT=/Applications/Godot.app/Contents/MacOS/Godot
"$GODOT" --version       # 4.7.2.stable... olmalı
```

Godot yoksa ya da sürümü farklıysa indir ve doğrula. Başka sürüm kuruluysa üzerine yazma: yeni `Godot.app`'i başka bir yere koy ve `GODOT` değişkenini ona göre ayarla.

```bash
mkdir -p ~/Downloads/godot-4.7.2 && cd ~/Downloads/godot-4.7.2
curl -sSLO https://github.com/godotengine/godot/releases/download/4.7.2-stable/SHA512-SUMS.txt
curl -SLO https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_macos.universal.zip
grep ' Godot_v4.7.2-stable_macos.universal.zip$' SHA512-SUMS.txt | shasum -a 512 -c -
unzip -q Godot_v4.7.2-stable_macos.universal.zip      # Godot.app çıkar
```

### 4. iOS dışa aktarma şablonu

```bash
TPL="$HOME/Library/Application Support/Godot/export_templates/4.7.2.stable"
ls "$TPL/ios.zip" && echo "şablon hazır, bu adımı atla"
```

Şablon yoksa indir (1,3 GB). Pakette yalnızca `ios.zip` (200 MB) ve `version.txt` gerekli; diğerlerini çıkarma.

```bash
cd ~/Downloads/godot-4.7.2      # SHA512-SUMS.txt yoksa 3. adımdaki ilk curl satırıyla indir
curl -SLO -C - https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_export_templates.tpz
grep ' Godot_v4.7.2-stable_export_templates.tpz$' SHA512-SUMS.txt | shasum -a 512 -c -
mkdir -p "$TPL"
unzip -j -o Godot_v4.7.2-stable_export_templates.tpz templates/ios.zip templates/version.txt -d "$TPL"
```

İş bitince `.tpz` dosyası silinebilir (kullanıcıya sor).

### 5. İçe aktar ve test et

Bunları repo klasöründe çalıştır:

```bash
"$GODOT" --headless --path . --import      # ilk seferde strings.*.translation hataları normal
"$GODOT" --headless --path . --import      # ikincisi hatasız olmalı
"$GODOT" --headless --path . -s res://tests/run_tests.gd   # çıkış kodu 0: tüm testler geçti
```

İstersen oyunu önce Mac'te aç; kullanıcı da görsün: `"$GODOT" --path .`. Bu bir pencere açar ve kapanana kadar bekler, o yüzden arka planda çalıştır.

### 6. Team ID

Kısa yoldan Team ID'yi Kazı'dan kopyaladıysan bu adımı atla.

```bash
security find-certificate -c "Apple Development" -p | openssl x509 -noout -subject
```

- Çıktıda `OU=`'dan sonraki 10 karakter **Team ID**'dir. Sertifika adındaki parantez içindeki kod Team ID **değildir**.
- "could not be found" derse kullanıcı şunları yapsın:
  1. Xcode → **Settings → Accounts → +** ile Apple ID'siyle giriş yapsın.
  2. Hesabı seçip **Manage Certificates… → + → Apple Development**'a tıklasın.
  Sonra komutu tekrar çalıştır.
- Team ID'yi `export_presets.cfg`'deki `application/app_store_team_id=""` satırına yaz. Yalnızca bu satır değişsin.

### 7. Telefonu hazırla (kullanıcı yapar)

1. Telefon kabloyla bağlı ve kilidi açık olsun. **"Bu Bilgisayara Güvenilsin mi?"** sorusunda **Güven**'e dokunup telefon şifresini girsin.
2. **Ayarlar → Gizlilik ve Güvenlik → Geliştirici Modu** → aç. Telefon yeniden başlar; açılınca **Aç** onayını versin.
   Seçenek görünmüyorsa telefon Xcode açıkken bağlansın. Xcode'da **Window → Devices and Simulators** ekranını açmak da işe yarar.

Denetle. Beklenen satır şöyle olmalı: `<telefon adı> paired enabled wired`.

```bash
xcrun devicectl list devices -j - -q | python3 -c 'import json,sys
for d in json.load(sys.stdin)["result"]["devices"]:
    c, p = d["connectionProperties"], d["deviceProperties"]
    print(p["name"], c.get("pairingState"), p.get("developerModeStatus"), c.get("transportType"))'
```

İlk bağlantıda Xcode telefonu geliştirmeye hazırlar ("Preparing…"). Bu birkaç dakika sürebilir, bekle.

### 8. Xcode projesini üret

```bash
"$GODOT" --headless --path . --export-debug "iPhone" "$PWD/export/olta.ipa"
ls export/olta.xcodeproj
```

Performans ölçmek için `--export-release` kullan: debug butonları görünmez, oyun daha hızlı çalışır. 9. adımdaki derleme yine `Debug` kalır.

### 9. Derle

```bash
xcodebuild -project export/olta.xcodeproj -scheme olta -showdestinations
```

iPhone'un satırındaki `id:` değeri cihazın UDID'sidir. Telefon "Ineligible destinations" altında görünüyorsa yanındaki hatayı oku ve 7. adıma dön.

```bash
UDID="BURAYA_IPHONE_ID"   # -showdestinations çıktısındaki iPhone satırının id: değeri
xcodebuild -project export/olta.xcodeproj -scheme olta -configuration Debug \
  -destination "platform=iOS,id=$UDID" -derivedDataPath export/DerivedData \
  -allowProvisioningUpdates -allowProvisioningDeviceRegistration build
```

- Sonunda `** BUILD SUCCEEDED **` görünmeli.
- **Her zaman `-configuration Debug` kullan.** Godot, Release yapılandırmasına "Apple Distribution" imzası yazar; ücretsiz hesapta bu imza yoktur. Debug yapılandırması "Apple Development" kullanır.

### 10. Telefona yükle ve aç

```bash
APP=export/DerivedData/Build/Products/Debug-iphoneos/olta.app   # yoksa: find export/DerivedData -name '*.app' -path '*iphoneos*'
xcrun devicectl device install app -d "$UDID" "$APP"
xcrun devicectl device process launch --terminate-existing -d "$UDID" com.ersinaydogmuss.olta
```

İlk açılışta "güvenilmeyen geliştirici" ya da "not been explicitly trusted" hatası çıkabilir. Kullanıcı iPhone'da **Ayarlar → Genel → VPN ve Aygıt Yönetimi** → Apple ID'si → **Güven**'e dokunsun, sonra açma komutunu tekrar çalıştır.

### 11. Geri bildirim

Oyun açılınca kullanıcıdan şunlara bakmasını iste (v0.2: Nine'nin dükkânı, takım, para, nadirlik, Balık Defteri). Eski kaydı (v0.1) varsa kendiliğinden yeni biçime geçer; tuttuğu balıklar defterde kalır.

1. Önce iPhone'un sessiz anahtarını kapat (yoksa oyunun hiç sesi çıkmaz).
2. Birkaç balık tut. Balık elde gösterilirken üstünde adı, boyu ve nadirlik simgesi (● ▲ ◆ ★) okunuyor mu?
3. Sudaki gölgeler: bazıları arada pırıldıyor (Nadir), bazıları mor ışıldıyor (Destansı). Tutmadan önce fark ediliyor mu?
4. Kova: sol üstteki kova sayısı artıyor mu? Kova dolunca Dede uyarıyor mu?
5. Nine: iskelenin başındaki dükkâna ya da Nine'ye dokun. Kovayı sat, bir şey al ve tak. Kartlar ve yazılar okunuyor mu, düğmeler kolay basılıyor mu? Seçenek kalabalığı var mı?
6. Aldığın takımın farkı hissediliyor mu (ör. cam kamışla daha uzağa atış, yeni makarayla hızlı sarma, yemle istediğin balık)?
7. Balık Defteri (sağ üstteki kitap): tutmadığın balıkların ipuçları ve oranları anlaşılıyor mu?
8. Para ve rütbe hızı: ilk yarım saatte sık sık yeni bir şey alabiliyor musun, sıkıcı bekleme var mı?
9. Takılma ya da telefonun ısınması var mı? Ekranın çentiği (notch) bir yeri kapatıyor mu?

Kullanıcıya söyle: ana ekrandaki ikon geçici (kodla çizilmiş basit bir balık). Ersin'in uygulama ikonu gelince değişecek.

Ücretsiz Apple hesabıyla en fazla 3 uygulama yüklenebilir; Kazı da biri. Yer yoksa birini silmek gerekir.

Gözlemleri kısa bir liste hâlinde yaz. Kullanıcı bu listeyi kodu yazan Claude oturumuna iletecek.

## Sonraki güncellemeler (kısa yol)

Bulut oturumu yeni kod gönderdiğinde repo klasöründe:

```bash
git pull --autostash                       # yerel Team ID değişikliği korunur
"$GODOT" --headless --path . --import
"$GODOT" --headless --path . --export-debug "iPhone" "$PWD/export/olta.ipa"
# sonra 9. adımdaki xcodebuild ve 10. adımdaki iki devicectl komutu (aynı UDID)
```

Ücretsiz Apple ID ile yüklenen uygulama **7 gün** açılır. Sonra 8–10. adımları tekrarla.
İstersen bu komutları repo dışında `~/olta-iphone.sh` betiğine yazmayı kullanıcıya öner; böylece tek komutla yeniden yükleyebilir.

## Sorun giderme

| Hata | Çözüm |
|---|---|
| `tool 'xcodebuild' requires Xcode` | Kullanıcı: `sudo xcode-select -s /Applications/Xcode.app/Contents/Developer` |
| `No export template found ... ios.zip` | 4. adım |
| `App Store Team ID not specified` | 6. adım |
| `No Account for Team` / `No signing certificate` | Xcode → Settings → Accounts'ta Apple ID ekli mi? Team ID `OU=` değeri mi? |
| `Failed to register bundle identifier` / `is not available` | Bu kimliği başkası almış. `export_presets.cfg`'de `application/bundle_identifier`'ı örneğin `com.ersinaydogmuss.olta2` yap (yerel), 8. adımdan tekrarla. 10. adımdaki kimliği de değiştir. |
| `Developer Mode disabled` / telefon "Ineligible" | 7. adım |
| `iOS xx.x is not installed` | `xcodebuild -downloadPlatform iOS` |
| `device is busy` / `Preparing` | Birkaç dakika bekle, tekrar dene |
| `maximum App ID limit` | Ücretsiz hesap sınırı (7 günde 10 App ID). Var olan kimliği kullan ya da bekle. |
| `not been explicitly trusted` / "güvenilmeyen geliştirici" | 10. adımdaki Güven adımı |
| `Unexpected files found in the export destination directory` | `export/olta.xcodeproj` ve `export/olta` klasörlerini sil, 8. adımı tekrarla |
| `devicectl` UDID'yi tanımıyor | `xcrun devicectl list devices` çıktısındaki Identifier'ı `-d` ile kullan |
| Oyunda hiç ses yok | Kullanıcı iPhone'un sol yanındaki sessiz anahtarını kapatsın (turuncu görünmesin) ve sesi açsın. Godot iOS'ta sesi "Ambient" kipinde açar: telefon sessizdeyken oyun da sessizdir (çoğu oyun gibi). Oyunda Ayarlar → Ses efektleri / Müzik açık olmalı. |

**Komut satırı inatla olmuyorsa:** `open export/olta.xcodeproj` ile projeyi aç → **Signing & Capabilities → Team**'den kişisel takımı seç → üstten iPhone'u seç → **▶ Run**.

**Telefonda hiç olmuyorsa:** Oyunu Mac'te aç: `"$GODOT" --path .`

## Bitince kullanıcıya rapor ver

- Ne kuruldu: Godot, şablon, Team ID.
- Oyun telefonda açıldı mı?
- Karşılaşılan sorunlar ve nasıl çözüldükleri.
- Bir dahaki sefere yeniden yüklemek için ne yapması gerektiği.
