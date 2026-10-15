extends SceneTree
const L=preload("res://scripts/core/level_catalog.gd")
const B=preload("res://scripts/core/board.gd")
const P=preload("res://scripts/generation/auto_player.gd")
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var report: Array=[];var failures: Array=[];var engine_errors:=0;var witnesses: Dictionary={}
 var selected: Array=Array(OS.get_cmdline_user_args()).map(func(n):return int(n))
 if not selected.is_empty():witnesses=JSON.parse_string(FileAccess.get_file_as_string("res://build/v0141/witnesses.json"))
 for n in range(1,501):
  if not selected.is_empty() and n not in selected:continue
  var d:=L.get_level(n)
  if not d.has("evolution_revision"):continue
  var trials: Array=[];var won:=false
  for mode in ["objective","obstacles","powers"]:
   var b=B.new(d);var trace: Array=[]
   while b.available() and trace.size()<80:
    var action:=P.select(b,mode)
    if action.is_empty():break
    var event: Dictionary=P.apply(b,action);trace.append(action)
    if not event.get("accepted",false) or event.cascade_guard or b.recovery_failed:engine_errors+=1;break
   trials.append({"mode":mode,"won":b.outcome=="won","moves":trace.size(),"progress":b.collected,"trace":trace})
   if b.outcome=="won":won=true;witnesses[str(n)]={"trace":trace,"mode":mode,"seed":d.seed};break
  if not won:failures.append(n)
  report.append({"id":n,"won":won,"trials":trials})
 var file:=FileAccess.open("res://build/v0141/campaign-audit.json" if selected.is_empty() else "res://build/v0141/campaign-risk.json",FileAccess.WRITE);file.store_string(JSON.stringify({"rows":report,"failed":failures,"engine_errors":engine_errors}));file.close()
 file=FileAccess.open("res://build/v0141/witnesses.json",FileAccess.WRITE);file.store_string(JSON.stringify(witnesses));file.close()
 print("AUDIT: ",report.size()," evolved levels; unresolved ",failures,"; engine errors ",engine_errors);quit(0 if failures.is_empty() and engine_errors==0 else 1)
