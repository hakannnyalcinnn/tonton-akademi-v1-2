extends Control
const CanyonArt=preload("res://scripts/ui/goal_registry.gd")
const CasualSkin=preload("res://scripts/ui/casual_skin.gd")
var world_theme:="garden"
var accent:=Color("f7d697")
var count:=50
var ocean:=false
var canyon:=false
var road:=PackedVector2Array()
func node_position(index: int) -> Vector2:
	return Vector2(228+sin(float(index)*.83)*145,70+index*100)
func _ready() -> void:
	mouse_filter=Control.MOUSE_FILTER_PASS
	for i in range(count*16):
		var index:=float(i)/16
		road.append(Vector2(228+sin(index*.83)*145,70+index*100))
func _draw() -> void:
	draw_polyline(road,Color(.38,.57,.65,.2),31,true)
	draw_polyline(road,accent,26,true)
	draw_polyline(road,Color("fff5d9"),18,true)
	for i in range(0,count,8):
		if not ocean:
			var source:=CasualSkin.region("ui",5)
			draw_texture_rect_region(CasualSkin.UI,CasualSkin.fit(Rect2(Vector2(300,90+i*100),Vector2(100,50)),source),source,Color(1,1,1,.65))
	if canyon:
		for i in range(0,count,3):
			var center:=node_position(i)+Vector2(-165 if i%2==0 else 135,0)
			draw_texture_rect(CanyonArt.icon("giants"),CasualSkin.fit(Rect2(center-Vector2(22,42),Vector2(48,84)),Rect2(Vector2.ZERO,CanyonArt.icon("giants").get_size())),false,Color(1,1,1,.85))
		return
	for i in range(0,count,3):
		var center:=node_position(i)+Vector2(-170 if i%2==0 else 130,20)
		var source:=CasualSkin.region("decor",4+i%4 if ocean else i%3)
		draw_texture_rect_region(CasualSkin.DECOR,CasualSkin.fit(Rect2(center,Vector2(95,95)),source),source)
