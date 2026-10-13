# PRİZMA 0.5.0 — Mekanik Paketi 2

2026-10-13 · Godot 4.6.3 · Android test teslimatı

**Mekanik 5–8 tamamlandı.** Çift renkli ve bukalemun kristaller 31–50. bölümlerde;
Prizma Köprüsü ve Yer Çekimi Çivisi yalnızca geliştirici laboratuvarında kullanılabilir.
İlk 50 normal bölümde köprü/çivi yoktur. Sonraki 12 mekanik, PRO, ödeme, reklam ve
1.000 bölüm geliştirilmedi. Bu paket sonunda duruldu; yeni grup kullanıcı onayı bekler.

## Korunan sürüm ve analiz

Başlangıç **50ed7a1 (0.4.0)**, Git etiketi **backup/garden-mechanics-v0.4.0**.
`/workspace/prizma-tools/prizma-before-package2.bundle` tam geçmişle doğrulandı.
Geliştirme başlamadan önce 0.4.0'ın bütün mevcut motor, kalite, dört engel, native
kaydırma ve kayıt testleri çalıştırılıp geçti. Yeni motorla aynı testler tekrar geçti.

**`data/levels.json`, `data/levels-11-30.json`, `gravity.gd`, `score.gd`, bahçe ve
önceki kristal varlıkları değiştirilmedi.** Marka/menü, 8×9 tahta, önceki 30 bölüm,
otomatik zincirler, güçler, yer çekimi, rezonans, geri alma, kayıt ve havuzlar korunur.
Motor sıfırdan yazılmadı. Normal kristale dokunarak patlatma eklenmedi.

## Çalışan kurallar

**Çift renkli kristal:** `trait.colors` iki farklı ana renk içerir; normal takasla
hareket eder. Bu iki renk dışında eşleşmez. Aynı dalgada yalnızca tek renk kimliği,
tek temizlik, tek puan/enerji ve tek çift-renk hedef katkısı vardır. Dört/beşli ve T/L
üretim kuralları aynı bileşen üzerinden çalışır; dönüşen kristal yerine yaratılan
özel güç yeni kimlikle normal güç kurallarına girer.

**Kesin renk ataması:** düz çizgi adayları hücre renk alanlarından çıkarılır;
budamalı arama tutarlı atamaların en iyisini seçer. Seçim sırası:

1. Takas hücrelerinden en az birini içeren eşleşmeli çözümler.
2. En yüksek benzersiz eşleşen hücre sayısı.
3. En uzun düz çizgi.
4. Hücre sırasına göre sabit renk önceliği: kızıl, mavi, yeşil, sarı, mor.

Atamalar sadece o hücrenin tanımlı alanından seçilir. Arama tahtanın rengini veya
RNG'sini değiştirmez. Bir hücre iki farklı renkli bileşeni keyfî birleştiremez.
Budama, henüz atanmamış alanların iyimser kapsamasını üst sınır olarak kullanır;
arama bütçesi dolduğunda yaklaşık sonuç seçme veya sessizce kesme yoktur. Renk/tahta
öncelikleri 300 sabit seed'li durumda budamasız tüm-atama aramasıyla karşılaştırıldı.
Oracle aynı çizgi taramasını, farklı ve budamasız atama aramasını kullanır; ayrıca
bağımsız elle tanımlanmış çizgi/T/kesişim/öncelik senaryoları vardır.

**Bukalemun:** aktif renk, döngü sırası, başlangıç fazı ve periyot veridedir.
Bahçe bölümlerinde yeşil → mavi → kızıl → mor döngüsü, iki başarılı takas periyodu
kullanılır; başlangıç fazları farklı olabilir. Sayaç, başarılı normal veya özel
**takasın** bütün ilk patlama/dolum zincirlerinden sonra bir kez ilerler. Geçersiz
takas, otomatik dalga, yer çekimi ve özel güce dokunma sayılmaz. Hayatta kalan
bukalemunlar dönüşür; tüketilmiş kristalin sayacı ilerletilmez. Sonraki eşleşmeler
aynı hamlede, devam eden kombo derinliğinde çözülür. Rezonansa ilave oyuncu hamlesi
sayılmaz. Son hamlenin sonucu bu zincirden sonra belirlenir.

