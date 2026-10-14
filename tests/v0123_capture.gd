extends SceneTree
const Save=preload("res://scripts/core/save_manager.gd")
var game
func _initialize() -> void:call_deferred("run")
func shot(name: String) -> void:
 await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://build/v0123-"+name+".png")
func setup_level(n: int) -> void:
 game.start_level(n);game.close_goal_tip();game.board.moves=9;game.board.score=3210
 for key in game.board.active_targets():game.board.collected[key]=mini(55,int(game.board.active_targets()[key])-1) if key=="double" else 0
 game.update_hud();await create_timer(.2).timeout
func run() -> void:
 root.size=Vector2i(540,1200)
 game=load("res://scenes/main.tscn").instantiate();game.production_mode=true;game.save=Save.new("user://v0123-capture-only.json");game.save.data=Save.defaults();game.save.data.unlocked=250;game.save.data.settings.music=false;game.save.data.settings.sfx=false;game.save.data.settings.reduced_motion=true
 root.add_child(game);await process_frame
 await setup_level(247)
 if "--before" in OS.get_cmdline_user_args():await shot("247-before")
 else:
  await shot("247-after")
  for n in [1,2,25,49,62,150,200,250,12,35]:
   await setup_level(n);await shot("level-%d"%n)
  for height in [960,1080,1170,1200]:
   root.size=Vector2i(540,height);game.size=Vector2(540,height);await setup_level(247);await shot("ratio-%d"%height)
  root.size=Vector2i(540,1200);game.size=Vector2(540,1200)
  await setup_level(247);game.board.moves=1;game.update_hud();game.show_goal_description(game.board.active_targets().keys()[0],true);await shot("last-move-tip")
 game.save.finish_writes();game.queue_free();await process_frame;await process_frame
 print("PASS: real Godot HUD captures; isolated fixture profile");quit()
