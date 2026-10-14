extends SceneTree
const L=preload("res://scripts/core/level_catalog.gd")
const W=preload("res://scripts/core/world_catalog.gd")
const B=preload("res://scripts/core/board.gd")
const M=preload("res://scripts/core/match_detector.gd")
const P=preload("res://scripts/generation/auto_player.gd")
var errors:=0
var checks:=0
func _initialize() -> void:call_deferred("run")
func check(ok: bool,message: String) -> void:
 checks+=1
 if not ok:errors+=1;push_error(message)
func run() -> void:
 check(L.count()==500 and W.all().size()==10 and W.capacity()==10000,"500 published definitions / 10 worlds / capacity10000")
 var rows=JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/v0140-witnesses.json"));var layouts: Dictionary={}
 for n in range(1,501):
  var d:=L.get_level(n);check(int(d.id)==n and L.validate(d),"Every existing/new level loads "+str(n))
  if n<=250:continue
  var b=B.new(d);check(b.find_matches().is_empty() and M.has_move(b.cells,8,9),"Stable playable authored start "+str(n))
  check(b.cells.map(func(c):return int(c.c))==d.layout.map(func(c):return int(c)),"No silent initial layout repair "+str(n))
  var fingerprint:=JSON.stringify([d.holes,d.mechanics,d.get("canyon",[]),d.get("conveyors",[]),d.get("portals",[]),d.layout]).sha256_text();check(not layouts.has(fingerprint),"Unique board/obstacles "+str(n));layouts[fingerprint]=true
  check(d.generation.status=="simulation_reviewed" and not d.generation.evidence.human_tested,"Only audited new definitions")
  for action in rows[str(n)].trace:
   if b.outcome!="playing":break
   var event: Dictionary=P.apply(b,action);check(event.accepted and not event.cascade_guard and not b.recovery_failed,"Witness action remains legal "+str(n))
  check(b.outcome=="won","Default seed completion witness after final move budget "+str(n))
 check(L.loaded.size()<=3,"Bounded lazy packet cache")
 var d:=L.get_level(1);d.id=10000;check(L.validate(d) and W.for_level(501)==0,"Future IDs supported but unprepared levels not exposed")
 print(("PASS:" if errors==0 else "FAIL:")+" %d campaign checks; all 500 load, 250 new starts and exact completion witnesses; no human/all-seed guarantee"%checks)
 quit(0 if errors==0 else 1)
