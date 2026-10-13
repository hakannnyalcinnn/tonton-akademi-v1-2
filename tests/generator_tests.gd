extends SceneTree
const Catalog=preload("res://scripts/core/level_catalog.gd")
const Board=preload("res://scripts/core/board.gd")
const Player=preload("res://scripts/generation/auto_player.gd")
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
 checks+=1
 if not ok:failures+=1;printerr("FAIL: "+label)
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var d:=Catalog.get_level(7);d["active_colors"]=[0,1,2,3];d.layout=d.layout.map(func(c):return int(c)%4)
 var b=Board.new(d);var snapshot:=b.snapshot()
 for mode in Player.MODES:
  var selected:=Player.select(b,mode)
  check(not selected.is_empty() and b.snapshot()==snapshot,"side-effect-free strategy "+mode)
  var clone=Board.new(d);clone.restore(snapshot);check(Player.apply(clone,selected).accepted,"strategy selects legal action "+mode)
  check(clone.cells.all(func(c):return int(c.c) in d.active_colors),"refill honors palette "+mode)
 var future:=d.duplicate(true);future.id=10001;future["definition_version"]=3
 check(Catalog.validate(future),"definition schema supports future IDs without exposing fake campaign levels")
 check(Catalog.count()==preload("res://scripts/core/world_catalog.gd").count() and Catalog.count()<10001,"only actual authored packages exposed")
 print("GENERATOR: %d checks, %d failures"%[checks,failures]);quit(int(failures>0))
