extends SceneTree
const Save=preload("res://scripts/core/save_manager.gd")
const Catalog=preload("res://scripts/core/level_catalog.gd")
const Board=preload("res://scripts/core/board.gd")
const Icon=preload("res://scripts/ui/visual_icon_button.gd")
var game
var checks:=0
var failures:=0
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(message)
func _initialize() -> void:call_deferred("run")
func find_button(text: String) -> Button:
 for child in game.overlay.find_children("*","",true,false):
  if child is Button and child.text==text:return child
 return null
func run() -> void:
 root.size=Vector2i(540,960)
 game=load("res://scenes/main.tscn").instantiate();game.production_mode=true;game.save=Save.new("user://v0121-ui-only.json");game.save.data=Save.defaults();game.save.data.settings.music=false;game.save.data.settings.sfx=false;game.save.data.settings.reduced_motion=true
 root.add_child(game);await process_frame;await process_frame
 check(game.screen=="map" and game.selected_world==1,"first startup is active adventure map")
 check(game.map_buttons.size()==50 and game.map_buttons[1].active,"50 real nodes and current marker")
 check(game.map_buttons[2].disabled,"locked levels stay locked")
 var nav:=0
 for child in game.page.get_children():
  if child is Icon:nav+=1;check(child.image!=null,"navigation has real icon")
  if child is Button:check(not child.text.begins_with("1–10"),"no decade selector")
 check(nav==5,"five working navigation destinations")
 game.save.data.unlocked=9 # Prism stock becomes usable only at its declared unlock.
 game.request_level(1);await process_frame
 var inventory: Dictionary=game.save.data.adventure_progress.inventory
 var initial: int=inventory.prism
 for child in game.overlay.find_children("*","",true,false):
  if child is Icon and child.get_meta("booster","")=="prism":child.pressed.emit()
 check(game.selected_booster=="prism","visual booster selection")
 game.close_overlay();check(inventory.prism==initial,"cancel does not consume stock")
 inventory.rocket=0;game.request_level(1);await process_frame
 for child in game.overlay.find_children("*","",true,false):
  if child is Icon and child.get_meta("booster","")=="rocket":check(child.unavailable and child.amount==0,"zero stock explains availability without purchase UI");child.pressed.emit();check(game.selected_booster=="","zero stock cannot select or consume")
  elif child is Icon and child.get_meta("booster","")=="prism":child.pressed.emit()
 find_button("OYNA!").pressed.emit();await create_timer(.1).timeout;await process_frame
 check(game.screen=="game" and inventory.prism==initial-1,"Play starts and consumes exactly one owned booster")
 var teaching: Array=game.board.level.tutorial_swap
 check(preload("res://scripts/core/match_detector.gd").can_swap(game.board.cells,int(teaching[0]),int(teaching[1]),8,9),"starting booster preserves the teaching swap")
 game.save.data.unlocked=250
 game.request_level(2);await process_frame;find_button("OYNA!").pressed.emit();game.go_back()
 game.request_level(3);await process_frame;find_button("OYNA!").pressed.emit();await create_timer(.1).timeout
 check(int(game.board.level.id)==3,"cancelled transition cannot later start a stale level")
 for height in [960,1080,1170,1200]:
  root.size=Vector2i(540,height);game.size=Vector2(540,height)
  for n in [1,2,10,25,50,75,100,150,200,250,12,35]:
   game.start_level(n);await process_frame;game.layout_stage()
   var board_rect: Rect2=game.board_view.get_global_rect()
   check(game.goals_panel.get_global_rect().end.y<board_rect.position.y,"targets stay above board %d/%d"%[n,height])
   game.board.moves=1;game.update_hud();var key: String=game.board.active_targets().keys()[0];game.show_goal_description(key,true)
   check(game.moves_label.visible and game.moves_label.text=="1","last move remains visible")
   check(not game.goal_tip.get_global_rect().intersects(game.moves_label.get_global_rect()),"tutorial cannot cover moves")
   check(not game.goal_tip.get_global_rect().intersects(board_rect),"tutorial cannot cover grid")
   var local:=Vector2(28,28);var global_point: Vector2=game.board_view.get_global_transform_with_canvas()*local
   check(game.board_view.get_global_transform_with_canvas().affine_inverse()*global_point==local,"touch transform roundtrip")
   game.close_goal_tip()
 game.start_level(25);game.board.outcome="lost";game.board.moves=0;game.show_result();await process_frame
 check(find_button("YENİDEN OYNA")!=null,"retry is primary failure action")
 find_button("YENİDEN OYNA").pressed.emit();await process_frame
 check(find_button("OYNA!")!=null,"retry routes through preview")
 game.close_overlay();game.start_level(1);game.board.outcome="won";game.board.score=4000
 for key in game.board.level.targets:game.board.collected[key]=game.board.level.targets[key]
 game.show_result();await process_frame
 find_button("SONRAKİ BÖLÜM").pressed.emit();await process_frame
 check(find_button("OYNA!")!=null and game.overlay.get_meta("preview_level")==2 and int(game.board.level.id)==1,"next level routes through preview")
 game.close_overlay();game.show_map(5);await process_frame
 var world: int=game.selected_world;game.go_back();check(game.selected_world==world and game.overlay!=null,"map back confirms exit, does not jump worlds")
 game.close_overlay();game.show_worlds();await process_frame
 check(game.planet_view.globe!=null and game.page.get_children().filter(func(n):return n is HBoxContainer).size()==1,"five real worlds in a 3D selector")
 game.save.finish_writes()
 var saved_board:=Board.new(Catalog.get_level(60));saved_board.moves=3
 var active: Dictionary=saved_board.snapshot()
 game.save.data.active=active;game.save.data.unlocked=75;game.save.flush();game.save.finish_writes()
 game.save=Save.new(game.save.path);game.show_home();await process_frame
 check(game.selected_world==2 and game.map_buttons[60].active,"disk save opens correct world and active node")
 var owned: int=game.save.data.adventure_progress.inventory.prism
 game.request_level(60);await process_frame;find_button("OYNA!").pressed.emit();await create_timer(.1).timeout
 check(game.board.snapshot()==active and game.save.data.adventure_progress.inventory.prism==owned,"resume preserves exact saved game and never consumes another booster")
 game.save.finish_writes();game.queue_free();await process_frame;await process_frame
 print("V0121 UI: %d checks, %d failures"%[checks,failures]);quit(1 if failures else 0)
