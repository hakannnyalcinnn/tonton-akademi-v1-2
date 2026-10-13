extends Control
signal swap_requested(a: int, b: int)
signal special_pressed(index: int)
signal device_pressed(index: int)
signal animation_finished
signal environment_started(data: Dictionary)
signal wave_started(data: Dictionary)
const CasualSkin=preload("res://scripts/ui/casual_skin.gd")
const DeviceVFX=preload("res://scripts/ui/mechanic4_animation.gd")
const TraitVFX=preload("res://scripts/ui/crystal_trait_animation.gd")
const Traits=preload("res://scripts/mechanics/crystal_traits.gd")
const MechanicVFX = preload("res://scripts/ui/mechanic_animation_controller.gd")
const Mechanics = preload("res://scripts/mechanics/mechanic_manager.gd")
const POWER_TEXTURES := {"rocket_h":5,"rocket_v":6,"prism":7,"color":8}
const Metrics = preload("res://scripts/ui/performance_metrics.gd")
const Backdrop = preload("res://scripts/ui/board_backdrop.gd")
const ATLAS = CasualSkin.GEMS
const GLOW = preload("res://assets/crystals/glow.svg")
const Palette = preload("res://scripts/ui/palette.gd")
const CELL := 56.0
const GAP := 4.0
const WIDTH := 8
const HEIGHT := 9
const STRIDE := CELL + GAP
const DRAG_THRESHOLD := CELL * 0.26
var board
var goal_highlights: Array=[]
var goal_highlight_time:=0.0
var settings: Dictionary = {}
var quality := "balanced"
var textures: Array[AtlasTexture] = []
var mechanic_textures: Array[AtlasTexture] = []
var trait_regions: Array[Rect2] = []
var trait_idle_animation := false
var bomb_origin := -1
var mechanic_font: Font
var layer_cells: Array = []
var layer_rects: Array[Rect2] = []
var layer_draw_count := 0
var lock_labels: Dictionary = {}
var particle_styles := PackedByteArray()
var leaf := PackedVector2Array([Vector2.ZERO,Vector2.ZERO,Vector2.ZERO,Vector2.ZERO])
var particle_positions := PackedVector2Array()
var particle_velocities := PackedVector2Array()
var particle_colors := PackedColorArray()
var particle_ages := PackedFloat32Array()
var particle_cursor := 0
var particle_count := 0
var shard := PackedVector2Array([Vector2.ZERO,Vector2.ZERO,Vector2.ZERO])
var shard_face := PackedVector2Array([Vector2.ZERO,Vector2.ZERO,Vector2.ZERO])
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
		texture.region=CasualSkin.region("gems",i)
		textures.append(texture)
	mechanic_textures = MechanicVFX.textures()
	trait_regions = TraitVFX.regions()
	mechanic_font = ThemeDB.fallback_font
	layer_cells.resize(80)
	layer_rects.resize(80)
	particle_styles.resize(192)
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
	var bold:=SystemFont.new();bold.font_names=PackedStringArray(["DejaVu Sans","Noto Sans","sans-serif"]);bold.font_weight=800
	value.add_theme_font_override("font",bold)
	value.add_theme_font_size_override("font_size",font_size)
	value.add_theme_color_override("font_color",Color("ffdd48"))
	value.add_theme_color_override("font_shadow_color",Color("75468c"))
	value.add_theme_constant_override("shadow_offset_y",3)
	value.add_theme_color_override("font_outline_color",Color("aa3b86"))
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
	var count := (14 if data.removed.size()>=5 or not data.get("creations",[]).is_empty() else 10)+mini(4,int(data.combo)-1)
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
			particle_velocities[slot] = Vector2.from_angle(index*2.41+k*TAU/count)*(90+(k%4)*28)
			particle_colors[slot] = Palette.COLORS[k%5 if Traits.bridge(previous[index]) else int(data.get("colors",{}).get(index,previous[index].c))].lightened(.16)
			particle_ages[slot] = -.075-.008*(index%4) if not reduced_motion else 0
			particle_styles[slot] = 0
	for effect in data.get("mechanics",[]):
		var center := cell_position(effect.index)+Vector2(28,28)
		for k in (mini(count+3,10) if effect.opened else 3):
			if reduced_motion: break
			var slot := particle_cursor%budget
			particle_cursor += 1
			particle_count = mini(192,maxi(particle_count,slot+1))
			particle_positions[slot]=center
			particle_velocities[slot]=Vector2.from_angle(effect.index+k*TAU/8)*(55+k%3*26)
			particle_colors[slot]=MechanicVFX.color(effect.kind)
			particle_ages[slot]=0
			particle_styles[slot]=1 if effect.kind=="seed" else (2 if effect.kind in ["stone","crate"] else 0)
		if effect.kind=="stone" and effect.opened and settings.get("shake",true) and not reduced_motion: shake_age=0
	var popup_slot := popup_cursor%4
	popup_cursor += 1
	score_ages[popup_slot] = 0
	score_origins[popup_slot] = (cell_position(data.origin)+Vector2(28,8)-Vector2(85,22)).clamp(Vector2(0,5),Vector2(306,470))
	score_popups[popup_slot].text = "+%d" % int(data.points)
	score_popups[popup_slot].show()
	if int(data.combo)>1:
		combo_label.text = ["KOMBO!","SÜPER!","MUHTEŞEM!","EFSANEVİ!"][mini(3,int(data.combo)-2)]
		combo_label.add_theme_font_size_override("font_size",39)
		combo_label.add_theme_color_override("font_color",Palette.COLORS[mini(4,int(data.combo)-1)].lightened(.5))
		combo_age = 0
		combo_label.show()
		spawn_stars(Vector2(238,252),mini(10,4+int(data.combo)))
	if (data.special or data.get("combo_kind","")!="") and settings.get("shake",true) and not reduced_motion:shake_age=0


