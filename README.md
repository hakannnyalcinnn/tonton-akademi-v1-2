# PRİZMA — Renklerin Uyanışı

Godot **4.6.3 stable**, GDScript, Android öncelikli çevrimdışı bulmaca oyunu. Bu depo artık PRİZMA'dır; iptal edilen Tonton Akademi uygulaması kaldırıldı. **Yalnızca ilk geliştirme aşaması** uygulanmıştır. Sonraki aşama kullanıcı talimatı gerektirir.

## Oyna
Godot Project Manager'da `project.godot` dosyasını açın ve F6/F5 ile ana sahneyi çalıştırın (F5 tüm proje). Ana menüde **OYNA**, devam eden kayıt varsa **DEVAM ET** bulunur. Harita tamamlanan bölümleri tekrar oynamayı sağlar.

- En az iki yatay/dikey aynı sembole dokunun. Tek bloğa dokunmak da bir hamle tüketir.
- 5–6 blok roket, 7–9 prizma, 10+ renk bombası oluşturur. Güç dokunulan hücrede doğar ve mevcut yer çekimiyle taşınır. Renk bombasında hedef rengi seçin.
- Komşu özel güçleri **Güçleri birleştir** düğmesiyle, ardından iki güce dokunarak birleştirin. Renk bombası birleşiminde yine hedef renk seçilir.
- 4. bölümden itibaren her 12 normal blok bir yön enerjisi verir, en çok iki birikir. Yön değiştirmek enerji tüketir, hamle tüketmez. Dolu tahtada konum aynı kalır; sonraki patlamada düşüş/dolum seçtiğiniz yönde gerçekleşir.
- 6. bölümden itibaren aynı rengi üst üste üç kez patlatmak rezonans oluşturur. Yakın, aynı renk dört ek normal blok temizlenebilir. Farklı renk seriyi yeniden başlatır; özel güç kullanımı sıfırlar; yön değiştirme korur.
- Hedefler tamamlanınca kalan hamleler puana eklenir. Sonuç ekranında iki/üç yıldız eşikleri gösterilir; en iyi sonuç korunur.
- Ayarlar: müzik, efekt, titreşim, azaltılmış hareket ve farklı erişilebilir renk paleti. Her renkte her zaman farklı sembol vardır.

## Geliştirme ve test
Gerekenler: Godot 4.6.3 (standart sürüm, .NET gerekmez), Python 3; test sarmalayıcısı için Bash ve `rg`. Oyun çalışma anında Python'a veya internete ihtiyaç duymaz.

```bash
godot --editor --path .
bash tools/test.sh
```

Kısıtlı bulut makinesinde kullanıcı dizinlerine yazmak yerine XDG dizinlerini yöneten sarmalayıcı kullanılır:

```bash
export PRIZMA_TOOLS_DIR=/workspace/prizma-tools
bash tools/godot.sh --editor
bash tools/test.sh
```

`tools/godot.sh` yerel kullanımda `.tools/` dizinini varsayar. Ham Godot komutuyla başlatılan oyunun `user://` kaydı normal kullanıcı dizinindedir; sarmalayıcıyla başlatıldığında seçilen XDG dizinindedir. İki yöntemin kayıt dizinleri farklı olabilir; aynı yöntemi tutarlı kullanın. Android'de kayıt uygulamanın özel cihaz dizininde saklanır.

Testler grup/çapraz/tek dokunma, dört yön ve dolum kenarı, enerji, rezonans seçimi, güçler/birleşimler, skor/yıldız, hedef ve sonuç kilidi, ücretsiz karıştırma, bozuk kayıt/yedek, aynı seed, 300 simülasyon, gerçek GUI giriş ile hızlı dokunma, duraklatma/ayar/geri dönüş ve dört ekran oranını kapsar. Ayrı iki Godot süreci aktif oyunun aynı şekilde devam ettiğini kontrol eder. Test kayıtları ayrı dosyalardadır; oyuncu kaydını silmezler.

