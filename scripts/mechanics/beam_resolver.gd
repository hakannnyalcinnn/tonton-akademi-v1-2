extends RefCounted
const Metrics=preload("res://scripts/ui/performance_metrics.gd")
const Mirror=preload("res://scripts/mechanics/mirror_manager.gd")
static func has_mirror(cells: Array) -> bool:
	for cell in cells:
		if cell!=null and cell.get("obstacle",{}).get("kind","")=="mirror":return true
	return false
static func trace(index: int, direction: Vector2i, cells: Array, width: int) -> Dictionary:
	var started:=Time.get_ticks_usec()
	var point:=Vector2i(index%width,int(index/width))+direction
	var seen: Dictionary={};var path: Array=[];var hits: Array=[];var looped:=false
	while point.x>=0 and point.x<width and point.y>=0 and point.y<int(cells.size()/width):
		var i:=point.y*width+point.x
		var key:=str(i)+":"+str(direction.x)+":"+str(direction.y)
		if seen.has(key):looped=true;break
		seen[key]=true;path.append(i)
		var m: Dictionary=cells[i].get("obstacle",{}) if cells[i]!=null else {}
		if m.get("kind","")=="mirror":direction=Mirror.reflect(direction.x,direction.y,m.orientation)
		elif i not in hits:hits.append(i)
		point+=direction
	Metrics.elapsed("beam_logic",started)
	return {"path":path,"hits":hits,"looped":looped}
static func area(index: int, kind: String, cells: Array, width: int) -> Array:
	var result: Array=[index]
	for d in ([Vector2i(-1,0),Vector2i(1,0)] if kind=="rocket_h" else [Vector2i(0,-1),Vector2i(0,1)]):
		for target in trace(index,d,cells,width).hits:
			if target not in result:result.append(target)
	return result
