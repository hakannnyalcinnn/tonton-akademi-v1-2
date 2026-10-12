extends RefCounted

static func neighbors(index: int, width: int, height: int) -> Array:
	var result: Array = []
	var x := index % width
	var y := index / width
	if x > 0: result.append(index - 1)
	if x < width - 1: result.append(index + 1)
	if y > 0: result.append(index - width)
	if y < height - 1: result.append(index + width)
	return result

static func group(cells: Array, index: int, width: int, height: int) -> Array:
	if index < 0 or index >= cells.size() or cells[index] == null or cells[index].p != "":
		return []
	var color: int = cells[index].c
	var found: Array = [index]
	var cursor := 0
	while cursor < found.size():
		for n in neighbors(found[cursor], width, height):
			if n not in found and cells[n] != null and cells[n].p == "" and cells[n].c == color:
				found.append(n)
		cursor += 1
	found.sort()
	return found

static func has_move(cells: Array, width: int, height: int) -> bool:
	for i in cells.size():
		if cells[i] == null: continue
		if cells[i].p != "": return true
		for n in neighbors(i, width, height):
			if cells[n] != null and cells[n].p == "" and cells[i].c == cells[n].c:
				return true
	return false
