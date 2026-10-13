extends RefCounted
const Registry = preload("res://scripts/mechanics/mechanic_registry.gd")
const Damage = preload("res://scripts/mechanics/damage_resolver.gd")
const Metrics = preload("res://scripts/ui/performance_metrics.gd")
static func install(cells: Array, specs: Array) -> void:
	for spec in specs:
		assert(Registry.valid_spec(spec))
		var cell: Dictionary = cells[int(spec.index)]
		cell[Registry.DEFINITIONS[spec.kind].layer] = Registry.payload(spec)
		cell["fixed"] = true

static func layer(cell: Dictionary) -> String:
	return "armor" if cell.has("armor") else ("obstacle" if cell.has("obstacle") else "")

static func wave(cells: Array, exploded: Array, direct: Array, triggered: Array, normal_colors: Dictionary, collected: Dictionary, width: int, height: int) -> Array:
	var present := false
	for cell in cells:
		if cell!=null and (cell.has("armor") or cell.has("obstacle")):
			present=true
			break
	if not present: return []
	var started := Time.get_ticks_usec()
	var hits := Damage.plan(cells,exploded,direct,triggered,width,height)
	var events: Array = []
	for index in cells.size():
		if cells[index] == null: continue
		var key := layer(cells[index])
		if key == "": continue
		var m: Dictionary = cells[index][key]
		var prior: Dictionary = m.duplicate()
		var result: Dictionary = Registry.DEFINITIONS[m.kind].rule.resolve(m,int(hits.get(index,0)),normal_colors)
		if not result.changed: continue
		var opened: bool = result.opened
		var objective: String = Registry.DEFINITIONS[m.kind].objective
		collected[objective] += int(result.progress)
		events.append({"index":index,"kind":m.kind,"before":prior,"after":m.duplicate(),"opened":opened})
		if opened:
			if key == "armor":
				cells[index].erase(key)
				cells[index].erase("fixed")
			else: cells[index] = null
	Metrics.elapsed("mechanic_wave",started)
	return events
