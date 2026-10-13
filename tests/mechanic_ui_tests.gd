extends SceneTree
const Save=preload("res://scripts/core/save_manager.gd")
const Solver=preload("res://tests/move_solver.gd")
var checks:=0
var game
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok:
		push_error(message)
		quit(1)
func _initialize() -> void: call_deferred("run")
func wait_view() -> void:
	var frames:=0
	while game.board_view.busy and frames<1000:
		await process_frame
		frames+=1
	check(frames<1000,"mechanic animation bounded")
func swipe(a: int, b: int) -> void:
	var start: Vector2=game.board_view.get_global_transform_with_canvas()*(game.board_view.cell_position(a)+Vector2(28,28))
	var end: Vector2=game.board_view.get_global_transform_with_canvas()*(game.board_view.cell_position(b)+Vector2(28,28))
	var press:=InputEventScreenTouch.new()
	press.position=start;press.index=0;press.pressed=true
	root.push_input(press,true)
	var drag:=InputEventScreenDrag.new()
	drag.position=end;drag.relative=end-start;drag.index=0
	root.push_input(drag,true)
	press.pressed=false;press.position=end
	root.push_input(press,true)
func run() -> void:
	game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.save.finish_writes()
	game.save=Save.new("user://mechanic-ui-only.json")
	game.save.data=Save.defaults()
	game.save.data.unlocked=30
	game.save.background_writes=true
	game.save.data.settings.music=false
	game.audio.apply_settings(game.save.data.settings)
	for n in range(11,31):
		game.start_level(n)
		game.board_view.reduced_motion=true
		await process_frame
		check(game.board_view.mechanic_textures.size()==13,"all original states preloaded")
		check(game.board_view.get_child_count()==6,"no per-mechanic scene nodes")
		var old_moves: int=game.board.moves
		var snapshot: Dictionary=game.board.snapshot()
		# Locked top-edge cells cannot begin a gesture; cannot alter snapshots.
		swipe(3,4)
		check(game.board.snapshot()==snapshot,"fixed top edge ignores native swipe")
		var move:=Solver.best_move(game.board)
		swipe(move[0],move[1])
		check(game.board.moves==old_moves-1 and game.board_view.busy,"extended native swipe commits exactly once")
		var settled: Dictionary=game.board.snapshot()
		swipe(move[0],move[1])
		check(game.board.snapshot()==settled,"rapid swipe blocked through mechanic effects")
		game._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
		check(game.paused,"background pauses mechanic presentation")
		game.close_overlay()
		await wait_view()
		check(game.board.snapshot()==settled,"visual effects/lifecycle do not change logical outcome")
		check(game.board_view.particle_positions.size()==192 and game.board_view.get_child_count()==6,"effect storage remains bounded")
		game.save.finish_writes()
		if game.board.outcome=="playing":
			var restored=Save.new(game.save.path)
			check(restored.data.active==game.board.snapshot(),"worker persistence with remaining mechanics")
	game.show_map(2)
	check(game.map_group==2 and game.screen=="map","26–30 reachable on paged map")
	var live_active: Dictionary=game.save.data.active.duplicate(true)
	var live_results: Dictionary=game.save.data.results.duplicate(true)
	game.start_mechanic_test()
	check(game.test_mode,"developer sandbox opens in editor build")
	for kind in ["seed","ice","stone","lock"]:
		game.test_index=27
		game.add_test_mechanic(kind)
		check(game.board.cells[27].get("armor",game.board.cells[27].get("obstacle",{})).kind==kind,"sandbox installs production "+kind)
		check(game.board.find_matches().is_empty(),"sandbox stays stable")
	game.persist_board()
	check(game.save.data.active==live_active and game.save.data.results==live_results,"sandbox cannot overwrite progression")
	game.test_seed=91234
	game.start_mechanic_test()
	var first: Dictionary=game.board.snapshot()
	game.start_mechanic_test()
	check(game.board.snapshot()==first,"sandbox seed reset deterministic")
	game.show_home()
	check(not game.test_mode,"normal game leaves sandbox")
	game.save.finish_writes()
	var path: String=game.save.path
	game.queue_free()
	await process_frame
	await create_timer(.15).timeout
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(path+suffix): DirAccess.remove_absolute(ProjectSettings.globalize_path(path+suffix))
	print("MECHANIC UI: %d checks, 0 failures; 20 levels, native swipes, fixed edges, effects, background/resume, isolated developer tools"%checks)
	quit()
