extends RefCounted
const Damage=preload("res://scripts/mechanics/damage_resolver.gd")
static func resolve(data: Dictionary, damage: int, _colors: Dictionary) -> Dictionary:
	# The clamp preserves the two distinct-wave rule, even under a prism.
	return Damage.durability(data,damage,1,false)
