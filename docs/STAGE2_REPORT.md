# PRİZMA 0.4.0 — İkinci aşama teslimat raporu

2026-10-13 · Godot 4.6.3 · Android test sürümü

Mevcut 0.3.0 oyunu genişletildi. İlk dört mekanik ve 11–30. bölümler tamamlandı;
sonraki 16 mekanik yalnızca [planda](MECHANICS_ROADMAP.md). Mağaza, PRO, satın alma,
yeni dünya veya başka mekanik geliştirilmedi. Bu teslimattan sonra duruldu.

## Çalışan mekanikler

- **Tohum kapsülü:** sabit hücre işgalcisi, iki dayanıklılık. Komşu yatay/dikey
  patlama veya doğrudan güç bir dalgada bir darbe verir. İkinci dalgada çiçek açar,
  çiçek hedefi bir kez ilerler; hücre serbest kalır ve dolar. Kapalı/çatlak kapsül,
  büyüyen çiçek, yapraklar ve ışık halkası var.
- **Buz zırhı:** kristalin üzerindeki ayrı koruma. Kristal içeride görünür; buz
  varken takas ve renk eşleşmesi yapamaz, yer çekiminde sabit kalır. Her dalgada
  en fazla bir katman kırılır. İki katmanın sonunda aynı kimlik/renkte kristal
  korunur. Buz hedefi kaldırılan katmanları sayar; çatlak ve mavi-beyaz parçacıklar var.
- **Taş engel:** sabit hücre işgalcisi, üç dayanıklılık. Komşu patlama ve doğrudan
  roket bir hasar; doğrudan prizmanın iki hücrelik etki alanı iki hasar verir.
  Kesişimler hasarı toplamaz; tek dalgada en güçlü geçerli hasar uygulanır.
  Üç çatlak seviyesi, taş parçaları, toz renkleri ve isteğe bağlı hafif sarsıntı var.
- **Renk kilidi:** hücreye bağlı sabit engel. Renk ve enerji gereksinimi bölüm
  verisindedir. Her dalgada yalnızca gerçekten temizlenen, benzersiz normal
  kristaller sayılır; özel kristaller ve korunmuş buz içeriği sayılmaz. Zincirler
  katkı verir; her kilit kendi enerjisini tutar. Aynı renkli kilitler aynı renk
  toplamından bağımsız ilerler. Beş renkli özgün kilit, enerji halkası ve sayaç var.

Buz veya engel kalkınca yer çekimi/dolum ve yeniden eşleşme taraması aynı mevcut
çözümleyicide devam eder. Zincir başına ilave hamle yoktur. Bütün hedefler son
zincir bitince değerlendirilir. Son hamlede kapsülün ikinci dalgada açılması kazanma
olarak test edildi. Normal dokunarak patlatma eklenmedi.

## Mimari ve korunmuş kod

`MechanicRegistry` yalnızca dört çalışan kural modülünü kaydeder; `MechanicManager`
hasar/enerji işlemini yönetir; `DamageResolver` dalgadaki komşu ve doğrudan etkileri
birleştirir; `ObjectiveManager` çoklu hedefleri kontrol eder. Normal/özel kristal,
`obstacle` hücre işgalcisi ve `armor` koruması ayrı veridir. Boş gelecek sınıfları
oluşturulmadı. Mekanik modülleri ortak `resolve(data, damage, colors)` sözleşmesini
uygular; kural modülünü değiştirmek için takas veya yer çekimi motoru yeniden yazılmaz.

**`data/levels.json`, `match_detector.gd`, `gravity.gd`, `resonance.gd` ve `score.gd`
değiştirilmedi.** Menü, bahçe, beş kristal, güçler, dört yönlü yer çekimi, rezonans,
hamle sayımı, kayıt ve önceki kaliteli efektler korunur. Bölüm katalogu yeni
`levels-11-30.json` verisini ekler. Dünya kimliği her 50 bölümde ilerleyecek şekilde
hesaplanır; şu anda tüm bölümler Büyülü Bahçe'dir.

