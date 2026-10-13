extends SceneTree
const Catalog=preload("res://scripts/core/level_catalog.gd")
const Board=preload("res://scripts/core/board.gd")
const Solver=preload("res://tests/move_solver.gd")
const Match=preload("res://scripts/core/match_detector.gd")
var checks:=0
var failures:=0
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures+=1;printerr("FAIL "+message)
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var args:=OS.get_cmdline_user_args()
 var first:=int(args[0]) if not args.is_empty() else 1
 var last:=int(args[1]) if args.size()>1 else Catalog.count()
 var rows: Array=[]
 for n in range(first,last+1):
  var d:=Catalog.get_level(n);check(Catalog.validate(d),"definition "+str(n))
  var b=Board.new(d);var clone=Board.new(d)
  check(b.snapshot()==clone.snapshot(),"seeded initial state "+str(n))
  while b.outcome=="playing" and b.moves>0 and not b.recovery_failed:
   var move:=Solver.best_move(b);var event: Dictionary=preload("res://scripts/generation/auto_player.gd").apply(b,move);preload("res://scripts/generation/auto_player.gd").apply(clone,move)
   check(event.accepted and b.snapshot()==clone.snapshot(),"deterministic accepted transaction "+str(n))
   check(b.find_matches().is_empty() and Match.has_move(b.cells,8,9),"stable and playable "+str(n))
   var restored=Board.new(d);check(restored.restore(b.snapshot()) and restored.snapshot()==b.snapshot(),"roundtrip "+str(n))
  check(b.outcome=="won","default seed completable "+str(n))
  rows.append({"level":n,"win":b.outcome=="won","used":int(d.moves)-b.moves})
 var f=FileAccess.open("res://build/v010-campaign-smoke-%d-%d.json"%[first,last],FileAccess.WRITE);f.store_string(JSON.stringify(rows,"  "))
 print("CAMPAIGN: %d checks, %d failures, %d default seeds replayed"%[checks,failures,last-first+1]);quit(int(failures>0))
