extends SceneTree
const Board = preload("res://scripts/core/board.gd")
const Catalog = preload("res://scripts/core/level_catalog.gd")
const Match = preload("res://scripts/core/match_detector.gd")
const Generator = preload("res://scripts/core/board_generator.gd")
const Gravity = preload("res://scripts/core/gravity.gd")
const Resonance = preload("res://scripts/core/resonance.gd")
const Powers = preload("res://scripts/core/powerups.gd")
const Score = preload("res://scripts/core/score.gd")
const Save = preload("res://scripts/core/save_manager.gd")
const Rng = preload("res://scripts/core/seed_rng.gd")
var checks := 0
var failures := 0
var simulated_moves := 0
var simulated_games := 0
var generated_boards := 0

func check(value: bool, message: String) -> void:
	checks += 1
	if not value:
		failures += 1
		printerr("FAIL: " + message)

func _initialize() -> void:
	call_deferred("run")

func fixture(number: int = 7):
	var definition: Dictionary = Catalog.get_level(number)
	definition.moves = 100
	definition.targets = {"total": 10000}
	return Board.new(definition)

func cells(colors: Array) -> Array:
	var result: Array = []
	for i in colors.size(): result.append({"c": colors[i], "p": "", "id": i + 1})
	return result

func clear_save(path: String) -> void:
	for suffix in ["", ".bak", ".tmp", ".v1-archive"]:
		if FileAccess.file_exists(path + suffix): DirAccess.remove_absolute(ProjectSettings.globalize_path(path + suffix))

func run() -> void:
	test_scanner()
	test_swap_and_cascade()
	test_powers()
	test_resonance()
	test_gravity_and_shuffle()
	test_outcomes_and_state()
	test_save_and_migration()
	test_generation()
	test_simulations()
	await test_ui()
	await create_timer(0.15).timeout
	print("MATCH3 TEST RESULT: %d assertions, %d failures; %d generated boards; %d games, %d moves" % [checks, failures, generated_boards, simulated_games, simulated_moves])
	quit(1 if failures else 0)

func test_scanner() -> void:
	check(Match.find(cells([0,0,1,2,3,4,4,1,2]),3,3).is_empty(), "two red never match")
	check(Match.indices(Match.find(cells([0,0,0,1,2,3,2,3,4]),3,3)) == [0,1,2], "horizontal three red")
	check(Match.indices(Match.find(cells([1,2,3,1,3,4,1,4,0]),3,3)) == [0,3,6], "vertical three blue")
	check(Match.find(cells([3,0,1,0,3,2,1,2,3]),3,3).is_empty(), "diagonal yellow excluded")
	check(Match.find(cells([0,0,1,0,0,2,1,2,3]),3,3).is_empty(), "irregular four cluster excluded")
	var t: Array = Match.find(cells([0,0,0,1,0,2,3,0,4]),3,3)
	check(t.size() == 1 and t[0].cells == [0,1,2,4,7] and t[0].lines.size() == 2, "T shape merged exactly once")
	var l: Array = Match.find(cells([0,1,2,0,2,3,0,0,0]),3,3)
	check(l.size() == 1 and l[0].cells == [0,3,6,7,8], "L shape merged exactly once")
	check(Powers.created(t[0]) == "prism" and Powers.created(l[0]) == "prism", "T/L creates prism")
	var separate: Array = Match.find(cells([0,0,0,0,0,0,1,2,3]),3,3)
	check(separate.size() == 2, "touching parallel runs stay separate components")
	var four: Array = Match.find(cells([0,0,0,0,1,2,3,4]),4,2)
	check(Powers.created(four[0]) == "rocket_h", "four horizontal creates horizontal rocket")
	var vertical_four: Array = Match.find(cells([0,1,0,2,0,3,0,4]),2,4)
	check(Powers.created(vertical_four[0]) == "rocket_v", "four vertical creates vertical rocket")
	var five: Array = Match.find(cells([2,2,2,2,2,0,1,2,3,4]),5,2)
	check(Powers.created(five[0]) == "color", "five straight creates color bomb")
	check(Powers.origin(t[0], []) == 1 and Powers.origin(four[0], []) == 0, "cascade origin deterministic intersection then row/column")
	var priority: Array = Match.find(cells([0,0,0,0,0,1,2,0,3,4,2,3,0,4,1]),5,3)
	check(Powers.created(priority[0]) == "color", "straight five wins priority over intersection")
	var special_line := cells([0,0,0,1,2,3,2,3,4])
	special_line[1].p = "rocket_h"
	check(Match.find(special_line,3,3).is_empty(), "special not a normal color-match cell")
	print("PASS: line scanner, T/L, deduplication and power priority")

