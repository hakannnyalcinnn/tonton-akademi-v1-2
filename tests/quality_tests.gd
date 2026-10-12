extends SceneTree
const Save = preload("res://scripts/core/save_manager.gd")
const Solver = preload("res://tests/move_solver.gd")
const Match = preload("res://scripts/core/match_detector.gd")
const Metrics = preload("res://scripts/ui/performance_metrics.gd")
var count := 0
func check(value: bool, message: String) -> void:
	count += 1
	if not value:
		push_error(message)
		quit(1)
func _initialize() -> void:
	call_deferred("run")
func wait_view(game) -> void:
	var frames := 0
	while game.board_view.busy and frames<1000:
		await process_frame
		frames += 1
	check(frames<1000,"bounded animation queue")
func run() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.save.finish_writes()
	game.save = Save.new("user://quality-tests-only.json")
	game.save.data = Save.defaults()
	game.save.data.unlocked = 10
	game.save.data.settings.music = false
	game.save.data.settings.quality = "high"
	game.audio.apply_settings(game.save.data.settings)
	game.save.background_writes = true
	game.start_level(7)
	var node_count: int = game.board_view.get_child_count()
	# Existing power combination receives distinct visual beams; no new mechanic.
	game.start_level(9)
	game.board_view.reduced_motion = true
	game.board.cells[0].p="rocket_h"
	game.board.cells[1].p="rocket_v"
	game.board_view.set_board(game.board)
	game.on_swap(0,1)
	await wait_view(game)
	check(Match.find(game.board.cells,8,9).is_empty(),"simultaneous rocket effects retain stable logic")
	# Full visual refill fixture, solved with the existing environmental resolver.
	game.start_level(10)
	game.board_view.reduced_motion=true
	game.board.cells.fill(null)
	game.board.frames.clear()
	game.board.settle(true)
	var refill_event: Dictionary = game.board.resolve(game.board.find_matches(),[],[],-1,-1,false,false)
	game.process_event(refill_event)
	await wait_view(game)
	check(game.board.cells.size()==72 and null not in game.board.cells,"complete refill restores 72 crystals")
	check(Match.find(game.board.cells,8,9).is_empty(),"complete refill cascades finish stable")
	game.start_level(7)
	game.board_view.reduced_motion=true
	var before: Dictionary = game.board.snapshot()
	var move: Array = Solver.best_move(game.board)
	game.on_swap(move[0],move[1])
	check(game.board.moves==before.moves-1,"successful swap spends exactly one move")
	for i in 100:
		game.on_swap(move[0],move[1])
		game.on_gravity("left")
	check(game.board.moves==before.moves-1,"100 rapid inputs cannot duplicate locked move")
	await wait_view(game)
	check(game.board_view.get_child_count()==node_count,"effect labels and backdrop remain pooled")
	check(game.board_view.particle_positions.size()==192,"particle storage stays bounded")
	check(game.board_view.textures.size()==9,"crystals and powers share cached atlas regions")
	check(Match.find(game.board.cells,8,9).is_empty(),"animated cascades end in a stable board")
	game.save.finish_writes()
	var restored := Save.new(game.save.path)
	check(restored.data.active==game.board.snapshot(),"worker saves exact settled board and RNG")
	for mode in ["high","balanced","performance","auto"]:
		game.board_view.apply_settings({"quality":mode,"reduced_effects":false})
		check(game.board_view.particle_budget()<=144,"quality particle budget bounded: "+mode)
	game.board_view.apply_settings({"quality":"high","reduced_effects":true})
	check(game.board_view.particle_budget()==24,"reduced effects overrides high quality")
	game.board_view.apply_settings({"quality":"auto","reduced_effects":false})
	game.board_view.frame_time=.04
	game.board_view.adaptive_time=4
	game.board_view._process(.04)
	check(game.board_view.quality=="performance","auto quality responds to sustained slow frames")
	for level in range(1,11):
		game.start_level(level)
		game.board_view.reduced_motion = true
		move = Solver.best_move(game.board)
		game.on_swap(move[0],move[1])
		await wait_view(game)
		check(Match.find(game.board.cells,8,9).is_empty(),"all ten levels stable with revised view: "+str(level))
	game.start_level(10)
	game.board_view.reduced_motion=true
	for direction in ["left","up","right","down"]:
		game.board.energy=2
		game.on_gravity(direction)
		await wait_view(game)
		check(game.board.direction==direction,"visual gravity: "+direction)
		check(Match.find(game.board.cells,8,9).is_empty(),"gravity leaves no ready match")
	game.on_swap(0,1)
	game._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	check(game.paused,"background pauses presentation")
	game.close_overlay()
	await wait_view(game)
	check(game.board.state!=game.board.State.PAUSED,"resume releases state")
	# Use the same layout function as native safe-area handling, without relying on a real notch.
	for aspect in [16.0/9,19.5/9,20.0/9]:
		var extent := Vector2(540,540*aspect)
		game.safe_rect_override = Rect2(Vector2(0,24),extent-Vector2(0,48))
		game.size=extent
		game.layout_stage()
		check(is_equal_approx(game.stage.scale.x,game.stage.scale.y),"aspect never stretches jewels")
		var view = game.board_view
		var global_point: Vector2 = view.get_global_transform_with_canvas()*(view.cell_position(35)+Vector2(28,28))
		var local_point: Vector2 = view.get_global_transform_with_canvas().affine_inverse()*global_point
		check(view.index_at(local_point)==35,"touch mapping survives aspect and inset")
		check(view.position.y+536<=game.hint_label.position.y,"board and footer remain separate")
	# A pathological external refill stream must produce a logged, stable recovery.
	var guard_board = preload("res://scripts/core/board.gd").new(preload("res://scripts/core/level_catalog.gd").get_level(10))
	for cell in guard_board.cells: cell.c=0; cell.p=""
	guard_board.refill_stream.resize(10000)
	guard_board.refill_stream.fill(0)
	var incident_count: int = Metrics.incidents.size()
	var guard_event: Dictionary = guard_board.resolve(guard_board.find_matches(),[],[],-1,-1,false,false)
	check(guard_event.cascade_guard,"pathological refill triggers cascade guard")
	check(Metrics.incidents.size()>incident_count,"cascade cause is logged instead of hidden")
	check(Match.find(guard_board.cells,8,9).is_empty() and Match.has_move(guard_board.cells,8,9),"cascade guard recovers to a playable stable board")
	game.show_settings()
	var page_id: int = game.page.get_instance_id()
	game.set_quality("performance")
	check(game.page.get_instance_id()==page_id,"quality changes do not rebuild settings scene")
	game.toggle_setting("shake")
	check(game.page.get_instance_id()==page_id,"toggle does not rebuild settings scene")
	var diagnostic: Dictionary = Metrics.report(game.save.data.settings)
	check(diagnostic.display.refresh_rate_hz==null or is_finite(diagnostic.display.refresh_rate_hz),"unsupported refresh rate is explicit null, not NaN")
	game.show_diagnostics()
	check(game.overlay_root.size==game.stage.size,"overlay covers expanded safe area")
	game.close_overlay()
	game.save.finish_writes()
	var path: String = game.save.path
	game.queue_free()
	await process_frame
	await process_frame
	await create_timer(.15).timeout
	# Older schema-2 saves gain additive options without deleting progress.
	var old := Save.defaults()
	for key in ["quality","shake","reduced_effects","music_volume","sfx_volume"]: old.settings.erase(key)
	var file := FileAccess.open(path,FileAccess.WRITE)
	file.store_string(JSON.stringify(old))
	file.close()
	var migrated := Save.new(path)
	check(migrated.data.settings.quality=="auto" and migrated.data.unlocked==old.unlocked,"old v2 settings preserved and extended")
	for ending in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(path+ending): DirAccess.remove_absolute(ProjectSettings.globalize_path(path+ending))
	print("QUALITY TEST RESULT: %d assertions, 0 failures; pooling, worker saves, rapid inputs, 10 levels, 4 gravities, 3 aspect ratios, pause/resume" % count)
	quit()
