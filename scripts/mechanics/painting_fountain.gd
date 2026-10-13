extends RefCounted
const Match=preload("res://scripts/core/match_detector.gd")
static func resolve(_data: Dictionary,_hits: int,_colors: Dictionary) -> Dictionary:return {"changed":false,"opened":false,"progress":0}
static func eligible(cell: Variant) -> bool:
 return Match.normal(cell) and not cell.has("armor") and not cell.has("trait") and not cell.has("motion")
static func activate(cells: Array,matched: Array,used: Dictionary,width: int,height: int) -> Array:
 var events: Array=[]
 for source in cells.size():
  if cells[source]==null or cells[source].get("obstacle",{}).get("kind","")!="fountain" or used.has(source):continue
  var adjacent:=false
  for i in Match.neighbors(source,width,height):
   if i in matched:adjacent=true
  if not adjacent:continue
  used[source]=true
  var color: int=cells[source].obstacle.color
  var candidates: Array=[]
  for i in cells.size():
   if eligible(cells[i]):candidates.append(i)
  candidates.sort_custom(func(a,b):
   var da: int=absi(a%width-source%width)+absi(a/width-source/width)
   var db: int=absi(b%width-source%width)+absi(b/width-source/width)
   return a<b if da==db else da<db)
  var painted: Array=[]
  for i in candidates.slice(0,3):
   painted.append({"index":i,"from":int(cells[i].c),"to":color});cells[i].c=color
  events.append({"source":source,"color":color,"painted":painted})
 return events