func start_environment(data: Dictionary) -> void:
	if reduced_motion:return
	var positions: Array=[]
	if data.kind=="portal":
		for transfer in data.get("transfers",[]):positions.append(transfer.from);positions.append(transfer.to)
	else:
		for growth in data.get("growth",[]):positions.append(growth.index)
		for i in data.get("broken",[]):positions.append(i)
		for e in data.get("seals",[]):positions.append(e.index)
		for e in data.get("fountains",[]):
			for c in e.painted:positions.append(c.index)
	for index in positions:
		for k in (3 if quality=="performance" else 6):
			var slot:=particle_cursor%particle_budget();particle_cursor+=1
			particle_count=mini(192,maxi(particle_count,slot+1))
			particle_positions[slot]=cell_position(index)+Vector2(28,28)
			particle_velocities[slot]=Vector2.from_angle(k*TAU/6)*(40+k*7)
			particle_colors[slot]=Color("a6ecff") if data.kind=="portal" else Color("a8e986")
			particle_ages[slot]=0;particle_styles[slot]=0 if data.kind=="portal" else 1

func set_board(value) -> void:
	lock_labels.clear()
	board = value
	if get_child_count()>0:
		get_child(0).world=int(board.level.get("world",1));get_child(0).queue_redraw()
	busy = false
	displayed = board.cells.duplicate(true)
	trait_idle_animation=has_trait_animation(displayed)
	target = displayed
	queue.clear()
	current={}
	cancel_drag()
	queue_redraw()

func highlight_goal(key: String) -> void:
	goal_highlights.clear()
	for i in displayed.size():
		if preload("res://scripts/ui/goal_registry.gd").relevant(key,displayed[i]):goal_highlights.append(i)
	if key=="conveyors":
		for rail in board.level.get("conveyors",[]):goal_highlights.append_array(rail.cells)
	if key=="portals":
		for pair in board.level.get("portals",[]):goal_highlights.append(pair.entry);goal_highlights.append(pair.exit)
	goal_highlight_time=1.0;queue_redraw()

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

var creation_indices: Dictionary={}

