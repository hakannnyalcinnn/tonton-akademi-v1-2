extends RefCounted
## Platform-independent 31-bit LCG. State is small enough to survive JSON numbers.
var state: int = 1

func _init(seed_value: int = 1) -> void:
	state = seed_value & 0x7fffffff

func next_int(bound: int) -> int:
	assert(bound > 0)
	state = (1103515245 * state + 12345) & 0x7fffffff
	return (state >> 8) % bound

func shuffle(items: Array) -> void:
	for i in range(items.size() - 1, 0, -1):
		var j := next_int(i + 1)
		var value = items[i]
		items[i] = items[j]
		items[j] = value
