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
	var package2=JSON.parse_string(FileAccess.get_file_as_string("res://data/levels-31-50.json"))
	assert(package2 is Dictionary and package2.version==2)
	var ocean=JSON.parse_string(FileAccess.get_file_as_string("res://data/levels-51-75.json"))
	assert(ocean is Dictionary and ocean.version==2)
	var finale=JSON.parse_string(FileAccess.get_file_as_string("res://data/levels-76-100.json"))
	assert(finale is Dictionary and finale.version==2)
	var canyon=JSON.parse_string(FileAccess.get_file_as_string("res://data/levels-101-150.json"))
	assert(canyon is Dictionary and canyon.version==2)
	cache = parsed.levels + extended.levels + package2.levels + ocean.levels + finale.levels + canyon.levels
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
	# Snapshots now contain definitions: reject malformed saved types before indexing/casting.
	if not level.layout is Array or not level.stars is Array or not level.targets is Dictionary:return false
	if not level.gravity is bool or not level.resonance is bool:return false
	if not Registry.integer(level.id,1,150) or not Registry.integer(level.moves,1,10000) or not Registry.integer(level.seed,-2147483648,2147483647):return false
	if not level.get("mechanics",[]) is Array or not level.get("portals",[]) is Array or not level.get("conveyors",[]) is Array or not level.get("powers",{}) is Dictionary:return false
	if level.layout.size() != 72 or level.stars.size() != 3: return false
	for threshold in level.stars:
		if not Registry.integer(threshold,0,2147483647):return false
	for flag in ["automatic_storm","crystal_wave","development_only"]:
		if level.has(flag) and not level[flag] is bool:return false
	if level.has("wave_color") and not Registry.integer(level.wave_color,0,4):return false
	if level.has("legacy_moves") and not Registry.integer(level.legacy_moves,1,10000):return false
	for index in level.get("powers",{}):
		if not str(index).is_valid_int() or not Registry.integer(int(str(index)),0,71) or level.powers[index] not in ["rocket_h","rocket_v","prism","color"]:return false
	if level.stars[0] > level.stars[1] or level.stars[1] > level.stars[2]: return false
	for color in level.layout:
		if not (color is float or color is int) or color < 0 or color > 4 or float(color) != floor(float(color)): return false
	for key in level.targets:
		if key not in Objectives.KEYS or not Registry.integer(level.targets[key],1,2147483647): return false
	if not preload("res://scripts/mechanics/portal_manager.gd").validate(level.get("portals",[])):return false
	if not level.get("development_only",false) and level.id<76 and not level.get("portals",[]).is_empty():return false
	if not preload("res://scripts/mechanics/conveyor_rails.gd").validate(level.get("conveyors",[])):return false
	if not level.get("conveyors",[]).is_empty() and level.id<101 and not level.get("development_only",false):return false
	var stages=level.get("objective_stages",[])
	if not stages is Array or stages.size()>6:return false
	var previous_stage: Dictionary={}
	for stage in stages:
		if not stage is Dictionary or stage.is_empty():return false
		for key in stage:
			if key not in level.targets or not Registry.integer(stage[key],1,int(level.targets[key])):return false
		for key in previous_stage:
			if int(stage.get(key,0))<int(previous_stage[key]):return false
		previous_stage=stage
	if not stages.is_empty() and stages[-1]!=level.targets:return false
	var occupied: Dictionary = {}
	var flexible_count:=0
	for spec in level.get("mechanics",[]):
		if not Registry.valid_spec(spec) or occupied.has(spec.index): return false
		if spec.kind in ["fountain","bubble","seal"] and not level.get("development_only",false):return false
		if spec.kind in ["vine","crate","mirror"] and level.id<76 and not level.get("development_only",false):return false
		occupied[spec.index] = true
		if spec.kind in ["bridge","pin"] and level.id<=50 and not level.get("development_only",false): return false
		if spec.kind=="dual" or spec.kind=="bridge": flexible_count+=1
	if not preload("res://scripts/mechanics/canyon_mechanics.gd").validate(level):return false
	return not level.targets.is_empty() and flexible_count<=Registry.Traits.MAX_FLEXIBLE
