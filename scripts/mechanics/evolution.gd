extends RefCounted
## v0.14.1: coordinate devices and identity-owned cargo, with bounded deterministic rules.
const Match=preload("res://scripts/core/match_detector.gd")
const KINDS=["cargo","shutter","relay","key","gate","balance"]
const TARGETS=["deliveries","shutters","relays","keys","gates","balances"]
static func whole(n: Variant,lo: int,hi: int) -> bool:return (n is int or n is float) and n>=lo and n<=hi and floor(n)==n
static func validate(level: Dictionary) -> bool:
 var specs=level.get("evolution",[])
 if not specs is Array or specs.size()>12:return false
 var occupied: Array=level.get("holes",[]).duplicate()
 for m in level.get("mechanics",[]):occupied.append(int(m.index))
 for m in level.get("canyon",[]):
  occupied.append(int(m.index))
  if m.kind in ["giant","core"]:occupied.append_array([int(m.index)+1,int(m.index)+8,int(m.index)+9])
 var indices: Array=[]
 for s in specs:
  if not s is Dictionary or s.get("kind","") not in KINDS or not whole(s.get("index",-1),0,71) or int(s.index) in occupied or int(s.index) in indices or level.get("powers",{}).has(str(int(s.index))):return false
  indices.append(int(s.index))
  if s.kind in ["key","gate","relay"] and not whole(s.get("group",0),1,12):return false
  if s.kind=="balance" and (not whole(s.get("need",0),3,12) or not s.get("colors",null) is Array or s.colors.size()!=2 or s.colors[0]==s.colors[1]):return false
  if s.kind=="balance":
   for c in s.colors:
    if not whole(c,0,4) or c not in level.get("active_colors",[0,1,2,3,4]):return false
 for s in specs:
  if s.kind=="gate" and not specs.any(func(n):return n.kind=="key" and n.group==s.group):return false
  if s.kind=="relay" and specs.filter(func(n):return n.kind=="relay" and n.group==s.group).size()<2:return false
  if s.kind=="cargo":
   for i in range(int(s.index)+8,72,8):
    if i in occupied or specs.any(func(n):return int(n.index)==i and n.kind!="cargo"):return false
 var quantities: Dictionary={}
 for i in specs.size():
  var key: String=TARGETS[KINDS.find(specs[i].kind)];quantities[key]=int(quantities.get(key,0))+1
 for key in TARGETS:
  if int(level.targets.get(key,0))>int(quantities.get(key,0)):return false
 return true
static func barrier(cells: Array,n: Dictionary) -> void:
 var c: Dictionary=cells[int(n.index)];c.p="";c.fixed=true;c.evolution={"kind":n.kind,"anchor":int(n.index)}
static func install(cells: Array,level: Dictionary) -> Dictionary:
 var state: Dictionary={"turn":0,"nodes":[]}
 for spec in level.get("evolution",[]):
  var n: Dictionary=spec.duplicate(true);n.done=false;n.open=false;n.lit=false;n.left=0;n.right=0
  state.nodes.append(n)
  if n.kind=="cargo":cells[int(n.index)].delivery=true;n.cell_id=int(cells[int(n.index)].id)
  else:barrier(cells,n)
 return state
static func event(n: Dictionary,opened: bool) -> Dictionary:return {"index":int(n.index),"kind":n.kind,"opened":opened,"left":n.left,"right":n.right,"open":n.open,"lit":n.lit}
static func remove(cells: Array,n: Dictionary,collected: Dictionary,events: Array) -> void:
 if n.done:return
 n.done=true;cells[int(n.index)]=null
 var key: String=TARGETS[KINDS.find(n.kind)];collected[key]=int(collected.get(key,0))+1;events.append(event(n,true))
