# PRİZMA 0.2.0 — Match-3 test sürümü

**Yeni temel oynanış:** sürükle → bir komşuyla takas → yatay/dikey 3+ eşleşme → otomatik patlama/düşüş/dolum/zincir. Normal dokunarak patlatma tamamen kaldırıldı. Geçersiz takas geri döner ve hamle harcamaz.

10 bölüm yeniden düzenlendi. 4 düz çizgi roket; 5 düz renk bombası; T/L prizma oluşturur. Dört yönlü yer çekimi, oyuncu hamlesine göre rezonans, yıldız/puan, kayıt, mevcut sanat/menu/ses/ayarlar korunur.

**21.969 otomatik kontrol geçti.** 2.000 farklı başlangıç tahtası, 10 bölümde 1.000 oyun / 4.128 hamle, iki ayrı süreçte kayıt devamı, schema 1 → 2 geçişi ve gerçek GUI mouse/ScreenTouch kontrolleri test edildi. GitHub yayın akışı aynı testleri ve yayımlanan APK'nın kaynak özeti, SHA-256 ve imzasını ayrıca doğrular.

**Android telefonuna indirmek için:** Assets → `prizma-match3.apk`. Android 7.0+, ARMv7/ARM64, çevrimdışı. Uygulama adı **PRİZMA Match-3**.

**Eski uygulamanı kaldırman gerekmez.** Önceki GitHub APK'sının geçici imzası mevcut olmadığından bu test paketi ayrı kimlikle eski uygulamanın yanına kurulur. Eski uygulama ve cihazdaki eski kayıtlar korunur; yeni test profili ayrı başlar. Telefonda eski profilden yeni ayrı profile otomatik aktarım yapılmadı. Aynı imzalı orijinal uygulama güncellemesinde schema dönüşümü desteklenir ve eski dosya arşivlenir.

Bu APK yerel, doğrulanmış paketin aynısıdır; CI'da farklı geçici anahtarla yeniden imzalanmaz. Özel imzalama anahtarı Git'e veya sürüm eklerine yüklenmez.

Fiziksel Android cihaz bağlı değildi. Telefon FPS, titreşim, Android yaşam döngüsü ve telefonda kayıt geçişi cihazda doğrulanmış sayılmaz. Debug test sürümüdür, Play Store yayın paketi değildir. Başka geliştirme aşamasına geçilmedi.
