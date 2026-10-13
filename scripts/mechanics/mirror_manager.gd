extends RefCounted
static func reflect(dx: int, dy: int, orientation: String) -> Vector2i:
	return Vector2i(-dy,-dx) if orientation=="/" else Vector2i(dy,dx)
static func resolve(_data: Dictionary, _damage: int, _colors: Dictionary) -> Dictionary:
	return {"changed":false,"opened":false,"progress":0}
