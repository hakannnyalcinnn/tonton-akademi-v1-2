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
 root.size=Vector2i(540,960)
 game=load("res://scenes/main.tscn").instantiate();game.production_mode=true;game.save=Save.new("user://v0131-tests-only.json");game.save.data=Save.defaults();game.save.data.unlocked=122;game.save.data.settings.reduced_motion=true;game.save.data.settings.music=false;game.save.data.settings.sfx=false
 game.save.data.results["121"]={"score":8000,"stars":3}
 root.add_child(game);await process_frame;await process_frame
 check(game.screen=="map" and game.selected_world==3,"Startup must land on current world map")
 check(game.map_buttons.size()==50 and game.map_buttons[121].stars==3 and game.map_buttons[122].active,"Preserve stars/current level")
 check(game.find_children("*","SubViewport",true,false).is_empty(),"No planet viewport may exist")
 var before: Dictionary=game.save.data.results.duplicate(true)
 game.show_worlds();await process_frame;await process_frame
 var scroll=game.page.get_node("WorldCardsScroll");var cards=scroll.get_child(0).get_children()
 check(cards.size()==preload("res://scripts/core/world_catalog.gd").playable_worlds().size(),"Five world cards")
 for i in 5:
  check(int(cards[i].metadata.start)==i*50+1 and int(cards[i].metadata.end)==(i+1)*50,"World card ranges")
  check(cards[i].disabled==(i>=3),"World locks preserved")
  check(cards[i].get_combined_minimum_size().x<=scroll.size.x,"World card minimum width")
 game.open_world_map(4);check(game.screen=="worlds","Locked world must not open")
 game.open_world_map(2);await process_frame;await process_frame
 check(game.screen=="map" and game.selected_world==2 and game.map_buttons.size()==50,"Open world map without planet")
 check(game.save.data.results==before,"Browsing must not mutate results")
 game.show_home();await process_frame;await process_frame
 check(game.selected_world==3 and game.map_buttons[122].active,"Current level button returns to active world")
 var path=game.map_scroll.get_child(0)
 check(path.curve.point_count==51 and path.road.size()>500,"Real baked Bezier adventure road")
 var min_x:=1000.0;var max_x:=0.0
 for point in path.road:min_x=minf(min_x,point.x);max_x=maxf(max_x,point.x)
 check(max_x-min_x>250,"Wide baked S turns including Bezier extrema")
 game.map_scroll.scroll_vertical=3000;await process_frame
 var touch:=InputEventScreenTouch.new();touch.index=0;touch.pressed=true;touch.position=game.map_scroll.get_global_transform_with_canvas()*Vector2(220,400);root.push_input(touch,true)
 var drag:=InputEventScreenDrag.new();drag.index=0;drag.position=game.map_scroll.get_global_transform_with_canvas()*Vector2(220,200);root.push_input(drag,true)
 touch.pressed=false;touch.position=drag.position;root.push_input(touch,true)
 check(game.map_scroll.scroll_vertical>3000 and game.screen=="map" and game.overlay==null,"Native drag scroll must not trigger a level")
 var life=path.get_node("LivingDecor");var clock: float=life.clock
 life._process(.2);check(life.clock==clock,"Reduced motion freezes decoration animation")
 life.quiet=false;life._process(.2);check(life.clock>clock,"Animation clock advances")
 game.save.data.unlocked=250
 for world in range(1,6):
  game.open_world_map(world);await process_frame
  check(game.map_buttons.keys().min()==(world-1)*50+1 and game.map_buttons.keys().max()==world*50,"Every world has its own 50 levels")
 for last in [50,100,150,200]:
  game.save.data.unlocked=last;game.start_level(last);game.close_goal_tip();game.board.outcome="won";game.board.score=20000;game.show_result();game.save.finish_writes()
  check(game.save.data.unlocked==last+1,"World completion unlocks next level")
  game.advance_after_win(last);await create_timer(.15).timeout
  check(game.screen=="map" and game.selected_world==int(last/50)+1,"World arrival opens next map")
  check(game.overlay!=null and game.overlay.find_child("PreviewLayout",true,false)!=null,"Next world first-level preview")
  game.close_overlay()
 game.save.finish_writes();var restored=Save.new("user://v0131-tests-only.json");check(restored.load_save() and restored.data.results["121"].stars==3,"Disk reload preserves old stars")
 game.start_level(201);game.close_goal_tip();game._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST);check(game.paused,"Android back pauses")
 var actions=game.overlay.get_node("PausePanel").find_child("PauseActions",true,false);check(actions.get_child_count()==3,"Compact pause icons")
 game._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST);check(not game.paused,"Android back resumes")
 game.save.finish_writes();game.queue_free();await process_frame;await process_frame
 print(("PASS" if errors==0 else "FAIL")+" v0131: %d checks, direct map startup, five cards/locks, Bezier path, native scroll, animation settings, four world arrivals, saves/back/pause"%checks)
 quit(0 if errors==0 else 1)
