# CLAUDE.md: game1 (yeni oyun, araştırma aşaması)

Ersin'in Kazı'dan sonraki yeni oyun projesi. Kodu tamamen Claude yazıyor. Açıklamaları **Türkçe ve sade** yaz; terimleri ilk geçtiğinde kısaca açıkla.

**Durum:**

- Saha araştırması bitti: `docs/saha-arastirmasi.md`.
- 5 fikir karşılaştırıldı: `docs/fikirler.md`.
- **Ersin'in seçimi bekleniyor.** Henüz oyun kodu yok.

## Ersin ve çalışma şartları

- **Deneyim:** İlk oyunu Kazı (`ErsinAydogmuss/game`). Kod bilmiyor, kodu Claude yazıyor. Samimi konuşur ("kanka").
- **Zaman:** Akşamları ve sabahları, iş arasında çalışıyor; test seansları kısa.
- **Cihazlar:** Mac ve iPhone 14 (kabloyla bağlı). Android cihazı yok.
- **Telefona yükleme:** Bulut oturumu kodu yazar, Mac'teki Claude Code oyunu telefona yükler. Bunun için adım adım bir md görev dosyası ister; örneği Kazı'nın `docs/iphone-kurulum.md`'si. Kurulum ücretsiz Apple hesabı varsayımıyla yazılır; uygulama 7 günde bir yeniden yüklenir.
- **Görseller:** Ersin ChatGPT ile kendisi üretir (stil sayfası + 3×2 sayfa, macenta arka plan) ve GitHub'a web'den yükler.
- **3D ve ses:** 3D modeller KayKit CC0 paketlerinden gelir; bulutta GitHub depoları açık, kenney.nl ve quaternius.com kapalı. Sesler kodla üretilir (numpy).
- **Geri bildirim:** Telefonda oynar, numaralı sorun listesi gönderir; "araştır", "beyin fırtınası yapalım" der.

## Süreç

- **Kararlar:** Seçenek listesi sun, birini "(Önerilen)" diye işaretle. Ersin şimdiye kadar hep önerileni seçti. Bu yüzden öneri dürüst ve gerekçeli olmalı, bedeli seçeneğin açıklamasında yazmalı.
- **Plan:** Seçtikleri sıralı bir plana dökülür. Her adım ayrı commit ve push olur; adım bitince kısa bir "telefonda dene" listesi ver.
- **"Sen karar ver" derse:** karar ver ve nedenini yaz.
- **Gece planı:** "Kendin planla ve onayla, bana sorma" derse sormadan çalış; sabah kısa bir rapor ver, gerekirse video ekle.
- **İnceleme:** Büyük bir işten sonra ayrı bir inceleme ajanı kodu baştan okusun.
- **Commit:** Commit'ten önce test çıktısını oku. Her adımda commit ve push yap; oturum yeniden başlarsa iş kaybolmasın.
- **Dil:** Belgeler ve yorumlar Türkçe, kod isimleri İngilizce, commit mesajları Türkçe.

## Gelir ve "her yaş" kuralları

Ayrıntı ve kaynaklar: `docs/saha-arastirmasi.md` §8.

1. **Konum:** "aile dostu, herkes için". Hedef Apple 4+/9+ ve PEGI 7; çocuk kategorisine girilmez.
2. **Karma kitle kurulumu:**
   - ilk açılışta tarafsız bir doğum yılı sorusu;
   - 13 yaş altı ya da yaşı bilinmeyen oyuncuya yalnızca sertifikalı SDK'dan kişiselleştirilmemiş ödüllü reklam; reklam kimliği yok;
   - yalnızca kendi analitiğimiz;
   - satın alma ve dış bağlantı önünde ebeveyn kapısı.
3. **Parayla şans yok.** Gerçek para ya da gerçek parayla alınan oyun parası, oranı değiştiren ya da zar attıran hiçbir şeyi alamaz. Örnekler: nadir yem, şans eşyası, ek deneme ya da enerji, satın alınan hava olayı, zaman atlama, altın yuva.
4. **Gizli içerik baştan belli.** Yumurta, sandık, çamurlu eşya gibi şeylerin içi oluştuğu anda belirlenir. İçini açtıran hızlandırma parayla satılmaz.
5. **Doğrudan satış:** kostümler ve görünüş süsleri. Fiyat her zaman gerçek parayla da yazar. Bir süs bir türü çağırıyorsa tarif o türü garanti eder.
6. **Sezon kartının süresi dolmaz.** Eski kartlar alınabilir kalır; satın alma ekranında geri sayım olmaz.
7. **Oyuncu yokken ceza yok.** Aç kalan, ölen, kirlenen, solan, kaçan bir şey olmaz; seri sıfırlanmaz. Boşta biriken gelir bir üst sınırda durur.
8. **Sık yarışma yok.** Etkinlikler seyrek ya da ortak hedefli olur.
9. **Açık sohbet yok.**
10. **Oranlar ve şans garantisi (pity) açıkça gösterilir.**

## Motor ve mimari

Fikir seçilince eklenecek. Godot 4.7 seçilirse Kazı'nın `CLAUDE.md` kuralları aynen geçerli:

- statik tip;
- determinizm (seed'li zar);
- `scripts/core/` altında saf oyun mantığı;
- headless testler, bot senaryoları ve ekran görüntüsü.
