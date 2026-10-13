extends SceneTree
const Manager=preload("res://scripts/mechanics/mechanic_manager.gd")
const Generator=preload("res://scripts/core/board_generator.gd")
var game
var pixel_checks:=0
func _initialize() -> void:call_deferred("run")
func snapshot(name: String) -> void:
	await create_timer(.15).timeout
	await RenderingServer.frame_post_draw
	var image:=root.get_texture().get_image()
	if name=="package2-level-31":
		for i in 72:
			var cell: Dictionary=game.board.cells[i]
			if cell.get("trait",{}).get("kind","")!="dual" or cell.trait.colors!=[0,1]:continue
			var origin: Vector2=game.board_view.get_global_transform_with_canvas()*game.board_view.cell_position(i)
			var red:=0;var blue:=0
			for x in range(int(origin.x),int(origin.x)+56):
				for y in range(int(origin.y),int(origin.y)+56):
					var c:=image.get_pixel(x,y)
					if c.r>.35 and c.r>c.g*1.3 and c.r>c.b*1.1:red+=1
					if c.b>.35 and c.b>c.r*1.15 and c.b>c.g*1.02:blue+=1
			assert(red>200 and blue>200,"Both dual-crystal colors must be visibly substantial")
			pixel_checks+=1
	assert(image.save_png("res://build/"+name+".png")==OK)
	print("Captured ",name," ",root.size)
func run() -> void:
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.save.finish_writes()
	game.save=load("res://scripts/core/save_manager.gd").new("user://package2-capture-only.json")
	game.save.data=game.save.defaults();game.save.data.unlocked=50
	game.save.data.settings.music=false;game.audio.apply_settings(game.save.data.settings)
	for n in [31,41,50]:
		game.start_level(n);await snapshot("package2-level-"+str(n))
	game.show_map(4);await snapshot("package2-map")
	game.start_mechanic_test();game.show_mechanic_test_tools();await snapshot("package2-laboratory");game.close_overlay()
	var specs: Array=[]
	var pairs: Array=[[0,1],[0,2],[0,3],[1,2],[1,4],[3,4]]
	for i in pairs.size():specs.append({"kind":"dual","index":16+i,"colors":pairs[i]})
	for i in 5:specs.append({"kind":"chameleon","index":32+i,"sequence":[i,(i+1)%5],"period":2})
	specs.append({"kind":"bridge","index":42});specs.append({"kind":"pin","index":48});specs.append({"kind":"pin","index":49})
	Manager.install(game.board.cells,specs)
	game.board.cells[49].armor.hp=1
	game.board.cells[33].trait.count=1
	Generator.repair_start(game.board.cells,game.board.rng,8,9)
	game.board_view.set_board(game.board)
	await snapshot("package2-crystals-and-pins")
	# Real warning/color-change playback from one successful production swap.
	game.start_level(41)
	var count:=0
	while game.board.outcome=="playing" and count<5:
		var move: Array=load("res://tests/move_solver.gd").best_move(game.board)
		game.on_swap(move[0],move[1])
		while game.board_view.busy:
			if game.board_view.current.get("kind","")=="trait" and game.board_view.age>.04:
				await RenderingServer.frame_post_draw
				assert(root.get_texture().get_image().save_png("res://build/package2-color-transition.png")==OK)
			await process_frame
		count+=1
	game.start_level(50)
	while game.board.outcome=="playing":
		var move: Array=load("res://tests/move_solver.gd").best_move(game.board)
		game.on_swap(move[0],move[1])
		while game.board_view.busy:await process_frame
	await snapshot("package2-world-finale")
	for height in [1170,1200]:
		root.size=Vector2i(540,height);root.content_scale_size=Vector2i(540,960)
		root.content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS;root.content_scale_aspect=Window.CONTENT_SCALE_ASPECT_EXPAND
		await create_timer(.2).timeout;game.start_level(50);await snapshot("package2-level-50-"+str(height))
	game.save.finish_writes()
	var path: String=game.save.path
	# Let the dummy mixer retire WAV playback while players are still in the tree.
	game.audio._notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	await create_timer(.25).timeout
	game.queue_free();await process_frame;await create_timer(.15).timeout
	for ending in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(path+ending):DirAccess.remove_absolute(ProjectSettings.globalize_path(path+ending))
	print("PACKAGE2 PIXELS: ",pixel_checks," dual color coverage checks, 0 failures")
	quit()
