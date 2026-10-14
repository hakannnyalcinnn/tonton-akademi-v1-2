# PRİZMA v0.13.3 — Harita/dünya arayüzü final paketi

- Tek tam ekran dünya zemini: harita ve sabit menüler artık ayrı resimler kullanmıyor. Beş temaya özgün sabit perspektifli zemin dokuları; sert dikdörtgen sınır/ufuk sıçraması yok. Yol menüler arkasında devam ediyor, plank çizgileri yerine sade toprak/taş yüzey ve küçük kenar detayları kullanıyor.
- Mevcut S yolu, 250 bölüm noktası, yıldız/kilit/aktif bölüm ve güncel bölüme odaklanma korunuyor. Dekorlar azaltılıp dengelendi; hareket ayarları korunuyor.
- DÜNYALAR butonu/başlığı/alt menüde özgün pastel küre simgesi. Güncel bölüme dönüş 404×54. Dünya kartlarında tema çerçevesi ve KEŞFET rengi, seçili dünya göstergesi, mevcut önizleme/ad/aralık/tamamlanma/ilerleme bilgisi.

## Doğrulama

- v0133_ui_tests: 377 kontrol; dört ekran boyutu, beş dünya, ortak tuval ve aynı kaydırma koordinatı, menü simgesi, yol renklerinin shader izolasyonu, kart sınırları/tek seçili dünya ve sonuçların korunması.
- v0131_tests: 49 mevcut akış kontrolü; kilitler, yıldızlar, native dokunma kaydırması, beş dünya, dört dünya sınırı, kayıt yükleme ve Android geri/duraklatma olayları. persistence_probe ve SMOKE başarılı.
- Gerçek Godot 4.6.3 render: beş dünyanın ilk/orta/son noktası; harita ve dünya listesi 540×960, 540×1170, 540×1200, 320×568. Görseller gözle incelendi. İlk render incelemesinde başlık simgesinin kaynak boyutuna büyümesi ve yolun shader ile beyazlaşması bulundu; ikisi düzeltildi ve son render tekrar incelendi.
- 100 px dünya kaydırmasıyla 464.400 örtüşen piksel karşılaştırıldı: maksimum kanal farkı 1/255. Bu zemin/yolun üst/alt menü konumlarında da aynı sahne koordinatında çizildiğini gösterir; sanat kalitesinin otomatik ispatı değildir.
- scripts/core, data, oyun tahtası, HUD ve hedef paneli geri dönüş noktasıyla aynı; hedef/hamle/oynanış/kayıt mantığı değişmedi. Geniş kampanya simülasyonu/FULL çalıştırılmadı.

## Sınırlar

Gerçek Android cihaz yok: telefon kurulumu, fiziksel dokunma gecikmesi, ses/titreşim ve telefon FPS testi yapılmadı. Beş dünya × 80 masaüstü frame aralığı, 20 ısınma frame; llvmpipe/Compatibility/LP_NUM_THREADS=4; ayrıntılar performance.json. Bunlar GPU profiler veya Android 60 FPS doğrulaması değildir.

Normal/DEV APK birer kez üretildi ve doğrulandı: sürüm 0.13.3, yapı 22; normal com.prizma.renklerinuyanisi.match3, DEV aynı kimliğin .dev eki. Önceki sertifika, ZIP/CRC, ARM kütüphaneleri ve bütün bölüm JSON baytları doğrulandı. APK içindeki gerçek kaynaklarla beş zemin varlığı, ortak harita tuvali/küre simgesi ve normal/geliştirici özellik kapıları doğrulandı. Yayın ve erişim sonucu publication.json dosyasına kaydedilir.
