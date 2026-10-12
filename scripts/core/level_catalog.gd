extends RefCounted

static func all() -> Array:
	var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://data/levels.json"))
	assert(parsed is Dictionary and parsed.version == 2)
	return parsed.levels

static func get_level(number: int) -> Dictionary:
	var levels := all()
	assert(number >= 1 and number <= levels.size())
	return levels[number - 1].duplicate(true)

static func validate(level: Dictionary) -> bool:
	if not level.has_all(["id", "seed", "moves", "targets", "stars", "layout", "gravity", "resonance"]): return false
	if level.moves < 1 or level.layout.size() != 72 or level.stars.size() != 3: return false
	if level.stars[0] > level.stars[1] or level.stars[1] > level.stars[2]: return false
	for color in level.layout:
		if not (color is float or color is int) or color < 0 or color > 4 or float(color) != floor(float(color)): return false
	for key in level.targets:
		if key not in ["total", "0", "1", "2", "3", "4"] or level.targets[key] < 1: return false
	return not level.targets.is_empty()
