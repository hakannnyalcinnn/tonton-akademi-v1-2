extends SceneTree
const Save=preload("res://scripts/core/save_manager.gd")
var game
func _initialize() -> void:call_deferred("run")
func run() -> void:
 root.size=Vector2i(540,1200);game=load("res://scenes/main.tscn").instantiate();game.production_mode=true;game.save=Save.new("user://r2-map-only.json");game.save.data=Save.defaults();game.save.data.settings.music=false;game.save.data.settings.sfx=false;root.add_child(game);await process_frame
 for group in [0,5,10,15,20]:
  game.save.data.unlocked=group*10+25
  for n in range(1,game.save.data.unlocked):game.save.data.results[str(n)]={"score":1000,"stars":1+n%3}
  game.show_map(group);await create_timer(.5).timeout
  var path=game.map_scroll.get_child(0);assert(path.count==50 and path.node_position(0).y>path.node_position(49).y and path.landmark!=null)
  await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://build/r2-map-%d.png"%game.selected_world)
 game.save.finish_writes();game.queue_free();await process_frame;await process_frame;print("PASS: five real bottom-to-top world maps with fifty nodes and original landmarks");quit()
