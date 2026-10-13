# PRİZMA 0.9.0 — Oynanış 2.0

Mevcut projeden devam edildi. Çalışan 0.8.0 için `backup/before-gameplay2-v0.8.0` etiketi ve doğrulanmış `/workspace/prizma-tools/before-gameplay2-v0.8.0.bundle` oluşturuldu. İki dünya, 100 bölüm, 16 mevcut mekanik, özgün renkli kristal atlasları ve ikonlu hedef sistemi korunur. Üçüncü dünya, ücretli ürün veya 17–20 numaralı engel eklenmedi.

## Oynanış ve sade arayüz

Oyun ekranındaki dört yön düğmesi, alttaki “Nasıl oynanır?” düğmesi ve kalıcı açıklama kartı kaldırıldı. Tahta aynı 8×9 koordinatlarıyla ana odaktır. Altında tıklanmayan Prizma Fırtınası göstergesi bulunur; rezonans ve kısa geçici geri bildirimler sürer. Yardım/öğreticiler Ayarlar menüsünde, ilk mekanik karşılaşmasında ve hedef ikonlarının açıklamalarında erişilebilir. 16:9, 19.5:9 ve 20:9 yerleşim testleri vardır.

Fırtına önceki yer çekimi öğretimiyle 4. bölümden itibaren açılır. Temizlenen normal kristaller merkezi sayaca eklenir; oluşturulan/etkinleştirilen özel güçler kendi başına enerji sayılmaz. 12 enerji bir kullanımdır. Başarılı oyuncu takası veya tanımlı özel güç eyleminin normal çözümlemesi, dönüşümler ve ray turu bittikten sonra otomatik fırtına çalışır. Mevcut yön hariç üç seçenekten platformdan bağımsız seed'li RNG ile seçim yapılır. Sonuca/hedeflere bakılarak yön veya dolum seçilmez. Fazla enerji saklanır; aynı eylemde ikinci fırtına açık bir bayrakla engellenir. Manuel motor giriş noktası da reddeder. Zincirler ek hamle tüketmez; son hamlede sonuç tüm otomatik etkiler bittikten sonra hesaplanır.

Tam dolu tahtada yalnızca yer çekimi sıkıştırması yapmak hiçbir taşı hareket ettirmez. Bu nedenle fırtınanın açık taşıma kuralı şudur: seçilen yöndeki her sabit engelle ayrılmış hareketli koridor bir hücre kayar; kenardaki kristal aynı koridorun diğer ucuna büyülü biçimde geçer. Önce koridorun tamamı okunur, sonra kimlikler taşınır. Engeller, hücre katmanları ve kristal sayısı korunur; yeni renk uydurulmaz. Sonrasında mevcut boşluk/portal/baloncuk yer çekimi motoru ve Match-3 kaskadları çalışır. Uzun kenar geçişi kısa küçülme/ışık animasyonudur. Bu kural oyuncunun yön seçmesi değildir.

Kristal Dalgası aynı eylemde en az üç gerçek eşleşme aşamasından sonra bir kez çalışır. Sadece güç ayak izi gerçek renk eşleşmesi aşaması sayılmaz. Aktif renk başarılı hamlenin rezonans/mühür için de kullanılan rengi, özel güçte seçilen/baskın renktir; bölüm isteğe bağlı sabit `wave_color` tanımlayabilir. Son eşleşme merkezine Manhattan mesafesi ve hücre indeksiyle sıralanan en yakın dört uygun düz kristalden en fazla ikisi boyanır. Zaten o renkteki aday atlanır; dördüncü adayın dışından telafi hedefi seçilmez. Sabit, zırhlı, trait, baloncuk ve özel güç kristalleri etkilenmez. Oluşan eşleşmeler otomatik çözülür; enerjiyle ayrı sayaçları vardır.

## Patlama, kombo, birleşimler ve ses

