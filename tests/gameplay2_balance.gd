extends SceneTree
const Board=preload("res://scripts/core/board.gd")
const Catalog=preload("res://scripts/core/level_catalog.gd")
const Solver=preload("res://tests/move_solver.gd")
var results: Array=[]
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var args:=OS.get_cmdline_user_args()
 var seeds:=int(args[0]) if args.size()>0 else 20
 var mode: String=args[1] if args.size()>1 else "before"
 var first:=int(args[2]) if args.size()>2 else 1
 var last:=int(args[3]) if args.size()>3 else 100
 for n in range(first,last+1):
  var d:=Catalog.get_level(n)
  var wins:=0;var usages: Array=[];var remaining: Array=[];var points: Array=[];var storms:=0;var waves:=0;var creations:=0;var max_cascade:=0;var guarded:=0
  for offset in seeds:
   var definition: Dictionary=d.duplicate(true);definition.seed=int(d.seed)+offset+(1000 if mode.begins_with("holdout") else 0)
   var b=Board.new(definition);var used:=0;var stagnant:=0;var last_progress:=0
   while b.available():
    if mode=="before" and stagnant>=4 and b.energy>0 and (b.collected.get("portals",0)>=int(d.targets.get("portals",0)) or b.direction!="down"):
     var directions: Array=["down","up","left","right"]
     b.change_gravity("down" if b.collected.get("portals",0)<int(d.targets.get("portals",0)) else directions[(directions.find(b.direction)+1)%4]);stagnant=0
     if not b.available():break
    var move:=Solver.best_move(b)
    if move.is_empty():break
    var e: Dictionary=b.swap(move[0],move[1]);assert(e.accepted)
    used+=1;creations+=e.created_count;max_cascade=maxi(max_cascade,e.cascade_count);guarded+=int(e.cascade_guard)
    storms+=int(e.get("storm",false));waves+=int(e.get("crystal_wave",false))
    var progress:=0
    for key in d.targets:progress+=mini(int(d.targets[key]),int(b.collected.get(key,0)))
    stagnant=stagnant+1 if progress==last_progress else 0;last_progress=progress
   if b.outcome=="won":wins+=1
   usages.append(used);remaining.append(b.moves);points.append(b.score)
  var sum_used:=0;var sum_left:=0
  for value in usages:sum_used+=value
  for value in remaining:sum_left+=value
  var row: Dictionary={"level":n,"moves":int(d.moves),"targets":d.targets,"blockers":d.get("mechanics",[]),"wins":wins,"seeds":seeds,"win_rate":float(wins)/seeds,"mean_used":float(sum_used)/seeds,"mean_remaining":float(sum_left)/seeds,"used":usages,"remaining":remaining,"scores":points,"power_creations":creations,"max_cascade":max_cascade,"storms":storms,"crystal_waves":waves,"cascade_guards":guarded}
  results.append(row)
  print("BALANCE %s %03d: %d/%d wins; mean %.1f used / %.1f remaining"%[mode,n,wins,seeds,row.mean_used,row.mean_remaining])
  var file:=FileAccess.open("res://build/gameplay2-balance-"+mode+".json",FileAccess.WRITE);file.store_string(JSON.stringify({"mode":mode,"seeds":seeds,"levels":results},"  "));file.close()
 print("BALANCE COMPLETE: ",mode," ",seeds*results.size()," games, ",results.size()," levels")
 quit()
