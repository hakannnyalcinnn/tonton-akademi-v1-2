extends SceneTree
const Board = preload("res://scripts/core/board.gd")
const Catalog = preload("res://scripts/core/level_catalog.gd")
const Match = preload("res://scripts/core/match_detector.gd")
const Gravity = preload("res://scripts/core/gravity.gd")
const Manager = preload("res://scripts/mechanics/mechanic_manager.gd")
const Registry = preload("res://scripts/mechanics/mechanic_registry.gd")
const Save = preload("res://scripts/core/save_manager.gd")
const Solver = preload("res://tests/move_solver.gd")
var checks := 0
var failures := 0
var game_count := 0
var move_count := 0
var results: Array = []
func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: "+message)
func _initialize() -> void: call_deferred("run")
func fixture(kind: String, index: int = 27):
	var definition := Catalog.get_level(1)
	definition.moves = 100
	definition.targets = {"total":10000}
	var spec := {"kind":kind,"index":index}
	if kind=="lock": spec.merge({"color":0,"required":6})
	definition.mechanics=[spec]
	return Board.new(definition)
func damage(b, indices: Array, direct: Array = [], triggered: Array = [], colors: Dictionary = {}) -> Array:
	return Manager.wave(b.cells,indices,direct,triggered,colors,b.collected,8,9)
func test_damage() -> void:
	for kind in ["seed","ice","stone"]:
		var b = fixture(kind)
		var hp: int = Registry.DEFINITIONS[kind].hp
		var identity: int = b.cells[27].id
		var color: int = b.cells[27].c
		check(not Match.normal(b.cells[27]),kind+" excluded from color matches")
		check(not b.swap(27,28).attempted and b.moves==100,kind+" cannot swap or spend moves")
		check(damage(b,[18]).is_empty(),kind+" diagonal damage rejected")
		for direction in ["down","up","left","right"]:
			b.cells[26]=null
			Gravity.compact(b.cells,8,9,direction)
			check(b.cells[27].id==identity,kind+" remains fixed in "+direction)
			b.settle()
		for hit in hp:
			var events := damage(b,[26,28,19,35,26],[27,27])
			check(events.size()==1,kind+" only one damage event per overlapping wave")
			check(events[0].after.hp==hp-hit-1,kind+" exact durability")
			if hit<hp-1: check(b.cells[27]!=null and b.cells[27].fixed,kind+" remains protected")
		if kind=="ice":
			check(b.cells[27].id==identity and b.cells[27].c==color and Match.normal(b.cells[27]),"ice preserves underlying crystal")
			check(b.collected.ice==2,"ice objective counts each removed layer exactly once")
		else:
			check(b.cells[27]==null,"opened obstacle releases occupancy")
			check(b.collected[Registry.DEFINITIONS[kind].objective]==1,"completion counted once")
		b.settle()
		check(null not in b.cells and b.moves==100,"release refills without extra move")
	var rock = fixture("stone")
	rock.cells[26].p="prism"
	var events := damage(rock,[],[27,27],[26],{})
	check(events[0].after.hp==1,"direct prism deals two stone damage")
	var ice = fixture("ice")
	ice.cells[26].p="prism"
	damage(ice,[],[27],[26],{})
	check(ice.cells[27].armor.hp==1,"prism removes only one ice layer per wave")
	var lock = fixture("lock")
	check(damage(lock,[26,28],[27],[],{"1":50}).is_empty(),"lock ignores damage and wrong color")
	damage(lock,[],[],[],{"0":3})
	check(lock.cells[27].obstacle.energy==3,"lock remembers exact normal-color energy")
	damage(lock,[],[],[],{"0":3})
	check(lock.cells[27]==null and lock.collected.locks==1 and lock.moves==100,"lock opens without move")
	var defs := Catalog.get_level(1)
	defs.mechanics=[{"kind":"lock","index":3,"color":0,"required":3},{"kind":"lock","index":20,"color":1,"required":3}]
	var dual = Board.new(defs)
	damage(dual,[],[],[],{"0":3})
	check(dual.cells[3]==null and dual.cells[20].obstacle.energy==0,"independent differently colored locks")
