extends SceneTree
const Save=preload("res://scripts/core/save_manager.gd")
var game
var evidence: Array=[]
func _initialize() -> void:call_deferred("run")
func shot(name: String) -> void:
 await process_frame;await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://build/v0131/"+name+".png")
 evidence.append({"file":name+".png","screen":game.screen,"world":game.selected_world,"actual_godot":true})
func run() -> void:
 root.content_scale_size=Vector2i(540,960);root.size=Vector2i(540,960)
 game=load("res://scenes/main.tscn").instantiate();game.production_mode=true;game.save=Save.new("user://v0131-render-fixture-only.json");game.save.data=Save.defaults();game.save.data.unlocked=10;game.save.data.settings.music=false;game.save.data.settings.sfx=false
 for n in range(1,10):game.save.data.results[str(n)]={"score":5000,"stars":2}
 root.add_child(game);await create_timer(.4).timeout
 await shot("map-world-1")
 if not "--garden-only" in OS.get_cmdline_user_args():
  for world in range(1,6):
   game.save.data.unlocked=(world-1)*50+10;game.show_map((world-1)*5);await create_timer(.2).timeout;await shot("map-world-%d"%world)
   await create_timer(.3).timeout;await shot("map-world-%d-motion"%world)
  game.show_map(0);await process_frame;await process_frame;game.map_scroll.scroll_vertical=0;await shot("world-gate")
  game.save.data.unlocked=250;game.show_worlds();await create_timer(.5).timeout;await shot("world-cards")
  game.page.get_node("WorldCardsScroll").scroll_vertical=1000;await shot("world-cards-bottom")
  game.start_level(205);game.close_goal_tip();game.show_pause();await shot("pause")
  for dimensions in [Vector2i(320,568),Vector2i(390,844)]:
   root.size=dimensions;root.content_scale_size=dimensions;game.show_worlds();await create_timer(.15).timeout;await shot("world-cards-%d"%dimensions.x)
   game.show_home();await process_frame;game.show_settings();game.show_help();await shot("help-%d"%dimensions.x)
  root.size=Vector2i(540,960);root.content_scale_size=Vector2i(540,960);game.show_home();game.advance_after_win(200);await create_timer(.3).timeout;await shot("arrival-lava");await create_timer(.7).timeout
 var out:=FileAccess.open("res://build/v0131/render-evidence.json",FileAccess.WRITE);out.store_string(JSON.stringify(evidence,"  "));out.close()
 game.save.finish_writes();game.queue_free();await process_frame;await process_frame
 print("PASS: actual Godot living-map captures and UI review fixtures");quit()
