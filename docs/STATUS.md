## Güncel: PRİZMA v0.10.0

[Gökkuşağı Kanyonu sürümü](https://github.com/hakannnyalcinnn/tonton-akademi-v1-2/releases/tag/v0.10.0) · [Rapor](v010/REPORT.md). İlk 100 bölüm korunuyor; 150 bölüm, 20 mekanik. Gerçek Android kabul testi bekliyor.

# Güncel çalışma — PRİZMA 0.9.0 / Oynanış 2.0

Otomatik Prizma Fırtınası, Kristal Dalgası, 100 bölüm dengelemesi ve görsel/ses revizyonu için güncel kaynak [GAMEPLAY2_REPORT.md](GAMEPLAY2_REPORT.md) dosyasıdır. Aşağıdaki sürüm notları geçmiş kaydıdır. Gerçek Android cihaz kabul testleri ayrıca gereklidir.

---

# Güncel durum — 0.6.0

Kristal Okyanus ve dördüncü paket için [PACKET4 test ve teslimat raporu](PACKAGE4_REPORT.md) güncel kaynaktır. Aşağıdaki önceki sürüm notları tarihî kayıt olarak korunur.

# Güncel sürüm: PRİZMA 0.5.0 — İki Rengin Uyanışı

İlk 50 bölüm, çift renkli kristal, bukalemun ve dünya finali tamamlandı. Köprü ve çivi test edilmiş geliştirici mekanikleridir; normal ilk 50 bölümde kilitli kalır. Güncel ayrıntılar: [PACKAGE2_REPORT.md](PACKAGE2_REPORT.md). Sonraki mekanik grubuna geçilmedi. Aşağıdaki sürüm raporları geçmiş kaydıdır.

---

# Güncel sürüm: PRİZMA 0.4.0 — Bahçenin Sırları

İkinci aşamanın ilk dört mekaniği ve 11–30. bölümler tamamlandı. İlk 10 bölüm ve mevcut Match-3 kuralları korundu. Yeni teslimatın testleri, ölçümleri, dosya listesi ve Android kabul testi sınırları: [STAGE2_REPORT.md](STAGE2_REPORT.md). Sonraki 16 mekanik yalnızca [planda](MECHANICS_ROADMAP.md); kullanıcı onayı bekleniyor.

Aşağıdaki raporlar önceki sürümlerin geçmiş kaydıdır.

---

# Güncel sürüm: PRİZMA 0.3.0 — Büyülü Kristaller

Görsel kalite revizyonu tamamlandı; ilk 10 bölüm ve Match-3 kuralları korundu. Yeni durum, gerçek ölçümler, test sonuçları ve cihazda henüz doğrulanmayanlar: [QUALITY_REVISION.md](QUALITY_REVISION.md). 21.969 motor + 71 kalite kontrolü ve 100 geçerli/100 engellenen ScreenTouch kaydırması doğrulandı. Fiziksel Android kabul testi bekleniyor.

Aşağıdaki 0.2.0 raporu önceki motor revizyonunun geçmiş kaydıdır.

---

# PRİZMA 0.2.0 Match-3 revizyonu — Durum raporu

## Doğrulanan motor
Mevcut Godot projesi korunarak normal dokunarak patlatma kaldırıldı. Sürükleme yalnızca dört yönde bir komşuya takas yapar. En az üçlü yatay/dikey çizgiler ve kesişimleri çözülür; düzensiz kümeler/ikili/çapraz patlamaz. Geçersiz takas animasyonla geri alınır, bütün sayaçlar ve RNG korunur. Otomatik patlat → yer çekimi → dolum → yeniden tara zinciri tek oyuncu hamlesiyle tamamen çözülür.

4 düz roket, 5 düz renk bombası, T/L prizma; üretim önceliği/konumu ve güç istisnaları açık tanımlıdır. Yeni güç ilk dalgada kendiliğinden tetiklenmez. Rezonans ilk dalgadaki bir oyuncu hamlesine bir kez ilerler; çok renkli eşleşme hedef hücreye göre seçilir. Dört yön, enerji ve ücretsiz karıştırma korunur. Sabit hücreler sıkıştırma segmentini böler ve karıştırmada yerinde kalır; ilk on bölüme engel oyunu eklenmez.

READY → SWAPPING/CHECKING_MATCHES → RESOLVING_MATCHES/PLAYING_EFFECTS → APPLYING_GRAVITY/REFILLING/CHECKING_CASCADES → CHECKING_OBJECTIVES → READY/LEVEL_COMPLETED/LEVEL_FAILED; REVERTING_SWAP, SHUFFLING ve PAUSED kontrollü kullanılır. Mantık son kararlı sonucu hesaplar; animasyon kuyruğu ve sunum kilidi ikinci hamleyi engeller. Kayıtlar animasyon ortasını içermez.

## Gerçek test sonuçları
`PRIZMA_TOOLS_DIR=/workspace/prizma-tools bash tools/build_android.sh`:
- **21.969 kontrol, 0 başarısızlık**.
- **2.000 farklı seed'li başlangıç tahtası**: hazır eşleşme yok, en az bir geçerli eylem var, başlangıç kendiliğinden puan/hamle üretmez.
- **1.000 oyun / 4.128 başarılı hamle**: tüm 10 bölümde 100 dolum seed'i. Hedef odaklı otomatik oyuncu her bölümde 100/100 kazandı. Bu insan oyuncu deneyimi için kapsamlı dengeleme yerine geçmez.
- Her işlem sonunda negatif hamle yok, 72 eşsiz hücre kimliği, enerji sınırı, hazır eşleşmesiz kararlı tahta ve geçerli sonraki eylem; aynı seed/eylem için aynı snapshot.
- İkili, yatay/dikey üçlü, çapraz, düzensiz küme, T/L birleşimi ve hücre tek sayımı.
- Normal dokunmanın etkisizliği, uzak/çapraz reddi, geçersiz takasın RNG dahil tam geri alımı ve iki parçalı geri dönüş animasyonu.
- Oyuncu ve otomatik dalgada güç üretim konumu, öncelik, oluşturma dalgasında korunma, özel-normal/özel-özel istisnaları ve renk seçimi.
- Otomatik zincir ek giriş/hamle gerektirmez; merkezi en çok x5 çarpan; rezonans yalnızca bir kez ve çok renkli takasta deterministik.
- Dört yönlü düşüş/dolum, karşı kaynak kenarı, sabit segmentler, ücretsiz renk/kimlik koruyan karıştırma ve eşleşmesiz/oynanabilir son tahta.
- Son hamlede ilk dalgada hedef eksikken ikinci dalganın tamamlanmasıyla kazanma; sonuç/bonus bir kez, terminal giriş kilidi.
- **Gerçek GUI olayları:** mouse ve native ScreenTouch, dört yönde yavaş sürükleme, hızlı/kısa ve uzun sürükleme, çapraz/tahta dışı/küçük hareket iptali, normal dokunma, hızlı ikinci giriş, animasyon sırasında PAUSED/geri dönüş, yardım/ayar/ölçek.
- **İki ayrı Godot sürecinde** kaydedilen oyunun aynı yeni takas/zincir/RNG/puanla devamı.
- Schema 1 eski dosyanın byte olarak `.v1-archive` korunması; ilerleme/ayar/en iyi sonuç/ödül kimliği, eski aktif tahta arşivi, yeni bölümün tam bütçesi ve geçiş bildirimi. Yeniden başlatmada idempotent dönüşüm; gelecek schema üzerine yazılmaz.

Başarısız kalan otomatik test veya sıfır test koşusu yoktur. İlk çalıştırmada JSON integer/float karşılaştırması kaynaklı üç dönüşüm kontrolü başarısızdı; sayısal canonical dönüşüm düzeltilip bütün etkilenen testler yeniden geçirildi. Normal dokunarak patlatma API'si ve eski eşleşme yardım metni aktif koddan kaldırıldı.

## Görsel ve Android kontrolü
Xvfb/Mesa Compatibility renderer ile aynı fantastik bahçe/ana menü, yeni kararlı tahta/sürükleyen el, harita/ayar ve oynanarak kazanılan sonuç ekranı render edildi; `build/*.png` incelendi. Xvfb'nin V-Sync uyarısı cihaz FPS ölçümü değildir. Son loglarda script hatası veya kaynak sızıntısı yoktur.

Gerçek çıktı **`build/prizma-match3.apk`**, sürüm 0.2.0/kod 2; `com.prizma.renklerinuyanisi.match3`, Android 7.0+ (SDK 24), hedef SDK 36, ARMv7/ARM64. APK v2/v3 imzası, bölüm verisi, iki mimarinin Godot kitaplığı ve internetsiz manifest doğrulandı. SHA-256 dosyası yanında üretilir. Orijinal Android preset aynı uygulama kimliğiyle korunur.

Önceki yayımlanan APK'nın CI özel imzası mevcut değildir. Verileri silen kaldırma/yeniden kurma önerilmez: yeni test APK'sı ayrı profille yan yana kurulur. Eski cihaz kayıtlarının ayrı test profiline otomatik aktarıldığı iddia edilmez. Aynı anahtarla normal güncellemede kodun schema geçişi desteklenir. Yeni imzalama malzemesi çalışma alanı araç dizininde korunur; Git dışında kalır. Yayın akışı yerelde doğrulanmış APK'yı imzasını değiştirmeden alır, runtime kaynak özeti/SHA-256/imzayı doğrular ve yükler.

## Cihazda doğrulanmayanlar
ADB listesi boş. Fiziksel Android kurulum/açılış, gerçek parmak davranışı, ekran çentikleri, geri tuşu, titreşim, FPS/pil/bellek, Android arka plan yaşam döngüsü ve telefonda gerçek eski kayıt dönüşümü test edilmedi. Headless GUI olayları bu cihaz kontrolleri yerine geçmez. Yerel ses yüklenmesi doğrulandı; fiziksel hoparlör dinleme yapılmadı.

## Koruma ve kapsam
Eski çalışan sürüm Git etiketi `backup/tap-blast-v0.1.0` ve `/workspace/prizma-tools/prizma-before-match3.bundle` ile korunur; eski GitHub v0.1.0 yayını da durur. Yeni kod aynı projedir; uygulama sıfırdan kurulmadı. Mağaza/ödeme/reklam, yeni dünyalar, engel bölümleri veya başka bir aşama eklenmedi. Kullanıcı yeni aşamaya talimat verene kadar burada durulur.

## Değişen dosyalar
- `scripts/core/board.gd`: komşu takas, durum makinesi, otomatik dalgalar, eylem/hamle ve son sonuç; `match_detector.gd`: çizgi/T/L; yeni `board_generator.gd`: kararlılık/karıştırma.
- `powerups.gd`, `resonance.gd`, `gravity.gd`, `score.gd`: yeni üretim/aktivasyon, oyuncu hamlesi temelli rezonans, sabit segmentler ve merkezi çarpan; `save_manager.gd`: schema 2 ve eski dosya arşivi; `level_catalog.gd`: yeni bölüm sürümü.
- `scripts/ui/board_view.gd`: native touch/mouse sürükleme ve aşamalı animasyon kuyruğu; `main.gd`: yardım, eğitim, güç akışı, pause/terminal dalga kilidi; `strings.gd`: yeni Türkçe kurallar.
- `data/levels.json`: 10 yeni başlangıç/eğitim/hedef; `project.godot`, `export_presets.cfg`: 0.2.0 ve eski uygulamayı koruyan ayrı test profili.
- `tests/run_tests.gd`, yeni `move_solver.gd`, `persistence_probe.gd`, `capture.gd`: yeni bütünleşme/simülasyon ve kayıt kontrolleri; `tools/build_android.sh`, yeni `runtime_digest.py` ve GitHub workflow: doğrulanmış yeni APK teslimi.
- README, proje gereksinimleri/yol haritası, bu durum raporu, `MATCH3_REVISION.md` ve yeni sürüm notları güncellendi. Bahçe görseli, ikon, ses dosyaları ve blok sanat yönü korunur.
