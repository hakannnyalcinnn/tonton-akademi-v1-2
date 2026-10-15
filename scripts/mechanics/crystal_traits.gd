extends RefCounted
## Pure crystal capabilities and one hook per successful player swap.
const MAX_FLEXIBLE := 8
static func normal(cell: Variant) -> bool:
	return cell!=null and cell.p=="" and not cell.get("fixed",false) and not cell.get("delivery",false)
static func domains(cell: Variant) -> Array:
	if not normal(cell): return []
	var t: Dictionary=cell.get("trait",{})
	if t.get("kind","")=="bridge": return [0,1,2,3,4]
	if t.get("kind","")=="dual":
		var result: Array=t.colors.duplicate()
		result.sort()
		return result
	return [int(cell.c)]
static func supports(cell: Variant, color: int) -> bool:
	if not normal(cell): return false
	var t: Dictionary=cell.get("trait",{})
	if t.get("kind","")=="bridge": return true
	if t.get("kind","")=="dual": return color in t.colors
	return int(cell.c)==color
static func flexible(cell: Variant) -> bool:
	return normal(cell) and cell.get("trait",{}).get("kind","") in ["dual","bridge"]
static func bridge(cell: Variant) -> bool:
	return normal(cell) and cell.get("trait",{}).get("kind","")=="bridge"
static func has_flexible(cells: Array) -> bool:
	for cell in cells:
		if flexible(cell): return true
	return false
static func advance(cells: Array, collected: Dictionary) -> Array:
	var result: Array=[]
	for i in cells.size():
		if not normal(cells[i]) or cells[i].get("trait",{}).get("kind","")!="chameleon": continue
		var t: Dictionary=cells[i].trait
		var old_color: int=cells[i].c
		t.count+=1
		var changed: bool=t.count>=t.period
		if changed:
			t.count=0
			t.phase=(int(t.phase)+1)%t.sequence.size()
			cells[i].c=int(t.sequence[t.phase])
			collected.shifts+=1
		result.append({"index":i,"id":cells[i].id,"kind":"chameleon","changed":changed,"from":old_color,"to":cells[i].c,"count":t.count,"period":t.period})
	return result

static func has_chameleon(cells: Array) -> bool:
	for cell in cells:
		if cell!=null and cell.has("trait") and cell.trait.kind=="chameleon":return true
	return false