**Prizma Köprüsü:** normal hareket eden, beş renk alanı olan jokerdir. Kızıl + köprü
+ kızıl geçerli; kızıl + köprü + mavi geçersiz. Sadece köprülerden oluşan çizgiler
reddedilir. Tanımlı iki rengi olan çift kristal köprüye renk dayanağı olabilir.
Normal dört/beşli güç üretimine katılır. Renk bombası köprüyü seçilen renk kimliğiyle
tüketebilir. Bombanın köprüyle takası en çok bulunan tek renkli normal kristalin
rengini, eşitlikte sabit renk sırasını kullanır. Aynı dalgada normal eşleşmenin zaten
verdiği renk kimliği varsa o kimlik korunur; kristal iki kez sayılmaz. Mevcut
prizma bombası ile köprü ayrı türlerdir (`p=prism` / `trait.kind=bridge`).

**Yer Çekimi Çivisi:** `armor.kind=pin`, iki dayanıklılıklı metalik sabitlemedir.
Normal takas/eşleşme ve dört yönde hareket engellenir. Komşu veya doğrudan güç
bir dalgada en fazla bir hasar verir; prizma da iki katmanı tek dalgada kırmaz.
İkinci dalgada katman kalkar; aynı kimlik ve renkteki kristal korunur. Hücrede ikinci
kristal oluşmaz. Serbest kristal düşüşe ve yeni otomatik eşleşmelere katılır.

## Etkileşim sınırları

- Yeni kristaller ve önceki dört engel farklı hücrelerde birlikte kullanılabilir;
  36–40 ve 46–50 bölümleri bunu uygular. Komşu/özel hasar ve hedef hesabı ortaktır.
- Aynı kristale trait ile buz/çivi katmanı yığma, birden çok trait veya birden çok
  engel katmanı bu sürümde tanımlanmadı; veri/kayıt doğrulaması reddeder.
- Kesin arama ve içerik bütçesi için tahta başına **en çok 8 çift renk/joker**
  desteklenir. Laboratuvar dokuzuncuyu reddeder, kayıt ve bölüm doğrulaması limiti
  kontrol eder. İlk 50 bölümde en çok 3 çift renk ve **0 köprü/0 çivi** vardır.
- Renk bombası çift kristali yalnızca seçilen renk alanında ise etkiler; koruma
  katmanları temizlemek yerine ortak hasar işlemi üzerinden darbe alır.

## Görseller ve animasyonlar

`generate_mechanics2.py` ile **10 çift renk, 5 bukalemun, 1 köprü ve 2 çivi** için
18 özgün SVG durum, 1280×1024 atlas ve ayrı 512 px madalya tasarlandı. Başka oyundan
varlık, emoji veya telifli ses alınmadı. Çift kristalin iki bölgesi büyük ve dengeli;
yüzeyler, ışık yansımaları ve gölge mevcut. Bukalemunda metalik/büyülü çerçeve,
periyodun son hamlesinde uyarı parlaması ve 160 ms renk geçişi var. Köprüde çok renkli
çekirdek ve düşük maliyetli yansımalar, eşleşme renginde kısa tonlama ve gökkuşağı
parçacıkları var. Çivi saydam buzdan farklı metal köşe aparatı, enerji bağları,
çatlaklar, kıvılcım/parçacık ve açılma halkası kullanır.

Sabit altı BoardView çocuğu, 192 parçacıklık depo ve kaliteye göre etkin bütçe
korundu. Atlas bölgeleri/counter metinleri önbelleklidir. Sürükleme sırasında
mekanik hesaplama yapılmaz. Mantık tamamlanmış değişmez kareler üretir, sunum
aynı sonucu oynatır. Dönüşüm sırasında ikinci hareket alınmaz. Normal takas 180 ms,
geçersiz geri dönüş 140 ms; azaltılmış harekette sunum süreleri kısalır.

Gerçek render kontrolü çift renk bölgelerinin küçük kalmasını ve madalyanın
TextureRect minimum boyutu nedeniyle taşmasını yakaladı; iki sorun düzeltildi.
Madalya 136×136 alana sığar. Eski yakut görünürlüğünde 126 piksel kontrolü ve yeni
kızıl/mavi bölge kapsamasında 1 kontrol geçti. 540×960, 540×1170 ve 540×1200
render çıktıları rapor ZIP'inde. Dummy ses sürücüsünün test kapanışında WAV referansını
bırakması için mixer, düğümler kaldırılmadan önce durdurulup frame'ler beklenir;
fiziksel ses dinleme testi yapılmış sayılmaz.

