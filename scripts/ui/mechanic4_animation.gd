extends RefCounted
const ATLAS=preload("res://assets/mechanics4/atlas.svg")
static func region(index: int) -> Rect2:return Rect2(index%4*256,int(index/4)*256,256,256)
static func index(kind: String, data: Dictionary) -> int:
	if kind=="vine":return 2
	if kind=="crate":return 3 if int(data.hp)==2 else 4
	return 5 if data.get("orientation","/")=="/" else 6
