extends SceneTree
const Board=preload("res://scripts/core/board.gd")
const Catalog=preload("res://scripts/core/level_catalog.gd")
const Save=preload("res://scripts/core/save_manager.gd")
const Match=preload("res://scripts/core/match_detector.gd")
const Solver=preload("res://tests/move_solver.gd")
const Scenarios=preload("res://scripts/mechanics/developer_scenarios.gd")
var checks:=0
var failures:=0
var game
func check(ok: bool, message: String) -> void:
	checks+=1
	if not ok:failures+=1;printerr("FAIL: "+message)
func _initialize() -> void:call_deferred("run")
func wait_view() -> void:
	var frames:=0
	while game.board_view.busy and frames<1000:await process_frame;frames+=1
	check(frames<1000,"device animations terminate")
func swipe(source: int,destination: int) -> void:
	var v=game.board_view;var transform: Transform2D=v.get_global_transform_with_canvas()
	var start: Vector2=transform*(v.cell_position(source)+Vector2(28,28));var end: Vector2=transform*(v.cell_position(destination)+Vector2(28,28))
	var press:=InputEventScreenTouch.new();press.index=0;press.position=start;press.pressed=true;root.push_input(press,true)
	var drag:=InputEventScreenDrag.new();drag.index=0;drag.position=end;drag.relative=end-start;root.push_input(drag,true)
	press.pressed=false;press.position=end;root.push_input(press,true)
