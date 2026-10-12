# PRİZMA — Renklerin Uyanışı · Match-3

Godot **4.6.3 stable**, GDScript, Android öncelikli çevrimdışı bulmaca. Mevcut PRİZMA projesi korunarak temel motor **sürükle → bir komşuyla takas → yatay/dikey 3+ eşleşme → otomatik zincir** sistemine dönüştürüldü. Normal dokunarak patlatma yoktur. Yalnızca ilk aşamanın 10 bölümü ve kullanıcının istediği Match-3 revizyonu uygulanır.

## Oyna
Godot Project Manager'da `project.godot` açın ve F5 ile çalıştırın. **OYNA** açık bölüme, **DEVAM ET** kayıtlı aynı tahtaya döner. Harita tamamlanan bölümleri tekrar açar.

- Bir bloğu yukarı/aşağı/sağa/sola bir komşusuna kaydırın. Çapraz ve uzak taşıma yoktur; uzun kaydırma da tek komşuya gider. Normal dokunma hiçbir işlem yapmaz.
- Üçlü düz çizgi otomatik patlar; yeni oluşan çizgiler kendiliğinden zincirlenir. Her başarılı işlem bir hamle; geçersiz takas sıfır hamle.
- **4 düz: roket**, **5 düz: renk bombası**, **T/L: prizma**. Roket/prizmaya dokunmak bir hamleyle etkinleştirir. Renk bombası hedef renk ister. İki komşu gücü takas ederek birleştirin.
- 4. bölümden itibaren 12 normal blok bir yön enerjisi verir, kapasite iki. Yön seçimi normal hamle harcamaz. Dolu tahtada yön seçimi sonraki düşüşü değiştirir; boşluk/eşleşme varsa otomatik çözülür.
- 6. bölümden itibaren aynı renkte üç başarılı normal oyuncu takası rezonans oluşturur. Otomatik zincirler ayrı hamle sayılmaz. Çok renkli takasta hedef hücrenin eşleşme rengi esas alınır.
- **Nasıl oynanır?** yeni eşleşme kurallarını gösterir. El eğitimi gerçekten kaydırma yönünü gösterir.
- Ayarlar: müzik, efekt, titreşim, azaltılmış hareket, erişilebilir renk paleti. Her renkte ayrı sembol her zaman bulunur.

## Geliştirme ve otomatik test
Gerekenler: Godot 4.6.3 standart sürüm, Python 3, Bash ve `rg`. Oyun çalışma anında Python veya internet istemez.

```bash
godot --editor --path .
bash tools/test.sh
```

Bu bulut makinesinde kullanıcı dizinleri yerine yazılabilir XDG dizinlerini kullanın:

```bash
export PRIZMA_TOOLS_DIR=/workspace/prizma-tools
bash tools/godot.sh --editor
bash tools/test.sh
```

Sarmalayıcı yerelde `.tools/` dizinini varsayar. Ham Godot ve XDG sarmalayıcısı farklı `user://` kayıt dizinleri kullanabilir; aynı başlatma yolunu tutarlı kullanın.

Testler üçlü çizgi/T/L/çapraz/ikili, takas geri alımı ve normal dokunma, otomatik zincir/çarpan, güç üretim konumu/aktivasyon/istisnalar, dört yön/dolum kenarı/sabit hücre, kararlı başlangıç ve ücretsiz karıştırma, rezonans/hamle/sonuç, schema dönüşümü ve iki süreçte kayıt devamını kapsar. 2.000 farklı başlangıç üretimi ve tüm 10 bölümde 1.000 seed'li oyun simülasyonu yürütülür. Gerçek GUI mouse ve ScreenTouch olayları, kısa/uzun/yavaş sürükleme, dört yön, tahta dışı iptal, animasyon/PAUSED kilidi, yardım ve ayarlar test edilir. Testler ayrı kayıt dosyaları kullanır.

## Android APK
Java 17+ (`java`/`keytool`; bu makinede OpenJDK 21), Godot 4.6.3 ve resmi şablonlar gerekir. SDK lisansını kabul ettikten sonra:

```bash
python3 tools/bootstrap_android.py --accept-sdk-license
bash tools/build_android.sh
```

