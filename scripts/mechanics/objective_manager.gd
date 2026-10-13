extends RefCounted
const KEYS := ["total","0","1","2","3","4","flowers","ice","stones","locks"]
const NAMES := {"total":"Blok","flowers":"Çiçek","ice":"Buz katmanı","stones":"Taş","locks":"Kilit"}
static func value(collected: Dictionary, key: String) -> int:
	return int(collected.get(key,0))
static func complete(targets: Dictionary, collected: Dictionary) -> bool:
	for key in targets:
		if value(collected,key) < targets[key]: return false
	return true
