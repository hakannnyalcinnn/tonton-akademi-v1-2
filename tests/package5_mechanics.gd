extends SceneTree
const Board=preload("res://scripts/core/board.gd")
const Scenarios=preload("res://scripts/mechanics/developer_scenarios.gd")
const Mechanics=preload("res://scripts/mechanics/mechanic_manager.gd")
const Fountain=preload("res://scripts/mechanics/painting_fountain.gd")
const Bubble=preload("res://scripts/mechanics/floating_bubble.gd")
const Conveyor=preload("res://scripts/mechanics/conveyor_rails.gd")
const Seal=preload("res://scripts/mechanics/sequence_seal.gd")
const Portal=preload("res://scripts/mechanics/portal_manager.gd")
const Match=preload("res://scripts/core/match_detector.gd")
const Solver=preload("res://tests/move_solver.gd")
const Catalog=preload("res://scripts/core/level_catalog.gd")
var checks:=0
var failures:=0
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures+=1;push_error(message)
func _initialize() -> void:call_deferred("run")
func run() -> void:
 # Fountain excludes protected/dual/bridge/power/bubble; distance then ascending coordinate.
 var b=Board.new(Scenarios.make("fountain",4));var cells: Array=b.cells.duplicate(true)
 for c in cells:
  if c!=null and not c.get("fixed",false) and not c.has("trait"):c.c=2
 Mechanics.install(cells,[{"kind":"ice","index":34},{"kind":"bubble","index":36}]);cells[43].p="rocket_h"
 var used: Dictionary={};var e:=Fountain.activate(cells,[27],used,8,9)
 check(e.size()==1 and e[0].painted.size()==3,"fountain activates with three eligible targets")
 check(e[0].painted.map(func(c):return c.index)==[27,19,26],"nearest distance / coordinate order")
 for hit in e[0].painted:check(cells[hit.index].c==1,"configured color applied")
 check(cells[47].trait.colors==[0,1] and cells[50].trait.kind=="bridge","dual and bridge preserved")
 check(cells[34].armor.kind=="ice" and cells[36].motion.kind=="bubble" and cells[43].p=="rocket_h","protected layers and powers excluded")
 check(Fountain.activate(cells,[27],used,8,9).is_empty(),"once per player action, including cascades")
 check(Fountain.activate(cells,[71],{},8,9).is_empty(),"nonadjacent match cannot paint")
 b=Board.new(Scenarios.make("fountain",4));var event: Dictionary=b.swap(20,28)
 check(event.accepted and b.moves==99 and b.collected.fountains==1,"fountain real swap costs exactly one move")
 check(event.frames.filter(func(f):return f.kind=="paint").size()==1 and b.find_matches().is_empty(),"fountain cascade settles without input")
 # Bubble rises toward opposing edge. Fixed blocker stops travel; IDs and layers conserved.
 for direction in ["down","up","left","right"]:
  b=Board.new(Scenarios.make("bubble",3));cells=[];cells.resize(72)
  var source: int={"down":40,"up":24,"left":27,"right":28}[direction]
  var destination: int={"down":0,"up":64,"left":31,"right":24}[direction]
  cells[source]=b.make_cell(1);Mechanics.install(cells,[{"kind":"bubble","index":source}]);var id: int=cells[source].id
  Bubble.compact(cells,8,9,direction)
  check(cells[destination]!=null and cells[destination].id==id and Bubble.present(cells[destination]),"bubble opposite gravity "+direction)
  check(cells.filter(func(c):return c!=null).size()==1,"bubble no cloning "+direction)
  check(not cells[destination].get("fixed",false),"temporary gravity blocker restored")
 cells=[];cells.resize(72);cells[40]=b.make_cell();cells[24]=b.make_cell();Mechanics.install(cells,[{"kind":"bubble","index":40},{"kind":"stone","index":24}]);Bubble.compact(cells,8,9,"down")
 check(Bubble.present(cells[32]) and cells[24].obstacle.kind=="stone","bubble never crosses fixed obstacle")
 var id: int=cells[32].id;var progress: Dictionary={"bubbles":0}
 check(Bubble.break_layers(cells,[32],progress)==[32] and cells[32].id==id and not Bubble.present(cells[32]) and progress.bubbles==1,"bubble break retains actual crystal / separate count")
 check(Bubble.break_layers(cells,[32],progress).is_empty() and progress.bubbles==1,"bubble not double counted")
 cells=[];cells.resize(72);cells[8]=b.make_cell();Mechanics.install(cells,[{"kind":"bubble","index":8}]);id=cells[8].id
 check(Portal.transfer(cells,[{"entry":8,"exit":3}],{id:true},{},[]).size()==1 and Bubble.present(cells[3]),"bubble portal preserves movement layer")
 # Conveyor closed loop and controlled segment: exact simultaneous cell permutation.
 cells=[];cells.resize(72)
 for i in [26,27,35,34]:cells[i]=b.make_cell(i%5)
 var rail: Array=[{"cells":[26,27,35,34],"loop":true}];var before: Array=cells.duplicate(true)
 e=Conveyor.advance(cells,rail)
 check(e.size()==4 and cells[27].id==before[26].id and cells[35].id==before[27].id and cells[34].id==before[35].id and cells[26].id==before[34].id,"closed conveyor moves all simultaneously")
 check(cells.filter(func(c):return c!=null).map(func(c):return c.id).size()==4,"no conveyor losses")
 Mechanics.install(cells,[{"kind":"stone","index":35}]);before=cells.duplicate(true);e=Conveyor.advance(cells,rail)
 check(e.is_empty() and cells==before,"blocked full loop cannot overwrite stone or drop crystals")
 cells=[];cells.resize(72);cells[26]=b.make_cell();cells[27]=b.make_cell();before=cells.duplicate(true)
 e=Conveyor.advance(cells,[{"cells":[26,27,28],"loop":false}]);check(e.size()==2 and cells[27].id==before[26].id and cells[28].id==before[27].id and cells[26]==null,"controlled linear chain uses vacancy")
 var moved_id: int=cells[28].id
 check(Portal.transfer(cells,[{"entry":28,"exit":0}],{moved_id:true},{},[]).size()==1 and cells[0].id==moved_id,"conveyor arrival can transfer through portal")
 check(Conveyor.validate(rail) and not Conveyor.validate([{"cells":[0,2],"loop":false}]) and not Conveyor.validate(rail+rail),"rail topology / cross-rail duplicate validation")
 b=Board.new(Scenarios.make("conveyor",5));event=b.swap(Solver.best_move(b)[0],Solver.best_move(b)[1])
 check(event.accepted and event.frames.filter(func(f):return f.kind=="conveyor").size()==1 and b.moves==99 and b.find_matches().is_empty(),"one conveyor turn per valid player move; cascades stable")
 # Sequence receives one centralized primary color; cascades never invoke it.
 b=Board.new(Scenarios.make("seal",3));progress=b.collected
 e=Seal.advance(b.cells,0,progress);check(b.cells[35].obstacle.step==1 and e[0].correct,"seal correct first color")
 e=Seal.advance(b.cells,2,progress);check(b.cells[35].obstacle.step==0 and not e[0].correct,"wrong color resets")
 Seal.advance(b.cells,0,progress);Seal.advance(b.cells,1,progress);e=Seal.advance(b.cells,2,progress)
 check(b.cells[35]==null and progress.seals==1 and e[0].opened,"sequence opens / objective increments once")
 check(Seal.advance(b.cells,2,progress).is_empty() and progress.seals==1,"opened seal no double count")
 var d:=Scenarios.make("seal",5);d.mechanics=[{"kind":"seal","index":35,"sequence":[0,0,0,0,0]}]
 b=Board.new(d);var pair:=Solver.best_move(b);event=b.swap(pair[0],pair[1])
 check(event.frames.filter(func(f):return f.kind=="seal").size()==1,"automatic cascades produce only one seal update")
 check(b.resonance.color==event.primary_color and b.resonance.count==1,"seal and resonance share deterministic normal primary color")
 b=Board.new(d);b.cells[10].p="rocket_h";event=b.activate(10)
 check(event.accepted and event.frames.filter(func(f):return f.kind=="seal").size()==1 and b.moves==99,"special action feeds one explicitly defined primary color")
 # 800 seeded developer boards, 8 actions each; repeatable, conservation and snapshots.
 var actions:=0
 for kind in ["fountain","bubble","conveyor","seal"]:
  for seed in 200:
   d=Scenarios.make(kind,seed+100)
   check(Catalog.validate(d),"developer scenario valid "+kind)
   b=Board.new(d);var clone=Board.new(d)
   for turn in 8:
    if not b.available():break
    pair=Solver.best_move(b);event=b.swap(pair[0],pair[1]);var repeat: Dictionary=clone.swap(pair[0],pair[1]);actions+=1
    check(event.accepted and repeat.accepted and b.snapshot()==clone.snapshot(),"same seed / action exact determinism "+kind)
    check(b.find_matches().is_empty() and Match.has_move(b.cells,8,9),"settled board match-free and playable "+kind)
    var ids: Dictionary={}
    for cell in b.cells:ids[cell.id]=true
    check(ids.size()==72,"72 unique cells, no clone / empty "+kind)
   var restored=Board.new(d);check(restored.restore(b.snapshot()) and restored.snapshot()==b.snapshot(),"new layers save / restore "+kind)
 print("PACKAGE5 MECHANICS: %d checks, %d failures; 800 seeded boards, %d actions, four-direction / cross-mechanic cases"%[checks,failures,actions]);quit(1 if failures else 0)
