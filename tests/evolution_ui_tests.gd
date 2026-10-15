extends SceneTree
const S=preload("res://scripts/core/save_manager.gd")
var game
var checks:=0
var errors:=0
func _initialize() -> void:call_deferred("run")
func check(value: bool,message: String) -> void:
 checks+=1
 if not value:errors+=1;push_error(message)
func gesture(scroll,from: Vector2,to: Vector2) -> void:
 var press:=InputEventScreenTouch.new();press.index=0;press.pressed=true;press.position=from;scroll._input(press)
 var drag:=InputEventScreenDrag.new();drag.index=0;drag.position=to;drag.relative=to-from;scroll._input(drag)
 var release:=InputEventScreenTouch.new();release.index=0;release.pressed=false;release.position=to;scroll._input(release)
func run() -> void:
 root.size=Vector2i(540,1170);root.content_scale_size=root.size
 game=load("res://scenes/main.tscn").instantiate();game.production_mode=true;game.save=S.new("user://v0141-ui.json");game.save.data=S.defaults();game.save.data.unlocked=65;game.save.data.settings.music=false;game.save.data.settings.sfx=false;game.save.data.settings.reduced_motion=true
 root.add_child(game);await process_frame;await process_frame
 var map=game.map_scroll;var point: Vector2=map.get_global_transform_with_canvas()*Vector2(250,300)
 gesture(map,point,point+Vector2(0,140));game.map_buttons[65].pressed.emit()
 check(game.overlay==null and not map.may_select(),"Map drag cannot open a level even on delayed button release")
 var touch:=InputEventScreenTouch.new();touch.pressed=true;touch.position=point;touch.index=0;map._input(touch);touch.pressed=false;map._input(touch);game.map_buttons[65].pressed.emit()
 check(game.overlay==null,"First touch stops inertia without opening a level")
 touch.pressed=true;map._input(touch);touch.pressed=false;map._input(touch);game.map_buttons[65].pressed.emit()
 check(game.overlay!=null and int(game.overlay.get_meta("preview_level"))==65,"Fresh short release tap opens chosen unlocked level after scrolling")
 game.close_overlay();var resume: Button=game.page.get_node("CurrentLevelButton");check(resume.text=="KALDIĞIM YERDEN BAŞLA","Continue button caption fits requested action")
 resume.pressed.emit();check(game.overlay!=null and int(game.overlay.get_meta("preview_level"))==65,"Continue resolves latest unlocked level and opens OYNA preview")
 game.close_overlay();game.show_map(0);await process_frame;await process_frame
 for tab in ["collection","login","missions","shop","achievements"]:
  var original: int=game.map_scroll.scroll_vertical
  game.EconomyScreen.build(game,tab);await process_frame;await process_frame
  var scroll=game.overlay.find_child("EconomyScroll",true,false);var start: Vector2=scroll.get_global_transform_with_canvas()*(scroll.size/2)
  check(game.map_scroll.blocked,"Modal suspends map input: "+tab)
  var initial: int=scroll.scroll_vertical;gesture(scroll,start,start-Vector2(0,180))
  if tab=="collection":check(scroll.scroll_vertical>initial,"Friends list independently scrolls toward lower characters")
  check(game.map_scroll.scroll_vertical==original,"Background map remains stationary: "+tab)
  game.close_overlay();check(game.map_scroll.scroll_vertical==original and not game.map_scroll.blocked,"Closing modal preserves map location: "+tab)
 game.EconomyScreen.build(game,"collection");await process_frame;await process_frame
 var native_scroll=game.overlay.find_child("EconomyScroll",true,false);var native_point: Vector2=native_scroll.get_global_transform_with_canvas()*(native_scroll.size/2);var background_position: int=game.map_scroll.scroll_vertical
 var native_press:=InputEventScreenTouch.new();native_press.index=4;native_press.pressed=true;native_press.position=native_point;Input.parse_input_event(native_press);await process_frame
 var native_drag:=InputEventScreenDrag.new();native_drag.index=4;native_drag.position=native_point-Vector2(0,150);native_drag.relative=Vector2(0,-150);Input.parse_input_event(native_drag);await process_frame
 native_press.pressed=false;native_press.position=native_drag.position;Input.parse_input_event(native_press);await process_frame
 check(native_scroll.scroll_vertical>0 and game.map_scroll.scroll_vertical==background_position,"Native Input dispatch routes drag exclusively into modal list")
 game.close_overlay()
 for n in [61,151,301,351,401]:
  game.save.data.unlocked=500;game.start_level(n);game.close_goal_tip();await process_frame
  var targets: Dictionary=game.board.level.targets
  for key in ["deliveries","shutters","relays","gates","balances"]:
   if targets.has(key):check(game.goals_panel.targets.has(key),"New mechanic target has real HUD card: "+key)
  check(not game.board.evolution.nodes.is_empty(),"Real game instantiates new mechanism "+str(n))
 game.save.finish_writes();game.queue_free();await process_frame;await process_frame
 print(("PASS:" if errors==0 else "FAIL:")+" %d native gesture/modal/UI checks"%checks);quit(0 if errors==0 else 1)
