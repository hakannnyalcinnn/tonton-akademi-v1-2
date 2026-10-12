extends RefCounted

var color: int = -1
var count: int = 0

func advance(next_color: int) -> bool:
	count = count + 1 if color == next_color else 1
	color = next_color
	if count == 3:
		count = 0
		return true
	return false

func reset() -> void:
	color = -1
	count = 0

static func extras(cells: Array, origin: int, selected_color: int, excluded: Array, width: int) -> Array:
	var candidates: Array = []
	for i in cells.size():
		if i in excluded or cells[i] == null or cells[i].p != "" or cells[i].c != selected_color: continue
		var distance: int = absi(i % width - origin % width) + absi(int(i / width) - int(origin / width))
		if distance <= 2: candidates.append({"i": i, "d": distance})
	candidates.sort_custom(func(a, b): return a.d < b.d or (a.d == b.d and a.i < b.i))
	var result: Array = []
	for k in mini(4, candidates.size()): result.append(candidates[k].i)
	return result
