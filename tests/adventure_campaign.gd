extends SceneTree
const Catalog=preload("res://scripts/core/level_catalog.gd")
const Board=preload("res://scripts/core/board.gd")
const Solver=preload("res://tests/move_solver.gd")
const Player=preload("res://scripts/generation/auto_player.gd")
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var rows: Array=[];var wins:=0;var total:=0
	for definition in Catalog.all():
		if not definition.has("adventure"):continue
		for variant in 3:
			var d: Dictionary=definition.duplicate(true);d.seed=int(d.seed)+variant*7919
			var board:=Board.new(d);var steps:=0
			while board.available() and steps<int(d.moves):
				var action:=Solver.best_move(board)
				if action.is_empty():break
				var event:=Player.apply(board,action)
				assert(event.accepted and not board.recovery_failed);steps+=1
			var won:=board.outcome=="won";wins+=int(won);total+=1
			rows.append({"level":int(d.id),"seed":int(d.seed),"won":won,"moves_used":steps,"remaining":board.moves,"collected":board.collected})
	var file:=FileAccess.open("res://build/v012-adventure-simulations.json",FileAccess.WRITE);file.store_string(JSON.stringify({"wins":wins,"trials":total,"human_balance_verified":false,"rows":rows},"  "));file.close()
	print("ADVENTURE CAMPAIGN: ",wins,"/",total," sampled wins; PASS: simulations completed without corrupt state")
	quit()
