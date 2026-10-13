# PRİZMA — Kalıcı çalışma kuralları

Bu dosya bütün PRİZMA görevlerinde geçerlidir. Mevcut talimatları koru ve yeni kuralları birleştir; kullanıcı talimatları önceliklidir. Mevcut Godot projesini yeniden oluşturma. Kullanıcı istemedikçe Git worktree oluşturma.

## Çalışma düzeni
- Başlangıçta Git durumunu ve ilgili dosyaları incele; kısa plan oluştur. Önce hızlı, bağımsız işleri tamamla. Büyük işleri küçük, test edilebilir değişikliklere böl.
- Yalnızca gerekli dosyaları oku. Önceden incelenmiş, değişmemiş dosyaları tekrar analiz etme. Uzun terminal çıktıları yerine kısa özet göster; ayrıntıları log dosyasında tut. Hatalarda ilgili log bölümünü incele.
- Tamamlanan işler, kalan işler ve engelleri kısa `docs/WORK_PROGRESS.md` dosyasında takip et. Aynı açıklamaları tekrar etme.
- Normal geliştirmede SMOKE ve değişikliğe uygun TARGETED kullan. FULL yalnızca sürüm finalinde, büyük çekirdek motor değişikliğinde veya somut risk gerektirdiğinde çalıştır. Ayrıntı: `docs/TEST_POLICY.md`.
- Aynı başarılı testi ilgili kod, girdiler, araç sürümü veya koşullar değişmediyse tekrar çalıştırma. Sonuçları içerik parmak izi, commit, komut, süre ve durumla sakla; yalnızca doğrulanmış eşleşmeleri yeniden kullan.
- Görsel değişiklikte görsel/UI testleri; bölüm değişikliğinde ilgili bölümler; mekanik değişikliğinde ilgili mekanik ve onu kullanan bölümler; eşleşme/yer çekimi değişikliğinde bütün bölümleri kapsayan regresyon seç.
- Küçük seed örneklemiyle başla; başarısız/sınırda bölümlerde artır. Hatalı bölümleri hız uğruna onaylama. Kritik kayıt bütünlüğü, güvenlik ve varsa ödeme testlerini atlama.
- Başarısız testte nedeni belirle, yalnızca etkilenen testi yeniden çalıştır. Sonsuz düzeltme döngüsü kurma. Uzun/takılmış testte süreyi, logu ve süreci incele. İptal, zaman aşımı, başarısız, atlanmış ve çalıştırılmamış sonuçları başarıdan ayrı raporla.

## APK ve GitHub
- Geliştirme tamamlanmadan APK üretme; her küçük değişiklikte derleme yapma. Android önbelleğini kullan. Aynı başarılı APK'yı tekrar derleme.
- Finalde APK'nın varlığını, ZIP/veri bütünlüğünü, paket kimliğini, sürümünü ve imzasını doğrula. Mevcut paket/imzayı ve kayıtları koru; imza anahtarını değiştirme, okumaya/çıktıya/commit'e dahil etme.
- Sürüm teslimatında kodu GitHub'a gönder, APK'yı yeni Releases sürümünde yayımla ve erişilebilirliği doğrula. Eski sürümü silme veya üzerine yazma.
- Geçici GitHub hatasında ilk girişimden sonra en fazla iki kontrollü yeniden deneme yap. Aynı başarısız indirmeyi sürekli tekrarlama. Kalıcı/yinelenen yayın hatasında nedeni ve mevcut APK yolunu bildir, dur. Başarılı Git gönderiminden sonra gereksiz doğrulama döngüsü kurma.
- Gerçek Android cihazında yapılmamış testi/FPS ölçümünü yapılmış gösterme. Mantık ve animasyon sonuçlarını karıştırma.

## Teslimat
Kısa rapor: tamamlanan özellikler; başarılı/başarısız testler; test edilemeyen noktalar; APK sürümü ve Releases bağlantısı; önemli bilinen sorunlar. Gereksiz büyük rapor/video üretme. Yalnızca çalışma düzeni veya dokümantasyon değiştiyse APK/sürüm üretme. Kullanıcının onayı olmadan sonraki geliştirme aşamasına geçme.
