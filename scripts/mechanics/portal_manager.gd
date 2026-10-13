extends RefCounted
## Devices belong to coordinates, never to a crystal. One transfer per ID/action.
static func validate(specs: Variant) -> bool:
	if not specs is Array or specs.size()>8:return false
	var occupied: Dictionary={}
	for pair in specs:
		if not pair is Dictionary or not pair.has_all(["entry","exit"]):return false
		for key in ["entry","exit"]:
			var v=pair[key]
			if not (v is int or v is float) or v<0 or v>71 or float(v)!=floor(float(v)) or occupied.has(int(v)):return false
			occupied[int(v)]=true
	return true
static func transfer(cells: Array, pairs: Array, arrived: Dictionary, used: Dictionary, queue: Array) -> Array:
	var events: Array=[]
	var ordered:=pairs.duplicate(true)
	ordered.sort_custom(func(a,b):return int(a.entry)<int(b.entry))
	for pair in ordered:
		var a:=int(pair.entry);var b:=int(pair.exit)
		var cell=cells[a]
		if cell==null or cell.get("fixed",false) or cell.p!="" or not arrived.has(int(cell.id)) or used.has(int(cell.id)) or cells[b]!=null:continue
		cells[b]=cell;cells[a]=null;used[int(cell.id)]=true
		var event: Dictionary={"id":int(cell.id),"from":a,"to":b,"kind":"portal"}
		events.append(event);queue.append(event)
	return events
