extends SceneTree

const Board = preload("res://scripts/core/board.gd")
const Catalog = preload("res://scripts/core/level_catalog.gd")
const Match = preload("res://scripts/core/match_detector.gd")
const Gravity = preload("res://scripts/core/gravity.gd")
const Resonance = preload("res://scripts/core/resonance.gd")
const Powers = preload("res://scripts/core/powerups.gd")
const Score = preload("res://scripts/core/score.gd")
const Save = preload("res://scripts/core/save_manager.gd")
var checks := 0
var failures := 0
var simulations := 0
var simulated_moves := 0

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		printerr("FAIL: " + message)

func fixture(number: int = 10):
	var definition: Dictionary = Catalog.get_level(number)
	definition.targets = {"total": 10000}
	definition.moves = 100
	var b = Board.new(definition)
	for i in 72: b.cells[i] = b.make_cell((i % 8 + int(i / 8)) % 5)
	return b

func _initialize() -> void:
	call_deferred("run")

func run() -> void:
	test_matches()
	test_gravity()
	test_resonance()
	test_powers()
	test_score_and_outcomes()
	test_save()
	test_shuffle()
	test_simulations()
	await test_ui()
	await create_timer(0.15).timeout
	print("PRIZMA TEST RESULT: %d assertions, %d failures; %d simulated games, %d moves" % [checks, failures, simulations, simulated_moves])
	quit(1 if failures else 0)

func test_matches() -> void:
	var b = fixture()
	b.cells[0].c = 0
	b.cells[1].c = 0
	check(Match.group(b.cells, 0, 8, 9) == [0, 1], "orthogonal pair")
	var old_moves: int = b.moves
	var event: Dictionary = b.tap(0)
	check(event.removed == [0, 1] and b.moves == old_moves - 1, "pair clear costs one move")
	check(b.collected.total == 2 and b.collected["0"] == 2, "target counts exact")
	b = fixture()
	b.cells[9].c = b.cells[0].c
	check(Match.group(b.cells, 0, 8, 9) == [0], "diagonal excluded")
	var original: Array = b.cells.duplicate(true)
	event = b.tap(0)
	check(event.invalid and b.moves == 99 and b.cells == original and b.score == 0, "isolated tap consumes one move without clear")
	check(not b.tap(-1).accepted and not b.tap(72).accepted and b.moves == 99, "out-of-board taps ignored")
	b = fixture()
	for cell in b.cells: cell.c = 2
	event = b.tap(19)
	check(event.removed.size() == 72 and b.collected.total == 72, "whole board group")
	check(b.cells.any(func(cell): return cell.p == "color"), "large group yields color bomb")
	check(b.moves == 99 and b.cells.size() == 72, "no automatic clear during refill")
	print("PASS suite: matching and move rules")

func test_gravity() -> void:
	for direction in ["down", "up", "left", "right"]:
		var cells: Array = []
		cells.resize(9)
		cells[0] = {"id": 1}
		cells[4] = {"id": 2}
		cells[8] = {"id": 3}
		Gravity.compact(cells, 3, 3, direction)
		var destinations: Array = {"down": [6, 7, 8], "up": [0, 1, 2], "left": [0, 3, 6], "right": [2, 5, 8]}[direction]
		for i in 3: check(cells[destinations[i]] != null and cells[destinations[i]].id == i + 1, "compact " + direction)
		for line in Gravity.lines(3, 3, direction):
			var gap := false
			for index in line:
				if cells[index] == null: gap = true
				else: check(not gap, "no gap between destination and survivor " + direction)
		var b = fixture()
		b.direction = direction
		b.cells[20] = null
		b.cells[21] = null
		var ids: Array = []
		for cell in b.cells:
			if cell != null: ids.append(cell.id)
		b.settle()
		for line in Gravity.lines(8, 9, direction):
			var new_seen := false
			for index in line:
				if b.cells[index].id not in ids: new_seen = true
				else: check(not new_seen, "new blocks on source edge " + direction)
	var b = fixture()
	b.energy = 2
	b.cells[1].c = b.cells[0].c
	b.resonance.color = 1
	b.resonance.count = 2
	var before: Array = b.cells.duplicate(true)
	check(b.change_gravity("left").accepted and b.energy == 1 and b.moves == 100, "gravity cost separate from moves")
	check(b.resonance.count == 2 and b.resonance.color == 1, "gravity preserves resonance")
	check(b.cells == before, "full board does not invent a physical shift")
	check(not b.change_gravity("left").accepted and not b.change_gravity("bad").accepted and b.energy == 1, "same and invalid direction no cost")
	b.energy = 0
	check(not b.change_gravity("right").accepted, "no free energy")
	b = fixture(1)
	b.energy = 2
	check(not b.change_gravity("up").accepted, "gravity tutorial lock")
	b = fixture()
	for cell in b.cells: cell.c = 1
	b.tap(0)
	check(b.energy == 2 and b.energy_blocks == 0, "energy capped at two")
	print("PASS suite: four gravity directions and energy")

