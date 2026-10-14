extends SceneTree
const Adventure=preload("res://scripts/core/adventure.gd")
const Progress=preload("res://scripts/core/adventure_progress.gd")
const Board=preload("res://scripts/core/board.gd")
const Catalog=preload("res://scripts/core/level_catalog.gd")
const Save=preload("res://scripts/core/save_manager.gd")
var checks:=0
var failures:=0
func check(ok: bool,message: String) -> void:
	checks+=1
	if not ok:failures+=1;push_error(message)
func _initialize() -> void:call_deferred("run")
func run() -> void:
	var definition:=Catalog.get_level(12)
	check(definition.targets.has("rescues"),"rescue is introduced in first world")
	var state:=Adventure.initial(definition)
	var collected: Dictionary={"rescues":0,"bosses":0}
	var cage=state.cages[0]
	var events:=Adventure.wave(state,[int(cage.index),int(cage.index)],{},false,collected)
	check(events.size()==1 and collected.rescues==1,"one phase damages cage once, duplicate cells do not double count")
	Adventure.wave(state,[int(cage.index)],{},false,collected)
	check(collected.rescues==1,"rescued creature is counted once")
	var boss:=Adventure.initial(Catalog.get_level(35))
	Adventure.wave(boss,[],{"0":4},false,collected)
	check(boss.boss.phase==1,"boss advances by requested colors")
	Adventure.wave(boss,[],{"2":4},false,collected)
	check(boss.boss.phase==2,"boss has deterministic phases")
	Adventure.wave(boss,[],{"0":100},false,collected)
	check(not boss.boss.defeated,"normal crystals cannot bypass final special shield")
	Adventure.wave(boss,[],{},true,collected)
	check(boss.boss.defeated and collected.bosses==1,"special power completes final boss shield")
	var data:=Save.defaults();Progress.ensure(data)
	var count: int=data.adventure_progress.inventory.rocket
	check(Progress.consume(data,"rocket") and data.adventure_progress.inventory.rocket==count-1,"only owned booster can be consumed")
	data.adventure_progress.inventory.rocket=0
	check(not Progress.consume(data,"rocket"),"empty inventory is never negative")
	var board:=Board.new(Catalog.get_level(20));board.outcome="won"
	Progress.complete(data,board,true);var coins: int=data.adventure_progress.coins
	Progress.complete(data,board,false)
	check(coins==30 and data.adventure_progress.coins==coins,"treasure rewards are exactly once")
	var d:=Progress.daily(data);d.blue=30
	check(Progress.claim_daily(data,"blue") and not Progress.claim_daily(data,"blue"),"daily reward is exactly once")
	var restore:=Board.new(definition);var snapshot:=restore.snapshot()
	check(restore.restore(snapshot),"new objective state survives canonical snapshot")
	var invalid:=snapshot.duplicate(true);invalid.adventure.cages[0].remaining=-1
	check(not restore.restore(invalid),"invalid cage state cannot load")
	var game=load("res://scenes/main.tscn").instantiate()
	game.save=Save.new("user://v012-ui-only.json");game.save.data=Save.defaults();game.save.data.settings.music=false;game.save.data.settings.sfx=false
	root.add_child(game);await process_frame
	game.request_level(1);await process_frame
	check(game.screen!="game" and game.overlay!=null,"preflight precedes board")
	check(game.selected_booster=="","preflight starts without consuming inventory")
	game.close_overlay();game.start_level(1);await process_frame
	check(game.moves_label.visible and game.moves_label.text!="","moves remain visible during goal introduction")
	var budget: int=game.board.moves
	game.production_mode=true
	game.dev_command("moves")
	check(game.board.moves==budget,"developer mutations are rejected in normal runtime")
	game.production_mode=false
	game.board.outcome="lost";game.show_result();await process_frame
	var goal_panel:=false
	for child in game.overlay.get_children():
		if child.get_script()==preload("res://scripts/ui/goals_panel.gd"):goal_panel=true
	check(goal_panel,"failure shows remaining goal icons")
	game.save.finish_writes();game.queue_free();await process_frame;await process_frame
	print("V012: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
