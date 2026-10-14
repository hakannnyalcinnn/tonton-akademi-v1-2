extends RefCounted
const Canyon=preload("res://scripts/mechanics/canyon_mechanics.gd")
const Storm=preload("res://scripts/core/prizma_storm.gd")
const Wave=preload("res://scripts/core/crystal_wave.gd")
const Metrics = preload("res://scripts/ui/performance_metrics.gd")

const Seal=preload("res://scripts/mechanics/sequence_seal.gd")
const Conveyor=preload("res://scripts/mechanics/conveyor_rails.gd")
const Bubble=preload("res://scripts/mechanics/floating_bubble.gd")
const Fountain=preload("res://scripts/mechanics/painting_fountain.gd")
const Beam=preload("res://scripts/mechanics/beam_resolver.gd")
const Portal=preload("res://scripts/mechanics/portal_manager.gd")
const Vines=preload("res://scripts/mechanics/vine_manager.gd")
const Chain=preload("res://scripts/mechanics/chain_reaction_resolver.gd")
const Traits=preload("res://scripts/mechanics/crystal_traits.gd")
const Mechanics = preload("res://scripts/mechanics/mechanic_manager.gd")
const Registry = preload("res://scripts/mechanics/mechanic_registry.gd")
const Objectives = preload("res://scripts/mechanics/objective_manager.gd")
const Match = preload("res://scripts/core/match_detector.gd")
const Generator = preload("res://scripts/core/board_generator.gd")
const Gravity = preload("res://scripts/core/gravity.gd")
const Resonance = preload("res://scripts/core/resonance.gd")
const Powers = preload("res://scripts/core/powerups.gd")
const Score = preload("res://scripts/core/score.gd")
const SeedRng = preload("res://scripts/core/seed_rng.gd")
const WIDTH := 8
const HEIGHT := 9
const RULES := 2
const MAX_CASCADES := 128

enum State { READY, SWAPPING, CHECKING_MATCHES, REVERTING_SWAP, RESOLVING_MATCHES, PLAYING_EFFECTS, APPLYING_GRAVITY, REFILLING, CHECKING_CASCADES, CHECKING_OBJECTIVES, SHUFFLING, LEVEL_COMPLETED, LEVEL_FAILED, PAUSED }
var canyon: Dictionary={}
var recovery_failed:=false
var state: State = State.READY
var state_trace: Array = []
var presentation_locked := false
var paused_state: State = State.READY
var cells: Array = []
var level: Dictionary
var rng = SeedRng.new()
var resonance = Resonance.new()
var moves: int
var initial_moves:=0
var action_match_stages:=0
var action_magnet_used:=false
var action_wave_used:=false
var action_storm_used:=false
var action_color:=0
var last_match_origin:=0
var action_combo:=""
var action_virtual: Array=[]
var score := 0
var adventure: Dictionary={}
var collected: Dictionary = {"total": 0, "0": 0, "1": 0, "2": 0, "3": 0, "4": 0}
var direction := "down"
var palette: Array=[0,1,2,3,4]
var energy := 0
var energy_blocks := 0
var serial := 0
var outcome := "playing"
var objective_stage:=0
var refill_stream: Array = []
var frames: Array = []
var portal_used: Dictionary={}
var fountain_used: Dictionary={}
var movement_queue: Array=[]
var vine_count:=0
var pending_portal_arrivals: Dictionary={}

func _init(definition: Dictionary = {}) -> void:
	if definition.is_empty(): return
	level = definition.duplicate(true)
	if level.has("active_colors"):level.active_colors=level.active_colors.map(func(color):return int(color))
	palette=level.get("active_colors",palette)
	direction=str(level.get("initial_gravity","down"))
	moves = int(level.moves)
	initial_moves=moves
	rng = SeedRng.new(int(level.seed))
	refill_stream = level.get("opening_refill", []).map(func(color): return int(color))
	for color in level.layout: cells.append(make_cell(int(color)))
	for key in level.get("powers", {}): cells[int(key)].p = level.powers[key]
	Mechanics.install(cells, level.get("mechanics", []))
	for key in ["flowers","ice","stones","locks","duals","shifts","pins","vines","crates","mirrors","bridges","fountains","bubbles","conveyors","seals","portals"]: collected[key] = 0
	canyon=Canyon.install(cells,level)
	for key in ["floors","giants","magnets","cores","shield0","shield1","shield2","shield3"]:collected[key]=0
	adventure=preload("res://scripts/core/adventure.gd").initial(level)
	collected.rescues=0;collected.bosses=0
	Generator.repair_start(cells, rng, WIDTH, HEIGHT,palette)

func find_matches(preferred: Array = []) -> Array:
	var started := Time.get_ticks_usec()
	var result: Array = Match.find(cells, WIDTH, HEIGHT, preferred)
	Metrics.elapsed("match_scan", started)
	return result