func test_resonance() -> void:
	var r = Resonance.new()
	check(not r.advance(0) and r.count == 1, "resonance first")
	check(not r.advance(0) and r.count == 2, "resonance second")
	check(r.advance(0) and r.count == 0, "resonance third")
	r.advance(0)
	r.advance(1)
	check(r.color == 1 and r.count == 1, "different color resets chain")
	var b = fixture()
	var origin := 27
	for i in [11, 18, 20, 25, 26, 28, 29, 34, 36, 43]: b.cells[i].c = 4
	b.cells[27].c = 4
	b.cells[26].p = "prism"
	var extra: Array = Resonance.extras(b.cells, origin, 4, [27, 28], 8)
	check(extra == [11, 18, 20, 25], "resonance distance then row/column and cap")
	check(26 not in extra and 28 not in extra, "resonance excludes special and original group")
	b = fixture()
	b.cells[0].c = 0
	b.cells[1].c = 0
	b.cells[16].c = 0
	b.resonance.color = 0
	b.resonance.count = 2
	var event: Dictionary = b.tap(0)
	check(event.resonated and 16 in event.removed and b.score >= 120, "resonance integrated clear")
	b = fixture(1)
	b.cells[0].c = 0
	b.cells[1].c = 0
	b.tap(0)
	check(b.resonance.count == 0, "resonance locked before level six")
	print("PASS suite: deterministic resonance")

func test_powers() -> void:
	check(Powers.created([0, 1, 2, 3], 8) == "", "four blocks normal")
	check(Powers.created([0, 1, 2, 3, 4], 8) == "rocket_h", "five horizontal rocket")
	check(Powers.created([0, 8, 16, 24, 32, 40], 8) == "rocket_v", "six vertical rocket")
	check(Powers.created([0, 1, 2, 3, 4, 5, 6], 8) == "prism", "seven prism")
	check(Powers.created(range(10), 8) == "color", "ten color bomb")
	var b = fixture()
	for i in 5: b.cells[i].c = 0
	b.cells[5].c = 1
	for i in range(8, 16): b.cells[i].c = 1
	var event: Dictionary = b.tap(2)
	var new_power = b.cells.filter(func(cell): return cell.p == "rocket_h")
	check(event.created == "rocket_h" and new_power.size() == 1, "created power survives current resolution")
	check(b.collected.total == 5, "only five group colors counted")
	# Remove gravity displacement to verify tap-origin placement rule.
	b = fixture()
	b.direction = "up"
	for i in 5: b.cells[i].c = 0
	b.cells[5].c = 1
	for i in range(8, 16): b.cells[i].c = 1
	b.tap(2)
	check(b.cells[2].p == "rocket_h", "power created at tapped cell")
	b = fixture()
	b.cells[0].p = "rocket_h"
	b.cells[4].p = "rocket_v"
	event = b.tap(0)
	check(68 in event.removed and event.removed.size() == 16, "rocket chain runs once, union row/column")
	b = fixture()
	b.cells[27].p = "prism"
	event = b.tap(27)
	check(event.removed.size() == 13, "prism Manhattan area")
	b = fixture()
	b.cells[0].p = "color"
	var old_moves: int = b.moves
	check(b.tap(0).choose_color and b.moves == old_moves, "color picker no premature move")
	var expected := 0
	for cell in b.cells:
		if cell.c == 3 and cell.p == "": expected += 1
	b.tap(0, 3)
	check(b.collected["3"] == expected and b.collected.total == expected, "color bomb only selected normal color")
	b = fixture()
	b.cells[0].p = "rocket_h"
	b.cells[1].p = "rocket_v"
	event = b.tap(0, -1, 1)
	check(event.combined and event.removed.size() == 24 and b.moves == 99, "rocket combo union counts once")
	b = fixture()
	b.cells[0].p = "rocket_h"
	b.cells[10].p = "prism"
	check(not b.tap(0, -1, 10).accepted and b.moves == 100, "nonadjacent powers cannot combine")
	b.cells[1].p = "prism"
	event = b.tap(0, -1, 1)
	check(event.combined and 65 in event.removed and 15 in event.removed, "rocket/prism wide cross")
	b = fixture()
	b.cells[27].p = "prism"
	b.cells[28].p = "prism"
	event = b.tap(27, -1, 28)
	check(event.combined and event.removed.size() > 13, "double prism expanded area")
	b = fixture()
	b.cells[0].p = "color"
	b.cells[1].p = "rocket_h"
	event = b.tap(0, 2, 1)
	check(event.combined and event.removed.size() > 20, "color rocket combination")
	print("PASS suite: powers and basic combinations")

