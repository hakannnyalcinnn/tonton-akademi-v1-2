# PRİZMA v0.13.4 — Harita üst boşluk düzeltmesi

Kök neden: güvenli ekran alanı üstten daraldığında harita zemini yalnızca Stage boyutunu kaplıyordu. Yol çizimi dışarı taşabildiği halde zemin taşmıyor, çentik/sistem alanı payında kök ekranın koyu temizleme rengi görünüyordu.

Sadece map_terrain.gd değişti: arka plan görünür viewport'u tamamen kapsar. Dokuya yerel başlangıç koordinatı eklenir; yol katmanı ters ofsetle aynı yerde tutulur. Başlık, düğmeler, kaydırma, bölüm noktaları, dünya seçimi, tahta, veri ve kayıt kodu değişmedi. Sürüm 0.13.4, Android yapı 23.

- Gerçek Godot 4.6.3 render: 540×960, 390×844, 540×1170, 540×1200; üst güvenli alan 0/36/56 px olarak simüle edildi. Önce/sonra görüntüsü gözle incelendi.
- Hedefli yeni test: 5 dünya × 4 oran, 100 kontrol. Zemin viewport'u dolduruyor; kontroller güvenli alanda; yol ve bölüm koordinatları korunuyor; doku başlangıç fazı doğru.
- Mevcut v0133 UI testi 377 kontrol ve kısa SMOKE başarılı. Eski testteki 'zemin Stage boyutuyla aynı' varsayımı, tam viewport kapsamını doğrulayacak şekilde güncellendi; kontrol kaldırılmadı.
- 390×844 örneğinde üst 36 px şeritte eski kök arka plan rengini taşıyan 11.674 piksel varken düzeltmeden sonra bu sayı 0. Doğal koyu yaprak/gölge pikselleri boş alan sayılmadı.
- Görünüm dışındaki oyun motoru, bölüm verisi ve kayıt kodu Git karşılaştırmasıyla değişmedi. FULL/kampanya simülasyonu yapılmadı.

Fiziksel Android cihazda kurulum/çentik/FPS testi yapılmadı. Bunlar gerçek Godot render'ında simüle edilen güvenli ekran alanı sonuçlarıdır. Normal/DEV APK kimlik, önceki imza, ZIP, ARM ve bölüm verisi bütünlüğü doğrulaması teslim aşamasında kaydedilir.
