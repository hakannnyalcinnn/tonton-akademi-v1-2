extends Node
var settings: Dictionary = {}
var voices: Array = []
var streams: Dictionary = {}
var cursor := 0
var music: AudioStreamPlayer

func _ready() -> void:
	for key in ["click","pop","large","resonance","power","gravity","win","lose","invalid","rocket","color","cascade","portal","vine","crate","mirror"]:
		streams[key] = load("res://assets/audio/"+key+".wav")
	for i in 5:
		var voice := AudioStreamPlayer.new()
		voice.volume_db = -12
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
	var voice: AudioStreamPlayer = voices[cursor%voices.size()]
	cursor += 1
	voice.stop()
	voice.stream = streams[key]
	voice.volume_db = linear_to_db(maxf(.001,settings.get("sfx_volume",.8)))-14+minf(2,intensity*.45)
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