13 özgün 256 px SVG durum tek 1024×1024 atlası kullanır; yeni sahne düğümü veya
emoji yoktur. Kristallerin yanındaki atlas kırpılması render görüntülerinde bulundu;
doğrudan atlas bölgesi çizimiyle giderildi. 126 gerçek render piksel kontrolü
normal yakutların görünür kaldığını doğrular. Normal kristal çizimleri ardından
koruma/engel çizimleri yapılır; kilit metinleri enerji değişince önbelleğe alınır.
Efekt havuzu 192 parçacık, kaliteye göre sınırlı etkin bütçe ve altı sabit BoardView
çocuğu ile korunur. Animasyon yalnızca değişmez sonuç karelerini oynatır.

## Kayıt ve geri dönüş noktası

Git etiketi **`backup/crystal-quality-v0.3.0`**, başlangıç commit'i **f675f34**;
Git bundle doğrulandı. Hiçbir eski kayıt silinmedi. Schema 2 korunur; mekanik
sayaçları eski aktif tahtalarda sıfır varsayılır, RNG/hamle/puan/renkler korunur.
Tamamlanmış 10. bölümün eski katalog sınırı 11'e yükselir. Kayıt doğrulaması artık
30 bölümü ve koruma/engel dayanıklılığı/enerjisini tanır. JSON dolum renkleri
başlangıçta ve geri yüklemede tamsayıya normalleştirilir; bulunan karşılaştırma
hatası düzeltilmiştir. Bozuk katmanlar script hatası üretmeden reddedilir.

Aynı paket ve önceki kalıcı test imzası kullanılır. **0.2/0.3 Match-3 üzerine
kurun; uygulamayı kaldırmayın.** Fiziksel cihazdaki veri dönüşümü bu ortamda
çalıştırılmadı. Masaüstü test profillerinde eski schema 2, 10→11 geçişi, tekrar
ödülünün engellenmesi, aktif mekanikler ve iki ayrı süreçte devam doğrulandı.

Geliştirici laboratuvarı editör veya `prizma_dev_tools` özelliği olan test APK'sında
Ayarlar'dan açılır. Seed, hedef hücre ve dört mekanik ekleme/reset var. Bu tahta
normal aktif kayıt, ilerleme veya ödülleri değiştirmez. Normal Android hedefinde
araç özelliği yoktur; laboratuvar gösterilmez.

## Gerçek otomatik test sonuçları

| Test | Sonuç |
| --- | --- |
| Mevcut Match-3 motoru | 21.969 kontrol, 0 başarısız |
| Mevcut kalite / havuz / kayıt / ölçek | 71 kontrol, 0 başarısız |
| Yeni mekanik motoru | 16,822 kontrol, 0 başarısız |
| Yeni bölüm arayüzü / test laboratuvarı | 209 kontrol, 0 başarısız |
| İlk 10 bölüm native ScreenTouch | 100 geçerli + 100 engellenen ikinci giriş |
| Yeni mekanik bölümleri native ScreenTouch | 100 geçerli + 100 engellenen ikinci giriş |
| Görsel piksel / atlas görünürlüğü | 126 kontrol, 0 başarısız |
| İki ayrı süreçte kalıcı kayıt | Aynı tahta, RNG ve puanla devam |
| Render ekran oranları | 540×960, 540×1170, 540×1200 |
| Android export | SDK, imza, izinler, iki ARM kitaplığı, 20 ek bölüm verisi doğrulandı |

Sayılan motor/kalite/mekanik/UI kontrolleri toplamı **39.071**. Ayrıca native swipe
stresleri ve grafik piksel kontrolleri çalıştırıldı. İlk on bölümde **1.000 oyun /
4.128 hamle**, yeni yirmi bölümde **600 oyun / 3.085 hamle**. Ayrıca mevcut motorun
2.000 bağımsız başlangıç tahtası kontrolü tekrar geçti. Yeni bölümler yalnızca
üretilmedi: her biri 30 dolum seed'i ile sonuca kadar oynandı, her hamlede aynı
seed/eylemin ikinci motorda aynı sonucu vermesi ve geri yüklenebilirlik kontrol edildi.

Tohum/buz/taş tek-dalga hasarı, çapraz reddi, buzun içeriğinin korunması, üç taş
hasarı, prizma/roket alanları, kilitte yanlış renk reddi, farklı kilitler, özel güç
kesişiminde tek kristal sayımı, mekanikli ücretsiz karıştırma, dört yönde boşluk
oluşturulmuş çevresel dolum, son hamle zinciri, çoklu hedef ve geçiş test edildi.
20 yeni bölümün UI olayları, sabit kenar hücreleri, hızlı tekrar giriş, simüle
arka plan/pause ve devam da test edildi. İlk bulunan kayıt karşılaştırma hatası
ve render atlas kırpılması düzeltildi; etkilenen kontroller tekrar geçti.