func make_cell(color: int = -1, power: String = "") -> Dictionary:
	serial += 1
	return {"c": int(palette[rng.next_int(palette.size())]) if color < 0 else color, "p": power, "id": serial}

func transition(next_state: State) -> void:
	state = next_state
	state_trace.append(next_state)

func frame(kind: String, before: Array, extra: Dictionary = {}) -> void:
	var item := {"kind": kind, "before": before, "after": cells.duplicate(true), "state": state, "direction": direction,"storm_energy":storm_charge(),"canyon":canyon.duplicate(true)}
	item.merge(extra)
	frames.append(item)

func available() -> bool:
	return outcome == "playing" and moves > 0 and state == State.READY and not presentation_locked

func swap(a: int, b: int) -> Dictionary:
	if not available() or a < 0 or b < 0 or a >= cells.size() or b >= cells.size() or b not in Match.neighbors(a, WIDTH, HEIGHT): return {"accepted": false, "attempted": false}
	if cells[a] == null or cells[b] == null or cells[a].get("fixed", false) or cells[b].get("fixed", false): return {"accepted": false, "attempted": false}
	state_trace.clear()
	frames.clear()
	var before := cells.duplicate(true)
	transition(State.SWAPPING)
	var first = cells[a]
	cells[a] = cells[b]
	cells[b] = first
	frame("swap", before, {"a": a, "b": b})
	transition(State.CHECKING_MATCHES)
	var matches: Array = find_matches([b,a])
	var matched: Array = Match.indices(matches)
	var special: bool = cells[a].p != "" or cells[b].p != ""
	if not special and (a not in matched and b not in matched):
		transition(State.REVERTING_SWAP)
		var swapped := cells.duplicate(true)
		cells[b] = cells[a]
		cells[a] = first
		frame("revert", swapped, {"a": a, "b": b})
		transition(State.READY)
		return {"accepted": false, "attempted": true, "invalid": true, "frames": frames.duplicate(), "points": 0}
	begin_action(b)
	pending_portal_arrivals={int(cells[a].id):true,int(cells[b].id):true}
	moves -= 1
	var combined: bool = cells[a].p != "" and cells[b].p != ""
	var extra: Array = []
	var selected_color := Powers.dominant_color(cells)
	var primary_color := -1
	if special:
		resonance.reset()
		if combined:
			var plan:=Powers.combo_plan(a,b,cells,WIDTH,selected_color)
			extra=plan.area;action_combo=plan.kind;action_virtual=plan.virtual
		else:
			var power_index: int = a if cells[a].p != "" else b
			var normal_index: int = b if power_index == a else a
			selected_color = Powers.dominant_color(cells) if Traits.bridge(cells[normal_index]) else int(cells[normal_index].c)
			extra = Powers.area(power_index, cells[power_index].p, cells, WIDTH, selected_color)
	else:
		for preferred in [b, a]:
			for component in matches:
				if preferred in component.cells and primary_color < 0: primary_color = component.color
		if primary_color < 0: primary_color = matches[0].color
	action_color=primary_color if primary_color>=0 else selected_color
	var original_score:=score
	var event:=resolve(matches, extra, [b, a], primary_color, selected_color, special, combined, false)
	var before_shift: Array=[]
	var changes: Array=[]
	if Traits.has_chameleon(cells):
		before_shift=cells.duplicate(true)
		var change_started:=Time.get_ticks_usec()
		changes=Traits.advance(cells,collected)
		Metrics.elapsed("chameleon_logic",change_started)
	if not changes.is_empty():
		transition(State.PLAYING_EFFECTS)
		frame("trait",before_shift,{"traits":changes,"collected":collected.duplicate()})
		var additional:=resolve(find_matches(),[],[],-1,selected_color,false,false,false,int(event.cascade_count))
		for key in ["cascade_count","normal_count","created_count"]: event[key]+=additional[key]
		event.cascade_guard=event.cascade_guard or additional.cascade_guard
	apply_seals(event,primary_color if primary_color>=0 else selected_color,selected_color)
	apply_conveyors(event,selected_color)
	event.primary_color=primary_color if primary_color>=0 else selected_color
	if level.get("vine_enabled",false):
		vine_count=(vine_count+1)%3
		if vine_count==0:
			var before_vine:=cells.duplicate(true)
			var vine_started:=Time.get_ticks_usec()
			var growing:=Vines.spread(cells,int(level.get("vine_max",6)),WIDTH,HEIGHT)
			Metrics.elapsed("vine_logic",vine_started)
			if not growing.is_empty():
				frame("vine",before_vine,{"growth":growing})
				if not Match.has_move(cells,WIDTH,HEIGHT):
					var grown:=cells.duplicate(true);var prior_rng: int=rng.state
					if Generator.shuffle(cells,rng,WIDTH,HEIGHT):frame("shuffle",grown)
					else:
						cells=before_vine;rng.state=prior_rng
						Metrics.incident("Vine spread would remove all legal moves; growth reverted",{"level":level.id,"growth":growing})
						frame("vine",grown,{"growth":[]})
	complete_action(event,selected_color)
	event.shuffled=ensure_move() or frames.any(func(f):return f.kind=="shuffle")
	finish_if_needed()
	event.frames=frames.duplicate()
	event.points=score-original_score
	return event

