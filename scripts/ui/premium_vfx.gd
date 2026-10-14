extends RefCounted
## Cached authoritative beam paths; this renderer never applies damage or score.
static func beam(view: Control,points: PackedVector2Array,t: float,tint: Color,lite: bool) -> void:
 if points.size()<2:return
 var travel:=clampf((t-.1)/.72,0,1)*(points.size()-1)
 var whole:=mini(points.size()-2,int(travel))
 var head:=points[whole].lerp(points[whole+1],travel-whole)
 var alpha:=clampf((1-t)*3,0,1)
 var last:=points[0]
 for k in whole+1:
  var destination:=head if k==whole else points[k+1]
  if not lite:view.draw_line(last,destination,Color(tint.darkened(.7),alpha*.4),9,true)
  view.draw_line(last,destination,Color(tint,alpha),5 if not lite else 2,true)
  if not lite:view.draw_line(last,destination,Color(1,.98,.94,alpha),1.6,true)
  if k==whole:
   var axis:=(destination-last).normalized();var side:=Vector2(-axis.y,axis.x)
   view.draw_colored_polygon(PackedVector2Array([head+axis*7,head-axis*7+side*4,head-axis*7-side*4]),Color(1,.95,.75,alpha))
   view.draw_arc(head,4+(travel-whole)*10,0,TAU,12,Color(tint,alpha*.65),1.5,true)
  last=destination
 if not lite:view.draw_texture_rect(view.GLOW,Rect2(head-Vector2(18,18),Vector2(36,36)),false,Color(tint,alpha*.55))
static func double_bomb(view: Control,sources: PackedVector2Array,t: float,lite: bool) -> void:
 if sources.size()<2:return
 var center:=(sources[0]+sources[1])*.5
 var alpha:=sin(t*PI)*.5
 view.draw_line(sources[0],sources[1],Color(1,.89,.68,alpha),5,true)
 for k in (3 if lite else 5):
  var color: Color=view.Palette.COLORS[k]
  view.draw_arc(center,20+t*(100+k*36),k*TAU/5,k*TAU/5+TAU*.7,20,Color(color,alpha),2.5,true)
 if not lite:view.draw_texture_rect(view.GLOW,Rect2(center-Vector2(130,130),Vector2(260,260)),false,Color(1,.79,.94,alpha*.25))
