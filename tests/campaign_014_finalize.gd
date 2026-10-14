extends SceneTree
const L=preload("res://scripts/core/level_catalog.gd")
const B=preload("res://scripts/core/board.gd")
const M=preload("res://scripts/core/match_detector.gd")
const P=preload("res://scripts/generation/auto_player.gd")
var errors:=0
func _initialize() -> void:call_deferred("run")
func play(d: Dictionary,mode: String,trace: Array=[]) -> Dictionary:
 var b=B.new(d);var actions: Array=[];var steps:=0
 while b.available() and steps<100:
  var next: Array=trace[steps] if steps<trace.size() else P.select(b,mode)
  if next.is_empty():break
  var event: Dictionary=P.apply(b,next);actions.append(next);steps+=1
  if not event.accepted or event.cascade_guard or b.recovery_failed:errors+=1;break
 return {"mode":mode,"seed":int(d.seed),"won":b.outcome=="won","used":steps,"trace":actions,"score":b.score}
func normalize(d: Dictionary) -> bool:
 for attempt in 8:
  var b=B.new(d);var layout: Array=b.cells.map(func(c):return int(c.c))
  if layout==d.layout and b.find_matches().is_empty() and M.has_move(b.cells,8,9):return true
  d.layout=layout
 return false
func run() -> void:
 var previous=JSON.parse_string(FileAccess.get_file_as_string("res://build/v0140/audit-251-500.json"));var by_id: Dictionary={}
 for row in previous.rows:by_id[int(row.id)]=row
 var reports: Array=[];var unresolved: Array=[];var edits: Array=[]
 for start in [251,301,351,401,451]:
  var path:="res://data/levels-%d-%d.json"%[start,start+49];var document=JSON.parse_string(FileAccess.get_file_as_string(path))
  for d in document.levels:
   var original: Dictionary=d.duplicate(true);var normalized:=normalize(d)
   if not normalized:unresolved.append(d.id);continue
   var row: Dictionary=by_id[int(d.id)];var trials: Array=[];var winning: Dictionary={}
   if row.trials[0].won and original.layout==d.layout:
    winning=play(d,"objective",row.trials[0].trace);trials.append(winning)
   if winning.is_empty() or not winning.won:
    for mode in ["objective","obstacles","powers"]:
     var trial:=play(d,mode);trials.append(trial)
     if trial.won:winning=trial;break
   if winning.is_empty() or not winning.get("won",false):
    for seed_offset in range(1,4):
     d.seed=int(original.seed)+seed_offset*1009
     if not normalize(d):continue
     var trial:=play(d,"objective");trials.append(trial)
     if trial.won:winning=trial;break
   if winning.is_empty() or not winning.get("won",false):unresolved.append(d.id);reports.append({"id":d.id,"trials":trials});continue
   var margin: int={"easy":4,"medium":3,"hard":2,"very_hard":1}[d.difficulty]
   if int(d.id)%50 in [1,2,3]:margin+=2
   d.moves=mini(int(d.moves),maxi(12,int(winning.used)+margin))
   var verified:=play(d,str(winning.mode),winning.trace)
   if not verified.won:unresolved.append(d.id);continue
   d.generation.status="simulation_reviewed";d.generation.seed=d.seed
   d.generation.evidence={"trials":trials.size(),"human_tested":false,"default_seed_witness":true,"strategy":winning.mode,"trace_sha256":JSON.stringify(verified.trace).sha256_text(),"winning_moves":verified.used}
   var initial=B.new(d);d.generation.initial_analysis={"legal_swaps":M.legal_swaps(initial.cells,8,9).size(),"playable_cells":72-d.holes.size()}
   if original.seed!=d.seed or original.moves!=d.moves or original.layout!=d.layout:edits.append({"id":d.id,"old_moves":original.moves,"moves":d.moves,"old_seed":original.seed,"seed":d.seed,"layout_normalized":original.layout!=d.layout})
   reports.append({"id":d.id,"trials":trials,"witness":verified,"moves":d.moves})
  var out:=FileAccess.open(path,FileAccess.WRITE);out.store_string(JSON.stringify(document,"  "));out.close();print("FINALIZED ",start,"–",start+49)
 var report:=FileAccess.open("res://build/v0140/final-campaign-audit.json",FileAccess.WRITE);report.store_string(JSON.stringify({"rows":reports,"unresolved":unresolved,"engine_errors":errors,"edits":edits}));report.close()
 print("PASS: campaign authoring complete; unresolved ",unresolved," engine errors ",errors);quit(0 if unresolved.is_empty() and errors==0 else 1)
