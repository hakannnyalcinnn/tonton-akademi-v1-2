extends SceneTree
const Solver = preload("res://tests/move_solver.gd")
const Save = preload("res://scripts/core/save_manager.gd")
var samples: Dictionary = {}
var game
var frame_count := 0
var running := false
var previous_frame_usec := 0
func _initialize() -> void:
	call_deferred("run")
func record(key: String, value: float) -> void:
	if not samples.has(key): samples[key] = []
	samples[key].append(value)
func _process(delta: float) -> bool:
	if running:
		var now := Time.get_ticks_usec()
		if previous_frame_usec>0: record("frame_interval_ms",float(now-previous_frame_usec)/1000)
		previous_frame_usec = now
		record("engine_delta_ms",delta*1000)
		record("process_cpu_ms", Performance.get_monitor(Performance.TIME_PROCESS) * 1000)
		record("draw_calls", Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		record("objects", Performance.get_monitor(Performance.OBJECT_COUNT))
		frame_count += 1
	return false
func run() -> void:
	game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.save = Save.new("user://visual-benchmark-only.json")
	game.save.data = Save.defaults()
	if game.save.has_method("finish_writes"):
		game.save.background_writes = true
		game.save.data.settings.quality = "performance" if "low" in OS.get_cmdline_user_args() else "balanced"
	game.save.data.unlocked = 10
	game.save.data.settings.music = false
	game.audio.apply_settings(game.save.data.settings)
	game.start_level(10)
	await create_timer(0.5).timeout
	running = true
	var successful := 0
	var cascades := 0
	for attempt in (20 if "low" in OS.get_cmdline_user_args() else 100):
		if game.board.outcome != "playing":
			game.start_level(1 + attempt % 10)
			await process_frame
		var move: Array = Solver.best_move(game.board)
		assert(not move.is_empty())
		var started := Time.get_ticks_usec()
		var event: Dictionary = game.board.swap(move[0], move[1])
		record("engine_swap_ms", float(Time.get_ticks_usec() - started) / 1000)
		assert(event.accepted)
		successful += 1
		cascades += event.cascade_count
		started = Time.get_ticks_usec()
		game.process_event(event)
		record("presentation_and_save_ms", float(Time.get_ticks_usec() - started) / 1000)
		while game.board_view.busy: await process_frame
		assert(preload("res://scripts/core/match_detector.gd").find(game.board.cells,8,9).is_empty())
	running = false
	var summary := {"successful_swaps": successful,"cascade_waves": cascades,"frames": frame_count,"renderer": RenderingServer.get_video_adapter_name(),"platform": OS.get_name(),"metrics": {}}
	for key in samples:
		var values: Array = samples[key]
		values.sort()
		var total := 0.0
		for value in values: total += value
		summary.metrics[key] = {"count": values.size(),"mean":total/values.size(),"p50":values[int((values.size()-1)*0.5)],"p95":values[int((values.size()-1)*0.95)],"max":values.back()}
	var suffix := "baseline" if "baseline" in OS.get_cmdline_user_args() else ("low-quality" if "low" in OS.get_cmdline_user_args() else "revised")
	var output := FileAccess.open("res://build/performance-"+suffix+".json",FileAccess.WRITE)
	output.store_string(JSON.stringify(summary,"  "))
	output.close()
	print(JSON.stringify(summary))
	var save_path: String = game.save.path
	if game.save.has_method("finish_writes"): game.save.finish_writes()
	if FileAccess.file_exists("res://scripts/ui/performance_metrics.gd"):
		summary["device_diagnostics"] = load("res://scripts/ui/performance_metrics.gd").report(game.save.data.settings)
	output = FileAccess.open("res://build/performance-"+suffix+".json",FileAccess.WRITE)
	output.store_string(JSON.stringify(summary,"  "))
	output.close()
	game.queue_free()
	await process_frame
	await process_frame
	for ending in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(save_path+ending): DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path+ending))
	quit()
