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

Oyun açılınca kullanıcıdan şunlara bakmasını iste (v0.3: büyük göl; v0.3.1: berrak görüntü ve iri balık; v0.4: teknikler, 13–19). Eski kayıt kendiliğinden yeni biçime geçer: v2'den v3'e rütbe ve rütbe çubuğundaki ilerleme aynı kalır, yalnızca rütbe puanının sayısı yeni (daha uzun) rütbe eğrisine taşınır; v3'ten v4'e şamandıra takımı aynen kalır, makara ve misina bütün tekniklerde ortak olur. Para, kova, takım ve defter aynen kalır.

1. Önce iPhone'un sessiz anahtarını kapat (yoksa oyunun hiç sesi çıkmaz).
2. Rütben güncellemeden önceki gibi mi? (Sayı değişebilir; rütbe ve çubuk aynı kalmalı.)
3. **Göl büyüdü** (eskisinin ~3,7 katı). İskeleden karaya in, kıyı boyunca bir yere dokun: balıkçı sudan geçmeden kıyı yolundan dolaşıyor mu? Kilitli bir bölgenin çitine gelince duruyor ve Dede ne zaman geçileceğini söylüyor mu?
4. **Harita:** ilk balıktan sonra sağ üstte harita düğmesi çıkar. Haritada bölge rozetleri, kilitler, "Yeni!" ve "Buradasın" iğnesi var mı? Açık bir bölgeye dokun: ekran kararıp oraya geçiyor mu? Harita çentiğe takılmadan ekrana sığıyor mu?
5. **Yeni bölge:** rütbe 3'te nilüferli koy açılır (5'te kayalık burun, 7'de dere ağzı). Bildirim çıkıyor, Dede söylüyor, harita düğmesi atıyor mu?
6. **Bölgelerin görünüşü:** sazlıkta sık kamış, nilüferli koyda nilüfer tarlası, kayalık burunda iri kayalar ve yosunlu taş, dere ağzında akan su, derin ortada şamandıralar. Kıyıya gelen dalga çizgileri, toprak yol ve ıslak kum güzel mi?
7. **Yeni türler** (7 tür, toplam 12): gümüş balığı iskele koyunda ve sazlıkta, çapak iskele koyunda ve derin ortada, kadife sazlıkta, altın sazan nilüferli koyda, tatlısu kefali kayalık burunda ve dere ağzında, sudak kayalık burunda ve derin ortada, mersin derin ortada. Defter bulunduğun bölgenin oranlarını gösteriyor mu?
8. **Sandal:** rütbe 9'da Nine'nin Ekstra sekmesinde (3.500 para). İskeledeki sandala dokun: derin ortada sandaldasın; sol alttaki "Kıyıya dön" iskeleye getirir. Mersin tutulunca kartında "Göle bırak" çıkıyor mu? "Kıyıya dön" düğmesi çentiğe takılmadan tam görünüyor mu?
9. **Hepsini hızlıca görmek için** aşağıdaki "12. Telefonda hız ölçümü" bölümündeki **Bölgeleri ve teknikleri aç**'ı kullan (kaydı değiştirir; istersen sonra **Kaydı sıfırla**). Normal oyunda nilüferli koy ≈ 10. dakikada açılır; derin ortaya (rütbe 9 ve sandal) ≈ 2 saatte varılır.
10. Takılma, ısınma ya da pil çabuk bitmesi var mı? Sonra "12. Telefonda hız ölçümü" bölümündeki ölçümü yap.
11. **v0.3.1: renkler berrak mı?** Eskiden görüntü sisli gibiydi; şimdi su daha koyu mavi, çimen ve iskele daha canlı olmalı. Olta sudayken de puslu görünmemeli.
12. **v0.3.1: iri balık takım ister.**
    - İskele koyunda bambu oltayla 4–5 yıldızlı iri sazan, turna ya da yayın takılınca "Çok iri!" çıkıyor mu?
    - O balıkta gerilim sakinken bile kırmızıya çıkıp misina kopuyor mu? Ardından Dede neyi alman gerektiğini söylüyor mu?
    - Nine'nin kamış ve misina kartlarında "İri balık" yıldızları var mı? Cam elyafı kamış ve naylon misinayı alınca 4 yıldızlılar tutuluyor mu?
    - Kolay çekme açıkken iri balık kopmadan, yalnızca yavaş geliyor mu?