func first_clear(event: Dictionary) -> Dictionary:
	for frame in event.frames:
		if frame.kind == "clear": return frame
	return {}

func invalid_pair(b) -> Array:
	for a in 72:
		for neighbor in Match.neighbors(a,8,9):
			if a < neighbor and b.cells[a].p == "" and b.cells[neighbor].p == "" and not Match.can_swap(b.cells,a,neighbor,8,9): return [a,neighbor]
	return []

func test_swap_and_cascade() -> void:
	var b = fixture()
	var before: Dictionary = b.snapshot()
	check(not b.has_method("tap"), "old tap-blast API completely removed")
	check(not b.activate(0).accepted and b.snapshot() == before, "normal tap cannot clear or spend a move")
	check(not b.swap(0,9).accepted and not b.swap(0,2).accepted and not b.swap(-1,0).accepted and b.snapshot() == before, "diagonal, remote and out-of-range rejected")
	var pair: Array = invalid_pair(b)
	check(not pair.is_empty(), "invalid-swap fixture exists")
	var rejected: Dictionary = b.swap(pair[0],pair[1])
	check(not rejected.accepted and rejected.attempted and b.snapshot() == before, "invalid swap restores all state including RNG")
	check(rejected.frames.size() == 2 and rejected.frames[0].kind == "swap" and rejected.frames[1].kind == "revert", "invalid swap has outward and return animation")
	check(Board.State.REVERTING_SWAP in b.state_trace and b.state == Board.State.READY, "revert state returns READY")
	var event: Dictionary = b.swap(1,9)
	check(event.accepted and b.moves == 99, "successful swap costs exactly one move")
	check(event.cascade_count >= 2 and event.frames.filter(func(f): return f.kind == "clear").size() >= 2, "authored automatic cascade needs no second input")
	check(first_clear(event).removed == [0,1,2], "first clear exactly the matched three")
	check(b.resonance.count == 1, "multiple cascades advance resonance only once")
	check(Match.find(b.cells,8,9).is_empty() and Match.has_move(b.cells,8,9), "cascade ends stable with a legal move")
	var points := 0
	for f in event.frames:
		if f.kind == "clear":
			points += int(f.points)
			check(f.multiplier == mini(5, int(f.combo)), "central cascade multiplier")
	check(b.score == points, "score equals sum of waves without double counting")
	check(not event.cascade_guard, "ordinary cascade never needs safety guard")
	print("PASS: normal tap ignored, swaps, rollback and automatic chains")

