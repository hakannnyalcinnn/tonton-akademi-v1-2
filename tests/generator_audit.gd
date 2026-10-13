extends SceneTree
const Catalog=preload("res://scripts/core/level_catalog.gd")
const Board=preload("res://scripts/core/board.gd")
const Match=preload("res://scripts/core/match_detector.gd")
const Player=preload("res://scripts/generation/auto_player.gd")
var failures:=0
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var args:=OS.get_cmdline_user_args()
 var source: String=args[0];var destination: String=args[1]
 var modes: Array=args[2].split(",") if args.size()>2 else Player.MODES
 var count:=int(args[3]) if args.size()>3 else 1
 var document=JSON.parse_string(FileAccess.get_file_as_string(source));var rows: Array=[]
 for definition in document.levels:
  if not Catalog.validate(definition):printerr("FAIL: invalid definition ",definition.id);failures+=1;continue
  var initial=Board.new(definition)
  definition.layout=initial.cells.map(func(c):return int(c.c))
  var repeat=Board.new(definition)
  if not repeat.find_matches().is_empty() or not Match.has_move(repeat.cells,8,9):printerr("FAIL: initial board ",definition.id);failures+=1;continue
  var action_options:=Match.legal_swaps(repeat.cells,8,9)
  var opportunities:=0
  for pair in action_options:
   var preview:=Player.preview(repeat,pair[0],pair[1])
   if preview.powers>preview.largest:opportunities+=1
  definition.generation["initial_analysis"]={"legal_swaps":action_options.size(),"power_opportunities":opportunities,"playable_cells":72-definition.get("holes",[]).size()}
  var trials: Array=[]
  for mode in modes:
   for offset in count:
    var d: Dictionary=definition.duplicate(true);d.seed=int(d.seed)+offset*1009
    var b=Board.new(d);var guard:=false
    while b.available():
     var next:=Player.select(b,mode)
     if next.is_empty():printerr("FAIL: no action ",d.id);failures+=1;break
     var event:=Player.apply(b,next)
     if not event.accepted or event.cascade_guard or b.recovery_failed or not b.find_matches().is_empty():guard=true;failures+=1;printerr("FAIL: transaction ",d.id);break
    trials.append({"strategy":mode,"seed":int(d.seed),"won":b.outcome=="won","used":int(d.moves)-b.moves,"score":b.score,"remaining":b.moves,"guard":guard,"progress":b.collected.duplicate()})
  rows.append({"id":int(definition.id),"moves":int(definition.moves),"trials":trials,"initial":definition.generation.initial_analysis})
  print("AUDIT ",definition.id," ",trials.filter(func(t):return t.won).size(),"/",trials.size())
 var file=FileAccess.open(destination,FileAccess.WRITE);file.store_string(JSON.stringify({"levels":document.levels,"rows":rows,"failures":failures,"source_sha256":FileAccess.get_sha256(source),"godot":Engine.get_version_info().string},"  "));file.close()
 print("GENERATOR AUDIT: ",rows.size()," levels, ",failures," failures; simulation success is not proof of all-seed solvability");quit(int(failures>0))
