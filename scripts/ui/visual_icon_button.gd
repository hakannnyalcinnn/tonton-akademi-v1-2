extends Button
static var empty_style:=StyleBoxEmpty.new()
const Design=preload("res://scripts/ui/ui_theme.gd")
var image: Texture2D
var amount:=-1
var chosen:=false
var caption:=""
var quiet:=false
var check_icon: Texture2D
func _ready() -> void:
 text="";mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
 for key in ["normal","hover","pressed","disabled","focus"]:add_theme_stylebox_override(key,empty_style)
 if caption!="":tooltip_text=caption
 check_icon=preload("res://scripts/ui/casual_skin.gd").texture("advanced",7,preload("res://scripts/ui/casual_skin.gd").ADVANCED)
func _draw() -> void:
 var center:=Vector2(size.x/2,minf(size.y/2,30))
 var radius:=minf(size.x*.42,29)
 draw_circle(center+Vector2(0,3),radius,Color("507b98"))
 draw_circle(center,radius,Color("fff5dc") if chosen else Color("d6eef1"))
 draw_arc(center,radius-1,0,TAU,28,Color("fff4b3") if chosen else Color("829ac3"),2.2,true)
 if chosen:draw_arc(center,radius+4,0,TAU,30,Color("ffe095"),3,true)
 if image:
  var tint:=Color(.65,.68,.74,.55) if disabled else Color.WHITE
  draw_texture_rect(image,preload("res://scripts/ui/casual_skin.gd").fit(Rect2(center-Vector2(25,25) if chosen else center-Vector2(23,23),Vector2(50,50) if chosen else Vector2(46,46)),Rect2(Vector2.ZERO,image.get_size())),false,tint)
 var font:=ThemeDB.fallback_font
 if amount>=0:
  var point:=center+Vector2(21,20);draw_circle(point,11,Color("584882"));draw_string(font,point+Vector2(-5,5),str(amount),HORIZONTAL_ALIGNMENT_LEFT,-1,13,Color.WHITE)
 if chosen and amount>=0:
  draw_texture_rect(check_icon,Rect2(center+Vector2(-28,13),Vector2(18,18)),false)
 if caption!="" and size.y>=76:draw_string(font,Vector2(1,70),caption,HORIZONTAL_ALIGNMENT_CENTER,size.x-2,12,Design.INK)
