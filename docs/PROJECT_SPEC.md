# PRİZMA — Renklerin Uyanışı

## Güncel proje hedefi
Android öncelikli, çevrimdışı Godot 4.6.3 / GDScript **Match-3** oyunu. Kullanıcının acil revizyonu, önceki tap-blast kurallarını tamamen değiştirdi. Mevcut marka, menü, fantastik bahçe, blok çizimleri, dünya/bölüm, puan, kayıt, ses/ayar ve modüler mimari korunur. Yalnızca ilk aşamanın 10 bölümü ve bu motor revizyonu kapsam içindedir; başka aşamaya kullanıcı talimatı olmadan geçilmez.

## Kabul kuralları
- 8×9, beş renk ve beş ayırt edilebilir sembol. Normal bloğa dokunmak işlemsizdir.
- Sürükleme dört yönde yalnızca bir komşuya takas yapar. Çapraz/uzak takas reddedilir. Kısa, hızlı ve yavaş kaydırma; tahta dışına bırakmayı iptal etme; ikinci parmağı ve animasyon sırasındaki ek girişi engelleme.
- Yatay/dikey düz 3+ normal renk çizgileri patlar. Çapraz, ikili ve çizgisiz kümeler patlamaz. Kesişen çizgiler birleşir ve her hücre bir kez sayılır.
- Geçersiz takas dışarı/geri animasyonu oynatır; hamle, puan, hedef, RNG ve rezonans değişmez.
- Geçerli eylem sonrası bütün patlama/düşüş/dolum/yeniden eşleşme dalgaları otomatik tamamlanır. Zincir ilave hamle harcamaz; en çok x5 puan çarpanı. Sonuç son zincirden sonra kontrol edilir.
- 4 düz → ekseni gösterilen roket; 5+ düz → renk bombası; 5+ T/L → prizma. Öncelik renk bombası > prizma > roket. Takas hedefi/kaynağı, zincirlerde kesişim/satır/sütun önceliği. Yeni güç oluştuğu dalgada kendi kendine tetiklenmez.
- Doğrudan roket/prizma aktivasyonu, renk seçmeli bomba ve özel-normal takasları açık tanımlı bir hamlelik istisnalardır. İki komşu güç takası birleşebilir. Tam istisna/etki tablosu `MATCH3_REVISION.md` içindedir.
- Dört yön korunur: her 12 normal blok bir enerji, kapasite 2; yön değişimi bir enerji ve sıfır normal hamle. Mevcut boşluk ve eşleşmeler otomatik çözülür. Dolu dikdörtgende sahte kaydırma veya blok silme yapılmaz; yön sonraki dolumu etkiler.
- Rezonans üç başarılı normal oyuncu hamlesinin ilk dalgasına göre ilerler; otomatik zincirler ayrı oyuncu hamlesi sayılmaz. Çok renkli eşleşmede takas hedefinin rengi tercih edilir. Üçüncü aynı renkte Manhattan ≤2 içinde en çok dört normal blok mesafe/satır/sütun sırasıyla temizlenir. Yön eylemi zinciri korur.
- Başlangıç ve kararlı tahtada hazır eşleşme yok; en az bir geçerli eylem var. Normal blok kimlik/renk çoklu kümesini koruyan ücretsiz karıştırma, özel ve sabit hücreleri yerinde bırakır.
- 10 açık tanımlı öğretici bölüm: temel yatay, dikey, roket, yön, renk bombası, rezonans, otomatik zincir, karma hedef, birleşim, dünya meydan okuması.
- Merkezi puan/yıldız, en iyi sonuç, tekrar oynama ve sırayla açılma; son hamle zinciri bittikten sonra kazanma/kaybetme. Bonus/ödül olayları bir kez.
- Schema/rules 2 atomik JSON + yedek. Schema 1 dosyası byte olarak arşivlenir; ilerleme/ayarlar korunur, aktif bölüm yeni Match-3 başlangıcına tam bütçeyle dönüştürülür ve kullanıcıya açıklanır. Desteklenmeyen gelecek schema üzerine yazılmaz.
- Mantık ve animasyon bağımsızdır. İşlem sonucu ve sıralı animasyon kareleri hesaplanır; sunum sırasında durum kilidi ve PAUSED durumu girişleri engeller. Kayıtlar yalnızca tamamen kararlı mantıksal durumu içerir.

## Görsel ve teknik yapı
Sembollü parlak özgün bloklar, yapay zekâ destekli özgün bahçe illüstrasyonu, renkle canlanan dünya, sürükleyen el eğitimi, akıcı takas/geri dönüş/patlama/düşüş, zincir bildirimleri, rezonans ve zafer efektleri. Müzik, efekt, titreşim, hareket azaltma ve erişilebilir renk seçenekleri korunur. Türkçe arayüz metinleri merkezi `scripts/ui/strings.gd` dosyasındadır.

Çekirdek: Board/state machine, MatchDetector, BoardGenerator, Gravity, Resonance, PowerUps, Score, LevelCatalog/validator, SeedRng, SaveManager. UI: Main, BoardView, Garden, AudioManager, Celebration. İleride ekonomi/görev/mağaza/engeller eklendiğinde mevcut modüller genişletilir; içi boş servisler eklenmez.

## Dünya ve gelecek aşamalar
İlk on bölüm Büyülü Bahçe'dedir. Görsel referans dünyaları: Büyülü Bahçe, Derin Okyanus, Buz Krallığı, Volkan Diyarı, Galaksi, Altın Çöl. İleri engeller, zincir şimşeği, görev/günlük/sonsuz mod, başarımlar, kozmetik ekonomi, mağaza/PRO/Billing/reklam ve 1.000 bölüm sistemi yapılmaz. Engeller için sabit hücre sözleşmesi test edilmiştir; engel oyunu bu sürüme eklenmez.

Gerçek Android cihaz testleri, düşük segment FPS/bellek ve yaşam döngüsü cihazda ayrıca ölçülmelidir. Bunlar başsız mantık testleriyle tamamlanmış sayılmaz. Önceki geçici CI imzası nedeniyle yeni ayrı test profili eski telefondaki uygulamayı ve kayıtlarını değiştirmeden yanına kurulabilir.
