extends SceneTree
const Save=preload("res://scripts/core/save_manager.gd")
const Icons=preload("res://scripts/ui/visual_icon_button.gd")
var game
func _initialize() -> void:call_deferred("run")
func shot(name: String) -> void:
 await process_frame;await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://build/r2-"+name+".png")
func run() -> void:
 root.size=Vector2i(540,1200);game=load("res://scenes/main.tscn").instantiate();game.production_mode=true;game.save=Save.new("user://r2-interface-only.json");game.save.data=Save.defaults();game.save.data.unlocked=250;game.save.data.settings.music=false;game.save.data.settings.sfx=false;root.add_child(game);await process_frame
 for height in [960,1080,1170,1200]:
  root.size=Vector2i(540,height);game.size=Vector2(540,height);game.request_level(49);await process_frame
  var panel=game.overlay.get_node("PreviewExplanation");var text=panel.get_node("ExplanationText");var child_count: int=panel.get_child_count()
  text.add_theme_font_size_override("normal_font_size",22)
  for tap in 50:
   text.text="Renk enerjisi toplayarak kilitleri aç. Çok aşamalı hedefleri tamamlamak için kristalleri eşleştir. Uzun Türkçe açıklamalar burada kalır, OYNA düğmesinin üzerine taşmaz."
  assert(panel.get_child_count()==child_count and text.scroll_active)
  var play=game.overlay.get_children().filter(func(node):return node is Button and node.text=="OYNA!")[0]
  assert(panel.get_global_rect().end.y<play.get_global_rect().position.y)
  await shot("preview-ratio-%d"%height);game.close_overlay()
 root.size=Vector2i(540,1200);game.size=Vector2(540,1200);game.request_level(25);await process_frame
 var rocket=game.overlay.get_children().filter(func(node):return node is Icons and node.get_meta("booster","")=="rocket")[0]
 var stock: int=game.save.data.adventure_progress.inventory.rocket
 rocket.pressed.emit();assert(game.selected_booster=="rocket" and rocket.chosen and game.save.data.adventure_progress.inventory.rocket==stock);await shot("selected-booster");game.close_overlay();assert(game.save.data.adventure_progress.inventory.rocket==stock)
 game.request_level(25);await process_frame;assert(game.selected_booster=="");game.close_overlay()
 game.start_level(25);game.close_goal_tip();await process_frame;game.board.moves=3;game.update_hud();await shot("three-moves")
 game.helper_buttons.rocket.pressed.emit();await shot("helper-targeting");game.helper_buttons.rocket.pressed.emit();assert(game.armed_helper=="")
 game.show_goal_description(game.board.active_targets().keys()[0],true);await shot("goal-explanation");game.close_goal_tip()
 game.audio.settings.sfx=true;var cursor: int=game.audio.cursor;game.audio.play("fall_group");game.audio.play("fall_group");assert(game.audio.cursor==cursor+1 and game.audio.voices.size()==5);game.audio.settings.sfx=false;game.audio.play("touch");assert(game.audio.cursor==cursor+1)
 await create_timer(.2).timeout
 game.save.finish_writes();game.queue_free();await process_frame;await process_frame;print("PASS: four aspect ratios, enlarged long Turkish text, 200 text updates, stock cancellation, targeting, three moves, bounded cached audio");quit()
