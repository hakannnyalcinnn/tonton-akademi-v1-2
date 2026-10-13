extends SceneTree
const Save=preload("res://scripts/core/save_manager.gd")
const Catalog=preload("res://scripts/core/level_catalog.gd")
const Board=preload("res://scripts/core/board.gd")
const Solver=preload("res://tests/move_solver.gd")
const Registry=preload("res://scripts/ui/goal_registry.gd")
var checks:=0
var failures:=0
var game
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures+=1;printerr(message)
func _initialize() -> void:call_deferred("run")
func run() -> void:
 game=load("res://scenes/main.tscn").instantiate();game.save=Save.new("user://canyon-ui-only.json");game.save.data=Save.defaults();game.save.data.unlocked=150
 game.save.data.settings.music=false;game.save.data.settings.sfx=false
 root.add_child(game);await process_frame
 for height in [960,1170,1200]:
  root.size=Vector2i(540,height);game.size=Vector2(540,height)
  for number in [101,109,111,121,136,150]:
   game.start_level(number);game.close_goal_tip();game.layout_stage();await process_frame
   check(game.goals_panel.targets==game.board.active_targets(),"central targets "+str(number))
   check(game.goals_panel.get_global_rect().end.y<=game.board_view.get_global_rect().position.y,"no panel overlap")
   for key in game.board.level.targets:
    check(Registry.icon(key)!=null,"registered icon "+key)
    game.show_goal_description(key);check(game.goal_tip!=null,"description "+key);game.close_goal_tip()
   check(game.gravity_buttons.is_empty(),"manual gravity remains removed")
 game.show_map(10);check(game.map_buttons.size()==50 and game.map_buttons.has(101) and game.map_buttons.has(150),"third world map")
 game.show_map(0);check(game.map_buttons.has(1) and game.map_buttons.has(50),"return to garden")
 game.show_map(5);check(game.map_buttons.has(51) and game.map_buttons.has(100),"return to ocean")
 var d:=Catalog.get_level(150);var b=Board.new(d)
 while b.outcome=="playing" and b.moves>0:
  var move:=Solver.best_move(b);b.swap(move[0],move[1])
 check(b.outcome=="won","real final completable with free powers")
 game.save.complete(b);var saved: Dictionary=game.save.data.duplicate(true);game.save.complete(b)
 check(game.save.data==saved and game.save.data.world_rewards==[3],"world three reward once")
 game.save.finish_writes();check(Save.new(game.save.path).data.world_rewards==[3],"reward persists")
 game.start_level(150);var snapshot: Dictionary=game.board.snapshot();var clone=Board.new(d)
 check(clone.restore(snapshot) and clone.snapshot()==snapshot,"core save round trip")
 snapshot.canyon.cores["27"].shields[0]=-1
 check(not clone.restore(snapshot),"malformed shield save rejected")
 game.save.data=Save.defaults();game.save.data.unlocked=100;game.save.data.results={"100":{"score":9000,"stars":3}};game.save.flush();game.save.finish_writes()
 var migrated=Save.new(game.save.path)
 check(migrated.data.unlocked==101 and migrated.data.results["100"].stars==3,"v09 cap expands without losing progress")
 game.save.finish_writes();game.queue_free();await process_frame
 await process_frame
 print("CANYON UI: %d checks, %d failures"%[checks,failures]);quit(int(failures>0))
