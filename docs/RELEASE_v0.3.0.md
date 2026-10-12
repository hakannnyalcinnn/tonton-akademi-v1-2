# PRİZMA 0.3.0 — Büyülü Kristaller test sürümü

Beş özgün, büyük ve farklı silüetli kristal; yüzey yansımaları, parçacıklı kırılma, güç oluşumu, roket/renk/prizma efektleri, büyük kombo yazıları ve akıcı puan gösterimi. Normal dokunarak patlatma yoktur; aynı Match-3 motoru ve 10 bölüm korunur. Yeni dünya, bölüm, mağaza veya mekanik eklenmedi.

Kaydırma eşikte başlar, komşuya tek takas yapar. Paylaşılan kristal atlası, tek görselde önceden çizilmiş tahta, yeniden kullanılan efektler/etiketler/sesler ve arka planda atomik kayıt yazımı kullanılır. Otomatik/yüksek/dengeli/performans, sarsıntı, azaltılmış efekt/hareket, titreşim ve ses seviyesi ayarları vardır. 16:9 / 19,5:9 / 20:9 ekranlar için tam arka plan ve güvenli alan yerleşimi desteklenir.

**22.040 sayılan otomatik kontrol başarılı** (21.969 motor + 71 kalite). 2.000 başlangıç tahtası, 10 bölümde 1.000 oyun / 4.128 hamle, iki süreçte kayıt devamı, 100 geçerli + 100 engellenen native ScreenTouch kaydırması, efekt havuzları, dört yön ve tam dolum kontrol edildi.

Bulutun yazılımsal çiziminde aynı 100 hamle / 228 dalgada ortalama yaklaşık **32,3 → 59,9 FPS**, çizim çağrısı **692 → 170**, kare p95 **39,5 → 17,2 ms**. Bazı uzun kareler hâlâ var; her karede 60 FPS garanti edilmedi. **Bunlar Android cihaz ölçümü değildir.** Grafik ve mantık ölçümleri, sınırlar ve gerçek test ayrıntıları `prizma-quality-report.zip` ve kaynak arşivindeki `docs/QUALITY_REVISION.md` içindedir.

## Telefona kurulum

Assets → **prizma-match3.apk**. Mevcut **0.2.0 PRİZMA Match-3** üzerine güncelleme olarak kurulur; paket ve imza aynı, kayıt korunur. **Uygulamayı kaldırmayın.** 0.1.0’daki ayrı eski uygulama da değiştirilmez. Android 7.0+, ARMv7/ARM64, internet izni yoktur. Debug test APK’sıdır.

Cihazda oyna, ardından **Ayarlar → Performans ölçümü / rapor → RAPORU KOPYALA**. Telefonun gerçek FPS, CPU/GPU, dokunma/görsel tepki ve oyun aşaması süreleri paylaşılabilir; uygulama raporu kendiliğinden göndermez.

Fiziksel Android cihaz bağlı değildi. Telefon FPS, çentik, titreşim/ses gecikmesi, gerçek Android arka plan dönüşü ve ısınma testi yapılmış gibi gösterilmez. Godot ekran görüntüleri ve sentetik yaşam döngüsü/koordinat testleri cihaz testinin yerini tutmaz. Bir sonraki geliştirme aşamasına geçilmedi.
