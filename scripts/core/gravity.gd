extends RefCounted
## Lines run from destination edge to source edge, preserving survivor order.
static func lines(width: int, height: int, direction: String) -> Array:
	var result: Array = []
	if direction in ["down", "up"]:
		for x in width:
			var line: Array = []
			for k in height:
				var y := height - 1 - k if direction == "down" else k
				line.append(y * width + x)
			result.append(line)
	else:
		for y in height:
			var line: Array = []
			for k in width:
				var x := width - 1 - k if direction == "right" else k
				line.append(y * width + x)
			result.append(line)
	return result

static func compact(cells: Array, width: int, height: int, direction: String) -> void:
	assert(direction in ["down", "up", "left", "right"])
	for line in lines(width, height, direction):
		var segment: Array = []
		for index in line:
			if cells[index] != null and cells[index].get("fixed", false):
				compact_segment(cells, segment)
				segment.clear()
			else:
				segment.append(index)
		compact_segment(cells, segment)

static func compact_segment(cells: Array, segment: Array) -> void:
	var surviving: Array = []
	for index in segment:
		if cells[index] != null: surviving.append(cells[index])
	for k in segment.size():
		cells[segment[k]] = surviving[k] if k < surviving.size() else null
