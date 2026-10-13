extends SceneTree
const Save=preload("res://scripts/core/save_manager.gd")
const Metrics=preload("res://scripts/ui/performance_metrics.gd")
func _initialize() -> void:call_deferred("run")
func run() -> void:
 root.size=Vector2i(540,960)
 var game=load("res://scenes/main.tscn").instantiate();game.save=Save.new("user://background-profile-only.json");game.save.data=Save.defaults();game.save.data.unlocked=250;game.save.data.settings.music=false;game.save.data.settings.sfx=false;game.save.data.settings.quality="balanced";root.add_child(game);await process_frame
 game.start_level(250);game.close_goal_tip()
 var candidate=game.garden.backdrop.material.shader
 var baseline:=Shader.new();baseline.code=FileAccess.get_file_as_string("res://tests/fixtures/v010-background.gdshader")
 var rows: Array=[]
 for shader in [baseline,candidate]:
  game.garden.backdrop.material.shader=shader
  await create_timer(1).timeout;Metrics.reset();await create_timer(4).timeout
  var report:=Metrics.report(game.save.data.settings);rows.append(report.metrics);print("BACKGROUND PROFILE ",rows.size(),": ",JSON.stringify(report.metrics.get("frame_interval",{})))
 var file=FileAccess.open("res://build/v011-background-comparison.json",FileAccess.WRITE);file.store_string(JSON.stringify(rows,"  "));file.close();game.save.finish_writes();game.queue_free();await process_frame;quit()
