extends SceneTree
const Save=preload("res://scripts/core/save_manager.gd")
var game
func _initialize() -> void:call_deferred("run")
func run() -> void:
 root.size=Vector2i(540,960)
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game)
 game.save.finish_writes();game.save=Save.new("user://gameplay2-before-match-capture.json" if "before" in OS.get_cmdline_user_args() else "user://gameplay2-match-capture.json");game.save.data=Save.defaults();game.save.data.unlocked=100
 game.save.data.settings.music=false;game.save.data.settings.sfx=false;game.audio.apply_settings(game.save.data.settings);await process_frame
 var prefix: String="before-" if "before" in OS.get_cmdline_user_args() else ""
 for kind in ["match3","match4","match5","prism-birth"]:
  game.start_level(7);game.close_goal_tip()
  for i in 72:game.board.cells[i].c=(i%8+int(i/8))%5;game.board.cells[i].p=""
  game.board.refill_stream.clear()
  var source:=10;var target:=2
  if kind=="prism-birth":
   for i in [1,8,10,17,25]:game.board.cells[i].c=0
   game.board.cells[9].c=1;game.board.cells[33].c=2;source=1;target=9
  else:
   for i in [0,1]:game.board.cells[i].c=0
   game.board.cells[2].c=1;game.board.cells[10].c=0
   if kind in ["match4","match5"]:game.board.cells[3].c=0
   if kind=="match5":game.board.cells[4].c=0;game.board.cells[5].c=2
  assert(game.board.find_matches().is_empty())
  game.board_view.set_board(game.board);game.on_swap(source,target)
  var captured:=false
  while game.board_view.busy:
   var view=game.board_view
   if not captured and view.current.get("kind","")=="clear" and view.age/view.duration>.54:
    captured=true;await RenderingServer.frame_post_draw
    root.get_texture().get_image().save_png("/workspace/tonton-akademi-v1-2/build/gameplay2-"+prefix+kind+".png")
   await process_frame
  assert(captured)
 game.save.finish_writes();game.audio._notification(Node.NOTIFICATION_APPLICATION_PAUSED);await create_timer(.25).timeout
 game.queue_free();await process_frame;await process_frame;quit()
