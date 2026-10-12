extends Node
var settings: Dictionary = {}
var voices: Array = []
var cursor := 0
var music: AudioStreamPlayer

func _ready() -> void:
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
	if music:
		if settings.get("music", true):
			if not music.playing: music.play()
		else:
			music.stop()

func play(key: String) -> void:
	if not settings.get("sfx", true) or voices.is_empty(): return
	var path := "res://assets/audio/" + key + ".wav"
	if not ResourceLoader.exists(path): return
	var voice: AudioStreamPlayer = voices[cursor % voices.size()]
	cursor += 1
	voice.stream = load(path)
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
	elif what == NOTIFICATION_APPLICATION_RESUMED:
		apply_settings(settings)
