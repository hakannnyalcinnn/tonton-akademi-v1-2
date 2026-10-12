extends SceneTree

func _initialize() -> void:
	call_deferred("capture")

func snapshot(file_name: String) -> void:
	await create_timer(0.12).timeout
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var error := image.save_png("res://build/" + file_name + ".png")
	assert(error == OK)
	print("Screenshot: " + file_name)

func capture() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://build"))
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.save = preload("res://scripts/core/save_manager.gd").new("user://capture-only.json")
	game.save.data = game.save.defaults()
	game.save.data.settings.music = false
	game.audio.apply_settings(game.save.data.settings)
	game.show_home()
	await create_timer(0.5).timeout
	await snapshot("home")
	game.save.data.unlocked = 10
	game.start_level(6)
	await snapshot("game")
	game.show_map()
	await snapshot("map")
	game.show_settings()
	await snapshot("settings")
	game.start_level(1)
	while game.board.outcome == "playing":
		var move: Array = preload("res://tests/move_solver.gd").best_move(game.board)
		game.on_swap(move[0],move[1])
		while game.board_view.busy: await process_frame
	await snapshot("victory")
	for height in [1170,1200]:
		root.size = Vector2i(540,height)
		root.content_scale_size = Vector2i(540,960)
		root.content_scale_mode = Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
		root.content_scale_aspect = Window.CONTENT_SCALE_ASPECT_EXPAND
		await create_timer(.2).timeout
		game.start_level(6)
		print("Viewport extent: ",root.size," / ",game.size," / ",game.stage.size)
		await snapshot("game_"+str(height))

	var save_path: String = game.save.path
	game.queue_free()
	await process_frame
	await process_frame
	await create_timer(0.15).timeout
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(save_path + suffix): DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path + suffix))
	quit()
