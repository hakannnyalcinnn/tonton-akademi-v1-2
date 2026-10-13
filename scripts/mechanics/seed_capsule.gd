extends RefCounted
const Damage = preload("res://scripts/mechanics/damage_resolver.gd")
static func resolve(data: Dictionary, damage: int, _colors: Dictionary) -> Dictionary:
	# A pod opens after two distinct waves, including direct power waves.
	return Damage.durability(data,damage,1,false)
