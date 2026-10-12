extends RefCounted

static func move_points(normal_count: int, group_size: int, resonated: bool, special: bool, combined: bool) -> int:
	return normal_count * 20 + group_size * group_size * 5 + (120 if resonated else 0) + (100 if special else 0) + (250 if combined else 0)

static func completion_bonus(moves: int) -> int:
	return maxi(0, moves) * 100

static func stars(points: int, thresholds: Array) -> int:
	var result := 1
	if points >= thresholds[1]: result = 2
	if points >= thresholds[2]: result = 3
	return result
