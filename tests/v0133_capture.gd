extends SceneTree
const Save=preload("res://scripts/core/save_manager.gd")
var game
var evidence: Array=[]
func _initialize() -> void:call_deferred("run")
func shot(name: String) -> void:
 await process_frame;await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://build/v0133/"+name+".png")
 evidence.append({"file":name+".png","screen":game.screen,"world":game.selected_world,"actual_godot":true})
func run() -> void:
 root.content_scale_size=Vector2i(540,960);root.size=Vector2i(540,960)
 game=load("res://scenes/main.tscn").instantiate();game.production_mode=true;game.save=Save.new("user://v0133-render-fixture-only.json");game.save.data=Save.defaults();game.save.data.unlocked=10;game.save.data.settings.music=false;game.save.data.settings.sfx=false
 for n in range(1,10):game.save.data.results[str(n)]={"score":5000,"stars":2}
 root.add_child(game);await create_timer(.4).timeout
 for world in range(1,6):
  game.save.data.unlocked=(world-1)*50+45;game.show_map((world-1)*5);await create_timer(.15).timeout
  for point in [0,24,49]:
   var path=game.map_scroll.get_node("LivingAdventurePath")
   game.map_scroll.scroll_vertical=maxi(0,int(path.node_position(point).y-game.map_scroll.size.y*.5))
   await shot("map-world-%d-%d"%[world,point+1])
 game.save.data.unlocked=250;game.show_worlds();await create_timer(.4).timeout;await shot("world-cards")
 game.page.get_node("WorldCardsScroll").scroll_vertical=9999;await shot("world-cards-bottom")
 for dimensions in [Vector2i(540,960),Vector2i(540,1170),Vector2i(540,1200),Vector2i(320,568)]:
  root.size=dimensions;root.content_scale_size=dimensions
  for w in [1,5]:
   game.save.data.active={};game.save.data.unlocked=(w-1)*50+45;game.show_map((w-1)*5);await create_timer(.1).timeout;await shot("map-%d-%d"%[w,dimensions.y])
  game.save.data.unlocked=250;game.show_worlds();await create_timer(.1).timeout;await shot("worlds-%d"%dimensions.y)
 root.size=Vector2i(540,960);root.content_scale_size=Vector2i(540,960);await process_frame
 game.show_map(0);await process_frame;await process_frame
 var terrain=game.page.get_node("MapSceneBackdrop")
 for child in game.page.get_children():
  if child!=terrain:child.hide()
 game.map_scroll.scroll_vertical=1900;terrain.sync_canvas();await shot("terrain-continuity-a")
 game.map_scroll.scroll_vertical=2000;terrain.sync_canvas();await shot("terrain-continuity-b")
 var out:=FileAccess.open("res://build/v0133/render-evidence.json",FileAccess.WRITE);out.store_string(JSON.stringify(evidence,"  "));out.close()
 game.save.finish_writes();game.queue_free();await process_frame;await process_frame
 print("PASS: actual Godot living-map captures and UI review fixtures");quit()
