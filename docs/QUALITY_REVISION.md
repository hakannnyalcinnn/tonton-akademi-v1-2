# PRİZMA 0.3.0 — Görsel kalite ve performans revizyonu

Bu çalışma mevcut oyunun kalite revizyonudur. Yeni dünya, bölüm, mağaza veya mekanik eklenmedi. `data/levels.json`, Match-3 hedefleri/hamleleri ve puan formülü korundu. Çalışan önceki sürüm `backup/match3-v0.2.0` Git etiketi ve doğrulanmış Git bundle ile kaydedildi.

## Görseller ve kontrol

Beş özgün, saydam SVG kristal: yıldız yakut, elmas safir, altıgen zümrüt, yuvarlak güneş kristali ve ay yüzeyli çokgen ametist. Kenar yüzeyleri, ışık yansımaları, gölgeler ve farklı silüetler var. Küçük gri normal-blok sembolleri kaldırıldı. Bunlar emoji veya geçici varlık değildir. Kaynakları `tools/generate_crystals.py` üretir.

Dokuz kristal/güç varlığı tek **768×768 atlas** kullanır; her varlığın kaynak bölgesi 256×256’dır. 2048 piksel sınırına sahip GPU’lar için atlas geniş tutulmadı. Tahta ve 72 hücre zemini özgün **1000×1120 SVG** dokusuyla tek çizimde gösterilir. Mevcut bahçe, marka, menü, dünya, kayıt ve ses korunur.

| Görsel durum | Kontrol |
| --- | --- |
| Normal | Sabit atlas görüntüsü; farklı büyük silüet |
| Seçili | Anında yeniden çizim, hafif büyüme ve kenar parıltısı |
| Sürükleme | Parmak yönünde konum, yükselme gölgesi; eşikte tek komşu takası |
| Eşleşme | Kısa büyüme ve yoğun ışık |
| Patlama | Renkli kristal parçaları, ışık halkası, yükselen puan |
| Geçersiz takas | 140 ms yumuşak geri dönüş; mantık/sayaç değişmez |
| Yeni kristal | Yer çekiminin karşı kenarından giriş ve kısa yerleşme |

Normal takas **180 ms**, patlama **210 ms**, düşüş **150 ms**, dolum **170 ms**. Azaltılmış hareket seçeneği süreleri kısaltır ve parçacık hareketini kapatır. Normal dokunma hâlâ patlatmaz. Native ScreenTouch ile emüle fare çift girişleri engellenir; takas eşikte başlar ve tek hareket iki hamle oluşturmaz.

Dörtlüde yönlü roket enerjisi; beşlide renkli yörünge dönüşümü; T/L’de üç yönlü prizma enerjisi; etkin güçlerde roket ışınları/renk dalgaları var. Kombolar KOMBO / SÜPER KOMBO / MUHTEŞEM / EFSANEVİ şeklinde kısa büyüme ve kaybolmayla gösterilir. Tahta sarsıntısı en fazla yaklaşık 1,4 mantıksal piksel, 200 ms’dir; kapatılabilir.

## Ölçümle araştırılan maliyetler ve düzeltmeler

- Önceki çizim her normal hücre için dört yeni StyleBoxFlat oluşturuyor, tüm tahtayı her karede yeniden çiziyordu. Normal durumda yaklaşık 288 geçici stil nesnesi/kare, ayrıca çerçeve ve seçili stiller vardı. Yeni kristal çizimi stil nesnesi oluşturmaz; boşta gereksiz yeniden çizim yapılmaz.
- Sabit yuvarlak hücre kenarları çok sayıda GPU çizim çağrısı üretiyordu. Statik dekor tek dokuda önceden çizildi. Görsel hücre koordinatları değişmedi.
- Animasyon olaylarında tahta görüntüleri tekrar tekrar derin kopyalanıyordu. Kaydedilen kareler değişmez tutulur; kuyruk listeleri sığ kopyalanır. Mantık hücreleri ile görsel görüntüler bağımsız kalır.
- Animasyondan önce JSON doğrulama/okuma/yazma/yedekleme ana iş parçacığında yapılıyordu. UI artık değişmez, tamamen çözülmüş kayıt görüntüsünü sıralı bir işçi iş parçacığına verir. Bekleyen kayıtlar en son görüntüde birleştirilir. Atomik geçici dosya/yedek/yeniden adlandırma korunur; duraklatma ve çıkışta yazım tamamlanır. Yazım hatası gizlenmez.
- Ses dosyası arama/yükleme patlama sırasında yapılmıyor. Özgün sesler başta ön yüklenir; beş ses kanalı yeniden kullanılır. Roket, renk bombası ve zincir için ayrı özgün sentezler vardır; ses seviyeleri sınırlıdır.
- Parçacık deposu sabit **192** girdidir. Aktif bütçe yüksek/dengeli/performans/azaltılmış efekt için **144/96/36/24**. Dört puan etiketi ve bir kombo etiketi yeniden kullanılır. Kare başına Tween veya efekt sahnesi oluşturulmaz.
- Arka plan dokusu kalıcıdır; ortam hareketleri daha düşük hızda çizilir, performans kipinde kapatılır. Otomatik kalite sürdürülen yavaş karelerde parçacık yoğunluğunu düşürür. Oyun kuralları veya sonuçları değişmez.

