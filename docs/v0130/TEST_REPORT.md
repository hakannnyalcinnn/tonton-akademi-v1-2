# PRİZMA v0.13.0 — kısa test raporu

- Gerçek 3D gezegen: özgün, kıyıları ve yüksekliği şekillendirilmiş yüzey; beş biyom, kaleler, bayraklar, ormanlar/çiçekler, mercanlar, kristal dağlar, gökkuşağı köprüsü, bulutlar, volkan, balonlar ve tekneler. Hazır referans resmi / beş resimli küre kullanılmadı.
- Native parmak sürükleme, 360° dönüş ve arkadaki biyomlar; yüzeye ray seçimi, kilit kontrolü, tek yakınlaşma geçişi ve gerçek 50 düğümlü dünya yolu doğrulandı. Üç sürükleme hareketinin altı zamanlı karesi ile kamera yakınlaşmasının üç karesi kaydedildi.
- Menü hiyerarşisi, büyük Güncel Bölüm aksiyonu, okunabilir alt menü etiketleri; Container/ScrollContainer bölüm önizlemesi ve güçlendiriciler; tek açıklama / boş alanda kapatma; doğru dünya adlı karakterli duraklatma paneli. Splash ve ikon native tooltip katmanları kaldırıldı. Rastgele boş alan dokunuşu yeni overlay oluşturmuyor.

## Çalıştırılan kontroller
- SMOKE başarılı: Match-3, geçerli/geçersiz takas, patlama, yer çekimi, gerçek ana sahne ve temel kayıt.
- TARGETED başarılı: v0130_tests, v0121_ui_tests, casual_ui, r2_helper_tests, r2_gravity_tests, goals_panel_tests, v0123_tests, gameplay2_ui, v012_tests, persistence_probe, quality_tests, v0122_ui_tests.
- v0122 UI bütün 250 bölümün HUD/veri yüklemelerini kontrol etti. Çekirdek/mekanikler/veri Git ağaç hash'leri v0.12.4 ile aynı; 250 kampanya simülasyonu ve tam motor FULL bu UI değişikliği için tekrar çalıştırılmadı.
- Gerçek Godot/Xvfb render: beş gezegen açısı, beş kıvrımlı dünya yolu, dört hedefli önizleme/açıklama, yardım/ayarlar, doğru Lav duraklatma ekranı; 320×568 ve 390×844 pencerelerde gezegen, altı hedefli önizleme, uzun kaydırılabilir yardım ve duraklatma ekranı.
- Önceki küçük-ekran render denemesinde test fixture'ı fiziksel pencere ölçeğini iki kere uyguluyordu; gerçek Godot sanal viewport ölçüsü kullanılarak düzeltildi, son kareler yeniden kontrol edildi. Oyun yerleşiminde bu hata bulunmuyordu.
- İlk geliştirme sırasında tip çıkarımı, cache anahtarı ve instanced renklerin malzemede etkinleşmesi hataları bulundu ve düzeltildi. Son seçilmiş testlerde açık başarısızlık kalmadı; geçmiş runner sonuçları JSON'da korunur.

## Performans ve sınırlar
- Paylaşılan indeksli yüzey, instance renkleriyle az sayıda MultiMesh, tekrar açılışta geometri önbelleği; gölgeler kapalı, boşta gezegen viewport'u çizim yapmaz. Planet ekranında alttaki dünya arka planı çizilmez. Performans kalite modu daha düşük çözünürlük kullanır.
- Son ölçüm: 120 dönen frame / kalite, 25 ısınma frame. Dengeli p95 ~44,17 ms, maksimum ~54,33 ms; performans p95 ~29,99 ms, maksimum ~32,02 ms. Ayrıntı performance.json. İlk mesh oluşturma ~0,13 s; tekrar açma ~0,03 s. TIME_PROCESS eski motor örnekleri içerebildiğinden gerçek tek-frame CPU gecikmesi olarak yorumlanmaz.
- Bunlar llvmpipe yazılımsal masaüstü render ölçümleri. 16,7 ms bütçesi bütün örneklerde sağlanmadı. Android cihaz FPS, GPU uyumluluğu, fiziksel dokunma gecikmesi, kurulum, ses/haptik ve gerçek çentik alanları test edilmedi.
- Görseller referansların küresel kompozisyonunu, ayrı fantastik bölgelerini ve küçük 3D dekorlarını temel alan özgün, optimize edilmiş stilize mesh sanatıdır. Referansın aynı varlıkları/detayları kullanılmadı; nihai estetik kabul kullanıcı cihazı ve geri bildirimine bağlıdır.

## Artefaktlar
APK, imza, ZIP/CRC, tüm paketlenmiş bölüm JSON'ları ve ARM kütüphaneleri; normal/geliştirici kapıları ve gerçekten paketlenmiş gezegen/önizleme kaynakları doğrulandı. İki APK kaynak probe'u geçti. İlk probe sabit 80 ms geçiş varsayımında başarısız oldu; gerçek geçişi 2 saniye sınırla bekleyen kontrol geçti. APK yeniden derlenmedi. Paket kimlikleri ve sertifika korunur. Artefakt ve yayın sonucu ayrı JSON dosyalarında kaydedilir; APK export veya yayın engeli başarı olarak yazılmaz.
