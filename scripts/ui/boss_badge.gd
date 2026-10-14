extends Control
const Registry=preload("res://scripts/ui/goal_registry.gd")
var state: Dictionary={}
var font: Font
var style: StyleBoxTexture
func _ready() -> void:mouse_filter=Control.MOUSE_FILTER_IGNORE;font=ThemeDB.fallback_font;style=preload("res://scripts/ui/casual_skin.gd").panel_style(1)
func update_state(value: Dictionary) -> void:state=value.duplicate(true);queue_redraw()
func _draw() -> void:
	if state.is_empty() or font==null:return
	draw_style_box(style,Rect2(Vector2.ZERO,size))
	if state.defeated:
		draw_string(font,Vector2(12,25),"BEKÇİ YENİLDİ!",HORIZONTAL_ALIGNMENT_LEFT,-1,15,Color("426b60"));return
	var phase: Dictionary=state.phases[int(state.phase)]
	draw_string(font,Vector2(10,14),str(state.name),HORIZONTAL_ALIGNMENT_LEFT,-1,11,Color("645386"))
	draw_string(font,Vector2(10,31),"%d/%d · %d enerji"%[int(state.phase)+1,state.phases.size(),int(state.remaining)],HORIZONTAL_ALIGNMENT_LEFT,-1,12,Color("426176"))
	if phase.get("special",false):draw_texture_rect(Registry.icon("bosses"),Rect2(230,4,32,32),false)
	else:
		for k in phase.colors.size():draw_texture_rect(Registry.icon(str(int(phase.colors[k]))),Rect2(216+k*28,7,26,26),false)
