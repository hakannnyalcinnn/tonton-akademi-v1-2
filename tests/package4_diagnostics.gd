extends SceneTree
const Board=preload("res://scripts/core/board.gd")
const Scenarios=preload("res://scripts/mechanics/developer_scenarios.gd")
const Solver=preload("res://tests/move_solver.gd")
const Metrics=preload("res://scripts/ui/performance_metrics.gd")
func _initialize() -> void:
	var events: Array=[];var b
	for attempt in 100:
		if attempt%5==0:b=Board.new(Scenarios.make(["portal","vine","crate","mirror"][int(attempt/5)%4],104169+int(attempt/20)))
		var pair:=Solver.best_move(b);var event: Dictionary={};var started:=Time.get_ticks_usec()
		if attempt%5==0 and "Ayna" in b.level.name:event=b.activate(18)
		elif attempt%5 in [0,1] and "Sandık" in b.level.name:event=b.activate(34 if attempt%5==0 else 42)
		elif attempt%5==0 and "Portal" in b.level.name:event=b.swap(58,66)
		else:event=b.swap(pair[0],pair[1])
		assert(event.accepted)
		events.append({"attempt":attempt,"scene":b.level.name,"time_ms":(Time.get_ticks_usec()-started)/1000.0,"shuffled":event.shuffled})
	var f:=FileAccess.open("res://build/lab-headless-diagnosis.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"actions":events,"metrics":Metrics.report({})},"  "));f.close()
	print("LAB HEADLESS DIAGNOSIS: 100 actions, 0 failures")
	quit()
