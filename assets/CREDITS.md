# PRİZMA varlık kaynakları

- `art/garden.png`: PRİZMA için bu çalışma sırasında image generation aracıyla oluşturulan özgün bahçe illüstrasyonu; kullanıcı kolajı yalnızca dünya fikri referansıdır. Oyun, indirme veya uzaktan medya yükleme yapmaz.
- `crystals/*.svg`: `tools/generate_crystals.py` ile bu revizyonda tasarlanan beş özgün yüzeyli kristal ve dört özel güç. Ortak 768×768 atlas, 1000×1120 tahta/zemin görseli, saydam vektör kaynakları ve parıltı dokusu; emoji veya hazır simge paketi kullanılmadı.
- `art/icon.svg`, shader ve arka plan sembol çizimleri: bu projede oluşturulan özgün vektör/prosedürel tasarım.
- `audio/*.wav`: `tools/generate_audio.py` ile oluşturulmuş özgün deterministik sentezler; üçüncü taraf kayıt kullanılmadı. Müzik kısa bir çevrimdir; sonraki sanat aşamalarında geliştirilebilir.
- Godot varsayılan yazı tipi Godot'un beraberindeki lisans kapsamındadır; ek ücretli font eklenmedi.

Hiçbir başka oyunun karakteri, blok varlığı, müziği veya arayüz dosyası kopyalanmadı.

0.4.0: `assets/mechanics/*.svg` tohum/kapsül/çiçek, saydam buz, taş ve beş renkli kilit varlıkları `tools/generate_mechanics.py` ile bu proje için özgün oluşturulmuştur. Dışarıdan ikon, emoji, görsel veya telifli ses indirilmedi. Mekanik açılmalarında projenin mevcut özgün sentezlenmiş sesleri kullanılır.

0.5.0: `assets/mechanics2/*.svg`, on çift renkli kristal, beş bukalemun, joker köprü, iki metalik çivi durumu ve Büyülü Bahçe madalyası `tools/generate_mechanics2.py` ile özgün tasarlanmıştır. Ana kristal, bahçe ve özgün sentez sesleri korunur; yeni dış kaynak/telifli içerik kullanılmaz.
