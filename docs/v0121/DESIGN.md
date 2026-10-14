# v0.12.1 ekran hiyerarşisi

Açılış → aktif dünya haritası → kompakt önizleme → OYNA/geçiş → ortak HUD → sonuç → sonraki önizleme veya harita. Ayrı ana menü ve onluk bölüm aralıkları kaldırılır.

Ortak UITheme: gölgeli altın çerçeve, kontrollü krem yüzey, özgün parlak pembe birincil / turkuaz ikincil SVG eylemler; INK yüksek kontrastlı metin. Dairesel bölüm düğümleri ve ikonlu stok/seçim bileşeni. Harita üstü 86 px, gezinme 80 px; 50 düğüm hafif Button/custom draw. Can sistemi olmadığı için sahte can gösterilmez; para gerçek adventure_progress.coins verisidir.

HUD: büyük sabit hamle alanı, hedefler ve yıldızlar; 8×9 hücrelerin yerel koordinatları korunur. Öğreticiler tahta altındaki ayrı şeritte, hamle alanıyla çakışmaz. Önizleme stok tüketimi yalnızca gerçek başlangıçta; mevcut oyun devam ediyorsa tekrar tüketim yok.

Prototipler gerçek Godot 540×1200 sahneleridir. İlk kırpılmış hedef ve düşük kontrastlı düğümler kalite kontrolünde reddedilip düzeltildi. Prototipler teslim edilmiş son arayüz olarak gösterilmez; final ekranlar ayrıca ölçülür.
