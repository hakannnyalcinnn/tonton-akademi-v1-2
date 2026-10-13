# PRİZMA 0.6.0 — Dördüncü geliştirme paketi

## Kapsam ve mevcut proje kontrolü

Mevcut Godot 4.6.3 projesi korunmuştur. Başlangıç sürümü `fe979ad0060fab0889dfd654c0479b8f451c8a52` (0.5.0), geri dönüş etiketi `backup/before-package4-v0.5.0`. Geliştirme öncesinde bütün mevcut testler geçti; tüm Git geçmişini içeren yerel bundle ayrıca doğrulandı.

Match-3 sürükleme, otomatik çözümleme/zincirler, dört yön, rezonans, güçler, tohum/buz/taş/kilit, çift renk/bukalemun, köprü/çivi, 50 bölüm, kayıt ve ses/kalite ayarları mevcut ve çalışan sistemlerdi. Köprü/çivi 0.5.0'da yalnızca laboratuvardaydı; bu sürüm onları normal oyuncu bölümlerine tanıtır. Normal kristale dokunarak patlatma geri eklenmedi. İlk üç bölüm veri dosyasının (1–50) içeriği değiştirilmedi.

Yeni 9–12 mekanikleri **yalnızca geliştirici sahnelerindedir**. 51–75 kampanyasında portal, sarmaşık, sandık veya ayna yoktur; katalog doğrulaması bunu denetler. Yeni satın alma, mağaza veya sonraki mekanik paketi geliştirilmedi.

## Kurallar ve olay sırası

### PortalManager

Portal kristale bağlı bir parça değildir: bölümün `portals` listesinde giriş/çıkış koordinatları bulunan sabit bir cihazdır. En fazla 8 çift; koordinatlar 0–71 ve bütün uçlar farklı olmalıdır. Hücrede normal kristal bulunabilir. Sabit/çivili kristal, güç veya dolu çıkış taşınmaz. Çiftler giriş indeksine göre sıralanır; aktarım tek hücre atamasıyla atomik olur. Olaylar `movement_queue` ve ayrı `portal` animasyon karelerine kaydedilir.

Geçerli takasın taşıdığı veya kompaksiyonla girişe ulaşan normal kristal kontrol edilir. Çıkış boşsa transfer olur; çıkışta sonraki kompaksiyon mevcut yer çekimi yönünde çalışır. **Bir kristal ID'si tüm oyuncu eylemi boyunca, zincirlerin tamamı dahil yalnızca bir kez transfer olabilir.** Sabit kristaller her karede kontrol edilmez. Gravity ve özel güç eylemleri yeni bir aktarım bağlamı başlatır; portal ilave hamle tüketmez.

Dolu tahtayı yeniden doldurmadan önce boş çıkışın kullanılabilmesi için sıralama mevcut motora uyarlandı: kompaksiyon → geliş/portal kontrolü → çıkış kompaksiyonu → boşlukları doldurma → yeni eşleşmeler. Portal turu kristal sayısıyla sınırlı, kullanılan ID kümesi tekrar aktarımı engeller. Dolu çıkış güvenli biçimde atlanır; sonraki tanımlı gelişte tekrar denenebilir. Yerleşme/eşleşme/sonuç kontrolü otomatik tamamlanır. Hiçbir çerçeve mantık hücrelerini değiştirmez.

### VineManager

Sarmaşık 1 dayanıklılıklı zırh katmanıdır: kristalin rengi görünür, fakat takas/eşleşme/yer çekimi engellenir. Komşu yatay/dikey temizleme veya tanımlı güç hasarı bir olayda en fazla bir darbe uygular. Temizlenince alt kristal serbest kalır.

`vine_enabled` olan test/bölüm tanımında yalnızca kabul edilmiş **oyuncu takası** sayacı artırır. Geçersiz takas, özel güce dokunma, otomatik zincir ve yer çekimi sayılmaz. Üçüncü takasın tüm normal, sandık, portal ve bukalemun zincirleri bittikten sonra kaynak hücreler ve uygun komşular indeks sırasıyla değerlendirilir. En fazla bir normal/özelliksiz kristal kaplanır; `vine_max` aşılmaz; taş, güç veya başka katman üzerine yayılmaz.

