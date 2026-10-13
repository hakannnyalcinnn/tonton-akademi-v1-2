extends SceneTree
const Board=preload("res://scripts/core/board.gd")
const Catalog=preload("res://scripts/core/level_catalog.gd")
const Solver=preload("res://tests/move_solver.gd")
const Save=preload("res://scripts/core/save_manager.gd")
var checks:=0
var failures:=0
var game
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(message)
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var d:=Catalog.get_level(100);var b=Board.new(d)
 check(b.active_targets()==d.objective_stages[0],"stage one targets from data")
 b.collected.portals=1;b.collected.total=int(d.objective_stages[0].total);b.collected["0"]=b.collected.total;b.finish_if_needed()
 check(b.objective_stage==1 and b.outcome=="playing" and b.active_targets()==d.objective_stages[1],"first stage advances without completion")
 var clone=Board.new(d);check(clone.restore(b.snapshot()) and clone.objective_stage==1,"mid-stage save restored")
 b.collected.portals=2;b.collected.vines=2;b.collected.total=int(d.objective_stages[1].total);b.collected["0"]=b.collected.total;b.finish_if_needed()
 check(b.objective_stage==2 and b.outcome=="playing" and b.active_targets()==d.targets,"second stage displays final six goals")
 b=Board.new(d)
 while b.available():
  var pair:=Solver.best_move(b);b.swap(pair[0],pair[1])
 check(b.outcome=="won" and b.objective_stage==2,"real canonical final level won via valid match-3 swaps")
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 game.save.finish_writes();game.save=Save.new("user://finale-ui-only.json");game.save.data=Save.defaults();game.save.data.unlocked=100
 game.save.data.settings.music=false;game.save.data.settings.sfx=false;game.audio.apply_settings(game.save.data.settings)
 game.start_level(100);game.close_goal_tip();game.board=b;game.board_view.set_board(b);game.update_hud();game.show_result();await process_frame
 check(game.save.data.world_rewards==[2] and game.garden.world==2 and game.garden.vitality==1,"ocean restored and own durable medal granted")
 check(game.goals_panel.targets==d.targets,"final visual target definitions")
 for key in d.targets:check(int(game.goals_panel.amounts[key])==int(d.targets[key]),"final visual counter corresponds to actual completed target "+key)
 var title_found:=false
 for child in game.overlay.get_children():
  if child is Label and child.text=="Kristal Okyanus uyandı!":title_found=true
 check(title_found,"ocean final screen uses ocean title / art")
 var snapshot: Dictionary=game.save.data.duplicate(true);game.show_result();check(game.save.data==snapshot and game.save.data.world_rewards.size()==1,"final reward is idempotent across result reopening")
 game.save.finish_writes();var saved=Save.new(game.save.path);check(saved.data.world_rewards==[2] and saved.data.results.has("100"),"reward survives disk reload")
 game.show_map(9);check(game.map_buttons.size()==50 and game.map_buttons.has(100),"full real ocean map ends at 100")
 # Legacy 75 completed profiles unlock 76 automatically, without deleting their stars/settings.
 saved.data.unlocked=75;saved.data.results["75"]={"score":4000,"stars":3};saved.flush();var migrated=Save.new(saved.path)
 check(migrated.data.unlocked==76 and migrated.data.results["75"].stars==3 and migrated.data.world_rewards==[2],"75 capped save expands additively and preserves rewards")
 game.save.finish_writes();var path: String=game.save.path;game.audio._notification(Node.NOTIFICATION_APPLICATION_PAUSED);await create_timer(.25).timeout
 game.queue_free();await process_frame;await process_frame
 for suffix in ["",".bak",".tmp"]:
  if FileAccess.file_exists(path+suffix):DirAccess.remove_absolute(ProjectSettings.globalize_path(path+suffix))
 print("FINALE UI: %d checks, %d failures; real level100 win, 3 stages, durable reward once, legacy75 migration"%[checks,failures]);quit(1 if failures else 0)
