# PRİZMA v0.10.0 — Gökkuşağı Kanyonu

v0.9.0 kaynak sürümü `29b3e59` üzerinden geliştirildi. Geri dönüş etiketi: `backup/before-v0.10.0`; doğrulanmış Git bundle bulut araç dizininde tutuluyor. Proje yeniden oluşturulmadı. İlk 100 bölümün beş veri dosyası byte düzeyinde değiştirilmedi.

## Tamamlanan kapsam

- Merkezi MatchDetector bütün komşu takasları, çift renk/köprü alanlarını, hareketli özel güçleri ve kombinasyonlarını denetliyor. Sorgular bağımsız hücre dizisinde çalışıyor; tahta/RNG/puan/kayıt değişmiyor. Önce gerekli yerel çizgi testi, ardından gerektiğinde aynı esnek eşleşme çözümleyicisi kullanılıyor. İzole özel güç etkinleştirmesi de hamle sayılıyor.
- Gerçek hamlesizlikte ücretsiz karıştırma: kristal kimlikleri, renk envanteri, hareketli katmanlar ve sabit engeller korunuyor. Hazır eşleşme yok ve geçerli eylem var koşulları birlikte doğrulanıyor. Hamle/puan/hedef/enerji tüketilmiyor. Bildirim ikinci hamle kontrolüyle artık kaybolmuyor. Kaydedilmiş hamlesiz tahta açılışta kurtarılıyor.
- Karıştırma kurtarması sınırlı: 24 seed destekli yapıcı deneme, ardından mevcut envanteri koruyan en fazla 200.000 düğümlük arama. Matematiksel olarak mümkün düzen bulunamazsa tanılama kaydı ve açık yeniden deneme/ana menü ekranı açılıyor; yenilgi, hedef değişikliği veya kristal çoğaltma yapılmıyor. Geçerli hamle olması kalan hedeflerin her seed ile tamamlanacağını kanıtlamaz.
- 62. bölüm: hedef **195**, hamle **23**; yeniden kolaylaştırılmadı. Bu sürümde 20 seed: **18/20** kazanma, hamlesizlik/stabilite ihlali yok. Android'deki özgün hamle dizisi/kayıt dosyası sağlanmadığı için o cihaz olayının birebir yeniden üretildiği iddia edilmiyor.
- Mekanik 17: koordinata bağlı iki darbeli kırılgan zemin; ikinci hasar hücreyi kalıcı oynanamaz boşluğa çeviriyor. Dört yönlü yer çekimi/refill/fırtına boşluğa kristal koymuyor. Özel güç doğum konumu kırılıyorsa uygun diğer eşleşme hücresine deterministik taşınıyor.
- Mekanik 18: dört hücreyi kaplayan tek Dev Kristal nesnesi. Üç hasar, çözümleme aşamasında tek hasar; dört hücre aynı anda açılıyor.
- Mekanik 19: üçüncü başarılı eylemde çalışan sabit Manyetik Düğüm. Aynı satırın mesafe/koordinat sırasındaki iki uygun kristalini eş zamanlı değiştiriyor. Aynı kristal aynı turda yeniden seçilmiyor. Eşleşmeler otomatik; tek oyuncu eyleminde mıknatıs/fırtına tekrar etmiyor.
- Mekanik 20: dört merkezi kalkan sayacı ve savunmasız çekirdek. 150. bölümde 12 kırmızı, 12 mavi, 10 yeşil, 10 sarı enerji. Kalkanları kaldıran aynı patlama son darbeyi veremiyor; sonraki gerçek özel güç etkisi gerekiyor. Dev nesne/kalkan durumları kaydediliyor, bozuk durumlar reddediliyor.
- Özgün üretilmiş 2.5D kanyon resmi ve beş yeni cihaz/hedef görseli; yeni sentezlenmiş çatlak, dev kırılma, çekirdek, mıknatıs ve karıştırma sesleri. İkonlar, kısa Türkçe açıklamalar, tahta vurgusu ve mevcut tek seferlik hedef öğreticileri korunuyor.
- Üçüncü dünya haritası, 101–150 numaralı 50 bölüm, T/L/ortası boş/iki kanat/dar geçit/asimetrik şekiller, portal+mıknatıs / konveyör+taş / köprü+zemin / buz+dev kombinasyonları. 150. bölümün final animasyonu ve kalıcı tek seferlik dünya ödülü.
- Eski 100 bölüm, 16 mekanik, otomatik rastgele yer çekimi, Kristal Dalgası, ikonlu panel, kalite ayarları ve ücretsiz oyun korunuyor. Manuel yön seçimi ve oyun ekranındaki “Nasıl oynanır?” butonu geri getirilmedi. Reklam, ödeme, PRO veya sonraki aşama eklenmedi.

