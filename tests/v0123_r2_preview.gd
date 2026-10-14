extends SceneTree
const Save=preload("res://scripts/core/save_manager.gd")
var game
func _initialize() -> void:call_deferred("run")
func run() -> void:
 root.size=Vector2i(540,1200);game=load("res://scenes/main.tscn").instantiate();game.production_mode=true;game.save=Save.new("user://r2-preview-only.json");game.save.data=Save.defaults();game.save.data.unlocked=250;game.save.data.settings.music=false;game.save.data.settings.sfx=false;root.add_child(game);await process_frame
 for n in [1,25,49,250]:
  game.request_level(n);await create_timer(.3).timeout
  var panel=game.overlay.get_node("PreviewExplanation");var text=panel.get_child(0).get_node("ExplanationText");var count: int=panel.get_child_count()
  var goals
  for child in game.overlay.get_children():
   if child.get_script()==preload("res://scripts/ui/goals_panel.gd"):goals=child
  for tap in 30:
   var key: String=goals.targets.keys()[tap%goals.targets.size()];goals.goal_pressed.emit(key)
   assert(panel.get_child_count()==count and panel.get_child(0).get_node("ExplanationText")==text)
  await process_frame;await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://build/r2-preview-%d.png"%n)
  assert(panel.get_global_rect().end.y<game.overlay.get_children().filter(func(node):return node is Button and node.text=="OYNA!")[0].get_global_rect().position.y)
 game.close_overlay();game.save.data.unlocked=1;game.request_level(1);await create_timer(.3).timeout
 await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://build/r2-preview-locked.png")
 game.save.finish_writes();game.queue_free();await process_frame;await process_frame;print("PASS: single reused preview description, 120 rapid taps, 1/4/6/8 goals and locked controls");quit()
