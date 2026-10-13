# Performans ölçümü

Godot 4.6.3, Xvfb 540×960, Mesa llvmpipe, Compatibility renderer, `--profiling --max-fps 60`. Gerçek Android cihaz kullanılmadı. PNG kaydı kapalı temiz ölçüm: 35 hamle, 5075 gözlenen frame. Merkezi örnek havuzu son 2048 frame ile sınırlıdır.

| İşlem | Ortalama ms | p95 ms | Maksimum ms |
|---|---:|---:|---:|
| frame_interval | 16.697 | 16.884 | 78.105 |
| player_action_total | 4.293 | 6.550 | 9.252 |
| match_scan | 0.145 | 0.203 | 0.370 |
| clear_logic | 0.210 | 0.341 | 0.480 |
| gravity_logic | 0.102 | 0.170 | 0.416 |
| refill_logic | 0.024 | 0.034 | 0.247 |
| legal_move_logic | 0.128 | 0.306 | 2.045 |
| shuffle_logic | 0.993 | 0.993 | 0.993 |
| render_cpu | 1.816 | 2.660 | 19.970 |
| render_gpu | 8.604 | 10.728 | 29.551 |
| main_thread_cpu | 21.600 | 34.510 | 39.116 |

Frame ortalamasının karşılığı yaklaşık 59.89 FPS. Bu Android için 60 FPS garantisi değildir. Tekil frame gecikmeleri 16,7 ms bütçesini aşıyor; yazılımsal GPU/host koşullarında ölçüldü, telefon kök nedeni olarak sunulamaz.
Gözlenen statik bellek zirvesi 48.48 MiB. Efekt havuzu 192 slot, kaliteye göre aktif sınır korunuyor; tahta görünümünde altı sabit düğüm kullanımı sürüyor.

İlk PNG kayıtlı iki koşunun ham raporları ayrıca dahil edildi. PNG GPU okuması ve disk yazımı frame gecikmelerini etkiler; temiz ölçüm esas alındı. Performans kalite modunda 35 hamlelik render koşusu ayrıca tamamlandı.

Dokunmatik: mevcut gerçek Godot ScreenTouch/drag simülasyonları, hızlı yinelenen giriş engeli, geçersiz takas ve üç ekran oranı geçti. Fiziksel Android input-to-photon, çentik/sistem çubukları, ses gecikmesi, titreşim ve termal ölçümler yapılmadı. Ayarlardaki tanılama ekranı cihazdan frame/işlem raporu alınmasına devam ediyor.
