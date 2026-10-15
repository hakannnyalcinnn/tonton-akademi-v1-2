extends RefCounted
const Match=preload("res://scripts/core/match_detector.gd")
const Damage=preload("res://scripts/mechanics/damage_resolver.gd")
static func resolve(data: Dictionary, damage: int, _colors: Dictionary) -> Dictionary:
	return Damage.durability(data,damage,1,false)
static func spread(cells: Array, maximum: int, width: int, height: int, reserved: Array=[]) -> Array:
	var vines: Array=[]
	for i in cells.size():
		if cells[i]!=null and cells[i].get("armor",{}).get("kind","")=="vine":vines.append(i)
	if vines.is_empty() or vines.size()>=maximum:return []
	# Sources in row order; neighbor priority up,left,right,down via sorted indices.
	for source in vines:
		var neighbors:=Match.neighbors(source,width,height);neighbors.sort()
		for target in neighbors:
			var c=cells[target]
			if target in reserved or c==null or c.get("delivery",false) or c.p!="" or c.get("fixed",false) or c.has("trait") or c.has("armor") or c.has("obstacle") or c.has("motion"):continue
			c.armor={"kind":"vine","hp":1};c.fixed=true
			return [{"index":target,"source":source,"kind":"vine","opened":false}]
	return []
