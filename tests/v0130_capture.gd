extends SceneTree
const Save=preload("res://scripts/core/save_manager.gd")
var game
var sequence: Array=[]
func _initialize() -> void:call_deferred("run")
func shot(name: String) -> void:
 await process_frame;await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://build/v130-"+name+".png")
func run() -> void:
 root.size=Vector2i(540,960);game=load("res://scenes/main.tscn").instantiate();game.production_mode=true;game.save=Save.new("user://v130-visual-fixture.json");game.save.data=Save.defaults();game.save.data.unlocked=250;game.save.data.settings.music=false;game.save.data.settings.sfx=false;root.add_child(game);await process_frame
 game.selected_world=1;game.show_worlds();await create_timer(1).timeout;await shot("planet-1")
 var planet=game.planet_view
 for gesture in 3:
  var touch:=InputEventScreenTouch.new();touch.index=0;touch.pressed=true;touch.position=planet.get_global_transform_with_canvas()*Vector2(120,230);root.push_input(touch,true)
  for step in 8:
   var drag:=InputEventScreenDrag.new();drag.index=0;drag.position=planet.get_global_transform_with_canvas()*Vector2(120+(step+1)*38,230);drag.relative=planet.get_global_transform_with_canvas().basis_xform(Vector2(38,0));root.push_input(drag,true);await create_timer(.06).timeout
   if step in [3,7]:
    sequence.append({"gesture":gesture,"step":step,"yaw":planet.yaw,"time_ms":Time.get_ticks_msec()});await shot("rotation-%d"%sequence.size())
  touch.pressed=false;touch.position=planet.get_global_transform_with_canvas()*Vector2(424,230);root.push_input(touch,true);planet.velocity=0
 assert(sequence[-1].yaw-sequence[0].yaw>TAU)
 for world in range(2,6):game.select_planet_world(world);await create_timer(.8).timeout;await shot("planet-%d"%world)
 game.planet_view.focus_world(5,true)
 for frame in 3:
  await create_timer(.15).timeout;sequence.append({"zoom_frame":frame,"camera_size":game.planet_view.camera.size,"time_ms":Time.get_ticks_msec()});await shot("zoom-%d"%frame)
 await create_timer(.5).timeout;assert(game.screen=="map" and game.selected_world==5);await shot("lava-map")
 game.request_level(25);await create_timer(.3).timeout;await shot("preview")
 var goals=game.overlay.find_children("*","",true,false).filter(func(n):return n.get_script()==preload("res://scripts/ui/goals_panel.gd"))[0]
 goals.goal_pressed.emit(goals.targets.keys()[0]);await shot("goal-explanation")
 game.close_overlay()
 for height in [960,1200]:
  root.size=Vector2i(540,height);game.size=Vector2(540,height);game.show_settings();await shot("settings-%d"%height);game.show_help();await shot("help-%d"%height);game.close_overlay()
 root.size=Vector2i(540,960);game.size=Vector2(540,960)
 for group in [0,5,10,15,20]:game.show_map(group);game.map_scroll.scroll_vertical=3100;await create_timer(.2).timeout;await shot("world-path-%d"%game.selected_world)
 game.close_overlay();game.start_level(205);game.show_pause();await process_frame;await shot("pause")
 var file:=FileAccess.open("res://build/v130-rotation-evidence.json",FileAccess.WRITE);file.store_string(JSON.stringify(sequence,"  "));file.close()
 game.save.finish_writes();game.queue_free();await process_frame;print("PASS v130 actual render capture and planet zoom navigation");quit()