func test_integration() -> void:
	for number in [11,16,21,26]:
		var teaching:=Catalog.get_level(number)
		# This unit fixture isolates the obstacle; campaign total targets now require strategy.
		teaching.targets.erase("total")
		var b=Board.new(teaching)
		check(b.find_matches().is_empty() and Match.has_move(b.cells,8,9),"teaching board stable/playable")
		var before: int=b.moves
		var event: Dictionary=b.swap(1,9)
		check(event.accepted and b.moves==before-1,"teaching swipe costs exactly one")
		check(event.cascade_count>=2,"tutorial automatic repeated refill wave")
		check(b.cells[3]!=null and not b.cells[3].get("fixed",false),"tutorial obstacle releases and fills")
		check(b.find_matches().is_empty(),"release cascades finish stable")
		check(b.outcome=="won","last teaching objective ends after cascades")
		check(not event.cascade_guard,"normal teaching has no cascade recovery")
		var restored=Board.new(b.level)
		check(restored.restore(b.snapshot()) and restored.snapshot()==b.snapshot(),"mechanic settled snapshot restored exactly")
	var last_definition:=Catalog.get_level(11);last_definition.targets={"flowers":1}
	var last=Board.new(last_definition)
	last.moves=1
	var last_event: Dictionary=last.swap(1,9)
	check(last.outcome=="won" and last.moves==0 and last_event.cascade_count>=2,"last move waits for seed cascade completion")
	var shuffle_board=Board.new(Catalog.get_level(30))
	var protected: Dictionary={}
	for i in 72:
		if shuffle_board.cells[i].get("fixed",false): protected[i]=shuffle_board.cells[i].duplicate(true)
	var shuffled: bool=preload("res://scripts/core/board_generator.gd").shuffle(shuffle_board.cells,shuffle_board.rng,8,9)
	check(shuffled and shuffle_board.find_matches().is_empty() and Match.has_move(shuffle_board.cells,8,9),"mechanic board shuffles to stable legal arrangement")
	for i in protected: check(shuffle_board.cells[i]==protected[i],"shuffle preserves occupancy, armor, HP and energy")
	var direct=fixture("stone")
	direct.cells[26].p="rocket_h"
	var power_event: Dictionary=direct.activate(26)
	var first_effect: Dictionary={}
	for frame in power_event.frames:
		if frame.kind=="clear":
			for effect in frame.mechanics:
				if effect.index==27 and first_effect.is_empty(): first_effect=effect
	check(not first_effect.is_empty() and first_effect.after.hp==2,"direct rocket includes fixed stone footprint once")
	var lock_def:=Catalog.get_level(1)
	lock_def.targets={"total":10000}
	lock_def.mechanics=[{"kind":"lock","index":71,"color":0,"required":1000}]
	var lock_board=Board.new(lock_def)
	lock_board.cells[26].p="prism";lock_board.cells[27].p="prism"
	lock_board.swap(26,27)
	check(lock_board.cells[71].obstacle.energy==lock_board.collected["0"],"overlapping special combo counts each normal red crystal once across cascades")
	var b=fixture("ice",1)
	b.cells[0].c=0; b.cells[1].c=0; b.cells[2].c=0
	check(not Match.line_at(b.cells,0,8,9),"ice blocks ready triple")
	damage(b,[9]); damage(b,[9])
	var event: Dictionary=b.resolve(b.find_matches(),[],[],-1,0,false,false)
	check(event.cascade_count>=1 and b.find_matches().is_empty() and b.moves==100,"ice release triggers automatic match without spending move")
	var initial=fixture("ice")
	var snap: Dictionary=initial.snapshot()
	var corrupt: Dictionary=snap.duplicate(true)
	corrupt.cells[27].armor.hp=0
	check(not initial.restore(corrupt),"invalid armor durability rejected")
	corrupt=snap.duplicate(true);corrupt.cells[27].fixed=false
	check(not initial.restore(corrupt),"moving armor save rejected")
	corrupt=snap.duplicate(true);corrupt.cells[27].armor="bad"
	check(not initial.restore(corrupt),"malformed layer rejects without a script error")
	check(initial.restore(snap),"valid protected-layer save accepted")
func test_environmental_gravity() -> void:
	for kind in ["seed","ice","stone","lock"]:
		for direction in ["left","up","right","down"]:
			var b=fixture(kind)
			b.level.gravity=true
			b.direction="up" if direction=="down" else "down"
			b.energy=1
			var protected: Dictionary=b.cells[27].duplicate(true)
			b.cells[26]=null
			b.cells[43]=null
			b.direction=direction
			b.frames.clear();b.settle(true)
			var event: Dictionary=b.resolve(b.find_matches(),[],[],-1,-1,false,false)
			event.frames=b.frames.duplicate()
			check(b.moves==100 and b.energy>=0,"mechanic environmental resolver spends no move")
			check(event.frames[0].kind=="fall" and event.frames[0].after[27]==protected,"fixed mechanic remains in first gravity frame")
			check(b.find_matches().is_empty() and null not in b.cells and Match.has_move(b.cells,8,9),"gravity refills around mechanic and resolves cascades")