## Bölümler, kayıt ve dünya finali

31–35 çift renk, 36–40 eski engellerle birleşim, 41–45 bukalemun ve renk toplama,
46–49 stratejik birleşimler, 50 dünya finalidir. Başlangıçlar ayrı ve açık bölüm
verisindedir; trait-aware üretici hazır eşleşme ve geçerli hamleyi de kontrol eder.
Başlangıç düzelticisinin bukalemun rengini sırasından koparabileceği testte bulundu;
artık trait renk/fazını koruyarak normal komşular düzeltilir veya tahta karıştırılır.
Yeni veri normalleştirme aracı gerçek geçerli, çift renkliyi sürükleyen öğretici
hamleler seçer. Önceki bölüm verisi değişmez.

İlk denge denemesinde erken tüketilen bütün bukalemunları dönüşüme zorlayan hedef
bazı seed'lerde imkânsızdı. Normal kampanya bu gereksiz hedef yerine döngüdeki
renkleri toplama hedeflerini kullanır; dönüşüm yine oynanışa otomatik katkı sağlar.
Dönüşüm sayacı ve son hamle/dönüşüm test hedefi motorda ayrı olarak doğrulanır.
Hamle ve yıldız bütçeleri gerçek oynanmış rotalarla ayarlandı; her başlangıç
seed'inde üç yıldızlı rota kanıtlandı. İnsan oyuncu zorluğu ayrıca değerlendirilmelidir.

| Bölüm | Ad | Hamle bütçesi | 20 oyunda en çok kullanılan | Kazanma | 2★ / 3★ |
| --- | --- | --- | --- | --- | --- |
| 31 | İki Rengin Kalbi | 14 | 3 | 20/20 | 1000 / 1400 |
| 32 | Yakut ve Safir | 16 | 3 | 20/20 | 1800 / 2500 |
| 33 | Çift Işığın Yolu | 22 | 12 | 20/20 | 1700 / 2350 |
| 34 | Renkli Pusula | 20 | 5 | 20/20 | 2700 / 3800 |
| 35 | İkili Kristal Korusu | 24 | 6 | 20/20 | 2050 / 2850 |
| 36 | Tohumun İki Rengi | 20 | 3 | 20/20 | 2000 / 2750 |
| 37 | Buzda Saklı Renk | 24 | 5 | 20/20 | 1950 / 2700 |
| 38 | İkili Kaya Yolu | 24 | 5 | 20/20 | 1900 / 2650 |
| 39 | Renklerin Anahtarı | 28 | 10 | 20/20 | 4600 / 6350 |
| 40 | Bahçenin İkili Yankısı | 30 | 10 | 20/20 | 4000 / 5500 |
| 41 | Bukalemunun Uyanışı | 20 | 6 | 20/20 | 4550 / 6300 |
| 42 | İki Hamlenin Ritmi | 22 | 5 | 20/20 | 3150 / 4350 |
| 43 | Değişen Işık | 26 | 9 | 20/20 | 2850 / 4000 |
| 44 | Yankılı Dönüşüm | 26 | 7 | 20/20 | 4400 / 6100 |
| 45 | Renk Döngüsü | 30 | 9 | 20/20 | 2450 / 3400 |
| 46 | Filizlerin Stratejisi | 26 | 4 | 20/20 | 2300 / 3150 |
| 47 | Buz ve Dönüşüm | 30 | 7 | 20/20 | 2600 / 3650 |
| 48 | İkili Kaya Çemberi | 30 | 10 | 20/20 | 2500 / 3500 |
| 49 | Bahçenin Son Mührü | 30 | 11 | 20/20 | 3050 / 4250 |
| 50 | Büyülü Bahçenin Kalbi | 26 | 10 | 20/20 | 5200 / 7200 |


50 tamamlanınca bahçe tamamen renklenir, özel halkalar/ışınlarla final animasyonu
oynar ve **kalıcı Büyülü Bahçe madalyası** verilir. `world_rewards=[1]` tekrar
oynamada çoğalmaz. Ana menü madalyayı ve tam renkli bahçeyi korur. Mevcut katalog
50 ile bittiği için 51 düğmesi yoktur: **Yeni dünya hazırlanıyor** gösterilir.
Gerçek 51. bölüm verisi ileride eklendiğinde katalog ve kayıt sınırı otomatik açar;
bu davranış yalnızca test kataloğuna geçici 51 eklenerek doğrulandı. Oyuna 51 veya
ikinci dünya eklenmedi. Dünya kimliği her 50 bölümde ilerler.

