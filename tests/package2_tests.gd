extends SceneTree
const Board=preload("res://scripts/core/board.gd")
const Catalog=preload("res://scripts/core/level_catalog.gd")
const Match=preload("res://scripts/core/match_detector.gd")
const Flex=preload("res://scripts/core/flexible_match_resolver.gd")
const Traits=preload("res://scripts/mechanics/crystal_traits.gd")
const Manager=preload("res://scripts/mechanics/mechanic_manager.gd")
const Powers=preload("res://scripts/core/powerups.gd")
const Save=preload("res://scripts/core/save_manager.gd")
const Solver=preload("res://tests/move_solver.gd")
var checks:=0
var failures:=0
func check(value: bool, message: String) -> void:
	checks+=1
	if not value: failures+=1;printerr("FAIL: "+message)
func _initialize() -> void:call_deferred("run")
func fixture():
	var d:=Catalog.get_level(1)
	d.moves=100;d.targets={"total":10000}
	var b=Board.new(d)
	for i in 72:b.cells[i].c=(i%8+int(i/8))%5
	return b
func add_trait(b, i: int, kind: String, extra: Dictionary = {}) -> void:
	var spec: Dictionary={"kind":kind,"index":i}
	spec.merge(extra)
	Manager.install(b.cells,[spec])
func isolated(width: int, height: int) -> Array:
	var cells: Array=[]
	for i in width*height:cells.append({"c":(i%width+int(i/width))%5,"p":"","id":i+1,"fixed":true})
	return cells
func normal(c: int, id: int) -> Dictionary:return {"c":c,"p":"","id":id}
func test_dual_and_bridge() -> void:
	var c:=isolated(5,5)
	c[10]=normal(0,11);c[11]=normal(0,12);c[12]=normal(0,13)
	Manager.install(c,[{"kind":"dual","index":12,"colors":[0,1]}])
	check(Match.find(c,5,5)[0].color==0,"dual matches red")
	c[10].c=1;c[11].c=1
	check(Match.find(c,5,5)[0].color==1,"dual matches blue without mutating its base color")
	c[10].c=2;c[11].c=2
	check(Match.find(c,5,5).is_empty(),"dual rejects third color")
	c[10].c=0;c[11].c=0;c[13]=normal(1,14);c[14]=normal(1,15)
	c[2]=normal(1,3);c[7]=normal(1,8)
	var result:=Match.find(c,5,5)
	check(Match.indices(result).size()==5 and result[0].color==1,"maximum unique coverage wins over competing red run")
	result=Match.find(c,5,5,[10])
	check(result[0].color==0 and Match.indices(result).size()==3,"swap anchor is considered before unrelated larger alternative")
	c[2].fixed=true;c[7].fixed=true
	result=Match.find(c,5,5)
	check(result[0].color==0,"equal length/coverage uses fixed color order")
	# Equal five-cell coverage: red T (longest 3) versus blue straight 5.
	var q:=isolated(5,5)
	for i in [10,11,12,13,14]:q[i]=normal(1,i+1)
	for i in [7,17]:q[i]=normal(0,i+1)
	for i in [11,12,13]:Manager.install(q,[{"kind":"dual","index":i,"colors":[0,1]}])
	check(Match.indices(Match.find(q,5,5)).size()==5 and Match.find(q,5,5)[0].color==1,"equal coverage chooses longer straight line")
	var w:=isolated(3,3)
	w[3]=normal(0,4);w[4]=normal(0,5);w[5]=normal(0,6)
	Manager.install(w,[{"kind":"bridge","index":4}])
	check(Match.find(w,3,3)[0].color==0,"red bridge red valid")
	w[5].c=1
	check(Match.find(w,3,3).is_empty(),"red bridge blue rejected")
	Manager.install(w,[{"kind":"bridge","index":3},{"kind":"bridge","index":5}])
	check(Match.find(w,3,3).is_empty(),"all-bridge line rejected")
	w[3]=normal(1,4)
	Manager.install(w,[{"kind":"dual","index":3,"colors":[0,1]}])
	check(Match.find(w,3,3)[0].color==0,"dual anchors two bridges deterministically")
	var b=fixture()
	b.cells[0].c=0;b.cells[1].c=2;b.cells[2].c=0
	add_trait(b,9,"dual",{"colors":[0,1]})
	var before: int=b.moves
	var event: Dictionary=b.swap(1,9)
	check(event.accepted and b.moves==before-1 and b.collected.duals==1,"dual swap clears and counts once")
	check(b.find_matches().is_empty(),"dual cascade settles")
	var first: Dictionary={}
	for frame in event.frames:
		if frame.kind=="clear":first=frame;break
	check(first.removed.count(1)==1 and first.colors[1]==0,"dual clear has one assigned color and unique cell")
	var rocket=isolated(4,1)
	for i in 4:rocket[i]=normal(0,i+1)
	Manager.install(rocket,[{"kind":"bridge","index":1}])
	check(Powers.created(Match.find(rocket,4,1)[0])=="rocket_h","bridge four creates normal rocket")
	var bomb=fixture()
	add_trait(bomb,20,"bridge")
	bomb.cells[19].p="color"
	check(20 in Powers.area(19,"color",bomb.cells,8,3),"color bomb can consume bridge with selected color")