Yayılma sonrasında hamle yoksa normal bloklar ücretsiz karıştırılır. Yeni sabit topoloji hiçbir karıştırmayla oynanabilir olamıyorsa büyüme geri alınır; önceki tahta korunur ve teşhis kaydı yazılır. Bu kurtarma yolu özel bir gerçek üçüncü takas testiyle doğrulandı. `vine_count` aktif tahta kaydına eklenir; eski kayıtlarda 0 kabul edilir.

### ExplosiveCrateManager / ChainReactionResolver

Sandık sabit, eşleşmeyen, iki dayanıklılıklı engeldir. Tek olay içindeki birden çok komşu/ışın en fazla bir hasar verir. İkinci **ayrı** hasar olayı sandığı siler ve sınırlar içindeki 3×3 etkiyi kuyruğa ekler. Kenarlarda alan tahta sınırlarına kırpılır.

Her olay sıra numaralı benzersiz `event_id` taşır. Olay içindeki güçler bir kez genişletilir; sandık ID/hücre tetiklemeleri bir kez kaydedilir. Farklı sandık patlamaları farklı olaylardır; buz/taş/sarmaşık/sandık üzerinde hasar birikir. Aynı kristal, örtüşen alanlarda tek kez temizlenir ve puanlanır. Mevcut güçler zincirlenebilir; bu eşleşmede yeni yaratılan güçler sırf yaratıldığı için tetiklenmez. Sandık zinciri bittikten sonra yer çekimi/dolum ve Match-3 kaskadları devam eder.

Kuyruk yapısal olarak her sandık için en fazla bir patlama olayı üretebilir; ayrıca hücre sayısına bağlı güvenlik denetimi ve ayrıntılı incident kaydı vardır. Normal eski güç/hasar yolu sandık olmayan tahtalarda korunur.

### MirrorManager / BeamResolver

Ayna sabit ve yok edilemeyen bir engeldir; kristal eşleşmesine katılmaz. `/`: `(dx,dy) → (-dy,-dx)`; `\\`: `(dx,dy) → (dy,dx)`. İki yönün dört geliş açısı test edildi.

Roket, her zıt yöndeki ışını bağımsız çözer. Her ışın `(hücre, geliş yönü)` kümesi taşır; aynı duruma tekrar girerse güvenli biçimde durur. Ayna hücresi ışını yönlendirir ve normal temizleme alanına eklenmez. Tahta dışına çıkış ışını bitirir. Yollar animasyon verisine kaydedilir. Ayna yoksa önceki satır/sütun roket alanı kullanılır; bütün 72 başlangıç hücresi ve iki eksende eşdeğerlik test edildi.

Mevcut geniş prizma/roket kombinasyonlarının alan kuralı korunur. Tek roket ışınları ve `Powers.area` üzerinden üretilen roket alanları aynayla yansır; yeni bir ışın çoğaltma kuralı eklenmedi.

### Destek sınırları

8×9 tahtanın bütün hücreleri kullanılabilirdir; tahta dışı cihaz koordinatları reddedilir. Aynı kristal üzerinde birden fazla zırh/engel/özellik katmanı desteklenmez; geçersiz tanımlar reddedilir. Portal cihazının normal kristalle aynı koordinatta bulunması bu katman istiflemesi değildir. Önceki kesin joker/çift renk çözümleyicisinin mühendislik sınırı 8 esnek kristaldir; Okyanus kampanyasının en yoğun tahtasında yalnızca 3 esnek kristal bulunur. Yeni toplu hareket/ışın işlemleri animasyondan önce hesaplanır; giriş mevcut presentation kilidiyle korunur.

## Kristal Okyanus ve bölümler

İkinci dünya aralığı 51–100; bu teslimatta **yalnızca 51–75** oynanabilir. 50'nin tamamlanması 51'i açar. Eski tamamlanmış 50 kaydı yüklenirken katalogdaki gerçek yeni bölüm açılır; sonuçlar, madalya, ayarlar ve aktif uyumlu tahta korunur. Oyuncu iki dünya kartından Bahçe'ye dönebilir.

