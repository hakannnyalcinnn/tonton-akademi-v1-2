extends SceneTree
var game
var pixel_checks:=0
func _initialize() -> void: call_deferred("run")
func snapshot(name: String) -> void:
	await create_timer(.15).timeout
	await RenderingServer.frame_post_draw
	check_image(name)
func check_image(name: String) -> void:
	var image:=root.get_texture().get_image()
	# A previously clipped ruby atlas region must remain visibly readable beside locks.
	if game.screen=="game" and not game.board_view.busy and game.overlay==null:
		for i in 72:
			var cell: Dictionary=game.board.cells[i]
			if cell.c!=0 or cell.get("fixed",false) or cell.p!="": continue
			var origin: Vector2=game.board_view.get_global_transform_with_canvas()*game.board_view.cell_position(i)
			var extent: Vector2=game.board_view.get_global_transform_with_canvas().get_scale()*Vector2(56,56)
			var coverage:=0
			for x in range(int(origin.x),int(origin.x+extent.x)):
				for y in range(int(origin.y),int(origin.y+extent.y)):
					var color:=image.get_pixel(x,y)
					if color.r>.35 and color.r>color.g*1.3 and color.r>color.b*1.03: coverage+=1
			assert(coverage>120,"Ruby visibility regression at cell %d: %d red pixels"%[i,coverage])
			pixel_checks+=1
	assert(image.save_png("res://build/"+name+".png")==OK)
	print("Captured ",name," ",image.get_size())
func run() -> void:
	game=load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.save.finish_writes()
	game.save=load("res://scripts/core/save_manager.gd").new("user://mechanic-capture-only.json")
	game.save.data=game.save.defaults()
	game.save.data.unlocked=30
	game.save.data.settings.music=false
	game.audio.apply_settings(game.save.data.settings)
	for n in [11,16,21,26,30]:
		game.start_level(n)
		await snapshot("mechanic-level-"+str(n))
	game.show_map(2)
	await snapshot("mechanic-map")
	game.start_mechanic_test()
	game.show_mechanic_test_tools()
	await snapshot("mechanic-laboratory")
	game.close_overlay()
	# Show all durability states without changing production level data.
	for hp in [2,1]:
		game.test_index=24+hp
		game.add_test_mechanic("seed")
		game.board.cells[24+hp].obstacle.hp=hp
		game.test_index=32+hp
		game.add_test_mechanic("ice")
		game.board.cells[32+hp].armor.hp=hp
	for hp in [3,2,1]:
		game.test_index=40+hp
		game.add_test_mechanic("stone")
		game.board.cells[40+hp].obstacle.hp=hp
	for color in 5:
		game.test_index=56+color
		game.add_test_mechanic("lock")
		game.board.cells[56+color].obstacle.color=color
		game.board.cells[56+color].obstacle.energy=color*3
	game.board_view.set_board(game.board)
	await snapshot("mechanic-all-states")
	# Capture a flower-opening transaction at the midpoint of its clear animation.
	game.start_level(11)
	var event: Dictionary=game.board.swap(1,9)
	game.process_event(event)
	while game.board_view.busy:
		if game.board_view.current.get("kind","")=="clear":
			var opened:=false
			for effect in game.board_view.current.get("mechanics",[]): opened=opened or effect.opened
			if opened and game.board_view.age>.06:
				await RenderingServer.frame_post_draw
				check_image("mechanic-flower-opening")
				break
		await process_frame
	game.show_home()
	for height in [1170,1200]:
		root.size=Vector2i(540,height)
		root.content_scale_size=Vector2i(540,960)
		root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
		root.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_EXPAND
		await create_timer(.2).timeout
		game.start_level(30)
		await snapshot("mechanic-level-30-"+str(height))
	game.save.finish_writes()
	var path: String=game.save.path
	game.queue_free()
	await process_frame
	await create_timer(.15).timeout
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(path+suffix): DirAccess.remove_absolute(ProjectSettings.globalize_path(path+suffix))
	print("RENDER PIXEL CHECKS: ",pixel_checks," ruby visibility assertions, 0 failures")
	quit()
