extends RefCounted
## Five transparent, bounded authoring strategies; never changes gameplay RNG or rules.
const Match=preload("res://scripts/core/match_detector.gd")
const Powers=preload("res://scripts/core/powerups.gd")
const Damage=preload("res://scripts/mechanics/damage_resolver.gd")
const Traits=preload("res://scripts/mechanics/crystal_traits.gd")
const Board=preload("res://scripts/core/board.gd")
const MODES=["largest","objective","powers","obstacles","lookahead"]
static func preview(board,a: int,b: int) -> Dictionary:
 var probe: Array=board.cells.duplicate(true);var first=probe[a];probe[a]=probe[b];probe[b]=first
 var matches:=Match.find(probe,8,9,[b,a]);var removed:=Match.indices(matches)
 var birth:=0.0;var primary: int=Powers.dominant_color(probe)
 for preferred in [b,a]:
  var found:=false
  for component in matches:
   if preferred in component.cells:primary=int(component.color);found=true;break
  if found:break
 for component in matches:birth+={"":0,"rocket_h":2,"rocket_v":2,"prism":4,"color":6}[Powers.created(component)]
 var special: bool=probe[a].p!="" or probe[b].p!=""
 if special:
  if probe[a].p!="" and probe[b].p!="":removed=Powers.combo_area(a,b,probe,8,primary)
  else:
   var p: int=a if probe[a].p!="" else b;var normal: int=b if p==a else a
   primary=int(probe[normal].c);removed=Powers.area(p,probe[p].p,probe,8,primary)
 var objective:=0.0;var obstruction:=0.0
 for i in removed:
  if not Match.normal(probe[i]):continue
  var c:=str(probe[i].c)
  if board.collected.get(c,0)<int(board.level.targets.get(c,0)):objective+=4
  if board.collected.get("shield"+c,0)<int(board.level.targets.get("shield"+c,0)):objective+=6
  var kind: String=probe[i].get("trait",probe[i].get("motion",{})).get("kind","")
  if kind in ["dual","bridge","bubble"]:objective+=12
  if kind=="chameleon" and board.collected.shifts<int(board.level.targets.get("shifts",0)):objective-=150
  if board.canyon.floors.has(str(i)):obstruction+=22
 for cage in board.adventure.get("cages",[]):
  if int(cage.remaining)>0 and removed.any(func(i):return absi(int(i)%8-int(cage.index)%8)+absi(int(i)/8-int(cage.index)/8)<=1):objective+=75
 if board.adventure.has("boss") and not board.adventure.boss.defeated:
  var phase: Dictionary=board.adventure.boss.phases[int(board.adventure.boss.phase)]
  if phase.get("special",false):objective+=120 if special else 0
  else:
   for i in removed:
    if Match.normal(probe[i]) and phase.colors.has(int(probe[i].c)):objective+=10
 for node in board.evolution.get("nodes",[]):
  if node.done:continue
  var anchor:=int(node.index)
  var hit: bool=Match.neighbors(anchor,8,9).any(func(i):return i in removed) or (special and anchor in removed)
  if node.kind in ["key","relay"] and hit:objective+=100
  if node.kind=="shutter" and ((node.open and anchor in removed) or (special and anchor in removed)):objective+=110
  if node.kind=="cargo":
   for i in probe.size():
    if probe[i]!=null and probe[i].get("delivery",false):
     for target in removed:
      if int(target)%8==i%8 and int(target)>i:objective+=30+float(target)/8
  if node.kind=="balance":
   for i in removed:
    if not Match.normal(probe[i]):continue
    if int(probe[i].c)==int(node.colors[0]):objective+=14 if node.left<=node.right else -8
    if int(probe[i].c)==int(node.colors[1]):objective+=14 if node.right<=node.left else -8
   if special and anchor in removed:objective+=90
 var hits:=Damage.plan(probe,removed,removed,[],8,9)
 obstruction+=hits.size()*12
 for key in board.canyon.giants:
  var area: Array=preload("res://scripts/mechanics/canyon_mechanics.gd").footprint(int(key))
  if area.any(func(i):return i in removed or Match.neighbors(i,8,9).any(func(n):return n in removed)):obstruction+=30
 for key in board.canyon.cores:
  var core: Dictionary=board.canyon.cores[key]
  if core.opened:continue
  if core.shields.all(func(n):return n==0):
   if special and preload("res://scripts/mechanics/canyon_mechanics.gd").footprint(int(key)).any(func(i):return i in removed):objective+=200
  elif special:objective-=12 # Reserve a free power for the final blow when practical.
 for cell in probe:
  if cell==null:continue
  var m: Dictionary=cell.get("obstacle",{})
  if m.get("kind","")=="seal":objective+=100 if primary==int(m.sequence[int(m.step)]) else -65
  if m.get("kind","")=="lock" and primary==int(m.color):objective+=15
  if m.get("kind","")=="fountain" and Match.neighbors(probe.find(cell),8,9).any(func(i):return i in removed):objective+=15
 return {"largest":removed.size(),"objective":objective+obstruction+birth*4+removed.size(),"powers":birth*16+removed.size(),"obstacles":obstruction*2+objective*.35+removed.size(),"color":primary}
static func select(board,mode: String="objective") -> Array:
 assert(mode in MODES)
 var choices:=Match.legal_swaps(board.cells,8,9)
 if choices.is_empty():
  for i in board.cells.size():
   if board.cells[i]!=null and not board.cells[i].get("fixed",false) and board.cells[i].p!="":return [i,-1,Powers.dominant_color(board.cells)]
  return []
 var ranked: Array=[]
 for pair in choices:
  var result:=preview(board,pair[0],pair[1]);ranked.append({"pair":pair,"value":result["objective" if mode=="lookahead" else mode]})
 ranked.sort_custom(func(a,b):return a.value>b.value if a.value!=b.value else (a.pair[0]<b.pair[0] if a.pair[0]!=b.pair[0] else a.pair[1]<b.pair[1]))
 if mode!="lookahead":return ranked[0].pair
 # Depth two, beam width two + two follow-ups: bounded real-engine evaluation.
 var best: Array=ranked[0].pair;var best_score:=-INF
 for candidate in ranked.slice(0,2):
  var clone=Board.new(board.level);if not clone.restore(board.snapshot()):continue
  clone.swap(candidate.pair[0],candidate.pair[1])
  var value: float=candidate.value+float(clone.collected.total-board.collected.total)
  if clone.outcome=="won":value+=10000
  elif clone.available():
   var next:=select(clone,"objective")
   if not next.is_empty() and next[1]>=0:value+=preview(clone,next[0],next[1]).objective*.4
  if value>best_score:best_score=value;best=candidate.pair
 return best
static func apply(board,action: Array) -> Dictionary:
 return board.activate(action[0],action[2]) if action[1]<0 else board.swap(action[0],action[1])
