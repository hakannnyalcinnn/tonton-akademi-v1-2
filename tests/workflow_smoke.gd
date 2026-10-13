extends SceneTree
const Board=preload("res://scripts/core/board.gd")
const Catalog=preload("res://scripts/core/level_catalog.gd")
const Match=preload("res://scripts/core/match_detector.gd")
const Gravity=preload("res://scripts/core/gravity.gd")
const Save=preload("res://scripts/core/save_manager.gd")
var checks:=0
var failures:=0
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures+=1;printerr("FAIL: "+message)
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var simple: Array=[]
 for i in 9:simple.append({"id":i+1,"c":i%3,"p":""})
 simple[0].c=0;simple[1].c=0;simple[2].c=0
 check(0 in Match.indices(Match.find(simple,3,3)),"horizontal match")
 var d:=Catalog.get_level(7);d.targets={"total":100000}
 var b=Board.new(d);var legal:=Match.legal_swaps(b.cells,8,9)
 check(not legal.is_empty() and b.find_matches().is_empty(),"playable stable opening")
 var invalid: Array=[]
 for a in 72:
  for destination in Match.neighbors(a,8,9):
   if not Match.can_swap(b.cells,a,destination,8,9):invalid=[a,destination];break
  if not invalid.is_empty():break
 var before: Dictionary=b.snapshot()
 var bad: Dictionary=b.swap(invalid[0],invalid[1])
 check(not bad.accepted and b.snapshot()==before,"invalid swap rolls back without cost")
 var event: Dictionary=b.swap(legal[0][0],legal[0][1])
 check(event.accepted and b.moves==int(before.moves)-1,"valid swap costs one move")
 check(event.cascade_count>0 and b.find_matches().is_empty(),"automatic clear settles")
 var cells: Array=[null,{"id":1,"c":0,"p":""},null,{"id":2,"c":1,"p":""}]
 Gravity.compact(cells,2,2,"down")
 check(cells[3].id==2 and cells[1].id==1,"gravity retains order")
 var path: String="user://workflow-smoke-only.json"
 var save=Save.new(path);save.data=Save.defaults();save.data.unlocked=7;save.save_active(b);save.finish_writes()
 var loaded=Save.new(path);var clone=Board.new(d)
 check(clone.restore(loaded.data.active) and clone.snapshot()==b.snapshot(),"disk save roundtrip")
 var game=load("res://scenes/main.tscn").instantiate();game.save=Save.new("user://workflow-smoke-ui-only.json");game.save.data=Save.defaults();game.save.data.settings.music=false;game.save.data.settings.sfx=false
 root.add_child(game);await process_frame
 check(game.screen=="home" and game.stage!=null,"game startup")
 game.save.finish_writes();game.queue_free();await process_frame;await process_frame
 for suffix in ["",".bak",".tmp"]:
  if FileAccess.file_exists(path+suffix):DirAccess.remove_absolute(ProjectSettings.globalize_path(path+suffix))
 print("SMOKE: %d checks, %d failures"%[checks,failures]);quit(int(failures>0))
