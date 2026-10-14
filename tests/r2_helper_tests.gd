extends SceneTree
const Save=preload("res://scripts/core/save_manager.gd")
var game
func _initialize() -> void:call_deferred("run")
func run() -> void:
 game=load("res://scenes/main.tscn").instantiate();game.production_mode=true;game.save=Save.new("user://r2-helper-only.json");game.save.data=Save.defaults();game.save.data.unlocked=250;game.save.data.settings.music=false;game.save.data.settings.sfx=false;game.save.data.settings.reduced_motion=true;root.add_child(game);await process_frame
 game.start_level(247);game.close_goal_tip();await process_frame
 var stock: int=game.save.data.adventure_progress.inventory.rocket;var moves: int=game.board.moves;var score: int=game.board.score
 game.helper_buttons.rocket.pressed.emit();assert(game.armed_helper=="rocket")
 game.on_helper_cell(44);assert(game.save.data.adventure_progress.inventory.rocket==stock and game.armed_helper=="rocket")
 var snapshot: Dictionary=game.board.snapshot();game.on_swap(2,3);assert(game.board.snapshot()==snapshot)
 game.on_helper_cell(2);assert(game.board.cells[2].p=="rocket_h" and game.save.data.adventure_progress.inventory.rocket==stock-1 and game.board.moves==moves and game.board.score==score)
 game.on_helper_cell(3);assert(game.save.data.adventure_progress.inventory.rocket==stock-1)
 while game.board_view.busy:await process_frame
 game.helper_buttons.prism.pressed.emit();game.helper_buttons.prism.pressed.emit();assert(game.armed_helper=="")
 game.save.finish_writes();game.save.data.unlocked=1;game.start_level(1);game.close_goal_tip();await process_frame;game.helper_buttons.rocket.pressed.emit();assert(game.armed_helper=="" and game.helper_buttons.rocket.locked)
 game.save.finish_writes();game.queue_free();await process_frame;await process_frame;print("PASS: real helper placement, invalid target, drag guard, one inventory transaction, no move/score cost, cancellation and locks");quit()
