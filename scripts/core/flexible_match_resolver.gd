extends RefCounted
const Traits=preload("res://scripts/mechanics/crystal_traits.gd")
## Exact branch-and-bound. Unassigned domains give an optimistic coverage bound.
## Assignments are ordered by cell index then fixed color priority 0..4.
## No greedy merging, cutoff, RNG, or mutation of the board.
static func scan(cells: Array, width: int, height: int, assignments: Dictionary) -> Array:
	var runs: Array=[]
	for color in 5:
		for axis in ["h","v"]:
			var line_count:=height if axis=="h" else width
			var length:=width if axis=="h" else height
			for line in line_count:
				var current: Array=[]
				var has_anchor:=false
				for k in range(length+1):
					var index:=line*width+k if axis=="h" else k*width+line
					var fits:=false
					if k<length:
						fits=int(assignments[index])==color if assignments.has(index) else Traits.supports(cells[index],color)
					if not fits:
						if current.size()>=3 and has_anchor: runs.append({"cells":current.duplicate(),"axis":axis,"color":color})
						current.clear();has_anchor=false
					else:
						current.append(index)
						has_anchor=has_anchor or not Traits.bridge(cells[index])
	return runs
static func rank(runs: Array, preferred: Array) -> Array:
	var unique: Dictionary={}
	var anchored:=0
	var longest:=0
	for run in runs:
		longest=maxi(longest,run.cells.size())
		for i in run.cells:
			unique[i]=true
			if i in preferred: anchored=1
	return [anchored,unique.size(),longest]
static func better(a: Array, b: Array) -> bool:
	for i in 3:
		if a[i]!=b[i]: return a[i]>b[i]
	return false
static func search(cells: Array, width: int, height: int, variables: Array, cursor: int, assigned: Dictionary, preferred: Array, best: Dictionary) -> void:
	var candidates:=scan(cells,width,height,assigned)
	var upper:=rank(candidates,preferred)
	if not better(upper,best.rank): return
	if cursor==variables.size():
		best.rank=upper
		best.runs=candidates
		return
	var index: int=variables[cursor]
	for color in Traits.domains(cells[index]):
		assigned[index]=color
		search(cells,width,height,variables,cursor+1,assigned,preferred,best)
	assigned.erase(index)
static func find_runs(cells: Array, width: int, height: int, preferred: Array) -> Array:
	var candidates:=scan(cells,width,height,{})
	var relevant: Dictionary={}
	for run in candidates:
		for i in run.cells:
			if Traits.flexible(cells[i]): relevant[i]=true
	var variables: Array=relevant.keys()
	variables.sort()
	if variables.is_empty(): return candidates
	var best: Dictionary={"rank":[-1,-1,-1],"runs":[]}
	search(cells,width,height,variables,0,{},preferred,best)
	return best.runs
static func prefix(cells: Array, index: int, width: int) -> bool:
	for step in [1,width]:
		if (step==1 and index%width<2) or (step==width and index<width*2): continue
		var a=cells[index];var b=cells[index-step];var c=cells[index-step*2]
		if not Traits.normal(a) or not Traits.normal(b) or not Traits.normal(c): continue
		if Traits.bridge(a) and Traits.bridge(b) and Traits.bridge(c): continue
		for color in Traits.domains(a):
			if Traits.supports(b,color) and Traits.supports(c,color): return true
	return false
