extends RefCounted
## Bounded device diagnostics; no per-frame sorting, file writes or console spam.
const CAPACITY := 2048
static var enabled := true
static var samples: Dictionary = {}
static var cursors: Dictionary = {}
static var counters: Dictionary = {}
static var incidents: Array = []
static var slow_frames: Array = []
static func record(key: String, milliseconds: float) -> void:
	if not enabled or not is_finite(milliseconds) or OS.get_thread_caller_id() != OS.get_main_thread_id(): return
	if not samples.has(key):
		samples[key] = PackedFloat32Array()
		cursors[key] = 0
	if samples[key].size() < CAPACITY: samples[key].append(milliseconds)
	else:
		samples[key][cursors[key]] = milliseconds
		cursors[key] = (int(cursors[key]) + 1) % CAPACITY
static func elapsed(key: String, start: int) -> void:
	record(key, float(Time.get_ticks_usec() - start) / 1000.0)
static func incident(message: String, context: Dictionary) -> void:
	var entry := {"message": message,"context": context,"time_ms": Time.get_ticks_msec()}
	if incidents.size() >= 8: incidents.pop_front()
	incidents.append(entry)
	push_warning("PRIZMA_DIAGNOSTIC " + JSON.stringify(entry))
static func report(settings: Dictionary) -> Dictionary:
	var result := {"version":ProjectSettings.get_setting("application/config/version","unknown"),"device_model":OS.get_model_name(),"platform":OS.get_name(),"renderer":RenderingServer.get_video_adapter_name(),"settings":settings.duplicate(),"metrics":{},"counters":counters.duplicate(),"incidents":incidents.duplicate(true),"slow_frames":slow_frames.duplicate(true)}
	var pixel_size := DisplayServer.window_get_size()
	var safe_area := DisplayServer.get_display_safe_area()
	var refresh_rate := DisplayServer.screen_get_refresh_rate()
	result["display"] = {"width":pixel_size.x,"height":pixel_size.y,"refresh_rate_hz":refresh_rate if is_finite(refresh_rate) and refresh_rate>0 else null,"safe_area":[safe_area.position.x,safe_area.position.y,safe_area.size.x,safe_area.size.y]}
	var audio_latency := AudioServer.get_output_latency()*1000
	result["audio_output_latency_ms"] = audio_latency if is_finite(audio_latency) and audio_latency>=0 else null
	for key in samples:
		var values: PackedFloat32Array = samples[key].duplicate()
		values.sort()
		if values.is_empty(): continue
		var total := 0.0
		for value in values: total += value
		result.metrics[key] = {"samples":values.size(),"mean_ms":total/values.size(),"p50_ms":values[int((values.size()-1)*.5)],"p95_ms":values[int((values.size()-1)*.95)],"max_ms":values[values.size()-1]}
	return result
static func reset() -> void:
	samples.clear()
	cursors.clear()
	counters.clear()
	incidents.clear()
	slow_frames.clear()