func test_powers() -> void:
	for spec in [[3,"rocket_h",2],[5,"color",2],[10,"prism",27]]:
		var b = fixture(spec[0])
		var swap: Array = b.level.tutorial_swap
		var event: Dictionary = b.swap(swap[0],swap[1])
		var first: Dictionary = first_clear(event)
		check(first.after[spec[2]] != null and first.after[spec[2]].p == spec[1], "tutorial creates " + spec[1] + " at swap cell")
		check(first.after[spec[2]].id > 72, "new power gets fresh unique identity")
		var unique: Dictionary = {}
		for i in first.removed: unique[i] = true
		check(unique.size() == first.removed.size(), "intersection normal block counted once")
	var b = fixture(9)
	var moves: int = b.moves
	var event: Dictionary = b.swap(27,28)
	check(event.accepted and b.moves == moves - 1 and first_clear(event).removed.size() > 10, "two special swaps combine without normal match")
	b = fixture()
	b.cells[27].p = "rocket_h"
	b.cells[31].p = "rocket_v"
	event = b.activate(27)
	check(event.accepted and 71 in first_clear(event).removed and b.moves == 99, "direct rocket and caught rocket chain activate once")
	b = fixture()
	b.cells[0].p = "color"
	var before: Dictionary = b.snapshot()
	check(b.activate(0).choose_color and b.snapshot() == before, "color picker before move consumption")
	var expected := 0
	for cell in b.cells:
		if cell.p == "" and cell.c == 3: expected += 1
	event = b.activate(0,3)
	var first: Dictionary = first_clear(event)
	check(first.removed.size() == expected + 1 and b.moves == 99, "color bomb selection clears that color plus bomb")
	b = fixture()
	b.cells[0].p = "color"
	b.cells[1].p = "color"
	event = b.swap(0,1)
	check(first_clear(event).removed.size() == 72, "double color bomb clears whole board")
	b = fixture()
	b.cells[0].p = "prism"
	var picked: int = b.cells[1].c
	event = b.swap(0,1)
	check(event.accepted and b.moves == 99 and b.resonance.count == 0, "special-normal swap is explicit activation exception")
	b = fixture()
	b.cells[0].p = "color"
	picked = b.cells[1].c
	event = b.swap(0,1)
	check(event.accepted, "color-normal swap selects moved normal color")
	for i in first_clear(event).removed:
		var old = first_clear(event).before[i]
		check(old.p != "" or old.c == picked, "color-normal swap never clears an unrelated normal in first wave")
	b = fixture()
	for i in 72: b.cells[i].c = (i % 8 + int(i / 8)) % 5
	for i in [0,2,9]: b.cells[i].c = 0
	b.cells[1].c = 2
	b.refill_stream = [3,3,3]
	event = b.swap(1,9)
	var clears: Array = event.frames.filter(func(f): return f.kind == "clear")
	check(clears.size() >= 2 and clears[1].after[0] != null and clears[1].after[0].p == "rocket_h", "automatic four creates rocket at deterministic smallest cell")
	check(b.resonance.count == 1 and b.moves == 99, "automatic power wave not an extra player move")
	print("PASS: Match-3 power production, placement, activation and combinations")

func safe_refill(b, a: int, destination: int) -> Array:
	var temp: Array = b.cells.duplicate(true)
	var cell = temp[a]
	temp[a] = temp[destination]
	temp[destination] = cell
	for i in Match.indices(Match.find(temp,8,9)): temp[i] = null
	Gravity.compact(temp,8,9,b.direction)
	var result: Array = []
	for line in Gravity.lines(8,9,b.direction):
		for i in line:
			if temp[i] != null: continue
			for color in 5:
				temp[i] = {"c":color,"p":"","id":1000+i}
				if not Match.line_at(temp,i,8,9):
					result.append(color)
					break
	return result

