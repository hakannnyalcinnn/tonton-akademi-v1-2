extends SceneTree
const Board=preload("res://scripts/core/board.gd")
const Match=preload("res://scripts/core/match_detector.gd")
const Generator=preload("res://scripts/core/board_generator.gd")
const Catalog=preload("res://scripts/core/level_catalog.gd")
var checks:=0
var failures:=0
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures+=1;printerr(message)
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var d:=Catalog.get_level(62)
 check(int(d.targets.total)==195,"62 target remains 195")
 var b=Board.new(d)
 # Latin board with no three or match-producing adjacent swap.
 for i in 72:b.cells[i]={"id":i+1,"c":(i%8+int(i/8)*2)%5,"p":""}
 check(Match.find(b.cells,8,9).is_empty() and not Match.has_move(b.cells,8,9),"fixture is a true deadlock")
 var before:=b.snapshot()
 var ids: Array=b.cells.map(func(c):return c.id);ids.sort()
 var colors: Array=b.cells.map(func(c):return c.c);colors.sort()
 check(b.ensure_move(),"free shuffle starts")
 var after_ids: Array=b.cells.map(func(c):return c.id);after_ids.sort()
 var after_colors: Array=b.cells.map(func(c):return c.c);after_colors.sort()
 check(ids==after_ids and colors==after_colors,"shuffle preserves identities and color inventory")
 check(b.moves==before.moves and b.score==before.score and b.collected==before.collected and b.storm_charge()==before.energy*12+before.energy_blocks,"shuffle changes no resources or objectives")
 check(Match.find(b.cells,8,9).is_empty() and Match.has_move(b.cells,8,9),"shuffle produces a stable playable board")
 for seed_value in 30:
  d.seed=seed_value;b=Board.new(d)
  var saved:=b.snapshot()
  var legal:=Match.legal_swaps(b.cells,8,9)
  check(b.snapshot()==saved,"legal query has no side effects")
  for pair in legal:
   var clone=Board.new(d);clone.restore(saved)
   check(clone.swap(pair[0],pair[1]).accepted,"every detected move is accepted by engine")
 var solo: Array=[]
 for i in 72:solo.append({"id":i+1,"c":i%5,"p":"","fixed":true})
 solo[35]={"id":36,"c":0,"p":"rocket_h"}
 check(Match.has_move(solo,8,9),"isolated special activation prevents false deadlock")
 for direction in ["down","up","left","right"]:
  b=Board.new(d);b.direction=direction
  for i in 72:b.cells[i]={"id":i+1,"c":(i%8+int(i/8)*2)%5,"p":""}
  b.cells[27].fixed=true;b.cells[27]["armor"]={"kind":"ice","hp":2}
  b.cells[8]["motion"]={"kind":"bubble","hp":1}
  var fixed: Dictionary=b.cells[27].duplicate(true);var inventory: Array=b.cells.duplicate(true)
  check(b.ensure_move(),"barrier board recovers in "+direction)
  check(b.cells[27]==fixed,"fixed protection and identity retained")
  var bubble_id: int=inventory[8].id
  check(b.cells.any(func(c):return c.id==bubble_id and c.get("motion",{}).get("kind","")=="bubble"),"movable bubble layer retained")
  check(b.find_matches().is_empty() and Match.has_move(b.cells,8,9),"barrier shuffle stable")
 # Saved deadlocks are recovered rather than discarded on restart.
 b=Board.new(d)
 for i in 72:b.cells[i]={"id":i+1,"c":(i%8+int(i/8)*2)%5,"p":""}
 var dead_save:=b.snapshot();var resumed=Board.new(d)
 check(resumed.restore(dead_save) and Match.has_move(resumed.cells,8,9) and resumed.moves==dead_save.moves,"resume repairs deadlock without resource loss")
 print("DEADLOCK: %d checks, %d failures"%[checks,failures]);quit(int(failures>0))
