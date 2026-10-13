extends RefCounted
const Damage = preload("res://scripts/mechanics/damage_resolver.gd")
static func resolve(data: Dictionary, damage: int, _colors: Dictionary) -> Dictionary:
	# Three durability, with a stronger direct prism hit from DamageResolver.
	return Damage.durability(data,damage,2,false)