func activate(index: int, selected_color: int = -1) -> Dictionary:
	if not available() or index < 0 or index >= cells.size() or cells[index] == null or cells[index].p == "" or cells[index].get("fixed", false): return {"accepted": false, "attempted": false}
	if cells[index].p == "color" and (selected_color < 0 or selected_color > 4): return {"accepted": false, "attempted": false, "choose_color": true}
	state_trace.clear()
	frames.clear()
	begin_action(index)
	moves -= 1
	resonance.reset()
	if selected_color < 0: selected_color = Powers.dominant_color(cells)
	action_color=selected_color
	var original_score:=score
	var event:=resolve(find_matches(), Powers.area(index,cells[index].p,cells,WIDTH,selected_color),[],-1,selected_color,true,false,false)
	apply_seals(event,selected_color,selected_color)
	apply_conveyors(event,selected_color)
	complete_action(event,selected_color)
	event.shuffled=ensure_move() or frames.any(func(f):return f.kind=="shuffle");finish_if_needed();event.frames=frames.duplicate();event.points=score-original_score;event.primary_color=selected_color
	return event

func storm_charge() -> int:return energy*Storm.COST+energy_blocks
func begin_action(origin: int=0) -> void:
	last_match_origin=origin
	portal_used.clear();fountain_used.clear();movement_queue.clear()
	action_match_stages=0;action_magnet_used=false;action_wave_used=false;action_storm_used=false;action_combo="";action_virtual=[]
func credit_storm(normal_count: int) -> void:
	if not level.gravity:return
	var amount:=energy_blocks+normal_count
	energy+=amount/Storm.COST;energy_blocks=amount%Storm.COST
func complete_action(event: Dictionary,selected_color: int) -> void:
	var magnetic_before:=cells.duplicate(true)
	var magnetic_events: Array=[]
	if not action_magnet_used:
		action_magnet_used=true
		magnetic_events=Canyon.magnetic(cells,canyon,collected)
	if not magnetic_events.is_empty():
		for motion in magnetic_events:
			pending_portal_arrivals[int(cells[motion.a].id)]=true
			pending_portal_arrivals[int(cells[motion.b].id)]=true
		frame("magnet",magnetic_before,{"magnetic":magnetic_events,"collected":collected.duplicate()})
		if cells.any(func(c):return c==null):settle(true)
		merge_event(event,resolve(find_matches(),[],[],-1,selected_color,false,false,false,int(event.cascade_count)))
	apply_crystal_wave(event,selected_color)
	if level.gravity and level.get("automatic_storm",true) and energy>0 and not action_storm_used and not event.cascade_guard:
		action_storm_used=true
		var charge_before:=storm_charge();energy-=1
		var old_direction:=direction;direction=Storm.choose(direction,rng)
		var before:=cells.duplicate(true)
		transition(State.APPLYING_GRAVITY)
		var started:=Time.get_ticks_usec()
		var transports:=Storm.reflow(cells,WIDTH,HEIGHT,direction)
		for t in transports:pending_portal_arrivals[int(t.id)]=true
		Metrics.elapsed("storm_logic",started)
		frame("storm",before,{"from_direction":old_direction,"transports":transports,"energy_before":charge_before})
		settle(true)
		merge_event(event,resolve(find_matches(),[],[],-1,selected_color,false,false,false,int(event.cascade_count)))
		apply_crystal_wave(event,selected_color)
	event.storm=action_storm_used;event.crystal_wave=action_wave_used;event.match_stages=action_match_stages;event.combo_kind=action_combo
func apply_crystal_wave(event: Dictionary,selected_color: int) -> void:
	if action_wave_used or action_match_stages<Wave.THRESHOLD or event.cascade_guard or not level.get("crystal_wave",true):return
	action_wave_used=true
	var before:=cells.duplicate(true)
	var color: int=int(level.get("wave_color",action_color))
	var started:=Time.get_ticks_usec()
	var painted:=Wave.apply(cells,last_match_origin,color,WIDTH)
	Metrics.elapsed("crystal_wave_logic",started)
	frame("crystal_wave",before,{"painted":painted,"origin":last_match_origin,"color":color})
	merge_event(event,resolve(find_matches(),[],[],-1,selected_color,false,false,false,int(event.cascade_count)))