Okyanus kısmen renksiz başlar; kalıcı bölüm sonuçları o dünyanın doygunluğunu ve renk ışıklarını artırır. Arka plan dünya bazında değişir; düşük maliyetli yükselen baloncuklar ve ışıklar kalite/hareket ayarlarına uyar. Dünya kartları farklı kırpılmış gerçek illüstrasyonlar kullanır. `prizma/show_future_levels=false` hazırlık etiketini gizler; 76–100 hiçbir ayarda açılmaz.

- 51–55: Prizma Köprüsü ve gerçek kaydırma eğitimi.
- 56–60: Çivi, serbest bırakma, akıntı ve buz.
- 61–65: Köprü + buz / çift renk, otomatik zincirler.
- 66–70: Çivi + taş, buz + renk kilidi.
- 71–74: Birleşik hedefler ve güç stratejileri.
- 75: Güçlendirilmiş ara meydan okuma kutlaması; **dünya finali veya Okyanus madalyası değildir**. Gerçek final 100 için gelecekteki içerik gerekir.

Her bölümde açık layout, seed, hamle, hedef, yıldız ve zorluk tanımı bulunur. Başlangıçlar hazır çizgi içermeyecek şekilde normalize edildi; gerçek geçerli eğitim takasları kaydedildi. Her bölümün varsayılan seed'inde üç yıldızlı otomatik rota gösterildi. 20 refill seed'i/bölüm toplam 500 oyunda tamamlanma doğrulandı. Simülasyon gerekli yerde yön enerjisini de kullanır: dolu tahtada yön değişimi sonraki düşüşleri etkiler. İlk düz greedy denemede 3/500 oyun engellerin bulunduğu alt bölgeye ulaşamadı; yalnızca hamle artırmak çözmedi. Tahtayı/kuralları değiştirmek yerine simülasyon oyuncusuna mevcut yön stratejisi eklendi. Gereksiz hamle artışları geri alındı. İnsan zorluğu ve gerçek telefon oynanışı henüz doğrulanmış değildir.

## Görsel varlıklar ve ses

Yeni özgün su altı illüstrasyonu image generation aracıyla üretildi. Portal giriş/çıkış, kıvrımlı yaprak/diken sarmaşık, iki sandık hasar durumu, iki ayna yönü toplam 7 özgün 256 px SVG durum/1024×512 atlas içerir. Kaynak üreteç `tools/generate_mechanics4.py`; görseller emoji veya hazır ikon değildir. Mevcut beş kristal ve güç atlasları korunur.

Portal küçülme/yeniden belirme ve ışık parçaları 260 ms; sarmaşık giriş/yeşil ışık/yaprak etkisi 190 ms; hasar, sandık enerji/parça etkileri mevcut kısa clear dalgasına; yansıyan ışın çizgileri aynı animasyon kuyruğuna bağlıdır. Dört özgün kısa PCM sesi hazırlanmış, mevcut 5 ses kanalı havuzunda çalınır. Gerçek telefon hoparlörü, gecikme ve titreşim kalitesi ölçülmedi.

## Test kanıtları

Sonuç tabloları ve gerçek render kareleri rapor ZIP'indedir. Hiçbir fiziksel Android test sonucu başarılı olarak yazılmamıştır.

| Çalıştırılan suite | Kontrol | Başarısız |
| --- | ---: | ---: |
| Match-3, 2.000 başlangıç, ilk 10 bölümde 1.000 oyun | 21.969 | 0 |
| Kalite, worker kayıt, lifecycle, pool | 71 | 0 |
| İlk dört mekanik / 11–30, 600 oyun | 16.822 | 0 |
| İlk mekanik UI | 209 | 0 |
| Çift renk/joker kesin çözüm birim testleri | 2.081 | 0 |
| 31–50 / 400 oyun | 10.506 | 0 |
| Önceki 20 bölüm UI ve tüm hücre/kenarlar | 2.586 | 0 |
| Portal/sarmaşık/sandık/ayna, 100 ek tahta / 600 eylem | 3.154 | 0 |
| Okyanus 51–75 / 500 oyun | 18.455 | 0 |
| Yeni UI, 25 eğitim / 3 oran / dört sahne | 482 | 0 |
| **Toplam sayılan kontrol** | **76.335** | **0** |

