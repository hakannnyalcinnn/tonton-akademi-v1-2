extends SceneTree
const Board=preload("res://scripts/core/board.gd")
const Catalog=preload("res://scripts/core/level_catalog.gd")
const Player=preload("res://scripts/generation/auto_player.gd")
const Mechanics=preload("res://scripts/mechanics/mechanic_manager.gd")
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var checks:=0
 for seed in 10:
  var definition:=Catalog.get_level(7);definition.seed=40000+seed;definition.targets={"total":100000};definition.moves=100
  var board=Board.new(definition);board.energy=3
  var clone=Board.new(definition);assert(clone.restore(board.snapshot()))
  var action:=Player.select(board,"objective");var moves: int=board.moves
  var event: Dictionary=Player.apply(board,action);Player.apply(clone,action)
  assert(event.accepted and board.moves==moves-1 and board.direction=="down" and board.snapshot()==clone.snapshot())
  assert(event.frames.filter(func(frame):return frame.kind=="storm").size()==1 and board.energy>=2)
  for frame in event.frames:
   assert(frame.direction=="down")
   if frame.kind=="storm":assert(frame.targets.size()<=3)
   if frame.kind=="fall":
    var origins: Dictionary={}
    for index in frame.before.size():
     if frame.before[index]!=null:origins[int(frame.before[index].id)]=index
    for index in frame.after.size():
     if frame.after[index]==null or not origins.has(int(frame.after[index].id)):continue
     var before: int=origins[int(frame.after[index].id)]
     assert(index%8==before%8 and int(index/8)>=int(before/8));checks+=1
 var barrier=Board.new(Catalog.get_level(7));Mechanics.install(barrier.cells,[{"kind":"stone","index":24}]);barrier.cells[32]=null;barrier.cells[40]=null;barrier.cells[0]=null
 barrier.settle(true)
 var refill: Dictionary=barrier.frames.filter(func(frame):return frame.kind=="refill")[0]
 for index in refill.spawn_origins:
  assert(float(refill.spawn_origins[index])<float(refill.spawn_clip_top[index]))
  if int(index)%8==0 and int(index)>24:assert(float(refill.spawn_clip_top[index])==240)
 assert(barrier.cells[24].get("fixed",false) and barrier.direction=="down")
 print("PASS: %d downward original-ID checks, ten replayed once-per-action storms, conserved moves/energy, barrier refill entry boundaries"%checks);quit()