## Bölüm dengesi

İlk tanıtımlar kontrollü açılış eşleşmesi ve otomatik dalgayla mekanik etkisini
gösterir. Daha sonraki bölümler birden fazla mekanik ve hedefi birleştirir; engel
sayısı tek zorluk ölçütü değildir. Hamle bütçeleri ölçülen çözümler üzerinden
ayarlanmıştır. Yıldız eşikleri başlangıç seed'inin oynanmış kazanma puanından
2★ için yaklaşık %65, 3★ için %90 ve 50 puan yuvarlama ile belirlenmiştir.
Her bölümün başlangıç seed'inde üç yıldız alabilen rota otomatik doğrulandı.

| Bölüm | Ad | Hamle bütçesi | 30 oyunda en çok kullanılan | Kazanma | 2★ / 3★ |
| --- | --- | --- | --- | --- | --- |
| 11 | Uyuyan Tohum | 12 | 1 | 30/30 | 1050 / 1450 |
| 12 | İkiz Filizler | 14 | 5 | 30/30 | 2300 / 3150 |
| 13 | Çiçek Yolu | 16 | 3 | 30/30 | 1900 / 2650 |
| 14 | Yankılı Yapraklar | 18 | 5 | 30/30 | 2550 / 3550 |
| 15 | Tohum Korusu | 22 | 10 | 30/30 | 3700 / 5150 |
| 16 | İlk Buz Çatlağı | 12 | 1 | 30/30 | 1900 / 2600 |
| 17 | Safir Kabuğu | 18 | 9 | 30/30 | 1750 / 2450 |
| 18 | Buz ve Filiz | 20 | 8 | 30/30 | 1850 / 2600 |
| 19 | Donmuş Patika | 24 | 12 | 30/30 | 3300 / 4600 |
| 20 | Kristal Çözülme | 26 | 13 | 30/30 | 3800 / 5250 |
| 21 | Taşın İçindeki Işık | 14 | 1 | 30/30 | 1150 / 1650 |
| 22 | Buzlu Kaya | 24 | 13 | 30/30 | 3150 / 4350 |
| 23 | Üç Darbenin Dansı | 32 | 24 | 30/30 | 3900 / 5400 |
| 24 | Saklı Çiçekler | 24 | 9 | 30/30 | 3950 / 5450 |
| 25 | Kaya Bahçesi | 34 | 24 | 30/30 | 7250 / 10050 |
| 26 | Kızıl Kilit | 14 | 2 | 30/30 | 1000 / 1350 |
| 27 | İki Rengin Anahtarı | 18 | 4 | 30/30 | 2950 / 4100 |
| 28 | Kilitli Filizler | 38 | 31 | 30/30 | 3400 / 4750 |
| 29 | Donmuş Anahtar | 34 | 24 | 30/30 | 4350 / 6050 |
| 30 | Bahçenin Dört Mührü | 32 | 21 | 30/30 | 3350 / 4650 |

Bunlar hedef odaklı bir otomatik oyuncunun sonuçlarıdır; insan oyuncu zorluğu ve
zevk değerlendirmesinin yerine geçmez. Evrensel kazanılabilirlik garantisi verilmez.

## Ölçülen performans

Gerçek Godot Compatibility renderer, Xvfb 540×960, Linux **llvmpipe (LLVM 19.1.7, 256 bits)**,
60 FPS sınırı, `--profiling`, native Performance ve RenderingServer CPU/GPU
ölçümleri. Fiziksel Android veya donanım GPU'su kullanılmadı.

- Dengeli: **100 hamle / 199 patlama dalgası / 7805 frame**.
  Ham frame aralığı ortalama **16.726 ms ≈ 59.8 FPS**;
  p95 **17.437 ms**, maksimum **214.187 ms**.
- Performans: **20 hamle / 33 dalga / 1329 frame**.
  Ortalama **16.840 ms ≈ 59.4 FPS**, p95 **17.929 ms**,
  maksimum **92.694 ms**. Bu kısa ve farklı örneklem doğrudan karşılaştırma değildir.
- Ortalama draw call: dengeli **159.0**;
  performans **95.0**. Mantık/kurallar kaliteye göre değişmez.