Ek olarak dört ayrı native stress koşusu: **400 geçerli ScreenTouch kaydırma + 400 animasyonda engellenen duplicate giriş**, her koşuda sabit düğüm/partikül havuzu ve 0 hata. Save iki ayrı süreçte write/read; 16 gerçek renderer görüntüsü. Negatif testlerde kasıtlı cascade guard ve sarmaşık kurtarma diagnostic uyarıları beklenir; hata/başarısız test değildir. Paket içi 2.500 kampanya oyunu toplam 12.624 başarılı takas (4.128 + 3.085 + 1.932 + 3.479). On iki eski/yeni mekaniğin aynı tahtada 22 eylemlik karma fixture testi, yeni dev senaryoları, 200 yoğun sandık zinciri ve 300 joker-oracle senaryosu bunlara eklenir.


Yeni mekanik testlerinde dört gravity yönü, dolu portal, sabit/güç engeli, ID kopyalama/tekrar aktarım, portal sonrası eşleşme, vine sayaç/cap/temizleme/karıştırılamayan topoloji kurtarması, crate iki olay/örtüşen 3×3/200 yoğun zincir, güç/kaskad, iki ayna/dört geliş açısı/kapalı döngü/aynadan bağımsız eski roket davranışı yer alır. UI testleri 25 gerçek eğitim takasını native input ile çalıştırır; animasyonda duplicate giriş ve pause aynı logical snapshot'u korur. 3 ekran oranı/safe-area ve kenarlar kontrol edilir. Dört developer sahnesi gerçek ilerlemeden izoledir; sahne başına oynanış etkisi doğrulanır. 75 sonucu 76 veya dünya 2 madalyası açmaz.

Eski kayıtların yeni optional sayaçları varsayılanlarla restore edilir; iki işlemli mevcut kalıcılık testleri ve 50→51 ilerleme reload testi çalışır. Aynı seed + takas/yön dizisi exact snapshot eşitliği her Okyanus oyunu aşamasında karşılaştırılır. Data schema/rules 2 korunur; kullanıcı verisi sıfırlama yapılmaz. Daha eski APK'ya geri dönüşte yeni aktif tablo alanlarının destekleneceği iddia edilmez.

## Performans ölçümü

Linux/Xvfb 540×960, Godot 4.6.3 Compatibility, Mesa **llvmpipe LLVM 19.1.7 yazılımsal renderer**, `--max-fps 60 --profiling`. Bu ölçümler Android GPU veya cihaz gecikmesini temsil etmez. Gerçek frame aralıkları renderer açıkken alınır; headless mantık testleri FPS diye sunulmaz. Kare sınırı/VSync sürücü uyarısı kayıttadır. Simülasyonun test AI seçim hesaplaması da ana iş parçacığında çalışır; üretim swipe yolunda bu AI yoktur.

| Renderer koşusu | Eylem / kare | Ortalama FPS | Frame ort. / p95 / max (ms) | Mantık ort. / p95 / max (ms) |
| --- | ---: | ---: | --- | --- |
| Okyanus dengeli | 100 / 7611 | 59.27 | 16.871 / 18.325 / 180.294 | 3.809 / 10.296 / 16.623 |
| Dört sahne dengeli | 100 / 7028 | 58.69 | 17.038 / 19.141 / 300.691 | 2.384 / 4.560 / 7.013 |
| Okyanus performans | 20 / 1363 | 58.87 | 16.987 / 19.794 / 158.284 | 4.048 / 13.436 / 19.176 |
| Dört sahne performans | 20 / 1209 | 59.30 | 16.863 / 19.236 / 51.131 | 2.229 / 3.996 / 4.759 |

Dengeli laboratuvar 85 takas + 15 özel güç, 179 otomatik dalga içerir; 20 sahne değişimi de kare ölçümüne dahildir. Kısa performans koşularıyla uzun koşular doğrudan cihaz karşılaştırması değildir. Kalan 180/300 ms gibi kare sıçramalarında tüm süreyi oyun hesabına atfetmek doğru değildir: ham test AI seçimi, sahne geçişi ve llvmpipe render/senkronizasyon aynı örnek akışındadır. Nihai 100 eylemde engine max 7,013 ms, karıştırma max 1,213 ms; fiziksel Android nedeni/kararlılığı belirlenmedi.

