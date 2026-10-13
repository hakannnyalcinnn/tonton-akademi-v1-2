extends SceneTree
const Save=preload("res://scripts/core/save_manager.gd")
const Solver=preload("res://tests/move_solver.gd")
const Match=preload("res://scripts/core/match_detector.gd")
const Metrics=preload("res://scripts/ui/performance_metrics.gd")
var game
var rows: Array=[]
func _initialize() -> void:call_deferred("run")
func run() -> void:
 root.size=Vector2i(540,960)
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 game.save.finish_writes();game.save=Save.new("user://gameplay2-perf-only.json");game.save.data=Save.defaults();game.save.data.unlocked=100;game.save.background_writes=true
 game.save.data.settings.music=false;game.save.data.settings.sfx=false;game.audio.apply_settings(game.save.data.settings)
 var combinations=[["rocket_h","rocket_v"],["rocket_h","prism"],["prism","prism"],["color","rocket_h"],["color","prism"],["color","color"]]
 for quality in ["balanced","performance"]:
  game.save.data.settings.quality=quality
  for repetition in 2:
   for combo in combinations:
    game.start_level(7);game.close_goal_tip();game.board.level.targets={"total":100000}
    game.board.cells[0].p=combo[0];game.board.cells[1].p=combo[1];game.board.energy=1;game.board_view.set_board(game.board)
    await create_timer(.15).timeout;Metrics.reset()
    var started:=Time.get_ticks_usec();var e: Dictionary=game.board.swap(0,1);var logic_ms:=float(Time.get_ticks_usec()-started)/1000
    game.process_event(e);var frames:=0;var first:=Time.get_ticks_usec();var durations: Array=[]
    while game.board_view.busy and frames<2000:
     await process_frame;var now:=Time.get_ticks_usec();durations.append(float(now-first)/1000);first=now;frames+=1
    assert(frames<2000 and game.board.find_matches().is_empty() and not e.cascade_guard)
    durations.sort();var total:=0.0
    for dt in durations:total+=dt
    rows.append({"quality":quality,"combo":e.combo_kind,"repeat":repetition,"logic_ms":logic_ms,"storm":e.storm,"crystal_wave":e.crystal_wave,"cascades":e.cascade_count,"frame_samples":durations.size(),"mean_frame_ms":total/durations.size(),"p95_frame_ms":durations[int((durations.size()-1)*.95)],"max_frame_ms":durations.back(),"diagnostics":Metrics.report(game.save.data.settings),"effect_nodes":game.board_view.get_child_count(),"pool_slots":game.board_view.particle_positions.size()})
    print("EFFECT PROFILE ",quality," ",e.combo_kind," ",logic_ms," ms; ",frames," frames")
 var file:=FileAccess.open("res://build/gameplay2-effects-performance.json",FileAccess.WRITE);file.store_string(JSON.stringify({"platform":OS.get_name(),"renderer":RenderingServer.get_video_adapter_name(),"android_device_tested":false,"llvmpipe_thread_limit":OS.get_environment("LP_NUM_THREADS"),"source":"Godot 4.6.3 --profiling, Xvfb :99, 540x960, max-fps 60","scenarios":rows},"  "));file.close()
 game.save.finish_writes();game.audio._notification(Node.NOTIFICATION_APPLICATION_PAUSED);await create_timer(.25).timeout;game.queue_free();await process_frame;await process_frame;quit()
