extends Control
## One bounded redraw loop; only visible decorators animate. No tween per sprite.
const CasualSkin=preload("res://scripts/ui/casual_skin.gd")
var biome:="garden"
var world_id:=1
var quiet:=false
var quality:="balanced"
var path
var clock:=0.0
var elapsed:=0.0
var visible_top:=0.0
var visible_bottom:=960.0
var landmarks: Array[Texture2D]=[]
var sprites: Array[Texture2D]=[]
var gem: Texture2D
var creature: Texture2D
func _ready() -> void:
 mouse_filter=Control.MOUSE_FILTER_IGNORE
 var metadata:=preload("res://scripts/core/world_catalog.gd").get_world(world_id)
 biome=str(metadata.get("decor_style",biome))
 var decor_world:=int(metadata.get("decor_world",clampi(world_id,1,5)))
 creature=preload("res://scripts/ui/companion.gd").sprite(decor_world)
 gem=CasualSkin.texture("gems",[4,1,0][clampi(decor_world-3,0,2)],CasualSkin.GEMS)
 for i in 8:sprites.append(CasualSkin.texture("decor",i,CasualSkin.DECOR))
 if ResourceLoader.exists("res://assets/casual/map-landmarks.png"):
  var atlas: Texture2D=load("res://assets/casual/map-landmarks.png")
  for i in 6:
   var texture:=AtlasTexture.new();texture.atlas=atlas;var split:=atlas.get_height()*.5664;texture.region=Rect2(Vector2((i%3)*atlas.get_width()/3.0,0 if i<3 else split),Vector2(atlas.get_width()/3.0,split if i<3 else atlas.get_height()-split));landmarks.append(texture)
 else:
  for i in 6:landmarks.append(load("res://assets/casual/map-"+biome+"-landmark.svg"))
func _process(delta: float) -> void:
 elapsed+=delta
 var parent=path.get_parent()
 var top: float=parent.scroll_vertical if parent is ScrollContainer else 0
 var changed:=absf(top-visible_top)>1
 visible_top=top;visible_bottom=top+parent.size.y
 var interval:=.12 if quality=="performance" else .05
 if changed or (not quiet and elapsed>=interval):
  if not quiet:clock+=elapsed
  elapsed=0;queue_redraw()
func sprite(texture: Texture2D,center: Vector2,extent: Vector2,angle: float=0.0,alpha: float=1.0) -> void:
 for n in range(maxi(0,int((path.count-1)-(center.y-160)/146)-2),mini(path.count,int((path.count-1)-(center.y-160)/146)+3)):
  var node_center: Vector2=path.node_position(n)
  var exclusion:=Rect2(node_center-Vector2(60,60),Vector2(120,120))
  if Rect2(center-extent/2,extent).intersects(exclusion):
   center.x=clampf(node_center.x+(-1 if center.x<node_center.x else 1)*(60+extent.x/2+6),extent.x/2,540-extent.x/2)
 draw_set_transform(center,angle)
 draw_texture_rect(texture,CasualSkin.fit(Rect2(-extent/2,extent),Rect2(Vector2.ZERO,texture.get_size())),false,Color(1,1,1,alpha));draw_set_transform(Vector2.ZERO)
func _draw() -> void:
 if not path:return
 for i in range(path.count):
  var anchor: Vector2=path.node_position(i)
  if anchor.y<visible_top-180 or anchor.y>visible_bottom+180:continue
  var side:=68.0 if anchor.x>270 else 472.0
  var phase:=clock+i*1.79
  var center:=Vector2(side+sin(i*2.39)*14,anchor.y+12+sin(i*3.7)*20)
  var scale_factor:=.72+fposmod(i*.173,.33)
  if biome=="garden":
   if i%3!=1:sprite(sprites[[1,0,2,0,1,2,0][i%7]],center,Vector2(120,128)*scale_factor,sin(phase*.5)*.014)
   if i%3!=1:sprite(sprites[2 if i%4 else 1],Vector2(540-side,anchor.y+74),Vector2(65,68)*scale_factor,sin(phase*.8)*.025)
   sprite(sprites[3],center+Vector2(sin(phase*.7)*23,-65+cos(phase)*10),Vector2(37,34),sin(phase)*.16)
  elif biome=="ocean":
   sprite(sprites[4 if i%2==0 else 6],center,Vector2(140,140)*scale_factor,sin(phase*.55)*.025)
   sprite(sprites[5],Vector2(540-side+sin(phase*.6)*22,anchor.y+55),Vector2(65,55),sin(phase*.5)*.06)
  else:
   var main_landmark:=i%3==0
   var feature: Texture2D=landmarks[{"canyon":0,"cloud":1,"lava":2}.get(biome,0)] if main_landmark else landmarks[4] if biome=="cloud" and i%3==2 else landmarks[5]
   sprite(feature,center,Vector2(132,139)*scale_factor if main_landmark else Vector2(92,96)*scale_factor,sin(phase*.4)*(.015 if biome=="cloud" else .004))
   if i%3!=1:sprite(gem,Vector2(540-side,anchor.y+70),Vector2(43,48)*(1+sin(i*2.17)*.15),sin(phase*.5)*.045)
   if biome=="cloud":sprite(landmarks[4],Vector2(540-side+sin(phase*.25)*18,anchor.y-16),Vector2(126,76),0,.85)
   elif biome=="canyon" and main_landmark:
    for k in 3:
     var drop:=fposmod(clock*28+k*19,62)
     draw_line(center+Vector2(-11+k*5,drop-10),center+Vector2(-11+k*5,drop+3),Color(.7,.97,1,.40),2,true)
   elif biome=="lava":draw_arc(center+Vector2(0,48),29,0,PI,16,Color(1,.42,.10,.12+.08*sin(phase)),9,true)
  if i%10==5:sprite(creature,Vector2(side,anchor.y-68+sin(phase)*4),Vector2(63,63),sin(phase*.6)*.035)
  if i%10==8:sprite(landmarks[3],Vector2(270,anchor.y-64),Vector2(124,60))