13. **v0.4: Takım Çantası.** Rütbe 2'de sol altta teknik düğmesi çıkar ("Yeni teknik: Spin!", Dede, düğme nabız gibi atar). Dokun: şamandıra, spin, dip, sinek karoları ve altta kerevit tuzağı. Kilitli teknikte rütbesi, kamışı yoksa NİNE'DE (dükkân o tekniğin kamışlarında açılır). Panel ve düğmeler çentiğe takılmadan sığıyor mu? Hızlı denemek için "12. Telefonda hız ölçümü"ndeki **Bölgeleri ve teknikleri aç** her tekniğin ilk kamışını ve bir tuzak verir.
14. **v0.4: Spin.** Bir gölgenin ötesine at, **basılı tut:** yem gelir; **bırak:** durur ve batar. Yırtıcı peşine düşünce (halka, "Peşinde biri var!") dur-kalk yap: o an basılıysan balık kendiliğinden takılır, bırakmışsan "VUR!" çıkar. Dur-kalk ritmi parmakta rahat mı? Sazlıkta yemi bekletince takılıyor mu (geri sarma)?
15. **v0.4: Dip** (rütbe 4). Suya dokun: kurşun uzağa uçar, olta yanındaki sehpaya konur. Zil tek tük çalarken dokunma (balık kokluyor); durmadan çalınca ve misina akınca ekranın her yerine dokun. Kamera kurşunu da gösteriyor mu, balıkçı ipucu çubuğunun arkasında kalıyor mu? Sazlıkta aynalı sazan geliyor mu?
16. **v0.4: Sinek** (rütbe 7, yalnızca dere ağzında). Akıntıya at: sinek süzülür, alabalık altına gelir; **halka çıkınca hemen dokun.** Halkadan önce dokunursan balık kaçar. Alabalık çekişirken sudan sıçrıyor mu? Dere ağzından çıkınca şamandıraya dönüp geri gelince sinek yine elinde mi? Dere ağzı dışındayken uygulamayı kapatıp açınca da?
17. **v0.4: Kerevit tuzağı** (rütbe 3). Nine'den tuzak al (Ekstra), sazlıkta ya da kayalık burunda Takım Çantası'ndan **Tuzak bırak**. Turuncu şamandıra ve "0/4" rozeti çıkıyor mu? Oyunu kapat, 20–40 dakika sonra aç: rozet 1/4 ya da 2/4 mü? Şamandıraya dokun: kerevitler kovaya, elde kerevit. Boş tuzağa dokununca bekle ya da kaldır paneli. Dipte olta sudayken ekranın her yeri eylemdir: yakındaki tuzağa dokunmak tuzağı değil oltayı sarar. Bu kafa karıştırıyor mu?
18. **v0.4: Defter ve Dede.** Defter iki sayfa (16 tür). Tutulmamış kerevitte "Tuzağa girer: Sazlık, Kayalık Burun", alabalıkta "Sevdiği sinek" yazıyor mu? Oranların başlığında elindeki teknik yazıyor mu? Rütbe 4'ten sonra sazlıkta şamandırayla bir balık tutunca Dede bir kez "Dip dene!" diyor mu? Dede'ye dokununca açtığın tekniklerin öğütleri de geliyor mu?
19. **v0.4: Denge.** Spinle iskelede ve nilüferli koyda, dipte derin ortada, sinekle dere ağzında para şamandıradan çabuk geliyor mu? Bir tekniğin sıkıcı ya da çok zor geldiği yer var mı?

Ücretsiz Apple hesabıyla en fazla 3 uygulama yüklenebilir; Kazı da biri. Yer yoksa birini silmek gerekir.

Gözlemleri kısa bir liste hâlinde yaz. Kullanıcı bu listeyi kodu yazan Claude oturumuna iletecek.

### 12. Telefonda hız ölçümü

Büyük göl telefonda akıcı mı, bunu ölçmek için. Kullanıcıyla birlikte yap ve değerleri tabloya yaz.

1. Telefonu prize tak ya da şarjı yüksek tut. **Düşük Güç Modu** kapalı olsun: açıkken telefon kendini yavaşlatır.
2. Oyunda **Ayarlar**'ı (dişli) aç. Dil satırının altındaki sürüm yazısına ("Olta: Gölün Sırrı · v…") arka arkaya **5 kez** dokun. Yazının sonuna "ölçüm açık" eklenir. Sol üstte "60 FPS · 140 çizim · 244k üçgen" gibi bir yazı belirir. Kapatmak için yine 5 dokunuş.
3. Ölçüm açıkken debug derlemede iki geliştirici satırı da görünür: **Bölgeleri ve teknikleri aç** ve **Kaydı sıfırla**. Bütün bölgeleri görmek için **Bölgeleri ve teknikleri aç** → **AÇ**: rütbe 9 olur; sandal, spin, dip ve sinek kamışları ve bir tuzak verilir; para ve defter değişmez. Bu kaydı değiştirir: istersen denemeden sonra **Kaydı sıfırla** ile baştan başla.
4. Haritadan sırayla her bölgeye geç: iskele koyu, sazlık, nilüferli koy, kayalık burun, dere ağzı. Sonra haritada **Derin Orta**'ya dokun: sandalla derin ortaya açılırsın. Her yerde 10 saniye bekle ve sol üstteki üç sayıyı yaz.
5. Bir balık tut. Çekişme sırasında FPS'e bak: en çok iş o anda yapılır.

| Yer | FPS | Çizim | Üçgen (k) |
|---|---|---|---|
| İskele koyu | | | |
| Sazlık | | | |
| Nilüferli koy | | | |
| Kayalık burun | | | |
| Dere ağzı | | | |
| Derin orta (sandal) | | | |
| Çekişme anında | | | |

- **Hedef:** her yerde 60 FPS, en az 50.
- **Bulutta ölçülen çizim sayısı** (`tour` botu, ölçüm yazısı açıkken): iskelede 140, öteki yerlerde 88–114, sandalda 98. Telefondaki sayı bundan çok farklıysa not et.
- FPS 50'nin altındaysa şunları da yaz: hangi yerde düştüğü, telefonun ısınıp ısınmadığı, ilk açılışta mı yoksa sürekli mi olduğu.

İstersen bir de `--export-release` ile kur (8. adım) ve açık bölgelerde ölç. Release derlemede "Bölgeleri ve teknikleri aç" düğmesi yoktur; sayılar debug'dan biraz daha iyi çıkar.

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
