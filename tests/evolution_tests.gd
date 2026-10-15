extends SceneTree
const B=preload("res://scripts/core/board.gd")
const L=preload("res://scripts/core/level_catalog.gd")
const E=preload("res://scripts/mechanics/evolution.gd")
const M=preload("res://scripts/core/match_detector.gd")
const S=preload("res://scripts/core/save_manager.gd")
var errors:=0
var checks:=0
func _initialize() -> void:call_deferred("run")
func check(value: bool,description: String) -> void:
 checks+=1
 if not value:errors+=1;push_error(description)
func board(specs: Array,targets: Dictionary):
 var d:=L.get_level(1);d.mechanics=[];d.powers={};d.holes=[];d.canyon=[];d.erase("adventure");d.erase("objective_stages");d.evolution=specs;d.targets=targets;d.moves=20;d.gravity=false;d.resonance=false
 return B.new(d)
func roundtrip(b) -> void:
 b.finish_if_needed();var d: Dictionary=JSON.parse_string(JSON.stringify(b.snapshot()));var clone=B.new(b.level)
 check(clone.restore(d),"Evolution state survives real JSON snapshot")
 check(clone.snapshot()==b.snapshot(),"Deterministic state roundtrip")
func run() -> void:
 var b=board([{"kind":"key","index":50,"group":1},{"kind":"gate","index":20,"group":1}],{"gates":1})
 E.wave(b.cells,b.evolution,[],[20],{},b.collected,true);check(b.collected.gates==0,"Powers cannot bypass a locked gate")
 b.cells[48].p="rocket_h";var event: Dictionary=b.activate(48)
 check(event.accepted and b.collected.keys==1 and b.collected.gates==1 and b.outcome=="won","Key hit opens actual linked gate and wins")
 roundtrip(b)
 b=board([{"kind":"relay","index":50,"group":1},{"kind":"relay","index":54,"group":1}],{"relays":2})
 E.wave(b.cells,b.evolution,[49],[],{},b.collected,false);check(b.collected.relays==0 and b.evolution.nodes[0].lit,"Partial relay charges without opening network")
 E.begin(b.evolution);E.wave(b.cells,b.evolution,[55],[],{},b.collected,false);check(b.collected.relays==0,"Separate player actions cannot accumulate relay charges")
 E.begin(b.evolution);b.cells[48].p="rocket_h";event=b.activate(48)
 check(b.collected.relays==2 and b.outcome=="won","One power activates full network, each relay counted once")
 roundtrip(b)
 b=board([{"kind":"shutter","index":50}],{"shutters":1})
 E.wave(b.cells,b.evolution,[49],[],{},b.collected,false);check(not b.evolution.nodes[0].done,"Closed timed gate ignores normal neighbor damage")
 E.advance(b.cells,b.evolution,b.make_cell);check(b.evolution.nodes[0].open and not b.cells[50].get("fixed",false),"Successful turn opens actual playable cell")
 E.advance(b.cells,b.evolution,b.make_cell);check(not b.evolution.nodes[0].open and b.cells[50].fixed,"Next successful turn closes cell")
 b.cells[48].p="rocket_h";event=b.activate(48);check(b.collected.shutters==1 and b.outcome=="won","Special power permanently removes timed gate")
 roundtrip(b)
 b=board([{"kind":"cargo","index":56}],{"deliveries":1})
 check(not M.normal(b.cells[56]),"Cargo does not form normal color matches")
 check(not b.deploy_power(56,"prism").accepted,"Inventory powers cannot overwrite delivery object")
 check(56 not in preload("res://scripts/core/prizma_storm.gd").targets(b.cells,56,8),"Storm targets only normal crystals, excludes cargo")
 check(not preload("res://scripts/mechanics/painting_fountain.gd").eligible(b.cells[56]),"Paint fountain and crystal wave exclude protected cargo")
 var id: int=b.cells[56].id;b.cells[48].p="rocket_v";event=b.activate(48)
 check(b.collected.deliveries==1 and b.outcome=="won","Power cannot destroy cargo; gravity carries it through cleared exit")
 check(b.cells.all(func(c):return int(c.id)!=id),"Delivered object is removed exactly once")
 roundtrip(b)
 b=board([{"kind":"balance","index":50,"need":3,"colors":[0,1]}],{"balances":1})
 E.wave(b.cells,b.evolution,[],[],{"0":7,"1":3},b.collected,false);check(b.collected.balances==0,"Unbalanced color totals cannot open balance device")
 E.wave(b.cells,b.evolution,[],[50],{},b.collected,true);check(b.collected.balances==1,"Direct power adds two to weaker side and restores equilibrium")
 b.settle();b.resolve(b.find_matches(),[],[],-1,-1,false,false);roundtrip(b)
 var bad: Dictionary=b.snapshot();bad.evolution.nodes[0].left=-1;check(not B.new(b.level).restore(bad),"Malformed saved new state rejected")
 var old=B.new(L.get_level(1));var snapshot: Dictionary=old.snapshot();snapshot.erase("evolution")
 for k in E.TARGETS:snapshot.collected.erase(k)
 check(B.new(old.level).restore(snapshot),"Old board snapshots without new mechanics still load")
 var old_profile:=S.defaults();old_profile.unlocked=500;preload("res://scripts/core/economy.gd").ensure(old_profile);old_profile.adventure_progress.coins=321;old_profile.results["499"]={"score":12345,"stars":3}
 check(S.new("user://v0141-compat.json").valid(old_profile),"Existing progress/currency/stars profile remains valid")
 var evolved:=0
 for n in range(1,501):
  var d:=L.get_level(n);check(L.validate(d),"Level data valid "+str(n));var fresh=B.new(d)
  check(fresh.find_matches().is_empty() and M.has_move(fresh.cells,8,9),"Playable stable initial board "+str(n))
  if d.get("evolution",[]).is_empty():
   var pair: Array=M.legal_swaps(fresh.cells,8,9)[0];var result: Dictionary=fresh.swap(pair[0],pair[1])
   check(result.accepted and not result.cascade_guard and not fresh.recovery_failed,"Unchanged level real action settles "+str(n))
   check(B.new(d).restore(JSON.parse_string(JSON.stringify(fresh.snapshot()))),"Unchanged level action persists "+str(n))
  if not d.get("evolution",[]).is_empty():
   evolved+=1;check(E.valid(fresh.evolution,d,fresh.cells,fresh.collected),"New state ownership consistent "+str(n))
 check(evolved>=60,"Only necessary definitions changed; variety reaches all later ranges")
 print(("PASS:" if errors==0 else "FAIL:")+" %d evolution checks; %d evolved levels; all 500 validate"%[checks,evolved]);quit(0 if errors==0 else 1)
