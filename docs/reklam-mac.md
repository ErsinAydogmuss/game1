# Mağaza sürümünü Mac'te derleme: Mac'teki Claude Code için görev

> **Ersin için:** Mac'te Terminal'i aç, `claude` yaz ve şunu söyle:
> "github.com/ErsinAydogmuss/game1 reposunun `claude/festive-shannon-yycmwu` dalındaki `docs/reklam-mac.md` dosyasını oku
> ve uygula. Önce Android paketini (ya da iPhone'u) derleyeceğiz."
> Ya da bu dosyanın tamamını kopyalayıp Claude'a yapıştır.

---

## Bağlam

- **Proje:** Olta: Gölün Sırrı, Godot 4.7.2 ile yapılan 3D, yatay ekranlı, rahat bir mobil balıkçılık oyunu. Repo
  `https://github.com/ErsinAydogmuss/game1`, dal `claude/festive-shannon-yycmwu`. Proje kuralları `CLAUDE.md`'de.
- **Kullanıcı:** Ersin. Kazı'dan sonraki oyununu yapıyor; kodu bulut oturumundaki Claude yazıyor. Türkçe ve sade
  konuş, teknik terimleri ilk geçtiğinde kısaca açıkla.
- **Kazı'yla aynı yol:** Ersin Kazı'yı bu Mac'ten Google Play'e ve App Store'a gönderdi (Kazı'nın reposunda
  `docs/reklam-mac.md`). Olta'da da aynı reklam eklentisi ve aynı adımlar var; Kazı için kurulanlar (Java, Android SDK,
  Godot şablonları, Xcode hesabı) büyük olasılıkla duruyor: her adımın başındaki denetimi çalıştır, hazırsa atla.
- **Neden Mac'te:** reklamlar (Google AdMob; Poing Studios'un `godot-admob-plugin` v5.1.0, `addons/admob/`) Android'de
  **Gradle derlemesi** ister: Google'ın reklam SDK'sı derlenirken Google'ın Maven deposundan (`dl.google.com`) iner,
  bulut oturumu oraya erişemiyor. iPhone'da Xcode, Google'ın SDK'larını Swift Package Manager'la kendisi indirir.