Bulut araçlarını tekrar kullanmak için:

```bash
export PRIZMA_TOOLS_DIR=/workspace/prizma-tools
python3 tools/bootstrap_android.py --tools-root "$PRIZMA_TOOLS_DIR" --accept-sdk-license
bash tools/build_android.sh
```

Varsayılan çıktı **`build/prizma-match3.apk`**, uygulama adı **PRİZMA Match-3**, test kimliği `com.prizma.renklerinuyanisi.match3`. Android 7.0+, hedef SDK 36, ARMv7/ARM64, internet izni yok. Build sarmalayıcısı önce test eder, sonra v2/v3 imzasını, manifesti, bölüm verisini ve kitaplıkları doğrular.

**Eski uygulama/veri korunur:** v0.1.0 GitHub APK'sı geçici CI debug anahtarıyla imzalandı. O özel anahtar mevcut olmadığından yeni paket onun üzerine güvenli güncelleme olarak kurulamaz. Yeni test kimliği eski uygulamanın yanına kurulur; eski uygulamayı kaldırmanız gerekmez. Yeni test profili ayrı başlar; telefondaki eski profili otomatik okuyup aktardığı iddia edilmez.

Mevcut orijinal Android preset de korunur. Önceki sürümü aynı imzayla güncelleyen geliştirme/yayın sahibi için:

```bash
PRIZMA_ANDROID_PRESET=Android bash tools/build_android.sh
```

Bu çıktı `build/prizma-debug.apk` ve orijinal uygulama kimliğidir. **Eski kurulumla aynı imza olmadan yerinde güncelleme yapmayın.** Gerçek yayın anahtarı Git'e eklenmez; yerel anahtar araç dizininde kalır. Debug APK bir Play Store yayın paketi değildir.

Bootstrap resmi Google arşiv checksum'larını ve Godot SHA-512'yi doğrular; TLS veya bütünlük kontrolünü kapatmaz. SDK 36 / Build Tools 36.0.0 / Platform Tools 37.0.1 kullanılır. Gradle gerektirmeyen Godot export şablonu yeterlidir.

## Kayıt ve geçiş
Schema/rules **2**. Atomik `user://prizma-save.json`, `.bak` ve eski schema dosyası için `.v1-archive`. Eski açılan bölümler, en iyi sonuçlar, ödül kimlikleri ve ayarlar korunur. Eski aktif tahta ayrıca arşivlenir; aynı bölüm yeni Match-3 başlangıcına tam hamleyle döner. Ana menü bu geçişi açıkça anlatır. Yeni sürümlü dosyaların üzerine yazılmaz. Android'de kayıt uygulamanın özel cihaz dizinindedir; ayrı test uygulaması ayrı profil kullanır.

## Dosyalar
- `docs/PROJECT_SPEC.md`, `docs/MATCH3_REVISION.md`: güncel gereksinimler, güç/rezonans istisnaları, durum ve kayıt sözleşmeleri.
- `docs/ROADMAP.md`: kullanıcı talimatı gerektiren sonraki aşamalar.
- `docs/STATUS.md`: gerçek test ve APK kanıtları, test edilmeyen cihaz davranışları.
- `data/levels.json`: 10 hazır eşleşmesiz öğretici başlangıç, hedef, seed, hamle/yıldız ve garantili zincir girişi.
- `scripts/core/board_generator.gd`: kararlı başlangıç ve renk/kimlik koruyan karıştırma; diğer core modülleri ve UI aynı projede genişletildi.
- `assets/`: aynı özgün bahçe/ikon/blok sanat yönü ve yerel sentez sesleri. `assets/CREDITS.md` kaynakları açıklar.
- `build/`: üretilmiş APK, checksum, test logları ve gerçek Godot ekran görüntüleri; Git dışında tutulur.

Fiziksel telefon FPS, titreşim, Android yaşam döngüsü ve gerçek telefonda kayıt geçişi ayrıca doğrulanmalıdır. Başsız testler veya APK imza doğrulaması cihaz testi yerine geçmez. Mağaza, ödeme/reklam, yeni dünyalar veya başka bir geliştirme aşaması eklenmez.
