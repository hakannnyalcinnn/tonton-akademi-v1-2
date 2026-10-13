extends RefCounted
## Terrain is owned by coordinates; multi-cell objects have one authoritative anchor.
const Match=preload("res://scripts/core/match_detector.gd")
static func footprint(anchor: int) -> Array:return [anchor,anchor+1,anchor+8,anchor+9]
static func barrier(cell: Dictionary,kind: String,anchor: int) -> void:
 cell.p="";cell.fixed=true;cell["canyon"]={"kind":kind,"anchor":anchor}
static func install(cells: Array,definition: Dictionary) -> Dictionary:
 var state: Dictionary={"floors":{},"giants":{},"magnets":{},"cores":{},"holes":definition.get("holes",[]).map(func(i):return int(i))}
 for i in state.holes:barrier(cells[int(i)],"void",int(i))
 for spec in definition.get("canyon",[]):
  var anchor:=int(spec.index);var key:=str(anchor)
  match spec.kind:
   "floor":state.floors[key]=2
   "giant":
    state.giants[key]=3
    for i in footprint(anchor):barrier(cells[i],"giant",anchor)
   "magnet":state.magnets[key]=0;barrier(cells[anchor],"magnet",anchor)
   "core":
    state.cores[key]={"shields":spec.shields.map(func(n):return int(n)),"opened":false}
    for i in footprint(anchor):barrier(cells[i],"core",anchor)
 return state
static func wave(cells: Array,state: Dictionary,removed: Array,direct: Array,colors: Dictionary,special: bool,collected: Dictionary,special_area: Array=[]) -> Array:
 var events: Array=[]
 for key in state.floors.keys():
  var i:=int(key)
  if i not in removed:continue
  state.floors[key]-=1
  events.append({"kind":"floor","index":i,"hp":state.floors[key]})
  if state.floors[key]==0:
   state.floors.erase(key);state.holes.append(i);barrier(cells[i],"void",i);collected.floors+=1
 for key in state.giants.keys():
  var area:=footprint(int(key));var hit:=false
  for i in area:
   if i in direct:hit=true
   for n in Match.neighbors(i,8,9):
    if n in removed:hit=true
  if not hit:continue
  state.giants[key]-=1
  events.append({"kind":"giant","index":int(key),"hp":state.giants[key]})
  if state.giants[key]==0:
   state.giants.erase(key);collected.giants+=1
   for i in area:cells[i]=null
 for key in state.cores:
  var core: Dictionary=state.cores[key]
  if core.opened:continue
  var vulnerable: bool=core.shields.all(func(n):return n==0)
  for color in 4:
   var prior: int=core.shields[color]
   core.shields[color]=maxi(0,prior-int(colors.get(str(color),0)))
   collected["shield"+str(color)]+=prior-int(core.shields[color])
  var hit: bool=special and footprint(int(key)).any(func(i):return i in (special_area if not special_area.is_empty() else direct))
  if vulnerable and hit:
   core.opened=true;collected.cores+=1
   for i in footprint(int(key)):cells[i]=null
  events.append({"kind":"core","index":int(key),"shields":core.shields.duplicate(),"opened":core.opened})
 return events
static func magnetic(cells: Array,state: Dictionary,collected: Dictionary) -> Array:
 var events: Array=[];var used: Dictionary={}
 var anchors: Array=state.magnets.keys();anchors.sort_custom(func(a,b):return int(a)<int(b))
 for key in anchors:
  state.magnets[key]=(int(state.magnets[key])+1)%3
  if state.magnets[key]!=0:continue
  var anchor:=int(key);var candidates: Array=[]
  for x in 8:
   var i:=int(anchor/8)*8+x;var c=cells[i]
   if c!=null and not c.get("fixed",false) and not used.has(c.id):candidates.append(i)
  candidates.sort_custom(func(a,b):return absi(a-anchor)<absi(b-anchor) if absi(a-anchor)!=absi(b-anchor) else a<b)
  if candidates.size()<2:continue
  var a: int=candidates[0];var b: int=candidates[1];var c=cells[a]
  used[c.id]=true;used[cells[b].id]=true;cells[a]=cells[b];cells[b]=c
  collected.magnets+=1;events.append({"index":anchor,"a":a,"b":b})
 return events