func test_resonance() -> void:
	var b = fixture()
	var baseline: Array = b.cells.duplicate(true)
	for k in 3:
		b.cells = baseline.duplicate(true)
		b.refill_stream = safe_refill(b,1,9)
		var event: Dictionary = b.swap(1,9)
		check(event.resonated == (k == 2), "resonance only third successful same-color swap")
	check(b.resonance.count == 0 and b.moves == 97, "resonance resets after third, one move per transaction")
	b = fixture()
	b.resonance.color = 4
	b.resonance.count = 2
	b.refill_stream = safe_refill(b,1,9)
	b.swap(1,9)
	check(b.resonance.color == 0 and b.resonance.count == 1, "different primary color starts new chain")
	b = fixture()
	b.resonance.color = 0
	b.resonance.count = 2
	var pair: Array = invalid_pair(b)
	b.swap(pair[0],pair[1])
	check(b.resonance.count == 2 and b.resonance.color == 0, "invalid swap cannot change resonance")
	b.energy = 1
	b.change_gravity("left")
	check(b.resonance.count == 2 and b.moves == 100, "gravity not a resonance player move")
	var temp := cells([0,0,0,0,0,0,0,0,0])
	temp[3].p = "prism"
	check(Resonance.extras(temp,4,0,[4,5],3) == [1,7,0,2], "resonance distance/row/column priority and four cap")
	b = fixture()
	for i in 72: b.cells[i].c = (i % 8 + int(i / 8)) % 5
	for key in {25:2,26:0,27:1,28:0,29:3,33:2,34:1,35:0,36:1,37:3}: b.cells[key].c = {25:2,26:0,27:1,28:0,29:3,33:2,34:1,35:0,36:1,37:3}[key]
	check(Match.find(b.cells,8,9).is_empty(), "two-color swap fixture starts stable")
	b.refill_stream = safe_refill(b,27,35)
	var multi: Dictionary = b.swap(27,35)
	check(first_clear(multi).removed.size() == 6 and b.resonance.color == 1 and b.resonance.count == 1, "simultaneous colors use destination color once")
	print("PASS: once-per-player-move resonance and deterministic targeting")

func test_gravity_and_shuffle() -> void:
	for direction in ["down","up","left","right"]:
		var sparse: Array = [null,null,null,null,null,null,null,null,null]
		sparse[0] = {"c":0,"p":"","id":1}
		sparse[4] = {"c":1,"p":"","id":2,"fixed":true}
		sparse[8] = {"c":2,"p":"","id":3}
		Gravity.compact(sparse,3,3,direction)
		check(sparse[4].id == 2, "fixed blocker not moved " + direction)
		for line in Gravity.lines(3,3,direction):
			var gap := false
			for i in line:
				if sparse[i] != null and sparse[i].get("fixed",false): gap = false
				elif sparse[i] == null: gap = true
				else: check(not gap, "gravity compacts within fixed segments " + direction)
		var b = fixture()
		b.direction = direction
		b.refill_stream.clear()
		var event: Dictionary = b.swap(1,9)
		check(event.accepted and b.moves == 99 and Match.find(b.cells,8,9).is_empty(), "Match-3 chain settles in direction " + direction)
		for f in event.frames:
			if f.kind != "refill": continue
			var original_ids: Dictionary = {}
			for cell in f.before:
				if cell != null: original_ids[cell.id] = true
			for line in Gravity.lines(8,9,direction):
				var new_seen := false
				for i in line:
					if not original_ids.has(f.after[i].id): new_seen = true
					else: check(not new_seen, "new blocks enter opposite source edge " + direction)
	var b = fixture()
	b.energy = 2
	var old_moves: int = b.moves
	check(b.change_gravity("left").accepted and b.energy == 1 and b.moves == old_moves, "gravity energy separate from move budget")
	check(not b.change_gravity("left").accepted and not b.change_gravity("bad").accepted and b.energy == 1, "invalid direction no energy charge")
	b.energy = 0
	check(not b.change_gravity("up").accepted, "zero energy blocks gravity")
	b = fixture(1)
	b.energy = 2
	check(not b.change_gravity("up").accepted, "early gravity tutorial lock preserved")
	b = fixture()
	for i in 72: b.cells[i].c = (i % 8 + int(i / 8)) % 5
	check(not Match.has_move(b.cells,8,9) and Match.find(b.cells,8,9).is_empty(), "dead stable Latin fixture")
	var colors: Array = []
	var ids: Array = []
	for cell in b.cells:
		colors.append(cell.c)
		ids.append(cell.id)
	colors.sort(); ids.sort()
	check(b.ensure_move(), "dead board shuffled free")
	check(Match.find(b.cells,8,9).is_empty() and Match.has_move(b.cells,8,9), "shuffle guarantees no ready match and at least one swap")
	var after_colors: Array = []
	var after_ids: Array = []
	for cell in b.cells:
		after_colors.append(cell.c)
		after_ids.append(cell.id)
	after_colors.sort(); after_ids.sort()
	check(after_colors == colors and after_ids == ids and b.moves == 100 and b.score == 0, "shuffle preserves color/ID multiset without move/score")
	b.cells[31].fixed = true
	b.cells[40].p = "prism"
	var fixed_id: int = b.cells[31].id
	var power_id: int = b.cells[40].id
	check(Generator.shuffle(b.cells,b.rng,8,9) and b.cells[31].id == fixed_id and b.cells[40].id == power_id, "shuffle preserves fixed and special positions")
	# Explicit environmental fixture: changing gravity resolves preexisting lines and cascades, no move.
	b = fixture()
	for i in [0,1,2]: b.cells[i].c = 4
	b.energy = 1
	var event: Dictionary = b.change_gravity("left")
	check(event.accepted and event.cascade_count >= 1 and b.moves == 100 and Match.find(b.cells,8,9).is_empty(), "gravity environmental match resolves automatically")
	print("PASS: all gravity directions, barriers, refill edge and free stable shuffles")