func oracle(cells: Array, width: int, height: int, variables: Array, cursor: int, assigned: Dictionary, preferred: Array, best: Dictionary) -> void:
	if cursor==variables.size():
		var runs:=Flex.scan(cells,width,height,assigned)
		var rank:=Flex.rank(runs,preferred)
		if Flex.better(rank,best.rank):best.rank=rank;best.runs=runs
		return
	var i: int=variables[cursor]
	for color in Traits.domains(cells[i]):assigned[i]=color;oracle(cells,width,height,variables,cursor+1,assigned,preferred,best)
	assigned.erase(i)
func test_exact_solver() -> void:
	var rng=preload("res://scripts/core/seed_rng.gd").new(78129)
	for scenario in 300:
		var cells: Array=[]
		for i in 20:cells.append(normal(rng.next_int(5),i+1))
		var variables: Array=[3,7,12,16]
		for i in variables:
			if scenario%3==0 and i==7:Manager.install(cells,[{"kind":"bridge","index":i}])
			else:
				var a: int=rng.next_int(5)
				Manager.install(cells,[{"kind":"dual","index":i,"colors":[a,(a+1+rng.next_int(4))%5]}])
		var old:=cells.duplicate(true)
		var preferred: Array=[3,4] if scenario%2==0 else []
		var expected: Dictionary={"rank":[-1,-1,-1],"runs":[]}
		oracle(cells,5,4,variables,0,{},preferred,expected)
		var actual:=Flex.find_runs(cells,5,4,preferred)
		check(actual==expected.runs,"exact bounded solver equals independent exhaustive oracle")
		check(cells==old,"match scan never mutates wildcard identities or colors")
		var assigned: Dictionary={}
		for run in actual:
			for i in run.cells:
				check(not assigned.has(i) or assigned[i]==run.color,"one color per wildcard per wave")
				assigned[i]=run.color
