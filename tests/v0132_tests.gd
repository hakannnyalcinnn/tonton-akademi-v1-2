extends SceneTree
const Save=preload("res://scripts/core/save_manager.gd")
var game
var errors:=0
var checks:=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:errors+=1;push_error(message)
func run() -> void:
 game=load("res://scenes/main.tscn").instantiate();game.production_mode=true;game.save=Save.new("user://v0132-ui-fixture.json");game.save.data=Save.defaults();game.save.data.unlocked=250;game.save.data.settings.reduced_motion=true;game.save.data.settings.music=false;game.save.data.settings.sfx=false
 root.add_child(game);await process_frame;await process_frame
 for dimensions in [Vector2i(540,960),Vector2i(540,1170),Vector2i(540,1200)]:
  root.size=dimensions;root.content_scale_size=dimensions;await process_frame
  for world in range(1,6):
   game.save.data.active={};game.save.data.unlocked=(world-1)*50+45;game.show_map((world-1)*5);await process_frame;await process_frame
   var path=game.map_scroll.get_node("LivingAdventurePath")
   check(game.map_scroll.position.x==0 and game.map_scroll.size.x==540,"Full-width terrain in every world")
   check(game.map_scroll.position.y+game.map_scroll.size.y<=game.stage.size.y-156,"Scroll excludes fixed current-level button")
   check(game.map_buttons[(world-1)*50+45].size.x==100,"Active level enlarged without transform animation")
   for n in range((world-1)*50+1,world*50+1):
    game.map_scroll.scroll_vertical=int(path.node_position(n-(world-1)*50-1).y-game.map_scroll.size.y*.5)
    await process_frame
    var center: float=path.node_position(n-(world-1)*50-1).y-game.map_scroll.scroll_vertical
    check(center>=50 and center<=game.map_scroll.size.y-50,"Every level reachable clear of footer")
  game.save.data.unlocked=250;game.start_level(49);game.close_goal_tip();await process_frame;await process_frame;game.layout_stage()
  var goal_bottom: float=game.goals_panel.position.y+game.goals_panel.size.y
  check(game.goals_panel.position.y>=game.game_hud.position.y+game.game_hud.size.y,"HUD and goals separated")
  check(game.board_view.position.y>=goal_bottom+10,"Board clear of goals")
  check(game.board_view.position.y+game.board_view.size.y<=game.stage.size.y-158+1,"Board clear of storm/boosters")
  check(game.moves_label.is_visible_in_tree(),"Moves always visible")
  var local:=Vector2(28,28);var global_point: Vector2=game.board_view.get_global_transform_with_canvas()*local
  check((game.board_view.get_global_transform_with_canvas().affine_inverse()*global_point).distance_to(local)<.01,"Touch coordinates roundtrip without stretch")
  game.show_worlds();await process_frame;await process_frame
  var cards=game.page.get_node("WorldCardsScroll").get_child(0).get_children()
  for card in cards:
   var action=card.find_child("Explore",true,false)
   check(action!=null and action.size.y>=40,"Visible touch-sized explore button")
   check(card.size.y<175,"Compact world cards")
 game.save.finish_writes();game.queue_free();await process_frame;await process_frame
 print(("PASS" if errors==0 else "FAIL")+" v0132: %d checks; 5 worlds x 50 nodes x 3 aspect ratios, safe footer, HUD and touch transforms"%checks)
 quit(0 if errors==0 else 1)
