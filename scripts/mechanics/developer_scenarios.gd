extends RefCounted
## Dedicated isolated laboratory boards; never inserted into the campaign catalog.
static func make(kind: String, seed: int) -> Dictionary:
	var d: Dictionary={"id":1,"world":1,"name":"Mekanik laboratuvarı","seed":seed,"moves":100,"targets":{"total":10000},"stars":[1000,2000,3000],"layout":[],"gravity":true,"resonance":true,"mechanics":[],"powers":{},"development_only":true,"opening_refill":[]}
	for y in 9:
		for x in 8:d.layout.append((x+y*2)%5)
	if kind=="portal":
		d.name="Portal geçiş sahnesi";d.portals=[{"entry":65,"exit":0}]
		d.layout[64]=0;d.layout[65]=0;d.layout[66]=1;d.layout[58]=0
		d.tutorial_swap=[58,66]
		d.tutorial="58 → 66 kaydır. Alt üçlü patlar; 65'e düşen kristal 0'a ışınlanır. Portal renkli blok değildir."
	elif kind=="vine":
		d.name="Canlı sarmaşık sahnesi";d.vine_enabled=true;d.vine_max=6
		d.mechanics=[{"kind":"vine","index":27},{"kind":"vine","index":44}]
		d.tutorial="Üç başarılı takas sonunda en fazla bir sarmaşık büyür. Yanında eşleştirerek temizle. Geçersiz takas sayılmaz."
	elif kind=="crate":
		d.name="Sandık zinciri sahnesi"
		d.mechanics=[{"kind":"crate","index":35},{"kind":"crate","index":36},{"kind":"ice","index":28},{"kind":"stone","index":43}]
		d.powers={"34":"rocket_h","42":"rocket_h"}
		d.tutorial="34'teki roketi, sonra 42'deki roketi etkinleştir. İki ayrı darbe sandıkları patlatır; 3×3 etkiler zincirlenir."
	elif kind=="mirror":
		d.name="Ayna yansıma sahnesi"
		d.mechanics=[{"kind":"mirror","index":19,"orientation":"\\"},{"kind":"mirror","index":35,"orientation":"/"},{"kind":"mirror","index":33,"orientation":"\\"},{"kind":"mirror","index":17,"orientation":"/"}]
		d.powers={"18":"rocket_h"}
		d.tutorial="18'deki roketi etkinleştir. Dört ayna ışını yönlendirir; kapalı ışın yolu güvenli biçimde sonlanır."
	elif kind=="fountain":
		d.name="Boyama çeşmesi sahnesi";d.targets={"fountains":3,"total":10000};d.mechanics=[{"kind":"fountain","index":35,"color":1},{"kind":"dual","index":47,"colors":[0,1]},{"kind":"bridge","index":50}]
		d.layout[26]=0;d.layout[27]=0;d.layout[28]=1;d.layout[20]=0;d.tutorial_swap=[20,28]
		d.tutorial="20 → 28 kaydır. Çeşme en yakın üç korunmasız kristali maviye boyar. Çift renk ve köprü korunur."
	elif kind=="bubble":
		d.name="Yüzen baloncuk sahnesi";d.targets={"bubbles":2,"total":10000};d.mechanics=[{"kind":"bubble","index":40},{"kind":"bubble","index":43},{"kind":"stone","index":24}]
		d.powers={"48":"rocket_h"};d.portals=[{"entry":8,"exit":3}]
		d.tutorial="48'deki roketle boşluk aç. Baloncuklar boş hücrelerde yer çekiminin tersine ilerler. Eşleşmeyle katman kırılır."
	elif kind=="conveyor":
		d.name="Konveyör rayları sahnesi";d.targets={"conveyors":8,"total":10000};d.conveyors=[{"cells":[26,27,28,36,44,43,42,34],"loop":true}]
		d.portals=[{"entry":43,"exit":0}];d.mechanics=[{"kind":"stone","index":55}]
		d.tutorial="Başarılı hamleden sonra kristaller ok yönünde bir hücre ilerler. Ray aynı hamlede tekrar dönmez."
	elif kind=="seal":
		d.name="Şifreli mühür sahnesi";d.targets={"seals":1,"total":10000};d.mechanics=[{"kind":"seal","index":35,"sequence":[0,1,2]}]
		d.tutorial="Mühüre dokun: kırmızı → mavi → yeşil sırasını gör. Her başarılı oyuncu hamlesi yalnızca bir adım ilerletir."
	return d
