# PRİZMA v0.12.1 UI test sürümü

- Doğrudan aktif dünya haritasında açılış; 50 dairesel düğüm, yıldız/kilit/özel bölüm göstergeleri; onluk aralıklar ve ayrı ana menü kaldırıldı. Gerçek bakiye ve beş ikonlu gezinme hedefi. Sahte can/mağaza yok.
- Ortak özgün UITheme, parlak SVG eylemleri ve kompakt hedef/ikonlu stok kartı. İptalde tüketim yok; OYNA'da yalnızca bir stok tüketilir. Kayıtlı oyun aynı snapshot ile sürer, ikinci stok tüketilmez. Eski öğretici takasını bozan güç yerleşimi UI başlangıcında korunur.
- Büyük sabit hamle sayısı, dört ekran oranı, çakışmayan alt öğretici, yıldız/hedef/karakter içeren ortak sonuç kartları. Sonraki ve tekrar akışı önizlemeden geçer. Geçiş yaklaşık 0,70 s; iptal edilmiş eski geçiş yeni bölümü başlatamaz.
- Pırıl, 250 bölüm, beş dünya, 20 mekanik, bütün motor/bölüm verileri ve eski kayıt sistemi korundu. İlgili kaynaklar Git yedeğiyle byte-identical; gereksiz tüm kampanya simülasyonu tekrarlanmadı.

## Kanıt

SMOKE ve final UI/kayıt regresyonu geçti: 1,2,10,25,50,75,100,150,200,250 ve kurtarma/boss örnekleri × 16:9,18:9,19.5:9,20:9. Gerçek GUI sürükleme, görünür hamle, hedef sayaçları, stok, iptal/geçiş, diskten devam, dünya ödülleri ve üretim kapısı testleri yapıldı. Eski piksel/başlık varsayımları yeni gerçek global sınır ve akışla güncellendi. Ayrıntılar tests.json/log SHA256.

Gerçek Godot 540×1200 render görüntüleri 1080×2400 eşdeğer tasarım ölçeğindedir; başarı/başarısızlık ekranları izole test profilinde kontrollü UI senaryolarıdır. HTML veya statik maket bitmiş oyun diye sunulmadı.

## Performans / sınırlar

Godot profiler / Xvfb llvmpipe masaüstü ölçümü. Arka planlar iş parçacığında yüklenir; en fazla beş doku ve paylaşılan ikon/stil önbelleği. Harita oluşturma CPU 54–67 ms'den yaklaşık 18–23 ms'ye düştü. Son ölçüm ortalama kare 18,03 ms, p95 24,04 ms, p99 34,14 ms. Her kare 16,7 ms garantisi yoktur. Fiziksel Android FPS/dokunma/ses/titreşim ve güncelleme kurulumu test edilmedi. Yeni APK'lar test cihazında değerlendirilmelidir.

Normal ve geliştirici APK ayrı kimlik/kayıt kullanır. Paketler, sürüm kodu 13, aynı sertifika, ZIP/veri/ARM bütünlüğü ve çıkarılmış gerçek APK kaynakları doğrulandı. Mevcut oyun kaydı silinmez. Sonraki aşamaya geçilmez.
