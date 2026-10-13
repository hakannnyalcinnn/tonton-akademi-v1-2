# v0.11.0 kısa test raporu

Üretici 2.0, 250 bölüm ve 5 dünya hazır. İlk 150 bölüm dosyaları Git yedeğiyle byte-identical. Yeni 100 bölümde 20 mekanik kullanılıyor. Kayıt şeması 3 korunur; v10 aktif tahta/puan/yıldız/ayar/envanter geçişi ve tek seferlik iki taç test edildi.

FULL kapsamı: 27 iş ve 102.561 kontrol çağrısı başarılı (ayrı benzersiz test sayısı değildir). 250 varsayılan bölüm kazanıldı, deterministik tekrar ve kayıt roundtrip doğrulandı. Bir eski UI testi kaydırılabilir panelin içindeki butonları aramıyordu; düzeltilip kalan kapsam tamamlandı. Başarılı testlerin tekrar kullanılmasının girdileri ve değişmeyen runtime SHA'sı `resume-proof.json` ile kaydedildi. Başlangıçtaki JSON sürüm/tür doğrulama hatası da giderildi.

Başlangıçta beş otomatik strateji karşılaştırıldı. Son üç-seed hedef/lookahead karşılaştırması: Bulut 292/300, Lav 293/300. Her bölümün seçilmiş stratejisi 3/3 kazandı; diğer strateji kayıpları mantık hatası değildir. İnsan testleri ve daha geniş seed'ler gerekir. Bulut hamleleri 8–21, Lav 8–24; eski 150 bütçe değişmedi. Sayısal rapor `balance.csv`.

Godot --profiling / Xvfb llvmpipe, 540×960: 38 hamle / 6.074 kare; son 2.048 kare ortalama 16,74 ms, p95 19,87 ms, max 44,03 ms. Takas animasyonu ortalama 185,79 ms; işlem CPU p95 7,80 ms. Mantık olayı sıfır. İki render thread ile ortalama 23,28 ms görüldü; aynı sahnede eski/yeni shader karşılaştırması ve dört-thread kontrolü yazılımsal render sınırını gösterdi. Bu Android 60 FPS garantisi değildir.

APK: 0.11.0 / code 11; ZIP/veri/ARM kitaplıkları/SDK 24–36/paket ve önceki sertifika doğrulandı. SHA256: `6beb6fbbfa1d9725a429383697ba91704751ac6abbcf867b495f5ac491884b85`.

Test edilmedi: gerçek Android kurulum/güncelleme, GPU/FPS/input gecikmesi, ses/titreşim ve insan zorluk/zevk değerlendirmesi. Bilinen açık mantık/derleme hatası yok; bu noktalar test APK'sıyla doğrulanmalıdır.