Schema 2 korunur. Eski aktif tahtaya yeni sayaçlar sıfır varsayılır; hamle, renk,
RNG, enerji, yıldız/puan ve ayarlar korunur. Tamamlanmış eski 30 sınırı 31'e çıkar.
Trait sırası/fazı/sayacı ve yeni koruma bilgisi kayda girer. Dünya madalyası
uygulama yeniden açılınca korunur. Geliştirici laboratuvarındaki sekiz araç, seed
reset ve hücre seçimi normal ilerleme/aktif kayıt/ödüllere yazılmaz.

## Gerçek otomatik testler

| Test | Kontrol | Başarısız |
| --- | --- | --- |
| Mevcut Match-3 ve ilk 10 bölüm | 21.969 | 0 |
| Mevcut kalite/havuz/kayıt | 71 | 0 |
| Önceki dört engel ve 11–30 | 16.822 | 0 |
| Önceki mekanik UI / test izolasyonu | 209 | 0 |
| Yeni kurallar / oracle / etkileşim / son hamle | 2.081 | 0 |
| Yeni 31–50 bölümler / kayıt / dünya ödülü | 10,506 | 0 |
| 72 hücre / dört yön / yeni UI / dünya finali | 2.586 | 0 |

Toplam **54.244 sayılmış kontrol, 0 başarısız**. Ayrıca ilk on, engel ve yeni
kristal gruplarında ayrı ayrı **100 geçerli + 100 engellenen ikinci native
ScreenTouch hareketi** çalıştı: toplam 300 + 300. Yeni koordinat testi dört yer
çekimi yönü sonrasında 72 merkezin ve dört sürükleme yönünün tamamını yokladı;
**1.152 yön denemesi**, 1.016 içeri yönelen komşu hareketi doğrulandı.

İlk 10 bölüm 1.000 oyun / 4.128 hamle; 11–30: 600 / 3.085; 31–50: **400 / 1.932**.
Toplam **2.000 oyun / 9.145 başarılı oyuncu hamlesi**. Ayrıca 2.000 bağımsız kararlı
başlangıç üretimi ve 300 renk-atama oracle senaryosu geçti. Her yeni işlem ikinci
motorda aynı seed/eylemle aynı snapshot üretti ve geri yüklenebilir kaldı.

İki tanımlı renk / üçüncü renk reddi, eşit kapsama uzun çizgi önceliği, sabit renk
sırası, takas önceliği, joker-only reddi, joker+dual, renk bombası+köprü,
roket/prizma+çivi, dört yönlü sabitlik, gerçek başarılı takas sonrası dönüşüm,
zincirin sayacı iki kez artırmaması, son hamlede yeni renk zinciriyle kazanma,
korumayla trait yığılmasını reddetme, 30→31, dünya ödülü/replay, masaüstü
pause/resume ve test profili izolasyonu çalıştırıldı. Tespit edilen başlangıç
fazı, hedef dengesi, test-fixture READY durumu ve madalya boyutlandırma hataları
düzeltildi; ilgili kontroller tekrar geçti. Otomatik başarısız kalan senaryo yoktur.

## Ölçülen performans ve sınırları

Gerçek Godot Compatibility/Xvfb **540×960**, Linux **llvmpipe (LLVM 19.1.7, 256 bits)**, 60 FPS
sınırı ve `--profiling`; native Performance ve RenderingServer ölçümleri kullanıldı.
Fiziksel Android / donanım GPU'su / Android remote profiler yoktur.

- Dengeli: **100 hamle / 198 dalga / 8016 frame**.
  Bu koşu otomatik oyuncunun tekrar başlattığı ağır 40/50. bölüm tahtalarını
  ağırlıkla kullandı; bütün 20 bölümün ayrı FPS testi değildir.
  Ortalama **16.808 ms ≈ 59.5 FPS**, p95 **17.658 ms**,
  maksimum **246.127 ms**.
- Performans: **20 hamle / 42 dalga / 1770 frame**;
  ortalama **16.755 ms ≈ 59.7 FPS**, p95 **16.810 ms**,
  maksimum **109.352 ms**. Kısa örneklem doğrudan karşılaştırma değildir.
