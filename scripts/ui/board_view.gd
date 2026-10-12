extends Control
signal swap_requested(a: int, b: int)
signal special_pressed(index: int)
signal animation_finished
signal wave_started(data: Dictionary)
const Metrics = preload("res://scripts/ui/performance_metrics.gd")
const Backdrop = preload("res://scripts/ui/board_backdrop.gd")
const ATLAS = preload("res://assets/crystals/atlas.svg")
const GLOW = preload("res://assets/crystals/glow.svg")
const Palette = preload("res://scripts/ui/palette.gd")
const CELL := 56.0
const GAP := 4.0
const WIDTH := 8
const HEIGHT := 9
const STRIDE := CELL + GAP
const DRAG_THRESHOLD := CELL * 0.26
var board
var settings: Dictionary = {}
var quality := "balanced"
var textures: Array[AtlasTexture] = []
var particle_positions := PackedVector2Array()
var particle_velocities := PackedVector2Array()
var particle_colors := PackedColorArray()
var particle_ages := PackedFloat32Array()
var particle_cursor := 0
var particle_count := 0
var shard := PackedVector2Array([Vector2.ZERO,Vector2.ZERO,Vector2.ZERO])
var combo_label: Label
var combo_age := 2.0
var score_popups: Array[Label] = []
var score_ages := PackedFloat32Array([2,2,2,2])
var score_origins := PackedVector2Array([Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,Vector2.ZERO])
var popup_cursor := 0
var shake_age := 1.0
var touch_started := 0
var touch_pending := false
var drag_visual_pending := false
var drag_motion_started := 0
var last_frame_usec := 0
var frame_time := 0.0
var adaptive_time := 0.0
var idle_time := 0.0
var busy := false
var reduced_motion := false
var colorblind := false
var age := 0.0
var duration := 0.14
var origins: Dictionary = {}
var previous: Array = []
var displayed: Array = []
var target: Array = []
var queue: Array = []
var current: Dictionary = {}
var hint_index := -1
var hint_target := -1
var selected := -1
var clock := 0.0
var drag_index := -1
var pointer_id := -1
var drag_start := Vector2.ZERO
var drag_offset := Vector2.ZERO
var moved := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(476, 536)
	var backdrop := Backdrop.new()
	backdrop.show_behind_parent = true
	add_child(backdrop)
	for i in 9:
		var texture := AtlasTexture.new()
		texture.atlas = ATLAS
		texture.region = Rect2((i%3)*256,int(i/3)*256,256,256)
		textures.append(texture)
	particle_positions.resize(192)
	particle_velocities.resize(192)
	particle_colors.resize(192)
	particle_ages.resize(192)
	particle_ages.fill(2)
	combo_label = make_effect_label(39)
	combo_label.size = Vector2(476,70)
	combo_label.position = Vector2(0,217)
	combo_label.pivot_offset = Vector2(238,35)
	for i in 4:
		var popup := make_effect_label(26)
		popup.size = Vector2(170,44)
		score_popups.append(popup)
	apply_settings(settings)
	if Metrics.enabled: RenderingServer.viewport_set_measure_render_time(get_viewport().get_viewport_rid(),true)

func make_effect_label(font_size: int) -> Label:
	var value := Label.new()
	value.mouse_filter = Control.MOUSE_FILTER_IGNORE
	value.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value.add_theme_font_size_override("font_size",font_size)
	value.add_theme_color_override("font_color",Palette.GOLD)
	value.add_theme_color_override("font_outline_color",Color("10213b"))
	value.add_theme_constant_override("outline_size",7)
	value.hide()
	add_child(value)
	return value

func apply_settings(value: Dictionary) -> void:
	settings = value
	reduced_motion = value.get("reduced_motion",reduced_motion)
	colorblind = value.get("colorblind",colorblind)
	quality = value.get("quality","auto")
	if quality == "auto": quality = "balanced"
	Metrics.counters["active_quality"] = quality

func particle_budget() -> int:
	if reduced_motion or settings.get("reduced_effects",false): return 24
	return {"high":144,"balanced":96,"performance":36}.get(quality,96)