func next_frame() -> void:
	if queue.is_empty():
		busy = false
		current={}
		displayed = board.cells.duplicate(true)
		board.release_presentation()
		animation_finished.emit()
		return
	current = queue.pop_front()
	creation_indices.clear()
	for c in current.get("creations",[]):creation_indices[int(c.i)]=true
	previous = current.before
	target = current.after
	trait_idle_animation=has_trait_animation(target)
	origins.clear()
	for i in previous.size():
		if previous[i] != null: origins[previous[i].id] = cell_position(i)
	duration = 0.02 if reduced_motion else {"swap": 0.18, "revert": 0.14, "clear": 0.21, "fall": 0.15, "refill": 0.17, "shuffle": 0.26,"trait":0.16,"portal":0.26,"vine":0.19,"paint":.22,"bubble":.14,"conveyor":.20,"seal":.20,"storm":.24,"crystal_wave":.22}.get(current.kind, 0.12)
	bomb_origin=-1
	if current.kind=="clear":
		for index in current.get("triggered",[]):
			if previous[index]!=null and previous[index].p=="color":bomb_origin=index;break
		if bomb_origin>=0 and not reduced_motion:duration=.30
	if current.get("combo_kind","")!="" and not reduced_motion:duration=.30
	age = 0
	board.visual_phase(int(current.state))
	if current.kind in ["portal","vine","paint","bubble","conveyor","seal","trait","storm","crystal_wave"]:
		environment_started.emit(current)
		start_environment(current)
		if current.kind in ["storm","crystal_wave"]:
			combo_label.text="PRİZMA FIRTINASI" if current.kind=="storm" else "KRİSTAL DALGASI"
			combo_label.add_theme_font_size_override("font_size",29 if current.kind=="storm" else 32);combo_label.add_theme_color_override("font_color",Color("b2f9ff") if current.kind=="storm" else Color("ffdc85"));combo_age=0;combo_label.show();spawn_stars(Vector2(238,252),8)
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
	if goal_highlight_time>0:
		goal_highlight_time=maxf(0,goal_highlight_time-delta);active=true
	if busy:
		age += delta
		if age >= duration:
			Metrics.record("animation_"+str(current.kind),age*1000)
			displayed = target
			next_frame()
	for i in particle_count:
		if particle_ages[i] < .46:
			particle_ages[i] += delta
			if particle_ages[i]>=0:
				particle_positions[i] += particle_velocities[i]*delta
				particle_velocities[i].y += 85*delta
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
		combo_label.scale = Vector2.ONE * (1.0 if reduced_motion else (.55+ .55*sin(intro*PI*.5)+.08*sin(intro*PI)))
		combo_label.modulate.a = clampf((.78-combo_age)/.22,0,1)
		if combo_age >= .78: combo_label.hide()
		active=true
	if shake_age < .2:
		shake_age += delta
		active = true
	idle_time += delta
	if active or (hint_index>=0 and idle_time>.033 and not reduced_motion) or (trait_idle_animation and quality!="performance" and idle_time>.05 and not reduced_motion):
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
		if index<0:return
		if board.cells[index].get("obstacle",{}).get("kind","")=="seal":device_pressed.emit(index);return
		if board.cells[index].get("fixed",false):return
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
	layer_draw_count=0
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
	var portal_pairs: Array=board.level.get("portals",[])
	for pair_index in portal_pairs.size():
		var pair: Dictionary=portal_pairs[pair_index]
		var pair_color: Color=Palette.COLORS[(pair_index+1)%5].lightened(.3)
		for endpoint in ["entry","exit"]:
			var portal_rect:=Rect2(cell_position(int(pair[endpoint]))-Vector2(2,2),Vector2(60,60))
			draw_texture_rect_region(DeviceVFX.ATLAS,portal_rect,DeviceVFX.region(0 if endpoint=="entry" else 1),Color(1,1,1,.8))
			if not reduced_motion and quality!="performance":
				var center:=portal_rect.get_center()
				draw_arc(center,24,clock*.7,clock*.7+PI*.8,12,Color(pair_color,.5),1.4,true)
	for rail in board.level.get("conveyors",[]):
		for k in rail.cells.size():
			var i: int=rail.cells[k]
			var j: int=rail.cells[(k+1)%rail.cells.size()] if rail.loop or k<rail.cells.size()-1 else rail.cells[k-1]
			var axis:=cell_position(j)-cell_position(i)
			var center:=cell_position(i)+Vector2(28,28)
			draw_set_transform(center,axis.angle())
			draw_texture_rect_region(CasualSkin.ADVANCED,Rect2(-28,-28,56,56),CasualSkin.region("advanced",3))
			draw_set_transform(shake)
	for i in values.size():
		if values[i] == null: continue
		var cell: Dictionary = values[i]
		var pos := cell_position(i)
		if busy and current.kind=="clear" and creation_indices.has(i):
			if t<.48:continue
		if busy:
			var origin: Vector2 = origins.get(cell.id, pos)
			if not origins.has(cell.id) and current.kind == "refill":
				match current.direction:
					"down": origin.y = -STRIDE * (1 + int(i / WIDTH))
					"up": origin.y = HEIGHT * STRIDE + STRIDE * (HEIGHT - int(i / WIDTH))
					"left": origin.x = WIDTH * STRIDE + STRIDE * (WIDTH - i % WIDTH)
					"right": origin.x = -STRIDE * (1 + i % WIDTH)
			if (current.kind=="portal" or (current.kind=="storm" and origin.distance_to(pos)>STRIDE*1.5)) and origin!=pos:
				var extent:=Vector2.ONE*CELL*(absf(2*t-1)*.85+.15)
				var anchor:=origin if t<.5 else pos
				draw_cell(cell,Rect2(anchor+Vector2(28,28)-extent/2,extent),true)
				continue
			pos = origin.lerp(pos, ease)
			if current.kind in ["fall", "refill"] and t > 0.85: pos.y += sin((t - 0.85) / 0.15 * PI) * 2
		if pos.y < -CELL or pos.y > HEIGHT * STRIDE or pos.x < -CELL or pos.x > WIDTH * STRIDE: continue
		if i == drag_index: continue
		draw_cell(cell, Rect2(pos, Vector2(CELL, CELL)), i == hint_index or i == hint_target or i == selected)
	if goal_highlight_time>0:
		for i in goal_highlights:
			draw_style_box(goal_highlight_style(),Rect2(cell_position(i)-Vector2(1,1),Vector2(58,58)))
	if drag_index >= 0:
		draw_texture_rect(GLOW,Rect2(cell_position(drag_index)+drag_offset+Vector2(0,6),Vector2(CELL,CELL)),false,Color(0,0,0,.5))
		draw_cell(displayed[drag_index], Rect2(cell_position(drag_index) + drag_offset, Vector2(CELL, CELL)), true)
	if busy and current.kind in ["storm","crystal_wave"]:
		var center:=Vector2(238,268) if current.kind=="storm" else cell_position(int(current.origin))+Vector2(28,28)
		var color: Color=Color("b5f4ff") if current.kind=="storm" else Palette.COLORS[int(current.color)].lightened(.4)
		draw_arc(center,20+t*270,0,TAU,40,Color(color,(1-t)*.7),3.5,true)
		draw_texture_rect(GLOW,Rect2(center-Vector2(140,140),Vector2(280,280)),false,Color(color,sin(t*PI)*.2))
		if current.kind=="storm":
			var axis: Vector2={"down":Vector2.DOWN,"up":Vector2.UP,"left":Vector2.LEFT,"right":Vector2.RIGHT}[current.direction]
			var tip:=center+axis*(55+25*t);var side:=Vector2(-axis.y,axis.x)
			draw_line(center-axis*35,tip,Color(1,1,1,1-t),4,true)
			draw_polyline(PackedVector2Array([tip-axis*17+side*14,tip,tip-axis*17-side*14]),Color(1,1,1,1-t),4,true)
		else:
			for c in current.get("painted",[]):draw_texture_rect(GLOW,Rect2(cell_position(c.index)-Vector2(7,7),Vector2(70,70)),false,Color(color,sin(t*PI)*.75))
	if busy and current.kind=="paint":
		for e in current.get("fountains",[]):
			for gem in e.painted:
				var source:=cell_position(e.source)+Vector2(28,28);var destination:=cell_position(gem.index)+Vector2(28,28)
				var drop:=source.lerp(destination,ease)+Vector2(0,-35*sin(t*PI))
				draw_circle(drop,4,Palette.COLORS[e.color].lightened(.35));draw_texture_rect(GLOW,Rect2(destination-Vector2(30,30),Vector2(60,60)),false,Color(Palette.COLORS[e.color],sin(t*PI)*.65))
	if busy and current.kind=="bubble":
		for i in current.get("broken",[]):draw_arc(cell_position(i)+Vector2(28,28),23+t*12,0,TAU,20,Color(.7,.92,1,1-t),2,true)
	if busy and current.kind=="seal":
		for e in current.get("seals",[]):
			var center:=cell_position(e.index)+Vector2(28,28)
			draw_texture_rect(GLOW,Rect2(center-Vector2(35,35),Vector2(70,70)),false,Color(Color("ffe693") if e.opened or e.correct else Color("ee91b3"),sin(t*PI)*.65))
			if e.opened:draw_texture_rect_region(CasualSkin.ADVANCED,Rect2(center-Vector2(28,28),Vector2(56,56)),CasualSkin.region("advanced",6),Color(1,1,1,1-t))
	if busy and current.kind == "clear":
		for i in current.removed:
			if previous[i] == null: continue
			var center := cell_position(i) + Vector2(28,28)
			var color: Color = Palette.COLORS[int(current.get("colors",{}).get(i,previous[i].c))]
			var phase:=t
			if bomb_origin>=0:
				phase=clampf((t-float(i%6)*.045)/.775,0,1)
				if not settings.get("reduced_effects",false):draw_line(cell_position(bomb_origin)+Vector2(28,28),center,Color(color,sin(t*PI)*.55),1.8,true)
			if phase<.32:
				var block_size:=Vector2.ONE*CELL*(1+.22*sin(phase/.32*PI*.5))
				draw_cell(previous[i],Rect2(center-block_size/2,block_size),true,int(current.get("colors",{}).get(i,previous[i].c)))
				draw_texture_rect(GLOW,Rect2(center-Vector2(38,38),Vector2(76,76)),false,Color(1,1,1,sin(phase/.32*PI)*.92))
			elif phase<.72 and current.removed.size()<=12 and quality!="performance" and not reduced_motion and not previous[i].has("trait") and previous[i].p=="":
				draw_shattered_crystal(previous[i],center,(phase-.32)/.4,shake)
			if phase>.22:
				draw_arc(center,12+(phase-.22)*39,0,TAU,16,Color(color,(1-phase)*.85),2.1,true)
				if current.removed.size()>=4 and not settings.get("reduced_effects",false):
					draw_line(center-Vector2(36,0)*phase,center+Vector2(36,0)*phase,Color(color.lightened(.5),(1-phase)*.7),1.3,true)
		if int(current.combo)>1 and not settings.get("reduced_effects",false):
			draw_texture_rect(GLOW,Rect2(-50,-50,576,636),false,Color(.65,.8,1,sin(t*PI)*.11))
		draw_combo_effect(current,t)
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
	if busy and current.kind=="trait":
		for effect in current.get("traits",[]):
			var center:=cell_position(effect.index)+Vector2(28,28)
			if effect.changed:
				var old: Dictionary=previous[effect.index]
				draw_texture_rect_region(TraitVFX.ATLAS,Rect2(center-Vector2(28,28),Vector2(CELL,CELL)),trait_regions[TraitVFX.index(old)],Color(1,1,1,1-ease))
			draw_texture_rect(GLOW,Rect2(center-Vector2(34,34),Vector2(68,68)),false,Color(Palette.COLORS[int(effect.to)],sin(t*PI)*.7))
	draw_mechanic_layers()
	for rail in board.level.get("conveyors",[]):
		for k in rail.cells.size():
			if not rail.loop and k==rail.cells.size()-1:continue
			var i: int=rail.cells[k];var j: int=rail.cells[(k+1)%rail.cells.size()]
			var axis: Vector2=(cell_position(j)-cell_position(i)).normalized();var side:=Vector2(-axis.y,axis.x)
			var point:=cell_position(i)+Vector2(28,28)+axis*23
			draw_polyline(PackedVector2Array([point-axis*5-side*4,point,point-axis*5+side*4]),Color("187b82"),4,true)
			draw_polyline(PackedVector2Array([point-axis*5-side*4,point,point-axis*5+side*4]),Color("affffe"),1.6,true)

	if busy and current.kind=="vine":
		for growth in current.get("growth",[]):
			var center:=cell_position(growth.index)+Vector2(28,28)
			draw_texture_rect(GLOW,Rect2(center-Vector2(35,35),Vector2(70,70)),false,Color(.5,1,.6,sin(t*PI)*.6))
	if busy and current.kind=="clear":
		for beam in current.get("beams",[]):
			var prior:=cell_position(int(beam.source))+Vector2(28,28)
			var count:=mini(beam.path.size(),int(ceil(t*beam.path.size()*2)))
			for k in count:
				var center:=cell_position(int(beam.path[k]))+Vector2(28,28)
				draw_line(prior,center,Color(.7,.85,1,1-t),4,true)
				draw_line(prior,center,Color(1,1,1,1-t),1.3,true)
				prior=center
	if busy and current.kind=="clear":
		for effect in current.get("mechanics",[]):
			var center := cell_position(effect.index)+Vector2(28,28)
			var color := MechanicVFX.color(effect.kind)
			if effect.opened and effect.kind=="seed":
				var extent := Vector2.ONE*CELL*(.65+.45*ease)
				draw_texture_rect(mechanic_textures[2],Rect2(center-extent/2,extent),false,Color(1,1,1,1-t*.65))
			elif effect.opened and effect.kind=="stone" and t<.45:
				draw_texture_rect(mechanic_textures[MechanicVFX.index(effect.kind,effect.before)],Rect2(center-Vector2(28,28),Vector2(CELL,CELL)),false,Color(1,1,1,1-t/.45))
			draw_texture_rect(GLOW,Rect2(center-Vector2(35,35),Vector2(70,70)),false,Color(color,sin(t*PI)*.75))
			if effect.opened:
				draw_arc(center,18+t*(80 if effect.kind=="crate" else 26),0,TAU,18,Color(color,1-t),2,true)
				if effect.kind=="crate":
					var lid:=DeviceVFX.region(DeviceVFX.index("crate",effect.before));lid.size.y*=.5
					draw_texture_rect_region(DeviceVFX.ATLAS,Rect2(center-Vector2(28,28+t*20),Vector2(56,28)),lid,Color(1,1,1,1-t))
					draw_texture_rect(GLOW,Rect2(center-Vector2(65,65),Vector2(130,130)),false,Color(color,sin(t*PI)*.22))
	for i in particle_count:
		var life := particle_ages[i]/.46
		if life<0 or life>=1: continue
		var center := particle_positions[i]
		var radius := (1-life)*3.5+.4
		shard[0] = center+Vector2(-radius,radius*.6)
		shard[1] = center+Vector2(radius,0)
		shard[2] = center+Vector2(0,-radius*1.6)
		var color: Color = particle_colors[i]
		color.a = 1-life
		if particle_styles[i] in [1,3]:
			var source:=CasualSkin.region("mechanics",13 if particle_styles[i]==3 else 14)
			draw_texture_rect_region(CasualSkin.MECHANICS,CasualSkin.fit(Rect2(center-Vector2(radius*2,radius*2),Vector2(radius*4,radius*4)),source),source,color)
		else:
			# One faceted crystal fragment, rather than repeating a multi-shard sprite bundle.
			draw_colored_polygon(shard,color)
			shard_face[0]=shard[1];shard_face[1]=shard[2];shard_face[2]=center+Vector2(0,radius*.35)
			draw_colored_polygon(shard_face,Color(color.lightened(.4),color.a))

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

