extends RefCounted
const Match = preload("res://scripts/core/match_detector.gd")
const Powers = preload("res://scripts/core/powerups.gd")

static func move_value(b, a: int, destination: int) -> float:
	var first = b.cells[a]
	b.cells[a] = b.cells[destination]
	b.cells[destination] = first
	var removed: Array = []
	var effective: Dictionary={}
	var power_bonus := 0.0
	if b.cells[a].p != "" and b.cells[destination].p != "":
		removed = Powers.combo_area(a,destination,b.cells,8,Powers.dominant_color(b.cells))
	elif b.cells[a].p != "" or b.cells[destination].p != "":
		var p: int = a if b.cells[a].p != "" else destination
		var n: int = destination if p == a else a
		removed = Powers.area(p,b.cells[p].p,b.cells,8,b.cells[n].c)
	else:
		var matches: Array = Match.find(b.cells,8,9)
		removed = Match.indices(matches)
		for component in matches:
			for i in component.cells: effective[i]=int(component.color)
			var kind: String = Powers.created(component)
			power_bonus += {"":0.0,"rocket_h":2.0,"rocket_v":2.0,"prism":4.0,"color":8.0}[kind]
	var value := power_bonus
	var unique: Dictionary = {}
	for i in removed:
		if unique.has(i) or not Match.normal(b.cells[i]): continue
		unique[i] = true
		var color := str(effective.get(i,b.cells[i].c))
		value += 1
		var kind: String=b.cells[i].get("trait",{}).get("kind","")
		if kind=="bridge" and b.collected.bridges<int(b.level.targets.get("bridges",0)):value+=40
		if kind=="dual" and b.collected.duals<int(b.level.targets.get("duals",0)):value+=40
		if kind=="chameleon" and b.collected.shifts<int(b.level.targets.get("shifts",0)):value-=150
		if b.level.targets.has(color) and b.collected[color] < b.level.targets[color]: value += 4
	if b.collected.get("mirrors",0)<int(b.level.targets.get("mirrors",0)):
		var reflected: Dictionary={}
		for source in removed:
			if b.cells[source]==null or not str(b.cells[source].p).begins_with("rocket"):continue
			for axis in ([Vector2i(-1,0),Vector2i(1,0)] if b.cells[source].p=="rocket_h" else [Vector2i(0,-1),Vector2i(0,1)]):
				for target in preload("res://scripts/mechanics/beam_resolver.gd").trace(source,axis,b.cells,8).path:
					if b.cells[target]!=null and b.cells[target].get("obstacle",{}).get("kind","")=="mirror":reflected[target]=true
		value+=reflected.size()*80
	if b.collected.get("portals",0)<int(b.level.targets.get("portals",0)):
		for portal in b.level.get("portals",[]):
			if removed.any(func(i):return i%8==int(portal.entry)%8 and i/8>=int(portal.entry)/8):
				value+=18 if b.cells[int(portal.entry)].p=="" else (50 if int(portal.entry) in removed else 0)
	# Prefer damage to unfinished mechanics; predict a wave without mutating it.
	if not b.level.get("mechanics",[]).is_empty():
		var hits: Dictionary = preload("res://scripts/mechanics/damage_resolver.gd").plan(b.cells,removed,removed,[],8,9)
		for index in hits:
			var cell: Dictionary = b.cells[index]
			var m: Dictionary = cell.get("armor",cell.get("obstacle",{}))
			if m.get("kind","") != "lock": value += 12*hits[index]
		for cell in b.cells:
			if cell != null and cell.get("obstacle",{}).get("kind","")=="lock":
				var color: int = cell.obstacle.color
				for index in removed:
					if Match.normal(b.cells[index]) and b.cells[index].c==color: value += 5
	b.cells[destination] = b.cells[a]
	b.cells[a] = first
	return value

static func best_move(b) -> Array:
	var options: Array = Match.legal_swaps(b.cells,8,9)
	var best := -1.0
	var choice: Array = options[0]
	for move in options:
		var value := move_value(b,move[0],move[1])
		if value > best:
			best = value
			choice = move
	return choice
