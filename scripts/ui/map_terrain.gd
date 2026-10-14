extends TextureRect
## One world-space canvas behind the map AND its floating menus. No clipped art strips.
var world_theme:="garden"
var scroll: ScrollContainer
var path: Control
var road_layer: Control
var last_scroll:=-INF
var last_extent:=Vector2.ZERO
func _ready() -> void:
 name="MapSceneBackdrop"
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 expand_mode=TextureRect.EXPAND_IGNORE_SIZE
 texture=load("res://assets/casual/terrain-"+world_theme+".png")
 var shader:=Shader.new()
 shader.code="""shader_type canvas_item;
uniform vec2 extent=vec2(540.0,960.0);
uniform float scroll_y=0.0;
uniform float period=800.0;
void fragment(){
 float world_y=UV.y*extent.y+scroll_y-130.0;
 float v=.12+fract(world_y/period)*.88;
 vec4 a=texture(TEXTURE,vec2(UV.x,v));
 vec4 b=texture(TEXTURE,vec2(UV.x,max(0.0,v-.88)));
 COLOR=mix(a,b,smoothstep(.88,1.0,v));
} """
 var paint:=ShaderMaterial.new();paint.shader=shader
 paint.set_shader_parameter("period",540.0*texture.get_height()/texture.get_width()*.88)
 material=paint
 road_layer=preload("res://scripts/ui/map_road_layer.gd").new();road_layer.name="ContinuousRoad";add_child(road_layer)
 sync_canvas()
func sync_canvas() -> void:
 var stage: Control=get_parent().get_parent()
 var offset: float=scroll.scroll_vertical if is_instance_valid(scroll) else 0.0
 if is_instance_valid(path) and road_layer.path!=path:road_layer.path=path;road_layer.queue_redraw()
 if size!=stage.size:size=stage.size
 if size!=last_extent:
  material.set_shader_parameter("extent",size);last_extent=size
 if offset!=last_scroll:
  material.set_shader_parameter("scroll_y",offset);last_scroll=offset;road_layer.world_offset=offset;road_layer.queue_redraw()
func _process(_delta: float) -> void:sync_canvas()
