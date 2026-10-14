extends SceneTree
const Save=preload("res://scripts/core/save_manager.gd")
const Metrics=preload("res://scripts/ui/performance_metrics.gd")
var game
func _initialize() -> void:call_deferred("run")
func capture(name: String) -> void:
	await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/v012-"+name+".png")
func run() -> void:
	root.size=Vector2i(540,960)
	game=load("res://scenes/main.tscn").instantiate();game.save=Save.new("user://v012-capture-only.json");game.save.data=Save.defaults();game.save.data.unlocked=250
	game.save.data.settings.music=false;game.save.data.settings.sfx=false;root.add_child(game);await process_frame
	game.show_map(0);await create_timer(.3).timeout;await capture("map")
	game.request_level(12);await capture("preflight");game.close_overlay()
	game.start_level(12);game.close_goal_tip();await capture("rescue")
	game.start_level(35);game.close_goal_tip();await capture("boss")
	game.start_level(7);game.close_goal_tip();game.board.level.targets={"total":100000}
	game.board.cells[0].p="color";game.board.cells[1].p="color";game.board_view.set_board(game.board)
	Metrics.reset();var event: Dictionary=game.board.swap(0,1);game.process_event(event)
	await create_timer(.27).timeout;await capture("double-bomb")
	var count:=0
	while game.board_view.busy and count<1000:await process_frame;count+=1
	assert(count<1000 and game.board.find_matches().is_empty())
	var report:=Metrics.report(game.save.data.settings);report.android_device_tested=false;report.source="Godot --profiling / Xvfb llvmpipe desktop"
	var file:=FileAccess.open("res://build/v012-performance.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "));file.close()
	game.close_overlay();game.show_adventure_menu(1);await capture("collection")
	game.close_overlay();game.start_level(20);game.board.outcome="won";game.earned_treasure=true;game.show_result();await create_timer(.45).timeout;await capture("treasure")
	game.save.finish_writes();game.queue_free();await process_frame;await process_frame
	print("V012 CAPTURE: PASS; desktop renderer, no Android device");quit()