Bu maliyetler bulut makinesinde kod ve süre ölçümüyle doğrulandı. **Kullanıcının Android cihazındaki donmanın tek kesin nedeni belirlenmiş değildir:** cihaz bağlı değildi. Telefonun CPU/GPU sürücüsü, kare zamanlaması, ısınma, ilk shader kullanımı ve gerçek dokunmatik gecikmesi cihaz raporuyla ayrılmalıdır.

## Test kanıtları

- **21.969 Match-3 doğrulaması, 0 başarısızlık.** 2.000 başlangıç tahtası; tüm 10 bölümde toplam 1.000 oyun / 4.128 hamle; her bölümde 100/100 otomatik kazanım. İnsan zorluk/zevk testi yerine geçmez.
- **71 kalite doğrulaması, 0 başarısızlık.** Havuz sınırları, işçi kayıtlarının tam tahta/RNG devamı, kalite/efekt seçenekleri, aynı karede 100 tekrar girişi, 10 bölüm, dört yer çekimi, iki roket kombinasyonu, tam tahta dolumu, eski schema-2 ayarları, duraklatma/devam ve üç ekran oranı.
- **100 geçerli native ScreenTouch kaydırması + 100 engellenen tekrar kaydırması.** Sahne/havuz sayısı sabit, ikinci hamle uygulanmıyor.
- İki ayrı süreçte kaydın devamı aynı tahta, RNG ve puanı üretiyor. Schema-1 arşivi ve daha yeni schema üzerine yazmama testleri korunuyor.
- Zorlanmış tek renkli 10.000 öğelik dolum kuyruğuyla 128 kaskad sınırı test edildi. Teşhis kaydı üretiliyor; bozuk akış bırakılıyor; sıradan karıştırma çözemiyorsa sadece acil toparlamada normal renkler yenileniyor, kimlikler/sabitler/güçler korunuyor. Son tahta hazır eşleşmesiz ve oynanabilir. Bu fixture’ın uyarıları beklenen test çıktısıdır; normal oyun koşularında sınır tetiklenmedi.
- Gerçek Godot çiziminden **540×960, 540×1170 ve 540×1200** görüntüleri alındı. Arka plan ekranı kaplıyor, kareler gerilmiyor. Güvenli alan girintileri ve koordinat dönüşümü ayrıca sentetik test edildi.
- Debug APK: Android 7.0+, SDK 36, ARMv7/ARM64, çevrimdışı. İmza, manifest, kristal/tahta/teşhis/ses varlıkları doğrulandı. 0.2.0 ile **aynı paket ve aynı imza** kullanır; eski Match-3 kurulumu ve kaydı korunarak güncellenir.

## Telefon üzerinde henüz doğrulanmayanlar

Fiziksel Android cihaz veya emülatör bağlı değildi (`adb devices` boş). Gerçek telefon 60 FPS, fiziksel parmak→ekran gecikmesi, çentik/sistem çubukları, titreşim, hoparlör gecikmesi, Android arka plan/geri dönüş davranışı, ısınma ve pil ölçülmedi. Simüle yaşam döngüsü testi gerçek işletim sistemi testi değildir. Gerçek düşük segment cihaz testi yapılmadı; performans kalite profili bulutta çizildi. Tam heap tahsis/GC izi veya Perfetto iş parçacığı zaman çizelgesi alınmadı; Godot bellek/nesne tepe sayaçları ve kodda kaldırılan geçici tahsisler raporlandı.

