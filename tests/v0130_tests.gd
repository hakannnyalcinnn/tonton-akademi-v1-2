extends SceneTree
const Save=preload("res://scripts/core/save_manager.gd")
const Planet=preload("res://scripts/ui/planet_view.gd")
const Goals=preload("res://scripts/ui/goals_panel.gd")
var game
var checks:=0
func _initialize() -> void:call_deferred("run")
func check(condition: bool) -> void:checks+=1;assert(condition)
func run() -> void:
 root.size=Vector2i(540,960);game=load("res://scenes/main.tscn").instantiate();game.production_mode=true;game.save=Save.new("user://v130-tests-only.json");game.save.data=Save.defaults();game.save.data.unlocked=250;game.save.data.settings.music=false;game.save.data.settings.sfx=false;game.save.data.settings.reduced_motion=true;root.add_child(game);await process_frame
 var before: Dictionary=game.save.data.duplicate(true)
 game.selected_world=1;game.show_worlds();await process_frame
 var planet=game.planet_view;check(planet.viewport.own_world_3d and planet.globe.get_child_count()>=8)
 var instances:=0
 for record in Planet.geometry_cache[planet.quality]:
  if record.has("multimesh"):instances+=record.multimesh.instance_count
 check(instances>600)
 var initial: float=planet.yaw
 var touch:=InputEventScreenTouch.new();touch.index=0;touch.pressed=true;touch.position=Vector2(240,230);planet._gui_input(touch)
 for i in 40:
  var drag:=InputEventScreenDrag.new();drag.index=0;drag.position=Vector2(240+(i+1)*20,230);planet._gui_input(drag)
 touch.pressed=false;touch.position=Vector2(1040,230);planet._gui_input(touch)
 check(planet.yaw-initial>TAU and not planet.choosing and planet.pointer==-1)
 planet.velocity=0
 for world in range(1,6):
  game.select_planet_world(world);await create_timer(.04).timeout
  check(game.selected_world==world and game.planet_info.text.contains(Planet.TITLES[world-1]))
  var center: Vector3=planet.globe.global_transform*(Planet.direction(Planet.CENTERS[world-1].x,Planet.CENTERS[world-1].y)*2.6)
  var point: Vector2=planet.camera.unproject_position(center)*planet.size/Vector2(planet.viewport.size)
  planet.select_at(point);check(game.selected_world==world)
 check(game.save.data.results==before.results and game.save.data.active==before.active)
 game.save.data.unlocked=1;game.select_planet_world(5);check(game.planet_enter.disabled);planet.focus_world(5,true);await create_timer(.1).timeout;check(game.screen=="worlds")
 game.save.data.unlocked=250;game.select_planet_world(3);await create_timer(.04).timeout
 planet.focus_world(3,true);planet.focus_world(3,true);await create_timer(.06).timeout
 check(game.screen=="map" and game.selected_world==3 and game.map_buttons.size()==50)
 check(game.map_buttons.keys().min()==101 and game.map_buttons.keys().max()==150)
 for node in game.page.get_children():
  if node is Button and node.text=="GÜNCEL BÖLÜME DÖN":check(node.size.y>=44 and node.size.x>=300)
 for height in [960,1080,1200]:
  root.size=Vector2i(540,height);game.size=Vector2(540,height);game.request_level(49);await process_frame;await process_frame
  var panel=game.overlay.find_child("PreviewExplanation",true,false);var text=panel.get_child(0).get_child(0);var identity: int=text.get_instance_id();var preview=game.overlay.find_children("*","",true,false).filter(func(n):return n.get_script()==Goals)[0]
  for i in 100:preview.goal_pressed.emit(preview.targets.keys()[i%preview.targets.size()]);check(text.get_instance_id()==identity)
  text.text="Uzun Türkçe açıklama, hedeflerin nasıl tamamlanacağını anlatır. ".repeat(20);text.add_theme_font_size_override("font_size",24)
  await process_frame;await process_frame
  var play=game.overlay.find_children("*","Button",true,false).filter(func(n):return n.text=="OYNA!")[0]
  check(panel.get_global_rect().end.y<play.get_global_rect().position.y)
  check(game.overlay.find_child("PreviewScroll",true,false) is ScrollContainer and panel.get_child(0) is ScrollContainer)
  var dismiss:=InputEventMouseButton.new();dismiss.pressed=true;dismiss.button_index=MOUSE_BUTTON_LEFT;dismiss.position=Vector2(10,10);game.overlay.gui_input.emit(dismiss);check(not panel.visible)
  preview.goal_pressed.emit(preview.targets.keys()[0]);check(panel.visible)
  game.close_overlay()
 game.start_level(205);game.close_goal_tip();await process_frame;var snapshot: Dictionary=game.board.snapshot();game.show_pause();await process_frame;await process_frame
 var pause=game.overlay.get_node("PausePanel");check(pause.get_child(0) is VBoxContainer)
 var texts: Array=[]
 for node in pause.find_children("*","Label",true,false):texts.append(node.text)
 check(str(texts).contains("Lav Kristalleri") and not str(texts).contains("Bahçe"))
 game.close_overlay();check(game.board.snapshot()==snapshot and not game.paused)
 game.show_map(0);await process_frame
 for i in 30:
  var event:=InputEventMouseButton.new();event.position=Vector2(4,150+i*10);event.button_index=MOUSE_BUTTON_LEFT;event.pressed=true;root.push_input(event,true);event.pressed=false;root.push_input(event,true)
 check(game.overlay==null)
 for node in game.page.find_children("*","Button",true,false):check(node.tooltip_text=="")
 game.save.finish_writes();game.queue_free();await process_frame;await process_frame;print("PASS v130: %d checks, real mesh detail, 360-degree drag, five ray selections, locks, zoom, unchanged saves, three aspect previews, 300 description replacements, pause and ghost-overlay guards"%checks);quit()
