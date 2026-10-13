extends SceneTree
const C=preload("res://scripts/mechanics/canyon_mechanics.gd")
const B=preload("res://scripts/core/board.gd")
const Catalog=preload("res://scripts/core/level_catalog.gd")
var checks:=0
var failures:=0
func check(ok: bool,label: String) -> void:
 checks+=1
 if not ok:failures+=1;printerr(label)
func _initialize() -> void:call_deferred("run")
func run() -> void:
 var d:=Catalog.get_level(7);d["canyon"]=[{"kind":"floor","index":27},{"kind":"giant","index":9},{"kind":"magnet","index":35},{"kind":"core","index":53,"shields":[2,2,2,2]}]
 var b=B.new(d)
 C.wave(b.cells,b.canyon,[27],[27],{},false,b.collected)
 check(b.canyon.floors["27"]==1,"floor first crack")
 C.wave(b.cells,b.canyon,[27],[27],{},false,b.collected)
 check(b.cells[27].canyon.kind=="void" and b.collected.floors==1,"second hit makes permanent hole")
 for direction in ["down","up","left","right"]:
  b.direction=direction;b.settle()
  check(b.cells[27].canyon.kind=="void","gravity/refill respects broken terrain")
 for hp in [2,1,0]:
  C.wave(b.cells,b.canyon,[8,11,25],[9,10,17,18],{},true,b.collected)
  check(b.canyon.giants.get("9",0)==hp,"giant hit deduplicated across four cells")
 check(C.footprint(9).all(func(i):return b.cells[i]==null) and b.collected.giants==1,"giant frees four slots once")
 b.settle()
 var original: Array=b.cells.duplicate(true)
 check(C.magnetic(b.cells,b.canyon,b.collected).is_empty(),"magnet waits first action")
 check(C.magnetic(b.cells,b.canyon,b.collected).is_empty(),"magnet waits second action")
 var events:=C.magnetic(b.cells,b.canyon,b.collected)
 check(events.size()==1,"magnet activates third action")
 var ids: Array=original.map(func(c):return c.id);ids.sort()
 var after_ids: Array=b.cells.map(func(c):return c.id);after_ids.sort()
 check(ids==after_ids and b.collected.magnets==1,"magnet preserves inventory")
 C.wave(b.cells,b.canyon,[],C.footprint(53),{"0":2,"1":2,"2":2,"3":2},true,b.collected)
 check(not b.canyon.cores["53"].opened,"same wave cannot strip shields and deal final blow")
 C.wave(b.cells,b.canyon,[],C.footprint(53),{},false,b.collected)
 check(not b.canyon.cores["53"].opened,"ordinary wave cannot finish vulnerable core")
 C.wave(b.cells,b.canyon,[],C.footprint(53),{},true,b.collected)
 check(b.canyon.cores["53"].opened and b.collected.cores==1,"special finishes vulnerable core")
 C.wave(b.cells,b.canyon,[],C.footprint(53),{},true,b.collected)
 check(b.collected.cores==1,"core reward counted once")
 var magnetic_definition:=Catalog.get_level(121)
 var guarded=B.new(magnetic_definition);guarded.level.targets={"total":100000}
 guarded.canyon.magnets["35"]=2;guarded.begin_action();guarded.energy=1
 var event: Dictionary={"cascade_guard":false,"cascade_count":0,"normal_count":0,"created_count":0}
 guarded.complete_action(event,0);var stable: Dictionary=guarded.snapshot()
 guarded.complete_action(event,0)
 check(guarded.snapshot()==stable and guarded.collected.magnets==1,"magnet and storm cannot repeat within one action")
 check(guarded.find_matches().is_empty(),"magnet plus storm cascades settle")
 var malformed:=magnetic_definition.duplicate(true);malformed["holes"]=[35]
 check(not C.validate(malformed),"device cannot overlap a hole")
 var floor_definition:=Catalog.get_level(7);floor_definition["canyon"]=[{"kind":"floor","index":27}];floor_definition.targets={"total":100000};floor_definition.automatic_storm=false;floor_definition.crystal_wave=false
 var birth=B.new(floor_definition)
 for i in 72:birth.cells[i].c=(i%8+int(i/8)*2)%5
 for i in range(24,28):birth.cells[i].c=0
 birth.cells[28].c=1;birth.canyon.floors["27"]=1
 var birth_event: Dictionary=birth.resolve(birth.find_matches([27]),[],[27],0,0,false,false,false)
 var first_clear: Dictionary=birth_event.frames.filter(func(f):return f.kind=="clear")[0]
 check(first_clear.creations.size()==1 and first_clear.creations[0].kind=="rocket_h" and first_clear.creations[0].i!=27,"four-match power moves to surviving matched slot when terrain breaks")
 check(birth.cells[27].canyon.kind=="void","birth never fills a broken slot")
 print("CANYON MECHANICS: %d checks, %d failures"%[checks,failures]);quit(int(failures>0))