- **Hazır olanlar (depoda):**
  - Android ayarı (`export_presets.cfg`, "Android"): Gradle derlemesi açık, biçim AAB, internet ve ağ durumu izinleri,
    paket `com.juiloot.olta`, imzalı (anahtar ortam değişkeninden), sürüm kodu `version/code`.
  - iPhone ayarı ("iPhone"): paket `com.juiloot.olta`, takım `3D9ZPVPY5L` (Kazı'nınki), en az iOS 15, Info.plist'e
    izleme izninin açıklaması (`NSUserTrackingUsageDescription`), Dosyalar'dan erişim (fotoğraflar).
    `GADApplicationIdentifier`'ı ve Google'ın SKAdNetwork kimliklerini eklenti ekler.
  - Reklam kimlikleri: **gerçekleri henüz yok** (Ersin AdMob'da açınca bulut oturumu yazar: `docs/reklam-kurulum.md`).
    O zamana kadar sürüm derlemesinde reklam çıkmaz (uygulama kimliği Google'ın örneği); **debug derleme her zaman
    Google'ın deneme reklamlarını** gösterir.
  - Denetim aracı: `tools/check_aab.py` (imza, sürüm kodu, izinler, AdMob kimliği, 16 KB hizası).

## Kurallar

- Oyun kodunu değiştirme; `git commit` / `git push` yapma. Bir şey değişmeliyse Ersin'e söyle, o bulut oturumuna iletir.
- **Yükleme anahtarı** (`olta-upload.jks`) ve parolası git'e girmez, komut satırına açıkça yazılmaz: parola ortam
  değişkeninden (`read -s`). `export_presets.cfg`'ye anahtar yolu ya da parola yazma. Anahtarı iki ayrı yerde yedekle.
- Oyunun kökünde oluşan `android/` klasörü (Godot'nun derleme şablonu) ve `export/` git'e girmez (`.gitignore`'da).
- **Kendi reklamına tıklama, kimseye tıklatma**: AdMob hesabı kalıcı kapanır. Deneme reklamları ("Test Ad") güvenli.
- Büyük indirmelerden önce Ersin'e haber ver (Android SDK ve NDK birkaç GB, Godot şablonları 1,3 GB).
- Her adımdan sonra Ersin'e bir iki cümleyle ne olduğunu söyle.

## Android: AAB (Google Play)

### 1. Ön koşullar (Kazı için kurulduysa atla)

```bash
git -C <repo> pull origin claude/festive-shannon-yycmwu   # repo yoksa: git clone, dal claude/festive-shannon-yycmwu
/usr/libexec/java_home -v 17 && ls "$HOME/Library/Android/sdk/ndk"   # ikisi de varsa bu adımı atla
brew install --cask temurin@17                              # Java 17 (Godot 4.7'nin Android şablonu ister)
brew install --cask android-commandlinetools                # Android SDK'nın komut satırı araçları
export JAVA_HOME="$(/usr/libexec/java_home -v 17)"
export ANDROID_HOME="$HOME/Library/Android/sdk"
yes | sdkmanager --sdk_root="$ANDROID_HOME" --licenses
sdkmanager --sdk_root="$ANDROID_HOME" "platform-tools" "platforms;android-36" "build-tools;36.1.0" "ndk;29.0.14206865"
```

Sürümler Godot 4.7.2'nin Android şablonundan: compileSdk / targetSdk 36, minSdk 24, build-tools 36.1.0, NDK
29.0.14206865, Java 17.

### 2. Godot 4.7.2 ve şablonlar

- `godot=/Applications/Godot.app/Contents/MacOS/Godot`; yoksa `docs/iphone-kurulum.md` 3. adım.
- Dışa aktarma şablonları 4.7.2 kurulu olmalı (`~/Library/Application Support/Godot/export_templates/4.7.2.stable/`);
  yoksa `docs/iphone-kurulum.md` 4. adım (aynı `.tpz`, Android şablonları da içinde).
- Godot'nun editör ayarlarında Java ve Android SDK yolları (Kazı için yazıldıysa duruyor):
  `~/Library/Application Support/Godot/editor_settings-4.7.tres` içinde
  `export/android/java_sdk_path = "<JAVA_HOME>"` ve `export/android/android_sdk_path = "<ANDROID_HOME>"`.

### 3. İçe aktar ve test et

```bash
cd <repo>
$godot --headless --path . --import
$godot --headless --path . -s res://tests/run_tests.gd      # çıkış kodu 0 olmalı
```

### 4. Yükleme anahtarı (yalnızca ilk sefer)

Olta'nın kendi yükleme anahtarı olur (Kazı'nınkinden ayrı). Ersin'le birlikte üret; parolayı Ersin seçsin ve bir şifre
yöneticisine yazsın:

```bash
mkdir -p ~/olta-keys && cd ~/olta-keys
keytool -genkeypair -v -keystore olta-upload.jks -storetype PKCS12 -alias upload -keyalg RSA -keysize 2048 \
  -validity 10000 -dname "CN=Ersin Aydogmus, O=Juiloot, C=TR"
keytool -list -v -keystore olta-upload.jks -alias upload | grep SHA256   # parmak izi: Ersin'e söyle
```

Parmak izini Ersin bulut oturumuna iletir: `tools/check_aab.py`'deki `UPLOAD_SHA256`'ya yazılır (sonraki paketlerin
doğru anahtarla imzalandığı denetlensin). Anahtarı iki ayrı yerde yedekle (ör. bu Mac ve şifre yöneticisi ya da
Google Drive). Kaybolursa uygulama kaybolmaz (Play App Signing), ama sıfırlamak günler sürer.

### 5. Derle

```bash
export GODOT_ANDROID_KEYSTORE_RELEASE_PATH="$HOME/olta-keys/olta-upload.jks"
export GODOT_ANDROID_KEYSTORE_RELEASE_USER="upload"
read -s GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD && export GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD
v=$(grep '^config/version=' project.godot | cut -d'"' -f2)
c=$(awk '/name="Android"/{a=1} a&&/^version\/code=/{split($0,x,"=");print x[2];exit}' export_presets.cfg)
mkdir -p export
# İlk kez: derleme şablonunu da kurar (oyunun kökünde android/ oluşur). Sonrakilerde --install-android-build-template gerekmez.
$godot --headless --path . --install-android-build-template --export-release "Android" "export/olta-$v-$c.aab"
```

İlk derleme Gradle'ı ve Google'ın SDK'sını indirir (birkaç dakika). Çıktıda "AdMob Android Export Error" ya da
"BUILD FAILED" varsa **Sorun giderme**'ye bak.

### 6. Denetle

```bash
curl -sSLo /tmp/bundletool.jar https://github.com/google/bundletool/releases/download/1.18.3/bundletool-all-1.18.3.jar
python3 tools/check_aab.py "export/olta-$v-$c.aab" --bundletool /tmp/bundletool.jar   # gerçek kimlikler gelince: --real-ids
```

Bütün `KONTROL` satırları TAMAM olmalı: imza (ve `UPLOAD_SHA256` yazıldıysa parmak izi), sürüm kodu, internet ve
reklam kimliği (AD_ID) izinleri, AdMob uygulama kimliği, 64 bit kütüphanelerin 16 KB hizası, `extractNativeLibs=false`.

### 7. Play'e yükle

1. Play Console → **Uygulama oluştur**: ad **Olta: Gölün Sırrı**, varsayılan dil **Türkçe**, **Oyun**, **Ücretsiz**.
   (Mağaza metinleri `docs/magaza/magaza-metinleri.md`'de; beyanlar `docs/magaza/yayin.md`'de.)
2. **Test et ve yayınla → Test → Dahili test → Yeni sürüm oluştur.** Uygulama imzalama sorulursa Google'ın önerisini
   kabul et (Play App Signing). AAB'yi sürükle; sürüm notları `docs/magaza/magaza-metinleri.md`'nin sonunda.
3. **Test kullanıcıları**: Ersin'in Gmail adresi; katılma bağlantısını Android telefonda aç (Ersin'in Android
   telefonu yok: bir yakınınınkini kullanabilir ya da bu adım kapalı teste kalır).
4. Üretime çıkmadan önce **kapalı test şartı**: kişisel geliştirici hesabı 13 Kasım 2023'ten sonra açıldıysa en az
   12 test kullanıcısı 14 gün boyunca kapalı testte olmalı (Play Console'un ana sayfası neyin eksik olduğunu gösterir).

## iPhone: App Store (TestFlight)

1. Telefona kabloyla deneme: `docs/iphone-kurulum.md` (8–10. adımlar; debug derleme, deneme reklamları).
2. Mağaza sürümü için Xcode projesini üret: `$godot --headless --path . --export-release "iPhone" "$PWD/export/olta.ipa"`
   (yalnızca proje: `export/olta.xcodeproj`).
3. `open export/olta.xcodeproj`. Xcode eklentinin eklediği Swift paketlerini (GoogleMobileAds,
   GoogleUserMessagingPlatform) indirir; inmezse **File → Packages → Resolve Package Versions**.
4. **Signing & Capabilities**: takım `3D9ZPVPY5L`, paket `com.juiloot.olta`. Info.plist'te `GADApplicationIdentifier`,
   `SKAdNetworkItems` ve `NSUserTrackingUsageDescription` olmalı.
5. App Store Connect'te uygulama açılmış olmalı (Ersin: **Uygulamalar → + → Yeni Uygulama**: iOS, ad **Olta: Gölün
   Sırrı**, dil Türkçe, paket kimliği `com.juiloot.olta`, SKU `olta`; ayrıntılar `docs/magaza/yayin.md`).
6. Üstten **Any iOS Device (arm64)** seç → **Product → Archive** → **Distribute App → App Store Connect → Upload**.
7. Birkaç dakika sonra App Store Connect → **TestFlight**'ta yapı görünür; Ersin iPhone'daki TestFlight uygulamasıyla
   kurup dener. İncelemeye göndermeden önce `docs/magaza/yayin.md`'deki **App Privacy** ve **inceleme notu**.

## Telefonda dene (her iki platformda)

`docs/iphone-kurulum.md` 46–49 (reklamlar): 3 balıktan sonra "Reklamlar hakkında", izleme izni (iPhone), dört teklif,
geçiş reklamı (20 dakikadan sonra harita ya da çayda), Ayarlar → Gizlilik ve Lisanslar. Gerçek kimliklerle denerken
telefon AdMob'da **test cihazı** olmalı (AdMob → Ayarlar → Test cihazları); yine de reklamlara tıklama.

## Sorun giderme

| Belirti | Çözüm |
|---|---|
| "'Use Gradle Build' must be enabled" | `export_presets.cfg`'de Android ayarında `gradle_build/use_gradle_build=true` olmalı (depoda öyle; yerel değişikliği geri al). |
| "Android build template not installed" | 5. adımdaki komutu `--install-android-build-template` ile çalıştır. |
| "SDK location not found" / "Java SDK path" | 2. adımdaki editör ayarları; ya da `ANDROID_HOME` ve `JAVA_HOME` dışa aktarılmış mı. |
| "Could not resolve com.google.android.libraries.ads.mobile.sdk" | İnternet; `dl.google.com` erişilebilir olmalı. |
| "Failed to find Build Tools revision 36.1.0" ya da NDK | 1. adımdaki `sdkmanager` paketleri. |
| İmza hatası / "keystore was tampered" | Parola yanlış ya da takma ad `upload` değil; `keytool -list -keystore <jks>` ile bak. |
| `check_aab.py`: "yükleme anahtarıyla imzalı" OLMADI | Başka bir anahtarla imzalanmış: `GODOT_ANDROID_KEYSTORE_RELEASE_*` değişkenleri. |
| Uygulama açılır açılmaz kapanıyor | AdMob uygulama kimliği bildirimde yok: `check_aab.py`'nin "AdMob uygulama kimliği" satırı. |
| Deneme reklamı gelmiyor | İnternet; `adb logcat \| grep -iE "godot\|ads"` (Android) ya da Xcode'un konsolu. Reklamlar 3 balıktan ve "Reklamlar hakkında"dan sonra yüklenir. |
| Gerçek reklam gelmiyor | Yeni AdMob uygulaması ilk saatlerde az reklam alır; uygulama mağazaya bağlanıp AdMob'un incelemesinden geçince düzelir; app-ads.txt. |
| iOS: "No such module 'GoogleMobileAds'" | Xcode → File → Packages → Resolve Package Versions. |

## Bitince kullanıcıya rapor ver

- AAB'nin adı ve yeri, `check_aab.py`'nin sonucu (bütün KONTROL satırları) ve yükleme anahtarının SHA-256 parmak izi.
- iPhone: arşiv yüklendi mi, TestFlight'ta görünüyor mu.
- Telefonda hangi teklifleri denediğin ve gördüğün.
- Bir sorun varsa hata metnini aynen; bulut oturumundaki Claude'a iletilecek.
