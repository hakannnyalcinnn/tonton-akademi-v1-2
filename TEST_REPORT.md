# PRİZMA v0.13.2 — UI kalite kontrolü

Tam ekran harita zemini: sağ/sol dikdörtgen sınırları kaldırıldı; doku oranı korunarak yumuşak örtüşmeyle döşeniyor. Yol ve 250 bölüm korunuyor. Kaydırma alanı sabit alt butonların üstünde bitiyor. Deterministik dekor türü/ölçek/konum çeşitleri ve hafif katman hareketi var. Aktif bölüm 100 px ve sakin parlak halka kullanıyor; geometrisi zıplamıyor. Geçit tabelası portalın parçası; tamamlanmış dünyada enerji açılışı oynuyor.

Dünya kartları 156 px; mevcut görseller/ad/aralık/sayaç/ilerleme korundu, tek KEŞFET işlemi gerçek 40 px butonla sunuluyor. HUD hedefleri ayırdıktan sonra kalan hayali hedef yüksekliği düzeltildi; HUD/hedef/tahta bitişik bir blok olarak ortalanıyor, fırtına ve yardımcı kontroller alt güvenli alanda. Hamle ve geliştirici ayrımı korunuyor.

## Başarılı kontroller

- SMOKE: Match-3, takas/geri dönüş, otomatik çözümleme, yer çekimi, açılış ve kayıt.
- v0131_tests: 49 kontrol; beş dünya/kilitler, yerel dokunma kaydırması, yıldızlar, dört dünya geçişi, kayıt yükleme ve geri/duraklatma.
- persistence_probe; goals_panel_tests; v0121_ui_tests.
- v0132_tests: 840 kontrol. Beş dünya × 50 bölüm × üç ekran oranı; bütün noktalar alt sabit butonlardan uzak görünür alana kaydırılabiliyor. Tam genişlik, aktif bölüm, kompakt kartlar, HUD/hedef/tahta ayrımı ve dokunma dönüşümleri.
- Gerçek Godot 4.6.3 render: her dünyanın ilk/orta/son noktası; dünya kartları ve oyun ekranı 540×960, 540×1170, 540×1200 (16:9, 19.5:9, 20:9). 15 harita karesi gözle incelendi. Portal açılışı iki zamanlı render karesiyle kaydedildi.
- Korunan scripts/core ve data dizinleri geri dönüş noktasıyla birebir aynı. Bölüm hedefi/hamle/motor/kayıt kodu değişmedi.

İlk denemelerde native Skin adı çakışması, doku tekrar birleşimi, eski HUD yüksekliği ve kaydırma çubuğunun genişlik talebi bulundu ve düzeltildi. UI test fixture'ında aktif oyun temizliği ve başarı çıktı biçimi düzeltildi; 840 kontrol finalde başarılı. Açık başarısız hedefli kontrol yok.

## Performans ve test sınırları

Beş dünya × 80 gerçek masaüstü frame aralığı, 20 ısınma frame; Compatibility/llvmpipe, LP_NUM_THREADS=4. p95 23,01–28,00 ms, en yüksek 33,94 ms. GPU profiler veya Android FPS ölçümü değildir; 16,7 ms bütçesi her karede sağlanmadı. Gerçek telefon kurulum, dokunma gecikmesi, ses/titreşim ve Android 60 FPS doğrulanmadı. Harita mevcut sanatın döşenmesini kullanıyor; uzun haritalarda tekrar eden çevre motifleri görülebilir. Yeni sanat dünyası/oyun mekaniği yok.

Normal ve DEV APK birer kez üretildi. Yapı 21, sürüm 0.13.2; normal `com.prizma.renklerinuyanisi.match3`, DEV `.dev`; önceki SHA256 sertifika korunuyor. ZIP/CRC, ARM kütüphaneleri ve bütün bölüm JSON baytları doğrulandı. Gerçek APK kaynaklarıyla üretimde geliştirici mutasyonlarının reddi ve DEV hızlı geçiş/özel güç/yenilgi kontrolü başarılı. Kapsam UI olduğundan geniş bölüm simülasyonu/FULL çalıştırılmadı.
