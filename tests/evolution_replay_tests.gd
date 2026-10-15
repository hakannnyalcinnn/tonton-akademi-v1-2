extends SceneTree
const L=preload("res://scripts/core/level_catalog.gd")
const B=preload("res://scripts/core/board.gd")
const P=preload("res://scripts/generation/auto_player.gd")
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var traces=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/v0141-witnesses.json"));var failed: Array=[];var actions:=0
 for key in traces:
  var d:=L.get_level(int(key));var b=B.new(d);var valid:=true
  for pair in traces[key].trace:
   if b.outcome=="won":break
   var event: Dictionary=P.apply(b,pair);actions+=1
   if not event.accepted or event.cascade_guard or b.recovery_failed:valid=false;break
  var restored=B.new(d)
  if not valid or b.outcome!="won" or not restored.restore(JSON.parse_string(JSON.stringify(b.snapshot()))):failed.append(int(key))
 print(("PASS:" if failed.is_empty() else "FAIL:")+" 69 full new/reused-mechanic completion + JSON save replays; %d actions; failed %s"%[actions,failed]);quit(0 if failed.is_empty() else 1)
