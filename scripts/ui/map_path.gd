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
 return Vector2(270+sin(float(index)*1.05)*130,160+(count-1-index)*146)
func _ready() -> void:
 mouse_filter=Control.MOUSE_FILTER_PASS
 var gate:=preload("res://scripts/ui/world_gate.gd").new();gate.position=Vector2(190,0);gate.size=Vector2(160,124);gate.quiet=quiet;gate.opened=completed_count>=50;gate.final_world=world_id==preload("res://scripts/core/world_catalog.gd").for_level(preload("res://scripts/core/world_catalog.gd").count());add_child(gate)
 curve.bake_interval=5
 for i in count:
  var tangent:=Vector2(130*1.05*cos(i*1.05),-146)/3
  curve.add_point(node_position(i),-tangent,tangent)
 curve.add_point(Vector2(270,64),Vector2(0,40),Vector2.ZERO)
 road=curve.get_baked_points()
 var living:=preload("res://scripts/ui/map_life.gd").new();living.name="LivingDecor";living.biome=world_theme;living.world_id=world_id;living.quiet=quiet;living.quality=quality;living.path=self;living.size=custom_minimum_size;living.mouse_filter=Control.MOUSE_FILTER_IGNORE;add_child(living)
func paint_road(canvas: CanvasItem) -> void:
 # Shared world canvas continues the path behind floating menus, without a clipped end.
 var soil:=Color("e6c595") if world_theme=="garden" else Color("d6d6af") if world_theme=="ocean" else Color("dfb290") if world_theme=="canyon" else Color("d7c8f5") if world_theme=="cloud" else Color("c7a1a5")
 canvas.draw_polyline(road,Color(.10,.14,.23,.14),86,true)
 canvas.draw_polyline(road,soil.darkened(.25),78,true)
 canvas.draw_polyline(road,soil.lightened(.25),72,true)
 canvas.draw_polyline(road,soil,62,true)
 canvas.draw_polyline(road,Color(1,.98,.86,.12),40,true)
 for i in range(7,road.size()-1,31):
  var side: Vector2=(road[i+1]-road[i]).normalized().orthogonal()
  var point: Vector2=road[i]+side*(27 if i%2 else -27)
  canvas.draw_circle(point,2.3,soil.darkened(.13))
  canvas.draw_circle(point+Vector2(3,2),1.4,soil.lightened(.2))