static func validate(definition: Dictionary) -> bool:
 if not definition.get("holes",[]) is Array or not definition.get("canyon",[]) is Array:return false
 var occupied: Dictionary={}
 for i in definition.get("holes",[]):
  if not i is int and not i is float:return false
  if i<0 or i>71 or int(i)!=i or occupied.has(int(i)):return false
  occupied[int(i)]=true
 for spec in definition.get("mechanics",[]):occupied[int(spec.index)]=true
 for spec in definition.get("canyon",[]):
  if not spec is Dictionary or not spec.has_all(["kind","index"]) or spec.kind not in ["floor","giant","magnet","core"]:return false
  if not spec.index is int and not spec.index is float:return false
  var i:=int(spec.index)
  if i<0 or i>71 or i!=spec.index:return false
  var area: Array=footprint(i) if spec.kind in ["giant","core"] else [i]
  if area.size()==4 and (i%8==7 or i>=64):return false
  for n in area:
   if occupied.has(n) or definition.get("powers",{}).has(str(n)):return false
   occupied[n]=true
  if spec.kind=="core":
   if not spec.get("shields",null) is Array or spec.shields.size()!=4:return false
   for amount in spec.shields:
    if not (amount is int or amount is float) or amount<1 or amount>1000 or int(amount)!=amount:return false
 return true
static func valid_state(state: Variant,definition: Dictionary,cells: Array) -> bool:
 if not state is Dictionary or not state.has_all(["floors","giants","magnets","cores","holes"]):return false
 for key in ["floors","giants","magnets","cores"]:
  if not state[key] is Dictionary:return false
 if not state.holes is Array:return false
 var initial:=install(cells.duplicate(true),definition)
 var allowed_holes: Array=initial.holes.duplicate()
 for key in initial.floors:allowed_holes.append(int(key))
 var seen: Dictionary={}
 for value in state.holes:
  if not whole(value,0,71) or int(value) not in allowed_holes or seen.has(int(value)):return false
  seen[int(value)]=true
 for i in initial.holes:
  if int(i) not in seen:return false
 for key in ["floors","giants","magnets"]:
  for anchor in state[key]:
   if not initial[key].has(anchor) or not whole(state[key][anchor],0 if key=="magnets" else 1,2 if key!="giants" else 3):return false
 for anchor in initial.floors:
  if state.floors.has(anchor)==seen.has(int(anchor)):return false
 if state.magnets.keys()!=initial.magnets.keys() or state.cores.keys()!=initial.cores.keys():return false
 for anchor in state.cores:
  var core=state.cores[anchor]
  if not core is Dictionary or not core.get("opened",null) is bool or not core.get("shields",null) is Array or core.shields.size()!=4:return false
  for color in 4:
   if not whole(core.shields[color],0,initial.cores[anchor].shields[color]):return false
  if core.opened and not core.shields.all(func(n):return n==0):return false
 var expected: Dictionary={}
 for i in state.holes:expected[int(i)]={"kind":"void","anchor":int(i)}
 for anchor in state.giants:
  for i in footprint(int(anchor)):expected[i]={"kind":"giant","anchor":int(anchor)}
 for anchor in state.magnets:expected[int(anchor)]={"kind":"magnet","anchor":int(anchor)}
 for anchor in state.cores:
  if not state.cores[anchor].opened:
   for i in footprint(int(anchor)):expected[i]={"kind":"core","anchor":int(anchor)}
 for i in cells.size():
  if expected.has(i):
   if cells[i]==null or cells[i].get("canyon",{})!=expected[i] or not cells[i].get("fixed",false):return false
  elif cells[i]!=null and cells[i].has("canyon"):return false
 return true
static func whole(value: Variant,minimum: int,maximum: int) -> bool:
 return (value is int or value is float) and value>=minimum and value<=maximum and int(value)==value
