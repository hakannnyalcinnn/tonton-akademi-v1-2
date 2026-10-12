# İlk aşama durum raporu

## Doğrulanan ilk aşama
Godot 4.6.3 ile 8×9 / beş sembollü renk, ortogonal patlatma, deterministik dolum, dört yönlü yer çekimi, enerji, rezonans, roket/prizma/renk bombası ve temel komşu birleşimleri çalışır. 10 bölüm sırayla açılır; puan/yıldız, tekrar oynama, aktif oyun ve ayarlar atomik yerel kayıtta saklanır. Dolu tahtada yön değişimi sonraki dolumu etkiler; mevcut blokları yapay olarak karıştırmaz.

Ana menü, bölüm haritası, oyun, duraklatma, kazanma/kaybetme ve ayarlar gerçek sahne kontrolleridir. Bahçe, toplanan renklerle doygunluk kazanır ve renk sembolleri canlanır. Blokların büyüme/patlama/düşüş efektleri, rezonans dalgası ve zafer kutlaması; yerel müzik ve dokuz sentez efekt vardır. Menü navigasyonu, oyun giriş kilidi ve kayıt devamı otomatik UI testinde doğrulandı.

## Gerçek çalıştırma kanıtı
`PRIZMA_TOOLS_DIR=/workspace/prizma-tools bash tools/test.sh`:
- **5.991 kontrol, 0 başarısızlık**.
- **300 oyun simülasyonu, 1.861 hamle**; her bölümde 30 farklı dolum seed'i. Bu hedef odaklı otomatik oyuncu tüm 300 oyunu kazandı. Bu sonuç insan oyuncular için kapsamlı zorluk dengelemesi yerine geçmez.
- Grup, çapraz/tek blok, büyük grup, güç üretim yeri, güç dalgaları ve birleşimlerin tek sayımı.
- Dört yönlü sıkıştırma, doğru kaynak kenarı, enerji sınırı, rezonans sırası/mesafesi/tie-break.
- Skor ve son hamlede kazanma, negatif sayaç/çift ödül engeli, açılma ve en iyi sonuç.
- Ölü tahta karıştırmasının renk çoklu kümesini koruması; sabit seed ve eylemle durum eşitliği.
- Tam kayıt/RNG devamı; bozuk JSON'da yedek, hatalı tür/kesirli renk/tekrarlı kimlik/toplam reddi.
- Gerçek GUI mouse/touch emülasyon giriş yolu, hızlı dokunma kilidi, duraklatma, ayar ve devam.
- 360×640, 360×800, 768×1024, 1080×2400 geometride 540×960 sahnenin taşmadan sığması.
- İki **ayrı Godot sürecinde** kayıt ve aynı sonraki hamlenin tahta/RNG/puan eşitliği.

Xvfb / Mesa Compatibility renderer ile gerçek ana menü, oyun, harita, ayarlar ve oynanarak kazanılmış sonuç ekranı render edildi; `build/*.png` görselleri kontrol edildi. Logo boyut sorunu ve kapanışta WAV kaynak sızıntısı düzeltildi. Son test logunda script/engine hatası veya kaynak sızıntısı bulunmuyor. Xvfb yazılım render sürücüsünün V-Sync uyarısı fiziksel telefon performansını ölçmez.

## Android çıktısı
`build/prizma-debug.apk` gerçek Godot export çıktısıdır; debug imzalıdır. APK Signature Scheme **v2 ve v3** doğrulandı. Paket `com.prizma.renklerinuyanisi`, sürüm 0.1.0 / kod 1; minimum SDK 24, hedef SDK 36; ARMv7 + ARM64. Bölüm JSON'u ve iki mimarinin Godot kitaplıkları APK içinde bulunur. İnternet izni yok; titreşim izni var. `build/prizma-debug.apk.sha256` bütünlük özeti build sarmalayıcısı tarafından üretilir.

Google SDK ve Godot şablonları resmi kaynaklardan checksum kontrolüyle kuruldu. Java SDK yöneticisinin proxy sorunu HTTPS arşiv kurulumu ile çözüldü; Godot Android doku import ayarı etkinleştirildi. Kurulum aracı tekrar çalıştırılarak mevcut SDK paketlerini koruduğu doğrulandı.

## Cihazda doğrulanmayanlar
ADB listesi boş; bağlı Android cihaz veya kullanılabilir emülatör yok. APK fiziksel telefona kurulup çalıştırılmadı. Telefon FPS, uzun oturum pil/bellek, titreşim, cihaz geri tuşu, uygulama arka plan/geri dönüş ve kesinti sırasında Android kayıt davranışı **cihazda test edilmedi**. Bunların kod yolları mevcut olsa da cihaz doğrulaması tamamlandı sayılmaz. Masaüstünde yerel ses varlıklarının yüklenmesi test edildi; hoparlör üzerinde dinleme ve müzikal kalite değerlendirmesi yapılmadı.

## Bilinçli kapsam sınırı
İleri engeller, zincir şimşeği, günlük görevler, sonsuz mod, başarımlar, profil ekonomisi, mağaza/PRO/Billing/reklam, yeni dünyalar ve 1.000 bölüm yok. İlk aşama on bölüm bahçeyle sınırlı. Yayın imzası, Play Store AAB ve yayınlama yapılmadı. Kullanıcı talimatı gelmeden ikinci aşamaya geçilmez.