Teşhis: ilk laboratuvar renderer koşusunda iki eylem 336/277 ms düzeyine çıktı. Aynı 100 eylem renderer kapalı tekrarlandı ve uzunluk `shuffle_logic` ile ayrıldı: mevcut karıştırmanın geri izleme araması en fazla 314,487 ms aldı; portal/beam küçük kaldı. Normal esnek olmayan tahtalara 24 denemelik, seed'e bağlı, renk stoklarını koruyan ağırlıklı kurucu eklendi. Oluşturulan sonuç yine hem hazır eşleşme hem geçerli hamle denetiminden geçer; eski kesin geri izleme yalnızca gerekli fallback olarak korunur. Sabit engeller/güçler hareket ettirilmez; yeni renk uydurulmaz. Jokerli tahtaların kesin çözüm yolu korunur. Aynı 100 eylemlik headless tekrarında shuffle maksimum 1,615 ms (üç gerçek karıştırma), tüm eylemler maksimum 5,993 ms oldu. Bu bir Android FPS ölçümü değildir. Önce/sonra ham veriler rapordadır; son renderer yeniden ölçümü aşağıdaki tabloda kullanılır. Eski başlangıç ve sonuç testleri bu değişiklikten sonra tekrar çalıştırıldı.


| Yeni işlem (lab dengeli) | Ortalama / p95 / max ms |
| --- | --- |
| portal_logic | 0.0078 / 0.0110 / 0.0310 |
| vine_logic | 0.0208 / 0.0210 / 0.0210 |
| effect_queue_logic | 0.2159 / 0.3790 / 0.4790 |
| beam_logic | 0.0170 / 0.0200 / 0.2280 |
| shuffle_logic | 1.0290 / 1.0060 / 1.2130 |

Son 2048 örnek cihaz JSON'u içinde portal, sarmaşık, olay kuyruğu, ışın, tarama, temizleme, gravity, dolum, çizim, CPU/GPU, save worker, peak memory/object ve slow-frame kayıtları tutulur. Dosyalar `docs/performance/ocean-*.json`, `lab-*.json`. Render CPU/GPU süreleri frame süresine eklenmez; process ölçümü saf mantık süresi değildir. 16,7 ms tüm karelerde garanti edilmez; yavaş kareler gizlenmez.

Tahta aynı 6 sabit alt düğümü ve 192 parçacık slotunu korur. Portal/sarmaşık parçaları aynı havuzdadır; yeni scene yaratımı yoktur. Aynalar hücre-yön, sandıklar tetikleme kümeleriyle sınırlanır. Dünya illüstrasyonları/resource atlasları cache'lenir; drag sırasında yüklenmez. Background hareketi düşük kalitede kapatılır. Yeni güç ve çevre hesaplamaları yalnızca eylem/çözümleme evresinde çalışır.

## Android teslimatı ve kalan cihaz doğrulamaları

`prizma-v0.6.0.apk`: **63,301,566 byte**, Android 7+/min SDK 24, target SDK 36, ARMv7 ve ARM64; versionCode 6, versionName 0.6.0. Paket `com.prizma.renklerinuyanisi.match3`. İnternet izni yok; VIBRATE var. APK imzası v2/v3 doğrulandı; sertifika SHA-256 `01bb7474354b56e234ce24df50fd2e1ef45c838111b364cd0b3894bf8bb8360a`, önceki 0.2–0.5 test sürümleriyle aynı. **Mevcut Match-3 uygulamasını kaldırmadan güncelleyin.**

APK SHA-256: `aa2cda6c728c7d23ec12f3051bea8a16e3470d07e31b878590a1678c5383c124`. Bütün 75 bölümün APK içindeki JSON byte'ları kaynak dosyalarıyla birebir karşılaştırıldı. Runtime digest: `cd24e936f59bfcaa6e0f80dc9434351a684656c3fc547a0e331eca7daa118185`.

APK debug/test sürümüdür. Godot editörü veya test APK'sında **Ayarlar → Geliştirici: mekanik laboratuvarı → Test araçları** ile dört ayrı sahne açılır; alt açıklama nasıl tetikleneceğini gösterir. Normal Android preset'inde geliştirici özelliği yoktur. Kampanya her iki preset'te yeni dört mekaniği açmaz.

