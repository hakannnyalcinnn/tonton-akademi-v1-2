extends RefCounted
## Deterministic energy pulse; never chooses or changes gravity direction.
const COST:=12
static func targets(cells: Array,origin: int,width: int) -> Array:
 var eligible: Array=[]
 for i in cells.size():
  var cell=cells[i]
  if cell==null or cell.get("fixed",false) or cell.p!="" or cell.has("armor") or cell.has("obstacle") or cell.has("trait") or cell.has("motion"):continue
  eligible.append(i)
 eligible.sort_custom(func(a,b):
  var da: int=absi(a%width-origin%width)+absi(int(a/width)-int(origin/width))
  var db: int=absi(b%width-origin%width)+absi(int(b/width)-int(origin/width))
  return da<db if da!=db else a<b)
 return eligible.slice(0,mini(3,eligible.size()))
