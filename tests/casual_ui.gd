extends SceneTree
const Save=preload("res://scripts/core/save_manager.gd")
var game
var checks:=0
var failures:=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error(message)
func _initialize() -> void:call_deferred("run")
func run() -> void:
	game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
	game.save.finish_writes();game.save=Save.new("user://casual-ui-only.json");game.save.data=Save.defaults();game.save.data.unlocked=75
	game.save.data.settings.music=false;game.save.data.settings.sfx=false;game.audio.apply_settings(game.save.data.settings)
	game.show_map(0);await process_frame;await process_frame
	var scroll: ScrollContainer
	for child in game.page.get_children():
		if child is ScrollContainer:scroll=child
	check(scroll!=null,"map uses real vertical scroll container")
	check(game.map_buttons.size()==50,"garden has exactly 50 nodes")
	var start:=scroll.scroll_vertical
	var touch:=InputEventScreenTouch.new();touch.index=0;touch.pressed=true;touch.position=scroll.get_global_transform_with_canvas()*Vector2(200,400);root.push_input(touch,true);await process_frame
	for i in 12:
		var drag:=InputEventScreenDrag.new();drag.index=0;drag.position=touch.position-scroll.get_global_transform_with_canvas().basis_xform(Vector2(0,(i+1)*20));drag.relative=scroll.get_global_transform_with_canvas().basis_xform(Vector2(0,-20));root.push_input(drag,true);await process_frame
	touch.pressed=false;touch.position-=scroll.get_global_transform_with_canvas().basis_xform(Vector2(0,240));root.push_input(touch,true);await process_frame
	check(scroll.scroll_vertical>start+100,"native finger swipe scrolls curved map")
	check(game.screen=="map","scroll does not accidentally select a level")
	game.show_map(7);await process_frame;await process_frame
	check(game.map_buttons.size()==25,"ocean has exactly 25 nodes")
	for n in game.map_buttons:check(n>=51 and n<=75,"ocean nodes use existing levels")
	game.save.data.unlocked=1;game.show_map(0);await process_frame;await process_frame
	for node in game.map_buttons[1].get_parent().get_children():
		if node is TextureRect:check(node.size.x<=100 and node.size.y<=100,"map atlas icons honor bounds, not source texture minimum size")
	game.start_level(1);await process_frame
	check(game.star_progress.thresholds==game.board.level.stars,"star HUD uses real existing thresholds")
	var threshold: float=game.board.level.stars[1]
	game.star_progress.score=threshold-.05;game.star_progress.target=threshold;await process_frame
	check(game.star_progress.score==threshold,"earned star at exact threshold settles without fractional shortfall")
	check(game.board_view.get_child_count()==6,"effects preserve existing fixed scene pool")
	game.board.outcome="won";game.board.score=1000;game.show_result();await process_frame;await process_frame
	var result_stars:=0
	for node in game.overlay.get_children():
		if node is TextureRect:result_stars+=1;check(node.size==Vector2(66,66),"success stars fit inside result card after layout")
	check(result_stars==3,"success screen contains three real asset stars")
	var path: String=game.save.path
	game.save.finish_writes();game.audio._notification(Node.NOTIFICATION_APPLICATION_PAUSED);await create_timer(.25).timeout
	game.queue_free();await process_frame;await process_frame
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(path+suffix):DirAccess.remove_absolute(ProjectSettings.globalize_path(path+suffix))
	print("CASUAL UI: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
