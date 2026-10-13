extends RefCounted
const Registry = preload("res://scripts/mechanics/mechanic_registry.gd")
const Objectives = preload("res://scripts/mechanics/objective_manager.gd")

static var cache: Array = []

static func all() -> Array:
	if not cache.is_empty(): return cache
	var parsed = JSON.parse_string(FileAccess.get_file_as_string("res://data/levels.json"))
	assert(parsed is Dictionary and parsed.version == 2)
	var extended = JSON.parse_string(FileAccess.get_file_as_string("res://data/levels-11-30.json"))
	assert(extended is Dictionary and extended.version == 2)
	cache = parsed.levels + extended.levels
	return cache

static func count() -> int:
	return all().size()

static func world_for(number: int) -> int:
	return int((number-1)/50)+1

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
		if key not in Objectives.KEYS or level.targets[key] < 1: return false
	var occupied: Dictionary = {}
	for spec in level.get("mechanics",[]):
		if not Registry.valid_spec(spec) or occupied.has(spec.index): return false
		occupied[spec.index] = true
	return not level.targets.is_empty()
