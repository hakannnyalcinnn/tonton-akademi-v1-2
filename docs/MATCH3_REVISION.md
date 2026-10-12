# PRİZMA Match-3 motor revizyonu

Bu talimat, önceki dokunarak iki blok patlatma kurallarının yerini alır. Proje ve sanat korunur; yeni aşama özellikleri eklenmez. Eski sürüm `backup/tap-blast-v0.1.0` etiketi ve çalışma alanı dışındaki Git bundle ile korundu.

## Kesin kurallar
- Normal blokta dokunma hiçbir işlem yapmaz. Sürükleme yalnızca dört yönde bir komşuya takastır; çapraz/uzak hareket geçersizdir.
- Normal takas, taşınan iki hücrenin en az birinde yatay/dikey 3+ normal blok çizgisi oluşturmalıdır. Geçersiz takas geri döner; RNG, puan, hedef, enerji, rezonans ve hamle aynı kalır.
- Tarayıcı tüm satır/sütun çizgilerini bulur. Sadece kesişen çizgiler birleşir; temas eden düzensiz aynı renk kümeleri temizlenmez. Her hücre bir dalgada bir kez sayılır.
- Güç önceliği: 5+ düz çizgi → renk bombası; 5+ T/L kesişim → prizma; 4 düz çizgi → aynı eksende roket. Her kesişen eşleşme bileşeninde en fazla bir güç. Oyuncu takasında hedef hücre, sonra kaynak hücre tercih edilir; zincirlerde kesişim hücresi, ardından satır/sütun sırası. Yeni güç kendi üretim dalgasında tetiklenmez.
- Özel güçler normal renk eşleşmelerine dahil edilmez. Roket/prizmaya dokunmak veya normal blokla takas etmek bir hamle karşılığı etkinleştirir. Renk bombasına dokununca hedef renk seçilir; normalle takasında diğer normal bloğun rengi temizlenir. İki komşu güç takası tek hamlede birleşir. İki renk bombası tüm normal blokları temizler; diğer renk bombası birleşimlerinde en çok bulunan normal renk, eşitlikte renk sırası esas alınır. Dalgaya yakalanan eski güçler bir kez zincirlenir.
- Takas/özel eylem sonrası patlat → sıkıştır → doldur → yeniden tara döngüsü hazır eşleşme kalmayana kadar otomatik sürer. Tek oyuncu eylemi tek hamle; her zincir dalgası skor çarpanını artırır (1, 2, 3, 4 ve en çok 5).
- Rezonans sadece ilk dalgadaki başarılı normal oyuncu takasında bir kez ilerler. Hedef takas hücresinin eşleşme rengi, sonra kaynak, sonra en küçük renk seçilir. Otomatik dalgalar ek ilerleme vermez; yer çekimi zinciri korur; doğrudan özel eylem zinciri sıfırlar. Üçüncü aynı renk hamlesinde Manhattan ≤2 içindeki dört ek normal renk bloğu, mesafe/satır/sütun önceliğiyle temizlenir.
- Dört yönlü yer çekimi korunur: 12 temizlenen normal blok bir enerji, kapasite 2; yön eylemi hamlesiz, bir enerji. Dolu dikdörtgende yön değişikliği tek başına boşluk yaratmaz; sonraki temizleme o yöne düşer. Varsa boşluklar/çevresel eşleşmeler yön eyleminin otomatik zincirinde çözülür.
- Başlangıç/karıştırma sonunda hazır eşleşme yok ve en az bir geçerli takas/özel eylem var. Karıştırma normal blok kimlik/renk çoklu kümesini korur; özel/sabit hücreleri taşımadan deterministik yerleştirme yapar. Sabit hücreler yer çekimi segmentlerini böler; ilk on bölümde engel oyunu eklenmez.
- Son hamlenin bütün zincirleri bittikten sonra hedef kontrol edilir; kazanma kaybetmeden önce gelir. Bonus bir kez eklenir.

## Durum ve animasyon
Mantık görsel bağımsız tek işlemde son durumu ve sıralı animasyon karelerini hesaplar. READY, SWAPPING, CHECKING_MATCHES, REVERTING_SWAP, RESOLVING_MATCHES, PLAYING_EFFECTS, APPLYING_GRAVITY, REFILLING, CHECKING_CASCADES, CHECKING_OBJECTIVES, SHUFFLING, LEVEL_COMPLETED, LEVEL_FAILED, PAUSED durumları kullanılır. Sunum kilidi boyunca ikinci işlem reddedilir. Arka plana alınırken son kararlı mantıksal durum kaydedilir; animasyonun ortası kayıt formatına girmez.

## Kayıt geçişi
Schema/rules 2. Eski schema 1 dosyası `.v1-archive` olarak korunur. Açılan bölümler, en iyi sonuçlar, tek ödül kayıtları ve ayarlar korunur; eski aktif oyun ayrıca `legacy_active` içinde arşivlenir. Uyumsuz aktif tahta aynı bölümün yeni kararlı Match-3 başlangıcıyla değiştirilir; hamleler yeni tam bütçeye döner. Oyuncuya menüde açık geçiş açıklaması gösterilir. Yeni eğitim işaretleri yeniden başlar. Eski skorlar arşivde de korunur; geçmiş başarılar silinmez.

## Android imzası sınırı
Önceki GitHub test APK'sının imzası geçici CI anahtarıyla oluşturuldu; özel anahtar yayımlanmadı/korunmadı. O anahtar olmadan aynı uygulamaya yerinde güncelleme yapılamaz. Eski uygulamayı ve verisini silmek çözüm olarak kullanılmaz: yeni Match-3 test APK'sı ayrı test uygulama kimliğiyle yan yana kurulabilir. Aynı anahtarla yapılan normal güncellemelerde schema dönüşümü otomatik çalışır; gerçek telefonda dönüşüm ayrıca doğrulanmalıdır. Yeni imzalama malzemesi Git dışında korunur.