func draw_cell(cell: Dictionary, rect: Rect2, highlighted: bool, match_color: int = -1) -> void:
	var center := rect.get_center()
	var pulse := 1.035 if highlighted else 1.0
	if highlighted and not reduced_motion: pulse += sin(clock*3)*.012
	var jewel := Rect2(center-rect.size*pulse/2,rect.size*pulse)
	var color: Color = Palette.COLORS[match_color if match_color>=0 else int(cell.c)]
	if highlighted:
		draw_texture_rect(GLOW,jewel.grow(7),false,Color(color.lightened(.4),.75))
	var texture_index: int = int(cell.c)
	if cell.p != "": texture_index = POWER_TEXTURES.get(cell.p,8)
	if colorblind and not highlighted:
		draw_texture_rect(GLOW,jewel.grow(1),false,Color(1,1,1,.24))
	# Same shared texture atlas for every crystal; no per-frame resources or styleboxes.
	if cell.has("trait"):
		draw_texture_rect_region(TraitVFX.ATLAS,CasualSkin.fit(jewel,trait_regions[TraitVFX.index(cell)]),trait_regions[TraitVFX.index(cell)],Palette.COLORS[match_color].lightened(.45) if match_color>=0 and Traits.bridge(cell) else Color.WHITE)
		if cell.trait.kind=="chameleon":
			var ready: bool=int(cell.trait.count)==int(cell.trait.period)-1
			draw_arc(center,24,-PI/2,-PI/2+TAU*float(cell.trait.count+1)/float(cell.trait.period+1),18,Color(Palette.GOLD,.8 if ready else .38),1.2,true)
			if ready: draw_texture_rect(GLOW,jewel.grow(3),false,Color(Palette.GOLD,.14 if reduced_motion else .12+.09*sin(clock*4)))
		elif cell.trait.kind=="bridge" and quality!="performance" and not settings.get("reduced_effects",false):
			for k in 2:
				var glint:=center+Vector2.from_angle(clock*.4+k*PI)*18
				draw_texture_rect(GLOW,Rect2(glint-Vector2(7,7),Vector2(14,14)),false,Color(Palette.COLORS[k*2],.5))
	elif not cell.has("obstacle"):
		draw_texture_rect_region(ATLAS,CasualSkin.fit(jewel,textures[texture_index].region),textures[texture_index].region)
	if cell.has("motion"):
		draw_texture_rect_region(CasualSkin.ADVANCED,jewel.grow(1),CasualSkin.region("advanced",2))
	var layer := Mechanics.layer(cell)
	if layer!="":
		layer_cells[layer_draw_count]=cell
		layer_rects[layer_draw_count]=jewel
		layer_draw_count+=1
	elif cell.get("fixed",false):
		draw_rect(jewel.grow(-3),Color(.08,.13,.2,.5))
		draw_line(jewel.position+Vector2(8,12),jewel.end-Vector2(8,12),Palette.MUTED,3,true)