Bulutta `adb devices -l` listesi boştur. Gerçek kurulum/güncelleme, eski cihaz verisi migrasyonu, fiziksel touch gecikmesi, ekran çentiği/system bar, 60 FPS/termal kararlılık, ses/haptics ve Android OS background/resume henüz cihazda test edilmemiştir. Masaüstünde safe-area override, input, pause ve save geçişleri doğrulanmıştır. Telefonda ölçüm için ayarlardan rapor kopyalanabilir; otomatik yükleme/internet izni yoktur.

## Değişen dosyalar

94 dosya (rapor ZIP için CI workflow dahil; kaynak/asset/import/UID/kanıt). Aşağıdaki liste `.uid` ve `.import` eşlikçilerini ana varlıklarıyla birlikte gruplar.

- `.github/workflows/android-test-release.yml`
- `README.md`
- `assets/CREDITS.md`
- `assets/art/ocean.png`
- `assets/audio/crate.wav`
- `assets/audio/mirror.wav`
- `assets/audio/portal.wav`
- `assets/audio/vine.wav`
- `assets/mechanics4/atlas.svg`
- `assets/mechanics4/crate-1.svg`
- `assets/mechanics4/crate-2.svg`
- `assets/mechanics4/mirror-backslash.svg`
- `assets/mechanics4/mirror-slash.svg`
- `assets/mechanics4/portal-entry.svg`
- `assets/mechanics4/portal-exit.svg`
- `assets/mechanics4/vine.svg`
- `data/levels-51-75.json`
- `docs/MECHANICS_ROADMAP.md`
- `docs/PACKAGE4_REPORT.md`
- `docs/RELEASE_v0.6.0.md`
- `docs/STATUS.md`
- `docs/performance/lab-balanced.json`
- `docs/performance/lab-low.json`
- `docs/performance/ocean-balanced.json`
- `docs/performance/ocean-level-tests.json`
- `docs/performance/ocean-low.json`
- `docs/performance/ocean-native-swipes.json`
- `docs/performance/package4-lab-before-diagnosis.json`
- `docs/performance/package4-shuffle-after.json`
- `docs/performance/package4-shuffle-before.json`
- `export_presets.cfg`
- `project.godot`
- `scripts/core/board.gd`
- `scripts/core/board_generator.gd`
- `scripts/core/level_catalog.gd`
- `scripts/core/powerups.gd`
- `scripts/mechanics/beam_resolver.gd`
- `scripts/mechanics/chain_reaction_resolver.gd`
- `scripts/mechanics/developer_scenarios.gd`
- `scripts/mechanics/explosive_crate_manager.gd`
- `scripts/mechanics/mechanic_registry.gd`
- `scripts/mechanics/mirror_manager.gd`
- `scripts/mechanics/objective_manager.gd`
- `scripts/mechanics/portal_manager.gd`
- `scripts/mechanics/vine_manager.gd`
- `scripts/ui/audio_manager.gd`
- `scripts/ui/board_view.gd`
- `scripts/ui/celebration.gd`
- `scripts/ui/garden.gd`
- `scripts/ui/main.gd`
- `scripts/ui/mechanic4_animation.gd`
- `scripts/ui/mechanic_animation_controller.gd`
- `scripts/ui/performance_metrics.gd`
- `tests/move_solver.gd`
- `tests/ocean_levels.gd`
- `tests/package2_levels.gd`
- `tests/package2_ui.gd`
- `tests/package4_capture.gd`
- `tests/package4_diagnostics.gd`
- `tests/package4_tests.gd`
- `tests/package4_ui.gd`
- `tests/swipe_stress.gd`
- `tests/visual_performance.gd`
- `tools/build_android.sh`
- `tools/generate_mechanics4.py`
- `tools/normalize_ocean.gd`
- `tools/test.sh`

0.6.0 kaynak commit'i ve tag'i sürüm sayfasındadır. APK, exact runtime digest ve public asset SHA-256 karşılaştırması yayımdan sonra ayrıca doğrulanır. Sonraki paket kullanıcı onayı gelmeden başlatılmaz.
