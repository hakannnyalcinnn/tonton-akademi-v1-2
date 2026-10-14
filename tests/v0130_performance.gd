extends SceneTree
const Save=preload("res://scripts/core/save_manager.gd")
var game
var rows: Array=[]
func _initialize() -> void:call_deferred("run")
func run() -> void:
 root.size=Vector2i(540,960);game=load("res://scenes/main.tscn").instantiate();game.production_mode=true;game.save=Save.new("user://v130-perf-only.json");game.save.data=Save.defaults();game.save.data.unlocked=250;game.save.data.settings.music=false;game.save.data.settings.sfx=false;root.add_child(game);await create_timer(.25).timeout
 for quality in ["balanced","performance"]:
  game.save.data.settings.quality=quality
  var began:=Time.get_ticks_usec();game.show_worlds();var build_ms:=float(Time.get_ticks_usec()-began)/1000
  for warm in 25:await process_frame
  var planet=game.planet_view;var samples: Array=[];var cpu: Array=[];var draws: Array=[];var prior:=Time.get_ticks_usec();var max_nodes:=0
  for frame in 120:
   planet.yaw+=.035;planet.globe.rotation.y=planet.yaw;planet.viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
   await process_frame;var now:=Time.get_ticks_usec();samples.append(float(now-prior)/1000);prior=now;cpu.append(Performance.get_monitor(Performance.TIME_PROCESS)*1000);draws.append(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME));max_nodes=maxi(max_nodes,int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT)))
  samples.sort();cpu.sort();draws.sort()
  began=Time.get_ticks_usec();game.show_map(0);game.show_worlds();var cached_ms:=float(Time.get_ticks_usec()-began)/1000
  rows.append({"quality":quality,"frames":120,"warmup_frames":25,"first_build_ms":build_ms,"map_and_cached_reopen_ms":cached_ms,"p95_ms":samples[114],"max_ms":samples[-1],"engine_process_p95_ms":cpu[114],"draw_calls_p95":draws[114],"max_scene_nodes":max_nodes,"viewport_pixels":str(game.planet_view.viewport.size)})
  print("PLANET PERF %s p95 %.2f ms max %.2f ms"%[quality,samples[114],samples[-1]])
 var file:=FileAccess.open("res://build/v130-performance.json",FileAccess.WRITE);file.store_string(JSON.stringify({"platform":"Actual Godot renderer, desktop Xvfb / llvmpipe software; not Android hardware","target_ms":16.7,"rows":rows},"  "));file.close()
 game.save.finish_writes();game.queue_free();await process_frame;await process_frame;print("PASS: two quality profiles, 240 actual rotating render frames and cached reopen timings measured");quit()