- Dengeli tanılama: tepe statik bellek **41,666,642 byte**,
  tepe canlı nesne **1880**.

| İşlem | Ortalama | p95 | Maksimum |
| --- | --- | --- | --- |
| Tüm takas + zincir mantığı | 1.625 ms | 2.735 ms | 3.392 ms |
| Sunum + arka plan kayıt isteği | 0.487 ms | 0.878 ms | 1.087 ms |
| Eşleşme taraması | 0.096 ms | 0.143 ms | 0.389 ms |
| Patlama mantığı | 0.158 ms | 0.250 ms | 0.333 ms |
| Mekanik hasar/enerji işlemi | 0.053 ms | 0.077 ms | 0.176 ms |
| Yer çekimi | 0.058 ms | 0.083 ms | 0.195 ms |
| Yeni blok üretimi | 0.025 ms | 0.034 ms | 0.084 ms |
| Tahta CPU çizim komutları | 0.391 ms | 0.595 ms | 2.706 ms |
| Renderer CPU | 2.110 ms | 4.410 ms | 34.925 ms |
| Renderer GPU / yazılım sürücüsü | 8.543 ms | 11.609 ms | 36.032 ms |

Tam frame ve takas serileri 100 hamleyi kapsar. Oyun tanılama penceresi son 2.048
örnekle sınırlıdır; renderer/çizim satırlarının penceresi bütün koşuyla eşit değildir.
`Performance.TIME_PROCESS` renderer/senkronizasyon işlerini de içerebilir; saf
mantık süresi olarak yorumlanmadı. CPU/GPU ve frame süreleri birbirine eklenmez.

**Her frame 16,7 ms altında değildir.** Nadir uzun frame'ler bağlamlarıyla kayda
alındı: final dengeli koşuda 214 ms örnek `clear` fazındaydı; ready/refill fazlarında
da 50 ms üstü örnekler var. Tüm takas/zincir mantığı maksimum 3,392 ms ölçüldü.
Bu veriler uzun frame'in tek başına eşleşme taramasından kaynaklandığını göstermiyor;
Linux yazılım renderer / işletim sistemi beklemesini Android'deki bir donma nedeni
olarak kesinleştirmiyoruz. Cihazın gerçek GPU, dokunma gecikmesi ve ana thread
izleri olmadan telefon için 60 FPS ya da sıfır takılma garantisi verilemez.

Ham JSON raporları `docs/performance/stage2-*.json` içindedir. Android'de Ayarlar >
Performans ölçümü / rapor, frame ve dokunma/işlem sürelerini kopyalar; rapor
kendiliğinden dışarı gönderilmez. Cihazda karşılaştırma için aynı bölüm/ayar/seed
ve Godot remote profiler kullanın. Bu ortamda Godot editörünün Android remote
profiler bağlantısı kurulmadı.

## APK ve cihaz kabul testi

Yerel çıktı `build/prizma-match3.apk`; yayın adı **`prizma-v0.4.0.apk`**.
Sürüm **0.4.0 / kod 4**, paket **`com.prizma.renklerinuyanisi.match3`**.
**59.745.156 byte**; SHA-256:
`101b543151c5abb316f85e66d50e40cb39e36e72c26c3ef7de894f20b0cea556`.
Android 7.0+ / min SDK 24, target SDK 36, ARMv7 ve ARM64. İnternet izni yok;
titreşim izni var. v2 ve v3 imzası doğrulandı. Önceki 0.3.0 ile aynı sertifika:
`01bb7474354b56e234ce24df50fd2e1ef45c838111b364cd0b3894bf8bb8360a`.
Özel imzalama anahtarı Git'e veya rapor paketine dahil edilmedi.

ADB listesi boş. **Fiziksel Android kurulum/güncelleme, parmak hissi, gerçek FPS,
ses/titreşim, cihaz sıcaklığı/pil, gerçek OS arka plana alma ve çentikler test
edilmedi.** Masaüstü input/lifecycle testleri bunların yerine geçmiş sayılmaz.

Telefonda APK'yı mevcut Match-3 üzerine kurup kayıt devamını ve 10→11 geçişini
kontrol edin. 11/16/21/26'da mekanik öğretimlerini, 30'da kombinasyonu oynayın;
hızlı kaydırma, geçersiz takas, dört yön, arka plana alıp geri dönme ve düşük kalite
seçimini deneyin. Cihaz performans raporunu bu testten sonra paylaşabilirsiniz.
30 bölüm ve dört mekanikten sonra burada durulur; yeni mekanik grubu onay bekler.

