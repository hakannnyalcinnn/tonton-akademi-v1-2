extends RefCounted
const Registry=preload("res://scripts/mechanics/mechanic_registry.gd")
static func validate(rails: Variant,width: int=8) -> bool:
 if not rails is Array or rails.size()>8:return false
 var used: Dictionary={}
 for rail in rails:
  if not rail is Dictionary or not rail.has_all(["cells","loop"]) or not rail.cells is Array or not rail.loop is bool or rail.cells.size()<2:return false
  for k in rail.cells.size():
   var i=rail.cells[k]
   if not Registry.integer(i,0,71) or used.has(int(i)):return false
   used[int(i)]=true
   if k>0 and absi(int(i)%width-int(rail.cells[k-1])%width)+absi(int(i)/width-int(rail.cells[k-1])/width)!=1:return false
  if rail.loop:
   var a: int=rail.cells[0];var b: int=rail.cells[-1]
   if absi(a%width-b%width)+absi(a/width-b/width)!=1:return false
 return true
static func eligible(cell: Variant) -> bool:return cell!=null and not cell.get("fixed",false) and not cell.has("motion")
static func advance(cells: Array,rails: Array) -> Array:
 var proposed: Dictionary={}
 for rail in rails:
  for k in rail.cells.size():
   if not rail.loop and k==rail.cells.size()-1:continue
   var source: int=rail.cells[k];var destination: int=rail.cells[(k+1)%rail.cells.size()]
   if eligible(cells[source]):proposed[source]=destination
 var changed:=true
 while changed:
  changed=false
  for source in proposed.keys():
   var destination: int=proposed[source]
   if cells[destination]!=null and not proposed.has(destination):proposed.erase(source);changed=true
 var moved: Dictionary={};var events: Array=[]
 for source in proposed:
  moved[proposed[source]]=cells[source];events.append({"from":source,"to":proposed[source],"id":cells[source].id})
 for source in proposed:cells[source]=null
 for destination in moved:cells[destination]=moved[destination]
 return events
