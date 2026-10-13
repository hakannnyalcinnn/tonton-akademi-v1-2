extends Control
const Art=preload("res://scripts/ui/casual_skin.gd")
var value:=0
var pulse:=0.0
var font: Font
func _ready() -> void:mouse_filter=Control.MOUSE_FILTER_IGNORE;font=ThemeDB.fallback_font
func set_value(amount: int) -> void:
 if amount>=12 and value<12:pulse=.32
 value=amount;queue_redraw()
func _process(delta: float) -> void:
 if pulse>0:pulse=maxf(0,pulse-delta);queue_redraw()
func _draw() -> void:
 if font==null:return
 var charge:=mini(12,value)
 draw_texture_rect_region(Art.GEMS,Rect2(4,5,34,34),Art.region("gems",7))
 draw_string(font,Vector2(46,17),"PRİZMA FIRTINASI",HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("826baf"))
 draw_rect(Rect2(46,25,304,9),Color("e5dcef"))
 draw_rect(Rect2(46,25,304*float(charge)/12,9),Color("a86de2"))
 var text:="%d/12"%value
 draw_string(font,Vector2(361,31),text,HORIZONTAL_ALIGNMENT_CENTER,98,15,Color("6b548e"))
 if pulse>0:draw_rect(Rect2(44,23,308,13),Color(1,1,1,pulse),false,2)
