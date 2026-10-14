extends SceneTree
const Save=preload("res://scripts/core/save_manager.gd")
const Scenarios=preload("res://tests/v0123_fx_scenarios.gd")
var game
func _initialize() -> void:call_deferred("run")
func run() -> void:
 root.size=Vector2i(540,1200);game=load("res://scenes/main.tscn").instantiate();game.production_mode=true;game.save=Save.new("user://v0123-fx-capture-only.json");game.save.data=Save.defaults();game.save.data.unlocked=250;game.save.data.settings.music=false;game.save.data.settings.sfx=false;game.save.data.settings.quality="high";root.add_child(game);await process_frame
 for kind in ["normal","four","five","bomb_normal","double","rockets","giant","storm","mirrors"]:
  var spec:=Scenarios.make(kind);game.start_level(247 if kind=="giant" else 7);game.close_goal_tip();game.board=spec.board;game.board_view.set_board(game.board);game.update_hud()
  var event: Dictionary=game.board.swap(spec.a,spec.b);assert(event.accepted);game.process_event(event)
  var found:=false
  while game.board_view.busy:
   await process_frame
   if not found and game.board_view.current.kind==("storm" if kind=="storm" else "clear") and game.board_view.age/game.board_view.duration>=.45:
    await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://build/v0123-effect-"+kind+".png");found=true
  assert(found)
 for hp in [3,2,1]:
  game.start_level(247);game.close_goal_tip();game.board.canyon.giants["44"]=hp;game.board_view.set_board(game.board);await process_frame;await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://build/v0123-giant-hp%d.png"%hp)
 game.save.finish_writes();game.queue_free();await process_frame;await process_frame;print("PASS: nine real Godot resolved effect captures");quit()
