extends RefCounted
## Central Turkish copy; extend with locale dictionaries later.
const COLORS := ["Kızıl", "Mavi", "Yeşil", "Altın", "Mor"]
const COPY := {
	"tagline": "RENKLERİN UYANIŞI",
	"world": "Büyülü Bahçe",
	"chapter": "BİRİNCİ DÜNYA · 50 BÖLÜM",
	"play": "OYNA",
	"resume": "DEVAM ET",
	"map": "Bahçeyi keşfet",
	"settings": "Ayarlar",
	"moves": "HAMLE",
	"score": "PUAN",
	"pause": "Bir nefes al",
	"won": "Bahçe canlanıyor!",
	"lost": "Bir kez daha deneyelim",
	"replay": "YENİDEN OYNA",
	"next": "SONRAKİ BÖLÜM",
	"home": "ANA MENÜ",
	"no_energy": "12 blok topla, yönü değiştir.",
	"gravity_hint": "Yönü seç. Sonraki patlamada bloklar o yöne kayar.",
	"swap_hint": "Bir bloğu kaydır; üç aynı sembolü yatay veya dikey eşleştir.",
	"resonance_hint": "Üç başarılı hamlede aynı rengi eşleştir; rezonansı uyandır.",
	"power_hint": "4 düz: roket · 5 düz: renk bombası · T/L: prizma.",
	"color_pick": "Renk bombası için bir renk seç",
	"combo_hint": "Komşu özel güçleri kaydırarak birleştir.",
	"shuffle": "Yeni olasılıklar · ücretsiz karıştırıldı",
	"invalid": "Üçlü oluşmadı · Takas geri alındı, hamlen korunuyor.",
	"help_body": "Bir bloğu dört yönden bir komşusuna kaydır.\n\n3 aynı renk: otomatik patlama.\n4 düz: roket. 5 düz: renk bombası.\nT/L kesişimi: prizma bombası.\n\nGeçersiz takas hamle harcamaz.\nYeni eşleşmeler kendiliğinden zincirlenir.\nÖzel güce dokunabilir veya iki komşu gücü takas edebilirsin.",
	"saved": "İlerlemen bu cihazda saklanır. İnternet gerekmez."
}

static func text(key: String) -> String:
	return COPY.get(key, key)
