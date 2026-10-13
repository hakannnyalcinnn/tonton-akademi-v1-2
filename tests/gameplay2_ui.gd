extends SceneTree
const Save=preload("res://scripts/core/save_manager.gd")
const Solver=preload("res://tests/move_solver.gd")
var game
var checks:=0
var failures:=0
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures+=1;printerr("FAIL: "+message)
func _initialize() -> void:call_deferred("run")
func buttons(node: Node) -> Array:
 var result: Array=[]
 if node is Button:result.append(node)
 for child in node.get_children():result.append_array(buttons(child))
 return result
func run() -> void:
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 game.save.finish_writes();game.save=Save.new("user://gameplay2-ui-only.json");game.save.data=Save.defaults();game.save.data.unlocked=100
 game.save.data.settings.music=false;game.save.data.settings.sfx=false;game.audio.apply_settings(game.save.data.settings)
 for extent in [Vector2(540,960),Vector2(540,1170),Vector2(540,1200)]:
  game.size=extent;game.start_level(49);game.close_goal_tip();game.layout_stage()
  check(game.gravity_buttons.is_empty(),"four direction controls absent")
  for button in buttons(game.page):
   check(button.text!="Nasıl oynanır?" and button.text not in ["←","→","↑","↓"],"game page contains no help or direction selection")
  check(game.storm_gauge.mouse_filter==Control.MOUSE_FILTER_IGNORE,"gauge is informational and cannot choose a direction")
  check(game.goals_panel.position.y+game.goals_panel.size.y<=game.board_view.position.y,"icon goals stay above board")
  var point: Vector2=game.board_view.get_global_transform_with_canvas()*(game.board_view.cell_position(71)+Vector2(28,28))
  check(game.board_view.index_at(game.board_view.get_global_transform_with_canvas().affine_inverse()*point)==71,"edge coordinates survive all aspects")
 game.start_level(7);game.close_goal_tip();game.board.level.targets={"total":100000};game.board.energy=3
 var pair:=Solver.best_move(game.board);var before: int=game.board.moves
 game.on_swap(pair[0],pair[1]);var metadata: Array=game.board.frames.duplicate(true)
 for i in 100:game.on_swap(pair[0],pair[1]);game.on_gravity("left")
 check(game.board.moves==before-1,"rapid inputs cannot overlap storm transaction")
 var ticks:=0
 while game.board_view.busy and ticks<1800:await process_frame;ticks+=1
 check(ticks<1800 and game.board.frames==metadata,"storm playback terminates without clearing logical event data")
 check(game.board_view.current.is_empty() and game.board_view.get_child_count()==6,"finished visual frame releases reference, pools stay fixed")
 check(game.storm_gauge.value==game.board.storm_charge(),"gauge and logical energy share final central value")
 check("gameplay2_storm" in game.save.data.tutorials,"first storm has persistent short automatic tutorial")
 game.show_settings();check(buttons(game.page).any(func(b):return b.text.contains("YARDIM")),"help remains accessible from settings")
 game.show_help();check(game.overlay_root!=null,"tutorial help remains available")
 game.close_overlay();game.save.finish_writes();game.audio._notification(Node.NOTIFICATION_APPLICATION_PAUSED);await create_timer(.25).timeout
 game.queue_free();await process_frame;await process_frame
 print("GAMEPLAY2 UI: %d checks, %d failures; no manual controls, three aspects, rapid inputs, event integrity, help"%[checks,failures])
 quit(1 if failures else 0)
