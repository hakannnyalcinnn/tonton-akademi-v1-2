extends SceneTree
const Save=preload("res://scripts/core/save_manager.gd")
var game
var rows: Array=[]
func _initialize() -> void:call_deferred("run")
func stats(samples: Array) -> Dictionary:
 samples.sort();var total:=0.0
 for item in samples:total+=float(item)
 return {"frames":samples.size(),"mean_ms":total/samples.size(),"p95_ms":samples[int((samples.size()-1)*.95)],"p99_ms":samples[int((samples.size()-1)*.99)],"max_ms":samples[-1]}
func run() -> void:
 root.size=Vector2i(540,1200);game=load("res://scenes/main.tscn").instantiate();game.production_mode=true;game.save=Save.new("user://r2-navigation-perf-only.json");game.save.data=Save.defaults();game.save.data.unlocked=250;game.save.data.settings.music=false;game.save.data.settings.sfx=false;root.add_child(game);await process_frame
 for group in [0,5,10,15,20]:
  game.show_map(group);await create_timer(.5).timeout
  var samples: Array=[];var prior:=Time.get_ticks_usec()
  for tick in 90:
   game.map_scroll.scroll_vertical=mini(5000,tick*48);await process_frame;var now:=Time.get_ticks_usec();samples.append(float(now-prior)/1000);prior=now
  rows.append({"scenario":"world_%d_scroll"%game.selected_world,"frame_interval":stats(samples)})
 var operations: Array=[];var samples: Array=[];var prior:=Time.get_ticks_usec()
 for tick in 60:
  var started:=Time.get_ticks_usec()
  if tick%6==0:game.request_level(49)
  elif tick%6==3:game.close_overlay()
  operations.append(float(Time.get_ticks_usec()-started)/1000)
  await process_frame;var now:=Time.get_ticks_usec();samples.append(float(now-prior)/1000);prior=now
 rows.append({"scenario":"preview_open_close","frame_interval":stats(samples),"callback_ms":stats(operations)})
 var file:=FileAccess.open("res://build/r2-navigation-performance.json",FileAccess.WRITE);file.store_string(JSON.stringify({"platform":"Godot actual viewport/Xvfb llvmpipe, not Android device","rows":rows},"  "));file.close()
 game.save.finish_writes();game.queue_free();await process_frame;await process_frame;print("PASS: actual five-map scrolling and preview opening measured");quit()
