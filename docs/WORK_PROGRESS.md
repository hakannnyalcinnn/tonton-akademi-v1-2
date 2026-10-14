# Güncel çalışma

v0.12.4 geliştirme ve yayın tamamlandı. https://github.com/hakannnyalcinnn/tonton-akademi-v1-2/releases/tag/v0.12.4 . CI 38578927103 Success; iki APK Range GET 206/doğru boyut/ZIP başlangıcı ile erişilebilir. Yayın kaydı docs/v0124/publication.json. Geri dönüş: backup/before-v0.12.4.
Altı görev: kaydırılabilir yardım/ayarlar/tek açıklama, beş Bézier harita, merkez tahta ve bitişik hedefler, kademeli 0,72 s enerji/varış sesi, görünür 12/12 Fırtına/0,48 s dalga, gruplanmış ses/kalite ayarları koruması.
İlgili testler ve gerçek render/kare dizisi geçti; 250 bölüm verisi/hamle/denge ve motor ağaçları değişmedi. Normal/dev APK birer kez üretildi, aynı kimlik/imza/kod17/ZIP/veri/ABI ve APK içi yeni UI/efekt kapıları doğrulandı. Eski export assertion'ı nedeniyle normal dosya tekrar derlenmedi.
Fiziksel Android ölçümü yok; final masaüstü tepe 62,17 ms, 60 FPS doğrulanmadı. Ayrıntı docs/v0124/TEST_REPORT.md. Bu sürümden sonra yeni aşamaya geçilmez.

## v0.13.0 — devam eden çalışma
- Geri dönüş: backup/before-v0.13.0 (v0.12.4 yayımlanmış kaynak).
- Gerçek 3D, özgün geometrili beş biyomlu gezegen; toplu çizim, native parmak döndürme, yüzey seçimi ve kamera yakınlaşması eklendi.
- Mevcut 50 düğümlü dünya yolları korundu; dünyalar/güncel bölüm hiyerarşisi ve alt menü etiketleri düzeltildi.
- Container tabanlı bölüm önizlemesi ve dünyaya uygun duraklatma paneli eklendi; eski splash ve native tooltip katmanları kaldırıldı.
- İlk SMOKE ve hedefli eski UI/drag/helper/gravity kontrolleri geçti. Görsel kalite düzeltmeleri, gezegen giriş testleri ve final render/perf/APK doğrulaması sürüyor.

- v0.13.0 final: native 360° / beş ray seçimi / kilit / yakınlaşma / tek açıklama testleri geçti; eski UI/helper/Storm/kurtarma-boss/kayıt ve 250 HUD yüklemeleri başarılı.
- Beş gezegen/bölüm yolu, hareketli kare dizileri, 320×568 ve 390×844 gerçek render'ları kontrol edildi. Son llvmpipe p95: dengeli 44,17 ms, performans 29,99 ms; cihaz FPS doğrulanmadı.
- İki APK v0.13.0/code18 tek sefer üretildi, aynı sertifika/paket ve ZIP/data/ARM doğrulandı. Paketlenmiş kaynak probe'ları normal/dev geçti; sabit 80 ms fixture beklemesi gerçek geçiş koşuluna dönüştürüldü, APK yeniden derlenmedi.
- v0.13.0 yayımlandı: kaynak ad5b8e9, artefakt 1bf2d38c3919a0c50e0b5f457576948c13d3537c. CI 38596989187 Success; iki APK 206 Range GET ile 4 bayt / doğru toplam boyut / APK-ZIP başlangıcı doğrulandı. Yayın: https://github.com/hakannnyalcinnn/tonton-akademi-v1-2/releases/tag/v0.13.0
- Bu aşama tamamlandı; yeni geliştirmeye geçilmedi. Fiziksel Android performans/görsel kabulü kullanıcı cihazında bekliyor.

## v0.13.0 yapı 19 — işlevsel gezegen sürümü
- Daha önce yayımlanan v0.13.0 gerçek 3D gezegeni temel alındı; sanat prototipleri ayrı Git dallarında korundu ve uygulamaya alınmadı.
- Eksik duraklatma ikon satırı düzeltildi: büyük Devam Et + Yeniden Oyna/Ayarlar/Harita. Paket kimlikleri, imza ve oyun sürüm adı korunup Android yapı kodu 19 yapıldı.
- SMOKE, v0130_tests ve persistence_probe geçti; 15 ek dönüş ataleti/Android geri bildirimi simülasyonu/kazanma kaydı/disk yükleme/doğrudan sonraki bölüm kontrolü geçti. İlk ek fixture tek frame bekleyerek erken kontrol etti; gerçek transition koşulunu bekleyecek şekilde düzeltildi.
- 320×568 ve 390×844 gerçek Godot render kontrolü geçti. Android fiziksel cihaz testi yok. Eski v0.13.0 yayını korunacak; yeni APK teslimatı v0.13.0-r2 etiketi altında hazırlanıyor.

- v0.13.0 yapı 19 final: iki APK aynı kimlik/imza, ZIP/veri/ABI ve gerçek APK kaynak probe kontrollerinden geçti. GitHub doğrudan upload 401 aldı; aynı komut tekrarlanmadı. Hazır APK artefaktları Actions ile yeniden derlemeden yayımlandı.
- Yayın https://github.com/hakannnyalcinnn/tonton-akademi-v1-2/releases/tag/v0.13.0-r2 ; Actions 38627411307 success. İki indirme bağlantısı 206 Range/doğru boyut/APK ZIP başlangıcıyla doğrulandı. Eski v0.13.0 yayını korunuyor. Fiziksel cihaz testi yok. Aşama tamamlandı, yeni geliştirmeye geçilmedi.

## v0.13.1 — Yaşayan Macera Haritası
- Geri dönüş backup/before-v0.13.1; dal prizma-release-v0.13.1. Gezegen aktif akıştan çıkarıldı, Android paketinden eski gezegen scripti hariç tutuluyor; sanat çalışmaları eski dallarda korunuyor.
- Mevcut arka planlar üzerinde geniş Bézier S yolu, 50 noktalı tek dikey harita, görünür alana sınırlı canlı 2D dekorlar, güncel bölüm odağı, beş görselli dünya kartı ve dört otomatik dünya geçişi eklendi. Kompakt pause/ikonlar, sürüm yazısı ve başlık kontrastı düzenlendi.
- Bahçe önce gerçek render ile kontrol edildi; ardından beş dünya, 320×568/390×844 kart/yardım, kapı, pause ve varış görüntüleri alındı. Dikiş ve ters resim sorunu giderildi; düz yönde örtüşen arka plan kullanılıyor.
- SMOKE; 49 v0131 kontrolü; persistence_probe, goals_panel_tests, r2_gravity_tests, güncellenmiş v0121_ui_tests ve v012_tests geçti. Eski 3D seçici kontrolü yeni beş kart/gezegensiz akışa uyarlandı; test atlanmadı. İlk S genişliği testi yalnız düğümleri örnekliyordu; gerçek Bézier uçlarını içeren baked yol kontrolüyle düzeltildi.
- Çekirdek/mekanik/veri Git ağaçları aynı. 250 bölüm yeniden üretilmedi veya geniş simülasyona sokulmadı. Masaüstü llvmpipe p95 24,75–35,99 ms; Android 60 FPS doğrulanmadı.
- İki imzalı APK ve v0.13.1 yayını hazırlanıyor; sonraki sürüme geçilmeyecek.
