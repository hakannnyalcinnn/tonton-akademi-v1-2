extends RefCounted
## Only real, earned inventory powers are exposed. No fictional shop items.
const ITEMS={"rocket":{"unlock":3,"name":"Roket desteği","power":"rocket_h","image":5,"help":"Bir normal kristali yatay rokete dönüştürür."},"prism":{"unlock":9,"name":"Prizma bombası","power":"prism","image":7,"help":"Bir normal kristali alan etkili Prizma gücüne dönüştürür."}}
static func unlocked(data: Dictionary,key: String) -> bool:return ITEMS.has(key) and int(data.get("unlocked",1))>=int(ITEMS[key].unlock)
static func available(data: Dictionary,key: String) -> bool:
 return unlocked(data,key) and int(data.get("adventure_progress",{}).get("inventory",{}).get(key,0))>0