func test_score_and_outcomes() -> void:
	check(Score.move_points(2, 2, false, false, false) == 60, "central score formula")
	check(Score.stars(400, [0, 500, 1000]) == 1 and Score.stars(500, [0, 500, 1000]) == 2 and Score.stars(1000, [0, 500, 1000]) == 3, "star boundary thresholds")
	var b = fixture()
	b.level.targets = {"total": 2}
	b.moves = 1
	b.cells[0].c = 0
	b.cells[1].c = 0
	b.tap(0)
	check(b.outcome == "won" and b.moves == 0 and b.score == 60, "win on last move beats lose")
	var score_before: int = b.score
	b.finish_if_needed()
	check(b.score == score_before and not b.tap(0).accepted, "completion bonus once and finished board locked")
	b = fixture()
	b.moves = 1
	b.tap(0)
	check(b.outcome == "lost" and b.moves == 0 and not b.tap(0).accepted, "lose on isolated last tap, no negative moves")
	print("PASS suite: score and outcomes")

func clear_save(path: String) -> void:
	for suffix in ["", ".bak", ".tmp"]:
		if FileAccess.file_exists(path + suffix): DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))

func test_save() -> void:
	var path := "user://automated-test.json"
	clear_save(path)
	var s = Save.new(path)
	var b = Board.new(Catalog.get_level(1))
	b.tap(0)
	check(s.save_active(b), "atomic save write")
	var restored_save = Save.new(path)
	var restored_board = Board.new(Catalog.get_level(1))
	check(restored_board.restore(restored_save.data.active), "active restore validation")
	check(restored_board.snapshot() == b.snapshot(), "exact board and RNG restore")
	var index := first_move(b)
	b.tap(index)
	restored_board.tap(index)
	check(b.snapshot() == restored_board.snapshot(), "same continuation after restart")
	b.level.targets = {"total": 1}
	b.finish_if_needed()
	check(s.complete(b) and not s.complete(b), "completion reward only once")
	check(s.data.unlocked == 2 and s.data.results["1"].score == b.score, "unlock and saved score match")
	var best: int = b.score
	b.score = 1
	s.complete(b)
	check(s.data.results["1"].score == best, "replay preserves best score")
	var final_save = Save.new(path)
	check(final_save.data.unlocked == 2 and final_save.data.rewarded.size() == 1, "completion persists")
	var invalid: Dictionary = restored_board.snapshot()
	invalid.cells[0].c = 99
	check(not restored_board.restore(invalid), "reject corrupt cell")
	invalid = restored_board.snapshot()
	invalid.cells[0].id = invalid.cells[1].id
	check(not restored_board.restore(invalid), "reject duplicate cell identities")
	for key in ["moves", "energy", "serial", "rng", "score", "resonance_count"]:
		invalid = restored_board.snapshot()
		invalid[key] = "broken"
		check(not restored_board.restore(invalid), "reject corrupt numeric type " + key)
	invalid = restored_board.snapshot()
	invalid.cells[0].c = 1.5
	check(not restored_board.restore(invalid), "reject fractional cell color")
	invalid = restored_board.snapshot()
	invalid.collected.total += 1
	check(not restored_board.restore(invalid), "reject inconsistent totals")
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string("{broken")
	file.close()
	var recovered = Save.new(path)
	check(recovered.data.unlocked == 2, "corrupted primary falls back to backup")
	clear_save(path)
	print("PASS suite: saves, replay and backup")

func test_shuffle() -> void:
	var b = fixture()
	check(not Match.has_move(b.cells, 8, 9), "dead board fixture")
	var colors: Array = []
	for cell in b.cells: colors.append(cell.c)
	colors.sort()
	check(b.ensure_move() and Match.has_move(b.cells, 8, 9), "free shuffle ensures move")
	var after: Array = []
	for cell in b.cells: after.append(cell.c)
	after.sort()
	check(after == colors and b.moves == 100 and b.score == 0, "shuffle preserves multiset and counters")
	print("PASS suite: shuffle")

func first_move(b) -> int:
	for i in 72:
		if b.cells[i].p != "" or Match.group(b.cells, i, 8, 9).size() >= 2: return i
	return -1

func best_move(b) -> Array:
	var best := -1.0
	var index := 0
	var picked := -1
	for i in 72:
		var cell: Dictionary = b.cells[i]
		var targets: Array
		var color := -1
		if cell.p == "":
			targets = Match.group(b.cells, i, 8, 9)
			if targets.size() < 2: continue
		elif cell.p == "color":
			color = 0
			var color_value := -1.0
			for c in 5:
				var area: Array = Powers.area(i, cell.p, b.cells, 8, c)
				var value: float = heuristic(b, area)
				if value > color_value:
					color_value = value
					color = c
			targets = Powers.area(i, cell.p, b.cells, 8, color)
		else:
			targets = Powers.area(i, cell.p, b.cells, 8)
		var value: float = heuristic(b, targets)
		if value > best:
			best = value
			index = i
			picked = color
	return [index, picked]

