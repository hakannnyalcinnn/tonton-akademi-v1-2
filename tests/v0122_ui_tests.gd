extends SceneTree
const Save=preload("res://scripts/core/save_manager.gd")
const Match=preload("res://scripts/core/match_detector.gd")
var checks:=0
var failures:=0
var game
func _initialize() -> void:call_deferred("run")
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(message)
func frame() -> void:
 await process_frame;await process_frame;game.layout_stage();await process_frame
func wait_view() -> void:
 var elapsed:=0
 while game.board_view.busy and elapsed<1000:await process_frame;elapsed+=1
 check(elapsed<1000,"bounded cascades")
func run() -> void:
 game=load("res://scenes/main.tscn").instantiate();game.production_mode=true;game.save=Save.new("user://v0122-hud-tests-only.json");game.save.data=Save.defaults();game.save.data.unlocked=250;game.save.data.settings.music=false;game.save.data.settings.sfx=false;game.save.data.settings.reduced_motion=true
 root.add_child(game);await process_frame
 # Every prepared level gets a real HUD constructed once, without campaign simulation.
 for n in range(1,251):
  game.start_level(n);game.close_goal_tip();await frame()
  check(game.goals_panel.targets==game.board.active_targets(),"central targets %d"%n)
  check(game.star_progress.thresholds==game.board.level.stars,"real star thresholds %d"%n)
  check(game.moves_label.text==str(game.board.moves),"central move count %d"%n)
  check(game.game_hud.size.y<=206,"compact shared HUD %d"%n)
 for extent in [Vector2i(1080,1920),Vector2i(1080,2160),Vector2i(1080,2340),Vector2i(1080,2400),Vector2i(720,1600)]:
  root.size=extent;game.size=Vector2(extent);game.safe_rect_override=Rect2(Vector2(0,32),Vector2(extent.x,extent.y-64))
  for n in [1,2,25,49,62,106,150,200,250,12,35]:
   game.start_level(n);await frame()
   var moves: Rect2=game.moves_label.get_global_rect();var score: Rect2=game.score_label.get_global_rect();var stars: Rect2=game.star_progress.get_global_rect();var grid: Rect2=game.board_view.get_global_rect();var goals: Rect2=game.goals_panel.get_global_rect()
   check(not moves.intersects(score) and not moves.intersects(stars) and not stars.intersects(score),"distinct information modules")
   check(goals.end.y<grid.position.y and absf((grid.position.y-goals.end.y)-(game.stage.get_global_rect().end.y-190*game.stage.scale.y-grid.end.y))<=20*game.stage.scale.y,"centered usable-area spacing with separate HUD")
   check(game.safe_rect().encloses(game.game_hud.get_global_rect()),"HUD fits notch safe area")
   check(game.safe_rect().encloses(grid),"board fits safe area")
   check(game.moves_label.get_theme_font_size("font_size")>=36,"moves stay readable")
   for key in game.goals_panel.rects:check(Rect2(Vector2.ZERO,game.goals_panel.size).encloses(game.goals_panel.rects[key]),"visible goal card %d %s size=%s rect=%s"%[n,key,str(game.goals_panel.size),str(game.goals_panel.rects[key])])
   for index in [0,7,32,64,71]:
    var local: Vector2=game.board_view.cell_position(index)+Vector2(28,28)
    var global: Vector2=game.board_view.get_global_transform_with_canvas()*local
    check(game.board_view.index_at(game.board_view.get_global_transform_with_canvas().affine_inverse()*global)==index,"unchanged cell touch mapping")
   game.board.moves=1;game.update_hud();game.show_goal_description(game.board.active_targets().keys()[0],true);await frame()
   check(game.moves_label.is_visible_in_tree() and game.moves_label.text=="1","last move visible through tutorial")
   check(not game.goal_tip.get_global_rect().intersects(moves) and not game.goal_tip.get_global_rect().intersects(grid),"tip never covers moves/grid")
   game.close_goal_tip()
 game.safe_rect_override=Rect2();root.size=Vector2i(540,1200);game.size=Vector2(540,1200)
 game.start_level(106);game.close_goal_tip();await frame()
 check(game.game_hud.size.y==176 and game.game_hud.size.y<215,"106 HUD height 215 -> 176")
 game.game_hud.show_score(3210);check(game.score_label.text=="3.210","score formatting")
 game.game_hud.show_score(123456789);check(game.score_label.get_theme_font_size("font_size")==13,"very large score shrinks before moves")
 var snapshot: Dictionary=game.board.snapshot()
 game.level_label.text="BÖLÜM 106 · Çok uzun Türkçe başlık: çığlık, ışıldayan kristaller ve gökkuşağı"
 await frame();check(game.level_label.text_overrun_behavior==TextServer.OVERRUN_TRIM_ELLIPSIS,"long Turkish titles ellipsize")
 check(game.board.snapshot()==snapshot,"presentation never mutates game state")
 for count in range(1,7):
  var targets: Dictionary={}
  for key in ["0","1","2","3","4","total"].slice(0,count):targets[key]=75
  game.goals_panel.configure(targets,{});game.game_hud.update_height();await frame()
  for key in targets:check(Rect2(Vector2.ZERO,game.goals_panel.size).encloses(game.goals_panel.rects[key]),"1-6 goals in bounds")
  check(game.goals_panel.key_at(game.goals_panel.rects[targets.keys()[0]].get_center())==targets.keys()[0],"correct goal tap hit target")
  game.goals_panel.update_progress(targets,false)
  for key in targets:check(int(game.goals_panel.amounts[key])==75,"exact complete counter / tick")
 game.start_level(1);game.close_goal_tip();game.board_view.reduced_motion=true
 var original_moves: int=game.board.moves
 var hint: Array=game.board.level.tutorial_swap
 game.on_swap(int(hint[0]),int(hint[1]));await wait_view()
 check(game.board.moves==original_moves-1 and game.moves_label.text==str(game.board.moves),"real valid drag consumes once / HUD follows")
 check(Match.find(game.board.cells,8,9).is_empty(),"stable automatic cascade")
 if game.overlay:game.close_overlay()
 game.start_level(106);game.close_goal_tip();game.board.moves=1;game.update_hud()
 game.board_view.combo_label.text="EFSANEVİ!";game.board_view.combo_label.show();await frame()
 check(not game.board_view.combo_label.get_global_rect().intersects(game.moves_label.get_global_rect()),"combo cannot hide moves")
 game.save.finish_writes();game.queue_free();await process_frame;await process_frame
 print("V0122 HUD: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
