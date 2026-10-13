extends SceneTree
const Save=preload("res://scripts/core/save_manager.gd")
var game
func _initialize() -> void:call_deferred("run")
func capture(name: String) -> void:
 await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://build/canyon-"+name+".png")
func run() -> void:
 root.size=Vector2i(540,960)
 game=load("res://scenes/main.tscn").instantiate();game.save=Save.new("user://canyon-delivery-capture.json");game.save.data=Save.defaults();game.save.data.unlocked=150;game.save.data.settings.music=false;game.save.data.settings.sfx=false
 root.add_child(game);await process_frame
 game.show_worlds();await capture("worlds");game.show_map(10);await capture("map")
 game.start_level(150);game.close_goal_tip();await capture("core-board-960")
 game.save.finish_writes();game.queue_free();await process_frame;await process_frame;quit()
