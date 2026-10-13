extends RefCounted
## Only implemented mechanics are registered. Layers describe ownership, not art.
const DEFINITIONS := {
	"seed": {"rule":preload("res://scripts/mechanics/seed_capsule.gd"), "layer":"obstacle", "hp":2, "objective":"flowers", "name":"Tohum"},
	"ice": {"rule":preload("res://scripts/mechanics/ice_armor.gd"), "layer":"armor", "hp":2, "objective":"ice", "name":"Buz"},
	"stone": {"rule":preload("res://scripts/mechanics/stone_obstacle.gd"), "layer":"obstacle", "hp":3, "objective":"stones", "name":"Taş"},
	"lock": {"rule":preload("res://scripts/mechanics/color_lock.gd"), "layer":"obstacle", "hp":0, "objective":"locks", "name":"Kilit"}
}
static func integer(value: Variant, minimum: int, maximum: int) -> bool:
	return (value is int or value is float) and value >= minimum and value <= maximum and float(value) == floor(float(value))

static func valid_spec(spec: Variant) -> bool:
	if not spec is Dictionary or not spec.has_all(["kind","index"]): return false
	if spec.kind not in DEFINITIONS or not integer(spec.index,0,71): return false
	if spec.kind == "lock":
		return integer(spec.get("color",-1),0,4) and integer(spec.get("required",0),1,1000)
	return true
static func payload(spec: Dictionary) -> Dictionary:
	var result := {"kind":spec.kind, "hp":DEFINITIONS[spec.kind].hp}
	if spec.kind == "lock":
		result.merge({"color":int(spec.color),"required":int(spec.required),"energy":0})
	return result
static func valid_cell(cell: Dictionary) -> bool:
	var count := 0
	for layer in ["armor","obstacle"]:
		if not cell.has(layer): continue
		count += 1
		var m = cell[layer]
		if not m is Dictionary or not m.has_all(["kind","hp"]) or m.kind not in DEFINITIONS: return false
		if DEFINITIONS[m.kind].layer != layer or not cell.get("fixed",false) or cell.p != "": return false
		if m.kind == "lock":
			if not m.has_all(["color","required","energy"]) or m.hp != 0: return false
			if not integer(m.color,0,4) or not integer(m.required,1,1000): return false
			if not integer(m.energy,0,int(m.required)-1): return false
		elif not integer(m.hp,1,int(DEFINITIONS[m.kind].hp)): return false
	return count <= 1
