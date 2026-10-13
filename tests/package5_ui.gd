extends SceneTree
const Save=preload("res://scripts/core/save_manager.gd")
const Scenarios=preload("res://scripts/mechanics/developer_scenarios.gd")
const Solver=preload("res://tests/move_solver.gd")
var game
var checks:=0
var failures:=0
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(message)
func _initialize() -> void:call_deferred("run")
func run() -> void:
 game=load("res://scenes/main.tscn").instantiate();root.add_child(game);await process_frame
 game.save.finish_writes();game.save=Save.new("user://package5-ui-only.json");game.save.data=Save.defaults();game.save.data.unlocked=75;game.save.data.settings.reduced_motion=true
 game.save.data.settings.music=false;game.save.data.settings.sfx=false;game.audio.apply_settings(game.save.data.settings)
 var original: Dictionary=game.save.data.duplicate(true)
 for kind in ["fountain","bubble","conveyor","seal"]:
  game.start_mechanic_test();game.add_test_mechanic(kind);await process_frame
  check(game.test_mode and game.board.level.development_only,"only developer scenes "+kind)
  var pair:=Solver.best_move(game.board)
  if kind=="fountain":pair=[20,28]
  if kind=="seal":
   var v=game.board_view;var touch:=InputEventScreenTouch.new();touch.index=0;touch.pressed=true;touch.position=v.get_global_transform_with_canvas()*(v.cell_position(35)+Vector2(28,28));root.push_input(touch,true);touch.pressed=false;root.push_input(touch,true)
   check(game.goal_tip!=null and not game.paused,"native fixed-seal tap shows crystal sequence without pause")
   var icons:=0
   for child in game.goal_tip.get_children():
    if child is TextureRect:icons+=1
   check(icons==3,"seal uses actual three crystal icons")
   game.close_goal_tip()
  var before: int=game.board.moves
  game.on_swap(pair[0],pair[1]);var logical: Dictionary=game.board.snapshot();var frames_before: Array=game.board.frames.duplicate(true);game.on_swap(pair[0],pair[1])
  check(game.board.moves==before-1 and game.board.snapshot()==logical,"duplicate input blocked during cosmetic playback")
  var frames:=0
  while game.board_view.busy and frames<1200:await process_frame;frames+=1
  check(frames<1200 and game.board.find_matches().is_empty(),"cosmetic sequence terminates stable "+kind)
  check(game.board.frames==frames_before,"cosmetic playback never mutates logical event metadata "+kind)
  check(game.board_view.get_child_count()==6 and game.board_view.particle_positions.size()==192,"new mechanics preserve fixed effect pools")
  game.persist_board();check(game.save.data==original,"developer action cannot change campaign saves")
 var d:=Scenarios.make("seal",104169)
 d.mechanics=[{"kind":"chameleon","index":27,"sequence":[0,1,2],"period":1,"phase":0}];d.targets={"shifts":1,"total":10000}
 d.layout[64]=0;d.layout[65]=0;d.layout[66]=1;d.layout[58]=0;d.opening_refill=[1,2,3]
 game.start_level(1,false,d)
 var trait_updates: Array=[]
 game.board_view.environment_started.connect(func(e):
  if e.kind=="trait":trait_updates.append(game.goals_panel.amounts.shifts))
 game.on_swap(58,66)
 while game.board_view.busy:await process_frame
 check(trait_updates==[1],"chameleon target progresses at its own cosmetic frame, not only at final HUD refresh")
 check(game.board.frames.any(func(f):return f.kind=="trait" and f.collected.shifts==1),"trait goal reads central collected snapshot")
 check(game.save.data==original,"trait animation still leaves developer save isolated")
 game.start_level(1);game.close_goal_tip();game.pending_goal_tutorials.clear()
 var before_tip: Dictionary=game.board.snapshot()
 var touch:=InputEventScreenTouch.new();touch.index=1;touch.pressed=true;touch.position=game.goals_panel.get_global_transform_with_canvas()*game.goals_panel.rects.values()[0].get_center();root.push_input(touch,true);touch.pressed=false;root.push_input(touch,true)
 check(game.goal_tip!=null and game.board.snapshot()==before_tip,"actual native goal tap opens description without move")
 game.close_goal_tip()
 game.save.data.tutorials=[];game.queue_goal_tutorials();await process_frame
 var marker: String="goal_"+game.board.level.targets.keys()[0]
 check(marker in game.save.data.tutorials and game.goal_tip!=null,"new target tutorial persisted")
 game.close_goal_tip();game.queue_goal_tutorials();check(game.goal_tip==null,"seen tutorial does not repeat")
 game.replay_goal_tutorials();check(game.goal_tip!=null,"help menu replays target tutorial")
 game.save.finish_writes();var path: String=game.save.path;game.audio._notification(Node.NOTIFICATION_APPLICATION_PAUSED);await create_timer(.25).timeout
 game.queue_free();await process_frame;await process_frame
 for suffix in ["",".bak",".tmp"]:
  if FileAccess.file_exists(path+suffix):DirAccess.remove_absolute(ProjectSettings.globalize_path(path+suffix))
 print("PACKAGE5 UI: %d checks, %d failures; four scenarios, actual native seal input, tutorials, pools, save isolation"%[checks,failures]);quit(1 if failures else 0)
