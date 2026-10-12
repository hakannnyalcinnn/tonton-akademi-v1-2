# PRİZMA — Renklerin Uyanışı

## Kaynak ve öncelik
Android öncelikli, çevrimdışı Godot 4 / GDScript blok patlatma oyunu. Kullanıcının ana metnin başındaki aşama talimatı, metin içindeki 5/50 bölüm hedeflerinden önceliklidir: **bu teslim sadece ilk aşama, 10 oynanabilir bölüm**. Kullanıcı Tonton Akademi'yi iptal etti; aynı Git deposunda PRİZMA devam eder.

## İlk aşama kabul ölçütleri
- Dikey, ölçeklenebilir 8×9 tahta; kırmızı/mavi/yeşil/sarı/mor bloklar, her renkte ayrı sembol.
- Yatay/dikey bağlı en az iki normal blok patlar; çapraz bağlantı yok. Tahtadaki tek normal bloğa dokunmak da bir hamle tüketir; arayüz uyarır. Kilitli giriş, ekran düğmeleri ve yer çekimi hamle tüketmez.
- Seed'li başlangıç ve dolum; dört yönlü sıkıştırma, karşı kenardan dolum; kendiliğinden eşleşme/patlama yok.
- 12 temizlenen normal blok = bir yer çekimi enerjisi, en çok iki. 4. bölümde açılır. Yön değiştirmek bir enerji tüketir, rezonansı korur. Tam dolu bir dikdörtgende fiziksel sıkıştırma konumu değiştirmez; seçilen yön sonraki patlamanın dolumunu değiştirir. Sırf yön değişsin diye bloklar silinmez veya rastgele taşınmaz.
- 6. bölümde açılan rezonans: üst üste aynı renkte üçüncü başarılı normal grup, Manhattan mesafesi ≤2 içindeki en fazla dört ek normal aynı renk bloğu temizler; yakınlık, satır, sütun önceliği. Farklı renk seriyi yeniden başlatır; özel güce dokunmak seriyi sıfırlar; yön değişimi bozmaz. Tetiklemeden sonra sayaç sıfıra döner.
- 5–6 normal blok roket; 7–9 prizma (Manhattan yarıçap 2); 10+ renk bombası. Oluşum hücresi dokunulan hücre; roket yatay açıklık ≥ dikey açıklık ise yatay. Yeni güç o hamlede tetiklenmez, dolumla taşınabilir. Renk bombasında oyuncu hedef rengi seçer. Temel komşu güç birleşimleri ayrı düğmeyle deterministik tetiklenir.
- 10 veri tabanlı bölüm; farklı seed, başlangıç düzeni, hedef ve hamle sınırı; sırayla açılma, tekrar oynama, kazanma/kaybetme, ücretsiz ve garantili geçerli grup karıştırması.
- Merkezi puan: temizlenen normal blok başına 20, normal grubun karesi ×5, rezonans +120, özel aktivasyon +100, birleşim +250, kazanırken kalan hamle ×100. Açık yıldız eşikleri; en iyi puan/yıldız saklanır.
- Sürümlü, atomik yerel JSON kayıt ve yedek; açık bölüm, en iyi sonuçlar, aktif tahta/RNG/hamle/hedef/rezonans/enerji, ayarlar. Ödül olayları bölüm kimliğiyle bir kez işlenir; ilk aşamada parasal ekonomi yok.
- İşlevsel ana menü, bahçe bölüm haritası, oyun, duraklatma, sonuç, ayarlar; Android geri tuşu ve uygulama arka plan bildirimi.
- Özgün bahçe görseli, sembollü parlak bloklar, dokunma/patlama/düşüş efektleri, ilerlemeyle bahçenin canlanması, özgün yerel sentez sesleri ve müzik. Müzik/efekt/titreşim/azaltılmış hareket/renk erişilebilirliği ayrı ayarlar.
- Başsız Godot otomatik mantık, kayıt, simülasyon ve UI bütünleşme testleri. Android export yapılandırması; araçlar uygunsa debug APK. Cihaz testi ayrıca raporlanır.

## Uzun vadeli hedefler (bu aşamada yapılmaz)
Engeller: buz, taş, kilit, renk değiştirici, ışık küresi, portal. Zincir şimşeği ve ileri birleşimler. 50+ bölüm, günlük bulmaca, sonsuz mod, görevler, başarımlar, profil, kozmetik/kristal ekonomisi; Billing, reklam ve PRO. Sahte satın alma/reklam düğmesi eklenmez. 1.000 bölüm sistemi bu aşamanın dışında.

## Dünya görsel yönü
Ekli görseldeki öneriler: 1–50 **Büyülü Bahçe** (çiçek/yaprak/kelebek), 51–100 **Derin Okyanus** (mercan/inci), 101–150 **Buz Krallığı**, 151–200 **Volkan Diyarı**, 201–250 **Galaksi**, 251–300 **Altın Çöl**. Bu görsel yön, önceki metnin beş dünya adlarına göre daha güncel tasarım referansıdır. İlk aşama sadece bahçenin ilk 10 bölümüdür; diğer dünyalar çalışıyormuş gibi gösterilmez. Referans görüntü doğrudan oyun varlığı olarak kopyalanmaz.

## Mimari
`scripts/core/board.gd`: görsel bağımsız hamle işlemleri ve durum; `match_detector`, `gravity`, `resonance`, `powerups`, `score`, `seed_rng`, `level_catalog`, `save_manager` ayrı çalışan modüller. `scripts/ui/main.gd` ekran akışı, `board_view.gd` animasyon/giriş, `garden.gd` dünya katmanı, `audio_manager.gd` yerel ses. `data/levels.json` sürümlü bölüm verisi. Çeviri metinleri `scripts/ui/strings.gd` içinde merkezidir. Mantık duvar saatine bağlı değildir; aynı seed ve eylem dizisi aynı tahtayı üretir.

## Kalite ve dürüstlük
60 FPS hedefi, Compatibility renderer, internet izni gerektirmeyen yerel varlıklar. Gerçek cihaz performansı, titreşim ve Android yaşam döngüsü emülatör/cihaz olmadan doğrulanmış sayılmaz. Otomatik testlerin sonuçları ve APK araç durumu `docs/STATUS.md` içinde tutulur. Kullanıcı talimatı olmadan ikinci aşamaya geçilmez.
