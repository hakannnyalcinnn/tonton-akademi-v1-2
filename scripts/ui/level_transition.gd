extends Control
const Art=preload("res://scripts/ui/casual_skin.gd")
const GLOW=preload("res://assets/crystals/glow.svg")
var age:=0.0
var quiet:=false
func _ready() -> void:mouse_filter=Control.MOUSE_FILTER_IGNORE
func _process(delta: float) -> void:
 age+=delta
 if not quiet:queue_redraw()
func _draw() -> void:
 if quiet:return
 var t:=clampf(age/.55,0,1)
 draw_texture_rect(GLOW,Rect2(Vector2(85,255),Vector2(370,300)),false,Color(.8,.9,1,sin(t*PI)*.3))
 for k in 12:
  var center:=Vector2(270,400)+Vector2.from_angle(k*TAU/12+t*.6)*(65+t*180)
  var source:=Art.region("gems",k%5)
  draw_texture_rect_region(Art.GEMS,Art.fit(Rect2(center-Vector2(12,12),Vector2(24,24)),source),source,Color(1,1,1,sin(t*PI)*.75))
