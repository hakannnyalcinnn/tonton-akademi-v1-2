extends RefCounted
const ATLAS=preload("res://assets/casual/devices.png")
static func region(index: int) -> Rect2:return preload("res://scripts/ui/casual_skin.gd").region("devices",index)
static func index(kind: String, data: Dictionary) -> int:
	if kind=="vine":return 2
	if kind=="crate":return 3 if int(data.hp)==2 else 4
	return 5 if data.get("orientation","/")=="/" else 6
