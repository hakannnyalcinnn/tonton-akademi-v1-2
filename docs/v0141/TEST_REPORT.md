# PRİZMA v0.14.1 — Teslim ve test özeti

## Beş yeni, işlevsel mekanik
| Mekanik | İlk bölüm | Gerçek davranış |
|---|---:|---|
| Kristal teslimatı | 61 | Eşleşmeyen, güçle silinmeyen sandığı yer çekimiyle alt sıradaki çıkışa indir. Kimliği korunur; teslimat bir kez sayılır. |
| Zaman kapısı | 151 | Her başarılı oyuncu eyleminden sonra açılır/kapanır. Açık hücrede temizleme veya kapalıyken doğrudan güç kalıcı olarak kaldırır. Geçersiz takas ve zincirler ayrıca tur ilerletmez. Korunan nesne/güç varsa kapanma ertelenir. |
| Röle ağı | 301 | Aynı numaralı röleleri tek oyuncu hamlesinde etkinleştir; zincirler dahildir. Sonraki hamlede eksik ağın enerjisi sıfırlanır. |
| Anahtar ve bağlı kapı | 351 | Yerel anahtarı toplayınca aynı numaralı uzak kapılar gerçekten kaldırılır. Güç kapıyı anahtarsız açamaz. |
| Denge kristali | 401 | İki gösterilen renkte eşik kadar enerji ve en fazla iki fark gerekir. Depo kapasitesi `2×eşik+2`; doğrudan güç zayıf tarafa iki verir. Sıralı mühürden farklı olarak sıra değil denge aranır. |

Her mekanik merkezi hedef ilerlemesine, kazanma/kaybetmeye, gerçek tahta durumuna, JSON kaydına, kısa görsel etkiye ve özgün üretilmiş seslere bağlıdır. İkonlu Türkçe açıklama, tahta vurgusu ve hareketli eşleştirme eli ilk hedefte bir kez gösterilir; yardım menüsünden yeniden erişilir.

## Bölüm çeşitliliği ve korunanlar
- Beş mekanik 64 bölümde; mevcut yayılan sarmaşık ayrıca 251/261/271/281/291'de kullanıldı. Gerçek kurtarma sistemi 451/461/471/481/491/498/500'e bağlandı. Toplam 69 bölüme küçük ek tanımlar uygulandı.
- 1–500 veri değerlendirmesi dünya/mekanik/hedef/tahta şekli temelinde `progression-review.json` içinde. İlk 500 kaynak paketin dosya baytları değiştirilmedi; ek tanımlar ayrı dosyada tutuldu. 481'de 12→16 hamle; üç riskli teslimat yerleşimi alt sıralara alındı. Diğer hamle bütçeleri korunur.
- İlk oynanabilirlik taramasında dört riskli aday bulundu; yalnızca riskli bölümler ve değişen denge davranışı yeniden incelendi. Son durumda 69 ek tanımın tamamında gerçek motor tamamlanma ve JSON kayıt izi mevcut (`tests/fixtures/v0141-witnesses.json`).
- 500 bölüm/10 dünya ve 10.000 bölüm kapasitesi korunur. Harita görselleri, ekonomi fiyat/ödül ayarları, mevcut yıldızlar/bakiyeler/canlar ve açık bölümler değiştirilmez. Eski aktif tahta kendi kayıtlı bölüm tanımıyla devam eder.

## Kritik dokunmatik düzeltmeleri
- Tek hareket sahibi: 16 mantıksal piksel, Android'de DPI uyarlamalı eşik; eşik aşılırsa bırakma ve emüle fare olayları bölüm açamaz. Atalet sırasında ilk dokunma yalnızca hareketi durdurur; yeni kısa dokunma seçer. Uzun basma seçim değildir.
- Modal açılırken arka plan haritasının native `_input` dinleyicisi ve ataleti askıya alınır. Dostlar/Günlük/Mağaza/Başarımlar kendi ScrollContainer girişini kullanır. Kapatma sabittir; harita konumu korunur. Dost kartı açıklaması erişilebilir.
- `KALDIĞIM YERDEN BAŞLA`, son açık bölümün haritasını ve OYNA önizlemesini açar; kilitli bölüme gitmez.

## Başarılı kontroller
- 1.967 yeni mekanik/500 bölüm doğrulaması; değişmeyen bölümlerde bir gerçek hamle ve JSON kayıt dönüşü.
- 69 değişen bölümde tam kazanma izi ve JSON dönüşü; mevcut 251–500 tamamlanma izleri de yeni tanımlarla doğrulandı.
- 32 native gesture/modal/UI kontrolü: sürüklemede yanlış seçim, atalet, kısa dokunma, gerçek Input dispatch ile Dostlar kaydırması, beş modalın haritayı sabit tutması ve devam butonu.
- 45 ekonomi kontrolü; 55 hedefli eski kayıt/fare/dokunma/UI kontrolü; SMOKE ve kayıt devamlılığı başarılı.
- Eski tohum/buz/taş/kilit, çift renk/çivi, portal/sarmaşık/sandık/ayna, çeşme/baloncuk/konveyör/mühür, kanyon, fırtına/dalga/güç kombinasyonları, karıştırma ve kurtarma/boss paketleri başarılı. Başarılı ağır testler tekrar çalıştırılmadı.
- Gerçek Godot render: harita/devam butonu, Dostlar üst/alt, beş mekanik, final bölüm ve 16:9 tahta. Röle/güç etkileşimi gerçek hareketin üç ayrı karesinde yakalandı; tek sabit görsel animasyon kanıtı olarak kullanılmadı.
- İki APK'da sürüm 0.14.1 / kod 25, önceki sertifika, ayrı normal/dev paketler, ZIP CRC, tüm JSON verileri ve ARM kitaplıkları doğrulandı. APK içinden gerçek kaynak probu normal/dev ayrımını, modal korumasını ve yeni mekanikleri geçti.

## Teşhis edilip giderilenler
JSON tamsayı normalizasyonunun eksikliği eski çift renk/kanyon katmanı dönüşlerini ve ekonomi yedeklemesini etkiliyordu; düzeltildi. Bozuk ana kayıt sonrası gerçek ekonomi yedeği test edildi. Hatalı yeni bölüm verisi, temel tür doğrulaması yapılmadan mekanik doğrulamasına giriyordu; sırası düzeltildi. Eski testlerin iç içe OYNA butonu ve güncel kayıt sürümü varsayımları uyarlandı. Bilinen eski varsayımla çalışan bir tekrar iptal edildi; başarılı sayılmadı. Son ilgili kontroller sıfır hatayla geçti.

## Test edilmemiş sınırlar
Fiziksel Android cihaz yok: gerçek cihazda kurulum/üzerine güncelleme, DPI/dokunma, ses/titreşim ve FPS doğrulanmadı. Godot görüntüleri llvmpipe masaüstü renderer'ındandır. Otomatik kazanma izleri bütün seedleri veya insan zorluk dengesini garanti etmez. Can/ödül sisteminin çevrimdışı saat korumasının önceki sınırları sürer. Gerçek para satın alımları kapalıdır.
