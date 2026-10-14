extends SceneTree
const Save=preload("res://scripts/core/save_manager.gd")
const Metrics=preload("res://scripts/ui/performance_metrics.gd")
var game
var prior:=0
var peak_memory:=0
var peak_nodes:=0
func _initialize() -> void:call_deferred("run")
func frame() -> void:
 await process_frame
 var now:=Time.get_ticks_usec()
 if prior>0:Metrics.record("ui_frame_interval",float(now-prior)/1000)
 prior=now;peak_memory=maxi(peak_memory,int(Performance.get_monitor(Performance.MEMORY_STATIC)));peak_nodes=maxi(peak_nodes,int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)))
func run() -> void:
 root.size=Vector2i(540,1200)
 game=load("res://scenes/main.tscn").instantiate();game.production_mode=true;game.save=Save.new("user://v0121-perf-only.json");game.save.data=Save.defaults();game.save.data.unlocked=250;game.save.data.settings.music=false;game.save.data.settings.sfx=false;root.add_child(game);await create_timer(.4).timeout
 Metrics.reset();var timings: Array=[]
 for group in [0,5,10,15,20]:
  var start:=Time.get_ticks_usec();game.show_map(group);timings.append({"operation":"world_map","group":group,"cpu_ms":float(Time.get_ticks_usec()-start)/1000});await frame();await frame()
  game.map_scroll.scroll_vertical=1300;await frame()
  var touch:=InputEventScreenTouch.new();touch.index=0;touch.pressed=true;touch.position=game.map_scroll.get_global_transform_with_canvas()*Vector2(210,420);root.push_input(touch,true)
  for i in 36:
   var drag:=InputEventScreenDrag.new();drag.index=0;drag.position=touch.position+Vector2(0,-(i+1)*8);drag.relative=Vector2(0,-8);root.push_input(drag,true);await frame()
  touch.pressed=false;touch.position+=Vector2(0,-288);root.push_input(touch,true);await frame()
  start=Time.get_ticks_usec();game.request_level(group*10+1);timings.append({"operation":"preview","group":group,"cpu_ms":float(Time.get_ticks_usec()-start)/1000})
  for i in 22:await frame()
  game.close_overlay()
 game.start_level(25);game.close_goal_tip();await frame()
 for i in 45:await frame()
 game.board.outcome="lost";game.board.moves=0;var start:=Time.get_ticks_usec();game.show_result();timings.append({"operation":"failure_popup","cpu_ms":float(Time.get_ticks_usec()-start)/1000})
 for i in 30:await frame()
 var report:=Metrics.report(game.save.data.settings);report.android_device_tested=false;report.source="Godot --profiling / Xvfb llvmpipe desktop / 540x1200; synthetic native touch";report.operation_timings=timings;report.peak_static_memory_bytes=peak_memory;report.peak_nodes=peak_nodes
 var file:=FileAccess.open("res://build/v0121-performance.json",FileAccess.WRITE);file.store_string(JSON.stringify(report,"  "));file.close()
 game.save.finish_writes();game.queue_free();await process_frame;await process_frame
 print("PASS: five map scrolls, preview, HUD and result renderer profile; no Android device");quit()
