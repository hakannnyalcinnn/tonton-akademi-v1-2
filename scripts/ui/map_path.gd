extends Control
const CasualSkin=preload("res://scripts/ui/casual_skin.gd")
var world_theme:="garden"
var world_id:=1
var accent:=Color("72dbb3")
var completed_count:=0
var quiet:=false
var quality:="balanced"
var count:=50
var ocean:=false
var canyon:=false
var curve:=Curve2D.new()
var road:=PackedVector2Array()
var artwork: Texture2D
func node_position(index: int) -> Vector2:
 return Vector2(228+sin(float(index)*1.05)*130,160+(count-1-index)*146)
func _ready() -> void:
 mouse_filter=Control.MOUSE_FILTER_PASS
 artwork=load("res://assets/casual/world-"+world_theme+".png")
 var paint:=TextureRect.new();paint.name="PaintedTerrain";paint.texture=artwork;paint.size=custom_minimum_size;paint.expand_mode=TextureRect.EXPAND_IGNORE_SIZE;paint.show_behind_parent=true;paint.mouse_filter=Control.MOUSE_FILTER_IGNORE
 # Upright image strips overlap by 20%; end of one cycle equals start of the next.
 var shader:=Shader.new();shader.code="shader_type canvas_item; uniform float extent=7580.0; uniform float start_y=.49; uniform float range_y=.51; void fragment(){float v=.2+fract(UV.y*extent/1200.0)*.8;vec4 a=texture(TEXTURE,vec2(UV.x,start_y+v*range_y));vec4 b=texture(TEXTURE,vec2(UV.x,start_y+max(0.0,v-.8)*range_y));COLOR=mix(a,b,smoothstep(.8,1.0,v));}"
 var material:=ShaderMaterial.new();material.shader=shader;material.set_shader_parameter("extent",custom_minimum_size.y)
 if world_theme in ["cloud","canyon"]:material.set_shader_parameter("start_y",.20);material.set_shader_parameter("range_y",.80)
 paint.material=material;add_child(paint)
 curve.bake_interval=5
 for i in count:
  var tangent:=Vector2(130*1.05*cos(i*1.05),-146)/3
  curve.add_point(node_position(i),-tangent,tangent)
 curve.add_point(Vector2(228,64),Vector2(0,40),Vector2.ZERO)
 road=curve.get_baked_points()
 var living:=preload("res://scripts/ui/map_life.gd").new();living.name="LivingDecor";living.biome=world_theme;living.world_id=world_id;living.quiet=quiet;living.quality=quality;living.path=self;living.size=custom_minimum_size;living.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(living)
func _draw() -> void:
 draw_polyline(road,Color(.10,.14,.23,.30),89,true)
 draw_polyline(road,accent.darkened(.34),78,true)
 draw_polyline(road,Color("fff0c5"),68,true)
 draw_polyline(road,Color("dfbc8a") if world_theme!="cloud" else Color("d7c8f5"),57,true)
 draw_polyline(road,Color(1,.98,.86,.35),26,true)
 for i in range(7,road.size()-1,11):
  var side: Vector2=(road[i+1]-road[i]).normalized().orthogonal()*25
  draw_line(road[i]-side,road[i]+side,Color(.45,.31,.20,.15),1.3,true)
 var gate=CasualSkin.texture("decor",7,CasualSkin.DECOR)
 draw_texture_rect(gate,Rect2(178,4,100,88),false)
 var caption:="DÜNYA GEÇİDİ" if world_id<5 else "MACERANIN ZİRVESİ"
 draw_string(ThemeDB.fallback_font,Vector2(99,119),caption,HORIZONTAL_ALIGNMENT_CENTER,260,16,Color("243754"))
 draw_string(ThemeDB.fallback_font,Vector2(98,118),caption,HORIZONTAL_ALIGNMENT_CENTER,260,16,Color("fff2c5"))
