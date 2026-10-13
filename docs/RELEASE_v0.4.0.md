# PRİZMA 0.4.0 — Bahçenin Sırları (Android test)

Mevcut Match-3 oyunu üzerine dört mekanik: 2 darbeli tohum kapsülü, 2 katmanlı buz
zırhı, 3 dayanıklılıklı taş ve normal kristal enerjisiyle açılan renk kilidi.
İlk 10 bölüm korunur; 11–30 ayrı bölüm verisinden eklenir. Otomatik zincir, dört
yönlü yer çekimi, rezonans ve geçersiz takasta hamle koruması devam eder.

Beş kristalin görselleri ve havuzlanmış efektler korunur. Yeni engeller 13 özgün SVG
durumuyla aynı fantastik sanat stilini kullanır. Kilitlerin yakınında görülen atlas
kırpılması doğrudan bölge çizimiyle giderildi ve gerçek render piksel kontrolü eklendi.

İndirilecek dosya `prizma-v0.4.0.apk` (yaklaşık 59,7 MB).

PRİZMA Match-3 0.2/0.3 üzerine güncelleme olarak kurun; uygulamayı kaldırmayın.
Aynı paket ve kalıcı test imzası kullanılır. Bölümler, yıldızlar, ayarlar ve aktif
ilk-on-bölüm kayıtları korunur; tamamlanmış 10. bölüm kayıtları 11'i açar.
Debug APK'da Ayarlar > Geliştirici: mekanik laboratuvarı yalnızca kayıt dışı bir
seed tahtasını değiştirir. Normal Android dışa aktarma hedefinde bu araçlar görünmez.

Test ayrıntıları, bölüm dengesi ve gerçek ölçümler `docs/STAGE2_REPORT.md` içindedir.
Gerçek Android cihazda FPS, gecikme ve yaşam döngüsü testi yapılmadı; cihaz erişimi
yoktur. APK fiziksel cihaz doğrulaması içindir. `prizma-stage2-report.zip` raporları,
ölçüm JSON dosyalarını ve render görüntülerini içerir. Sadece dört mekanik tamamlandı;
kalan 16 mekanik kullanıcı onayını bekliyor.
