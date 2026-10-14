extends SceneTree
const Catalog=preload("res://scripts/core/level_catalog.gd")
const Board=preload("res://scripts/core/board.gd")
const Player=preload("res://scripts/generation/auto_player.gd")
var rows: Array=[]
func _initialize() -> void:call_deferred("run")
func run() -> void:
 for n in [13,22,24,25]:
  for sample in 1:
   for mode in Player.MODES:
    var definition:=Catalog.get_level(n);definition.seed=int(definition.seed)+sample*1000;var board=Board.new(definition)
    while board.outcome=="playing" and board.moves>0 and not board.recovery_failed:
     var event: Dictionary=Player.apply(board,Player.select(board,mode));assert(event.accepted and board.direction=="down" and not event.get("cascade_guard",false))
    rows.append({"level":n,"sample":sample,"mode":mode,"won":board.outcome=="won","used":int(definition.moves)-board.moves,"score":board.score,"stars":definition.stars,"targets":definition.targets,"collected":board.collected})
    print("BALANCE %d %s %s"%[n,mode,board.outcome])
 var file:=FileAccess.open("res://build/r2-star-probe.json",FileAccess.WRITE);file.store_string(JSON.stringify(rows,"  "));file.close();print("PASS: failed levels examined with all five independent strategies; wins are not mathematical solvability proof");quit()
