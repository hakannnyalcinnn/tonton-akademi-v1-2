extends SceneTree
const Save=preload("res://scripts/core/save_manager.gd")
var game
func _initialize() -> void:call_deferred("run")
func capture(name: String) -> void:
 await process_frame;await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://build/package5-"+name+".png")
func run() -> void:
 root.size=Vector2i(540,960)
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 game.save.finish_writes();game.save=Save.new("user://package5-capture-only.json");game.save.data=Save.defaults();game.save.data.unlocked=100
 game.save.data.settings.music=false;game.save.data.settings.sfx=false;game.audio.apply_settings(game.save.data.settings)
 for n in [1,49,75,76,81,86,91,100]:
  game.start_level(n);game.close_goal_tip();await capture("goals-"+str(n))
 game.start_level(49);game.show_goal_description("stones");await capture("goal-description-highlight")
 for kind in ["fountain","bubble","conveyor","seal"]:
  game.start_mechanic_test();game.add_test_mechanic(kind);game.close_goal_tip();await capture(kind)
 for extent in [Vector2i(540,960),Vector2i(540,1170),Vector2i(540,1200)]:
  root.size=extent;game.size=Vector2(extent);game.start_level(49);game.close_goal_tip();game.layout_stage();await capture("six-goals-"+str(extent.y))
 root.size=Vector2i(540,960);game.size=Vector2(540,960);game.start_level(100);game.close_goal_tip()
 while game.board.outcome=="playing":
  var pair:=preload("res://tests/move_solver.gd").best_move(game.board);game.on_swap(pair[0],pair[1])
  while game.board_view.busy:await process_frame
  if game.board.outcome=="playing":await capture("final-stage-"+str(game.board.objective_stage+1))
 await create_timer(.5).timeout;await capture("ocean-final-win")
 game.show_map(9);await capture("map-100")
 game.save.finish_writes();game.audio._notification(Node.NOTIFICATION_APPLICATION_PAUSED);await create_timer(.25).timeout
 game.queue_free();await process_frame;await process_frame;quit()
