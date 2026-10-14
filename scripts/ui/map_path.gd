extends Control
const CanyonArt=preload("res://scripts/ui/goal_registry.gd")
const CasualSkin=preload("res://scripts/ui/casual_skin.gd")
var world_theme:="garden"
var accent:=Color("f7d697")
var completed_count:=0
var quiet:=false
var count:=50
var ocean:=false
var canyon:=false
var road:=PackedVector2Array()
var landmark: Texture2D
func node_position(index: int) -> Vector2:
	return Vector2(228+sin(float(index)*.71)*134+sin(float(index)*.23)*14,94+(count-1-index)*128)
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_PASS
	landmark=load("res://assets/casual/map-"+world_theme+"-landmark.svg")
	for i in range(0,count,10):
		var creature:=preload("res://scripts/ui/companion.gd").new();creature.creature=1 if world_theme=="garden" else 2 if world_theme=="ocean" else 3 if world_theme=="canyon" else 4 if world_theme=="cloud" else 5
		creature.position=node_position(i)+Vector2(-165,-25);creature.size=Vector2(72,72);creature.quiet=quiet;creature.modulate.a=1 if i<completed_count else .4;add_child(creature)
	for i in range((count-1)*20+1):
		var step:=float(i)/20
		road.append(Vector2(228+sin(step*.71)*134+sin(step*.23)*14,94+(count-1-step)*128))
func _draw() -> void:
	draw_polyline(road,Color(.12,.15,.28,.28),39,true)
	draw_polyline(road,accent.darkened(.15),33,true)
	draw_polyline(road,Color("ebd6ad"),24,true)
	for i in range(4,road.size(),13):
		var point: Vector2=road[i]
		draw_line(point-Vector2(4,0),point+Vector2(4,0),Color(.5,.35,.2,.22),1.5,true)
	for i in range(0,count,8):
		if not ocean:
			var source:=CasualSkin.region("ui",5)
			draw_texture_rect_region(CasualSkin.UI,CasualSkin.fit(Rect2(node_position(i)+Vector2(110,-48),Vector2(100,50)),source),source,Color(1,1,1,.65))
	for index in range(2,count,6):
		var anchor:=node_position(index)
		var center:=Vector2(60 if anchor.x>228 else 395,anchor.y-5)
		if landmark:draw_texture_rect(landmark,Rect2(center-Vector2(51,51),Vector2(102,102)),false)
	if canyon:
		for i in range(0,count,3):
			var center:=Vector2(60 if node_position(i).x>228 else 395,node_position(i).y)
			draw_texture_rect(CanyonArt.icon("giants"),CasualSkin.fit(Rect2(center-Vector2(22,42),Vector2(48,84)),Rect2(Vector2.ZERO,CanyonArt.icon("giants").get_size())),false,Color(1,1,1,.85))
		return
	for i in range(0,count,3):
		var center:=Vector2(8 if node_position(i).x>228 else 345,node_position(i).y+40)
		var source:=CasualSkin.region("decor",4+i%4 if ocean else i%3)
		draw_texture_rect_region(CasualSkin.DECOR,CasualSkin.fit(Rect2(center,Vector2(95,95)),source),source)
