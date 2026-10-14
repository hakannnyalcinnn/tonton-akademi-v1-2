extends RefCounted
const Board=preload("res://scripts/core/board.gd")
const Catalog=preload("res://scripts/core/level_catalog.gd")
const Solver=preload("res://tests/move_solver.gd")
static func make(kind: String) -> Dictionary:
 var definition:=Catalog.get_level(247 if kind=="giant" else 7)
 definition.targets={"total":100000};definition.moves=100;definition.automatic_storm=kind=="storm";definition.crystal_wave=kind=="chain"
 var board=Board.new(definition)
 if kind=="giant":
  board.canyon.giants["44"]=1;board.cells[27].p="color";board.cells[28].p="color"
  return {"board":board,"a":27,"b":28}
 if kind=="chain":
  for seed in range(1,25):
   definition.seed=20000+seed;var candidate=Board.new(definition);var pair:=Solver.best_move(candidate);var state: Dictionary=candidate.snapshot();var event: Dictionary=candidate.swap(int(pair[0]),int(pair[1]))
   if event.frames.filter(func(f):return f.kind=="clear").size()>=3:
    candidate.restore(state);return {"board":candidate,"a":int(pair[0]),"b":int(pair[1])}
  assert(false,"bounded deterministic chain fixture search failed")
 for i in 72:board.cells[i].c=(int(i/8)*2+i%8)%5;board.cells[i].p=""
 if kind in ["normal","four","five","storm"]:
  var count:=4 if kind=="four" else 5 if kind=="five" else 3
  for k in count:board.cells[24+k].c=0
  board.cells[26].c=1;board.cells[34].c=0;board.cells[24+count].c=2
  if kind=="storm":board.energy=1
  return {"board":board,"a":26,"b":34}
 if kind=="mirrors":preload("res://scripts/mechanics/mechanic_manager.gd").install(board.cells,[{"kind":"mirror","index":31,"orientation":"/"},{"kind":"mirror","index":11,"orientation":"/"}])
 if kind=="protected":preload("res://scripts/mechanics/mechanic_manager.gd").install(board.cells,[{"kind":"stone","index":35},{"kind":"ice","index":36},{"kind":"lock","index":43,"color":0,"required":30}])
 var powers: Array={"mirrors":["rocket_h","rocket_v"],"protected":["rocket_h","rocket_v"],"bomb_normal":["color",""],"double":["color","color"],"rockets":["rocket_h","rocket_v"],"rocket_prism":["rocket_h","prism"],"color_rocket":["color","rocket_h"],"color_prism":["color","prism"],"prisms":["prism","prism"]}[kind]
 board.cells[27].p=powers[0];board.cells[28].p=powers[1]
 return {"board":board,"a":27,"b":28}