func start_wave(data: Dictionary) -> void:
	var budget := particle_budget()
	var count := (9 if not data.get("creations",[]).is_empty() else 6)+mini(3,int(data.combo)-1)
	if quality == "performance": count = 3
	if reduced_motion: count = 0
	for index in data.removed:
		if previous[index] == null: continue
		var center := cell_position(index)+Vector2(28,28)
		for k in count:
			var slot := particle_cursor % budget
			particle_cursor += 1
			particle_count = mini(192, maxi(particle_count,slot+1))
			particle_positions[slot] = center
			particle_velocities[slot] = Vector2.from_angle(index*2.41+k*TAU/count)*(65+(k%3)*29)
			particle_colors[slot] = Palette.COLORS[previous[index].c].lightened(.16)
			particle_ages[slot] = 0
	var popup_slot := popup_cursor%4
	popup_cursor += 1
	score_ages[popup_slot] = 0
	score_origins[popup_slot] = (cell_position(data.origin)+Vector2(28,8)-Vector2(85,22)).clamp(Vector2(0,5),Vector2(306,470))
	score_popups[popup_slot].text = "+%d" % int(data.points)
	score_popups[popup_slot].show()
	if int(data.combo)>1:
		combo_label.text = ["KOMBO!","SÜPER KOMBO!","MUHTEŞEM!","EFSANEVİ!"][mini(3,int(data.combo)-2)]
		combo_age = 0
		combo_label.show()
		if settings.get("shake",true) and not reduced_motion and not settings.get("reduced_effects",false): shake_age = 0


func set_board(value) -> void:
	board = value
	busy = false
	displayed = board.cells.duplicate(true)
	target = displayed
	queue.clear()
	current.clear()
	cancel_drag()
	queue_redraw()

func cell_position(index: int) -> Vector2:
	return Vector2(index % WIDTH, int(index / WIDTH)) * STRIDE

func index_at(point: Vector2) -> int:
	if point.x < 0 or point.y < 0: return -1
	var x := int(point.x / STRIDE)
	var y := int(point.y / STRIDE)
	if x >= WIDTH or y >= HEIGHT or fmod(point.x, STRIDE) > CELL or fmod(point.y, STRIDE) > CELL: return -1
	return y * WIDTH + x

func inside(point: Vector2) -> bool:
	return Rect2(Vector2.ZERO, Vector2(476, 536)).has_point(point)

func animate(event: Dictionary) -> void:
	cancel_drag()
	queue = event.get("frames", []).duplicate()
	if queue.is_empty(): return
	board.hold_presentation()
	busy = true
	hint_index = -1
	hint_target = -1
	next_frame()

func next_frame() -> void:
	if queue.is_empty():
		busy = false
		current.clear()
		displayed = board.cells.duplicate(true)
		board.release_presentation()
		animation_finished.emit()
		return
	current = queue.pop_front()
	previous = current.before
	target = current.after
	origins.clear()
	for i in previous.size():
		if previous[i] != null: origins[previous[i].id] = cell_position(i)
	duration = 0.02 if reduced_motion else {"swap": 0.18, "revert": 0.14, "clear": 0.21, "fall": 0.15, "refill": 0.17, "shuffle": 0.26}.get(current.kind, 0.12)
	age = 0
	board.visual_phase(int(current.state))
	if current.kind == "clear":
		start_wave(current)
		wave_started.emit(current)

