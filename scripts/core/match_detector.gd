extends RefCounted
const Traits=preload("res://scripts/mechanics/crystal_traits.gd")
const Flexible=preload("res://scripts/core/flexible_match_resolver.gd")
## Straight-line Match-3 scanner. Specials and fixed cells never form color runs.

static func normal(cell: Variant) -> bool:
	return cell != null and cell.p == "" and not cell.get("fixed", false) and not cell.get("delivery",false)

static func neighbors(index: int, width: int, height: int) -> Array:
	var result: Array = []
	var x := index % width
	var y := int(index / width)
	if x > 0: result.append(index - 1)
	if x < width - 1: result.append(index + 1)
	if y > 0: result.append(index - width)
	if y < height - 1: result.append(index + width)
	return result

static func find(cells: Array, width: int, height: int, preferred: Array = []) -> Array:
	if Traits.has_flexible(cells): return merge_runs(Flexible.find_runs(cells,width,height,preferred))
	var runs: Array = []
	for axis in ["h", "v"]:
		var line_count := height if axis == "h" else width
		var length := width if axis == "h" else height
		for line in line_count:
			var current: Array = []
			var color := -1
			for k in range(length + 1):
				var index := line * width + k if axis == "h" else k * width + line
				var next_color := int(cells[index].c) if k < length and normal(cells[index]) else -1
				if next_color != color or next_color < 0:
					if current.size() >= 3: runs.append({"cells": current.duplicate(), "axis": axis, "color": color})
					current.clear()
					color = next_color
				if next_color >= 0: current.append(index)
	return merge_runs(runs)

static func merge_runs(runs: Array) -> Array:
	# Merge only intersecting lines, never merely touching same-color clusters.
	var components: Array = []
	for run in runs:
		var component := {"cells": run.cells.duplicate(), "lines": [run], "color": run.color}
		var merge_again := true
		while merge_again:
			merge_again = false
			for k in range(components.size() - 1, -1, -1):
				var other: Dictionary = components[k]
				if other.color != component.color: continue
				var intersects := false
				for i in run.cells:
					if i in other.cells: intersects = true
				for i in component.cells:
					if i in other.cells: intersects = true
				if intersects:
					for i in other.cells:
						if i not in component.cells: component.cells.append(i)
					component.lines.append_array(other.lines)
					components.remove_at(k)
					merge_again = true
		component.cells.sort()
		components.append(component)
	components.sort_custom(func(a, b): return a.cells[0] < b.cells[0])
	return components

static func indices(matches: Array) -> Array:
	var result: Array = []
	for component in matches:
		for i in component.cells:
			if i not in result: result.append(i)
	result.sort()
	return result

static func line_at(cells: Array, index: int, width: int, height: int) -> bool:
	if not normal(cells[index]): return false
	var x:=index%width
	var y:=int(index/width)
	for color in Traits.domains(cells[index]):
		for axis in [0,1]:
			var count:=1
			var anchored:=not Traits.bridge(cells[index])
			for sign_value in [-1,1]:
				var nx: int=x+(sign_value if axis==0 else 0)
				var ny: int=y+(sign_value if axis==1 else 0)
				while nx>=0 and nx<width and ny>=0 and ny<height:
					var cell=cells[ny*width+nx]
					if not Traits.supports(cell,color): break
					anchored=anchored or not Traits.bridge(cell)
					count+=1
					nx+=sign_value if axis==0 else 0
					ny+=sign_value if axis==1 else 0
			if count>=3 and anchored: return true
	return false

static func can_swap(cells: Array, a: int, b: int, width: int, height: int) -> bool:
	if a < 0 or b < 0 or a >= cells.size() or b >= cells.size() or b not in neighbors(a, width, height): return false
	if cells[a] == null or cells[b] == null or cells[a].get("fixed", false) or cells[b].get("fixed", false): return false
	if cells[a].p != "" or cells[b].p != "": return true # Explicit special activation/combination exception.
	if cells[a].c == cells[b].c and not Traits.flexible(cells[a]) and not Traits.flexible(cells[b]): return false
	# Probe an independent slot array: queries never write even transiently to the board.
	var probe := cells.duplicate()
	probe[a] = cells[b]
	probe[b] = cells[a]
	# Necessary local line test rejects impossible swaps before the exact flexible solver.
	var local_match:=line_at(probe,a,width,height) or line_at(probe,b,width,height)
	if not local_match:return false
	if Traits.has_flexible(probe):
		var matched := indices(find(probe,width,height,[b,a]))
		return a in matched or b in matched
	return true

static func legal_swaps(cells: Array, width: int, height: int) -> Array:
	var result: Array = []
	for a in cells.size():
		for b in neighbors(a, width, height):
			if b > a and can_swap(cells, a, b, width, height): result.append([a, b])
	return result

static func has_move(cells: Array, width: int, height: int) -> bool:
	# An isolated movable power still has a legal tap activation (color choice included).
	for cell in cells:
		if cell != null and not cell.get("fixed",false) and not cell.get("delivery",false) and cell.p != "": return true
	for a in cells.size():
		for b in neighbors(a, width, height):
			if b > a and can_swap(cells, a, b, width, height): return true
	return false
