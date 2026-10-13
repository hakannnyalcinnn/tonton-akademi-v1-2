extends SceneTree
const Catalog=preload("res://scripts/core/level_catalog.gd")
const Board=preload("res://scripts/core/board.gd")
const Solver=preload("res://tests/move_solver.gd")
const Match=preload("res://scripts/core/match_detector.gd")
var seeds:=3
var first:=101
var last:=150
var seed_start:=0
var report:="canyon-balance"
var failures:=0
var rows: Array=[]
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var args:=OS.get_cmdline_user_args()
 if args.size()>0:seeds=int(args[0])
 if args.size()>1:first=int(args[1])
 if args.size()>2:last=int(args[2])
 if args.size()>3:seed_start=int(args[3])
 if args.size()>4:report=args[4]
 for n in range(first,last+1):
  var definition:=Catalog.get_level(n)
  if not Catalog.validate(definition):printerr("INVALID LEVEL ",n);failures+=1;continue
  var wins:=0;var used:=0
  var samples: Array=[]
  for offset in seeds:
   var d:=definition.duplicate(true);d.seed+=offset+seed_start
   var b=Board.new(d)
   while b.outcome=="playing" and b.moves>0:
    var options:=Match.legal_swaps(b.cells,8,9)
    if options.is_empty():
     var index: int=b.cells.find_custom(func(c):return c!=null and not c.get("fixed",false) and c.p!="")
     if index<0:printerr("DEADLOCK ",n);failures+=1;break
     b.activate(index,0)
    else:
     var move:=Solver.best_move(b);b.swap(move[0],move[1])
    if not b.find_matches().is_empty():printerr("UNSTABLE ",n);failures+=1;break
   wins+=int(b.outcome=="won");used+=int(d.moves)-b.moves
   samples.append({"win":b.outcome=="won","used":int(d.moves)-b.moves,"score":b.score})
  rows.append({"level":n,"wins":wins,"samples":samples,"games":seeds,"moves":definition.moves,"mean_used":float(used)/seeds})
  print("LEVEL ",n," wins ",wins,"/",seeds)
 var f=FileAccess.open("res://build/"+report+".json",FileAccess.WRITE);f.store_string(JSON.stringify(rows,"  "))
 print("CANYON LEVELS: ",failures," invariant failures");quit(int(failures>0))