func test_outcomes_and_state() -> void:
	var b = fixture()
	b.moves = 1
	b.level.targets = {"total":4}
	var event: Dictionary = b.swap(1,9)
	check(first_clear(event).removed.size() == 3 and b.collected.total >= 6 and b.outcome == "won" and b.moves == 0, "last move waits for second cascade before outcome")
	var old_score: int = b.score
	b.finish_if_needed()
	check(b.score == old_score and not b.swap(0,1).accepted and not b.activate(0).accepted, "bonus once, finished board input locked")
	check(b.state_trace.find(Board.State.CHECKING_OBJECTIVES) > b.state_trace.find(Board.State.CHECKING_CASCADES), "objectives only after cascades")
	b = fixture()
	b.moves = 1
	event = b.swap(1,9)
	check(b.outcome == "lost" and b.moves == 0 and Match.find(b.cells,8,9).is_empty(), "last move settles then loses with no negative budget")
	b = fixture()
	b.hold_presentation()
	var before: Dictionary = b.snapshot()
	check(not b.swap(1,9).accepted and not b.change_gravity("left").accepted and b.snapshot() == before, "presentation lock rejects overlapping transactions")
	b.pause()
	check(b.state == Board.State.PAUSED and not b.swap(1,9).accepted, "paused state blocks swaps")
	b.resume()
	b.release_presentation()
	check(b.state == Board.State.READY and b.swap(1,9).accepted, "resume restores controlled ready state")
	check(Score.move_points(3,3,false,false,false) == 90 and Score.move_points(3,3,false,false,false,9) == 450, "central score and capped combo multiplier")
	check(Score.stars(400,[0,500,1000]) == 1 and Score.stars(500,[0,500,1000]) == 2 and Score.stars(1000,[0,500,1000]) == 3, "star threshold boundaries")
	print("PASS: state machine, locks, last-move cascades and centralized score")

