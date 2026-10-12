extends Control

signal cell_pressed(index: int)
signal animation_finished
const Palette = preload("res://scripts/ui/palette.gd")
const CELL := 56.0
const GAP := 4.0
const WIDTH := 8
const HEIGHT := 9
const STRIDE := CELL + GAP
var board
var busy := false
var reduced_motion := false
var colorblind := false
var age := 0.0
var duration := 0.32
var origins: Dictionary = {}
var removed: Array = []
var previous: Array = []
var hint_index := -1
var selected := -1
var wave_origin := -1
var resonance_wave := false
var clock := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	custom_minimum_size = Vector2(476, 536)

func set_board(value) -> void:
	board = value
	busy = false
	origins.clear()
	removed.clear()
	queue_redraw()

func cell_position(index: int) -> Vector2:
	return Vector2(index % WIDTH, int(index / WIDTH)) * STRIDE

func animate(event: Dictionary) -> void:
	if not event.get("accepted", false): return
	previous = event.get("before", []).duplicate(true)
	removed = event.get("removed", []).duplicate()
	origins.clear()
	var old_positions: Dictionary = {}
	for i in previous.size():
		if previous[i] != null: old_positions[previous[i].id] = cell_position(i)
	for i in board.cells.size():
		var cell: Dictionary = board.cells[i]
		if old_positions.has(cell.id):
			origins[cell.id] = old_positions[cell.id]
		else:
			var origin := cell_position(i)
			match board.direction:
				"down": origin.y = -STRIDE * (1 + int(i / WIDTH))
				"up": origin.y = HEIGHT * STRIDE + STRIDE * (HEIGHT - int(i / WIDTH))
				"left": origin.x = WIDTH * STRIDE + STRIDE * (WIDTH - i % WIDTH)
				"right": origin.x = -STRIDE * (1 + i % WIDTH)
			origins[cell.id] = origin
	age = 0
	duration = 0.06 if reduced_motion else 0.38
	busy = true
	wave_origin = event.get("origin", -1)
	resonance_wave = event.get("resonated", false)
	hint_index = -1
	queue_redraw()

func _process(delta: float) -> void:
	if not reduced_motion: clock += delta
	if busy:
		age += delta
		if age >= duration:
			busy = false
			removed.clear()
			animation_finished.emit()
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if busy or board == null: return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		var column := int(event.position.x / STRIDE)
		var row := int(event.position.y / STRIDE)
		if event.position.x < 0 or event.position.y < 0 or column >= WIDTH or row >= HEIGHT: return
		if fmod(event.position.x, STRIDE) > CELL or fmod(event.position.y, STRIDE) > CELL: return
		accept_event()
		cell_pressed.emit(row * WIDTH + column)

func _draw() -> void:
	if board == null: return
	draw_style_box(Palette.panel(Color(0.02, 0.05, 0.12, 0.92), 22, Color(0.62, 0.85, 0.83, 0.18)), Rect2(Vector2(-9, -9), Vector2(494, 554)))
	for i in board.cells.size():
		var cell: Dictionary = board.cells[i]
		var pos := cell_position(i)
		if busy:
			var t := clampf((age / duration - 0.18) / 0.82, 0, 1)
			var ease := 1 - pow(1 - t, 3)
			pos = origins.get(cell.id, pos).lerp(pos, ease)
			if t > 0.85 and t < 1: pos.y += sin((t - 0.85) / 0.15 * PI) * 2
		if pos.y < -CELL or pos.y > HEIGHT * STRIDE or pos.x < -CELL or pos.x > WIDTH * STRIDE: continue
		draw_cell(cell, Rect2(pos, Vector2(CELL, CELL)), i == hint_index or i == selected)
	if busy and not reduced_motion:
		var progress := clampf(age / duration, 0, 1)
		for i in removed:
			if i >= previous.size() or previous[i] == null: continue
			var center := cell_position(i) + Vector2.ONE * CELL * 0.5
			var color: Color = Palette.COLORS[previous[i].c]
			if progress < 0.20:
				var block_size := Vector2.ONE * CELL * (1 + progress * 0.5)
				draw_cell(previous[i], Rect2(center - block_size / 2, block_size), true)
			for k in 5:
				var ray := Vector2.from_angle(k * TAU / 5 + i)
				var position := center + ray * progress * 38
				draw_circle(position, (1 - progress) * 4 + 0.5, Color(color, 1 - progress))
		if resonance_wave and wave_origin >= 0:
			draw_arc(cell_position(wave_origin) + Vector2.ONE * CELL * 0.5, progress * 150, 0, TAU, 48, Color(0.7, 1, 0.94, 1 - progress), 3, true)
	if hint_index >= 0 and not busy:
		var hint_center := cell_position(hint_index) + Vector2(37, 37)
		hint_center.y += sin(clock * 3) * 4 if not reduced_motion else 0
		var hand := PackedVector2Array([Vector2(0, 0), Vector2(0, 16), Vector2(-4, 13), Vector2(-8, 14), Vector2(-2, 25), Vector2(13, 27), Vector2(17, 21), Vector2(16, 10), Vector2(5, 8), Vector2(5, 0)])
		for k in hand.size(): hand[k] += hint_center
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
