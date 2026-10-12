extends RefCounted
const Match = preload("res://scripts/core/match_detector.gd")

static func forbidden_prefix(cells: Array, i: int, color: int, width: int) -> bool:
	if i % width >= 2 and Match.normal(cells[i - 1]) and Match.normal(cells[i - 2]) and cells[i - 1].c == color and cells[i - 2].c == color: return true
	if i >= 2 * width and Match.normal(cells[i - width]) and Match.normal(cells[i - 2 * width]) and cells[i - width].c == color and cells[i - 2 * width].c == color: return true
	return false

static func repair_start(cells: Array, rng, width: int, height: int) -> void:
	if not Match.find(cells, width, height).is_empty():
		for i in cells.size():
			if not Match.normal(cells[i]): continue
			var colors: Array = [0, 1, 2, 3, 4]
			rng.shuffle(colors)
			for color in colors:
				if not forbidden_prefix(cells, i, color, width):
					cells[i].c = color
					break
	if not Match.has_move(cells, width, height):
		assert(shuffle(cells, rng, width, height), "No playable arrangement for this level multiset")
	assert(Match.find(cells, width, height).is_empty())
	assert(Match.has_move(cells, width, height))

static func shuffle(cells: Array, rng, width: int, height: int) -> bool:
	var positions: Array = []
	var pools: Array = [[], [], [], [], []]
	var before := cells.duplicate()
	for i in cells.size():
		if Match.normal(cells[i]):
			positions.append(i)
			pools[cells[i].c].append(cells[i])
	for pool in pools: rng.shuffle(pool)
	var order: Array = [0, 1, 2, 3, 4]
	rng.shuffle(order)
	var budget := {"remaining": 200000}
	var success := place(cells, positions, pools, order, 0, width, height, budget)
	if not success:
		for i in cells.size(): cells[i] = before[i]
	return success

static func place(cells: Array, positions: Array, pools: Array, order: Array, cursor: int, width: int, height: int, budget: Dictionary) -> bool:
	budget.remaining -= 1
	if budget.remaining <= 0: return false
	if cursor == positions.size():
		return Match.find(cells, width, height).is_empty() and Match.has_move(cells, width, height)
	var i: int = positions[cursor]
	var choices := order.duplicate()
	choices.sort_custom(func(a, b): return pools[a].size() > pools[b].size())
	for color in choices:
		if pools[color].is_empty() or forbidden_prefix(cells, i, color, width): continue
		var cell = pools[color].pop_back()
		cells[i] = cell
		if place(cells, positions, pools, order, cursor + 1, width, height, budget): return true
		pools[color].append(cell)
	return false
