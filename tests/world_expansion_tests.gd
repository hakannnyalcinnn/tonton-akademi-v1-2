extends SceneTree
const Catalog=preload("res://scripts/core/level_catalog.gd")
const Worlds=preload("res://scripts/core/world_catalog.gd")
const Board=preload("res://scripts/core/board.gd")
const Save=preload("res://scripts/core/save_manager.gd")
const Solver=preload("res://tests/move_solver.gd")
const Player=preload("res://scripts/generation/auto_player.gd")
var checks:=0
var failures:=0
var game
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures+=1;printerr("FAIL: "+message)
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var store=Save.new("user://v011-expansion-only.json");store.data=Save.defaults()
 # A v0.10 schema-3 profile with an embedded old active board and extra inventory survives additively.
 store.data.erase("cosmetic_rewards");store.data.unlocked=150
 store.data.results={"150":{"stars":3,"score":12000},"49":{"stars":2,"score":6500}}
 store.data.world_rewards=[1,2,3];store.data.tutorials=["goal_ice"];store.data["inventory"]={"free_power":2}
 store.data.active=Board.new(Catalog.get_level(7)).snapshot();store.data.settings.music_volume=.42
 var before: Dictionary=store.data.duplicate(true);store.flush();var loaded=Save.new(store.path)
 check(loaded.data.unlocked==151,"v10 cap expands to authored cloud entry")
 check(loaded.data.results==before.results and loaded.data.world_rewards==before.world_rewards and loaded.data.tutorials==before.tutorials,"old stars, scores, worlds and unlock markers preserved")
 check(loaded.data.active==before.active and loaded.data.inventory==before.inventory and loaded.data.settings==before.settings,"old active board, inventory and settings preserved")
 game=load("res://scenes/main.tscn").instantiate();game.save=Save.new("user://v011-ui-only.json");game.save.data=Save.defaults();game.save.data.unlocked=Catalog.count()
 game.save.data.settings.music=false;game.save.data.settings.sfx=false;root.add_child(game);await process_frame
 game.show_worlds();check(game.screen=="worlds","scrollable world screen opens")
 await process_frame
 var scroll=game.page.get_node("WorldsScroll")
 var content=scroll.get_child(0)
 check(content.get_child_count()==Worlds.playable_worlds().size(),"every authored world has a card")
 var last_card=content.get_child(content.get_child_count()-1)
 check(last_card.position.y+last_card.size.y<=scroll.size.y or content.custom_minimum_size.y>scroll.size.y,"fifth world is visible or reachable in scrollable content")
 for metadata in Worlds.playable_worlds():
  game.show_map(int((int(metadata.start)-1)/10));check(game.selected_world==int(metadata.id),"world map identity")
  check(game.map_buttons.size()==int(metadata.end)-int(metadata.start)+1 and game.map_buttons.has(int(metadata.end)),"all authored map platforms")
 for extent in [Vector2i(540,960),Vector2i(540,1170),Vector2i(540,1200)]:
  root.size=extent;game.size=Vector2(extent);game.layout_stage()
  for n in [151,161,171,181,186,200,Catalog.count()]:
   game.start_level(n);game.close_goal_tip();await process_frame
   check(game.goals_panel.targets==game.board.active_targets(),"central goals "+str(n))
   check(game.goals_panel.get_global_rect().end.y<=game.board_view.get_global_rect().position.y,"safe goal/board layout")
   for i in [0,7,64,71]:check(game.board_view.index_at(game.board_view.cell_position(i)+Vector2(28,28))==i,"unchanged edge touch coordinates")
 var actual_id:=int(game.board.level.id);game.start_level(Catalog.count()+1);check(int(game.board.level.id)==actual_id,"unprepared next level cannot open")
 for last in [200,250]:
  if last>Catalog.count():continue
  var b=Board.new(Catalog.get_level(last))
  while b.available():Player.apply(b,Solver.best_move(b))
  check(b.outcome=="won" and b.objective_stage==b.level.get("objective_stages",[]).size()-1,"multi-stage free world final "+str(last))
  game.save.complete(b);var saved: Dictionary=game.save.data.duplicate(true);game.save.complete(b)
  check(game.save.data==saved,"final rewards granted once")
  var metadata:=Worlds.get_world(Catalog.world_for(last))
  check(metadata.reward_id in game.save.data.cosmetic_rewards,"cosmetic crown granted")
  game.save.finish_writes();check(metadata.reward_id in Save.new(game.save.path).data.cosmetic_rewards,"cosmetic crown persists")
 game.save.finish_writes();game.queue_free();await process_frame;await process_frame
 print("WORLD EXPANSION: %d checks, %d failures; desktop UI and save compatibility, no Android device"%[checks,failures]);quit(int(failures>0))
