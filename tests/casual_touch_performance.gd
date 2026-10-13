extends SceneTree
const Save=preload("res://scripts/core/save_manager.gd")
const Solver=preload("res://tests/move_solver.gd")
const Match=preload("res://scripts/core/match_detector.gd")
const Metrics=preload("res://scripts/ui/performance_metrics.gd")
var game
var intervals: Array=[]
var last:=0
var running:=false
func _initialize() -> void:call_deferred("run")
func _process(_delta: float) -> bool:
	if running:
		var now:=Time.get_ticks_usec()
		if last>0:intervals.append(float(now-last)/1000)
		last=now
	return false
func press(index: int) -> Vector2:
	var view=game.board_view
	var pos: Vector2=view.get_global_transform_with_canvas()*(view.cell_position(index)+Vector2(28,28))
	var e:=InputEventScreenTouch.new();e.index=0;e.position=pos;e.pressed=true;root.push_input(e,true)
	return pos
func finish(start: Vector2,index: int) -> void:
	var view=game.board_view
	var pos: Vector2=view.get_global_transform_with_canvas()*(view.cell_position(index)+Vector2(28,28))
	var drag:=InputEventScreenDrag.new();drag.index=0;drag.position=pos;drag.relative=pos-start;root.push_input(drag,true)
	var release:=InputEventScreenTouch.new();release.index=0;release.position=pos;release.pressed=false;root.push_input(release,true)
func settle() -> void:
	while game.board_view.busy:await process_frame
func run() -> void:
	root.size=Vector2i(540,960)
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.save.finish_writes();game.save=Save.new("user://casual-touch-benchmark-only.json");game.save.data=Save.defaults();game.save.data.unlocked=100
	game.save.data.settings.music=false;game.save.data.settings.sfx=false;game.audio.apply_settings(game.save.data.settings)
	Metrics.reset();running=true
	var invalid_count:=0
	for attempt in 100:
		var level:=76+int(attempt/4) if "finale" in OS.get_cmdline_user_args() else 1+int(attempt/10)
		if attempt%(4 if "finale" in OS.get_cmdline_user_args() else 10)==0 or game.board.outcome!="playing":game.start_level(level);await process_frame
		if attempt%10==0:
			for i in 71:
				if i%8<7 and game.board.cells[i].p=="" and game.board.cells[i+1].p=="" and not Match.can_swap(game.board.cells,i,i+1,8,9):
					var moves: int=game.board.moves;var score: int=game.board.score
					finish(press(i),i+1);await settle()
					assert(game.board.moves==moves and game.board.score==score);invalid_count+=1;break
		var pair: Array=Solver.best_move(game.board);assert(not pair.is_empty())
		var moves: int=game.board.moves
		var start:=press(pair[0]);await process_frame;await RenderingServer.frame_post_draw
		finish(start,pair[1]);assert(game.board.moves==moves-1)
		var snapshot: Dictionary=game.board.snapshot();finish(press(pair[0]),pair[1]);assert(game.board.snapshot()==snapshot)
		await settle();assert(Match.find(game.board.cells,8,9).is_empty())
	running=false
	intervals.sort();var total:=0.0
	for value in intervals:total+=value
	var result: Dictionary={"native_valid_swipes":100,"blocked_duplicates":100,"invalid_swaps":invalid_count,"levels":25 if "finale" in OS.get_cmdline_user_args() else 10,"frame_interval_ms":{"count":intervals.size(),"mean":total/intervals.size(),"p95":intervals[int((intervals.size()-1)*.95)],"max":intervals.back()},"diagnostics":Metrics.report(game.save.data.settings)}
	var file:=FileAccess.open("res://build/package5-native-touch.json",FileAccess.WRITE);file.store_string(JSON.stringify(result,"  "));file.close()
	var path: String=game.save.path
	game.save.finish_writes();game.audio._notification(Node.NOTIFICATION_APPLICATION_PAUSED);await create_timer(.25).timeout
	game.queue_free();await process_frame;await process_frame
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(path+suffix):DirAccess.remove_absolute(ProjectSettings.globalize_path(path+suffix))
	print("CASUAL RENDER TOUCH: 100 valid, 100 blocked duplicate, %d invalid; 25 new levels when --finale; stable boards"%invalid_count);quit()