Normal kristaller kısa büyüme/beyaz parlama, gerçek atlas parçalarına ayrılma, renkli kırıklar ve genişleyen ışık halkasıyla kaybolur. Büyük eşleşmelerde ışık çizgileri, enerji dönüşümü ve ayrı özel güç doğuşu vardır. Kombo sırası `KOMBO! / SÜPER! / MUHTEŞEM! / EFSANEVİ!`; büyüyen renkli tipografi, yıldız parçaları ve kısa sönme kullanılır. Fırtına/dalga ışık halkaları ve geçici yön göstergesi vardır. Dengeli/performans/azaltılmış efekt ayarları aynı mantığı çalıştırır; yalnızca görsel yoğunluk değişir.

Önceden hazırlanmış geliştirici öğretim sahnelerinde sabit iki-adımlı gösterimleri korumak için fırtına/dalga kapalıdır; yeni entegrasyon testleri sekiz laboratuvar mekanizmasında bunları açıkça etkinleştirir. Kampanya normal kuralları kullanır.

Altı özel güç birleşiminin mevcut ayak izleri korundu; tek merkezi `combo_plan` tür/virtual etki/tekilleştirilmiş alan üretir. Roket+roket çapraz, roket+prizma çoklu şerit, prizma+prizma geniş alan, renk+roket seçilen renk üzerinden sanal roketler, renk+prizma sanal alan etkileri, renk+renk tüm tahta etkisidir. Sanal güçler hücrelere kalıcı yazılmaz, ortak hasar planından geçer. Korunmuş nesneler doğrudan silinmez: taş prizma alanında en fazla 2, zırh en fazla 1 darbe alır; renk kilidi normal enerji kurallarını korur. Örtüşen etkiler toplanmak yerine maksimum hasar alır; mevcut zincir ziyaret/limit korumaları sürer.

11 farklı kısa özgün ses matematiksel sentezle üretildi; üçüncü taraf ses kullanılmadı. Kaynak ve SHA-256/süre/tepe değerleri `assets/audio/gameplay2-manifest.json` içindedir. Beş seslik havuz ve azaltılmış kazanç aşırı miks seviyesini sınırlar. Büyük etkilerde kısa sarsıntı/titreşim ayarlardan kapatılır. Normal üçlüde sarsıntı yoktur; tahta koordinatları görsel titreşimden etkilenmez. Fiziksel hoparlör gecikmesi ve haptik hissi Android cihazda henüz doğrulanmadı.

## Bölüm dengesi ve kayıtlar

Tam bölüm tablosu: [BALANCE.md](gameplay2/BALANCE.md), makine okunur [CSV](gameplay2/balance.csv) ve [JSON](gameplay2/balance.json). Hedefler, engeller, eski/yeni hamleler, hazır güç fırsatları, özel güç üretimi, zincirler ve iki seed grubunun gerçek sonuçları raporlanır.

Aynı deterministik açgözlü çözücü ile eski sürümde 2.000/2.000 oyun kazanıldı; ortalama 5,48 hamle kullanıldı, 21,06 kaldı. Yeni düzende ilk 2.000 oyunda 1.901 (%95,05), ayrı `seed+1000..1019` grubunda 1.876/2.000 (%93,8) kazanma görüldü. Ortalama kullanılan hamle 10,60, kalan 6,19 oldu. Yeni ilk grupta 17.201 fırtına, 6.200 dalga; ayrı grupta 16.866 fırtına, 6.209 dalga ve sıfır kaskad limit olayı vardır. Bu oranlar insan oyuncu kazanma oranları değildir; bütün olası seed'lerin çözülebilirliği kanıtlanmış değildir.

54. bölümün ilk sert hedefi başarısız denge denemesiydi (%50 çözücü kazanma); hedef 186'dan 150'ye düzeltildi ve iki grup da %80 oldu. 62. bölümde örnek rota 23 hamlede 199 kristal toplayıp 208 hedefini kaçırıyordu; hedef 195 yapıldı. İki grup yeniden test edildi: ilk grupta %90, ayrı grupta %95. Üç yıldız eşiği ölçülen 10.630 puana ayarlandı. İlk hatalı ölçümler silinmedi, düzeltmeler ayrı ham dosyalarda tutuldu. Ayrı grupta zor/meydan okuma 66, 70, 94 %65 başarı gösterir; gerçek oyuncu testleri gerekir. İlk 10 öğretici kolay kalır. Sonraki sekizli dalga rahat/orta/orta/zor/rahat/stratejik/kombinasyon/meydan okumadır. Hedef sayıları, bazı ileri kilit maliyetleri ve hazır roketler hamle bütçesiyle birlikte düzenlendi; tek tip “beş hamle eksilt” uygulanmadı. 100. bölümün bütçesi 52 → 21; ilk grupta ortalama 15,2 hamle kullanımı, 5,8 kalan ve %85 kazanma vardır.

