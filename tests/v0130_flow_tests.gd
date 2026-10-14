extends SceneTree
const Save=preload("res://scripts/core/save_manager.gd")
var game
var checks:=0
var errors:=0
func check(ok: bool) -> void:
 checks+=1
 if not ok:errors+=1;push_error("flow check %d failed"%checks)
func _initialize() -> void:call_deferred("run")
func run() -> void:
 game=load("res://scenes/main.tscn").instantiate();game.production_mode=true
 game.save=Save.new("user://v0130-flow-recheck-only.json");game.save.data=Save.defaults();game.save.data.settings.music=false;game.save.data.settings.sfx=false;game.save.data.settings.reduced_motion=true
 root.add_child(game);await process_frame
 game.show_worlds();await process_frame
 var planet=game.planet_view;planet.velocity=3.0;var yaw: float=planet.yaw
 planet._process(.1);check(planet.velocity>0 and planet.velocity<3 and planet.yaw>yaw)
 for i in 24:planet._process(.1)
 check(planet.velocity<.002)
 game._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST);check(game.screen=="map")
 game.request_level(1);await process_frame;check(game.overlay!=null)
 game._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST);check(game.overlay==null and game.screen=="map")
 game.start_level(1);game.close_goal_tip();await process_frame
 check(game.screen=="game" and game.board.level.id==1)
 game._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST);check(game.paused and game.overlay!=null)
 var actions=game.overlay.get_node("PausePanel").find_child("PauseActions",true,false)
 check(actions is HBoxContainer and actions.get_child_count()==3)
 check(actions.get_child(0).caption=="Yeniden Oyna" and actions.get_child(1).caption=="Ayarlar" and actions.get_child(2).caption=="Harita")
 game._notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST);check(not game.paused and game.overlay==null)
 game.board.outcome="won";game.board.score=10000;game.show_result();await process_frame
 game.save.finish_writes();check(game.save.data.unlocked==2 and game.save.data.results.has("1"))
 var saved=Save.new("user://v0130-flow-recheck-only.json");check(saved.load_save() and saved.data.results["1"].stars==game.save.data.results["1"].stars)
 var buttons=game.overlay.find_children("*","Button",true,false).filter(func(n):return n.text=="SONRAKİ BÖLÜM")
 check(buttons.size()==1);buttons[0].pressed.emit();await process_frame
 check(game.screen=="game" and game.overlay.find_child("PreviewLayout",true,false)!=null)
 var play=game.overlay.find_children("*","Button",true,false).filter(func(n):return n.text=="OYNA!")[0]
 play.pressed.emit()
 var deadline:=Time.get_ticks_msec()+2000
 while game.screen=="transition" and Time.get_ticks_msec()<deadline:await process_frame
 check(game.screen=="game" and game.board.level.id==2)
 game.save.finish_writes();game.queue_free();await process_frame;await process_frame
 print(("PASS" if errors==0 else "FAIL")+": %d flow checks; inertia, simulated Android back, win-save/reload and direct next level; isolated profile"%checks);quit(0 if errors==0 else 1)