func heuristic(b, indices: Array) -> float:
	var value := 0.0
	for i in indices:
		if b.cells[i].p != "": continue
		var key := str(b.cells[i].c)
		value += 1.0
		if b.level.targets.has(key) and b.collected[key] < b.level.targets[key]: value += 5.0
	return value

func test_simulations() -> void:
	check(Catalog.all().size() == 10, "ten levels present")
	for number in range(1, 11):
		var definition: Dictionary = Catalog.get_level(number)
		check(Catalog.validate(definition), "level validation %d" % number)
		var wins := 0
		for seed_offset in 30:
			definition.seed = int(Catalog.get_level(number).seed) + seed_offset
			var a = Board.new(definition)
			var b = Board.new(definition)
			var actions := 0
			while a.outcome == "playing" and actions < 40:
				if a.energy > 0 and actions % 4 == 0:
					var dir: String = ["left", "up", "right", "down"][int(actions / 4) % 4]
					a.change_gravity(dir)
					b.change_gravity(dir)
				var move: Array = best_move(a)
				a.tap(move[0], move[1])
				b.tap(move[0], move[1])
				actions += 1
				simulated_moves += 1
				check(a.snapshot() == b.snapshot(), "seed determinism level %d seed %d action %d" % [number, seed_offset, actions])
				check(a.moves >= 0 and a.score >= 0 and a.cells.size() == 72, "simulation state bounds")
				var ids: Dictionary = {}
				for cell in a.cells: ids[cell.id] = true
				check(ids.size() == 72 and Match.has_move(a.cells, 8, 9), "simulation cell identities and no deadlock")
			if a.outcome == "won": wins += 1
			simulations += 1
		check(wins == 30, "all tested seeds solvable with heuristic at level %d (%d/30)" % [number, wins])
		print("Level %02d simulation: %d/30 won" % [number, wins])

func test_ui() -> void:
	var scene = load("res://scenes/main.tscn").instantiate()
	root.add_child(scene)
	await process_frame
	clear_save("user://ui-test.json")
	scene.save = Save.new("user://ui-test.json")
	scene.save.data.settings.music = false
	scene.audio.apply_settings(scene.save.data.settings)
	scene.show_home()
	check(scene.screen == "home", "home scene instantiated")
	scene.play_latest()
	check(scene.board.level.id == 1 and scene.board_view != null, "play button opens level one")
	await process_frame
	var touch := InputEventMouseButton.new()
	touch.button_index = MOUSE_BUTTON_LEFT
	touch.pressed = true
	touch.position = scene.board_view.global_position + Vector2(20, 20) * scene.stage.scale
	touch.global_position = touch.position
	root.push_input(touch, true)
	await process_frame
	check(scene.board.moves == int(scene.board.level.moves) - 1, "actual GUI input reaches board")
	touch.pressed = false
	root.push_input(touch, true)
	var moves: int = scene.board.moves
	scene.on_cell(1)
	check(scene.board.moves == moves, "rapid tap blocked during animation")
	await create_timer(0.5).timeout
	check(not scene.board_view.busy, "animation input unlocks")
	scene.show_pause()
	scene.on_cell(0)
	check(scene.board.moves == moves and scene.paused, "pause blocks board input")
	scene.close_overlay()
	scene.show_settings()
	check(scene.screen == "settings" and not scene.save.data.active.is_empty(), "settings preserves active game")
	scene.toggle_setting("reduced_motion")
	check(scene.save.data.settings.reduced_motion, "setting toggle persists")
	scene.play_latest()
	check(scene.board.moves == moves and scene.board_view.reduced_motion, "resume exact active game and settings")
	scene.show_map()
	check(scene.screen == "map" and scene.save.data.unlocked == 1, "map and locked progression")
	scene.start_level(2)
	check(scene.screen == "map", "locked level cannot start")
	for dimensions in [Vector2(360, 640), Vector2(360, 800), Vector2(768, 1024), Vector2(1080, 2400)]:
		scene.size = dimensions
		scene.layout_stage()
		check(scene.stage.position.x >= -0.01 and scene.stage.position.y >= -0.01 and scene.stage.size.x * scene.stage.scale.x <= dimensions.x + 0.01 and scene.stage.size.y * scene.stage.scale.y <= dimensions.y + 0.01, "UI fit at " + str(dimensions))
	scene.queue_free()
	await process_frame
	clear_save("user://ui-test.json")
	print("PASS suite: scene integration, pause, settings, rapid taps and viewport fit")