Kayıt şeması 2 → 3 dönüştürülür. Orijinal dosya `.v2-before-gameplay2` adıyla bir kez arşivlenir. Eski devam eden oyun tam 0.8 bölüm tanımını korur; kalan hamle/hedef/yıldız koşulları düşürülmez. Yeni kayıtlar `level_definition` ve `move_budget` içerir. Açılmış bölümler, yıldızlar, ses/kalite ayarları ve tek seferlik dünya ödülleri korunur. Yeniden oynanan/yeni başlayan oyunlar yeni dengeyi kullanır. Gelecek şema ve bozuk kayıt üzerine yazma korumaları sürer.

## Doğrulama ve teslimat

191.467 otomatik assertion/kontrol, sıfır başarısız sonuç. Bütün önceki Match-3, mekanik, hedef paneli, kayıt, dünya finali ve yeni Oynanış 2.0 testleri çalıştırıldı. Yerel koşu başarılı ve etkilenmeyen test sonuçlarını koruyarak 62. bölüm düzeltmesinden sonra ilgili Okyanus testi ve kalan kontrolleri yeniden çalıştırdı; GitHub CI temiz kaynaktan standart tam test.sh koşusunu tekrarlar. [Gerçek çıktılar](gameplay2/test-summary.txt), [performans raporu](gameplay2/PERFORMANCE.md), [eski/yeni ekranlar](gameplay2/screens/) ve ham log/JSON dosyaları pakettedir.

APK gerçekten üretildi, ZIP bütünlüğü ve tüm bölüm JSON dosyalarının kaynakla birebir eşleşmesi kontrol edildi. 71.409.152 byte; SHA-256 `21d3fae0020ada74399754aa216a6735aab8b0a0ffa6598ed5062c7d8e76afbb`. Paket `com.prizma.renklerinuyanisi.match3`, sürüm 0.9.0/code9, min SDK24/target36, ARMv7 ve ARM64; INTERNET izni yok, VIBRATE izni var. Önceki sürümle aynı imza SHA-256: `01bb7474354b56e234ce24df50fd2e1ef45c838111b364cd0b3894bf8bb8360a`. Gerçek telefon kurulumu henüz test edilmedi.

Değişen dosyalar: [tam liste](gameplay2/changed-files.txt). Temel dosyalar board/powerups/save_manager/level_catalog, storm/wave modülleri, ortak hasar/zincir, main/board_view/storm_gauge/audio_manager, beş bölüm veri dosyası, legacy tanımlar, yeni WAV kaynakları, test/derleme/rapor araçları ve release workflowdur. Çalışan eski proje yeniden oluşturulmadı.

Tamamlandı: sade oyun ekranı, otomatik rastgele fırtına, deterministik tek-dalga etkisi, altı birleşimin ortak hasar/yansıma/sayaç kuralları, güçlü kısa efektler/11 ses, 100 bölüm dengesi, eski aktif oyunları koruyan kayıt dönüşümü, otomatik testler, gerçek Linux render/dokunma ölçümleri ve imzalı Android test APK. Bekleyen kabul: gerçek Android FPS/ısı/dokunma/ses/haptik/çentik/kurulum ve insan zorluk testleri. Bunlar başarılı sayılmadı.

Buluta bağlı gerçek Android telefon/emülatör yoktur. Android FPS'i, fiziksel sürükleme gecikmesi, hoparlör/titreşim, çentik ve cihazda APK kurulum kabulü test edildiği iddia edilmez. Godot/Linux gerçek render ve sentetik native girişler ayrı belirtilir. Cihazda Ayarlar → Performans raporu kullanılabilir. 60 FPS hedefi cihaz kabul testi gerektirir.

Bu paket teslimatında durulur; sonraki aşama kullanıcı onayına bağlıdır.