func test_save_and_migration() -> void:
	var path := "user://match3-tests.json"
	clear_save(path)
	var save = Save.new(path)
	var b = Board.new(Catalog.get_level(1))
	b.swap(1,9)
	check(save.save_active(b), "save canonical settled transaction")
	var reloaded = Save.new(path)
	var restored = Board.new(Catalog.get_level(1))
	check(restored.restore(reloaded.data.active) and restored.snapshot() == b.snapshot(), "exact saved board, refill and RNG")
	if b.outcome == "playing":
		var move: Array = best_move(b)
		b.swap(move[0],move[1]); restored.swap(move[0],move[1])
		check(restored.snapshot() == b.snapshot(), "continued save gives identical chain")
	b.level.targets = {"total":1}
	b.finish_if_needed()
	check(save.complete(b) and not save.complete(b), "reward transaction once")
	var best: int = b.score
	b.score = 1
	save.complete(b)
	check(save.data.results["1"].score == best and save.data.unlocked == 2, "replay keeps highest score and unlock")
	var invalid: Dictionary = restored.snapshot()
	invalid.cells[0].id = invalid.cells[1].id
	check(not restored.restore(invalid), "reject duplicate identities")
	for key in ["moves","score","serial","rng","energy","state","rules"]:
		invalid = restored.snapshot(); invalid[key] = "bad"
		check(not restored.restore(invalid), "reject invalid save type " + key)
	var file := FileAccess.open(path,FileAccess.WRITE)
	file.store_string("{broken"); file.close()
	check(Save.new(path).data.unlocked == 2, "corrupt primary recovers backup")
	clear_save(path)
	var legacy := Save.defaults()
	legacy.version = 1
	legacy.unlocked = 7
	legacy.results = {"1":{"score":4321,"stars":3}}
	legacy.rewarded = ["1"]
	legacy.settings.music = false
	legacy.tutorials = ["tap","gravity"]
	legacy.active = {"level_id":6,"old_board":"kept exactly"}
	var original := JSON.stringify(legacy)
	file = FileAccess.open(path,FileAccess.WRITE); file.store_string(original); file.close()
	var migrated = Save.new(path)
	check(migrated.data.version == 2 and migrated.data.unlocked == 7 and migrated.data.settings.music == false, "schema migration preserves progress/settings")
	check(migrated.data.results == legacy.results and migrated.data.rewarded == legacy.rewarded, "schema migration preserves best results and reward identities")
	check(migrated.data.legacy_active == legacy.active and migrated.data.legacy_results == legacy.results, "legacy game and scoring archived without deletion")
	check(FileAccess.get_file_as_string(path + ".v1-archive") == original, "byte-for-byte old save archive")
	var fresh = Board.new(Catalog.get_level(6))
	check(fresh.restore(migrated.data.active) and fresh.moves == fresh.level.moves and fresh.score == 0, "incompatible active level restarts with full match3 budget")
	check(migrated.data.migration_notice and migrated.data.tutorials.is_empty(), "migration explicitly disclosed and drag tutorials reset")
	var loaded_again = Save.new(path)
	check(loaded_again.data == migrated.data, "migration idempotent after restart")
	clear_save(path)
	var future := Save.defaults()
	future.version = 3
	var future_bytes := JSON.stringify(future)
	file = FileAccess.open(path,FileAccess.WRITE); file.store_string(future_bytes); file.close()
	var future_save = Save.new(path)
	check(future_save.read_only and not future_save.flush() and FileAccess.get_file_as_string(path) == future_bytes, "future schema never overwritten")
	clear_save(path)
	print("PASS: atomic saves, rollback protection, v1 archive and v2 migration")

func test_generation() -> void:
	for seed_value in 2000:
		var definition: Dictionary = Catalog.get_level(10)
		var rng = Rng.new(seed_value + 911)
		var layout: Array = []
		for i in 72: layout.append(rng.next_int(5))
		definition.layout = layout
		definition.seed = seed_value + 119
		var b = Board.new(definition)
		check(Match.find(b.cells,8,9).is_empty() and Match.has_move(b.cells,8,9), "generated stable playable board seed %d" % seed_value)
		check(b.score == 0 and b.moves == definition.moves and b.state == Board.State.READY, "generation never auto-clears or charges")
		generated_boards += 1
	print("PASS: 2000 independently generated stable playable boards")

func best_move(b) -> Array:
	return preload("res://tests/move_solver.gd").best_move(b)

