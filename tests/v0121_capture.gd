extends SceneTree
const Save=preload("res://scripts/core/save_manager.gd")
var game
func _initialize() -> void:call_deferred("run")
func shot(name: String) -> void:
 await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://build/v0121-"+name+".png")
func run() -> void:
 root.size=Vector2i(540,1200)
 game=load("res://scenes/main.tscn").instantiate();game.production_mode=true;game.save=Save.new("user://v0121-capture-only.json");game.save.data=Save.defaults();game.save.data.unlocked=25;game.save.data.settings.music=false;game.save.data.settings.sfx=false
 for n in range(1,25):game.save.data.results[str(n)]={"score":1000,"stars":1+n%3}
 root.add_child(game);await create_timer(.35).timeout
 await shot("map");game.request_level(25);await create_timer(.3).timeout;await shot("preview")
 game.close_overlay();game.start_level(25);await shot("hud-tutorial");game.close_goal_tip();await shot("hud")
 game.board.outcome="won";game.board.score=8000
 for key in game.board.level.targets:game.board.collected[key]=int(game.board.level.targets[key])
 game.show_result();await create_timer(.4).timeout;await shot("success")
 game.close_overlay();game.start_level(25);game.board.outcome="lost";game.board.moves=0;game.show_result();await shot("failure")
 game.close_overlay();game.save.data.unlocked=250;game.show_worlds();await shot("worlds")
 game.save.finish_writes();game.queue_free();await process_frame;await process_frame
 print("PASS: six final Godot screens and visible tutorial HUD; isolated test profile");quit()
