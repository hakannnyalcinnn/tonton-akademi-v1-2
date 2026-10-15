# PRİZMA v0.14.0 — Kısa test ve kapsam raporu

## Tamamlananlar
- Merkezi ekonomi: yıldız başına 10/15/25 Kristal, her on bölümde +50, dünya sonunda +250. Tekrar oynama yalnızca yeni yıldız farkını kazandırır; kilometre taşı ve dünya ödülü bir kez verilir.
- Beş can, 30 dakikada yenilenme, sıfır canda giriş engeli, ilk 10 bölüm için öğretici koruması ve geliştiricide sınırsız can.
- UTC takvim günüyle yedi günlük giriş; günlük üç açılmış-mekanik uyumlu görev; gerçek olaylardan ilerleme; roket/prizma/can mağazası; mevcut beş karakter; tek seferlik başarımlar; bölüm sonu gerçek ödül özeti.
- Kayıt şeması 4: eski ham kayıt `.pre-v014` arşivlenir. Bakiye, envanter, ilerleme ve sonuçlar birlikte atomik kaydedilir; yazma hatası işlemi geri alır. Animasyon ödülün doğruluğunu etkilemez.
- 251–500 paketleri ve beş özgün dünya: Ayışığı Korusu, Mercan Sarayı, Yıldız Çölü, Aurora Vadisi, Zümrüt Harabeleri. İlk 250 bölümün dosyaları ve çekirdek motor değişmedi.
- 500 yayımlanmış bölüm/10 dünya; veri odaklı 10.000 bölüm/200 dünya kapasitesi. Tanım paketleri en çok üç girişlik LRU ile ihtiyaç halinde yüklenir. Hazır olmayan 501+ bölümler gösterilmez.

## Gerçekleştirilen testler
- SMOKE: gerçek ana sahne, Match-3, geçerli/geçersiz takas, otomatik çözüm, yer çekimi ve disk kayıt kontrolü başarılı.
- Ekonomi: ödül/alışveriş/olay tekrarı, yetersiz bakiye, gerçek envanter, can zamanlayıcısı, UTC gün/geri saat, v3 disk dönüşümü, sıfır can, eski yazıcı yarışı, yazma hatasında geri alma, 300. bölüm dünya ödülü ve kapalı IAP kontrolleri başarılı.
- Ekonomi UI: üç ekran boyutu, gerçek satın alma/ödül butonları, can admission ve tekrar sonuç işleme başarılı.
- Kampanya: 500 tanım yükleme; 250 yeni eşleşmesiz ve geçerli hamleli başlangıç; 250 varsayılan-seed gerçek motor kazanma izinin son hamle bütçesiyle tekrarı başarılı. İlk taramada 244/250; altı riskli aday alternatif strateji/yerleşimle incelendi ve tamamı düzeltildi. Son kabulde sıfır çözümlenmemiş aday/engine guard hatası.
- Hedefli eski kurtarma/boss, v0.12.1 UI, v0.13.1 harita/UI, kayıt devamlılığı ve generator veri testleri başarılı. Python generator testleri: 5 başarılı.
- Gerçek Godot Compatibility/llvmpipe render: yedi günlük ödüller, görevler, mağaza, koleksiyon, başarımlar, sonuç ve beş yeni dünya; ayrıca 320×568 mağaza görünümü kontrol edildi. Görüntüler ayrı test profiline ait.
- Düzeltilen doğrulama sorunları: Godot açık tür tanımı; headless dummy renderer texture iş parçacığı; JSON tamsayı eşitliği; eski APK betiğinin sabit 250 bölüm beklentisi. Son ilgili kontroller başarılı; geçmiş başarısız çalıştırmalar başarı olarak sayılmadı.
- Ayrıntılı kısa sonuçlar ve kaynak parmak izleri: `test-summary.json`. Bölüm bütçeleri: `level-balance.json`. Tekrar üretilebilir izler: `tests/fixtures/v0140-witnesses.json`.

## Sınırlar
- Fiziksel Android cihaz yok: cihaz FPS, kurulum/üzerine güncelleme, dokunma, ses ve titreşim doğrulanmadı. Masaüstü Godot görüntüleri cihaz performansı kanıtı değildir.
- Tamamen çevrimdışı saat koruması geri saat ve oturum içi büyük sıçramaları sınırlar; yeniden başlatmayla ileri saat manipülasyonunu kesin engelleyemez. Yetkili sunucu zamanı yoktur.
- Varsayılan seed kazanma izleri bütün seedlerin kazanılabilirliğini veya insan zorluk dengesini kanıtlamaz; gerçek oyuncu testleri gerekir.
- Koleksiyon yalnızca beş mevcut karakter görselini kullanır. Çalışmayan karıştırma/tek hücre gücü satılmaz. Gerçek para tahsilatı ve reklamlar kapalıdır.
- Bu sürümde çekirdek motor değişmediği için devasa FULL simülasyon tekrarı yapılmadı; kritik ekonomi/kayıt, bütün yeni bölümler, ilgili eski akışlar ve final APK kontrolleri seçildi.

## APK ve yayın
Normal ve geliştirici APK paketleri ayrıdır; mevcut sertifika korunur. Nihai dosya SHA256 ve erişim kanıtı GitHub Release varlıklarıyla birlikte sunulur. APK kaynak probu fiziksel Android çalıştırması değildir.

Final artefakt kontrolü: iki APK da üretildi; v0.14.0 / Android versionCode 24, aynı mevcut sertifika, normal/dev ayrı paket kimliği, ZIP CRC, tüm bölüm verileri ve iki ARM ABI doğrulandı. APK içinden çıkarılan gerçek kaynaklarla üretim kapısı, geliştirici araçları/sınırsız can, mağaza ve 500 bölüm/10 dünya akışları başarılı. Bu kontrol masaüstü Godot üzerindedir.
