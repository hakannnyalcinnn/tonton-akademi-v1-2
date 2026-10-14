extends Control
const BODY=preload("res://assets/casual/treasure-body.svg")
const LID=preload("res://assets/casual/treasure-lid.svg")
const GLOW=preload("res://assets/crystals/glow.svg")
var quiet:=false
var age:=0.0
func _ready() -> void:mouse_filter=Control.MOUSE_FILTER_IGNORE
func _process(delta: float) -> void:
	age=minf(1.1,age+delta);queue_redraw()
	if age>=1.1:set_process(false)
func _draw() -> void:
	var progress:=1.0 if quiet else clampf((age-.12)/.42,0,1)
	var center:=size/2
	draw_texture_rect(GLOW,Rect2(center-Vector2(47,47),Vector2(94,94)),false,Color(1,.85,.45,sin(progress*PI)*.85))
	draw_texture_rect(BODY,Rect2(0,size.y*.30,size.x,size.y*.64),false)
	var lid:=Rect2(0,size.y*.05-progress*size.y*.18,size.x,size.y*.40)
	draw_texture_rect(LID,lid,false)
	if not quiet and progress>0 and age<1.1:
		for k in 8:
			var point:=center+Vector2.from_angle(k*TAU/8)*progress*38
			draw_circle(point,1.4,Color(1,.91,.58,1-progress*.65))
