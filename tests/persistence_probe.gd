extends SceneTree
const Board = preload("res://scripts/core/board.gd")
const Save = preload("res://scripts/core/save_manager.gd")
const Catalog = preload("res://scripts/core/level_catalog.gd")
const Match = preload("res://scripts/core/match_detector.gd")
const PATH := "user://process-probe.json"

func _initialize() -> void:
	if OS.get_cmdline_user_args().is_empty():
		for phase in ["write","read"]:
			var output: Array=[]
			var code:=OS.execute(OS.get_executable_path(),["--headless","--audio-driver","Dummy","--path",ProjectSettings.globalize_path("res://"),"--script","tests/persistence_probe.gd","--",phase],output,true)
			for line in output:print(line)
			if code!=0:quit(code);return
		quit();return
	var mode: String = OS.get_cmdline_user_args()[0]
	var save = Save.new(PATH)
	var board = Board.new(Catalog.get_level(10))
	if mode == "write":
		save.data = Save.defaults()
		save.data.unlocked = 10
		board.swap(27,35)
		if board.outcome != "playing":
			printerr("ERROR: persistence fixture completed too soon")
			quit(1)
			return
		save.save_active(board)
		var action: Array = preload("res://tests/move_solver.gd").best_move(board)
		board.swap(action[0],action[1])
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
		board.swap(int(expected.action[0]),int(expected.action[1]))
		var expected_board = Board.new(Catalog.get_level(10))
		if not expected_board.restore(expected.snapshot) or board.snapshot() != expected_board.snapshot():
			printerr("ERROR: cross-process continuation differs")
			quit(1)
			return
		for suffix in ["", ".bak", ".tmp", ".expected"]:
			if FileAccess.file_exists(PATH + suffix): DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH + suffix))
		print("PASS: identical continued board/RNG/score in fresh process B")
	quit(0)
