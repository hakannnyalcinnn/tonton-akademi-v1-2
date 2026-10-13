extends RefCounted
const Beam=preload("res://scripts/mechanics/beam_resolver.gd")
const Traits=preload("res://scripts/mechanics/crystal_traits.gd")

static func created(component: Dictionary) -> String:
	for line in component.lines:
		if line.cells.size() >= 5: return "color"
	var horizontal := false
	var vertical := false
	for line in component.lines:
		horizontal = horizontal or line.axis == "h"
		vertical = vertical or line.axis == "v"
	if horizontal and vertical and component.cells.size() >= 5: return "prism"
	for line in component.lines:
		if line.cells.size() == 4: return "rocket_h" if line.axis == "h" else "rocket_v"
	return ""

static func origin(component: Dictionary, preferred: Array) -> int:
	for i in preferred:
		if i in component.cells: return i
	for i in component.cells:
		var count := 0
		for line in component.lines:
			if i in line.cells: count += 1
		if count > 1: return i
	return component.cells[0]

static func dominant_color(cells: Array) -> int:
	var counts: Array = [0, 0, 0, 0, 0]
	for cell in cells:
		if cell != null and cell.p == "" and not cell.get("fixed", false) and not Traits.flexible(cell): counts[cell.c] += 1
	var result := 0
	for c in 5:
		if counts[c] > counts[result]: result = c
	return result

static func area(index: int, kind: String, cells: Array, width: int, selected_color: int = -1) -> Array:
	if kind.begins_with("rocket") and Beam.has_mirror(cells):return Beam.area(index,kind,cells,width)
	var result: Array = [index]
	for i in cells.size():
		if cells[i] == null: continue
		var dx: int = absi(i % width - index % width)
		var dy: int = absi(int(i / width) - int(index / width))
		if (kind == "rocket_h" and dy == 0) or (kind == "rocket_v" and dx == 0): result.append(i)
		elif kind == "prism" and dx + dy <= 2: result.append(i)
		elif kind == "color" and cells[i].p == "" and not cells[i].has("obstacle") and (Traits.supports(cells[i],selected_color) or (cells[i].has("armor") and cells[i].c==selected_color)): result.append(i)
	return result

static func combo_area(a: int, b: int, cells: Array, width: int, selected_color: int) -> Array:
	var result: Array = [a, b]
	var first: String = cells[a].p
	var second: String = cells[b].p
	if first == "color" and second == "color":
		for i in cells.size():
			if cells[i] != null: result.append(i)
	elif "color" in [first, second]:
		var other: String = second if first == "color" else first
		for i in cells.size():
			if cells[i] != null and cells[i].p == "" and not cells[i].has("obstacle") and (Traits.supports(cells[i],selected_color) or (cells[i].has("armor") and cells[i].c==selected_color)):
				result.append(i)
				if other != "color": result.append_array(area(i, other, cells, width, selected_color))
	elif first.begins_with("rocket") and second.begins_with("rocket"):
		result.append_array(area(a, "rocket_h", cells, width))
		result.append_array(area(a, "rocket_v", cells, width))
		result.append_array(area(b, "rocket_h", cells, width))
		result.append_array(area(b, "rocket_v", cells, width))
	elif "prism" in [first, second]:
		for i in cells.size():
			var dx: int = absi(i % width - a % width)
			var dy: int = absi(int(i / width) - int(a / width))
			if (first == "prism" and second == "prism" and dx + dy <= 4) or ((first != second) and (dx <= 1 or dy <= 1)):
				result.append(i)
	return result
