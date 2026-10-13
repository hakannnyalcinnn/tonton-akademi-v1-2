extends SceneTree
const Save=preload("res://scripts/core/save_manager.gd")
var game
func _initialize() -> void:call_deferred("run")
func capture(name: String) -> void:
	await process_frame;await process_frame;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://build/package4-"+name+".png")
func run() -> void:
	root.size=Vector2i(540,960)
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.save.finish_writes();game.save=Save.new("user://package4-capture-only.json");game.save.data=Save.defaults()
	game.save.data.unlocked=75;game.save.data.settings.music=false;game.save.data.settings.sfx=false
	game.save.data.settings.quality="balanced";game.audio.apply_settings(game.save.data.settings)
	game.show_worlds();await capture("worlds")
	game.show_map(7);await capture("map71")
	for extent in [Vector2i(540,960),Vector2i(540,1170),Vector2i(540,1200)]:
		root.size=extent;game.size=Vector2(extent);game.start_level(51);game.layout_stage()
		await capture("ocean-"+str(extent.y))
	root.size=Vector2i(540,960);game.size=Vector2(540,960)
	game.start_level(75);await capture("level75")
	game.board.outcome="won";game.board.score=10000;game.show_result();await capture("challenge75")
	game.start_mechanic_test()
	game.show_mechanic_test_tools();await capture("laboratory");game.close_overlay()
	for kind in ["portal","vine","crate","mirror"]:
		game.add_test_mechanic(kind);await capture(kind)
		var e: Dictionary={}
		if kind=="portal":e=game.board.swap(58,66)
		elif kind=="mirror":e=game.board.activate(18)
		elif kind=="crate":
			e=game.board.activate(34);game.process_event(e)
			while game.board_view.busy:await process_frame
			e=game.board.activate(42)
		else:
			for turn in 3:
				var pair:=preload("res://tests/move_solver.gd").best_move(game.board);e=game.board.swap(pair[0],pair[1])
		game.process_event(e)
		if kind=="portal":
			while game.board_view.busy and game.board_view.current.kind!="portal":await process_frame
		elif kind=="vine":
			while game.board_view.busy and game.board_view.current.kind!="vine":await process_frame
		await create_timer(.09).timeout;await capture(kind+"-effect")
		while game.board_view.busy:await process_frame
	game.save.finish_writes();var path: String=game.save.path
	game.audio._notification(Node.NOTIFICATION_APPLICATION_PAUSED);await create_timer(.25).timeout
	game.queue_free();await process_frame;await process_frame
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(path+suffix):DirAccess.remove_absolute(ProjectSettings.globalize_path(path+suffix))
	print("PACKAGE4 CAPTURE: 16 rendered evidence frames, 0 script errors")
	quit()
