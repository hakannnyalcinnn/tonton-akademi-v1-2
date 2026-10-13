extends SceneTree
const Save=preload("res://scripts/core/save_manager.gd")
const Solver=preload("res://tests/move_solver.gd")
const Board=preload("res://scripts/core/board.gd")
const Catalog=preload("res://scripts/core/level_catalog.gd")
const View=preload("res://scripts/ui/board_view.gd")
var checks:=0
var game
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok:push_error(message);quit(1)
func _initialize() -> void:call_deferred("run")
func swipe(view, source: int, offset: Vector2) -> void:
	var transform: Transform2D=view.get_global_transform_with_canvas()
	var start: Vector2=transform*(view.cell_position(source)+Vector2(28,28))
	var end: Vector2=transform*(view.cell_position(source)+Vector2(28,28)+offset)
	var press:=InputEventScreenTouch.new();press.position=start;press.pressed=true;press.index=0
	root.push_input(press,true)
	var drag:=InputEventScreenDrag.new();drag.position=end;drag.relative=end-start;drag.index=0
	root.push_input(drag,true)
	press.pressed=false;press.position=end;root.push_input(press,true)
func wait_view() -> void:
	var frames:=0
	while game.board_view.busy and frames<1000:await process_frame;frames+=1
	check(frames<1000,"trait effects finish within bounded frames")
func test_coordinates() -> void:
	var b=Board.new(Catalog.get_level(31))
	var v=View.new();v.position=Vector2(32,270);v.size=Vector2(476,536)
	root.add_child(v);v.set_board(b)
	var captures: Array=[]
	v.swap_requested.connect(func(a,d):captures.append([a,d]))
	await process_frame
	for direction in ["down","up","left","right"]:
		b.direction=direction;b.cells[60]=null;b.settle();b.release_presentation();v.set_board(b)
		for i in 72:
			check(v.index_at(v.cell_position(i)+Vector2(28,28))==i,"all 72 cell centers retain coordinates")
			for axis in [Vector2(-56,0),Vector2(56,0),Vector2(0,-56),Vector2(0,56)]:
				captures.clear()
				swipe(v,i,axis)
				var inside: bool=(i%8>0 if axis.x<0 else (i%8<7 if axis.x>0 else (i>=8 if axis.y<0 else i<64)))
				check(captures.size()==(1 if inside else 0),"all four edge swipe directions after gravity")
				if inside:
					var target: int=i+(-1 if axis.x<0 else (1 if axis.x>0 else (-8 if axis.y<0 else 8)))
					check(captures[0]==[i,target],"exactly one orthogonal neighbor")
	v.queue_free();await process_frame
func run() -> void:
	await test_coordinates()
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.save.finish_writes()
	game.save=Save.new("user://package2-ui-only.json");game.save.data=Save.defaults()
	game.save.data.unlocked=50;game.save.background_writes=true
	game.save.data.settings.music=false;game.save.data.settings.reduced_motion=true
	game.audio.apply_settings(game.save.data.settings)
	for n in range(31,51):
		game.start_level(n);await process_frame
		var hint: Array=game.board.level.tutorial_swap
		check(preload("res://scripts/core/match_detector.gd").can_swap(game.board.cells,hint[0],hint[1],8,9),"tutorial is genuinely valid")
		var move:=Solver.best_move(game.board)
		var old: int=game.board.moves
		swipe(game.board_view,move[0],game.board_view.cell_position(move[1])-game.board_view.cell_position(move[0]))
		check(game.board.moves==old-1 and game.board_view.busy,"new crystal native swipe commits once")
		var settled: Dictionary=game.board.snapshot()
		swipe(game.board_view,move[0],Vector2(56,0))
		check(game.board.snapshot()==settled,"mutation animation locks duplicate move")
		game._notification(Node.NOTIFICATION_APPLICATION_PAUSED);game.close_overlay()
		await wait_view()
		check(game.board.snapshot()==settled and game.board_view.get_child_count()==6,"trait effects and resume preserve logic / fixed node count")
		check(game.board_view.trait_regions.size()==18 and game.board_view.particle_positions.size()==192,"new atlas and particles are cached and bounded")
	game.show_map(4)
	check(game.map_group==4,"all fifty levels reachable")
	var original: Dictionary=game.save.data.duplicate(true)
	game.start_mechanic_test()
	for kind in ["dual","chameleon","bridge","pin"]:
		game.test_index=27;game.add_test_mechanic(kind)
		var layer: String="armor" if kind=="pin" else "trait"
		check(game.board.cells[27][layer].kind==kind,"developer-only mechanic playable")
	game.persist_board()
	check(game.save.data==original,"developer mechanics never overwrite live progression")
	game.start_level(50);game.board.outcome="won";game.board.score=10000
	game.show_result()
	check(game.save.data.world_rewards==[1] and game.garden.vitality==1,"world finale restores garden and grants durable medal")
	var next_exists:=false
	for child in game.overlay.get_children():
		if child is Button and child.text=="SONRAKİ DÜNYA":next_exists=true
		if child is TextureRect:check(child.size==Vector2(136,136),"world medal fits its reserved card without overflowing")
	check(not next_exists,"unbuilt world fifty-one is not playable")
	game.show_result();check(game.save.data.world_rewards==[1],"reopened finale does not duplicate reward")
	game.save.finish_writes()
	var path: String=game.save.path
	game.queue_free();await process_frame;await create_timer(.15).timeout
	for ending in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(path+ending):DirAccess.remove_absolute(ProjectSettings.globalize_path(path+ending))
	print("PACKAGE2 UI: %d checks, 0 failures; all 72 cells / four gravity directions, 20 campaign levels, four developer mechanics, world finale"%checks)
	quit()
