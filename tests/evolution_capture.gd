extends SceneTree
const S=preload("res://scripts/core/save_manager.gd")
var game
func _initialize() -> void:call_deferred("run")
func shot(name: String) -> void:
 for attempt in 180:
  if game.garden.pending_art=="":break
  await process_frame
 assert(game.garden.pending_art=="")
 await process_frame;await process_frame;await RenderingServer.frame_post_draw
 root.get_texture().get_image().save_png("res://build/v0141/"+name+".png")
func run() -> void:
 root.size=Vector2i(540,1170);root.content_scale_size=root.size
 game=load("res://scenes/main.tscn").instantiate();game.production_mode=true;game.save=S.new("user://v0141-capture-only.json");game.save.data=S.defaults();game.save.data.unlocked=500;game.save.data.settings.music=false;game.save.data.settings.sfx=false
 root.add_child(game);await process_frame;await process_frame
 await shot("map-continue")
 game.EconomyScreen.build(game,"collection");await shot("friends-top")
 var scroll=game.overlay.find_child("EconomyScroll",true,false);scroll.scroll_vertical=10000;await shot("friends-bottom")
 game.close_overlay()
 for row in [[61,"cargo"],[151,"shutter"],[301,"relay"],[351,"key-gate"],[401,"balance"],[500,"finale"]]:
  game.start_level(int(row[0]));game.close_goal_tip();await shot(str(row[1]))
 game.start_level(301);game.close_goal_tip();var a:=-1
 for i in 71:
  if i%8<7 and not game.board.cells[i].get("fixed",false) and not game.board.cells[i+1].get("fixed",false):a=i;break
 assert(a>=0);game.board.cells[a].p="color";game.board.cells[a+1].p="color"
 var event: Dictionary=game.board.swap(a,a+1);assert(event.accepted);game.board_view.animate(event)
 var frame_number:=0
 while game.board_view.busy:
  if not game.board_view.current.get("evolution_events",[]).is_empty() and frame_number<3:
   await shot("relay-animation-%d"%frame_number);frame_number+=1
  await process_frame
 assert(frame_number==3)
 root.size=Vector2i(540,960);root.content_scale_size=root.size;game.start_level(401);game.close_goal_tip();await shot("balance-16x9")
 game.save.finish_writes();game.queue_free();await process_frame;await process_frame;print("PASS: real Godot new mechanics, modal scrolling, 16:9 and animated relay frames");quit()