## Değişen dosyalar

Aşağıdaki liste uygulama, görsel kaynaklar, otomatik test ve teslimat dosyalarını
kapsar. `build/`, Godot import cache'i ve imzalama anahtarı Git dışında tutulur.

- `.github/workflows/android-test-release.yml`
- `README.md`
- `assets/CREDITS.md`
- `assets/mechanics/atlas.svg`
- `assets/mechanics/atlas.svg.import`
- `assets/mechanics/flower.svg`
- `assets/mechanics/flower.svg.import`
- `assets/mechanics/ice-1.svg`
- `assets/mechanics/ice-1.svg.import`
- `assets/mechanics/ice-2.svg`
- `assets/mechanics/ice-2.svg.import`
- `assets/mechanics/lock-0.svg`
- `assets/mechanics/lock-0.svg.import`
- `assets/mechanics/lock-1.svg`
- `assets/mechanics/lock-1.svg.import`
- `assets/mechanics/lock-2.svg`
- `assets/mechanics/lock-2.svg.import`
- `assets/mechanics/lock-3.svg`
- `assets/mechanics/lock-3.svg.import`
- `assets/mechanics/lock-4.svg`
- `assets/mechanics/lock-4.svg.import`
- `assets/mechanics/seed-1.svg`
- `assets/mechanics/seed-1.svg.import`
- `assets/mechanics/seed-2.svg`
- `assets/mechanics/seed-2.svg.import`
- `assets/mechanics/stone-1.svg`
- `assets/mechanics/stone-1.svg.import`
- `assets/mechanics/stone-2.svg`
- `assets/mechanics/stone-2.svg.import`
- `assets/mechanics/stone-3.svg`
- `assets/mechanics/stone-3.svg.import`
- `data/levels-11-30.json`
- `docs/MECHANICS_ROADMAP.md`
- `docs/RELEASE_v0.4.0.md`
- `docs/STAGE2_REPORT.md`
- `docs/STATUS.md`
- `docs/performance/stage2-balanced.json`
- `docs/performance/stage2-level-tests.json`
- `docs/performance/stage2-low.json`
- `docs/performance/stage2-native-swipes.json`
- `export_presets.cfg`
- `project.godot`
- `scripts/core/board.gd`
- `scripts/core/level_catalog.gd`
- `scripts/core/powerups.gd`
- `scripts/core/save_manager.gd`
- `scripts/mechanics/color_lock.gd`
- `scripts/mechanics/color_lock.gd.uid`
- `scripts/mechanics/damage_resolver.gd`
- `scripts/mechanics/damage_resolver.gd.uid`
- `scripts/mechanics/ice_armor.gd`
- `scripts/mechanics/ice_armor.gd.uid`
- `scripts/mechanics/mechanic_manager.gd`
- `scripts/mechanics/mechanic_manager.gd.uid`
- `scripts/mechanics/mechanic_registry.gd`
- `scripts/mechanics/mechanic_registry.gd.uid`
- `scripts/mechanics/objective_manager.gd`
- `scripts/mechanics/objective_manager.gd.uid`
- `scripts/mechanics/seed_capsule.gd`
- `scripts/mechanics/seed_capsule.gd.uid`
- `scripts/mechanics/stone_obstacle.gd`
- `scripts/mechanics/stone_obstacle.gd.uid`
- `scripts/ui/board_view.gd`
- `scripts/ui/main.gd`
- `scripts/ui/mechanic_animation_controller.gd`
- `scripts/ui/mechanic_animation_controller.gd.uid`
- `scripts/ui/strings.gd`
- `tests/mechanic_capture.gd`
- `tests/mechanic_capture.gd.uid`
- `tests/mechanic_tests.gd`
- `tests/mechanic_tests.gd.uid`
- `tests/mechanic_ui_tests.gd`
- `tests/mechanic_ui_tests.gd.uid`
- `tests/move_solver.gd`
- `tests/run_tests.gd`
- `tests/swipe_stress.gd`
- `tests/visual_performance.gd`
- `tools/build_android.sh`
- `tools/generate_mechanics.py`
- `tools/test.sh`
