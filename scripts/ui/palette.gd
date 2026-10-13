extends RefCounted
const COLORS := [Color("f54371"), Color("22b8ef"), Color("19cd8c"), Color("ffc62b"), Color("ac59ec")]
const INK := Color("35436d")
const MUTED := Color("62779a")
const GOLD := Color("bf7021")

static func panel(color: Color, radius: int = 20, border: Color = Color(0, 0, 0, 0)) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.shadow_color=Color(.3,.25,.5,.12)
	style.shadow_size=5
	style.shadow_offset=Vector2(0,3)
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	style.border_color = border
	style.set_border_width_all(1 if border.a > 0 else 0)
	style.content_margin_left = 14
	style.content_margin_right = 14
	return style

static func symbol(canvas: CanvasItem, center: Vector2, color_index: int, ink: Color, radius: float = 9) -> void:
	match color_index:
		0:
			var points := PackedVector2Array()
			for k in 10:
				var angle := -PI / 2 + k * TAU / 10
				points.append(center + Vector2(cos(angle), sin(angle)) * (radius if k % 2 == 0 else radius * 0.46))
			canvas.draw_colored_polygon(points, ink)
		1:
			canvas.draw_colored_polygon(PackedVector2Array([center + Vector2(0, -radius), center + Vector2(radius * 0.75, radius * 0.45), center + Vector2(0, radius), center + Vector2(-radius * 0.75, radius * 0.45)]), ink)
		2:
			canvas.draw_colored_polygon(PackedVector2Array([center + Vector2(-radius, radius * 0.5), center + Vector2(-radius * 0.65, -radius * 0.6), center + Vector2(radius, -radius * 0.6), center + Vector2(radius * 0.65, radius * 0.7)]), ink)
			canvas.draw_line(center + Vector2(-radius * 0.5, radius * 0.35), center + Vector2(radius * 0.5, -radius * 0.3), ink.darkened(0.3), 2)
		3:
			canvas.draw_circle(center, radius * 0.68, ink)
			for k in 8:
				var ray := Vector2.from_angle(k * TAU / 8)
				canvas.draw_line(center + ray * radius * 0.85, center + ray * radius * 1.2, ink, 2)
		4:
			canvas.draw_circle(center, radius, ink)
			canvas.draw_circle(center + Vector2(radius * 0.45, -radius * 0.25), radius * 0.83, ink.darkened(0.42))
