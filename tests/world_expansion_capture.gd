extends SceneTree
const Save=preload("res://scripts/core/save_manager.gd")
const Solver=preload("res://tests/move_solver.gd")
const Metrics=preload("res://scripts/ui/performance_metrics.gd")
var game
var make_captures:=true
var frames:=0
var actions:=0
var max_process:=0.0
func _initialize() -> void:call_deferred("run")
func capture(name: String) -> void:
 if not make_captures:return
 await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://build/v011-"+name+".png")
func run() -> void:
 make_captures=not OS.get_cmdline_user_args().has("no-captures")
 root.size=Vector2i(540,960)
 game=load("res://scenes/main.tscn").instantiate();game.save=Save.new("user://v011-render-only.json");game.save.data=Save.defaults();game.save.data.unlocked=250
 game.save.data.settings.music=false;game.save.data.settings.sfx=false;root.add_child(game);await process_frame
 game.show_worlds();await capture("worlds")
 game.show_map(15);await capture("cloud-map")
 game.show_map(20);await capture("lava-map")
 for n in [161,171,200,221,231,250]:
  game.start_level(n);game.close_goal_tip();await capture("board-"+str(n))
 for height in [1170,1200]:
  root.size=Vector2i(540,height);game.size=Vector2(540,height);game.layout_stage();await capture("ratio-"+str(height))
 if OS.get_cmdline_user_args().has("snapshots-only"):
  game.save.finish_writes();game.queue_free();await process_frame;print("WORLD SNAPSHOTS: done");quit();return
 root.size=Vector2i(540,960);game.size=Vector2(540,960);game.layout_stage();await create_timer(.3).timeout;Metrics.reset()
 for n in [161,171,200,221,231,250]:
  game.start_level(n);game.close_goal_tip()
  for step in (24 if n in [200,250] else 4):
   if not game.board.available():break
   var move:=Solver.best_move(game.board);var started:=Time.get_ticks_usec()
   game.on_swap(move[0],move[1]);Metrics.elapsed("player_action_total",started);actions+=1
   var waiting:=0
   while game.board_view.busy and waiting<1800:
    waiting+=1;frames+=1;await process_frame
    max_process=maxf(max_process,Performance.get_monitor(Performance.TIME_PROCESS)*1000)
   assert(waiting<1800 and not game.board.recovery_failed and game.board.find_matches().is_empty())
  if n in [200,250]:
   assert(game.board.outcome=="won");await capture("final-"+str(n))
  game.close_overlay()
 var report:=Metrics.report(game.save.data.settings);report["actions"]=actions;report["observed_frames"]=frames;report["max_godot_process_ms"]=max_process;report["android_device_tested"]=false;report["llvmpipe_threads"]=OS.get_environment("LP_NUM_THREADS");report["png_captures_enabled"]=make_captures;report["source"]="Godot --profiling / Xvfb llvmpipe desktop"
 var file=FileAccess.open("res://build/v011-render-performance"+("" if make_captures else "-clean-"+OS.get_environment("LP_NUM_THREADS")+"threads")+".json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "));file.close()
 game.save.finish_writes();game.queue_free();await process_frame;await process_frame
 print("WORLD RENDER: ",actions," actions, ",frames," frames; no Android device");quit()
