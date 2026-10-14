extends RefCounted

const SCHEMA := 4
const Economy=preload("res://scripts/core/economy.gd")
var infinite_lives:=false
const Catalog = preload("res://scripts/core/level_catalog.gd")
const Board = preload("res://scripts/core/board.gd")
const Score = preload("res://scripts/core/score.gd")
const Metrics = preload("res://scripts/ui/performance_metrics.gd")
var background_writes := false
var writer: Thread
var pending: Dictionary = {}
var path: String
var data: Dictionary
var last_error: String = ""
var read_only := false

func _init(save_path: String = "user://prizma-save.json") -> void:
	path = save_path
	data = defaults()
	load_save()
	preload("res://scripts/core/adventure_progress.gd").ensure(data)
	Economy.ensure(data)

static func defaults() -> Dictionary:
	return {"version": SCHEMA, "unlocked": 1, "results": {}, "rewarded": [], "world_rewards":[], "cosmetic_rewards":[], "active": {}, "tutorials": [], "settings": {"companion_quiet":false, "music": true, "sfx": true, "haptics": true, "reduced_motion": false, "colorblind": false, "quality": "auto", "shake": true, "reduced_effects": false, "music_volume": 0.65, "sfx_volume": 0.8}, "migration_notice": false, "legacy_results": {}, "legacy_active": {}, "migrated_from": 0}

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
	if parsed is Dictionary and parsed.has("economy") and not Economy.valid(parsed.economy):return false
	if parsed is Dictionary and parsed.has("adventure_progress") and not preload("res://scripts/core/adventure_progress.gd").valid(parsed.adventure_progress):return false
	if not parsed is Dictionary or not parsed.has_all(["version", "unlocked", "results", "rewarded", "active", "tutorials", "settings"]): return false
	if not Board.whole(parsed.version, version, version) or not Board.whole(parsed.unlocked, 1, Catalog.count()): return false
	if not parsed.results is Dictionary or not parsed.active is Dictionary or not parsed.settings is Dictionary or not parsed.rewarded is Array or not parsed.tutorials is Array: return false
	if parsed.has("world_rewards"):
		if not parsed.world_rewards is Array: return false
		var seen: Dictionary={}
		for world in parsed.world_rewards:
			if not Board.whole(world,1,maxi(1,Catalog.world_for(Catalog.count()))) or seen.has(int(world)): return false
			seen[int(world)]=true
	if parsed.has("cosmetic_rewards"):
		if not parsed.cosmetic_rewards is Array:return false
		var cosmetic_seen: Dictionary={}
		for item in parsed.cosmetic_rewards:
			if not item is String or item.is_empty() or item.length()>64 or cosmetic_seen.has(item):return false
			cosmetic_seen[item]=true
	for key in ["music", "sfx", "haptics", "reduced_motion", "colorblind"]:
		if not parsed.settings.has(key) or not parsed.settings[key] is bool: return false
	for key in ["shake", "reduced_effects"]:
		if parsed.settings.has(key) and not parsed.settings[key] is bool: return false
	if parsed.settings.has("quality") and parsed.settings.quality not in ["auto","high","balanced","performance"]: return false
	for key in ["music_volume","sfx_volume"]:
		if parsed.settings.has(key) and (not (parsed.settings[key] is float or parsed.settings[key] is int) or parsed.settings[key] < 0 or parsed.settings[key] > 1): return false
	for key in parsed.results:
		if not str(key).is_valid_int() or int(key) < 1 or int(key) > Catalog.count(): return false
		var result = parsed.results[key]
		if not result is Dictionary or not result.has_all(["score", "stars"]): return false
		if not Board.whole(result.score, 0, 2147483647) or not Board.whole(result.stars, 1, 3): return false
	return true

func valid(parsed: Variant) -> bool:
	if not valid_meta(parsed, SCHEMA): return false
	if not parsed.active.is_empty():
		if not parsed.active.has("level_id") or not Board.whole(parsed.active.level_id, 1, int(parsed.unlocked)): return false
		var definition=parsed.active.get("level_definition",Catalog.get_level(int(parsed.active.level_id)))
		if not definition is Dictionary or not Catalog.validate(definition) or int(definition.id)!=int(parsed.active.level_id) or definition.get("development_only",false):return false
		var board = Board.new(definition)
		if not board.restore(parsed.active): return false
	return true