func _process(delta: float) -> void:
	var now := Time.get_ticks_usec()
	var real_interval := float(now-last_frame_usec)/1000 if last_frame_usec>0 else delta*1000
	last_frame_usec = now
	if real_interval<1000: Metrics.record("frame_interval",real_interval)
	if Metrics.enabled and real_interval>50 and real_interval<1000:
		if Metrics.slow_frames.size()>=12: Metrics.slow_frames.pop_front()
		Metrics.slow_frames.append({"frame_ms":real_interval,"phase":str(current.get("kind","ready")),"busy":busy,"level":int(board.level.id) if board!=null else 0,"time_ms":Time.get_ticks_msec()})
	if real_interval>=1000: Metrics.counters["suspension_gaps"] = int(Metrics.counters.get("suspension_gaps",0))+1
	if Metrics.enabled:
		var viewport_rid := get_viewport().get_viewport_rid()
		var render_cpu := RenderingServer.viewport_get_measured_render_time_cpu(viewport_rid)
		var render_gpu := RenderingServer.viewport_get_measured_render_time_gpu(viewport_rid)
		if render_cpu>0: Metrics.record("render_cpu",render_cpu)
		if render_gpu>0: Metrics.record("render_gpu",render_gpu)
		Metrics.counters["frames"] = int(Metrics.counters.get("frames",0))+1
		if real_interval>33.4 and real_interval<1000: Metrics.counters["frames_over_33ms"] = int(Metrics.counters.get("frames_over_33ms",0))+1
		Metrics.counters["peak_static_memory_bytes"] = maxi(int(Metrics.counters.get("peak_static_memory_bytes",0)),int(Performance.get_monitor(Performance.MEMORY_STATIC)))
		Metrics.counters["peak_live_objects"] = maxi(int(Metrics.counters.get("peak_live_objects",0)),int(Performance.get_monitor(Performance.OBJECT_COUNT)))
	Metrics.record("main_thread_cpu",Performance.get_monitor(Performance.TIME_PROCESS)*1000)
	if board != null and board.state == board.State.PAUSED:
		cancel_drag()
		return
	frame_time = lerpf(frame_time,delta,.04)
	adaptive_time += delta
	if settings.get("quality","auto") == "auto" and adaptive_time>3:
		# Degrade only effects when sustained frame cost exceeds budget; never game logic.
		if frame_time > .025: quality = "performance"
		elif frame_time < .018 and quality == "performance": quality = "balanced"
		Metrics.counters["active_quality"] = quality
		adaptive_time = 0
	if not reduced_motion: clock += delta
	var active := busy or drag_index >= 0
	if busy:
		age += delta
		if age >= duration:
			Metrics.record("animation_"+str(current.kind),age*1000)
			displayed = target
			next_frame()
	for i in particle_count:
		if particle_ages[i] < .46:
			particle_ages[i] += delta
			particle_positions[i] += particle_velocities[i]*delta
			particle_velocities[i].y += 65*delta
			active = true
	for i in 4:
		if score_ages[i]<.68:
			score_ages[i]+=delta
			score_popups[i].position = score_origins[i]+Vector2(0,0 if reduced_motion else -32*minf(1,score_ages[i]/.68))
			score_popups[i].modulate.a = clampf((.68-score_ages[i])/.24,0,1)
			if score_ages[i]>=.68: score_popups[i].hide()
	if combo_age < .78:
		combo_age += delta
		var intro := clampf(combo_age/.16,0,1)
		combo_label.scale = Vector2.ONE * (1.0 if reduced_motion else lerpf(.72,1.0,1-pow(1-intro,3)))
		combo_label.modulate.a = clampf((.78-combo_age)/.22,0,1)
		if combo_age >= .78: combo_label.hide()
	if shake_age < .2:
		shake_age += delta
		active = true
	idle_time += delta
	if active or (hint_index>=0 and idle_time>.033 and not reduced_motion):
		idle_time = 0
		queue_redraw()

func cancel_drag() -> void:
	var was_active := drag_index>=0 or selected>=0
	drag_index = -1
	pointer_id = -1
	drag_offset = Vector2.ZERO
	selected = -1
	moved = false
	if was_active: queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if busy or board == null or not board.available() or drag_index >= 0: return
	var press := false
	var position_local := Vector2.ZERO
	var pointer := -1
	if event is InputEventScreenTouch and event.pressed:
		press = true
		position_local = event.position
		pointer = event.index
	elif event is InputEventMouseButton and event.device != -1 and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		press = true
		position_local = event.position
	if press:
		var index := index_at(position_local)
		if index < 0 or board.cells[index].get("fixed", false): return
		drag_index = index
		selected = index
		pointer_id = pointer
		drag_start = position_local
		drag_offset = Vector2.ZERO
		moved = false
		touch_started = Time.get_ticks_usec()
		touch_pending = true
		drag_visual_pending = false
		Metrics.elapsed("touch_callback",touch_started)
		queue_redraw()
		accept_event()

func _input(event: InputEvent) -> void:
	if drag_index < 0: return
	if busy or not board.available():
		cancel_drag()
		return
	var motion := false
	var released := false
	var point := Vector2.ZERO
	if pointer_id >= 0:
		if event is InputEventScreenDrag and event.index == pointer_id:
			motion = true
			point = event.position
		elif event is InputEventScreenTouch and event.index == pointer_id and not event.pressed:
			released = true
			point = event.position
	else:
		if event is InputEventMouseMotion:
			motion = true
			point = event.position
		elif event is InputEventMouseButton and event.device != -1 and event.button_index == MOUSE_BUTTON_LEFT and not event.pressed:
			released = true
			point = event.position
	if not motion and not released: return
	var local := get_global_transform_with_canvas().affine_inverse() * point
	if motion and not drag_visual_pending:
		drag_motion_started = Time.get_ticks_usec()
		drag_visual_pending = true
	update_drag(local)
	if released: finish_drag(local)
	elif motion and inside(local) and drag_offset.length() >= DRAG_THRESHOLD:
		Metrics.elapsed("gesture_threshold_elapsed",touch_started)
		finish_drag(local)
	get_viewport().set_input_as_handled()

