# PRİZMA 0.5.0 — İki Rengin Uyanışı (Android test)

Mevcut oyuna mekanik paketi 2 eklendi. Çift renkli ve bukalemun kristaller 31–50.
bölümlerde kullanılır. Prizma Köprüsü ve Yer Çekimi Çivisi kodlanıp test edildi;
ilk 50 normal bölümde yer almaz, sadece geliştirici laboratuvarında denenebilir.

Kesin ve deterministik renk ataması: takas hücreleri, benzersiz eşleşen hücre sayısı,
en uzun düz çizgi ve kızıl/mavi/yeşil/sarı/mor önceliği. Aynı kristal dalgada tek renk
ve tek puan alır. Jokerlerin tek başına oluşturduğu çizgiler eşleşmez. Bukalemun
başarılı takasın ilk zincirleri bitince dönüşür; yeni eşleşmeler ilave hamle olmadan
çözülür. Çivi, iki dalgada kırılan metalik sabitlemedir; kristalin kimliği ve rengi korunur.

İlk 30 bölümün verisi, marka, bahçe, menü, ayarlar, kayıt ve performans havuzları
korundu. 50. bölümde bahçe tamamen renklenir, kalıcı ve tek seferlik dünya madalyası
verilir. Henüz yapılmamış dünya "Yeni dünya hazırlanıyor" olarak gösterilir.

`prizma-v0.5.0.apk` yaklaşık 60,6 MB. Mevcut 0.2/0.3/0.4 Match-3 uygulamasının üzerine
kurun; uygulamayı kaldırmayın. Aynı paket ve kalıcı test imzası kullanılır.
54.244 sayılmış otomatik kontrol, 2.000 oyun / 9.145 hamle, 300 sabit seed'li renk
atama oracle senaryosu, üç ayrı 100 native ScreenTouch stresi ve 72 hücrenin dört yön
koordinat testleri geçti. Detaylar `docs/PACKAGE2_REPORT.md` ve rapor ZIP'inde.

Fiziksel Android cihaz erişimi yok. Linux yazılım renderer ölçümü telefonun 60 FPS
başarısı olarak sunulmaz; seyrek uzun frame'ler raporda açıkça yer alır. Debug APK,
cihaz kabul testi içindir. Tahta başına en çok 8 çift renk/joker desteklenir; trait ile
korumanın aynı kristalde yığılması bu sürümde tanımlanmadığı için reddedilir.

Yalnızca mekanik 5–8 geliştirildi. 9–20, PRO, ödeme ve reklam geliştirilmedi.
Sonraki grup kullanıcı onayını bekliyor.
