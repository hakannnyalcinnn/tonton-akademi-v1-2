extends Control
## Portal and caption share one visual footprint. Completion opens the energy core.
const PortalArt=preload("res://scripts/ui/casual_skin.gd")
var quiet:=false
var opened:=false
var final_world:=false
var phase:=0.0
var art: Texture2D
func _ready() -> void:
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 art=PortalArt.texture("decor",7,PortalArt.DECOR)
func _process(delta: float) -> void:
 if not quiet:
  phase+=delta;queue_redraw()
func _draw() -> void:
 var energy:=clampf(phase/.7,0,1) if opened else .15
 draw_circle(Vector2(80,48),35,Color(.35,.86,1,.10+energy*.16))
 if opened:draw_arc(Vector2(80,48),29,phase,phase+TAU*.8,40,Color(.6,1,1,.75),3,true)
 if art:draw_texture_rect(art,Rect2(28,0,104,94),false)
 var plaque:=StyleBoxFlat.new();plaque.bg_color=Color("37426b");plaque.border_color=Color("f4d48d");plaque.set_border_width_all(2);plaque.set_corner_radius_all(10)
 draw_style_box(plaque,Rect2(0,84,160,30))
 draw_string(ThemeDB.fallback_font,Vector2(4,104),"MACERA ZİRVESİ" if final_world else "DÜNYA GEÇİDİ",HORIZONTAL_ALIGNMENT_CENTER,152,15,Color("fff0c4"))
