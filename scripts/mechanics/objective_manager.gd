extends RefCounted
const KEYS := ["total","0","1","2","3","4","flowers","ice","stones","locks","duals","shifts","pins"]
const NAMES := {"total":"Blok","flowers":"Çiçek","ice":"Buz katmanı","stones":"Taş","locks":"Kilit","duals":"Çift renk","shifts":"Dönüşüm","pins":"Çivi"}
static func value(collected: Dictionary, key: String) -> int:
	return int(collected.get(key,0))
static func complete(targets: Dictionary, collected: Dictionary) -> bool:
	for key in targets:
		if value(collected,key) < targets[key]: return false
	return true
