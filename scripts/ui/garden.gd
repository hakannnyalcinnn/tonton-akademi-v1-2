extends Control
const Palette = preload("res://scripts/ui/palette.gd")
## Calm, layered world; monochrome slowly restores with collected color energy.
var vitality: float = 0.35
var clock: float = 0.0
var reduced_motion := false
var artwork: Texture2D
var displayed_vitality := 0.2
var color_energy: Array = [0, 0, 0, 0, 0]

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var color_material := ShaderMaterial.new()
	color_material.shader = load("res://assets/art/restore_color.gdshader")
	material = color_material
	if ResourceLoader.exists("res://assets/art/garden.png"):
		artwork = load("res://assets/art/garden.png")

func _process(delta: float) -> void:
	if not reduced_motion: clock += delta
	displayed_vitality = vitality if reduced_motion else lerpf(displayed_vitality, vitality, minf(1, delta * 2.5))
	material.set_shader_parameter("vitality", displayed_vitality)
	queue_redraw()

func _draw() -> void:
	var extent := size
	draw_rect(Rect2(Vector2.ZERO, extent), Color("0b162b"))
	if artwork:
		var texture_size := artwork.get_size()
		var ratio := maxf(extent.x / texture_size.x, extent.y / texture_size.y)
		var destination := Rect2((extent - texture_size * ratio) * 0.5, texture_size * ratio)
		draw_texture_rect(artwork, destination, false)
		draw_rect(Rect2(Vector2.ZERO, extent), Color(0.018, 0.035, 0.085, 0.34))
	else:
		# Original vector fallback, usable offline while optional painted art imports.
		for layer in 3:
			for i in 8:
				var x := float(i) * extent.x / 7
				var y := extent.y * (0.25 + layer * 0.10)
				draw_circle(Vector2(x, y), 85 - layer * 13, Color(0.025, 0.12 + vitality * 0.07, 0.17, 0.7))
		for side in [0, 1]:
			var x: float = extent.x * side
			var trunk := PackedVector2Array([Vector2(x - 32, extent.y), Vector2(x + 23, extent.y), Vector2(x + 17, 180), Vector2(x - 18, 60)])
			draw_colored_polygon(trunk, Color("172e36"))
			for i in 6:
				var base := Vector2(x, 100 + i * 92)
				var tip := base + Vector2(70 if side == 0 else -70, -66)
				draw_line(base, tip, Color("25474b"), 9)
				draw_circle(tip, 27, Color("244d51"))
	for i in 24:
		var pos := Vector2(fmod(i * 93.3 + 18, extent.x), fmod(i * 137.7 + 34, extent.y))
		pos += Vector2(sin(clock * 0.45 + i) * 4, cos(clock * 0.35 + i) * 6)
		var opacity := (0.2 + 0.18 * sin(clock + i)) * (0.3 + vitality)
		draw_circle(pos, 7, Color(1, 0.82, 0.4, opacity * 0.09))
		draw_circle(pos, 1.5, Color(1, 0.90, 0.62, opacity))
	# Color-specific world restoration: flowers, droplets, leaves, suns, crystals.
	for color in 5:
		var amount: float = minf(1, float(color_energy[color]) / 18.0)
		if amount <= 0: continue
		for i in 4:
			var x := 18.0 if i % 2 == 0 else extent.x - 18.0
			var y := extent.y * (0.18 + (color * 4 + i) * 0.032)
			var glow: Color = Palette.COLORS[color]
			glow.a = amount * 0.09
			draw_circle(Vector2(x, y), 19, glow)
			glow.a = amount * 0.72
			Palette.symbol(self, Vector2(x, y), color, glow, 5 + amount * 3)
