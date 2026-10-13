extends SceneTree
const Save=preload("res://scripts/core/save_manager.gd")
const Solver=preload("res://tests/move_solver.gd")
var game
func _initialize() -> void:call_deferred("run")
func capture(name: String) -> void:
 await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://build/gameplay2-"+name+".png")
func run() -> void:
 root.size=Vector2i(540,960)
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 game.save.finish_writes();game.save=Save.new("user://gameplay2-capture-only.json");game.save.data=Save.defaults();game.save.data.unlocked=100
 game.save.data.settings.music=false;game.save.data.settings.sfx=false;game.audio.apply_settings(game.save.data.settings)
 game.start_level(49);game.close_goal_tip();await capture("board")
 for extent in [Vector2i(540,1170),Vector2i(540,1200)]:
  root.size=extent;game.size=Vector2(extent);game.layout_stage();await capture("board-"+str(extent.y))
 root.size=Vector2i(540,960);game.size=Vector2(540,960);game.layout_stage()
 game.start_level(7);game.close_goal_tip();game.board.level.targets={"total":100000};game.board.energy=2
 var move:=Solver.best_move(game.board);game.on_swap(move[0],move[1])
 var kinds: Dictionary={};var timeout:=0
 while game.board_view.busy and timeout<1500:
  timeout+=1
  var v=game.board_view
  var key: String=str(v.current.get("kind",""))
  if key in ["clear","storm","crystal_wave"] and not kinds.has(key) and v.age/v.duration>.43:
   kinds[key]=true;await capture(key)
   if key=="clear" and "probe" in OS.get_cmdline_user_args():
    print("CLEAR PROBE ",v.current.removed," powers ",v.current.removed.map(func(i):return v.previous[i].p))
    var count: int=v.particle_count;v.set_process(false);v.particle_count=0;v.age=v.duration*.50;v.queue_redraw();await capture("shatter-probe");v.particle_count=count;v.set_process(true)
  await process_frame
 game.start_level(9);game.close_goal_tip();game.board.cells[0].p="color";game.board.cells[1].p="rocket_h";game.board_view.set_board(game.board)
 game.on_swap(0,1);var captured:=false
 while game.board_view.busy:
  if not captured and game.board_view.current.get("kind","")=="clear" and game.board_view.age/game.board_view.duration>.33:
   captured=true;await capture("color-rocket")
  await process_frame
 game.save.finish_writes();game.audio._notification(Node.NOTIFICATION_APPLICATION_PAUSED);await create_timer(.25).timeout
 game.queue_free();await process_frame;await process_frame;quit()
