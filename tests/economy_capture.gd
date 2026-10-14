extends SceneTree
const S=preload("res://scripts/core/save_manager.gd")
const E=preload("res://scripts/core/economy.gd")
var game
func _initialize() -> void:call_deferred("run")
func shot(name: String) -> void:
 await process_frame;await process_frame;await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://build/v0140/"+name+".png")
func run() -> void:
 root.size=Vector2i(540,1170);root.content_scale_size=Vector2i(540,1170)
 game=load("res://scenes/main.tscn").instantiate();game.production_mode=true;game.save=S.new("user://v0140-capture-fixture.json");game.save.data=S.defaults();game.save.data.unlocked=500;game.save.data.settings.music=false;game.save.data.settings.sfx=false;game.save.data.settings.reduced_motion=true
 for n in range(1,111):game.save.data.results[str(n)]={"score":10000,"stars":3}
 E.ensure(game.save.data);game.save.data.adventure_progress.coins=1250;root.add_child(game);await process_frame
 for tab in ["login","missions","shop","collection","achievements"]:
  game.EconomyScreen.build(game,tab);await shot(tab)
 game.close_overlay();game.start_level(111);game.close_goal_tip();game.board.outcome="won";game.board.score=12000;game.show_result();await shot("level-rewards")
 for w in range(6,11):game.show_map((w-1)*5);await shot("world-%d"%w)
 root.size=Vector2i(320,568);root.content_scale_size=Vector2i(320,568);game.EconomyScreen.build(game,"shop");await shot("shop-small")
 game.save.finish_writes();game.queue_free();await process_frame;await process_frame;print("PASS: actual Godot economy UI captures and five new world maps");quit()
