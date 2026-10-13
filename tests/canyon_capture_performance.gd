extends SceneTree
const Save=preload("res://scripts/core/save_manager.gd")
const Solver=preload("res://tests/move_solver.gd")
const Metrics=preload("res://scripts/ui/performance_metrics.gd")
var game
var captures: Dictionary={}
var make_captures:=true
var quality:="balanced"
var actions:=0
var frames:=0
var max_memory:=0
func _initialize() -> void:call_deferred("run")
func capture(name: String) -> void:
 if not make_captures:return
 await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://build/canyon-"+name+".png")
func run() -> void:
 var args:=OS.get_cmdline_user_args()
 if not args.is_empty():quality=str(args[0])
 if args.size()>1:make_captures=str(args[1])!="no-captures"
 root.size=Vector2i(540,960)
 game=load("res://scenes/main.tscn").instantiate();game.save=Save.new("user://canyon-render-only.json");game.save.data=Save.defaults();game.save.data.unlocked=150
 game.save.data.settings.quality=quality
 game.save.data.settings.music=false;game.save.data.settings.sfx=false
 root.add_child(game);await process_frame
 game.show_worlds();await capture("worlds")
 game.show_map(10);await capture("map")
 for height in [960,1170,1200]:
  root.size=Vector2i(540,height);game.size=Vector2(540,height);game.start_level(150);game.close_goal_tip();game.layout_stage();await capture("core-board-"+str(height))
 root.size=Vector2i(540,960);game.size=Vector2(540,960);game.layout_stage();Metrics.reset()
 for number in [101,109,111,121,136,141,150]:
  game.start_level(number);game.close_goal_tip();await capture("board-"+str(number))
  for step in (32 if number==150 else 5):
   if not game.board.available():break
   var move:=Solver.best_move(game.board)
   var started:=Time.get_ticks_usec()
   game.on_swap(move[0],move[1]);Metrics.elapsed("player_action_total",started);actions+=1
   var waiting:=0
   while game.board_view.busy and waiting<1800:
    waiting+=1;frames+=1;await process_frame
    max_memory=maxi(max_memory,int(Performance.get_monitor(Performance.MEMORY_STATIC)))
    var v=game.board_view
    var key: String=str(v.current.get("kind",""))
    if v.age/v.duration>.5:
     if key=="magnet" and not captures.has(key):captures[key]=true;await capture(key)
     for e in v.current.get("canyon_events",[]):
      var label: String=str(e.kind)+("-break" if e.get("hp",1)==0 or e.get("opened",false) else "-hit")
      if not captures.has(label):captures[label]=true;await capture(label)
   if waiting>=1800:printerr("ANIMATION TIMEOUT");quit(1);return
  game.close_overlay()
 # A real no-move board exercises production free shuffle and presentation.
 game.start_level(62);game.close_goal_tip()
 for i in 72:game.board.cells[i]={"id":i+1,"c":(i%8+int(i/8)*2)%5,"p":""}
 game.board_view.set_board(game.board);game.board.frames.clear();game.board.ensure_move();game.board.finish_if_needed()
 game.board_view.animate({"frames":game.board.frames.duplicate()})
 while game.board_view.busy:
  await process_frame;frames+=1
  if game.board_view.age/game.board_view.duration>.5 and not captures.has("shuffle"):captures.shuffle=true;await capture("shuffle")
 var report:=Metrics.report(game.save.data.settings);report["actions"]=actions;report["observed_frames"]=frames;report["memory_peak_bytes"]=max_memory;report["captures"]=captures;report["real_android_device"]=false;report["png_captures_enabled"]=make_captures
 var f=FileAccess.open("res://build/canyon-performance-"+quality+("" if make_captures else "-clean")+".json",FileAccess.WRITE);f.store_string(JSON.stringify(report,"  "))
 game.save.finish_writes();game.queue_free();await process_frame;await process_frame
 print("CANYON RENDER: ",actions," actions, ",frames," frames, capture keys ",captures.keys());quit()
