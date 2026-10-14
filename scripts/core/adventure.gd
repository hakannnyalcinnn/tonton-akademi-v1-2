extends RefCounted
## One deterministic objective layer over the existing Match-3 damage transaction.
static func initial(definition: Dictionary) -> Dictionary:
	var result: Dictionary=normalize(definition.get("adventure",{}))
	for cage in result.get("cages",[]):cage.remaining=int(cage.hp)
	if result.has("boss"):
		for phase in result.boss.phases:
			if phase.has("colors"):phase.colors=phase.colors.map(func(c):return int(c))
		result.boss.phase=0;result.boss.remaining=int(result.boss.phases[0].hp);result.boss.defeated=false
	return result
static func wave(state: Dictionary, removed: Array, normal_colors: Dictionary, special: bool, collected: Dictionary) -> Array:
	var events: Array=[]
	for cage in state.get("cages",[]):
		if cage.remaining<=0:continue
		var index:=int(cage.index)
		if removed.any(func(i):return absi(int(i)%8-index%8)+absi(int(i)/8-index/8)<=1):
			cage.remaining-=1
			if cage.remaining==0:collected.rescues=int(collected.get("rescues",0))+1
			events.append({"kind":"rescue","index":index,"hp":cage.remaining,"creature":cage.creature})
	if state.has("boss") and not state.boss.defeated:
		var boss: Dictionary=state.boss
		var phase: Dictionary=boss.phases[int(boss.phase)]
		var damage:=0
		if phase.get("special",false):damage=1 if special else 0
		else:
			for color in normal_colors:
				if phase.colors.has(int(color)):damage+=int(normal_colors[color])
		boss.remaining=maxi(0,int(boss.remaining)-damage)
		if damage>0:events.append({"kind":"boss","damage":damage,"phase":boss.phase})
		if boss.remaining==0:
			boss.phase+=1
			if boss.phase>=boss.phases.size():boss.defeated=true;collected.bosses=int(collected.get("bosses",0))+1
			else:boss.remaining=int(boss.phases[int(boss.phase)].hp)
	return events
static func valid(state: Variant) -> bool:
	if not state is Dictionary:return false
	if not state.get("cages",[]) is Array:return false
	var seen: Dictionary={}
	for cage in state.get("cages",[]):
		if not cage is Dictionary or not cage.has_all(["index","hp","creature"]):return false
		if not preload("res://scripts/mechanics/mechanic_registry.gd").integer(cage.index,0,71) or not preload("res://scripts/mechanics/mechanic_registry.gd").integer(cage.hp,1,10):return false
		if seen.has(int(cage.index)) or not cage.creature is String or cage.creature not in ["creature-1","creature-2","creature-3","creature-4","creature-5"]:return false
		seen[int(cage.index)]=true
		if cage.has("remaining") and not preload("res://scripts/mechanics/mechanic_registry.gd").integer(cage.remaining,0,int(cage.hp)):return false
	if state.has("boss"):
		var boss=state.boss
		if not boss is Dictionary or not boss.get("phases",null) is Array or boss.phases.size()<1 or boss.phases.size()>5:return false
		for phase in boss.phases:
			if not phase is Dictionary or not preload("res://scripts/mechanics/mechanic_registry.gd").integer(phase.get("hp",0),1,100):return false
			if not phase.get("special",false):
				if not phase.get("colors",null) is Array or phase.colors.is_empty():return false
				for c in phase.colors:
					if not preload("res://scripts/mechanics/mechanic_registry.gd").integer(c,0,4):return false
		if boss.has("phase"):
			if not preload("res://scripts/mechanics/mechanic_registry.gd").integer(boss.phase,0,boss.phases.size()) or not boss.get("defeated",null) is bool:return false
			if boss.defeated!=(int(boss.phase)==boss.phases.size()):return false
			if not boss.defeated and not preload("res://scripts/mechanics/mechanic_registry.gd").integer(boss.get("remaining",-1),1,int(boss.phases[int(boss.phase)].hp)):return false
	return true

static func normalize(value: Variant) -> Variant:
	if value is Dictionary:
		var result: Dictionary={}
		for key in value:result[key]=normalize(value[key])
		return result
	if value is Array:
		var result: Array=[]
		for item in value:result.append(normalize(item))
		return result
	if value is float and value==floor(value):return int(value)
	return value
