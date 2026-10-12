extends RefCounted

const SCHEMA := 2
const Catalog = preload("res://scripts/core/level_catalog.gd")
const Board = preload("res://scripts/core/board.gd")
const Score = preload("res://scripts/core/score.gd")
var path: String
var data: Dictionary
var last_error: String = ""
var read_only := false

func _init(save_path: String = "user://prizma-save.json") -> void:
	path = save_path
	data = defaults()
	load_save()

static func defaults() -> Dictionary:
	return {"version": SCHEMA, "unlocked": 1, "results": {}, "rewarded": [], "active": {}, "tutorials": [], "settings": {"music": true, "sfx": true, "haptics": true, "reduced_motion": false, "colorblind": false}, "migration_notice": false, "legacy_results": {}, "legacy_active": {}, "migrated_from": 0}

static func canonical(value: Variant) -> Variant:
	if value is Dictionary:
		var result: Dictionary = {}
		for key in value: result[key] = canonical(value[key])
		return result
	if value is Array:
		var result: Array = []
		for item in value: result.append(canonical(item))
		return result
	if value is float and Board.whole(value, -2147483648, 2147483647): return int(value)
	return value

func valid_meta(parsed: Variant, version: int) -> bool:
	if not parsed is Dictionary or not parsed.has_all(["version", "unlocked", "results", "rewarded", "active", "tutorials", "settings"]): return false
	if not Board.whole(parsed.version, version, version) or not Board.whole(parsed.unlocked, 1, 10): return false
	if not parsed.results is Dictionary or not parsed.active is Dictionary or not parsed.settings is Dictionary or not parsed.rewarded is Array or not parsed.tutorials is Array: return false
	for key in defaults().settings:
		if not parsed.settings.has(key) or not parsed.settings[key] is bool: return false
	for key in parsed.results:
		if not str(key).is_valid_int() or int(key) < 1 or int(key) > 10: return false
		var result = parsed.results[key]
		if not result is Dictionary or not result.has_all(["score", "stars"]): return false
		if not Board.whole(result.score, 0, 2147483647) or not Board.whole(result.stars, 1, 3): return false
	return true

func valid(parsed: Variant) -> bool:
	if not valid_meta(parsed, SCHEMA): return false
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
		var parsed = canonical(parser.data) if parse_error == OK else null
		if valid(parsed):
			data = parsed
			data.unlocked = int(data.unlocked)
			return true
		if valid_meta(parsed, 1):
			var archive := path + ".v1-archive"
			if not FileAccess.file_exists(archive):
				if DirAccess.copy_absolute(ProjectSettings.globalize_path(candidate), ProjectSettings.globalize_path(archive)) != OK:
					last_error = "Eski kayıt arşivlenemedi; üzerine yazma durduruldu."
					read_only = true
					return false
			data = migrate(parsed)
			return flush()
		if parsed is Dictionary and Board.whole(parsed.get("version", 0), SCHEMA + 1, 2147483647):
			last_error = "Bu kayıt daha yeni bir sürüme ait; üzerine yazılmayacak."
			read_only = true
			return false
		last_error = "Kayıt okunamadı; sağlam yedek varsa kullanıldı."
	return false

func migrate(legacy: Dictionary) -> Dictionary:
	var result := defaults()
	for key in ["unlocked", "results", "rewarded", "settings"]: result[key] = legacy[key].duplicate(true) if legacy[key] is Dictionary or legacy[key] is Array else int(legacy[key])
	result.legacy_results = legacy.results.duplicate(true)
	result.legacy_active = legacy.active.duplicate(true)
	result.migrated_from = 1
	result.migration_notice = true
	if not legacy.active.is_empty() and Board.whole(legacy.active.get("level_id"), 1, int(legacy.unlocked)):
		result.active = Board.new(Catalog.get_level(int(legacy.active.level_id))).snapshot()
	return result

func flush() -> bool:
	if read_only: return false
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
		if valid(old_data) or valid_meta(old_data, 1):
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
