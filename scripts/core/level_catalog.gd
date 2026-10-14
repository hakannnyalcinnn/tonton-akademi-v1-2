extends RefCounted
const Registry = preload("res://scripts/mechanics/mechanic_registry.gd")
const Objectives = preload("res://scripts/mechanics/objective_manager.gd")

static var cache: Array = []
static var adventures: Dictionary={}

const Worlds=preload("res://scripts/core/world_catalog.gd")
static var loaded: Dictionary={}
static var access_order: Array=[]
static func packet(path: String) -> Array:
	if not loaded.has(path):
		var parsed=JSON.parse_string(FileAccess.get_file_as_string(path))
		assert(parsed is Dictionary and Registry.integer(parsed.get("version",0),2,3))
		loaded[path]=parsed.levels
	if path in access_order:access_order.erase(path)
	access_order.append(path)
	if access_order.size()>3:loaded.erase(access_order.pop_front())
	return loaded[path]
static func all() -> Array:
	if not cache.is_empty():return cache
	for entry in Worlds.manifest().packages:cache.append_array(packet(entry.path).map(func(d):return decorate(d)))
	cache.sort_custom(func(a,b):return int(a.id)<int(b.id))
	assert(cache.size()==count())
	for index in cache.size():assert(int(cache[index].id)==index+1)
	return cache
static func count() -> int:return Worlds.count()
static func world_for(number: int) -> int:return Worlds.for_level(number)
static func get_level(number: int) -> Dictionary:
	assert(number>=1 and number<=count())
	if not cache.is_empty():return cache[number-1].duplicate(true)
	for entry in Worlds.manifest().packages:
		if number>=int(entry.start) and number<=int(entry.end):
			for definition in packet(entry.path):
				if int(definition.id)==number:return decorate(definition)
	assert(false,"Campaign packet missing requested authored level")
	return {}

static func decorate(source: Dictionary) -> Dictionary:
	var definition: Dictionary=source.duplicate(true)
	if adventures.is_empty():adventures=JSON.parse_string(FileAccess.get_file_as_string("res://data/adventure-levels.json")).levels
	var addition: Dictionary=adventures.get(str(int(definition.id)),{})
	if addition.has("treasure"):definition.treasure=addition.treasure.duplicate(true)
	if not addition.has("kind"):return definition
	definition.adventure=addition.duplicate(true);definition.adventure.erase("treasure")
	if addition.kind=="rescue":
		definition.targets.rescues=addition.cages.size()
		definition.tutorial="Kafesin çevresinde eşleştir; dostunu kurtar."
	else:
		definition.targets.bosses=1
		definition.tutorial="Bekçinin gösterdiği renkleri eşleştir; son kalkanı özel güçle kır."
		if definition.get("powers",{}).is_empty():
			definition.powers=definition.get("powers",{})
			for i in 72:
				if int(definition.layout[i])>=0 and not definition.mechanics.any(func(m):return int(m.index)==i):definition.powers[str(i)]="rocket_h";break
	if definition.has("objective_stages"):definition.objective_stages[-1].merge(definition.targets,true)
	return definition

static func validate(level: Dictionary) -> bool:
	if not preload("res://scripts/core/adventure.gd").valid(level.get("adventure",{})):return false
	if not level.has_all(["id", "seed", "moves", "targets", "stars", "layout", "gravity", "resonance"]): return false
	# Snapshots now contain definitions: reject malformed saved types before indexing/casting.
	if not level.layout is Array or not level.stars is Array or not level.targets is Dictionary:return false
	if not level.gravity is bool or not level.resonance is bool:return false
	if not Registry.integer(level.id,1,2147483647) or not Registry.integer(level.moves,1,10000) or not Registry.integer(level.seed,-2147483648,2147483647):return false
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
	if not level.get("active_colors",[0,1,2,3,4]) is Array:return false
	var palette: Array=level.get("active_colors",[0,1,2,3,4])
	if palette.size()<3 or palette.size()>5:return false
	var seen_colors: Dictionary={}
	for color in palette:
		if not Registry.integer(color,0,4) or seen_colors.has(int(color)):return false
		seen_colors[int(color)]=true
	if level.get("initial_gravity","down") not in ["up","down","left","right"]:return false
	for color in level.layout:
		if not (color is float or color is int) or color < 0 or color > 4 or float(color) != floor(float(color)) or not seen_colors.has(int(color)): return false
	for key in level.targets:
		if key not in Objectives.KEYS or not Registry.integer(level.targets[key],1,2147483647): return false
		if str(key).is_valid_int() and not seen_colors.has(int(str(key))):return false
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
		for color in spec.get("colors",spec.get("sequence",[])):
			if not seen_colors.has(int(color)):return false
		if spec.has("color") and not seen_colors.has(int(spec.color)):return false
		if spec.kind in ["fountain","bubble","seal"] and level.id<151 and not level.get("development_only",false):return false
		if spec.kind in ["vine","crate","mirror"] and level.id<76 and not level.get("development_only",false):return false
		occupied[spec.index] = true
		if spec.kind in ["bridge","pin"] and level.id<=50 and not level.get("development_only",false): return false
		if spec.kind=="dual" or spec.kind=="bridge": flexible_count+=1
	if not preload("res://scripts/mechanics/canyon_mechanics.gd").validate(level):return false
	return not level.targets.is_empty() and flexible_count<=Registry.Traits.MAX_FLEXIBLE