func draw_mechanic_layers() -> void:
	# Keep crystal atlas submissions together, then armor/obstacles and text.
	# Fixed arrays avoid per-frame draw-command dictionaries or scene nodes.
	for i in layer_draw_count:
		var jewel: Rect2=layer_rects[i]
		var center:=jewel.get_center()
		var cell: Dictionary=layer_cells[i]
		var m: Dictionary=cell[Mechanics.layer(cell)]
		if m.kind in ["vine","crate","mirror"]:
			var extent:=jewel;var opacity:=1.0
			if m.kind=="vine" and busy and current.kind=="vine":
				for growth in current.get("growth",[]):
					if int(growth.index)==index_at(center):
						var phase:=clampf(age/duration,0,1)
						var grown_size:=jewel.size*(.25+.75*smoothstep(0,1,phase))
						extent=Rect2(center-grown_size/2,grown_size);opacity=.15+.85*phase
			draw_texture_rect_region(DeviceVFX.ATLAS,CasualSkin.fit(extent,DeviceVFX.region(DeviceVFX.index(m.kind,m))),DeviceVFX.region(DeviceVFX.index(m.kind,m)),Color(1,1,1,opacity))
		elif m.kind in ["fountain","seal"]:
			draw_texture_rect_region(CasualSkin.ADVANCED,CasualSkin.fit(jewel,CasualSkin.region("advanced",5 if m.kind=="seal" else (0 if m.color==0 else 1))),CasualSkin.region("advanced",5 if m.kind=="seal" else (0 if m.color==0 else 1)))
			if m.kind=="fountain":draw_texture_rect_region(ATLAS,Rect2(center+Vector2(-9,6),Vector2(18,18)),textures[int(m.color)].region)
			else:
				for k in m.sequence.size():
					var pos:=center+Vector2((k-(m.sequence.size()-1)*.5)*12,17)
					if k<int(m.step):draw_circle(pos,7,Color("87e9a0"))
					draw_texture_rect_region(ATLAS,Rect2(pos-Vector2(5,5),Vector2(10,10)),textures[int(m.sequence[k])].region)
		elif m.kind=="pin":
			draw_texture_rect_region(TraitVFX.ATLAS,CasualSkin.fit(jewel,trait_regions[16 if m.hp==2 else 17]),trait_regions[16 if m.hp==2 else 17])
		else: draw_texture_rect_region(MechanicVFX.ATLAS,CasualSkin.fit(jewel,mechanic_textures[MechanicVFX.index(m.kind,m)].region),mechanic_textures[MechanicVFX.index(m.kind,m)].region)
		if m.kind=="lock":
			var progress:=float(m.energy)/float(m.required)
			if progress>0: draw_arc(center,25,-PI/2,-PI/2+TAU*progress,18,Color(Palette.COLORS[int(m.color)],.9),2.2,true)
			if not lock_labels.has(cell.id) or lock_labels[cell.id].energy!=m.energy or lock_labels[cell.id].required!=m.required:
				var content: String="%d/%d"%[m.energy,m.required]
				lock_labels[cell.id]={"energy":m.energy,"required":m.required,"text":content,"width":mechanic_font.get_string_size(content,HORIZONTAL_ALIGNMENT_LEFT,-1,10).x}
			var text: String=lock_labels[cell.id].text
			var anchor:=center+Vector2(-float(lock_labels[cell.id].width)/2,25)
			draw_string_outline(mechanic_font,anchor,text,HORIZONTAL_ALIGNMENT_LEFT,-1,10,3,Color("091524"))
			draw_string(mechanic_font,anchor,text,HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("fff1c9"))