func merge_event(event: Dictionary,more: Dictionary) -> void:
	for key in ["cascade_count","normal_count","created_count"]:event[key]+=more[key]
	event.cascade_guard=event.cascade_guard or more.cascade_guard
func apply_seals(event: Dictionary,color: int,selected_color: int) -> void:
	if not cells.any(func(c):return c!=null and c.get("obstacle",{}).get("kind","")=="seal"):return
	var before_seal:=cells.duplicate(true)
	var seal_started:=Time.get_ticks_usec()
	var seals:=Seal.advance(cells,color,collected)
	Metrics.elapsed("seal_logic",seal_started)
	if seals.is_empty():return
	frame("seal",before_seal,{"seals":seals,"collected":collected.duplicate()})
	if seals.any(func(e):return e.opened):
		settle(true)
		merge_event(event,resolve(find_matches(),[],[],-1,selected_color,false,false,false,int(event.cascade_count)))
func apply_conveyors(event: Dictionary,selected_color: int) -> void:
	if not level.get("conveyors",[]).is_empty():
		var before_rail:=cells.duplicate(true)
		var rail_started:=Time.get_ticks_usec()
		var transports:=Conveyor.advance(cells,level.conveyors)
		Metrics.elapsed("conveyor_logic",rail_started)
		if not transports.is_empty():
			collected.conveyors+=transports.size()
			for transport in transports:pending_portal_arrivals[int(transport.id)]=true
			frame("conveyor",before_rail,{"transports":transports,"collected":collected.duplicate()})
			settle(true)
			var more:=resolve(find_matches(),[],[],-1,selected_color,false,false,false,int(event.cascade_count))
			for key in ["cascade_count","normal_count","created_count"]:event[key]+=more[key]
			event.cascade_guard=event.cascade_guard or more.cascade_guard

