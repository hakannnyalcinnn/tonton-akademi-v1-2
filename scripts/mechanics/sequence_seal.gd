extends RefCounted
static func resolve(_data: Dictionary,_hits: int,_colors: Dictionary) -> Dictionary:return {"changed":false,"opened":false,"progress":0}
static func advance(cells: Array,color: int,collected: Dictionary) -> Array:
 if color<0:return []
 var events: Array=[]
 for i in cells.size():
  if cells[i]==null or cells[i].get("obstacle",{}).get("kind","")!="seal":continue
  var m: Dictionary=cells[i].obstacle
  var before: int=m.step
  if color==int(m.sequence[int(m.step)]):m.step+=1
  else:m.step=0
  var opened: bool=m.step==m.sequence.size()
  events.append({"index":i,"before":before,"step":int(m.step),"sequence":m.sequence.duplicate(),"opened":opened,"correct":color==int(m.sequence[before])})
  if opened:cells[i]=null;collected.seals=int(collected.get("seals",0))+1
 return events
