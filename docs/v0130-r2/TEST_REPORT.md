# PRİZMA v0.13.0 — yapı 19

Mevcut çalışan mavi-yeşil gerçek 3D gezegen temel alındı. Beş dünya seçimi, 360° parmak dönüşü/atalet, kamera yaklaşımı, 50 düğümlü dikey yollar, hedef açıklamaları ve sonraki bölüm akışı korunuyor. Sanat prototipleri uygulamaya eklenmedi; premium görsel kalite iddiası yok.

Bu revizyonda gerçek render'da bulunan eksik giderildi: dört uzun duraklatma butonu yerine büyük DEVAM ET ve altında Yeniden Oyna/Ayarlar/Harita ikon satırı. Mevcut v0.13.0 yayını değiştirilmez; aynı uygulama sürüm adının yeni Android yapı kodu 19, yayın etiketi v0.13.0-r2.

## Doğrulama

- SMOKE: import ve workflow_smoke geçti.
- TARGETED: v0130_tests (360°/beş seçim/kilit/zoom/50 bölüm/300 açıklama değişimi/duraklatma), persistence_probe geçti.
- 15 ek kontrol: dönüşün yavaşlaması, Android geri isteğinin masaüstünde simülasyonu, önizleme kapatma, pause/resume, ikon satırı, kazanma fixture'ı sonrası diske ilerleme/yıldız kaydı ve yeniden okuma, doğrudan sonraki bölüm girişi geçti. Bu fixture gerçek bir bölüm kazanılabilirliği simülasyonu değildir. İlk fixture tek frame beklediği için transition sırasında erken kontrol etti; oyun kodu bu nedenle değiştirilmedi, test gerçek geçiş durumunu bekleyecek şekilde düzeltildi.
- Godot 4.6.3 llvmpipe gerçek render: 320×568 ve 390×844 gezegen, altı hedefli önizleme, uzun kaydırılabilir yardım, doğru dünya adıyla yeni kompakt duraklatma. Son loglarda SCRIPT ERROR yok.
- İki APK birer kez üretildi; ZIP/CRC, aynı sertifika, paket kimlikleri, yapı 19, paketlenmiş bölüm JSON'ları ve ARM kitaplıkları doğrulandı. APK içindeki gerçek kaynaklar ayrıca açıldı: üretimde geliştirici komutları reddediliyor; ayrı geliştirici paketinde hızlı geçiş/özel güçler çalışıyor, iki pakette de yeni ikon menüsü var.
- Çekirdek motor, mekanikler ve bölüm veri dosyaları önceki kaynakla aynı; 250 bölüm yeniden üretilmedi ve geniş kampanya simülasyonu çalıştırılmadı.

## Sınırlar

Gerçek Android cihazında FPS/input/geri tuşu/kurulum ölçülmedi; 60 FPS garantisi yok. Kullanılan gezegen görselleri işlevsel mevcut stilize varlıklardır; reddedilen premium sanat hedefinin tamamlandığı iddia edilmiyor. Fiziksel Android eski kayıtla üstüne kurulum kullanıcı cihazında kontrol edilmelidir; imza ve paket uyumluluğu doğrulandı. Normal ve geliştirici paket kimlikleri ayrı kalır.
