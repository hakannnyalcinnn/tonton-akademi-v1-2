extends RefCounted
## Pure seeded direction choice and full-board reflow; never considers goals or victory.
const Gravity=preload("res://scripts/core/gravity.gd")
const DIRECTIONS=["down","up","left","right"]
const COST:=12
static func choose(current: String,rng) -> String:
 var options: Array=DIRECTIONS.duplicate();options.erase(current)
 return options[rng.next_int(options.size())]
static func reflow(cells: Array,width: int,height: int,direction: String) -> Array:
 var events: Array=[]
 for line in Gravity.lines(width,height,direction):
  var segment: Array=[]
  for i in line:
   if cells[i]!=null and cells[i].get("fixed",false):
    rotate_segment(cells,segment,events);segment.clear()
   else:segment.append(i)
  rotate_segment(cells,segment,events)
 return events
static func rotate_segment(cells: Array,segment: Array,events: Array) -> void:
 if segment.size()<2:return
 var before: Array=[]
 for i in segment:before.append(cells[i])
 # One step toward the chosen edge; the edge crystal wraps within this segment.
 # This creates visible movement even when a settled board contains no empty cells.
 for k in segment.size():
  var source: int=segment[(k+1)%segment.size()];var cell=before[(k+1)%segment.size()]
  cells[segment[k]]=cell
  if cell!=null:events.append({"id":cell.id,"from":source,"to":segment[k],"wrap":k==segment.size()-1})
