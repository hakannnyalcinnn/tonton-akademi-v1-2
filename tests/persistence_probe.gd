extends SceneTree
const Board = preload("res://scripts/core/board.gd")
const Save = preload("res://scripts/core/save_manager.gd")
const Catalog = preload("res://scripts/core/level_catalog.gd")
const Match = preload("res://scripts/core/match_detector.gd")
const PATH := "user://process-probe.json"

func _initialize() -> void:
	var mode: String = OS.get_cmdline_user_args()[0]
	var save = Save.new(PATH)
	var board = Board.new(Catalog.get_level(10))
	if mode == "write":
		save.data = Save.defaults()
		save.data.unlocked = 10
		board.tap(0)
		board.tap(2)
		save.save_active(board)
		var action := 0
		for i in 72:
			if Match.group(board.cells, i, 8, 9).size() >= 2:
				action = i
				break
		board.tap(action)
		var expected := FileAccess.open(PATH + ".expected", FileAccess.WRITE)
		expected.store_string(JSON.stringify({"action": action, "snapshot": board.snapshot()}))
		expected.close()
		print("PASS: saved active game in process A")
	else:
		var expected = JSON.parse_string(FileAccess.get_file_as_string(PATH + ".expected"))
		if not board.restore(save.data.active):
			printerr("ERROR: cross-process restore failed")
			quit(1)
			return
		board.tap(int(expected.action))
		var expected_board = Board.new(Catalog.get_level(10))
		if not expected_board.restore(expected.snapshot) or board.snapshot() != expected_board.snapshot():
			printerr("ERROR: cross-process continuation differs")
			quit(1)
			return
		for suffix in ["", ".bak", ".tmp", ".expected"]:
			if FileAccess.file_exists(PATH + suffix): DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH + suffix))
		print("PASS: identical continued board/RNG/score in fresh process B")
	quit(0)