func test_saves() -> void:
	var path: String="user://mechanics-test-only.json"
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(path+suffix): DirAccess.remove_absolute(ProjectSettings.globalize_path(path+suffix))
	var save=Save.new(path)
	save.data.unlocked=10
	var b=Board.new(Catalog.get_level(10))
	b.outcome="won"
	check(save.complete(b) and save.data.unlocked==11,"level 10 unlocks 11 with reward")
	check(not save.complete(b) and save.data.rewarded.size()==1,"replay never duplicates reward")
	var next=Board.new(Catalog.get_level(11))
	check(save.save_active(next),"mechanic save writes")
	var loaded=Save.new(path)
	check(loaded.data.active==next.snapshot() and loaded.data.unlocked==11,"restart keeps mechanic and level progress")
	# A completed old level-ten profile used to remain capped at ten.
	save.data=Save.defaults()
	save.data.unlocked=10
	save.data.results={"10":{"score":1000,"stars":1}}
	save.flush()
	check(Save.new(path).data.unlocked==11,"old completed level-ten save upgrades its catalog cap")
	var legacy: Dictionary=Board.new(Catalog.get_level(4)).snapshot()
	for key in ["flowers","ice","stones","locks"]: legacy.collected.erase(key)
	var restored=Board.new(Catalog.get_level(4))
	check(restored.restore(legacy) and restored.collected.flowers==0,"old schema2 active board gains optional mechanic counters")
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(path+suffix): DirAccess.remove_absolute(ProjectSettings.globalize_path(path+suffix))
func simulations() -> void:
	for number in range(11,31):
		var wins:=0
		var max_used:=0
		var score_sum:=0
		var min_score:=2147483647
		var max_score:=0
		for offset in 30:
			var definition:=Catalog.get_level(number)
			definition.seed=int(definition.seed)+offset
			check(Catalog.validate(definition),"extended level validates")
			var a=Board.new(definition)
			var b=Board.new(definition)
			check(a.find_matches().is_empty() and Match.has_move(a.cells,8,9),"extended starts stable with move")
			var actions:=0
			while a.available():
				var move:=Solver.best_move(a)
				var event: Dictionary=a.swap(move[0],move[1])
				b.swap(move[0],move[1])
				check(event.accepted and not event.cascade_guard,"extended legal action accepted")
				check(a.snapshot()==b.snapshot(),"extended deterministic seed and actions")
				check(a.find_matches().is_empty() and Match.has_move(a.cells,8,9) and null not in a.cells,"extended finishes stable/refilled/playable")
				check(a.moves==int(definition.moves)-actions-1,"extended wave costs only one move")
				var restored=Board.new(definition)
				check(restored.restore(a.snapshot()),"every extended state validates for saving")
				actions+=1
				move_count+=1
			if a.outcome=="won":wins+=1
			if offset==0:
				var star_route: bool=a.outcome=="won" and a.score>=int(definition.stars[2])
				if not star_route:
					for strategy in ["largest","objective","powers","lookahead"]:
						var witness=Board.new(definition)
						while witness.available():
							var player=preload("res://scripts/generation/auto_player.gd")
							var proof: Dictionary=player.apply(witness,player.select(witness,strategy))
							check(proof.accepted and not proof.get("cascade_guard",false),"bounded three-star witness uses actual legal engine transactions")
						if witness.outcome=="won" and witness.score>=int(definition.stars[2]):
							star_route=true;print("Three-star witness %d: %s, score %d"%[number,strategy,witness.score]);break
				check(star_route,"default seed has demonstrated three-star winning route")
			score_sum+=a.score
			min_score=mini(min_score,a.score)
			max_score=maxi(max_score,a.score)
			max_used=maxi(max_used,actions)
			game_count+=1
		results.append({"level":number,"wins":wins,"games":30,"max_moves_used":max_used,"min_score":min_score,"max_score":max_score,"mean_score":score_sum/30.0})
		check(wins>=21,"level %d gameplay2 heuristic minimum 70%% %d/30"%[number,wins])
		print("Mechanic Level %02d: %d/30 won, max %d moves"%[number,wins,max_used])
func run() -> void:
	test_damage()
	test_integration()
	test_environmental_gravity()
	test_saves()
	simulations()
	var file:=FileAccess.open("res://build/mechanic-tests.json",FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks":checks,"failures":failures,"games":game_count,"moves":move_count,"levels":results},"  "))
	file.close()
	print("MECHANICS: %d checks, %d failures; %d games / %d moves"%[checks,failures,game_count,move_count])
	quit(1 if failures>0 else 0)
