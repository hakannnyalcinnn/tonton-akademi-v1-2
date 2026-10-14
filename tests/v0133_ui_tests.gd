extends SceneTree
const Save=preload("res://scripts/core/save_manager.gd")
var game
var checks:=0
var errors:=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:errors+=1;push_error(message)
func run() -> void:
 game=load("res://scenes/main.tscn").instantiate();game.production_mode=true;game.save=Save.new("user://v0133-ui-fixture.json");game.save.data=Save.defaults();game.save.data.unlocked=245;game.save.data.results["4"]={"stars":3,"score":4000};game.save.data.settings.reduced_motion=true;game.save.data.settings.music=false;game.save.data.settings.sfx=false
 root.add_child(game);await process_frame;await process_frame
 var preserved: Dictionary=game.save.data.results.duplicate(true)
 for dimensions in [Vector2i(540,960),Vector2i(540,1170),Vector2i(540,1200),Vector2i(320,568)]:
  root.size=dimensions;root.content_scale_size=dimensions;await process_frame
  for w in range(1,6):
   game.show_map((w-1)*5);await process_frame;await process_frame
   var terrain=game.page.get_node("MapSceneBackdrop")
   check(terrain.get_global_rect().position.distance_to(Vector2.ZERO)<.1 and terrain.get_global_rect().size.distance_to(Vector2(dimensions))<.1 and not game.garden.visible,"One shared world scene covers header/map/footer")
   check(terrain.texture!=null and terrain.texture.resource_path.ends_with("terrain-"+str(game.Worlds.get_world(w).map_style)+".png"),"Correct terrain theme")
   check(game.page.get_node("WorldsButton").icon!=null,"World button has globe icon")
   check(game.map_buttons.size()==50,"All 50 existing levels remain")
   check(terrain.road_layer.path==game.map_scroll.get_child(0) and terrain.road_layer.material==null and not terrain.road_layer.use_parent_material,"Continuous road retains its own colors outside terrain shader")
   for offset in [0,24,44,49]:
    game.map_scroll.scroll_vertical=int(game.map_scroll.get_child(0).node_position(offset).y-game.map_scroll.size.y*.5);await process_frame
    terrain.sync_canvas()
    check(is_equal_approx(terrain.material.get_shader_parameter("scroll_y"),float(game.map_scroll.scroll_vertical)),"Background uses the exact same scroll coordinate behind menus")
    check(terrain.get_parent()==game.page and terrain.get_index()==0,"Terrain is one unclipped canvas, not separate menu art")
  game.show_worlds();await process_frame;await process_frame
  var scroll=game.page.get_node("WorldCardsScroll");var cards=scroll.get_child(0).get_children()
  check(cards.size()==5,"Five world cards")
  var globe=game.page.get_node("WorldsHeaderIcon")
  check(globe.size==Vector2(42,42) and globe.position.x+globe.size.x<86,"Header globe does not overlap title or grow to source size")
  var selected:=0
  for card in cards:
   if card.selected:selected+=1
   check(card.get_combined_minimum_size().x<=scroll.size.x,"Card fits viewport width")
   var action=card.find_child("Explore",true,false)
   check(action!=null and action.size.y>=40,"Explore is a touch-sized primary action")
   for label in card.find_children("*","Label",true,false):
    check(label.get_global_rect().end.y<=card.get_global_rect().end.y+1,"Card labels remain inside card")
  check(selected==1,"Exactly one world card indicates current browsing world")
 check(game.save.data.results==preserved,"Map/card browsing does not mutate stars/results")
 game.save.finish_writes();game.queue_free();await process_frame;await process_frame
 print(("PASS:" if errors==0 else "FAIL:")+" %d checks; continuous world canvas, globe button, five themed cards, four screen sizes, preserved results"%checks)
 quit(0 if errors==0 else 1)
