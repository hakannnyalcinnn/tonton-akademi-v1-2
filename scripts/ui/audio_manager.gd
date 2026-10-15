extends Node
var settings: Dictionary = {}
var voices: Array = []
var streams: Dictionary = {}
var cursor := 0
var last_played: Dictionary={}
var music: AudioStreamPlayer

func _ready() -> void:
	for key in ["touch","swap_motion","swap_accept","fall_group","land_group","preview_open","panel_close","locked","booster_select","rocket_impact","double_color","rescue","boss_hit","boss_win","chest","star_award","world_unlock","click","pop","large","resonance","power","gravity","win","lose","invalid","rocket","color","cascade","portal","vine","crate","mirror","match3","match4","match5","prism","combo_power","storm","crystal_wave","combo_big","success2","floor_crack","giant_break","core_break","magnet","shuffle"]:
		streams[key] = load("res://assets/audio/"+key+".wav")
	for kind in ["cargo","shutter","relay","key","gate","balance"]:streams["evolution-"+kind]=load("res://assets/audio/evolution-"+kind+".wav")
	for i in 5:
		var voice := AudioStreamPlayer.new()
		voice.volume_db = -18
		add_child(voice)
		voices.append(voice)
	music = AudioStreamPlayer.new()
	add_child(music)
	music.volume_db = -24
	if ResourceLoader.exists("res://assets/audio/garden.wav"):
		var stream: AudioStreamWAV = load("res://assets/audio/garden.wav")
		stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		stream.loop_end = int(stream.get_length() * stream.mix_rate)
		music.stream = stream

func apply_settings(value: Dictionary) -> void:
	settings = value
	if music: music.volume_db = linear_to_db(maxf(.001,value.get("music_volume",.65))) - 18
	if music:
		if settings.get("music", true):
			if not music.playing: music.play()
		else:
			music.stop()

func play(key: String, intensity: int = 0) -> void:
	if not settings.get("sfx",true) or voices.is_empty() or not streams.has(key): return
	var now:=Time.get_ticks_msec()
	if now-int(last_played.get(key,-1000))<(75 if key in ["fall_group","land_group","touch"] else 35):return
	last_played[key]=now
	var voice: AudioStreamPlayer = voices[cursor%voices.size()]
	cursor += 1
	voice.stop()
	voice.stream = streams[key]
	voice.volume_db = linear_to_db(maxf(.001,settings.get("sfx_volume",.8)))-18+minf(2,intensity*.45)
	voice.pitch_scale = 1+minf(.16,intensity*.04)
	voice.play()

func vibrate(special: bool = false) -> void:
	if settings.get("haptics", true) and OS.get_name() == "Android":
		Input.vibrate_handheld(35 if special else 12, 0.45)

func _exit_tree() -> void:
	# Stop paused WAV playback explicitly before releasing its resource.
	for voice in voices:
		voice.stop()
		voice.stream = null
	if music:
		music.stop()
		music.stream = null

func _notification(what: int) -> void:
	if music == null: return
	if what == NOTIFICATION_APPLICATION_PAUSED:
		music.stop()
		for voice in voices: voice.stop()
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		apply_settings(settings)
