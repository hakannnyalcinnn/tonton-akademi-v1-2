extends RefCounted
const ATLAS=preload("res://assets/mechanics2/atlas.svg")
const PAIRS: Array=[[0,1],[0,2],[0,3],[0,4],[1,2],[1,3],[1,4],[2,3],[2,4],[3,4]]
static func regions() -> Array[Rect2]:
	var result: Array[Rect2]=[]
	for i in 18:result.append(Rect2(i%5*256,int(i/5)*256,256,256))
	return result
static func index(cell: Dictionary) -> int:
	var t: Dictionary=cell.trait
	if t.kind=="bridge":return 15
	if t.kind=="chameleon":return 10+int(cell.c)
	var pair: Array=t.colors.map(func(c):return int(c))
	pair.sort()
	return PAIRS.find(pair)
