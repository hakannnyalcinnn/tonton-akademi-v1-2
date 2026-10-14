# PRİZMA v0.12.2 — HUD düzeltmesi

Üç katmanlı ortak Godot HUD: ince bölüm/dünya başlığı ve güvenli duraklatma; ayrı 38 punto hamle / kompakt gerçek eşikli yıldız çubuğu / noktayla ayrılmış küçük puan; gerçek ikon ve sayaç içeren küçük hedef kartları. Büyük tek krem panel kaldırıldı. Uzun Türkçe başlıklar üç noktayla kısalır; çok büyük puan hamleden önce küçülür. Hamle değişimi kısa ölçek vurgusu, 5/3/1 uyarıları ve kazanılan yıldız parlaması sunum katmanında çalışır.

106 karşılaştırması: aynı 540×1200 ekran, aynı başlangıç seed/tahta, 9 hamle, 3210 puan ve 0/75 + 0/1 hedefleri. HUD 215 → 176 (yaklaşık %18 daha kısa); 56×56 hücreler / 476×536 tahta değişmedi; HUD–tahta mantıksal boşluğu 12. Tek hedeften altı hedefe 1–2 satır, 7–8 hedefte dört sütunlu iki satır; daha fazlası sayısı görünen kaydırma alanı. Uzun ekranlarda kristaller gerilmez; kalan çevre alanı özgün arka planla dolar.

## Doğrulama

Final SMOKE ve TARGETED başarılı: 250 bölümün gerçek HUD'u ve merkezi hedef/hamle/yıldız verileri yüklendi; kampanya çözüm simülasyonları tekrarlanmadı. 1,2,25,49,62,106,150,200,250 ve kurtarma/boss 12/35; 1080×1920,1080×2160,1080×2340,1080×2400,720×1600; çentik safe area, bütün hedeflerin sınırları, 1–6 hedef, sekiz hedefli 250 finali, 9+ kaydırma, uzun başlık, çok büyük puan, son hamle/öğretici/kombo, gerçek geçerli-geçersiz sürükleme ve animasyon sonuna kadar sonuç bekleme. Diskten devam, stok, üretim kapısı, eski hedef vurguları, kurtarma/boss, ödüller ve temel efekt/yer çekimi entegrasyonları geçti. Ayrıntılar tests.json ve SHA256 log kayıtları.

İlk testte sekiz hedefin son ikisi görünmüyordu; dört sütunlu düzenle düzeltildi. Yeni container ilk yerleşmeden önce sıfır genişlikli hit rect üretiyordu; başlangıç boyutu verilerek giderildi. Önceki sabit 240 px hedef merkezi ve yerel koordinat varsayımları gerçek container genişliği/global sınırlar ile güncellendi. Başarısız geçmiş testler build/test-policy altında saklandı; finalde açık başarısızlık yok.

Gerçek Godot/Mesa render'ları capture testindeki izole profilden alınmıştır; HTML maket veya fiziksel Android çekimi değildir. Temsilci bölümler, dört ekran oranı, son hamle/hedef açıklaması ve dünya finalleri görsel olarak incelendi. Oyun motoru, tüm bölüm/mekanik verileri, tahta dokunmatik kodu, ses, kayıt ve Pırıl atlası Git yedeğiyle aynıdır.

## Cihaz sınırları / teslimat

Fiziksel Android erişimi yok: telefon FPS, dokunma gecikmesi, çentik/sistem çubuğunun cihaz davranışı ve eski sürüm üzerine kurulum ölçülmedi. 60 FPS garantisi verilmez. Normal/dev APK 0.12.2 / kod 14; eski paket ve sertifika korunur, dev ayrı kayıt kimliği kullanır. Final APK imza/bütünlük/veri/kaynak ve yayımlanan bağlantı doğrulamaları ayrıca apk-proof.json / publication.json dosyalarına kaydedilir. Yeni mekanik, dünya veya bölüm eklenmedi. Bu aşamadan sonra durulur.
