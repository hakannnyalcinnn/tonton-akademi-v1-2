extends RefCounted
const Gravity=preload("res://scripts/core/gravity.gd")
static func present(cell: Variant) -> bool:return cell!=null and cell.get("motion",{}).get("kind","")=="bubble"
static func compact(cells: Array,width: int,height: int,direction: String) -> void:
 var bubbles: Array=[]
 for i in cells.size():
  if present(cells[i]):cells[i].fixed=true;bubbles.append(cells[i])
 Gravity.compact(cells,width,height,direction)
 for cell in bubbles:cell.erase("fixed")
 if bubbles.is_empty():return
 var opposite: String={"down":"up","up":"down","left":"right","right":"left"}[direction]
 # Destination-edge order; each bubble scans its own unoccupied corridor, never crosses blockers.
 for line in Gravity.lines(width,height,opposite):
  for k in line.size():
   var source: int=line[k]
   if not present(cells[source]):continue
   var destination:=source
   for step in range(k-1,-1,-1):
    if cells[line[step]]!=null:break
    destination=line[step]
   if destination!=source:cells[destination]=cells[source];cells[source]=null
static func break_layers(cells: Array,hit: Array,collected: Dictionary) -> Array:
 var preserved: Array=[]
 for i in hit:
  if present(cells[i]):
   cells[i].erase("motion");preserved.append(i);collected.bubbles=int(collected.get("bubbles",0))+1
 return preserved
