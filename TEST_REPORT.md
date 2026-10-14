# PRİZMA v0.13.1 — Yaşayan Macera Haritası

- Aktif gezegen ekranı kaldırıldı; uygulama güncel bölümün haritasından açılıyor. Beş dünyada tek parça 50 noktalı, geniş Bézier S yolu, numaralar/yıldızlar/kilitler, aktif nokta vurgusu ve güncel bölüme dönüş var.
- Mevcut özgün dünya arka planları korundu. Ayrı 2D katmanda kelebek/balık hareketi, çiçek salınımı, şelale çizgileri, bulut hareketi, lav parlaması ve karakter hareketleri var. Görünür alan dışında çizim yapılmıyor; azaltılmış hareket ve performans ayarları uygulanıyor. Ek dekor atlası özgün görüntü üretimiyle hazırlandı, başka oyun varlıkları kullanılmadı.
- Dünya kartları büyük önizleme, ad/aralık/tamamlanma/ilerleme ve kilit durumu gösteriyor. Dört dünya sınırında kısa varış ve sonraki bölüm önizlemesi açılıyor. Gerçek hedef/ödül/kayıt kuralları değiştirilmedi; olmayan ödül veya 251. bölüm gösterilmiyor.
- Duraklatma paneli kısaltıldı; büyük Devam Et ve üç ikon korundu. Dünyalar kontrolü belirginleştirildi; yazılar Container/ScrollContainer içinde.

## Gerçekleştirilen kontroller

SMOKE/workflow_smoke; 49 v0131 kontrolü; persistence_probe; goals_panel_tests; r2_gravity_tests; v0121_ui_tests ve v012_tests başarılı. Native dokunma kaydırması masaüstü olaylarıyla simüle edildi; beş dünya, kilitler, yıldızlar, dört dünya geçişi, kayıt yükleme ve geri/pause davranışları kontrol edildi. Çekirdek/mekanik/bölüm verileri Git ağaçlarıyla birebir aynı; geniş kampanya simülasyonu çalıştırılmadı.

İlk geliştirme denemelerinde sınıf adı çakışması, eksik metin helper'ı, eski gezegen assertion'ı ve seyrek düğüm örnekleyen yol genişliği fixture'ı bulundu; düzeltildi. Eski UI kontrolü atlanmadı, beş kart/gezegensiz akışa uyarlandı. İlk render'da zemin dikişi ve ters görünen arka planlar düzeltildi; son kareler düz yönde yumuşak örtüşme kullanıyor. Son seçilmiş testlerde açık başarısızlık yok.

Godot 4.6.3 gerçek render: beş dünya ve hareketli kare çiftleri, kapı, dünya kartları, pause, yeni dünya varışı; 320×568/390×844 kartlar ve kaydırılabilir yardım. Beş kare çiftinin yan dekor alanlarındaki hareket doğrulandı; statik kare animasyon kanıtı olarak sunulmuyor. Görseller ayrı test profillerinden, gerçek oyuncu ilerlemesi değildir.

İki APK birer kez üretildi. Aynı sertifika/paket kimlikleri, yapı 20, ZIP/CRC, bölüm JSON'ları ve ARM kütüphaneleri doğrulandı. Gerçek APK kaynakları açıldı: üretimde geliştirici komutları reddediliyor, ayrı DEV paketinde hızlı geçiş/özel güçler çalışıyor; ikisinde de yeni kart/harita/pause akışı var. Eski gezegen scripti ve reddedilen 3D varlıkları APK'larda yok.

## Performans ve sınırlar

Beş dünya × 80 örnek, 20 ısınma frame; 540×960 llvmpipe yazılımsal masaüstü renderer. p95 24,75–35,99 ms; en yüksek tek örnek 96,67 ms. Bunlar duvar saati frame aralıklarıdır, GPU profiler veya Android FPS ölçümü değildir. 16,7 ms bütçesi her örnekte sağlanmadı. Gerçek Android kurulum/input/FPS/ses/titreşim testi yapılmadı; 60 FPS garanti edilmiyor.

APK sürümü 0.13.1 / Android yapı 20. Normal ve DEV paketleri ayrı kayıtlarını ve önceki imzayı korur. Önceki Releases sürümleri korunur. Yayın ve erişim sonucu publication.json dosyasına ayrıca kaydedilir.
