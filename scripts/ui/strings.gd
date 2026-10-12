extends RefCounted
## Central Turkish copy; extend with locale dictionaries later.
const COLORS := ["Kızıl", "Mavi", "Yeşil", "Altın", "Mor"]
const COPY := {
	"tagline": "RENKLERİN UYANIŞI",
	"world": "Büyülü Bahçe",
	"chapter": "BİRİNCİ DÜNYA · 10 BÖLÜM",
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
	"tap_hint": "Yan yana iki aynı sembole dokun. Tek blok da hamle harcar.",
	"resonance_hint": "Aynı rengi üç kez patlat: yakındaki dört blok da ışığa dönüşsün.",
	"power_hint": "5+ blok roket, 7+ prizma, 10+ renk bombası oluşturur.",
	"color_pick": "Renk bombası için bir renk seç",
	"combo_hint": "Birleştirmek için komşu özel güce dokun.",
	"shuffle": "Yeni olasılıklar · ücretsiz karıştırıldı",
	"invalid": "Bu blok yalnız! Bir grup seç.",
	"saved": "İlerlemen bu cihazda saklanır. İnternet gerekmez."
}

static func text(key: String) -> String:
	return COPY.get(key, key)
