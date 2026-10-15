# PRİZMA test politikası

Amaç aynı güvenilir sonuca daha az tekrar ve daha kısa teslimatla ulaşmaktır. Oyun testleri kaldırılmaz; kapsam değişikliğin riskine göre seçilir. Kalıcı çalışma kuralları kökteki `AGENTS.md` dosyasındadır.

## Komutlar

Depo kökünden çalıştır. Bu bulutta hazır araçları kullanmak için komutun başına `PRIZMA_TOOLS_DIR=/workspace/prizma-tools` ekle. Başka ortamda mevcut kuruluma ait araç dizinini kullan; gereksiz indirme/kurulum yapma.

```bash
python3 tools/test_profiles.py SMOKE
python3 tools/test_profiles.py TARGETED --suite canyon_mechanics_tests
python3 tools/test_profiles.py TARGETED --levels 62,101-105
python3 tools/test_profiles.py TARGETED --suite canyon_ui --suite goals_panel_tests
python3 tools/test_profiles.py TARGETED --levels 62 --seeds 3
python3 tools/test_profiles.py FULL --reuse
# Yalnızca yetkilendirilmiş sürüm finalinde, APK yoksa veya eskiyse:
python3 tools/test_profiles.py FULL --reuse --android-build
```

`tools/build_android.sh` artık FULL profilini ve gerektiğinde tek Android export işlemini kullanır. Eski `test.sh`, `test_v010.sh` ve sürüm kabul betikleri geçmiş uyumluluk için korunur; normal geliştirmede yeni giriş noktasını kullan. TARGETED seçim olmadan veya olmayan test adıyla çalışmaz.

## Profiller

| Profil | Kapsam | Kullanım |
|---|---|---|
| SMOKE | Tek hızlı sahnede yatay Match-3, kararlı başlangıç, geçerli/geçersiz takas ve maliyeti, otomatik çözümleme, yer çekimi, diskten kayıt dönüşümü, gerçek ana sahne açılışı | Normal değişiklik sonrası hızlı kontrol |
| TARGETED | Açıkça seçilen mevcut mekanik/UI testleri ve belirtilen bölüm aralıkları; bölüm kontrolünde deterministik tekrar ve kayıt karşılaştırması | Değiştirilen sistem, onu kullanan bölümler ve kritik komşu entegrasyonlar |
| FULL | Temel ve 20 mekanik için mevcut unit/entegrasyon paketleri; fırtına/dalga/güç kombinasyonları; kalite, UI ve hedef paneli; bağımsız süreçte kayıt devamlılığı; hazırlanmış bütün bölümlerin (v0.12: 250) veri/oynanabilirlik/deterministik kayıt kontrolleri; Android APK bütünlük/imza kontrolü | Sürüm finali, büyük eşleşme/yer çekimi değişikliği veya kanıtlanan yüksek risk |

FULL'de Android kontrolü atlanmaz: mevcut APK kaynak runtime parmak iziyle eşleşmiyorsa profil başarısız olur. `--android-build` verilmişse bir kez export edilip doğrulanır; eşleşen APK yeniden derlenmez. Paket, sürüm adı, aynı sertifika, ZIP bütünlüğü, bütün veri JSON'ları ve ARM kitaplıkları kontrol edilir. İmza anahtarı dış araç dizininde kalır. Tamamen yeni bir ortamda uygun Android SDK yoksa sonuç engeldir, başarılı sayılmaz.

## Değişiklikten kapsama

- Sadece sanat/animasyon/UI: SMOKE + ilgili UI ve olay verisi bütünlüğü testleri. Gerçek render/perf ölçümü yalnızca efekt/render maliyeti değiştiyse; tüm bölüm simülasyonlarını başlatma.
- Bölüm verisi: yalnızca değişen IDs; önce varsayılan seed ile deterministik oynanabilirlik/kayıt kontrolü. Sınırda sonuçta 3 seed, gerekirse daha fazla. Başlangıçta tüm kampanya × yüzlerce seed çalıştırma.
- Mekanik: ilgili mevcut unit testi + o mekaniği kullanan bölüm IDs + etkilenen portal/fırtına/güç/kayıt entegrasyonları. Mekaniğin veri alanına göre bölüm JSON'larını sorgula; yalnızca dünya numarasına güvenme.
- Eşleşme/yer çekimi/maliyet/hasar motoru: bütün bölüm aralığı için regresyon ve kritik kayıt/özel güç testleri. Büyük değişiklikte FULL.
- Kayıt veya güvenlik: değişikliğin gerçek riskini doğrulayan test zorunludur. Ödeme gelecekte eklenirse ödeme bütünlüğü de zorunludur; şu anda oyunda ödeme sistemi yoktur.
- Talimat/dokümantasyon/runner düzeni: betik söz dizimi, runner doğrulaması ve gerektiğinde tek SMOKE; oyun kodu aynıysa FULL/APK/yeni Release yok.

Bir seed'in otomatik oyuncuyla kaybedilmesi imkânsızlık kanıtı değildir. Ancak başarısız veya sınırda bölümleri incelemeden onaylama. Çoklu seed yardımcı ölçümünde %70 altı kazanma `review_required` olur; bu bir insan zorluk kabulü veya matematiksel eşik değildir. Yerleşik testlerin mevcut assertions'ları korunur. Gerçek cihaz erişimi yoksa Android FPS/input/ses/titreşim/kurulum test edilmemiş olarak raporlanır.

## Sonuçlar, tekrar kullanımı ve süre

