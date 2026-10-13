extends RefCounted
const Fountain=preload("res://scripts/mechanics/painting_fountain.gd")
const THRESHOLD:=3
const CANDIDATES:=4
const MAX_PAINTED:=2
static func apply(cells: Array,origin: int,color: int,width: int) -> Array:
 var candidates: Array=[]
 for i in cells.size():
  if Fountain.eligible(cells[i]):candidates.append(i)
 candidates.sort_custom(func(a,b):
  var da: int=absi(a%width-origin%width)+absi(a/width-origin/width)
  var db: int=absi(b%width-origin%width)+absi(b/width-origin/width)
  return a<b if da==db else da<db)
 var painted: Array=[]
 for i in candidates.slice(0,CANDIDATES):
  if cells[i].c==color:continue
  painted.append({"index":i,"from":int(cells[i].c),"to":color});cells[i].c=color
  if painted.size()==MAX_PAINTED:break
 return painted
static func center(matches: Array,fallback: int,width: int) -> int:
 if matches.is_empty():return fallback
 var selected: Dictionary=matches[0]
 for component in matches:
  if component.cells.size()>selected.cells.size():selected=component
 var centroid:=Vector2.ZERO
 for i in selected.cells:centroid+=Vector2(i%width,i/width)
 centroid/=selected.cells.size()
 var best: int=selected.cells[0];var distance:=INF
 for i in selected.cells:
  var d: float=Vector2(i%width,i/width).distance_squared_to(centroid)
  if d<distance:best=i;distance=d
 return best
