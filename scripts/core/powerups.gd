extends RefCounted

static func created(group: Array, width: int) -> String:
	if group.size() >= 10: return "color"
	if group.size() >= 7: return "prism"
	if group.size() >= 5:
		var min_x := width
		var max_x := 0
		var min_y := 999
		var max_y := 0
		for i in group:
			min_x = mini(min_x, i % width)
			max_x = maxi(max_x, i % width)
			min_y = mini(min_y, int(i / width))
			max_y = maxi(max_y, int(i / width))
		return "rocket_h" if max_x - min_x >= max_y - min_y else "rocket_v"
	return ""

static func area(index: int, kind: String, cells: Array, width: int, selected_color: int = -1) -> Array:
	var result: Array = [index]
	for i in cells.size():
		if cells[i] == null: continue
		var dx: int = absi(i % width - index % width)
		var dy: int = absi(int(i / width) - int(index / width))
		if (kind == "rocket_h" and dy == 0) or (kind == "rocket_v" and dx == 0): result.append(i)
		elif kind == "prism" and dx + dy <= 2: result.append(i)
		elif kind == "color" and cells[i].p == "" and cells[i].c == selected_color: result.append(i)
	return result

static func combo_area(a: int, b: int, cells: Array, width: int, selected_color: int) -> Array:
	var result: Array = [a, b]
	var first: String = cells[a].p
	var second: String = cells[b].p
	if "color" in [first, second]:
		var other: String = second if first == "color" else first
		for i in cells.size():
			if cells[i] != null and cells[i].p == "" and cells[i].c == selected_color:
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
