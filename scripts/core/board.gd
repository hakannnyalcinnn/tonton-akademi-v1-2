extends RefCounted

const Match = preload("res://scripts/core/match_detector.gd")
const Gravity = preload("res://scripts/core/gravity.gd")
const Resonance = preload("res://scripts/core/resonance.gd")
const Powers = preload("res://scripts/core/powerups.gd")
const Score = preload("res://scripts/core/score.gd")
const SeedRng = preload("res://scripts/core/seed_rng.gd")
const WIDTH := 8
const HEIGHT := 9

var cells: Array = []
var level: Dictionary
var rng = SeedRng.new()
var resonance = Resonance.new()
var moves: int
var score: int = 0
var collected: Dictionary = {"total": 0, "0": 0, "1": 0, "2": 0, "3": 0, "4": 0}
var direction: String = "down"
var energy: int = 0
var energy_blocks: int = 0
var serial: int = 0
var outcome: String = "playing"

func _init(definition: Dictionary = {}) -> void:
	if definition.is_empty(): return
	level = definition.duplicate(true)
	moves = int(level.moves)
	rng = SeedRng.new(int(level.seed))
	for color in level.layout: cells.append(make_cell(int(color)))
	ensure_move()

func make_cell(color: int = -1, power: String = "") -> Dictionary:
	serial += 1
	return {"c": rng.next_int(5) if color < 0 else color, "p": power, "id": serial}

func tap(index: int, selected_color: int = -1, partner: int = -1) -> Dictionary:
	if outcome != "playing" or index < 0 or index >= cells.size() or cells[index] == null:
		return {"accepted": false}
	var special: bool = cells[index].p != ""
	var combined := false
	if partner >= 0:
		if not special or partner not in Match.neighbors(index, WIDTH, HEIGHT) or cells[partner] == null or cells[partner].p == "":
			return {"accepted": false}
		combined = true
	if (cells[index].p == "color" or (combined and cells[partner].p == "color")) and (selected_color < 0 or selected_color > 4):
		return {"accepted": false, "choose_color": true}
	var before := cells.duplicate(true)
	var group: Array = [] if special else Match.group(cells, index, WIDTH, HEIGHT)
	moves -= 1
	if not special and group.size() < 2:
		finish_if_needed()
		return {"accepted": true, "invalid": true, "removed": [], "before": before, "points": 0}
	var color: int = cells[index].c
	var created: String = "" if special else Powers.created(group, WIDTH)
	var resonated := false
	var removed: Array
	if combined:
		removed = Powers.combo_area(index, partner, cells, WIDTH, selected_color)
		resonance.reset()
	elif special:
		removed = Powers.area(index, cells[index].p, cells, WIDTH, selected_color)
		resonance.reset()
	else:
		removed = group.duplicate()
		if level.resonance:
			resonated = resonance.advance(color)
			if resonated: removed.append_array(Resonance.extras(cells, index, color, removed, WIDTH))
	# Existing specials touched by a wave chain exactly once, in sorted cell order.
	var triggered: Array = [index, partner] if special else []
	var cursor := 0
	while cursor < removed.size():
		var i: int = removed[cursor]
		if i not in triggered and cells[i] != null and cells[i].p != "":
			triggered.append(i)
			var chain_color: int = selected_color if selected_color >= 0 else color
			for target in Powers.area(i, cells[i].p, cells, WIDTH, chain_color):
				if target not in removed: removed.append(target)
		cursor += 1
	var unique: Array = []
	for i in removed:
		if i not in unique: unique.append(i)
	unique.sort()
	var normal_count := 0
	for i in unique:
		if cells[i] != null and cells[i].p == "":
			normal_count += 1
			collected[str(cells[i].c)] += 1
		cells[i] = null
	collected.total += normal_count
	if created != "": cells[index] = make_cell(color, created)
	if level.gravity:
		energy_blocks += normal_count
		while energy_blocks >= 12:
			energy_blocks -= 12
			energy = mini(2, energy + 1)
	var points: int = Score.move_points(normal_count, group.size(), resonated, special, combined)
	score += points
	settle()
	var shuffled := ensure_move()
	finish_if_needed()
	return {"accepted": true, "invalid": false, "before": before, "removed": unique, "points": points, "resonated": resonated, "created": created, "special": special, "combined": combined, "shuffled": shuffled, "origin": index}

func settle() -> void:
	Gravity.compact(cells, WIDTH, HEIGHT, direction)
	for line in Gravity.lines(WIDTH, HEIGHT, direction):
		for index in line:
			if cells[index] == null: cells[index] = make_cell()