func has_trait_animation(values: Array) -> bool:
	for cell in values:
		if cell!=null and cell.has("trait"):
			if cell.trait.kind=="bridge" or (cell.trait.kind=="chameleon" and int(cell.trait.count)==int(cell.trait.period)-1):return true
	return false

var highlight_style: StyleBoxFlat
func goal_highlight_style() -> StyleBoxFlat:
	if highlight_style==null:
		highlight_style=StyleBoxFlat.new();highlight_style.bg_color=Color(1,.92,.3,.08);highlight_style.border_color=Color("fff09a");highlight_style.set_border_width_all(2);highlight_style.set_corner_radius_all(10)
	return highlight_style

func spawn_stars(center: Vector2,count: int) -> void:
	if reduced_motion or settings.get("reduced_effects",false):return
	for k in mini(count,4 if quality=="performance" else 10):
		var slot:=particle_cursor%particle_budget();particle_cursor+=1;particle_count=maxi(particle_count,slot+1)
		particle_positions[slot]=center+Vector2((k-count/2)*15,0);particle_velocities[slot]=Vector2((k-count/2)*20,-70-k%3*20);particle_colors[slot]=Palette.COLORS[k%5].lightened(.4);particle_styles[slot]=3;particle_ages[slot]=0
func draw_shattered_crystal(cell: Dictionary,center: Vector2,t: float,shake: Vector2) -> void:
	var region: Rect2=textures[int(cell.c)].region
	var fitted:=CasualSkin.fit(Rect2(-28,-28,56,56),region)
	for k in 4:
		var x:=k%2;var y:=int(k/2)
		var axis:=Vector2(-1 if x==0 else 1,-1 if y==0 else 1)
		var source:=Rect2(region.position+Vector2(x,y)*region.size/2,region.size/2)
		var piece:=Rect2(fitted.position+Vector2(x,y)*fitted.size/2,fitted.size/2)
		draw_set_transform(center+axis*t*29,t*.2*axis.x)
		draw_texture_rect_region(ATLAS,piece,source,Color(1,1,1,1-t))
	draw_set_transform(shake)
