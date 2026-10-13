# Godot performans ölçümleri — Oynanış 2.0

Godot 4.6.3, --profiling, Linux/Xvfb :99, 540×960, Mesa llvmpipe LLVM19.1.7 yazılım rendererı, 60 FPS sınırlayıcı. Nihai koşuda renderer thread limiti yoktur; bulut CPU kotası 4 vCPU. Telefon/emülatör bağlı değildir. Bunlar Android ölçümü değildir.

100 geçerli ScreenTouch kaydırma, 100 engellenen tekrar, 10 geçersiz takas; 76–100 arasındaki 25 bölüm. Mantık/kararlı tahta doğrulamaları geçti. Native benchmark kendi test profiline senkron kayıt yazar; gerçek uygulama arka plan yazıcı kullanır. Sahne geçişleri ve test çözücüsü kare istatistiğine dahildir.

| Ölçüm | Ortalama | p95 | Maksimum |
|---|---|---|---|
| Kare aralığı (14009 kare) | 16.730 ms / 59.77 FPS | 16.856 ms | 566.773 ms |
| Dokunma callback | 0.003 ms | 0.004 ms | 0.024 ms |
| Dokunma → görsel CPU gönderimi | 0.170 ms | 0.781 ms | 2.183 ms |
| Sürükleme → görsel CPU gönderimi | 7.204 ms | 11.077 ms | 40.268 ms |
| Takas ve bütün zincir mantığı | 3.944 ms | 7.600 ms | 37.091 ms |
| Eşleşme taraması | 0.171 ms | 0.223 ms | 4.412 ms |
| Temizleme | 0.359 ms | 0.416 ms | 30.596 ms |
| Yer çekimi | 0.151 ms | 0.232 ms | 1.729 ms |
| Dolum | 0.024 ms | 0.034 ms | 0.210 ms |
| Fırtına taşıma | 0.118 ms | 0.143 ms | 0.188 ms |
| Dalga boyama | 0.230 ms | 0.276 ms | 0.319 ms |
| Tahta çizim komutları CPU | 0.571 ms | 0.959 ms | 2.777 ms |
| Takas animasyonu | 184.093 ms | 191.754 ms | 196.299 ms |
| Geçersiz geri dönüş | 148.664 ms | 150.000 ms | 150.000 ms |
| Render CPU monitorü | 1.824 ms | 2.853 ms | 16.670 ms |
| Render GPU zaman sorgusu | 9.045 ms | 11.238 ms | 562.704 ms |

**Tekil gecikme gizlenmedi:** en uzun kare 566,773 ms; GPU zaman sorgusu en çok 562,704 ms. Mantık takası en çok 37,091 ms, temizleme 30,596 ms oldu. Bütün karelerde 16,7 ms bütçesi karşılanmadı. Yazılım rendererı/host beklemesi gözlenir; Android sürücüsü, OS input kuyruğu ve gerçek cihazdaki takılmanın nedeni bu ölçümden kesinleşmez.

Dokunma/görsel süresi CPU çizim gönderimidir; fiziksel parmak→Android→ekran gecikmesi değildir. Performance.TIME_PROCESS, engine process zamanıdır; bağımsız CPU çevrim sayımı değildir. Monitorler son 2.048 örneği, kare tablosu 14.009 karenin tamamını kullanır.

## Altı birleşim, iki kalite

Her birleşim dengeli/performans ayarında iki kez: 24 gerçek render senaryosu. Fırtına hazırdı; otomatik zincirler tamamlandı, kaskad koruması tetiklenmedi.

| Kalite | Birleşim | Mantık aralığı | Kare ortalaması | En kötü p95 |
|---|---|---|---|
| balanced | rocket_rocket | 2.528–3.540 ms | 16.797 ms / 59.54 FPS | 20.876 ms |
| balanced | rocket_prism | 3.391–4.005 ms | 16.633 ms / 60.12 FPS | 16.721 ms |
| balanced | prism_prism | 3.735–3.960 ms | 16.670 ms / 59.99 FPS | 17.474 ms |
| balanced | color_rocket | 4.954–7.269 ms | 17.691 ms / 56.52 FPS | 29.137 ms |
| balanced | color_prism | 4.759–4.804 ms | 17.444 ms / 57.33 FPS | 26.566 ms |
| balanced | color_color | 4.328–4.873 ms | 16.955 ms / 58.98 FPS | 20.752 ms |
| performance | rocket_rocket | 2.846–3.255 ms | 16.634 ms / 60.12 FPS | 16.760 ms |
| performance | rocket_prism | 3.523–3.787 ms | 16.656 ms / 60.04 FPS | 16.881 ms |
| performance | prism_prism | 4.893–5.267 ms | 16.634 ms / 60.12 FPS | 16.841 ms |
| performance | color_rocket | 4.955–5.619 ms | 16.687 ms / 59.93 FPS | 19.749 ms |
| performance | color_prism | 4.694–4.954 ms | 16.719 ms / 59.81 FPS | 18.484 ms |
| performance | color_color | 4.925–6.883 ms | 16.887 ms / 59.22 FPS | 21.751 ms |

Native static-memory monitorü en çok 49.48 MiB, canlı nesne monitorü 1984. Birleşimlerin tümü 6 tahta çocuğu / 192 sabit partikül slotuyla bitti. Kesin tahsis-adedi/byte-allocation profili ölçülmedi; nesne/bellek monitorü bunu kanıtlamaz.

Koruma: kaliteye bağlı partikül bütçesi, sabit etiket/efekt havuzları, merkezi tekilleştirilmiş güç alanları ve doğuş hücresi önbelleği kullanılır. Her blok için yeni sahne/texture yüklenmez. Animasyon sonunda current={} yerel referansı bırakır; mantıksal olay sözlüğü clear() ile silinmez. Metadata değişmezlik testleri vardır.

Android FPS/p95/max, uzun kullanımda pil/ısı, fiziksel dokunma, hoparlör/haptik, gerçek çentik/sistem çubukları, APK kurulum ve cihaz arka plan/geri dönüş kabulü henüz doğrulanmadı. Desktop/headless pause/resume ve safe-area testleri bunların yerine sunulmaz.

[Ham native JSON](performance/gameplay2-native-touch.json) · [Ham birleşim JSON](performance/gameplay2-effects-performance.json). APK içinde Ayarlar → Performans raporu kullanılabilir.
