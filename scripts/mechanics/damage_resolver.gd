extends RefCounted
const Match = preload("res://scripts/core/match_detector.gd")
## A wave is a single damage transaction. Overlaps select max, never sum.
static func plan(cells: Array, exploded: Array, direct: Array, triggered: Array, width: int, height: int, virtual: Array = []) -> Dictionary:
	var hits: Dictionary = {}
	for index in exploded:
		for neighbor in Match.neighbors(index,width,height):
			if cells[neighbor] != null and (cells[neighbor].has("armor") or cells[neighbor].has("obstacle")): hits[neighbor] = 1
	for index in direct:
		if index >= 0 and index < cells.size() and cells[index] != null and (cells[index].has("armor") or cells[index].has("obstacle")):
			hits[index] = maxi(1,int(hits.get(index,0)))
	# Prisms crush stone with two damage; seeds and armor always lose one layer/wave.
	for source in triggered:
		if cells[source].p != "prism": continue
		for index in hits:
			if cells[index].get("obstacle",{}).get("kind","") == "stone":
				var distance: int = absi(index%width-source%width)+absi(int(index/width)-int(source/width))
				if distance <= 2: hits[index] = 2
	for power in virtual:
		if power.kind!="prism":continue
		for index in hits:
			if cells[index]!=null and cells[index].get("obstacle",{}).get("kind","")=="stone":
				var distance: int=absi(index%width-int(power.index)%width)+absi(index/width-int(power.index)/width)
				if distance<=2:hits[index]=maxi(2,int(hits[index]))
	return hits

static func durability(data: Dictionary, damage: int, maximum_per_wave: int, count_layers: bool) -> Dictionary:
	var old_hp: int = data.hp
	data.hp = maxi(0,old_hp-mini(maximum_per_wave,damage))
	return {"changed":old_hp!=data.hp,"opened":data.hp==0,"progress":old_hp-int(data.hp) if count_layers else (1 if data.hp==0 else 0)}