func update_drag(point: Vector2) -> void:
	var delta := point - drag_start
	if delta.length() >= DRAG_THRESHOLD: moved = true
	if absf(delta.x) > absf(delta.y) * 1.2:
		drag_offset = Vector2(clampf(delta.x, -STRIDE * 0.65, STRIDE * 0.65), 0)
	elif absf(delta.y) > absf(delta.x) * 1.2:
		drag_offset = Vector2(0, clampf(delta.y, -STRIDE * 0.65, STRIDE * 0.65))
	else: drag_offset = Vector2.ZERO
	queue_redraw()

func finish_drag(point: Vector2) -> void:
	var source := drag_index
	var delta := point - drag_start
	var was_moved := moved
	cancel_drag()
	if source < 0 or not inside(point): return
	if delta.length() < DRAG_THRESHOLD:
		if not was_moved and board.cells[source].p != "": special_pressed.emit(source)
		return
	var destination := -1
	if absf(delta.x) > absf(delta.y) * 1.2:
		var x := source % WIDTH + (1 if delta.x > 0 else -1)
		if x >= 0 and x < WIDTH: destination = source + (1 if delta.x > 0 else -1)
	elif absf(delta.y) > absf(delta.x) * 1.2:
		var y := int(source / WIDTH) + (1 if delta.y > 0 else -1)
		if y >= 0 and y < HEIGHT: destination = source + (WIDTH if delta.y > 0 else -WIDTH)
	if destination >= 0:
		Metrics.elapsed("touch_to_swap_request",touch_started)
		swap_requested.emit(source, destination)

