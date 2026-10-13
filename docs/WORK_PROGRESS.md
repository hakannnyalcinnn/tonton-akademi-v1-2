# Güncel çalışma

Görev: PRİZMA v0.11.0 — üretici 2.0, 250 bölüm ve 5 dünya.

- Geri dönüş: backup/before-v0.11.0, doğrulanmış yerel Git bundle; başlangıç SMOKE başarılı.
- A–C tamamlandı: sürümlü manifest/üretici, benzerlik/zorluk, beş otomatik oyuncu, iki özgün dünya, 151–250 ve iki aşamalı finaller/tek seferlik taçlar. İlk 150 dosya yedekle byte-identical.
- Testler: SMOKE, üretici/palet, bütün yeni başlangıçlar, hedef paneli, eski harita/finaller ve v10 kayıt uyumluluğu geçti. Son üç-seed karşılaştırması: Bulut 292/300, Lav 293/300; her bölümde seçilen strateji 3/3. Bu insan dengesi/garantili çözüm iddiası değildir.
- Render: 38 hamle/4.495 kare, sıfır mantık olayı. llvmpipe 2 thread kare bütçesini aştı; aynı sahnede 4 thread eski/yeni shader ~16,67 ms. Son 4-thread action profili: ortalama 16,74 ms / p95 19,87 ms; 38 hamle, 6.074 kare.
- Final: FULL kapsamı 27 iş / 102.561 kontrol çağrısı; 250 varsayılan bölüm deterministik kayıt/tekrar ile geçti. Eski bir UI testi düzeltildi; aynı girdili başarılı testler kanıtla korundu.
- APK 0.11.0 / code 11 üretildi; aynı sertifika, ZIP/veri/ARM/paket doğrulandı. SHA256: 6beb6fbbfa1d9725a429383697ba91704751ac6abbcf867b495f5ac491884b85.
- Kalan: GitHub/Release yayını. Rapor: docs/v011/REPORT.md; küçük ZIP ve iki ekran görüntüsü hazır.
- Gerçek Android cihaz yok; telefon FPS/input/ses/titreşim/kurulum doğrulanmadı.
