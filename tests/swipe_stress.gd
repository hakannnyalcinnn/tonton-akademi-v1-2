extends SceneTree
const Save = preload("res://scripts/core/save_manager.gd")
const Solver = preload("res://tests/move_solver.gd")
const Metrics = preload("res://scripts/ui/performance_metrics.gd")
var game
var waves := 0
func _initialize() -> void:
	call_deferred("run")
func touch(source: int, destination: int) -> void:
	var view = game.board_view
	var start: Vector2 = view.get_global_transform_with_canvas()*(view.cell_position(source)+Vector2(28,28))
	var end: Vector2 = view.get_global_transform_with_canvas()*(view.cell_position(destination)+Vector2(28,28))
	var press := InputEventScreenTouch.new()
	press.index=0
	press.position=start
	press.pressed=true
	root.push_input(press,true)
	var motion := InputEventScreenDrag.new()
	motion.index=0
	motion.position=end
	motion.relative=end-start
	root.push_input(motion,true)
	press.pressed=false
	press.position=end
	root.push_input(press,true)
func run() -> void:
	game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.save.finish_writes()
	game.save=Save.new("user://swipe-stress-only.json")
	game.save.data=Save.defaults()
	game.save.data.unlocked=10
	game.save.background_writes=true
	game.save.data.settings.music=false
	game.save.data.settings.reduced_motion=true
	game.save.data.settings.quality="performance"
	game.audio.apply_settings(game.save.data.settings)
	Metrics.reset()
	game.start_level(1)
	for i in 100:
		if game.board.outcome!="playing":
			game.start_level(1+i%10)
			await process_frame
		var move: Array = Solver.best_move(game.board)
		var old_moves: int = game.board.moves
		touch(move[0],move[1])
		assert(game.board.moves==old_moves-1 and game.board_view.busy)
		var snapshot: Dictionary = game.board.snapshot()
		# Another swipe in the same frame must never be accepted.
		touch(move[0],move[1])
		assert(game.board.snapshot()==snapshot)
		var frames := 0
		while game.board_view.busy and frames<1000:
			await process_frame
			frames+=1
		assert(frames<1000)
		assert(game.board_view.get_child_count()==6)
	game.save.finish_writes()
	var report: Dictionary = Metrics.report(game.save.data.settings)
	var file := FileAccess.open("res://build/swipe-stress.json",FileAccess.WRITE)
	file.store_string(JSON.stringify(report,"  "))
	file.close()
	var path: String = game.save.path
	game.queue_free()
	await process_frame
	await create_timer(.15).timeout
	for ending in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(path+ending): DirAccess.remove_absolute(ProjectSettings.globalize_path(path+ending))
	print("SWIPE STRESS: 100 valid native ScreenTouch swipes, 100 blocked duplicate swipes; fixed-size pools; 0 failures")
	quit()