func _draw() -> void:
	if board == null: return
	var draw_started := Time.get_ticks_usec()
	if touch_pending:
		Metrics.elapsed("touch_to_visual_submit",touch_started)
		touch_pending = false
	if drag_visual_pending:
		Metrics.elapsed("drag_motion_to_visual_submit",drag_motion_started)
		drag_visual_pending = false
	var shake := Vector2.ZERO
	if shake_age < .2: shake = Vector2(sin(shake_age*90),cos(shake_age*73)) * 1.4 * (1-shake_age/.2)
	draw_set_transform(shake)
	var values: Array = target if busy else displayed
	var t := clampf(age / duration, 0, 1) if busy else 1.0
	var ease := 1 - pow(1 - t, 3)
	for i in values.size():
		if values[i] == null: continue
		var cell: Dictionary = values[i]
		var pos := cell_position(i)
		if busy:
			var origin: Vector2 = origins.get(cell.id, pos)
			if not origins.has(cell.id) and current.kind == "refill":
				match current.direction:
					"down": origin.y = -STRIDE * (1 + int(i / WIDTH))
					"up": origin.y = HEIGHT * STRIDE + STRIDE * (HEIGHT - int(i / WIDTH))
					"left": origin.x = WIDTH * STRIDE + STRIDE * (WIDTH - i % WIDTH)
					"right": origin.x = -STRIDE * (1 + i % WIDTH)
			pos = origin.lerp(pos, ease)
			if current.kind in ["fall", "refill"] and t > 0.85: pos.y += sin((t - 0.85) / 0.15 * PI) * 2
		if pos.y < -CELL or pos.y > HEIGHT * STRIDE or pos.x < -CELL or pos.x > WIDTH * STRIDE: continue
		if i == drag_index: continue
		draw_cell(cell, Rect2(pos, Vector2(CELL, CELL)), i == hint_index or i == hint_target or i == selected)
	if drag_index >= 0:
		draw_texture_rect(GLOW,Rect2(cell_position(drag_index)+drag_offset+Vector2(0,6),Vector2(CELL,CELL)),false,Color(0,0,0,.5))
		draw_cell(displayed[drag_index], Rect2(cell_position(drag_index) + drag_offset, Vector2(CELL, CELL)), true)
	if busy and current.kind == "clear":
		for i in current.removed:
			if previous[i] == null: continue
			var center := cell_position(i) + Vector2(28,28)
			var color: Color = Palette.COLORS[previous[i].c]
			if t<.48:
				var block_size := Vector2.ONE*CELL*(1+.12*sin(t/.48*PI))
				draw_cell(previous[i],Rect2(center-block_size/2,block_size),true)
				draw_texture_rect(GLOW,Rect2(center-Vector2(36,36),Vector2(72,72)),false,Color(1,1,1,sin(t/.48*PI)*.7))
			else:
				draw_arc(center,(t-.35)*45,0,TAU,16,Color(color,(1-t)*.8),1.7,true)
		if int(current.combo)>1 and not settings.get("reduced_effects",false):
			draw_texture_rect(GLOW,Rect2(-50,-50,576,636),false,Color(.65,.8,1,sin(t*PI)*.11))
		for creation in current.get("creations",[]):
			var center := cell_position(creation.i)+Vector2(28,28)
			draw_arc(center,25+sin(t*PI)*13,0,TAU,24,Color(Palette.GOLD,1-t*.6),2,true)
			if not settings.get("reduced_effects",false):
				if creation.kind == "color":
					for k in 5:
						var orbit := center+Vector2.from_angle(k*TAU/5+t*2)*42*sin(t*PI)
						draw_texture_rect(GLOW,Rect2(orbit-Vector2(14,14),Vector2(28,28)),false,Color(Palette.COLORS[k],1-t))
				elif creation.kind == "prism":
					for k in 3:
						var axis := Vector2.from_angle(k*TAU/3-PI/2)
						draw_line(center,center+axis*58*sin(t*PI),Color(.8,1,.97,1-t),3,true)
				else:
					var axis := Vector2.RIGHT if creation.kind == "rocket_h" else Vector2.UP
					draw_line(center-axis*52*sin(t*PI),center+axis*52*sin(t*PI),Color(1,.94,.75,(1-t)*.8),2,true)
		var beam_count := 0
		for index in current.get("triggered",[]):
			if beam_count>=6: break
			beam_count+=1
			var center := cell_position(index)+Vector2(28,28)
			var kind: String = previous[index].p
			if kind.begins_with("rocket"):
				var axis := Vector2.RIGHT if kind == "rocket_h" else Vector2.UP
				draw_line(center-axis*285*t,center+axis*285*t,Color(.85,1,1,(1-t)*.75),6*(1-t)+1,true)
			elif kind == "color":
				for k in 5: draw_arc(center,t*(60+k*15),k*TAU/5,(k+1)*TAU/5,10,Color(Palette.COLORS[k],1-t),3,true)
			else:
				draw_arc(center,t*120,0,TAU,28,Color(.8,.65,1,1-t),4,true)
		if current.resonated and not reduced_motion:
			draw_arc(cell_position(current.origin)+Vector2(28,28),t*150,0,TAU,40,Color(.7,1,.94,1-t),3,true)
	for i in particle_count:
		var life := particle_ages[i]/.46
		if life>=1: continue
		var center := particle_positions[i]
		var radius := (1-life)*3.5+.4
		shard[0] = center+Vector2(-radius,radius*.6)
		shard[1] = center+Vector2(radius,0)
		shard[2] = center+Vector2(0,-radius*1.6)
		var color: Color = particle_colors[i]
		color.a = 1-life
		draw_colored_polygon(shard,color)
		draw_line(shard[1],shard[2],Color(1,1,1,(1-life)*.6),.7,true)
	if hint_index >= 0 and not busy and drag_index < 0:
		var center := cell_position(hint_index) + Vector2(37, 37)
		if hint_target >= 0:
			var travel := clampf(fmod(clock, 2.2) - 0.45, 0, 1)
			center = center.lerp(cell_position(hint_target) + Vector2(37, 37), travel)
		var hand := PackedVector2Array([Vector2(0, 0), Vector2(0, 16), Vector2(-4, 13), Vector2(-8, 14), Vector2(-2, 25), Vector2(13, 27), Vector2(17, 21), Vector2(16, 10), Vector2(5, 8), Vector2(5, 0)])
		for k in hand.size(): hand[k] += center
		draw_colored_polygon(hand, Color("fff4dc"))
		draw_polyline(hand, Color("c5ab85"), 1.5, true)

	Metrics.elapsed("board_draw_cpu",draw_started)

func draw_cell(cell: Dictionary, rect: Rect2, highlighted: bool) -> void:
	var center := rect.get_center()
	var pulse := 1.035 if highlighted else 1.0
	if highlighted and not reduced_motion: pulse += sin(clock*3)*.012
	var jewel := Rect2(center-rect.size*pulse/2,rect.size*pulse)
	var color: Color = Palette.COLORS[cell.c]
	if highlighted:
		draw_texture_rect(GLOW,jewel.grow(7),false,Color(color.lightened(.4),.75))
	var texture_index: int = int(cell.c)
	if cell.p != "": texture_index = {"rocket_h":5,"rocket_v":6,"prism":7,"color":8}.get(cell.p,8)
	if colorblind and not highlighted:
		draw_texture_rect(GLOW,jewel.grow(1),false,Color(1,1,1,.24))
	# Same shared texture atlas for every crystal; no per-frame resources or styleboxes.
	draw_texture_rect(textures[texture_index],Rect2(jewel.position+Vector2(0,2),jewel.size),false)
	if cell.get("fixed",false):
		draw_rect(jewel.grow(-3),Color(.08,.13,.2,.5))
		draw_line(jewel.position+Vector2(8,12),jewel.end-Vector2(8,12),Palette.MUTED,3,true)
