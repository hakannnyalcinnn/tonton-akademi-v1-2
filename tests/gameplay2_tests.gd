extends SceneTree
const Board=preload("res://scripts/core/board.gd")
const Catalog=preload("res://scripts/core/level_catalog.gd")
const Match=preload("res://scripts/core/match_detector.gd")
const Storm=preload("res://scripts/core/prizma_storm.gd")
const Wave=preload("res://scripts/core/crystal_wave.gd")
const Rng=preload("res://scripts/core/seed_rng.gd")
const Powers=preload("res://scripts/core/powerups.gd")
const Save=preload("res://scripts/core/save_manager.gd")
const Solver=preload("res://tests/move_solver.gd")
var checks:=0
var failures:=0
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:failures+=1;printerr("FAIL: "+message)
func _initialize() -> void:call_deferred("run")
func run() -> void:
 for legacy_direction in ["up","down","left","right"]:
  var definition:=Catalog.get_level(7);var board=Board.new(definition);board.direction=legacy_direction;board.moves=7
  var legacy: Dictionary=board.snapshot();legacy.gameplay_version=3
  var restored=Board.new(definition)
  check(restored.restore(legacy) and restored.direction=="down","legacy direction normalizes safely")
  check(restored.cells==board.cells and restored.moves==7 and restored.score==board.score and restored.collected==board.collected and restored.rng.state==board.rng.state,"normalizing gravity preserves player state")
 var probe=Board.new(Catalog.get_level(7));var before: Dictionary=probe.snapshot()
 var storm_targets: Array=Storm.targets(probe.cells,27,8)
 check(storm_targets.size()<=3 and storm_targets==Storm.targets(probe.cells,27,8),"storm targets deterministic and bounded")
 check(storm_targets.all(func(i):return probe.cells[i].p=="" and not probe.cells[i].get("fixed",false)),"storm touches only suitable normal crystals")
 check(not probe.change_gravity("up").accepted and probe.snapshot()==before,"manual direction rejected without mutation")
 var exact=Board.new(Catalog.get_level(7));exact.level.targets={"total":100000};exact.begin_action()
 exact.credit_storm(11);check(exact.energy==0 and exact.storm_charge()==11,"energy below twelve is not ready")
 exact.credit_storm(1);check(exact.energy==1 and exact.storm_charge()==12,"exactly twelve normal crystals make storm ready")
 exact.energy=4
 var exact_event: Dictionary={"cascade_guard":false,"cascade_count":0,"normal_count":0,"created_count":0}
 var exact_moves: int=exact.moves;exact.complete_action(exact_event,0);var exact_state:=exact.snapshot()
 exact.complete_action(exact_event,0)
 check(exact_event.storm and exact.snapshot()==exact_state and exact.moves==exact_moves,"central resolver prevents repeat storm in the same action")
 var ordinary=Board.new(Catalog.get_level(7));ordinary.cells[27].p="rocket_h";ordinary.cells[28].fixed=true
 var painted:=Wave.apply(ordinary.cells,27,4,8)
 check(painted.size()<=2 and painted.all(func(c):return c.index!=27 and c.index!=28),"wave excludes powers and protected cells")
 var original: Array=[]
 for i in 9:original.append({"c":0,"p":"","id":i+1})
 check(Wave.apply(original,4,1,3).map(func(c):return c.index)==[4,1],"wave uses nearest four with coordinate tie-break and at most two")
 var d:=Catalog.get_level(7);d.moves=1;d.targets={"total":1}
 var last=Board.new(d);last.energy=1
 var pair:=Solver.best_move(last);var event: Dictionary=last.swap(pair[0],pair[1])
 check(last.outcome=="won" and last.moves==0 and event.storm and last.find_matches().is_empty(),"last move waits for storm and wave before final result")
 var combinations=[["rocket_h","rocket_v","rocket_rocket"],["rocket_h","prism","rocket_prism"],["prism","prism","prism_prism"],["color","rocket_h","color_rocket"],["color","prism","color_prism"],["color","color","color_color"]]
 for combo in combinations:
  var definition:=Catalog.get_level(7);definition.moves=100;definition.targets={"total":100000}
  var board=Board.new(definition);board.cells[0].p=combo[0];board.cells[1].p=combo[1]
  var plan:=Powers.combo_plan(0,1,board.cells,8,2)
  check(plan.kind==combo[2] and not plan.area.is_empty(),"central combination kind "+combo[2])
  var unique: Dictionary={}
  for i in plan.area:unique[i]=true
  check(unique.size()==plan.area.size(),"combination footprint deduplicated")
  var copy=Board.new(definition);check(copy.restore(board.snapshot()),"combination snapshot accepted")
  var e: Dictionary=board.swap(0,1);copy.swap(0,1)
  check(e.accepted and e.combo_kind==combo[2] and not e.cascade_guard,"combination accepted and bounded")
  check(board.moves==99 and board.snapshot()==copy.snapshot() and board.find_matches().is_empty(),"combination deterministic, stable and one move")
 var mirror_board=Board.new(Catalog.get_level(7));mirror_board.level.targets={"total":100000}
 preload("res://scripts/mechanics/mechanic_manager.gd").install(mirror_board.cells,[{"kind":"mirror","index":3,"orientation":"/"}])
 mirror_board.cells[0].p="color";mirror_board.cells[1].p="rocket_h"
 for i in [2,4,5,6]:mirror_board.cells[i].c=2
 var chosen:=Powers.dominant_color(mirror_board.cells);mirror_board.cells[2].c=chosen
 var reflected_event: Dictionary=mirror_board.swap(0,1)
 check(reflected_event.accepted and mirror_board.collected.mirrors>=1,"virtual colour rockets count actual mirror reflections through central objective rule")
 check(reflected_event.frames.any(func(f):return f.kind=="clear" and f.get("beams",[]).any(func(ray):return ray.get("virtual",false))),"virtual rocket beams have actual traced visual paths")
 var protected=Board.new(Catalog.get_level(7))
 preload("res://scripts/mechanics/mechanic_manager.gd").install(protected.cells,[{"kind":"stone","index":27},{"kind":"ice","index":28},{"kind":"lock","index":29,"color":0,"required":30}])
 var hits: Dictionary=preload("res://scripts/mechanics/damage_resolver.gd").plan(protected.cells,[26],[27,28,29],[],8,9,[{"index":26,"kind":"prism"},{"index":26,"kind":"prism"}])
 check(hits[27]==2 and hits[28]==1 and hits[29]==1,"virtual prism and overlaps obey common stone/armor/lock damage")
 var damage:=preload("res://scripts/mechanics/mechanic_manager.gd").wave(protected.cells,[26],[27,28,29],[],{},protected.collected,8,9,[{"index":26,"kind":"prism"}])
 check(protected.cells[27]!=null and protected.cells[27].obstacle.hp==1 and protected.cells[28].armor.hp==1 and protected.cells[29]!=null,"combination cannot directly delete protected goals")
 # A genuine old schema-2 active board retains its old definition and move budget.
 var legacy=JSON.parse_string(FileAccess.get_file_as_string("res://data/legacy-gameplay-0.8.json"))
 var old=Board.new(legacy.levels[99]);var active:=old.snapshot()
 for key in ["level_definition","move_budget","gameplay_version"]:active.erase(key)
 var path: String="user://gameplay2-migration-test.json"
 for suffix in ["",".bak",".tmp",".v2-before-gameplay2"]:
  if FileAccess.file_exists(path+suffix):DirAccess.remove_absolute(ProjectSettings.globalize_path(path+suffix))
 var data:=Save.defaults();data.version=2;data.unlocked=100;data.active=active;data.world_rewards=[1];data.settings.music=false
 var file:=FileAccess.open(path,FileAccess.WRITE);file.store_string(JSON.stringify(data));file.close()
 var saved=Save.new(path)
 check(saved.data.version==3 and not saved.read_only and FileAccess.file_exists(path+".v2-before-gameplay2"),"v2 archived and migrated without reset")
 check(saved.data.active.level_definition.targets==Save.canonical(legacy.levels[99].targets) and saved.data.active.moves==52,"old active goals and remaining moves preserved")
 check(saved.data.world_rewards==[1] and not saved.data.settings.music,"rewards and settings preserved")
 check(saved.flush() and Save.new(path).data.active==saved.data.active,"upgraded save survives disk reopen")
 for field in ["layout","stars","targets","moves","gravity","mechanics"]:
  var corrupt: Dictionary=saved.data.duplicate(true);corrupt.active.level_definition[field]="malformed"
  check(not saved.valid(corrupt),"malformed embedded definition rejected without crash: "+field)

 var storms:=0;var waves:=0
 for n in range(1,101):
  for seed_offset in 3:
   var level:=Catalog.get_level(n);level.seed+=1000+seed_offset
   var a=Board.new(level);var b=Board.new(level)
   for action in mini(8,int(level.moves)):
    if not a.available():break
    var m:=Solver.best_move(a);var e: Dictionary=a.swap(m[0],m[1]);b.swap(m[0],m[1])
    storms+=int(e.storm);waves+=int(e.crystal_wave)
    check(e.accepted and not e.cascade_guard and a.snapshot()==b.snapshot(),"100-level deterministic integration")
    check(a.moves>=0 and a.find_matches().is_empty() and Match.has_move(a.cells,8,9),"100-level stable integration")
 for kind in ["portal","vine","crate","mirror","fountain","bubble","conveyor","seal"]:
  for seed in 10:
   var scene:=preload("res://scripts/mechanics/developer_scenarios.gd").make(kind,104169+seed)
   scene.automatic_storm=true;scene.crystal_wave=true
   var a=Board.new(scene);var b=Board.new(scene);a.energy=1;b.energy=1
   for action in 4:
    if not a.available():break
    var lab_pair:=Solver.best_move(a);var lab_event: Dictionary=a.swap(lab_pair[0],lab_pair[1]);b.swap(lab_pair[0],lab_pair[1])
    check(lab_event.accepted and not lab_event.cascade_guard and a.snapshot()==b.snapshot(),"all eight lab mechanics integrate with automatic storm and wave")
    check(a.find_matches().is_empty() and Match.has_move(a.cells,8,9) and null not in a.cells,"lab mechanics remain stable and playable with automatic effects")
 check(storms>100 and waves>20,"integration exercises storms and crystal waves")
 print("GAMEPLAY2: %d checks, %d failures; %d storms, %d crystal waves"%[checks,failures,storms,waves])
 quit(1 if failures else 0)