func resolve(matches: Array, extra: Array, preferred: Array, primary_color: int, selected_color: int, special: bool, combined: bool, finalize: bool = true, depth_offset: int = 0) -> Dictionary:
	var original_score := score
	var depth := depth_offset
	var total_removed := 0
	var power_count := 0
	var did_resonate := false
	var guarded := false
	while not matches.is_empty() or not extra.is_empty():
		depth += 1
		if depth > MAX_CASCADES:
			guarded = true
			Metrics.incident("Cascade limit exceeded; stable shuffle recovery", {"level":level.id,"seed_state":rng.state,"direction":direction,"depth":depth,"remaining_refill_stream":refill_stream.size(),"refill_sample":refill_stream.slice(0,8),"cells":cells.duplicate(true)})
			refill_stream.clear()
			transition(State.SHUFFLING)
			var old := cells.duplicate(true)
			var recovered := Generator.shuffle(cells,rng,WIDTH,HEIGHT)
			if not recovered:
				Metrics.incident("Cascade multiset cannot be stabilized; regenerate normal colors, preserve IDs and blockers", {"level":level.id,"depth":depth})
				recovered = Generator.emergency_stabilize(cells,rng,WIDTH,HEIGHT,palette)
			if not recovered:
				Metrics.incident("Cascade recovery failed", {"level":level.id,"depth":depth})
				outcome = "lost"
			assert(recovered, "Cascade guard could not find a stable arrangement")
			frame("shuffle", old)
			break
		var clear_started := Time.get_ticks_usec()
		transition(State.RESOLVING_MATCHES)
		var before := cells.duplicate(true)
		var matched: Array = Match.indices(matches)
		if not matches.is_empty():action_match_stages+=1
		last_match_origin=Wave.center(matches,preferred[0] if not preferred.is_empty() else last_match_origin,WIDTH)
		var removed := matched.duplicate()
		for i in extra:
			if i not in removed: removed.append(i)
		var creations: Array = []
		for component in matches:
			var kind: String = Powers.created(component)
			if kind != "":
				creations.append({"i": Powers.origin(component, preferred if depth == 1 else []), "kind": kind, "color": component.color})
		var resonated := false
		if depth == 1 and primary_color >= 0 and level.resonance:
			resonated = resonance.advance(primary_color)
			if resonated:
				var origin := -1
				for i in preferred:
					if i in matched and Traits.supports(cells[i],primary_color):
						origin = i
						break
				if origin < 0: origin = matched[0]
				removed.append_array(Resonance.extras(cells, origin, primary_color, removed, WIDTH))
				did_resonate = true
		# Existing powers caught by a wave activate once; newly planned powers do not yet exist.
		var triggered: Array = []
		var has_crates:=Chain.present(cells)
		var cursor := 0
		while not has_crates and cursor < removed.size():
			var i: int = removed[cursor]
			if i >= 0 and i < cells.size() and cells[i] != null and not cells[i].get("fixed", false) and cells[i].p != "" and i not in triggered:
				triggered.append(i)
				for target in Powers.area(i, cells[i].p, cells, WIDTH, selected_color):
					if target not in removed: removed.append(target)
			cursor += 1
		var unique: Array = []
		for i in removed:
			if i >= 0 and i < cells.size() and cells[i] != null and not cells[i].get("fixed", false) and i not in unique: unique.append(i)
		unique.sort()
		var effective_colors: Dictionary={}
		for component in matches:
			for i in component.cells: effective_colors[i]=int(component.color)
		for i in unique:
			if not effective_colors.has(i): effective_colors[i]=selected_color if Traits.flexible(cells[i]) and Traits.supports(cells[i],selected_color) else int(cells[i].c)
		var normal_colors: Dictionary = {}
		for i in unique:
			if Match.normal(cells[i]): normal_colors[str(effective_colors[i])] = int(normal_colors.get(str(effective_colors[i]),0))+1
		# Shared transaction before clearing: neighbors and direct power footprints.
		var mechanic_events: Array=[]
		var effect_events: Array=[]
		if has_crates:
			var chain:=Chain.resolve(cells,removed,selected_color,effective_colors,collected,WIDTH,HEIGHT,action_virtual if combined else [])
			triggered=chain.triggered;mechanic_events=chain.mechanics;effect_events=chain.events
			for i in chain.removed:
				if cells[i]!=null and not cells[i].get("fixed",false) and i not in unique:
					unique.append(i)
					effective_colors[i]=selected_color if Traits.flexible(cells[i]) and Traits.supports(cells[i],selected_color) else int(cells[i].c)
		else:mechanic_events=Mechanics.wave(cells,unique,removed,triggered,normal_colors,collected,WIDTH,HEIGHT,action_virtual if combined else [])
		var beams: Array=[]
		if Beam.has_mirror(before):
			for source in triggered:
				if before[source]==null or not str(before[source].p).begins_with("rocket"):continue
				for axis in ([Vector2i(-1,0),Vector2i(1,0)] if before[source].p=="rocket_h" else [Vector2i(0,-1),Vector2i(0,1)]):
					var ray:=Beam.trace(source,axis,before,WIDTH);ray.source=source;beams.append(ray)
			if combined:
				for power in action_virtual:
					if not str(power.kind).begins_with("rocket"):continue
					for axis in ([Vector2i(-1,0),Vector2i(1,0)] if power.kind=="rocket_h" else [Vector2i(0,-1),Vector2i(0,1)]):
						var ray:=Beam.trace(int(power.index),axis,before,WIDTH);ray.source=int(power.index);ray.virtual=true;beams.append(ray)
		var reflected: Dictionary={}
		for ray in beams:
			for index in ray.path:
				if before[index]!=null and before[index].get("obstacle",{}).get("kind","")=="mirror":reflected[index]=true
		collected.mirrors+=reflected.size()
		var bubbles_before:=cells.duplicate(true) if unique.any(func(i):return Bubble.present(cells[i])) else []
		var preserved:=Bubble.break_layers(cells,unique,collected)
		if not preserved.is_empty():frame("bubble",bubbles_before,{"broken":preserved,"collected":collected.duplicate()})
		for i in preserved:unique.erase(i)
		for creation in creations:
			if creation.i in preserved:
				for i in unique:
					if i in matched:creation.i=i;break
		creations=creations.filter(func(c):return c.i not in preserved)
		var canyon_colors: Dictionary={}
		var normal_indices: Array=[]
		for i in unique:
			if Match.normal(cells[i]):
				normal_indices.append(i)
				canyon_colors[str(effective_colors[i])]=int(canyon_colors.get(str(effective_colors[i]),0))+1
		var canyon_direct:=removed.duplicate()
		for effect in effect_events:
			for index in effect.area:
				if index not in canyon_direct:canyon_direct.append(index)
		var special_area:=extra.duplicate() if special or combined else []
		if not canyon.cores.is_empty():
			for source in triggered:
				for index in Powers.area(source,before[source].p,before,WIDTH,selected_color):
					if index not in special_area:special_area.append(index)
		var canyon_events:=Canyon.wave(cells,canyon,unique,canyon_direct,canyon_colors,special or not triggered.is_empty() or combined,collected,special_area)
		var normal_count := 0
		for i in unique:
			if i in normal_indices:
				normal_count += 1
				collected[str(effective_colors[i])] += 1
				if cells[i].get("trait",{}).get("kind","")=="dual": collected.duals+=1
				if Traits.bridge(cells[i]):collected.bridges+=1
			if i not in canyon.holes:cells[i] = null
		var adventure_events:=preload("res://scripts/core/adventure.gd").wave(adventure,unique,normal_colors,not triggered.is_empty() or (combined and depth==depth_offset+1),collected)
		collected.total += normal_count
		for creation in creations:
			if creation.i not in canyon.holes:continue
			for component in matches:
				if creation.i not in component.cells:continue
				for index in component.cells:
					if index not in canyon.holes and index in unique and not creations.any(func(other):return other!=creation and other.i==index):
						creation.i=index;break
				break
		creations=creations.filter(func(c):return c.i not in canyon.holes)
		for creation in creations: cells[creation.i] = make_cell(creation.color, creation.kind)
		power_count += creations.size()
		total_removed += normal_count
		credit_storm(normal_count)
		var points: int = Score.move_points(normal_count, matched.size(), resonated, special or not triggered.is_empty(), combined, depth)
		score += points
		transition(State.PLAYING_EFFECTS)
		frame("clear", before, {"removed": unique, "points": points, "score": score, "collected":collected.duplicate(), "special": not triggered.is_empty(), "combo": depth, "multiplier": mini(depth, 5), "resonated": resonated, "creations": creations, "triggered": triggered, "mechanics": mechanic_events, "effects":effect_events,"adventure_events":adventure_events,"adventure":adventure.duplicate(true),"canyon_events":canyon_events,"canyon":canyon.duplicate(true), "beams":beams, "colors":effective_colors, "origin":last_match_origin,"combo_kind":action_combo if combined else "","virtual_powers":action_virtual if combined else []})
		Metrics.elapsed("clear_logic", clear_started)
		var pre_paint:=cells.duplicate(true) if cells.any(func(c):return c!=null and c.get("obstacle",{}).get("kind","")=="fountain") else []
		var paint_started:=Time.get_ticks_usec()
		var painted:=Fountain.activate(cells,matched,fountain_used,WIDTH,HEIGHT) if not pre_paint.is_empty() else []
		Metrics.elapsed("fountain_logic",paint_started)
		if not painted.is_empty():
			collected.fountains+=painted.size()
			frame("paint",pre_paint,{"fountains":painted,"collected":collected.duplicate()})
		settle(true)
		transition(State.CHECKING_CASCADES)
		matches = find_matches()
		extra = []
		special = false
		combined = false
	var shuffled := ensure_move() if finalize else false
	if finalize: finish_if_needed()
	return {"accepted": true, "attempted": true, "invalid": false, "frames": frames.duplicate(), "points": score - original_score, "resonated": did_resonate, "created_count": power_count, "cascade_count": depth-depth_offset, "normal_count": total_removed, "shuffled": shuffled, "cascade_guard": guarded}

