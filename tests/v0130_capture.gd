extends SceneTree
const Save=preload("res://scripts/core/save_manager.gd")
var game
func _initialize() -> void:call_deferred("run")
func shot(name: String) -> void:
 await process_frame;await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://build/v130-"+name+".png")
func run() -> void:
 root.size=Vector2i(540,960);game=load("res://scenes/main.tscn").instantiate();game.production_mode=true;game.save=Save.new("user://v130-visual-fixture.json");game.save.data=Save.defaults();game.save.data.unlocked=250;game.save.data.settings.music=false;game.save.data.settings.sfx=false;root.add_child(game);await process_frame
 game.selected_world=1;game.show_worlds();await create_timer(1).timeout;await shot("planet-1")
 for world in range(2,6):game.select_planet_world(world);await create_timer(.8).timeout;await shot("planet-%d"%world)
 game.planet_view.focus_world(5,true);await create_timer(1).timeout;assert(game.screen=="map" and game.selected_world==5);await shot("lava-map")
 game.request_level(25);await create_timer(.3).timeout;await shot("preview")
 game.close_overlay();game.start_level(205);game.show_pause();await process_frame;await shot("pause")
 game.save.finish_writes();game.queue_free();await process_frame;print("PASS v130 actual render capture and planet zoom navigation");quit()