## Telefonda ölçüm

1. `prizma-match3.apk` dosyasını mevcut 0.2.0 **PRİZMA Match-3** uygulamasının üzerine kur. Uygulamayı kaldırma.
2. Otomatik/dengeli kipte en az 40 saniye oyna: hızlı/yavaş geçerli ve geçersiz kaydırmalar, büyük eşleşme ve zincir. Açık bölümlerde roket/renk bombası, dört yön ve rezonansı da dene.
3. Uygulamayı arka plana alıp geri aç; aktif tahta ve hedefleri kontrol et. 19,5:9/20:9 çentikli cihazda tahtanın/alt kontrollerin güvenli alanda olduğunu kontrol et.
4. Ayarlar → **Performans ölçümü / rapor** → **RAPORU KOPYALA**. Raporu paylaşarak cihaz/model/kalite ile gecikmenin hangi aşamada görüldüğünü karşılaştırabiliriz. Frame/GPU örnekleri son 2048 kaydı tutar; kalite karşılaştırmasında her kipte en az 40 saniye oyna.
5. İstersen Performans, azaltılmış efekt ve sarsıntı kapalı kiplerini karşılaştır. Seviye/puan/moves kuralları aynıdır.

Rapor oyun verisindeki `prizma-performance.json` dosyasına ve panoya yazılır; kendiliğinden gönderilmez. Model, ekran boyutu/yenileme hızı/güvenli alan, kalite, p50/p95/en yüksek süreler, render CPU/GPU, bellek/nesne tepe değerleri ve 50 ms üzerindeki karelerin oyun aşaması kaydedilir. Dokunma metriği Godot girişinin alınmasından çizim komutunun gönderilmesine kadardır; fiziksel ekran taramasını içermez. AudioServer gecikmesi de gerçek hoparlör/Bluetooth gecikmesinin tamamı değildir.

Bilgisayarla ileri teşhis için Godot Profiler/Visual Profiler ve `adb logcat -s godot`, `adb shell dumpsys meminfo com.prizma.renklerinuyanisi.match3` kullanılabilir. Bu çalışma `--profiling`, Godot Performance sayaçları ve RenderingServer CPU/GPU zamanlayıcılarını kullandı; telefona bağlı uzak editör profiler oturumu çalıştırılmadı. Grafik sunucusu zamanlayıcı sunmuyorsa ilgili GPU ölçümü yoktur.

Sonraki geliştirme aşamasına geçilmedi. Android kabul ölçümü ve kullanıcının görsel değerlendirmesi bekleniyor.

## Gerçek performans ölçümleri

Godot 4.6.3, Linux/Xvfb, **llvmpipe LLVM 19.1.7 yazılımsal çizimi**, 540×960, 60 FPS sınırı. Önce/sonra aynı 100 geçerli mantık takası, aynı solver/seed ve **228 kaskad dalgası**. Eski kod Git yedeğinden geçici bir karşılaştırma dizininde çalıştırıldı; mevcut proje sıfırlanmadı. Zamanlar Time.get_ticks_usec ile, kare aralığı ardışık gerçek callback zamanlarıyla ölçüldü. p95 örneklerin yüzde 95’inin altında kaldığı değerdir. Bulut zamanlama gürültüsü ve yazılımsal sürücü sonuçları telefon performansı değildir.

Tabloda **ortalama / p95**, süreler ms; çizim çağrısı satırı adettir.

| Ölçüm | Önce | Sonra, dengeli |
| --- | ---: | ---: |
| Gerçek kare aralığı | 31.004 / 39.494 | 16.704 / 17.199 |
| Takas + bütün zincir mantığı | 2.558 / 5.623 | 1.599 / 3.436 |
| Animasyon hazırlığı/kayıt kuyruğu | 2.452 / 3.231 | 0.431 / 0.695 |
| Kare başına çizim çağrısı | 691.817 / 759.000 | 169.813 / 297.000 |
| Godot TIME_PROCESS sayacı | 44.049 / 58.489 | 22.176 / 34.621 |