func draw_combo_effect(data: Dictionary,t: float) -> void:
	var kind: String=data.get("combo_kind","")
	if kind=="":return
	var center:=cell_position(data.origin)+Vector2(28,28)
	var alpha:=sin(t*PI)*.65
	if kind in ["rocket_rocket","rocket_prism"]:
		for offset in ([-1,0,1] if kind=="rocket_prism" else [0]):
			draw_line(Vector2(0,center.y+offset*STRIDE),Vector2(476,center.y+offset*STRIDE),Color(.6,.94,1,alpha),5,true)
			draw_line(Vector2(center.x+offset*STRIDE,0),Vector2(center.x+offset*STRIDE,536),Color(1,.86,.6,alpha),5,true)
	elif kind in ["prism_prism","color_color"]:
		for k in (3 if kind=="color_color" else 2):draw_arc(center,20+t*(130+k*55),0,TAU,32,Color(Palette.COLORS[k],(1-t)*.8),4,true)
		draw_texture_rect(GLOW,Rect2(-30,-30,536,596),false,Color(1,1,1,alpha*.16))
	else:
		var sources: Array=data.get("virtual_powers",[])
		for power in sources.slice(0,6 if quality=="performance" else 12):
			var position:=cell_position(int(power.index))+Vector2(28,28)
			if t<.6:draw_texture_rect_region(ATLAS,Rect2(position-Vector2(23,23),Vector2(46,46)),textures[POWER_TEXTURES[power.kind]].region,Color(1,1,1,sin(t/.6*PI)))
			if power.kind=="prism":draw_arc(position,12+t*70,0,TAU,16,Color(.92,.7,1,(1-t)*.55),2,true)
			else:
				var axis:=Vector2.RIGHT if power.kind=="rocket_h" else Vector2.DOWN
				draw_line(position-axis*100*t,position+axis*100*t,Color(.7,1,1,(1-t)*.6),2,true)