func test_simulations() -> void:
	check(Catalog.all().size() >= 10, "all ten levels retained")
	for number in range(1,11):
		var definition: Dictionary = Catalog.get_level(number)
		check(Catalog.validate(definition), "new level data valid %d" % number)
		var wins := 0
		for seed_offset in 100:
			definition.seed = int(Catalog.get_level(number).seed) + seed_offset
			var a = Board.new(definition)
			var b = Board.new(definition)
			check(Match.find(a.cells,8,9).is_empty() and Match.has_move(a.cells,8,9), "level starts stable and playable")
			var actions := 0
			while a.outcome == "playing" and actions <= int(definition.moves):
				if a.energy > 0 and actions % 6 == 0:
					var direction: String = ["left","up","right","down"][int(actions / 6) % 4]
					a.change_gravity(direction); b.change_gravity(direction)
				var move: Array = best_move(a)
				var event: Dictionary = a.swap(move[0],move[1])
				b.swap(move[0],move[1])
				check(event.accepted and not event.cascade_guard, "legal simulator move accepted without guard")
				check(a.snapshot() == b.snapshot(), "identical seed/action cascade outcome")
				check(a.moves >= 0 and a.cells.size() == 72 and Match.find(a.cells,8,9).is_empty() and Match.has_move(a.cells,8,9), "stable no-negative state after every transaction")
				var identities: Dictionary = {}
				for cell in a.cells: identities[cell.id] = true
				check(identities.size() == 72 and a.energy <= 2 and a.energy_blocks < 12, "identity and energy bounds")
				actions += 1
				simulated_moves += 1
			if a.outcome == "won": wins += 1
			simulated_games += 1
		check(wins == 100, "heuristic solvability level %d (%d/100)" % [number,wins])
		print("Match3 Level %02d: %d/100 won" % [number,wins])

func mouse(game, local: Vector2, pressed: bool) -> void:
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = pressed
	event.position = game.board_view.get_global_transform_with_canvas() * local
	event.global_position = event.position
	root.push_input(event,true)

func drag(game, source: int, delta: Vector2, touch: bool = false) -> void:
	var start: Vector2 = game.board_view.cell_position(source) + Vector2(26,26)
	if touch:
		var press := InputEventScreenTouch.new()
		press.index = 0; press.pressed = true
		press.position = game.board_view.get_global_transform_with_canvas() * start
		root.push_input(press,true)
		var motion := InputEventScreenDrag.new()
		motion.index = 0; motion.position = game.board_view.get_global_transform_with_canvas() * (start + delta)
		root.push_input(motion,true)
		press.pressed = false; press.position = motion.position
		root.push_input(press,true)
	else:
		mouse(game,start,true)
		var motion := InputEventMouseMotion.new()
		motion.button_mask = MOUSE_BUTTON_MASK_LEFT
		motion.position = game.board_view.get_global_transform_with_canvas() * (start + delta)
		root.push_input(motion,true)
		mouse(game,start+delta,false)

func wait_animation(game) -> void:
	var deadline := 0
	while game.board_view != null and game.board_view.busy and deadline < 400:
		await process_frame
		deadline += 1
	check(deadline < 400, "animation queue completes")