func test_chameleon_and_pin() -> void:
	var b=fixture()
	add_trait(b,43,"chameleon",{"sequence":[2,1,0],"period":2})
	var id: int=b.cells[43].id
	var invalid: Dictionary=b.swap(0,1)
	check(not invalid.accepted and b.cells[43].trait.count==0,"invalid swap does not advance chameleon")
	b.level.gravity=true;b.energy=1
	b.change_gravity("left")
	check(b.cells[43].trait.count==0,"gravity action does not advance chameleon")
	var changes:=Traits.advance(b.cells,b.collected)
	check(changes.size()==1 and not changes[0].changed and b.cells[43].c==2,"first successful swap warns")
	changes=Traits.advance(b.cells,b.collected)
	check(changes[0].changed and b.cells[43].c==1 and b.collected.shifts==1,"second successful swap changes color once")
	# Production hook after a deliberately multi-wave move, with the chameleon away from the clearing columns.
	var d:=Catalog.get_level(7)
	d.targets={"total":10000};d.moves=100
	d.mechanics=[{"kind":"chameleon","index":71,"sequence":[4,1,0],"period":2}]
	var engine=Board.new(d)
	var event: Dictionary=engine.swap(1,9)
	var surviving: Dictionary={}
	for cell in engine.cells:
		if cell.id==72:surviving=cell
	check(event.cascade_count>=2 and not surviving.is_empty() and surviving.trait.count==1,"multiple automatic waves count as one chameleon swap")
	# Color change creates a fresh line, solved without another move or resonance count.
	var environment=fixture()
	add_trait(environment,35,"chameleon",{"sequence":[2,0],"period":2})
	environment.cells[34].c=0;environment.cells[36].c=0
	Traits.advance(environment.cells,environment.collected);Traits.advance(environment.cells,environment.collected)
	var resolved: Dictionary=environment.resolve(environment.find_matches(),[],[],-1,0,false,false)
	check(resolved.cascade_count>0 and environment.moves==100 and environment.find_matches().is_empty(),"post-change automatic match needs no extra move")
	var atomic=fixture()
	atomic.level.targets={"shifts":1};atomic.level.resonance=true;atomic.moves=1
	atomic.cells[0].c=0;atomic.cells[1].c=2;atomic.cells[2].c=0;atomic.cells[9].c=0
	add_trait(atomic,35,"chameleon",{"sequence":[2,0],"period":2})
	atomic.cells[35].trait.count=1
	atomic.cells[34].c=0;atomic.cells[36].c=0
	atomic.refill_stream=[1,2,3]
	var atomic_event: Dictionary=atomic.swap(1,9)
	check(atomic_event.accepted and atomic_event.cascade_count>=2 and atomic.moves==0 and atomic.outcome=="won","real swap defers last-move result through post-color cascade")
	check(atomic.collected.shifts==1 and atomic.resonance.count==1,"color effect is one transition, not a second player/resonance move")
	for direction in ["left","right","up","down"]:
		var pin=fixture()
		add_trait(pin,27,"pin")
		var original: Dictionary=pin.cells[27].duplicate(true)
		pin.cells[26]=null
		preload("res://scripts/core/gravity.gd").compact(pin.cells,8,9,direction)
		check(pin.cells[27]==original,"pin occupies cell and stays fixed in "+direction)
		check(not pin.swap(27,28).attempted and not Match.normal(pin.cells[27]),"pin blocks swap and matching")
		Manager.wave(pin.cells,[26,28],[27,27],[],{},pin.collected,8,9)
		check(pin.cells[27].armor.hp==1,"first pin wave cracks once")
		Manager.wave(pin.cells,[26,28],[27,27],[],{},pin.collected,8,9)
		check(pin.cells[27].c==original.c and pin.cells[27].id==original.id and Match.normal(pin.cells[27]),"second pin wave preserves released crystal")
		pin.settle()
		check(null not in pin.cells and pin.collected.pins==1,"pin release fills with unique occupant")
	var pin=fixture();add_trait(pin,27,"pin");pin.cells[26].p="prism"
	Manager.wave(pin.cells,[],Powers.area(26,"prism",pin.cells,8),[26],{},pin.collected,8,9)
	check(pin.cells[27].armor.hp==1,"prism removes one pin layer")
	var rocket_pin=fixture();add_trait(rocket_pin,27,"pin");rocket_pin.cells[26].p="rocket_h"
	var rocket_event: Dictionary=rocket_pin.activate(26)
	var first_hit: Dictionary={}
	for frame in rocket_event.frames:
		if frame.kind=="clear":
			for effect in frame.mechanics:
				if effect.index==27 and first_hit.is_empty():first_hit=effect
	check(not first_hit.is_empty() and first_hit.after.hp==1,"production rocket damages fixed pin once")
	var restored=fixture();add_trait(restored,27,"dual",{"colors":[0,1]})
	check(restored.restore(restored.snapshot()),"dual snapshot restores")
	var corrupt: Dictionary=restored.snapshot();corrupt.cells[27].armor={"kind":"pin","hp":2};corrupt.cells[27].fixed=true
	check(not restored.restore(corrupt),"undefined same-cell pin + dual rejected")
func run() -> void:
	test_dual_and_bridge();test_exact_solver();test_chameleon_and_pin()
	print("PACKAGE2 UNIT: %d checks, %d failures"%[checks,failures])
	quit(1 if failures else 0)
