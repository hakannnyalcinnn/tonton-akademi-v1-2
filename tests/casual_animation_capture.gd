extends SceneTree
const Save=preload("res://scripts/core/save_manager.gd")
var game
var frame:=0
func _initialize() -> void:call_deferred("run")
func record() -> void:
	await RenderingServer.frame_post_draw
	assert(root.get_texture().get_image().save_png("res://build/casual-animation/frame-%04d.png"%frame)==OK);frame+=1
func run() -> void:
	root.size=Vector2i(540,960)
	DirAccess.make_dir_recursive_absolute("res://build/casual-animation")
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.save.finish_writes();game.save=Save.new("user://casual-animation-only.json");game.save.data=Save.defaults();game.save.data.unlocked=75
	game.save.data.settings.music=false;game.save.data.settings.sfx=false;game.audio.apply_settings(game.save.data.settings)
	for number in [1,3,5,9]:
		game.start_level(number);await process_frame
		for i in 6:await record()
		var pair: Array=game.board.level.tutorial_swap
		game.on_swap(pair[0],pair[1])
		while game.board_view.busy:await record()
		for i in 6:await record()
	# Actual color bomb activation on an isolated laboratory board.
	game.start_mechanic_test();game.board.cells[27].p="color";game.board_view.set_board(game.board)
	game.perform_special(27,0)
	while game.board_view.busy:await record()
	game.save.finish_writes();game.audio._notification(Node.NOTIFICATION_APPLICATION_PAUSED);await create_timer(.25).timeout
	game.queue_free();await process_frame;await process_frame
	print("CASUAL ANIMATION: %d real rendered frames; normal, four, five, combo, color bomb"%frame);quit()