func test_ui() -> void:
	var game = load("res://scenes/main.tscn").instantiate()
	root.add_child(game)
	await process_frame
	var path := "user://match3-ui-tests.json"
	clear_save(path)
	game.save = Save.new(path)
	game.save.data.settings.music = false
	game.save.data.settings.reduced_motion = true
	game.audio.apply_settings(game.save.data.settings)
	game.show_home(); game.play_latest()
	await process_frame
	var before: Dictionary = game.board.snapshot()
	mouse(game,Vector2(26,26),true); mouse(game,Vector2(26,26),false)
	check(game.board.snapshot() == before and not game.board_view.busy, "actual normal GUI tap does nothing")
	drag(game,1,Vector2(0,60))
	check(game.board.moves == int(game.board.level.moves)-1 and game.board_view.busy, "GUI downward drag makes valid adjacent swap")
	var moves: int = game.board.moves
	drag(game,2,Vector2(60,0))
	game.on_gravity("left")
	check(game.board.moves == moves, "rapid touch and gravity during animation blocked")
	game.show_pause()
	check(game.board.state == Board.State.PAUSED, "pause during animation uses PAUSED state")
	var paused_age: float = game.board_view.age
	await create_timer(0.08).timeout
	check(game.board_view.age == paused_age, "paused cosmetic queue freezes")
	var canonical: Dictionary = game.save.data.active.duplicate(true)
	var restarted = Board.new(Catalog.get_level(1))
	check(restarted.restore(canonical), "background/pause save is a settled canonical board")
	game.close_overlay()
	await wait_animation(game)
	check(game.board.state == game.board.stable_state(), "animation restores terminal or READY state")
	game.start_level(1)
	await process_frame
	before = game.board.snapshot()
	drag(game,1,Vector2(40,40))
	drag(game,1,Vector2(0,-1000))
	drag(game,1,Vector2(0,6))
	check(game.board.snapshot() == before, "diagonal, outside-board and tiny drag cancel free")
	# A long swipe still selects only the immediately adjacent tile.
	drag(game,1,Vector2(0,240),true)
	check(game.board.moves == int(game.board.level.moves)-1, "native screen touch long swipe performs one neighbor swap")
	await wait_animation(game)
	game.start_level(1)
	await process_frame
	var invalid: Array = invalid_pair(game.board)
	before = game.board.snapshot()
	var offset := Vector2(invalid[1] % 8 - invalid[0] % 8, int(invalid[1] / 8)-int(invalid[0] / 8))*60
	drag(game,invalid[0],offset)
	check(game.board.snapshot() == before and game.board_view.busy, "invalid drag starts rollback with unchanged logical save")
	await wait_animation(game)
	for direction in [Vector2(60,0),Vector2(-60,0),Vector2(0,60),Vector2(0,-60)]:
		game.start_level(1)
		await process_frame
		var requested: Array = []
		game.board_view.swap_requested.connect(func(a,b): requested.append([a,b]))
		var source := 27
		var start: Vector2 = game.board_view.cell_position(source) + Vector2(26,26)
		mouse(game,start,true)
		for step in range(1,11):
			var motion := InputEventMouseMotion.new()
			motion.button_mask = MOUSE_BUTTON_MASK_LEFT
			motion.position = game.board_view.get_global_transform_with_canvas() * (start + direction * float(step) / 10)
			root.push_input(motion,true)
		mouse(game,start+direction,false)
		var expected: int = source + (1 if direction.x > 0 else (-1 if direction.x < 0 else (8 if direction.y > 0 else -8)))
		check(requested == [[source,expected]], "slow GUI drag emits exactly one neighbor " + str(direction))
		await wait_animation(game)
	game.start_level(1)
	await process_frame
	before = game.board.snapshot()
	game.show_help()
	check(game.overlay != null and game.paused, "new Match-3 help is functional")
	game.close_overlay()
	game.show_settings(); game.toggle_setting("colorblind"); game.play_latest()
	check(game.board_view.colorblind and game.board.snapshot() == before, "settings and resume preserve exact stable game")
	game.start_level(1)
	await process_frame
	game.board.level.targets = {"total":3}
	game.on_swap(1,9)
	check(game.board.outcome == "won" and game.board_view.busy and game.overlay == null, "logical victory waits for visual cascade before result")
	game.show_pause()
	check(game.board.state == Board.State.PAUSED and game.board_view.busy, "terminal animation can be paused without premature result")
	game.close_overlay()
	await wait_animation(game)
	check(game.overlay != null and not game.board_view.busy and game.board.state == Board.State.LEVEL_COMPLETED, "victory shown only after all visual waves finish")
	for dimensions in [Vector2(360,640),Vector2(360,800),Vector2(768,1024),Vector2(1080,2400)]:
		game.size = dimensions; game.layout_stage()
		check(game.stage.position.x >= -0.01 and game.stage.position.y >= -0.01 and game.stage.size.x*game.stage.scale.x <= dimensions.x+0.01 and game.stage.size.y*game.stage.scale.y <= dimensions.y+0.01, "viewport fit " + str(dimensions))
	game.queue_free()
	await process_frame
	clear_save(path)
	print("PASS: real mouse/touch drags, tap ignored, rollback, pause/resume, help, settings and scaling")