## Android APK
Bu ortamda `build/prizma-debug.apk` üretildi. **Debug imzalı test APK'sıdır; Play Store yayın paketi değildir.** Fiziksel cihaz veya emülatör bağlı değildi; cihazda açılış, titreşim, arka plan yaşam döngüsü ve FPS doğrulanmadı. Android 7.0+ (minimum SDK 24), hedef SDK 36, ARMv7 ve ARM64. İnternet izni yoktur.

Linux'ta yeniden hazırlama: Java 17+ (`java` ve `keytool`; bu ortamda OpenJDK 21), Godot 4.6.3 ve resmi export şablonları gerekir. Google Android SDK lisansını okuyup kabul ettikten sonra:

```bash
python3 tools/bootstrap_android.py --accept-sdk-license
bash tools/build_android.sh
```

Bulut ortamındaki mevcut araçları kullanmak için:

```bash
export PRIZMA_TOOLS_DIR=/workspace/prizma-tools
python3 tools/bootstrap_android.py --tools-root "$PRIZMA_TOOLS_DIR" --accept-sdk-license
bash tools/build_android.sh
```

Bootstrap, resmi Google metadata'sından Build Tools 36.0.0 / Android 36 / Platform Tools 37.0.1 arşivlerini checksum ile doğrular; Godot şablonunu resmi SHA-512 ile doğrular. TLS veya checksum kontrolünü kapatmaz. Java `sdkmanager` bulut proxy'sini kullanamadığı için doğrulanmış arşivler desteklenen HTTPS yoluyla kurulur. Editör SDK/Java/debug anahtar yolları yalnızca yerel araç dizininde saklanır; Git'e imzalama anahtarı eklenmez. Kurulu paketler tekrar kullanımda korunur.

Godot editöründe manuel alternatif: Editor Settings → Export → Android altında Java/SDK yollarını girin, Export Templates 4.6.3'ü kurun, Android preset'inden Export Project yapın. Gradle gerektirmeyen standart şablon kullanılır. Yayın anahtarı, AAB, mağaza ve Billing bu aşamanın kapsamı dışındadır.

Cihaz testi için kendi bilgisayarınızda:

```bash
adb install -r build/prizma-debug.apk
adb shell monkey -p com.prizma.renklerinuyanisi 1
```

Kayıtlar `user://prizma-save.json` ve `.bak` ile sürümlü, atomik şekilde tutulur. Uygulamayı kaldırmak cihaz kaydını siler. İlk sürüm zorunlu hesap veya bulut kaydı kullanmaz.

## Dosyalar ve tasarım
- `docs/PROJECT_SPEC.md`: öncelikler, tam gereksinimler ve kesin mekanik kuralları.
- `docs/ROADMAP.md`: yalnızca ilk aşama ve ileride kullanıcı talimatıyla yapılacak işler.
- `docs/STATUS.md`: çalıştırılmış kontroller, APK kanıtı ve sınırlar.
- `data/levels.json`: 10 seed'li başlangıç, hedef, hamle ve yıldız eşikleri.
- `scripts/core/`: görsel bağımsız çalışan modüller; `scripts/ui/`: ekranlar, çizim, ses ve animasyon.
- `assets/art/garden.png`: bu proje için oluşturulmuş özgün yapay zekâ destekli bahçe illüstrasyonu. Ekli dünya kolajı kopyalanmadı. Bloklar, semboller ve ikon özgün vektör çizimlerdir. `tools/generate_audio.py` özgün yerel sentez seslerini yeniden üretir. Bunlar ilk aşama varlıklarıdır; sonraki aşamalarda sanat/ses yönetimi geliştirilebilir.
- `build/`: APK, test logları ve gerçek Godot ekran görüntüleri; üretilmiş çıktılar Git dışında tutulur.

Mağaza, gerçek ödeme, reklam, PRO, günlük/sonsuz mod, ileri engeller veya 1.000 bölüm sistemi bu sürümde yoktur. İşlevsiz menü veya sahte satın alma eklenmemiştir.
