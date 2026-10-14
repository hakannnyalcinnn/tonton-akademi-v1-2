extends RefCounted
## Central Turkish copy; extend with locale dictionaries later.
const COLORS := ["Kızıl", "Mavi", "Yeşil", "Altın", "Mor"]
const COPY := {
	"tagline": "RENKLERİN UYANIŞI",
	"world": "Büyülü Bahçe",
	"chapter": "BİRİNCİ DÜNYA · 50 BÖLÜM",
	"play": "OYNA",
	"resume": "DEVAM ET",
	"map": "Haritayı keşfet",
	"settings": "Ayarlar",
	"moves": "HAMLE",
	"score": "PUAN",
	"pause": "Bir nefes al",
	"won": "Bahçe canlanıyor!",
	"lost": "Bir kez daha deneyelim",
	"replay": "YENİDEN OYNA",
	"next": "SONRAKİ BÖLÜM",
	"home": "HARİTA",
	"no_energy": "12 normal kristal: Prizma Fırtınası kendiliğinden çalışır.",
	"gravity_hint": "Fırtına en fazla üç normal kristali temizler; kristaller aşağı düşer.",
	"swap_hint": "Bir bloğu kaydır; üç aynı sembolü yatay veya dikey eşleştir.",
	"resonance_hint": "Üç başarılı hamlede aynı rengi eşleştir; rezonansı uyandır.",
	"power_hint": "4 düz: roket · 5 düz: renk bombası · T/L: Gökkuşağı Yıldızı.",
	"color_pick": "Renk bombası için bir renk seç",
	"combo_hint": "Komşu özel güçleri kaydırarak birleştir.",
	"shuffle": "Yeni olasılıklar · ücretsiz karıştırıldı",
	"invalid": "Üçlü oluşmadı · Takas geri alındı, hamlen korunuyor.",
	"help_body": "Komşu kristale kaydır → 3 aynı renk.\n4 düz: roket · 5 düz: renk bombası.\nT/L kesişimi: Gökkuşağı Yıldızı (prizma bombası).\nYıldız, merkezden iki hücre uzaklıktaki alanı temizler.\n\nGeçersiz takas hamle harcamaz.\nZincirler kendiliğinden patlar.\nİki komşu özel gücü birleştirebilirsin.\n\n12 normal kristal: Prizma Fırtınası.\nFırtına üç normal kristali temizler. Yer çekimi her zaman aşağıdır.\n3 eşleşme aşaması: Kristal Dalgası.\nBir hamlede her biri yalnızca bir kez.\nHedef ikonuna dokun: açıklama ve vurgu.",

	"saved": "İlerlemen bu cihazda saklanır. İnternet gerekmez."
}

static func text(key: String) -> String:
	return COPY.get(key, key)
