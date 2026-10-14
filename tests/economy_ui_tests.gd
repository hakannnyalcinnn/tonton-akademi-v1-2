extends SceneTree
const S=preload("res://scripts/core/save_manager.gd")
const E=preload("res://scripts/core/economy.gd")
var game
var checks:=0
var errors:=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:errors+=1;push_error(message)
func run() -> void:
 game=load("res://scenes/main.tscn").instantiate();game.production_mode=true;game.save=S.new("user://v0140-ui-tests.json");game.save.data=S.defaults();game.save.data.unlocked=500;game.save.data.settings.reduced_motion=true;game.save.data.settings.music=false;game.save.data.settings.sfx=false;E.ensure(game.save.data);game.save.data.adventure_progress.coins=500
 root.add_child(game);await process_frame;await process_frame
 check(game.screen=="map" and game.map_buttons.size()==50,"Existing direct map startup")
 for dimensions in [Vector2i(540,960),Vector2i(390,844),Vector2i(540,1200)]:
  root.size=dimensions;root.content_scale_size=dimensions;game.layout_stage()
  for tab in ["login","missions","shop","collection","achievements"]:
   game.EconomyScreen.build(game,tab);await process_frame;await process_frame
   var panel=game.overlay.get_node("EconomyPanel");check(panel.size.x<=492 and panel.size.y<=832,"Economy panel fits responsive overlay")
   for label in panel.find_children("*","Label",true,false):check(label.get_combined_minimum_size().x<=464,"Labels fit panel width")
   check(panel.find_child("EconomyScroll",true,false) is ScrollContainer,"Long content scrolls independently of close button")
 game.close_overlay();game.save.data.economy.lives=0;game.save.data.economy.refill_at=E.now()+1800
 game.request_level(11);check(game.screen=="map" and game.life_wait_label!=null,"Zero lives blocks level preview and shows countdown")
 game.close_overlay();game.start_level(11);check(game.screen=="map","Direct gameplay admission also rejects zero lives")
 game.close_overlay();game.start_level(1);game.close_goal_tip();check(game.screen=="game" and game.board.level.id==1,"Tutorial remains playable without lives")
 game.board.outcome="won";game.board.score=1000;game.show_result();check(game.save.data.results.has("1"),"Normal result stores stars and rewards")
 game.save.data.economy.lives=5;game.save.data.economy.refill_at=0;game.start_level(11);game.close_goal_tip();game.board.outcome="lost";game.show_result();var count: int=game.save.data.economy.lives;game.show_result();check(count==4 and game.save.data.economy.lives==4,"Result overlay repeated without double life charge")
 game.save.finish_writes();game.queue_free();await process_frame;await process_frame
 print(("PASS:" if errors==0 else "FAIL:")+" %d economy UI checks"%checks);quit(0 if errors==0 else 1)
