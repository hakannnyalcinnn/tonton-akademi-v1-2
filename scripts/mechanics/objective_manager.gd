extends RefCounted
const KEYS := ["rescues","bosses","total","0","1","2","3","4","flowers","ice","stones","locks","duals","shifts","pins","vines","crates","mirrors","bridges","fountains","bubbles","conveyors","seals","portals","floors","giants","magnets","cores","shield0","shield1","shield2","shield3"]
const NAMES := {"total":"Blok","flowers":"Çiçek","ice":"Buz katmanı","stones":"Taş","locks":"Kilit","duals":"Çift renk","shifts":"Dönüşüm","pins":"Çivi","vines":"Sarmaşık","crates":"Sandık","mirrors":"Ayna","bridges":"Köprü","fountains":"Çeşme","bubbles":"Baloncuk","conveyors":"Konveyör","seals":"Mühür","portals":"Portal"}
static func value(collected: Dictionary, key: String) -> int:
	return int(collected.get(key,0))
static func complete(targets: Dictionary, collected: Dictionary) -> bool:
	for key in targets:
		if value(collected,key) < targets[key]: return false
	return true
