extends SceneTree
const Save=preload("res://scripts/core/save_manager.gd")
const Scenarios=preload("res://tests/v0123_fx_scenarios.gd")
const Powers=preload("res://scripts/core/powerups.gd")
const Match=preload("res://scripts/core/match_detector.gd")
var checks:=0
var failures:=0
var game
func _initialize() -> void:call_deferred("run")
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(message)
func run() -> void:
 game=load("res://scenes/main.tscn").instantiate();game.production_mode=true;game.save=Save.new("user://v0123-tests-only.json");game.save.data=Save.defaults();game.save.data.unlocked=250;game.save.data.settings.music=false;game.save.data.settings.sfx=false;root.add_child(game);await process_frame
 for kind in ["normal","four","five","bomb_normal","double","rockets","rocket_prism","color_rocket","color_prism","prisms","storm","giant","chain","mirrors","protected"]:
  for reduced in [false,true]:
   var spec:=Scenarios.make(kind);game.start_level(247 if kind=="giant" else 7);game.close_goal_tip();game.board=spec.board;game.board_view.set_board(game.board);game.board_view.reduced_motion=true;game.board_view.settings.reduced_effects=reduced
   var copy=preload("res://scripts/core/board.gd").new(game.board.level);check(copy.restore(game.board.snapshot()),"fixture snapshot restores")
   var moves: int=game.board.moves;var event: Dictionary=game.board.swap(spec.a,spec.b);copy.swap(spec.a,spec.b)
   check(event.accepted and game.board.moves==moves-1,"one successful move "+kind)
   check(game.board.snapshot()==copy.snapshot(),"deterministic settled state "+kind)
   game.process_event(event);var stages:=0;var bound:=0;var prior_kind:=""
   while game.board_view.busy and bound<1000:
    var v=game.board_view
    if v.current.kind=="clear" and prior_kind!="clear":
     stages+=1
     var unique: Dictionary={}
     for index in v.current.removed:unique[index]=true
     check(unique.size()==v.current.removed.size(),"removed cells unique within wave")
     if v.bomb_origin>=0:
      check(v.current.has("selected_color"),"visual color is supplied by central resolver")
      var expected: Array=v.current.removed if v.current.get("combo_kind","")=="color_color" else Powers.area(v.bomb_origin,"color",v.previous,8,int(v.current.selected_color))
      for index in expected:check(v.energy_paths.has(index),"every eligible target has an energy link, including reduced quality")
     if not v.current.get("beams",[]).is_empty():check(v.render_beams.size()==v.current.beams.size(),"all authoritative reflected rays rendered")
    prior_kind=str(v.current.kind)
    await process_frame;bound+=1
   check(stages>0,"actual clear frames inspected "+kind)
   check(bound<1000 and game.board.available(),"control returns only after bounded animation "+kind)
   check(game.board.snapshot()==copy.snapshot(),"effects never change score/targets/state "+kind)
   check(game.board.find_matches().is_empty() and Match.has_move(game.board.cells,8,9),"stable playable state "+kind)
   if kind=="five":check(event.frames.any(func(f):return f.get("creations",[]).any(func(c):return c.kind=="color")),"five creates color bomb")
   if kind=="four":check(event.frames.any(func(f):return f.get("creations",[]).any(func(c):return str(c.kind).begins_with("rocket"))),"four creates rocket")
   if kind=="giant":check(game.board.collected.giants==1,"giant destruction credits exactly once")
   if kind=="storm":check(event.storm and event.frames.filter(func(f):return f.kind=="storm").size()==1,"at most one storm")
 game.save.data.settings.reduced_motion=true;game.save.data.tutorials=[];game.start_level(1);await process_frame
 check(game.goal_tip!=null and game.goal_tip.size.y==60,"compact 60px notice")
 await create_timer(2.8).timeout;check(game.goal_tip==null,"one-time notice expires safely")
 var snapshot: Dictionary=game.board.snapshot();game.show_goal_description(game.goals_panel.targets.keys()[0]);game.on_swap(1,9)
 check(game.board.snapshot()==snapshot and game.goal_tip==null,"first board gesture only dismisses a deliberately opened explanation")
 game.start_level(247);game.close_goal_tip();await process_frame
 check(game.board.canyon.giants["44"]==3,"247 actual giant has three HP")
 check(game.goals_panel.rects.size()==3 and game.storm_gauge.size.y==30,"readable targets and slim storm")
 game.storm_gauge.set_value(56);check(game.storm_gauge.value==56,"energy remains centrally accounted; visible text is clamped to twelve")
 for command in ["rr","cr","storm","giant"]:
  var state: Dictionary=game.board.snapshot();game.dev_command(command);check(game.board.snapshot()==state,"production rejects new developer command "+command)
 game.production_mode=false;game.fast_test=true;game.start_level(7);game.close_goal_tip()
 game.dev_command("rr");check(game.board.cells.any(func(c):return c!=null and c.p=="rocket_v"),"developer rocket pair")
 game.dev_command("cr");check(game.board.cells.any(func(c):return c!=null and c.p=="color"),"developer color/rocket pair")
 game.start_level(7);game.close_goal_tip();game.dev_command("storm")
 while game.board_view.busy:await process_frame
 check(game.board.action_storm_used,"developer storm uses actual resolver")
 game.dev_command("giant");check(int(game.board.level.id)==247 and game.board.canyon.giants["44"]==1,"developer last-hit giant fixture")
 game.save.finish_writes();game.queue_free();await process_frame;await process_frame
 print("V0123: %d checks, %d failures; 15 real effect scenarios, central damage, links, notice and production gate"%[checks,failures]);quit(1 if failures else 0)