func load_save() -> bool:
	for candidate in [path, path + ".bak"]:
		if not FileAccess.file_exists(candidate): continue
		var parser := JSON.new()
		var parse_error := parser.parse(FileAccess.get_file_as_string(candidate))
		var parsed = canonical(parser.data) if parse_error == OK else null
		if valid_meta(parsed,2):
			var upgraded: Dictionary=parsed.duplicate(true);upgraded.version=SCHEMA
			if not upgraded.active.is_empty() and not upgraded.active.has("level_definition"):
				var legacy=JSON.parse_string(FileAccess.get_file_as_string("res://data/legacy-gameplay-0.8.json"))
				var n: int=int(upgraded.active.get("level_id",0))
				if n>=1 and n<=legacy.levels.size():upgraded.active.level_definition=canonical(legacy.levels[n-1])
			if valid(upgraded):
				var archive:=path+".v2-before-gameplay2"
				if not FileAccess.file_exists(archive) and DirAccess.copy_absolute(ProjectSettings.globalize_path(candidate),ProjectSettings.globalize_path(archive))!=OK:
					last_error="Önceki kayıt arşivlenemedi; üzerine yazma durduruldu.";read_only=true;return false
				parsed=upgraded
		if valid_meta(parsed,3):
			parsed=parsed.duplicate(true);parsed.version=SCHEMA
		if parsed is Dictionary and parsed.get("economy",{}) is Dictionary and parsed.get("economy",{}).get("version",1)>1:
			last_error="Ekonomi kaydı daha yeni; üzerine yazılmayacak.";read_only=true;return false
		if valid(parsed):
			if not parsed.has("economy") and not FileAccess.file_exists(path+".pre-v014"):
				if DirAccess.copy_absolute(ProjectSettings.globalize_path(candidate),ProjectSettings.globalize_path(path+".pre-v014"))!=OK:last_error="Ekonomi geçiş yedeği yazılamadı.";read_only=true;return false
			data = parsed
			var merged: Dictionary = defaults().settings
			merged.merge(data.settings, true)
			data.settings = merged
			data.unlocked = int(data.unlocked)
			# Previously ten was the catalog cap, even when level ten was complete.
			var caps: Array=[10,30,75]
			for world in preload("res://scripts/core/world_catalog.gd").playable_worlds():caps.append(int(world.end))
			for cap in caps:
				if data.unlocked==cap and data.results.has(str(cap)): data.unlocked=mini(cap+1,Catalog.count())
			if not data.has("world_rewards"): data.world_rewards=[]
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
	var merged: Dictionary = defaults().settings
	merged.merge(result.settings, true)
	result.settings = merged
	result.legacy_results = legacy.results.duplicate(true)
	result.legacy_active = legacy.active.duplicate(true)
	result.migrated_from = 1
	result.migration_notice = true
	if not legacy.active.is_empty() and Board.whole(legacy.active.get("level_id"), 1, int(legacy.unlocked)):
		result.active = Board.new(Catalog.get_level(int(legacy.active.level_id))).snapshot()
	return result

func flush() -> bool:
	if read_only: return false
	if background_writes:
		pending = data.duplicate(true)
		poll_flush()
		return true
	var started := Time.get_ticks_usec()
	var error := write_snapshot(data)
	Metrics.elapsed("save_sync", started)
	last_error = error
	return error == ""

func poll_flush() -> void:
	if writer != null:
		if writer.is_alive(): return
		var result: Dictionary = writer.wait_to_finish()
		last_error = result.error
		Metrics.record("save_worker", result.ms)
		writer = null
	if pending.is_empty(): return
	var payload := pending
	pending = {}
	writer = Thread.new()
	var error := writer.start(func() -> Dictionary:
		var started := Time.get_ticks_usec()
		var problem := write_snapshot(payload)
		return {"error":problem,"ms":float(Time.get_ticks_usec()-started)/1000.0})
	if error != OK:
		writer = null
		last_error = write_snapshot(payload)

func finish_writes() -> void:
	# Lifecycle boundary: guarantee durability before suspending/exiting.
	while writer != null or not pending.is_empty():
		if writer != null:
			var result: Dictionary = writer.wait_to_finish()
			last_error = result.error
			Metrics.record("save_worker", result.ms)
			writer = null
		poll_flush()