- Ortalama draw call: dengeli **162.9**, performans
  **88.9**. Mantık kaliteyle değişmez.
- Statik bellek monitor tepe değeri **41,742,340 byte**;
  canlı nesne tepe değeri **1866**.

| İşlem | Ortalama ms | p95 ms | Maksimum ms |
| --- | --- | --- | --- |
| Takas + bütün zincir/dönüşüm | 3.300 | 6.739 | 12.448 |
| Sunum + kayıt isteği | 0.508 | 0.716 | 0.806 |
| Eşleşme taraması | 0.519 | 2.976 | 5.639 |
| Bukalemun sayaç/dönüşüm | 0.046 | 0.050 | 0.061 |
| Patlama mantığı | 0.172 | 0.297 | 2.651 |
| Yer çekimi | 0.062 | 0.080 | 0.869 |
| Yeni blok üretimi | 0.025 | 0.041 | 0.112 |
| Tahta çizim komutları | 0.424 | 0.673 | 6.155 |
| Renderer CPU | 2.306 | 5.271 | 15.603 |
| Renderer GPU / yazılım | 8.946 | 12.795 | 26.876 |


Frame/takas serisi bütün 100 hamleyi kapsar; oyun tanılama penceresi son 2.048
örnekle sınırlıdır, çizim/render satırları aynı süreyi kapsamayabilir. Native
`TIME_PROCESS` render/senkronizasyon beklemelerini içerebilir; saf oyun mantığı
olarak kullanılmadı. CPU/GPU süreleri frame süresine eklenmedi.

**Her frame 16,7 ms altında değildir.** Maksimum 246 ms `clear` fazında kaydedildi;
50 ms üstü swap/ready örnekleri de var. Hamle/zincir mantığı maksimum 12,448 ms.
Otomatik oyuncunun aday hamle araması da bu testte ana thread'dedir; normal oyun
sürüklemesinde bu test oyuncusu çalışmaz. Yazılım renderer, host beklemeleri ve
bütün frame verisi fiziksel Android'deki bir donmanın kesin nedeni sayılmaz.
Telefonun gerçek parmak gecikmesi veya 60 FPS başarısı test edilmiş olarak sunulmaz.

Android Ayarlar > Performans ölçümü / rapor, frame, dokunma, eşleşme, dönüşüm,
patlama, gravity/refill, worker kayıt ve render sürelerini JSON olarak kopyalar.
Rapor otomatik gönderilmez. Android remote Godot profiler ve aynı seed/bölüm/ayar
karşılaştırması fiziksel cihaz kabul testinde kullanılmalıdır.

## APK

Çıktı **prizma-v0.5.0.apk**, **60.593.941 byte**, sürüm **0.5.0 / kod 5**.
Paket **com.prizma.renklerinuyanisi.match3**, Android 7.0+ / SDK 24, hedef SDK 36,
ARMv7/ARM64. İnternet izni yok; titreşim izni var. v2/v3 imzası doğrulandı.
SHA-256: `a3617fc63268a294fe16389ba8f8c8ece4e63724dca1b73ddf49d31c48a6c3cd`.
Sertifika önceki 0.2/0.3/0.4 ile aynı:
`01bb7474354b56e234ce24df50fd2e1ef45c838111b364cd0b3894bf8bb8360a`.
Özel anahtar Git'e, kaynak ZIP'ine veya rapora konmadı. Son APK'nın yeni 20 bölüm
verisi kaynakla byte/JSON olarak karşılaştırıldı; normal kampanyada köprü/çivi yok.

**Mevcut Match-3 uygulamasını kaldırmadan üzerine kurun.** Cihazda kurulum/güncelleme,
gerçek kayıt dönüşümü, parmak hissi, ses/titreşim, çentik, FPS/pil/ısı ve gerçek OS
arka plan yaşam döngüsü test edilmedi; ADB listesi boş. Masaüstü testleri bunların
yerine geçtiği iddiası değildir. APK bu kontrolleri yapmanız içindir. Sonraki
mekanik grubuna geçilmedi.

## Değişen dosyalar

