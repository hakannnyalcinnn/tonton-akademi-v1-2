extends SceneTree
const Save=preload("res://scripts/core/save_manager.gd")
func _initialize() -> void:call_deferred("run")
func run() -> void:
 root.size=Vector2i(540,960)
 var game=load("res://scenes/main.tscn").instantiate();game.production_mode=true;game.save=Save.new("user://v0132-portal-fixture.json");game.save.data=Save.defaults();game.save.data.unlocked=51;game.save.data.settings.music=false;game.save.data.settings.sfx=false
 for n in range(1,51):game.save.data.results[str(n)]={"score":6000,"stars":2}
 root.add_child(game);await process_frame;game.show_map(0);await process_frame;await process_frame;game.map_scroll.scroll_vertical=0
 await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://build/v0132/portal-opening-1.png")
 await create_timer(.6).timeout;await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://build/v0132/portal-opening-2.png")
 game.save.finish_writes();game.queue_free();await process_frame;await process_frame;print("PASS: two actual Godot portal-opening frames");quit()
