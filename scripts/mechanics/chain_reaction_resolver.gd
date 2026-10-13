extends RefCounted
const Traits=preload("res://scripts/mechanics/crystal_traits.gd")
const Powers=preload("res://scripts/core/powerups.gd")
const Mechanics=preload("res://scripts/mechanics/mechanic_manager.gd")
const Crates=preload("res://scripts/mechanics/explosive_crate_manager.gd")
const Metrics=preload("res://scripts/ui/performance_metrics.gd")
static func present(cells: Array) -> bool:
	for cell in cells:
		if cell!=null and cell.get("obstacle",{}).get("kind","")=="crate":return true
	return false
static func resolve(cells: Array, removed: Array, selected: int, colors: Dictionary, collected: Dictionary, width: int, height: int) -> Dictionary:
	var started:=Time.get_ticks_usec()
	var queue: Array=[{"source":-1,"area":removed.duplicate()}]
	var triggered: Array=[];var exploded: Dictionary={};var all_removed: Array=[];var events: Array=[];var event_log: Array=[]
	var cursor:=0
	while cursor<queue.size():
		# Each crystal power and each crate contributes at most once: <= 1+2*N.
		if cursor>cells.size()*2:
			Metrics.incident("Effect queue invariant exceeded",{"queue":queue.duplicate(true),"cursor":cursor})
			assert(false,"Effect queue invariant exceeded")
			break
		var effect: Dictionary=queue[cursor];cursor+=1
		var area: Array=[];var normals: Array=[];var normal_colors: Dictionary={}
		for i in effect.area:
			if i not in area:area.append(i)
		var scan:=0
		var wave_powers: Array=[]
		while scan<area.size():
			var i: int=area[scan];scan+=1
			if cells[i]==null or cells[i].get("fixed",false):continue
			if cells[i].p!="" and i not in triggered:
				triggered.append(i);wave_powers.append(i)
				for target in Powers.area(i,cells[i].p,cells,width,selected):
					if target not in area:area.append(target)
		for i in area:
			if cells[i]==null or cells[i].get("fixed",false):continue
			if i not in all_removed:
				all_removed.append(i)
				if cells[i].p=="":
					normals.append(i)
					var color:=str(colors.get(i,selected if Traits.flexible(cells[i]) and Traits.supports(cells[i],selected) else cells[i].c))
					normal_colors[color]=int(normal_colors.get(color,0))+1
		var hits:=Mechanics.wave(cells,normals,area,wave_powers,normal_colors,collected,width,height)
		for event in hits:
			event.event_id=cursor;events.append(event)
			if event.kind=="crate" and event.opened and not exploded.has(event.index):
				exploded[event.index]=true
				queue.append({"source":event.index,"area":Crates.area(event.index,width,height)})
		event_log.append({"event_id":cursor,"source":effect.source,"area":area})
	Metrics.elapsed("effect_queue_logic",started)
	return {"removed":all_removed,"triggered":triggered,"mechanics":events,"events":event_log}
