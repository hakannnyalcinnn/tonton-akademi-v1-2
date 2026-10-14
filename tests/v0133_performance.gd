extends SceneTree
const Save=preload("res://scripts/core/save_manager.gd")
var game
var results: Array=[]
func _initialize() -> void:call_deferred("run")
func run() -> void:
 root.size=Vector2i(540,960);root.content_scale_size=Vector2i(540,960)
 game=load("res://scenes/main.tscn").instantiate();game.production_mode=true;game.save=Save.new("user://v0133-perf-fixture-only.json");game.save.data=Save.defaults();game.save.data.unlocked=250;game.save.data.settings.music=false;game.save.data.settings.sfx=false
 root.add_child(game)
 for world in range(1,6):
  game.show_map((world-1)*5)
  for i in 20:await process_frame
  var times: Array[float]=[];var previous:=Time.get_ticks_usec()
  for i in 80:
   await process_frame
   var now:=Time.get_ticks_usec();times.append((now-previous)/1000.0);previous=now
  times.sort();results.append({"world":world,"samples":times.size(),"p50_ms":times[40],"p95_ms":times[76],"max_ms":times[79],"measurement":"desktop wall-frame intervals, Engine.max_fps=60; not Android or GPU timings"})
 var file:=FileAccess.open("res://build/v0133/performance.json",FileAccess.WRITE);file.store_string(JSON.stringify({"renderer":"Godot Compatibility / llvmpipe software, LP_NUM_THREADS=4","real_android_tested":false,"results":results},"  "));file.close()
 game.save.finish_writes();game.queue_free();await process_frame;await process_frame;print("PASS: five bounded desktop map performance samples recorded; no Android FPS claim");quit()
