extends SceneTree
const Catalog=preload("res://scripts/core/level_catalog.gd")
const Save=preload("res://scripts/core/save_manager.gd")
const Registry=preload("res://scripts/ui/goal_registry.gd")
var game
var checks:=0
var failures:=0
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(message)
func _initialize() -> void:call_deferred("run")
func run() -> void:
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 game.save.finish_writes();game.save=Save.new("user://goals-test-only.json");game.save.data=Save.defaults();game.save.data.unlocked=Catalog.count()
 game.save.data.settings.music=false;game.save.data.settings.sfx=false;game.audio.apply_settings(game.save.data.settings)
 for n in range(1,Catalog.count()+1):
  game.start_level(n);await process_frame;game.close_goal_tip()
  var panel=game.goals_panel
  check(panel.targets==game.board.active_targets(),"targets read exact level data %d"%n)
  check(panel.rects.size()==game.board.active_targets().size(),"all targets visible %d"%n)
  check(panel.get_global_rect().end.y<game.board_view.get_global_rect().position.y,"panel cannot overlap board")
  for key in panel.targets:
   check(Registry.icon(key)!=null,"actual target art loaded")
   check(panel.amounts[key]==game.board.collected.get(key,0),"central initial counter")
   check(str(int(panel.targets[key])) in Registry.description(key,int(panel.targets[key])),"data-driven Turkish description")
   var state: Dictionary=game.board.snapshot()
   game.show_goal_description(key)
   check(game.goal_tip!=null and not game.paused,"nonblocking description")
   var expected: Array=[]
   for i in 72:
    if Registry.relevant(key,game.board_view.displayed[i],i,game.board.adventure if key=="rescues" else game.board.canyon):expected.append(i)
   if key=="portals":
    for pair in game.board.level.get("portals",[]):expected.append(pair.entry);expected.append(pair.exit)
   if key=="conveyors":
    for rail in game.board.level.get("conveyors",[]):expected.append_array(rail.cells)
   check(game.board_view.goal_highlights==expected,"precise target highlights")
   check(game.board.snapshot()==state,"goal tapping never changes game state")
   game.close_goal_tip()
  var changes: Array=[];panel.goal_completed.connect(func(key):changes.append(key))
  var filled: Dictionary=game.board.collected.duplicate()
  for key in panel.targets:filled[key]=panel.targets[key]
  panel.update_progress(filled,false)
  check(changes.size()==panel.targets.size(),"one complete signal for each target")
  panel.update_progress(filled,false);check(changes.size()==panel.targets.size(),"completion sound cannot repeat")
  for key in panel.targets:check(panel.displayed[key]==float(panel.targets[key]),"completed rendered counter")
 for extent in [Vector2i(540,960),Vector2i(540,1170),Vector2i(540,1200)]:
  root.size=extent;game.size=Vector2(extent);game.safe_rect_override=Rect2(0,24,540,extent.y-48)
  game.start_level(49);game.layout_stage();await process_frame
  check(game.goals_panel.targets.size()==6,"six goals fit two rows")
  check(game.board_view.get_global_rect().position.y-game.goals_panel.get_global_rect().end.y<=14*game.stage.scale.y,"goals remain adjacent to board on tall screens")
  for key in game.goals_panel.rects:check(Rect2(Vector2.ZERO,game.goals_panel.size).encloses(game.goals_panel.rects[key]),"six icons all in bounds")
  for i in 72:check(game.board_view.index_at(game.board_view.cell_position(i)+Vector2(28,28))==i,"cell coordinates unchanged")
 game.safe_rect_override=Rect2();root.size=Vector2i(540,960);game.size=Vector2(540,960)
 game.start_level(1);game.close_goal_tip()
 var panel=game.goals_panel
 panel.configure({"0":1},{});check(is_equal_approx(panel.rects["0"].get_center().x,panel.size.x*.5),"single goal centered")
 panel.configure({"0":1,"1":2},{});check(panel.rects.size()==2 and panel.rects["0"].end.x<panel.rects["1"].position.x,"two balanced goals")
 panel.configure({"0":1,"1":1,"2":1,"3":1,"4":1,"total":1,"stones":1,"lock":1,"ice":1},{})
 check(panel.content_height>panel.size.y,"nine targets scroll with explicit count cue")
 panel.offset=panel.content_height-panel.size.y;check(panel.key_at(panel.rects.ice.get_center()-Vector2(0,panel.offset))=="ice","ninth goal remains accessible")
 game.start_level(49);game.close_goal_tip();game.board.collected["1"]=3;game.board.collected.total=3;game.save.save_active(game.board);game.start_level(49,true)
 check(game.goals_panel.amounts["1"]==3,"saved target progress restores")
 game.save.finish_writes();var path: String=game.save.path;game.audio._notification(Node.NOTIFICATION_APPLICATION_PAUSED);await create_timer(.25).timeout
 game.queue_free();await process_frame;await process_frame
 for suffix in ["",".bak",".tmp"]:
  if FileAccess.file_exists(path+suffix):DirAccess.remove_absolute(ProjectSettings.globalize_path(path+suffix))
 print("GOALS PANEL: %d checks, %d failures; all %d levels, six goals, 3 ratios, descriptions, counters, highlights, save"%[checks,failures,Catalog.count()]);quit(1 if failures else 0)
