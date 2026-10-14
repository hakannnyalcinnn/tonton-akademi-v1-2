extends SceneTree
const L=preload("res://scripts/core/level_catalog.gd")
const B=preload("res://scripts/core/board.gd")
const M=preload("res://scripts/core/match_detector.gd")
const P=preload("res://scripts/generation/auto_player.gd")
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var args:=OS.get_cmdline_user_args();var first:=int(args[0]) if args.size()>0 else 251;var last:=int(args[1]) if args.size()>1 else 500;var report: Array=[];var failures:=0
 for n in range(first,last+1):
  var d:=L.get_level(n);var row: Dictionary={"id":n,"valid":L.validate(d),"trials":[]}
  if not row.valid:failures+=1;report.append(row);continue
  var initial=B.new(d)
  row.initial_matches=initial.find_matches().size();row.legal_swaps=M.legal_swaps(initial.cells,8,9).size();row.layout=initial.cells.map(func(c):return int(c.c))
  if row.initial_matches>0 or row.legal_swaps==0:failures+=1
  for mode in ["objective"]:
   var board=B.new(d);var guard:=0;var trace: Array=[]
   while board.available() and guard<100:
    var action:=P.select(board,mode)
    if action.is_empty():break
    trace.append(action);var event: Dictionary=P.apply(board,action);guard+=1
    if not event.accepted or event.cascade_guard or board.recovery_failed:failures+=1;break
   row.trials.append({"strategy":mode,"won":board.outcome=="won","used":d.moves-board.moves,"progress":board.collected.duplicate(),"score":board.score,"trace":trace})
  report.append(row)
  if n%10==0:print("AUDIT ",n," through ",last)
 var out:=FileAccess.open("res://build/v0140/audit-%d-%d.json"%[first,last],FileAccess.WRITE);out.store_string(JSON.stringify({"rows":report,"engine_failures":failures}));out.close();print("PASS: campaign audit ended, ",report.size()," levels; engine failures ",failures);quit(1 if failures>0 else 0)
