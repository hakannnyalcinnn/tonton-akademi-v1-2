extends Control
signal swap_requested(a: int, b: int)
signal special_pressed(index: int)
signal animation_finished
signal wave_started(data: Dictionary)
const Palette = preload("res://scripts/ui/palette.gd")
const CELL := 56.0
const GAP := 4.0
const WIDTH := 8
const HEIGHT := 9
const STRIDE := CELL + GAP
const DRAG_THRESHOLD := CELL * 0.26
var board
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
	queue = event.get("frames", []).duplicate(true)
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
	duration = 0.02 if reduced_motion else {"swap": 0.13, "revert": 0.13, "clear": 0.16, "fall": 0.12, "refill": 0.12, "shuffle": 0.24}.get(current.kind, 0.12)
	age = 0
	board.visual_phase(int(current.state))
	if current.kind == "clear": wave_started.emit(current)

func _process(delta: float) -> void:
	if board != null and board.state == board.State.PAUSED:
		cancel_drag()
		return
	if not reduced_motion: clock += delta
	if busy:
		age += delta
		if age >= duration:
			displayed = target
			next_frame()
	queue_redraw()

func cancel_drag() -> void:
	drag_index = -1
	pointer_id = -1
	drag_offset = Vector2.ZERO
	selected = -1
	moved = false

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
	update_drag(local)
	if released: finish_drag(local)
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
	if destination >= 0: swap_requested.emit(source, destination)

func _draw() -> void:
	if board == null: return
	draw_style_box(Palette.panel(Color(0.02, 0.05, 0.12, 0.92), 22, Color(0.62, 0.85, 0.83, 0.18)), Rect2(Vector2(-9, -9), Vector2(494, 554)))
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
		draw_cell(displayed[drag_index], Rect2(cell_position(drag_index) + drag_offset, Vector2(CELL, CELL)), true)
	if busy and current.kind == "clear":
		for i in current.removed:
			if previous[i] == null: continue
			var center := cell_position(i) + Vector2.ONE * CELL * 0.5
			var color: Color = Palette.COLORS[previous[i].c]
			if t < 0.5:
				var block_size := Vector2.ONE * CELL * (1 + t * 0.15) * (1 - t * 1.6)
				draw_cell(previous[i], Rect2(center - block_size / 2, block_size), true)
			if not reduced_motion:
				for k in 5:
					var ray := Vector2.from_angle(k * TAU / 5 + i)
					draw_circle(center + ray * t * 38, (1 - t) * 4 + 0.5, Color(color, 1 - t))
		if current.resonated and not reduced_motion:
			draw_arc(cell_position(current.origin) + Vector2.ONE * CELL * 0.5, t * 150, 0, TAU, 48, Color(0.7, 1, 0.94, 1 - t), 3, true)
	if hint_index >= 0 and not busy and drag_index < 0:
		var center := cell_position(hint_index) + Vector2(37, 37)
		if hint_target >= 0:
			var travel := clampf(fmod(clock, 2.2) - 0.45, 0, 1)
			center = center.lerp(cell_position(hint_target) + Vector2(37, 37), travel)
		var hand := PackedVector2Array([Vector2(0, 0), Vector2(0, 16), Vector2(-4, 13), Vector2(-8, 14), Vector2(-2, 25), Vector2(13, 27), Vector2(17, 21), Vector2(16, 10), Vector2(5, 8), Vector2(5, 0)])
		for k in hand.size(): hand[k] += center
		draw_colored_polygon(hand, Color("fff4dc"))
		draw_polyline(hand, Color("c5ab85"), 1.5, true)

func draw_cell(cell: Dictionary, rect: Rect2, highlighted: bool) -> void:
	var color: Color = Palette.COLORS[cell.c]
	if colorblind:
		color = [Color("e78145"), Color("5dace3"), Color("5ac8b4"), Color("f0da83"), Color("c08ecc")][cell.c]
	var center := rect.get_center()
	var pulse := 1.0 + (sin(clock * 3) * 0.035 if highlighted and not reduced_motion else 0.0)
	rect = Rect2(center - rect.size * pulse / 2, rect.size * pulse)
	draw_style_box(Palette.panel(color.darkened(0.56), 13), Rect2(rect.position + Vector2(0, 4), rect.size))
	draw_style_box(Palette.panel(color.darkened(0.18), 12, Color(color.lightened(0.35), 0.85)), rect)
	draw_style_box(Palette.panel(color, 10), Rect2(rect.position + Vector2(3, 2), rect.size - Vector2(6, 9)))
	draw_style_box(Palette.panel(Color(1, 1, 1, 0.21), 7), Rect2(rect.position + Vector2(7, 5), Vector2(rect.size.x - 14, 9)))
	draw_circle(rect.position + Vector2(rect.size.x - 9, 9), 2, Color(1, 1, 1, 0.60))
	if highlighted:
		draw_style_box(Palette.panel(Color(1, 1, 1, 0.07), 12, Color("fff1ba")), rect.grow(2))
	var ink := Color(1, 1, 1, 0.86)
	if cell.p == "":
		Palette.symbol(self, center + Vector2(0, 1), cell.c, color.darkened(0.45), 10)
		Palette.symbol(self, center + Vector2(0, -1), cell.c, ink, 9)
	elif cell.p.begins_with("rocket"):
		var axis := Vector2.RIGHT if cell.p == "rocket_h" else Vector2.UP
		draw_line(center - axis * 18, center + axis * 18, color.darkened(0.55), 11, true)
		draw_line(center - axis * 16, center + axis * 16, ink, 6, true)
		var normal := axis.orthogonal()
		draw_colored_polygon(PackedVector2Array([center + axis * 22, center + axis * 12 + normal * 7, center + axis * 12 - normal * 7]), ink)
	elif cell.p == "prism":
		draw_colored_polygon(PackedVector2Array([center + Vector2(0, -19), center + Vector2(17, 9), center + Vector2(0, 20), center + Vector2(-17, 9)]), ink)
		draw_line(center + Vector2(0, -17), center + Vector2(0, 18), color, 3, true)
		draw_line(center + Vector2(-15, 9), center + Vector2(15, 9), color, 2, true)
	else:
		for k in 5:
			var point := center + Vector2.from_angle(k * TAU / 5 - PI / 2) * 11
			draw_circle(point, 7, Palette.COLORS[k])
		draw_circle(center, 6, Color("ffffff"))
