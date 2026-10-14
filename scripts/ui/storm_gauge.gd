extends Control
const Art=preload("res://scripts/ui/casual_skin.gd")
var quiet:=false
var value:=0
var pulse:=0.0
var flow:=0.0
var font: Font
func _ready() -> void:mouse_filter=Control.MOUSE_FILTER_IGNORE;font=ThemeDB.fallback_font
func set_value(amount: int) -> void:
 if amount>=12 and value<12:pulse=.32
 value=maxi(0,amount);queue_redraw()
func _process(delta: float) -> void:
 if value>0 and not quiet:
  flow=fmod(flow+delta*.65,1);queue_redraw()
 if pulse>0:pulse=maxf(0,pulse-delta);queue_redraw()
func _draw() -> void:
 if font==null:return
 var charge:=clampi(value,0,12)
 draw_texture_rect_region(Art.GEMS,Rect2(0,1,28,28),Art.region("gems",7))
 draw_string(font,Vector2(34,12),"PRİZMA FIRTINASI",HORIZONTAL_ALIGNMENT_LEFT,-1,10,Color("765393"))
 var width:=size.x-106
 draw_rect(Rect2(34,18,width,5),Color("ded2ef"))
 for k in 5:
  var left:=width*float(k)/5;var extent:=clampf(width*float(charge)/12-left,0,width/5)
  if extent>0:draw_rect(Rect2(34+left,18,extent,5),Color.from_hsv(float(k)/5,.55,.95))
 if charge>0:
  var head:=34+width*float(charge)/12*flow
  draw_line(Vector2(head,17),Vector2(head+4,24),Color(1,1,1,.6),1.5,true)
 draw_string(font,Vector2(size.x-61,22),"%d/12"%charge,HORIZONTAL_ALIGNMENT_CENTER,58,13,Color("6b548e"))
 if pulse>0:draw_rect(Rect2(32,16,width+4,9),Color(1,.83,.4,pulse*2),false,2)