func settle(record: bool = false) -> void:
	var before := cells.duplicate(true) if record else []
	transition(State.APPLYING_GRAVITY)
	var gravity_started := Time.get_ticks_usec()
	var portals: Array=level.get("portals",[])
	if portals.is_empty():Bubble.compact(cells,WIDTH,HEIGHT,direction)
	else:
		# Compact, transfer only arriving normal IDs, compact exits on the next pass.
		# The per-action ID set bounds the process even with portal paths crossing.
		for pass_index in 73:
			var positions: Dictionary={}
			for i in cells.size():
				if cells[i]!=null:positions[int(cells[i].id)]=i
			Bubble.compact(cells,WIDTH,HEIGHT,direction)
			var arrived: Dictionary={}
			for pair in portals:
				var cell=cells[int(pair.entry)]
				if cell!=null and (positions.get(int(cell.id),int(pair.entry))!=int(pair.entry) or pending_portal_arrivals.has(int(cell.id))):arrived[int(cell.id)]=true
			if record:frame("fall",before)
			var old_portal:=cells.duplicate(true)
			var portal_started:=Time.get_ticks_usec()
			var events:=Portal.transfer(cells,portals,arrived,portal_used,movement_queue)
			Metrics.elapsed("portal_logic",portal_started)
			if events.is_empty():break
			collected.portals+=events.size()
			if record:frame("portal",old_portal,{"transfers":events,"collected":collected.duplicate()})
			before=cells.duplicate(true)
			assert(pass_index<72,"Portal transfer exceeded unique crystal count")
	pending_portal_arrivals.clear()
	Metrics.elapsed("gravity_logic", gravity_started)
	if record and portals.is_empty():frame("fall",before)
	before = cells.duplicate(true) if record else []
	transition(State.REFILLING)
	var refill_started := Time.get_ticks_usec()
	for line in Gravity.lines(WIDTH, HEIGHT, direction):
		for index in line:
			if cells[index] == null:
				cells[index] = make_cell(int(refill_stream.pop_front())) if not refill_stream.is_empty() else make_cell()
	Metrics.elapsed("refill_logic", refill_started)
	if record: frame("refill", before)

func change_gravity(_next_direction: String) -> Dictionary:
	# Kept only as a safe compatibility rejection: players cannot select direction.
	return {"accepted":false,"attempted":false}

