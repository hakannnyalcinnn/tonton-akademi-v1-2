extends RefCounted
const Match = preload("res://scripts/core/match_detector.gd")
const Powers = preload("res://scripts/core/powerups.gd")

static func move_value(b, a: int, destination: int) -> float:
	var first = b.cells[a]
	b.cells[a] = b.cells[destination]
	b.cells[destination] = first
	var removed: Array = []
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
			var kind: String = Powers.created(component)
			power_bonus += {"":0.0,"rocket_h":2.0,"rocket_v":2.0,"prism":4.0,"color":8.0}[kind]
	var value := power_bonus
	var unique: Dictionary = {}
	for i in removed:
		if unique.has(i) or not Match.normal(b.cells[i]): continue
		unique[i] = true
		var color := str(b.cells[i].c)
		value += 1
		if b.level.targets.has(color) and b.collected[color] < b.level.targets[color]: value += 4
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
