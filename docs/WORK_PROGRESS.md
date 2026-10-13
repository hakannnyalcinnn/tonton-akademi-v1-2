# Güncel çalışma

Görev: kalıcı çalışma/test düzeni; oyun mekaniği ve bölüm değişikliği yok.

- Tamamlandı: AGENTS.md ve TEST_POLICY; SMOKE/TARGETED/FULL giriş noktası, kısa log/JSON sonuçları, içerik tabanlı yeniden kullanım, zaman aşımı ve iptal ayrımı.
- Tamamlandı: FULL için mevcut APK'yı imza/veri/runtime ile doğrulama; gerekiyorsa açık seçenekle tek export.
- Doğrulama: SMOKE 8/8; TARGETED 8+23 kontrol başarılı. Aynı içerik/koşulla yeniden kullanımda iki test çalıştırılmadan REUSED olarak kaydedildi; JSON raporu üç işi de doğru gösteriyor. Python/Bash söz dizimi ve mevcut APK doğrulaması geçti; runtime parmak izi değişmedi.
- Çalıştırılmadı: FULL, geniş bölüm simülasyonları, yeni APK veya Releases. Bu görev için gerekli değil.
