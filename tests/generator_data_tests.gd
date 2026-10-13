extends SceneTree
const Catalog=preload("res://scripts/core/level_catalog.gd")
const Worlds=preload("res://scripts/core/world_catalog.gd")
const Board=preload("res://scripts/core/board.gd")
const Match=preload("res://scripts/core/match_detector.gd")
var checks:=0
var failures:=0
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures+=1;printerr("FAIL: "+message)
func _initialize() -> void:call_deferred("run")
func run() -> void:
 check(Catalog.count()==250 and Worlds.playable_worlds().size()==5,"only prepared 250 levels and five worlds")
 var used: Dictionary={};var registry=JSON.parse_string(FileAccess.get_file_as_string("res://data/mechanic-catalog.json"))
 for d in Catalog.all():
  check(Catalog.validate(d),"loadable schema "+str(d.id))
  if int(d.id)<=150:continue
  check(d.generation.status=="simulation_reviewed","drafts never exposed")
  check(d.generation.evidence.trials>=3 and not d.generation.evidence.human_tested,"bounded honest simulation evidence")
  check(d.world_id==Catalog.world_for(int(d.id)),"data-driven world assignment")
  var b=Board.new(d)
  check(b.find_matches().is_empty() and Match.has_move(b.cells,8,9),"stable authored start with a legal move")
  check(b.cells.map(func(c):return int(c.c))==d.layout.map(func(c):return int(c)),"no silent initial layout repair")
  check(b.cells.all(func(c):return int(c.c) in b.level.active_colors),"allowed palette")
  for kind in d.recipe:
   used[kind]=true
   var entries: Array=registry.mechanics.filter(func(e):return e.kind==kind)
   check(entries.size()==1 and int(entries[0].first_level)<=int(d.id),"registered taught mechanic "+kind)
  if d.recipe.size()>1:
   var kinds: Array=d.recipe.duplicate();kinds.sort();var compatible:=false
   for combination in registry.reviewed_combinations:
    var sorted: Array=combination.duplicate();sorted.sort();if sorted==kinds:compatible=true
   check(compatible,"only reviewed combinations")
 check(used.size()==20,"all twenty mechanics appear across the new campaign")
 print("GENERATOR DATA: %d checks, %d failures; all 250 loadable, all 100 new starts tested"%[checks,failures]);quit(int(failures>0))
