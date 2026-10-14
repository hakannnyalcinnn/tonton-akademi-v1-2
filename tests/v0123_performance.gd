extends SceneTree
const Save=preload("res://scripts/core/save_manager.gd")
const Scenarios=preload("res://tests/v0123_fx_scenarios.gd")
var game
var rows: Array=[]
func _initialize() -> void:call_deferred("run")
func stats(samples: Array) -> Dictionary:
 samples.sort();var sum:=0.0
 for value in samples:sum+=float(value)
 return {"frames":samples.size(),"mean_ms":sum/maxi(1,samples.size()),"p95_ms":samples[mini(samples.size()-1,int(samples.size()*.95))],"p99_ms":samples[mini(samples.size()-1,int(samples.size()*.99))],"max_ms":samples[-1]}
func run() -> void:
 root.size=Vector2i(540,1200);game=load("res://scenes/main.tscn").instantiate();game.production_mode=true;game.save=Save.new("user://v0123-perf-only.json");game.save.data=Save.defaults();game.save.data.unlocked=250;game.save.data.settings.music=false;game.save.data.settings.sfx=false;root.add_child(game);await create_timer(.35).timeout
 for quality in ["balanced","performance"]:
  game.save.data.settings.quality=quality
  for kind in ["normal","five","double","rockets","storm","giant","chain"]:
   var spec:=Scenarios.make(kind);game.start_level(247 if kind=="giant" else 7);game.close_goal_tip();game.board=spec.board;game.board_view.set_board(game.board);game.update_hud();await process_frame;await process_frame
   for warm_frame in 20:await process_frame
   var before: Dictionary=game.board.snapshot();var start:=Time.get_ticks_usec();var event: Dictionary=game.board.swap(spec.a,spec.b);var logic:=float(Time.get_ticks_usec()-start)/1000
   assert(event.accepted and not event.get("cascade_guard",false));game.process_event(event)
   var intervals: Array=[];var cpu: Array=[];var slow: Array=[];var prior:=Time.get_ticks_usec();var peak:=0;var started:=prior;var frames:=0
   while game.board_view.busy and frames<600:
    await process_frame;var now:=Time.get_ticks_usec();intervals.append(float(now-prior)/1000);prior=now;frames+=1;cpu.append(Performance.get_monitor(Performance.TIME_PROCESS)*1000)
    if intervals[-1]>25:slow.append({"ms":intervals[-1],"phase":game.board_view.current.get("kind","ready"),"pending_world_art":preload("res://scripts/ui/world_art_cache.gd").pending.size()})
    peak=maxi(peak,int(Performance.get_monitor(Performance.MEMORY_STATIC)))
   assert(frames<600 and not intervals.is_empty())
   rows.append({"scenario":kind,"quality":quality,"warm_up_frames":20,"slow_frames":slow,"frame_interval":stats(intervals),"process_cpu":stats(cpu),"logic_ms":logic,"animation_ms":float(Time.get_ticks_usec()-started)/1000,"cascade_stages":event.frames.filter(func(f):return f.kind=="clear").size(),"peak_static_bytes":peak,"particle_slots":game.board_view.particle_count})
   print("PERF %s/%s %d frames"%[kind,quality,frames])
 var file:=FileAccess.open("res://build/v0123-performance.json",FileAccess.WRITE);file.store_string(JSON.stringify({"platform":"Godot profiler / desktop Xvfb llvmpipe; not physical Android","fps_target":60,"cpu_monitor_note":"Performance.TIME_PROCESS samples are engine monitors, not precise per-frame CPU timings","rows":rows},"  "));file.close()
 game.save.finish_writes();game.queue_free();await process_frame;await process_frame;print("PASS: seven real resolved VFX scenarios x two quality profiles measured");quit()
