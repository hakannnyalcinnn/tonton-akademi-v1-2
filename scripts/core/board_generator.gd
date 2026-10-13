extends RefCounted
const Traits=preload("res://scripts/mechanics/crystal_traits.gd")
const Flexible=preload("res://scripts/core/flexible_match_resolver.gd")
const Match = preload("res://scripts/core/match_detector.gd")

static func forbidden_prefix(cells: Array, i: int, color: int, width: int) -> bool:
	if i % width >= 2 and Match.normal(cells[i - 1]) and Match.normal(cells[i - 2]) and cells[i - 1].c == color and cells[i - 2].c == color: return true
	if i >= 2 * width and Match.normal(cells[i - width]) and Match.normal(cells[i - 2 * width]) and cells[i - width].c == color and cells[i - 2 * width].c == color: return true
	return false

static func repair_start(cells: Array, rng, width: int, height: int) -> void:
	if has_traits(cells):
		# Repair ordinary neighbors, never detach a trait from its defined colors/phase.
		for attempt in 32:
			var matches:=Match.find(cells,width,height)
			if matches.is_empty():break
			var changed:=false
			var indices:=Match.indices(matches)
			indices.reverse()
			for index in indices:
				if cells[index].has("trait"):continue
				var old_color: int=cells[index].c
				var best_color:=old_color
				var best_count:=indices.size()
				var colors: Array=[0,1,2,3,4]
				rng.shuffle(colors)
				for color in colors:
					cells[index].c=color
					var count:=Match.indices(Match.find(cells,width,height)).size()
					if count<best_count:best_count=count;best_color=color
				cells[index].c=best_color
				if best_color!=old_color:changed=true;break
			if not changed:break
		if not Match.find(cells,width,height).is_empty():
			var repaired:=shuffle(cells,rng,width,height)
			assert(repaired,"Trait starting arrangement cannot be stabilized")
	elif not Match.find(cells, width, height).is_empty():
		for i in cells.size():
			if not Match.normal(cells[i]): continue
			var colors: Array = [0, 1, 2, 3, 4]
			rng.shuffle(colors)
			for color in colors:
				if not forbidden_prefix(cells, i, color, width):
					cells[i].c = color
					break
	if not Match.has_move(cells, width, height):
		var repaired := shuffle(cells,rng,width,height)
		assert(repaired, "No playable arrangement for this level multiset")
	assert(Match.find(cells, width, height).is_empty())
	assert(Match.has_move(cells, width, height))

static func shuffle(cells: Array, rng, width: int, height: int) -> bool:
	var positions: Array = []
	var pools: Array = [[], [], [], [], []]
	var before := cells.duplicate()
	for i in cells.size():
		if Match.normal(cells[i]):
			positions.append(i)
			pools[cells[i].c].append(cells[i])
	for pool in pools: rng.shuffle(pool)
	var order: Array = [0, 1, 2, 3, 4]
	rng.shuffle(order)
	# Weighted seeded construction avoids enumerating thousands of match-free
	# arrangements with no possible swap. Preserve every crystal, power and fixed cell.
	if not Traits.has_flexible(cells) and construct_shuffle(cells,positions,pools,order,rng,width,height):return true
	for i in cells.size():cells[i]=before[i]
	var budget := {"remaining": 200000,"flexible":Traits.has_flexible(cells)}
	var success := place(cells, positions, pools, order, 0, width, height, budget)
	if not success:
		for i in cells.size(): cells[i] = before[i]
	return success

static func construct_shuffle(cells: Array, positions: Array, pools: Array, order: Array, rng, width: int, height: int) -> bool:
	for attempt in 24:
		var remaining: Array=[]
		for pool in pools:remaining.append(pool.duplicate())
		var complete:=true
		for index in positions:
			var choices: Array=[];var total:=0
			for color in order:
				if not remaining[color].is_empty() and not forbidden_prefix(cells,index,color,width):
					choices.append(color);total+=remaining[color].size()
			if total==0:complete=false;break
			var selected: int=rng.next_int(total)
			for color in choices:
				selected-=remaining[color].size()
				if selected<0:
					cells[index]=remaining[color].pop_back();break
		if complete and Match.find(cells,width,height).is_empty() and Match.has_move(cells,width,height):return true
	return false

static func place(cells: Array, positions: Array, pools: Array, order: Array, cursor: int, width: int, height: int, budget: Dictionary) -> bool:
	budget.remaining -= 1
	if budget.remaining <= 0: return false
	if cursor == positions.size():
		return Match.find(cells, width, height).is_empty() and Match.has_move(cells, width, height)
	var i: int = positions[cursor]
	var choices := order.duplicate()
	choices.sort_custom(func(a, b): return pools[a].size() > pools[b].size())
	for color in choices:
		if pools[color].is_empty(): continue
		if not budget.flexible and forbidden_prefix(cells,i,color,width): continue
		var cell = pools[color].pop_back()
		cells[i] = cell
		if (not budget.flexible or not Flexible.prefix(cells,i,width)) and place(cells, positions, pools, order, cursor + 1, width, height, budget): return true
		pools[color].append(cell)
	return false

static func emergency_stabilize(cells: Array, rng, width: int, height: int) -> bool:
	# Only diagnosed cascade corruption uses new colors. Ordinary no-move shuffles
	# still preserve their color multiset, specials, cell identities and blockers.
	for attempt in 32:
		for i in cells.size():
			if not Match.normal(cells[i]) or cells[i].has("trait"): continue
			var start: int = rng.next_int(5)
			for offset in 5:
				var color := (start+offset)%5
				if not forbidden_prefix(cells,i,color,width):
					cells[i].c=color
					break
		if Match.find(cells,width,height).is_empty() and Match.has_move(cells,width,height): return true
	return false

static func has_traits(cells: Array) -> bool:
	for cell in cells:
		if cell!=null and cell.has("trait"):return true
	return false