func ensure_move() -> bool:
	if moves<=0 or targets_complete():return false
	var checking_started:=Time.get_ticks_usec()
	var playable:=Match.has_move(cells,WIDTH,HEIGHT)
	Metrics.elapsed("legal_move_logic",checking_started)
	if playable:return false
	transition(State.SHUFFLING)
	var before := cells.duplicate(true)
	var shuffle_started:=Time.get_ticks_usec()
	var recovered := Generator.shuffle(cells,rng,WIDTH,HEIGHT)
	Metrics.elapsed("shuffle_logic",shuffle_started)
	if not recovered:
		Metrics.incident("No legal shuffle arrangement", {"level":level.id})
		# Preserve the original transaction and resources; do not fabricate a defeat.
		recovery_failed=true
		transition(State.PAUSED)
		return false
	recovery_failed=false
	frame("shuffle", before)
	return true

func active_targets() -> Dictionary:
	var stages: Array=level.get("objective_stages",[])
	return level.targets if stages.is_empty() else stages[mini(objective_stage,stages.size()-1)]
func targets_complete() -> bool:
	return Objectives.complete(level.targets,collected)

func finish_if_needed() -> void:
	if recovery_failed:transition(State.PAUSED);return
	transition(State.CHECKING_OBJECTIVES)
	var stages: Array=level.get("objective_stages",[])
	while objective_stage<stages.size()-1 and Objectives.complete(stages[objective_stage],collected):objective_stage+=1
	if outcome == "playing":
		if targets_complete():
			outcome = "won"
			score += Score.completion_bonus(moves)
		elif moves <= 0: outcome = "lost"
	transition(stable_state())

func stable_state() -> State:
	return State.PAUSED if recovery_failed else State.LEVEL_COMPLETED if outcome == "won" else (State.LEVEL_FAILED if outcome == "lost" else State.READY)

func hold_presentation() -> void:
	presentation_locked = true
	state = State.PLAYING_EFFECTS

func visual_phase(next_state: int) -> void:
	if presentation_locked and state != State.PAUSED: state = next_state as State

func release_presentation() -> void:
	presentation_locked = false
	state = stable_state()

func pause() -> void:
	if state != State.PAUSED:
		paused_state = state
		state = State.PAUSED

func resume() -> void:
	if recovery_failed:return
	if state == State.PAUSED: state = paused_state

func snapshot() -> Dictionary:
	return {"adventure":adventure.duplicate(true),"recovery_failed":recovery_failed,"canyon":canyon.duplicate(true),"level_definition":canonical_definition(level),"gameplay_version":3,"move_budget":initial_moves,"objective_stage":objective_stage,"vine_count":vine_count,"rules": RULES, "state": stable_state(), "level_id": int(level.id), "cells": cells.duplicate(true), "moves": moves, "score": score, "collected": collected.duplicate(), "direction": direction, "energy": energy, "energy_blocks": energy_blocks, "serial": serial, "rng": rng.state, "resonance_color": resonance.color, "resonance_count": resonance.count, "outcome": outcome, "refill_stream": refill_stream.duplicate()}

static func whole(value: Variant, minimum: int, maximum: int) -> bool:
	if not (value is int or value is float): return false
	return value >= minimum and value <= maximum and float(value) == floor(float(value))