func change_gravity(next_direction: String) -> Dictionary:
	if outcome != "playing" or not level.gravity or energy < 1 or next_direction == direction or next_direction not in ["down", "up", "left", "right"]:
		return {"accepted": false}
	var before := cells.duplicate(true)
	energy -= 1
	direction = next_direction
	settle()
	ensure_move()
	return {"accepted": true, "before": before, "removed": [], "points": 0, "gravity": true}

func ensure_move() -> bool:
	if Match.has_move(cells, WIDTH, HEIGHT): return false
	for attempt in 40:
		rng.shuffle(cells)
		if Match.has_move(cells, WIDTH, HEIGHT): return true
	# Preserve the exact multiset even in an adversarial arrangement.
	for a in cells.size():
		for b in range(a + 1, cells.size()):
			if cells[a].p == "" and cells[b].p == "" and cells[a].c == cells[b].c:
				var first = cells[a]
				cells[a] = cells[0]
				cells[0] = first
				var second = cells[b]
				cells[b] = cells[1]
				cells[1] = second
				assert(Match.has_move(cells, WIDTH, HEIGHT))
				return true
	assert(false, "72 normal cells / 5 colors must have a repeated color")
	return true

func targets_complete() -> bool:
	for key in level.targets:
		if collected[key] < level.targets[key]: return false
	return true

func finish_if_needed() -> void:
	if outcome != "playing": return
	if targets_complete():
		outcome = "won"
		score += Score.completion_bonus(moves)
	elif moves <= 0:
		outcome = "lost"

func snapshot() -> Dictionary:
	return {"level_id": int(level.id), "cells": cells.duplicate(true), "moves": moves, "score": score, "collected": collected.duplicate(), "direction": direction, "energy": energy, "energy_blocks": energy_blocks, "serial": serial, "rng": rng.state, "resonance_color": resonance.color, "resonance_count": resonance.count, "outcome": outcome}

static func whole(value: Variant, minimum: int, maximum: int) -> bool:
	if not (value is int or value is float): return false
	return value >= minimum and value <= maximum and float(value) == floor(float(value))

func restore(data: Dictionary) -> bool:
	if not data.has_all(["level_id", "cells", "moves", "score", "collected", "direction", "energy", "energy_blocks", "serial", "rng", "resonance_color", "resonance_count", "outcome"]): return false
	if not data.cells is Array or data.cells.size() != 72: return false
	if not whole(data.level_id, int(level.id), int(level.id)) or data.direction not in ["up", "down", "left", "right"]: return false
	if not whole(data.moves, 0, int(level.moves)) or not whole(data.score, 0, 2147483647) or not whole(data.energy, 0, 2) or not whole(data.energy_blocks, 0, 11): return false
	if not whole(data.serial, 72, 2147483647) or not whole(data.rng, 0, 2147483647): return false
	if data.outcome not in ["playing", "won", "lost"] or not whole(data.resonance_count, 0, 2) or not whole(data.resonance_color, -1, 4): return false
	if not data.collected is Dictionary or not data.collected.has_all(["total", "0", "1", "2", "3", "4"]): return false
	var seen: Array = []
	var normalized: Array = []
	for cell in data.cells:
		if not cell is Dictionary or not cell.has_all(["c", "p", "id"]): return false
		if not whole(cell.c, 0, 4) or cell.p not in ["", "rocket_h", "rocket_v", "prism", "color"] or not whole(cell.id, 1, int(data.serial)) or int(cell.id) in seen: return false
		seen.append(int(cell.id))
		normalized.append({"c": int(cell.c), "p": str(cell.p), "id": int(cell.id)})
	var total := 0
	for key in data.collected:
		if key not in ["total", "0", "1", "2", "3", "4"] or not whole(data.collected[key], 0, 2147483647): return false
		if key != "total": total += int(data.collected[key])
	if total != int(data.collected.total): return false
	cells = normalized
	moves = int(data.moves)
	score = int(data.score)
	collected = data.collected.duplicate()
	for key in collected: collected[key] = int(collected[key])
	direction = str(data.direction)
	energy = int(data.energy)
	energy_blocks = int(data.energy_blocks)
	serial = int(data.serial)
	rng.state = int(data.rng)
	resonance.color = int(data.resonance_color)
	resonance.count = int(data.resonance_count)
	outcome = str(data.outcome)
	return true