func write_snapshot(payload: Dictionary) -> String:
	var temp := path + ".tmp"
	var file := FileAccess.open(temp, FileAccess.WRITE)
	if file == null: return "Kayıt yazılamadı."
	file.store_string(JSON.stringify(payload))
	file.flush()
	file.close()
	var absolute := ProjectSettings.globalize_path(path)
	if FileAccess.file_exists(path):
		var old_parser := JSON.new()
		var parse_error := old_parser.parse(FileAccess.get_file_as_string(path))
		var old_data = old_parser.data if parse_error == OK else null
		if valid(old_data) or valid_meta(old_data,1) or valid_meta(old_data,2) or valid_meta(old_data,3):
			if DirAccess.copy_absolute(absolute, absolute + ".bak") != OK: return "Kayıt yedeği yazılamadı."
	var error := DirAccess.rename_absolute(ProjectSettings.globalize_path(temp), absolute)
	return "" if error == OK else "Kayıt değiştirilemedi: " + str(error)

func save_active(board) -> bool:
	data.active = board.snapshot()
	return flush()

func _complete(board) -> bool:
	Economy.ensure(data)
	if board.outcome != "won": return false
	var key := str(int(board.level.id))
	var old: Dictionary = data.results.get(key, {"score": 0, "stars": 0})
	var stars: int = Score.stars(board.score, board.level.stars)
	data.results[key] = {"score": maxi(int(old.score), board.score), "stars": maxi(int(old.stars), stars)}
	var first: bool = key not in data.rewarded
	if first: data.rewarded.append(key)
	data.unlocked = mini(Catalog.count(), maxi(int(data.unlocked), int(board.level.id) + 1))
	if int(board.level.id)==int(preload("res://scripts/core/world_catalog.gd").get_world(Catalog.world_for(int(board.level.id))).end):
		if not data.has("world_rewards"): data.world_rewards=[]
		var world:=Catalog.world_for(int(board.level.id))
		if world not in data.world_rewards: data.world_rewards.append(world)
		var metadata=preload("res://scripts/core/world_catalog.gd").get_world(world)
		if metadata.has("reward_id"):
			if not data.has("cosmetic_rewards"):data.cosmetic_rewards=[]
			if metadata.reward_id not in data.cosmetic_rewards:data.cosmetic_rewards.append(metadata.reward_id)
	Economy.complete(data,board,stars)
	preload("res://scripts/core/adventure_progress.gd").complete(data,board,first)
	data.active = {}
	return first

func mark_tutorial(key: String) -> void:
	if key not in data.tutorials:
		data.tutorials.append(key)
		flush()

func economy_transaction(operation: Callable) -> Dictionary:
	finish_writes()
	if read_only:return {"ok":false,"message":"Kayıt salt okunur; işlem yapılmadı."}
	var before:=data.duplicate(true)
	var result: Dictionary=operation.call(data)
	if not result.get("ok",false):data=before;return result
	if not Economy.valid(data.economy) or not preload("res://scripts/core/adventure_progress.gd").valid(data.adventure_progress):data=before;return {"ok":false,"message":"Ekonomi verisi doğrulanamadı; işlem geri alındı."}
	var error:=write_snapshot(data)
	if error!="":data=before;last_error=error;return {"ok":false,"message":error}
	last_error="";return result
func complete(board) -> bool:
	if board.outcome!="won":return false
	var result:=economy_transaction(func(_data):return {"ok":true,"first":_complete(board)})
	return result.get("first",false) if result.ok else false
func begin_run(level: int,resume: bool) -> Dictionary:
	return economy_transaction(func(payload):return Economy.begin_run(payload,level,resume,infinite_lives))
func fail_run(board) -> bool:
	var result:=economy_transaction(func(payload):Economy.fail(payload,int(board.level.id),infinite_lives);payload.active={};return {"ok":true})
	return result.ok
func record_action(board,event: Dictionary) -> bool:
	var result:=economy_transaction(func(payload):
		Economy.action(payload,event,board)
		preload("res://scripts/core/adventure_progress.gd").action(payload,event)
		if board.outcome=="won":_complete(board)
		elif board.outcome=="lost":Economy.fail(payload,int(board.level.id),infinite_lives);payload.active={}
		else:payload.active=board.snapshot()
		return {"ok":true})
	return result.ok
