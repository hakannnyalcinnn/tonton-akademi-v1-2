extends RefCounted
const ATLAS=preload("res://assets/casual/traits.png")
const PAIRS: Array=[[0,1],[0,2],[0,3],[0,4],[1,2],[1,3],[1,4],[2,3],[2,4],[3,4]]
static func regions() -> Array[Rect2]:
	var result: Array[Rect2]=[]
	for i in 18:result.append(preload("res://scripts/ui/casual_skin.gd").region("traits",i))
	return result
static func index(cell: Dictionary) -> int:
	var t: Dictionary=cell.trait
	if t.kind=="bridge":return 15
	if t.kind=="chameleon":return 10+int(cell.c)
	var pair: Array=t.colors.map(func(c):return int(c))
	pair.sort()
	return PAIRS.find(pair)
