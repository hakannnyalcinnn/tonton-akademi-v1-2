extends RefCounted
const Damage = preload("res://scripts/mechanics/damage_resolver.gd")
static func resolve(data: Dictionary, damage: int, _colors: Dictionary) -> Dictionary:
	# Removing layers advances the objective; the underlying crystal survives.
	return Damage.durability(data,damage,1,true)
