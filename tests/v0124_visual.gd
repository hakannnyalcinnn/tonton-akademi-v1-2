extends SceneTree
const Save=preload("res://scripts/core/save_manager.gd")
const Scenarios=preload("res://tests/v0123_fx_scenarios.gd")
var game
var rows: Array=[]
func _initialize() -> void:call_deferred("run")
func shot(name: String) -> void:
 await process_frame;await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://build/v124-"+name+".png")
func run() -> void:
 root.size=Vector2i(540,960);game=load("res://scenes/main.tscn").instantiate();game.production_mode=true;game.save=Save.new("user://v124-visual-only.json");game.save.data=Save.defaults();game.save.data.unlocked=250;game.save.data.settings.music=false;game.save.data.settings.sfx=false;root.add_child(game);await process_frame
 for height in [960,1200]:
  root.size=Vector2i(540,height);game.size=Vector2(540,height);game.show_settings();await process_frame;await shot("settings-%d"%height)
  game.show_help();await process_frame;await process_frame
  var column=game.overlay.get_node("DialogFlow");var scroll=column.get_node("TextScroll");var controls=column.get_node("DialogActions")
  scroll.get_child(0).text+="\n\n"+"Uzun Türkçe öğretici açıklaması kristallerin ve özel güçlerin nasıl kullanıldığını anlatır. ".repeat(30)
  scroll.get_child(0).add_theme_font_size_override("font_size",22);await process_frame;await process_frame
  assert(scroll.get_global_rect().end.y<=controls.get_global_rect().position.y and scroll.get_child(0).size.y>scroll.size.y)
  await shot("help-%d"%height);scroll.scroll_vertical=10000;await shot("help-bottom-%d"%height);game.close_overlay()
 game.request_level(25);await process_frame;await process_frame
 var panel=game.overlay.get_node("PreviewExplanation");var text=panel.get_child(0).get_child(0);var original=text.get_instance_id()
 var goals=game.overlay.get_children().filter(func(node):return node.get_script()==preload("res://scripts/ui/goals_panel.gd"))[0]
 for tap in 100:goals.goal_pressed.emit(goals.targets.keys()[tap%4]);assert(text.get_instance_id()==original)
 await shot("preview-four");game.close_overlay()
 for group in [0,5,20]:
  game.show_map(group);game.map_scroll.scroll_vertical=3100;await create_timer(.4).timeout
  var path=game.map_scroll.get_child(0);assert(path.curve.point_count==50 and path.road.size()>500)
  for index in 50:assert(path.curve.get_point_position(index)==path.node_position(index))
  await shot("map-%d"%game.selected_world)
 for height in [960,1080,1200]:
  root.size=Vector2i(540,height);game.size=Vector2(540,height);game.start_level(25);game.close_goal_tip();await process_frame
  var top: float=game.game_hud.position.y+game.game_hud.size.y+12
  assert(absf(game.board_view.position.y+268-maxf(top+268,(top+game.stage.size.y-190)/2))<1)
  assert(game.hint_label.position.y+game.hint_label.size.y<=game.stage.size.y)
  for cell in [0,7,64,71]:assert(game.board_view.index_at(game.board_view.cell_position(cell)+Vector2(28,28))==cell)
  await shot("centered-%d"%height)
 root.size=Vector2i(540,1200);game.size=Vector2(540,1200)
 for kind in ["bomb_normal","storm"]:
  var spec:=Scenarios.make(kind);game.start_level(7);game.close_goal_tip();game.board=spec.board;game.board_view.set_board(game.board);game.update_hud()
  var event: Dictionary=game.board.swap(spec.a,spec.b);var logical: Dictionary=game.board.snapshot();game.process_event(event)
  var milestones: Array=[];var stages: Array=[.18,.38,.6,.8] if kind=="bomb_normal" else [.25,.65]
  while game.board_view.busy:
   await process_frame
   var view=game.board_view
   if not view.busy:break
   if view.current.kind==("clear" if kind=="bomb_normal" else "storm"):
    var t: float=view.age/view.duration
    if milestones.size()<stages.size() and t>=float(stages[milestones.size()]):
     milestones.append(t);rows.append({"kind":kind,"progress":t,"duration":view.duration,"paths":view.energy_paths.size(),"impact":view.bomb_impact_sent,"energy":game.storm_gauge.value})
     if kind=="bomb_normal" and t<.7:assert(not view.bomb_impact_sent and view.duration>=.5 and not view.energy_paths.is_empty())
     if kind=="storm":assert(game.storm_gauge.value>=12 and game.board.direction=="down")
     await shot("%s-%d"%[kind,milestones.size()])
  assert(milestones.size()==stages.size() and game.board.snapshot()==logical and game.board.frames==event.frames)
 var file:=FileAccess.open("res://build/v124-animation-evidence.json",FileAccess.WRITE);file.store_string(JSON.stringify(rows,"  "));file.close()
 game.save.finish_writes();game.queue_free();await process_frame;await process_frame;print("PASS: container text separation, 100 target replacements, Bezier node continuity, three centered aspects, timed energy/impact and storm frame sequences preserve logical snapshots");quit()
