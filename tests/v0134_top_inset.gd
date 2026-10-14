extends SceneTree
const Save=preload("res://scripts/core/save_manager.gd")
var game
var errors:=0
var checks:=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:errors+=1;push_error(message)
func shot(name: String) -> void:
 await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://build/v0134/"+name+".png")
func run() -> void:
 var capture: bool="--capture" in OS.get_cmdline_user_args()
 var before: bool="--before" in OS.get_cmdline_user_args()
 root.size=Vector2i(390,844);root.content_scale_size=Vector2i(390,844)
 game=load("res://scenes/main.tscn").instantiate();game.production_mode=true;game.safe_rect_override=Rect2(0,36,390,784);game.save=Save.new("user://v0134-inset-fixture.json");game.save.data=Save.defaults();game.save.data.unlocked=245;game.save.data.settings.reduced_motion=true;game.save.data.settings.music=false;game.save.data.settings.sfx=false
 root.add_child(game);await process_frame;game.show_map(0);await process_frame;await process_frame
 if before:
  if capture:await shot("map-top-before")
  game.save.finish_writes();game.queue_free();await process_frame;quit();return
 for dimensions in [Vector2i(540,960),Vector2i(390,844),Vector2i(540,1170),Vector2i(540,1200)]:
  root.size=dimensions;root.content_scale_size=dimensions
  var top:=0 if dimensions.y==960 else 36 if dimensions.y==844 else 56
  game.safe_rect_override=Rect2(0,top,dimensions.x,dimensions.y-top-24);game.layout_stage()
  for w in range(1,6):
   game.show_map((w-1)*5);await process_frame;await process_frame
   var terrain=game.page.get_node("MapSceneBackdrop");terrain.sync_canvas()
   var full: Rect2=terrain.get_global_rect()
   check(full.position.distance_to(Vector2.ZERO)<.1 and full.size.distance_to(Vector2(dimensions))<.1,"Terrain fills visible viewport including unsafe top/bottom")
   check(game.stage.position.y>=top,"Interactive controls remain inside safe area")
   check(terrain.road_layer.get_global_transform_with_canvas().origin.distance_to(game.page.get_global_transform_with_canvas().origin)<.1,"Road and level coordinates unchanged when backdrop extends")
   check(is_equal_approx(terrain.material.get_shader_parameter("origin_y"),terrain.position.y),"World texture phase includes extended top origin")
   check(game.map_buttons.size()==50,"Existing level nodes preserved")
   if capture and w==1:await shot("map-top-fixed-%d"%dimensions.y)
 game.save.finish_writes();game.queue_free();await process_frame;await process_frame
 print(("PASS:" if errors==0 else "FAIL:")+" %d checks; 5 worlds x 4 phone ratios, safe-area background coverage and unchanged UI/road coordinates"%checks)
 quit(0 if errors==0 else 1)
