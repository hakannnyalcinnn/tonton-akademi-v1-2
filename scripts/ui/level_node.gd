extends Button
static var empty_style:=StyleBoxEmpty.new()
const ART=preload("res://assets/casual/level-node.svg")
const UI=preload("res://scripts/ui/ui_theme.gd")
var number:=1
var stars:=0
var active:=false
var finale:=false
var marker: Texture2D
var star_icon: Texture2D
var lock_icon: Texture2D
func _ready() -> void:
 for key in ["normal","hover","pressed","disabled","focus"]:add_theme_stylebox_override(key,empty_style)
 for key in ["font_color","font_hover_color","font_pressed_color","font_disabled_color"]:add_theme_color_override(key,Color.TRANSPARENT)
 star_icon=UI.icon("ui",3);lock_icon=UI.icon("ui",4)
 mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
func _draw() -> void:
 var tint:=Color(.7,.74,.84,.58) if disabled else Color("ffe4ad") if stars>0 else Color.WHITE
 draw_texture_rect(ART,Rect2(Vector2.ZERO,size),false,tint)
 var center:=size/2
 if active:draw_arc(center-Vector2(0,3),size.x*.47,0,TAU,36,Color("fff0a8"),3,true)
 var font:=ThemeDB.fallback_font;var caption:=str(number)
 var width:=font.get_string_size(caption,HORIZONTAL_ALIGNMENT_LEFT,-1,25).x
 draw_string(font,center+Vector2(-width/2,5),caption,HORIZONTAL_ALIGNMENT_LEFT,-1,25,UI.INK)
 if disabled:draw_texture_rect(lock_icon,Rect2(size.x-25,0,22,22),false)
 elif marker:draw_texture_rect(marker,Rect2(size.x-27,-4,28,28),false)
 for k in stars:draw_texture_rect(star_icon,Rect2(center.x-26+k*18,size.y-8,18,18),false)