- `.github/workflows/android-test-release.yml`
- `README.md`
- `assets/CREDITS.md`
- `assets/mechanics2/atlas.svg`
- `assets/mechanics2/atlas.svg.import`
- `assets/mechanics2/bridge.svg`
- `assets/mechanics2/bridge.svg.import`
- `assets/mechanics2/chameleon-0.svg`
- `assets/mechanics2/chameleon-0.svg.import`
- `assets/mechanics2/chameleon-1.svg`
- `assets/mechanics2/chameleon-1.svg.import`
- `assets/mechanics2/chameleon-2.svg`
- `assets/mechanics2/chameleon-2.svg.import`
- `assets/mechanics2/chameleon-3.svg`
- `assets/mechanics2/chameleon-3.svg.import`
- `assets/mechanics2/chameleon-4.svg`
- `assets/mechanics2/chameleon-4.svg.import`
- `assets/mechanics2/dual-0-1.svg`
- `assets/mechanics2/dual-0-1.svg.import`
- `assets/mechanics2/dual-0-2.svg`
- `assets/mechanics2/dual-0-2.svg.import`
- `assets/mechanics2/dual-0-3.svg`
- `assets/mechanics2/dual-0-3.svg.import`
- `assets/mechanics2/dual-0-4.svg`
- `assets/mechanics2/dual-0-4.svg.import`
- `assets/mechanics2/dual-1-2.svg`
- `assets/mechanics2/dual-1-2.svg.import`
- `assets/mechanics2/dual-1-3.svg`
- `assets/mechanics2/dual-1-3.svg.import`
- `assets/mechanics2/dual-1-4.svg`
- `assets/mechanics2/dual-1-4.svg.import`
- `assets/mechanics2/dual-2-3.svg`
- `assets/mechanics2/dual-2-3.svg.import`
- `assets/mechanics2/dual-2-4.svg`
- `assets/mechanics2/dual-2-4.svg.import`
- `assets/mechanics2/dual-3-4.svg`
- `assets/mechanics2/dual-3-4.svg.import`
- `assets/mechanics2/garden-medal.svg`
- `assets/mechanics2/garden-medal.svg.import`
- `assets/mechanics2/pin-1.svg`
- `assets/mechanics2/pin-1.svg.import`
- `assets/mechanics2/pin-2.svg`
- `assets/mechanics2/pin-2.svg.import`
- `data/levels-31-50.json`
- `docs/MECHANICS_ROADMAP.md`
- `docs/PACKAGE2_REPORT.md`
- `docs/RELEASE_v0.5.0.md`
- `docs/STATUS.md`
- `docs/performance/package2-balanced.json`
- `docs/performance/package2-level-tests.json`
- `docs/performance/package2-low.json`
- `docs/performance/package2-native-swipes.json`
- `export_presets.cfg`
- `project.godot`
- `scripts/core/board.gd`
- `scripts/core/board_generator.gd`
- `scripts/core/flexible_match_resolver.gd`
- `scripts/core/flexible_match_resolver.gd.uid`
- `scripts/core/level_catalog.gd`
- `scripts/core/match_detector.gd`
- `scripts/core/powerups.gd`
- `scripts/core/resonance.gd`
- `scripts/core/save_manager.gd`
- `scripts/mechanics/crystal_traits.gd`
- `scripts/mechanics/crystal_traits.gd.uid`
- `scripts/mechanics/gravity_pin.gd`
- `scripts/mechanics/gravity_pin.gd.uid`
- `scripts/mechanics/mechanic_manager.gd`
- `scripts/mechanics/mechanic_registry.gd`
- `scripts/mechanics/objective_manager.gd`
- `scripts/ui/board_view.gd`
- `scripts/ui/celebration.gd`
- `scripts/ui/crystal_trait_animation.gd`
- `scripts/ui/crystal_trait_animation.gd.uid`
- `scripts/ui/main.gd`
- `scripts/ui/mechanic_animation_controller.gd`
- `scripts/ui/strings.gd`
- `tests/move_solver.gd`
- `tests/package2_capture.gd`
- `tests/package2_capture.gd.uid`
- `tests/package2_levels.gd`
- `tests/package2_levels.gd.uid`
- `tests/package2_tests.gd`
- `tests/package2_tests.gd.uid`
- `tests/package2_ui.gd`
- `tests/package2_ui.gd.uid`
- `tests/swipe_stress.gd`
- `tests/visual_performance.gd`
- `tools/build_android.sh`
- `tools/generate_mechanics2.py`
- `tools/normalize_package2.gd`
- `tools/normalize_package2.gd.uid`
- `tools/test.sh`