Ortalama gerçek kare aralığından hesaplanan FPS **32.3 → 59.9**. Çizim çağrısı ortalaması **%75.5** azaldı. Takasın görsel süresi ortalama **184.8 ms**, p95 **192.7 ms**.

| Son sürüm işlem | Ortalama ms | p95 ms |
| --- | ---: | ---: |
| Eşleşme taraması | 0.094 | 0.123 |
| Patlama mantığı | 0.101 | 0.173 |
| Yer çekimi hesaplama | 0.057 | 0.087 |
| Yeni blok üretimi | 0.025 | 0.037 |
| GDScript tahta çizim komutları | 0.308 | 0.500 |
| RenderingServer CPU | 2.161 | 4.913 |
| RenderingServer GPU, yazılımsal sürücü | 8.501 | 11.716 |
| Arka plan dosya yazımı | 1.314 | 2.129 |

Performans kipinde ayrı **20 takas / 52 dalga**: ortalama **59.8 FPS**, kare p95 **16.733 ms**, çizim çağrısı ortalaması **87.8**. Daha kısa veri kümesi olduğu için 100 hamlelik koşunun bire bir karşılaştırması değildir. Düşük segment fiziksel cihaz testi değildir.

Godot izlenen statik bellek tepe değeri **39.8 MiB**, canlı nesne tepe değeri **1814**; bunlar benchmark toplayıcısını da içerir, toplam Android uygulama RSS’i veya bütün heap tahsisleri değildir. TIME_PROCESS, render eşzamanlaması/beklemeleri içerebilir; saf GDScript işlem süresiyle veya birbirine eklenen CPU/GPU bütçesiyle karıştırılmamalıdır.

**60 FPS bütün karelerde garanti edilmedi:** dengeli koşuda en uzun kare **52.644 ms**; seyrek uzun kareler vardı. Teşhis raporu bunların aşamasını ayrıca tutar. Normal mantık takası en fazla **3.878 ms** idi; buluttaki bütün uzun karelerin veya telefondaki donmanın kök nedeni bununla kesinleştirilmez. İlk kullanım/sürücü/zamanlama etkileri gerçek cihaz profiler kaydıyla doğrulanmalıdır.

Ham ölçüm özetleri: [önce](performance/baseline.json), [sonra](performance/revised.json), [performans kipi](performance/low-quality.json). `tools/test.sh` ayrıca 100 gerçek GUI kaydırması için ayrı dokunma metrikleri üretir. Başsız toplayıcının FPS veya dokunma değerleri fiziksel telefon ölçümü olarak kullanılmaz.

## Değişen dosyalar

- `scripts/ui/board_view.gd`, yeni `board_backdrop.gd`: atlas çizimi, hücre dekoru, sürükleme, havuzlanmış parçalar/puan/kombo, süreler ve kalite uyarlaması.
- `scripts/ui/main.gd`, `garden.gd`, `audio_manager.gd`, yeni `performance_metrics.gd`: ekran/güvenli alan, ses/ayarlar, akıcı sayaç ve cihaz teşhisi.
- `scripts/core/board.gd`, `board_generator.gd`, `save_manager.gd`: değişmez görsel kareler, süre ölçümü, teşhis edilen kaskad toparlaması, işçi kayıt yazımı ve ek ayar uyumluluğu. Normal oyun kuralları/puan formülü değişmedi.
- Yeni `assets/crystals/*.svg` ve import dosyaları, üç özgün ses (`rocket`, `color`, `cascade`), `assets/CREDITS.md`; üretim araçları `generate_crystals.py` / `generate_audio.py`.
- `tests/capture.gd`, yeni `quality_tests.gd`, `swipe_stress.gd`, `visual_performance.gd` ve UID dosyaları; `tools/test.sh`, `build_android.sh`.
- `project.godot`, `export_presets.cfg`: ekran genişleme ve 0.3.0 / kod 3; aynı Match-3 Android paket kimliği.
- `README.md`, `docs/STATUS.md`, bu rapor, ölçüm JSON’ları ve `RELEASE_v0.3.0.md`; `.github/workflows/android-test-release.yml`: tam aynı imzalı APK ve kanıtların doğrulanarak yayımlanması.

`data/levels.json`, Match-3 dedektörü, yer çekimi, güç/rezonans ve puan modülleri değiştirilmedi. Git commit bu dosyaların tam listesini içerir.
