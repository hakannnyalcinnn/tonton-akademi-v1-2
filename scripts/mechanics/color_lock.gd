extends RefCounted
static func resolve(data: Dictionary, _damage: int, colors: Dictionary) -> Dictionary:
	# Colors are deduplicated normal removals from this transaction, cascades included.
	var prior: int = data.energy
	data.energy=mini(int(data.required),prior+int(colors.get(str(data.color),0)))
	var opened: bool = data.energy>=data.required
	return {"changed":prior!=data.energy,"opened":opened,"progress":1 if opened else 0}
