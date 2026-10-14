extends SceneTree
const Board=preload("res://scripts/core/board.gd")
const Catalog=preload("res://scripts/core/level_catalog.gd")
const Portal=preload("res://scripts/mechanics/portal_manager.gd")
const Vines=preload("res://scripts/mechanics/vine_manager.gd")
const Chain=preload("res://scripts/mechanics/chain_reaction_resolver.gd")
const Mechanics=preload("res://scripts/mechanics/mechanic_manager.gd")
const Registry=preload("res://scripts/mechanics/mechanic_registry.gd")
const Beam=preload("res://scripts/mechanics/beam_resolver.gd")
const Mirror=preload("res://scripts/mechanics/mirror_manager.gd")
const Powers=preload("res://scripts/core/powerups.gd")
const Gravity=preload("res://scripts/core/gravity.gd")
const Solver=preload("res://tests/move_solver.gd")
var checks:=0
var failures:=0
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL: "+message)
func fresh() -> Board:return Board.new(Catalog.get_level(1))
func _initialize() -> void:call_deferred("run")
func run() -> void:
	check(Portal.validate([{"entry":1,"exit":2}]) and not Portal.validate([{"entry":1,"exit":1}]) and not Portal.validate([{"entry":1,"exit":2},{"entry":2,"exit":3}]),"portal coordinates distinct, bounded and unambiguous")
	for direction in ["down","up","left","right"]:
		var b=fresh();var lines:=Gravity.lines(8,9,"down")
		b.cells.fill(null);b.direction=direction
		var id: int=b.make_cell(0).id
		b.cells[lines[0][1]]={"id":id,"c":0,"p":""}
		b.level.portals=[{"entry":lines[0][0],"exit":lines[1][-1]}]
		b.settle(true)
		check(b.direction=="down","legacy direction canonicalizes before portal gravity")
		check(b.movement_queue.size()==1 and b.movement_queue[0].id==id,"gravity arrival transfers exactly once: "+direction)
		check(b.cells[lines[1][0]].id==id,"portal exits continue under current gravity: "+direction)
		var seen: Dictionary={}
		for c in b.cells:check(not seen.has(c.id),"portal/refill IDs never copied");seen[c.id]=true
		check(b.frames.any(func(f):return f.kind=="portal"),"portal transfer has separate animation frame")
	var b=fresh();var used: Dictionary={};var queue: Array=[];var crystal: int=b.cells[0].id
	check(Portal.transfer(b.cells,[{"entry":0,"exit":1}],{crystal:true},used,queue).is_empty(),"occupied portal exit blocks safely")
	b.cells[1]=null
	check(Portal.transfer(b.cells,[{"entry":0,"exit":1}],{},used,queue).is_empty(),"stationary crystal never teleports")
	Mechanics.install(b.cells,[{"kind":"pin","index":0}])
	check(Portal.transfer(b.cells,[{"entry":0,"exit":1}],{crystal:true},used,queue).is_empty(),"pinned crystal cannot teleport")
	b.cells[0]=b.make_cell(0,"rocket_h")
	check(Portal.transfer(b.cells,[{"entry":0,"exit":1}],{int(b.cells[0].id):true},used,queue).is_empty(),"special objects are not transported")
	b=fresh();b.cells[0].c=0;b.cells[40].c=0;b.cells[42].c=0;b.cells[41]=null
	used={};queue=[];crystal=b.cells[0].id
	Portal.transfer(b.cells,[{"entry":0,"exit":41}],{crystal:true},used,queue)
	check(b.find_matches().any(func(m):return 41 in m.cells),"portal landing creates match")
	var old: int=b.moves;var e:=b.resolve(b.find_matches(),[],[],-1,0,false,false)
	check(e.cascade_count>0 and b.moves==old and b.find_matches().is_empty(),"portal landing automatically resolves without extra moves")
	b=fresh();used={};queue=[];crystal=b.cells[0].id;b.cells[1]=null
	Portal.transfer(b.cells,[{"entry":0,"exit":1}],{crystal:true},used,queue)
	check(Portal.transfer(b.cells,[{"entry":1,"exit":0}],{crystal:true},used,queue).is_empty(),"same crystal cannot cycle twice in an action")
	b=fresh();b.level.targets={"total":10000};b.level.moves=100;b.moves=100;b.initial_moves=100;b.level.vine_enabled=true;b.level.vine_max=2;Mechanics.install(b.cells,[{"kind":"vine","index":35}])
	check(b.cells[35].fixed and not Powers.Traits.supports(b.cells[35],b.cells[35].c),"vine locks match and movement")
	for action in 3:
		var move:=Solver.best_move(b);e=b.swap(move[0],move[1])
		check(e.accepted and b.vine_count==(action+1)%3,"vine advances once per accepted swap, not cascade")
	check(b.snapshot().vine_count==0,"vine turn counter persisted")
	var restored=Board.new(b.level);check(restored.restore(b.snapshot()),"new optional counters preserve save format")
	var cells: Array=fresh().cells;Mechanics.install(cells,[{"kind":"vine","index":27},{"kind":"stone","index":19}])
	var growth:=Vines.spread(cells,2,8,9)
	check(growth.size()==1 and growth[0].index==26,"vine row order and neighbor order deterministic; stone excluded")
	check(Vines.spread(cells,2,8,9).is_empty(),"vine cap stops further growth")
	var counts: Dictionary=b.collected.duplicate();var hits:=Mechanics.wave(cells,[28,35],[27,27],[],{},counts,8,9)
	check(hits.filter(func(v):return v.index==27).size()==1 and not cells[27].has("armor"),"one wave removes vine exactly once")
	b=fresh();b.level.targets={"total":10000};b.level.moves=100;b.moves=100;b.initial_moves=100;b.level.vine_enabled=true;Mechanics.install(b.cells,[{"kind":"vine","index":35}]);b.energy=2;b.level.gravity=true
	old=b.vine_count;b.change_gravity("up");check(b.vine_count==old,"gravity special action does not grow vines")
	var invalid_found:=false
	for i in 72:
		if invalid_found:break
		for j in preload("res://scripts/core/match_detector.gd").neighbors(i,8,9):
			if b.cells[i].get("fixed",false) or b.cells[j].get("fixed",false) or b.cells[i].p!="" or b.cells[j].p!="":continue
			if not preload("res://scripts/core/match_detector.gd").can_swap(b.cells,i,j,8,9):
				old=b.vine_count;var snapshot:=b.snapshot();e=b.swap(i,j)
				check(not e.accepted and snapshot==b.snapshot() and b.vine_count==old,"invalid swap neither grows nor spends move");invalid_found=true;break
	check(invalid_found,"invalid-swap scenario actually exercised")
	# Two crates at hp1: first adjacent match detonates A; its independent blast detonates B.
	b=fresh();Mechanics.install(b.cells,[{"kind":"crate","index":27},{"kind":"crate","index":28},{"kind":"ice","index":20},{"kind":"stone","index":36}])
	b.cells[27].obstacle.hp=1;b.cells[28].obstacle.hp=1
	var chain:=Chain.resolve(b.cells,[26],0,{},b.collected,8,9)
	check(b.cells[27]==null and b.cells[28]==null and b.collected.crates==2,"crate chain detonates both once")
	check(chain.events.size()==3 and chain.events[1].area.size()==9,"crate effects carry unique event IDs and 3x3 footprints")
	check(not b.cells[20].has("armor") and b.collected.ice==2 and b.cells[36].obstacle.hp==1,"ice one wave / stone independent blasts accumulate")
	check(chain.removed.count(26)==1,"overlapping crate blasts score crystal once")
	b=fresh();Mechanics.install(b.cells,[{"kind":"crate","index":27}])
	chain=Chain.resolve(b.cells,[26,19,28],0,{},b.collected,8,9)
	check(b.cells[27].obstacle.hp==1 and b.collected.crates==0,"several neighbors in one event inflict only first crate hit")
	chain=Chain.resolve(b.cells,[26],0,{},b.collected,8,9)
	check(b.cells[27]==null and b.collected.crates==1,"second distinct hit detonates crate")
	b=fresh();Mechanics.install(b.cells,[{"kind":"crate","index":27}]);b.cells[27].obstacle.hp=1;b.cells[28].p="rocket_h"
	e=b.resolve([], [26],[],-1,0,true,false)
	check(e.cascade_count>=1 and not e.cascade_guard and b.find_matches().is_empty() and b.collected.crates==1,"crate power/gravity/refill/cascade engine integration")
	check(e.frames.any(func(f):return f.kind=="clear" and 28 in f.triggered),"crate blast triggers existing special once")
	var directions: Array=[Vector2i(1,0),Vector2i(-1,0),Vector2i(0,1),Vector2i(0,-1)]
	var slash: Array=[Vector2i(0,-1),Vector2i(0,1),Vector2i(-1,0),Vector2i(1,0)]
	var backslash: Array=[Vector2i(0,1),Vector2i(0,-1),Vector2i(1,0),Vector2i(-1,0)]
	for i in 4:
		check(Mirror.reflect(directions[i].x,directions[i].y,"/")==slash[i],"slash four incoming directions")
		check(Mirror.reflect(directions[i].x,directions[i].y,"\\")==backslash[i],"backslash four incoming directions")
	b=fresh();Mechanics.install(b.cells,[{"kind":"mirror","index":19,"orientation":"\\"},{"kind":"mirror","index":35,"orientation":"/"},{"kind":"mirror","index":33,"orientation":"\\"},{"kind":"mirror","index":17,"orientation":"/"}])
	var beam:=Beam.trace(18,Vector2i(1,0),b.cells,8)
	check(beam.looped and beam.path.size()<=72*4,"closed mirror loop terminates by cell and incoming direction")
	check(19 in beam.path and 35 in beam.path and 33 in beam.path and 17 in beam.path,"several mirrors reflect a single ray")
	check(19 not in beam.hits and 35 not in beam.hits,"mirrors redirect without taking damage or duplicating beams")
	for index in 72:
		b=fresh()
		for kind in ["rocket_h","rocket_v"]:
			var actual:=Powers.area(index,kind,b.cells,8);var unique: Array=[]
			for target in actual:
				if target not in unique:unique.append(target)
			var expected: Array=[]
			for i in 72:
				if (kind=="rocket_h" and int(i/8)==int(index/8)) or (kind=="rocket_v" and i%8==index%8):expected.append(i)
			unique.sort();check(unique==expected,"mirror-free rocket regression all cells")
	for seed in 200:
		b=fresh();b.rng.state=seed+1
		var specs: Array=[]
		for i in range(0,72,9):specs.append({"kind":"crate","index":i})
		Mechanics.install(b.cells,specs)
		for spec in specs:b.cells[spec.index].obstacle.hp=1
		chain=Chain.resolve(b.cells,[1,10,19,28,37,46,55,64],0,{},b.collected,8,9)
		check(chain.events.size()<=9 and b.collected.crates==8,"200 dense crate chains bounded")
	b=fresh();b.level.moves=100;b.moves=100;b.initial_moves=100;b.level.targets={"total":10000};b.level.vine_enabled=true;b.level.vine_max=6;b.vine_count=2
	var barrier_specs: Array=[]
	for i in 72:
		if i not in [20,21,22,29]:barrier_specs.append({"kind":"vine","index":i} if i==37 else {"kind":"mirror","index":i,"orientation":"/"})
	Mechanics.install(b.cells,barrier_specs)
	b.cells[20].c=1;b.cells[21].c=0;b.cells[22].c=1;b.cells[29].c=1
	b.refill_stream=[0,1,0]
	e=b.swap(21,29)
	check(e.accepted and b.moves==99 and b.vine_count==0,"third successful swap reaches vine growth after complete cascade")
	check(not b.cells[29].has("armor") and b.find_matches().is_empty() and preload("res://scripts/core/match_detector.gd").has_move(b.cells,8,9),"vine topology with no possible shuffle safely reverts growth and keeps legal move")
	check(e.frames.any(func(f):return f.kind=="vine" and f.get("growth",[]).is_empty()),"unrecoverable growth has explicit presentation rollback and diagnostic")
	var scenario_count:=0;var scenario_actions:=0
	for kind in ["portal","vine","crate","mirror"]:
		for seed in 25:
			var definition:=preload("res://scripts/mechanics/developer_scenarios.gd").make(kind,104169+seed)
			var left=Board.new(definition);var right=Board.new(definition)
			for turn in 6:
				var move:=Solver.best_move(left)
				var event: Dictionary={}
				if turn==0 and kind=="portal":event=left.swap(58,66);right.swap(58,66)
				elif turn==0 and kind=="mirror":event=left.activate(18);right.activate(18)
				elif kind=="crate" and turn in [0,1] and left.cells[34 if turn==0 else 42].p!="":
					var index:=34 if turn==0 else 42;event=left.activate(index);right.activate(index)
				else:event=left.swap(move[0],move[1]);right.swap(move[0],move[1])
				check(event.accepted and not event.cascade_guard,"100 developer boards / six finite valid actions")
				check(left.snapshot()==right.snapshot(),"same seed and input reproduce all new mechanics")
				check(left.find_matches().is_empty() and null not in left.cells,"new combined environment/clear/refill settles")
				var reload=Board.new(definition)
				check(reload.restore(left.snapshot()),"portal/vine/crate/mirror stable snapshots restore")
				scenario_actions+=1
			scenario_count+=1
	var old_board=Board.new(Catalog.get_level(50));var old_save: Dictionary=old_board.snapshot()
	old_save.erase("vine_count")
	for key in ["vines","crates","mirrors","bridges"]:old_save.collected.erase(key)
	var upgraded=Board.new(Catalog.get_level(50))
	check(upgraded.restore(old_save),"0.5-style active snapshot missing new fields remains loadable")
	check(upgraded.cells==old_board.cells and upgraded.rng.state==old_board.rng.state and upgraded.collected.bridges==0 and upgraded.vine_count==0,"old active crystals/RNG preserved, new counters default to zero")
	var mixed:=preload("res://scripts/mechanics/developer_scenarios.gd").make("crate",104169)
	mixed.mechanics[0].index=36;mixed.mechanics[1].index=37
	mixed.portals=[{"entry":65,"exit":0}];mixed.vine_enabled=true;mixed.vine_max=5
	mixed.mechanics.append_array([{"kind":"seed","index":35},{"kind":"lock","index":51,"color":1,"required":12},{"kind":"dual","index":4,"colors":[0,1]},{"kind":"chameleon","index":12,"sequence":[2,1,0,4],"period":2},{"kind":"bridge","index":23},{"kind":"pin","index":60},{"kind":"vine","index":44},{"kind":"mirror","index":19,"orientation":"/"}])
	var mixed_a=Board.new(mixed);var mixed_b=Board.new(mixed)
	for turn in 22:
		var event: Dictionary={}
		if turn==0:event=mixed_a.activate(34);mixed_b.activate(34)
		elif turn==1 and mixed_a.cells[42].p!="":event=mixed_a.activate(42);mixed_b.activate(42)
		else:
			var pair:=Solver.best_move(mixed_a);event=mixed_a.swap(pair[0],pair[1]);mixed_b.swap(pair[0],pair[1])
		check(event.accepted and not event.cascade_guard,"all twelve mechanics coexist on separate cells")
		check(mixed_a.snapshot()==mixed_b.snapshot() and mixed_a.find_matches().is_empty(),"mixed mechanics are deterministic and settle after all chains")
		var reload=Board.new(mixed);check(reload.restore(mixed_a.snapshot()),"mixed twelve-mechanic snapshot remains valid")
	print("PACKAGE4 SCENARIOS: %d boards / %d actions"%[scenario_count,scenario_actions])
	print("PACKAGE4 MECHANICS: %d checks, %d failures"%[checks,failures])
	quit(1 if failures else 0)