func run() -> void:
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.save.finish_writes();game.save=Save.new("user://package4-ui-only.json");game.save.data=Save.defaults()
	game.save.data.settings.music=false;game.save.data.settings.sfx=false;game.save.data.settings.reduced_motion=true
	game.audio.apply_settings(game.save.data.settings)
	check(Catalog.count()==100,"75 legacy plus 25 new real levels")
	game.show_worlds();await process_frame
	var locked:=false
	for child in game.page.get_children():
		if child is Button and "50. BÖLÜMÜ" in child.text:locked=child.disabled
	check(locked,"ocean locked before garden completion")
	ProjectSettings.set_setting("prizma/show_future_levels",false);game.show_worlds()
	check(not game.page.get_children().any(func(c):return c is Label and "76–100" in c.text),"future levels label can be hidden without inventing playable buttons")
	ProjectSettings.set_setting("prizma/show_future_levels",true)
	game.save.data.unlocked=50
	var finale=Board.new(Catalog.get_level(50));finale.outcome="won";finale.score=10000
	game.save.complete(finale)
	check(game.save.data.unlocked==51 and game.save.data.world_rewards==[1],"garden reward unlocks actual ocean")
	var copy=Save.new(game.save.path)
	check(copy.data.unlocked==51 and copy.data.world_rewards==[1],"world transition persists across process-style reload")
	game.save.data.unlocked=75
	for group in [0,4,5,6,7]:
		game.show_map(group);await process_frame
		check(game.garden.world==(1 if group<5 else 2),"map selects correct world art")
		check(game.map_buttons.size()==50,"all real world levels present on winding map")
		for n in game.map_buttons:
			check(n>=1 and n<=100 and int(game.map_buttons[n].text)==n,"map uses only real 1-100 levels")
	for n in range(51,76):
		game.start_level(n);await process_frame
		check(game.garden.world==2 and game.board.find_matches().is_empty(),"all ocean levels start stable in ocean world")
		var pair: Array=game.board.level.tutorial_swap
		check(Match.can_swap(game.board.cells,pair[0],pair[1],8,9),"ocean tutorial is a real legal swap")
		var before: int=game.board.moves
		swipe(pair[0],pair[1]);var snapshot: Dictionary=game.board.snapshot()
		check(game.board.moves==before-1 and game.board_view.busy,"native ocean tutorial commits one move")
		swipe(pair[0],pair[1]);check(game.board.snapshot()==snapshot,"duplicate native swipe rejected while busy")
		game._notification(Node.NOTIFICATION_APPLICATION_PAUSED);game.close_overlay();await wait_view()
		check(game.board.snapshot()==snapshot,"pause during cosmetic animation leaves exact logical snapshot")
		check(game.board_view.get_child_count()==6 and game.board_view.particle_positions.size()==192,"ocean pools remain fixed")
	# Every crystal center / edge direction in three actual aspect ratios, with safe-area override.
	for extent in [Vector2i(540,960),Vector2i(540,1170),Vector2i(540,1200)]:
		root.size=extent;game.size=Vector2(extent);game.safe_rect_override=Rect2(0,32,540,extent.y-62)
		game.start_level(51);await process_frame;game.layout_stage()
		var v=game.board_view
		for i in 72:check(v.index_at(v.cell_position(i)+Vector2(28,28))==i,"safe-area scaled cell centers")
		for pair in [[0,1],[7,6],[64,56],[71,63]]:
			var captures: Array=[];var callback=func(a,b):captures.append([a,b])
			v.swap_requested.disconnect(game.on_swap);v.swap_requested.connect(callback)
			swipe(pair[0],pair[1]);check(captures==[pair],"all four outside edges retain native coordinates")
			v.swap_requested.disconnect(callback);v.swap_requested.connect(game.on_swap)
	game.safe_rect_override=Rect2()
	var original: Dictionary=game.save.data.duplicate(true)
	game.start_mechanic_test()
	for kind in ["portal","vine","crate","mirror"]:
		game.add_test_mechanic(kind);await process_frame
		check(game.test_mode and game.board.level.development_only,"four dedicated developer scenes isolated")
		var e: Dictionary={}
		if kind=="portal":
			e=game.board.swap(58,66)
			check(e.accepted and game.board.movement_queue.size()>0,"portal test scene actually transfers crystal through gameplay")
		elif kind=="vine":
			for turn in 3:
				var move:=Solver.best_move(game.board);e=game.board.swap(move[0],move[1])
			check(game.board.vine_count==0,"developer vine scene counts three actual swaps")
		elif kind=="crate":
			e=game.board.activate(34);e=game.board.activate(42)
			check(game.board.collected.crates>=1,"developer crate scene can demonstrate chain")
		else:
			e=game.board.activate(18)
			check(e.accepted and e.frames.any(func(f):return f.kind=="clear" and not f.get("beams",[]).is_empty()),"mirror scene produces reflected beam animation metadata")
		game.process_event(e);await wait_view()
		check(game.board.find_matches().is_empty() and game.board_view.get_child_count()==6,"new device chain finishes stable / pooled")
		game.persist_board();check(game.save.data==original,"developer scenarios cannot change real saves")
	game.start_level(75);game.board.outcome="won";game.board.score=10000;game.show_result()
	check(game.save.data.unlocked==76 and game.save.data.world_rewards==[1],"75 challenge never grants ocean world-final reward and unlocks built 76")
	var challenge_title:=false;var next_found:=false
	for child in game.overlay.get_children():
		if child is Label and "Okyanus meydan" in child.text:challenge_title=true
		if child is Button and child.text=="SONRAKİ DÜNYA":next_found=true
	check(challenge_title and not next_found,"75 is presented as challenge, not 100 finale")
	game.show_map(5);check(game.garden.vitality>.18,"ocean restoration derived from durable completed levels")
	game.show_map(0);check(game.garden.world==1 and game.garden.vitality==1,"player returns to fully restored rewarded garden")
	game.save.finish_writes();var path: String=game.save.path
	game.audio._notification(Node.NOTIFICATION_APPLICATION_PAUSED);await create_timer(.25).timeout
	game.queue_free();await process_frame;await process_frame
	for ending in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(path+ending):DirAccess.remove_absolute(ProjectSettings.globalize_path(path+ending))
	print("PACKAGE4 UI: %d checks, %d failures; 25 tutorials, 3 ratios, four dev scenarios, world saves"%[checks,failures])
	quit(1 if failures else 0)