func restore(data: Dictionary) -> bool:
	if not preload("res://scripts/core/adventure.gd").valid(data.get("adventure",{})):return false
	if data.has("recovery_failed") and not data.recovery_failed is bool:return false
	if not data.has_all(["rules", "state", "level_id", "cells", "moves", "score", "collected", "direction", "energy", "energy_blocks", "serial", "rng", "resonance_color", "resonance_count", "outcome", "refill_stream"]): return false
	if not whole(data.get("vine_count",0),0,2):return false
	if not whole(data.get("objective_stage",0),0,maxi(0,level.get("objective_stages",[]).size()-1)):return false
	if not whole(data.rules, RULES, RULES) or not data.cells is Array or data.cells.size() != 72: return false
	if not whole(data.level_id, int(level.id), int(level.id)) or data.direction not in ["up", "down", "left", "right"]: return false
	if data.has("move_budget") and not whole(data.move_budget,1,maxi(int(level.moves),int(level.get("legacy_moves",level.moves)))):return false
	if not whole(data.moves, 0, int(data.get("move_budget",maxi(int(level.moves),int(level.get("legacy_moves",level.moves)))))) or not whole(data.score, 0, 2147483647) or not whole(data.energy, 0, 178956970) or not whole(data.energy_blocks, 0, 11): return false
	if not whole(data.get("move_budget",maxi(int(level.moves),int(level.get("legacy_moves",level.moves)))),1,maxi(int(level.moves),int(level.get("legacy_moves",level.moves)))):return false
	if not whole(data.serial, 72, 2147483647) or not whole(data.rng, 0, 2147483647): return false
	if data.outcome not in ["playing", "won", "lost"] or not whole(data.resonance_count, 0, 2) or not whole(data.resonance_color, -1, 4): return false
	if not data.collected is Dictionary or not data.collected.has_all(["total", "0", "1", "2", "3", "4"]): return false
	if not data.refill_stream is Array: return false
	for color in data.refill_stream:
		if not whole(color, 0, 4): return false
	var seen: Dictionary = {}
	var normalized: Array = []
	for cell in data.cells:
		if not cell is Dictionary or not cell.has_all(["c", "p", "id"]): return false
		if not whole(cell.c, 0, 4) or cell.p not in ["", "rocket_h", "rocket_v", "prism", "color"] or not whole(cell.id, 1, int(data.serial)) or seen.has(int(cell.id)): return false
		if cell.has("fixed") and not cell.fixed is bool: return false
		seen[int(cell.id)] = true
		var normalized_cell := {"c": int(cell.c), "p": str(cell.p), "id": int(cell.id)}
		if cell.get("fixed", false): normalized_cell["fixed"] = true
		for layer in ["armor","obstacle","trait","motion"]:
			if cell.has(layer):
				if not cell[layer] is Dictionary: return false
				normalized_cell[layer] = cell[layer].duplicate(true)
		if cell.has("canyon"):
			if not cell.canyon is Dictionary or cell.canyon.get("kind","") not in ["void","giant","magnet","core"] or not whole(cell.canyon.get("anchor",-1),0,71) or not cell.get("fixed",false):return false
			normalized_cell.canyon=cell.canyon.duplicate(true)
		if not Registry.valid_cell(normalized_cell): return false
		normalized.append(normalized_cell)
	if not Canyon.valid_state(canonical_definition(data.get("canyon",canyon)),level,normalized):return false
	var flexible_count:=0
	for cell in normalized:
		if Traits.flexible(cell): flexible_count+=1
	if flexible_count>Traits.MAX_FLEXIBLE: return false
	var total := 0
	for key in data.collected:
		if key not in Objectives.KEYS or not whole(data.collected[key], 0, 2147483647): return false
		if key in ["0","1","2","3","4"]: total += int(data.collected[key])
	if total != int(data.collected.total): return false
	for stage in range(int(data.get("objective_stage",0))):
		if not Objectives.complete(level.objective_stages[stage],data.collected):return false
	if not Match.find(normalized, WIDTH, HEIGHT).is_empty(): return false
	var restored_state := State.PAUSED if data.get("recovery_failed",false) else State.LEVEL_COMPLETED if data.outcome == "won" else (State.LEVEL_FAILED if data.outcome == "lost" else State.READY)
	if not whole(data.state, restored_state, restored_state): return false
	if data.outcome == "playing" and data.moves == 0: return false
	objective_stage=int(data.get("objective_stage",0))
	vine_count=int(data.get("vine_count",0))
	canyon=canonical_definition(data.get("canyon",canyon))
	cells = normalized
	initial_moves=int(data.get("move_budget",maxi(int(level.moves),int(level.get("legacy_moves",level.moves)))))
	moves = int(data.moves)
	score = int(data.score)
	adventure=data.get("adventure",preload("res://scripts/core/adventure.gd").initial(level)).duplicate(true)
	collected = data.collected.duplicate()
	for key in collected: collected[key] = int(collected[key])
	for key in ["flowers","ice","stones","locks","duals","shifts","pins","vines","crates","mirrors","bridges","fountains","bubbles","conveyors","seals","portals"]:
		if not collected.has(key): collected[key] = 0
	for key in ["floors","giants","magnets","cores","shield0","shield1","shield2","shield3"]:
		if not collected.has(key):collected[key]=0
	direction = str(data.direction)
	energy = int(data.energy)
	energy_blocks = int(data.energy_blocks)
	serial = int(data.serial)
	rng.state = int(data.rng)
	resonance.color = int(data.resonance_color)
	resonance.count = int(data.resonance_count)
	refill_stream = data.refill_stream.map(func(color): return int(color))
	outcome = str(data.outcome)
	recovery_failed=bool(data.get("recovery_failed",false))
	state = restored_state
	presentation_locked = false
	if outcome=="playing" and not Match.has_move(cells,WIDTH,HEIGHT):
		ensure_move();finish_if_needed()
	return true

static func canonical_definition(value: Variant) -> Variant:
	if value is Dictionary:
		var result: Dictionary={}
		for key in value:result[key]=canonical_definition(value[key])
		return result
	if value is Array:
		var result: Array=[]
		for item in value:result.append(canonical_definition(item))
		return result
	if value is float and whole(value,-2147483648,2147483647):return int(value)
	return value
