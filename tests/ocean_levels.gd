extends SceneTree
const Board=preload("res://scripts/core/board.gd")
const Catalog=preload("res://scripts/core/level_catalog.gd")
const Match=preload("res://scripts/core/match_detector.gd")
const Solver=preload("res://tests/move_solver.gd")
const Save=preload("res://scripts/core/save_manager.gd")
var checks:=0
var failures:=0
var results: Array=[]
var moves:=0
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL: "+message)
func _initialize() -> void:call_deferred("run")
func run() -> void:
	for n in range(51,76):
		var wins:=0;var max_used:=0;var score_sum:=0;var base_score:=0
		for offset in 20:
			var d:=Catalog.get_level(n)
			d.seed=int(d.seed)+offset
			check(Catalog.validate(d),"campaign has only released, valid mechanics")
			var a=Board.new(d);var b=Board.new(d)
			check(a.find_matches().is_empty() and Match.has_move(a.cells,8,9),"package4 starts stable and playable")
			var action:=0;var stagnant:=0;var previous_progress:=0
			for key in d.targets:previous_progress+=mini(int(d.targets[key]),int(a.collected.get(key,0)))
			while a.available():
				if stagnant>=4 and a.energy>0:
					var directions: Array=["down","up","left","right"]
					var direction: String=directions[(directions.find(a.direction)+1)%4]
					var prior_moves: int=a.moves
					var gravity_event: Dictionary=a.change_gravity(direction);b.change_gravity(direction)
					check(gravity_event.accepted and a.moves==prior_moves and a.snapshot()==b.snapshot(),"strategic gravity spends energy only and replays deterministically")
					stagnant=0
					if not a.available():break
				var move:=Solver.best_move(a)
				var event: Dictionary=a.swap(move[0],move[1])
				b.swap(move[0],move[1])
				check(event.accepted and not event.cascade_guard,"package4 legal move and finite cascade")
				check(a.snapshot()==b.snapshot(),"package4 same seed / actions replay exactly")
				check(a.moves==int(d.moves)-action-1,"mutation and cascade spend one move")
				check(a.find_matches().is_empty() and null not in a.cells and Match.has_move(a.cells,8,9),"package4 settles without matches or occupancy holes")
				var restored=Board.new(d)
				check(restored.restore(a.snapshot()),"every package4 state can be saved and restored")
				var progress:=0
				for key in d.targets:progress+=mini(int(d.targets[key]),int(a.collected.get(key,0)))
				stagnant=stagnant+1 if progress==previous_progress else 0
				previous_progress=progress
				action+=1;moves+=1
			max_used=maxi(max_used,action);score_sum+=a.score
			if offset==0:
				base_score=a.score
				check(a.outcome=="won" and a.score>=int(d.stars[2]),"default seed has a demonstrated three-star route")
			if a.outcome=="won":wins+=1
		check(wins==20,"level %d solvability %d/20"%[n,wins])
		results.append({"level":n,"wins":wins,"games":20,"max_moves_used":max_used,"mean_score":score_sum/20.0,"base_score":base_score})
		print("Ocean level %d: %d/20 wins, max %d moves"%[n,wins,max_used])
	var f:=FileAccess.open("res://build/package4-level-tests.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"failures":failures,"games":500,"moves":moves,"levels":results},"  "));f.close()
	print("OCEAN LEVELS: %d checks, %d failures; 500 games / %d moves"%[checks,failures,moves])
	quit(1 if failures else 0)