## Denge ve testler

[bölüm tablosu](balance.csv), [test özeti](test-summary.txt), [makine sonuçları](tests.json), [performans](PERFORMANCE.md).

Yeni bölümler: ilk 500 oyunla hedef/hamle gereksinimi incelendi; eğitim, rahatlama ve strateji dalgasına göre hamle bütçeleri düzenlendi. Son küçük zemin-özel güç doğum konumu düzeltmesinden önceki dengelenmiş adayda ayrı seed grubunda 500 oyun: **487/500 (%97,4)** kazanma, sıfır tahta invarianti ihlali. Bu güçlü otomatik oyuncunun oranıdır; gerçek oyuncu zorluk oranı değildir. Hamle azaltması sabit yüzde ya da sabit -5 yapılmadı. 150. bölüm için normal ücretsiz özel güçler yeterli; ücretli yardımcı gerekmiyor.

**150/150 varsayılan bölüm tamamlandı**; bütün hamlelerde aynı seed ile tekrar, kararlı/oynanabilir tahta ve kayıt dönüşümü karşılaştırıldı: 4.791 kontrol. Son zemin-özel güç düzeltmesinden sonra yeni 50 bölüm ayrıca yeniden doğrulandı: 1.383 kontrol. Seçilen eski Match-3/mekanik/fırtına/dalga/özel güç ve UI paketleriyle toplam **94.014 başarılı kontrol**, son kabul sonuçlarında sıfır hata. Sayı benzersiz test senaryosu sayısı değildir. Gerçek dokunmatik olay simülasyonları ve üç ekran oranı test edildi.

Başarısız aday sonuçları saklandı: ilk kampanya karşılaştırması 44 hata (90. bölümde sandık zincirinin serbest bıraktığı kristalin sayılması; şekilli tahtalarda sayı türü nedeniyle kayıt karşılaştırması), ilk genişletilmiş hedef-vurgu testi 21 hata (koordinata bağlı zemin bağlamının eski test/registry yoluna eklenmesi). Hatalar giderildi ve ilgili testler geçti. İlk yazılmış birkaç test betiğinin GDScript tür çıkarımı hataları da düzeltildi. Başarısız koşular başarılı sayılmadı; ham loglar rapor ZIP'inde.

## Android teslimatı

- APK: `prizma-v0.10.0.apk`; yerel `build/prizma-match3.apk`.
- Paket: `com.prizma.renklerinuyanisi.match3`; sürüm adı `0.10.0`, kod `10`.
- Minimum SDK 24, hedef SDK 36; ARMv7 ve ARM64; internet izni yok.
- Aynı imza sertifikası SHA256: `01bb7474354b56e234ce24df50fd2e1ef45c838111b364cd0b3894bf8bb8360a`.
- APK SHA256: `2e3bbd11a6c29326de7b0f61d8e9d3c1cc2cc55a535d9364b03859f4568593c3`.
- 75.265.394 byte. ZIP bütünlüğü, imza, paket/sürüm, bütün bölüm verilerinin kaynakla eşitliği ve iki ARM kitaplığı kontrol edildi.
- Kayıt şeması 3 korunuyor. Eski aktif bölüm tanımları ve eski yıldız/ödül/ayarlar saklanıyor; tamamlanmış 100 sınırından 101'e genişleme test edildi. Cihazda uygulamayı silmeden üzerine kurulum hedefleniyor; gerçek telefonda kurulum testi yapılmadı.

## Açık sınırlar

Gerçek Android cihaz erişimi yok. Fiziksel FPS/input-to-photon, termal davranış, titreşim, ses gecikmesi, çentik/sistem çubukları ve yerinde APK güncellemesi doğrulanmadı. Linux yazılımsal GPU ölçümünde tekil frame gecikmeleri var; Android için kusursuz 60 FPS iddiası yok. İnsan oyuncuyla yeni dünya zorluğu ve 62. bölüm strateji kabulü bekliyor. Her seed için kazanılabilirlik matematiksel olarak kanıtlanmadı; test edilen seed grupları açıkça raporlandı.

Bu sürüm tamamlandıktan sonra yeni geliştirme aşamasına geçilmez.
