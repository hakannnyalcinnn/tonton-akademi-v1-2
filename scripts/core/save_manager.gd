extends RefCounted

const SCHEMA := 1
const Catalog = preload("res://scripts/core/level_catalog.gd")
const Board = preload("res://scripts/core/board.gd")
const Score = preload("res://scripts/core/score.gd")
var path: String
var data: Dictionary
var last_error: String = ""

func _init(save_path: String = "user://prizma-save.json") -> void:
	path = save_path
	data = defaults()
	load_save()

static func defaults() -> Dictionary:
	return {"version": SCHEMA, "unlocked": 1, "results": {}, "rewarded": [], "active": {}, "tutorials": [], "settings": {"music": true, "sfx": true, "haptics": true, "reduced_motion": false, "colorblind": false}}

func valid(parsed: Variant) -> bool:
	if not parsed is Dictionary or not parsed.has_all(["version", "unlocked", "results", "rewarded", "active", "tutorials", "settings"]): return false
	if not Board.whole(parsed.version, SCHEMA, SCHEMA) or not Board.whole(parsed.unlocked, 1, 10): return false
	if not parsed.results is Dictionary or not parsed.active is Dictionary or not parsed.settings is Dictionary or not parsed.rewarded is Array or not parsed.tutorials is Array: return false
	for key in defaults().settings:
		if not parsed.settings.has(key) or not parsed.settings[key] is bool: return false
	for key in parsed.results:
		if not str(key).is_valid_int() or int(key) < 1 or int(key) > 10: return false
		var result = parsed.results[key]
		if not result is Dictionary or not result.has_all(["score", "stars"]): return false
		if not Board.whole(result.score, 0, 2147483647) or not Board.whole(result.stars, 1, 3): return false
	if not parsed.active.is_empty():
		if not parsed.active.has("level_id") or not Board.whole(parsed.active.level_id, 1, int(parsed.unlocked)): return false
		var board = Board.new(Catalog.get_level(int(parsed.active.level_id)))
		if not board.restore(parsed.active): return false
	return true

func load_save() -> bool:
	for candidate in [path, path + ".bak"]:
		if not FileAccess.file_exists(candidate): continue
		var parser := JSON.new()
		var parse_error := parser.parse(FileAccess.get_file_as_string(candidate))
		var parsed = parser.data if parse_error == OK else null
		if valid(parsed):
			data = parsed
			data.unlocked = int(data.unlocked)
			return true
		last_error = "Kayıt okunamadı; sağlam yedek varsa kullanıldı."
	return false

func flush() -> bool:
	var temp := path + ".tmp"
	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null:
		last_error = "Kayıt yazılamadı: " + str(FileAccess.get_open_error())
		return false
	file.store_string(JSON.stringify(data))
	file.flush()
	file.close()
	var absolute := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(path):
		var old_parser := JSON.new()
		var parse_error := old_parser.parse(FileAccess.get_file_as_string(path))
		var old_data = old_parser.data if parse_error == OK else null
		if valid(old_data):
			var backup_error := DirAccess.copy_absolute(absolute, absolute + ".bak")
			if backup_error != OK:
				last_error = "Kayıt yedeği yazılamadı."
				return false
	var error := DirAccess.rename_absolute(ProjectSettings.globalize_path(temp), absolute)
	if error != OK:
		last_error = "Kayıt değiştirilemedi: " + str(error)
		return false
	last_error = ""
	return true

func save_active(board) -> bool:
	data.active = board.snapshot()
	return flush()

func complete(board) -> bool:
	if board.outcome != "won": return false
	var key := str(int(board.level.id))
	var old: Dictionary = data.results.get(key, {"score": 0, "stars": 0})
	var stars: int = Score.stars(board.score, board.level.stars)
	data.results[key] = {"score": maxi(int(old.score), board.score), "stars": maxi(int(old.stars), stars)}
	var first: bool = key not in data.rewarded
	if first: data.rewarded.append(key)
	data.unlocked = mini(10, maxi(int(data.unlocked), int(board.level.id) + 1))
	data.active = {}
	flush()
	return first

func mark_tutorial(key: String) -> void:
	if key not in data.tutorials:
		data.tutorials.append(key)
		flush()
