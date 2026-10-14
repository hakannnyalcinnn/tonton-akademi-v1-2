# PRİZMA v0.12.0

- Korunan yapı: 250 bölüm, 5 dünya, 20 mekanik, mevcut Match-3/özel güç/fırtına/dalga ve oyuncu kayıtları. İlk 150 bölüm dosyası geri dönüş noktasıyla byte-identical. Yeni hedefler ayrı `adventure-levels.json` katmanıyla eklenir.
- Sunum: kavisli renk bombası bağları, daha güçlü roket çizgileri; Gökkuşağı Yıldızı mevcut prizma bombasıdır, renk bombasından farklı alan temizler. Fırtına gösterimi en fazla 12/12; gerçek fazla enerji korunur.
- Akış: hedefli önizleme → OYNA → kısa Pırıl geçişi; yalnızca sahip olunan ücretsiz güç tüketilir. İptalde tüketim yok. Kalan hedefli kaybetme ve dünyaya özgü başarı ekranları.
- Macera: özgün Pırıl ve 5 canlı; ilerlemeyle renklenen haritalar, 15 kurtarma / 10 aşamalı boss / 10 hazine, kısa sandık açılışı, özgün sesler, günlük görevler ve koleksiyon. Ödüller bir kez verilir.
- Geliştirici: ayrı `.match3.dev` uygulaması ve dev kayıt dosyası; 1–250 atlama, sonuç, hamle, güç/iki bomba, seed/hız ve mekanik laboratuvarı. Normal APK'nın gerçek çıkarılmış kaynakları komutları reddetti.

## Test ve sınırlar

FULL kapsamı tamamlandı; kesilen eski UI varsayımı ayrı testle düzeltildi, başarılı çekirdek kısmı log ve değişmemiş test gövdesiyle korundu. 20 mekanik, özel güçler, yeni amaç/ödül/UI, kayıt ve 250 varsayılan bölüm deterministik tekrar/roundtrip kontrolleri geçti. Bulunan gerçek JSON sayısal tür kayması ve bozulan öğretici roket yerleşimi düzeltildi. Geçmiş başarısız sonuçlar `tests.json` içinde saklanır; hiçbiri geriye dönük başarılı yapılmadı.

Yeni amaçlı 75 örnekten 74'ü kazanıldı. 50. bölümün kalan seed'i beş başka stratejiyle 5/5, üç ek seed'de 3/3 kazanıldı; hedef veya hamle keyfî değiştirilmedi. İnsan testleri ve bütün seed'ler için çözüm garantisi yoktur.

24 temiz masaüstü yazılım-renderer senaryosu: dengeli ortalama 17,38 ms (en kötü senaryo p95 30,35 ms), performans 17,06 ms (p95 27,99 ms). 60 FPS her karede doğrulanmış değildir. Gerçek Android cihaz yok; telefon FPS/input/ses/titreşim/ısınma ve uygulama güncelleme kurulumu test edilmedi. Günlük görevler çevrimdışı cihaz saatiyle çalışır; kusursuz saat güvenliği iddia edilmez.

İki APK oluşturuldu ve aynı sertifika, paket/sürüm, CRC, bütün JSON verileri ve ARM kitaplıkları doğrulandı. `apk-proof.json` hash/profil ayrımını içerir. APK'dan çıkarılmış gerçek oyun kaynakları ayrıca çalıştırıldı; bu Android cihaz testi yerine sunulmaz.

Bu sürüm test sürümüdür. Sonraki aşamaya geçilmez.
