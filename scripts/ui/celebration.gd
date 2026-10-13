extends Control
var world_finale := false
var age := 0.0

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(delta: float) -> void:
	age += delta
	queue_redraw()
	if age > 2.4: queue_free()

func _draw() -> void:
	var colors := [Color("f5d593"), Color("8ce1c5"), Color("ae91ec"), Color("f07791")]
	for i in 48:
		var velocity := Vector2.from_angle(i * 2.399963) * (90 + (i % 7) * 33)
		var pos := Vector2(270, 408) + velocity * age + Vector2(0, 100 * age * age)
		var color: Color = colors[i % 4]
		color.a = clampf(2.4 - age, 0, 1)
		draw_circle(pos, 2.5 + i % 3, color)
	var opacity := clampf(1.0 - age, 0, 1)
	draw_arc(Vector2(270, 408), age * 240, 0, TAU, 80, Color(0.75, 1, 0.89, opacity), 3, true)

	if world_finale:
		var center:=Vector2(270,444)
		var fade:=clampf(1-age/2.4,0,1)
		for ring in 3:draw_arc(center,35+age*(65+ring*32),0,TAU,48,Color(.92,.86,.58,fade*.6),2,true)
		for k in 12:
			var direction:=Vector2.from_angle(k*TAU/12+age*.1)
			draw_line(center+direction*(50+age*24),center+direction*(61+age*36),Color(.83,1,.85,fade),2,true)