`build/test-policy/` içinde kısa JSON raporu ve ayrıntılı loglar tutulur. Commit, gerçek dosya içerik parmak izi, Godot sürümü, komut/argümanlar, temel çalışma koşulları, süre, exit code ve log SHA256 kaydedilir. Çalışma ağacı değişiklikleri de parmak izine dahildir. Markdown ve ilerleme kayıtları oyun testlerinin önbelleğini bozmaz. Bağımlılık parmak izi bilerek muhafazakârdır: runtime/test/araç değişince eski sonuç otomatik kabul edilmez.

`--reuse` yalnızca aynı parmak izi/komut/koşullardaki başarılı ve logu sağlam sonuçları yeniden kullanır; `reused` olarak ayrı işaretler. Başarısız, zaman aşımı, iptal ve inceleme bekleyen sonuçlar önbelleğe başarı diye yazılmaz. Import kontrolü her girişte hızlı yapılır; süreçler arası kayıt çiftleri beraber yeniden çalışır; Android kontrolü mevcut dosyayı gerçekten doğrular. Eski serbest loglardan otomatik başarı ithal edilmez. Yeniden kullanılmış testin eski commit'i raporda saklanır.

Varsayılan iş başı zaman sınırı 600 saniyedir; SMOKE için `--timeout 60` kullanılabilir. Takılan süreç grubu sonlandırılır; `timeout`/`interrupted` açıkça yazılır, sonraki işler `not_run` kalır. Süre sınırını artırmadan önce nedenini, yükü ve ilgili logu incele. Geçmiş başarıları yeniden çalıştırmak yerine etkilenen testi düzelt ve tekrar seç. Runner kısa özet ve log yolu verir; hata çıktısını sınırlı gösterir. Üretim testi olmayan veya tamamlandığını göstermeyen sıfır çıktılı çalışma inceleme gerektirir.

## Sürüm teslimatı

Önce risk uygun testler ve final artefakt; sonra Git commit/push, yeni Releases sürümü, APK Assets ve erişim kontrolü. GitHub geçici hatalarında ilk denemeden sonra en fazla iki kontrollü yeniden deneme; kalıcı hata veya yineleme sınırında nedeni ve yerel APK yolunu bildirip dur. Başarılı gönderimi tekrar tekrar doğrulama, erişilebilir APK'yı gereksiz yeniden indirme, aynı APK'yı yeniden derleme. CI'nin aynı ağır simülasyonları gereksiz tekrar etmesi yerine final kabul/artefakt doğrulamasını seç; bağımsız gerekli kontrolleri atlama.

Kısa teslimat: özellikler, başarılı/başarısız ve çalıştırılmamış testler, APK sürümü, Releases bağlantısı, önemli sorunlar. Gereksiz büyük rapor/video yok. Sonraki aşama kullanıcı onayıyla başlar.

## v0.12 hedefli kontroller
`v012_tests`: kurtarma/boss evreleri, gerçek JSON kayıt dönüşü, envanter, tek seferlik ödüller, önizleme ve üretim kapısı. `adventure_campaign`: yeni amaçlı 25 bölüm × üç seed; insan dengesi kanıtı değildir. `tools/probe_exported_apks.py`: gerçekten üretilmiş iki APK içindeki kaynakları masaüstü Godot ile açar ve üretim/geliştirici özellik kapılarını doğrular; fiziksel Android çalıştırması değildir.
Bir paket yalnızca arayüz varsayımı nedeniyle kesilirse, başarılı çekirdek bölümleri kanıtlı logla saklanır ve ilgili UI ile henüz çalışmamış paketler tamamlanır. Kesilen paket geçmişte başarılı diye işaretlenmez.

## v0.14 ekonomi ve paketli kampanya
`economy_tests`: ödül/purchase tekrar koruması, gerçek match olaylarından sayaç, can/UTC gün hesabı, v3→v4 disk dönüşümü, atomik yazma hatası ve eski arka plan yazıcısıyla yarış. `economy_ui_tests`: beş ekonomi sekmesi, gerçek satın alma/hediye butonu ve can admission. `campaign_014_tests`: 500 tanım, 250 yeni kararlı başlangıç ve kaydedilmiş varsayılan-seed kazanma izinin son hamle bütçesiyle tekrarı. Fixture `tests/fixtures/v0140-witnesses.json`; taze checkout'ta build logu gerekmez.
Yeni paket kabulü bir gerçek motor tamamlanma izi + riskli adaylarda alternatif stratejiler kullanır; eski 151–250 paketlerinin mevcut üç denemelik kanıtı korunur. Bu bir insan zorluk onayı veya bütün seed'lerin kazanılabilirlik garantisi değildir. Tanım paketleri en çok üç girişlik LRU ile yüklenir; `Catalog.all()` yalnızca açıkça bütün tanımları isteyen araç/testler içindir. Görselsiz testlerde dummy texture sunucusu için senkron sanat yüklemesi kullanılır; gerçek renderer/Android'de asenkron yükleme korunur.

## v0.14.1 hedefli kabul
`evolution_tests`: beş mekanik, korunan teslimat nesnesi, JSON katman normalizasyonu ve 500 başlangıç/hamle/kayıt kontrolü. `evolution_ui_tests`: native gesture sahipliği, atalet, modal izolasyon, gerçek Input dispatch ve devam önizlemesi. `evolution_replay_tests`: 69 değişen bölümün tamamlama + JSON izi; pahalı yeniden arama yapmaz. `run_tests.gd -- save-ui` yalnızca başarısız eski kayıt/UI alt bölümünü yeniden çalıştırır; önce geçen 2.000 üretim/1.000 oyun döngüsünü gereksiz tekrarlamaz. Fiziksel Android testi olarak raporlanmaz.