static func wave(cells: Array,state: Dictionary,removed: Array,direct: Array,colors: Dictionary,collected: Dictionary,special: bool) -> Array:
 var events: Array=[]
 for n in state.nodes:
  if n.done or n.kind=="cargo":continue
  var i:=int(n.index)
  var neighbor: bool=Match.neighbors(i,8,9).any(func(k):return k in removed)
  var hit: bool=(special and i in direct) or neighbor
  match n.kind:
   "key":
    if hit:
     remove(cells,n,collected,events)
     for gate in state.nodes:
      if gate.kind=="gate" and gate.group==n.group:remove(cells,gate,collected,events)
   "shutter":
    if (n.open and i in removed) or (not n.open and special and i in direct):
     var occupant=cells[i];remove(cells,n,collected,events)
     if i in removed:cells[i]=occupant
   "relay":
    if hit:n.lit=true;events.append(event(n,false))
   "balance":
    var capacity:=int(n.need)*2+2
    n.left=mini(capacity,n.left+int(colors.get(str(int(n.colors[0])),0)));n.right=mini(capacity,n.right+int(colors.get(str(int(n.colors[1])),0)))
    if special and i in direct:
     if n.left<=n.right:n.left=mini(capacity,n.left+2)
     else:n.right=mini(capacity,n.right+2)
    if n.left>=int(n.need) and n.right>=int(n.need) and absi(n.left-n.right)<=2:remove(cells,n,collected,events)
    elif not colors.is_empty() or hit:events.append(event(n,false))
 for n in state.nodes:
  if n.kind!="relay" or n.done:continue
  var group: Array=state.nodes.filter(func(other):return other.kind=="relay" and other.group==n.group)
  if group.all(func(other):return other.lit):
   for other in group:remove(cells,other,collected,events)
 return events
static func begin(state: Dictionary) -> void:
 for n in state.nodes:
  if n.kind=="relay":n.lit=false
static func advance(cells: Array,state: Dictionary,make_cell: Callable) -> Array:
 if state.nodes.is_empty():return []
 state.turn+=1;var events: Array=[]
 for n in state.nodes:
  if n.kind!="shutter" or n.done:continue
  var c=cells[int(n.index)]
  if n.open and c!=null and (c.p!="" or c.get("delivery",false) or c.has("armor") or c.has("obstacle") or c.has("motion") or c.has("trait")):continue # keep protected occupants intact
  n.open=not n.open
  if n.open:cells[int(n.index)]=make_cell.call()
  else:barrier(cells,n)
  events.append(event(n,false))
 return events
static func deliver(cells: Array,state: Dictionary,collected: Dictionary) -> Array:
 var events: Array=[]
 for i in range(64,72):
  if cells[i]==null or not cells[i].get("delivery",false):continue
  for n in state.nodes:
   if n.kind=="cargo" and not n.done and int(n.cell_id)==int(cells[i].id):
    n.done=true;collected.deliveries+=1;var e:=event(n,true);e.index=i;events.append(e);cells[i]=null;break
 return events
static func valid(state: Variant,level: Dictionary,cells: Array,collected: Dictionary) -> bool:
 if not state is Dictionary or not whole(state.get("turn",-1),0,10000) or not state.get("nodes",null) is Array or state.nodes.size()!=level.get("evolution",[]).size():return false
 var expected: Dictionary={};var cargo_ids: Array=[]
 for i in state.nodes.size():
  var n=state.nodes[i];var spec: Dictionary=level.evolution[i]
  if not n is Dictionary:return false
  for k in spec:
   if k=="colors":
    if n.get(k,[]).map(func(c):return int(c))!=spec[k].map(func(c):return int(c)):return false
   elif n.get(k)!=spec[k]:return false
  for k in ["done","open","lit"]:
   if not n.get(k,null) is bool:return false
  if not whole(n.get("left",-1),0,1000000) or not whole(n.get("right",-1),0,1000000):return false
  if n.kind=="cargo":
   if not whole(n.get("cell_id",0),1,2147483647):return false
   if not n.done:cargo_ids.append(int(n.cell_id))
  elif not n.done and not (n.kind=="shutter" and n.open):expected[int(n.index)]={"kind":n.kind,"anchor":int(n.index)}
 for i in cells.size():
  var c: Dictionary=cells[i]
  if c.has("evolution"):
   if c.evolution!=expected.get(i,{}) or not c.get("fixed",false) or c.p!="":return false
  elif expected.has(i):return false
  if c.has("delivery"):
   if c.delivery!=true or c.p!="" or c.get("fixed",false) or int(c.id) not in cargo_ids:return false
   cargo_ids.erase(int(c.id))
 if not cargo_ids.is_empty():return false
 for i in KINDS.size():
  var completed: int=state.nodes.filter(func(n):return n.kind==KINDS[i] and n.done).size()
  if int(collected.get(TARGETS[i],0))!=completed:return false
 return true
