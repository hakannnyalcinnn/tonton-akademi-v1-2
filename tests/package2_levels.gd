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
	for n in range(31,51):
		var wins:=0;var max_used:=0;var score_sum:=0;var base_score:=0
		for offset in 20:
			var d:=Catalog.get_level(n)
			d.seed=int(d.seed)+offset
			check(Catalog.validate(d),"campaign has only released, valid mechanics")
			var a=Board.new(d);var b=Board.new(d)
			check(a.find_matches().is_empty() and Match.has_move(a.cells,8,9),"package2 starts stable and playable")
			var action:=0
			while a.available():
				var move:=Solver.best_move(a)
				var event: Dictionary=a.swap(move[0],move[1])
				b.swap(move[0],move[1])
				check(event.accepted and not event.cascade_guard,"package2 legal move and finite cascade")
				check(a.snapshot()==b.snapshot(),"package2 same seed / actions replay exactly")
				check(a.moves==int(d.moves)-action-1,"mutation and cascade spend one move")
				check(a.find_matches().is_empty() and null not in a.cells and Match.has_move(a.cells,8,9),"package2 settles without matches or occupancy holes")
				var restored=Board.new(d)
				check(restored.restore(a.snapshot()),"every package2 state can be saved and restored")
				action+=1;moves+=1
			max_used=maxi(max_used,action);score_sum+=a.score
			if offset==0:
				base_score=a.score
				check(a.outcome=="won" and a.score>=int(d.stars[2]),"default seed has a demonstrated three-star route")
			if a.outcome=="won":wins+=1
		check(wins>=14,"level %d gameplay2 heuristic minimum 70%%: %d/20"%[n,wins])
		results.append({"level":n,"wins":wins,"games":20,"max_moves_used":max_used,"mean_score":score_sum/20.0,"base_score":base_score})
		print("Package2 level %d: %d/20 wins, max %d moves"%[n,wins,max_used])
	var path: String="user://package2-save-only.json"
	var save=Save.new(path)
	save.data=Save.defaults();save.data.unlocked=30;save.data.results={"30":{"score":5000,"stars":2}};save.flush()
	check(Save.new(path).data.unlocked==31,"old completed level thirty unlocks 31")
	var final_board=Board.new(Catalog.get_level(50));final_board.outcome="won"
	check(save.complete(final_board),"world final level reward granted once")
	check(save.data.world_rewards==[1] and save.data.unlocked==51,"world medal grants only the actual next catalog level")
	save.complete(final_board)
	check(save.data.world_rewards==[1],"world medal not duplicated on replay")
	check(Save.new(path).data.world_rewards==[1],"world medal durable after restart")
	check(Save.new(path).data.unlocked==51 and Catalog.world_for(51)==2,"completed garden enters released ocean")
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(path+suffix):DirAccess.remove_absolute(ProjectSettings.globalize_path(path+suffix))
	var f:=FileAccess.open("res://build/package2-level-tests.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"failures":failures,"games":400,"moves":moves,"levels":results},"  "));f.close()
	print("PACKAGE2 LEVELS: %d checks, %d failures; 400 games / %d moves"%[checks,failures,moves])
	quit(1 if failures else 0)
