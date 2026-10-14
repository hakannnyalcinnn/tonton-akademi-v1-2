extends SceneTree
const Save=preload("res://scripts/core/save_manager.gd")
var game
func _initialize() -> void:call_deferred("run")
func shot(name: String) -> void:
 await process_frame;await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://build/v130-"+name+".png")
func run() -> void:
 game=load("res://scenes/main.tscn").instantiate();game.production_mode=true;game.save=Save.new("user://v130-small-render-only.json");game.save.data=Save.defaults();game.save.data.unlocked=250;game.save.data.settings.music=false;game.save.data.settings.sfx=false;game.save.data.settings.reduced_motion=true;root.add_child(game);await process_frame
 for dimensions in [Vector2i(320,568),Vector2i(390,844)]:
  root.size=dimensions;await process_frame;game.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT);await process_frame;game.size=game.get_viewport_rect().size;game.selected_world=4;game.show_worlds();await process_frame;await shot("small-planet-%d"%dimensions.x)
  game.show_map(0);game.request_level(49);await process_frame;await process_frame
  var panel=game.overlay.find_child("PreviewExplanation",true,false);panel.get_child(0).get_child(0).text="Uzun Türkçe açıklama kristal hedeflerini ve farklı engelleri anlatır. ".repeat(20)
  await process_frame;await process_frame;await shot("small-preview-%d"%dimensions.x)
  var play=game.overlay.find_children("*","Button",true,false).filter(func(n):return n.text=="OYNA!")[0]
  assert(play.get_global_rect().end.y<=game.size.y and panel.get_global_rect().end.y<play.get_global_rect().position.y)
  game.show_help();await process_frame
  var scroll=game.overlay.get_node("DialogFlow/TextScroll");scroll.get_child(0).text+="Uzun yardım açıklaması. ".repeat(80)
  await process_frame;await process_frame;assert(scroll.get_global_rect().end.y<=game.overlay.get_node("DialogFlow/DialogActions").get_global_rect().position.y);await shot("small-help-%d"%dimensions.x)
  game.close_overlay();game.start_level(205);game.close_goal_tip();game.show_pause();await process_frame;await shot("small-pause-%d"%dimensions.x);game.close_overlay()
 game.save.finish_writes();game.queue_free();await process_frame;await process_frame;print("PASS: actual 320x568 and 390x844 planet, six-goal preview, long scroll help and world-correct pause renders");quit()
